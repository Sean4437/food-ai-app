Uri? _toExternalUri(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri == null) return null;
  final scheme = uri.scheme.toLowerCase();
  if ((scheme != 'https' && scheme != 'http') || uri.host.isEmpty) return null;
  return uri;
}

const String _kPrivacyPolicyRaw = String.fromEnvironment(
  'PRIVACY_POLICY_URL',
  defaultValue: '',
);
const String _kTermsOfServiceRaw = String.fromEnvironment(
  'TERMS_OF_SERVICE_URL',
  defaultValue: '',
);

final Uri? kPrivacyPolicyUri = _toExternalUri(_kPrivacyPolicyRaw);
final Uri? kTermsOfServiceUri = _toExternalUri(_kTermsOfServiceRaw);
