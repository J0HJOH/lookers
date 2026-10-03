import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/ui/app_scope.dart';
import '../../../core/ui/async_view.dart';
import '../../../core/ui/layout.dart';
import '../../cart/presentation/cart_page.dart';
import '../../orders/domain/place_order.dart';
import '../domain/shipping_address.dart';
import '../domain/shipping_rules.dart';
import '../../../core/ui/neu.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final mobile = isMobile(context);
    return PageContainer(
      padding: EdgeInsets.symmetric(horizontal: mobile ? 20 : 32, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Checkout', style: AppText.display(mobile ? 44 : 56)),
          const SizedBox(height: 32),
          ListenableBuilder(
            listenable: scope.cart,
            builder: (context, _) {
              if (scope.cart.isEmpty) {
                return EmptyState(
                  title: 'Your bag is empty.',
                  actionLabel: 'Continue shopping',
                  onAction: () => context.go('/shop'),
                );
              }
              return AsyncView<ShippingRules>(
                minHeight: 160,
                load: scope.orders.getShippingRules,
                builder: (context, rules) => _CheckoutForm(rules: rules),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CheckoutForm extends StatefulWidget {
  const _CheckoutForm({required this.rules});

  final ShippingRules rules;

  @override
  State<_CheckoutForm> createState() => _CheckoutFormState();
}

enum _PaymentMethod { payOnDelivery, card }

class _CheckoutFormState extends State<_CheckoutForm> {
  static const _fieldNames = [
    'fullName',
    'email',
    'phone',
    'line1',
    'line2',
    'city',
    'region',
    'postalCode',
    'country',
    'notes',
  ];

  final _c = <String, TextEditingController>{};
  Map<String, String> _fieldErrors = {};
  String? _message;
  bool _busy = false;
  _PaymentMethod _payment = _PaymentMethod.payOnDelivery;

  TextEditingController _ctl(String name) =>
      _c.putIfAbsent(name, TextEditingController.new);

  @override
  void initState() {
    super.initState();
    final scope = AppScope.read(context);
    // Restore what was typed before a sign-in round trip, then fill gaps from the account.
    final draft = scope.drafts.read();
    for (final name in _fieldNames) {
      _ctl(name).text = draft[name] ?? '';
    }
    final user = scope.auth.user;
    if (_ctl('fullName').text.isEmpty)
      _ctl('fullName').text = user?.fullName ?? '';
    if (_ctl('email').text.isEmpty) _ctl('email').text = user?.email ?? '';
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> _values() => {
    for (final n in _fieldNames) n: _ctl(n).text,
  };

  ShippingAddress _address() {
    String v(String k) => _ctl(k).text;
    return ShippingAddress(
      fullName: v('fullName'),
      email: v('email'),
      phone: v('phone'),
      line1: v('line1'),
      line2: v('line2'),
      city: v('city'),
      region: v('region'),
      postalCode: v('postalCode'),
      country: v('country'),
      notes: v('notes'),
    );
  }

  /// Signed out: remember the form, then send the shopper to Google. They return to this page
  /// with their bag and details intact (an account is created automatically on first sign-in).
  Future<void> _signInToContinue() async {
    final scope = AppScope.of(context);
    if (scope.isPreview) {
      setState(
        () => _message =
            'Sign-in isn\'t set up yet, so orders can\'t be placed in preview mode. See docs/SETUP.md.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await scope.drafts.write(_values());
      await scope.auth.signInWithGoogle('/checkout');
    } on Failure catch (f) {
      if (mounted) {
        setState(() {
          _message = f.message;
          _busy = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final scope = AppScope.of(context);
    setState(() {
      _busy = true;
      _message = null;
      _fieldErrors = {};
    });
    try {
      final placed = await scope.placeOrder(scope.cart.lines, _address());
      await scope.drafts.clear();
      scope.cart.clear();
      if (mounted) context.go('/checkout/success?order=${placed.id}');
    } on FieldErrors catch (e) {
      setState(() {
        _fieldErrors = e.fields;
        _message = e.message;
        _busy = false;
      });
    } on Failure catch (f) {
      if (f.kind == FailureKind.auth) {
        // Session expired while filling the form: same sign-in path as a guest.
        await _signInToContinue();
        return;
      }
      setState(() {
        _message = f.message;
        _busy = false;
      });
    } catch (_) {
      setState(() {
        _message = 'We couldn\'t place your order. Please try again.';
        _busy = false;
      });
    }
  }

  Widget _field(
    String name,
    String label, {
    TextInputType? type,
    int maxLines = 1,
    List<String>? hints,
    bool optional = false,
    int? maxLength,
  }) {
    return NeuTextField(
      controller: _ctl(name),
      keyboardType: type,
      maxLines: maxLines,
      maxLength: maxLength,
      autofillHints: hints,
      label: optional ? '$label (optional)' : label,
      errorText: _fieldErrors[name],
      // Keep what was typed so a sign-in round trip (or a theme switch) never loses it.
      onChanged: (_) => AppScope.of(context).drafts.write(_values()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final wide = isDesktop(context);

    Widget pair(Widget a, Widget b) => isMobile(context)
        ? Column(children: [a, const SizedBox(height: 16), b])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: 16),
              Expanded(child: b),
            ],
          );

    final form = AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListenableBuilder(
            listenable: scope.auth,
            builder: (context, _) => scope.auth.isSignedIn
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: SizedBox(
                      width: double.infinity,
                      child: NeuBox(
                        inset: true,
                        radius: 20,
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lock_outline, color: AppColors.accent),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Fill in your details now. When you place your order you\'ll sign in or sign up with Google (one tap, no password), then come straight back here.',
                                style: AppText.body(
                                  size: 14,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          Text('Contact', style: AppText.display(26)),
          const SizedBox(height: 16),
          pair(
            _field('fullName', 'Full name', hints: const [AutofillHints.name]),
            _field(
              'email',
              'Email',
              type: TextInputType.emailAddress,
              hints: const [AutofillHints.email],
            ),
          ),
          const SizedBox(height: 16),
          _field(
            'phone',
            'Phone',
            type: TextInputType.phone,
            hints: const [AutofillHints.telephoneNumber],
          ),
          const SizedBox(height: 40),
          Text('Delivery address', style: AppText.display(26)),
          const SizedBox(height: 16),
          _field(
            'line1',
            'Address',
            hints: const [AutofillHints.streetAddressLine1],
          ),
          const SizedBox(height: 16),
          _field(
            'line2',
            'Apartment, suite',
            optional: true,
            hints: const [AutofillHints.streetAddressLine2],
          ),
          const SizedBox(height: 16),
          pair(
            _field('city', 'City', hints: const [AutofillHints.addressCity]),
            _field(
              'region',
              'State / region',
              hints: const [AutofillHints.addressState],
            ),
          ),
          const SizedBox(height: 16),
          pair(
            _field(
              'postalCode',
              'Postal code',
              hints: const [AutofillHints.postalCode],
            ),
            _field(
              'country',
              'Country',
              hints: const [AutofillHints.countryName],
            ),
          ),
          const SizedBox(height: 16),
          _field(
            'notes',
            'Delivery notes',
            optional: true,
            maxLines: 3,
            maxLength: 500,
          ),
          const SizedBox(height: 40),
          Text('Payment', style: AppText.display(26)),
          const SizedBox(height: 16),
          _PaymentSection(
            selected: _payment,
            onChanged: (m) => setState(() => _payment = m),
          ),
        ],
      ),
    );

    final summary = ListenableBuilder(
      listenable: Listenable.merge([scope.cart, scope.auth]),
      builder: (context, _) {
        final signedIn = scope.auth.isSignedIn;
        final cardSelected = _payment == _PaymentMethod.card;
        return OrderSummaryCard(
          subtotal: scope.cart.subtotal,
          rules: widget.rules,
          lines: scope.cart.lines,
          action: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _message!,
                      style: AppText.body(size: 14, color: AppColors.danger),
                    ),
                  ),
                ),
              NeuButton(
                onPressed: _busy || cardSelected
                    ? null
                    : (signedIn ? _submit : _signInToContinue),
                child: Text(
                  _busy
                      ? (signedIn ? 'PLACING ORDER…' : 'REDIRECTING…')
                      : cardSelected
                      ? 'CARD PAYMENT UNAVAILABLE'
                      : (signedIn ? 'PLACE ORDER' : 'SIGN IN TO PLACE ORDER'),
                ),
              ),
              if (!signedIn && !cardSelected)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'New here? Signing in with Google creates your account.',
                    textAlign: TextAlign.center,
                    style: AppText.body(size: 12, color: AppColors.inkMuted),
                  ),
                ),
            ],
          ),
          footnote:
              'Totals are confirmed by our server when you place the order.',
        );
      },
    );

    return wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: form),
              const SizedBox(width: 56),
              SizedBox(width: 400, child: summary),
            ],
          )
        : Column(children: [form, const SizedBox(height: 40), summary]);
  }
}

