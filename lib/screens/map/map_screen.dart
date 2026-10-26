
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/filter_option.dart';
import '../../widgets/filters.dart';

// Modelo local de atractivos turísticos.
class Place {
  final String id;
  final String name;
  final PlaceCategory category;
  final LatLng location;
  final bool isFavorite;

  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    this.isFavorite = false,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  LatLng? _currentPosition;
  bool _isLoading = false;
  bool _mapReady = false;

  PlaceCategory _activeCategory = PlaceCategory.all;

  // Atractivos turísticos de prueba.
  final List<Place> _allPlaces = const [
    Place(
      id: '1',
      name: 'Museo Regional de Tlaxcala',
      category: PlaceCategory.museum,
      location: LatLng(19.3182, -98.2375),
    ),
    Place(
      id: '2',
      name: 'Museo de Arte de Tlaxcala (MAT)',
      category: PlaceCategory.museum,
      location: LatLng(19.3220, -98.2450),
    ),
    Place(
      id: '3',
      name: 'Basílica de Nuestra Señora de Ocotlán',
      category: PlaceCategory.church,
      location: LatLng(19.3250, -98.2300),
      isFavorite: true,
    ),
    Place(
      id: '4',
      name: 'Ex Convento de San Francisco',
      category: PlaceCategory.church,
      location: LatLng(19.3140, -98.2360),
    ),
    Place(
      id: '5',
      name: 'Parque Nacional La Malinche',
      category: PlaceCategory.park,
      location: LatLng(19.2300, -98.3000),
    ),
    Place(
      id: '6',
      name: 'Zócalo de Tlaxcala',
      category: PlaceCategory.park,
      location: LatLng(19.3175, -98.2381),
      isFavorite: true,
    ),
    Place(
      id: '7',
      name: 'Mirador de Ocotlán',
      category: PlaceCategory.viewpoint,
      location: LatLng(19.3270, -98.2280),
    ),
    Place(
      id: '8',
      name: 'Restaurante Los Portales',
      category: PlaceCategory.restaurant,
      location: LatLng(19.3150, -98.2400),
      isFavorite: true,
    ),
    Place(
      id: '9',
      name: 'Hotel San Francisco Tlaxcala',
      category: PlaceCategory.hotel,
      location: LatLng(19.3160, -98.2350),
    ),
  ];

  List<Place> get _filteredPlaces {
    if (_activeCategory == PlaceCategory.all) {
      return _allPlaces;
    }

    if (_activeCategory == PlaceCategory.favorites) {
      return _allPlaces.where((place) => place.isFavorite).toList();
    }

    return _allPlaces
        .where((place) => place.category == _activeCategory)
        .toList();
  }

  Future<void> _getCurrentLocation() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Comprobar si el servicio de ubicación está activado.
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'La ubicación está desactivada. Actívala en los ajustes del dispositivo.',
        );
      }

      // Comprobar permisos.
      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'El permiso está denegado permanentemente. Actívalo en los ajustes de la aplicación.',
        );
      }

      // Obtener la ubicación actual.
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );

      final LatLng currentLatLng = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = currentLatLng;
        _isLoading = false;
      });

      // Centrar el mapa cuando esté listo.
      if (_mapReady) {
        _animatedMapMove(currentLatLng, 16.0);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ubicación obtenida: '
            '${position.latitude.toStringAsFixed(6)}, '
            '${position.longitude.toStringAsFixed(6)}',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('ERROR DE UBICACIÓN: $e');
      debugPrint('DETALLES: $stackTrace');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de ubicación: $e'),
          duration: const Duration(seconds: 8),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _animatedMapMove(
    LatLng destination,
    double destinationZoom,
  ) {
    if (!_mapReady) return;

    final camera = _mapController.camera;

    final latTween = Tween<double>(
      begin: camera.center.latitude,
      end: destination.latitude,
    );

    final lngTween = Tween<double>(
      begin: camera.center.longitude,
      end: destination.longitude,
    );

    final zoomTween = Tween<double>(
      begin: camera.zoom,
      end: destinationZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    controller.addListener(() {
      if (!mounted || !_mapReady) return;

      _mapController.move(
        LatLng(
          latTween.evaluate(animation),
          lngTween.evaluate(animation),
        ),
        zoomTween.evaluate(animation),
      );
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Place> currentPlaces = _filteredPlaces;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(19.3182, -98.2375),
              initialZoom: 13.0,
              onMapReady: () {
                _mapReady = true;

                if (_currentPosition != null) {
                  _animatedMapMove(_currentPosition!, 16.0);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.tlaxgomobil',
              ),

              // Marcadores turísticos según el filtro seleccionado.
              MarkerLayer(
                markers: currentPlaces.map((place) {
                  return Marker(
                    point: place.location,
                    width: 44,
                    height: 50,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${place.name} '
                              '(Favorito: ${place.isFavorite ? "Sí" : "No"})',
                            ),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 40,
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Marcador de ubicación actual.
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blueAccent,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Filtros turísticos.
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 0,
            right: 0,
            child: Filters(
              activeCategory: _activeCategory,
              onCategoryChange: (newCategory) {
                setState(() {
                  _activeCategory = newCategory;
                });
              },
            ),
          ),

          // Mensaje cuando no existen resultados.
          if (currentPlaces.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: const Color(0xE6020617),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF1E293B),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No hay resultados',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'No se encontraron lugares en esta categoría.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Indicador de carga.
          if (_isLoading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Obteniendo ubicación...'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        tooltip: 'Mi ubicación actual',
        child: const Icon(Icons.navigation),
      ),
    );
  }
}
