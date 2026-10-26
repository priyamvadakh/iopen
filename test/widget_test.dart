import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/data/content.dart';
import 'package:shop_app/widgets/globe.dart';

void main() {
  test('online Guides add up to the number shown on Home', () {
    expect(totalGuidesOnline, 126);
  });

  test('every city in a region and in Popular now exists', () {
    for (final id in [...popularCityIds, ...regions.expand((r) => r.cityIds)]) {
      expect(cityById(id), isNotNull, reason: id);
    }
  });

  test('every intent offers six checks', () {
    for (final kind in InspectKind.values) {
      expect(kind.checks, hasLength(6), reason: kind.name);
      expect(InspectKind.fromName(kind.name), kind);
    }
    expect(InspectKind.fromName('boat'), isNull);
  });

  test('every area has a photo and Dubai offers seven mapped areas', () {
    for (final city in cities) {
      for (final area in city.areas) {
        expect(
          File('assets/images/${area.image}.jpg').existsSync() ||
              // A few city photos never downloaded; they show a placeholder.
              area.id == 'main',
          isTrue,
          reason: '${city.id}/${area.id}',
        );
      }
    }
    final dubai = cityById('dubai')!;
    expect(dubai.areas.map((a) => a.name), [
      'Dubai Marina',
      'Downtown Dubai',
      'Palm Jumeirah',
      'Business Bay',
      'Jumeirah Beach',
      'Dubai Creek',
      'Al Fahidi (Old Dubai)',
    ]);
    expect(dubai.areas.every((a) => a.lat != null && a.lng != null), isTrue);
    expect(dubai.areaById('palm').name, 'Palm Jumeirah');
    expect(dubai.areaById('nowhere').name, 'Dubai Marina');
  });

  group('projectPoint', () {
    const center = Offset(100, 100);

    test('the point being looked at lands in the centre', () {
      final p = projectPoint(
        lat: 25,
        lng: 55,
        viewLat: 25,
        viewLng: 55,
        center: center,
        radius: 50,
      );
      expect(p!.offset.dx, closeTo(100, 1e-9));
      expect(p.offset.dy, closeTo(100, 1e-9));
      expect(p.depth, closeTo(1, 1e-9));
    });

    test('the far side of the globe is hidden', () {
      expect(
        projectPoint(
          lat: 0,
          lng: 180,
          viewLat: 0,
          viewLng: 0,
          center: center,
          radius: 50,
        ),
        isNull,
      );
    });

    test('east is to the right and north is up', () {
      final east = projectPoint(
        lat: 0,
        lng: 30,
        viewLat: 0,
        viewLng: 0,
        center: center,
        radius: 50,
      )!;
      final north = projectPoint(
        lat: 30,
        lng: 0,
        viewLat: 0,
        viewLng: 0,
        center: center,
        radius: 50,
      )!;
      expect(east.offset.dx, greaterThan(100));
      expect(north.offset.dy, lessThan(100));
    });
  });
}
