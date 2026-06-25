import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MapPage extends StatefulWidget {
  final String searchQuery;
  final Set<String> enabledCategories;
  final Set<String> enabledDetailKeys;
  final String selectedRegion;

  const MapPage({
    super.key,
    this.searchQuery = '',
    this.enabledCategories = MapMarkerData.defaultCategoryKeys,
    this.enabledDetailKeys = MapMarkerData.defaultDetailKeys,
    this.selectedRegion = 'surface',
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const double _mapWidth = 4500.0;
  static const double _mapHeight = 4266.0;

  static const double _dlcMapWidth = 4096.0;
  static const double _dlcMapHeight = 4964.0;

  static const double _undergroundMapWidth = 4864.0;
  static const double _undergroundMapHeight = 4608.0;

  static const double _markerSize = 26.0;
  static const double _viewportPadding = 256.0;
  static const double _viewportPanThreshold = 96.0;
  static const double _viewportScaleThreshold = 0.05;

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
  static const double _dlcOffsetX = -2434.8233632454;

  static const double _dlcScaleY = 34.9537159451;
  static const double _dlcOffsetY = -2053.7393585445;

  // Underground map calibration values.
  // x = lng * undergroundScaleX + undergroundOffsetX
  // y = -lat * undergroundScaleY + undergroundOffsetY
  static const double _undergroundScaleX = 20.3724379686;
  static const double _undergroundOffsetX = -191.2706415701;

  static const double _undergroundScaleY = 20.6869061697;
  static const double _undergroundOffsetY = -362.6913367472;

  final TransformationController _controller = TransformationController();
  late final Future<List<MapMarkerData>> _markersFuture = _loadMarkers();

  late String _selectedRegion;
  double _lastViewportScale = 1.0;
  Offset _lastViewportTranslation = Offset.zero;

  bool get _isDlcMap => _selectedRegion == 'dlc';

  bool get _isUndergroundMap => _selectedRegion == 'underground';

  double get _currentMapWidth => _isDlcMap
      ? _dlcMapWidth
      : (_isUndergroundMap ? _undergroundMapWidth : _mapWidth);

  double get _currentMapHeight => _isDlcMap
      ? _dlcMapHeight
      : (_isUndergroundMap ? _undergroundMapHeight : _mapHeight);

  String get _currentMapAsset => _isDlcMap
      ? 'assets/images/map/dlc.png'
      : (_isUndergroundMap
            ? 'assets/images/map/underground.jpg'
            : 'assets/images/map/map.jpg');

  @override
  void initState() {
    super.initState();
    _selectedRegion = widget.selectedRegion;
    _controller.addListener(_handleViewportChanged);
  }

  @override
  void didUpdateWidget(covariant MapPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedRegion != widget.selectedRegion) {
      _selectedRegion = widget.selectedRegion;
      _resetViewport();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleViewportChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleViewportChanged() {
    final matrix = _controller.value;
    final scale = matrix.getMaxScaleOnAxis();
    final translationVector = matrix.getTranslation();
    final translation = Offset(translationVector.x, translationVector.y);

    if ((scale - _lastViewportScale).abs() > _viewportScaleThreshold ||
        (translation - _lastViewportTranslation).distance >
            _viewportPanThreshold) {
      _lastViewportScale = scale;
      _lastViewportTranslation = translation;
      setState(() {});
    }
  }

  Future<List<MapMarkerData>> _loadMarkers() async {
    const markerFileNames = {
      'bosses.json',
      'dungeons.json',
      'graces.json',
      'items.json',
      'npcs.json',
      'waygates.json',
    };
    final manifestString = await rootBundle.loadString('AssetManifest.json');
    final manifest = jsonDecode(manifestString) as Map<String, dynamic>;
    final markerAssetResolver = MapRegionMarkerAssetResolver.fromManifest(
      manifest,
    );
    final markerPaths =
        manifest.keys
            .where((path) => markerFileNames.contains(path.split('/').last))
            .toList()
          ..sort();

    final markers = <MapMarkerData>[];

    for (final path in markerPaths) {
      final jsonString = await rootBundle.loadString(path);
      final decoded = jsonDecode(jsonString);

      if (decoded is! List) continue;

      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;

        final marker = MapMarkerData.tryFromJson(
          item,
          path,
          markerAssetResolver: markerAssetResolver,
        );
        if (marker != null) {
          markers.add(marker);
        }
      }
    }

    final markerAssetUseCounts = <String, int>{};
    for (final marker in markers) {
      final markerAssetPath = marker.markerAssetPath;
      if (markerAssetPath == null) continue;

      markerAssetUseCounts[markerAssetPath] =
          (markerAssetUseCounts[markerAssetPath] ?? 0) + 1;
    }

    return [
      for (final marker in markers)
        _withAssetUseScale(marker, markerAssetUseCounts),
    ];
  }

  static MapMarkerData _withAssetUseScale(
    MapMarkerData marker,
    Map<String, int> markerAssetUseCounts,
  ) {
    final markerAssetPath = marker.markerAssetPath;
    final isSingleUseAsset =
        markerAssetPath != null && markerAssetUseCounts[markerAssetPath] == 1;
    final scale = isSingleUseAsset
        ? MapMarkerData.singleUseMarkerAssetScale
        : MapMarkerData.defaultMarkerAssetScale;

    return marker.withMarkerAssetScale(scale);
  }

  void _resetViewport() {
    _lastViewportScale = 1.0;
    _lastViewportTranslation = Offset.zero;
    _controller.value = Matrix4.identity();
  }

  void _showMarkerInfo(MapMarkerData marker) {
    final title = marker.displayName;
    final details = <String>[
      if (marker.hasKoreanName && marker.name.trim().isNotEmpty) marker.name,
      marker.label,
      marker.detailLabel,
      if (marker.typeLabel != null) marker.typeLabel!,
      if (marker.sourceLabel != null) marker.sourceLabel!,
    ].join(' · ');

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(details.isEmpty ? title : '$title\n$details'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  List<MapMarkerData> _visibleMarkers(
    List<MapMarkerData> markers,
    Size viewportSize,
  ) {
    final query = widget.searchQuery.trim().toLowerCase();
    final viewportRect = _visibleMapRect(viewportSize);

    return markers.where((marker) {
      if (marker.region != _selectedRegion) return false;
      if (!widget.enabledCategories.contains(marker.categoryKey)) return false;
      if (!widget.enabledDetailKeys.contains(marker.detailKey)) return false;
      if (!viewportRect.contains(marker.offset(_selectedRegion))) return false;
      if (query.isEmpty) return true;

      return marker.name.toLowerCase().contains(query) ||
          marker.displayName.toLowerCase().contains(query);
    }).toList();
  }

  Rect _visibleMapRect(Size viewportSize) {
    if (viewportSize.isEmpty) {
      return Rect.fromLTWH(0, 0, _currentMapWidth, _currentMapHeight);
    }

    final inverseMatrix = Matrix4.inverted(_controller.value);
    final topLeft = MatrixUtils.transformPoint(inverseMatrix, Offset.zero);
    final bottomRight = MatrixUtils.transformPoint(
      inverseMatrix,
      Offset(viewportSize.width, viewportSize.height),
    );

    final visibleRect = Rect.fromLTRB(
      math.min(topLeft.dx, bottomRight.dx),
      math.min(topLeft.dy, bottomRight.dy),
      math.max(topLeft.dx, bottomRight.dx),
      math.max(topLeft.dy, bottomRight.dy),
    ).inflate(_viewportPadding);

    return visibleRect.intersect(
      Rect.fromLTWH(0, 0, _currentMapWidth, _currentMapHeight),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: FutureBuilder<List<MapMarkerData>>(
        future: _markersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Icon(Icons.error_outline, color: Colors.white, size: 48),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final markers = _visibleMarkers(
                snapshot.data ?? const <MapMarkerData>[],
                constraints.biggest,
              );

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
                            for (final marker in markers) ...[
                              Builder(
                                builder: (context) {
                                  final markerSize = marker.visualSize(
                                    _markerSize,
                                  );

                                  return Positioned(
                                    left:
                                        marker.x(_selectedRegion) -
                                        markerSize / 2,
                                    top:
                                        marker.y(_selectedRegion) -
                                        markerSize / 2,
                                    width: markerSize,
                                    height: markerSize,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _showMarkerInfo(marker),
                                      child: _MapMarkerIcon(
                                        marker: marker,
                                        size: markerSize,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class MapMarkerData {
  static const String graceKey = 'grace';
  static const String bossKey = 'boss';
  static const String dungeonKey = 'dungeon';
  static const String itemKey = 'item';
  static const String npcKey = 'npc';
  static const String waygateKey = 'waygate';

  static const Set<String> defaultCategoryKeys = {
    graceKey,
    bossKey,
    dungeonKey,
    itemKey,
    npcKey,
    waygateKey,
  };

  final String name;
  final String? korName;
  final double lat;
  final double lng;
  final String region;
  final String categoryKey;
  final String label;
  final String detailKey;
  final String detailLabel;
  final String? category;
  final String? type;
  final String? source;
  final String? markerAssetPath;
  final double markerAssetScale;

  static const double defaultMarkerAssetScale = 1.0;
  static const double singleUseMarkerAssetScale = 4.0;

  const MapMarkerData({
    required this.name,
    required this.korName,
    required this.lat,
    required this.lng,
    required this.region,
    required this.categoryKey,
    required this.label,
    required this.detailKey,
    required this.detailLabel,
    required this.category,
    required this.type,
    required this.source,
    required this.markerAssetPath,
    required this.markerAssetScale,
  });

  String get displayName {
    final value = korName?.trim();
    return value == null || value.isEmpty ? name : value;
  }

  bool get hasKoreanName {
    final value = korName?.trim();
    return value != null && value.isNotEmpty && value != name;
  }

  String? get typeLabel {
    final value = type?.trim();
    if (value == null || value.isEmpty) return null;

    final label = typeDisplayLabel(value);
    return label == detailLabel ? null : label;
  }

  String? get sourceLabel {
    final value = source?.trim();
    if (value == null || value.isEmpty) return null;

    return sourceDisplayLabel(value);
  }

  double x(String region) {
    if (region == 'dlc') {
      return lng * _MapPageState._dlcScaleX + _MapPageState._dlcOffsetX;
    }

    if (region == 'underground') {
      return lng * _MapPageState._undergroundScaleX +
          _MapPageState._undergroundOffsetX;
    }

    return lng * _MapPageState._scaleX + _MapPageState._offsetX;
  }

  double y(String region) {
    if (region == 'dlc') {
      return -lat * _MapPageState._dlcScaleY + _MapPageState._dlcOffsetY;
    }

    if (region == 'underground') {
      return -lat * _MapPageState._undergroundScaleY +
          _MapPageState._undergroundOffsetY;
    }

    return -lat * _MapPageState._scaleY + _MapPageState._offsetY;
  }

  Offset offset(String region) {
    return Offset(x(region), y(region));
  }

  double visualSize(double baseSize) {
    return markerAssetPath == null ? baseSize : baseSize * markerAssetScale;
  }

  MapMarkerData withMarkerAssetScale(double scale) {
    if (markerAssetScale == scale) return this;

    return MapMarkerData(
      name: name,
      korName: korName,
      lat: lat,
      lng: lng,
      region: region,
      categoryKey: categoryKey,
      label: label,
      detailKey: detailKey,
      detailLabel: detailLabel,
      category: category,
      type: type,
      source: source,
      markerAssetPath: markerAssetPath,
      markerAssetScale: scale,
    );
  }

  static MapMarkerData? tryFromJson(
    Map<String, dynamic> json,
    String sourcePath, {
    MapRegionMarkerAssetResolver? markerAssetResolver,
  }) {
    final name = json['name'] as String?;
    final lat = json['lat'];
    final lng = json['lng'];
    final region = json['region'];

    if (name == null ||
        name.isEmpty ||
        lat is! num ||
        lng is! num ||
        region is! String ||
        (region != 'surface' && region != 'dlc' && region != 'underground')) {
      return null;
    }

    final category = json['category'] as String?;
    final korName = json['kor_name'] as String?;
    final type = json['type'] as String?;
    final subcategory = json['subcategory'] as String?;
    final dungeonType = json['dungeon_type'] as String?;
    final source = _sourceFileName(sourcePath);
    final categoryKey = _categoryKey(source, category, type);
    final detailKey = _detailKey(
      categoryKey: categoryKey,
      category: category,
      type: type,
      subcategory: subcategory,
      dungeonType: dungeonType,
    );

    if (!defaultCategoryKeys.contains(categoryKey)) {
      return null;
    }

    final markerAssetMatch = categoryKey == dungeonKey
        ? markerAssetResolver?.resolve(
            name: name,
            korName: korName,
            region: region,
          )
        : null;

    return MapMarkerData(
      name: name,
      korName: korName,
      lat: lat.toDouble(),
      lng: lng.toDouble(),
      region: region,
      categoryKey: categoryKey,
      label: categoryLabel(categoryKey),
      detailKey: detailKey,
      detailLabel: detailDisplayLabel(detailKey),
      category: category,
      type: type,
      source: source,
      markerAssetPath: markerAssetMatch?.path,
      markerAssetScale:
          markerAssetMatch?.scale ?? MapMarkerData.defaultMarkerAssetScale,
    );
  }

  static String categoryLabel(String categoryKey) {
    switch (categoryKey) {
      case graceKey:
        return '축복';
      case bossKey:
        return '보스';
      case dungeonKey:
        return '던전';
      case itemKey:
        return '아이템';
      case npcKey:
        return 'NPC';
      case waygateKey:
        return '전송문';
      default:
        return categoryKey;
    }
  }

  static String? categoryIconAsset(String categoryKey) {
    switch (categoryKey) {
      case graceKey:
        return 'assets/images/map_assets/grace.png';
      case bossKey:
        return 'assets/images/map_assets/boss.webp';
      case itemKey:
        return 'assets/images/map_assets/item.png';
      case npcKey:
        return 'assets/images/map_assets/npc.png';
      default:
        return null;
    }
  }

  static const List<MapMarkerDetailGroup> detailGroups = [
    MapMarkerDetailGroup(title: '축복', keys: ['grace']),
    MapMarkerDetailGroup(
      title: '보스',
      keys: ['boss:field', 'boss:dungeon', 'boss:legacy', 'boss:dlc'],
    ),
    MapMarkerDetailGroup(
      title: '던전',
      keys: [
        'dungeon:surface_poi',
        'dungeon:ruins',
        'dungeon:church',
        'dungeon:catacomb',
        'dungeon:cave',
        'dungeon:shack',
        'dungeon:legacy_dungeon',
        'dungeon:gaol',
        'dungeon:rise',
        'dungeon:minor_erdtree',
        'dungeon:tunnel',
        'dungeon:divine_tower',
        'dungeon:fort',
        'dungeon:forge',
        'dungeon:waygate',
      ],
    ),
    MapMarkerDetailGroup(
      title: '아이템',
      keys: [
        'item:weapon',
        'item:shield',
        'item:armor',
        'item:talisman',
        'item:spell',
        'item:ash_of_war',
        'item:spirit_ash',
        'item:key_item',
        'item:consumable',
        'item:upgrade_material',
        'item:material',
        'item:flask_upgrade',
        'item:map_fragment',
      ],
    ),
    MapMarkerDetailGroup(title: 'NPC', keys: ['npc:npc', 'npc:npc_invader']),
    MapMarkerDetailGroup(title: '전송문', keys: ['waygate']),
  ];

  static const Set<String> defaultDetailKeys = {
    'grace',
    'boss:field',
    'boss:dungeon',
    'boss:legacy',
    'boss:dlc',
    'dungeon:surface_poi',
    'dungeon:ruins',
    'dungeon:church',
    'dungeon:catacomb',
    'dungeon:cave',
    'dungeon:shack',
    'dungeon:legacy_dungeon',
    'dungeon:gaol',
    'dungeon:rise',
    'dungeon:minor_erdtree',
    'dungeon:tunnel',
    'dungeon:divine_tower',
    'dungeon:fort',
    'dungeon:forge',
    'dungeon:waygate',
    'item:weapon',
    'item:shield',
    'item:armor',
    'item:talisman',
    'item:spell',
    'item:ash_of_war',
    'item:spirit_ash',
    'item:key_item',
    'item:consumable',
    'item:upgrade_material',
    'item:material',
    'item:flask_upgrade',
    'item:map_fragment',
    'npc:npc',
    'npc:npc_invader',
    'waygate',
  };

  static String detailDisplayLabel(String detailKey) {
    switch (detailKey) {
      case 'grace':
        return '축복';
      case 'boss:field':
        return '필드 보스';
      case 'boss:dungeon':
        return '던전 보스';
      case 'boss:legacy':
        return '레거시 보스';
      case 'boss:dlc':
        return 'DLC 보스';
      case 'dungeon:surface_poi':
        return '지상 명소';
      case 'dungeon:ruins':
        return '폐허';
      case 'dungeon:church':
        return '교회';
      case 'dungeon:catacomb':
        return '지하 묘지';
      case 'dungeon:cave':
        return '동굴';
      case 'dungeon:shack':
        return '오두막';
      case 'dungeon:legacy_dungeon':
        return '레거시 던전';
      case 'dungeon:gaol':
        return '봉인 감옥';
      case 'dungeon:rise':
        return '마술사탑';
      case 'dungeon:minor_erdtree':
        return '작은 황금 나무';
      case 'dungeon:tunnel':
        return '갱도';
      case 'dungeon:divine_tower':
        return '신수탑';
      case 'dungeon:fort':
        return '요새';
      case 'dungeon:forge':
        return '용광로';
      case 'dungeon:waygate':
        return '던전 전송문';
      case 'item:weapon':
        return '무기';
      case 'item:shield':
        return '방패';
      case 'item:armor':
        return '방어구';
      case 'item:talisman':
        return '탈리스만';
      case 'item:spell':
        return '주문';
      case 'item:ash_of_war':
        return '전회';
      case 'item:spirit_ash':
        return '뼛가루';
      case 'item:key_item':
        return '주요 아이템';
      case 'item:consumable':
        return '소모품';
      case 'item:upgrade_material':
        return '강화 재료';
      case 'item:material':
        return '제작 재료';
      case 'item:flask_upgrade':
        return '성배병 강화';
      case 'item:map_fragment':
        return '지도 조각';
      case 'npc:npc':
        return 'NPC';
      case 'npc:npc_invader':
        return '침입자';
      case 'waygate':
        return '전송문';
      default:
        return detailKey;
    }
  }

  static String typeDisplayLabel(String type) {
    switch (type) {
      case 'field':
        return '필드';
      case 'dungeon':
        return '던전';
      case 'legacy':
        return '레거시';
      case 'dlc':
        return 'DLC';
      case 'surface_poi':
        return '지상 명소';
      case 'ruins':
        return '폐허';
      case 'church':
        return '교회';
      case 'catacomb':
        return '지하 묘지';
      case 'cave':
        return '동굴';
      case 'shack':
        return '오두막';
      case 'legacy_dungeon':
        return '레거시 던전';
      case 'gaol':
        return '봉인 감옥';
      case 'rise':
        return '마술사탑';
      case 'minor_erdtree':
        return '작은 황금 나무';
      case 'tunnel':
        return '갱도';
      case 'divine_tower':
        return '신수탑';
      case 'fort':
        return '요새';
      case 'forge':
        return '용광로';
      case 'waygate':
        return '전송문';
      default:
        return type;
    }
  }

  static String sourceDisplayLabel(String source) {
    switch (source) {
      case 'graces.json':
        return '축복 데이터';
      case 'bosses.json':
        return '보스 데이터';
      case 'dungeons.json':
        return '던전 데이터';
      case 'items.json':
        return '아이템 데이터';
      case 'npcs.json':
        return 'NPC 데이터';
      case 'waygates.json':
        return '전송문 데이터';
      default:
        return source;
    }
  }

  static String _detailKey({
    required String categoryKey,
    String? category,
    String? type,
    String? subcategory,
    String? dungeonType,
  }) {
    switch (categoryKey) {
      case graceKey:
        return 'grace';
      case bossKey:
        return 'boss:${type ?? 'field'}';
      case dungeonKey:
        return 'dungeon:${dungeonType ?? type ?? 'surface_poi'}';
      case itemKey:
        return 'item:${category ?? subcategory ?? 'item'}';
      case npcKey:
        return 'npc:${category ?? 'npc'}';
      case waygateKey:
        return 'waygate';
      default:
        return categoryKey;
    }
  }

  static String _sourceFileName(String sourcePath) {
    return sourcePath.split('/').last;
  }

  static String _categoryKey(String source, String? category, String? type) {
    switch (source) {
      case 'graces.json':
        return graceKey;
      case 'bosses.json':
        return bossKey;
      case 'dungeons.json':
        return dungeonKey;
      case 'items.json':
        return itemKey;
      case 'npcs.json':
        return npcKey;
      case 'waygates.json':
        return waygateKey;
    }

    final value = '${category ?? ''} ${type ?? ''}'.toLowerCase();

    if (value.contains('grace')) return graceKey;
    if (value.contains('boss')) return bossKey;
    if (value.contains('dungeon')) return dungeonKey;
    if (value.contains('npc')) return npcKey;
    if (value.contains('waygate')) return waygateKey;

    if (value.contains('item') ||
        value.contains('weapon') ||
        value.contains('armor') ||
        value.contains('talisman') ||
        value.contains('spell') ||
        value.contains('ash')) {
      return itemKey;
    }

    return itemKey;
  }
}

class MapRegionMarkerAssetResolver {
  static const String _assetRoot = 'assets/images/map_assets/';
  static const Set<String> _imageExtensions = {'png', 'jpg', 'jpeg', 'webp'};

  static const Map<String, String> _specialSharedAssets = {
    '왕조유적': 'Ruin Palace',
    '대회랑': 'Ruin Palace',
    '각해의 영지': 'Ruin Palace',
    '영원한 도읍 노크론': 'nok',
    '밤의 성역': 'nok',
    '시프라 수도교': 'nok',
    '영원한 도읍 녹스텔라': 'nok',
  };

  static const Map<String, List<String>> _koreanAssetNameHints = {
    '영웅 묘지': ["hero's grave", 'heros grave'],
    '지하 묘지': ['catacombs'],
    '묘지': ['catacombs'],
    '동굴': ['cave'],
    '마을': ['village'],
    '오두막': ['shack'],
    '갱도': ['tunnel', 'tunnels'],
    '폐허': ['ruins'],
    '교회': ['church'],
    '요새': ['fort'],
    '탑': ['tower'],
  };
  static final RegExp _dlcShackNamePattern = RegExp(
    r'\b(hovel|rest|hut)\b',
  );

  final Map<String, _MapRegionMarkerAsset> _assetsByBaseName;
  final List<_MapRegionMarkerAsset> _assets;

  const MapRegionMarkerAssetResolver._({
    required Map<String, _MapRegionMarkerAsset> assetsByBaseName,
    required List<_MapRegionMarkerAsset> assets,
  }) : _assetsByBaseName = assetsByBaseName,
       _assets = assets;

  factory MapRegionMarkerAssetResolver.fromManifest(
    Map<String, dynamic> manifest,
  ) {
    final assets =
        manifest.keys
            .where(_isSupportedAssetPath)
            .map(_MapRegionMarkerAsset.fromPath)
            .toList()
          ..sort((a, b) {
            final lengthCompare = b.lookupName.length.compareTo(
              a.lookupName.length,
            );
            return lengthCompare != 0
                ? lengthCompare
                : a.baseName.compareTo(b.baseName);
          });

    return MapRegionMarkerAssetResolver._(
      assetsByBaseName: {
        for (final asset in assets) asset.normalizedBaseName: asset,
      },
      assets: assets,
    );
  }

  MapRegionMarkerAssetMatch? resolve({
    required String name,
    required String? korName,
    required String region,
  }) {
    final names = _normalizedNames(name, korName, region: region);
    final isDlc = region == 'dlc';

    for (final entry in _specialSharedAssets.entries) {
      if (names.contains(_normalize(entry.key))) {
        return _matchForBaseName(
          entry.value,
          scale: MapMarkerData.defaultMarkerAssetScale,
        );
      }
    }

    // Generic matching priority:
    // 1. Exact region/dungeon name to asset base name, ignoring extension/case.
    // 2. Partial match where the asset base name, or a safe English variant
    //    such as Tunnel/Tunnels, is contained in the region name; DLC maps
    //    prefer an otherwise matching "_dlc" asset.
    for (final normalizedName in names) {
      final exactMatch = _assetsByBaseName[normalizedName];
      if (exactMatch != null) {
        return MapRegionMarkerAssetMatch(
          path: exactMatch.path,
          scale: MapMarkerData.defaultMarkerAssetScale,
        );
      }
    }

    _MapRegionMarkerAsset? bestMatch;
    var ambiguous = false;
    var bestMatchLength = 0;

    for (final asset in _assets) {
      final matchLength = asset.matchLengthIn(names);
      if (matchLength == null) {
        continue;
      }

      if (bestMatch == null) {
        bestMatch = asset;
        bestMatchLength = matchLength;
        ambiguous = false;
        continue;
      }

      if (matchLength < bestMatchLength) {
        continue;
      }

      if (matchLength > bestMatchLength) {
        bestMatch = asset;
        bestMatchLength = matchLength;
        ambiguous = false;
        continue;
      }

      if (asset.isDlcVariant != bestMatch.isDlcVariant) {
        if (asset.isDlcVariant == isDlc) bestMatch = asset;
        ambiguous = false;
        continue;
      }

      if (asset.path != bestMatch.path) {
        ambiguous = true;
      }
    }

    return ambiguous || bestMatch == null
        ? null
        : MapRegionMarkerAssetMatch(
            path: bestMatch.path,
            scale: MapMarkerData.defaultMarkerAssetScale,
          );
  }

  static bool _isSupportedAssetPath(String path) {
    if (!path.startsWith(_assetRoot)) return false;

    final fileName = path.split('/').last;
    final extension = _extension(fileName);
    return _imageExtensions.contains(extension);
  }

  static Set<String> _normalizedNames(
    String name,
    String? korName, {
    required String region,
  }) {
    final normalizedName = _normalize(name);
    final normalizedKorName = korName == null ? null : _normalize(korName);

    return {
      ..._nameVariants(normalizedName),
      if (region == 'dlc') ..._dlcNameVariants(normalizedName),
      if (normalizedKorName != null && normalizedKorName.isNotEmpty) ...[
        ..._nameVariants(normalizedKorName),
        if (region == 'dlc') ..._dlcNameVariants(normalizedKorName),
      ],
    }..remove('');
  }

  MapRegionMarkerAssetMatch? _matchForBaseName(
    String baseName, {
    required double scale,
  }) {
    final asset = _assetsByBaseName[_normalize(baseName)];
    return asset == null
        ? null
        : MapRegionMarkerAssetMatch(path: asset.path, scale: scale);
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  static Set<String> _nameVariants(String value) {
    final variants = <String>{value};

    if (_isAscii(value)) {
      final withoutApostrophes = value.replaceAll(RegExp("[`']"), '');
      variants.add(withoutApostrophes);
    } else {
      for (final entry in _koreanAssetNameHints.entries) {
        if (value.contains(entry.key)) {
          variants.addAll(entry.value);
        }
      }
    }

    return variants;
  }

  static Set<String> _dlcNameVariants(String value) {
    return _dlcShackNamePattern.hasMatch(value)
        ? const {'shack'}
        : const <String>{};
  }

  static Set<String> _lookupVariants(String value) {
    final variants = _nameVariants(value);

    if (!_isAscii(value)) return variants;

    for (final variant in variants.toList()) {
      if (variant.length > 3 && variant.endsWith('ies')) {
        variants.add('${variant.substring(0, variant.length - 3)}y');
      } else if (variant.length > 2 && variant.endsWith('s')) {
        variants.add(variant.substring(0, variant.length - 1));
      }
    }

    return variants..remove('');
  }

  static bool _isAscii(String value) {
    return value.codeUnits.every((codeUnit) => codeUnit <= 0x7f);
  }

  static String _extension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) return '';
    return fileName.substring(dotIndex + 1).toLowerCase();
  }
}

class MapRegionMarkerAssetMatch {
  final String path;
  final double scale;

  const MapRegionMarkerAssetMatch({required this.path, required this.scale});
}

class _MapRegionMarkerAsset {
  final String path;
  final String baseName;
  final String normalizedBaseName;
  final String lookupName;
  final Set<String> lookupNames;
  final bool isDlcVariant;

  const _MapRegionMarkerAsset({
    required this.path,
    required this.baseName,
    required this.normalizedBaseName,
    required this.lookupName,
    required this.lookupNames,
    required this.isDlcVariant,
  });

  int? matchLengthIn(Set<String> names) {
    int? bestLength;

    for (final lookupName in lookupNames) {
      if (!names.any((name) => name.contains(lookupName))) {
        continue;
      }

      if (bestLength == null || lookupName.length > bestLength) {
        bestLength = lookupName.length;
      }
    }

    return bestLength;
  }

  factory _MapRegionMarkerAsset.fromPath(String path) {
    final fileName = path.split('/').last;
    final dotIndex = fileName.lastIndexOf('.');
    final baseName = dotIndex < 0 ? fileName : fileName.substring(0, dotIndex);
    final normalizedBaseName = MapRegionMarkerAssetResolver._normalize(
      baseName,
    );
    final isDlcVariant = normalizedBaseName.endsWith('_dlc');
    final lookupName = isDlcVariant
        ? normalizedBaseName.substring(0, normalizedBaseName.length - 4)
        : normalizedBaseName;

    return _MapRegionMarkerAsset(
      path: path,
      baseName: baseName,
      normalizedBaseName: normalizedBaseName,
      lookupName: lookupName,
      lookupNames: MapRegionMarkerAssetResolver._lookupVariants(lookupName),
      isDlcVariant: isDlcVariant,
    );
  }
}

class MapMarkerDetailGroup {
  final String title;
  final List<String> keys;

  const MapMarkerDetailGroup({required this.title, required this.keys});
}

class _MapMarkerIcon extends StatelessWidget {
  final MapMarkerData marker;
  final double size;

  const _MapMarkerIcon({required this.marker, required this.size});

  @override
  Widget build(BuildContext context) {
    final markerAsset = marker.markerAssetPath;

    if (markerAsset != null) {
      return Center(
        child: Image.asset(
          markerAsset,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      );
    }

    final iconAsset = MapMarkerData.categoryIconAsset(marker.categoryKey);

    if (iconAsset != null) {
      return Center(
        child: Image.asset(
          iconAsset,
          width: size * 0.72,
          height: size * 0.72,
          fit: BoxFit.contain,
        ),
      );
    }

    final color = _colorForCategory(marker.categoryKey);

    return Center(
      child: Container(
        width: size * 0.72,
        height: size * 0.72,
        decoration: BoxDecoration(
          color: color.withOpacity(0.92),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForCategory(String categoryKey) {
    switch (categoryKey) {
      case MapMarkerData.bossKey:
        return Colors.redAccent;
      case MapMarkerData.dungeonKey:
        return Colors.deepPurpleAccent;
      case MapMarkerData.itemKey:
        return Colors.lightBlueAccent;
      case MapMarkerData.npcKey:
        return Colors.greenAccent;
      case MapMarkerData.waygateKey:
        return Colors.orangeAccent;
      default:
        return Colors.white70;
    }
  }
}
