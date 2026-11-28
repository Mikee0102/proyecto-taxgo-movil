import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/filter_option.dart';
import '../models/place.dart';

class PlacesService {
  static const String _tlaxcalaBbox = '19.1000,-98.5000,19.6000,-97.9000';
  static const List<String> _overpassEndpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];
  static const String _placesCacheKey = 'cached_overpass_places';
  static List<Place>? _lastSuccessfulPlaces;

  static PlaceCategory _mapOsmTagToCategory(Map<String, dynamic> tags) {
    if (tags['tourism'] == 'museum') return PlaceCategory.museum;
    if (tags['amenity'] == 'place_of_worship') return PlaceCategory.church;
    if (tags['leisure'] == 'park') return PlaceCategory.park;
    if (tags['tourism'] == 'viewpoint') return PlaceCategory.viewpoint;
    if (tags['amenity'] == 'restaurant' || tags['amenity'] == 'cafe') {
      return PlaceCategory.restaurant;
    }
    if (tags['tourism'] == 'hotel' || tags['tourism'] == 'guest_house') {
      return PlaceCategory.hotel;
    }
    return PlaceCategory.all;
  }

  static Future<List<Place>> fetchPlacesFromOverpass() async {
    if (_lastSuccessfulPlaces == null) {
      await loadCachedPlaces();
    }

    const query =
        '''
      [out:json][timeout:15];
      (
        node["tourism"~"^(museum|viewpoint|hotel|guest_house)\$"]($_tlaxcalaBbox);
        node["amenity"~"^(place_of_worship|restaurant|cafe)\$"]($_tlaxcalaBbox);
        node["leisure"="park"]($_tlaxcalaBbox);
        way["tourism"~"^(museum|viewpoint|hotel|guest_house)\$"]($_tlaxcalaBbox);
        way["amenity"~"^(place_of_worship|restaurant|cafe)\$"]($_tlaxcalaBbox);
        way["leisure"="park"]($_tlaxcalaBbox);
      );
      out center;
    ''';

    for (final endpoint in _overpassEndpoints) {
      try {
        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: const {'User-Agent': 'TlaxGo/1.0'},
              body: {'data': query},
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode != 200) {
          debugPrint(
            'Overpass respondió ${response.statusCode} desde $endpoint.',
          );
          continue;
        }

        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is! Map<String, dynamic> || decoded['elements'] is! List) {
          debugPrint('Overpass devolvió una respuesta con formato inválido.');
          continue;
        }

        final places = <Place>[];
        for (final raw in decoded['elements'] as List<dynamic>) {
          if (raw is! Map<String, dynamic>) continue;

          final tagsValue = raw['tags'];
          final tags = tagsValue is Map<String, dynamic>
              ? tagsValue
              : <String, dynamic>{};
          final name = (tags['name'] ?? tags['official_name'] ?? '')
              .toString()
              .trim();
          if (name.isEmpty) continue;

          final centerValue = raw['center'];
          final center = centerValue is Map<String, dynamic>
              ? centerValue
              : null;
          final latitude = raw['lat'] ?? center?['lat'];
          final longitude = raw['lon'] ?? center?['lon'];
          if (latitude is! num || longitude is! num) continue;

          final location = LatLng(latitude.toDouble(), longitude.toDouble());
          final osmMun =
              (tags['addr:municipality'] ??
                      tags['addr:city'] ??
                      tags['addr:town'] ??
                      tags['addr:village'] ??
                      '')
                  .toString()
                  .trim();
          final id = raw['id']?.toString();
          if (id == null) continue;

          places.add(
            Place(
              id: id,
              name: name,
              category: _mapOsmTagToCategory(tags),
              location: location,
              municipality: osmMun.isNotEmpty
                  ? osmMun
                  : resolveClosestMunicipality(location),
            ),
          );
        }

        if (places.isEmpty) {
          debugPrint('Overpass no encontró lugares con nombre.');
          continue;
        }

        _lastSuccessfulPlaces = List.unmodifiable(places);
        await _saveCachedPlaces(_lastSuccessfulPlaces!);
        return _lastSuccessfulPlaces!;
      } on Exception catch (error) {
        debugPrint('No se pudo consultar Overpass en $endpoint: $error');
      }
    }

    debugPrint(
      'No se pudo cargar Overpass; se usará la última lista disponible.',
    );
    return _lastSuccessfulPlaces ?? getFallbackPlaces();
  }

  static Future<List<Place>> loadCachedPlaces() async {
    if (_lastSuccessfulPlaces != null) return _lastSuccessfulPlaces!;

    try {
      final preferences = await SharedPreferences.getInstance();
      final cachedJson = preferences.getString(_placesCacheKey);
      if (cachedJson == null) return const [];

      final decoded = jsonDecode(cachedJson);
      if (decoded is! List<dynamic>) {
        throw const FormatException('El caché de lugares no es una lista.');
      }

      final places = <Place>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;

        final latitude = item['latitude'];
        final longitude = item['longitude'];
        final id = item['id'];
        final name = item['name'];
        if (latitude is! num ||
            longitude is! num ||
            id is! String ||
            name is! String) {
          continue;
        }

        final categoryName = item['category'];
        final category = PlaceCategory.values.firstWhere(
          (value) => value.name == categoryName,
          orElse: () => PlaceCategory.all,
        );
        final municipality = item['municipality'];
        final location = LatLng(latitude.toDouble(), longitude.toDouble());

        places.add(
          Place(
            id: id,
            name: name,
            category: category,
            location: location,
            municipality: municipality is String ? municipality : null,
          ),
        );
      }

      if (places.isEmpty) return const [];
      _lastSuccessfulPlaces = List.unmodifiable(places);
      return _lastSuccessfulPlaces!;
    } on Exception catch (error) {
      debugPrint('No se pudo leer el caché de lugares: $error');
      return const [];
    }
  }

  static Future<void> _saveCachedPlaces(List<Place> places) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final cacheSaved = await preferences.setString(
        _placesCacheKey,
        jsonEncode(
          places
              .map(
                (place) => {
                  'id': place.id,
                  'name': place.name,
                  'category': place.category.name,
                  'latitude': place.location.latitude,
                  'longitude': place.location.longitude,
                  'municipality': place.municipality,
                },
              )
              .toList(),
        ),
      );
      if (!cacheSaved) {
        debugPrint('No se pudo guardar el caché de lugares.');
      }
    } on Exception catch (error) {
      debugPrint('No se pudo guardar el caché de lugares: $error');
    }
  }

  static List<Place> getFallbackPlaces() {
    return const [
      Place(
        id: 'fb-1',
        name: 'Zócalo de Tlaxcala',
        category: PlaceCategory.park,
        location: LatLng(19.3182, -98.2396),
        municipality: 'Tlaxcala',
        isFavorite: true,
      ),
      Place(
        id: 'fb-2',
        name: 'Museo de Arte de Tlaxcala (MAT)',
        category: PlaceCategory.museum,
        location: LatLng(19.3186, -98.2385),
        municipality: 'Tlaxcala',
      ),
      Place(
        id: 'fb-3',
        name: 'Basílica de Nuestra Señora de Ocotlán',
        category: PlaceCategory.church,
        location: LatLng(19.3250, -98.2300),
        municipality: 'Tlaxcala',
        isFavorite: true,
      ),
      Place(
        id: 'fb-4',
        name: 'Ex Convento de San Francisco',
        category: PlaceCategory.church,
        location: LatLng(19.3140, -98.2360),
        municipality: 'Tlaxcala',
      ),
      Place(
        id: 'fb-5',
        name: 'Parque Nacional La Malinche',
        category: PlaceCategory.park,
        location: LatLng(19.2300, -98.3000),
        municipality: 'Teolocholco',
      ),
    ];
  }
}
