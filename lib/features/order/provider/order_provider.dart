import 'dart:math' show Random;
import 'package:ecommerce_app/features/auth/models/user_model.dart';
import 'package:ecommerce_app/features/cart/models/cart_item.dart';
import 'package:ecommerce_app/features/order/models/payment_method.dart';
import 'package:ecommerce_app/features/order/models/shipping_address_model.dart';
import 'package:flutter/foundation.dart';

import '../../payment/data/payment_repository.dart';
import '../data/order_repository.dart';
import '../models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository orderRepository;
  final PaymentRepository paymentRepository;

  bool _isSubmitting = false;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cashOnDelivery;
  bool _isGatewayLoading = false;
  List<OrderModel> _orders = [];
  OrderModel? _latestOrder;
  bool _isLoadingHistory = false;


  String? _errorMessage;
  String? _historyErrorMessage;

  int _fetchToken = 0;
  int? _syncedUserId;

  bool get isSubmitting => _isSubmitting;
  PaymentMethod get selectedPaymentMethod => _selectedPaymentMethod;
  bool get isGatewayLoading => _isGatewayLoading;
  List<OrderModel> get orders => List.unmodifiable(_orders);
  OrderModel? get latestOrder => _latestOrder;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get errorMessage => _errorMessage;
  String? get historyErrorMessage => _historyErrorMessage;

  OrderProvider({
    required this.orderRepository,
    required this.paymentRepository,
  });


  void syncUser(int? userId) {
    if (userId == _syncedUserId) return;
    _syncedUserId = userId;
    _fetchToken++;

    if (userId == null) {
      _orders = [];
      _latestOrder = null;
      _isLoadingHistory = false;
      _historyErrorMessage = null;

      Future.microtask(notifyListeners);
    } else {
      Future.microtask(() => fetchOrderHistory(userId: userId));
    }
  }

  void updateSelectedPaymentMethod(PaymentMethod method) {
    if (_selectedPaymentMethod == method) return;
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  String generateTransactionId() {
    return 'EVR-AAM-${DateTime.now().millisecondsSinceEpoch}';
  }

  ShippingAddressModel getInitialShippingAddress(UserModel? user) {
    if (user != null) {
      return ShippingAddressModel(
        fullName: user.fullName,
        addressLine: '742 Evergreen Terrace',
        city: 'Springfield',
        postalCode: '97477',
        phone: user.phone ?? '',
      );
    }
    return const ShippingAddressModel(
      fullName: 'Guest Shopper',
      addressLine: '100 Market Street',
      city: 'San Francisco',
      postalCode: '94105',
      phone: '+1 (555) 432-1098',
    );
  }

  void setGatewayLoading(bool loading) {
    if (_isGatewayLoading == loading) return;
    _isGatewayLoading = loading;
    notifyListeners();
  }

  void resetCheckoutState() {
    _selectedPaymentMethod = PaymentMethod.cashOnDelivery;
    _isGatewayLoading = false;
    _isSubmitting = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<OrderModel?> placeOrder({
    required List<CartItem> items,
    required double subtotal,
    required double tax,
    required double total,
    required ShippingAddressModel shippingAddress,
    String? paymentStatus,
    String? transactionId,
    UserModel? user,
  }) async {

    if (_isSubmitting) return null;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final orderId =
          'EVR-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(900) + 100}';

      final newOrder = OrderModel(
        id: orderId,
        userId: user?.id ?? 0,
        items: List.from(items),
        subtotal: subtotal,
        tax: tax,
        total: total,
        shippingAddress: shippingAddress,
        paymentMethod: _selectedPaymentMethod.name,
        paymentStatus: paymentStatus,
        transactionId: transactionId,
        status: 'confirmed',
        createdAt: DateTime.now(),
      );

      final placed = await orderRepository.placeOrder(newOrder);
      _latestOrder = placed;

      _orders = [placed, ..._orders];
      return placed;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<String> initiateAmarpayPayment({
    required String transactionId,
    required double amount,
    required ShippingAddressModel address,
    UserModel? user,
    String? description,
  }) async {
    _isGatewayLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final paymentUrl = await paymentRepository.initiatePayment(
        transactionId: transactionId,
        amount: amount,
        customerName: address.fullName,
        customerEmail: user?.email ?? 'user@mail.com',
        customerPhone: address.phone,
        customerAddress: address.addressLine,
        customerCity: address.city,
        description: description ?? 'Payment for order',
      );
      return paymentUrl;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isGatewayLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrderHistory({int? userId}) async {
    final id = userId ?? _syncedUserId;
    final token = ++_fetchToken;

    _isLoadingHistory = true;
    _historyErrorMessage = null;
    notifyListeners();

    try {
      final result = await orderRepository.getOrders(userId: id);

      if (token != _fetchToken) return;
      _orders = result;
    } catch (e) {
      if (token != _fetchToken) return;
      _historyErrorMessage = e.toString();
    }

    if (token == _fetchToken) {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  void clearLatestOrder() {
    if (_latestOrder == null) return;
    _latestOrder = null;
    notifyListeners();
  }

  void clearOrderState() {
    _fetchToken++;
    _isSubmitting = false;
    _selectedPaymentMethod = PaymentMethod.cashOnDelivery;
    _isGatewayLoading = false;
    _orders = [];
    _latestOrder = null;
    _isLoadingHistory = false;
    _errorMessage = null;
    _historyErrorMessage = null;
    notifyListeners();
  }
}