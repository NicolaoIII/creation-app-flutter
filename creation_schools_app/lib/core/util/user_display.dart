String userDisplayFromData(Map<String, dynamic>? data, String uidFallback) {
  if (data == null) return 'User ${uidFallback.substring(0, 6)}';
  final first = (data['firstName'] as String?)?.trim() ?? '';
  final last  = (data['lastName']  as String?)?.trim() ?? '';
  final email = (data['email']     as String?)?.trim() ?? '';
  final name = ('$first $last').trim();
  if (name.isNotEmpty) return name;
  if (email.isNotEmpty) return email;
  return 'User ${uidFallback.substring(0, 6)}';
}
