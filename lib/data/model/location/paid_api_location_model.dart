class PaidAPILocationModel {
  final String name;
  final String? placeId;
  final String? fullAddress;
  final double? lat;
  final double? lng;

  // Structured fields from result address_components
  final String? sublocality;
  final String? locality;
  final String? areaLevel3;
  final String? state;
  final String? country;

  PaidAPILocationModel({
    required this.name,
    this.placeId,
    this.fullAddress,
    this.lat,
    this.lng,
    this.sublocality,
    this.locality,
    this.areaLevel3,
    this.state,
    this.country,
  });

  factory PaidAPILocationModel.fromPrediction(Map<String, dynamic> json) {
    final terms = json['terms'] as List<dynamic>? ?? [];

    // Extract last few elements safely
    String? getTerm(int reverseIndex) {
      final index = terms.length - 1 - reverseIndex;
      if (index >= 0 && index < terms.length) {
        return terms[index]['value'];
      }
      return null;
    }

    return PaidAPILocationModel(
      name: json['description'] ?? '',
      placeId: json['place_id'] ?? '',
      country: getTerm(0),
      // last item
      state: getTerm(1),
      locality: getTerm(2),
      sublocality:
          terms.length > 3 ? terms[0]['value'] : null, // first item if detailed
    );
  }

  /// From result response

  factory PaidAPILocationModel.fromResult(Map<String, dynamic> json) {
    List addressComponents = json['address_components'] ?? [];

    String? getComponent(String type) {
      try {
        return addressComponents.firstWhere(
            (c) => (c['types'] as List).contains(type))['long_name'];
      } catch (_) {
        return null;
      }
    }

    final location = json['geometry']?['location'] ?? {};

    return PaidAPILocationModel(
      name: getComponent('locality') ?? getComponent('sublocality') ?? '',
      placeId: json['place_id'] ?? '',
      fullAddress: json['formatted_address'] ?? '',
      lat: (location['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (location['lng'] as num?)?.toDouble() ?? 0.0,
      sublocality: getComponent('sublocality') ?? '',
      locality: getComponent('locality') ?? '',
      //areaLevel3: getComponent('administrative_area_level_3') ?? '',
      state: getComponent('administrative_area_level_1') ?? '',
      country: getComponent('country') ?? '',
    );
  }
}
