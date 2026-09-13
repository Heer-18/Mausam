class CitySearchResult {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String country;
  final String? admin1;
  final String? countryCode;

  CitySearchResult({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.country,
    this.admin1,
    this.countryCode,
  });

  String get fullDisplayName {
    final parts = [name];
    if (admin1 != null && admin1!.isNotEmpty && admin1 != name) {
      parts.add(admin1!);
    }
    if (country.isNotEmpty) {
      parts.add(country);
    }
    return parts.join(', ');
  }

  factory CitySearchResult.fromJson(Map<String, dynamic> json) => CitySearchResult(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    country: json['country'] ?? '',
    admin1: json['admin1'],
    countryCode: json['country_code'] ?? json['countryCode'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'country': country,
    'admin1': admin1,
    'country_code': countryCode,
  };
}
