class Boss {
  final String id;
  final String name;
  final String? image;
  final String description;
  final String location;
  final List<String> drops;

  Boss({
    required this.id,
    required this.name,
    this.image,
    required this.description,
    required this.location,
    required this.drops,
  });

  factory Boss.fromJson(Map<String, dynamic> json) {
    return Boss(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String?,
      description: json['description'] as String,
      location: json['location'] as String,
      drops: List<String>.from(json['drops'] ?? []),
    );
  }
}

class BossResponse {
  final bool success;
  final int count;
  final List<Boss> data;

  BossResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory BossResponse.fromJson(Map<String, dynamic> json) {
    return BossResponse(
      success: json['success'] as bool,
      count: json['count'] as int,
      data: (json['data'] as List)
          .map((e) => Boss.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
