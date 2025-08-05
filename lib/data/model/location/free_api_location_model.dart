class FreeAPILocationModel {
  final int? areaId;
  final String? area;
  final int? cityId;
  final String? city;
  final String? state;
  final String? country;
  final String? latitude;
  final String? longitude;

  FreeAPILocationModel({
    this.areaId,
    this.area,
    this.cityId,
    this.city,
    this.state,
    this.country,
    this.latitude,
    this.longitude,
  });

  factory FreeAPILocationModel.fromJson(Map<String, dynamic> json) {
    return FreeAPILocationModel(
      areaId: json['area_id'],
      area: json['area'],
      cityId: json['city_id'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  Map<String, dynamic> toJson() => {
    'area_id': areaId,
    'area': area,
    'city_id': cityId,
    'city': city,
    'state': state,
    'country': country,
    'latitude': latitude,
    'longitude': longitude,
  };
}