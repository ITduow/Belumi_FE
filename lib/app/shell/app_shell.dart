import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/i18n/app_strings.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../presentation/widgets/belumi_luxury.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _routes = [
    '/home',
    '/skincare-ai',
    '/ingredient-lookup',
    '/virtual-makeup',
    '/news',
    '/wishlist',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _routes.indexWhere(
      (route) => location.startsWith(route),
    );
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;
    final locale = ref.watch(appLocaleProvider);
    final strings = AppStrings(locale);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: const BelumiLogo(height: 30),
        actions: [
          SegmentedButton<String>(
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            segments: const [
              ButtonSegment(value: 'vi', label: Text('VI')),
              ButtonSegment(value: 'en', label: Text('EN')),
            ],
            selected: {locale},
            onSelectionChanged: (value) =>
                ref.read(appLocaleProvider.notifier).state = value.first,
          ),
          IconButton(
            tooltip: strings.t('about'),
            onPressed: () => context.go('/about'),
            icon: const Icon(Icons.info_outline),
          ),
          if (authState.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (user == null)
            TextButton(
              onPressed: () => context.go('/login'),
              child: Text(strings.t('login')),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle),
              onSelected: (value) {
                if (value == 'logout') {
                  ref.read(authControllerProvider.notifier).logout();
                  context.go('/login');
                } else if (value == 'admin') {
                  context.go('/admin');
                } else if (value == 'profile') {
                  context.go('/profile');
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(enabled: false, child: Text(user.email)),
                const PopupMenuItem(value: 'profile', child: Text('Profile')),
                if (user.role.toLowerCase() == 'admin')
                  PopupMenuItem(
                    value: 'admin',
                    child: Text(strings.t('admin')),
                  ),
                PopupMenuItem(
                  value: 'logout',
                  child: Text(strings.t('logout')),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: DecoratedBox(
          decoration: BelumiLuxury.background,
          child: KeyedSubtree(key: ValueKey(locale), child: child),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFFFFF9F5),
        indicatorColor: const Color(0xFFFFE8E0),
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        onDestinationSelected: (index) => context.go(_routes[index]),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: strings.t('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_awesome_outlined),
            selectedIcon: const Icon(Icons.auto_awesome),
            label: strings.t('skincareAi'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.document_scanner_outlined),
            selectedIcon: const Icon(Icons.document_scanner),
            label: strings.t('ingredientLookup'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.face_retouching_natural_outlined),
            selectedIcon: const Icon(Icons.face_retouching_natural),
            label: strings.t('virtualMakeup'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.article_outlined),
            selectedIcon: const Icon(Icons.article),
            label: strings.t('news'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
            label: strings.t('wishlist'),
          ),
        ],
      ),
    );
  }
}
