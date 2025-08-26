// lib/detail_image_viewer_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DetailImageViewerPage extends StatefulWidget {
  final String imageUrl;
  final String title;

  const DetailImageViewerPage({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  @override
  State<DetailImageViewerPage> createState() => _DetailImageViewerPageState();
}

class _DetailImageViewerPageState extends State<DetailImageViewerPage> {
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleUI() {
    setState(() {
      _isVisible = !_isVisible;
      if (_isVisible) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white10,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedOpacity(
          opacity: _isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: AppBar(
            title: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.black.withOpacity(0.7),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: _toggleUI,
        // [수정] Center 위젯을 제거하여 InteractiveViewer가 전체 화면을 차지하도록 함
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.8,
          maxScale: 4.0,
          // [추가] 사용자가 이미지 경계를 넘어 패닝할 때 여백을 주어 부드러운 느낌을 줌
          boundaryMargin: const EdgeInsets.all(20.0),
          child: Center( // 이미지가 처음에는 중앙에 오도록 Center 위젯을 여기에 추가
            child: Image.network(
              widget.imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.error_outline, color: Colors.white, size: 50),
              ),
            ),
          ),
        ),
      ),
    );
  }
}