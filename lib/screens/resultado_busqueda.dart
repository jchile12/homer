import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homer/screens/detalle_propiedades.dart';

class SearchResultsScreen extends StatefulWidget {
  final List<DocumentSnapshot> resultados;
  final Map<String, dynamic> filtrosAplicados;

  const SearchResultsScreen({
    Key? key,
    required this.resultados,
    required this.filtrosAplicados,
  }) : super(key: key);

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late List<DocumentSnapshot> _resultados;
  String _ordenamiento = 'reciente'; // reciente, precio_asc, precio_desc

  @override
  void initState() {
    super.initState();
    _resultados = widget.resultados;
  }

  void _ordenarResultados(String tipo) {
    setState(() {
      _ordenamiento = tipo;
      if (tipo == 'precio_asc') {
        _resultados.sort((a, b) {
          final precioA = (a.data() as Map<String, dynamic>)['precio'] ?? 0;
          final precioB = (b.data() as Map<String, dynamic>)['precio'] ?? 0;
          return precioA.compareTo(precioB);
        });
      } else if (tipo == 'precio_desc') {
        _resultados.sort((a, b) {
          final precioA = (a.data() as Map<String, dynamic>)['precio'] ?? 0;
          final precioB = (b.data() as Map<String, dynamic>)['precio'] ?? 0;
          return precioB.compareTo(precioA);
        });
      } else {
        _resultados = widget.resultados;
      }
    });
  }

  void _mostrarOpcionesOrdenamiento() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Ordenar por',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.schedule,
                color: _ordenamiento == 'reciente' ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
              title: const Text('Más recientes'),
              trailing: _ordenamiento == 'reciente' ? const Icon(Icons.check) : null,
              onTap: () {
                _ordenarResultados('reciente');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.arrow_upward,
                color: _ordenamiento == 'precio_asc' ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
              title: const Text('Precio: menor a mayor'),
              trailing: _ordenamiento == 'precio_asc' ? const Icon(Icons.check) : null,
              onTap: () {
                _ordenarResultados('precio_asc');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.arrow_downward,
                color: _ordenamiento == 'precio_desc' ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
              title: const Text('Precio: mayor a menor'),
              trailing: _ordenamiento == 'precio_desc' ? const Icon(Icons.check) : null,
              onTap: () {
                _ordenarResultados('precio_desc');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtros aplicados',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    if (widget.filtrosAplicados['tipo'] != null)
                      _buildFiltroItem(
                        'Tipo',
                        widget.filtrosAplicados['tipo'],
                      ),
                    if (widget.filtrosAplicados['comuna'] != null)
                      _buildFiltroItem(
                        'Comuna',
                        widget.filtrosAplicados['comuna'],
                      ),
                    if ((widget.filtrosAplicados['cercanias'] as Set?)?.isNotEmpty ?? false)
                      _buildFiltroItem(
                        'Cercanías',
                        (widget.filtrosAplicados['cercanias'] as Set).join(', '),
                      ),
                    if ((widget.filtrosAplicados['incluye'] as Set?)?.isNotEmpty ?? false)
                      _buildFiltroItem(
                        'Incluye',
                        (widget.filtrosAplicados['incluye'] as Set).join(', '),
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

  Widget _buildFiltroItem(String titulo, String valor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final tipo = data['tipo'] ?? '';
    final direccion1 = data['direccion1'] ?? '';
    final direccion2 = data['direccion2'] ?? '';
    final comuna = data['comuna'] ?? '';
    final precio = (data['precio'] ?? 0).toDouble();
    final metros = (data['metros'] ?? 0).toDouble();
    final dormitorios = data['dormitorios'] ?? 0;
    final banos = data['banos'] ?? 0;
    final imagenes = data['imagenes'] as List<dynamic>? ?? [];
    final cercanias = data['cercanias'] as List<dynamic>? ?? [];
    final estacionamiento = data['estacionamiento'] ?? false;
    final bodega = data['bodega'] ?? false;
    final mascotas = data['mascotas'] ?? false;
    final colors = Theme.of(context).colorScheme;
    final iconos = {
      'Transporte público': Icons.directions_bus,
      'Mall': Icons.shopping_bag_outlined,
      'Parque': Icons.park_outlined,
      'Ciclovía': Icons.pedal_bike,
      'Hospital': Icons.local_hospital_outlined,
      'Restaurantes': Icons.restaurant_outlined,
      'Colegio': Icons.school_outlined,
      'Supermercado': Icons.shopping_cart_outlined,
      'Jardín infantil': Icons.child_care_outlined,
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailScreen(
                propertyData: data,
                propertyId: doc.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagenes.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    Image.network(
                      imagenes[0],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported, size: 50),
                      ),
                    ),
                    if (imagenes.length > 1)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.photo_library, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '${imagenes.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${precio.toInt()} UF',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$tipo • $comuna',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$direccion1${direccion2.isNotEmpty ? ', $direccion2' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.square_foot, size: 18, color: Colors.grey.shade700),
                      const SizedBox(width: 4),
                      Text('${metros.toInt()} m²'),
                      const SizedBox(width: 16),
                      Icon(Icons.bed_outlined, size: 18, color: Colors.grey.shade700),
                      const SizedBox(width: 4),
                      Text('$dormitorios dorm.'),
                      const SizedBox(width: 16),
                      Icon(Icons.bathroom_outlined, size: 18, color: Colors.grey.shade700),
                      const SizedBox(width: 4),
                      Text('$banos baños'),
                    ],
                  ),
                  if (estacionamiento || bodega || mascotas) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (estacionamiento) _buildExtraChip('Estacionamiento', Icons.local_parking),
                        if (bodega) _buildExtraChip('Bodega', Icons.warehouse),
                        if (mascotas) _buildExtraChip('Permitido Mascotas', Icons.pets),
                      ],
                    ),
                  ],
                  if (cercanias.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Cerca de:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: cercanias.take(6).map<Widget>((c) {
                        final icono = iconos[c.toString()] ?? Icons.place;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: colors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.secondary.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icono, size: 14, color: colors.secondary),
                              const SizedBox(width: 4),
                              Text(
                                c.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    if (cercanias.length > 6)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '+${cercanias.length - 6} más',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraChip(String label, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    // Contar filtros aplicados
    int numFiltros = 0;
    if (widget.filtrosAplicados['tipo'] != null) numFiltros++;
    if (widget.filtrosAplicados['comuna'] != null) numFiltros++;
    if ((widget.filtrosAplicados['cercanias'] as Set?)?.isNotEmpty ?? false) numFiltros++;
    if ((widget.filtrosAplicados['incluye'] as Set?)?.isNotEmpty ?? false) numFiltros++;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Resultados (${_resultados.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pop(context),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de filtros y ordenamiento
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _mostrarFiltros,
                    icon: const Icon(Icons.tune, size: 20),
                    label: Text('Filtros${numFiltros > 0 ? ' ($numFiltros)' : ''}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade800,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _mostrarOpcionesOrdenamiento,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade800,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Ordenar'),
                  ),
                ),
              ],
            ),
          ),

          // Lista de resultados
          Expanded(
            child: _resultados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron propiedades',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Intenta ajustar los filtros',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _resultados.length,
                    itemBuilder: (context, index) {
                      return _buildPropertyCard(_resultados[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}