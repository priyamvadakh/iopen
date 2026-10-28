import 'package:flutter/material.dart';

/// Sample content for the UI. Replace with Firestore data once the backend
/// is connected.

class InspectCheck {
  const InspectCheck(this.label, this.icon, this.image);

  final String label;
  final IconData icon;

  /// File name in assets/images without the extension.
  final String image;
}

enum InspectKind {
  place(
    card: 'cat_place',
    cardSubtitle: 'Check the area, shops and environment.',
    label: 'Place',
    icon: Icons.shopping_bag_outlined,
    hero: 'loc_streets',
    title: 'Visiting a Location?',
    subtitle: 'Check the area, vibe and even the weather with a local Guide.',
    checksTitle: 'What photos don’t show',
    checksSubtitle: 'Know the area before you go.',
    infoTitle: 'Explore any place, anywhere',
    infoBody: 'A local Guide walks the streets with you in live video.',
    placeSubtitle: 'See the streets and the vibe live with a local Guide.',
    checks: [
      InspectCheck('Streets & vibe', Icons.signpost_outlined, 'loc_streets'),
      InspectCheck('Crowds', Icons.groups_outlined, 'loc_crowds'),
      InspectCheck('Transport', Icons.tram_outlined, 'loc_transport'),
      InspectCheck('Food spots', Icons.restaurant_outlined, 'loc_food'),
      InspectCheck('At night', Icons.nightlight_outlined, 'loc_safety'),
      InspectCheck('Weather now', Icons.wb_sunny_outlined, 'loc_weather'),
    ],
  ),
  car(
    card: 'cat_car',
    cardSubtitle: 'See what the seller doesn’t show.',
    label: 'Car',
    icon: Icons.directions_car_outlined,
    hero: 'hero_car_live',
    title: 'Buying a Car?',
    subtitle:
        'See what the seller doesn’t show with a local Guide in live video.',
    checksTitle: 'What sellers don’t show',
    checksSubtitle: 'Check important details before you buy.',
    infoTitle: 'Inspect any car, anywhere',
    infoBody: 'A local Guide shows you the real condition in live video.',
    placeSubtitle: 'See the car up close, live, before you pay the seller.',
    checks: [
      InspectCheck(
        'Damaged Parts',
        Icons.car_crash_outlined,
        'car_damaged_live',
      ),
      InspectCheck('Engine Condition', Icons.oil_barrel_outlined, 'car_engine'),
      InspectCheck('Tire Wear', Icons.tire_repair, 'car_tires'),
      InspectCheck(
        'Interior Condition',
        Icons.airline_seat_recline_normal,
        'car_interior_live',
      ),
      InspectCheck(
        'Undercarriage',
        Icons.build_outlined,
        'car_undercarriage_live',
      ),
      InspectCheck('Mileage Check', Icons.speed, 'car_mileage_live'),
    ],
  ),
  property(
    card: 'cat_property',
    cardSubtitle: 'Check the property and surroundings.',
    label: 'Property',
    icon: Icons.apartment_outlined,
    hero: 'hero_property',
    title: 'Buying or Renting a Property?',
    subtitle: 'Walk through the home and its street with a local Guide.',
    checksTitle: 'What listings don’t show',
    checksSubtitle: 'Check the details before you sign.',
    infoTitle: 'Inspect any home, anywhere',
    infoBody: 'A local Guide shows you the real condition in live video.',
    placeSubtitle: 'Walk the home and street live with a local Guide.',
    checks: [
      InspectCheck(
        'Walls & ceilings',
        Icons.format_paint_outlined,
        'prop_walls',
      ),
      InspectCheck('Plumbing', Icons.plumbing, 'prop_plumbing'),
      InspectCheck(
        'Light & electrics',
        Icons.electrical_services,
        'prop_light',
      ),
      InspectCheck('Windows & view', Icons.window_outlined, 'prop_windows'),
      InspectCheck(
        'Neighbourhood',
        Icons.location_city_outlined,
        'prop_neighbourhood',
      ),
      InspectCheck(
        'Noise & parking',
        Icons.local_parking_outlined,
        'prop_parking',
      ),
    ],
  ),
  hotel(
    card: 'cat_hotel',
    cardSubtitle: 'See the real conditions before you book.',
    label: 'Hotel',
    icon: Icons.hotel_outlined,
    hero: 'hero_hotel',
    title: 'Booking a Hotel?',
    subtitle: 'See the room and its surroundings live before you book.',
    checksTitle: 'What hotels don’t show',
    checksSubtitle: 'Check the stay matches the photos.',
    infoTitle: 'Inspect any hotel, anywhere',
    infoBody: 'A local Guide shows you the real stay in live video.',
    placeSubtitle: 'See the room and the area live before you book.',
    checks: [
      InspectCheck('Room size', Icons.square_foot, 'hotel_room'),
      InspectCheck('Bathroom', Icons.bathtub_outlined, 'hotel_bathroom'),
      InspectCheck('Bed & linen', Icons.bed_outlined, 'hotel_bed'),
      InspectCheck('The view', Icons.landscape_outlined, 'hotel_view'),
      InspectCheck('Pool & facilities', Icons.pool, 'hotel_pool'),
      InspectCheck(
        'Surroundings',
        Icons.beach_access_outlined,
        'hotel_surroundings',
      ),
    ],
  ),
  restaurant(
    card: 'cat_restaurant',
    cardSubtitle: 'See the place, menu and atmosphere.',
    label: 'Restaurant',
    icon: Icons.restaurant,
    hero: 'cat_restaurant',
    title: 'Exploring a Restaurant?',
    subtitle: 'See the tables, the menu and the mood live before you go.',
    checksTitle: 'What reviews don’t show',
    checksSubtitle: 'Check the place before you book a table.',
    infoTitle: 'Check any restaurant, anywhere',
    infoBody: 'A local Guide shows you the real place in live video.',
    placeSubtitle: 'See the place and the menu live with a local Guide.',
    checks: [
      InspectCheck('Seating', Icons.chair_outlined, 'cat_restaurant'),
      InspectCheck('Menu & prices', Icons.menu_book_outlined, 'loc_food'),
      InspectCheck('How busy', Icons.groups_outlined, 'loc_crowds'),
      InspectCheck('The view', Icons.landscape_outlined, 'hotel_view'),
      InspectCheck('Getting there', Icons.tram_outlined, 'loc_transport'),
      InspectCheck('At night', Icons.nightlight_outlined, 'loc_safety'),
    ],
  ),
  venue(
    card: 'cat_venue',
    cardSubtitle: 'See the location and facilities live.',
    label: 'Venue',
    icon: Icons.location_on_outlined,
    hero: 'cat_venue',
    title: 'Checking a Venue?',
    subtitle: 'See the stage, the seats and the way in before the event.',
    checksTitle: 'What tickets don’t show',
    checksSubtitle: 'Check the venue before the big day.',
    infoTitle: 'Check any venue, anywhere',
    infoBody: 'A local Guide shows you the real venue in live video.',
    placeSubtitle: 'See the venue and its facilities live.',
    checks: [
      InspectCheck('Stage view', Icons.theater_comedy_outlined, 'cat_venue'),
      InspectCheck('Crowds', Icons.groups_outlined, 'loc_crowds'),
      InspectCheck('Entrances', Icons.door_front_door_outlined, 'loc_streets'),
      InspectCheck('Food & drink', Icons.restaurant_outlined, 'loc_food'),
      InspectCheck('Parking', Icons.local_parking_outlined, 'prop_parking'),
      InspectCheck('Transport', Icons.tram_outlined, 'loc_transport'),
    ],
  ),
  tourist(
    card: 'cat_tourist',
    cardSubtitle: 'See the place before you go.',
    label: 'Tourist spot',
    icon: Icons.travel_explore,
    hero: 'cat_tourist',
    title: 'Exploring a Tourist Spot?',
    subtitle: 'See the queues, the crowds and the view live before you go.',
    checksTitle: 'What brochures don’t show',
    checksSubtitle: 'Know what to expect before you travel.',
    infoTitle: 'See any landmark, anywhere',
    infoBody: 'A local Guide shows you the real place in live video.',
    placeSubtitle: 'See the landmark live with a local Guide.',
    checks: [
      InspectCheck('The view', Icons.landscape_outlined, 'cat_tourist'),
      InspectCheck('Queues', Icons.groups_outlined, 'loc_crowds'),
      InspectCheck('Weather now', Icons.wb_sunny_outlined, 'loc_weather'),
      InspectCheck('Getting there', Icons.tram_outlined, 'loc_transport'),
      InspectCheck('Food nearby', Icons.restaurant_outlined, 'loc_food'),
      InspectCheck('Streets around', Icons.signpost_outlined, 'loc_streets'),
    ],
  ),
  mall(
    card: 'cat_mall',
    cardSubtitle: 'Check stores, products and availability.',
    label: 'Mall',
    icon: Icons.local_mall_outlined,
    hero: 'cat_mall',
    title: 'Shopping in a Mall?',
    subtitle: 'Check the shops, the stock and the prices live before you go.',
    checksTitle: 'What websites don’t show',
    checksSubtitle: 'Check it’s in stock before you make the trip.',
    infoTitle: 'Shop any mall, anywhere',
    infoBody: 'A local Guide shows you the real shelves in live video.',
    placeSubtitle: 'Walk the mall live with a local Guide.',
    checks: [
      InspectCheck('Stores open', Icons.storefront_outlined, 'cat_mall'),
      InspectCheck('Products', Icons.shopping_bag_outlined, 'loc_streets'),
      InspectCheck('How busy', Icons.groups_outlined, 'loc_crowds'),
      InspectCheck('Food court', Icons.restaurant_outlined, 'loc_food'),
      InspectCheck('Parking', Icons.local_parking_outlined, 'prop_parking'),
      InspectCheck('Transport', Icons.tram_outlined, 'loc_transport'),
    ],
  );

