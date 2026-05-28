import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../data/models/belumi_models.dart' as legacy_models;
import '../../data/repositories/belumi_repository.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_screen_v2.dart';
import '../../presentation/screens/about_screen.dart';
import '../../presentation/screens/admin_login_screen.dart';
import '../../presentation/screens/admin_news_screen.dart';
import '../../presentation/screens/admin_panel_screen.dart';
import '../../presentation/screens/account_screen.dart';
import '../../presentation/screens/ingredient_lookup_screen.dart';
import '../../presentation/screens/news_detail_screen.dart';
import '../../presentation/screens/news_screen.dart';
import '../../presentation/screens/payment_screen.dart';
import '../../presentation/screens/pricing_screen.dart';
import '../../presentation/screens/skin_analysis_screen.dart';
import '../../presentation/screens/virtual_makeup_screen.dart';
import '../../presentation/screens/wishlist_screen.dart';
import '../shell/app_shell.dart';

final legacyRepositoryProvider = Provider<BelumiRepository>((ref) {
  final repository = BelumiRepository(ApiClient());

  void syncLegacyAuth(AsyncValue<AppUser?> authState) {
    final user = authState.valueOrNull;
    repository.api.token = user?.token;
    repository.currentUser = user == null
        ? null
        : legacy_models.AuthUser(
            userId: user.id,
            email: user.email,
            fullName: user.fullName,
            role: user.role,
            token: user.token,
            phone: user.phone,
          );
  }

  syncLegacyAuth(ref.read(authControllerProvider));
  ref.listen(authControllerProvider, (_, next) => syncLegacyAuth(next));

  return repository;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final legacyRepository = ref.watch(legacyRepositoryProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final user = ref.read(authControllerProvider).valueOrNull;
      final loggedIn = user != null;
      final privateRoute = state.uri.path == '/wishlist';
      final adminRoute =
          state.uri.path == '/admin-dashboard' ||
          (state.uri.path.startsWith('/admin') &&
              state.uri.path != '/admin-login');

      if (!loggedIn && privateRoute) return '/login';
      if (adminRoute && !loggedIn) return '/login';
      if (adminRoute && user?.role.toLowerCase() != 'admin') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/admin-login',
        builder: (context, state) =>
            AdminLoginScreen(repository: legacyRepository),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) =>
            AdminPanelScreen(repository: legacyRepository),
      ),
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) =>
            AdminPanelScreen(repository: legacyRepository),
      ),
      GoRoute(
        path: '/admin/news',
        builder: (context, state) =>
            AdminNewsScreen(repository: legacyRepository),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                HomeScreenV2(repository: legacyRepository),
          ),
          GoRoute(
            path: '/skincare-ai',
            builder: (context, state) =>
                SkinAnalysisScreen(repository: legacyRepository),
          ),
          GoRoute(
            path: '/ingredient-lookup',
            builder: (context, state) =>
                IngredientLookupScreen(repository: legacyRepository),
          ),
          GoRoute(
            path: '/virtual-makeup',
            builder: (context, state) =>
                VirtualMakeupScreen(repository: legacyRepository),
          ),
          GoRoute(
            path: '/news',
            builder: (context, state) =>
                NewsScreen(repository: legacyRepository),
          ),
          GoRoute(
            path: '/news/:slug',
            builder: (context, state) => NewsDetailScreen(
              repository: legacyRepository,
              slug: state.pathParameters['slug'] ?? '',
            ),
          ),
          GoRoute(
            path: '/wishlist',
            builder: (context, state) =>
                WishlistScreen(repository: legacyRepository),
          ),
          GoRoute(
            path: '/pricing',
            builder: (context, state) =>
                PricingScreen(repository: legacyRepository),
          ),
          GoRoute(
            path: '/about',
            builder: (context, state) => const AboutScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) =>
                AccountScreen(repository: legacyRepository),
          ),
          GoRoute(
            path: '/payment/:plan',
            builder: (context, state) => PaymentScreen(
              repository: legacyRepository,
              planCode: state.pathParameters['plan'] ?? 'plus',
            ),
          ),
        ],
      ),
    ],
  );
});
