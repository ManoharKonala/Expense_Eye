import 'package:flutter/foundation.dart';

enum AppLanguage {
  english('English', 'English'),
  hindi('Hindi', 'हिन्दी'),
  marathi('Marathi', 'मराठी');

  const AppLanguage(this.englishName, this.nativeName);

  final String englishName;
  final String nativeName;
}

class AppLanguageController {
  static final ValueNotifier<AppLanguage> language = ValueNotifier(
    AppLanguage.english,
  );

  static void setLanguage(AppLanguage value) {
    if (language.value == value) return;
    language.value = value;
  }
}

class AppStrings {
  AppStrings(this.language);

  final AppLanguage language;

  static AppStrings get current =>
      AppStrings(AppLanguageController.language.value);

  String get languageInstruction {
    switch (language) {
      case AppLanguage.hindi:
        return 'Reply only in Hindi. Keep all advice short and clear.';
      case AppLanguage.marathi:
        return 'Reply only in Marathi. Keep all advice short and clear.';
      case AppLanguage.english:
        return 'Reply only in English. Keep all advice short and clear.';
    }
  }

  String t(String key) {
    return _translations[language]?[key] ??
        _translations[AppLanguage.english]![key] ??
        key;
  }
}

const Map<AppLanguage, Map<String, String>> _translations = {
  AppLanguage.english: {
    'appTitle': 'Expense Tracker',
    'createAccount': 'Create Account',
    'username': 'Username',
    'email': 'Email',
    'pin': 'PIN',
    'enterUsername': 'Enter username',
    'enterEmail': 'Enter email',
    'enterValidEmail': 'Enter a valid email',
    'enterPin': 'Enter PIN',
    'dateOfBirth': 'Date of Birth (Calendar)',
    'dob': 'DOB',
    'signUp': 'Sign Up',
    'selectDob': 'SELECT DATE OF BIRTH',
    'profileSettings': 'Profile & Settings',
    'save': 'Save',
    'appSettings': 'App Settings',
    'notifications': 'Notifications',
    'language': 'Language',
    'chooseLanguage': 'Choose Language',
    'monthlyBudget': 'Monthly Budget',
    'dataManagement': 'Data Management',
    'exportExpenseHistory': 'Export Expense History',
    'downloadMonthlyReport': 'Download Monthly Report',
    'privacyData': 'Privacy & Data',
    'privacySettings': 'Privacy Settings',
    'logOut': 'Log Out',
    'privacyPolicy': 'Privacy Policy',
    'privacyPolicyBody':
        'This application is an Open Source Project.\n\nAll your expense data, transactions, and personal settings are strictly stored locally on your device.\n\nTherefore, your data is 100% safe. We do not transmit or store anything on remote servers.\n\nIf you decide to uninstall the app or clear data, make sure to export your history manually using the Data Management features.',
    'gotIt': 'Got it',
    'financerAdviser': 'Financer Adviser',
    'newSession': 'New session',
    'financeGuidance': 'Finance and mutual fund guidance',
    'financeGuidanceSub':
        'Ask for budgeting, SIP, fund, debt, and investing guidance.',
    'chatHint': 'Ask about SIP, budget, mutual funds...',
    'typing': 'Financer Adviser is typing...',
    'chatWelcome':
        'Hi, I am Financer Adviser. Ask me about budgeting, saving, SIPs, mutual funds, debt control, or investment planning.',
    'financeOnly':
        'I can only help with finance and mutual fund advice. Please ask about budgeting, saving, SIPs, mutual funds, debt, or investment planning.',
    'chatEmpty': 'I could not prepare an answer right now. Please try again.',
    'chatError':
        'I am having trouble connecting right now. Please check your internet connection and try again.',
    'spentThisMonth': 'Spent this month',
    'summary': 'Summary',
    'budget': 'Budget',
    'overspent': 'Overspent',
    'budgetExceeded':
        "You've exceeded your budget!\nConsider reviewing your expenses.",
    'spendingCategories': 'Spending Categories',
    'totalSpent': 'Total Spent',
    'recentTransactions': 'Recent Transactions',
    'seeAll': 'See All',
    'all': 'All',
    'income': 'Income',
    'expense': 'Expense',
    'food': 'Food',
    'travel': 'Travel',
    'shopping': 'Shopping',
    'other': 'Other',
    'entertainment': 'Entertainment',
    'makePayment': 'Make Payment',
    'merchant': 'Merchant',
    'amount': 'Amount',
    'category': 'Category',
    'noteOptional': 'Note (Optional)',
    'noteHint': 'e.g. Lunch with friends',
    'payNow': 'Pay Now',
    'chooseUpiApp': 'Choose UPI App',
    'invalidUpiQr': 'Invalid UPI QR code.',
    'cameraRequired': 'Camera permission is required.',
    'enterAmount': 'Please enter an amount',
    'invalidUpiId': 'Invalid UPI ID',
    'noUpiApp': 'No UPI app found. Please install a UPI app to proceed.',
    'failedToLaunch': 'Failed to launch',
    'upiPersonalBlocked':
        'Your installed UPI apps are likely blocking third-party personal QR payments. Please scan this QR directly in the UPI app, or install a UPI app that supports external payment intents.',
    'paymentRejected': 'The selected UPI app rejected this payment request.',
    'allTransactions': 'All Transactions',
    'noTransactions': 'No transactions found.',
    'page': 'Page',
    'of': 'of',
    'payWithUpi': 'Pay with UPI',
    'micPermissionRequired': 'Microphone permission is required.',
    'voiceListening': 'Listening...',
    'voiceProcessing': 'Transcribing voice...',
    'voiceFailed': 'Could not transcribe your voice. Please try again.',
    'voiceNotSupported': 'Voice input could not start on this device.',
    'voiceEmpty':
        'No clear voice was captured. Please speak louder and try again.',
  },
  AppLanguage.hindi: {
    'appTitle': 'खर्च ट्रैकर',
    'createAccount': 'खाता बनाएं',
    'username': 'यूजरनेम',
    'email': 'ईमेल',
    'pin': 'पिन',
    'enterUsername': 'यूजरनेम दर्ज करें',
    'enterEmail': 'ईमेल दर्ज करें',
    'enterValidEmail': 'सही ईमेल दर्ज करें',
    'enterPin': 'पिन दर्ज करें',
    'dateOfBirth': 'जन्म तारीख',
    'dob': 'जन्म तारीख',
    'signUp': 'साइन अप',
    'selectDob': 'जन्म तारीख चुनें',
    'profileSettings': 'प्रोफाइल और सेटिंग्स',
    'save': 'सेव',
    'appSettings': 'ऐप सेटिंग्स',
    'notifications': 'नोटिफिकेशन',
    'language': 'भाषा',
    'chooseLanguage': 'भाषा चुनें',
    'monthlyBudget': 'मासिक बजट',
    'dataManagement': 'डेटा मैनेजमेंट',
    'exportExpenseHistory': 'खर्च हिस्ट्री एक्सपोर्ट करें',
    'downloadMonthlyReport': 'मासिक रिपोर्ट डाउनलोड करें',
    'privacyData': 'प्राइवेसी और डेटा',
    'privacySettings': 'प्राइवेसी सेटिंग्स',
    'logOut': 'लॉग आउट',
    'privacyPolicy': 'प्राइवेसी पॉलिसी',
    'privacyPolicyBody':
        'यह ऐप एक ओपन सोर्स प्रोजेक्ट है।\n\nआपका खर्च डेटा, लेन-देन और सेटिंग्स केवल आपके डिवाइस पर सेव रहती हैं।\n\nहम आपका डेटा किसी सर्वर पर नहीं भेजते या स्टोर करते।\n\nऐप हटाने से पहले अपनी हिस्ट्री एक्सपोर्ट कर लें।',
    'gotIt': 'ठीक है',
    'financerAdviser': 'फाइनेंसर एडवाइजर',
    'newSession': 'नया सेशन',
    'financeGuidance': 'फाइनेंस और म्यूचुअल फंड सलाह',
    'financeGuidanceSub': 'बजट, SIP, फंड, कर्ज और निवेश पर पूछें।',
    'chatHint': 'SIP, बजट, म्यूचुअल फंड पूछें...',
    'typing': 'फाइनेंसर एडवाइजर लिख रहा है...',
    'chatWelcome':
        'नमस्ते, मैं फाइनेंसर एडवाइजर हूं। बजट, बचत, SIP, म्यूचुअल फंड, कर्ज या निवेश प्लानिंग पूछें।',
    'financeOnly':
        'मैं केवल फाइनेंस और म्यूचुअल फंड सलाह दे सकता हूं। कृपया बजट, SIP, कर्ज या निवेश से जुड़ा सवाल पूछें।',
    'chatEmpty': 'अभी जवाब तैयार नहीं हो पाया। कृपया फिर कोशिश करें।',
    'chatError': 'कनेक्शन में दिक्कत है। इंटरनेट चेक करके फिर कोशिश करें।',
    'spentThisMonth': 'इस महीने खर्च',
    'summary': 'सारांश',
    'budget': 'बजट',
    'overspent': 'अधिक खर्च',
    'budgetExceeded': 'आपने बजट पार कर दिया है!\nखर्चों की समीक्षा करें।',
    'spendingCategories': 'खर्च श्रेणियां',
    'totalSpent': 'कुल खर्च',
    'recentTransactions': 'हाल के लेन-देन',
    'seeAll': 'सभी देखें',
    'all': 'सभी',
    'income': 'आय',
    'expense': 'खर्च',
    'food': 'खाना',
    'travel': 'यात्रा',
    'shopping': 'शॉपिंग',
    'other': 'अन्य',
    'entertainment': 'मनोरंजन',
    'makePayment': 'पेमेंट करें',
    'merchant': 'व्यापारी',
    'amount': 'राशि',
    'category': 'श्रेणी',
    'noteOptional': 'नोट (वैकल्पिक)',
    'noteHint': 'जैसे दोस्तों के साथ लंच',
    'payNow': 'अभी भुगतान करें',
    'chooseUpiApp': 'UPI ऐप चुनें',
    'invalidUpiQr': 'गलत UPI QR कोड।',
    'cameraRequired': 'कैमरा अनुमति जरूरी है।',
    'enterAmount': 'कृपया राशि दर्ज करें',
    'invalidUpiId': 'गलत UPI ID',
    'noUpiApp': 'UPI ऐप नहीं मिला। कृपया UPI ऐप इंस्टॉल करें।',
    'failedToLaunch': 'खोलने में विफल',
    'upiPersonalBlocked':
        'आपके UPI ऐप थर्ड-पार्टी पर्सनल QR पेमेंट ब्लॉक कर सकते हैं। QR को सीधे UPI ऐप में स्कैन करें।',
    'paymentRejected': 'चुने गए UPI ऐप ने पेमेंट रिक्वेस्ट अस्वीकार की।',
    'allTransactions': 'सभी लेन-देन',
    'noTransactions': 'कोई लेन-देन नहीं मिला।',
    'page': 'पेज',
    'of': 'में से',
    'payWithUpi': 'UPI से भुगतान',
    'micPermissionRequired': 'माइक्रोफोन अनुमति जरूरी है।',
    'voiceListening': 'सुन रहा है...',
    'voiceProcessing': 'आवाज़ को टेक्स्ट में बदला जा रहा है...',
    'voiceFailed': 'आवाज़ को टेक्स्ट में नहीं बदल पाया। फिर कोशिश करें।',
    'voiceNotSupported': 'इस डिवाइस पर वॉइस इनपुट शुरू नहीं हो सका।',
    'voiceEmpty': 'साफ आवाज रिकॉर्ड नहीं हुई। कृपया फिर से बोलें।',
  },
  AppLanguage.marathi: {
    'appTitle': 'खर्च ट्रॅकर',
    'createAccount': 'खाते तयार करा',
    'username': 'युजरनेम',
    'email': 'ईमेल',
    'pin': 'पिन',
    'enterUsername': 'युजरनेम टाका',
    'enterEmail': 'ईमेल टाका',
    'enterValidEmail': 'योग्य ईमेल टाका',
    'enterPin': 'पिन टाका',
    'dateOfBirth': 'जन्म तारीख',
    'dob': 'जन्म तारीख',
    'signUp': 'साइन अप',
    'selectDob': 'जन्म तारीख निवडा',
    'profileSettings': 'प्रोफाइल आणि सेटिंग्स',
    'save': 'सेव',
    'appSettings': 'ऐप सेटिंग्स',
    'notifications': 'नोटिफिकेशन्स',
    'language': 'भाषा',
    'chooseLanguage': 'भाषा निवडा',
    'monthlyBudget': 'मासिक बजेट',
    'dataManagement': 'डेटा मॅनेजमेंट',
    'exportExpenseHistory': 'खर्च हिस्ट्री एक्सपोर्ट करा',
    'downloadMonthlyReport': 'मासिक रिपोर्ट डाउनलोड करा',
    'privacyData': 'प्रायव्हसी आणि डेटा',
    'privacySettings': 'प्रायव्हसी सेटिंग्स',
    'logOut': 'लॉग आउट',
    'privacyPolicy': 'प्रायव्हसी पॉलिसी',
    'privacyPolicyBody':
        'हे अॅप ओपन सोर्स प्रोजेक्ट आहे।\n\nतुमचा खर्च डेटा, व्यवहार आणि सेटिंग्स फक्त तुमच्या डिवाइसवर सेव राहतात।\n\nआम्ही तुमचा डेटा सर्व्हरवर पाठवत किंवा सेव करत नाही।\n\nअॅप हटवण्यापूर्वी हिस्ट्री एक्सपोर्ट करा।',
    'gotIt': 'ठीक आहे',
    'financerAdviser': 'फाइनेंसर अॅडवायजर',
    'newSession': 'नवे सेशन',
    'financeGuidance': 'फायनान्स आणि म्युच्युअल फंड सल्ला',
    'financeGuidanceSub': 'बजेट, SIP, फंड, कर्ज आणि गुंतवणूक विचारा।',
    'chatHint': 'SIP, बजेट, म्युच्युअल फंड विचारा...',
    'typing': 'फाइनेंसर अॅडवायजर लिहित आहे...',
    'chatWelcome':
        'नमस्कार, मी फाइनेंसर अॅडवायजर आहे. बजेट, बचत, SIP, म्युच्युअल फंड, कर्ज किंवा गुंतवणूक प्लॅनिंग विचारा.',
    'financeOnly':
        'मी फक्त फायनान्स आणि म्युच्युअल फंड सल्ला देऊ शकतो. कृपया बजेट, SIP, कर्ज किंवा गुंतवणुकीचा प्रश्न विचारा.',
    'chatEmpty': 'आत्ता उत्तर तयार झाले नाही. पुन्हा प्रयत्न करा.',
    'chatError': 'कनेक्शनमध्ये अडचण आहे. इंटरनेट तपासून पुन्हा प्रयत्न करा.',
    'spentThisMonth': 'या महिन्यात खर्च',
    'summary': 'सारांश',
    'budget': 'बजेट',
    'overspent': 'जास्त खर्च',
    'budgetExceeded': 'तुम्ही बजेट ओलांडले आहे!\nखर्च तपासा.',
    'spendingCategories': 'खर्च श्रेणी',
    'totalSpent': 'एकूण खर्च',
    'recentTransactions': 'अलीकडील व्यवहार',
    'seeAll': 'सर्व पहा',
    'all': 'सर्व',
    'income': 'उत्पन्न',
    'expense': 'खर्च',
    'food': 'खाणे',
    'travel': 'प्रवास',
    'shopping': 'शॉपिंग',
    'other': 'इतर',
    'entertainment': 'मनोरंजन',
    'makePayment': 'पेमेंट करा',
    'merchant': 'व्यापारी',
    'amount': 'रक्कम',
    'category': 'श्रेणी',
    'noteOptional': 'नोट (पर्यायी)',
    'noteHint': 'उदा. मित्रांसोबत लंच',
    'payNow': 'आता पे करा',
    'chooseUpiApp': 'UPI अॅप निवडा',
    'invalidUpiQr': 'चुकीचा UPI QR कोड.',
    'cameraRequired': 'कॅमेरा परवानगी आवश्यक आहे.',
    'enterAmount': 'कृपया रक्कम टाका',
    'invalidUpiId': 'चुकीचा UPI ID',
    'noUpiApp': 'UPI अॅप सापडले नाही. कृपया UPI अॅप इंस्टॉल करा.',
    'failedToLaunch': 'उघडता आले नाही',
    'upiPersonalBlocked':
        'तुमचे UPI अॅप्स थर्ड-पार्टी पर्सनल QR पेमेंट ब्लॉक करू शकतात. QR थेट UPI अॅपमध्ये स्कॅन करा.',
    'paymentRejected': 'निवडलेल्या UPI अॅपने पेमेंट रिक्वेस्ट नाकारली.',
    'allTransactions': 'सर्व व्यवहार',
    'noTransactions': 'व्यवहार सापडले नाहीत.',
    'page': 'पेज',
    'of': 'पैकी',
    'payWithUpi': 'UPI ने पे करा',
    'micPermissionRequired': 'मायक्रोफोन परवानगी आवश्यक आहे.',
    'voiceListening': 'ऐकत आहे...',
    'voiceProcessing': 'आवाजाचे मजकुरात रूपांतर सुरू आहे...',
    'voiceFailed': 'आवाजाचे मजकुरात रूपांतर करता आले नाही. पुन्हा प्रयत्न करा.',
    'voiceNotSupported': 'या डिवाइसवर व्हॉइस इनपुट सुरू होऊ शकले नाही.',
    'voiceEmpty': 'स्पष्ट आवाज रेकॉर्ड झाला नाही. कृपया पुन्हा बोला.',
  },
};
