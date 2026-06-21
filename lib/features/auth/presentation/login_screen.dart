import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/i18n/app_strings.dart';
import '../application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const Color _background = Color(0xFFF5F0ED);
  static const Color _brandBrown = Color(0xFF7A5A3C);
  static const Color _buttonBrown = Color(0xFFA7754B);
  static const Color _mutedText = Color(0xFFB5A69D);
  static const Color _border = Color(0xFFD9CCC5);

  final formKey = GlobalKey<FormState>();
  final fullName = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool registerMode = false;
  bool rememberAccount = false;
  bool obscurePassword = true;
  int adminTapCount = 0;
  DateTime? lastAdminTapAt;
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
    final authState = ref.watch(authControllerProvider);
    final loading = authState.isLoading;
    final copy = ref.watch(belumiCopyProvider);
    final t = copy.t;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 402),
                  child: SizedBox(
                    height: constraints.maxHeight < 874
                        ? 874
                        : constraints.maxHeight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 50, 24, 0),
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: Row(
                              children: [
                                TextButton.icon(
                                  onPressed: loading
                                      ? null
                                      : () => context.go('/home'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: _brandBrown,
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 34),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 15,
                                  ),
                                  label: Text(
                                    t('Trang chủ', 'Home'),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                _LanguageSwitch(
                                  locale: copy.locale,
                                  onChanged: (locale) =>
                                      ref
                                              .read(appLocaleProvider.notifier)
                                              .state =
                                          locale,
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: Form(
                              key: formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _handleAdminLogoTap,
                                    child: Image.asset(
                                      'assets/images/belumi_logo_login_full.png',
                                      width: 210,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  if (registerMode) ...[
                                    _BelumiTextField(
                                      controller: fullName,
                                      hintText: t('Họ tên', 'Full name'),
                                      keyboardType: TextInputType.name,
                                      validator: (value) =>
                                          value == null || value.trim().isEmpty
                                          ? t(
                                              'Nhập họ tên',
                                              'Enter your full name',
                                            )
                                          : null,
                                    ),
                                    const SizedBox(height: 14),
                                    _BelumiTextField(
                                      controller: phone,
                                      hintText: t(
                                        'Số điện thoại',
                                        'Phone number',
                                      ),
                                      keyboardType: TextInputType.phone,
                                      validator: (value) =>
                                          value == null ||
                                              value.trim().length < 8
                                          ? t(
                                              'Số điện thoại không hợp lệ',
                                              'Invalid phone number',
                                            )
                                          : null,
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                  _BelumiTextField(
                                    controller: email,
                                    hintText: t(
                                      'Mail/Số điện thoại',
                                      'Email/Phone number',
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) =>
                                        value == null || !value.contains('@')
                                        ? t(
                                            'Email không hợp lệ',
                                            'Invalid email',
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                  _BelumiTextField(
                                    controller: password,
                                    hintText: t('Mật khẩu', 'Password'),
                                    obscureText: obscurePassword,
                                    suffix: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 40,
                                            height: 36,
                                          ),
                                      visualDensity: VisualDensity.compact,
                                      tooltip: obscurePassword
                                          ? t('Hiện mật khẩu', 'Show password')
                                          : t('Ẩn mật khẩu', 'Hide password'),
                                      icon: Icon(
                                        obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: _mutedText,
                                        size: 19,
                                      ),
                                      onPressed: () => setState(
                                        () =>
                                            obscurePassword = !obscurePassword,
                                      ),
                                    ),
                                    validator: (value) =>
                                        value == null || value.length < 6
                                        ? t(
                                            'Mật khẩu tối thiểu 6 ký tự',
                                            'Password must be at least 6 characters',
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                  if (!registerMode)
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: Checkbox(
                                            value: rememberAccount,
                                            onChanged: loading
                                                ? null
                                                : (value) => setState(
                                                    () => rememberAccount =
                                                        value ?? false,
                                                  ),
                                            activeColor: _buttonBrown,
                                            side: const BorderSide(
                                              color: _border,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          t('Ghi nhớ tài khoản', 'Remember me'),
                                          style: const TextStyle(
                                            color: Color(0xFF8A7B72),
                                            fontSize: 12,
                                          ),
                                        ),
                                        const Spacer(),
                                        TextButton(
                                          onPressed: loading
                                              ? null
                                              : _showForgotPasswordNotice,
                                          style: TextButton.styleFrom(
                                            minimumSize: Size.zero,
                                            padding: EdgeInsets.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            foregroundColor: _brandBrown,
                                          ),
                                          child: Text(
                                            t(
                                              'Quên mật khẩu?',
                                              'Forgot password?',
                                            ),
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 36,
                                    child: ElevatedButton(
                                      onPressed: loading
                                          ? null
                                          : registerMode
                                          ? _submitRegister
                                          : _submitLogin,
                                      style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        backgroundColor: _buttonBrown,
                                        disabledBackgroundColor: _buttonBrown
                                            .withValues(alpha: 0.62),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                        ),
                                      ),
                                      child: loading
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : Text(
                                              registerMode
                                                  ? t('Đăng ký', 'Register')
                                                  : t('Đăng nhập', 'Login'),
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                  if (errorText != null) ...[
                                    const SizedBox(height: 12),
                                    _AuthNotice(
                                      icon: Icons.error_outline,
                                      message: errorText!,
                                      tone: _AuthNoticeTone.error,
                                    ),
                                  ],
                                  if (!registerMode) ...[
                                    const SizedBox(height: 18),
                                    Text(
                                      t('Hoặc', 'Or'),
                                      style: const TextStyle(
                                        color: _mutedText,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 36,
                                      child: OutlinedButton(
                                        onPressed: loading
                                            ? null
                                            : _submitGoogleLogin,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _buttonBrown,
                                          side: const BorderSide(
                                            color: _buttonBrown,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              22,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Image.asset(
                                              'assets/images/google_logo.png',
                                              width: 18,
                                              height: 18,
                                            ),
                                            const SizedBox(width: 14),
                                            Text(
                                              t(
                                                'Tiếp tục với Google',
                                                'Continue with Google',
                                              ),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        registerMode
                                            ? t(
                                                'Đã có tài khoản? ',
                                                'Already have an account? ',
                                              )
                                            : t(
                                                'Chưa có tài khoản? ',
                                                'No account yet? ',
                                              ),
                                        style: const TextStyle(
                                          color: _mutedText,
                                          fontSize: 12,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: loading ? null : _toggleAuthMode,
                                        child: Text(
                                          registerMode
                                              ? t('Đăng nhập', 'Login')
                                              : t(
                                                  'Đăng ký ngay',
                                                  'Register now',
                                                ),
                                          style: const TextStyle(
                                            color: _brandBrown,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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

  void _showForgotPasswordNotice() {
    final t = ref.read(belumiCopyProvider).t;
    _showAuthSnackBar(
      message: t(
        'Tính năng quên mật khẩu sẽ được bổ sung sau.',
        'Forgot password will be added later.',
      ),
      tone: _AuthNoticeTone.success,
    );
  }

  void _handleAdminLogoTap() {
    final now = DateTime.now();
    final lastTapAt = lastAdminTapAt;
    if (lastTapAt == null ||
        now.difference(lastTapAt) > const Duration(seconds: 3)) {
      adminTapCount = 0;
    }

    lastAdminTapAt = now;
    adminTapCount += 1;
    if (adminTapCount < 5) return;

    adminTapCount = 0;
    lastAdminTapAt = null;
    _showAuthSnackBar(
      message: ref
          .read(belumiCopyProvider)
          .t('Đang mở chế độ quản trị...', 'Opening admin mode...'),
      tone: _AuthNoticeTone.success,
    );
    context.go('/admin-login');
  }

  void _toggleAuthMode() {
    formKey.currentState?.reset();
    setState(() {
      registerMode = !registerMode;
      errorText = null;
      obscurePassword = true;
    });
  }

  Future<void> _submitRegister() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => errorText = null);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            email: email.text.trim(),
            password: password.text,
            fullName: fullName.text.trim(),
            phone: phone.text.trim(),
          );
      if (!mounted) return;

      _showAuthSnackBar(
        message: ref
            .read(belumiCopyProvider)
            .t('Đăng ký thành công', 'Registration successful'),
        tone: _AuthNoticeTone.success,
      );
      context.go('/home');
    } catch (error) {
      if (!mounted) return;
      setState(() => errorText = _friendlyRegisterError(error));
    }
  }

  String _friendlyRegisterError(Object error) {
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

  String _friendlyError(Object error) {
    final message = error.toString();
    final t = ref.read(belumiCopyProvider).t;
    if (message.contains('invalid-credential') ||
        message.contains('wrong-password') ||
        message.contains('user-not-found')) {
      return t(
        'Email hoặc mật khẩu không đúng.',
        'Email or password is wrong.',
      );
    }
    if (message.contains('too-many-requests')) {
      return t(
        'Bạn đang thử quá nhiều lần. Vui lòng đợi một lát rồi thử lại.',
        'Too many attempts. Please wait a moment and try again.',
      );
    }
    if (message.contains('network-request-failed')) {
      return t(
        'Không kết nối được máy chủ đăng nhập. Kiểm tra mạng rồi thử lại.',
        'Could not reach the sign-in server. Check your connection and try again.',
      );
    }
    if (message.contains('REPLACE_WITH')) {
      return t(
        'Chưa cấu hình Firebase client. Hãy thay lib/firebase_options.dart bằng file tạo từ flutterfire configure.',
        'Firebase client is not configured. Replace lib/firebase_options.dart with the file from flutterfire configure.',
      );
    }
    if (message.contains('popup') || message.contains('unauthorized-domain')) {
      return t(
        'Google Sign-In bị chặn. Kiểm tra Firebase Auth provider và Authorized domains.',
        'Google Sign-In is blocked. Check Firebase Auth provider and Authorized domains.',
      );
    }
    return message;
  }
}

class _LanguageSwitch extends StatelessWidget {
  const _LanguageSwitch({required this.locale, required this.onChanged});

  final String locale;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        border: Border.all(color: _LoginScreenState._border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LanguageOption(
            label: 'VI',
            selected: locale == 'vi',
            onTap: () => onChanged('vi'),
          ),
          _LanguageOption(
            label: 'EN',
            selected: locale == 'en',
            onTap: () => onChanged('en'),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
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
          color: selected ? _LoginScreenState._buttonBrown : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _LoginScreenState._brandBrown,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BelumiTextField extends StatelessWidget {
  const _BelumiTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textAlignVertical: TextAlignVertical.center,
        validator: validator,
        style: const TextStyle(
          color: _LoginScreenState._brandBrown,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: _LoginScreenState._mutedText,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          isDense: true,
          filled: true,
          fillColor: _LoginScreenState._background,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          suffixIcon: suffix,
          suffixIconConstraints: const BoxConstraints.tightFor(
            width: 40,
            height: 36,
          ),
          errorStyle: const TextStyle(height: 0, fontSize: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: _LoginScreenState._border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: _LoginScreenState._border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(
              color: _LoginScreenState._buttonBrown,
              width: 1.2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: Color(0xFFB85C5C)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: Color(0xFFB85C5C), width: 1.2),
          ),
        ),
      ),
    );
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF1DFD8)),
        boxShadow: [
          BoxShadow(
            color: _LoginScreenState._buttonBrown.withValues(alpha: 0.14),
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
                color: Color(0xFF3A3028),
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
