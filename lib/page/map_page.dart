import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const double _mapWidth = 4500.0;
  static const double _mapHeight = 4266.0;
  static const double _markerSize = 26.0;

  final TransformationController _controller = TransformationController();
  late final Future<List<GraceMarker>> _gracesFuture = _loadGraces();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<GraceMarker>> _loadGraces() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/map_data/graces.json',
    );
    final decoded = jsonDecode(jsonString) as List<dynamic>;

    return decoded
        .map((item) => GraceMarker.fromJson(item as Map<String, dynamic>))
        .where((grace) => grace.region == null || grace.region == 'surface')
        .toList();
  }

  void _showGraceName(GraceMarker grace) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(grace.name),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: FutureBuilder<List<GraceMarker>>(
        future: _gracesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 48,
              ),
            );
          }

          final graces = snapshot.data ?? const <GraceMarker>[];

          return InteractiveViewer(
            transformationController: _controller,
            minScale: 1.0,
            maxScale: 8.0,
            boundaryMargin: const EdgeInsets.all(80),
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _mapWidth,
                  height: _mapHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/map/map.jpg',
                          fit: BoxFit.fill,
                        ),
                      ),
                      for (final grace in graces)
                        Positioned(
                          left: grace.x - _markerSize / 2,
                          top: grace.y - _markerSize / 2,
                          width: _markerSize,
                          height: _markerSize,
                          child: Tooltip(
                            message: grace.name,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _showGraceName(grace),
                              child: Image.asset(
                                'assets/images/grace_Icon2.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class GraceMarker {
  final String name;
  final double lat;
  final double lng;
  final String? region;

  const GraceMarker({
    required this.name,
    required this.lat,
    required this.lng,
    required this.region,
  });

  double get x => lng / 256.0 * 4500.0- 120;
  double get y => -lat / 256.0 * 4266.0 + 20;

  factory GraceMarker.fromJson(Map<String, dynamic> json) {
    return GraceMarker(
      name: json['name'] as String? ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      region: json['region'] as String?,
    );
  }
}
