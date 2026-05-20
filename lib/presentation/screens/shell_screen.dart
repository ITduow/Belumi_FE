import 'package:flutter/material.dart';

import '../../config/i18n/app_strings.dart';
import '../../core/network/api_client.dart';
import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import 'account_screen.dart';
import 'admin_panel_screen.dart';
import 'home_screen.dart';
import 'ingredient_lookup_screen.dart';
import 'news_screen.dart';
import 'pricing_screen.dart';
import 'product_list_screen.dart';
import 'skin_analysis_screen.dart';
import 'user_auth_screen.dart';
import 'virtual_makeup_screen.dart';
import 'wishlist_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  late final BelumiRepository repository = BelumiRepository(ApiClient());
  int index = 0;
  String locale = 'vi';
  AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(locale);
    final screens = [
      HomeScreen(repository: repository),
      SkinAnalysisScreen(repository: repository),
      IngredientLookupScreen(repository: repository),
      VirtualMakeupScreen(repository: repository),
      NewsScreen(repository: repository),
      WishlistScreen(repository: repository),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('home')),
        actions: [
          TextButton(
            onPressed: () =>
                setState(() => locale = locale == 'vi' ? 'en' : 'vi'),
            child: Text(locale.toUpperCase()),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              ListTile(
                title: const Text('Belumi Beauty'),
                subtitle: Text(
                  user == null
                      ? 'Chua dang nhap'
                      : '${user!.fullName} • ${repository.currentPlan.toUpperCase()}',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_add_alt),
                title: const Text('Dang nhap / Dang ky user'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UserAuthScreen(
                      repository: repository,
                      onAuthenticated: (loggedIn) =>
                          setState(() => user = loggedIn),
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.g_mobiledata),
                title: Text(strings.t('googleLogin')),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final loggedIn = await repository.googleMockLogin();
                    setState(() => user = loggedIn);
                    messenger.showSnackBar(
                      SnackBar(content: Text('Xin chao ${loggedIn.fullName}')),
                    );
                  } catch (_) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Khong ket noi duoc API auth'),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Tai khoan & lien he'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AccountScreen(repository: repository),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.spa),
                title: const Text('Products catalog'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductListScreen(repository: repository),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.payments),
                title: Text(strings.t('pricing')),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PricingScreen(repository: repository),
                  ),
                ),
              ),
              if (repository.isAdmin)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: Text(strings.t('adminPanel')),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminPanelScreen(repository: repository),
                    ),
                  ),
                ),
              if (user != null)
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Dang xuat'),
                  onTap: () {
                    repository.logout();
                    setState(() => user = null);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
      body: SafeArea(child: screens[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
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
