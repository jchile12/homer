import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PropertyDetailScreen extends StatelessWidget {
  final Map<String, dynamic> propertyData;
  final String? propertyId;

  const PropertyDetailScreen({
    Key? key,
    required this.propertyData,
    this.propertyId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // DATOS ACTUALIZADOS
    final tipo = propertyData['tipo'] ?? '';
    final direccion = propertyData['direccion'] ?? 
                     '${propertyData['direccion1'] ?? ''} ${propertyData['direccion2'] ?? ''}'.trim();
    final numeroDepto = propertyData['numeroDepto'] ?? '';
    final comuna = propertyData['comuna'] ?? '';
    final precio = (propertyData['precio'] ?? 0).toDouble();
    final gastosComunes = (propertyData['gastosComunes'] ?? 0).toDouble();
    final metros = (propertyData['metros'] ?? 0).toDouble();
    final banos = propertyData['banos'] ?? 0;
    final dormitorios = propertyData['dormitorios'] ?? 0;
    final imagenes = propertyData['imagenes'] as List<dynamic>? ?? [];
    final estacionamiento = propertyData['estacionamiento'] ?? false;
    final bodega = propertyData['bodega'] ?? false;
    final mascotas = propertyData['mascotas'] ?? false;
    final cercanias = propertyData['cercanias'] as List<dynamic>? ?? [];
    final latitud = propertyData['latitud'] as double?;
    final longitud = propertyData['longitud'] as double?;

    final colors = Theme.of(context).colorScheme;

    final iconosCercanias = {
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

    // Dirección completa para mostrar
    final direccionCompleta = numeroDepto.isNotEmpty 
        ? '$direccion, Depto $numeroDepto' 
        : direccion;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        title: const Text('Detalle de propiedad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen principal
            if (imagenes.isNotEmpty)
              SizedBox(
                height: 250,
                child: PageView.builder(
                  itemCount: imagenes.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      imagenes[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported, size: 50),
                      ),
                    );
                  },
                ),
              ),

            // Contenido principal
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dirección
                  Text(
                    '$direccionCompleta, $comuna',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Publicado por: ${propertyData['userEmail'] ?? 'Usuario'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Precio
                  Text(
                    '${precio.toInt()} UF',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (gastosComunes > 0)
                    Text(
                      'Gastos comunes: \$${gastosComunes.toInt()}',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Descripción
                  const Text(
                    'Descripción:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Breve descripción delimitada, una vez que llega al límite se hacen puntos de continuidad como...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Leer más...'),
                  ),
                  const SizedBox(height: 24),

                  // Características
                  const Text(
                    'Características:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCaracteristica(
                          icon: Icons.straighten,
                          label: '${metros.toInt()} m²',
                        ),
                      ),
                      Expanded(
                        child: _buildCaracteristica(
                          icon: Icons.local_parking_outlined,
                          label: estacionamiento ? 'Estacionamiento disponible' : 'Estacionamiento no disponible',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCaracteristica(
                          icon: Icons.bed_outlined,
                          label: '$dormitorios dormitorios',
                        ),
                      ),
                      Expanded(
                        child: _buildCaracteristica(
                          icon: Icons.home_work_outlined,
                          label: bodega ? 'Con bodega' : 'Sin bodega',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCaracteristica(
                          icon: Icons.bathroom_outlined,
                          label: '$banos baños',
                        ),
                      ),
                      Expanded(
                        child: _buildCaracteristica(
                          icon: Icons.pets_outlined,
                          label: mascotas ? 'Se admiten' : 'No se admiten',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Servicios
                  const Text(
                    'Servicios:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 20,
                    runSpacing: 16,
                    children: [
                      _buildServicio(
                        icon: Icons.pool_outlined,
                        label: 'Piscina',
                        disponible: false,
                      ),
                      _buildServicio(
                        icon: Icons.ac_unit,
                        label: 'Aire Acondicionado',
                        disponible: true,
                      ),
                      _buildServicio(
                        icon: Icons.deck_outlined,
                        label: 'Terraza',
                        disponible: true,
                      ),
                      _buildServicio(
                        icon: Icons.local_laundry_service_outlined,
                        label: 'Lavadora',
                        disponible: true,
                      ),
                      _buildServicio(
                        icon: Icons.local_parking_outlined,
                        label: 'Estacionamiento',
                        disponible: estacionamiento,
                      ),
                      _buildServicio(
                        icon: Icons.warehouse_outlined,
                        label: 'Bodega',
                        disponible: bodega,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Cercanías (NUEVO)
                  if (cercanias.isNotEmpty) ...[
                    const Text(
                      'Cercanías:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: cercanias.map<Widget>((c) {
                        final icono = iconosCercanias[c.toString()] ?? Icons.place;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: colors.secondaryContainer,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colors.secondary.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icono, size: 18, color: colors.onSecondaryContainer),
                              const SizedBox(width: 8),
                              Text(
                                c.toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.onSecondaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Ubicación
                  const Text(
                    'Ubicación:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: latitud != null && longitud != null
                        ? GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(latitud, longitud),
                              zoom: 15,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('propiedad'),
                                position: LatLng(latitud, longitud),
                                infoWindow: InfoWindow(
                                  title: tipo,
                                  snippet: direccion,
                                ),
                              ),
                            },
                            zoomControlsEnabled: false,
                            myLocationButtonEnabled: false,
                            mapToolbarEnabled: false,
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.map, size: 50, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text(
                                  'Mapa de ubicación',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Requisitos de arriendo
                  const Text(
                    'Requisitos de arriendo:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRequisito('Acreditar una renta mayor o igual a 3 veces el valor del arriendo'),
                  _buildRequisito('6 últimas liquidaciones de sueldo'),
                  _buildRequisito('12 últimas cotizaciones'),
                  _buildRequisito('Sin DICOM'),
                  const SizedBox(height: 24),

                  // Propiedades similares
                  const Text(
                    'Propiedades similares:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('propiedades')
                          .limit(5)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final propiedades = snapshot.data!.docs
                            .where((doc) => doc.id != propertyId)
                            .take(3)
                            .toList();

                        if (propiedades.isEmpty) {
                          return Center(
                            child: Text(
                              'No hay propiedades similares',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          );
                        }

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: propiedades.length,
                          itemBuilder: (context, index) {
                            final propData = propiedades[index].data() as Map<String, dynamic>;
                            final precio = (propData['precio'] ?? 0).toDouble();
                            final metros = (propData['metros'] ?? 0).toDouble();
                            final imagenes = propData['imagenes'] as List<dynamic>? ?? [];

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PropertyDetailScreen(
                                      propertyData: propData,
                                      propertyId: propiedades[index].id,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 180,
                                margin: const EdgeInsets.only(right: 12),
                                child: Card(
                                  clipBehavior: Clip.antiAlias,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      imagenes.isNotEmpty
                                          ? Image.network(
                                              imagenes[0],
                                              height: 120,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                height: 120,
                                                color: Colors.grey.shade300,
                                                child: const Icon(Icons.home, size: 40),
                                              ),
                                            )
                                          : Container(
                                              height: 120,
                                              color: Colors.grey.shade300,
                                              child: const Center(
                                                child: Icon(Icons.home, size: 40),
                                              ),
                                            ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                'Arriendo',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${precio.toInt()} UF',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 4,
                                                children: [
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.straighten, size: 14),
                                                      const SizedBox(width: 4),
                                                      Text('${metros.toInt()} m²', style: const TextStyle(fontSize: 11)),
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.bed_outlined, size: 14),
                                                      const SizedBox(width: 4),
                                                      Text('${propData['banos'] ?? 2} baños', style: const TextStyle(fontSize: 11)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Flexible(
                                                child: Text(
                                                  '${propData['tipo'] ?? 'Propiedad'} en ${propData['comuna'] ?? 'Comuna'}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.call),
                label: const Text('Contactar'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: colors.secondary),
                  foregroundColor: colors.secondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.calendar_month),
                label: const Text('Solicitud Reserva'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: colors.secondary,
                  foregroundColor: colors.onSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaracteristica({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicio({
    required IconData icon,
    required String label,
    required bool disponible,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          disponible ? Icons.check : Icons.close,
          size: 18,
          color: disponible ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildRequisito(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}