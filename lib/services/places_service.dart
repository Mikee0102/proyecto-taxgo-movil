import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/filter_option.dart';
import '../models/place.dart';

class PlacesService {
  static const String _tlaxcalaBbox = '19.1000,-98.5000,19.6000,-97.9000';

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
    const query = '''
      [out:json][timeout:25];
      (
        node["tourism"~"museum|viewpoint|hotel|guest_house"]($_tlaxcalaBbox);
        node["amenity"~"place_of_worship|restaurant|cafe"]($_tlaxcalaBbox);
        node["leisure"="park"]($_tlaxcalaBbox);
        way["tourism"~"museum|viewpoint|hotel|guest_house"]($_tlaxcalaBbox);
        way["amenity"~"place_of_worship|restaurant|cafe"]($_tlaxcalaBbox);
        way["leisure"="park"]($_tlaxcalaBbox);
      );
      out center;
    ''';

    final uri = Uri.parse(
      'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        debugPrint(
          'Overpass API respondió con estado: ${response.statusCode}. Usando fallback local.',
        );
        return getFallbackPlaces();
      }

      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final elements = decoded['elements'] as List<dynamic>? ?? [];

      if (elements.isEmpty) return getFallbackPlaces();

      final places = <Place>[];

      for (final raw in elements) {
        if (raw is! Map<String, dynamic>) continue;

        final tags = (raw['tags'] as Map<String, dynamic>?) ?? {};
        final name =
            (tags['name'] ?? tags['official_name'] ?? '').toString().trim();
        if (name.isEmpty) continue;

        final center = raw['center'] as Map<String, dynamic>?;
        final lat = (raw['lat'] ?? center?['lat']) as num?;
        final lon = (raw['lon'] ?? center?['lon']) as num?;
        if (lat == null || lon == null) continue;

        final location = LatLng(lat.toDouble(), lon.toDouble());
        final osmMun = (tags['addr:municipality'] ??
                tags['addr:city'] ??
                tags['addr:town'] ??
                tags['addr:village'] ??
                '')
            .toString()
            .trim();

        places.add(
          Place(
            id: raw['id'].toString(),
            name: name,
            category: _mapOsmTagToCategory(tags),
            location: location,
            municipality: osmMun.isNotEmpty
                ? osmMun
                : resolveClosestMunicipality(location),
          ),
        );
      }

      return places.isEmpty ? getFallbackPlaces() : places;
    } catch (e) {
      debugPrint(
        'Error al conectar con Overpass API. Usando fallback local: $e',
      );
      return getFallbackPlaces();
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