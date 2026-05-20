import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/i18n/app_strings.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/input_field.dart';
import '../../../presentation/widgets/belumi_luxury.dart';
import '../application/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  final fullName = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).isLoading;
    final t = ref.watch(belumiCopyProvider).t;

    ref.listen(authControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null) context.go('/home');
        },
        error: (error, _) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.toString())));
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const BelumiLogo(height: 28)),
      body: SafeArea(
        child: LuxuryPage(
          maxWidth: 520,
          children: [
            LuxuryHero(
              title: t('Tạo hồ sơ Belumi', 'Create Your Glow Profile'),
              subtitle: t(
                'Tạo tài khoản để Belumi lưu routine, wishlist và gợi ý AI cá nhân hóa.',
                'Create an account so Belumi can save your routine, wishlist and personalized AI suggestions.',
              ),
              imageUrl:
                  'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=1200&q=80',
            ),
            const SizedBox(height: 18),
            LuxuryPanel(
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    InputField(
                      controller: fullName,
                      label: t('Họ tên', 'Full name'),
                      icon: Icons.person_outline,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? t('Nhập họ tên', 'Enter your full name')
                          : null,
                    ),
                    const SizedBox(height: 14),
                    InputField(
                      controller: phone,
                      label: t('Số điện thoại', 'Phone'),
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value == null || value.trim().length < 8
                          ? t(
                              'Số điện thoại không hợp lệ',
                              'Invalid phone number',
                            )
                          : null,
                    ),
                    const SizedBox(height: 14),
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
                      label: t('Đăng ký', 'Register'),
                      icon: Icons.person_add_alt,
                      loading: loading,
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        ref
                            .read(authControllerProvider.notifier)
                            .register(
                              email: email.text.trim(),
                              password: password.text,
                              fullName: fullName.text.trim(),
                              phone: phone.text.trim(),
                            );
                      },
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        t(
                          'Đã có tài khoản? Đăng nhập',
                          'Already have an account? Login',
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
}