  const InspectKind({
    required this.card,
    required this.cardSubtitle,
    required this.label,
    required this.icon,
    required this.hero,
    required this.title,
    required this.subtitle,
    required this.checksTitle,
    required this.checksSubtitle,
    required this.infoTitle,
    required this.infoBody,
    required this.placeSubtitle,
    required this.checks,
  });

  /// Photo for the category cards on Home and "See Before You Decide".
  final String card;

  /// One short line under the title on those cards.
  final String cardSubtitle;
  final String label;
  final IconData icon;
  final String hero;
  final String title;
  final String subtitle;
  final String checksTitle;
  final String checksSubtitle;
  final String infoTitle;
  final String infoBody;
  final String placeSubtitle;
  final List<InspectCheck> checks;

  String placeTitle(String area) => switch (this) {
    place => 'Walk around $area',
    car => 'Car check in $area',
    property => 'Property in $area',
    hotel => 'Hotel in $area',
    restaurant => 'Restaurant in $area',
    venue => 'Venue in $area',
    tourist => 'Sights in $area',
    mall => 'Shopping in $area',
  };

  /// Order of the "See Before You Decide" cards.
  static const decideOrder = [
    car,
    property,
    hotel,
    place,
    restaurant,
    venue,
    tourist,
    mall,
  ];

