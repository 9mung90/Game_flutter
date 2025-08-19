class Game {
  final int id;
  final String title;
  final int price;
  final String img;
  final String genre1;
  final String genre2;
  final String genre3;

  Game({
    required this.id,
    required this.title,
    required this.price,
    required this.img,
    required this.genre1,
    required this.genre2,
    required this.genre3,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      title: json['title'],
      price: json['price'],
      img: json['img'],
      genre1: json['genre1'],
      genre2: json['genre2'],
      genre3: json['genre3'],
    );
  }
}
