import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../domain/models/observation.dart';
import '../../../../domain/models/region.dart';
import '../view_models/dashboard_view_model.dart';
import '../../../core/theme/command_center_theme.dart';
import '../widgets/displacement_legend.dart';

class MapPanel extends StatelessWidget {
  const MapPanel({
    super.key,
    required this.regions,
    required this.viewModel,
  });

  final List<Region> regions;
  final DashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final center = regions.isNotEmpty
        ? LatLng(
            regions.map((r) => r.lat).reduce((a, b) => a + b) / regions.length,
            regions.map((r) => r.lng).reduce((a, b) => a + b) / regions.length,
          )
        : const LatLng(36.587, 137.468);

    final selected = viewModel.selectedRegion;
    final obs = selected != null
        ? viewModel.observationAtProgress(selected, viewModel.animatedProgress)
        : null;
    final footprintPolygons = _footprintPolygons(obs);

    final showLegend = viewModel.viewMode == ViewMode.analyst &&
        selected?.id == viewModel.displacementDemo?.regionId;
    final sliderIso = viewModel.currentSliderIso ?? '';
    final disp = showLegend
        ? viewModel.displacementAtDate(sliderIso.length >= 10 ? sliderIso.substring(0, 10) : sliderIso)
        : null;

    return Stack(
      children: [
        ClipRRect(
          key: const ValueKey('map_panel'),
          borderRadius: BorderRadius.circular(12),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 10,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tellus.demo',
              ),
              if (footprintPolygons.isNotEmpty)
                PolygonLayer(
                  polygons: footprintPolygons,
                ),
              MarkerLayer(
                markers: [
                  for (final region in regions) _buildMarker(region),
                ],
              ),
            ],
          ),
        ),
        if (showLegend)
          Positioned(
            right: 10,
            bottom: 10,
            child: DisplacementLegend(displacementMm: disp),
          ),
      ],
    );
  }

  List<Polygon> _footprintPolygons(Observation? obs) {
    final geom = obs?.geometry;
    if (geom == null || !geom.isValid) return [];

    final coords = geom.coordinates;
    if (geom.type != 'Polygon' || coords is! List || coords.isEmpty) return [];

    final ring = coords[0] as List;
    final points = <LatLng>[];
    for (final pt in ring) {
      if (pt is List && pt.length >= 2) {
        points.add(LatLng((pt[1] as num).toDouble(), (pt[0] as num).toDouble()));
      }
    }
    if (points.length < 3) return [];

    return [
      Polygon(
        points: points,
        color: CommandCenterTheme.accent.withValues(alpha: 0.15),
        borderColor: CommandCenterTheme.accent,
        borderStrokeWidth: 2,
      ),
    ];
  }

  Marker _buildMarker(Region region) {
    final colorParts = viewModel.markerColorFor(region);
    final color = HSLColor.fromAHSL(
      1,
      colorParts.hue,
      colorParts.saturation,
      colorParts.lightness,
    ).toColor();

    final obs = viewModel.observationAtProgress(region, viewModel.animatedProgress);

    return Marker(
      point: LatLng(region.lat, region.lng),
      width: 132,
      height: 56,
      child: ClipRect(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxWidth: 120),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: CommandCenterTheme.panel.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: CommandCenterTheme.border),
              ),
              child: Text(
                region.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CommandCenterTheme.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (obs != null)
              Text(
                obs.monitoringIndex.toStringAsFixed(2),
                maxLines: 1,
                style: const TextStyle(
                  color: CommandCenterTheme.accent,
                  fontSize: 9,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
