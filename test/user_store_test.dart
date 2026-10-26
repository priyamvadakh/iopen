import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_app/data/content.dart';
import 'package:shop_app/data/user_store.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await UserStore.init();
  });

  test('remembers the last place viewed', () {
    final store = UserStore.instance;
    expect(store.lastViewed.value, isNull);
    final dubai = cityById('dubai')!;
    store.rememberView(dubai, dubai.areaById('palm'), InspectKind.hotel);
    final last = store.lastViewed.value!;
    expect(last.city.id, 'dubai');
    expect(last.area.id, 'palm');
    expect(last.kind, InspectKind.hotel);
  });

  test('onboarding is remembered once seen', () {
    final store = UserStore.instance;
    expect(store.onboardingSeen, isFalse);
    store.onboardingSeen = true;
    expect(store.onboardingSeen, isTrue);
  });

  test('requested sessions can be cancelled', () {
    final store = UserStore.instance;
    final dubai = cityById('dubai')!;
    final session = BookedSession(
      city: dubai,
      area: dubai.areas.first,
      kind: InspectKind.property,
      checks: InspectKind.property.checks.take(3).toList(),
      guide: guidesNearby.first,
    );
    store.addSession(session);
    expect(store.sessions.value, [session]);
    store.cancelSession(session);
    expect(store.sessions.value, isEmpty);
  });
}
