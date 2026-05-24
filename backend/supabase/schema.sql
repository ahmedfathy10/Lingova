create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.safe_timestamptz(value text)
returns timestamptz
language plpgsql
immutable
as $$
begin
  if value is null or btrim(value) = '' then
    return null;
  end if;

  return value::timestamptz;
exception when others then
  return null;
end;
$$;

create or replace function public.safe_date(value text)
returns date
language plpgsql
immutable
as $$
begin
  if value is null or btrim(value) = '' then
    return null;
  end if;

  return value::date;
exception when others then
  return null;
end;
$$;

create or replace function public.safe_int(value text, fallback integer default 0)
returns integer
language plpgsql
immutable
as $$
begin
  if value is null or btrim(value) = '' then
    return fallback;
  end if;

  return value::integer;
exception when others then
  return fallback;
end;
$$;

create or replace function public.safe_numeric(value text, fallback numeric default 0)
returns numeric
language plpgsql
immutable
as $$
declare
  normalized text;
begin
  if value is null or btrim(value) = '' then
    return fallback;
  end if;

  normalized := regexp_replace(value, '[^0-9.\-]+', '', 'g');

  if normalized is null or normalized in ('', '-', '.', '-.') then
    return fallback;
  end if;

  return normalized::numeric;
exception when others then
  return fallback;
end;
$$;

create or replace function public.safe_bool(value text, fallback boolean default false)
returns boolean
language plpgsql
immutable
as $$
begin
  if value is null or btrim(value) = '' then
    return fallback;
  end if;

  return value::boolean;
exception when others then
  return fallback;
end;
$$;

do $$
declare
  column_record record;
  constraint_record record;
begin
  for constraint_record in
    select table_name, constraint_name
    from information_schema.table_constraints
    where table_schema = 'public'
      and constraint_type = 'FOREIGN KEY'
      and constraint_name in (
        'levels_course_id_fkey',
        'lessons_course_id_fkey',
        'lessons_level_id_fkey',
        'lesson_materials_course_id_fkey',
        'lesson_materials_level_id_fkey',
        'lesson_materials_lesson_id_fkey',
        'lesson_material_files_material_id_fkey',
        'exams_course_id_fkey',
        'exams_level_id_fkey',
        'exam_questions_exam_id_fkey',
        'exam_attempts_exam_id_fkey',
        'certificates_exam_attempt_id_fkey',
        'certificates_student_id_fkey',
        'enrollments_profile_id_fkey',
        'enrollments_course_id_fkey',
        'enrollments_student_id_fkey',
        'payments_enrollment_id_fkey',
        'progress_student_id_fkey',
        'audio_resource_items_audio_resource_id_fkey'
      )
  loop
    execute format(
      'alter table public.%I drop constraint if exists %I',
      constraint_record.table_name,
      constraint_record.constraint_name
    );
  end loop;

  for column_record in
    select *
    from (values
      ('profiles', 'id'),
      ('courses', 'id'),
      ('levels', 'id'),
      ('levels', 'course_id'),
      ('lessons', 'id'),
      ('lessons', 'course_id'),
      ('lessons', 'level_id'),
      ('lesson_materials', 'id'),
      ('lesson_materials', 'course_id'),
      ('lesson_materials', 'level_id'),
      ('lesson_materials', 'lesson_id'),
      ('lesson_material_files', 'id'),
      ('lesson_material_files', 'material_id'),
      ('books', 'id'),
      ('exams', 'id'),
      ('exams', 'course_id'),
      ('exams', 'level_id'),
      ('exam_questions', 'id'),
      ('exam_questions', 'exam_id'),
      ('exam_attempts', 'id'),
      ('exam_attempts', 'exam_id'),
      ('exam_attempts', 'student_id'),
      ('certificates', 'id'),
      ('certificates', 'exam_attempt_id'),
      ('certificates', 'exam_id'),
      ('certificates', 'student_id'),
      ('enrollments', 'id'),
      ('enrollments', 'profile_id'),
      ('enrollments', 'course_id'),
      ('enrollments', 'student_id'),
      ('payments', 'id'),
      ('payments', 'enrollment_id'),
      ('payments', 'student_id'),
      ('progress', 'id'),
      ('progress', 'student_id'),
      ('notifications', 'id'),
      ('chat_messages', 'id'),
      ('chat_messages', 'student_id'),
      ('student_questions', 'id'),
      ('student_questions', 'student_id'),
      ('community_posts', 'id'),
      ('community_posts', 'student_id'),
      ('audio_resources', 'id'),
      ('audio_resource_items', 'id'),
      ('audio_resource_items', 'audio_resource_id'),
      ('vocabulary_words', 'id'),
      ('device_tokens', 'id'),
      ('device_tokens', 'user_id'),
      ('activity_logs', 'id'),
      ('activity_logs', 'user_id'),
      ('app_sessions', 'id'),
      ('app_sessions', 'user_id')
    ) as columns_to_normalize(table_name, column_name)
  loop
    if exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = column_record.table_name
        and column_name = column_record.column_name
        and data_type <> 'text'
    ) then
      execute format(
        'alter table public.%I alter column %I drop identity if exists',
        column_record.table_name,
        column_record.column_name
      );
      execute format(
        'alter table public.%I alter column %I drop default',
        column_record.table_name,
        column_record.column_name
      );
      execute format(
        'alter table public.%I alter column %I type text using %I::text',
        column_record.table_name,
        column_record.column_name,
        column_record.column_name
      );
    end if;
  end loop;
end;
$$;