  static InspectKind? fromName(String? name) =>
      name == null ? null : InspectKind.values.asNameMap()[name];
}

class Hotspot {
  const Hotspot(this.label, this.icon, this.x, this.y);

  final String label;
  final IconData icon;

  /// Position as a fraction of the panorama's width and height.
  final double x;
  final double y;
}

/// A neighbourhood a Guide can show: its drag-to-look image, pins and an
/// optional real walk video.
class Area {
  const Area({
    required this.id,
    required this.name,
    required this.image,
    this.panoramaSpan = 110,
    this.initialX = 0.5,
    this.hotspots = const [],
    this.walkVideoId,
    this.walkVideoCredit,
    this.lat,
    this.lng,
  });

  final String id;
  final String name;

  /// File name in assets/images without the extension.
  final String image;

  /// Horizontal angle (degrees) the image covers.
  final double panoramaSpan;

  /// Where the view starts, as a fraction of the image width.
  final double initialX;
  final List<Hotspot> hotspots;
  final String? walkVideoId;
  final String? walkVideoCredit;

  /// Where the area is, for its map pin; null hides it from the map.
  final double? lat;
  final double? lng;
}

class City {
  const City({
    required this.id,
    required this.name,
    required this.country,
    required this.image,
    required this.lat,
    required this.lng,
    required this.guidesOnline,
    required this.area,
    this.panorama,
    this.panoramaSpan = 110,
    this.walkVideoId,
    this.walkVideoCredit,
    this.extraAreas = const [],
    this.mainLat,
    this.mainLng,
    this.cover,
    this.hotspots = const [
      Hotspot('Metro', Icons.train_outlined, 0.2, 0.55),
      Hotspot('Main street', Icons.directions_walk, 0.5, 0.6),
      Hotspot('Café', Icons.local_cafe_outlined, 0.78, 0.52),
    ],
  });

