import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final instance = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(instance != null, 'AppLocalizations not found in context');
    return instance!;
  }

  bool get isArabic => locale.languageCode == 'ar';

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'profileTitle': 'Profile',
      'roleAdmin': 'ADMIN',
      'roleStaff': 'STAFF',
      'roleCitizen': 'CITIZEN',
      'activeSession': 'Active session',
      'guestMode': 'Guest mode',
      'mobileReady': 'Mobile ready',
      'administration': 'Administration',
      'administrationSubtitle':
          'Jump into internal tools and operational workflow.',
      'adminDashboard': 'Admin Dashboard',
      'adminDashboardSubtitle':
          'Users, tenders, roles, reports, and system controls',
      'approvals': 'Approvals',
      'approvalsSubtitle': 'Review submissions and verify participants',
      'processes': 'Processes',
      'processesSubtitle': 'Track tender and auction process activity',
      'payments': 'Payments',
      'paymentsSubtitle': 'Stay on top of invoices and completed wins.',
      'myPayments': 'My Payments',
      'myPaymentsSubtitle': 'Review auction invoices and awarded tenders',
      'updates': 'Updates',
      'updatesSubtitle': 'Track newly added auctions and tenders.',
      'notifications': 'Notifications',
      'notificationsSubtitle': 'New auctions, tenders, and platform alerts',
      'preferences': 'Preferences',
      'preferencesSubtitle':
          'A lighter mobile layout for settings and support.',
      'appearance': 'Appearance',
      'appearanceSubtitle': 'Choose how the app looks on your device.',
      'language': 'Language',
      'languageSubtitle': 'Choose your preferred language for the app.',
      'english': 'English',
      'arabic': 'Arabic',
      'systemTheme': 'System',
      'lightTheme': 'Light',
      'darkTheme': 'Dark',
      'account': 'Account',
      'accountSubtitle': 'Profile and personal details',
      'notificationsPrefSubtitle': 'Bid alerts and platform announcements',
      'helpSupport': 'Help & Support',
      'helpSupportSubtitle': 'FAQ, contact, and guidance',
      'session': 'Session',
      'sessionSignedIn': 'Manage your current sign-in securely.',
      'sessionSignedOut': 'Sign in to save activity across devices.',
      'login': 'Login',
      'logout': 'Logout',
      'profileHeroReady': 'Account ready',
      'profileHeroGuest': 'Browsing as guest',
      'profileHeroReadySubtitle':
          'Keep your auction activity, tenders, and account tools within easy reach from one mobile-friendly hub.',
      'profileHeroGuestSubtitle':
          'Sign in to save bids, manage payments, and access a smoother app-style experience.',
      'compactInfo':
          'Forsa keeps auctions, tenders, and account actions easier to manage on phones with a cleaner app-style layout.',
      'systemSettings': 'System Settings',
      'platformConfiguration': 'Platform Configuration',
      'platformConfigurationSubtitle':
          'Toggle maintenance mode and security requirements.',
      'useSystemTheme': 'Use System Theme',
      'useSystemThemeSubtitle': 'Match the device appearance automatically',
      'lightMode': 'Light Mode',
      'lightModeSubtitle': 'Always use the light theme',
      'darkMode': 'Dark Mode',
      'darkModeSubtitle': 'Always use the dark theme',
      'maintenanceMode': 'Maintenance Mode',
      'maintenanceModeSubtitle':
          'Disable access for citizens temporarily',
      'require2fa': 'Require 2FA for Admins',
      'require2faSubtitle': 'Extra security for admin accounts',
      'save': 'Save',
      'savedDemo': 'Saved (demo)',
      'governmentAuctionPortal': 'Government Auction Portal',
      'welcomeBack': 'Welcome back',
      'loginHeroSubtitle':
          'Track bids, manage watchlists, and continue participating from your phone with a faster, cleaner sign-in flow.',
      'signIn': 'Sign In',
      'signInSubtitle':
          'Use your account to continue to auctions, tenders, and saved activity.',
      'emailAddress': 'Email address',
      'password': 'Password',
      'emailRequired': 'Email is required',
      'enterValidEmail': 'Enter a valid email',
      'passwordRequired': 'Password is required',
      'min6Chars': 'Min 6 characters',
      'secureSignInNote':
          'Secure sign-in keeps your auction activity and tender access synced across sessions.',
      'continue': 'Continue',
      'needAccount': 'Need an account?',
      'createOne': 'Create one',
      'newBidderRegistration': 'New bidder registration',
      'createYourAccount': 'Create your account',
      'signupHeroSubtitle':
          'Start with a cleaner mobile sign-up journey designed for auctions, tenders, and secure public-sector participation.',
      'createAccount': 'Create Account',
      'createAccountSubtitle':
          'Complete your profile once and continue everything from your phone.',
      'fullName': 'Full name',
      'nameRequired': 'Name is required',
      'nationalId': 'National ID',
      'nationalIdRequired': 'National ID is required',
      'invalidIdLength': 'Invalid ID length',
      'email': 'Email',
      'invalidEmail': 'Invalid email',
      'phone': 'Phone',
      'phoneRequired': 'Phone is required',
      'minimum8Characters': 'Minimum 8 characters',
      'includeOneNumber': 'Include at least 1 number',
      'confirmPassword': 'Confirm password',
      'passwordsDoNotMatch': 'Passwords do not match',
      'citizenAccountNote':
          'Citizen accounts are created with a default role and can be reviewed through the admin workflow later.',
      'alreadyHaveAccount': 'Already have an account?',
    },
    'ar': {
      'profileTitle': 'الملف الشخصي',
      'roleAdmin': 'مشرف',
      'roleStaff': 'موظف',
      'roleCitizen': 'مواطن',
      'activeSession': 'جلسة نشطة',
      'guestMode': 'وضع الضيف',
      'mobileReady': 'جاهز للهاتف',
      'administration': 'الإدارة',
      'administrationSubtitle': 'الوصول إلى الأدوات الداخلية ومسار العمل التشغيلي.',
      'adminDashboard': 'لوحة الإدارة',
      'adminDashboardSubtitle':
          'المستخدمون والمناقصات والأدوار والتقارير وإعدادات النظام',
      'approvals': 'الموافقات',
      'approvalsSubtitle': 'مراجعة الطلبات والتحقق من المشاركين',
      'processes': 'العمليات',
      'processesSubtitle': 'متابعة نشاط عمليات المزادات والمناقصات',
      'payments': 'المدفوعات',
      'paymentsSubtitle': 'تابع الفواتير والعمليات المكتملة بسهولة.',
      'myPayments': 'مدفوعاتي',
      'myPaymentsSubtitle': 'مراجعة فواتير المزادات والمناقصات الممنوحة',
      'updates': 'التحديثات',
      'updatesSubtitle': 'تابع المزادات والمناقصات الجديدة.',
      'notifications': 'الإشعارات',
      'notificationsSubtitle': 'تنبيهات المزادات والمناقصات وإشعارات المنصة',
      'preferences': 'التفضيلات',
      'preferencesSubtitle': 'إعدادات ودعم بتنسيق أسهل للأجهزة المحمولة.',
      'appearance': 'المظهر',
      'appearanceSubtitle': 'اختر شكل التطبيق على جهازك.',
      'language': 'اللغة',
      'languageSubtitle': 'اختر اللغة المفضلة للتطبيق.',
      'english': 'الإنجليزية',
      'arabic': 'العربية',
      'systemTheme': 'النظام',
      'lightTheme': 'فاتح',
      'darkTheme': 'داكن',
      'account': 'الحساب',
      'accountSubtitle': 'الملف الشخصي والبيانات الشخصية',
      'notificationsPrefSubtitle': 'تنبيهات المزايدة وإعلانات المنصة',
      'helpSupport': 'المساعدة والدعم',
      'helpSupportSubtitle': 'الأسئلة الشائعة والتواصل والإرشادات',
      'session': 'الجلسة',
      'sessionSignedIn': 'إدارة تسجيل الدخول الحالي بشكل آمن.',
      'sessionSignedOut': 'سجّل الدخول لحفظ نشاطك عبر الأجهزة.',
      'login': 'تسجيل الدخول',
      'logout': 'تسجيل الخروج',
      'profileHeroReady': 'حسابك جاهز',
      'profileHeroGuest': 'التصفح كضيف',
      'profileHeroReadySubtitle':
          'احتفظ بنشاط المزادات والمناقصات وأدوات الحساب في متناولك من خلال واجهة مريحة للهاتف.',
      'profileHeroGuestSubtitle':
          'سجّل الدخول لحفظ المزايدات وإدارة المدفوعات والوصول إلى تجربة أكثر سلاسة.',
      'compactInfo':
          'فُرصة تجعل إدارة المزادات والمناقصات وإجراءات الحساب أسهل على الهواتف بتصميم أنظف.',
      'systemSettings': 'إعدادات النظام',
      'platformConfiguration': 'إعدادات المنصة',
      'platformConfigurationSubtitle':
          'تحكم في وضع الصيانة ومتطلبات الأمان.',
      'useSystemTheme': 'استخدام مظهر النظام',
      'useSystemThemeSubtitle': 'مطابقة مظهر الجهاز تلقائياً',
      'lightMode': 'الوضع الفاتح',
      'lightModeSubtitle': 'استخدام المظهر الفاتح دائماً',
      'darkMode': 'الوضع الداكن',
      'darkModeSubtitle': 'استخدام المظهر الداكن دائماً',
      'maintenanceMode': 'وضع الصيانة',
      'maintenanceModeSubtitle': 'تعطيل وصول المواطنين مؤقتاً',
      'require2fa': 'فرض التحقق الثنائي للمشرفين',
      'require2faSubtitle': 'حماية إضافية لحسابات الإدارة',
      'save': 'حفظ',
      'savedDemo': 'تم الحفظ (تجريبي)',
      'governmentAuctionPortal': 'بوابة المزادات الحكومية',
      'welcomeBack': 'مرحباً بعودتك',
      'loginHeroSubtitle':
          'تابع المزايدات وأدر قوائم المتابعة وواصل المشاركة من هاتفك عبر تسجيل دخول أسرع وأنظف.',
      'signIn': 'تسجيل الدخول',
      'signInSubtitle':
          'استخدم حسابك للمتابعة إلى المزادات والمناقصات والنشاط المحفوظ.',
      'emailAddress': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'emailRequired': 'البريد الإلكتروني مطلوب',
      'enterValidEmail': 'أدخل بريداً إلكترونياً صحيحاً',
      'passwordRequired': 'كلمة المرور مطلوبة',
      'min6Chars': '6 أحرف على الأقل',
      'secureSignInNote':
          'تسجيل الدخول الآمن يحافظ على مزامنة نشاط المزادات وصلاحيات المناقصات عبر الجلسات.',
      'continue': 'متابعة',
      'needAccount': 'ليس لديك حساب؟',
      'createOne': 'أنشئ حساباً',
      'newBidderRegistration': 'تسجيل مزايد جديد',
      'createYourAccount': 'أنشئ حسابك',
      'signupHeroSubtitle':
          'ابدأ رحلة تسجيل أسهل على الهاتف للمزادات والمناقصات والمشاركة الحكومية الآمنة.',
      'createAccount': 'إنشاء حساب',
      'createAccountSubtitle':
          'أكمل ملفك مرة واحدة وتابع كل شيء من هاتفك.',
      'fullName': 'الاسم الكامل',
      'nameRequired': 'الاسم مطلوب',
      'nationalId': 'الرقم القومي',
      'nationalIdRequired': 'الرقم القومي مطلوب',
      'invalidIdLength': 'طول الرقم القومي غير صحيح',
      'email': 'البريد الإلكتروني',
      'invalidEmail': 'بريد إلكتروني غير صحيح',
      'phone': 'رقم الهاتف',
      'phoneRequired': 'رقم الهاتف مطلوب',
      'minimum8Characters': '8 أحرف على الأقل',
      'includeOneNumber': 'يجب أن تحتوي على رقم واحد على الأقل',
      'confirmPassword': 'تأكيد كلمة المرور',
      'passwordsDoNotMatch': 'كلمتا المرور غير متطابقتين',
      'citizenAccountNote':
          'يتم إنشاء حسابات المواطنين بدور افتراضي ويمكن مراجعتها لاحقاً من خلال مسار الإدارة.',
      'alreadyHaveAccount': 'لديك حساب بالفعل؟',
    },
  };

  String _text(String key) {
    final language = isArabic ? 'ar' : 'en';
    return _localizedValues[language]![key] ?? _localizedValues['en']![key]!;
  }

  String t(String en, String ar) => isArabic ? ar : en;

  String get profileTitle => _text('profileTitle');
  String get roleAdmin => _text('roleAdmin');
  String get roleStaff => _text('roleStaff');
  String get roleCitizen => _text('roleCitizen');
  String get activeSession => _text('activeSession');
  String get guestMode => _text('guestMode');
  String get mobileReady => _text('mobileReady');
  String get administration => _text('administration');
  String get administrationSubtitle => _text('administrationSubtitle');
  String get adminDashboard => _text('adminDashboard');
  String get adminDashboardSubtitle => _text('adminDashboardSubtitle');
  String get approvals => _text('approvals');
  String get approvalsSubtitle => _text('approvalsSubtitle');
  String get processes => _text('processes');
  String get processesSubtitle => _text('processesSubtitle');
  String get payments => _text('payments');
  String get paymentsSubtitle => _text('paymentsSubtitle');
  String get myPayments => _text('myPayments');
  String get myPaymentsSubtitle => _text('myPaymentsSubtitle');
  String get updates => _text('updates');
  String get updatesSubtitle => _text('updatesSubtitle');
  String get notifications => _text('notifications');
  String get notificationsSubtitle => _text('notificationsSubtitle');
  String get preferences => _text('preferences');
  String get preferencesSubtitle => _text('preferencesSubtitle');
  String get appearance => _text('appearance');
  String get appearanceSubtitle => _text('appearanceSubtitle');
  String get language => _text('language');
  String get languageSubtitle => _text('languageSubtitle');
  String get english => _text('english');
  String get arabic => _text('arabic');
  String get systemTheme => _text('systemTheme');
  String get lightTheme => _text('lightTheme');
  String get darkTheme => _text('darkTheme');
  String get account => _text('account');
  String get accountSubtitle => _text('accountSubtitle');
  String get notificationsPrefSubtitle => _text('notificationsPrefSubtitle');
  String get helpSupport => _text('helpSupport');
  String get helpSupportSubtitle => _text('helpSupportSubtitle');
  String get session => _text('session');
  String get sessionSignedIn => _text('sessionSignedIn');
  String get sessionSignedOut => _text('sessionSignedOut');
  String get login => _text('login');
  String get logout => _text('logout');
  String get profileHeroReady => _text('profileHeroReady');
  String get profileHeroGuest => _text('profileHeroGuest');
  String get profileHeroReadySubtitle => _text('profileHeroReadySubtitle');
  String get profileHeroGuestSubtitle => _text('profileHeroGuestSubtitle');
  String get compactInfo => _text('compactInfo');
  String get systemSettings => _text('systemSettings');
  String get platformConfiguration => _text('platformConfiguration');
  String get platformConfigurationSubtitle =>
      _text('platformConfigurationSubtitle');
  String get useSystemTheme => _text('useSystemTheme');
  String get useSystemThemeSubtitle => _text('useSystemThemeSubtitle');
  String get lightMode => _text('lightMode');
  String get lightModeSubtitle => _text('lightModeSubtitle');
  String get darkMode => _text('darkMode');
  String get darkModeSubtitle => _text('darkModeSubtitle');
  String get maintenanceMode => _text('maintenanceMode');
  String get maintenanceModeSubtitle => _text('maintenanceModeSubtitle');
  String get require2fa => _text('require2fa');
  String get require2faSubtitle => _text('require2faSubtitle');
  String get save => _text('save');
  String get savedDemo => _text('savedDemo');
  String get governmentAuctionPortal => _text('governmentAuctionPortal');
  String get welcomeBack => _text('welcomeBack');
  String get loginHeroSubtitle => _text('loginHeroSubtitle');
  String get signIn => _text('signIn');
  String get signInSubtitle => _text('signInSubtitle');
  String get emailAddress => _text('emailAddress');
  String get password => _text('password');
  String get emailRequired => _text('emailRequired');
  String get enterValidEmail => _text('enterValidEmail');
  String get passwordRequired => _text('passwordRequired');
  String get min6Chars => _text('min6Chars');
  String get secureSignInNote => _text('secureSignInNote');
  String get continueText => _text('continue');
  String get needAccount => _text('needAccount');
  String get createOne => _text('createOne');
  String get newBidderRegistration => _text('newBidderRegistration');
  String get createYourAccount => _text('createYourAccount');
  String get signupHeroSubtitle => _text('signupHeroSubtitle');
  String get createAccount => _text('createAccount');
  String get createAccountSubtitle => _text('createAccountSubtitle');
  String get fullName => _text('fullName');
  String get nameRequired => _text('nameRequired');
  String get nationalId => _text('nationalId');
  String get nationalIdRequired => _text('nationalIdRequired');
  String get invalidIdLength => _text('invalidIdLength');
  String get email => _text('email');
  String get invalidEmail => _text('invalidEmail');
  String get phone => _text('phone');
  String get phoneRequired => _text('phoneRequired');
  String get minimum8Characters => _text('minimum8Characters');
  String get includeOneNumber => _text('includeOneNumber');
  String get confirmPassword => _text('confirmPassword');
  String get passwordsDoNotMatch => _text('passwordsDoNotMatch');
  String get citizenAccountNote => _text('citizenAccountNote');
  String get alreadyHaveAccount => _text('alreadyHaveAccount');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String tr(String en, String ar) => l10n.t(en, ar);
}
