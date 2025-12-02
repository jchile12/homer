import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// 1. IMPORTACIÓN NECESARIA PARA LA UBICACIÓN
import 'package:geolocator/geolocator.dart'; 

class MapSaveScreen extends StatefulWidget {
  const MapSaveScreen({super.key});

  @override
  State<MapSaveScreen> createState() => _MapSaveScreenState();
}

class _MapSaveScreenState extends State<MapSaveScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _marcadores = {};
  bool _cargando = true;

  // 2. VARIABLE DE ESTADO PARA LA POSICIÓN DE LA CÁMARA
  // Posición inicial por defecto (Santiago) si la ubicación falla o no se concede permiso.
  LatLng _cameraPosicion = const LatLng(-33.4489, -70.6693); 

  @override
  void initState() {
    super.initState();
    _cargarMarcadores();
    // 3. LLAMAR A LA FUNCIÓN DE UBICACIÓN AL INICIAR
    _obtenerUbicacionActual();
  }

  // =========================================================
  // LÓGICA DE UBICACIÓN ACTUAL (TU NUEVA FUNCIÓN)
  // =========================================================
  Future<void> _obtenerUbicacionActual() async {
    // 3.1. Verificar si los servicios están habilitados.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    // 3.2. Verificar/Solicitar permisos.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('Location permissions are denied or permanently denied.');
        return;
      }
    }

    // 3.3. Obtener la posición actual.
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final nuevaPosicion = LatLng(position.latitude, position.longitude);

      setState(() {
        _cameraPosicion = nuevaPosicion;
      });

      // 3.4. Centrar el mapa si el controlador ya está inicializado.
      // Esto asegura que la cámara se mueva si la ubicación se obtiene después de onMapCreated.
      if (mounted && mapController != null) {
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: nuevaPosicion,
              zoom: 15, 
            ),
          ),
        );
      }
    } catch (e) {
      print("Error obteniendo ubicación: $e");
    }
  }
  
  // =========================================================
  // LÓGICA DE FIREBASE (TU CÓDIGO ORIGINAL)
  // =========================================================
  Future<void> _cargarMarcadores() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('ubicaciones').get();

    final nuevosMarcadores = snapshot.docs.map((doc) {
      final data = doc.data();
      final lat = data['lat'] as double?;
      final lng = data['lng'] as double?;
      final titulo = data['titulo'] ?? 'Sin título';
      final descripcion = data['descripcion'] ?? '';
      final categoria = data['categoria'] ?? 'General';

      if (lat == null || lng == null) return null;

      final color = _colorPorCategoria(categoria);

      return Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: titulo,
          snippet: '$descripcion ($categoria)',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(color),
      );
    }).whereType<Marker>().toSet();

    setState(() {
      _marcadores
        ..clear()
        ..addAll(nuevosMarcadores);
      _cargando = false;
    });
  }

  double _colorPorCategoria(String categoria) {
    switch (categoria) {
      case 'Restaurante':
        return BitmapDescriptor.hueRed;
      case 'Tienda':
        return BitmapDescriptor.hueAzure;
      case 'Evento':
        return BitmapDescriptor.hueGreen;
      default:
        return BitmapDescriptor.hueViolet;
    }
  }

  void _abrirFormulario() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: const _FormularioUbicacion(),
      ),
    );

    // Refrescar marcadores al cerrar el formulario
    _cargarMarcadores();
  }

  // =========================================================
  // Construcción de pantalla principal
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de ubicaciones')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (controller) {
                mapController = controller;
                // Si ya obtuvimos la ubicación antes de que el mapa estuviera listo, la centramos aquí.
                if (_cameraPosicion.latitude != -33.4489 || _cameraPosicion.longitude != -70.6693) {
                   mapController.moveCamera(
                     CameraUpdate.newLatLngZoom(_cameraPosicion, 15),
                   );
                }
              },
              // 4. USAMOS LA POSICIÓN DE LA CÁMARA (actual o por defecto)
              initialCameraPosition:
                  CameraPosition(target: _cameraPosicion, zoom: 12),
              markers: _marcadores,
              
              // 5. ACTIVAR CAPA DE UBICACIÓN ACTUAL Y BOTÓN
              myLocationEnabled: true, // Muestra el punto azul
              myLocationButtonEnabled: true, // Muestra el botón de centrado
              
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormulario,
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }
}

// ===========================================================================
// Formulario con mini mapa para agregar nueva ubicación (TU CÓDIGO ORIGINAL)
// ===========================================================================
class _FormularioUbicacion extends StatefulWidget {
  const _FormularioUbicacion();

  @override
  State<_FormularioUbicacion> createState() => _FormularioUbicacionState();
}

class _FormularioUbicacionState extends State<_FormularioUbicacion> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  String _categoria = 'General';
  final List<String> _categorias = [
    'General',
    'Restaurante',
    'Tienda',
    'Evento'
  ];

  LatLng _posicionSeleccionada = const LatLng(-33.4489, -70.6693);
  // ignore: unused_field
  GoogleMapController? _miniMapaController;

  // =========================================================
  // Guardar ubicación en Firestore
  // =========================================================
  Future<void> _guardarUbicacion() async {
    final titulo = _tituloController.text.trim();
    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes ingresar un título')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('ubicaciones').add({
      'titulo': titulo,
      'descripcion': _descripcionController.text.trim(),
      'categoria': _categoria,
      'lat': _posicionSeleccionada.latitude,
      'lng': _posicionSeleccionada.longitude,
      'fecha': DateTime.now(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 5,
              width: 50,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const Text(
            'Agregar nueva ubicación',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Campo título
          TextField(
            controller: _tituloController,
            decoration: const InputDecoration(
              labelText: 'Título',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Campo descripción
          TextField(
            controller: _descripcionController,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Categoría
          DropdownButtonFormField<String>(
            value: _categoria,
            items: _categorias
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _categoria = v!),
            decoration: const InputDecoration(
              labelText: 'Categoría',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Mini mapa
          SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: _posicionSeleccionada, zoom: 14),
                onMapCreated: (controller) => _miniMapaController = controller,
                markers: {
                  Marker(
                    markerId: const MarkerId('nuevo'),
                    position: _posicionSeleccionada,
                    draggable: true,
                    onDragEnd: (nuevaPos) =>
                        setState(() => _posicionSeleccionada = nuevaPos),
                  ),
                },
                onTap: (pos) => setState(() => _posicionSeleccionada = pos),
                myLocationButtonEnabled: true, // Si quieres el botón aquí también
                zoomControlsEnabled: false,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botón Guardar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _guardarUbicacion,
              icon: const Icon(Icons.save),
              label: const Text('Guardar ubicación'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}