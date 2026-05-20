import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/i18n/app_strings.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/input_field.dart';
import '../../../presentation/widgets/belumi_luxury.dart';
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final loading = authState.isLoading;
    final t = ref.watch(belumiCopyProvider).t;

    ref.listen(authControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null) context.go('/home');
        },
        error: (error, _) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
        },
      );
    });

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
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        ref
                            .read(authControllerProvider.notifier)
                            .login(email.text.trim(), password.text);
                      },
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: loading
                          ? null
                          : () => ref
                                .read(authControllerProvider.notifier)
                                .signInWithGoogle(),
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

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('REPLACE_WITH')) {
      return 'Chua cau hinh Firebase client. Hay thay lib/firebase_options.dart bang file tao tu flutterfire configure.';
    }
    if (message.contains('popup') || message.contains('unauthorized-domain')) {
      return 'Google Sign-In bi chan. Kiem tra Firebase Auth provider va Authorized domains co localhost.';
    }
    return message;
  }
}
