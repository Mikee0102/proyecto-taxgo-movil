import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/biometric_service.dart';
import '../../styles/app_colors.dart';
import '../../widgets/glass_surface.dart';

class ItinerariosScreen extends StatefulWidget {
  const ItinerariosScreen({
  super.key,
  this.isAdmin = false,
  this.isActive = true,
  this.onSignOut,
});

  final bool isAdmin;
  final bool isActive;
  final VoidCallback? onSignOut;

  @override
  State<ItinerariosScreen> createState() => _ItinerariosScreenState();
}

class _ItinerariosScreenState extends State<ItinerariosScreen> {
  bool _isAuthorized = false;
  bool _isChecking = false;
  int _securityCheckGeneration = 0;
  bool _mostrarSoloMeGusta = false;
  final Map<String, Map<String, bool>> _meGustaPendiente = {};
  late final Stream<QuerySnapshot> _streamItinerarios = FirebaseFirestore
      .instance
      .collection('itineraries')
      .snapshots();
  final Map<String, Stream<QuerySnapshot<Map<String, dynamic>>>>
  _streamsMeGusta = {};

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _checkSecurity();
    }
  }

  @override
  void didUpdateWidget(covariant ItinerariosScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive) return;

    if (widget.isActive) {
      _checkSecurity();
    } else {
      _securityCheckGeneration++;
      setState(() {
        _isAuthorized = false;
        _isChecking = false;
      });
    }
  }

  Future<void> _checkSecurity() async {
    if (!widget.isActive) return;

    final generation = ++_securityCheckGeneration;
    setState(() => _isChecking = true);

    try {
      final lockEnabled = await BiometricService.isLockEnabled();
      final authenticated =
          !lockEnabled || await BiometricService.authenticate();
      if (!mounted ||
          !widget.isActive ||
          generation != _securityCheckGeneration) {
        return;
      }

      setState(() {
        _isAuthorized = authenticated;
        _isChecking = false;
      });
    } catch (error) {
      if (!mounted ||
          !widget.isActive ||
          generation != _securityCheckGeneration) {
        return;
      }

      setState(() {
        _isAuthorized = false;
        _isChecking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo verificar el bloqueo: $error')),
      );
    }
  }

  // Conexión con la colección global utilizada por Tlax.Go WEB.
  Stream<QuerySnapshot<Map<String, dynamic>>> _obtenerMeGusta(String uid) {
    return _streamsMeGusta.putIfAbsent(
      uid,
      () => FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .where('type', isEqualTo: 'itinerary')
          .snapshots(),
    );
  }

  void _toggleMeGusta({
    required String itineraryId,
    required String title,
    required bool isLiked,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para guardar me gusta.')),
      );
      return;
    }

    final favoriteRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc('itinerary_$itineraryId');

    final shouldLike = !isLiked;
    final write = shouldLike
        ? favoriteRef.set({
            'type': 'itinerary',
            'itineraryId': itineraryId,
            'title': title,
            'createdAt': FieldValue.serverTimestamp(),
          })
        : favoriteRef.delete();

    setState(() {
      (_meGustaPendiente[user.uid] ??= {})[itineraryId] = shouldLike;
    });
    unawaited(_confirmarMeGusta(write, user.uid, itineraryId, shouldLike));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shouldLike
              ? '"$title" se guardó en tus me gusta.'
              : 'Se quitó "$title" de tus me gusta.',
        ),
      ),
    );
  }

  Future<void> _confirmarMeGusta(
    Future<void> write,
    String uid,
    String itineraryId,
    bool shouldLike,
  ) async {
    try {
      await write;
      if (!mounted) return;
      if (_meGustaPendiente[uid]?[itineraryId] == shouldLike) {
        setState(() => _meGustaPendiente[uid]?.remove(itineraryId));
      }
    } catch (error) {
      if (!mounted) {
        debugPrint('No se pudo sincronizar el me gusta: $error');
        return;
      }

      setState(() {
        if (_meGustaPendiente[uid]?[itineraryId] == shouldLike) {
          _meGustaPendiente[uid]?.remove(itineraryId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el me gusta: $error')),
      );
    }
  }

  Future<void> _refreshItinerarios(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('itineraries').get();
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron actualizar los itinerarios: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const SizedBox.shrink();
    }

    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthorized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Itinerario Protegido')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 72, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Este itinerario está protegido',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Usa tu huella digital o el PIN de tu dispositivo para acceder.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _checkSecurity,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Desbloquear'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Itinerarios',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.headerGlass,
        foregroundColor: AppColors.onHeader,
        elevation: 0,
        actions: [
          if (widget.isAdmin)
            IconButton(
              tooltip: 'Crear itinerario',
              onPressed: () => _abrirFormulario(context),
              icon: const Icon(Icons.add_rounded),
            ),
          if (widget.onSignOut != null)
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: widget.onSignOut,
              icon: const Icon(Icons.logout_rounded),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshItinerarios(context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIntroBanner(),
              const SizedBox(height: 26),
              Text(
                'Recorridos para inspirarte',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Ideas para descubrir Tlaxcala a tu ritmo.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: !_mostrarSoloMeGusta,
                    onSelected: (_) {
                      setState(() => _mostrarSoloMeGusta = false);
                    },
                    selectedColor: AppColors.accent.withValues(alpha: 0.18),
                    side: BorderSide(
                      color: !_mostrarSoloMeGusta
                          ? AppColors.accent
                          : AppColors.border,
                      width: !_mostrarSoloMeGusta ? 1.5 : 1,
                    ),
                    labelStyle: TextStyle(
                      color: _mostrarSoloMeGusta
                          ? AppColors.muted
                          : AppColors.textStrong,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  ChoiceChip(
                    avatar: Icon(
                      _mostrarSoloMeGusta
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 17,
                      color: _mostrarSoloMeGusta
                          ? AppColors.accentLight
                          : AppColors.muted,
                    ),
                    label: const Text('Mis me gusta'),
                    selected: _mostrarSoloMeGusta,
                    onSelected: (selected) {
                      if (FirebaseAuth.instance.currentUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Inicia sesión para ver tus itinerarios favoritos.',
                            ),
                          ),
                        );
                        return;
                      }
                      setState(() => _mostrarSoloMeGusta = selected);
                    },
                    selectedColor: AppColors.accent.withValues(alpha: 0.18),
                    side: BorderSide(
                      color: _mostrarSoloMeGusta
                          ? AppColors.accent
                          : AppColors.border,
                      width: _mostrarSoloMeGusta ? 1.5 : 1,
                    ),
                    labelStyle: TextStyle(
                      color: _mostrarSoloMeGusta
                          ? AppColors.textStrong
                          : AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Escucha los cambios de Firebase en tiempo real.
              StreamBuilder<QuerySnapshot>(
                stream: _streamItinerarios,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _mensaje(
                      'No se pudieron cargar los itinerarios. '
                      'Verifica tu conexión y los permisos de Firebase.',
                      Icons.error_outline_rounded,
                    );
                  }

                  final documentos = snapshot.data?.docs ?? [];

                  if (documentos.isEmpty) {
                    return _mensaje(
                      _mostrarSoloMeGusta
                          ? 'Todavía no has guardado itinerarios con me gusta.'
                          : 'Todavía no hay itinerarios publicados. '
                                'Cuando se publique uno desde la WEB, aparecerá aquí.',
                      Icons.map_outlined,
                    );
                  }

                  Widget buildCards(Set<String> likedIds) {
                    final documentosVisibles = _mostrarSoloMeGusta
                        ? documentos
                              .where(
                                (documento) => likedIds.contains(documento.id),
                              )
                              .toList()
                        : documentos;

                    if (documentosVisibles.isEmpty) {
                      return _mensaje(
                        'Todavía no has guardado itinerarios con me gusta.',
                        Icons.favorite_border_rounded,
                      );
                    }

                    return Column(
                      children: documentosVisibles.map((documento) {
                        final rawData = documento.data();
                        if (rawData is! Map) {
                          return const SizedBox.shrink();
                        }

                        final itinerario = Map<String, dynamic>.from(rawData);
                        final isLiked = likedIds.contains(documento.id);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildItinerarioCard(
                            context,
                            documento.id,
                            itinerario,
                            isLiked: isLiked,
                          ),
                        );
                      }).toList(),
                    );
                  }

                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return buildCards(<String>{});

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _obtenerMeGusta(user.uid),
                    builder: (context, meGustaSnapshot) {
                      if (meGustaSnapshot.hasError) {
                        return _mensaje(
                          'No se pudieron cargar tus itinerarios favoritos.',
                          Icons.error_outline_rounded,
                        );
                      }
                      if (meGustaSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final likedIds =
                          meGustaSnapshot.data?.docs
                              .map(
                                (document) =>
                                    document.data()['itineraryId']?.toString(),
                              )
                              .whereType<String>()
                              .toSet() ??
                          <String>{};

                      final pendingLikes =
                          _meGustaPendiente[user.uid] ?? <String, bool>{};
                      for (final entry in pendingLikes.entries) {
                        if (entry.value) {
                          likedIds.add(entry.key);
                        } else {
                          likedIds.remove(entry.key);
                        }
                      }

                      return buildCards(likedIds);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirFormulario(BuildContext context) async {
    final creado = await showDialog<bool>(
      context: context,
      builder: (_) => _CrearItinerarioDialog(
        onSyncError: (error) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudo sincronizar el itinerario: $error'),
            ),
          );
        },
      ),
    );

    if (creado == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Itinerario agregado. Si estás sin conexión, se sincronizará al recuperarla.',
          ),
        ),
      );
    }
  }

  Widget _buildIntroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.itineraryTop, AppColors.itineraryBottom],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.heroBorder),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -12,
            child: Icon(
              Icons.route_rounded,
              size: 112,
              color: AppColors.accent.withValues(alpha: 0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'VIAJES CON HISTORIA',
                  style: TextStyle(
                    color: AppColors.itineraryAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 17),
              Text(
                'Tu próxima aventura\nempieza aquí',
                style: TextStyle(
                  color: AppColors.onHero,
                  fontSize: 25,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'Recorre la cultura, naturaleza y tradición de Tlaxcala.',
                style: TextStyle(
                  color: AppColors.itineraryText,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mensaje(String mensaje, IconData icono) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icono, size: 42, color: AppColors.accentDark),
          const SizedBox(height: 12),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildItinerarioCard(
    BuildContext context,
    String itineraryId,
    Map<String, dynamic> itinerario, {
    required bool isLiked,
  }) {
    final nombre = itinerario['title']?.toString() ?? 'Sin título';

    final descripcion =
        itinerario['description']?.toString() ??
        'Descubre este recorrido turístico de Tlaxcala.';

    final dias = itinerario['days'] is List ? itinerario['days'] as List : [];

    int minutosTotales = 0;
    final lugares = <String>[];

    for (final dia in dias) {
      if (dia is! Map) continue;

      final actividades = dia['activities'];

      if (actividades is! List) continue;

      for (final actividad in actividades) {
        if (actividad is! Map) continue;

        final minutos = actividad['duration_minutes'];

        if (minutos is num) {
          minutosTotales += minutos.toInt();
        }

        final titulo = actividad['title']?.toString().trim() ?? '';

        if (titulo.isNotEmpty && !lugares.contains(titulo)) {
          lugares.add(titulo);
        }
      }
    }

    final duracion = minutosTotales > 0
        ? _formatearDuracion(minutosTotales)
        : '${dias.length} ${dias.length == 1 ? 'día' : 'días'}';

    final lugaresTexto = lugares.isEmpty
        ? 'Consulta las actividades de este itinerario.'
        : lugares.join(', ');

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => _mostrarDetalles(context, itinerario),
        borderRadius: BorderRadius.circular(22),
        child: GlassSurface(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.itineraryTop, AppColors.itineraryBottom],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.onHero.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.map_rounded,
                        color: AppColors.onHero,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dias.isEmpty
                                ? 'RECORRIDO RECOMENDADO'
                                : '${dias.length} ${dias.length == 1 ? 'DÍA' : 'DÍAS'} DE RECORRIDO',
                            style: TextStyle(
                              color: AppColors.onHero.withValues(alpha: 0.72),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.onHero,
                              fontSize: 18,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: isLiked
                          ? 'Quitar de mis me gusta'
                          : 'Agregar a mis me gusta',
                      onPressed: () => _toggleMeGusta(
                        itineraryId: itineraryId,
                        title: nombre,
                        isLiked: isLiked,
                      ),
                      style: IconButton.styleFrom(
                        foregroundColor: isLiked
                            ? AppColors.accentLight
                            : AppColors.onHero,
                        backgroundColor: isLiked
                            ? AppColors.accent.withValues(alpha: 0.16)
                            : AppColors.onHero.withValues(alpha: 0.12),
                        shape: const CircleBorder(),
                      ),
                      icon: Icon(
                        isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      descripcion,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color: AppColors.accentDark,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Duración aproximada: $duracion',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textStrong,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Lugares del recorrido',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      lugaresTexto,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Toca para ver detalles',
                          style: TextStyle(
                            color: AppColors.accentDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: AppColors.accentDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarDetalles(
    BuildContext context,
    Map<String, dynamic> itinerario,
  ) async {
    final dias = itinerario['days'] is List ? itinerario['days'] as List : [];
    final nombre = itinerario['title']?.toString() ?? 'Itinerario';
    final descripcion =
        itinerario['description']?.toString() ??
        'Descubre este recorrido turístico de Tlaxcala.';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.itineraryTop, AppColors.itineraryBottom],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.36),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Icon(
                          Icons.route_rounded,
                          color: AppColors.itineraryAccent,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dias.isEmpty
                                  ? 'RECORRIDO RECOMENDADO'
                                  : '${dias.length} ${dias.length == 1 ? 'DÍA' : 'DÍAS'} DE RECORRIDO',
                              style: TextStyle(
                                color: AppColors.itineraryAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nombre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.onHero,
                                fontSize: 20,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Text(
                      descripcion,
                      style: TextStyle(
                        color: AppColors.itineraryText,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Icon(
                        Icons.event_note_rounded,
                        color: AppColors.itineraryAccent,
                        size: 19,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Actividades del recorrido',
                        style: TextStyle(
                          color: AppColors.onHero,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (dias.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.heroPanel,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.34),
                        ),
                      ),
                      child: Text(
                        'Este itinerario aún no tiene actividades registradas.',
                        style: TextStyle(
                          color: AppColors.itineraryText,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    )
                  else
                    ...dias.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildDetalleDia(entry.value, entry.key),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetalleDia(dynamic rawDia, int index) {
    if (rawDia is! Map) return const SizedBox.shrink();

    final tituloDia = rawDia['title']?.toString().trim();
    final nombreDia = tituloDia == null || tituloDia.isEmpty
        ? 'Día ${index + 1}'
        : tituloDia;
    final actividades = rawDia['activities'] is List
        ? rawDia['activities'] as List
        : const [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.heroPanel,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.itineraryAccent,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  nombreDia,
                  style: TextStyle(
                    color: AppColors.onHero,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (actividades.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Sin actividades registradas.',
                style: TextStyle(color: AppColors.itineraryText, fontSize: 12),
              ),
            )
          else
            ...actividades.asMap().entries.map((entry) {
              final actividad = entry.value;
              if (actividad is! Map) return const SizedBox.shrink();

              final titulo =
                  actividad['title']?.toString().trim().isNotEmpty == true
                  ? actividad['title'].toString().trim()
                  : 'Actividad ${entry.key + 1}';
              final detalle = actividad['description']?.toString().trim();
              final minutos = actividad['duration_minutes'];

              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 25,
                      height: 25,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          color: AppColors.itineraryAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: TextStyle(
                              color: AppColors.onHero,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (detalle != null && detalle.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                detalle,
                                style: TextStyle(
                                  color: AppColors.itineraryText,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          if (minutos is num && minutos > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.18,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Duración: ${_formatearDuracion(minutos.toInt())}',
                                  style: TextStyle(
                                    color: AppColors.itineraryAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatearDuracion(int minutos) {
    final horas = minutos ~/ 60;
    final restantes = minutos % 60;

    if (horas == 0) return '$restantes minutos';
    if (restantes == 0) {
      return '$horas ${horas == 1 ? 'hora' : 'horas'}';
    }

    return '$horas h $restantes min';
  }
}

class _CrearItinerarioDialog extends StatefulWidget {
  const _CrearItinerarioDialog({required this.onSyncError});

  final ValueChanged<Object> onSyncError;

  @override
  State<_CrearItinerarioDialog> createState() => _CrearItinerarioDialogState();
}

class _CrearItinerarioDialogState extends State<_CrearItinerarioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _activitiesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _activitiesController.dispose();
    super.dispose();
  }

  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para publicar.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final activities = _activitiesController.text
        .split('\n')
        .map((activity) => activity.trim())
        .where((activity) => activity.isNotEmpty)
        .map((activity) => {'title': activity, 'duration_minutes': 60})
        .toList();

    try {
      final write = FirebaseFirestore.instance
          .collection('itineraries')
          .doc()
          .set({
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'days': activities.isEmpty
                ? <Map<String, dynamic>>[]
                : [
                    {'title': 'Día 1', 'activities': activities},
                  ],
            'createdBy': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      Navigator.of(context).pop(true);
      unawaited(_confirmarPublicacion(write));
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo publicar el itinerario: $error')),
      );
    }
  }

  Future<void> _confirmarPublicacion(Future<void> write) async {
    try {
      await write;
    } catch (error) {
      widget.onSyncError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear itinerario'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Título'),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Escribe un título.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Escribe una descripción.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _activitiesController,
                  decoration: const InputDecoration(
                    labelText: 'Actividades o lugares',
                    hintText: 'Un lugar por línea (opcional)',
                    helperText: 'Cada actividad se estima en 60 minutos.',
                    alignLabelWithHint: true,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _publicar,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Publicar'),
        ),
      ],
    );
  }
}
