import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/cart_storage.dart';
import '../domain/cart.dart';
import '../domain/cart_repository.dart';

/// The shopping bag.
///
/// - **Signed out:** the bag lives on this device (localStorage / app storage).
/// - **Signed in:** the bag lives on the server and is shared by all the shopper's devices. A real-time
///   (WebSocket) subscription reloads it whenever it changes elsewhere, so adding an item on the website
///   shows up on the phone and the other way round.
///
/// Rules about lines live in `cart.dart`; this class holds state, persistence and sync.
class CartController extends ChangeNotifier {
  CartController(this._storage) : _lines = parseStoredCart(_storage.read());

  final CartStorage _storage;
  List<CartLine> _lines;
  CartRepository? _remote;
  StreamSubscription<void>? _changes;
  Timer? _debounce;
  bool _disposed = false;
  String? _syncError;

  List<CartLine> get lines => _lines;
  int get count => itemCount(_lines);
  int get subtotal => subtotalCents(_lines);
  bool get isEmpty => _lines.isEmpty;

  /// True while the bag is stored on the server (signed in).
  bool get isSynced => _remote != null;

  /// A short message when the last server update failed (the bag was restored from the server).
  String? get syncError => _syncError;

  /// Switches to the server bag of a signed-in shopper ([repository]), or back to the device bag
  /// (null, on sign-out). Whatever was in the device bag is merged into the account's bag on sign-in.
  Future<void> bindRemote(CartRepository? repository) async {
    if (identical(repository, _remote)) return;
    await _unbind();
    if (repository == null) {
      // Signed out: start with an empty device bag (the account's bag stays on the server).
      _setLocal(const []);
      return;
    }
    final pending = _lines;
    try {
      for (final line in pending) {
        await repository.add(line);
      }
      final serverLines = await repository.load();
      _remote = repository;
      _storage.write(encodeCart(const [])).catchError((Object _) {});
      _lines = serverLines;
      _changes = repository.changes.listen((_) => _scheduleReload());
      _notify();
    } catch (_) {
      // Couldn't reach the server: stay on the device bag and say so.
      _remote = null;
      _syncError =
          'We couldn\'t sync your bag. It is saved on this device for now.';
      _notify();
    }
  }

  Future<void> _unbind() async {
    _debounce?.cancel();
    await _changes?.cancel();
    _changes = null;
    _remote = null;
  }

  void _scheduleReload() {
    // A burst of events (several lines changed, or our own echo) becomes one reload.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), reload);
  }

  /// Re-reads the server bag. Called on real-time events and after a failed update.
  Future<void> reload() async {
    final repo = _remote;
    if (repo == null) return;
    try {
      final fresh = await repo.load();
      if (!identical(repo, _remote)) return; // signed out meanwhile
      if (encodeCart(fresh) != encodeCart(_lines)) {
        _lines = fresh;
        _notify();
      }
    } catch (_) {
      // Keep what is shown; the next change event or action will refresh it.
    }
  }

  void add(CartLine line) => _change(addLine(_lines, line), (r) => r.add(line));
  void setQty(CartLine line, int quantity) => _change(
    setQuantity(_lines, line.slug, line.size, line.color, quantity),
    (r) => r.setQuantity(line, quantity),
  );
  void remove(CartLine line) => _change(
    removeLine(_lines, line.slug, line.size, line.color),
    (r) => r.remove(line),
  );
  void clear() => _change(const [], (r) => r.clear());

  /// Applies [next] immediately (so the UI never waits), then tells the server. If the server refuses,
  /// the bag is reloaded from it, which undoes the optimistic change.
  void _change(
    List<CartLine> next,
    Future<void> Function(CartRepository) send,
  ) {
    _lines = next;
    _syncError = null;
    final repo = _remote;
    if (repo == null) {
      _persistLocal(next);
    } else {
      send(repo).catchError((Object error) {
        _syncError = 'We couldn\'t update your bag. Please try again.';
        return reload();
      });
    }
    _notify();
  }

  void _setLocal(List<CartLine> next) {
    _lines = next;
    _persistLocal(next);
    _notify();
  }

  void _persistLocal(List<CartLine> next) {
    // Best effort: if storage is blocked the bag still works for this session.
    _storage.write(encodeCart(next)).catchError((Object _) {});
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _changes?.cancel();
    super.dispose();
  }
}
