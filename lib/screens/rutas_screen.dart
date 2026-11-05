
import 'package:flutter/material.dart';

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

  final List<RutaPrueba> _rutas = const [
    RutaPrueba(
      id: 'ruta_1',
      nombre: 'Centro Histórico de Tlaxcala',
      descripcion: 'Recorre plazas, edificios históricos y calles tradicionales.',
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

  void _cambiarFavorito(RutaPrueba ruta) {
    setState(() {
      if (_favoritos.contains(ruta.id)) {
        _favoritos.remove(ruta.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ruta.nombre} se quitó de favoritos')),
        );
      } else {
        _favoritos.add(ruta.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ruta.nombre} se agregó a favoritos')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas turísticas'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.pinkAccent),
                  const SizedBox(width: 5),
                  Text('${_favoritos.length}'),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Descubre Tlaxcala',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Prueba cómo funcionarán los favoritos de tus rutas.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 18),
          ..._rutas.map((ruta) {
            final bool esFavorito = _favoritos.contains(ruta.id);

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 65,
                      height: 75,
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        ruta.icono,
                        size: 35,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ruta.nombre,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            ruta.descripcion,
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(ruta.categoria),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: esFavorito
                          ? 'Quitar de favoritos'
                          : 'Agregar a favoritos',
                      onPressed: () => _cambiarFavorito(ruta),
                      icon: Icon(
                        esFavorito ? Icons.favorite : Icons.favorite_border,
                        color: esFavorito ? Colors.red : Colors.grey,
                        size: 29,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            'Favoritos seleccionados: ${_favoritos.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
