const crypto = require('crypto');
const fsSync = require('fs');
const fs = require('fs/promises');
const http = require('http');
const path = require('path');
const { Readable } = require('stream');
let firebaseAdmin = null;
try {
  firebaseAdmin = require('firebase-admin');
} catch {}

const port = Number(process.env.PORT || 3000);
const host = process.env.HOST || '0.0.0.0';
const bundledDataDir = path.join(__dirname, 'data');
const isRailway =
  process.env.RAILWAY_ENVIRONMENT ||
  process.env.RAILWAY_PROJECT_ID ||
  process.env.RAILWAY_SERVICE_ID;
const localDataDir = path.join(
  process.env.LOCALAPPDATA ||
    process.env.APPDATA ||
    process.env.XDG_DATA_HOME ||
    path.join(process.env.HOME || process.cwd(), '.local', 'share'),
  'Lingova',
  'backend-data'
);
const railwayDataDir = isRailway ? '/data' : '';
const dataDir =
  process.env.LINGOVA_DATA_DIR ||
  process.env.RAILWAY_VOLUME_MOUNT_PATH ||
  railwayDataDir ||
  localDataDir;
const usersFile = path.join(dataDir, 'users.json');
const coursesFile = path.join(dataDir, 'courses.json');
const booksFile = path.join(dataDir, 'books.json');
const subscriptionsFile = path.join(dataDir, 'subscriptions.json');
const notificationsFile = path.join(dataDir, 'notifications.json');
const notificationReadsFile = path.join(dataDir, 'notification_reads.json');
const supportMessagesFile = path.join(dataDir, 'support_messages.json');
const deviceTokensFile = path.join(dataDir, 'device_tokens.json');
const questionsFile = path.join(dataDir, 'questions.json');
const watchProgressFile = path.join(dataDir, 'watch_progress.json');
const examsFile = path.join(dataDir, 'exams.json');
const examResultsFile = path.join(dataDir, 'exam_results.json');
const activityLogsFile = path.join(dataDir, 'activity_logs.json');
const appSessionsFile = path.join(dataDir, 'app_sessions.json');
const communityPostsFile = path.join(dataDir, 'community_posts.json');
const vocabularyWordsFile = path.join(dataDir, 'vocabulary_words.json');
const audioResourcesFile = path.join(dataDir, 'audio_resources.json');
const appSettingsFile = path.join(dataDir, 'app_settings.json');
const adminEmail = process.env.ADMIN_EMAIL || 'admin@lingova.com';
const adminPassword = process.env.ADMIN_PASSWORD || 'admin123';
const adminSessions = new Map();
const appDownloadUrl = process.env.APP_DOWNLOAD_URL || 'https://example.com/download-app';
const adminPanelUrl = process.env.ADMIN_PANEL_URL || 'https://example.com/admin-panel';
const availableCoursesCount = 8;
let firebaseMessaging = undefined;
const supabaseUrl = String(process.env.SUPABASE_URL || '').replace(/\/$/, '');
const supabaseKey =
  process.env.SUPABASE_SERVICE_ROLE_KEY ||
  process.env.SUPABASE_SERVICE_KEY ||
  process.env.SUPABASE_KEY ||
  '';
const useSupabase = Boolean(supabaseUrl && supabaseKey);
const googleDriveApiKey = process.env.GOOGLE_DRIVE_API_KEY || '';

async function ensureStore() {
  if (useSupabase) {
    return;
  }

  await fs.mkdir(dataDir, { recursive: true });
  await ensureJsonFile(usersFile);
  await ensureJsonFile(coursesFile);
  await ensureJsonFile(booksFile);
  await ensureJsonFile(subscriptionsFile);
  await ensureJsonFile(notificationsFile);
  await ensureJsonFile(notificationReadsFile);
  await ensureJsonFile(deviceTokensFile);
  await ensureJsonFile(questionsFile);
  await ensureJsonFile(watchProgressFile);
  await ensureJsonFile(examsFile);
  await ensureJsonFile(examResultsFile);
  await ensureJsonFile(activityLogsFile);
  await ensureJsonFile(appSessionsFile);
  await ensureJsonFile(supportMessagesFile);
  await ensureJsonFile(communityPostsFile);
  await ensureJsonFile(vocabularyWordsFile);
  await ensureJsonFile(audioResourcesFile);
  await ensureJsonFile(appSettingsFile);
}

async function ensureJsonFile(file) {
  try {
    await fs.access(file);
    return;
  } catch {}

  const seedFile = path.join(bundledDataDir, path.basename(file));
  if (path.resolve(seedFile) !== path.resolve(file)) {
    try {
      const seedContent = await fs.readFile(seedFile, 'utf8');
      await fs.writeFile(file, seedContent || '[]\n', 'utf8');
      return;
    } catch {}
  }

  await fs.writeFile(file, '[]\n', 'utf8');
}

function collectionNameForFile(file) {
  return path.basename(file, '.json');
}