/// Payment options. **Screen only**: no payment is processed and nothing typed here is read,
/// stored or sent. The card fields are disabled placeholders until a provider is chosen.
class _PaymentSection extends StatelessWidget {
  const _PaymentSection({required this.selected, required this.onChanged});

  final _PaymentMethod selected;
  final ValueChanged<_PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget option({
      required _PaymentMethod method,
      required String title,
      required String subtitle,
      Widget? badge,
      Widget? body,
    }) {
      final isSelected = selected == method;
      return SizedBox(
        width: double.infinity,
        child: NeuSelectable(
          selected: isSelected,
          radius: 20,
          padding: const EdgeInsets.all(18),
          onTap: () => onChanged(method),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected ? AppColors.accent : AppColors.ink,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: AppText.body(
                        color: AppColors.ink,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ?badge,
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 4),
                child: Text(
                  subtitle,
                  style: AppText.body(size: 13, color: AppColors.inkMuted),
                ),
              ),
              if (isSelected && body != null)
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 16),
                  child: body,
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        option(
          method: _PaymentMethod.payOnDelivery,
          title: 'Pay on delivery',
          subtitle: 'Pay when your order arrives.',
        ),
        const SizedBox(height: 12),
        option(
          method: _PaymentMethod.card,
          title: 'Credit or debit card',
          subtitle: 'Visa, Mastercard and more.',
          badge: NeuBox(
            radius: 10,
            depth: 0.4,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              'COMING SOON',
              style: AppText.eyebrow().copyWith(
                fontSize: 10,
                letterSpacing: 1.8,
              ),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NeuTextField(
                enabled: false,
                label: 'Card number',
                hint: '1234 5678 9012 3456',
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(
                    child: NeuTextField(
                      enabled: false,
                      label: 'Expiry',
                      hint: 'MM / YY',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: NeuTextField(
                      enabled: false,
                      label: 'CVC',
                      hint: '123',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const NeuTextField(enabled: false, label: 'Name on card'),
              const SizedBox(height: 12),
              Text(
                'Card payments aren\'t available yet. Please choose Pay on delivery to place your order.',
                style: AppText.body(size: 13, color: AppColors.danger),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
