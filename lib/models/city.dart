class City {
  String city;
  String region;

  City({this.city, this.region});

  factory City.fromJson(Map<String, dynamic> parsedJson) {
    return City(
      city: parsedJson["name"] as String,
      region: parsedJson["region"] as String,
    );
  }
}