create table if not exists public.profiles (
  id text primary key,
  full_name text not null default '',
  phone text not null default '',
  password_hash text not null default '',
  address text not null default '',
  job text not null default '',
  language text not null default '',
  learning_reason text not null default '',
  referral_reason text not null default '',
  status text not null default 'active',
  role text not null default 'student',
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  created_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.courses (
  id text primary key,
  language text not null default '',
  language_code text not null default '',
  title text not null default '',
  course_type text not null default 'free',
  price numeric not null default 0,
  course_level text not null default '',
  image_data_url text not null default '',
  learning_outcomes jsonb not null default '[]'::jsonb,
  created_by text not null default '',
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  created_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (language, title)
);

create table if not exists public.levels (
  id text primary key,
  course_id text references public.courses(id) on delete cascade,
  language text not null default '',
  course_title text not null default '',
  title text not null default '',
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  created_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (language, course_title, title)
);

create table if not exists public.lessons (
  id text primary key,
  course_id text references public.courses(id) on delete cascade,
  level_id text references public.levels(id) on delete cascade,
  language text not null default '',
  course_title text not null default '',
  level_title text not null default '',
  title text not null default '',
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  created_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (language, course_title, level_title, title)
);

create table if not exists public.lesson_materials (
  id text primary key,
  course_id text references public.courses(id) on delete cascade,
  level_id text references public.levels(id) on delete cascade,
  lesson_id text references public.lessons(id) on delete cascade,
  language text not null default '',
  course_title text not null default '',
  level_title text not null default '',
  lesson_title text not null default '',
  title text not null default '',
  vimeo_url text not null default '',
  duration text not null default '',
  material_type text not null default 'video',
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  created_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.lesson_material_files (
  id text primary key default gen_random_uuid()::text,
  material_id text references public.lesson_materials(id) on delete cascade,
  title text not null default '',
  url text not null default '',
  file_type text not null default '',
  storage_bucket text,
  storage_path text,
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.books (
  id text primary key,
  title text not null default '',
  subtitle text not null default '',
  language text not null default '',
  level text not null default '',
  url text not null default '',
  created_by text not null default '',
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  created_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.exams (
  id text primary key,
  course_id text references public.courses(id) on delete set null,
  level_id text references public.levels(id) on delete set null,
  title text not null default '',
  description text not null default '',
  exam_type text not null default 'lecture_quiz',
  course_title text not null default '',
  course_language text not null default '',
  level_title text not null default '',
  after_lecture_index integer not null default 0,
  pass_score integer not null default 60,
  duration_minutes integer not null default 10,
  created_by text not null default '',
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  created_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.exam_questions (
  id text primary key,
  exam_id text not null references public.exams(id) on delete cascade,
  question_type text not null default 'mcq',
  prompt text not null default '',
  options jsonb not null default '[]'::jsonb,
  correct_answers jsonb not null default '[]'::jsonb,
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.exam_attempts (
  id text primary key,
  exam_id text references public.exams(id) on delete set null,
  student_id text references public.profiles(id) on delete set null,
  student_name text not null default '',
  course_title text not null default '',
  course_language text not null default '',
  level_title text not null default '',
  exam_type text not null default '',
  score integer not null default 0,
  total_questions integer not null default 0,
  correct_answers integer not null default 0,
  passed boolean not null default false,
  answers jsonb not null default '{}'::jsonb,
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  submitted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.certificates (
  id text primary key default gen_random_uuid()::text,
  exam_attempt_id text references public.exam_attempts(id) on delete cascade,
  exam_id text,
  student_id text references public.profiles(id) on delete set null,
  student_name text not null default '',
  course_title text not null default '',
  course_language text not null default '',
  level_title text not null default '',
  score integer not null default 0,
  issued_at timestamptz not null default now(),
  certificate_url text not null default '',
  raw_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.enrollments (
  id text primary key,
  profile_id text references public.profiles(id) on delete set null,
  course_id text references public.courses(id) on delete set null,
  student_id text references public.profiles(id) on delete set null,
  student_name text not null default '',
  student_phone text not null default '',
  student_address text not null default '',
  student_job text not null default '',
  student_language text not null default '',
  course_key text not null default '',
  course_title text not null default '',
  course_language text not null default '',
  course_level text not null default '',
  course_price text not null default '',
  status text not null default 'approved',
  payment_status text not null default '',
  opened_by text not null default '',
  approved_by text not null default '',
  source_collection text not null default '',
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  requested_at timestamptz,
  opened_at timestamptz,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payments (
  id text primary key,
  enrollment_id text references public.enrollments(id) on delete cascade,
  student_id text not null default '',
  course_title text not null default '',
  course_language text not null default '',
  amount numeric not null default 0,
  method text not null default '',
  payment_phone text not null default '',
  status text not null default 'paid',
  source_collection text not null default '',
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.progress (
  id text primary key,
  student_id text references public.profiles(id) on delete set null,
  student_name text not null default '',
  student_phone text not null default '',
  course_title text not null default '',
  course_language text not null default '',
  level_title text not null default '',
  lesson_title text not null default '',
  part_title text not null default '',
  vimeo_url text not null default '',
  duration text not null default '',
  watch_date date,
  watch_count integer not null default 1,
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id text primary key,
  title text not null default '',
  body text not null default '',
  notification_type text not null default 'general',
  created_by text not null default '',
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  created_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.chat_messages (
  id text primary key,
  student_id text not null default '',
  student_name text not null default '',
  student_phone text not null default '',
  message text not null default '',
  answer text not null default '',
  sender text not null default 'student',
  status text not null default 'open',
  read_by_admin boolean not null default false,
  read_by_student boolean not null default false,
  attachments jsonb not null default '[]'::jsonb,
  answered_by text not null default '',
  channel text not null default 'support',
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  created_at timestamptz,
  answered_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.student_questions (
  id text primary key,
  student_id text not null default '',
  student_name text not null default '',
  student_phone text not null default '',
  course_title text not null default '',
  course_language text not null default '',
  level_title text not null default '',
  lesson_title text not null default '',
  part_title text not null default '',
  vimeo_url text not null default '',
  question text not null default '',
  answer text not null default '',
  status text not null default 'pending',
  attachments jsonb not null default '[]'::jsonb,
  answered_by text not null default '',
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  created_at timestamptz,
  answered_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.community_posts (
  id text primary key,
  student_id text not null default '',
  student_name text not null default '',
  student_phone text not null default '',
  content text not null default '',
  image_url text not null default '',
  attachments jsonb not null default '[]'::jsonb,
  reactions jsonb not null default '{}'::jsonb,
  comments jsonb not null default '[]'::jsonb,
  shares integer not null default 0,
  status text not null default 'active',
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  created_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.audio_resources (
  id text primary key,
  title text not null default '',
  description text not null default '',
  course text not null default '',
  course_language text not null default '',
  level text not null default '',
  access_type text not null default 'free',
  file_type text not null default 'audio',
  link_type text not null default 'clip',
  url text not null default '',
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  created_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.audio_resource_items (
  id text primary key,
  audio_resource_id text references public.audio_resources(id) on delete cascade,
  title text not null default '',
  url text not null default '',
  file_type text not null default 'audio',
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.vocabulary_words (
  id text primary key,
  language text not null default '',
  word text not null default '',
  translation text not null default '',
  pronunciation text not null default '',
  example text not null default '',
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  created_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.device_tokens (
  id text primary key,
  user_id text not null default '',
  token text not null default '',
  platform text not null default '',
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  created_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.activity_logs (
  id text primary key,
  user_id text not null default '',
  user_name text not null default '',
  user_phone text not null default '',
  action text not null default '',
  label text not null default '',
  details text not null default '',
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  created_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.app_sessions (
  id text primary key,
  session_id text not null default '',
  user_id text not null default '',
  user_name text not null default '',
  user_phone text not null default '',
  raw_payload jsonb not null default '{}'::jsonb,
  source_position integer not null default 0,
  opened_at timestamptz,
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.app_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  description text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles add column if not exists full_name text not null default '';
alter table public.profiles add column if not exists phone text not null default '';
alter table public.profiles add column if not exists password_hash text not null default '';
alter table public.profiles add column if not exists address text not null default '';
alter table public.profiles add column if not exists job text not null default '';
alter table public.profiles add column if not exists language text not null default '';
alter table public.profiles add column if not exists learning_reason text not null default '';
alter table public.profiles add column if not exists referral_reason text not null default '';
alter table public.profiles add column if not exists status text not null default 'active';
alter table public.profiles add column if not exists role text not null default 'student';
alter table public.profiles add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.profiles add column if not exists source_position integer not null default 0;
alter table public.profiles add column if not exists created_at timestamptz;
alter table public.profiles add column if not exists updated_at timestamptz not null default now();

alter table public.courses add column if not exists language text not null default '';
alter table public.courses add column if not exists language_code text not null default '';
alter table public.courses add column if not exists title text not null default '';
alter table public.courses add column if not exists course_type text not null default 'free';
alter table public.courses add column if not exists price numeric not null default 0;
alter table public.courses add column if not exists course_level text not null default '';
alter table public.courses add column if not exists image_data_url text not null default '';
alter table public.courses add column if not exists learning_outcomes jsonb not null default '[]'::jsonb;
alter table public.courses add column if not exists created_by text not null default '';
alter table public.courses add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.courses add column if not exists source_position integer not null default 0;
alter table public.courses add column if not exists created_at timestamptz;
alter table public.courses add column if not exists updated_at timestamptz not null default now();

alter table public.levels add column if not exists course_id text;
alter table public.levels add column if not exists language text not null default '';
alter table public.levels add column if not exists course_title text not null default '';
alter table public.levels add column if not exists title text not null default '';
alter table public.levels add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.levels add column if not exists source_position integer not null default 0;
alter table public.levels add column if not exists created_at timestamptz;
alter table public.levels add column if not exists updated_at timestamptz not null default now();

alter table public.lessons add column if not exists course_id text;
alter table public.lessons add column if not exists level_id text;
alter table public.lessons add column if not exists language text not null default '';
alter table public.lessons add column if not exists course_title text not null default '';
alter table public.lessons add column if not exists level_title text not null default '';
alter table public.lessons add column if not exists title text not null default '';
alter table public.lessons add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.lessons add column if not exists source_position integer not null default 0;
alter table public.lessons add column if not exists created_at timestamptz;
alter table public.lessons add column if not exists updated_at timestamptz not null default now();

alter table public.lesson_materials add column if not exists course_id text;
alter table public.lesson_materials add column if not exists level_id text;
alter table public.lesson_materials add column if not exists lesson_id text;
alter table public.lesson_materials add column if not exists language text not null default '';
alter table public.lesson_materials add column if not exists course_title text not null default '';
alter table public.lesson_materials add column if not exists level_title text not null default '';
alter table public.lesson_materials add column if not exists lesson_title text not null default '';
alter table public.lesson_materials add column if not exists title text not null default '';
alter table public.lesson_materials add column if not exists vimeo_url text not null default '';
alter table public.lesson_materials add column if not exists duration text not null default '';
alter table public.lesson_materials add column if not exists material_type text not null default 'video';
alter table public.lesson_materials add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.lesson_materials add column if not exists source_position integer not null default 0;
alter table public.lesson_materials add column if not exists created_at timestamptz;
alter table public.lesson_materials add column if not exists updated_at timestamptz not null default now();

alter table public.lesson_material_files add column if not exists material_id text;
alter table public.lesson_material_files add column if not exists title text not null default '';
alter table public.lesson_material_files add column if not exists url text not null default '';
alter table public.lesson_material_files add column if not exists file_type text not null default '';
alter table public.lesson_material_files add column if not exists storage_bucket text;
alter table public.lesson_material_files add column if not exists storage_path text;
alter table public.lesson_material_files add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.lesson_material_files add column if not exists source_position integer not null default 0;
alter table public.lesson_material_files add column if not exists created_at timestamptz not null default now();
alter table public.lesson_material_files add column if not exists updated_at timestamptz not null default now();

alter table public.books add column if not exists title text not null default '';
alter table public.books add column if not exists subtitle text not null default '';
alter table public.books add column if not exists language text not null default '';
alter table public.books add column if not exists level text not null default '';
alter table public.books add column if not exists url text not null default '';
alter table public.books add column if not exists created_by text not null default '';
alter table public.books add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.books add column if not exists source_position integer not null default 0;
alter table public.books add column if not exists created_at timestamptz;
alter table public.books add column if not exists updated_at timestamptz not null default now();

alter table public.exams add column if not exists course_id text;
alter table public.exams add column if not exists level_id text;
alter table public.exams add column if not exists title text not null default '';
alter table public.exams add column if not exists description text not null default '';
alter table public.exams add column if not exists exam_type text not null default 'lecture_quiz';
alter table public.exams add column if not exists course_title text not null default '';
alter table public.exams add column if not exists course_language text not null default '';
alter table public.exams add column if not exists level_title text not null default '';
alter table public.exams add column if not exists after_lecture_index integer not null default 0;
alter table public.exams add column if not exists pass_score integer not null default 60;
alter table public.exams add column if not exists duration_minutes integer not null default 10;
alter table public.exams add column if not exists created_by text not null default '';
alter table public.exams add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.exams add column if not exists source_position integer not null default 0;
alter table public.exams add column if not exists created_at timestamptz;
alter table public.exams add column if not exists updated_at timestamptz not null default now();

alter table public.exam_questions add column if not exists exam_id text;
alter table public.exam_questions add column if not exists question_type text not null default 'mcq';
alter table public.exam_questions add column if not exists prompt text not null default '';
alter table public.exam_questions add column if not exists options jsonb not null default '[]'::jsonb;
alter table public.exam_questions add column if not exists correct_answers jsonb not null default '[]'::jsonb;
alter table public.exam_questions add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.exam_questions add column if not exists source_position integer not null default 0;
alter table public.exam_questions add column if not exists created_at timestamptz not null default now();
alter table public.exam_questions add column if not exists updated_at timestamptz not null default now();

alter table public.exam_attempts add column if not exists exam_id text;
alter table public.exam_attempts add column if not exists student_id text;
alter table public.exam_attempts add column if not exists student_name text not null default '';
alter table public.exam_attempts add column if not exists course_title text not null default '';
alter table public.exam_attempts add column if not exists course_language text not null default '';
alter table public.exam_attempts add column if not exists level_title text not null default '';
alter table public.exam_attempts add column if not exists exam_type text not null default '';
alter table public.exam_attempts add column if not exists score integer not null default 0;
alter table public.exam_attempts add column if not exists total_questions integer not null default 0;
alter table public.exam_attempts add column if not exists correct_answers integer not null default 0;
alter table public.exam_attempts add column if not exists passed boolean not null default false;
alter table public.exam_attempts add column if not exists answers jsonb not null default '{}'::jsonb;
alter table public.exam_attempts add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.exam_attempts add column if not exists source_position integer not null default 0;
alter table public.exam_attempts add column if not exists submitted_at timestamptz;
alter table public.exam_attempts add column if not exists created_at timestamptz not null default now();
alter table public.exam_attempts add column if not exists updated_at timestamptz not null default now();

alter table public.certificates add column if not exists exam_attempt_id text;
alter table public.certificates add column if not exists exam_id text;
alter table public.certificates add column if not exists student_id text;
alter table public.certificates add column if not exists student_name text not null default '';
alter table public.certificates add column if not exists course_title text not null default '';
alter table public.certificates add column if not exists course_language text not null default '';
alter table public.certificates add column if not exists level_title text not null default '';
alter table public.certificates add column if not exists score integer not null default 0;
alter table public.certificates add column if not exists issued_at timestamptz not null default now();
alter table public.certificates add column if not exists certificate_url text not null default '';
alter table public.certificates add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.certificates add column if not exists created_at timestamptz not null default now();
alter table public.certificates add column if not exists updated_at timestamptz not null default now();

alter table public.enrollments add column if not exists profile_id text;
alter table public.enrollments add column if not exists course_id text;
alter table public.enrollments add column if not exists student_id text;
alter table public.enrollments add column if not exists student_name text not null default '';
alter table public.enrollments add column if not exists student_phone text not null default '';
alter table public.enrollments add column if not exists student_address text not null default '';
alter table public.enrollments add column if not exists student_job text not null default '';
alter table public.enrollments add column if not exists student_language text not null default '';
alter table public.enrollments add column if not exists course_key text not null default '';
alter table public.enrollments add column if not exists course_title text not null default '';
alter table public.enrollments add column if not exists course_language text not null default '';
alter table public.enrollments add column if not exists course_level text not null default '';
alter table public.enrollments add column if not exists course_price text not null default '';
alter table public.enrollments add column if not exists status text not null default 'approved';
alter table public.enrollments add column if not exists payment_status text not null default '';
alter table public.enrollments add column if not exists opened_by text not null default '';
alter table public.enrollments add column if not exists approved_by text not null default '';
alter table public.enrollments add column if not exists source_collection text not null default '';
alter table public.enrollments add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.enrollments add column if not exists source_position integer not null default 0;
alter table public.enrollments add column if not exists requested_at timestamptz;
alter table public.enrollments add column if not exists opened_at timestamptz;
alter table public.enrollments add column if not exists approved_at timestamptz;
alter table public.enrollments add column if not exists created_at timestamptz not null default now();
alter table public.enrollments add column if not exists updated_at timestamptz not null default now();

alter table public.payments add column if not exists enrollment_id text;
alter table public.payments add column if not exists student_id text not null default '';
alter table public.payments add column if not exists course_title text not null default '';
alter table public.payments add column if not exists course_language text not null default '';
alter table public.payments add column if not exists amount numeric not null default 0;
alter table public.payments add column if not exists method text not null default '';
alter table public.payments add column if not exists payment_phone text not null default '';
alter table public.payments add column if not exists status text not null default 'paid';
alter table public.payments add column if not exists source_collection text not null default '';
alter table public.payments add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.payments add column if not exists source_position integer not null default 0;
alter table public.payments add column if not exists paid_at timestamptz;
alter table public.payments add column if not exists created_at timestamptz not null default now();
alter table public.payments add column if not exists updated_at timestamptz not null default now();

alter table public.progress add column if not exists student_id text;
alter table public.progress add column if not exists student_name text not null default '';
alter table public.progress add column if not exists student_phone text not null default '';
alter table public.progress add column if not exists course_title text not null default '';
alter table public.progress add column if not exists course_language text not null default '';
alter table public.progress add column if not exists level_title text not null default '';
alter table public.progress add column if not exists lesson_title text not null default '';
alter table public.progress add column if not exists part_title text not null default '';
alter table public.progress add column if not exists vimeo_url text not null default '';
alter table public.progress add column if not exists duration text not null default '';
alter table public.progress add column if not exists watch_date date;
alter table public.progress add column if not exists watch_count integer not null default 1;
alter table public.progress add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.progress add column if not exists source_position integer not null default 0;
alter table public.progress add column if not exists completed_at timestamptz;
alter table public.progress add column if not exists created_at timestamptz not null default now();
alter table public.progress add column if not exists updated_at timestamptz not null default now();

alter table public.notifications add column if not exists title text not null default '';
alter table public.notifications add column if not exists body text not null default '';
alter table public.notifications add column if not exists notification_type text not null default 'general';
alter table public.notifications add column if not exists created_by text not null default '';
alter table public.notifications add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.notifications add column if not exists source_position integer not null default 0;
alter table public.notifications add column if not exists created_at timestamptz;
alter table public.notifications add column if not exists updated_at timestamptz not null default now();

alter table public.chat_messages add column if not exists student_id text not null default '';
alter table public.chat_messages add column if not exists student_name text not null default '';
alter table public.chat_messages add column if not exists student_phone text not null default '';
alter table public.chat_messages add column if not exists message text not null default '';
alter table public.chat_messages add column if not exists answer text not null default '';
alter table public.chat_messages add column if not exists sender text not null default 'student';
alter table public.chat_messages add column if not exists status text not null default 'open';
alter table public.chat_messages add column if not exists read_by_admin boolean not null default false;
alter table public.chat_messages add column if not exists read_by_student boolean not null default false;
alter table public.chat_messages add column if not exists answered_by text not null default '';
alter table public.chat_messages add column if not exists channel text not null default 'support';
alter table public.chat_messages add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.chat_messages add column if not exists source_position integer not null default 0;
alter table public.chat_messages add column if not exists created_at timestamptz;
alter table public.chat_messages add column if not exists answered_at timestamptz;
alter table public.chat_messages add column if not exists updated_at timestamptz not null default now();

alter table public.student_questions add column if not exists student_id text not null default '';
alter table public.student_questions add column if not exists student_name text not null default '';
alter table public.student_questions add column if not exists student_phone text not null default '';
alter table public.student_questions add column if not exists course_title text not null default '';
alter table public.student_questions add column if not exists course_language text not null default '';
alter table public.student_questions add column if not exists level_title text not null default '';
alter table public.student_questions add column if not exists lesson_title text not null default '';
alter table public.student_questions add column if not exists part_title text not null default '';
alter table public.student_questions add column if not exists vimeo_url text not null default '';
alter table public.student_questions add column if not exists question text not null default '';
alter table public.student_questions add column if not exists answer text not null default '';
alter table public.student_questions add column if not exists status text not null default 'pending';
alter table public.student_questions add column if not exists answered_by text not null default '';
alter table public.student_questions add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.student_questions add column if not exists source_position integer not null default 0;
alter table public.student_questions add column if not exists created_at timestamptz;
alter table public.student_questions add column if not exists answered_at timestamptz;
alter table public.student_questions add column if not exists updated_at timestamptz not null default now();

alter table public.community_posts add column if not exists student_id text not null default '';
alter table public.community_posts add column if not exists student_name text not null default '';
alter table public.community_posts add column if not exists student_phone text not null default '';
alter table public.community_posts add column if not exists content text not null default '';
alter table public.community_posts add column if not exists image_url text not null default '';
alter table public.community_posts add column if not exists attachments jsonb not null default '[]'::jsonb;
alter table public.community_posts add column if not exists reactions jsonb not null default '{}'::jsonb;
alter table public.community_posts add column if not exists comments jsonb not null default '[]'::jsonb;
alter table public.community_posts add column if not exists shares integer not null default 0;
alter table public.community_posts add column if not exists status text not null default 'active';
alter table public.community_posts add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.community_posts add column if not exists source_position integer not null default 0;
alter table public.community_posts add column if not exists created_at timestamptz;
alter table public.community_posts add column if not exists updated_at timestamptz not null default now();

alter table public.chat_messages add column if not exists attachments jsonb not null default '[]'::jsonb;
alter table public.student_questions add column if not exists attachments jsonb not null default '[]'::jsonb;
alter table public.community_posts alter column reactions set default '{}'::jsonb;

alter table public.audio_resources add column if not exists title text not null default '';
alter table public.audio_resources add column if not exists description text not null default '';
alter table public.audio_resources add column if not exists course text not null default '';
alter table public.audio_resources add column if not exists course_language text not null default '';
alter table public.audio_resources add column if not exists level text not null default '';
alter table public.audio_resources add column if not exists access_type text not null default 'free';
alter table public.audio_resources add column if not exists file_type text not null default 'audio';
alter table public.audio_resources add column if not exists link_type text not null default 'clip';
alter table public.audio_resources add column if not exists url text not null default '';
alter table public.audio_resources add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.audio_resources add column if not exists source_position integer not null default 0;
alter table public.audio_resources add column if not exists created_at timestamptz;
alter table public.audio_resources add column if not exists updated_at timestamptz not null default now();

alter table public.audio_resource_items add column if not exists audio_resource_id text;
alter table public.audio_resource_items add column if not exists title text not null default '';
alter table public.audio_resource_items add column if not exists url text not null default '';
alter table public.audio_resource_items add column if not exists file_type text not null default 'audio';
alter table public.audio_resource_items add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.audio_resource_items add column if not exists source_position integer not null default 0;
alter table public.audio_resource_items add column if not exists created_at timestamptz not null default now();
alter table public.audio_resource_items add column if not exists updated_at timestamptz not null default now();

alter table public.vocabulary_words add column if not exists language text not null default '';
alter table public.vocabulary_words add column if not exists word text not null default '';
alter table public.vocabulary_words add column if not exists translation text not null default '';
alter table public.vocabulary_words add column if not exists pronunciation text not null default '';
alter table public.vocabulary_words add column if not exists example text not null default '';
alter table public.vocabulary_words add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.vocabulary_words add column if not exists source_position integer not null default 0;
alter table public.vocabulary_words add column if not exists created_at timestamptz;
alter table public.vocabulary_words add column if not exists updated_at timestamptz not null default now();

alter table public.device_tokens add column if not exists user_id text not null default '';
alter table public.device_tokens add column if not exists token text not null default '';
alter table public.device_tokens add column if not exists platform text not null default '';
alter table public.device_tokens add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.device_tokens add column if not exists source_position integer not null default 0;
alter table public.device_tokens add column if not exists created_at timestamptz;
alter table public.device_tokens add column if not exists updated_at timestamptz not null default now();

alter table public.activity_logs add column if not exists user_id text not null default '';
alter table public.activity_logs add column if not exists user_name text not null default '';
alter table public.activity_logs add column if not exists user_phone text not null default '';
alter table public.activity_logs add column if not exists action text not null default '';
alter table public.activity_logs add column if not exists label text not null default '';
alter table public.activity_logs add column if not exists details text not null default '';
alter table public.activity_logs add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.activity_logs add column if not exists source_position integer not null default 0;
alter table public.activity_logs add column if not exists created_at timestamptz;
alter table public.activity_logs add column if not exists updated_at timestamptz not null default now();

alter table public.app_sessions add column if not exists session_id text not null default '';
alter table public.app_sessions add column if not exists user_id text not null default '';
alter table public.app_sessions add column if not exists user_name text not null default '';
alter table public.app_sessions add column if not exists user_phone text not null default '';
alter table public.app_sessions add column if not exists raw_payload jsonb not null default '{}'::jsonb;
alter table public.app_sessions add column if not exists source_position integer not null default 0;
alter table public.app_sessions add column if not exists opened_at timestamptz;
alter table public.app_sessions add column if not exists last_seen_at timestamptz;
alter table public.app_sessions add column if not exists created_at timestamptz not null default now();
alter table public.app_sessions add column if not exists updated_at timestamptz not null default now();

alter table public.app_settings add column if not exists value jsonb not null default '{}'::jsonb;
alter table public.app_settings add column if not exists description text not null default '';
alter table public.app_settings add column if not exists created_at timestamptz not null default now();
alter table public.app_settings add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'courses'
      and column_name = 'price'
      and data_type <> 'numeric'
  ) then
    alter table public.courses alter column price drop default;
    alter table public.courses alter column price drop not null;
    alter table public.courses
      alter column price type numeric using public.safe_numeric(price::text, 0);
    alter table public.courses alter column price set default 0;
    alter table public.courses alter column price set not null;
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'payments'
      and column_name = 'amount'
      and data_type <> 'numeric'
  ) then
    alter table public.payments alter column amount drop default;
    alter table public.payments alter column amount drop not null;
    alter table public.payments
      alter column amount type numeric using public.safe_numeric(amount::text, 0);
    alter table public.payments alter column amount set default 0;
    alter table public.payments alter column amount set not null;
  end if;
end;
$$;

do $$
begin
  alter table public.enrollments alter column student_id drop not null;
  alter table public.enrollments alter column student_id drop default;
  alter table public.progress alter column student_id drop not null;
  alter table public.progress alter column student_id drop default;
  alter table public.exam_attempts alter column student_id drop not null;
  alter table public.exam_attempts alter column student_id drop default;
  alter table public.certificates alter column student_id drop not null;
  alter table public.certificates alter column student_id drop default;

  update public.enrollments e
  set student_id = null
  where e.student_id is not null
    and not exists (select 1 from public.profiles p where p.id = e.student_id);

  update public.progress pr
  set student_id = null
  where pr.student_id is not null
    and not exists (select 1 from public.profiles p where p.id = pr.student_id);

  update public.exam_attempts ea
  set student_id = null
  where ea.student_id is not null
    and not exists (select 1 from public.profiles p where p.id = ea.student_id);

  update public.certificates c
  set student_id = null
  where c.student_id is not null
    and not exists (select 1 from public.profiles p where p.id = c.student_id);

  if not exists (select 1 from pg_constraint where conname = 'levels_course_id_fkey') then
    alter table public.levels
      add constraint levels_course_id_fkey
      foreign key (course_id) references public.courses(id) on delete cascade;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'lessons_course_id_fkey') then
    alter table public.lessons
      add constraint lessons_course_id_fkey
      foreign key (course_id) references public.courses(id) on delete cascade;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'lessons_level_id_fkey') then
    alter table public.lessons
      add constraint lessons_level_id_fkey
      foreign key (level_id) references public.levels(id) on delete cascade;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'lesson_materials_course_id_fkey') then
    alter table public.lesson_materials
      add constraint lesson_materials_course_id_fkey
      foreign key (course_id) references public.courses(id) on delete cascade;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'lesson_materials_level_id_fkey') then
    alter table public.lesson_materials
      add constraint lesson_materials_level_id_fkey
      foreign key (level_id) references public.levels(id) on delete cascade;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'lesson_materials_lesson_id_fkey') then
    alter table public.lesson_materials
      add constraint lesson_materials_lesson_id_fkey
      foreign key (lesson_id) references public.lessons(id) on delete cascade;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'lesson_material_files_material_id_fkey') then
    alter table public.lesson_material_files
      add constraint lesson_material_files_material_id_fkey
      foreign key (material_id) references public.lesson_materials(id) on delete cascade;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'exams_course_id_fkey') then
    alter table public.exams
      add constraint exams_course_id_fkey
      foreign key (course_id) references public.courses(id) on delete set null;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'exams_level_id_fkey') then
    alter table public.exams
      add constraint exams_level_id_fkey
      foreign key (level_id) references public.levels(id) on delete set null;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'exam_questions_exam_id_fkey') then
    alter table public.exam_questions
      add constraint exam_questions_exam_id_fkey
      foreign key (exam_id) references public.exams(id) on delete cascade;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'exam_attempts_exam_id_fkey') then
    alter table public.exam_attempts
      add constraint exam_attempts_exam_id_fkey
      foreign key (exam_id) references public.exams(id) on delete set null;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'exam_attempts_student_id_fkey') then
    alter table public.exam_attempts
      add constraint exam_attempts_student_id_fkey
      foreign key (student_id) references public.profiles(id) on delete set null;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'certificates_exam_attempt_id_fkey') then
    alter table public.certificates
      add constraint certificates_exam_attempt_id_fkey
      foreign key (exam_attempt_id) references public.exam_attempts(id) on delete cascade;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'certificates_student_id_fkey') then
    alter table public.certificates
      add constraint certificates_student_id_fkey
      foreign key (student_id) references public.profiles(id) on delete set null;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'enrollments_profile_id_fkey') then
    alter table public.enrollments
      add constraint enrollments_profile_id_fkey
      foreign key (profile_id) references public.profiles(id) on delete set null;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'enrollments_course_id_fkey') then
    alter table public.enrollments
      add constraint enrollments_course_id_fkey
      foreign key (course_id) references public.courses(id) on delete set null;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'enrollments_student_id_fkey') then
    alter table public.enrollments
      add constraint enrollments_student_id_fkey
      foreign key (student_id) references public.profiles(id) on delete set null;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'payments_enrollment_id_fkey') then
    alter table public.payments
      add constraint payments_enrollment_id_fkey
      foreign key (enrollment_id) references public.enrollments(id) on delete cascade;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'progress_student_id_fkey') then
    alter table public.progress
      add constraint progress_student_id_fkey
      foreign key (student_id) references public.profiles(id) on delete set null;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'audio_resource_items_audio_resource_id_fkey') then
    alter table public.audio_resource_items
      add constraint audio_resource_items_audio_resource_id_fkey
      foreign key (audio_resource_id) references public.audio_resources(id) on delete cascade;
  end if;
