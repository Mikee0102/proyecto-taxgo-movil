import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/filter_option.dart';
import '../../models/place.dart';
import '../../services/places_service.dart';
import '../../styles/app_colors.dart';
import '../../widgets/filters.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/map_search_bar.dart';
import '../../widgets/place_detail_card.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.onSignOut});

  final VoidCallback? onSignOut;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final Set<String> _favoritos = {};
  final Connectivity _connectivity = Connectivity();

  LatLng? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isLoadingPlaces = true;
  bool _mapReady = false;
  bool? _hasNetworkConnection;
  int? _refreshPointer;
  double? _refreshStartY;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  PlaceCategory _activeCategory = PlaceCategory.all;
  String _searchQuery = '';
  Place? _selectedPlace;

  List<Place> _allPlaces = [];

  @override
  void initState() {
    super.initState();
    _allPlaces = PlacesService.getFallbackPlaces();
    _loadPlacesFromOverpass();
    _cargarFavoritos();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChanged,
    );
    _checkConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (!mounted) return;
      _updateConnectivity(results, notify: false);
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo comprobar la conexión: ${error.message}'),
        ),
      );
    }
  }

  void _handleConnectivityChanged(List<ConnectivityResult> results) {
    _updateConnectivity(results);
  }

  void _updateConnectivity(
    List<ConnectivityResult> results, {
    bool notify = true,
  }) {
    final isConnected = results.any(
      (result) => result != ConnectivityResult.none,
    );
    final previous = _hasNetworkConnection;
    if (previous == isConnected) return;

    setState(() => _hasNetworkConnection = isConnected);

    if (!notify || previous == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            isConnected
                ? 'Conexión restablecida.'
                : 'Sin conexión. El mapa puede no cargarse.',
          ),
        ),
      );
  }

  Future<void> _loadPlacesFromOverpass() async {
    setState(() {
      _isLoadingPlaces = true;
    });

    final places = await PlacesService.fetchPlacesFromOverpass();

    if (!mounted) return;

    setState(() {
      _allPlaces = places;
      _isLoadingPlaces = false;
    });
  }

  void _handleRefreshPointerDown(PointerDownEvent event) {
    if (event.position.dy <= 40) {
      _refreshPointer = event.pointer;
      _refreshStartY = event.position.dy;
    }
  }

  void _handleRefreshPointerUp(PointerUpEvent event) {
    if (_refreshPointer != event.pointer) return;

    final shouldRefresh =
        event.position.dy - (_refreshStartY ?? event.position.dy) >= 100;
    _refreshPointer = null;
    _refreshStartY = null;

    if (shouldRefresh && !_isLoadingPlaces) {
      _refreshMap();
    }
  }

  void _handleRefreshPointerCancel(PointerCancelEvent event) {
    if (_refreshPointer != event.pointer) return;
    _refreshPointer = null;
    _refreshStartY = null;
  }

  Future<void> _refreshMap() async {
    await Future.wait<void>([_loadPlacesFromOverpass(), _cargarFavoritos()]);
  }

  String _normalizeText(String text) {
    const accents = 'áéíóúüñÁÉÍÓÚÜÑ';
    const plain = 'aeiouunAEIOUUN';
    var normalized = text.toLowerCase().trim();
    for (var i = 0; i < accents.length; i++) {
      normalized = normalized.replaceAll(accents[i], plain[i]);
    }
    return normalized;
  }

  String _categoryLabel(PlaceCategory category) {
    for (final opt in filterOptions) {
      if (opt.id == category) return opt.label;
    }
    return '';
  }

  List<Place> get _filteredPlaces {
    final normalizedQuery = _normalizeText(_searchQuery);

    return _allPlaces.where((place) {
      final matchesCategory = switch (_activeCategory) {
        PlaceCategory.all => true,
        PlaceCategory.favorites => _favoritos.contains(place.id),
        _ => place.category == _activeCategory,
      };

      if (!matchesCategory) return false;
      if (normalizedQuery.isEmpty) return true;

      final name = _normalizeText(place.name);
      final municipality = _normalizeText(place.resolvedMunicipality);
      final category = _normalizeText(_categoryLabel(place.category));

      return name.contains(normalizedQuery) ||
          municipality.contains(normalizedQuery) ||
          category.contains(normalizedQuery);
    }).toList();
  }

  Future<void> _cargarFavoritos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      if (!mounted) return;

      setState(() {
        _favoritos
          ..clear()
          ..addAll(snapshot.docs.map((document) => document.id));
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron cargar los lugares favoritos: $error'),
        ),
      );
    }
  }

  Future<void> _toggleFavorito(Place place) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para guardar favoritos.')),
      );
      return;
    }

    final referencia = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(place.id);
    final esFavorito = _favoritos.contains(place.id);

    try {
      if (esFavorito) {
        await referencia.delete();
      } else {
        await referencia.set({
          'type': 'place',
          'name': place.name,
          'category': place.category.name,
          'latitude': place.location.latitude,
          'longitude': place.location.longitude,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      setState(() {
        if (esFavorito) {
          _favoritos.remove(place.id);
        } else {
          _favoritos.add(place.id);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esFavorito
                ? '${place.name} se quitó de lugares favoritos'
                : '${place.name} se agregó a lugares favoritos',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar el lugar favorito: $error'),
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_isLoadingLocation) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'La ubicación está desactivada. Actívala en los ajustes del dispositivo.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();

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
        _isLoadingLocation = false;
      });

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
        _isLoadingLocation = false;
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

  void _animatedMapMove(LatLng destination, double destinationZoom) {
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

    final zoomTween = Tween<double>(begin: camera.zoom, end: destinationZoom);

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
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
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
  Widget build(BuildContext context) {
    final List<Place> currentPlaces = _filteredPlaces;
    final selectedPlace = _selectedPlace;
    final double topOffset = MediaQuery.of(context).padding.top + 12;

    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handleRefreshPointerDown,
        onPointerUp: _handleRefreshPointerUp,
        onPointerCancel: _handleRefreshPointerCancel,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(19.3182, -98.2375),
                initialZoom: 12.0,
                onMapReady: () {
                  _mapReady = true;

                  if (_currentPosition != null) {
                    _animatedMapMove(_currentPosition!, 16.0);
                  }
                },
                onTap: (_, _) {
                  if (_selectedPlace != null) {
                    setState(() {
                      _selectedPlace = null;
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.tlaxgomobil',
                ),

                MarkerLayer(
                  markers: currentPlaces.map((place) {
                    final isSelected = _selectedPlace?.id == place.id;
                    return Marker(
                      point: place.location,
                      width: 44,
                      height: 50,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPlace = place;
                          });
                        },
                        child: Icon(
                          Icons.location_on,
                          color: isSelected
                              ? AppColors.accentLight
                              : AppColors.accent,
                          size: isSelected ? 46 : 40,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentPosition!,
                        width: 50,
                        height: 50,
                        child: Icon(
                          Icons.my_location,
                          color: AppColors.accent,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Barra de búsqueda, filtros y estado de carga de Overpass.
            Positioned(
              top: topOffset,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: MapSearchBar(
                          value: _searchQuery,
                          onChanged: (newValue) {
                            setState(() {
                              _searchQuery = newValue;
                            });
                          },
                        ),
                      ),
                      if (widget.onSignOut != null) ...[
                        const SizedBox(width: 8),
                        Material(
                          color: AppColors.headerGlass,
                          borderRadius: BorderRadius.circular(15),
                          child: IconButton(
                            tooltip: 'Cerrar sesión',
                            onPressed: widget.onSignOut,
                            color: AppColors.onHeader,
                            icon: const Icon(Icons.logout_rounded),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Filters(
                    activeCategory: _activeCategory,
                    onCategoryChange: (newCategory) {
                      setState(() {
                        _activeCategory = newCategory;
                        _selectedPlace = null;
                      });
                    },
                  ),
                  if (_hasNetworkConnection == false)
                    GlassSurface(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      tintColor: AppColors.headerGlass,
                      borderColor: AppColors.accentLight.withValues(alpha: 0.3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            color: AppColors.accentLight,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sin conexión. El mapa puede no cargarse.',
                            style: TextStyle(
                              color: AppColors.onHeader,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_isLoadingPlaces)
                    GlassSurface(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      tintColor: AppColors.headerGlass,
                      borderColor: AppColors.accentLight.withValues(alpha: 0.3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accent,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Cargando atractivos de Tlaxcala...',
                            style: TextStyle(
                              color: AppColors.onHeader,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Tarjeta de detalle y botón "Cómo llegar" al tocar un puntito.
            PlaceDetailCard(
              place: selectedPlace,
              isFavorite:
                  selectedPlace != null &&
                  _favoritos.contains(selectedPlace.id),
              onToggleFavorite: () {
                if (selectedPlace != null) {
                  _toggleFavorito(selectedPlace);
                }
              },
              onClose: () {
                setState(() {
                  _selectedPlace = null;
                });
              },
            ),

            if (!_isLoadingPlaces && currentPlaces.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: GlassSurface(
                    padding: const EdgeInsets.all(20),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 42,
                          color: AppColors.accentLight,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No hay resultados',
                          style: TextStyle(
                            color: AppColors.textStrong,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No se encontraron lugares con ese filtro o municipio.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (_isLoadingLocation)
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
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'refreshMap',
            onPressed: _isLoadingPlaces ? null : _refreshMap,
            tooltip: 'Actualizar mapa',
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.navy,
            child: _isLoadingPlaces
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.navy,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'currentLocation',
            onPressed: _getCurrentLocation,
            tooltip: 'Mi ubicación actual',
            child: const Icon(Icons.navigation),
          ),
        ],
      ),
    );
  }
}
