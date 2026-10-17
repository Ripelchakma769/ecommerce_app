import 'package:ecommerce_app/features/cart/models/cloud_cart_dto.dart';

import '../../../core/storage/preference_service.dart';
import '../models/cart_item.dart';
import 'cart_remote_datasource.dart';

abstract class CartRepository {
  Future<List<CartItem>> loadCart();
  Future<void> saveCart(List<CartItem> items);
  Future<void> clearCart();

  Future<CloudCartDto?> fetchRemoteCart({required int userId});
  Future<CloudCartDto> pushCartToCloud({
    required int userId,
    required List<CartItem> items,
  });
  Future<void> deleteCloudCart();

  int? getCloudCartId();
  Future<void> setCloudCartId(int? id);
  DateTime? getLastSyncTime();
  Future<void> setLastSyncTime(DateTime time);
  bool hasPendingSync();
  Future<void> setPendingSync(bool pending);
}

class CartRepositoryImpl implements CartRepository {
  final PreferenceService preferenceService;
  final CartRemoteDatasource remoteDatasource;

  CartRepositoryImpl({
    required this.preferenceService,
    required this.remoteDatasource,
  });

  @override
  Future<List<CartItem>> loadCart() async {
    final cached = preferenceService.getCartCache();
    return cached.map((e) => CartItem.fromJson(e)).toList();
  }

  @override
  Future<void> saveCart(List<CartItem> items) async {
    final maps = items.map((e) => e.toJson()).toList();
    await preferenceService.setCartCache(maps);
  }

  @override
  Future<void> clearCart() async {
    await preferenceService.setCartCache([]);
  }

  @override
  Future<CloudCartDto?> fetchRemoteCart({required int userId}) async {
    return await remoteDatasource.fetchUserCart(userId);
  }

  @override
  Future<CloudCartDto> pushCartToCloud({
    required int userId,
    required List<CartItem> items,
  }) async {
    final existingCartId = preferenceService.getCloudCartId();
    if (existingCartId != null && existingCartId > 0) {
      try {
        final result = await remoteDatasource.updateCloudCart(
          cartId: existingCartId,
          items: items,
        );
        await setCloudCartId(result.id);
        await setLastSyncTime(DateTime.now());
        await setPendingSync(false);
        return result;
      } catch (_) {
        // Fallback to create if update fails (e.g. ephemeral server reset 404)
        final result = await remoteDatasource.createCloudCart(
          userId: userId,
          items: items,
        );
        await setCloudCartId(result.id);
        await setLastSyncTime(DateTime.now());
        await setPendingSync(false);
        return result;
      }
    } else {
      final result = await remoteDatasource.createCloudCart(
        userId: userId,
        items: items,
      );
      await setCloudCartId(result.id);
      await setLastSyncTime(DateTime.now());
      await setPendingSync(false);
      return result;
    }
  }

  @override
  Future<void> deleteCloudCart() async {
    final cartId = preferenceService.getCloudCartId();
    if (cartId != null) {
      try {
        await remoteDatasource.deleteCloudCart(cartId);
      } catch (_) {
        // Silently tolerate remote delete failures
      }
      await setCloudCartId(null);
    }
  }

  @override
  int? getCloudCartId() => preferenceService.getCloudCartId();

  @override
  Future<void> setCloudCartId(int? id) => preferenceService.setCloudCartId(id);

  @override
  DateTime? getLastSyncTime() => preferenceService.getLastCartSync();

  @override
  Future<void> setLastSyncTime(DateTime time) =>
      preferenceService.setLastCartSync(time);

  @override
  bool hasPendingSync() => preferenceService.hasPendingCartSync();

  @override
  Future<void> setPendingSync(bool pending) =>
      preferenceService.setPendingCartSync(pending);
}