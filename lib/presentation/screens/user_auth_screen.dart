import 'package:flutter/material.dart';

import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../widgets/belumi_luxury.dart';

class UserAuthScreen extends StatefulWidget {
  const UserAuthScreen({
    super.key,
    required this.repository,
    required this.onAuthenticated,
  });

  final BelumiRepository repository;
  final ValueChanged<AuthUser> onAuthenticated;

  @override
  State<UserAuthScreen> createState() => _UserAuthScreenState();
}

class _UserAuthScreenState extends State<UserAuthScreen> {
  bool registerMode = false;
  bool loading = false;
  String? error;

  final email = TextEditingController(text: 'customer@belumi.vn');
  final password = TextEditingController(text: 'Customer@123');
  final fullName = TextEditingController(text: 'Belumi Customer');
  final phone = TextEditingController(text: '0911111111');

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          registerMode ? t('Đăng ký', 'Register') : t('Đăng nhập', 'Login'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            registerMode
                ? t('Tạo tài khoản Belumi', 'Create Belumi account')
                : t('Đăng nhập khách hàng', 'Customer login'),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            t(
              'Tài khoản user dùng cho Skin AI, Wishlist và Beauty Profile.',
              'User account for Skin AI, Wishlist and Beauty Profile.',
            ),
          ),
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.login),
                label: Text(t('Đăng nhập', 'Login')),
              ),
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.person_add),
                label: Text(t('Đăng ký', 'Register')),
              ),
            ],
            selected: {registerMode},
            onSelectionChanged: (value) {
              setState(() {
                registerMode = value.first;
                error = null;
              });
            },
          ),
          const SizedBox(height: 18),
          if (registerMode) ...[
            TextField(
              controller: fullName,
              decoration: InputDecoration(labelText: t('Họ tên', 'Full name')),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              decoration: InputDecoration(
                labelText: t('Số điện thoại', 'Phone'),
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            obscureText: true,
            decoration: InputDecoration(labelText: t('Mật khẩu', 'Password')),
            onSubmitted: (_) => _submit(),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: loading ? null : _submit,
            icon: Icon(registerMode ? Icons.person_add : Icons.login),
            label: Text(
              loading
                  ? t('Đang xử lý...', 'Processing...')
                  : registerMode
                  ? t('Tạo tài khoản', 'Create account')
                  : t('Đăng nhập', 'Login'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: loading
                ? null
                : () async {
                    setState(() {
                      loading = true;
                      error = null;
                    });
                    try {
                      final user = await widget.repository.googleMockLogin();
                      widget.onAuthenticated(user);
                      if (context.mounted) Navigator.pop(context);
                    } catch (_) {
                      setState(() {
                        error = t(
                          'Google mock login thất bại. Kiểm tra backend.',
                          'Google mock login failed. Check backend.',
                        );
                      });
                    } finally {
                      if (mounted) setState(() => loading = false);
                    }
                  },
            icon: const Icon(Icons.g_mobiledata),
            label: Text(t('Đăng nhập Google mock', 'Google mock login')),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                t(
                  'Tài khoản seed: customer@belumi.vn / Customer@123',
                  'Seed account: customer@belumi.vn / Customer@123',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final t = belumiCopy(context).t;
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final user = registerMode
          ? await widget.repository.register(
              email.text.trim(),
              password.text,
              fullName.text.trim(),
              phone.text.trim(),
            )
          : await widget.repository.login(email.text.trim(), password.text);
      widget.onAuthenticated(user);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() {
        error = registerMode
            ? t(
                'Đăng ký thất bại. Email có thể đã tồn tại hoặc API chưa chạy.',
                'Registration failed. Email may already exist or API is not running.',
              )
            : t(
                'Đăng nhập thất bại. Kiểm tra email/mật khẩu hoặc backend.',
                'Login failed. Check email/password or backend.',
              );
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
