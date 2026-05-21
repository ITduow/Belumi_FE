import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      error = 'You are not allowed to access admin panel.';
      loading = false;
    });
  }

  String _friendlyAdminError(Object error) {
    if (error is AdminAccessDeniedException) {
      return 'You are not allowed to access admin panel.';
    }

    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' ||
        'invalid-email' => 'Invalid admin email or password.',
        'too-many-requests' =>
          'Too many failed attempts. Please wait and try again.',
        'network-request-failed' =>
          'Network error. Please check your connection.',
        'firebase-placeholder-config' =>
          'Firebase client config is still placeholder.',
        _ => error.message ?? 'Admin login failed.',
      };
    }

    final message = error.toString();
    if (message.contains('user-not-found') ||
        message.contains('wrong-password') ||
        message.contains('invalid-credential')) {
      return 'Invalid admin email or password.';
    }
    if (message.contains('Firebase client config is still placeholder')) {
      return 'Firebase client config is still placeholder.';
    }
    return message;
  }
}
