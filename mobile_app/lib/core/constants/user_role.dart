/// Who is signed in. Matches the `role` claim in the JWT (api.md 9.5).
/// The role decides the home screen and the colour of the app.
enum UserRole {
  mother,
  phm,
  supervisor,
  admin;

  /// Supervisor and admin both work in the MOH office and share its screens.
  bool get isMohOffice => this == supervisor || this == admin;
}
