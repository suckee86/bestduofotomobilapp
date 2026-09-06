import 'package:firebase_auth/firebase_auth.dart';

const contentAdminEmail = 'bestduo.firebase@gmail.com';

bool isContentAdmin(User user) {
  return isContentAdminIdentity(
    email: user.email,
    emailVerified: user.emailVerified,
  );
}

bool isContentAdminIdentity({
  required String? email,
  required bool emailVerified,
}) {
  return emailVerified && email?.trim().toLowerCase() == contentAdminEmail;
}