end;
$$;

create index if not exists profiles_phone_idx on public.profiles(phone);
create index if not exists courses_language_title_idx on public.courses(language, title);
create index if not exists levels_course_idx on public.levels(course_id);
create index if not exists lessons_level_idx on public.lessons(level_id);
create index if not exists lesson_materials_lesson_idx on public.lesson_materials(lesson_id);
create index if not exists exams_course_level_idx on public.exams(course_language, course_title, level_title);
create index if not exists exam_questions_exam_idx on public.exam_questions(exam_id, source_position);
create index if not exists exam_attempts_student_idx on public.exam_attempts(student_id, submitted_at desc);
create index if not exists enrollments_student_course_idx on public.enrollments(student_id, course_language, course_title);
create index if not exists payments_student_idx on public.payments(student_id, paid_at desc);
create index if not exists progress_student_course_idx on public.progress(student_id, course_language, course_title);
create index if not exists notifications_created_idx on public.notifications(created_at desc);
create index if not exists chat_messages_student_idx on public.chat_messages(student_id, created_at);
create index if not exists student_questions_student_idx on public.student_questions(student_id, created_at);
create index if not exists community_posts_created_idx on public.community_posts(created_at desc);
create index if not exists audio_resources_course_idx on public.audio_resources(course_language, course, level);
create index if not exists activity_logs_created_idx on public.activity_logs(created_at desc);
create index if not exists app_sessions_user_idx on public.app_sessions(user_id, last_seen_at desc);

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_courses_updated_at on public.courses;
create trigger set_courses_updated_at before update on public.courses
for each row execute function public.set_updated_at();

