import 'package:ecommerce_app/features/payment/presentation/payment_page.dart';
import 'package:ecommerce_app/features/product/presentation/pages/product_list.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/signin_page.dart';
import '../../features/cart/presentation/pages/cart_screen.dart';
import '../../features/order/presentation/checkout_page.dart';
import '../../features/order/presentation/order_page.dart';
import '../../features/order/presentation/order_success_page.dart';
import '../../features/product/presentation/pages/product_details.dart';

class AppRouter {
  AppRouter._();

  static const String homePath = '/';
  static const String _productDetailPath = '/product/:id';
  static const String cartPath = '/cart';
  static const String signinPath = '/signin';
  static const String profilePath = '/profile';
  static const String checkoutPath = '/checkout';
  static const String _orderSuccessPath = '/orderSuccess/:orderId';
  static const String ordersPath = '/orders';
  static const String paymentPath = '/payment';

  static String productDetailRoute(int id) => '/product/$id';
  static String orderSuccessRoute(String orderId) => '/orderSuccess/$orderId';

  static final GoRouter router = GoRouter(
    initialLocation: homePath,
    routes: [
      GoRoute(
        path: homePath,
        name: 'home',
        builder: (context, state) => ProductListScreen(),
      ),
      GoRoute(
        path: _productDetailPath,
        name: 'productDetail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ProductDetailScreen(productId: int.tryParse(id) ?? 0);
        },
      ),
      GoRoute(
        path: cartPath,
        name: 'cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: signinPath,
        name: 'signin',
        builder: (context, state) {
          final redirect = state.uri.queryParameters['redirect'];
          return SignInPage(redirect: redirect);
        },
      ),
      GoRoute(
        path: profilePath,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: checkoutPath,
        name: 'checkout',
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        path: _orderSuccessPath,
        name: 'orderSuccess',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return OrderSuccessPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: ordersPath,
        name: 'orders',
        builder: (context, state) => const OrdersPage(),
      ),
      GoRoute(
        path: paymentPath,
        name: 'payment',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final paymentUrl = extra['paymentUrl'] as String? ?? '';
          final transactionId = extra['transactionId'] as String? ?? '';
          return PaymentPage(
            paymentUrl: paymentUrl,
            transactionId: transactionId,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                '404 - Page Not Found',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'The route "${state.uri.path}" could not be found.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.home),
                label: const Text('Back to Catalog'),
                onPressed: () => context.go(homePath),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}