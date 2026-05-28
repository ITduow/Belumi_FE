import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/i18n/app_strings.dart';
import '../../../presentation/widgets/belumi_luxury.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/input_field.dart';
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
  String? errorText;

  @override
  void dispose() {
    fullName.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).isLoading;
    final t = ref.watch(belumiCopyProvider).t;

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
                      onPressed: _submitRegister,
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      _RegisterNotice(message: errorText!),
                    ],
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

  Future<void> _submitRegister() async {
    if (!formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => errorText = null);
    messenger.clearSnackBars();

    try {
      final user = await ref
          .read(authControllerProvider.notifier)
          .register(
            email: email.text.trim(),
            password: password.text,
            fullName: fullName.text.trim(),
            phone: phone.text.trim(),
          );
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ref
                .read(belumiCopyProvider)
                .t('Đăng ký thành công', 'Registration successful'),
          ),
        ),
      );
      if (user.email.isNotEmpty) context.go('/home');
    } catch (error) {
      if (!mounted) return;
      setState(() => errorText = _friendlyError(error));
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('email-already-in-use')) {
      return 'Email này đã được đăng ký.';
    }
    if (message.contains('weak-password')) {
      return 'Mật khẩu chưa đủ mạnh. Vui lòng dùng mật khẩu khác.';
    }
    if (message.contains('invalid-email')) {
      return 'Email không hợp lệ.';
    }
    if (message.contains('network-request-failed')) {
      return 'Không kết nối được máy chủ đăng ký. Kiểm tra mạng rồi thử lại.';
    }
    return message;
  }
}

class _RegisterNotice extends StatelessWidget {
  const _RegisterNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
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
          const CircleAvatar(
            radius: 17,
            backgroundColor: Color(0xFFFFF5F2),
            child: Icon(
              Icons.error_outline,
              color: Color(0xFFB85C5C),
              size: 19,
            ),
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
