import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../../catalog/data/supabase_catalog_repository.dart';
import '../../catalog/data/supabase_error_mapper.dart';
import '../../catalog/domain/category.dart';
import '../../catalog/domain/product.dart';
import '../../orders/domain/order.dart';
import '../domain/admin_models.dart';
import '../domain/admin_repository.dart';
import '../domain/product_draft.dart';

class SupabaseAdminRepository implements AdminRepository {
  SupabaseAdminRepository(this._client);

  final SupabaseClient _client;
  static const _timeout = Duration(seconds: 15);

  @override
  Future<AdminStats> loadStats() async {
    try {
      final orders = await _client
          .from('orders')
          .select('status, total_cents')
          .timeout(_timeout);
      final customers = await _client
          .from('profiles')
          .select('id')
          .count(CountOption.exact)
          .timeout(_timeout);
      final low = await _client
          .from('products')
          .select(productColumns)
          .eq('active', true)
          .lte('stock', lowStockThreshold)
          .order('stock', ascending: true)
          .limit(8)
          .timeout(_timeout);
      var revenue = 0;
      var pending = 0;
      for (final o in orders) {
        if (o['status'] == 'pending') pending++;
        // Cancelled orders aren't revenue.
        if (o['status'] != 'cancelled') revenue += o['total_cents'] as int;
      }
      return AdminStats(
        orderCount: orders.length,
        pendingCount: pending,
        revenueCents: revenue,
        customerCount: customers.count,
        lowStock: low.map(productFromRow).whereType<Product>().toList(),
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<List<Product>> listProducts() async {
    try {
      // No `active` filter: RLS lets only admins see hidden products.
      final rows = await _client
          .from('products')
          .select(productColumns)
          .order('created_at', ascending: false)
          .timeout(_timeout);
      return rows.map(productFromRow).whereType<Product>().toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<Product?> getProduct(String id) async {
    try {
      final row = await _client
          .from('products')
          .select(productColumns)
          .eq('id', id)
          .maybeSingle()
          .timeout(_timeout);
      return row == null ? null : productFromRow(row);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<List<Category>> listCategories() async {
    try {
      final rows = await _client
          .from('categories')
          .select('id, slug, name, tagline, image_url')
          .order('sort_order', ascending: true)
          .timeout(_timeout);
      return [
        for (final r in rows)
          Category(
            id: r['id'] as String,
            slug: r['slug'] as String,
            name: r['name'] as String,
            tagline: (r['tagline'] as String?) ?? '',
            imageUrl: r['image_url'] as String,
          ),
      ];
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<void> saveProduct(ProductDraft draft) async {
    try {
      final id = draft.id;
      if (id == null) {
        await _client.from('products').insert(draft.toRow()).timeout(_timeout);
      } else {
        await _client
            .from('products')
            .update(draft.toRow())
            .eq('id', id)
            .timeout(_timeout);
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const Failure(
          FailureKind.validation,
          'That slug is already used. Choose a different one.',
        );
      }
      throw mapSupabaseError(e);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      // Past orders keep their line items (product_id is set to null), so deleting is safe.
      await _client.from('products').delete().eq('id', id).timeout(_timeout);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _client
          .from('orders')
          .update({'status': status.name})
          .eq('id', orderId)
          .timeout(_timeout);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
