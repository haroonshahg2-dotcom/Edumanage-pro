class PasswordGenerator {
  // Email generate karo - sahi format mein
  static String generateEmail(String firstName, String lastName, String domain) {
    // Space aur special characters hatao
    String cleanFirst = firstName
        .toLowerCase()
        .trim()
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^a-z]'), '');

    String cleanLast = lastName
        .toLowerCase()
        .trim()
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^a-z]'), '');

    // Agar empty ho toh default do
    if (cleanFirst.isEmpty) cleanFirst = 'user';
    if (cleanLast.isEmpty) cleanLast = 'name';

    return '$cleanFirst.$cleanLast@$domain';
  }

  // Password generate karo
  static String generate({String? firstName}) {
    final name = firstName?.toLowerCase().trim().replaceAll(' ', '') ?? 'user';
    return '${name}@2024';
  }
}