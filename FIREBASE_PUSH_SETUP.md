# Firebase Push Setup

لكي تعمل الـ Push Notifications الحقيقية في Lingova:

1. ضع ملف Android Firebase هنا:
`android/app/google-services.json`

2. ضع ملف iOS Firebase هنا:
`ios/Runner/GoogleService-Info.plist`

3. ضع ملف Firebase service account الخاص بالسيرفر هنا:
`backend/firebase-service-account.json`

أو استخدم متغير البيئة:
`FIREBASE_SERVICE_ACCOUNT_PATH`

4. شغّل تحميل الحزم:

```bash
flutter pub get
```

5. داخل مجلد `backend` شغّل:

```bash
npm install
```

6. بعد ذلك أعد تشغيل الباك إند والتطبيق.

ملاحظات:
- التطبيق يسجل الجهاز تلقائيًا بعد تسجيل دخول الطالب.
- لوحة التحكم ترسل التنبيه وتخزنه في النظام، ثم يحاول السيرفر إرساله عبر Firebase.
- إذا كانت ملفات Firebase غير موجودة، سيظهر التنبيه داخل التطبيق عند فتحه، لكن الـ Push الحقيقي لن يصل للجهاز وهو مغلق.
