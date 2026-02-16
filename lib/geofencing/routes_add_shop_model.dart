class AddShopModel {
  // ALL FIELDS FROM API
  String? shop_name;
  String? latitude;
  String? longitude;
  String? shop_address;
  String? route_id;

  AddShopModel({
    this.shop_name,
    this.latitude,
    this.longitude,
    this.shop_address,
    this.route_id,
  });

  // FROM JSON - WITH CASE-INSENSITIVE FIELD MATCHING
  factory AddShopModel.fromMap(Map<String, dynamic> json) {
    // Helper function to get value case-insensitively
    String? getValue(String key) {
      // Try exact match first
      if (json.containsKey(key)) {
        return json[key]?.toString();
      }
      // Try uppercase
      if (json.containsKey(key.toUpperCase())) {
        return json[key.toUpperCase()]?.toString();
      }
      // Try lowercase
      if (json.containsKey(key.toLowerCase())) {
        return json[key.toLowerCase()]?.toString();
      }
      // Try capitalized
      final capitalized = key[0].toUpperCase() + key.substring(1).toLowerCase();
      if (json.containsKey(capitalized)) {
        return json[capitalized]?.toString();
      }
      return null;
    }

    return AddShopModel(
      shop_name: getValue('SHOP_NAME') ??
          getValue('shop_name') ??
          getValue('name') ??
          getValue('Name'),

      latitude: getValue('LATITUDE') ??
          getValue('latitude') ??
          getValue('lat') ??
          getValue('Lat'),

      longitude: getValue('LONGITUDE') ??
          getValue('longitude') ??
          getValue('lng') ??
          getValue('lon') ??
          getValue('Long') ??
          getValue('Lng'),

      shop_address: getValue('SHOP_ADDRESS') ??
          getValue('shop_address') ??
          getValue('address') ??
          getValue('Address'),

      route_id: getValue('ROUTE_ID') ??
          getValue('route_id') ??
          getValue('routeId') ??
          getValue('RouteId') ??
          getValue('routeid'),
    );
  }

  // GET LAT LNG AS DOUBLE
  double? get lat => latitude != null ? double.tryParse(latitude!) : null;
  double? get lng => longitude != null ? double.tryParse(longitude!) : null;

  // GET ROUTE ID AS INT
  int? get routeIdAsInt => route_id != null ? int.tryParse(route_id!) : null;
}