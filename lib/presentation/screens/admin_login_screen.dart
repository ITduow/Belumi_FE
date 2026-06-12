import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/i18n/app_strings.dart';
import '../../data/repositories/belumi_repository.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/data/admin_auth_service.dart';
import '../widgets/belumi_luxury.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(belumiCopyProvider);
    final t = copy.t;

    return Scaffold(
      appBar: AppBar(
        title: const BelumiLogo(height: 32),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _AdminLanguageSwitch(
              locale: copy.locale,
              onChanged: (locale) =>
                  ref.read(appLocaleProvider.notifier).state = locale,
            ),
          ),
        ],
      ),
      body: LuxuryPage(
        maxWidth: 520,
        children: [
          LuxuryHero(
            title: t('Trung tâm quản trị', 'Admin Center'),
            subtitle: t(
              'Đăng nhập để quản lý người dùng, nội dung, gói dịch vụ và dữ liệu AI của Belumi.',
              'Sign in to manage users, content, plans and AI data for Belumi.',
            ),
            imageUrl:
                'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=1200&q=80',
          ),
          const SizedBox(height: 18),
          LuxuryPanel(
            child: Column(
              children: [
                TextField(
                  controller: email,
                  decoration: InputDecoration(
                    labelText: t('Email quản trị', 'Admin email'),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: t('Mật khẩu', 'Password'),
                  ),
                  onSubmitted: (_) => _submitAdminLogin(),
                ),
                const SizedBox(height: 16),
                LuxuryButton(
                  label: loading
                      ? t('Đang đăng nhập...', 'Signing in...')
                      : t('Đăng nhập quản trị', 'Admin login'),
                  icon: Icons.admin_panel_settings,
                  onPressed: loading ? null : _submitAdminLogin,
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: loading ? null : () => context.go('/home'),
                        icon: const Icon(Icons.home_outlined),
                        label: Text(t('Trang chủ', 'Home')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: loading ? null : () => context.go('/login'),
                        icon: const Icon(Icons.login_outlined),
                        label: Text(t('Login thường', 'User login')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAdminLogin() async {
    setState(() {
      loading = true;
      error = null;
    });

    final authController = ref.read(authControllerProvider.notifier);
    final user = await authController.adminLogin(
      email.text.trim(),
      password.text,
    );

    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    final loginError = authState.error;
    if (loginError != null) {
      setState(() {
        error = _friendlyAdminError(loginError);
        loading = false;
      });
      return;
    }

    if (user?.isAdmin == true) {
      setState(() => loading = false);
      context.go('/admin-dashboard');
      return;
    }

    await authController.logout();
    if (!mounted) return;

    setState(() {
      error = ref.read(belumiCopyProvider).t(
            'Bạn không có quyền truy cập trang quản trị.',
            'You are not allowed to access the admin panel.',
          );
      loading = false;
    });
  }

  String _friendlyAdminError(Object error) {
    final t = ref.read(belumiCopyProvider).t;
    if (error is AdminAccessDeniedException) {
      return t(
        'Bạn không có quyền truy cập trang quản trị.',
        'You are not allowed to access the admin panel.',
      );
    }

    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' ||
        'invalid-email' =>
          t('Email hoặc mật khẩu quản trị không đúng.',
              'Invalid admin email or password.'),
        'too-many-requests' => t(
            'Bạn thử sai quá nhiều lần. Vui lòng đợi rồi thử lại.',
            'Too many failed attempts. Please wait and try again.',
          ),
        'network-request-failed' => t(
            'Lỗi mạng. Vui lòng kiểm tra kết nối.',
            'Network error. Please check your connection.',
          ),
        'firebase-placeholder-config' => t(
            'Firebase client chưa được cấu hình.',
            'Firebase client config is still placeholder.',
          ),
        _ => error.message ?? t('Đăng nhập quản trị thất bại.',
            'Admin login failed.'),
      };
    }

    final message = error.toString();
    if (message.contains('user-not-found') ||
        message.contains('wrong-password') ||
        message.contains('invalid-credential')) {
      return t(
        'Email hoặc mật khẩu quản trị không đúng.',
        'Invalid admin email or password.',
      );
    }
    if (message.contains('Firebase client config is still placeholder')) {
      return t(
        'Firebase client chưa được cấu hình.',
        'Firebase client config is still placeholder.',
      );
    }
    return message;
  }
}

class _AdminLanguageSwitch extends StatelessWidget {
  const _AdminLanguageSwitch({required this.locale, required this.onChanged});

  final String locale;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE7D7D1)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LanguageChip(
            label: 'VI',
            selected: locale == 'vi',
            onTap: () => onChanged('vi'),
          ),
          _LanguageChip(
            label: 'EN',
            selected: locale == 'en',
            onTap: () => onChanged('en'),
          ),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: selected ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? BelumiLuxury.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : BelumiLuxury.ink,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
