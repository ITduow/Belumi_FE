import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/belumi_repository.dart';
import '../../features/auth/application/auth_controller.dart';
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
    final t = belumiCopy(context).t;
    return Scaffold(
      appBar: AppBar(title: const BelumiLogo(height: 28)),
      body: LuxuryPage(
        maxWidth: 520,
        children: [
          LuxuryHero(
            title: t('Trung tâm quản trị', 'Admin Beauty Center'),
            subtitle: t(
              'Đăng nhập để quản lý user, content, subscription và AI usage của Belumi.',
              'Sign in to manage users, content, subscriptions and AI usage for Belumi.',
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
                ),
                const SizedBox(height: 16),
                LuxuryButton(
                  label: loading
                      ? t('Đang đăng nhập...', 'Signing in...')
                      : t('Đăng nhập quản trị', 'Admin login'),
                  icon: Icons.admin_panel_settings,
                  onPressed: loading
                      ? null
                      : () async {
                          setState(() {
                            loading = true;
                            error = null;
                          });
                          try {
                            await ref
                                .read(authControllerProvider.notifier)
                                .adminLogin(email.text.trim(), password.text);
                            final user = ref
                                .read(authControllerProvider)
                                .valueOrNull;
                            if (user?.role.toLowerCase() == 'admin') {
                              if (context.mounted) context.go('/admin');
                            } else {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .logout();
                              setState(() {
                                error = t(
                                  'Bạn không có quyền truy cập',
                                  'Access denied',
                                );
                              });
                            }
                          } catch (ex) {
                            setState(() {
                              error = t(
                                'Đăng nhập admin thất bại. Kiểm tra API hoặc tài khoản.',
                                'Admin login failed. Check the API or credentials.',
                              );
                            });
                          } finally {
                            if (mounted) setState(() => loading = false);
                          }
                        },
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
