import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Keeps what the shopper has typed into the checkout form, so a sign-in round trip
/// (the browser leaves for Google and comes back) doesn't make them re-enter it.
///
/// It holds only delivery details, on the shopper's own device, and is cleared once an order is
/// placed. Payment details are never collected or stored.
abstract class CheckoutDraftStorage {
  Map<String, String> read();
  Future<void> write(Map<String, String> fields);
  Future<void> clear();
}

class SharedPrefsCheckoutDraftStorage implements CheckoutDraftStorage {
  SharedPrefsCheckoutDraftStorage(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'lookers.checkout.draft.v1';

  @override
  Map<String, String> read() {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null) return {};
      final data = jsonDecode(raw);
      if (data is! Map) return {};
      return {
        for (final e in data.entries)
          if (e.key is String && e.value is String)
            e.key as String: e.value as String,
      };
    } on FormatException {
      return {};
    }
  }

  @override
  Future<void> write(Map<String, String> fields) async {
    await _prefs.setString(_key, jsonEncode(fields));
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}

class MemoryCheckoutDraftStorage implements CheckoutDraftStorage {
  Map<String, String> _fields = {};

  @override
  Map<String, String> read() => Map.of(_fields);

  @override
  Future<void> write(Map<String, String> fields) async =>
      _fields = Map.of(fields);

  @override
  Future<void> clear() async => _fields = {};
}
