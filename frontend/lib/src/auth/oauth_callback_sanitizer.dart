const _authCallbackKeys = <String>{
  'code',
  'error',
  'error_code',
  'error_description',
  'sb',
  'state',
};

Map<String, String> _fragmentQueryParams(String fragment) {
  if (fragment.isEmpty || !fragment.contains('=')) {
    return const <String, String>{};
  }
  return Uri.splitQueryString(fragment);
}

Uri sanitizeOAuthCallbackUri(Uri uri) {
  final retained = <String, String>{};

  void addRetained(Map<String, String> source) {
    for (final entry in source.entries) {
      if (_authCallbackKeys.contains(entry.key)) {
        continue;
      }
      retained.putIfAbsent(entry.key, () => entry.value);
    }
  }

  addRetained(uri.queryParameters);
  addRetained(_fragmentQueryParams(uri.fragment));

  final sanitized = uri.replace(
    queryParameters: retained.isEmpty ? null : retained,
    fragment: '',
  );
  final withPath = sanitized.path.isEmpty ? sanitized.replace(path: '/') : sanitized;
  final withoutTrailingHash = withPath.toString().replaceFirst(RegExp(r'#$'), '');
  return Uri.parse(withoutTrailingHash);
}

bool shouldSanitizeOAuthCallbackUri(Uri uri) {
  if (uri.queryParameters.keys.any(_authCallbackKeys.contains)) {
    return true;
  }
  return _fragmentQueryParams(uri.fragment).keys.any(_authCallbackKeys.contains);
}
