import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../styles/app_colors.dart';

class ItinerariosScreen extends StatelessWidget {
  const ItinerariosScreen({super.key, this.isAdmin = false});

  final bool isAdmin;

  // Conexión con la colección global utilizada por Tlax.Go WEB.
  Stream<QuerySnapshot> _obtenerItinerarios() {
    return FirebaseFirestore.instance.collection('itineraries').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Itinerarios',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Crear itinerario',
              onPressed: () => _abrirFormulario(context),
              icon: const Icon(Icons.add_rounded),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroBanner(),
            const SizedBox(height: 26),
            const Text(
              'Recorridos para inspirarte',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Ideas para descubrir Tlaxcala a tu ritmo.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 16),

            // Escucha los cambios de Firebase en tiempo real.
            StreamBuilder<QuerySnapshot>(
              stream: _obtenerItinerarios(),
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
                    'Todavía no hay itinerarios publicados. '
                    'Cuando se publique uno desde la WEB, aparecerá aquí.',
                    Icons.map_outlined,
                  );
                }

                return Column(
                  children: documentos.map((documento) {
                    final rawData = documento.data();
                    if (rawData is! Map) {
                      return const SizedBox.shrink();
                    }

                    final itinerario = Map<String, dynamic>.from(rawData);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildItinerarioCard(itinerario),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirFormulario(BuildContext context) async {
    final creado = await showDialog<bool>(
      context: context,
      builder: (context) => const _CrearItinerarioDialog(),
    );

    if (creado == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Itinerario publicado para todos.')),
      );
    }
  }

  Widget _buildIntroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.heroTop, AppColors.navy],
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
                child: const Text(
                  'VIAJES CON HISTORIA',
                  style: TextStyle(
                    color: AppColors.accentLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 17),
              const Text(
                'Tu próxima aventura\nempieza aquí',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Recorre la cultura, naturaleza y tradición de Tlaxcala.',
                style: TextStyle(
                  color: AppColors.heroText,
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
        color: Colors.white,
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
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItinerarioCard(Map<String, dynamic> itinerario) {
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
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
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF175A76), AppColors.navy],
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
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: Colors.white,
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
                          color: Colors.white.withValues(alpha: 0.72),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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
                  style: const TextStyle(
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
                      const Icon(
                        Icons.access_time_rounded,
                        size: 18,
                        color: AppColors.accentDark,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Duración aproximada: $duracion',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Lugares del recorrido',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  lugaresTexto,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
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
  const _CrearItinerarioDialog();

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
      await FirebaseFirestore.instance.collection('itineraries').add({
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

      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo publicar el itinerario: $error')),
      );
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

