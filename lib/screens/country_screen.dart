import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../app/theme.dart';
import '../data/content.dart';
import '../widgets/common.dart';
import 'map_screen.dart';

/// One country on a map: landmark photo pins, city names and what people
/// are exploring there right now.
class CountryScreen extends StatefulWidget {
  const CountryScreen({super.key, required this.city, this.kind});

  final City city;

  /// Carried through to the place view when arriving from a request.
  final InspectKind? kind;

  @override
  State<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen> {
  final _map = MapController();

  City get _city => widget.city;

  /// Countries without hand-made data get one pin on their city and its
  /// neighbourhoods as the trending list.
  late final CountryMap _data =
      countryMaps[_city.id] ??
      CountryMap(
        lat: _city.lat,
        lng: _city.lng,
        zoom: 10,
        landmarks: [
          Landmark(_city.area, _city.coverImage, _city.lat, _city.lng),
        ],
        labels: [MapLabel(_city.name, _city.lat - 0.035, _city.lng)],
        trending: [
          for (final (i, a) in _city.areas.take(3).indexed)
            Trending(
              a.name,
              '${(_city.guidesOnline * (3 - i) * 0.12).toStringAsFixed(1)}K '
              'searches',
              areaId: a.id,
              rising: i < 2,
            ),
        ],
      );

  void _open(String? areaId) {
    if (areaId == null) {
      showComingSoon(context, 'Guides here');
      return;
    }
    final intent = widget.kind == null ? '' : '&intent=${widget.kind!.name}';
    context.push('/city/${_city.id}?area=$areaId$intent');
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final country = _city.country;
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: LatLng(_data.lat, _data.lng),
              initialZoom: _data.zoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              AppColors.dark
                  ? brandTileLayer()
                  : TileLayer(
                      // English labels, beige land and yellow roads, like
                      // the design.
                      urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                      userAgentPackageName: 'com.example.iopen',
                      maxNativeZoom: 19,
                      // Pushes the pale blue sea towards bright aqua.
                      tileBuilder: (context, tile, _) => ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          0.92, 0, 0, 0, 0, //
                          0, 1.0, 0, 0, 6, //
                          0, 0, 1.0, 0, 4, //
                          0, 0, 0, 1, 0,
                        ]),
                        child: tile,
                      ),
                    ),
              MarkerLayer(
                markers: [
                  // The light basemap already names its cities.
                  if (AppColors.dark)
                    for (final l in _data.labels)
                      Marker(
                        point: LatLng(l.lat, l.lng),
                        width: 120,
                        height: 24,
                        alignment: const Alignment(0.75, 0),
                        child: _Label(l.name),
                      ),
                  for (final l in _data.landmarks)
                    Marker(
                      point: LatLng(l.lat, l.lng),
                      width: 72,
                      height: 86,
                      alignment: Alignment.topCenter,
                      child: _PhotoPin(
                        landmark: l,
                        onTap: () => _open(l.areaId),
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Aqua haze behind the header.
          IgnorePointer(
            child: Container(
              height: top + 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (AppColors.dark
                            ? AppColors.background
                            : const Color(0xFFBEEBF3))
                        .withValues(alpha: 0.9),
                    (AppColors.dark
                            ? AppColors.background
                            : const Color(0xFFBEEBF3))
                        .withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: top + 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppBackButton(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            country,
                            style: AppText.title.copyWith(fontSize: 24),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Explore the real $country with\nlocal Guides.',
                            style: AppText.small.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    GlassIconButton(
                      icon: Icons.my_location,
                      label: 'Centre the map',
                      iconColor: AppColors.teal,
                      onPressed: () =>
                          _map.move(LatLng(_data.lat, _data.lng), _data.zoom),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GlassSearchField(
                  hint: 'Search in $country',
                  onTap: () => context.push('/explore'),
                ),
              ],
            ),
          ),
          // Map data credit (required by Esri and OpenStreetMap).
          Positioned(
            right: 8,
            bottom: bottom + 270,
            child: IgnorePointer(
              child: Text(
                AppColors.dark
                    ? '© OpenStreetMap contributors'
                    : 'Tiles © Esri, HERE, Garmin, © OpenStreetMap',
                style: AppText.small.copyWith(fontSize: 9),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _TrendingSheet(
              country: country,
              items: _data.trending,
              bottomInset: bottom,
              onTap: (t) => _open(t.areaId),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: AppColors.muted,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F1B3D),
              shadows: const [Shadow(color: Colors.white, blurRadius: 6)],
            ),
          ),
        ),
      ],
    );
  }
}

/// Round landmark photo in a glass ring, on a short stem with a teal dot.
class _PhotoPin extends StatelessWidget {
  const _PhotoPin({required this.landmark, required this.onTap});

  final Landmark landmark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: landmark.name,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.9),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F1B3D).withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(child: Photo(landmark.image)),
            ),
            Container(width: 2, height: 8, color: Colors.white),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.teal,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingSheet extends StatelessWidget {
  const _TrendingSheet({
    required this.country,
    required this.items,
    required this.bottomInset,
    required this.onTap,
  });

  final String country;
  final List<Trending> items;
  final double bottomInset;
  final ValueChanged<Trending> onTap;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 30,
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 10, 18, bottomInset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Trending in $country',
              style: AppText.title.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 2),
            Text(
              'Popular places people are exploring live now.',
              style: AppText.small.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 6),
            for (final (i, t) in items.indexed) ...[
              if (i > 0) Divider(height: 1, color: AppColors.border),
              InkWell(
                onTap: () => onTap(t),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${i + 1}',
                          style: AppText.label.copyWith(
                            fontSize: 17,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.trending_up_rounded,
                        size: 22,
                        color: t.rising ? AppColors.online : AppColors.muted,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.name,
                              style: AppText.label.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(t.searches, style: AppText.small),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.tealDark,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