drop trigger if exists set_levels_updated_at on public.levels;
create trigger set_levels_updated_at before update on public.levels
for each row execute function public.set_updated_at();

drop trigger if exists set_lessons_updated_at on public.lessons;
create trigger set_lessons_updated_at before update on public.lessons
for each row execute function public.set_updated_at();

drop trigger if exists set_lesson_materials_updated_at on public.lesson_materials;
create trigger set_lesson_materials_updated_at before update on public.lesson_materials
for each row execute function public.set_updated_at();

drop trigger if exists set_books_updated_at on public.books;
create trigger set_books_updated_at before update on public.books
for each row execute function public.set_updated_at();

drop trigger if exists set_exams_updated_at on public.exams;
create trigger set_exams_updated_at before update on public.exams
for each row execute function public.set_updated_at();

drop trigger if exists set_exam_questions_updated_at on public.exam_questions;
create trigger set_exam_questions_updated_at before update on public.exam_questions
for each row execute function public.set_updated_at();

drop trigger if exists set_exam_attempts_updated_at on public.exam_attempts;
create trigger set_exam_attempts_updated_at before update on public.exam_attempts
for each row execute function public.set_updated_at();

drop trigger if exists set_certificates_updated_at on public.certificates;
create trigger set_certificates_updated_at before update on public.certificates
for each row execute function public.set_updated_at();

