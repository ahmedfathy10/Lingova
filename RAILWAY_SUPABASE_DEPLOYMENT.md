# نشر Lingova باستخدام Railway و Supabase

## 1. نشر الباك-إند على Railway

1. ادخل إلى https://railway.app/ وسجّل الدخول.
2. أنشئ مشروع جديد (`New Project`).
3. اختر `Deploy from GitHub` أو `Start from Scratch`.
   - إذا ربطت المشروع مع GitHub، حدد مجلد `backend/`.
4. اجعل `Root Directory` هو `backend` إذا لم تُعرف تلقائياً.
5. راقب خطوة البناء.
   - Railway سيستخدم `npm install` ثم `npm start`.

### إعداد متغيرات البيئة على Railway
أضف هذه المتغيرات في `Settings > Variables`:
- `PORT=3000`
- `HOST=0.0.0.0`
- `ADMIN_EMAIL=admin@lingova.com`
- `ADMIN_PASSWORD=admin123`
- `FIREBASE_SERVICE_ACCOUNT_PATH=/app/firebase-service-account.json`

إذا كنت تريد إشعارات Firebase، ارفع ملف `firebase-service-account.json` إلى Railway باستخدام `Files` أو قم بإنشاء سرّ جديد.

## 2. إعداد Supabase

1. ادخل إلى https://supabase.com/ وسجّل الدخول.
2. أنشئ مشروع جديد (`New project`).
3. اختر اسم المشروع والمنطقة.
4. بعد الإنشاء، احصل على:
   - `SUPABASE_URL`
   - `SUPABASE_KEY` (Service Role أو API Key)

### استخدام Supabase لاحقاً
التطبيق الحالي لا يزال يستخدم ملفات JSON للبيانات.
لكي تستخدم Supabase فعلياً، ستحتاج إلى:
- إنشاء جداول PostgreSQL في Supabase.
- تعديل `backend/server.js` لتقرأ وتكتب من قاعدة بيانات Supabase بدل JSON.

## 3. ربط التطبيق بالباك-إند الجديد

بعد نشر الباك-إند على Railway، ستأخذ عنوان URL العام مثل:
`https://your-project.up.railway.app`

ثم تبني تطبيق Flutter باستخدام:

```bash
flutter build apk --release --target lib/main_app.dart --dart-define=API_BASE_URL=https://your-project.up.railway.app
```

وللتطبيق الإداري:

```bash
flutter build apk --release --flavor admin --target lib/main_admin.dart --dart-define=API_BASE_URL=https://your-project.up.railway.app
```

## 4. اختبار الاتصال

افتح المتصفح على رابط الباك-إند وحدد أي نقطة نهاية موجودة في التطبيق، مثل:
`https://your-project.up.railway.app/api/courses`

إذا ظهرت نتيجة JSON، يكون الباك-إند يعمل بشكل صحيح.

## 5. ملاحظات مهمة

- الباك-إند الحالي يكتب إلى ملفات JSON محلياً داخل Railway.
- إذا أعدت تشغيل المشروع في Railway، فقد تحتاج إلى حفظ البيانات في قاعدة بيانات حقيقية.
- Supabase مناسب لهذا الغرض، لكنه يحتاج تعديل في الكود.

---

## 6. الخطوة التالية إذا أردت استخدام Supabase كقاعدة بيانات

1. أنشئ جداول في Supabase للبيانات الأساسية:
   - users
   - courses
   - books
   - subscriptions
   - notifications
   - questions
   - watch_progress
   - exams
   - exam_results
   - activity_logs
   - app_sessions
   - device_tokens
2. أضف متغيرات البيئة في Railway:
   - `SUPABASE_URL`
   - `SUPABASE_KEY`
3. عدّل باك-إند `backend/server.js` لاستخدام `@supabase/supabase-js`.
4. غيّر وظائف القراءة/الكتابة من JSON إلى PostgreSQL.

إذا تريد، أقدر أبدأ معك في خطوة 6 ونعدّل الكود معاً ليتصل مباشرة بـ Supabase.
