import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:homer/screens/inicio.dart';
import 'package:homer/screens/roomies.dart';
import 'package:homer/screens/detalle_propiedades.dart';
import 'package:homer/screens/miCuenta.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class PublishPropertyScreen extends StatefulWidget {
  const PublishPropertyScreen({Key? key}) : super(key: key);

  @override
  State<PublishPropertyScreen> createState() => _PublishPropertyScreenState();
}

class _PublishPropertyScreenState extends State<PublishPropertyScreen> {
  int _currentStep = 0;
  int _currentIndex = 2;

  void _onTabTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProductsScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatsScreen()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MiCuentaScreen()),
      );
    } else {
      setState(() => _currentIndex = index);
    }
  }

  // Paso 1 - MODIFICADO
  String _tipoPropiedad = 'Casa';
  final List<String> _tiposPropiedad = const ['Casa', 'Departamento'];
  String _direccionCompleta = '';
  String _comuna = '';
  String _numeroDepto = ''; // NUEVO
  double? _latitud;
  double? _longitud;

  // Paso 2
  final TextEditingController _metrosController = TextEditingController();
  int _banos = 1;
  final List<int> _banosList = const [1, 2, 3, 4];
  int _dormitorios = 1;
  final List<int> _dormitoriosList = const [1, 2, 3, 4, 5];
  bool _estacionamiento = false;
  bool _bodega = false;
  bool _mascotas = false;

  // Paso 3
  final List<File> _imagenesFiles = [];
  final List<String> _imagenesUrls = [];
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _gastosController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Paso 4
  final Map<String, bool> _cercanias = {
    'Transporte público': false,
    'Mall': false,
    'Parque': false,
    'Ciclovía': false,
    'Hospital': false,
    'Restaurantes': false,
    'Colegio': false,
    'Supermercado': false,
    'Jardín infantil': false,
  };

  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _tipoPropiedad = _tiposPropiedad.first;
      _direccionCompleta = '';
      _comuna = '';
      _numeroDepto = '';
      _latitud = null;
      _longitud = null;
      _metrosController.clear();
      _banos = _banosList.first;
      _dormitorios = _dormitoriosList.first;
      _estacionamiento = false;
      _bodega = false;
      _mascotas = false;
      _precioController.clear();
      _gastosController.clear();
      _imagenesFiles.clear();
      _imagenesUrls.clear();
      _cercanias.updateAll((key, value) => false);
    });
  }


  Future<void> _seleccionarMetodoUbicacion(StateSetter setStateSB) async {
    final colors = Theme.of(context).colorScheme;
    
    final metodo = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¿Cómo deseas agregar la ubicación?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.map_outlined, color: colors.primary, size: 32),
              title: const Text('Seleccionar en mapa'),
              subtitle: const Text('Usa el mapa para marcar la ubicación'),
              onTap: () => Navigator.pop(context, 'mapa'),
            ),
            const Divider(height: 24),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: colors.primary, size: 32),
              title: const Text('Ingresar manualmente'),
              subtitle: const Text('Escribe la dirección y comuna'),
              onTap: () => Navigator.pop(context, 'manual'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );

    if (metodo == 'mapa') {
      await _abrirSelectorUbicacionMapa(setStateSB);
    } else if (metodo == 'manual') {
      await _abrirSelectorUbicacionManual(setStateSB);
    }
  }

  // Selector por mapa
  Future<void> _abrirSelectorUbicacionMapa(StateSetter setStateSB) async {
    final resultado = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const _SelectorUbicacionMapaScreen(),
      ),
    );

    if (resultado != null) {
      setStateSB(() {
        _direccionCompleta = resultado['direccion'] ?? '';
        _comuna = resultado['comuna'] ?? '';
        _latitud = resultado['latitud'];
        _longitud = resultado['longitud'];
      });
    }
  }

  // NUEVO: Selector manual
  Future<void> _abrirSelectorUbicacionManual(StateSetter setStateSB) async {
    final colors = Theme.of(context).colorScheme;
    final direccionController = TextEditingController(text: _direccionCompleta);
    final comunaController = TextEditingController(text: _comuna);

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ingresar dirección'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  hintText: 'Ej: Av. Providencia 123',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: comunaController,
                decoration: const InputDecoration(
                  labelText: 'Comuna',
                  hintText: 'Ej: Providencia',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
            ),
            onPressed: () {
              if (direccionController.text.trim().isEmpty ||
                  comunaController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor completa todos los campos'),
                  ),
                );
                return;
              }
              Navigator.pop(context, {
                'direccion': direccionController.text.trim(),
                'comuna': comunaController.text.trim(),
              });
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (resultado != null) {
      setStateSB(() {
        _direccionCompleta = resultado['direccion'] ?? '';
        _comuna = resultado['comuna'] ?? '';
        _latitud = null;
        _longitud = null;
      });
    }
  }

  // Métodos de imágenes con dialog mejorado
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imagenesFiles.add(File(image.path));
        });
        await _mostrarDialogImagenAgregada();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imagenesFiles.add(File(image.path));
        });
        await _mostrarDialogImagenAgregada();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al tomar foto: $e')),
      );
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          for (var image in images) {
            _imagenesFiles.add(File(image.path));
          }
        });
        await _mostrarDialogImagenesAgregadas(images.length);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imágenes: $e')),
      );
    }
  }

  // NUEVO: Dialog Material Design para imagen agregada
  Future<void> _mostrarDialogImagenAgregada() async {
    final colors = Theme.of(context).colorScheme;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: Icon(
          Icons.check_circle_outline,
          color: colors.primary,
          size: 48,
        ),
        title: const Text('Imagen agregada'),
        content: const Text(
          '¿Deseas agregar más imágenes?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, continuar'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showImageSourceDialog(setState);
            },
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Agregar más'),
          ),
        ],
      ),
    );
  }

  // NUEVO: Dialog para múltiples imágenes
  Future<void> _mostrarDialogImagenesAgregadas(int cantidad) async {
    final colors = Theme.of(context).colorScheme;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: Icon(
          Icons.check_circle_outline,
          color: colors.primary,
          size: 48,
        ),
        title: Text('$cantidad ${cantidad == 1 ? 'imagen agregada' : 'imágenes agregadas'}'),
        content: Text(
          'Ahora tienes ${_imagenesFiles.length} ${_imagenesFiles.length == 1 ? 'imagen' : 'imágenes'} en total',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _imagenesFiles.removeAt(index);
    });
  }

  void _showImageSourceDialog(StateSetter setStateSB) {
    final colors = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Agregar Imagen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.photo_library, color: colors.primary),
              title: const Text('Seleccionar de la galería'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImageFromGallery();
                setStateSB(() {});
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: colors.primary),
              title: const Text('Tomar foto'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImageFromCamera();
                setStateSB(() {});
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: colors.primary),
              title: const Text('Seleccionar múltiples'),
              onTap: () async {
                Navigator.pop(context);
                await _pickMultipleImages();
                setStateSB(() {});
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<String>> _uploadImages() async {
    final List<String> downloadUrls = [];
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return downloadUrls;

    try {
      for (int i = 0; i < _imagenesFiles.length; i++) {
        final file = _imagenesFiles[i];
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('propiedades')
            .child(user.uid)
            .child(fileName);

        final uploadTask = await storageRef.putFile(file);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }
    } catch (e) {
      print('Error al subir imágenes: $e');
      rethrow;
    }

    return downloadUrls;
  }

  void _showFormDialog() {
    _resetForm();
    final colors = Theme.of(context).colorScheme;
    
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          child: StatefulBuilder(
            builder: (context, setStateSB) {
              void continueSB() {
                if (_currentStep < 3) {
                  setStateSB(() => _currentStep += 1);
                } else {
                  _showResumenDialog();
                }
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.maxFinite,
                  height: 500,
                  child: Column(
                    children: [
                      Text(
                        'Publicación de Propiedad',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: List.generate(4, (index) {
                            final isActive = index <= _currentStep;
                            final isCurrent = index == _currentStep;
                            return Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isActive
                                                ? colors.primary
                                                : colors.surfaceContainerHighest,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                color: isActive ? colors.onPrimary : colors.onSurfaceVariant,
                                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          index == 0 ? 'Info' : index == 1 ? 'Detalles' : index == 2 ? 'Precio' : 'Cercanía',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isActive ? colors.primary : colors.onSurfaceVariant,
                                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (index < 3)
                                    Expanded(
                                      child: Container(
                                        height: 2,
                                        color: isActive ? colors.primary : colors.surfaceContainerHighest,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: _currentStep == 0
                              ? _buildPaso1(setStateSB)
                              : _currentStep == 1
                                  ? _buildPaso2(setStateSB)
                                  : _currentStep == 2
                                      ? _buildPaso3(setStateSB)
                                      : _buildPaso4(setStateSB),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_currentStep == 0)
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancelar'),
                            ),
                          if (_currentStep > 0)
                            TextButton(
                              onPressed: () => setStateSB(() => _currentStep -= 1),
                              child: const Text('Atrás'),
                            ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                            ),
                            onPressed: continueSB,
                            child: Text(_currentStep == 3 ? 'Finalizar' : 'Siguiente'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showResumenDialog() async {
    final colors = Theme.of(context).colorScheme;
    final tipo = _tipoPropiedad;
    final direccion = _direccionCompleta;
    final numeroDepto = _numeroDepto;
    final direccionCompleta = numeroDepto.isNotEmpty 
        ? '$direccion, Depto $numeroDepto' 
        : direccion;
    final comuna = _comuna;
    final metros = double.tryParse(_metrosController.text.trim()) ?? 0;
    final banos = _banos;
    final dormitorios = _dormitorios;
    final extrasList = <String>[
      if (_estacionamiento) 'Estacionamiento',
      if (_bodega) 'Bodega',
      if (_mascotas) 'Permitido mascotas',
    ];
    final extras = extrasList.join(', ');
    final precio = double.tryParse(_precioController.text.trim()) ?? 0;
    final gastos = double.tryParse(_gastosController.text.trim()) ?? 0;
    final cercaniasSeleccionadas =
        _cercanias.entries.where((e) => e.value).map((e) => e.key).toList();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Resumen de la propiedad'),
        content: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                leading: Icon(Icons.home_outlined, color: colors.primary),
                title: const Text('Tipo'),
                subtitle: Text(tipo),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                leading: Icon(Icons.location_on_outlined, color: colors.primary),
                title: const Text('Dirección'),
                subtitle: Text(direccionCompleta),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                leading: Icon(Icons.map_outlined, color: colors.primary),
                title: const Text('Comuna'),
                subtitle: Text(comuna),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                leading: Icon(Icons.square_foot_outlined, color: colors.primary),
                title: const Text('Metros²'),
                subtitle: Text('${metros.toStringAsFixed(0)}'),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                leading: Icon(Icons.bed_outlined, color: colors.primary),
                title: const Text('Dormitorios'),
                subtitle: Text('$dormitorios'),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                leading: Icon(Icons.bathroom_outlined, color: colors.primary),
                title: const Text('Baños'),
                subtitle: Text('$banos'),
              ),
              if (extras.isNotEmpty)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  leading: Icon(Icons.checklist_outlined, color: colors.primary),
                  title: const Text('Extras'),
                  subtitle: Text(extras),
                ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                leading: Icon(Icons.attach_money_outlined, color: colors.primary),
                title: const Text('Precio'),
                subtitle: Text('${precio.toInt()} UF'),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                leading: Icon(Icons.account_balance_wallet_outlined, color: colors.primary),
                title: const Text('Gastos Comunes'),
                subtitle: Text('\$${gastos.toInt()}'),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                leading: Icon(Icons.image_outlined, color: colors.primary),
                title: const Text('Imágenes'),
                subtitle: Text('${_imagenesFiles.length} foto(s)'),
              ),
              if (cercaniasSeleccionadas.isNotEmpty)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  leading: Icon(Icons.place_outlined, color: colors.primary),
                  title: const Text('Cercanías'),
                  subtitle: Text(cercaniasSeleccionadas.join(', ')),
                ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (result == true) {
      Navigator.of(context).pop();
      await _submit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propiedad publicada correctamente')),
      );
    }
  }

  Future<void> _submit() async {
    final colors = Theme.of(context).colorScheme;
  
    showDialog(
     context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
             CircularProgressIndicator(
                color: colors.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
             Text(
                'Subiendo propiedad',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
             ),
              const SizedBox(height: 8),
              Text(
               'Estamos subiendo las imágenes y guardando la información...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
           ],
         ),
        ),
      ),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
    
      if (user == null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes iniciar sesión para publicar')),
       );
        return;
     }

      final imagenesUrls = await _uploadImages();
      final cercaniasSeleccionadas =
          _cercanias.entries.where((e) => e.value).map((e) => e.key).toList();

     final direccionCompleta = _numeroDepto.isNotEmpty
          ? '$_direccionCompleta, Depto $_numeroDepto'
         : _direccionCompleta;

      await FirebaseFirestore.instance.collection('propiedades').add({
       'tipo': _tipoPropiedad,
       'direccion': direccionCompleta,
        'numeroDepto': _numeroDepto,
       'comuna': _comuna,
       'latitud': _latitud,
        'longitud': _longitud,
        'metros': double.tryParse(_metrosController.text.trim()) ?? 0,
        'banos': _banos,
        'dormitorios': _dormitorios,
        'estacionamiento': _estacionamiento,
       'bodega': _bodega,
        'mascotas': _mascotas,
        'precio': double.tryParse(_precioController.text.trim()) ?? 0,
        'gastosComunes': double.tryParse(_gastosController.text.trim()) ?? 0,
        'imagenes': imagenesUrls,
        'cercanias': cercaniasSeleccionadas,
        'userId': user.uid,
        'userEmail': user.email,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop(); 
    
    
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          icon: Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 64,
          ),
          title: const Text('¡Propiedad publicada!'),
          content: const Text(
            'Tu propiedad ha sido publicada exitosamente y ya está visible para otros usuarios.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.done),
              label: const Text('Entendido'),
              style: FilledButton.styleFrom(
               backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
            ),
          ],
        ),
     );
    
    } catch (e) {
      Navigator.of(context).pop(); 
    
    
      await showDialog(
      context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          icon: Icon(
            Icons.error_outline,
            color: colors.error,
            size: 64,
          ),
          title: const Text('Error al publicar'),
          content: Text(
            'No se pudo publicar la propiedad. Por favor intenta de nuevo.\n\nError: $e',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Cerrar'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _metrosController.dispose();
    _precioController.dispose();
    _gastosController.dispose();
    super.dispose();
  }

  // PASO 1 MODIFICADO CON NÚMERO DE DEPTO
  Widget _buildPaso1(StateSetter setStateSB) {
    final colors = Theme.of(context).colorScheme;
    final numeroDeptoController = TextEditingController(text: _numeroDepto);
    
    return Column(
      children: <Widget>[
        DropdownButtonFormField<String>(
          value: _tipoPropiedad,
          decoration: const InputDecoration(
            labelText: 'Tipo de propiedad',
            border: OutlineInputBorder(),
          ),
          items: _tiposPropiedad.map((t) => DropdownMenuItem<String>(value: t, child: Text(t))).toList(),
          onChanged: (v) {
            setStateSB(() {
              _tipoPropiedad = v ?? _tipoPropiedad;
              if (_tipoPropiedad == 'Casa') {
                _numeroDepto = '';
              }
            });
          },
        ),
        const SizedBox(height: 16),
        
        // Selector de ubicación
        InkWell(
          onTap: () => _seleccionarMetodoUbicacion(setStateSB),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: colors.outline),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.map_outlined, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _direccionCompleta.isEmpty
                            ? 'Seleccionar ubicación'
                            : _direccionCompleta,
                        style: TextStyle(
                          fontSize: 16,
                          color: _direccionCompleta.isEmpty
                              ? colors.onSurfaceVariant
                              : colors.onSurface,
                        ),
                      ),
                      if (_comuna.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _comuna,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
        
        // Campo de número de departamento (solo si es Departamento)
        if (_tipoPropiedad == 'Departamento') ...[
          const SizedBox(height: 16),
          TextField(
            controller: numeroDeptoController,
            decoration: InputDecoration(
              labelText: 'Número de Departamento',
              hintText: 'Ej: 101, 2A, etc.',
              border: const OutlineInputBorder(),
              prefixIcon: Icon(Icons.door_front_door, color: colors.primary),
            ),
            onChanged: (value) => setStateSB(() => _numeroDepto = value),
            textCapitalization: TextCapitalization.characters,
          ),
        ],
      ],
    );
  }

  Widget _buildPaso2(StateSetter setStateSB) {
    final colors = Theme.of(context).colorScheme;
    
    return Column(
      children: <Widget>[
        TextField(controller: _metrosController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Metros cuadrados', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _dormitorios,
                decoration: const InputDecoration(labelText: 'Dormitorios', border: OutlineInputBorder()),
                items: _dormitoriosList.map((d) => DropdownMenuItem<int>(value: d, child: Text(d.toString()))).toList(),
                onChanged: (v) => setStateSB(() => _dormitorios = v ?? _dormitorios),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _banos,
                decoration: const InputDecoration(labelText: 'Baños', border: OutlineInputBorder()),
                items: _banosList.map((b) => DropdownMenuItem<int>(value: b, child: Text(b.toString()))).toList(),
                onChanged: (v) => setStateSB(() => _banos = v ?? _banos),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('Estacionamiento'),
          value: _estacionamiento,
          onChanged: (v) => setStateSB(() => _estacionamiento = v ?? false),
          activeColor: colors.primary,
        ),
        CheckboxListTile(
          title: const Text('Bodega'),
          value: _bodega,
          onChanged: (v) => setStateSB(() => _bodega = v ?? false),
          activeColor: colors.primary,
        ),
        CheckboxListTile(
          title: const Text('Permite Mascotas'),
          value: _mascotas,
          onChanged: (v) => setStateSB(() => _mascotas = v ?? false),
          activeColor: colors.primary,
        ),
      ],
    );
  }

  Widget _buildPaso3(StateSetter setStateSB) {
    final colors = Theme.of(context).colorScheme;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _precioController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Precio (UF)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _gastosController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Gastos Comunes (\$)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Imágenes de la propiedad',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona fotos de tu galería o toma nuevas fotos',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showImageSourceDialog(setStateSB),
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Agregar Imágenes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_imagenesFiles.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _imagenesFiles.length,
              itemBuilder: (context, index) => Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.outline),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _imagenesFiles[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        _removeImage(index);
                        setStateSB(() {});
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.error,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          color: colors.onError,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_imagenesFiles.isEmpty)
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: colors.outline, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: colors.surfaceContainerHighest.withOpacity(0.3),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No hay imágenes seleccionadas',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toca "Agregar Imágenes" para comenzar',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaso4(StateSetter setStateSB) {
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
    final colors = Theme.of(context).colorScheme;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Cercanías importantes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona los lugares cercanos a la propiedad:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _cercanias.keys.map((cercania) {
              final sel = _cercanias[cercania] ?? false;
              return FilterChip(
                avatar: Icon(
                  iconos[cercania] ?? Icons.place,
                  size: 20,
                  color: sel ? colors.onSecondaryContainer : colors.secondary,
                ),
                label: Text(cercania),
                selected: sel,
                onSelected: (v) => setStateSB(() => _cercanias[cercania] = v),
                backgroundColor: colors.surface,
                selectedColor: colors.secondaryContainer,
                checkmarkColor: colors.onSecondaryContainer,
                labelStyle: TextStyle(
                  color: sel ? colors.onSecondaryContainer : colors.onSurface,
                ),
                side: BorderSide(color: colors.secondary, width: 1.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> data) {
    final tipo = data['tipo'] ?? '';
    final direccion = data['direccion'] ?? '';
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
                      color: colors.surfaceContainerHighest,
                      child: Icon(Icons.image_not_supported, size: 50, color: colors.onSurfaceVariant),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  direccion,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.square_foot, size: 18, color: colors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${metros.toInt()} m²', style: TextStyle(color: colors.onSurface)),
                    const SizedBox(width: 16),
                    Icon(Icons.bed_outlined, size: 18, color: colors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('$dormitorios dorm.', style: TextStyle(color: colors.onSurface)),
                    const SizedBox(width: 16),
                    Icon(Icons.bathroom_outlined, size: 18, color: colors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('$banos baños', style: TextStyle(color: colors.onSurface)),
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
                      color: colors.onSurfaceVariant,
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
                          color: colors.secondaryContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.secondary.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icono, size: 14, color: colors.onSecondaryContainer),
                            const SizedBox(width: 4),
                            Text(
                              c.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.onSecondaryContainer,
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
                          color: colors.onSurfaceVariant,
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
    );
  }

  Widget _buildExtraChip(String label, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        title: const Text('Propiedades'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('propiedades')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar propiedades'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No hay propiedades publicadas'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return GestureDetector(
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
                child: _buildPropertyCard(data),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFormDialog,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: colors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Roomies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_home_work),
            label: 'Propiedades',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Mi cuenta',
          ),
        ],
      ),
    );
  }
}

// PANTALLA DE SELECTOR DE UBICACIÓN POR MAPA
class _SelectorUbicacionMapaScreen extends StatefulWidget {
  const _SelectorUbicacionMapaScreen();

  @override
  State<_SelectorUbicacionMapaScreen> createState() => _SelectorUbicacionMapaScreenState();
}

class _SelectorUbicacionMapaScreenState extends State<_SelectorUbicacionMapaScreen> {
  late GoogleMapController _mapController;
  LatLng _posicionSeleccionada = const LatLng(-33.4489, -70.6693);
  String _direccion = '';
  String _comuna = '';
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionActual();
  }

  Future<void> _obtenerUbicacionActual() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _cargando = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _cargando = false);
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final nuevaPosicion = LatLng(position.latitude, position.longitude);

      setState(() {
        _posicionSeleccionada = nuevaPosicion;
        _cargando = false;
      });

      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: nuevaPosicion, zoom: 15),
        ),
      );

      await _obtenerDireccion(nuevaPosicion);
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _obtenerDireccion(LatLng posicion) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        posicion.latitude,
        posicion.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _direccion = '${place.street ?? ''} ${place.subThoroughfare ?? ''}'.trim();
          _comuna = place.locality ?? place.subAdministrativeArea ?? '';
        });
      }
    } catch (e) {
      print('Error obteniendo dirección: $e');
    }
  }

  void _confirmarUbicacion() {
    if (_direccion.isEmpty || _comuna.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una ubicación válida')),
      );
      return;
    }

    Navigator.pop(context, {
      'direccion': _direccion,
      'comuna': _comuna,
      'latitud': _posicionSeleccionada.latitude,
      'longitud': _posicionSeleccionada.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        title: const Text('Seleccionar Ubicación'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _posicionSeleccionada,
              zoom: 15,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('ubicacion'),
                position: _posicionSeleccionada,
                draggable: true,
                onDragEnd: (nuevaPos) async {
                  setState(() => _posicionSeleccionada = nuevaPos);
                  await _obtenerDireccion(nuevaPos);
                },
              ),
            },
            onTap: (pos) async {
              setState(() => _posicionSeleccionada = pos);
              await _obtenerDireccion(pos);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),
          if (_cargando)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ubicación seleccionada',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_direccion.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.location_on, color: colors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _direccion,
                            style: TextStyle(
                              fontSize: 16,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.map, color: colors.onSurfaceVariant, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _comuna,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Text(
                      'Mueve el marcador o toca el mapa',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _confirmarUbicacion,
                      icon: const Icon(Icons.check),
                      label: const Text('Confirmar ubicación'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}