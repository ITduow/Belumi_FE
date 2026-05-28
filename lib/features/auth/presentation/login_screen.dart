import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/i18n/app_strings.dart';
import '../../../presentation/widgets/belumi_luxury.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/input_field.dart';
import '../application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController(text: 'customer@belumi.vn');
  final password = TextEditingController(text: 'Customer@123');
  String? errorText;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final loading = authState.isLoading;
    final t = ref.watch(belumiCopyProvider).t;

    return Scaffold(
      body: SafeArea(
        child: LuxuryPage(
          maxWidth: 520,
          children: [
            LuxuryHero(
              title: t('Chào mừng trở lại', 'Welcome Back'),
              subtitle: t(
                'Đăng nhập để đồng bộ Skin AI, Wishlist và Beauty Profile của bạn.',
                'Sign in to sync your Skin AI, Wishlist and Beauty Profile.',
              ),
              imageUrl:
                  'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?auto=format&fit=crop&w=1200&q=80',
            ),
            const SizedBox(height: 18),
            LuxuryPanel(
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    const BelumiLogo(height: 42),
                    const SizedBox(height: 18),
                    InputField(
                      controller: email,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? t('Email không hợp lệ', 'Invalid email')
                          : null,
                    ),
                    const SizedBox(height: 14),
                    InputField(
                      controller: password,
                      label: t('Mật khẩu', 'Password'),
                      icon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) => value == null || value.length < 6
                          ? t(
                              'Mật khẩu tối thiểu 6 ký tự',
                              'Password must be at least 6 characters',
                            )
                          : null,
                    ),
                    const SizedBox(height: 18),
                    CustomButton(
                      label: t('Đăng nhập', 'Login'),
                      icon: Icons.login,
                      loading: loading,
                      onPressed: _submitLogin,
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      _AuthNotice(
                        icon: Icons.error_outline,
                        message: errorText!,
                        tone: _AuthNoticeTone.error,
                      ),
                    ],
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: loading ? null : _submitGoogleLogin,
                      icon: const Icon(Icons.g_mobiledata),
                      label: Text(t('Đăng nhập Google', 'Sign in with Google')),
                    ),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: Text(
                        t(
                          'Chưa có tài khoản? Đăng ký',
                          'No account yet? Register',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitLogin() async {
    if (!formKey.currentState!.validate()) return;
    await _runLogin(
      () => ref
          .read(authControllerProvider.notifier)
          .login(email.text.trim(), password.text),
    );
  }

  Future<void> _submitGoogleLogin() async {
    await _runLogin(
      () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
    );
  }

  Future<void> _runLogin(Future<Object?> Function() loginAction) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => errorText = null);
    messenger.clearSnackBars();

    try {
      final user = await loginAction();
      if (!mounted || user == null) return;

      final t = ref.read(belumiCopyProvider).t;
      _showAuthSnackBar(
        message: t('Đăng nhập thành công', 'Login successful'),
        tone: _AuthNoticeTone.success,
      );
      context.go('/home');
    } catch (error) {
      if (!mounted) return;

      final message = _friendlyError(error);
      setState(() => errorText = message);
    }
  }

  void _showAuthSnackBar({
    required String message,
    required _AuthNoticeTone tone,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 2),
        content: _AuthNotice(
          icon: tone == _AuthNoticeTone.success
              ? Icons.check_circle_outline
              : Icons.error_outline,
          message: message,
          tone: tone,
        ),
      ),
    );
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('invalid-credential') ||
        message.contains('wrong-password') ||
        message.contains('user-not-found')) {
      return 'Email hoặc mật khẩu không đúng.';
    }
    if (message.contains('too-many-requests')) {
      return 'Bạn đang thử quá nhiều lần. Vui lòng đợi một lát rồi thử lại.';
    }
    if (message.contains('network-request-failed')) {
      return 'Không kết nối được máy chủ đăng nhập. Kiểm tra mạng rồi thử lại.';
    }
    if (message.contains('REPLACE_WITH')) {
      return 'Chưa cấu hình Firebase client. Hãy thay lib/firebase_options.dart bằng file tạo từ flutterfire configure.';
    }
    if (message.contains('popup') || message.contains('unauthorized-domain')) {
      return 'Google Sign-In bị chặn. Kiểm tra Firebase Auth provider và Authorized domains.';
    }
    return message;
  }
}

enum _AuthNoticeTone { success, error }

class _AuthNotice extends StatelessWidget {
  const _AuthNotice({
    required this.icon,
    required this.message,
    required this.tone,
  });

  final IconData icon;
  final String message;
  final _AuthNoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final accent = tone == _AuthNoticeTone.success
        ? const Color(0xFF4D8B6F)
        : const Color(0xFFB85C5C);
    final fill = tone == _AuthNoticeTone.success
        ? const Color(0xFFF3FAF6)
        : const Color(0xFFFFF5F2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1DFD8)),
        boxShadow: [
          BoxShadow(
            color: BelumiLuxury.rose.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: fill,
            child: Icon(icon, color: accent, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: BelumiLuxury.ink,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
