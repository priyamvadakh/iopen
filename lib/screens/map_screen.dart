import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../app/theme.dart';
import '../data/content.dart';
import '../widgets/common.dart';

/// Desaturates the map and pulls it towards teal.
// Dark theme: the same streets, inverted to deep teal.
const _brandTintDark = ColorFilter.matrix([
  -0.075, -0.1375, -0.0375, 0, 79, //
  -0.075, -0.1375, -0.0375, 0, 100, //
  -0.075, -0.1375, -0.0375, 0, 105, //
  0, 0, 0, 1, 0,
]);

const _brandTint = ColorFilter.matrix([
  0.28, 0.5, 0.12, 0, 22, //
  0.3, 0.55, 0.12, 0, 42, //
  0.3, 0.55, 0.12, 0, 46, //
  0, 0, 0, 1, 0,
]);

/// OpenStreetMap tiles tinted to the app's aqua palette.
TileLayer brandTileLayer() => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.example.iopen',
  maxNativeZoom: 19,
  tileBuilder: (context, tile, _) => ColorFiltered(
    colorFilter: AppColors.dark ? _brandTintDark : _brandTint,
    child: tile,
  ),
);

/// Street map of where Guides are, with search on top.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.focusCityId});

  /// Opens zoomed into this city, e.g. `/map?city=dubai`.
  final String? focusCityId;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  static const _start = LatLng(24, 60);
  static const _startZoom = 3.0;

  final _map = MapController();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  late final _fly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  City? _selected;

  /// Close enough to show each neighbourhood instead of one city pin.
  static const _areaZoom = 9.5;
  bool _showAreas = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _searchFocus.addListener(() => setState(() {}));
    final focus = cityById(widget.focusCityId ?? '');
    if (focus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _select(focus);
      });
    }
  }

  @override
  void dispose() {
    _fly.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Smoothly pans and zooms the map to [to].
  void _flyTo(LatLng to, double zoom) {
    final camera = _map.camera;
    final lat = Tween(begin: camera.center.latitude, end: to.latitude);
    final lng = Tween(begin: camera.center.longitude, end: to.longitude);
    final z = Tween(begin: camera.zoom, end: zoom);
    final curve = CurvedAnimation(parent: _fly, curve: Curves.easeInOutCubic);
    void step() => _map.move(
      LatLng(lat.evaluate(curve), lng.evaluate(curve)),
      z.evaluate(curve),
    );
    _fly
      ..stop()
      ..reset();
    curve.addListener(step);
    _fly.forward().whenComplete(() => curve.removeListener(step));
  }

  void _select(City city) {
    _search.clear();
    _searchFocus.unfocus();
    setState(() => _selected = city);
    if (_hasMappedAreas(city)) {
      // Frame every area, nudged up so the city card doesn't cover them.
      final areas = city.areas;
      final lat =
          areas.map((a) => a.lat!).reduce((x, y) => x + y) / areas.length;
      final lng =
          areas.map((a) => a.lng!).reduce((x, y) => x + y) / areas.length;
      _flyTo(LatLng(lat - 0.07, lng), 10.3);
    } else {
      _flyTo(LatLng(city.lat, city.lng), 10.5);
    }
  }

  void _zoomBy(double delta) {
    final camera = _map.camera;
    _flyTo(camera.center, (camera.zoom + delta).clamp(2.0, 17.0));
  }

  static bool _hasMappedAreas(City c) =>
      c.areas.length > 1 && c.areas.every((a) => a.lat != null);

  List<({City city, Area? area})> _results() {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return [
      for (final c in cities) ...[
        if ('${c.name} ${c.country}'.toLowerCase().contains(q))
          (city: c, area: null),
        for (final a in c.areas)
          if (a.name.toLowerCase().contains(q) &&
              !'${c.name} ${c.country}'.toLowerCase().contains(q))
            (city: c, area: a),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final results = _results();
    final searching = _searchFocus.hasFocus || _search.text.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _start,
              initialZoom: _startZoom,
              minZoom: 2,
              maxZoom: 17,
              onPositionChanged: (camera, _) {
                final show = camera.zoom >= _areaZoom;
                if (show != _showAreas) setState(() => _showAreas = show);
              },
              onTap: (_, _) {
                _searchFocus.unfocus();
                setState(() => _selected = null);
              },
            ),
            children: [
              brandTileLayer(),
              MarkerLayer(
                markers: [
                  for (final c in cities)
                    if (_showAreas && _hasMappedAreas(c))
                      for (final a in c.areas)
                        Marker(
                          point: LatLng(a.lat!, a.lng!),
                          width: 190,
                          height: 56,
                          child: _AreaPin(
                            area: a,
                            onTap: () =>
                                context.push('/city/${c.id}?area=${a.id}'),
                          ),
                        )
                    else
                      Marker(
                        point: LatLng(c.lat, c.lng),
                        width: 72,
                        height: 72,
                        child: _CityPin(
                          city: c,
                          selected: c == _selected,
                          onTap: () => _select(c),
                        ),
                      ),
                ],
              ),
            ],
          ),

          // Search on top, with quick city chips or live results below.
          Positioned(
            top: padding.top + 10,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SearchBar(controller: _search, focus: _searchFocus),
                const SizedBox(height: 10),
                if (searching && _search.text.isNotEmpty)
                  _Results(
                    results: results,
                    onCity: _select,
                    onArea: (c, a) {
                      _search.clear();
                      _searchFocus.unfocus();
                      setState(() => _selected = c);
                      _flyTo(
                        LatLng(a.lat ?? c.lat, a.lng ?? c.lng),
                        a.lat == null ? 10.5 : 13,
                      );
                    },
                  )
                else if (!searching)
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: cities.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, i) => ChoicePill(
                        label: '${cities[i].name} · ${cities[i].guidesOnline}',
                        icon: Icons.place_outlined,
                        selected: cities[i] == _selected,
                        onTap: () => _select(cities[i]),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: ZoomControls(
                onZoomIn: () => _zoomBy(1),
                onZoomOut: () => _zoomBy(-1),
              ),
            ),
          ),

          if (_selected != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: padding.bottom + 12,
              child: _CityCard(
                city: _selected!,
                onClose: () => setState(() => _selected = null),
              ),
            ),

          // Map data credit (required by OpenStreetMap).
          Positioned(
            left: 12,
            bottom: padding.bottom + (_selected == null ? 4 : 196),
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '© OpenStreetMap contributors',
                  style: AppText.small.copyWith(fontSize: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.focus});

  final TextEditingController controller;
  final FocusNode focus;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.95),
      shape: StadiumBorder(side: BorderSide(color: AppColors.border)),
      child: TextField(
        controller: controller,
        focusNode: focus,
        textInputAction: TextInputAction.search,
        style: AppText.label.copyWith(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Search a city or area',
          hintStyle: AppText.body,
          prefixIcon: Icon(Icons.search, color: AppColors.muted),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: Icon(Icons.close, color: AppColors.muted),
                  onPressed: controller.clear,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.results,
    required this.onCity,
    required this.onArea,
  });

  final List<({City city, Area? area})> results;
  final ValueChanged<City> onCity;
  final void Function(City city, Area area) onArea;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: results.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No Guides there yet.', style: AppText.body),
            )
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final r in results)
                    ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Photo(
                            r.area?.image ?? r.city.image,
                            icon: Icons.location_city_outlined,
                          ),
                        ),
                      ),
                      title: Text(
                        r.area == null
                            ? '${r.city.name}, ${r.city.country}'
                            : '${r.area!.name}, ${r.city.name}',
                        style: AppText.label,
                      ),
                      subtitle: Text(
                        r.area == null
                            ? '${r.city.guidesOnline} Guides online'
                            : 'Area · 360° view',
                        style: AppText.small,
                      ),
                      onTap: () => r.area == null
                          ? onCity(r.city)
                          : onArea(r.city, r.area!),
                    ),
                ],
              ),
            ),
    );
  }
}

