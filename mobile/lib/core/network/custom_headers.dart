/// How many custom headers a person can add for their server.
const int maxCustomHeaders = 10;

/// Characters a header name may contain, per RFC 9110.
final RegExp _headerNamePattern = RegExp(r"^[!#$%&'*+\-.^_`|~0-9A-Za-z]+$");

/// Names the app or the transport layer sets themselves; the value
/// typed for one of these would never reach the server as intended.
const Set<String> _reservedHeaderNames = {
  'accept',
  'authorization',
  'connection',
  'content-length',
  'content-type',
  'host',
  'transfer-encoding',
  'x-anchor-protocol',
};

class CustomHeader {
  const CustomHeader({required this.name, required this.value});

  factory CustomHeader.of(String name, String value) => CustomHeader(
    name: name.trim(),
    value: value.trim(),
  );

  final String name;
  final String value;

  bool get isBlank => name.isEmpty && value.isEmpty;

  Map<String, String> toJson() => {'name': name, 'value': value};

  static CustomHeader fromJson(Map<String, dynamic> json) => CustomHeader(
    name: json['name'] as String? ?? '',
    value: json['value'] as String? ?? '',
  );

  @override
  bool operator ==(Object other) =>
      other is CustomHeader &&
      other.name.toLowerCase() == name.toLowerCase() &&
      other.value == value;

  @override
  int get hashCode => Object.hash(name.toLowerCase(), value);

  @override
  String toString() => 'CustomHeader($name: $value)';
}

/// Names are case-insensitive, like on the wire.
bool isHeaderNameValid(String name) =>
    name.isNotEmpty && _headerNamePattern.hasMatch(name);

bool isHeaderNameReserved(String name) =>
    _reservedHeaderNames.contains(name.trim().toLowerCase());

/// Whether [name] repeats an earlier one, case-insensitively.
bool isHeaderNameDuplicate(String name, Iterable<CustomHeader> earlier) =>
    earlier.any((header) => header.name.toLowerCase() == name.toLowerCase());

/// What's wrong with a header row, if anything.
enum CustomHeaderIssue { invalidName, reservedName, duplicateName }

/// Checks the header at [index] against the ones before it.
CustomHeaderIssue? customHeaderIssueOf(int index, List<CustomHeader> headers) {
  final header = headers[index];
  if (header.isBlank) return null;
  if (!isHeaderNameValid(header.name)) {
    return CustomHeaderIssue.invalidName;
  }
  if (isHeaderNameReserved(header.name)) return CustomHeaderIssue.reservedName;
  if (isHeaderNameDuplicate(header.name, headers.take(index))) {
    return CustomHeaderIssue.duplicateName;
  }
  return null;
}

/// The headers safe to send: filled-in rows that pass every rule,
/// capped at [maxCustomHeaders].
List<CustomHeader> validCustomHeadersOf(List<CustomHeader> headers) {
  final valid = <CustomHeader>[];
  for (var i = 0; i < headers.length; i++) {
    if (valid.length == maxCustomHeaders) break;
    final header = headers[i];
    if (header.isBlank || customHeaderIssueOf(i, headers) != null) continue;
    valid.add(header);
  }
  return List.unmodifiable(valid);
}
