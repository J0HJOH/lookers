/// The delivery details collected at checkout. [validate] gives fast feedback; the database
/// re-validates the same limits inside `place_order` and is the authority.
class ShippingAddress {
  const ShippingAddress({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.line1,
    this.line2 = '',
    required this.city,
    required this.region,
    required this.postalCode,
    required this.country,
    this.notes = '',
  });

  final String fullName;
  final String email;
  final String phone;
  final String line1;
  final String line2;
  final String city;
  final String region;
  final String postalCode;
  final String country;
  final String notes;

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phone = RegExp(r'^[+0-9][0-9 ().-]{6,24}$');

  /// Field name -> message. Empty when valid.
  Map<String, String> validate() {
    final errors = <String, String>{};
    void length(String field, String value, int min, int max, String label) {
      final v = value.trim();
      if (v.length < min) {
        errors[field] = '$label is required.';
      } else if (v.length > max) {
        errors[field] = '$label is too long.';
      }
    }

    length('fullName', fullName, 2, 100, 'Full name');
    length('line1', line1, 3, 200, 'Address');
    length('city', city, 2, 100, 'City');
    length('region', region, 2, 100, 'State / region');
    length('postalCode', postalCode, 2, 20, 'Postal code');
    length('country', country, 2, 100, 'Country');
    if (line2.trim().length > 200)
      errors['line2'] = 'Address line 2 is too long.';
    if (notes.trim().length > 500) errors['notes'] = 'Notes are too long.';
    if (!_email.hasMatch(email.trim()))
      errors['email'] = 'Enter a valid email address.';
    if (!_phone.hasMatch(phone.trim()))
      errors['phone'] = 'Enter a valid phone number.';
    return errors;
  }

  Map<String, dynamic> toJson() => {
    'fullName': fullName.trim(),
    'email': email.trim(),
    'phone': phone.trim(),
    'line1': line1.trim(),
    'line2': line2.trim(),
    'city': city.trim(),
    'region': region.trim(),
    'postalCode': postalCode.trim(),
    'country': country.trim(),
  };
}
