const String _kOfficialSiteBase = 'https://sean4437.github.io/food-ai-site';

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
const String _kSupportCenterRaw = String.fromEnvironment(
  'SUPPORT_URL',
  defaultValue: '',
);

bool _isZhLanguageCode(String languageCode) =>
    languageCode.toLowerCase().startsWith('zh');

Uri _officialUri(String path) => Uri.parse('$_kOfficialSiteBase/$path');

Uri _localizedOfficialUri(
  String languageCode, {
  required String zhPath,
  required String enPath,
}) {
  return _officialUri(_isZhLanguageCode(languageCode) ? zhPath : enPath);
}

Uri privacyPolicyUriForLanguageCode(String languageCode) {
  return _toExternalUri(_kPrivacyPolicyRaw) ??
      _localizedOfficialUri(
        languageCode,
        zhPath: 'privacy.html',
        enPath: 'en/privacy.html',
      );
}

Uri termsOfServiceUriForLanguageCode(String languageCode) {
  return _toExternalUri(_kTermsOfServiceRaw) ??
      _localizedOfficialUri(
        languageCode,
        zhPath: 'terms.html',
        enPath: 'en/terms.html',
      );
}

Uri supportCenterUriForLanguageCode(String languageCode) {
  return _toExternalUri(_kSupportCenterRaw) ??
      _localizedOfficialUri(
        languageCode,
        zhPath: 'support.html',
        enPath: 'en/support.html',
      );
}

final Uri kPrivacyPolicyUri = privacyPolicyUriForLanguageCode('zh-TW');
final Uri kTermsOfServiceUri = termsOfServiceUriForLanguageCode('zh-TW');
