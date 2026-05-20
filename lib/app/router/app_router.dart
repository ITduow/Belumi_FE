import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../data/models/belumi_models.dart' as legacy_models;
import '../../data/repositories/belumi_repository.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_screen_v2.dart';
import '../../presentation/screens/about_screen.dart';
import '../../presentation/screens/admin_login_screen.dart';
import '../../presentation/screens/admin_panel_screen.dart';
import '../../presentation/screens/account_screen.dart';
import '../../presentation/screens/ingredient_lookup_screen.dart';
import '../../presentation/screens/news_screen.dart';
import '../../presentation/screens/payment_screen.dart';
import '../../presentation/screens/pricing_screen.dart';
import '../../presentation/screens/skin_analysis_screen.dart';
import '../../presentation/screens/virtual_makeup_screen.dart';
import '../../presentation/screens/wishlist_screen.dart';
import '../shell/app_shell.dart';

final legacyRepositoryProvider = Provider<BelumiRepository>((ref) {
  return BelumiRepository(ApiClient());
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final legacyRepository = ref.watch(legacyRepositoryProvider);
  final user = authState.valueOrNull;
  legacyRepository.api.token = user?.token;
  legacyRepository.currentUser = user == null
      ? null
      : legacy_models.AuthUser(
          userId: user.id,
          email: user.email,
          fullName: user.fullName,
          role: user.role,
          token: user.token,
          phone: user.phone,
        );

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final loggedIn = user != null;
      final authRoute =
          state.uri.path == '/login' || state.uri.path == '/register';
      final privateRoute = state.uri.path == '/wishlist';
      final adminRoute = state.uri.path == '/admin';

      if (!loggedIn && privateRoute) return '/login';
      if (adminRoute && user?.role.toLowerCase() != 'admin') {
        return '/admin-login';
      }
      if (loggedIn && authRoute) return '/home';
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
