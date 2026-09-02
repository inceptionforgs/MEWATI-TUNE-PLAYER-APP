/// Escapes a user-supplied search string for safe use inside a Postgres
/// LIKE/ILIKE pattern sent through PostgREST (e.g. via Supabase's
/// .ilike() filter).
///
/// This logic previously lived as a private _escapeLikePattern method
/// duplicated in both songs_service.dart and singers_service.dart, which
/// meant it could never be unit tested directly (Dart privacy is
/// per-file). Behavior here is UNCHANGED from the original — only its
/// location moved, so both services can share one implementation and it
/// can finally be covered by tests.
///
/// Note: single quotes (') and double quotes (") are intentionally NOT
/// escaped here. Supabase's postgrest-dart client parameterizes the
/// filter value rather than string-interpolating raw SQL, so quotes are
/// not special within a LIKE pattern the way % and _ are.
String escapeLikePattern(String input) {
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');
}
