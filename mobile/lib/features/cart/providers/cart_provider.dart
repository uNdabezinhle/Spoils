import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/cart_repository.dart';
import '../models/cart_models.dart';
import '../models/customisation_options.dart';

const _emptyCart = CartModel(id: 0, items: [], itemCount: 0, subtotal: '0');

final cartProvider = StateNotifierProvider<CartNotifier, AsyncValue<CartModel>>((ref) {
  final notifier = CartNotifier(ref.read(cartRepositoryProvider), ref);
  ref.listen(authProvider, (previous, next) {
    if (next.isAuthenticated) {
      notifier.refresh();
    } else {
      notifier.reset();
    }
  });
  if (ref.read(authProvider).isAuthenticated) {
    notifier.refresh();
  } else {
    notifier.reset();
  }
  return notifier;
});

final cartItemCountProvider = Provider<int>((ref) {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return 0;
  return ref.watch(cartProvider).valueOrNull?.itemCount ?? 0;
});

class CartNotifier extends StateNotifier<AsyncValue<CartModel>> {
  CartNotifier(this._repository, this._ref) : super(const AsyncValue.data(_emptyCart));

  final CartRepository _repository;
  final Ref _ref;

  void reset() {
    state = const AsyncValue.data(_emptyCart);
  }

  Future<void> refresh() async {
    if (!_ref.read(authProvider).isAuthenticated) {
      reset();
      return;
    }
    state = const AsyncValue.loading();
    try {
      final cart = await _repository.fetchCart();
      state = AsyncValue.data(cart);
    } catch (e, st) {
      if (e is DioException && e.response?.statusCode == 401) {
        reset();
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<bool> addToCart({
    required int productId,
    int quantity = 1,
    CustomisationDetails? customisation,
  }) async {
    try {
      await _repository.addItem(
        productId: productId,
        quantity: quantity,
        customisation: customisation,
      );
      await refresh();
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return false;
      rethrow;
    }
  }

  Future<void> updateQuantity(int itemId, int quantity) async {
    if (quantity < 1) return;
    await _repository.updateItem(itemId: itemId, quantity: quantity);
    await refresh();
  }

  Future<void> removeItem(int itemId) async {
    await _repository.removeItem(itemId);
    await refresh();
  }

  Future<void> clear() async {
    await _repository.clearCart();
    await refresh();
  }
}

final wrappingOptionsProvider = FutureProvider.autoDispose((ref) {
  return ref.read(customisationRepositoryProvider).fetchWrappingOptions();
});

final messageTemplatesProvider =
    FutureProvider.autoDispose.family<List<MessageTemplateModel>, String?>((ref, occasion) {
  return ref.read(customisationRepositoryProvider).fetchMessageTemplates(occasion: occasion);
});