  final String id;
  final String name;
  final String country;
  final String image;

  /// Postcard photo for country cards and the Home city bubbles.
  final String? cover;
  final double lat;
  final double lng;
  final int guidesOnline;

  String get coverImage => cover ?? image;

  /// Neighbourhood shown in the place view title.
  final String area;
  final String? panorama;

  /// Horizontal angle (degrees) the panorama, or the city photo, covers.
  final double panoramaSpan;

  /// Embeddable YouTube video of a real walk through the area.
  final String? walkVideoId;
  final String? walkVideoCredit;

  /// Map position of the main [area], when it differs from the city centre.
  final double? mainLat;
  final double? mainLng;

  /// More neighbourhoods besides [area].
  final List<Area> extraAreas;

  List<Area> get areas => [
    Area(
      id: 'main',
      name: area,
      image: panorama ?? image,
      panoramaSpan: panoramaSpan,
      initialX: panorama == null ? 0.5 : 0.36,
      hotspots: hotspots,
      walkVideoId: walkVideoId,
      walkVideoCredit: walkVideoCredit,
      lat: mainLat,
      lng: mainLng,
    ),
    ...extraAreas,
  ];

  Area areaById(String? id) =>
      areas.firstWhere((a) => a.id == id, orElse: () => areas.first);
  final List<Hotspot> hotspots;
}

