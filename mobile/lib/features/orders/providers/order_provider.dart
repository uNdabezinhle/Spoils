import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/order_repository.dart';
import '../models/order_model.dart';

final ordersProvider = FutureProvider.autoDispose<List<OrderModel>>((ref) async {
  if (!ref.watch(authProvider).isAuthenticated) return [];
  return ref.read(orderRepositoryProvider).fetchOrders();
});

final orderDetailProvider = FutureProvider.autoDispose.family<OrderModel, int>((ref, id) async {
  return ref.read(orderRepositoryProvider).fetchOrder(id);
});