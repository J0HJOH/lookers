import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../../catalog/data/supabase_error_mapper.dart';
import '../domain/cart.dart';
import '../domain/cart_repository.dart';

/// Parses one `cart_items` row joined with its product. Null for malformed rows.
CartLine? cartLineFromRow(Map<String, dynamic> row) {
  try {
    final product = row['products'] as Map<String, dynamic>;
    final color = row['color'] as String;
    return CartLine(
      slug: product['slug'] as String,
      name: product['name'] as String,
      imageUrl: product['image_url'] as String,
      priceCents: product['price_cents'] as int,
      size: row['size'] as String,
      color: color.isEmpty ? null : color,
      quantity: row['quantity'] as int,
    );
  } on TypeError {
    return null;
  }
}

/// Maps the coded exceptions raised by the cart_* SQL functions to messages a shopper can act on.
Failure mapCartError(String message) {
  if (message.contains('AUTH_REQUIRED')) {
    return const Failure(FailureKind.auth, 'Please sign in again.');
  }
  if (message.contains('CART_FULL')) {
    return const Failure(
      FailureKind.validation,
      'Your bag is full (30 different items).',
    );
  }
  if (message.contains('PRODUCT_UNAVAILABLE')) {
    return const Failure(
      FailureKind.validation,
      'That item is no longer available.',
    );
  }
  if (message.contains('INVALID_')) {
    return const Failure(
      FailureKind.validation,
      'That choice isn\'t available for this item.',
    );
  }
  return const Failure(
    FailureKind.server,
    'We couldn\'t update your bag. Please try again.',
  );
}

class SupabaseCartRepository implements CartRepository {
  SupabaseCartRepository(this._client, this._userId) {
    _changes = StreamController<void>.broadcast(
      onListen: _subscribe,
      onCancel: _unsubscribe,
    );
  }

  final SupabaseClient _client;
  final String _userId;
  late final StreamController<void> _changes;
  RealtimeChannel? _channel;
  static const _timeout = Duration(seconds: 12);

  @override
  Stream<void> get changes => _changes.stream;

  void _subscribe() {
    // One WebSocket channel per signed-in shopper; the server only sends rows they may read (RLS),
    // and the filter keeps traffic to their own bag.
    _channel = _client
        .channel('cart:$_userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'cart_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId,
          ),
          callback: (_) => _changes.add(null),
        )
        .subscribe();
  }

  void _unsubscribe() {
    final channel = _channel;
    _channel = null;
    if (channel != null) _client.removeChannel(channel);
  }

  @override
  Future<List<CartLine>> load() async {
    try {
      final rows = await _client
          .from('cart_items')
          .select(
            'quantity, size, color, products!inner(slug, name, image_url, price_cents)',
          )
          .eq('products.active', true)
          .order('created_at', ascending: true)
          .timeout(_timeout);
      return rows.map(cartLineFromRow).whereType<CartLine>().toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> _rpc(String name, Map<String, dynamic> params) async {
    try {
      await _client.rpc(name, params: params).timeout(_timeout);
    } on PostgrestException catch (e) {
      throw mapCartError(e.message);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<void> add(CartLine line) => _rpc('cart_add', {
    'p_slug': line.slug,
    'p_size': line.size,
    'p_color': line.color ?? '',
    'p_qty': line.quantity,
  });

  @override
  Future<void> setQuantity(CartLine line, int quantity) =>
      _rpc('cart_set_qty', {
        'p_slug': line.slug,
        'p_size': line.size,
        'p_color': line.color ?? '',
        'p_qty': quantity,
      });

  @override
  Future<void> remove(CartLine line) => _rpc('cart_remove', {
    'p_slug': line.slug,
    'p_size': line.size,
    'p_color': line.color ?? '',
  });

  @override
  Future<void> clear() => _rpc('cart_clear', const {});
}
