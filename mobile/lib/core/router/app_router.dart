import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/addresses_screen.dart';
import '../../features/auth/screens/edit_profile_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/cart/providers/cart_provider.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/cart/screens/personalise_screen.dart';
import '../../features/catalog/screens/product_detail_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/orders/screens/checkout_screen.dart';
import '../../features/orders/screens/order_confirmation_screen.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/orders/screens/receipt_screen.dart';
import '../../features/content/screens/faq_screen.dart';
import '../../features/content/screens/legal_hub_screen.dart';
import '../../features/content/screens/static_page_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/screens/popia_screen.dart';
import '../../features/reminders/my_people_screen.dart';
import '../../features/reminders/screens/occasion_detail_screen.dart';
import '../../features/shop/shop_screen.dart';
import '../../features/subscriptions/screens/subscriptions_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/loyalty/screens/loyalty_screen.dart';
import '../../features/group_gifts/screens/create_group_gift_screen.dart';
import '../../features/group_gifts/screens/group_gift_contribute_screen.dart';
import '../../features/group_gifts/screens/group_gift_detail_screen.dart';
import '../../features/support/screens/support_chat_screen.dart';
import '../../features/ar_preview/screens/ar_preview_screen.dart';
import '../theme/spoil_colors.dart';
import '../theme/spoil_decorations.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

const _protectedPrefixes = [
  '/orders',
  '/checkout',
  '/people',
  '/profile/edit',
  '/profile/addresses',
  '/profile/data',
  '/cart',
  '/subscriptions',
  '/profile/loyalty',
  '/group-gifts/create',
  '/support',
];

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: authNotifier.changes,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final path = state.matchedLocation;

      if (auth.status == AuthStatus.unknown) return null;

      final needsAuth = _protectedPrefixes.any((prefix) => path.startsWith(prefix));
      if (needsAuth && !auth.isAuthenticated) {
        final redirect = Uri.encodeComponent(path);
        return '/auth/login?redirect=$redirect';
      }

      if (path.startsWith('/auth') && auth.isAuthenticated) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => LoginScreen(redirect: state.uri.queryParameters['redirect']),
      ),
      GoRoute(path: '/auth/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/auth/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/auth/reset-password',
        builder: (context, state) => ResetPasswordScreen(
          uid: state.uri.queryParameters['uid'],
          token: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: '/product/:slug',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ProductDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/personalise/:slug',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PersonaliseScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/cart',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/content/faq',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FaqScreen(),
      ),
      GoRoute(
        path: '/content/:pageType',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => StaticPageScreen(pageType: state.pathParameters['pageType']!),
      ),
      GoRoute(
        path: '/orders/confirmation/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => OrderConfirmationScreen(
          orderId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/orders/:id/receipt',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ReceiptScreen(
          orderId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/orders/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => OrderDetailScreen(
          orderId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/people/occasion/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => OccasionDetailScreen(
          occasionId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/subscriptions',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SubscriptionsScreen(),
      ),
      GoRoute(
        path: '/profile/loyalty',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoyaltyScreen(),
      ),
      GoRoute(
        path: '/support',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SupportChatScreen(),
      ),
      GoRoute(
        path: '/group-gifts/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateGroupGiftScreen(),
      ),
      GoRoute(
        path: '/group-gift/:token',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => GroupGiftDetailScreen(token: state.pathParameters['token']!),
        routes: [
          GoRoute(
            path: 'contribute',
            builder: (context, state) => GroupGiftContributeScreen(token: state.pathParameters['token']!),
          ),
        ],
      ),
      GoRoute(
        path: '/product/:slug/ar',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ArPreviewScreen(slug: state.pathParameters['slug']!),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/shop',
            builder: (context, state) => ShopScreen(
              initialCategory: state.uri.queryParameters['category'],
              initialOccasion: state.uri.queryParameters['occasion'],
            ),
          ),
          GoRoute(path: '/people', builder: (context, state) => const MyPeopleScreen()),
          GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          GoRoute(path: '/profile/edit', builder: (context, state) => const EditProfileScreen()),
          GoRoute(path: '/profile/addresses', builder: (context, state) => const AddressesScreen()),
          GoRoute(path: '/profile/legal', builder: (context, state) => const LegalHubScreen()),
          GoRoute(path: '/profile/data', builder: (context, state) => const PopiaScreen()),
        ],
      ),
    ],
  );
});

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/shop')) return 1;
    if (location.startsWith('/people')) return 2;
    if (location.startsWith('/orders')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    const routes = ['/home', '/shop', '/people', '/orders', '/profile'];
    context.go(routes[index]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      body: child,
      extendBody: true,
      floatingActionButton: cartCount > 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 72),
              child: FloatingActionButton(
                onPressed: () => context.push('/cart'),
                backgroundColor: SpoilColors.teal,
                elevation: 4,
                child: Badge(
                  label: Text('$cartCount'),
                  child: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SafeArea(
          child: DecoratedBox(
            decoration: SpoilDecorations.navBar(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(SpoilColors.radiusXl),
              child: NavigationBar(
                selectedIndex: _selectedIndex(context),
                onDestinationSelected: (i) => _onTap(context, i),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
                  NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Shop'),
                  NavigationDestination(icon: Icon(Icons.favorite_outline), selectedIcon: Icon(Icons.favorite), label: 'People'),
                  NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
                  NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}