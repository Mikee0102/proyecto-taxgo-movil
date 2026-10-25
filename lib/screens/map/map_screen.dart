import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/filter_option.dart';
import '../../widgets/filters.dart';

// Modelo local de Atractivos adaptado a las categorías
class Place {
  final String id;
  final String name;
  final PlaceCategory category;
  final LatLng location;
  final bool isFavorite;

  Place({
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

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  bool _isLoading = false;

  // Categoría seleccionada por defecto: 'Todos'
  PlaceCategory _activeCategory = PlaceCategory.all;

  // Lista completa de atractivos turísticos en Tlaxcala con variedad para cada filtro
  final List<Place> _allPlaces = [
    Place(id: '1', name: 'Museo Regional de Tlaxcala', category: PlaceCategory.museum, location: const LatLng(19.3182, -98.2375)),
    Place(id: '2', name: 'Museo de Arte de Tlaxcala (MAT)', category: PlaceCategory.museum, location: const LatLng(19.3220, -98.2450)),
    Place(id: '3', name: 'Basílica de Nuestra Señora de Ocotlán', category: PlaceCategory.church, location: const LatLng(19.3250, -98.2300), isFavorite: true),
    Place(id: '4', name: 'Ex Convento de San Francisco', category: PlaceCategory.church, location: const LatLng(19.3140, -98.2360)),
    Place(id: '5', name: 'Parque Nacional La Malinche', category: PlaceCategory.park, location: const LatLng(19.2300, -98.3000)),
    Place(id: '6', name: 'Zócalo de Tlaxcala', category: PlaceCategory.park, location: const LatLng(19.3175, -98.2381), isFavorite: true),
    Place(id: '7', name: 'Mirador de Ocotlán', category: PlaceCategory.viewpoint, location: const LatLng(19.3270, -98.2280)),
    Place(id: '8', name: 'Restaurante Los Portales', category: PlaceCategory.restaurant, location: const LatLng(19.3150, -98.2400), isFavorite: true),
    Place(id: '9', name: 'Hotel San Francisco Tlaxcala', category: PlaceCategory.hotel, location: const LatLng(19.3160, -98.2350)),
  ];

  // Filtrado reactivo de los lugares según la opción seleccionada
  List<Place> get _filteredPlaces {
    if (_activeCategory == PlaceCategory.all) {
      return _allPlaces;
    }
    if (_activeCategory == PlaceCategory.favorites) {
      return _allPlaces.where((p) => p.isFavorite).toList();
    }
    return _allPlaces.where((p) => p.category == _activeCategory).toList();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, enciende el GPS / ubicación del dispositivo.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permisos de ubicación denegados.')),
          );
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permisos denegados permanentemente en ajustes.')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado al buscar la ubicación.');
        },
      );

      LatLng currentLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = currentLatLng;
        _isLoading = false;
      });

      _animatedMapMove(currentLatLng, 16.0);
      
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al obtener ubicación: Verifica tu GPS o ubicación simulada.')),
      );
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final camera = _mapController.camera;
    final latTween = Tween<double>(begin: camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    final controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    final animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final currentPlaces = _filteredPlaces;

    return Scaffold(
      body: Stack(
        children: [
          // Mapa principal (FlutterMap)
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(19.3182, -98.2375), // Centro de Tlaxcala
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.tlaxgomobil',
              ),
              
              // Capa de marcadores de los lugares filtrados dinámicamente
              MarkerLayer(
                markers: currentPlaces.map((place) {
                  return Marker(
                    point: place.location,
                    width: 40.0,
                    height: 40.0,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${place.name} (Favorito: ${place.isFavorite ? "Sí" : "No"})'))
                        );
                      },
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 40.0,
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Capa de la ubicación actual del usuario
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 50.0,
                      height: 50.0,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blueAccent,
                        size: 40.0,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Componente de filtrado horizontal adaptado de Web a Móvil
          Positioned(
            top: MediaQuery.of(context).padding.top + 12, // Respeta la barra de estado superior
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

          // Estado vacío si la categoría no tiene elementos (Criterio de aceptación)
          if (currentPlaces.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: const Color(0xE6020617), // Estilo oscuro moderno
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E293B)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.search_off, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'No hay resultados',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'No se encontraron lugares en esta categoría.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          // Indicador de carga de ubicación
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
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