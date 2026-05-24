const fs = require('fs/promises');
const path = require('path');

const dataDir = process.env.LINGOVA_JSON_DATA_DIR || path.join(__dirname, '..', 'data');
const supabaseUrl = String(process.env.SUPABASE_URL || '').replace(/\/$/, '');
const supabaseKey =
  process.env.SUPABASE_SERVICE_ROLE_KEY ||
  process.env.SUPABASE_SERVICE_KEY ||
  process.env.SUPABASE_KEY ||
  '';

const files = [
  'users.json',
  'courses.json',
  'books.json',
  'subscriptions.json',
  'notifications.json',
  'support_messages.json',
  'direct_messages.json',
  'device_tokens.json',
  'questions.json',
  'watch_progress.json',
  'exams.json',
  'exam_results.json',
  'activity_logs.json',
  'app_sessions.json',
  'community_posts.json',
  'vocabulary_words.json',
  'audio_resources.json',
];

function collectionName(fileName) {
  return path.basename(fileName, '.json');
}

async function supabaseRpc(functionName, body) {
  if (typeof fetch !== 'function') {
    throw new Error('This migration requires Node.js 18 or newer.');
  }

  const response = await fetch(`${supabaseUrl}/rest/v1/rpc/${functionName}`, {
    method: 'POST',
    headers: {
      apikey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  const text = await response.text();
  if (!response.ok) {
    throw new Error(`${functionName} failed (${response.status}): ${text}`);
  }

  return text ? JSON.parse(text) : null;
}

async function supabaseRest(pathname) {
  if (typeof fetch !== 'function') {
    throw new Error('This migration requires Node.js 18 or newer.');
  }

  const response = await fetch(`${supabaseUrl}${pathname}`, {
    headers: {
      apikey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
      'Content-Type': 'application/json',
    },
  });

  const text = await response.text();
  if (!response.ok) {
    throw new Error(`REST verification failed (${response.status}): ${text}`);
  }

  return text ? JSON.parse(text) : null;
}

function chatChannelForCollection(collection) {
  if (collection === 'support_messages') return 'support';
  if (collection === 'direct_messages') return 'direct';
  return '';
}

async function logChatVerification(collection, sourceCount, readableCount) {
  const channel = chatChannelForCollection(collection);
  if (!channel) return;

  const sampleRows = await supabaseRest(
    `/rest/v1/chat_messages?channel=eq.${encodeURIComponent(channel)}&select=id,student_id,sender,read_by_admin,read_by_student,created_at&order=created_at.desc.nullslast&limit=5`
  );

  const sample = Array.isArray(sampleRows)
    ? sampleRows.map((row) => ({
        id: row.id,
        studentId: row.student_id,
        sender: row.sender,
        readByAdmin: row.read_by_admin,
        readByStudent: row.read_by_student,
        createdAt: row.created_at,
      }))
    : [];

  console.log(
    `[verify:chat] collection=${collection} channel=${channel} source=${sourceCount} readable=${readableCount} sample=${JSON.stringify(sample)}`
  );
}

async function main() {
  if (!supabaseUrl || !supabaseKey) {
    throw new Error(
      'Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY before running migration.'
    );
  }

  for (const fileName of files) {
    const filePath = path.join(dataDir, fileName);
    let records = [];

    try {
      const content = await fs.readFile(filePath, 'utf8');
      records = JSON.parse(content || '[]');
    } catch (error) {
      if (error.code !== 'ENOENT') {
        throw error;
      }

      console.log(`Skipped ${fileName}; file not found in ${dataDir}`);
      continue;
    }

    if (!Array.isArray(records)) {
      throw new Error(`${filePath} must contain a JSON array.`);
    }

    const collection = collectionName(fileName);

    await supabaseRpc('lingova_replace_collection', {
      p_collection: collection,
      p_records: records,
    });

    const migratedRows = await supabaseRpc('lingova_read_collection', {
      collection_name: collection,
    });
    const migratedCount = Array.isArray(migratedRows) ? migratedRows.length : 0;

    console.log(
      `Migrated ${records.length} records from ${fileName}; readable rows: ${migratedCount}`
    );

    await logChatVerification(collection, records.length, migratedCount);
  }
}

main().catch((error) => {
  const message =
    error && error.stack
      ? error.stack
      : error && error.message
        ? error.message
        : String(error);

  try {
    console.error(message);
  } catch {}

  process.exitCode = 1;
});
