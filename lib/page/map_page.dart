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

  static const double _dlcMapWidth = 4096.0;
  static const double _dlcMapHeight = 4964.0;

  static const double _markerSize = 26.0;

  // Surface map calibration values.
  // x = lng * scaleX + offsetX
  // y = -lat * scaleY + offsetY
  static const double _scaleX = 20.0265436304;
  static const double _offsetX = -270.0875581638;

  static const double _scaleY = 19.8693755067;
  static const double _offsetY = -402.0110326920;

  // DLC map calibration values.
  // x = lng * dlcScaleX + dlcOffsetX
  // y = -lat * dlcScaleY + dlcOffsetY
  static const double _dlcScaleX = 34.5793649786;
  static const double _dlcOffsetX = -2440.8233632454;

  static const double _dlcScaleY = 34.9537159451;
  static const double _dlcOffsetY = -2053.7393585445;

  final TransformationController _controller = TransformationController();
  late final Future<List<GraceMarker>> _gracesFuture = _loadGraces();

  String _selectedRegion = 'surface';

  bool get _isDlcMap => _selectedRegion == 'dlc';

  double get _currentMapWidth => _isDlcMap ? _dlcMapWidth : _mapWidth;

  double get _currentMapHeight => _isDlcMap ? _dlcMapHeight : _mapHeight;

  String get _currentMapAsset =>
      _isDlcMap ? 'assets/images/map/dlc.png' : 'assets/images/map/map.jpg';

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
        .toList();
  }

  void _toggleMapRegion() {
    setState(() {
      _selectedRegion = _isDlcMap ? 'surface' : 'dlc';
      _controller.value = Matrix4.identity();
    });
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

          final graces = (snapshot.data ?? const <GraceMarker>[])
              .where((grace) => grace.region == _selectedRegion)
              .toList();

          return Stack(
            children: [
              InteractiveViewer(
                transformationController: _controller,
                constrained: false,
                minScale: 0.1,
                maxScale: 8.0,
                boundaryMargin: const EdgeInsets.all(80),
                child: SizedBox(
                  width: _currentMapWidth,
                  height: _currentMapHeight,
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (event) {
                      final p = event.localPosition;
                      debugPrint(
                        'MAP PIXEL => x: ${p.dx.toStringAsFixed(2)}, '
                            'y: ${p.dy.toStringAsFixed(2)}',
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Image.asset(
                          _currentMapAsset,
                          width: _currentMapWidth,
                          height: _currentMapHeight,
                          fit: BoxFit.fill,
                        ),
                        for (final grace in graces)
                          Positioned(
                            left: grace.x(_selectedRegion) - _markerSize / 2,
                            top: grace.y(_selectedRegion) - _markerSize / 2,
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
              Positioned(
                top: 16,
                right: 16,
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: _toggleMapRegion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xDD1B1B1B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0x99D8C080)),
                      ),
                    ),
                    child: Text(_isDlcMap ? 'MAP' : 'DLC'),
                  ),
                ),
              ),
            ],
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

  double x(String region) {
    if (region == 'dlc') {
      return lng * _MapPageState._dlcScaleX +
          _MapPageState._dlcOffsetX;
    }

    return lng * _MapPageState._scaleX + _MapPageState._offsetX;
  }

  double y(String region) {
    if (region == 'dlc') {
      return -lat * _MapPageState._dlcScaleY +
          _MapPageState._dlcOffsetY;
    }

    return -lat * _MapPageState._scaleY + _MapPageState._offsetY;
  }

  factory GraceMarker.fromJson(Map<String, dynamic> json) {
    return GraceMarker(
      name: json['name'] as String? ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      region: json['region'] as String?,
    );
  }
}