async function supabaseRequest(pathname, { method = 'GET', body } = {}) {
  if (typeof fetch !== 'function') {
    throw new Error('Supabase storage requires Node.js 18 or newer.');
  }

  const response = await fetch(`${supabaseUrl}${pathname}`, {
    method,
    headers: {
      apikey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
      'Content-Type': 'application/json',
      Prefer: 'return=representation',
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  const text = await response.text();
  if (!response.ok) {
    throw new Error(
      `Supabase request failed (${response.status}): ${text || response.statusText}`
    );
  }

  return text ? JSON.parse(text) : null;
}

const defaultRegistrationForm = {
  fields: [
    { key: 'fullName', label: 'الاسم بالكامل', type: 'text', required: true, enabled: true, isCore: true, icon: 'person', options: [] },
    { key: 'phone', label: 'رقم الهاتف', type: 'phone', required: true, enabled: true, isCore: true, icon: 'phone', options: [] },
    { key: 'password', label: 'كلمة المرور', type: 'password', required: true, enabled: true, isCore: true, icon: 'lock', options: [] },
    { key: 'confirmPassword', label: 'تأكيد كلمة المرور', type: 'password', required: true, enabled: true, isCore: true, icon: 'verified', options: [] },
    { key: 'address', label: 'المحافظة', type: 'dropdown', required: true, enabled: true, isCore: true, icon: 'location', options: ['القاهرة', 'الجيزة', 'الإسكندرية', 'الدقهلية', 'البحر الأحمر', 'البحيرة', 'الفيوم', 'الغربية', 'الإسماعيلية', 'المنوفية', 'المنيا', 'القليوبية', 'الوادي الجديد', 'السويس', 'أسوان', 'أسيوط', 'بني سويف', 'بورسعيد', 'دمياط', 'الشرقية', 'جنوب سيناء', 'كفر الشيخ', 'مطروح', 'الأقصر', 'قنا', 'شمال سيناء', 'سوهاج'] },
    { key: 'job', label: 'الوظيفة', type: 'dropdown', required: true, enabled: true, isCore: true, icon: 'work', options: ['طالب', 'معلم', 'طبيب', 'صيدلي', 'مهندس', 'محاسب', 'محامي', 'مصمم جرافيك', 'مبرمج', 'مصمم واجهات', 'مسوق رقمي', 'مندوب مبيعات', 'خدمة عملاء', 'موظف إداري', 'مدير مشروع', 'مدير موارد بشرية', 'صاحب عمل', 'رائد أعمال', 'مترجم', 'كاتب محتوى', 'صحفي', 'باحث', 'عامل حر', 'فني', 'سائق', 'ممرض', 'مدرب', 'مصمم أزياء', 'ربة منزل', 'أخرى'] },
    { key: 'language', label: 'اللغة المهتم بها', type: 'dropdown', required: true, enabled: true, isCore: true, icon: 'translate', options: ['الإنجليزية', 'الألمانية'] },
    { key: 'learningReason', label: 'سبب تعلم اللغة', type: 'dropdown', required: true, enabled: true, isCore: true, icon: 'flag', options: ['السفر', 'الدراسة', 'الشغل', 'تعليم الأولاد', 'سبب أخر'] },
    { key: 'referralReason', label: 'لماذا اخترتنا؟', type: 'text', required: true, enabled: true, isCore: true, icon: 'favorite', options: [] },
  ],
};

const coreRegistrationKeys = new Set([
  'fullName',
  'phone',
  'password',
  'confirmPassword',
  'address',
  'job',
  'language',
  'learningReason',
  'referralReason',
]);

const requiredCoreRegistrationKeys = new Set(['fullName', 'phone', 'password']);

function normalizeRegistrationFormConfig(value) {
  const sourceFields = Array.isArray(value?.fields)
    ? value.fields
    : defaultRegistrationForm.fields;
  const fields = sourceFields
    .map((field, index) => {
      const key = String(field?.key || '').trim() || `custom_${index + 1}`;
      const type = ['text', 'phone', 'password', 'dropdown', 'multiline'].includes(field?.type)
        ? field.type
        : 'text';
      const isCore = coreRegistrationKeys.has(key) || field?.isCore === true;
      const options = Array.isArray(field?.options)
        ? field.options.map((item) => String(item || '').trim()).filter(Boolean)
        : [];
      return {
        key,
        label: String(field?.label || key).trim(),
        type,
        required: requiredCoreRegistrationKeys.has(key) ? true : field?.required !== false,
        enabled: requiredCoreRegistrationKeys.has(key) ? true : field?.enabled !== false,
        isCore,
        icon: String(field?.icon || 'text').trim(),
        options,
      };
    })
    .filter((field) => field.key && field.label);

  for (const defaultField of defaultRegistrationForm.fields) {
    if (requiredCoreRegistrationKeys.has(defaultField.key) && !fields.some((field) => field.key === defaultField.key)) {
      fields.unshift(defaultField);
    }
  }

  return { fields: fields.length ? fields : defaultRegistrationForm.fields };
}

async function readAppSetting(key, fallback) {
  if (useSupabase) {
    const rows = await supabaseRequest(`/rest/v1/app_settings?key=eq.${encodeURIComponent(key)}&select=value`);
    return rows && rows[0] ? rows[0].value : fallback;
  }

  await ensureStore();
  const settings = await readCollection(appSettingsFile);
  const row = settings.find((item) => item.key === key);
  return row?.value ?? fallback;
}

async function writeAppSetting(key, value, description = '') {
  if (useSupabase) {
    const existing = await supabaseRequest(`/rest/v1/app_settings?key=eq.${encodeURIComponent(key)}&select=key`);
    if (existing && existing.length) {
      await supabaseRequest(`/rest/v1/app_settings?key=eq.${encodeURIComponent(key)}`, {
        method: 'PATCH',
        body: { value, description, updated_at: new Date().toISOString() },
      });
    } else {
      await supabaseRequest('/rest/v1/app_settings', {
        method: 'POST',
        body: { key, value, description },
      });
    }
    return;
  }

  const settings = await readCollection(appSettingsFile);
  const existing = settings.find((item) => item.key === key);
  if (existing) {
    existing.value = value;
    existing.description = description;
    existing.updatedAt = new Date().toISOString();
  } else {
    settings.push({
      key,
      value,
      description,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });
  }
  await writeCollection(appSettingsFile, settings);
}

async function readRegistrationFormConfig() {
  const value = await readAppSetting('registration_form', defaultRegistrationForm);
  return normalizeRegistrationFormConfig(value);
}

async function readCollection(file) {
  if (useSupabase) {
    const rows = await supabaseRequest('/rest/v1/rpc/lingova_read_collection', {
      method: 'POST',
      body: {
        collection_name: collectionNameForFile(file),
      },
    });
    return (rows || []).map((row) => row.data).filter(Boolean);
  }

  await ensureStore();
  const content = await fs.readFile(file, 'utf8');
  return JSON.parse(content || '[]');
}

async function writeCollection(file, records) {
  if (useSupabase) {
    await supabaseRequest('/rest/v1/rpc/lingova_replace_collection', {
      method: 'POST',
      body: {
        p_collection: collectionNameForFile(file),
        p_records: records,
      },
    });
    return;
  }

  await fs.writeFile(file, `${JSON.stringify(records, null, 2)}\n`, 'utf8');
}

async function readUsers() {
  return readCollection(usersFile);
}

async function writeUsers(users) {
  await writeCollection(usersFile, users);
}

function normalizePhone(phone) {
  return String(phone || '').replace(/\s/g, '');
}

async function findUserByPhone(phone) {
  const users = await readUsers();
  const normalizedPhone = normalizePhone(phone);
  return users.find((user) => normalizePhone(user.phone) === normalizedPhone);
}

async function readCourseParts() {
  return readCollection(coursesFile);
}

async function writeCourseParts(parts) {
  await writeCollection(coursesFile, parts);
}

async function readBooks() {
  return readCollection(booksFile);
}

async function writeBooks(books) {
  await writeCollection(booksFile, books);
}

async function readSubscriptions() {
  return readCollection(subscriptionsFile);
}

async function writeSubscriptions(subscriptions) {
  await writeCollection(subscriptionsFile, subscriptions);
}

async function readNotifications() {
  return readCollection(notificationsFile);
}

async function writeNotifications(notifications) {
  await writeCollection(notificationsFile, notifications);
}

async function readNotificationReads() {
  if (useSupabase) {
    return supabaseRequest('/rest/v1/notification_reads?select=notification_id,user_id,read_at');
  }

  return readCollection(notificationReadsFile);
}

async function writeNotificationReads(reads) {
  if (useSupabase) {
    await supabaseRequest('/rest/v1/notification_reads?notification_id=neq.__never__', {
      method: 'DELETE',
    });
    if (reads.length) {
      await supabaseRequest('/rest/v1/notification_reads', {
        method: 'POST',
        body: reads.map((item) => ({
          notification_id: item.notificationId || item.notification_id,
          user_id: item.userId || item.user_id,
          read_at: item.readAt || item.read_at || new Date().toISOString(),
        })),
      });
    }
    return;
  }

  await writeCollection(notificationReadsFile, reads);
}

async function readSupportMessages() {
  return readCollection(supportMessagesFile);
}

async function writeSupportMessages(messages) {
  await writeCollection(supportMessagesFile, messages);
}

function publicSupportMessage(message) {
  return {
    id: message.id,
    studentId: message.studentId || message.userId || '',
    studentName: message.studentName || message.userName || message.authorName || '',
    studentPhone: message.studentPhone || message.userPhone || '',
    message: message.message || message.text || message.body || message.content || '',
    answer: message.answer || '',
    sender: message.sender || 'student',
    status: message.status || 'open',
    readByAdmin: message.readByAdmin === true || message.readByAdmin === 'true' || message.read_by_admin === true || message.read_by_admin === 'true',
    readByStudent: message.readByStudent === true || message.readByStudent === 'true' || message.read_by_student === true || message.read_by_student === 'true',
    attachments: Array.isArray(message.attachments) ? message.attachments : [],
    createdAt: message.createdAt || message.created_at || message.timestamp || message.sentAt,
    answeredAt: message.answeredAt || message.answered_at || '',
    answeredBy: message.answeredBy || message.answered_by || '',
  };
}

async function readDeviceTokens() {
  return readCollection(deviceTokensFile);
}

async function writeDeviceTokens(tokens) {
  await writeCollection(deviceTokensFile, tokens);
}

async function readQuestions() {
  return readCollection(questionsFile);
}

async function writeQuestions(questions) {
  await writeCollection(questionsFile, questions);
}

async function readWatchProgress() {
  return readCollection(watchProgressFile);
}

async function writeWatchProgress(records) {
  await writeCollection(watchProgressFile, records);
}

async function readExams() {
  return readCollection(examsFile);
}

async function writeExams(exams) {
  await writeCollection(examsFile, exams);
}

async function readExamResults() {
  return readCollection(examResultsFile);
}

async function writeExamResults(results) {
  await writeCollection(examResultsFile, results);
}

async function readSupportMessages() {
  return readCollection(supportMessagesFile);
}

async function writeSupportMessages(messages) {
  await writeCollection(supportMessagesFile, messages);
}

async function readCommunityPosts() {
  return readCollection(communityPostsFile);
}

async function writeCommunityPosts(posts) {
  await writeCollection(communityPostsFile, posts);
}

async function readVocabularyWords() {
  return readCollection(vocabularyWordsFile);
}

async function writeVocabularyWords(words) {
  await writeCollection(vocabularyWordsFile, words);
}

async function readAudioResources() {
  return readCollection(audioResourcesFile);
}

async function writeAudioResources(resources) {
  await writeCollection(audioResourcesFile, resources);
}

async function readActivityLogs() {
  return readCollection(activityLogsFile);
}

async function writeActivityLogs(logs) {
  await writeCollection(activityLogsFile, logs);
}

async function readAppSessions() {
  return readCollection(appSessionsFile);
}

async function writeAppSessions(sessions) {
  await writeCollection(appSessionsFile, sessions);
}

function hashPassword(password) {
  const salt = crypto.randomBytes(16).toString('hex');
  const hash = crypto
    .pbkdf2Sync(password, salt, 100000, 64, 'sha512')
    .toString('hex');

  return `${salt}:${hash}`;
}

function verifyPassword(password, passwordHash) {
  const [salt, storedHash] = String(passwordHash || '').split(':');
  if (!salt || !storedHash) {
    return false;
  }

  const hash = crypto
    .pbkdf2Sync(password, salt, 100000, 64, 'sha512')
    .toString('hex');

  return crypto.timingSafeEqual(Buffer.from(hash), Buffer.from(storedHash));
}

function sendJson(response, statusCode, body) {
  response.writeHead(statusCode, {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,PATCH,DELETE,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
    Pragma: 'no-cache',
    Expires: '0',
    'Content-Type': 'application/json; charset=utf-8',
  });
  response.end(JSON.stringify(body));
}

function readBody(request) {
  return new Promise((resolve, reject) => {
    let body = '';

    request.on('data', (chunk) => {
      body += chunk;
      if (body.length > 120_000_000) {
        request.destroy();
        reject(new Error('Request body is too large.'));
      }
    });

    request.on('end', () => resolve(body));
    request.on('error', reject);
  });
}

function validateRegistration(payload, formConfig = defaultRegistrationForm) {
  const fields = normalizeRegistrationFormConfig(formConfig).fields;
  for (const field of fields) {
    if (!field.enabled || field.key === 'confirmPassword') {
      continue;
    }
    if (field.required && !String(payload[field.key] || '').trim()) {
      return 'Please fill in all fields.';
    }
    if (
      field.type === 'dropdown' &&
      field.options.length &&
      String(payload[field.key] || '').trim() &&
      !field.options.includes(String(payload[field.key]).trim())
    ) {
      return 'Please select a valid option.';
    }
  }

  if (String(payload.password).length < 6) {
    return 'Password must be at least 6 characters.';
  }

  if (!/^[0-9+\-\s]{8,20}$/.test(String(payload.phone))) {
    return 'Please enter a valid phone number.';
  }

  return null;
}

function validateUserPayload(payload, { requirePassword }) {
  const role = normalizeRole(payload.role);
  const validationError = validateRegistration({
    fullName: payload.fullName,
    phone: payload.phone,
    password: requirePassword ? payload.password : 'temporary-password',
    address: payload.address,
    job: payload.job,
    language: payload.language,
    learningReason: payload.learningReason,
    referralReason: payload.referralReason,
  }, defaultRegistrationForm);

  if (validationError) {
    return validationError;
  }

  if (role === 'admin' && !String(payload.phone || '').trim()) {
    return 'Please enter an admin phone or email.';
  }

  if (payload.password && String(payload.password).length < 6) {
    return 'Password must be at least 6 characters.';
  }

  return null;
}

function normalizeRole(role) {
  return role === 'admin' ? 'admin' : 'student';
}

function validateUserUpdatePayload(payload) {
  if (
    payload.password !== undefined &&
    String(payload.password || '').trim().length < 6
  ) {
    return 'Password must be at least 6 characters.';
  }

  if (
    payload.phone !== undefined &&
    !/^[0-9+\-\s]{8,20}$/.test(String(payload.phone))
  ) {
    return 'Please enter a valid phone number.';
  }

  const requiredWhenProvided = [
    'fullName',
    'address',
    'job',
    'language',
    'learningReason',
    'referralReason',
  ];

  for (const field of requiredWhenProvided) {
    if (payload[field] !== undefined && !String(payload[field]).trim()) {
      return 'Please fill in all fields.';
    }
  }

  return null;
}

function normalizeCourseNodeType(type) {
  return ['course', 'level', 'lecture', 'part'].includes(type) ? type : 'part';
}

function validateCoursePartPayload(payload) {
  const type = normalizeCourseNodeType(payload.type);
  const requiredFieldsByType = {
    course: ['language', 'course', 'courseLevel'],
    level: ['language', 'course', 'level'],
    lecture: ['language', 'course', 'level', 'lecture'],
    part: ['language', 'course', 'level', 'lecture', 'part', 'vimeoUrl', 'duration'],
  };
  const requiredFields = requiredFieldsByType[type];

  for (const field of requiredFields) {
    if (!String(payload[field] || '').trim()) {
      return 'Please fill in all course fields.';
    }
  }

  if (
    type === 'part' &&
    !/^https?:\/\/(www\.)?(vimeo\.com|player\.vimeo\.com)\//.test(
      String(payload.vimeoUrl)
    )
  ) {
    return 'Please enter a valid Vimeo link.';
  }

  if (type === 'part' && parseDurationToSeconds(payload.duration) === null) {
    return 'Please enter duration in hh:mm:ss format.';
  }

  if (type === 'course') {
    const courseType = normalizeCoursePaymentType(payload.courseType);
    if (
      courseType === 'paid' &&
      (!String(payload.price || '').trim() ||
        Number.isNaN(Number(payload.price)) ||
        Number(payload.price) < 0)
    ) {
      return 'Please enter a valid course price.';
    }
  }

  return null;
}

function normalizeCoursePaymentType(courseType) {
  return String(courseType || '').toLowerCase() === 'paid' ? 'paid' : 'free';
}

function normalizeNotificationType(type) {
  const value = String(type || '').trim().toLowerCase();
  return ['general', 'course', 'lesson', 'exam', 'payment'].includes(value)
    ? value
    : 'general';
}

function getFirebaseMessaging() {
  if (firebaseMessaging !== undefined) {
    return firebaseMessaging;
  }

  firebaseMessaging = null;

  if (!firebaseAdmin) {
    return firebaseMessaging;
  }

  try {
    if (!firebaseAdmin.apps.length) {
      let credentialConfig = null;
      const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
      if (serviceAccountJson) {
        credentialConfig = JSON.parse(serviceAccountJson);
      } else if (
        process.env.FIREBASE_PROJECT_ID &&
        process.env.FIREBASE_CLIENT_EMAIL &&
        process.env.FIREBASE_PRIVATE_KEY
      ) {
        credentialConfig = {
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, "\n"),
        };
      }

      if (!credentialConfig) {
        console.log('Firebase init error: missing service account env');
        return firebaseMessaging;
      }

      firebaseAdmin.initializeApp({
        credential: firebaseAdmin.credential.cert(credentialConfig),
      });
    }

    firebaseMessaging = firebaseAdmin.messaging();
  } catch (error) {
    console.log('Firebase init error:', error.message);
    firebaseMessaging = null;
  }

  return firebaseMessaging;
}

function normalizeCourseLevel(courseLevel) {
  const value = String(courseLevel || '').trim();
  return value || 'مبتدئ';
}

function normalizeLearningOutcomes(value) {
  if (Array.isArray(value)) {
    return value
      .map((item) => String(item || '').trim())
      .filter(Boolean);
  }

  return String(value || '')
    .split(/\r?\n/)
    .map((item) => item.trim())
    .filter(Boolean);
}

function parseDurationToSeconds(duration) {
  const match = String(duration || '').trim().match(/^(\d{2}):([0-5]\d):([0-5]\d)$/);
  if (!match) {
    return null;
  }
  return Number(match[1]) * 3600 + Number(match[2]) * 60 + Number(match[3]);
}

function formatDuration(totalSeconds) {
  const seconds = Math.max(0, Number(totalSeconds) || 0);
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const remainingSeconds = seconds % 60;
  return [hours, minutes, remainingSeconds]
    .map((value) => String(value).padStart(2, '0'))
    .join(':');
}

function publicCoursePart(part) {
  return {
    id: part.id,
    type: part.type || 'part',
    language: part.language,
    course: part.course,
    level: part.level || '',
    lecture: part.lecture || '',
    part: part.part || '',
    vimeoUrl: part.vimeoUrl || '',
    courseType: part.courseType || 'free',
    price: part.price || '',
    courseLevel: part.courseLevel || '',
    duration: part.duration || '',
    imageDataUrl: part.imageDataUrl || '',
    learningOutcomes: normalizeLearningOutcomes(part.learningOutcomes),
    createdAt: part.createdAt,
    createdBy: part.createdBy || 'Admin',
  };
}

function publicSubscription(subscription) {
  return {
    id: subscription.id,
    studentId: subscription.studentId,
    studentName: subscription.studentName,
    studentPhone: subscription.studentPhone,
    studentAddress: subscription.studentAddress || '',
    studentJob: subscription.studentJob || '',
    studentLanguage: subscription.studentLanguage || '',
    courseTitle: subscription.courseTitle,
    courseLanguage: subscription.courseLanguage,
    courseLevel: subscription.courseLevel || '',
    coursePrice: subscription.coursePrice || '',
    status: subscription.status || 'pending',
    requestedAt: subscription.requestedAt,
    approvedAt: subscription.approvedAt || null,
    approvedBy: subscription.approvedBy || '',
    paymentMethod: subscription.paymentMethod || '',
    paymentDate: subscription.paymentDate || '',
    paymentPhone: subscription.paymentPhone || '',
    paidAmount: subscription.paidAmount || '',
  };
}

function publicNotification(notification, options = {}) {
  const targetUserIds = Array.isArray(notification.targetUserIds)
    ? notification.targetUserIds
    : [];
  const targetPhones = Array.isArray(notification.targetPhones)
    ? notification.targetPhones
    : [];
  return {
    id: notification.id,
    title: notification.title,
    body: notification.body,
    type: notification.type || 'general',
    createdAt: notification.createdAt,
    createdBy: notification.createdBy || 'Admin',
    targetMode: notification.targetMode || (targetUserIds.length || targetPhones.length ? 'specific' : 'all'),
    targetUserIds,
    targetPhones,
    isRead: options.isRead === true,
  };
}

function publicCourseQuestion(question) {
  return {
    id: question.id,
    studentId: question.studentId || question.userId || '',
    studentName: question.studentName || question.userName || '',
    courseTitle: question.courseTitle || question.course_title || '',
    courseLanguage: question.courseLanguage || question.course_language || '',
    levelTitle: question.levelTitle || question.level_title || '',
    lectureTitle: question.lectureTitle || question.lessonTitle || question.lesson_title || '',
    partTitle: question.partTitle || question.part_title || '',
    vimeoUrl: question.vimeoUrl || question.vimeo_url || '',
    question: question.question || question.message || question.text || '',
    answer: question.answer || '',
    status: question.status || 'pending',
    attachments: Array.isArray(question.attachments) ? question.attachments : [],
    createdAt: question.createdAt || question.created_at,
    answeredAt: question.answeredAt || question.answered_at || '',
    answeredBy: question.answeredBy || question.answered_by || '',
  };
}

function publicSupportMessage(message) {
  const sender =
    message.sender || (message.answer && !message.message ? 'admin' : 'student');

  return {
    id: message.id,
    studentId: message.studentId || message.userId || message.senderId || '',
    studentName: message.studentName || message.userName || message.senderName || message.authorName || '',
    studentPhone: message.studentPhone || message.userPhone || '',
    sender,
    message: message.message || message.text || message.body || message.content || (sender === 'admin' ? message.answer || '' : ''),
    answer: message.answer || '',
    status: message.status || 'pending',
    readByAdmin: message.readByAdmin === true || message.readByAdmin === 'true' || message.read_by_admin === true || message.read_by_admin === 'true',
    readByStudent: message.readByStudent === true || message.readByStudent === 'true' || message.read_by_student === true || message.read_by_student === 'true',
    attachments: Array.isArray(message.attachments) ? message.attachments : [],
    createdAt: message.createdAt || message.created_at || message.timestamp || message.sentAt,
    answeredAt: message.answeredAt || message.answered_at || '',
    answeredBy: message.answeredBy || message.answered_by || '',
  };
}

function publicCommunityPost(post) {
  post = { ...post, authorName: post.authorName || post.studentName || post.userName };

  return {
    id: post.id,
    studentId: post.studentId || post.userId || '',
    authorName: post.authorName || 'مستخدم',
    message: post.message || post.content || post.text || '',
    attachments: Array.isArray(post.attachments) ? post.attachments : [],
    createdAt: post.createdAt || post.created_at || post.timestamp,
  };
}

function publicCommunityPostDetailed(post, viewerStudentId = '') {
  post = { ...post, authorName: post.authorName || post.studentName || post.userName };

  const reactions = post.reactions && typeof post.reactions === 'object'
    ? post.reactions
    : {};
  const comments = Array.isArray(post.comments) ? post.comments : [];
  const reactionValues = Object.values(reactions);
  return {
    id: post.id,
    studentId: post.studentId || post.userId || '',
    authorName: post.authorName || 'مستخدم',
    message: post.message || post.content || post.text || '',
    attachments: Array.isArray(post.attachments) ? post.attachments : [],
    createdAt: post.createdAt || post.created_at || post.timestamp,
    likesCount: reactionValues.filter((reaction) => reaction === 'like').length,
    dislikesCount: reactionValues.filter((reaction) => reaction === 'dislike').length,
    commentsCount: comments.length,
    sharesCount: Number(post.sharesCount || post.shares || 0),
    userReaction: viewerStudentId ? reactions[viewerStudentId] || '' : '',
    comments: comments.map((comment) => ({
      id: comment.id,
      studentId: comment.studentId || '',
      authorName: comment.authorName || 'مستخدم',
      message: comment.message || '',
      createdAt: comment.createdAt || '',
    })),
  };
}

function publicVocabularyWord(word) {
  return {
    id: word.id,
    word: word.word || '',
    meaning: word.meaning || '',
    pronunciation: word.pronunciation || '',
    example: word.example || '',
    languageCode: word.languageCode || 'en',
    course: word.course || '',
    courseLanguage: word.courseLanguage || '',
    level: word.level || '',
    lesson: word.lesson || '',
    translation: word.translation || '',
    createdAt: word.createdAt || '',
    createdBy: word.createdBy || 'Admin',
  };
}

function publicAudioResource(resource) {
  return {
    id: resource.id,
    title: resource.title || '',
    description: resource.description || '',
    course: resource.course || '',
    courseLanguage: resource.courseLanguage || '',
    level: resource.level || '',
    accessType: normalizeCoursePaymentType(resource.accessType),
    fileType: resource.fileType || 'audio',
    linkType: resource.linkType || 'clip',
    url: resource.url || '',
    items: Array.isArray(resource.items)
      ? resource.items.map((item) => ({
          id: item.id || crypto.randomUUID(),
          title: item.title || '',
          url: item.url || '',
          fileType: item.fileType || resource.fileType || 'audio',
          relativePath: item.relativePath || '',
        }))
      : [],
    createdAt: resource.createdAt || '',
    createdBy: resource.createdBy || 'Admin',
  };
}

async function withResolvedAudioItems(resource) {
  const existingItems = Array.isArray(resource.items) ? resource.items : [];
  if (existingItems.length > 0) {
    return resource;
  }

  const linkType = String(resource.linkType || 'clip').trim();
  const folderId = linkType === 'folder'
    ? parseGoogleDriveFolderId(resource.url)
    : '';
  if (!folderId || !googleDriveApiKey) {
    return resource;
  }

  try {
    const items = await listGoogleDriveFolderAudio(folderId);
    return items.length > 0 ? { ...resource, items } : resource;
  } catch {
    return resource;
  }
}

function publicWatchProgress(record) {
  return {
    id: record.id,
    studentId: record.studentId,
    studentName: record.studentName || '',
    studentPhone: record.studentPhone || '',
    courseTitle: record.courseTitle || '',
    courseLanguage: record.courseLanguage || '',
    levelTitle: record.levelTitle || '',
    lectureTitle: record.lectureTitle || '',
    partTitle: record.partTitle || '',
    vimeoUrl: record.vimeoUrl || '',
    duration: record.duration || '',
    completedAt: record.completedAt,
    watchDate: record.watchDate || String(record.completedAt || '').slice(0, 10),
    watchCount: Number(record.watchCount || 1),
  };
}

function normalizeExamType(type) {
  return String(type || '') === 'level_final' ? 'level_final' : 'lecture_quiz';
}

function normalizeQuestionType(type) {
  const value = String(type || '').trim();
  return ['mcq', 'true_false', 'complete', 'audio', 'video'].includes(value)
    ? value
    : 'mcq';
}

function publicExam(exam, { includeAnswers = false } = {}) {
  return {
    id: exam.id,
    title: exam.title || '',
    description: exam.description || '',
    type: normalizeExamType(exam.type),
    courseTitle: exam.courseTitle || '',
    courseLanguage: exam.courseLanguage || '',
    levelTitle: exam.levelTitle || '',
    afterLectureIndex: Number(exam.afterLectureIndex || 0),
    passScore: Number(exam.passScore || 60),
    durationMinutes: Number(exam.durationMinutes || 10),
    createdAt: exam.createdAt,
    createdBy: exam.createdBy || 'Admin',
    questions: (Array.isArray(exam.questions) ? exam.questions : []).map((question) => ({
      id: question.id,
      type: normalizeQuestionType(question.type),
      prompt: question.prompt || '',
      options: Array.isArray(question.options) ? question.options : [],
      correctAnswers: includeAnswers && Array.isArray(question.correctAnswers)
        ? question.correctAnswers
        : [],
    })),
  };
}

function publicExamResult(result) {
  return {
    id: result.id,
    examId: result.examId,
    studentId: result.studentId,
    studentName: result.studentName || '',
    courseTitle: result.courseTitle || '',
    courseLanguage: result.courseLanguage || '',
    levelTitle: result.levelTitle || '',
    type: normalizeExamType(result.type),
    score: Number(result.score || 0),
    totalQuestions: Number(result.totalQuestions || 0),
    correctAnswers: Number(result.correctAnswers || 0),
    passed: Boolean(result.passed),
    submittedAt: result.submittedAt,
  };
}

function readMoney(value) {
  const cleaned = String(value || '').replace(/[^\d.]/g, '');
  return Number(cleaned) || 0;
}

function parsePaymentDay(value) {
  const raw = String(value || '').trim();
  const iso = Date.parse(raw);
  if (!Number.isNaN(iso)) {
    return new Date(iso);
  }

  const match = raw.match(/^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$/);
  if (match) {
    return new Date(
      Number(match[3]),
      Number(match[2]) - 1,
      Number(match[1])
    );
  }

  return null;
}

function dateKey(value = new Date()) {
  const date = value instanceof Date ? value : new Date(value);
  return Number.isNaN(date.getTime()) ? '' : date.toISOString().slice(0, 10);
}

function monthKey(value = new Date()) {
  const date = value instanceof Date ? value : new Date(value);
  return Number.isNaN(date.getTime()) ? '' : date.toISOString().slice(0, 7);
}

function publicActivityLog(log) {
  return {
    id: log.id,
    userId: log.userId || '',
    userName: log.userName || '',
    userPhone: log.userPhone || '',
    action: log.action || '',
    label: log.label || '',
    details: log.details || '',
    createdAt: log.createdAt,
  };
}

async function recordActivity({
  userId = '',
  userName = '',
  userPhone = '',
  action = '',
  label = '',
  details = '',
} = {}) {
  const logs = await readActivityLogs();
  logs.unshift({
    id: crypto.randomUUID(),
    userId,
    userName,
    userPhone,
    action,
    label,
    details,
    createdAt: new Date().toISOString(),
  });
  await writeActivityLogs(logs.slice(0, 5000));
}

function publicDeviceToken(deviceToken) {
  return {
    id: deviceToken.id,
    userId: deviceToken.userId,
    role: deviceToken.role || 'student',
    token: deviceToken.token,
    platform: deviceToken.platform || 'unknown',
    createdAt: deviceToken.createdAt,
    updatedAt: deviceToken.updatedAt || deviceToken.createdAt,
  };
}

function courseKeyFor(language, courseTitle) {
  return `${String(language || '').trim()}|${String(courseTitle || '').trim()}`;
}

function buildUserFromPayload(payload, { createdBy = 'App' } = {}) {
  const extraFields = Object.fromEntries(
    Object.entries(payload)
      .filter(([key]) => !coreRegistrationKeys.has(key) && key !== 'role' && key !== 'status')
      .map(([key, value]) => [key, typeof value === 'string' ? value.trim() : value])
  );

  return {
    id: crypto.randomUUID(),
    fullName: String(payload.fullName || '').trim(),
    phone: String(payload.phone || '').replace(/\s/g, ''),
    passwordHash: hashPassword(String(payload.password || '')),
    address: String(payload.address || '').trim(),
    job: String(payload.job || '').trim(),
    language: String(payload.language || '').trim(),
    learningReason: String(payload.learningReason || '').trim(),
    referralReason: String(payload.referralReason || '').trim(),
    role: normalizeRole(payload.role),
    status: 'active',
    extraFields,
    createdAt: new Date().toISOString(),
    createdBy,
  };
}

function publicUser(user) {
  return {
    id: user.id,
    fullName: user.fullName,
    phone: user.phone,
    address: user.address,
    job: user.job,
    language: user.language,
    learningReason: user.learningReason,
    referralReason: user.referralReason,
    status: user.status || 'active',
    role: user.role || 'student',
    extraFields: user.extraFields && typeof user.extraFields === 'object' ? user.extraFields : {},
    createdAt: user.createdAt,
    createdBy: user.createdBy || 'App',
    enrollments: Array.isArray(user.enrollments) ? user.enrollments : [],
  };
}

function systemAdminUser() {
  return {
    id: 'system-admin',
    fullName: 'مدير النظام',
    phone: adminEmail,
    address: 'لوحة التحكم',
    job: 'إدارة',
    language: 'كل اللغات',
    learningReason: 'إدارة المنصة',
    referralReason: 'حساب افتراضي',
    status: 'active',
    role: 'admin',
    createdAt: null,
    createdBy: 'System',
  };
}

function getAdminSession(request) {
  const header = request.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  return adminSessions.get(token);
}

function requireAdmin(request, response) {
  const session = getAdminSession(request);
  if (session) {
    return session;
  }

  sendJson(response, 401, { message: 'غير مصرح بالدخول.' });
  return null;
}

async function getRegistrationForm(request, response) {
  try {
    const form = await readRegistrationFormConfig();
    sendJson(response, 200, { form });
  } catch {
    sendJson(response, 200, { form: defaultRegistrationForm });
  }
}

async function getAdminRegistrationForm(request, response) {
  if (!requireAdmin(request, response)) {
    return;
  }

  try {
    const form = await readRegistrationFormConfig();
    sendJson(response, 200, { form });
  } catch {
    sendJson(response, 500, { message: 'Unable to load registration form settings.' });
  }
}

async function updateAdminRegistrationForm(request, response) {
  if (!requireAdmin(request, response)) {
    return;
  }

  try {
    const payload = JSON.parse(await readBody(request));
    const form = normalizeRegistrationFormConfig(payload);
    await writeAppSetting(
      'registration_form',
      form,
      'Dynamic registration form configuration'
    );
    sendJson(response, 200, { form });
  } catch {
    sendJson(response, 400, { message: 'Unable to save registration form settings.' });
  }
}

async function register(request, response) {
  try {
    const payload = JSON.parse(await readBody(request));
    const formConfig = await readRegistrationFormConfig();
    const validationError = validateRegistration(payload, formConfig);

    if (validationError) {
      sendJson(response, 400, { message: validationError });
      return;
    }

    const users = await readUsers();
    const normalizedPhone = String(payload.phone).replace(/\s/g, '');
    const userExists = users.some((user) => user.phone === normalizedPhone);

    if (userExists) {
      sendJson(response, 409, {
        message: 'This phone number already has an account.',
      });
      return;
    }

    const user = buildUserFromPayload(payload, { createdBy: 'App' });
    user.phone = normalizedPhone;
    users.push(user);
    await writeUsers(users);
    await recordActivity({
      userId: user.id,
      userName: user.fullName || '',
      userPhone: user.phone || '',
      action: 'register',
      label: 'تسجيل حساب جديد',
      details: user.language || '',
    });

    await notifyAdmins(
      'تسجيل عميل جديد',
      `${user.fullName || 'طالب جديد'} سجل حساب جديد في Lingova.`,
      'admin_new_user'
    );

    sendJson(response, 201, {
      message: 'Account created successfully.',
      user: {
        id: user.id,
        fullName: user.fullName,
        phone: user.phone,
        language: user.language,
        enrollments: [],
      },
    });
  } catch {
    sendJson(response, 500, {
      message: 'Something went wrong while creating the account.',
    });
  }
}

async function login(request, response) {
  try {
    const payload = JSON.parse(await readBody(request));
    const phone = String(payload.phone || '').replace(/\s/g, '');
    const password = String(payload.password || '');

    if (!phone || !password) {
      sendJson(response, 400, {
        message: 'Please enter your phone and password.',
      });
      return;
    }

    const users = await readUsers();
    const user = users.find((currentUser) => currentUser.phone === phone);

    if (!user) {
      sendJson(response, 404, {
        message: 'انت مش مشترك، أنشئ حساب جديد.',
      });
      return;
    }

    if ((user.role || 'student') !== 'student') {
      sendJson(response, 403, {
        message: 'هذا الحساب مخصص للوحة التحكم فقط.',
      });
      return;
    }

    if ((user.status || 'active') === 'suspended') {
      sendJson(response, 403, {
        message: 'تم تعليق الدخول لهذا الحساب.',
      });
      return;
    }

    if (!verifyPassword(password, user.passwordHash)) {
      sendJson(response, 401, {
        message: 'حاول تكتب كلمة السر من جديد.',
      });
      return;
    }

    await recordActivity({
      userId: user.id,
      userName: user.fullName || '',
      userPhone: user.phone || '',
      action: 'login',
      label: 'تسجيل دخول',
      details: '',
    });

    sendJson(response, 200, {
      message: 'تم تسجيل الدخول بنجاح.',
      user: {
        id: user.id,
        fullName: user.fullName,
        phone: user.phone,
        language: user.language,
        enrollments: Array.isArray(user.enrollments) ? user.enrollments : [],
      },
    });
  } catch {
    sendJson(response, 500, {
      message: 'Something went wrong while logging in.',
    });
  }
}

async function getPublicUser(request, response, userId) {
  try {
    const users = await readUsers();
    const user = users.find((currentUser) => currentUser.id === userId);
    if (!user) {
      sendJson(response, 404, { message: 'بيانات الطالب غير موجودة.' });
      return;
    }
    sendJson(response, 200, { user: publicUser(user) });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل بيانات الطالب.' });
  }
}

async function adminLogin(request, response) {
  try {
    const payload = JSON.parse(await readBody(request));
    const email = String(payload.email || '').trim().toLowerCase();
    const password = String(payload.password || '');

    const users = await readUsers();
    const adminUser = users.find((user) => {
      const role = normalizeRole(user.role);
      const identifier = String(user.email || user.phone || '')
        .trim()
        .toLowerCase();
      return role === 'admin' && identifier === email;
    });

    const isDefaultAdmin =
      email === adminEmail.toLowerCase() && password === adminPassword;
    const isStoredAdmin =
      adminUser &&
      (adminUser.status || 'active') === 'active' &&
      verifyPassword(password, adminUser.passwordHash);

    if (!isDefaultAdmin && !isStoredAdmin) {
      sendJson(response, 401, { message: 'بيانات الأدمن غير صحيحة.' });
      return;
    }

    const token = crypto.randomBytes(32).toString('hex');
    const adminName = isStoredAdmin ? adminUser.fullName : 'Lingova Admin';
    adminSessions.set(token, {
      name: adminName,
      email: isStoredAdmin ? adminUser.phone : adminEmail,
    });

    sendJson(response, 200, {
      token,
      admin: {
        name: adminName,
        email: isStoredAdmin ? adminUser.phone : adminEmail,
      },
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر تسجيل دخول الأدمن.' });
  }
}

async function adminStats(request, response) {
  if (!requireAdmin(request, response)) {
    return;
  }

  try {
    const users = await readUsers();
    const courseParts = await readCourseParts();
    const subscriptions = await readSubscriptions();
    const sessions = await readAppSessions();
    const logs = await readActivityLogs();
    const students = users.filter((user) => normalizeRole(user.role) === 'student');
    const uniqueCourses = new Set(courseParts.map((part) => part.course));
    const registrationsByLanguage = students.reduce((result, user) => {
      const language = user.language || 'غير محدد';
      result[language] = (result[language] || 0) + 1;
      return result;
    }, {});
    const now = new Date();
    const today = dateKey(now);
    const thisMonth = monthKey(now);
    const approvedSubscriptions = subscriptions.filter(
      (subscription) => (subscription.status || 'pending') === 'approved'
    );
    const revenueByCourseMap = new Map();
    let totalRevenue = 0;
    let todayRevenue = 0;
    let monthRevenue = 0;

    for (const subscription of approvedSubscriptions) {
      const amount = readMoney(
        subscription.paidAmount || subscription.coursePrice
      );
      const paidAt =
        parsePaymentDay(subscription.approvedAt) ||
        parsePaymentDay(subscription.paymentDate) ||
        parsePaymentDay(subscription.requestedAt) ||
        now;
      const language = subscription.courseLanguage || 'غير محدد';
      const courseTitle = subscription.courseTitle || 'غير محدد';
      const key = `${language}|${courseTitle}`;
      const current = revenueByCourseMap.get(key) || {
        courseLanguage: language,
        courseTitle,
        purchasesCount: 0,
        collectedAmount: 0,
      };

      current.purchasesCount += 1;
      current.collectedAmount += amount;
      revenueByCourseMap.set(key, current);
      totalRevenue += amount;

      if (dateKey(paidAt) === today) {
        todayRevenue += amount;
      }
      if (monthKey(paidAt) === thisMonth) {
        monthRevenue += amount;
      }
    }

    const activeThreshold = Date.now() - 2 * 60 * 1000;
    const activeNowCount = sessions.filter((session) => {
      const lastSeen = Date.parse(session.lastSeenAt || '');
      return !Number.isNaN(lastSeen) && lastSeen >= activeThreshold;
    }).length;
    const opensTodayCount = logs.filter(
      (log) => log.action === 'app_open' && dateKey(new Date(log.createdAt)) === today
    ).length;

    sendJson(response, 200, {
      studentsCount: students.length,
      activeUsersCount: users.filter(
        (user) => (user.status || 'active') === 'active'
      ).length,
      suspendedUsersCount: users.filter((user) => user.status === 'suspended')
        .length,
      courseRegistrationsCount: students.filter((user) => user.language).length,
      coursesCount: uniqueCourses.size || availableCoursesCount,
      registrationsByLanguage,
      revenue: {
        total: totalRevenue,
        today: todayRevenue,
        month: monthRevenue,
        byCourse: Array.from(revenueByCourseMap.values()).sort(
          (a, b) => b.collectedAmount - a.collectedAmount
        ),
      },
      activity: {
        activeNowCount,
        opensTodayCount,
      },
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل إحصائيات الداشبورد.' });
  }
}

async function listCourseParts(request, response) {
  if (!requireAdmin(request, response)) {
    return;
  }

  try {
    const parts = await readCourseParts();
    sendJson(response, 200, { parts: parts.map(publicCoursePart) });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل الكورسات.' });
  }
}

async function listAdminBooks(request, response) {
  if (!requireAdmin(request, response)) {
    return;
  }

  try {
    const books = await readBooks();
    sendJson(response, 200, { books });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل الكتب.' });
  }
}

function normalizeIdList(value) {
  if (!Array.isArray(value)) {
    return [];
  }
  return [...new Set(value.map((item) => String(item || '').trim()).filter(Boolean))];
}

function normalizePhoneList(value) {
  return normalizeIdList(value).map(normalizePhone).filter(Boolean);
}

function notificationTargetsUser(notification, userId) {
  const targetMode = notification.targetMode || 'all';
  const targetUserIds = normalizeIdList(notification.targetUserIds);
  if (!userId || targetMode === 'all' || !targetUserIds.length) {
    return true;
  }
  return targetUserIds.includes(userId);
}

async function resolveNotificationTargets(payload) {
  const users = await readUsers();
  const students = users.filter((user) => String(user.role || 'student') !== 'admin');
  const targetMode = String(payload.targetMode || payload.target || 'all').trim();
  if (targetMode !== 'specific') {
    return {
      targetMode: 'all',
      targetUserIds: [],
      targetPhones: [],
      unmatchedPhones: [],
      users: students,
    };
  }

  const requestedIds = normalizeIdList(payload.targetUsers || payload.targetUserIds);
  const requestedPhones = normalizePhoneList(payload.targetPhones || payload.phones);
  const matchedUsers = new Map();

  for (const user of students) {
    if (requestedIds.includes(user.id)) {
      matchedUsers.set(user.id, user);
    }
  }

  const unmatchedPhones = [];
  for (const phone of requestedPhones) {
    const user = students.find((item) => normalizePhone(item.phone) === phone);
    if (user) {
      matchedUsers.set(user.id, user);
    } else {
      unmatchedPhones.push(phone);
    }
  }

  return {
    targetMode: 'specific',
    targetUserIds: [...matchedUsers.keys()],
    targetPhones: requestedPhones,
    unmatchedPhones,
    users: [...matchedUsers.values()],
  };
}

async function readNotificationReadIds(userId) {
  if (!userId) {
    return new Set();
  }

  if (useSupabase) {
    const rows = await supabaseRequest(
      `/rest/v1/notification_reads?user_id=eq.${encodeURIComponent(userId)}&select=notification_id`
    );
    return new Set((rows || []).map((item) => item.notification_id).filter(Boolean));
  }

  const reads = await readNotificationReads();
  return new Set(
    reads
      .filter((item) => String(item.userId || item.user_id || '') === userId)
      .map((item) => item.notificationId || item.notification_id)
      .filter(Boolean)
  );
}

async function markNotificationReadForUser(notificationId, userId) {
  const readAt = new Date().toISOString();
  if (useSupabase) {
    await supabaseRequest(
      `/rest/v1/notification_reads?notification_id=eq.${encodeURIComponent(notificationId)}&user_id=eq.${encodeURIComponent(userId)}`,
      { method: 'DELETE' }
    );
    await supabaseRequest('/rest/v1/notification_reads', {
      method: 'POST',
      body: {
        notification_id: notificationId,
        user_id: userId,
        read_at: readAt,
      },
    });
    return readAt;
  }

  const reads = await readNotificationReads();
  const existing = reads.find(
    (item) =>
      String(item.notificationId || item.notification_id || '') === notificationId &&
      String(item.userId || item.user_id || '') === userId
  );
  if (existing) {
    existing.readAt = existing.readAt || existing.read_at || readAt;
  } else {
    reads.push({ notificationId, userId, readAt });
  }
  await writeNotificationReads(reads);
  return readAt;
}

async function deleteNotificationReads(notificationId) {
  if (useSupabase) {
    await supabaseRequest(
      `/rest/v1/notification_reads?notification_id=eq.${encodeURIComponent(notificationId)}`,
      { method: 'DELETE' }
    );
    return;
  }

  const reads = await readNotificationReads();
  await writeNotificationReads(
    reads.filter((item) => String(item.notificationId || item.notification_id || '') !== notificationId)
  );
}

async function listNotifications(request, response, url) {
  try {
    const userId = String(url?.searchParams.get('userId') || '').trim();
    const unreadOnly = String(url?.searchParams.get('unreadOnly') || '') === 'true';
    const notifications = await readNotifications();
    const readIds = await readNotificationReadIds(userId);
    const filtered = notifications
      .filter((notification) => notificationTargetsUser(notification, userId))
      .filter((notification) => !unreadOnly || !readIds.has(notification.id));
    sendJson(response, 200, {
      notifications: filtered.map((notification) =>
        publicNotification(notification, { isRead: readIds.has(notification.id) })
      ),
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل التنبيهات.' });
  }
}

async function registerDeviceToken(request, response) {
  try {
    const payload = JSON.parse(await readBody(request));
    const userId = String(payload.userId || '').trim();
    const token = String(payload.token || '').trim();
    const platform = String(payload.platform || 'unknown').trim();
    const role = String(payload.role || 'student').trim() === 'admin'
      ? 'admin'
      : 'student';

    if (!userId || !token) {
      sendJson(response, 400, { message: 'بيانات الجهاز غير مكتملة.' });
      return;
    }

    const users = await readUsers();
    const user = users.find((currentUser) => currentUser.id === userId);
    const isSystemAdmin =
      role === 'admin' &&
      (userId === 'system-admin' ||
        userId === adminEmail ||
        userId === normalizePhone(adminEmail));
    if (!user && !isSystemAdmin) {
      sendJson(response, 404, { message: 'بيانات المستخدم غير موجودة.' });
      return;
    }

    const deviceTokens = await readDeviceTokens();
    const existing = deviceTokens.find((item) => item.token === token);
    if (existing) {
      existing.userId = userId;
      existing.role = role;
      existing.platform = platform;
      existing.userName = user?.fullName || (role === 'admin' ? 'Lingova Admin' : '');
      existing.userPhone = user?.phone || (role === 'admin' ? adminEmail : '');
      existing.updatedAt = new Date().toISOString();
    } else {
      deviceTokens.push({
        id: crypto.randomUUID(),
        userId,
        userName: user?.fullName || (role === 'admin' ? 'Lingova Admin' : ''),
        userPhone: user?.phone || (role === 'admin' ? adminEmail : ''),
        role,
        token,
        platform,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      });
    }

    await writeDeviceTokens(deviceTokens);
    sendJson(response, 200, { message: 'تم تسجيل الجهاز.', token: publicDeviceToken(existing || deviceTokens[deviceTokens.length - 1]) });
  } catch {
    sendJson(response, 500, { message: 'تعذر تسجيل الجهاز.' });
  }
}

async function sendPushNotification(notification) {
  const messaging = getFirebaseMessaging();
  if (!messaging) {
    return { sent: false, reason: 'firebase_unavailable' };
  }

  const deviceTokens = await readDeviceTokens();
  const tokens = deviceTokens
    .filter((item) => String(item.role || 'student').trim() !== 'admin')
    .map((item) => String(item.token || '').trim())
    .filter(Boolean);

  if (!tokens.length) {
    return { sent: false, reason: 'no_tokens' };
  }

  try {
    const result = await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: {
        notificationId: notification.id,
        type: notification.type || 'general',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'lingova_notifications',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    });

    const invalidTokens = [];
    result.responses.forEach((item, index) => {
      if (item.success) {
        return;
      }
      const code = item.error?.code || '';
      if (
        code.includes('registration-token-not-registered') ||
        code.includes('invalid-argument')
      ) {
        invalidTokens.push(tokens[index]);
      }
    });

    if (invalidTokens.length) {
      const nextTokens = deviceTokens.filter(
        (item) => !invalidTokens.includes(item.token)
      );
      await writeDeviceTokens(nextTokens);
    }

    return {
      sent: result.successCount > 0,
      successCount: result.successCount,
      failureCount: result.failureCount,
    };
  } catch {
    return { sent: false, reason: 'send_failed' };
  }
}

async function sendPushNotificationToUser(userId, notification) {
  const messaging = getFirebaseMessaging();
  if (!messaging) {
    return { sent: false, reason: 'firebase_unavailable' };
  }

  const deviceTokens = await readDeviceTokens();
  const tokens = deviceTokens
    .filter((item) => String(item.userId || '').trim() === String(userId).trim())
    .map((item) => String(item.token || '').trim())
    .filter(Boolean);

  if (!tokens.length) {
    return { sent: false, reason: 'no_tokens' };
  }

  try {
    const result = await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: {
        notificationId: notification.id,
        type: notification.type || 'general',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'lingova_notifications',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    });

    const invalidTokens = [];
    result.responses.forEach((item, index) => {
      if (item.success) {
        return;
      }
      const code = item.error?.code || '';
      if (
        code.includes('registration-token-not-registered') ||
        code.includes('invalid-argument')
      ) {
        invalidTokens.push(tokens[index]);
      }
    });

    if (invalidTokens.length) {
      const nextTokens = deviceTokens.filter(
        (item) => !invalidTokens.includes(item.token)
      );
      await writeDeviceTokens(nextTokens);
    }

    return {
      sent: result.successCount > 0,
      successCount: result.successCount,
      failureCount: result.failureCount,
    };
  } catch {
    return { sent: false, reason: 'send_failed' };
  }
}

async function sendPushNotificationToUsers(userIds, notification) {
  const uniqueUserIds = [...new Set(userIds.map((item) => String(item || '').trim()).filter(Boolean))];
  if (!uniqueUserIds.length) {
    return { sent: false, reason: 'no_target_users' };
  }

  const results = await Promise.all(
    uniqueUserIds.map((userId) => sendPushNotificationToUser(userId, notification))
  );
  const successCount = results.reduce((total, item) => total + Number(item.successCount || 0), 0);
  const failureCount = results.reduce((total, item) => total + Number(item.failureCount || 0), 0);
  const sent = results.some((item) => item.sent === true);
  return {
    sent,
    successCount,
    failureCount,
    reason: sent ? undefined : results[0]?.reason || 'send_failed',
  };
}

async function sendPushNotificationToAdmins(notification) {
  const messaging = getFirebaseMessaging();
  if (!messaging) {
    return { sent: false, reason: 'firebase_unavailable' };
  }

  const deviceTokens = await readDeviceTokens();
  const tokens = deviceTokens
    .filter((item) => String(item.role || '').trim() === 'admin')
    .map((item) => String(item.token || '').trim())
    .filter(Boolean);

  if (!tokens.length) {
    return { sent: false, reason: 'no_admin_tokens' };
  }

  try {
    const result = await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: {
        notificationId: notification.id || crypto.randomUUID(),
        type: notification.type || 'admin',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'lingova_notifications',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    });

    const invalidTokens = [];
    result.responses.forEach((item, index) => {
      if (item.success) {
        return;
      }
      const code = item.error?.code || '';
      if (
        code.includes('registration-token-not-registered') ||
        code.includes('invalid-argument')
      ) {
        invalidTokens.push(tokens[index]);
      }
    });

    if (invalidTokens.length) {
      const nextTokens = deviceTokens.filter(
        (item) => !invalidTokens.includes(item.token)
      );
      await writeDeviceTokens(nextTokens);
    }

    return {
      sent: result.successCount > 0,
      successCount: result.successCount,
      failureCount: result.failureCount,
    };
  } catch {
    return { sent: false, reason: 'send_failed' };
  }
}

async function notifyAdmins(title, body, type) {
  try {
    return await sendPushNotificationToAdmins({
      id: crypto.randomUUID(),
      title,
      body,
      type,
    });
  } catch {
    return { sent: false, reason: 'send_failed' };
  }
}

async function listSupportMessages(request, response, url) {
  try {
    const studentId = String(url.searchParams.get('studentId') || '').trim();

    if (!studentId) {
      sendJson(response, 400, { message: 'بيانات الطالب غير مكتملة.' });
      return;
    }

    const messages = await readSupportMessages();
    const filtered = messages.filter((item) => item.studentId === studentId);

    sendJson(response, 200, {
      messages: filtered.map(publicSupportMessage),
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل رسائل الدعم.' });
  }
}

async function createSupportMessage(request, response) {
  try {
    const payload = JSON.parse((await readBody(request)) || '{}');
    const studentId = String(payload.studentId || '').trim();
    const messageText = String(payload.message || '').trim();

    if (!studentId || !messageText) {
      sendJson(response, 400, { message: 'من فضلك اكتب الرسالة.' });
      return;
    }

    const users = await readUsers();
    const user = users.find((item) => item.id === studentId);

    if (!user) {
      sendJson(response, 404, { message: 'بيانات الطالب غير موجودة.' });
      return;
    }

    const messages = await readSupportMessages();

    const message = {
      id: crypto.randomUUID(),
      studentId,
      studentName: user.fullName || '',
      studentPhone: user.phone || '',
      message: messageText,
      answer: '',
      sender: 'student',
      status: 'open',
      createdAt: new Date().toISOString(),
      answeredAt: '',
      answeredBy: '',
    };

    messages.unshift(message);

    await writeSupportMessages(messages);

    sendJson(response, 201, {
      message: publicSupportMessage(message),
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر إرسال الرسالة.' });
  }
}

async function listAdminSupportMessages(request, response) {
  const adminSession = requireAdmin(request, response);

  if (!adminSession) {
    return;
  }

  try {
    const messages = await readSupportMessages();

    sendJson(response, 200, {
      messages: messages.map(publicSupportMessage),
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل رسائل الدعم.' });
  }
}

async function answerSupportMessage(request, response, messageId) {
  const adminSession = requireAdmin(request, response);

  if (!adminSession) {
    return;
  }

  try {
    const payload = JSON.parse((await readBody(request)) || '{}');
    const answer = String(payload.answer || '').trim();

    if (!answer) {
      sendJson(response, 400, { message: 'من فضلك اكتب الرد.' });
      return;
    }

    const messages = await readSupportMessages();

    const message = messages.find((item) => item.id === messageId);

    if (!message) {
      sendJson(response, 404, { message: 'الرسالة غير موجودة.' });
      return;
    }

    message.answer = answer;
    message.status = 'answered';
    message.answeredAt = new Date().toISOString();
    message.answeredBy = adminSession.name || 'Admin';

    await writeSupportMessages(messages);

    sendJson(response, 200, {
      message: publicSupportMessage(message),
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر إرسال الرد.' });
  }
}

async function sendAdminSupportMessage(request, response) {
  const adminSession = requireAdmin(request, response);

  if (!adminSession) {
    return;
  }

  try {
    const payload = JSON.parse((await readBody(request)) || '{}');

    const studentId = String(payload.studentId || '').trim();
    const studentPhone = String(
      payload.studentPhone || '',
    ).replace(/\s/g, '');

    const messageText = String(payload.message || '').trim();

    if ((!studentId && !studentPhone) || !messageText) {
      sendJson(response, 400, {
        message: 'بيانات الرسالة غير مكتملة.',
      });
      return;
    }

    const users = await readUsers();

    const user = studentId
      ? users.find((item) => item.id === studentId)
      : users.find((item) => normalizePhone(item.phone) === studentPhone);

    if (!user) {
      sendJson(response, 404, {
        message: 'الطالب غير موجود.',
      });
      return;
    }

    const messages = await readSupportMessages();

    const message = {
      id: crypto.randomUUID(),
      studentId: user.id,
      studentName: user.fullName || '',
      studentPhone: user.phone || '',
      message: messageText,
      answer: '',
      sender: 'admin',
      status: 'sent',
      readByAdmin: true,
      readByStudent: false,
      createdAt: new Date().toISOString(),
      answeredAt: '',
      answeredBy: adminSession.name || 'Admin',
    };

    messages.unshift(message);

    await writeSupportMessages(messages);

    sendJson(response, 201, {
      message: publicSupportMessage(message),
    });
  } catch {
    sendJson(response, 500, {
      message: 'تعذر إرسال رسالة الأدمن.',
    });
  }
}

async function listAdminNotifications(request, response) {
  if (!requireAdmin(request, response)) {
    return;
  }

  await listNotifications(request, response, new URL(request.url, `http://${request.headers.host || 'localhost'}`));
}

async function createNotification(request, response) {
  const adminSession = requireAdmin(request, response);
  if (!adminSession) {
    return;
  }

  try {
    const payload = JSON.parse(await readBody(request));
    const title = String(payload.title || '').trim();
    const body = String(payload.body || '').trim();

    if (!title || !body) {
      sendJson(response, 400, { message: 'من فضلك اكتب عنوان التنبيه والمحتوى.' });
      return;
    }

    const targets = await resolveNotificationTargets(payload);
    if (targets.targetMode === 'specific' && !targets.targetUserIds.length) {
      sendJson(response, 400, { message: 'Ù„Ù… ÙŠØªÙ… Ø§Ù„Ø¹Ø«ÙˆØ± Ø¹Ù„Ù‰ Ø·Ù„Ø§Ø¨ Ù…Ø·Ø§Ø¨Ù‚ÙŠÙ†.' });
      return;
    }

    const notifications = await readNotifications();
    const notification = {
      id: crypto.randomUUID(),
      title,
      body,
      type: normalizeNotificationType(payload.type),
      targetMode: targets.targetMode,
      targetUserIds: targets.targetUserIds,
      targetPhones: targets.targetPhones,
      unmatchedPhones: targets.unmatchedPhones,
      createdAt: new Date().toISOString(),
      createdBy: adminSession.name || 'Admin',
    };

    notifications.unshift(notification);
    await writeNotifications(notifications);
    const push = targets.targetMode === 'specific'
      ? await sendPushNotificationToUsers(targets.targetUserIds, notification)
      : await sendPushNotification(notification);
    sendJson(response, 201, {
      notification: publicNotification(notification),
      push,
      unmatchedPhones: targets.unmatchedPhones,
      matchedCount: targets.targetMode === 'specific'
        ? targets.targetUserIds.length
        : targets.users.length,
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر إرسال التنبيه.' });
  }
}

async function deleteNotification(request, response, notificationId) {
  if (!requireAdmin(request, response)) {
    return;
  }

  try {
    const notifications = await readNotifications();
    const nextNotifications = notifications.filter((item) => item.id !== notificationId);
    if (nextNotifications.length === notifications.length) {
      sendJson(response, 404, { message: 'التنبيه غير موجود.' });
      return;
    }

    await writeNotifications(nextNotifications);
    await deleteNotificationReads(notificationId);
    sendJson(response, 200, { success: true });
  } catch (err) {
    sendJson(response, 500, { message: 'تعذر حذف التنبيه.' });
  }
}

async function markNotificationRead(request, response, notificationId) {
  try {
    const payload = JSON.parse((await readBody(request)) || '{}');
    const userId = String(payload.userId || '').trim();
    if (!userId) {
      sendJson(response, 400, { message: 'بيانات الطالب غير مكتملة.' });
      return;
    }

    const notifications = await readNotifications();
    const notification = notifications.find((item) => item.id === notificationId);
    if (!notification || !notificationTargetsUser(notification, userId)) {
      sendJson(response, 404, { message: 'التنبيه غير موجود.' });
      return;
    }

    await markNotificationReadForUser(notificationId, userId);
    sendJson(response, 200, { success: true });
  } catch (err) {
    sendJson(response, 500, { message: 'تعذر تحديث حالة الإشعار.' });
  }
}

async function listNotificationReaders(request, response, notificationId) {
  const adminSession = requireAdmin(request, response);
  if (!adminSession) {
    return;
  }

  try {
    const reads = await readNotificationReads();
    const users = await readUsers();

    const matched = (reads || []).filter((r) => String(r.notificationId || r.notification_id || '') === String(notificationId));

    const readers = matched
      .map((r) => {
        const uid = String(r.userId || r.user_id || '');
        const user = users.find((u) => String(u.id || '') === uid) || {};
        return {
          id: uid,
          fullName:
            user.fullName || user.full_name || user.userName || user.user_name || user.name || '',
          phone: user.phone || user.userPhone || user.user_phone || '',
          readAt: r.readAt || r.read_at || r.readAt || r.read_at || '',
        };
      })
      .sort((a, b) => String(b.readAt || '').localeCompare(String(a.readAt || '')));

    sendJson(response, 200, { readers });
  } catch (err) {
    sendJson(response, 500, { message: 'تعذر تحميل قرّاء الإشعار.' });
  }
}

async function listPublicCourses(request, response) {
  try {
    const parts = await readCourseParts();
    const grouped = new Map();

    for (const part of parts) {
      if (!part.language || !part.course) {
        continue;
      }
      const key = `${part.language}|${part.course}`;
      if (!grouped.has(key)) {
        grouped.set(key, {
          language: part.language,
          course: part.course,
          courseType: part.courseType || 'free',
          price: part.price || '',
          courseLevel: part.courseLevel || '',
          imageDataUrl: part.imageDataUrl || '',
          learningOutcomes: [],
          levels: new Set(),
          lectures: new Set(),
          totalDurationSeconds: 0,
          parts: 0,
        });
      }
      const entry = grouped.get(key);
      if ((part.type || 'part') === 'course') {
        entry.courseType = part.courseType || 'free';
        entry.price = part.price || '';
        entry.courseLevel = part.courseLevel || entry.courseLevel;
        entry.imageDataUrl = part.imageDataUrl || entry.imageDataUrl;
        entry.learningOutcomes = normalizeLearningOutcomes(part.learningOutcomes);
      }
      if (part.level) {
        entry.levels.add(part.level);
      }
      if (part.lecture) {
        entry.lectures.add(part.lecture);
      }
      if ((part.type || 'part') === 'part') {
        entry.parts += 1;
        entry.totalDurationSeconds += parseDurationToSeconds(part.duration) || 0;
      }
    }

    const courses = [...grouped.values()].map((entry) => {
      const levels = [...entry.levels];
      const levelBadge = entry.courseLevel || levels[0] || 'Course';
      const lessonsTotal = entry.lectures.size || entry.parts || 0;
      return {
        title: entry.course,
        language: entry.language,
        levelBadge,
        level: levelBadge,
        levelsCount: levels.length,
        lessonsTotal,
        lessonsCount: `${lessonsTotal} درس`,
        duration: formatDuration(entry.totalDurationSeconds),
        imageDataUrl: entry.imageDataUrl || '',
        learningOutcomes: entry.learningOutcomes,
        price: entry.courseType === 'paid' ? entry.price : 'مجانا',
        courseType: entry.courseType,
        description: `كورس ${entry.course} في ${entry.language} من Lingova.`,
      };
    });

    sendJson(response, 200, { courses });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل الكورسات.' });
  }
}

async function listBooks(request, response) {
  try {
    const books = await readBooks();
    sendJson(response, 200, { books });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل الكتب.' });
  }
}

async function getStudentCourseContent(request, response, url) {
  try {
    const studentId = String(url.searchParams.get('studentId') || '').trim();
    const courseTitle = String(url.searchParams.get('courseTitle') || '').trim();
    const courseLanguage = String(url.searchParams.get('courseLanguage') || '').trim();
    const courseKey = courseKeyFor(courseLanguage, courseTitle);

    const users = await readUsers();
    const user = users.find((currentUser) => currentUser.id === studentId);
    const enrollments = Array.isArray(user?.enrollments) ? user.enrollments : [];
    const isEnrolled = enrollments.some(
      (enrollment) => enrollment.courseKey === courseKey
    );

    if (!isEnrolled) {
      sendJson(response, 403, { message: 'الكورس غير مفتوح لهذا الطالب.' });
      return;
    }

    const parts = await readCourseParts();
    const courseParts = parts.filter(
      (part) => part.course === courseTitle && part.language === courseLanguage
    );
    const levelsMap = new Map();

    for (const part of courseParts) {
      if (!part.level) {
        continue;
      }
      if (!levelsMap.has(part.level)) {
        levelsMap.set(part.level, new Map());
      }
      const lecturesMap = levelsMap.get(part.level);
      if (part.lecture && !lecturesMap.has(part.lecture)) {
        lecturesMap.set(part.lecture, []);
      }
      if ((part.type || 'part') === 'part' && part.lecture) {
        lecturesMap.get(part.lecture).push({
          title: part.part,
          vimeoUrl: part.vimeoUrl,
          duration: part.duration || '00:00:00',
        });
      }
    }

    const levels = [...levelsMap.entries()].map(([title, lecturesMap]) => ({
      title,
      lectures: [...lecturesMap.entries()].map(([lectureTitle, lectureParts]) => ({
        title: lectureTitle,
        parts: lectureParts,
      })),
    }));

    sendJson(response, 200, {
      course: {
        title: courseTitle,
        language: courseLanguage,
        levels,
      },
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل محتوى الكورس.' });
  }
}

async function listStudentQuestions(request, response, url) {
  try {
    const studentId = String(url.searchParams.get('studentId') || '').trim();
    const courseTitle = String(url.searchParams.get('courseTitle') || '').trim();
    const courseLanguage = String(url.searchParams.get('courseLanguage') || '').trim();

    if (!studentId || !courseTitle || !courseLanguage) {
      sendJson(response, 400, { message: 'بيانات الأسئلة غير مكتملة.' });
      return;
    }

    const users = await readUsers();
    const user = users.find((currentUser) => currentUser.id === studentId);
    const enrollments = Array.isArray(user?.enrollments) ? user.enrollments : [];
    const courseKey = courseKeyFor(courseLanguage, courseTitle);
    const isEnrolled = enrollments.some(
      (enrollment) => enrollment.courseKey === courseKey
    );

    if (!isEnrolled) {
      sendJson(response, 403, { message: 'الكورس غير مفتوح لهذا الطالب.' });
      return;
    }

    const questions = await readQuestions();
    const studentQuestions = questions.filter(
      (question) =>
        question.studentId === studentId &&
        question.courseTitle === courseTitle &&
        question.courseLanguage === courseLanguage
    );

    sendJson(response, 200, {
      questions: studentQuestions.map(publicCourseQuestion),
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل الأسئلة.' });
  }
}

async function listStudentWatchProgress(request, response, url) {
  try {
    const studentId = String(url.searchParams.get('studentId') || '').trim();
    const courseTitle = String(url.searchParams.get('courseTitle') || '').trim();
    const courseLanguage = String(url.searchParams.get('courseLanguage') || '').trim();

    if (!studentId || !courseTitle || !courseLanguage) {
      sendJson(response, 400, { message: 'بيانات المشاهدة غير مكتملة.' });
      return;
    }

    const records = await readWatchProgress();
    const filtered = records.filter(
      (record) =>
        record.studentId === studentId &&
        record.courseTitle === courseTitle &&
        record.courseLanguage === courseLanguage
    );

    sendJson(response, 200, {
      records: filtered.map(publicWatchProgress),
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل سجل المشاهدة.' });
  }
}

async function completePartWatch(request, response) {
  try {
    const payload = JSON.parse((await readBody(request)) || '{}');
    const studentId = String(payload.studentId || '').trim();
    const courseTitle = String(payload.courseTitle || '').trim();
    const courseLanguage = String(payload.courseLanguage || '').trim();
    const levelTitle = String(payload.levelTitle || '').trim();
    const lectureTitle = String(payload.lectureTitle || '').trim();
    const partTitle = String(payload.partTitle || '').trim();
    const vimeoUrl = String(payload.vimeoUrl || '').trim();
    const duration = String(payload.duration || '').trim();

    if (
      !studentId ||
      !courseTitle ||
      !courseLanguage ||
      !levelTitle ||
      !lectureTitle ||
      !partTitle ||
      !vimeoUrl
    ) {
      sendJson(response, 400, { message: 'بيانات المشاهدة غير مكتملة.' });
      return;
    }

    const users = await readUsers();
    const user = users.find((currentUser) => currentUser.id === studentId);
    if (!user) {
      sendJson(response, 404, { message: 'بيانات الطالب غير موجودة.' });
      return;
    }

    const courseKey = courseKeyFor(courseLanguage, courseTitle);
    const enrollments = Array.isArray(user.enrollments) ? user.enrollments : [];
    const isEnrolled = enrollments.some(
      (enrollment) => enrollment.courseKey === courseKey
    );
    if (!isEnrolled) {
      sendJson(response, 403, { message: 'الكورس غير مفتوح لهذا الطالب.' });
      return;
    }

    const now = new Date();
    const completedAt = now.toISOString();
    const watchDate = completedAt.slice(0, 10);
    const records = await readWatchProgress();
    const existing = records.find(
      (record) =>
        record.studentId === studentId &&
        record.courseTitle === courseTitle &&
        record.courseLanguage === courseLanguage &&
        record.vimeoUrl === vimeoUrl &&
        record.watchDate === watchDate
    );

    if (existing) {
      existing.completedAt = completedAt;
      existing.duration = duration || existing.duration || '';
      existing.watchCount = Number(existing.watchCount || 1) + 1;
    } else {
      records.unshift({
        id: crypto.randomUUID(),
        studentId,
        studentName: user.fullName || '',
        studentPhone: user.phone || '',
        courseTitle,
        courseLanguage,
        levelTitle,
        lectureTitle,
        partTitle,
        vimeoUrl,
        duration,
        completedAt,
        watchDate,
        watchCount: 1,
      });
    }

    await writeWatchProgress(records);
    await recordActivity({
      userId: user.id,
      userName: user.fullName || '',
      userPhone: user.phone || '',
      action: 'watch_part',
      label: 'مشاهدة جزء كامل',
      details: `${courseLanguage} - ${courseTitle} - ${levelTitle} - ${lectureTitle} - ${partTitle}`,
    });
    sendJson(response, 200, {
      record: publicWatchProgress(existing || records[0]),
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر تسجيل مشاهدة الجزء.' });
  }
}

async function listAdminWatchReport(request, response, url) {
  if (!requireAdmin(request, response)) {
    return;
  }

  try {
    const today = new Date().toISOString().slice(0, 10);
    const requestedDate = String(url.searchParams.get('date') || today).trim();
    const date = /^\d{4}-\d{2}-\d{2}$/.test(requestedDate)
      ? requestedDate
      : today;
    const records = await readWatchProgress();
    const filtered = records
      .filter((record) => (record.watchDate || '').slice(0, 10) === date)
      .sort((a, b) => String(b.completedAt || '').localeCompare(String(a.completedAt || '')));
    const uniqueStudents = new Set(filtered.map((record) => record.studentId));
    const uniqueCourses = new Set(
      filtered.map((record) => `${record.courseLanguage}|${record.courseTitle}`)
    );

    sendJson(response, 200, {
      date,
      summary: {
        completedPartsCount: filtered.length,
        studentsCount: uniqueStudents.size,
        coursesCount: uniqueCourses.size,
        totalWatchCount: filtered.reduce(
          (sum, record) => sum + Number(record.watchCount || 1),
          0
        ),
      },
      records: filtered.map(publicWatchProgress),
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل تقرير المشاهدة.' });
  }
}

async function listAdminExams(request, response) {
  if (!requireAdmin(request, response)) {
    return;
  }

  try {
    const exams = await readExams();
    sendJson(response, 200, {
      exams: exams.map((exam) => publicExam(exam, { includeAnswers: true })),
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل الامتحانات.' });
  }
}

async function listAdminExamResults(request, response) {
  if (!requireAdmin(request, response)) {
    return;
  }

  try {
    const results = await readExamResults();
    const attemptsCount = results.length;
    const passedCount = results.filter((result) => Boolean(result.passed)).length;
    const totalScore = results.reduce(
      (sum, result) => sum + Number(result.score || 0),
      0
    );
    const averageScore = attemptsCount
      ? Math.round(totalScore / attemptsCount)
      : 0;

    sendJson(response, 200, {
      summary: {
        attemptsCount,
        passedCount,
        failedCount: attemptsCount - passedCount,
        averageScore,
      },
      results: results.map(publicExamResult),
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل تقارير الامتحانات.' });
  }
}

async function createAdminExam(request, response) {
  const adminSession = requireAdmin(request, response);
  if (!adminSession) {
    return;
  }

  try {
    const payload = JSON.parse((await readBody(request)) || '{}');
    const type = normalizeExamType(payload.type);
    const title = String(payload.title || '').trim();
    const courseTitle = String(payload.courseTitle || '').trim();
    const courseLanguage = String(payload.courseLanguage || '').trim();
    const levelTitle = String(payload.levelTitle || '').trim();
    const afterLectureIndex = Number(payload.afterLectureIndex || 0);
    const questionsPayload = Array.isArray(payload.questions) ? payload.questions : [];

    if (!title || !courseTitle || !courseLanguage || !levelTitle) {
      sendJson(response, 400, { message: 'من فضلك املأ بيانات الامتحان.' });
      return;
    }

    if (type === 'lecture_quiz' && (!afterLectureIndex || afterLectureIndex < 1)) {
      sendJson(response, 400, { message: 'حدد مكان الكويز بعد أي محاضرة.' });
      return;
    }

    const questions = questionsPayload.map((item) => {
      const questionType = normalizeQuestionType(item.type);
      return {
        id: crypto.randomUUID(),
        type: questionType,
        prompt: String(item.prompt || '').trim(),
        options: Array.isArray(item.options)
          ? item.options.map((option) => String(option || '').trim()).filter(Boolean)
          : [],
        correctAnswers: Array.isArray(item.correctAnswers)
          ? item.correctAnswers.map((answer) => String(answer || '').trim()).filter(Boolean)
          : [],
      };
    });

    if (questions.some((question) => !question.prompt || !question.correctAnswers.length)) {
      sendJson(response, 400, { message: 'راجع نصوص الأسئلة والإجابات الصحيحة.' });
      return;
    }

    const exams = await readExams();
    const exam = {
      id: crypto.randomUUID(),
      title,
      description: String(payload.description || '').trim(),
      type,
      courseTitle,
      courseLanguage,
      levelTitle,
      afterLectureIndex: type === 'lecture_quiz' ? afterLectureIndex : 0,
      passScore: Math.min(100, Math.max(1, Number(payload.passScore || 60))),
      durationMinutes: Math.max(1, Number(payload.durationMinutes || 10)),
      questions,
      createdAt: new Date().toISOString(),
      createdBy: adminSession.name || 'Admin',
    };

    exams.unshift(exam);
    await writeExams(exams);
    sendJson(response, 201, { exam: publicExam(exam, { includeAnswers: true }) });
  } catch {
    sendJson(response, 500, { message: 'تعذر إنشاء الامتحان.' });
  }
}

async function updateAdminExamQuestions(request, response, examId) {
  if (!requireAdmin(request, response)) {
    return;
  }

  try {
    const payload = JSON.parse((await readBody(request)) || '{}');
    const questionsPayload = Array.isArray(payload.questions) ? payload.questions : [];
    const questions = questionsPayload.map((item) => {
      const questionType = normalizeQuestionType(item.type);
      return {
        id: String(item.id || '').trim() || crypto.randomUUID(),
        type: questionType,
        prompt: String(item.prompt || '').trim(),
        options: Array.isArray(item.options)
          ? item.options.map((option) => String(option || '').trim()).filter(Boolean)
          : [],
        correctAnswers: Array.isArray(item.correctAnswers)
          ? item.correctAnswers.map((answer) => String(answer || '').trim()).filter(Boolean)
          : [],
      };
    });

    if (questions.some((question) => !question.prompt || !question.correctAnswers.length)) {
      sendJson(response, 400, { message: 'راجع نصوص الأسئلة والإجابات الصحيحة.' });
      return;
    }

    const exams = await readExams();
    const exam = exams.find((item) => item.id === examId);
    if (!exam) {
      sendJson(response, 404, { message: 'الامتحان غير موجود.' });
      return;
    }

    exam.questions = questions;
    await writeExams(exams);
    sendJson(response, 200, { exam: publicExam(exam, { includeAnswers: true }) });
  } catch {
    sendJson(response, 500, { message: 'تعذر حفظ أسئلة الامتحان.' });
  }
}

async function deleteAdminExam(request, response, examId) {
  if (!requireAdmin(request, response)) {
    return;
  }

  try {
    const exams = await readExams();
    const nextExams = exams.filter((exam) => exam.id !== examId);
    if (nextExams.length === exams.length) {
      sendJson(response, 404, { message: 'الامتحان غير موجود.' });
      return;
    }
    await writeExams(nextExams);
    sendJson(response, 200, { message: 'تم حذف الامتحان.' });
  } catch {
    sendJson(response, 500, { message: 'تعذر حذف الامتحان.' });
  }
}

async function listStudentExams(request, response, url) {
  try {
    const studentId = String(url.searchParams.get('studentId') || '').trim();
    const exams = await readExams();
    const results = await readExamResults();
    const studentResults = results.filter((result) => result.studentId === studentId);
    sendJson(response, 200, {
      exams: exams.map((exam) => publicExam(exam)),
      results: studentResults.map(publicExamResult),
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل الامتحانات.' });
  }
}

function isAnswerCorrect(question, answers) {
  const correct = (question.correctAnswers || []).map((value) =>
    String(value || '').trim().toLowerCase()
  );
  const given = (Array.isArray(answers) ? answers : [answers]).map((value) =>
    String(value || '').trim().toLowerCase()
  );

  return correct.length > 0 && given.length > 0 && correct[0] === given[0];
}

async function submitStudentExam(request, response, examId) {
  try {
    const payload = JSON.parse((await readBody(request)) || '{}');
    const studentId = String(payload.studentId || '').trim();
    const answers = payload.answers && typeof payload.answers === 'object'
      ? payload.answers
      : {};

    const exams = await readExams();
    const exam = exams.find((item) => item.id === examId);
    if (!exam) {
      sendJson(response, 404, { message: 'الامتحان غير موجود.' });
      return;
    }

    const users = await readUsers();
    const user = users.find((item) => item.id === studentId);
    if (!user) {
      sendJson(response, 404, { message: 'بيانات الطالب غير موجودة.' });
      return;
    }

    const questions = Array.isArray(exam.questions) ? exam.questions : [];
    const correctAnswers = questions.filter((question) =>
      isAnswerCorrect(question, answers[question.id])
    ).length;
    const totalQuestions = Math.max(1, questions.length);
    const score = Math.round((correctAnswers / totalQuestions) * 100);
    const passed = score >= Number(exam.passScore || 60);
    const result = {
      id: crypto.randomUUID(),
      examId: exam.id,
      studentId,
      studentName: user.fullName || '',
      courseTitle: exam.courseTitle,
      courseLanguage: exam.courseLanguage,
      levelTitle: exam.levelTitle,
      type: normalizeExamType(exam.type),
      score,
      totalQuestions,
      correctAnswers,
      passed,
      submittedAt: new Date().toISOString(),
    };

    const results = await readExamResults();
    results.unshift(result);
    await writeExamResults(results);
    await recordActivity({
      userId: user.id,
      userName: user.fullName || '',
      userPhone: user.phone || '',
      action: 'exam_submit',
      label: 'إنهاء امتحان',
      details: `${exam.title || ''} - ${score}% - ${passed ? 'ناجح' : 'لم ينجح'}`,
    });
    sendJson(response, 200, { result: publicExamResult(result) });
  } catch {
    sendJson(response, 500, { message: 'تعذر إرسال الامتحان.' });
  }
}

async function createStudentQuestion(request, response) {
  try {
    const payload = JSON.parse(await readBody(request));
    const studentId = String(payload.studentId || '').trim();
    const courseTitle = String(payload.courseTitle || '').trim();
    const courseLanguage = String(payload.courseLanguage || '').trim();
    const questionText = String(payload.question || '').trim();

    if (!studentId || !courseTitle || !courseLanguage || !questionText) {
      sendJson(response, 400, { message: 'من فضلك اكتب السؤال.' });
      return;
    }

    const users = await readUsers();
    const user = users.find((currentUser) => currentUser.id === studentId);
    if (!user || normalizeRole(user.role) !== 'student') {
      sendJson(response, 404, { message: 'بيانات الطالب غير موجودة.' });
      return;
    }

    const enrollments = Array.isArray(user.enrollments) ? user.enrollments : [];
    const courseKey = courseKeyFor(courseLanguage, courseTitle);
    const isEnrolled = enrollments.some(
      (enrollment) => enrollment.courseKey === courseKey
    );

    if (!isEnrolled) {
      sendJson(response, 403, { message: 'الكورس غير مفتوح لهذا الطالب.' });
      return;
    }

    const questions = await readQuestions();
    const question = {
      id: crypto.randomUUID(),
      studentId,
      studentName: user.fullName || '',
      studentPhone: user.phone || '',
      courseTitle,
      courseLanguage,
      levelTitle: String(payload.levelTitle || '').trim(),
      lectureTitle: String(payload.lectureTitle || '').trim(),
      partTitle: String(payload.partTitle || '').trim(),
      vimeoUrl: String(payload.vimeoUrl || '').trim(),
      question: questionText,
      answer: '',
      status: 'pending',
      createdAt: new Date().toISOString(),
      answeredAt: '',
      answeredBy: '',
    };

    questions.unshift(question);
    await writeQuestions(questions);
    await recordActivity({
      userId: user.id,
      userName: user.fullName || '',
      userPhone: user.phone || '',
      action: 'ask_question',
      label: 'إضافة سؤال',
      details: `${courseLanguage} - ${courseTitle} - ${questionText}`,
    });
    sendJson(response, 201, { question: publicCourseQuestion(question) });
  } catch {
    sendJson(response, 500, { message: 'تعذر إرسال السؤال.' });
  }
}

async function listAdminQuestions(request, response) {
  const adminSession = requireAdmin(request, response);
  if (!adminSession) {
    return;
  }

  try {
    const questions = await readQuestions();
    sendJson(response, 200, { questions: questions.map(publicCourseQuestion) });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل أسئلة الطلاب.' });
  }
}

async function answerQuestion(request, response, questionId) {
  const adminSession = requireAdmin(request, response);
  if (!adminSession) {
    return;
  }

  try {
    const payload = JSON.parse(await readBody(request));
    const answer = String(payload.answer || '').trim();
    if (!answer) {
      sendJson(response, 400, { message: 'من فضلك اكتب الرد.' });
      return;
    }

    const questions = await readQuestions();
    const question = questions.find((item) => item.id === questionId);
    if (!question) {
      sendJson(response, 404, { message: 'السؤال غير موجود.' });
      return;
    }

    question.answer = answer;
    question.status = 'answered';
    question.answeredAt = new Date().toISOString();
    question.answeredBy = adminSession.name || 'Admin';

    await writeQuestions(questions);
    sendJson(response, 200, { question: publicCourseQuestion(question) });
  } catch {
    sendJson(response, 500, { message: 'تعذر حفظ الرد.' });
  }
}

async function listStudentSupportMessages(request, response, url) {
  try {
    const studentId = String(url.searchParams.get('studentId') || '').trim();

    if (!studentId) {
      sendJson(response, 400, { message: 'بيانات المستخدم غير مكتملة.' });
      return;
    }

    const messages = await readSupportMessages();
    const studentMessages = messages.filter(
      (item) => String(item.studentId || '').trim() === studentId
    );

    sendJson(response, 200, {
      messages: studentMessages.map(publicSupportMessage),
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل رسائل الدعم.' });
  }
}

async function createSupportMessage(request, response) {
  try {
    const payload = JSON.parse(await readBody(request));
    const studentId = String(payload.studentId || '').trim();
    const messageText = String(payload.message || '').trim();

    if (!studentId || !messageText) {
      sendJson(response, 400, { message: 'من فضلك اكتب رسالتك.' });
      return;
    }

    const users = await readUsers();
    const user = users.find((currentUser) => currentUser.id === studentId);
    if (!user || normalizeRole(user.role) !== 'student') {
      sendJson(response, 404, { message: 'بيانات الطالب غير موجودة.' });
      return;
    }

    const messages = await readSupportMessages();
    const supportMessage = {
      id: crypto.randomUUID(),
      studentId,
      studentName: user.fullName || '',
      studentPhone: user.phone || '',
      sender: 'student',
      message: messageText,
      answer: '',
      status: 'pending',
      readByAdmin: false,
      readByStudent: true,
      createdAt: new Date().toISOString(),
      answeredAt: '',
      answeredBy: '',
    };

    messages.unshift(supportMessage);
    await writeSupportMessages(messages);
    try {
      await recordActivity({
        userId: user.id,
        userName: user.fullName || '',
        userPhone: user.phone || '',
        action: 'support_message',
        label: 'طلب دعم مباشر',
        details: messageText,
      });
    } catch (error) {
      console.log('Support activity log error:', error.message);
    }

    await notifyAdmins(
      'رسالة شات جديدة',
      `${user.fullName || 'طالب'} أرسل رسالة دعم جديدة.`,
      'admin_new_chat'
    );

    sendJson(response, 201, { message: publicSupportMessage(supportMessage) });
  } catch {
    sendJson(response, 500, { message: 'تعذر إرسال رسالة الدعم.' });
  }
}

async function listAdminSupportMessages(request, response) {
  const adminSession = requireAdmin(request, response);
  if (!adminSession) {
    return;
  }

  try {
    const messages = await readSupportMessages();
    sendJson(response, 200, {
      messages: messages.map(publicSupportMessage),
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل رسائل الدعم.' });
  }
}

async function createAdminSupportMessage(request, response) {
  const adminSession = requireAdmin(request, response);
  if (!adminSession) {
    return;
  }

  try {
    const payload = JSON.parse(await readBody(request));
    const studentId = String(payload.studentId || '').trim();
    const studentPhone = normalizePhone(payload.studentPhone || '');
    const message = String(payload.message || '').trim();

    if ((!studentId && !studentPhone) || !message) {
      sendJson(response, 400, { message: 'من فضلك اكتب رقم الهاتف والنص.' });
      return;
    }

    const users = await readUsers();
    const student = studentId
      ? users.find((user) => user.id === studentId)
      : users.find((user) => normalizePhone(user.phone) === studentPhone);
    if (!student || normalizeRole(student.role) !== 'student') {
      sendJson(response, 404, { message: 'الطالب غير موجود.' });
      return;
    }

    const messages = await readSupportMessages();
    const supportMessage = {
      id: crypto.randomUUID(),
      studentId: student.id,
      studentName: student.fullName || '',
      studentPhone: student.phone || '',
      sender: 'admin',
      message,
      answer: '',
      status: 'sent',
      readByAdmin: true,
      readByStudent: false,
      createdAt: new Date().toISOString(),
      answeredAt: '',
      answeredBy: adminSession.name || 'Admin',
    };

    messages.unshift(supportMessage);
    await writeSupportMessages(messages);
    try {
      await recordActivity({
        userId: student.id,
        userName: student.fullName || '',
        userPhone: student.phone || '',
        action: 'support_message',
        label: 'رسالة من الإدارة إلى الطالب',
        details: message,
      });
    } catch (error) {
      console.log('Support activity log error:', error.message);
    }

    try {
      await sendPushNotificationToUser(student.id, {
        id: crypto.randomUUID(),
        title: 'رسالة جديدة من الدعم',
        body: message,
        type: 'support',
      });
    } catch (error) {
      console.log('Support push notification error:', error.message);
    }

    sendJson(response, 201, { message: publicSupportMessage(supportMessage) });
  } catch {
    sendJson(response, 500, { message: 'تعذر إرسال الرسالة.' });
  }
}

async function markAdminSupportMessagesRead(request, response) {
  const adminSession = requireAdmin(request, response);
  if (!adminSession) {
    return;
  }

  try {
    const payload = JSON.parse((await readBody(request)) || '{}');
    const studentId = String(payload.studentId || '').trim();

    if (!studentId) {
      sendJson(response, 400, { message: 'Student data is missing.' });
      return;
    }

    const messages = await readSupportMessages();
    let changed = false;

    for (const message of messages) {
      if (
        message.studentId === studentId &&
        (message.sender || 'student') === 'student'
      ) {
        if (message.readByAdmin !== true) {
          message.readByAdmin = true;
          changed = true;
        }
      }
    }

    if (changed) {
      await writeSupportMessages(messages);
    }

    sendJson(response, 200, { message: 'Messages marked as read.' });
  } catch {
    sendJson(response, 500, { message: 'Could not mark messages as read.' });
  }
}

async function answerSupportMessage(request, response, messageId) {
  const adminSession = requireAdmin(request, response);
  if (!adminSession) {
    return;
  }

  try {
    const payload = JSON.parse(await readBody(request));
    const answer = String(payload.answer || '').trim();
    if (!answer) {
      sendJson(response, 400, { message: 'من فضلك اكتب الرد.' });
      return;
    }

    const messages = await readSupportMessages();
    const supportMessage = messages.find((item) => item.id === messageId);
    if (!supportMessage) {
      sendJson(response, 404, { message: 'رسالة الدعم غير موجودة.' });
      return;
    }

    supportMessage.answer = answer;
    supportMessage.status = 'answered';
    supportMessage.answeredAt = new Date().toISOString();
    supportMessage.answeredBy = adminSession.name || 'Admin';

    await writeSupportMessages(messages);
    await recordActivity({
      userId: supportMessage.studentId || '',
      userName: supportMessage.studentName || '',
      userPhone: '',
      action: 'support_answer',
      label: 'رد على رسالة دعم',
      details: answer,
    });

    await sendPushNotificationToUser(supportMessage.studentId, {
      id: crypto.randomUUID(),
      title: 'تم الرد على طلب الدعم',
      body: 'يمكنك الاطلاع على الرد في صفحة الشات المباشر.',
      type: 'support',
    });

    sendJson(response, 200, { message: publicSupportMessage(supportMessage) });
  } catch {
    sendJson(response, 500, { message: 'تعذر حفظ الرد.' });
  }
}

async function listCommunityPosts(request, response) {
  try {
    const url = new URL(request.url, `http://${request.headers.host}`);
    const viewerStudentId = String(url.searchParams.get('studentId') || '').trim();
    const posts = await readCommunityPosts();
    sendJson(response, 200, {
      posts: posts.map((post) => publicCommunityPostDetailed(post, viewerStudentId)),
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل منشورات المجتمع.' });
  }
}

async function createCommunityPost(request, response) {
  try {
    const payload = JSON.parse(await readBody(request));
    const studentId = String(payload.studentId || '').trim();
    const authorName = String(payload.authorName || '').trim();
    const messageText = String(payload.message || '').trim();

    if (!studentId || !messageText) {
      sendJson(response, 400, { message: 'من فضلك اكتب المنشور.' });
      return;
    }

    const users = await readUsers();
    const user = users.find((currentUser) => currentUser.id === studentId);
    if (!user) {
      sendJson(response, 404, { message: 'بيانات المستخدم غير موجودة.' });
      return;
    }
    if ((user.status || 'active') === 'suspended') {
      sendJson(response, 403, { message: 'تم حظر هذا الحساب من النشر في المجتمع.' });
      return;
    }

    const posts = await readCommunityPosts();
    const newPost = {
      id: crypto.randomUUID(),
      studentId,
      authorName: authorName || user.fullName || 'مستخدم',
      message: messageText,
      reactions: {},
      comments: [],
      sharesCount: 0,
      createdAt: new Date().toISOString(),
    };

    posts.unshift(newPost);
    await writeCommunityPosts(posts);
    await recordActivity({
      userId: user.id,
      userName: user.fullName || '',
      userPhone: user.phone || '',
      action: 'community_post',
      label: 'منشور مجتمع',
      details: messageText,
    });

    await notifyAdmins(
      'بوست جديد في المجتمع',
      `${user.fullName || authorName || 'طالب'} نشر بوست جديد في المجتمع.`,
      'admin_new_community_post'
    );
    sendJson(response, 201, { post: publicCommunityPostDetailed(newPost, studentId) });
  } catch {
    sendJson(response, 500, { message: 'تعذر نشر المنشور.' });
  }
}

async function reactToCommunityPost(request, response, postId) {
  try {
    const payload = JSON.parse(await readBody(request));
    const studentId = String(payload.studentId || '').trim();
    const reaction = String(payload.reaction || '').trim();
    if (!studentId || !['like', 'dislike', 'none'].includes(reaction)) {
      sendJson(response, 400, { message: 'بيانات التفاعل غير مكتملة.' });
      return;
    }

    const posts = await readCommunityPosts();
    const post = posts.find((item) => item.id === postId);
    if (!post) {
      sendJson(response, 404, { message: 'المنشور غير موجود.' });
      return;
    }

    post.reactions = post.reactions && typeof post.reactions === 'object'
      ? post.reactions
      : {};
    if (reaction === 'none' || post.reactions[studentId] === reaction) {
      delete post.reactions[studentId];
    } else {
      post.reactions[studentId] = reaction;
    }
    await writeCommunityPosts(posts);
    sendJson(response, 200, { post: publicCommunityPostDetailed(post, studentId) });
  } catch {
    sendJson(response, 500, { message: 'تعذر تسجيل التفاعل.' });
  }
}

async function commentOnCommunityPost(request, response, postId) {
  try {
    const payload = JSON.parse(await readBody(request));
    const studentId = String(payload.studentId || '').trim();
    const authorName = String(payload.authorName || '').trim();
    const messageText = String(payload.message || '').trim();
    if (!studentId || !messageText) {
      sendJson(response, 400, { message: 'اكتب التعليق أولاً.' });
      return;
    }

    const users = await readUsers();
    const user = users.find((currentUser) => currentUser.id === studentId);
    if (!user) {
      sendJson(response, 404, { message: 'بيانات المستخدم غير موجودة.' });
      return;
    }
    if ((user.status || 'active') === 'suspended') {
      sendJson(response, 403, { message: 'تم حظر هذا الحساب من التعليق في المجتمع.' });
      return;
    }

    const posts = await readCommunityPosts();
    const post = posts.find((item) => item.id === postId);
    if (!post) {
      sendJson(response, 404, { message: 'المنشور غير موجود.' });
      return;
    }
    post.comments = Array.isArray(post.comments) ? post.comments : [];
    post.comments.push({
      id: crypto.randomUUID(),
      studentId,
      authorName: authorName || user.fullName || 'مستخدم',
      message: messageText,
      createdAt: new Date().toISOString(),
    });
    await writeCommunityPosts(posts);
    await notifyAdmins(
      'تعليق جديد في المجتمع',
      `${user.fullName || authorName || 'طالب'} علّق على بوست في المجتمع.`,
      'admin_new_community_comment'
    );
    sendJson(response, 201, { post: publicCommunityPostDetailed(post, studentId) });
  } catch {
    sendJson(response, 500, { message: 'تعذر إضافة التعليق.' });
  }
}

async function shareCommunityPost(request, response, postId) {
  try {
    const payload = JSON.parse(await readBody(request));
    const studentId = String(payload.studentId || '').trim();
    const posts = await readCommunityPosts();
    const post = posts.find((item) => item.id === postId);
    if (!post) {
      sendJson(response, 404, { message: 'المنشور غير موجود.' });
      return;
    }
    post.sharesCount = Number(post.sharesCount || 0) + 1;
    await writeCommunityPosts(posts);
    sendJson(response, 200, { post: publicCommunityPostDetailed(post, studentId) });
  } catch {
    sendJson(response, 500, { message: 'تعذر مشاركة المنشور.' });
  }
}

async function listAdminCommunityPosts(request, response) {
  const adminSession = requireAdmin(request, response);
  if (!adminSession) {
    return;
  }
  try {
    const posts = await readCommunityPosts();
    sendJson(response, 200, {
      posts: posts.map((post) =>
        publicCommunityPostDetailed(post, adminCommunityId(adminSession))
      ),
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل منشورات المجتمع.' });
  }
}

function adminCommunityId(adminSession) {
  return `admin:${adminSession.email || adminSession.name || 'lingova'}`;
}

async function reactToAdminCommunityPost(request, response, postId) {
  const adminSession = requireAdmin(request, response);
  if (!adminSession) {
    return;
  }
  try {
    const payload = JSON.parse(await readBody(request));
    const reaction = String(payload.reaction || '').trim();
    if (!['like', 'dislike', 'none'].includes(reaction)) {
      sendJson(response, 400, { message: 'بيانات التفاعل غير مكتملة.' });
      return;
    }

    const posts = await readCommunityPosts();
    const post = posts.find((item) => item.id === postId);
    if (!post) {
      sendJson(response, 404, { message: 'المنشور غير موجود.' });
      return;
    }

    const adminId = adminCommunityId(adminSession);
    post.reactions = post.reactions && typeof post.reactions === 'object'
      ? post.reactions
      : {};
    if (reaction === 'none' || post.reactions[adminId] === reaction) {
      delete post.reactions[adminId];
    } else {
      post.reactions[adminId] = reaction;
    }
    await writeCommunityPosts(posts);
    sendJson(response, 200, { post: publicCommunityPostDetailed(post, adminId) });
  } catch {
    sendJson(response, 500, { message: 'تعذر تسجيل التفاعل.' });
  }
}

async function commentOnAdminCommunityPost(request, response, postId) {
  const adminSession = requireAdmin(request, response);
  if (!adminSession) {
    return;
  }
  try {
    const payload = JSON.parse(await readBody(request));
    const messageText = String(payload.message || '').trim();
    if (!messageText) {
      sendJson(response, 400, { message: 'اكتب التعليق أولاً.' });
      return;
    }

    const posts = await readCommunityPosts();
    const post = posts.find((item) => item.id === postId);
    if (!post) {
      sendJson(response, 404, { message: 'المنشور غير موجود.' });
      return;
    }

    const adminId = adminCommunityId(adminSession);
    post.comments = Array.isArray(post.comments) ? post.comments : [];
    post.comments.push({
      id: crypto.randomUUID(),
      studentId: adminId,
      authorName: adminSession.name || 'Lingova Admin',
      message: messageText,
      createdAt: new Date().toISOString(),
    });
    await writeCommunityPosts(posts);
    sendJson(response, 201, { post: publicCommunityPostDetailed(post, adminId) });
  } catch {
    sendJson(response, 500, { message: 'تعذر إضافة التعليق.' });
  }
}

async function deleteAdminCommunityPost(request, response, postId) {
  if (!requireAdmin(request, response)) {
    return;
  }
  try {
    const posts = await readCommunityPosts();
    const nextPosts = posts.filter((post) => post.id !== postId);
    if (nextPosts.length === posts.length) {
      sendJson(response, 404, { message: 'المنشور غير موجود.' });
      return;
    }
    await writeCommunityPosts(nextPosts);
    sendJson(response, 200, { message: 'تم حذف المنشور.' });
  } catch {
    sendJson(response, 500, { message: 'تعذر حذف المنشور.' });
  }
}

async function deleteAdminCommunityComment(request, response, postId, commentId) {
  if (!requireAdmin(request, response)) {
    return;
  }
  try {
    const posts = await readCommunityPosts();
    const post = posts.find((item) => item.id === postId);
    if (!post) {
      sendJson(response, 404, { message: 'المنشور غير موجود.' });
      return;
    }
    post.comments = Array.isArray(post.comments) ? post.comments : [];
    const nextComments = post.comments.filter((comment) => comment.id !== commentId);
    if (nextComments.length === post.comments.length) {
      sendJson(response, 404, { message: 'التعليق غير موجود.' });
      return;
    }
    post.comments = nextComments;
    await writeCommunityPosts(posts);
    sendJson(response, 200, { post: publicCommunityPostDetailed(post) });
  } catch {
    sendJson(response, 500, { message: 'تعذر حذف التعليق.' });
  }
}

async function banCommunityUser(request, response, studentId) {
  if (!requireAdmin(request, response)) {
    return;
  }
  try {
    const users = await readUsers();
    const user = users.find((currentUser) => currentUser.id === studentId);
    if (!user) {
      sendJson(response, 404, { message: 'المستخدم غير موجود.' });
      return;
    }
    user.status = 'suspended';
    await writeUsers(users);
    sendJson(response, 200, { user: publicUser(user) });
  } catch {
    sendJson(response, 500, { message: 'تعذر حظر المستخدم.' });
  }
}

async function createSubscriptionRequest(request, response) {
  try {
    const payload = JSON.parse(await readBody(request));
    const studentId = String(payload.studentId || '').trim();
    const courseTitle = String(payload.courseTitle || '').trim();
    const courseLanguage = String(payload.courseLanguage || '').trim();

    if (!studentId || !courseTitle || !courseLanguage) {
      sendJson(response, 400, { message: 'بيانات طلب الاشتراك غير مكتملة.' });
      return;
    }

    const users = await readUsers();
    const user = users.find((currentUser) => currentUser.id === studentId);
    if (!user || normalizeRole(user.role) !== 'student') {
      sendJson(response, 404, { message: 'بيانات الطالب غير موجودة.' });
      return;
    }

    const parts = await readCourseParts();
    const course = parts.find(
      (part) =>
        (part.type || 'part') === 'course' &&
        part.course === courseTitle &&
        part.language === courseLanguage
    );
    if (!course) {
      sendJson(response, 404, { message: 'الكورس غير موجود.' });
      return;
    }

    const subscriptions = await readSubscriptions();
    const existing = subscriptions.find(
      (subscription) =>
        subscription.studentId === studentId &&
        subscription.courseTitle === courseTitle &&
        subscription.courseLanguage === courseLanguage &&
        (subscription.status || 'pending') === 'pending'
    );
    if (existing) {
      sendJson(response, 200, {
        message: 'طلب الاشتراك موجود بالفعل.',
        subscription: publicSubscription(existing),
      });
      return;
    }

    const subscription = {
      id: crypto.randomUUID(),
      studentId,
      studentName: user.fullName,
      studentPhone: user.phone,
      studentAddress: user.address || '',
      studentJob: user.job || '',
      studentLanguage: user.language || '',
      courseTitle,
      courseLanguage,
      courseLevel: course.courseLevel || payload.courseLevel || '',
      coursePrice:
        (course.courseType || 'free') === 'paid'
          ? String(course.price || payload.coursePrice || '')
          : 'مجانا',
      status: 'pending',
      requestedAt: new Date().toISOString(),
      approvedAt: null,
      approvedBy: '',
    };

    subscriptions.unshift(subscription);
    await writeSubscriptions(subscriptions);
    await recordActivity({
      userId: user.id,
      userName: user.fullName || '',
      userPhone: user.phone || '',
      action: 'subscription_request',
      label: 'طلب شراء كورس',
      details: `${courseLanguage} - ${courseTitle}`,
    });
    await notifyAdmins(
      'طلب شراء جديد',
      `${user.fullName || 'طالب'} طلب شراء ${courseTitle}.`,
      'admin_new_subscription'
    );
    sendJson(response, 201, {
      message: 'تم إرسال طلب الاشتراك.',
      subscription: publicSubscription(subscription),
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر إرسال طلب الاشتراك.' });
  }
}

async function listAdminSubscriptions(request, response) {
  if (!requireAdmin(request, response)) {
    return;
  }

  try {
    const subscriptions = await readSubscriptions();
    sendJson(response, 200, {
      subscriptions: subscriptions.map(publicSubscription),
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل طلبات الاشتراك.' });
  }
}

async function listVocabularyWords(request, response) {
  try {
    const words = await readVocabularyWords();
    sendJson(response, 200, { words: words.map(publicVocabularyWord) });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل كلمات Vocabulary.' });
  }
}

async function listAdminVocabularyWords(request, response) {
  if (!requireAdmin(request, response)) {
    return;
  }
  await listVocabularyWords(request, response);
}

async function createVocabularyWord(request, response) {
  const adminSession = requireAdmin(request, response);
  if (!adminSession) {
    return;
  }
  try {
    const payload = JSON.parse((await readBody(request)) || '{}');
    const incomingWords = Array.isArray(payload.words) ? payload.words : [payload];
    const now = new Date().toISOString();
    const items = incomingWords
      .map((entry) => {
        const word = String(entry.word || '').trim();
        const meaning = String(entry.meaning || '').trim();
        if (!word || !meaning) {
          return null;
        }
        return {
          id: crypto.randomUUID(),
          word,
          meaning,
          pronunciation: String(entry.pronunciation || '').trim(),
          example: String(entry.example || '').trim(),
          languageCode: String(entry.languageCode || 'en').trim() || 'en',
          course: String(entry.course || '').trim(),
          courseLanguage: String(entry.courseLanguage || '').trim(),
          level: String(entry.level || '').trim(),
          lesson: String(entry.lesson || '').trim(),
          translation: String(entry.translation || '').trim(),
          createdAt: now,
          createdBy: adminSession.name || 'Admin',
        };
      })
      .filter(Boolean);

    if (items.length === 0) {
      sendJson(response, 400, { message: 'اكتب الكلمة والمعنى.' });
      return;
    }

    const words = await readVocabularyWords();
    words.unshift(...items);
    await writeVocabularyWords(words);
    sendJson(response, 201, {
      word: publicVocabularyWord(items[0]),
      words: items.map(publicVocabularyWord),
      count: items.length,
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر إضافة الكلمة.' });
  }
}

async function deleteVocabularyWord(request, response, wordId) {
  if (!requireAdmin(request, response)) {
    return;
  }
  try {
    const words = await readVocabularyWords();
    const nextWords = words.filter((word) => word.id !== wordId);
    if (nextWords.length === words.length) {
      sendJson(response, 404, { message: 'الكلمة غير موجودة.' });
      return;
    }
    await writeVocabularyWords(nextWords);
    sendJson(response, 200, { message: 'تم حذف الكلمة.' });
  } catch {
    sendJson(response, 500, { message: 'تعذر حذف الكلمة.' });
  }
}

async function listAudioResources(request, response) {
  try {
    const resources = await readAudioResources();
    const resolvedResources = await Promise.all(
      resources.map((resource) => withResolvedAudioItems(resource))
    );
    sendJson(response, 200, {
      resources: resolvedResources.map(publicAudioResource),
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل الصوتيات.' });
  }
}

async function listAdminAudioResources(request, response) {
  if (!requireAdmin(request, response)) {
    return;
  }
  await listAudioResources(request, response);
}

async function createAudioResource(request, response) {
  const adminSession = requireAdmin(request, response);
  if (!adminSession) {
    return;
  }
  try {
    const payload = JSON.parse((await readBody(request)) || '{}');
    const title = String(payload.title || '').trim();
    const urlValue = String(payload.url || '').trim();
    const linkType = String(payload.linkType || 'clip').trim() === 'folder'
      ? 'folder'
      : 'clip';
    if (!title || !urlValue) {
      sendJson(response, 400, { message: 'اكتب عنوان الصوت والرابط.' });
      return;
    }

    const rawItems = Array.isArray(payload.items) ? payload.items : [];
    let items = rawItems
      .map((item) => ({
        id: crypto.randomUUID(),
        title: String(item.title || '').trim(),
        url: String(item.url || '').trim(),
        fileType: String(item.fileType || payload.fileType || 'audio').trim(),
        relativePath: String(item.relativePath || '').trim(),
      }))
      .filter((item) => item.title && item.url);

    if (linkType === 'folder' && items.length === 0) {
      const folderId = parseGoogleDriveFolderId(urlValue);
      if (folderId && googleDriveApiKey) {
        items = await listGoogleDriveFolderAudio(folderId);
      }
    }

    const course = String(payload.course || '').trim();
    const courseLanguage = String(payload.courseLanguage || '').trim();
    const level = String(payload.level || '').trim();
    const fileType = String(payload.fileType || 'audio').trim() || 'audio';
    const normalizedItems = [];
    for (const item of items) {
      normalizedItems.push({
        ...item,
        url: await ensureOnlineAudioUrl(item.url, {
          course,
          courseLanguage,
          level,
          title: item.relativePath || item.title || title,
        }),
      });
    }

    const storedUrl = await ensureOnlineAudioUrl(urlValue, {
      course,
      courseLanguage,
      level,
      title,
    });

    const resources = await readAudioResources();
    const resource = {
      id: crypto.randomUUID(),
      title,
      description: String(payload.description || '').trim(),
      course,
      courseLanguage,
      level,
      accessType: normalizeCoursePaymentType(payload.accessType),
      fileType,
      linkType,
      url: storedUrl,
      items: normalizedItems,
      createdAt: new Date().toISOString(),
      createdBy: adminSession.name || 'Admin',
    };
    resources.unshift(resource);
    await writeAudioResources(resources);
    sendJson(response, 201, { resource: publicAudioResource(resource) });
  } catch {
    sendJson(response, 500, { message: 'تعذر إضافة الصوت.' });
  }
}

function parseGoogleDriveFolderId(value) {
  const raw = String(value || '').trim();
  if (!raw) return '';
  const folderMatch = raw.match(/drive\.google\.com\/drive\/folders\/([^/?#]+)/);
  if (folderMatch) return folderMatch[1];
  const queryMatch = raw.match(/[?&]id=([^&#]+)/);
  if (queryMatch) return queryMatch[1];
  return /^[a-zA-Z0-9_-]{10,}$/.test(raw) ? raw : '';
}

function parseGoogleDriveFileId(value) {
  const raw = String(value || '').trim();
  if (!raw) return '';
  const fileMatch = raw.match(/drive\.google\.com\/file\/d\/([^/?#]+)/);
  if (fileMatch) return fileMatch[1];
  const queryMatch = raw.match(/[?&]id=([^&#]+)/);
  if (queryMatch) return queryMatch[1];
  return /^[a-zA-Z0-9_-]{10,}$/.test(raw) ? raw : '';
}

async function proxyAudio(request, response, url) {
  const sourceUrl = String(url.searchParams.get('url') || '').trim();
  const sourceId = String(url.searchParams.get('id') || '').trim();
  const fileId = sourceId || parseGoogleDriveFileId(sourceUrl);

  if (!fileId && !/^https?:\/\//i.test(sourceUrl)) {
    sendJson(response, 400, { message: 'Audio URL is required.' });
    return;
  }

  const range = request.headers.range;
  const upstreamUrl = fileId
    ? googleDriveApiKey
      ? `https://www.googleapis.com/drive/v3/files/${encodeURIComponent(fileId)}?alt=media&key=${encodeURIComponent(googleDriveApiKey)}`
      : `https://drive.google.com/uc?export=download&id=${encodeURIComponent(fileId)}`
    : sourceUrl;

  try {
    const upstream = await fetch(upstreamUrl, {
      method: 'GET',
      redirect: 'follow',
      headers: range ? { Range: range } : undefined,
    });
    const contentType = String(upstream.headers.get('content-type') || '');
    if (!upstream.ok || contentType.toLowerCase().includes('text/html')) {
      sendJson(response, upstream.ok ? 502 : upstream.status, {
        message:
          'تعذر تشغيل ملف Google Drive مباشرة. تأكد أن الملف Public أو اضبط GOOGLE_DRIVE_API_KEY.',
      });
      return;
    }

    const headers = {
      'Access-Control-Allow-Origin': '*',
      'Accept-Ranges': upstream.headers.get('accept-ranges') || 'bytes',
      'Cache-Control': 'public, max-age=3600',
      'Content-Type': contentType || 'audio/mpeg',
    };
    const contentLength = upstream.headers.get('content-length');
    const contentRange = upstream.headers.get('content-range');
    if (contentLength) headers['Content-Length'] = contentLength;
    if (contentRange) headers['Content-Range'] = contentRange;

    response.writeHead(upstream.status, headers);
    if (upstream.body) {
      Readable.fromWeb(upstream.body).pipe(response);
    } else {
      response.end(Buffer.from(await upstream.arrayBuffer()));
    }
  } catch {
    sendJson(response, 502, { message: 'تعذر تحميل ملف الصوت.' });
  }
}

function parseDataUrl(value) {
  const match = String(value || '').match(/^data:([^;,]+)?(;base64)?,(.*)$/s);
  if (!match) return null;
  const mimeType = match[1] || 'application/octet-stream';
  const isBase64 = Boolean(match[2]);
  const payload = match[3] || '';
  const buffer = isBase64
    ? Buffer.from(payload, 'base64')
    : Buffer.from(decodeURIComponent(payload), 'utf8');
  return buffer.length > 0 ? { mimeType, buffer } : null;
}

function safeStoragePathPart(value) {
  return String(value || '')
    .normalize('NFKD')
    .replace(/[^\w.\-]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 90) || 'audio';
}

function extensionForMime(mimeType) {
  const type = String(mimeType || '').toLowerCase();
  if (type.includes('mpeg') || type.includes('mp3')) return '.mp3';
  if (type.includes('wav')) return '.wav';
  if (type.includes('ogg')) return '.ogg';
  if (type.includes('aac')) return '.aac';
  if (type.includes('flac')) return '.flac';
  if (type.includes('mp4') || type.includes('m4a')) return '.m4a';
  return '.bin';
}

async function uploadSupabaseStorageObject(storagePath, buffer, contentType) {
  if (!useSupabase) {
    throw new Error('Supabase storage is not configured.');
  }
  const objectPath = `/storage/v1/object/lingova-audio/${storagePath
    .split('/')
    .map(encodeURIComponent)
    .join('/')}`;
  const uploadResponse = await fetch(`${supabaseUrl}${objectPath}`, {
    method: 'POST',
    headers: {
      apikey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
      'Content-Type': contentType || 'application/octet-stream',
      'x-upsert': 'true',
    },
    body: buffer,
  });
  const text = await uploadResponse.text();
  if (!uploadResponse.ok) {
    throw new Error(
      `Supabase storage upload failed (${uploadResponse.status}): ${text}`
    );
  }
  return `${supabaseUrl}/storage/v1/object/public/lingova-audio/${storagePath
    .split('/')
    .map(encodeURIComponent)
    .join('/')}`;
}

async function ensureOnlineAudioUrl(value, context) {
  const urlValue = String(value || '').trim();
  if (!urlValue.startsWith('data:')) {
    return urlValue;
  }
  if (!useSupabase) {
    throw new Error('Audio uploads require Supabase storage configuration.');
  }
  const parsed = parseDataUrl(urlValue);
  if (!parsed) {
    throw new Error('Invalid audio data URL.');
  }
  const extension = extensionForMime(parsed.mimeType);
  const pathParts = [
    safeStoragePathPart(context.courseLanguage),
    safeStoragePathPart(context.course),
    safeStoragePathPart(context.level),
    `${Date.now()}-${crypto.randomUUID()}-${safeStoragePathPart(context.title)}${extension}`,
  ].filter(Boolean);
  return uploadSupabaseStorageObject(
    pathParts.join('/'),
    parsed.buffer,
    parsed.mimeType
  );
}

function googleDriveAudioMime(file) {
  const name = String(file.name || '').toLowerCase();
  const mimeType = String(file.mimeType || '').toLowerCase();
  if (mimeType.startsWith('audio/')) return true;
  return ['.mp3', '.wav', '.m4a', '.aac', '.ogg', '.flac'].some((ext) =>
    name.endsWith(ext)
  );
}

async function listGoogleDriveFolderAudio(folderId, prefix = '') {
  const q = encodeURIComponent(`'${folderId}' in parents and trashed = false`);
  const fields = encodeURIComponent(
    'nextPageToken,files(id,name,mimeType)'
  );
  const items = [];
  let pageToken = '';

  do {
    const page = pageToken ? `&pageToken=${encodeURIComponent(pageToken)}` : '';
    const driveResponse = await fetch(
      `https://www.googleapis.com/drive/v3/files?q=${q}&fields=${fields}&pageSize=1000${page}&key=${encodeURIComponent(googleDriveApiKey)}`
    );
    if (!driveResponse.ok) {
      throw new Error(`Google Drive API failed: ${driveResponse.status}`);
    }
    const json = await driveResponse.json();
    const files = Array.isArray(json.files) ? json.files : [];
    for (const file of files) {
      const name = String(file.name || '').trim();
      if (!name) continue;
      const relativePath = prefix ? `${prefix}/${name}` : name;
      if (file.mimeType === 'application/vnd.google-apps.folder') {
        items.push(...(await listGoogleDriveFolderAudio(file.id, relativePath)));
      } else if (googleDriveAudioMime(file)) {
        items.push({
          title: name.replace(/\.[^.]+$/, ''),
          url: `https://drive.google.com/uc?export=download&id=${file.id}`,
          fileType: 'audio',
          relativePath,
        });
      }
    }
    pageToken = json.nextPageToken || '';
  } while (pageToken);

  return items;
}

async function importGoogleDriveAudioFolder(request, response) {
  if (!requireAdmin(request, response)) {
    return;
  }
  if (!googleDriveApiKey) {
    sendJson(response, 400, {
      message: 'GOOGLE_DRIVE_API_KEY غير مضبوط في إعدادات الباك إند.',
    });
    return;
  }

  try {
    const payload = JSON.parse((await readBody(request)) || '{}');
    const folderId = parseGoogleDriveFolderId(payload.folderUrl || payload.url);
    if (!folderId) {
      sendJson(response, 400, { message: 'رابط فولدر Google Drive غير صحيح.' });
      return;
    }

    const items = await listGoogleDriveFolderAudio(folderId);
    if (items.length === 0) {
      sendJson(response, 200, {
        items: [],
        count: 0,
        message: 'لم يتم العثور على ملفات صوتية داخل هذا الفولدر',
      });
      return;
    }

    sendJson(response, 200, { items, count: items.length });
  } catch (error) {
    sendJson(response, 500, {
      message: 'تعذر قراءة فولدر Google Drive. تأكد أن الفولدر متاح للمشاركة.',
    });
  }
}

async function checkOnlineAudioUrl(urlValue, expectedAudio = true) {
  const url = String(urlValue || '').trim();
  if (!url) {
    return { ok: false, reason: 'missing_url' };
  }
  if (url.startsWith('data:')) {
    return { ok: false, reason: 'stored_inline_data_url' };
  }
  if (url.startsWith('local-audio-folder:')) {
    return { ok: true, reason: 'folder_placeholder' };
  }
  if (!/^https?:\/\//i.test(url)) {
    return { ok: false, reason: 'not_online_url' };
  }

  try {
    let checked = await fetch(url, { method: 'HEAD', redirect: 'follow' });
    if (!checked.ok || checked.status === 405) {
      checked = await fetch(url, {
        method: 'GET',
        redirect: 'follow',
        headers: { Range: 'bytes=0-1' },
      });
    }
    const contentType = String(checked.headers.get('content-type') || '').toLowerCase();
    if (!checked.ok) {
      return { ok: false, reason: `http_${checked.status}` };
    }
    if (expectedAudio && contentType.includes('text/html')) {
      return { ok: false, reason: 'html_instead_of_audio' };
    }
    return { ok: true, reason: contentType || 'online' };
  } catch (error) {
    return { ok: false, reason: 'request_failed' };
  }
}

async function auditAudioResources(request, response) {
  if (!requireAdmin(request, response)) {
    return;
  }
  try {
    const resources = await readAudioResources();
    const issues = [];
    let checkedFiles = 0;
    let onlineFiles = 0;

    for (const resource of resources) {
      const publicResource = publicAudioResource(resource);
      const items = Array.isArray(publicResource.items) ? publicResource.items : [];

      if (publicResource.linkType === 'folder') {
        if (items.length === 0) {
          issues.push({
            resourceId: publicResource.id,
            title: publicResource.title,
            type: 'folder_empty',
            reason: 'folder_has_no_audio_items',
          });
        }
        for (const item of items) {
          checkedFiles += 1;
          const result = await checkOnlineAudioUrl(item.url, item.fileType === 'audio');
          if (result.ok) {
            onlineFiles += 1;
          } else {
            issues.push({
              resourceId: publicResource.id,
              itemId: item.id,
              title: item.title || publicResource.title,
              type: 'item',
              reason: result.reason,
              url: item.url,
            });
          }
        }
      } else {
        checkedFiles += 1;
        const result = await checkOnlineAudioUrl(
          publicResource.url,
          publicResource.fileType === 'audio'
        );
        if (result.ok) {
          onlineFiles += 1;
        } else {
          issues.push({
            resourceId: publicResource.id,
            title: publicResource.title,
            type: 'resource',
            reason: result.reason,
            url: publicResource.url,
          });
        }
      }
    }

    sendJson(response, 200, {
      checkedResources: resources.length,
      checkedFiles,
      onlineFiles,
      missingFiles: checkedFiles - onlineFiles,
      issues,
    });
  } catch (error) {
    sendJson(response, 500, { message: 'تعذر فحص ملفات الصوت.' });
  }
}

async function deleteAudioResource(request, response, resourceId) {
  if (!requireAdmin(request, response)) {
    return;
  }
  try {
    const resources = await readAudioResources();
    const nextResources = resources.filter((resource) => resource.id !== resourceId);
    if (nextResources.length === resources.length) {
      sendJson(response, 404, { message: 'الملف الصوتي غير موجود.' });
      return;
    }
    await writeAudioResources(nextResources);
    sendJson(response, 200, { message: 'تم حذف الملف الصوتي.' });
  } catch {
    sendJson(response, 500, { message: 'تعذر حذف الملف الصوتي.' });
  }
}

async function listAdminActivityLogs(request, response) {
  if (!requireAdmin(request, response)) {
    return;
  }

  try {
    const logs = await readActivityLogs();
    sendJson(response, 200, { logs: logs.map(publicActivityLog) });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل سجل النشاط.' });
  }
}

async function recordAppActivity(request, response) {
  try {
    const payload = JSON.parse((await readBody(request)) || '{}');
    const userId = String(payload.userId || '').trim();
    const sessionId = String(payload.sessionId || '').trim() || userId;
    const action = String(payload.action || 'activity').trim();
    const label = String(payload.label || '').trim();
    const details = String(payload.details || '').trim();

    if (!userId || !sessionId) {
      sendJson(response, 400, { message: 'بيانات النشاط غير مكتملة.' });
      return;
    }

    const users = await readUsers();
    const user = users.find((item) => item.id === userId);
    if (!user) {
      sendJson(response, 404, { message: 'بيانات المستخدم غير موجودة.' });
      return;
    }

    const now = new Date().toISOString();
    const sessions = await readAppSessions();
    const existing = sessions.find((session) => session.sessionId === sessionId);
    if (existing) {
      existing.userId = userId;
      existing.userName = user.fullName || '';
      existing.userPhone = user.phone || '';
      existing.lastSeenAt = now;
    } else {
      sessions.push({
        id: crypto.randomUUID(),
        sessionId,
        userId,
        userName: user.fullName || '',
        userPhone: user.phone || '',
        openedAt: now,
        lastSeenAt: now,
      });
    }

    await writeAppSessions(sessions.slice(-1000));
    await recordActivity({
      userId,
      userName: user.fullName || '',
      userPhone: user.phone || '',
      action,
      label,
      details,
    });

    sendJson(response, 200, { status: 'ok' });
  } catch {
    sendJson(response, 500, { message: 'تعذر تسجيل النشاط.' });
  }
}

async function getAppStreak(request, response, url) {
  try {
    const userId = String(url.searchParams.get('userId') || '').trim();
    if (!userId) {
      sendJson(response, 400, { message: 'Missing userId.' });
      return;
    }

    const logs = await readActivityLogs();
    const activeDays = new Set(
      logs
        .filter((log) => String(log.userId || '') === userId)
        .map((log) => dateKey(log.createdAt))
        .filter(Boolean)
    );
    const sessions = await readAppSessions();
    for (const session of sessions) {
      if (String(session.userId || '') !== userId) {
        continue;
      }
      const openedDay = dateKey(session.openedAt);
      const lastSeenDay = dateKey(session.lastSeenAt);
      if (openedDay) {
        activeDays.add(openedDay);
      }
      if (lastSeenDay) {
        activeDays.add(lastSeenDay);
      }
    }

    let streak = 0;
    const cursor = new Date();
    while (activeDays.has(dateKey(cursor))) {
      streak += 1;
      cursor.setDate(cursor.getDate() - 1);
    }

    sendJson(response, 200, {
      streak,
      today: dateKey(new Date()),
      activeDaysCount: activeDays.size,
    });
  } catch {
    sendJson(response, 500, { message: 'Could not load app streak.' });
  }
}

async function approveSubscription(request, response, subscriptionId) {
  const adminSession = requireAdmin(request, response);
  if (!adminSession) {
    return;
  }

  try {
    const payload = JSON.parse(await readBody(request) || '{}');
    const paymentMethod = String(payload.paymentMethod || '').trim();
    const paymentDate = String(payload.paymentDate || '').trim();
    const paymentPhone = String(payload.paymentPhone || '').trim();
    const paidAmount = String(payload.paidAmount || '').trim();

    if (!paymentMethod || !paymentDate || !paymentPhone || !paidAmount) {
      sendJson(response, 400, { message: 'من فضلك املأ بيانات الدفع كاملة.' });
      return;
    }

    const subscriptions = await readSubscriptions();
    const subscription = subscriptions.find((item) => item.id === subscriptionId);
    if (!subscription) {
      sendJson(response, 404, { message: 'طلب الاشتراك غير موجود.' });
      return;
    }

    const users = await readUsers();
    const user = users.find((currentUser) => currentUser.id === subscription.studentId);
    if (!user) {
      sendJson(response, 404, { message: 'بيانات الطالب غير موجودة.' });
      return;
    }

    const courseKey = courseKeyFor(
      subscription.courseLanguage,
      subscription.courseTitle
    );
    const enrollments = Array.isArray(user.enrollments) ? user.enrollments : [];
    const existingEnrollment = enrollments.find(
      (enrollment) => enrollment.courseKey === courseKey
    );
    if (existingEnrollment) {
      existingEnrollment.paymentStatus = 'paid';
      existingEnrollment.paymentMethod = paymentMethod;
      existingEnrollment.paymentDate = paymentDate;
      existingEnrollment.paymentPhone = paymentPhone;
      existingEnrollment.paidAmount = paidAmount;
      existingEnrollment.openedBy = adminSession.name || 'Admin';
    } else {
      enrollments.push({
        courseKey,
        courseTitle: subscription.courseTitle,
        courseLanguage: subscription.courseLanguage,
        openedAt: new Date().toISOString(),
        openedBy: adminSession.name || 'Admin',
        paymentStatus: 'paid',
        paymentMethod,
        paymentDate,
        paymentPhone,
        paidAmount,
      });
    }
    user.enrollments = enrollments;

    subscription.status = 'approved';
    subscription.approvedAt = new Date().toISOString();
    subscription.approvedBy = adminSession.name || 'Admin';
    subscription.paymentMethod = paymentMethod;
    subscription.paymentDate = paymentDate;
    subscription.paymentPhone = paymentPhone;
    subscription.paidAmount = paidAmount;

    await writeUsers(users);
    await writeSubscriptions(subscriptions);
    await recordActivity({
      userId: user.id,
      userName: user.fullName || '',
      userPhone: user.phone || '',
      action: 'subscription_approved',
      label: 'تم فتح كورس مدفوع',
      details: `${subscription.courseLanguage} - ${subscription.courseTitle} - ${paidAmount}`,
    });
    sendJson(response, 200, {
      message: 'تم فتح الكورس للطالب.',
      subscription: publicSubscription(subscription),
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر اعتماد طلب الاشتراك.' });
  }
}

async function createCoursePart(request, response) {
  const adminSession = requireAdmin(request, response);
  if (!adminSession) {
    return;
  }

  try {
    const payload = JSON.parse(await readBody(request));
    const validationError = validateCoursePartPayload(payload);
    if (validationError) {
      sendJson(response, 400, { message: validationError });
      return;
    }

    const parts = await readCourseParts();
    const type = normalizeCourseNodeType(payload.type);
    const coursePart = {
      id: crypto.randomUUID(),
      type,
      language: String(payload.language).trim(),
      course: String(payload.course).trim(),
      level: String(payload.level || '').trim(),
      lecture: String(payload.lecture || '').trim(),
      part: String(payload.part || '').trim(),
      vimeoUrl: String(payload.vimeoUrl || '').trim(),
      courseType: normalizeCoursePaymentType(payload.courseType),
      price: String(payload.price || '').trim(),
      courseLevel: normalizeCourseLevel(payload.courseLevel),
      duration: String(payload.duration || '').trim(),
      imageDataUrl: String(payload.imageDataUrl || '').trim(),
      learningOutcomes: type === 'course'
        ? normalizeLearningOutcomes(payload.learningOutcomes)
        : [],
      createdAt: new Date().toISOString(),
      createdBy: adminSession.name || 'Admin',
    };

    parts.push(coursePart);
    await writeCourseParts(parts);
    sendJson(response, 201, { part: publicCoursePart(coursePart) });
  } catch {
    sendJson(response, 500, { message: 'تعذر إنشاء جزء الكورس.' });
  }
}

async function createAdminBook(request, response) {
  const adminSession = requireAdmin(request, response);
  if (!adminSession) {
    return;
  }

  try {
    const payload = JSON.parse(await readBody(request));
    const isFreeValue = payload.isFree;
    const isFree = isFreeValue === undefined
      ? true
      : isFreeValue === true || String(isFreeValue).toLowerCase() === 'true';

    const book = {
      id: crypto.randomUUID(),
      title: String(payload.title).trim(),
      subtitle: String(payload.subtitle).trim(),
      course: String(payload.course || '').trim(),
      language: String(payload.language || '').trim(),
      isFree,
      url: String(payload.url).trim(),
      createdAt: new Date().toISOString(),
      createdBy: adminSession.name || 'Admin',
    };

    const books = await readBooks();
    books.push(book);
    await writeBooks(books);
    sendJson(response, 201, { book });
  } catch {
    sendJson(response, 500, { message: 'تعذر إنشاء الكتاب.' });
  }
}

async function updateCoursePart(request, response, partId) {
  if (!requireAdmin(request, response)) {
    return;
  }

  try {
    const payload = JSON.parse(await readBody(request));
    const validationError = validateCoursePartPayload(payload);
    if (validationError) {
      sendJson(response, 400, { message: validationError });
      return;
    }

    const parts = await readCourseParts();
    const index = parts.findIndex((part) => part.id === partId);
    if (index === -1) {
      sendJson(response, 404, { message: 'جزء الكورس غير موجود.' });
      return;
    }

    const current = parts[index];
    const type = normalizeCourseNodeType(payload.type || current.type);
    const previous = {
      language: current.language,
      course: current.course,
      level: current.level || '',
      lecture: current.lecture || '',
    };
    const updated = {
      ...current,
      type,
      language: String(payload.language).trim(),
      course: String(payload.course).trim(),
      level: String(payload.level || '').trim(),
      lecture: String(payload.lecture || '').trim(),
      part: String(payload.part || '').trim(),
      vimeoUrl: String(payload.vimeoUrl || '').trim(),
      courseType: normalizeCoursePaymentType(payload.courseType),
      price: String(payload.price || '').trim(),
      courseLevel: normalizeCourseLevel(payload.courseLevel || current.courseLevel),
      duration: String(payload.duration || '').trim(),
      imageDataUrl: String(payload.imageDataUrl || current.imageDataUrl || '').trim(),
      learningOutcomes: type === 'course'
        ? normalizeLearningOutcomes(payload.learningOutcomes ?? current.learningOutcomes)
        : [],
    };

    parts[index] = updated;

    const isSameCourse = (part) =>
      part.language === previous.language && part.course === previous.course;
    if (type === 'course') {
      for (const part of parts) {
        if (part.id !== partId && isSameCourse(part)) {
          part.language = updated.language;
          part.course = updated.course;
        }
      }
    }
    if (type === 'level') {
      for (const part of parts) {
        if (part.id !== partId && isSameCourse(part) && part.level === previous.level) {
          part.level = updated.level;
        }
      }
    }
    if (type === 'lecture') {
      for (const part of parts) {
        if (
          part.id !== partId &&
          isSameCourse(part) &&
          part.level === previous.level &&
          part.lecture === previous.lecture
        ) {
          part.lecture = updated.lecture;
        }
      }
    }

    await writeCourseParts(parts);
    sendJson(response, 200, { part: publicCoursePart(updated) });
  } catch {
    sendJson(response, 500, { message: 'تعذر تعديل الكورس.' });
  }
}

async function deleteCoursePart(request, response, partId) {
  if (!requireAdmin(request, response)) {
    return;
  }

  try {
    const parts = await readCourseParts();
    const current = parts.find((part) => part.id === partId);
    if (!current) {
      sendJson(response, 404, { message: 'جزء الكورس غير موجود.' });
      return;
    }

    let nextParts = parts.filter((part) => part.id !== partId);
    if ((current.type || 'part') === 'course') {
      nextParts = parts.filter(
        (part) =>
          part.language !== current.language || part.course !== current.course
      );
    }
    if ((current.type || 'part') === 'level') {
      nextParts = parts.filter(
        (part) =>
          part.id === partId ||
          part.language !== current.language ||
          part.course !== current.course ||
          part.level !== current.level
      );
      nextParts = nextParts.filter((part) => part.id !== partId);
    }
    if ((current.type || 'part') === 'lecture') {
      nextParts = parts.filter(
        (part) =>
          part.id === partId ||
          part.language !== current.language ||
          part.course !== current.course ||
          part.level !== current.level ||
          part.lecture !== current.lecture
      );
      nextParts = nextParts.filter((part) => part.id !== partId);
    }

    await writeCourseParts(nextParts);
    sendJson(response, 200, { message: 'تم حذف جزء الكورس.' });
  } catch {
    sendJson(response, 500, { message: 'تعذر حذف جزء الكورس.' });
  }
}

async function updateAdminBook(request, response, bookId) {
  if (!requireAdmin(request, response)) {
    return;
  }

  try {
    const payload = JSON.parse(await readBody(request));
    const books = await readBooks();
    const index = books.findIndex((book) => book.id === bookId);
    if (index === -1) {
      sendJson(response, 404, { message: 'الكتاب غير موجود.' });
      return;
    }

    const current = books[index];
    const isFreeValue = payload.isFree;
    const isFree = isFreeValue === undefined
      ? current.isFree
      : isFreeValue === true || String(isFreeValue).toLowerCase() === 'true';

    const updated = {
      ...current,
      title: String(payload.title ?? current.title).trim(),
      subtitle: String(payload.subtitle ?? current.subtitle).trim(),
      course: String(payload.course ?? current.course).trim(),
      language: String(payload.language ?? current.language ?? '').trim(),
      isFree,
      url: String(payload.url ?? current.url).trim(),
    };

    books[index] = updated;
    await writeBooks(books);
    sendJson(response, 200, { book: updated });
  } catch {
    sendJson(response, 500, { message: 'تعذر تعديل الكتاب.' });
  }
}

async function deleteAdminBook(request, response, bookId) {
  if (!requireAdmin(request, response)) {
    return;
  }

  try {
    const books = await readBooks();
    const current = books.find((book) => book.id === bookId);
    if (!current) {
      sendJson(response, 404, { message: 'الكتاب غير موجود.' });
      return;
    }

    const nextBooks = books.filter((book) => book.id !== bookId);
    await writeBooks(nextBooks);
    sendJson(response, 200, { message: 'تم حذف الكتاب.' });
  } catch {
    sendJson(response, 500, { message: 'تعذر حذف الكتاب.' });
  }
}

async function listAdminUsers(request, response) {
  if (!requireAdmin(request, response)) {
    return;
  }

  try {
    const users = await readUsers();
    sendJson(response, 200, {
      users: [systemAdminUser(), ...users.map(publicUser)],
    });
  } catch {
    sendJson(response, 500, { message: 'تعذر تحميل اليوزرز.' });
  }
}

async function createAdminUser(request, response) {
  const adminSession = requireAdmin(request, response);
  if (!adminSession) {
    return;
  }

  try {
    const payload = JSON.parse(await readBody(request));
    const validationError = validateUserPayload(payload, {
      requirePassword: true,
    });
    if (validationError) {
      sendJson(response, 400, { message: validationError });
      return;
    }

    const users = await readUsers();
    const normalizedPhone = String(payload.phone).replace(/\s/g, '');
    if (users.some((user) => user.phone === normalizedPhone)) {
      sendJson(response, 409, {
        message: 'This phone number already has an account.',
      });
      return;
    }

    const user = buildUserFromPayload(payload, {
      createdBy: adminSession.name || 'Admin',
    });
    user.phone = normalizedPhone;
    users.push(user);
    await writeUsers(users);
    sendJson(response, 201, { user: publicUser(user) });
  } catch {
    sendJson(response, 500, { message: 'تعذر إضافة اليوزر.' });
  }
}

async function updateAdminUser(request, response, userId) {
  if (!requireAdmin(request, response)) {
    return;
  }

  try {
    const payload = JSON.parse(await readBody(request));
    const users = await readUsers();
    const user = users.find((currentUser) => currentUser.id === userId);

    if (!user) {
      sendJson(response, 404, { message: 'اليوزر غير موجود.' });
      return;
    }

    const validationError = validateUserUpdatePayload(payload);
    if (validationError) {
      sendJson(response, 400, { message: validationError });
      return;
    }

    if (payload.phone) {
      const normalizedPhone = String(payload.phone).replace(/\s/g, '');
      const phoneExists = users.some(
        (currentUser) =>
          currentUser.id !== userId && currentUser.phone === normalizedPhone
      );
      if (phoneExists) {
        sendJson(response, 409, {
          message: 'This phone number already has an account.',
        });
        return;
      }
      user.phone = normalizedPhone;
    }

    for (const field of [
      'fullName',
      'address',
      'job',
      'language',
      'learningReason',
      'referralReason',
    ]) {
      if (payload[field] !== undefined) {
        user[field] = String(payload[field]).trim();
      }
    }

    if (payload.status !== undefined) {
      user.status = payload.status === 'suspended' ? 'suspended' : 'active';
    }

    if (payload.role !== undefined) {
      user.role = normalizeRole(payload.role);
    }

    if (payload.password) {
      user.passwordHash = hashPassword(String(payload.password));
    }

    await writeUsers(users);
    sendJson(response, 200, { user: publicUser(user) });
  } catch {
    sendJson(response, 500, { message: 'تعذر تعديل بيانات اليوزر.' });
  }
}

async function deleteAdminUser(request, response, userId) {
  if (!requireAdmin(request, response)) {
    return;
  }

  try {
    const users = await readUsers();
    const nextUsers = users.filter((user) => user.id !== userId);
    if (nextUsers.length === users.length) {
      sendJson(response, 404, { message: 'اليوزر غير موجود.' });
      return;
    }

    await writeUsers(nextUsers);
    sendJson(response, 200, { message: 'تم حذف اليوزر.' });
  } catch {
    sendJson(response, 500, { message: 'تعذر حذف اليوزر.' });
  }
}

const server = http.createServer(async (request, response) => {
  const url = new URL(request.url, `http://${request.headers.host}`);

  if (request.method === 'OPTIONS') {
    sendJson(response, 204, {});
    return;
  }

  if (request.method === 'GET' && url.pathname === '/health') {
    sendJson(response, 200, { status: 'ok' });
    return;
  }

  if (request.method === 'GET' && url.pathname === '/app-download') {
    response.writeHead(302, { Location: appDownloadUrl });
    response.end();
    return;
  }

  if (request.method === 'GET' && url.pathname === '/admin') {
    response.writeHead(302, { Location: adminPanelUrl });
    response.end();
    return;
  }

  if (request.method === 'GET' && url.pathname === '/api/links') {
    sendJson(response, 200, {
      appDownloadUrl,
      adminPanelUrl,
    });
    return;
  }

  if (request.method === 'GET' && url.pathname === '/api/registration-form') {
    await getRegistrationForm(request, response);
    return;
  }

  if (request.method === 'POST' && url.pathname === '/api/register') {
    await register(request, response);
    return;
  }

  if (request.method === 'POST' && url.pathname === '/api/login') {
    await login(request, response);
    return;
  }

  const publicUserMatch = url.pathname.match(/^\/api\/users\/([^/]+)$/);
  if (publicUserMatch && request.method === 'GET') {
    await getPublicUser(request, response, publicUserMatch[1]);
    return;
  }

  if (request.method === 'POST' && url.pathname === '/api/admin/login') {
    await adminLogin(request, response);
    return;
  }

  if (url.pathname === '/api/admin/registration-form') {
    if (request.method === 'GET') {
      await getAdminRegistrationForm(request, response);
      return;
    }

    if (request.method === 'POST') {
      await updateAdminRegistrationForm(request, response);
      return;
    }
  }

  if (request.method === 'GET' && url.pathname === '/api/courses') {
    await listPublicCourses(request, response);
    return;
  }

  if (request.method === 'GET' && url.pathname === '/api/books') {
    await listBooks(request, response);
    return;
  }

  if (request.method === 'GET' && url.pathname === '/api/vocabulary') {
    await listVocabularyWords(request, response);
    return;
  }

  if (request.method === 'GET' && url.pathname === '/api/audio-resources') {
    await listAudioResources(request, response);
    return;
  }

  if (request.method === 'GET' && url.pathname === '/api/audio-proxy') {
    await proxyAudio(request, response, url);
    return;
  }

  if (request.method === 'GET' && url.pathname === '/api/notifications') {
    await listNotifications(request, response, url);
    return;
  }

  if (request.method === 'POST' && url.pathname === '/api/notifications') {
    await createNotification(request, response);
    return;
  }

  const notificationReadersMatch = url.pathname.match(/^\/api\/notifications\/([^/]+)\/readers$/);
  if (notificationReadersMatch && request.method === 'GET') {
    await listNotificationReaders(request, response, notificationReadersMatch[1]);
    return;
  }

  const notificationReadMatch = url.pathname.match(/^\/api\/notifications\/([^/]+)\/read$/);
  if (notificationReadMatch && request.method === 'POST') {
    await markNotificationRead(request, response, notificationReadMatch[1]);
    return;
  }

  const notificationDeleteMatch = url.pathname.match(/^\/api\/notifications\/([^/]+)$/);
  if (notificationDeleteMatch && request.method === 'DELETE') {
    await deleteNotification(request, response, notificationDeleteMatch[1]);
    return;
  }

  if (request.method === 'POST' && url.pathname === '/api/devices/register') {
    await registerDeviceToken(request, response);
    return;
  }

  if (request.method === 'POST' && url.pathname === '/api/app/activity') {
    await recordAppActivity(request, response);
    return;
  }

  if (request.method === 'GET' && url.pathname === '/api/app/streak') {
    await getAppStreak(request, response, url);
    return;
  }

  if (request.method === 'GET' && url.pathname === '/api/course-content') {
    await getStudentCourseContent(request, response, url);
    return;
  }

  if (url.pathname === '/api/questions') {
    if (request.method === 'GET') {
      await listStudentQuestions(request, response, url);
      return;
    }

    if (request.method === 'POST') {
      await createStudentQuestion(request, response);
      return;
    }
  }

  if (url.pathname === '/api/support/messages') {
    if (request.method === 'GET') {
      await listStudentSupportMessages(request, response, url);
      return;
    }

    if (request.method === 'POST') {
      await createSupportMessage(request, response);
      return;
    }
  }

  if (url.pathname === '/api/community/posts') {
    if (request.method === 'GET') {
      await listCommunityPosts(request, response);
      return;
    }

    if (request.method === 'POST') {
      await createCommunityPost(request, response);
      return;
    }
  }

  const communityReactionMatch = url.pathname.match(
    /^\/api\/community\/posts\/([^/]+)\/reaction$/
  );
  if (communityReactionMatch && request.method === 'POST') {
    await reactToCommunityPost(request, response, communityReactionMatch[1]);
    return;
  }

  const communityCommentMatch = url.pathname.match(
    /^\/api\/community\/posts\/([^/]+)\/comments$/
  );
  if (communityCommentMatch && request.method === 'POST') {
    await commentOnCommunityPost(request, response, communityCommentMatch[1]);
    return;
  }

  const communityShareMatch = url.pathname.match(
    /^\/api\/community\/posts\/([^/]+)\/share$/
  );
  if (communityShareMatch && request.method === 'POST') {
    await shareCommunityPost(request, response, communityShareMatch[1]);
    return;
  }

  if (url.pathname === '/api/watch-progress') {
    if (request.method === 'GET') {
      await listStudentWatchProgress(request, response, url);
      return;
    }

    if (request.method === 'POST') {
      await completePartWatch(request, response);
      return;
    }
  }

  if (request.method === 'POST' && url.pathname === '/api/subscriptions') {
    await createSubscriptionRequest(request, response);
    return;
  }

  if (request.method === 'GET' && url.pathname === '/api/admin/stats') {
    await adminStats(request, response);
    return;
  }

  if (request.method === 'GET' && url.pathname === '/api/admin/subscriptions') {
    await listAdminSubscriptions(request, response);
    return;
  }

  if (request.method === 'GET' && url.pathname === '/api/admin/questions') {
    await listAdminQuestions(request, response);
    return;
  }

  if (url.pathname === '/api/admin/support-messages') {
    if (request.method === 'GET') {
      await listAdminSupportMessages(request, response);
      return;
    }

    if (request.method === 'POST') {
      await createAdminSupportMessage(request, response);
      return;
    }
  }

  if (
    request.method === 'POST' &&
    url.pathname === '/api/admin/support-messages/read'
  ) {
    await markAdminSupportMessagesRead(request, response);
    return;
  }

  if (request.method === 'GET' && url.pathname === '/api/admin/watch-report') {
    await listAdminWatchReport(request, response, url);
    return;
  }

  if (request.method === 'GET' && url.pathname === '/api/admin/community/posts') {
    await listAdminCommunityPosts(request, response);
    return;
  }

  if (request.method === 'GET' && url.pathname === '/api/admin/activity-logs') {
    await listAdminActivityLogs(request, response);
    return;
  }

  if (request.method === 'GET' && url.pathname === '/api/admin/exam-results') {
    await listAdminExamResults(request, response);
    return;
  }

  if (url.pathname === '/api/admin/exams') {
    if (request.method === 'GET') {
      await listAdminExams(request, response);
      return;
    }

    if (request.method === 'POST') {
      await createAdminExam(request, response);
      return;
    }
  }

  if (request.method === 'GET' && url.pathname === '/api/exams') {
    await listStudentExams(request, response, url);
    return;
  }

  if (url.pathname === '/api/admin/notifications') {
    if (request.method === 'GET') {
      await listAdminNotifications(request, response);
      return;
    }

    if (request.method === 'POST') {
      await createNotification(request, response);
      return;
    }
  }

  const adminNotificationReadersMatch = url.pathname.match(/^\/api\/admin\/notifications\/([^/]+)\/readers$/);
  if (adminNotificationReadersMatch && request.method === 'GET') {
    await listNotificationReaders(request, response, adminNotificationReadersMatch[1]);
    return;
  }

  const adminNotificationDeleteMatch = url.pathname.match(/^\/api\/admin\/notifications\/([^/]+)$/);
  if (adminNotificationDeleteMatch && request.method === 'DELETE') {
    await deleteNotification(request, response, adminNotificationDeleteMatch[1]);
    return;
  }

  if (url.pathname === '/api/admin/users') {
    if (request.method === 'GET') {
      await listAdminUsers(request, response);
      return;
    }

    if (request.method === 'POST') {
      await createAdminUser(request, response);
      return;
    }
  }

  if (url.pathname === '/api/admin/courses') {
    if (request.method === 'GET') {
      await listCourseParts(request, response);
      return;
    }

    if (request.method === 'POST') {
      await createCoursePart(request, response);
      return;
    }
  }

  if (url.pathname === '/api/admin/books') {
    if (request.method === 'GET') {
      await listAdminBooks(request, response);
      return;
    }

    if (request.method === 'POST') {
      await createAdminBook(request, response);
      return;
    }
  }

  if (url.pathname === '/api/admin/vocabulary') {
    if (request.method === 'GET') {
      await listAdminVocabularyWords(request, response);
      return;
    }

    if (request.method === 'POST') {
      await createVocabularyWord(request, response);
      return;
    }
  }

  if (url.pathname === '/api/admin/audio-resources') {
    if (request.method === 'GET') {
      await listAdminAudioResources(request, response);
      return;
    }

    if (request.method === 'POST') {
      await createAudioResource(request, response);
      return;
    }
  }

  if (url.pathname === '/api/admin/audio-resources/google-drive-folder') {
    if (request.method === 'POST') {
      await importGoogleDriveAudioFolder(request, response);
      return;
    }
  }

  if (url.pathname === '/api/admin/audio-resources/audit') {
    if (request.method === 'GET') {
      await auditAudioResources(request, response);
      return;
    }
  }

  const userMatch = url.pathname.match(/^\/api\/admin\/users\/([^/]+)$/);
  if (userMatch && request.method === 'PATCH') {
    await updateAdminUser(request, response, userMatch[1]);
    return;
  }

  if (userMatch && request.method === 'DELETE') {
    await deleteAdminUser(request, response, userMatch[1]);
    return;
  }

  const userUpdateActionMatch = url.pathname.match(
    /^\/api\/admin\/users\/([^/]+)\/update$/
  );
  if (userUpdateActionMatch && request.method === 'POST') {
    await updateAdminUser(request, response, userUpdateActionMatch[1]);
    return;
  }

  const userDeleteActionMatch = url.pathname.match(
    /^\/api\/admin\/users\/([^/]+)\/delete$/
  );
  if (userDeleteActionMatch && request.method === 'POST') {
    await deleteAdminUser(request, response, userDeleteActionMatch[1]);
    return;
  }

  const courseDeleteActionMatch = url.pathname.match(
    /^\/api\/admin\/courses\/([^/]+)\/delete$/
  );
  if (courseDeleteActionMatch && request.method === 'POST') {
    await deleteCoursePart(request, response, courseDeleteActionMatch[1]);
    return;
  }

  const courseUpdateActionMatch = url.pathname.match(
    /^\/api\/admin\/courses\/([^/]+)\/update$/
  );
  if (courseUpdateActionMatch && request.method === 'POST') {
    await updateCoursePart(request, response, courseUpdateActionMatch[1]);
    return;
  }

  const bookUpdateActionMatch = url.pathname.match(
    /^\/api\/admin\/books\/([^/]+)$/
  );
  if (bookUpdateActionMatch && request.method === 'POST') {
    await updateAdminBook(request, response, bookUpdateActionMatch[1]);
    return;
  }

  const bookDeleteActionMatch = url.pathname.match(
    /^\/api\/admin\/books\/([^/]+)\/delete$/
  );
  if (bookDeleteActionMatch && request.method === 'POST') {
    await deleteAdminBook(request, response, bookDeleteActionMatch[1]);
    return;
  }

  const vocabularyDeleteActionMatch = url.pathname.match(
    /^\/api\/admin\/vocabulary\/([^/]+)\/delete$/
  );
  if (vocabularyDeleteActionMatch && request.method === 'POST') {
    await deleteVocabularyWord(request, response, vocabularyDeleteActionMatch[1]);
    return;
  }

  const audioDeleteActionMatch = url.pathname.match(
    /^\/api\/admin\/audio-resources\/([^/]+)\/delete$/
  );
  if (audioDeleteActionMatch && request.method === 'POST') {
    await deleteAudioResource(request, response, audioDeleteActionMatch[1]);
    return;
  }

  const examDeleteActionMatch = url.pathname.match(
    /^\/api\/admin\/exams\/([^/]+)\/delete$/
  );
  if (examDeleteActionMatch && request.method === 'POST') {
    await deleteAdminExam(request, response, examDeleteActionMatch[1]);
    return;
  }

  const examQuestionsActionMatch = url.pathname.match(
    /^\/api\/admin\/exams\/([^/]+)\/questions$/
  );
  if (examQuestionsActionMatch && request.method === 'POST') {
    await updateAdminExamQuestions(request, response, examQuestionsActionMatch[1]);
    return;
  }

  const examSubmitActionMatch = url.pathname.match(
    /^\/api\/exams\/([^/]+)\/submit$/
  );
  if (examSubmitActionMatch && request.method === 'POST') {
    await submitStudentExam(request, response, examSubmitActionMatch[1]);
    return;
  }

  const subscriptionApproveActionMatch = url.pathname.match(
    /^\/api\/admin\/subscriptions\/([^/]+)\/approve$/
  );
  if (subscriptionApproveActionMatch && request.method === 'POST') {
    await approveSubscription(request, response, subscriptionApproveActionMatch[1]);
    return;
  }

  const questionAnswerActionMatch = url.pathname.match(
    /^\/api\/admin\/questions\/([^/]+)\/answer$/
  );
  if (questionAnswerActionMatch && request.method === 'POST') {
    await answerQuestion(request, response, questionAnswerActionMatch[1]);
    return;
  }

  const supportAnswerActionMatch = url.pathname.match(
    /^\/api\/admin\/support-messages\/([^/]+)\/answer$/
  );
  if (supportAnswerActionMatch && request.method === 'POST') {
    await answerSupportMessage(request, response, supportAnswerActionMatch[1]);
    return;
  }

  const adminCommunityDeleteMatch = url.pathname.match(
    /^\/api\/admin\/community\/posts\/([^/]+)\/delete$/
  );
  if (adminCommunityDeleteMatch && request.method === 'POST') {
    await deleteAdminCommunityPost(request, response, adminCommunityDeleteMatch[1]);
    return;
  }

  const adminCommunityReactionMatch = url.pathname.match(
    /^\/api\/admin\/community\/posts\/([^/]+)\/reaction$/
  );
  if (adminCommunityReactionMatch && request.method === 'POST') {
    await reactToAdminCommunityPost(
      request,
      response,
      adminCommunityReactionMatch[1]
    );
    return;
  }

  const adminCommunityCommentMatch = url.pathname.match(
    /^\/api\/admin\/community\/posts\/([^/]+)\/comments$/
  );
  if (adminCommunityCommentMatch && request.method === 'POST') {
    await commentOnAdminCommunityPost(
      request,
      response,
      adminCommunityCommentMatch[1]
    );
    return;
  }

  const adminCommunityCommentDeleteMatch = url.pathname.match(
    /^\/api\/admin\/community\/posts\/([^/]+)\/comments\/([^/]+)\/delete$/
  );
  if (adminCommunityCommentDeleteMatch && request.method === 'POST') {
    await deleteAdminCommunityComment(
      request,
      response,
      adminCommunityCommentDeleteMatch[1],
      adminCommunityCommentDeleteMatch[2]
    );
    return;
  }

  const adminCommunityBanMatch = url.pathname.match(
    /^\/api\/admin\/community\/users\/([^/]+)\/ban$/
  );
  if (adminCommunityBanMatch && request.method === 'POST') {
    await banCommunityUser(request, response, adminCommunityBanMatch[1]);
    return;
  }

  if (request.method === 'GET' && url.pathname === '/api/support/messages') {
  await listSupportMessages(request, response, url);
  return;
}

if (request.method === 'POST' && url.pathname === '/api/support/messages') {
  await createSupportMessage(request, response);
  return;
}

if (request.method === 'GET' && url.pathname === '/api/admin/support-messages') {
  await listAdminSupportMessages(request, response);
  return;
}

if (request.method === 'POST' && url.pathname === '/api/admin/support-messages') {
  await sendAdminSupportMessage(request, response);
  return;
}

const supportAnswerMatch = url.pathname.match(
  /^\/api\/admin\/support-messages\/([^/]+)\/answer$/
);

if (request.method === 'POST' && supportAnswerMatch) {
  await answerSupportMessage(request, response, supportAnswerMatch[1]);
  return;
}

sendJson(response, 404, { message: 'Route not found.' });
});

server.listen(port, host, () => {
  console.log(`Lingova backend is running on http://${host}:${port}`);
  console.log(
    useSupabase
      ? 'Lingova storage: Supabase PostgreSQL'
      : `Lingova data directory: ${dataDir}`
  );
  if (dataDir === bundledDataDir) {
    console.log(
      'Warning: using bundled backend/data. Configure LINGOVA_DATA_DIR or a Railway volume to keep chats, exam results, certificates, and community messages after deploys.'
    );
  }
  if (
    !useSupabase &&
    isRailway &&
    !process.env.LINGOVA_DATA_DIR &&
    !process.env.RAILWAY_VOLUME_MOUNT_PATH
  ) {
    console.log(
      'Warning: Railway is running without a configured persistent volume. Data written to /data may be lost after a redeploy. Add a Railway volume mounted at /data or set LINGOVA_DATA_DIR to the mounted path.'
    );
  }
  console.log(`Admin login: ${adminEmail} / ${adminPassword}`);
});