/// Labelled pin for one neighbourhood; opens its live view.
class _AreaPin extends StatelessWidget {
  const _AreaPin({required this.area, required this.onTap});

  final Area area;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The whole marker box is the touch target, not just the pill.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Semantics(
          button: true,
          label: 'Open ${area.name}',
          child: Container(
            padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.teal, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF5BAEB4), AppColors.teal],
                    ),
                  ),
                  child: const Icon(
                    Icons.threesixty,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    area.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Glossy teal pin showing how many Guides are online.
class _CityPin extends StatelessWidget {
  const _CityPin({
    required this.city,
    required this.selected,
    required this.onTap,
  });

  final City city;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = selected ? 54.0 : 44.0;
    return Semantics(
      button: true,
      label: '${city.name}, ${city.guidesOnline} Guides online',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF5BAEB4), AppColors.teal, AppColors.tealDark],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${city.guidesOnline}',
              style: AppText.label.copyWith(
                color: Colors.white,
                fontSize: selected ? 15 : 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CityCard extends StatelessWidget {
  const _CityCard({required this.city, required this.onClose});

  final City city;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final areas = city.areas;
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Photo(
                      city.image,
                      icon: Icons.location_city_outlined,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${city.name}, ${city.country}',
                        style: AppText.section,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.online,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${city.guidesOnline} Guides online',
                            style: AppText.small,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: onClose,
                  icon: Icon(Icons.close, color: AppColors.muted),
                ),
              ],
            ),
            if (areas.length > 1) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: areas.length,
                  separatorBuilder: (context, _) => const SizedBox(width: 6),
                  itemBuilder: (context, i) => ActionChip(
                    label: Text(areas[i].name, style: AppText.small),
                    backgroundColor: AppColors.tealTint,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    onPressed: () =>
                        context.push('/city/${city.id}?area=${areas[i].id}'),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            GlossyButton(
              onPressed: () => context.push('/city/${city.id}'),
              child: Text('Explore ${city.name}'),
            ),
          ],
        ),
      ),
    );
  }
}