const cities = [
  City(
    id: 'dubai',
    cover: 'cover_uae',
    name: 'Dubai',
    country: 'UAE',
    image: 'dubai_marina',
    lat: 25.2,
    lng: 55.27,
    guidesOnline: 34,
    area: 'Dubai Marina',
    panorama: 'dubai_marina_360',
    panoramaSpan: 210,
    walkVideoId: 'XlNtZ3FojWM',
    walkVideoCredit: 'Marina Walk tour by Travel Algorithm on YouTube',
    mainLat: 25.078,
    mainLng: 55.134,
    // Positions match the JBR beach panorama (fractions of the image).
    hotspots: [
      Hotspot('Metro 5 min', Icons.train_outlined, 0.06, 0.42),
      Hotspot('Supermarket', Icons.shopping_basket_outlined, 0.24, 0.5),
      Hotspot('Marina Walk', Icons.directions_walk, 0.44, 0.47),
      Hotspot('Beach access', Icons.beach_access_outlined, 0.7, 0.66),
    ],
    extraAreas: [
      Area(
        id: 'downtown',
        lat: 25.1972,
        lng: 55.2744,
        name: 'Downtown Dubai',
        image: 'area_downtown',
        panoramaSpan: 100,
        hotspots: [
          Hotspot('Burj Khalifa', Icons.location_city_outlined, 0.36, 0.5),
          Hotspot('Dubai Mall 4 min', Icons.shopping_bag_outlined, 0.5, 0.62),
          Hotspot('Metro 6 min', Icons.train_outlined, 0.82, 0.62),
        ],
        walkVideoId: 'AjwcqYZ6cIw',
        walkVideoCredit: 'Downtown tour by Dubai Wanderscape on YouTube',
      ),
      Area(
        id: 'palm',
        lat: 25.1124,
        lng: 55.139,
        name: 'Palm Jumeirah',
        image: 'area_palm',
        panoramaSpan: 100,
        hotspots: [
          Hotspot('Monorail', Icons.tram_outlined, 0.42, 0.36),
          Hotspot('Beach access', Icons.beach_access_outlined, 0.28, 0.6),
          Hotspot('Frond villas', Icons.villa_outlined, 0.72, 0.45),
        ],
        walkVideoId: 'Qee1k-jDjWM',
        walkVideoCredit: 'Palm Jumeirah tour by Explore Virtually on YouTube',
      ),
      Area(
        id: 'businessbay',
        lat: 25.1838,
        lng: 55.2617,
        name: 'Business Bay',
        image: 'area_businessbay',
        panoramaSpan: 100,
        hotspots: [
          Hotspot('Metro 8 min', Icons.train_outlined, 0.12, 0.32),
          Hotspot('Canal walk', Icons.directions_walk, 0.5, 0.72),
          Hotspot('Supermarket', Icons.shopping_basket_outlined, 0.86, 0.5),
        ],
        walkVideoId: 'tudnmvTMh6c',
        walkVideoCredit: 'Business Bay tour by CitiesTouch on YouTube',
      ),
      Area(
        id: 'jumeirah',
        lat: 25.1412,
        lng: 55.1853,
        name: 'Jumeirah Beach',
        image: 'area_jumeirah',
        panoramaSpan: 100,
        hotspots: [
          Hotspot('Burj Al Arab', Icons.sailing_outlined, 0.47, 0.45),
          Hotspot('Bus stop 2 min', Icons.directions_bus_outlined, 0.1, 0.6),
          Hotspot('Beach access', Icons.beach_access_outlined, 0.62, 0.74),
        ],
        walkVideoId: '36kVF1qxiwY',
        walkVideoCredit: 'Jumeirah Beach walk by Ashraf Kathia247 on YouTube',
      ),
      Area(
        id: 'creek',
        lat: 25.2697,
        lng: 55.3046,
        name: 'Dubai Creek',
        image: 'area_creek',
        panoramaSpan: 100,
        hotspots: [
          Hotspot('Abra · AED 1', Icons.directions_boat_outlined, 0.67, 0.6),
          Hotspot('Deira', Icons.location_city_outlined, 0.3, 0.42),
          Hotspot('Gold Souk 5 min', Icons.storefront_outlined, 0.88, 0.36),
        ],
        walkVideoId: '27OhUAumxoI',
        walkVideoCredit: 'Bur Dubai abra walk by Virtual Strolls on YouTube',
      ),
      Area(
        id: 'fahidi',
        lat: 25.2637,
        lng: 55.2972,
        name: 'Al Fahidi (Old Dubai)',
        image: 'area_fahidi',
        panoramaSpan: 100,
        hotspots: [
          Hotspot('Wind tower', Icons.account_balance_outlined, 0.52, 0.28),
          Hotspot('Café', Icons.local_cafe_outlined, 0.22, 0.6),
          Hotspot('Museum 3 min', Icons.museum_outlined, 0.88, 0.55),
        ],
        walkVideoId: '65zg4ccFX14',
        walkVideoCredit: 'Al Fahidi walk by Walk With Haseeb on YouTube',
      ),
    ],
  ),
  City(
    id: 'riyadh',
    cover: 'cover_saudi',
    name: 'Riyadh',
    country: 'Saudi Arabia',
    image: 'country_saudi',
    lat: 24.71,
    lng: 46.68,
    guidesOnline: 18,
    area: 'Olaya',
  ),
  City(
    id: 'doha',
    cover: 'cover_qatar',
    name: 'Doha',
    country: 'Qatar',
    image: 'country_qatar',
    lat: 25.29,
    lng: 51.53,
    guidesOnline: 12,
    area: 'West Bay',
  ),
  City(
    id: 'tokyo',
    cover: 'cover_japan',
    name: 'Tokyo',
    country: 'Japan',
    image: 'cover_japan',
    lat: 35.68,
    lng: 139.69,
    guidesOnline: 21,
    area: 'Shibuya',
  ),
  City(
    id: 'amman',
    cover: 'cover_jordan',
    name: 'Amman',
    country: 'Jordan',
    image: 'cover_jordan',
    lat: 31.95,
    lng: 35.93,
    guidesOnline: 6,
    area: 'Jabal Amman',
  ),
  City(
    id: 'beirut',
    cover: 'cover_lebanon',
    name: 'Beirut',
    country: 'Lebanon',
    image: 'country_lebanon',
    lat: 33.89,
    lng: 35.5,
    guidesOnline: 5,
    area: 'Hamra',
  ),
  City(
    id: 'baghdad',
    cover: 'cover_iraq',
    name: 'Baghdad',
    country: 'Iraq',
    image: 'country_iraq',
    lat: 33.31,
    lng: 44.36,
    guidesOnline: 3,
    area: 'Karrada',
  ),
  City(
    id: 'bangkok',
    cover: 'cover_thailand',
    name: 'Bangkok',
    country: 'Thailand',
    image: 'country_thailand',
    lat: 13.75,
    lng: 100.5,
    guidesOnline: 14,
    area: 'Sukhumvit',
  ),
  City(
    id: 'singapore',
    cover: 'cover_singapore',
    name: 'Singapore',
    country: 'Singapore',
    image: 'country_singapore',
    lat: 1.29,
    lng: 103.85,
    guidesOnline: 13,
    area: 'Marina Bay',
  ),
  City(
    id: 'paris',
    name: 'Paris',
    country: 'France',
    image: 'cover_france',
    lat: 48.86,
    lng: 2.35,
    guidesOnline: 11,
    area: 'Le Marais',
  ),
  City(
    id: 'rome',
    name: 'Rome',
    country: 'Italy',
    image: 'cover_italy',
    lat: 41.9,
    lng: 12.5,
    guidesOnline: 7,
    area: 'Trastevere',
  ),
  City(
    id: 'london',
    name: 'London',
    country: 'United Kingdom',
    image: 'cover_uk',
    lat: 51.51,
    lng: -0.13,
    guidesOnline: 12,
    area: 'Covent Garden',
  ),
  City(
    id: 'newyork',
    name: 'New York',
    country: 'USA',
    image: 'cover_usa',
    lat: 40.71,
    lng: -74.01,
    guidesOnline: 15,
    area: 'Midtown',
  ),
  City(
    id: 'toronto',
    name: 'Toronto',
    country: 'Canada',
    image: 'cover_canada',
    lat: 43.65,
    lng: -79.38,
    guidesOnline: 6,
    area: 'Downtown',
  ),
  City(
    id: 'rio',
    name: 'Rio de Janeiro',
    country: 'Brazil',
    image: 'cover_brazil',
    lat: -22.91,
    lng: -43.17,
    guidesOnline: 5,
    area: 'Copacabana',
  ),
  City(
    id: 'istanbul',
    name: 'Istanbul',
    country: 'Türkiye',
    image: 'bubble_istanbul',
    lat: 41.01,
    lng: 28.98,
    guidesOnline: 9,
    area: 'Sultanahmet',
  ),
];

