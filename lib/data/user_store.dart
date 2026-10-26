import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'content.dart';

/// What the app remembers about this user, so returning visits are quicker
/// and personal. Stored locally (browser storage on the web).
class UserStore {
  UserStore._(this._prefs);

  static late final UserStore instance;

  static Future<void> init() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // Private browsing or blocked storage: run without remembering.
    }
    instance = UserStore._(prefs);
  }

  final SharedPreferences? _prefs;

  bool get onboardingSeen => _prefs?.getBool('onboarding_seen') ?? false;

  set onboardingSeen(bool value) => _prefs?.setBool('onboarding_seen', value);

  /// The last place the user looked at, for "Continue exploring".
  late final lastViewed = ValueNotifier<LastViewed?>(_readLastViewed());

  LastViewed? _readLastViewed() {
    final city = cityById(_prefs?.getString('last_city') ?? '');
    if (city == null) return null;
    return LastViewed(
      city: city,
      area: city.areaById(_prefs?.getString('last_area')),
      kind:
          InspectKind.fromName(_prefs?.getString('last_kind')) ??
          InspectKind.property,
    );
  }

  void rememberView(City city, Area area, InspectKind kind) {
    final current = lastViewed.value;
    if (current != null &&
        current.city.id == city.id &&
        current.area.id == area.id &&
        current.kind == kind) {
      return;
    }
    _prefs
      ?..setString('last_city', city.id)
      ..setString('last_area', area.id)
      ..setString('last_kind', kind.name);
    lastViewed.value = LastViewed(city: city, area: area, kind: kind);
  }

  /// Sessions requested in this visit (a prototype: not sent anywhere).
  final sessions = ValueNotifier<List<BookedSession>>(const []);

  void addSession(BookedSession session) =>
      sessions.value = [session, ...sessions.value];

  void cancelSession(BookedSession session) =>
      sessions.value = [...sessions.value]..remove(session);
}

class LastViewed {
  const LastViewed({
    required this.city,
    required this.area,
    required this.kind,
  });

  final City city;
  final Area area;
  final InspectKind kind;
}

class BookedSession {
  BookedSession({
    required this.city,
    required this.area,
    required this.kind,
    required this.checks,
    required this.guide,
  }) : requestedAt = DateTime.now();

  final City city;
  final Area area;
  final InspectKind kind;
  final List<InspectCheck> checks;
  final Guide guide;
  final DateTime requestedAt;
}
