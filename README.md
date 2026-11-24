# ShamCash Web — تطبيق آيفون (غلاف ويب غير رسمي)

تطبيق iOS يفتح موقع Sham Cash الرسمي `https://shamcash.sy` داخل نافذة تطبيق،
مع أزرار تنقل (رجوع / تقدم / تحديث / الرئيسية) ودعم الكاميرا ورفع الصور
التي يحتاجها الموقع لمسح QR والتحقق من الحساب.

> هذا ليس تطبيق Sham Cash الأصلي ولا يحتوي كوده. هو مجرد نافذة على الموقع
> الرسمي، للاستخدام الشخصي فقط. لا تنشره باسم Sham Cash الرسمي ولا ترفعه
> إلى App Store (سيرفضه Apple لأنه غلاف لموقع جهة أخرى).

## محتويات المشروع

- `project.yml` — تعريف المشروع لـ XcodeGen (يولّد مشروع Xcode تلقائياً)
- `ShamCashWeb/` — كود Swift (SwiftUI + WKWebView)
- `.github/workflows/build-ipa.yml` — بناء IPA غير موقّع على خوادم GitHub مجاناً

## طريقة البناء بدون جهاز Mac (موصى بها)

### أسهل طريقة: سكربت الرفع التلقائي

من PowerShell داخل هذا المجلد:

```powershell
.\upload-to-github.ps1
```

السكربت يثبّت Git و GitHub CLI تلقائياً إن لم يكونا موجودين، ويفتح تسجيل
الدخول إلى GitHub، وينشئ مستودعاً خاصاً ويرفع المشروع. يمكنك تغيير اسم
المستودع أو جعله عاماً:

```powershell
.\upload-to-github.ps1 -RepoName my-ios-app -Visibility public
```

### أو يدوياً

1. أنشئ مستودعاً جديداً على GitHub وارفع **محتويات هذا المجلد** لتكون جذر المستودع
   (أي بحيث يكون `project.yml` و `.github` في الجذر).
2. من تبويب **Actions** اختر workflow باسم **Build unsigned IPA** ثم **Run workflow**.
3. بعد انتهاء البناء (حوالي 5 دقائق) حمّل الملف من قسم **Artifacts**:
   `ShamCashWeb-unsigned-ipa`.

## التثبيت على الآيفون

الملف غير موقّع، ويحتاج توقيعاً بحساب Apple الخاص بك:

- **Sideloadly** (ويندوز): وصّل الآيفون، اسحب ملف IPA، أدخل Apple ID، ثبّت.
- أو **AltStore** من نفس الجهاز.

ملاحظات:
- الحساب المجاني يوقّع لمدة 7 أيام، بعدها أعد التثبيت بنفس الطريقة.
- حساب المطور المدفوع (99$/سنة) يوقّع لمدة سنة.
- بعد التثبيت: إعدادات الآيفون ← عام ← VPN وإدارة الجهاز ← وثّق المطور.

## البناء على جهاز Mac (بديل)

```bash
brew install xcodegen
xcodegen generate
open ShamCashWeb.xcodeproj
```

ثم اختر فريق التوقيع الخاص بك في Xcode واضغط Run.

## التخصيص

- اسم التطبيق: `CFBundleDisplayName` في `project.yml`
- معرف الحزمة: غيّر `bundleIdPrefix` أو أضف `PRODUCT_BUNDLE_IDENTIFIER`
  خاصاً بك قبل التوقيع
- الأيقونة: استبدل `ShamCashWeb/Assets.xcassets/AppIcon.appiconset/icon.png`
  بصورة 1024×1024
