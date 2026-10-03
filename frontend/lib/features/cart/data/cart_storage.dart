import 'package:shared_preferences/shared_preferences.dart';

abstract class CartStorage {
  String? read();
  Future<void> write(String value);
}

/// Browser localStorage on the web (through shared_preferences).
class SharedPrefsCartStorage implements CartStorage {
  SharedPrefsCartStorage(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'lookers.cart.v1';

  @override
  String? read() => _prefs.getString(_key);

  @override
  Future<void> write(String value) async {
    await _prefs.setString(_key, value);
  }
}

class MemoryCartStorage implements CartStorage {
  String? _value;

  @override
  String? read() => _value;

  @override
  Future<void> write(String value) async => _value = value;
}
