import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../styles/app_colors.dart';

class RutaPrueba {
  final String id;
  final String nombre;
  final String descripcion;
  final String categoria;
  final IconData icono;

  const RutaPrueba({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.icono,
  });
}

class RutasScreen extends StatefulWidget {
  const RutasScreen({super.key});

  @override
  State<RutasScreen> createState() => _RutasScreenState();
}

class _RutasScreenState extends State<RutasScreen> {
  final Set<String> _favoritos = {};
  bool _cargandoFavoritos = true;
  bool _guardandoFavorito = false;

  final List<RutaPrueba> _rutas = const [
    RutaPrueba(
      id: 'ruta_1',
      nombre: 'Centro Histórico de Tlaxcala',
      descripcion:
          'Recorre plazas, edificios históricos y calles tradicionales.',
      categoria: 'Cultural',
      icono: Icons.account_balance,
    ),
    RutaPrueba(
      id: 'ruta_2',
      nombre: 'Santuario de las Luciérnagas',
      descripcion: 'Disfruta de los bosques y de la naturaleza de Tlaxcala.',
      categoria: 'Naturaleza',
      icono: Icons.forest,
    ),
    RutaPrueba(
      id: 'ruta_3',
      nombre: 'Huamantla Tradicional',
      descripcion: 'Conoce sus tradiciones, calles y atractivos turísticos.',
      categoria: 'Cultural',
      icono: Icons.location_city,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _cargarFavoritos();
  }

  Future<void> _cargarFavoritos() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => _cargandoFavoritos = false);
      }
      return;
    }

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
        _cargandoFavoritos = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _cargandoFavoritos = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los favoritos: $error')),
      );
    }
  }

  Future<void> _cambiarFavorito(RutaPrueba ruta) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _guardandoFavorito) return;

    setState(() => _guardandoFavorito = true);

    final favoritoActual = _favoritos.contains(ruta.id);
    final referencia = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(ruta.id);

    try {
      if (favoritoActual) {
        await referencia.delete();
      } else {
        await referencia.set({
          'nombre': ruta.nombre,
          'descripcion': ruta.descripcion,
          'categoria': ruta.categoria,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      setState(() {
        if (favoritoActual) {
          _favoritos.remove(ruta.id);
        } else {
          _favoritos.add(ruta.id);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            favoritoActual
                ? '${ruta.nombre} se quitó de favoritos'
                : '${ruta.nombre} se agregó a favoritos',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el favorito: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _guardandoFavorito = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas turísticas'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.favorite.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.favorite,
                  size: 17,
                ),
                const SizedBox(width: 5),
                Text(
                  '${_rutas.where((ruta) => _favoritos.contains(ruta.id)).length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _cargandoFavoritos
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                _buildIntroBanner(),
                const SizedBox(height: 24),
                const Text(
                  'Rutas para explorar',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Elige una experiencia y guarda tus favoritas.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ..._rutas.map((ruta) {
                  final bool esFavorito = _favoritos.contains(ruta.id);

                  return _buildRutaCard(ruta, esFavorito);
                }),
              ],
            ),
    );
  }

  Widget _buildIntroBanner() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF184B67), AppColors.navy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -20,
            child: Icon(
              Icons.route_rounded,
              size: 118,
              color: Colors.white.withValues(alpha: 0.09),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'RECORRIDOS CON ENCANTO',
                  style: TextStyle(
                    color: AppColors.accentLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 17),
              const Text(
                'Cada ruta tiene\nuna historia',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Descubre Tlaxcala paso a paso.',
                style: TextStyle(color: AppColors.heroText, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRutaCard(RutaPrueba ruta, bool esFavorito) {
    final colors = switch (ruta.categoria) {
      'Naturaleza' => const [Color(0xFF43836A), Color(0xFF183D3B)],
      _ => const [Color(0xFF286984), Color(0xFF102B47)],
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 158,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 12,
                  top: 10,
                  child: Icon(
                    ruta.icono,
                    size: 128,
                    color: Colors.white.withValues(alpha: 0.13),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.first.withValues(alpha: 0.55),
                          colors.last.withValues(alpha: 0.92),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 13,
                  left: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ruta.categoria.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 7,
                  right: 7,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.16),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: esFavorito
                          ? 'Quitar de favoritos'
                          : 'Agregar a favoritos',
                      onPressed: _guardandoFavorito
                          ? null
                          : () => _cambiarFavorito(ruta),
                      icon: Icon(
                        esFavorito
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 17,
                  right: 17,
                  bottom: 15,
                  child: Text(
                    ruta.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 14, 17, 17),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ruta.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