City? cityById(String id) {
  for (final c in cities) {
    if (c.id == id) return c;
  }
  return null;
}

int get totalGuidesOnline => cities.fold(0, (n, c) => n + c.guidesOnline);

const popularCityIds = ['dubai', 'riyadh', 'doha', 'tokyo'];

class Region {
  const Region(this.name, this.subtitle, this.cityIds);

  final String name;
  final String subtitle;
  final List<String> cityIds;
}

const regions = [
  Region('Middle East', 'Culture, history and remarkable places.', [
    'amman',
    'beirut',
    'baghdad',
  ]),
  Region('Gulf', 'Modern cities and coastal experiences.', [
    'dubai',
    'riyadh',
    'doha',
  ]),
  Region('Asia', 'Vibrant destinations and unforgettable moments.', [
    'tokyo',
    'bangkok',
    'singapore',
  ]),
  Region('Europe', 'History, art and breathtaking landscapes.', [
    'paris',
    'rome',
    'london',
  ]),
  Region('Americas', 'Iconic cities and diverse cultures.', [
    'newyork',
    'toronto',
    'rio',
  ]),
];

/// The city bubbles along the Home globe, left to right.
const homeBubbleCityIds = [
  'newyork',
  'london',
  'paris',
  'dubai',
  'istanbul',
  'tokyo',
];

class Guide {
  const Guide({
    required this.name,
    required this.rating,
    required this.reviews,
    required this.languages,
    required this.distanceKm,
    required this.color,
    required this.joinMinutes,
  });

  final String name;
  final double rating;
  final int reviews;
  final List<String> languages;
  final double distanceKm;

  /// How quickly this Guide usually goes live after a request.
  final int joinMinutes;

  /// Avatar background colour.
  final Color color;

  String get initials =>
      name.split(' ').map((p) => p[0]).take(2).join().toUpperCase();
}

