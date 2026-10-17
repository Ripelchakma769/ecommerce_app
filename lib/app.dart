import 'package:ecommerce_app/core/constants/api_constants.dart';
import 'package:ecommerce_app/features/cart/provider/cart_provider.dart';
import 'package:ecommerce_app/features/cart/data/cart_repository.dart';
import 'package:ecommerce_app/features/order/data/order_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/payment_constans.dart';
import 'core/network/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/storage/preference_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_remote_datasource.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/provider/auth_provider.dart';
import 'features/cart/data/cart_remote_datasource.dart';
import 'features/order/provider/order_provider.dart';
import 'features/payment/data/payment_repository.dart';
import 'features/product/data/product_repository.dart';
import 'features/product/provider/product_provider.dart';

class MyApp extends StatelessWidget {
  final DioClient dioClient;
  final PreferenceService preferenceService;

  const MyApp({
    super.key,
    required this.dioClient,
    required this.preferenceService,
  });

  @override
  Widget build(BuildContext context) {
    final cachedUser = preferenceService.getUserData();
    final initialUserId = (cachedUser?['id'] as num?)?.toInt() ?? 1;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepository: AuthRepositoryImpl(
              remoteDataSource: AuthRemoteDataSourceImpl(dioClient: dioClient),
              preferenceService: preferenceService,
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(
            productRepository: ProductRepositoryImpl(dioClient: dioClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider(
            cartRepository: CartRepositoryImpl(
              preferenceService: preferenceService,
              remoteDatasource: CartRemoteDatasourceImpl(dioClient: dioClient),
            ),
            initialUserId: initialUserId,
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          update: (_, auth, order) => order!..syncUser(auth.user?.id),
          create: (_) => OrderProvider(
            orderRepository: OrderRepositoryImpl(
              dioClient: DioClient(
                preferenceService: preferenceService,
                baseUrl: ApiConstants.orderBaseUrl,
              ),
            ),
            paymentRepository: AmarPayRepositoryImpl(
              dioClient: DioClient(
                preferenceService: preferenceService,
                baseUrl: PaymentConstants.sandboxBaseUrl,
              ),
            ),
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'Flutter Demo',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}