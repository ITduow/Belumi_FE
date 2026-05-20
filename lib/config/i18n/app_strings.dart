import 'package:flutter_riverpod/flutter_riverpod.dart';

final appLocaleProvider = StateProvider<String>((ref) => 'vi');

final belumiCopyProvider = Provider<BelumiCopy>((ref) {
  return BelumiCopy(ref.watch(appLocaleProvider));
});

class BelumiCopy {
  const BelumiCopy(this.locale);

  final String locale;

  bool get isVi => locale == 'vi';

  String t(String vi, String en) => isVi ? vi : en;
}

class AppStrings {
  AppStrings(this.locale);

  final String locale;

  String t(String key) =>
      (_values[locale] ?? _values['vi']!)[key] ?? _values['vi']![key] ?? key;

  static final Map<String, Map<String, String>> _values = {
    'vi': {
      'home': 'Trang chủ',
      'skincareAi': 'AI chăm sóc da',
      'ingredientLookup': 'Tra cứu thành phần',
      'virtualMakeup': 'Trang điểm ảo',
      'news': 'Tin tức',
      'wishlist': 'Yêu thích',
      'about': 'Về Belumi',
      'pricing': 'Bảng giá',
      'payment': 'Thanh toán',
      'adminLogin': 'Đăng nhập quản trị',
      'adminPanel': 'Quản trị',
      'skinAnalysis': 'Phân tích da',
      'makeupConsultation': 'Tư vấn makeup',
      'googleLogin': 'Đăng nhập Google',
      'language': 'Ngôn ngữ',
      'login': 'Đăng nhập',
      'logout': 'Đăng xuất',
      'admin': 'Quản trị',
    },
    'en': {
      'home': 'Home',
      'skincareAi': 'Skincare AI',
      'ingredientLookup': 'Ingredient Lookup',
      'virtualMakeup': 'Virtual Makeup',
      'news': 'News',
      'wishlist': 'Wishlist',
      'about': 'About',
      'pricing': 'Pricing',
      'payment': 'Payment',
      'adminLogin': 'Admin Login',
      'adminPanel': 'Admin Panel',
      'skinAnalysis': 'Skin Analysis',
      'makeupConsultation': 'Makeup Consultation',
      'googleLogin': 'Google Sign-in',
      'language': 'Language',
      'login': 'Login',
      'logout': 'Logout',
      'admin': 'Admin',
    },
  };
}
