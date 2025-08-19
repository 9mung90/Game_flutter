import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // SystemChrome을 사용하기 위해 반드시 임포트해야 합니다.

class PhotoFullscreenViewer extends StatefulWidget {
  final String imageUrl;

  const PhotoFullscreenViewer({
    super.key,
    required this.imageUrl,
  });

  @override
  State<PhotoFullscreenViewer> createState() => _PhotoFullscreenViewerState();
}

class _PhotoFullscreenViewerState extends State<PhotoFullscreenViewer> {
  bool _isUIVisible = true;

  @override
  void initState() {
    super.initState();
    // ▼▼▼ 핵심 수정 1: 페이지 진입 시 시스템 UI 숨기기 ▼▼▼
    // 화면을 몰입 모드로 설정하여 상단 상태바와 하단 내비게이션 바를 모두 숨깁니다.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    // ▼▼▼ 핵심 수정 2: 페이지 이탈 시 시스템 UI 복원 ▼▼▼
    // 다른 페이지에 영향을 주지 않도록 시스템 UI를 원래 상태로 되돌립니다.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _isUIVisible = !_isUIVisible;
          });
        },
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                  errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.error_outline, color: Colors.white, size: 50)),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _isUIVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.4),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}