drop trigger if exists set_enrollments_updated_at on public.enrollments;
create trigger set_enrollments_updated_at before update on public.enrollments
for each row execute function public.set_updated_at();

drop trigger if exists set_payments_updated_at on public.payments;
create trigger set_payments_updated_at before update on public.payments
for each row execute function public.set_updated_at();

drop trigger if exists set_progress_updated_at on public.progress;
create trigger set_progress_updated_at before update on public.progress
for each row execute function public.set_updated_at();

drop trigger if exists set_notifications_updated_at on public.notifications;
create trigger set_notifications_updated_at before update on public.notifications
for each row execute function public.set_updated_at();

drop trigger if exists set_chat_messages_updated_at on public.chat_messages;
create trigger set_chat_messages_updated_at before update on public.chat_messages
for each row execute function public.set_updated_at();

drop trigger if exists set_student_questions_updated_at on public.student_questions;
create trigger set_student_questions_updated_at before update on public.student_questions
for each row execute function public.set_updated_at();

drop trigger if exists set_community_posts_updated_at on public.community_posts;
create trigger set_community_posts_updated_at before update on public.community_posts
for each row execute function public.set_updated_at();

drop trigger if exists set_audio_resources_updated_at on public.audio_resources;
create trigger set_audio_resources_updated_at before update on public.audio_resources
for each row execute function public.set_updated_at();

drop trigger if exists set_audio_resource_items_updated_at on public.audio_resource_items;
create trigger set_audio_resource_items_updated_at before update on public.audio_resource_items
for each row execute function public.set_updated_at();

drop trigger if exists set_vocabulary_words_updated_at on public.vocabulary_words;
create trigger set_vocabulary_words_updated_at before update on public.vocabulary_words
for each row execute function public.set_updated_at();

drop trigger if exists set_device_tokens_updated_at on public.device_tokens;
create trigger set_device_tokens_updated_at before update on public.device_tokens
for each row execute function public.set_updated_at();

drop trigger if exists set_activity_logs_updated_at on public.activity_logs;
create trigger set_activity_logs_updated_at before update on public.activity_logs
for each row execute function public.set_updated_at();

drop trigger if exists set_app_sessions_updated_at on public.app_sessions;
create trigger set_app_sessions_updated_at before update on public.app_sessions
for each row execute function public.set_updated_at();

drop trigger if exists set_app_settings_updated_at on public.app_settings;
create trigger set_app_settings_updated_at before update on public.app_settings
for each row execute function public.set_updated_at();

create or replace function public.lingova_read_collection(collection_name text)
returns table(source_position integer, data jsonb)
language plpgsql
security definer
set search_path = public
as $$
begin
  if collection_name = 'users' then
    return query select p.source_position, p.raw_payload from public.profiles p order by p.source_position;
  elsif collection_name = 'courses' then
    return query
      select c.source_position, c.raw_payload from public.courses c
      union all select l.source_position, l.raw_payload from public.levels l
      union all select le.source_position, le.raw_payload from public.lessons le
      union all select m.source_position, m.raw_payload from public.lesson_materials m
      order by 1;
  elsif collection_name = 'books' then
    return query select b.source_position, b.raw_payload from public.books b order by b.source_position;
  elsif collection_name = 'subscriptions' then
    return query select e.source_position, e.raw_payload from public.enrollments e where e.source_collection = 'subscriptions' order by e.source_position;
  elsif collection_name = 'notifications' then
    return query select n.source_position, n.raw_payload from public.notifications n order by n.source_position;
  elsif collection_name = 'support_messages' then
    return query select c.source_position, c.raw_payload from public.chat_messages c where c.channel = 'support' order by c.source_position;
  elsif collection_name = 'direct_messages' then
    return query select c.source_position, c.raw_payload from public.chat_messages c where c.channel = 'direct' order by c.source_position;
  elsif collection_name = 'device_tokens' then
    return query select d.source_position, d.raw_payload from public.device_tokens d order by d.source_position;
  elsif collection_name = 'questions' then
    return query select q.source_position, q.raw_payload from public.student_questions q order by q.source_position;
  elsif collection_name = 'watch_progress' then
    return query select p.source_position, p.raw_payload from public.progress p order by p.source_position;
  elsif collection_name = 'exams' then
    return query select e.source_position, e.raw_payload from public.exams e order by e.source_position;
  elsif collection_name = 'exam_results' then
    return query select a.source_position, a.raw_payload from public.exam_attempts a order by a.source_position;
  elsif collection_name = 'activity_logs' then
    return query select a.source_position, a.raw_payload from public.activity_logs a order by a.source_position;
  elsif collection_name = 'app_sessions' then
    return query select s.source_position, s.raw_payload from public.app_sessions s order by s.source_position;
  elsif collection_name = 'community_posts' then
    return query select c.source_position, c.raw_payload from public.community_posts c order by c.source_position;
  elsif collection_name = 'vocabulary_words' then
    return query select v.source_position, v.raw_payload from public.vocabulary_words v order by v.source_position;
  elsif collection_name = 'audio_resources' then
    return query select a.source_position, a.raw_payload from public.audio_resources a order by a.source_position;
  else
    raise exception 'Unsupported collection: %', collection_name;
  end if;
end;
$$;

drop function if exists public.lingova_replace_collection(text, jsonb);

