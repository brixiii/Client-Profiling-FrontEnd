import 'models/user.dart';

/// Session-scoped flags that live only in memory.
/// Calling [reset] on logout clears them so next login starts fresh.
class SessionFlags {
  SessionFlags._();

  /// True once the Calendar drag-guide has been shown this session.
  static bool calendarDragGuideShown = false;

  /// Role of the currently logged-in user (e.g. 'Super Admin' or 'Admin').
  static String userRole = '';

  /// The currently logged-in user's full profile data.
  /// Set after a successful profile fetch; cleared on logout.
  static User? loggedInUser;

  /// Call on every logout to restore all flags to their initial state.
  static void reset() {
    calendarDragGuideShown = false;
    userRole = '';
    loggedInUser = null;
  }
}