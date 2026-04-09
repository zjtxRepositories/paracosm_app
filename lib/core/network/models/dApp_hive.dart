
class DAppHive {
  String? name;
  String? headUrl;
  String? des;
  String url;
  late List<int> coins;

  DAppHive({
    this.name,
    this.headUrl,
    this.des,
    required this.url,
    this.coins = const [],
  });

  factory DAppHive.fromJson(Map<String, dynamic> json) {
    return DAppHive(
      name: json["name"] ?? "",
      headUrl: json["headUrl"] ?? "",
      des: json["des"] ?? "",
      url: json["url"] ?? "",
      coins: (json["coins"] as List? ?? [])
          .map((e) => int.parse(e))
          .toList(),
    );
  }

}