create or replace function public.lingova_replace_collection(
  p_collection text,
  p_records jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if jsonb_typeof(p_records) <> 'array' then
    raise exception 'records must be a JSON array';
  end if;

  if p_collection = 'users' then
    delete from public.enrollments
    where p_collection = 'users'
      and source_collection = 'users';

    delete from public.profiles
    where p_collection = 'users';

    insert into public.profiles (
      id, full_name, phone, password_hash, address, job, language,
      learning_reason, referral_reason, status, role, raw_payload,
      source_position, created_at
    )
    select
      coalesce(nullif(item->>'id', ''), gen_random_uuid()::text),
      coalesce(item->>'fullName', ''),
      coalesce(item->>'phone', ''),
      coalesce(item->>'passwordHash', ''),
      coalesce(item->>'address', ''),
      coalesce(item->>'job', ''),
      coalesce(item->>'language', ''),
      coalesce(item->>'learningReason', ''),
      coalesce(item->>'referralReason', ''),
      coalesce(nullif(item->>'status', ''), 'active'),
      coalesce(nullif(item->>'role', ''), 'student'),
      item,
      item_order::integer,
      public.safe_timestamptz(item->>'createdAt')
    from jsonb_array_elements(p_records) with ordinality as source(item, item_order);

    insert into public.enrollments (
      id, profile_id, student_id, course_key, course_title, course_language,
      payment_status, opened_by, source_collection, raw_payload,
      source_position, opened_at
    )
    select
      coalesce(nullif(enrollment->>'id', ''), md5((profile_item->>'id') || '|' || coalesce(enrollment->>'courseKey', '') || '|' || enrollment_order::text)),
      profile_item->>'id',
      profile_item->>'id',
      coalesce(enrollment->>'courseKey', ''),
      coalesce(enrollment->>'courseTitle', ''),
      coalesce(enrollment->>'courseLanguage', ''),
      coalesce(enrollment->>'paymentStatus', ''),
      coalesce(enrollment->>'openedBy', ''),
      'users',
      enrollment,
      (profile_order::integer * 1000 + enrollment_order::integer),
      public.safe_timestamptz(enrollment->>'openedAt')
    from jsonb_array_elements(p_records) with ordinality as profiles(profile_item, profile_order)
    cross join lateral jsonb_array_elements(coalesce(profile_item->'enrollments', '[]'::jsonb)) with ordinality as enrollments(enrollment, enrollment_order);

  elsif p_collection = 'courses' then
    delete from public.lesson_materials
    where p_collection = 'courses';

    delete from public.lessons
    where p_collection = 'courses';

    delete from public.levels
    where p_collection = 'courses';

    delete from public.courses
    where p_collection = 'courses';

    insert into public.courses (
      id, language, language_code, title, course_type, price, course_level, image_data_url,
      learning_outcomes, created_by, raw_payload, source_position, created_at
    )
    select
      coalesce(nullif(item->>'id', ''), gen_random_uuid()::text),
      coalesce(item->>'language', ''),
      coalesce(item->>'languageCode', item->>'language', ''),
      coalesce(item->>'course', ''),
      coalesce(nullif(item->>'courseType', ''), 'free'),
      coalesce(nullif(regexp_replace(coalesce(item->>'price', ''), '[^0-9.]', '', 'g'), '')::numeric, 0),
      coalesce(item->>'courseLevel', ''),
      coalesce(item->>'imageDataUrl', ''),
      case when jsonb_typeof(item->'learningOutcomes') = 'array' then item->'learningOutcomes' else '[]'::jsonb end,
      coalesce(item->>'createdBy', ''),
      item,
      item_order::integer,
      public.safe_timestamptz(item->>'createdAt')
    from jsonb_array_elements(p_records) with ordinality as source(item, item_order)
    where coalesce(item->>'type', 'part') = 'course';

    insert into public.levels (
      id, course_id, language, course_title, title, raw_payload, source_position, created_at
    )
    select
      coalesce(nullif(item->>'id', ''), gen_random_uuid()::text),
      c.id,
      coalesce(item->>'language', ''),
      coalesce(item->>'course', ''),
      coalesce(item->>'level', ''),
      item,
      item_order::integer,
      public.safe_timestamptz(item->>'createdAt')
    from jsonb_array_elements(p_records) with ordinality as source(item, item_order)
    left join public.courses c on c.language = coalesce(item->>'language', '') and c.title = coalesce(item->>'course', '')
    where coalesce(item->>'type', 'part') = 'level';

    insert into public.lessons (
      id, course_id, level_id, language, course_title, level_title, title,
      raw_payload, source_position, created_at
    )
    select
      coalesce(nullif(item->>'id', ''), gen_random_uuid()::text),
      c.id,
      l.id,
      coalesce(item->>'language', ''),
      coalesce(item->>'course', ''),
      coalesce(item->>'level', ''),
      coalesce(item->>'lecture', ''),
      item,
      item_order::integer,
      public.safe_timestamptz(item->>'createdAt')
    from jsonb_array_elements(p_records) with ordinality as source(item, item_order)
    left join public.courses c on c.language = coalesce(item->>'language', '') and c.title = coalesce(item->>'course', '')
    left join public.levels l on l.language = coalesce(item->>'language', '') and l.course_title = coalesce(item->>'course', '') and l.title = coalesce(item->>'level', '')
    where coalesce(item->>'type', 'part') = 'lecture';

    insert into public.lesson_materials (
      id, course_id, level_id, lesson_id, language, course_title, level_title,
      lesson_title, title, vimeo_url, duration, material_type, raw_payload,
      source_position, created_at
    )
    select
      coalesce(nullif(item->>'id', ''), gen_random_uuid()::text),
      c.id,
      l.id,
      le.id,
      coalesce(item->>'language', ''),
      coalesce(item->>'course', ''),
      coalesce(item->>'level', ''),
      coalesce(item->>'lecture', ''),
      coalesce(item->>'part', ''),
      coalesce(item->>'vimeoUrl', ''),
      coalesce(item->>'duration', ''),
      'video',
      item,
      item_order::integer,
      public.safe_timestamptz(item->>'createdAt')
    from jsonb_array_elements(p_records) with ordinality as source(item, item_order)
    left join public.courses c on c.language = coalesce(item->>'language', '') and c.title = coalesce(item->>'course', '')
    left join public.levels l on l.language = coalesce(item->>'language', '') and l.course_title = coalesce(item->>'course', '') and l.title = coalesce(item->>'level', '')
    left join public.lessons le on le.language = coalesce(item->>'language', '') and le.course_title = coalesce(item->>'course', '') and le.level_title = coalesce(item->>'level', '') and le.title = coalesce(item->>'lecture', '')
    where coalesce(item->>'type', 'part') = 'part';

  elsif p_collection = 'books' then
    delete from public.books
    where p_collection = 'books';
    insert into public.books (id, title, subtitle, language, level, url, created_by, raw_payload, source_position, created_at)
    select coalesce(nullif(item->>'id', ''), gen_random_uuid()::text), coalesce(item->>'title', ''), coalesce(item->>'subtitle', ''), coalesce(item->>'language', ''), coalesce(item->>'level', ''), coalesce(item->>'url', ''), coalesce(item->>'createdBy', ''), item, item_order::integer, public.safe_timestamptz(item->>'createdAt')
    from jsonb_array_elements(p_records) with ordinality as source(item, item_order);

  elsif p_collection = 'subscriptions' then
    delete from public.payments
    where p_collection = 'subscriptions'
      and source_collection = 'subscriptions';

    delete from public.enrollments
    where p_collection = 'subscriptions'
      and source_collection = 'subscriptions';
    insert into public.enrollments (
      id, profile_id, student_id, student_name, student_phone, student_address,
      student_job, student_language, course_title, course_language, course_level,
      course_price, status, approved_by, source_collection, raw_payload,
      source_position, requested_at, approved_at
    )
    select
      coalesce(nullif(item->>'id', ''), gen_random_uuid()::text),
      p.id,
      p.id,
      coalesce(item->>'studentName', ''),
      coalesce(item->>'studentPhone', ''),
      coalesce(item->>'studentAddress', ''),
      coalesce(item->>'studentJob', ''),
      coalesce(item->>'studentLanguage', ''),
      coalesce(item->>'courseTitle', ''),
      coalesce(item->>'courseLanguage', ''),
      coalesce(item->>'courseLevel', ''),
      coalesce(item->>'coursePrice', ''),
      coalesce(nullif(item->>'status', ''), 'pending'),
      coalesce(item->>'approvedBy', ''),
      'subscriptions',
      item,
      item_order::integer,
      public.safe_timestamptz(item->>'requestedAt'),
      public.safe_timestamptz(item->>'approvedAt')
    from jsonb_array_elements(p_records) with ordinality as source(item, item_order)
    left join public.profiles p on p.id = nullif(item->>'studentId', '');

    insert into public.payments (
      id, enrollment_id, student_id, course_title, course_language, amount,
      method, payment_phone, status, source_collection, raw_payload,
      source_position, paid_at
    )
    select
      md5(coalesce(item->>'id', gen_random_uuid()::text) || '|payment'),
      coalesce(nullif(item->>'id', ''), null),
      coalesce(item->>'studentId', ''),
      coalesce(item->>'courseTitle', ''),
      coalesce(item->>'courseLanguage', ''),
      coalesce(nullif(regexp_replace(coalesce(item->>'paidAmount', ''), '[^0-9.]', '', 'g'), '')::numeric, 0),
      coalesce(item->>'paymentMethod', ''),
      coalesce(item->>'paymentPhone', ''),
      case when coalesce(item->>'status', '') = 'approved' then 'paid' else coalesce(item->>'status', 'pending') end,
      'subscriptions',
      item,
      item_order::integer,
      public.safe_timestamptz(item->>'paymentDate')
    from jsonb_array_elements(p_records) with ordinality as source(item, item_order)
    where coalesce(item->>'paymentMethod', '') <> '' or coalesce(item->>'paidAmount', '') <> '';

  elsif p_collection = 'notifications' then
    delete from public.notifications
    where p_collection = 'notifications';
    insert into public.notifications (id, title, body, notification_type, created_by, raw_payload, source_position, created_at)
    select coalesce(nullif(item->>'id', ''), gen_random_uuid()::text), coalesce(item->>'title', ''), coalesce(item->>'body', ''), coalesce(nullif(item->>'type', ''), 'general'), coalesce(item->>'createdBy', ''), item, item_order::integer, public.safe_timestamptz(item->>'createdAt')
    from jsonb_array_elements(p_records) with ordinality as source(item, item_order);

  elsif p_collection = 'support_messages' then
    delete from public.chat_messages
    where channel = 'support';
    insert into public.chat_messages (id, student_id, student_name, student_phone, message, answer, sender, status, read_by_admin, read_by_student, attachments, answered_by, channel, raw_payload, source_position, created_at, answered_at)
    select coalesce(nullif(item->>'id', ''), gen_random_uuid()::text), coalesce(item->>'studentId', item->>'student_id', item->>'userId', item->>'user_id', ''), coalesce(item->>'studentName', item->>'student_name', item->>'userName', item->>'user_name', item->>'authorName', ''), coalesce(item->>'studentPhone', item->>'student_phone', item->>'userPhone', item->>'user_phone', ''), coalesce(item->>'message', item->>'text', item->>'body', item->>'content', ''), coalesce(item->>'answer', ''), coalesce(nullif(item->>'sender', ''), case when coalesce(item->>'answer', '') <> '' and coalesce(item->>'message', item->>'text', item->>'body', item->>'content', '') = '' then 'admin' else 'student' end), coalesce(nullif(item->>'status', ''), 'open'), public.safe_bool(coalesce(item->>'readByAdmin', item->>'read_by_admin'), false), public.safe_bool(coalesce(item->>'readByStudent', item->>'read_by_student'), false), case when jsonb_typeof(item->'attachments') = 'array' then item->'attachments' when jsonb_typeof(item->'files') = 'array' then item->'files' else '[]'::jsonb end, coalesce(item->>'answeredBy', item->>'answered_by', ''), 'support', item, item_order::integer, coalesce(public.safe_timestamptz(item->>'createdAt'), public.safe_timestamptz(item->>'created_at'), public.safe_timestamptz(item->>'timestamp'), public.safe_timestamptz(item->>'sentAt')), coalesce(public.safe_timestamptz(item->>'answeredAt'), public.safe_timestamptz(item->>'answered_at'))
    from jsonb_array_elements(p_records) with ordinality as source(item, item_order);

  elsif p_collection = 'direct_messages' then
    delete from public.chat_messages
    where channel = 'direct';
    insert into public.chat_messages (id, student_id, student_name, student_phone, message, answer, sender, status, read_by_admin, read_by_student, attachments, answered_by, channel, raw_payload, source_position, created_at, answered_at)
    select coalesce(nullif(item->>'id', ''), gen_random_uuid()::text), coalesce(item->>'studentId', item->>'student_id', item->>'userId', item->>'user_id', item->>'senderId', item->>'sender_id', ''), coalesce(item->>'studentName', item->>'student_name', item->>'userName', item->>'user_name', item->>'senderName', item->>'sender_name', item->>'authorName', ''), coalesce(item->>'studentPhone', item->>'student_phone', item->>'userPhone', item->>'user_phone', ''), coalesce(item->>'message', item->>'text', item->>'body', item->>'content', ''), coalesce(item->>'answer', ''), coalesce(nullif(item->>'sender', ''), nullif(item->>'senderRole', ''), nullif(item->>'sender_role', ''), 'student'), coalesce(nullif(item->>'status', ''), 'open'), public.safe_bool(coalesce(item->>'readByAdmin', item->>'read_by_admin'), false), public.safe_bool(coalesce(item->>'readByStudent', item->>'read_by_student'), false), case when jsonb_typeof(item->'attachments') = 'array' then item->'attachments' when jsonb_typeof(item->'files') = 'array' then item->'files' else '[]'::jsonb end, coalesce(item->>'answeredBy', item->>'answered_by', ''), 'direct', item, item_order::integer, coalesce(public.safe_timestamptz(item->>'createdAt'), public.safe_timestamptz(item->>'created_at'), public.safe_timestamptz(item->>'timestamp'), public.safe_timestamptz(item->>'sentAt')), coalesce(public.safe_timestamptz(item->>'answeredAt'), public.safe_timestamptz(item->>'answered_at'))
    from jsonb_array_elements(p_records) with ordinality as source(item, item_order);

  elsif p_collection = 'device_tokens' then
    delete from public.device_tokens
    where p_collection = 'device_tokens';
    insert into public.device_tokens (id, user_id, token, platform, raw_payload, source_position, created_at, updated_at)
    select coalesce(nullif(item->>'id', ''), gen_random_uuid()::text), coalesce(item->>'userId', ''), coalesce(item->>'token', ''), coalesce(item->>'platform', ''), item, item_order::integer, public.safe_timestamptz(item->>'createdAt'), coalesce(public.safe_timestamptz(item->>'updatedAt'), now())
    from jsonb_array_elements(p_records) with ordinality as source(item, item_order);

  elsif p_collection = 'questions' then
    delete from public.student_questions
    where true;
    insert into public.student_questions (id, student_id, student_name, student_phone, course_title, course_language, level_title, lesson_title, part_title, vimeo_url, question, answer, status, attachments, answered_by, raw_payload, source_position, created_at, answered_at)
    select coalesce(nullif(item->>'id', ''), gen_random_uuid()::text), coalesce(item->>'studentId', item->>'student_id', item->>'userId', item->>'user_id', ''), coalesce(item->>'studentName', item->>'student_name', item->>'userName', item->>'user_name', ''), coalesce(item->>'studentPhone', item->>'student_phone', item->>'userPhone', item->>'user_phone', ''), coalesce(item->>'courseTitle', item->>'course_title', ''), coalesce(item->>'courseLanguage', item->>'course_language', ''), coalesce(item->>'levelTitle', item->>'level_title', ''), coalesce(item->>'lectureTitle', item->>'lessonTitle', item->>'lesson_title', ''), coalesce(item->>'partTitle', item->>'part_title', ''), coalesce(item->>'vimeoUrl', item->>'vimeo_url', ''), coalesce(item->>'question', item->>'message', item->>'text', ''), coalesce(item->>'answer', ''), coalesce(nullif(item->>'status', ''), 'pending'), case when jsonb_typeof(item->'attachments') = 'array' then item->'attachments' when jsonb_typeof(item->'files') = 'array' then item->'files' else '[]'::jsonb end, coalesce(item->>'answeredBy', item->>'answered_by', ''), item, item_order::integer, coalesce(public.safe_timestamptz(item->>'createdAt'), public.safe_timestamptz(item->>'created_at')), coalesce(public.safe_timestamptz(item->>'answeredAt'), public.safe_timestamptz(item->>'answered_at'))
    from jsonb_array_elements(p_records) with ordinality as source(item, item_order);

  elsif p_collection = 'watch_progress' then
    delete from public.progress
    where p_collection = 'watch_progress';
    insert into public.progress (id, student_id, student_name, student_phone, course_title, course_language, level_title, lesson_title, part_title, vimeo_url, duration, watch_date, watch_count, raw_payload, source_position, completed_at)
    select coalesce(nullif(item->>'id', ''), gen_random_uuid()::text), p.id, coalesce(item->>'studentName', ''), coalesce(item->>'studentPhone', ''), coalesce(item->>'courseTitle', ''), coalesce(item->>'courseLanguage', ''), coalesce(item->>'levelTitle', ''), coalesce(item->>'lectureTitle', ''), coalesce(item->>'partTitle', ''), coalesce(item->>'vimeoUrl', ''), coalesce(item->>'duration', ''), public.safe_date(item->>'watchDate'), public.safe_int(item->>'watchCount', 1), item, item_order::integer, public.safe_timestamptz(item->>'completedAt')
    from jsonb_array_elements(p_records) with ordinality as source(item, item_order)
    left join public.profiles p on p.id = nullif(item->>'studentId', '');

  elsif p_collection = 'exams' then
    delete from public.exam_questions
    where p_collection = 'exams';

    delete from public.exams
    where p_collection = 'exams';
    insert into public.exams (id, course_id, level_id, title, description, exam_type, course_title, course_language, level_title, after_lecture_index, pass_score, duration_minutes, created_by, raw_payload, source_position, created_at)
    select coalesce(nullif(item->>'id', ''), gen_random_uuid()::text), c.id, l.id, coalesce(item->>'title', ''), coalesce(item->>'description', ''), coalesce(nullif(item->>'type', ''), 'lecture_quiz'), coalesce(item->>'courseTitle', ''), coalesce(item->>'courseLanguage', ''), coalesce(item->>'levelTitle', ''), public.safe_int(item->>'afterLectureIndex', 0), public.safe_int(item->>'passScore', 60), public.safe_int(item->>'durationMinutes', 10), coalesce(item->>'createdBy', ''), item, item_order::integer, public.safe_timestamptz(item->>'createdAt')
    from jsonb_array_elements(p_records) with ordinality as source(item, item_order)
    left join public.courses c on c.language = coalesce(item->>'courseLanguage', '') and c.title = coalesce(item->>'courseTitle', '')
    left join public.levels l on l.language = coalesce(item->>'courseLanguage', '') and l.course_title = coalesce(item->>'courseTitle', '') and l.title = coalesce(item->>'levelTitle', '');

    insert into public.exam_questions (id, exam_id, question_type, prompt, options, correct_answers, raw_payload, source_position)
    select coalesce(nullif(question->>'id', ''), gen_random_uuid()::text), exam_item->>'id', coalesce(nullif(question->>'type', ''), 'mcq'), coalesce(question->>'prompt', ''), case when jsonb_typeof(question->'options') = 'array' then question->'options' else '[]'::jsonb end, case when jsonb_typeof(question->'correctAnswers') = 'array' then question->'correctAnswers' else '[]'::jsonb end, question, question_order::integer
    from jsonb_array_elements(p_records) as exam_item
    cross join lateral jsonb_array_elements(coalesce(exam_item->'questions', '[]'::jsonb)) with ordinality as questions(question, question_order);

  elsif p_collection = 'exam_results' then
    delete from public.certificates
    where p_collection = 'exam_results';

    delete from public.exam_attempts
    where p_collection = 'exam_results';
    insert into public.exam_attempts (id, exam_id, student_id, student_name, course_title, course_language, level_title, exam_type, score, total_questions, correct_answers, passed, answers, raw_payload, source_position, submitted_at)
    select coalesce(nullif(item->>'id', ''), gen_random_uuid()::text), e.id, p.id, coalesce(item->>'studentName', ''), coalesce(item->>'courseTitle', ''), coalesce(item->>'courseLanguage', ''), coalesce(item->>'levelTitle', ''), coalesce(item->>'type', ''), public.safe_int(item->>'score', 0), public.safe_int(item->>'totalQuestions', 0), public.safe_int(item->>'correctAnswers', 0), public.safe_bool(item->>'passed', false), case when jsonb_typeof(item->'answers') = 'object' then item->'answers' else '{}'::jsonb end, item, item_order::integer, public.safe_timestamptz(item->>'submittedAt')
    from jsonb_array_elements(p_records) with ordinality as source(item, item_order)
    left join public.exams e on e.id = nullif(item->>'examId', '')
    left join public.profiles p on p.id = nullif(item->>'studentId', '');

    insert into public.certificates (exam_attempt_id, exam_id, student_id, student_name, course_title, course_language, level_title, score, issued_at, raw_payload)
    select coalesce(nullif(item->>'id', ''), null), item->>'examId', p.id, coalesce(item->>'studentName', ''), coalesce(item->>'courseTitle', ''), coalesce(item->>'courseLanguage', ''), coalesce(item->>'levelTitle', ''), public.safe_int(item->>'score', 0), coalesce(public.safe_timestamptz(item->>'submittedAt'), now()), item
    from jsonb_array_elements(p_records) as item
    left join public.profiles p on p.id = nullif(item->>'studentId', '')
    where public.safe_bool(item->>'passed', false) = true and coalesce(item->>'type', '') = 'level_final';

  elsif p_collection = 'activity_logs' then
    delete from public.activity_logs
    where p_collection = 'activity_logs';
    insert into public.activity_logs (id, user_id, user_name, user_phone, action, label, details, raw_payload, source_position, created_at)
    select coalesce(nullif(item->>'id', ''), gen_random_uuid()::text), coalesce(item->>'userId', ''), coalesce(item->>'userName', ''), coalesce(item->>'userPhone', ''), coalesce(item->>'action', ''), coalesce(item->>'label', ''), coalesce(item->>'details', ''), item, item_order::integer, public.safe_timestamptz(item->>'createdAt')
    from jsonb_array_elements(p_records) with ordinality as source(item, item_order);

  elsif p_collection = 'app_sessions' then
    delete from public.app_sessions
    where p_collection = 'app_sessions';
    insert into public.app_sessions (id, session_id, user_id, user_name, user_phone, raw_payload, source_position, opened_at, last_seen_at)
    select coalesce(nullif(item->>'id', ''), gen_random_uuid()::text), coalesce(item->>'sessionId', ''), coalesce(item->>'userId', ''), coalesce(item->>'userName', ''), coalesce(item->>'userPhone', ''), item, item_order::integer, public.safe_timestamptz(item->>'openedAt'), public.safe_timestamptz(item->>'lastSeenAt')
    from jsonb_array_elements(p_records) with ordinality as source(item, item_order);

  elsif p_collection = 'community_posts' then
    delete from public.community_posts
    where true;
    insert into public.community_posts (id, student_id, student_name, student_phone, content, image_url, attachments, reactions, comments, shares, status, raw_payload, source_position, created_at)
    select coalesce(nullif(item->>'id', ''), gen_random_uuid()::text), coalesce(item->>'studentId', item->>'student_id', item->>'userId', item->>'user_id', ''), coalesce(item->>'studentName', item->>'student_name', item->>'authorName', item->>'author_name', item->>'userName', item->>'user_name', ''), coalesce(item->>'studentPhone', item->>'student_phone', item->>'userPhone', item->>'user_phone', ''), coalesce(item->>'message', item->>'content', item->>'text', ''), coalesce(item->>'imageUrl', item->>'image_url', ''), case when jsonb_typeof(item->'attachments') = 'array' then item->'attachments' when jsonb_typeof(item->'files') = 'array' then item->'files' else '[]'::jsonb end, case when jsonb_typeof(item->'reactions') in ('object', 'array') then item->'reactions' else '{}'::jsonb end, case when jsonb_typeof(item->'comments') = 'array' then item->'comments' else '[]'::jsonb end, public.safe_int(coalesce(item->>'sharesCount', item->>'shares_count', item->>'shares'), 0), coalesce(nullif(item->>'status', ''), 'active'), item, item_order::integer, coalesce(public.safe_timestamptz(item->>'createdAt'), public.safe_timestamptz(item->>'created_at'), public.safe_timestamptz(item->>'timestamp'))
    from jsonb_array_elements(p_records) with ordinality as source(item, item_order);

  elsif p_collection = 'vocabulary_words' then
    delete from public.vocabulary_words
    where p_collection = 'vocabulary_words';
    insert into public.vocabulary_words (id, language, word, translation, pronunciation, example, raw_payload, source_position, created_at)
    select coalesce(nullif(item->>'id', ''), gen_random_uuid()::text), coalesce(item->>'language', ''), coalesce(item->>'word', ''), coalesce(item->>'translation', ''), coalesce(item->>'pronunciation', ''), coalesce(item->>'example', ''), item, item_order::integer, public.safe_timestamptz(item->>'createdAt')
    from jsonb_array_elements(p_records) with ordinality as source(item, item_order);

  elsif p_collection = 'audio_resources' then
    delete from public.audio_resource_items
    where p_collection = 'audio_resources';

    delete from public.audio_resources
    where p_collection = 'audio_resources';
    insert into public.audio_resources (id, title, description, course, course_language, level, access_type, file_type, link_type, url, raw_payload, source_position, created_at)
    select coalesce(nullif(item->>'id', ''), md5('audio_resources|' || item_order::text)), coalesce(item->>'title', ''), coalesce(item->>'description', ''), coalesce(item->>'course', ''), coalesce(item->>'courseLanguage', ''), coalesce(item->>'level', ''), coalesce(nullif(item->>'accessType', ''), 'free'), coalesce(nullif(item->>'fileType', ''), 'audio'), coalesce(nullif(item->>'linkType', ''), 'clip'), coalesce(item->>'url', ''), item, item_order::integer, public.safe_timestamptz(item->>'createdAt')
    from jsonb_array_elements(p_records) with ordinality as source(item, item_order);

    insert into public.audio_resource_items (id, audio_resource_id, title, url, file_type, raw_payload, source_position)
    select coalesce(nullif(child->>'id', ''), gen_random_uuid()::text), coalesce(nullif(parent->>'id', ''), md5('audio_resources|' || parent_order::text)), coalesce(child->>'title', ''), coalesce(child->>'url', ''), coalesce(nullif(child->>'fileType', ''), coalesce(parent->>'fileType', 'audio')), child, child_order::integer
    from jsonb_array_elements(p_records) with ordinality as parents(parent, parent_order)
    cross join lateral jsonb_array_elements(coalesce(parent->'items', '[]'::jsonb)) with ordinality as children(child, child_order);

  else
    raise exception 'Unsupported collection: %', p_collection;
  end if;
end;
$$;

grant execute on function public.lingova_read_collection(text) to service_role;
grant execute on function public.lingova_replace_collection(text, jsonb) to service_role;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'lingova-audio',
  'lingova-audio',
  true,
  104857600,
  array[
    'audio/mpeg',
    'audio/mp3',
    'audio/wav',
    'audio/ogg',
    'audio/aac',
    'audio/mp4',
    'video/mp4',
    'application/pdf',
    'image/png',
    'image/jpeg',
    'image/webp'
  ]
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
