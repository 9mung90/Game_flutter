class AppVersionInfo {
  final String latestVersion;
  final String title;
  final String message;
  final String storeUrl;
  final bool force;

  AppVersionInfo({
    required this.latestVersion,
    required this.title,
    required this.message,
    required this.storeUrl,
    required this.force,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      latestVersion: json['latestVersion'] ?? '',
      title: json['title'] ?? '업데이트 안내',
      message: json['message'] ?? '',
      storeUrl: json['storeUrl'] ?? '',
      force: json['force'] ?? false,
    );
  }
}