const guidesNearby = [
  Guide(
    name: 'Omar Haddad',
    rating: 4.9,
    reviews: 212,
    languages: ['English', 'Arabic'],
    distanceKm: 2,
    color: Color(0xFFCFE6E7),
    joinMinutes: 4,
  ),
  Guide(
    name: 'Aisha Rahman',
    rating: 4.8,
    reviews: 167,
    languages: ['English', 'Arabic', 'Hindi'],
    distanceKm: 3.4,
    color: Color(0xFFF3E3CF),
    joinMinutes: 6,
  ),
  Guide(
    name: 'Rahul Mehta',
    rating: 4.8,
    reviews: 98,
    languages: ['English', 'Hindi'],
    distanceKm: 1.2,
    color: Color(0xFFDCE3F5),
    joinMinutes: 3,
  ),
];

class RecentSession {
  const RecentSession({
    required this.place,
    required this.kind,
    required this.minutes,
    required this.image,
    required this.guide,
  });

  final String place;
  final InspectKind kind;
  final int minutes;
  final String image;
  final Guide guide;
}

final recentSessions = [
  RecentSession(
    place: 'Apartment, Dubai Marina',
    kind: InspectKind.property,
    minutes: 18,
    image: 'dubai_marina',
    guide: guidesNearby[0],
  ),
  RecentSession(
    place: 'Used BMW, Riyadh',
    kind: InspectKind.car,
    minutes: 22,
    image: 'car_damaged',
    guide: guidesNearby[2],
  ),
  RecentSession(
    place: 'Hotel room, Bangkok',
    kind: InspectKind.hotel,
    minutes: 15,
    image: 'hotel_room',
    guide: guidesNearby[1],
  ),
  RecentSession(
    place: 'Night market, Singapore',
    kind: InspectKind.place,
    minutes: 26,
    image: 'loc_crowds',
    guide: guidesNearby[0],
  ),
];

/// Pricing shown before the payment step, in AED.
abstract final class Pricing {
  static const base = 49;
  static const baseMinutes = 20;
  static const extra = 20;
  static const extraMinutes = 10;
}

/// A photo pin on a country map; opens [areaId] in [cityId] when set.
class Landmark {
  const Landmark(this.name, this.image, this.lat, this.lng, {this.areaId});

  final String name;
  final String image;
  final double lat;
  final double lng;
  final String? areaId;
}

class MapLabel {
  const MapLabel(this.name, this.lat, this.lng);

  final String name;
  final double lat;
  final double lng;
}

class Trending {
  const Trending(this.name, this.searches, {this.areaId, this.rising = true});

  final String name;
  final String searches;
  final String? areaId;
  final bool rising;
}

/// The country view behind a city: its map, landmarks and what's trending.
class CountryMap {
  const CountryMap({
    required this.lat,
    required this.lng,
    required this.zoom,
    this.landmarks = const [],
    this.labels = const [],
    this.trending = const [],
  });

  final double lat;
  final double lng;
  final double zoom;
  final List<Landmark> landmarks;
  final List<MapLabel> labels;
  final List<Trending> trending;
}

const countryMaps = {
  'dubai': CountryMap(
    lat: 24.76,
    lng: 54.87,
    zoom: 8.9,
    landmarks: [
      Landmark(
        'Atlantis, The Palm',
        'pin_atlantis',
        25.1305,
        55.1171,
        areaId: 'palm',
      ),
      Landmark(
        'Burj Khalifa',
        'pin_burj',
        25.1972,
        55.2744,
        areaId: 'downtown',
      ),
      Landmark('Sheikh Zayed Grand Mosque', 'pin_mosque', 24.4128, 54.475),
    ],
    labels: [
      MapLabel('Ajman', 25.405, 55.513),
      MapLabel('Sharjah', 25.346, 55.42),
      MapLabel('Dubai', 25.17, 55.3),
      MapLabel('Abu Dhabi', 24.36, 54.43),
      MapLabel('Al Ain', 24.2075, 55.7447),
    ],
    trending: [
      Trending('Burj Khalifa', '12K searches', areaId: 'downtown'),
      Trending('Dubai Marina', '9.8K searches', areaId: 'main'),
      Trending('Palm Jumeirah', '8.2K searches', areaId: 'palm', rising: false),
    ],
  ),
};
