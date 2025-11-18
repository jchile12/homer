import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ AGREGADO
import 'package:homer/screens/inicio.dart';
import 'package:homer/screens/roomies.dart';
import 'package:homer/screens/detalle_propiedades.dart';

class PublishPropertyScreen extends StatefulWidget {
  const PublishPropertyScreen({Key? key}) : super(key: key);

  @override
  State<PublishPropertyScreen> createState() => _PublishPropertyScreenState();
}

class _PublishPropertyScreenState extends State<PublishPropertyScreen> {
  int _currentStep = 0;
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProductsScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatsScreen()),
      );
    } else {
      setState(() => _currentIndex = index);
    }
  }

  // Paso 1
  String _tipoPropiedad = 'Casa';
  final List<String> _tiposPropiedad = const ['Casa', 'Departamento'];
  final TextEditingController _direccion1Controller = TextEditingController();
  final TextEditingController _direccion2Controller = TextEditingController();
  String _comuna = 'Las Condes';
  final List<String> _comunas = const ['Las Condes', 'Providencia', 'Ñuñoa'];

  // Paso 2
  final TextEditingController _metrosController = TextEditingController();
  int _banos = 1;
  final List<int> _banosList = const [1, 2, 3, 4];
  int _dormitorios = 1;
  final List<int> _dormitoriosList = const [1, 2, 3, 4, 5];
  bool _estacionamiento = false;
  bool _bodega = false;
  bool _mascotas = false;

  // Paso 3 - Imágenes (URLs)
  final List<String> _imagenesUrls = [];
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _gastosController = TextEditingController();
  final TextEditingController _imagenUrlController = TextEditingController();

  // Paso 4 - Cercanías
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
      _direccion1Controller.clear();
      _direccion2Controller.clear();
      _comuna = _comunas.first;
      _metrosController.clear();
      _banos = _banosList.first;
      _dormitorios = _dormitoriosList.first;
      _estacionamiento = false;
      _bodega = false;
      _mascotas = false;
      _precioController.clear();
      _gastosController.clear();
      _imagenesUrls.clear();
      _imagenUrlController.clear();
      _cercanias.updateAll((key, value) => false);
    });
  }

  void _agregarImagenUrl() {
    final url = _imagenUrlController.text.trim();
    if (url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'))) {
      setState(() {
        _imagenesUrls.add(url);
        _imagenUrlController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa una URL válida')),
      );
    }
  }

  void _usarImagenPlaceholder() {
    final placeholders = [
      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
      'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
      'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800',
      'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=800',
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800',
    ];
    
    final random = (DateTime.now().millisecondsSinceEpoch % placeholders.length);
    setState(() {
      _imagenesUrls.add(placeholders[random]);
    });
  }

  void _removeImagenUrl(int index) {
    setState(() {
      _imagenesUrls.removeAt(index);
    });
  }

  void _showFormDialog() {
    _resetForm();
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
                      Text('Publicación de Propiedad',
                          style: Theme.of(context).textTheme.titleLarge),
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
                                                ? Theme.of(context).colorScheme.primary
                                                : Colors.grey.shade300,
                                          ),
                                          child: Center(
                                            child: Text('${index + 1}',
                                                style: TextStyle(
                                                  color: isActive ? Colors.white : Colors.grey.shade600,
                                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                                )),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          index == 0 ? 'Info' : index == 1 ? 'Detalles' : index == 2 ? 'Precio' : 'Cercanía',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
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
                                        color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
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
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
    final tipo = _tipoPropiedad;
    final direccion1 = _direccion1Controller.text.trim();
    final direccion2 = _direccion2Controller.text.trim();
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
                leading: const Icon(Icons.home_outlined),
                title: const Text('Tipo'),
                subtitle: Text(tipo),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Dirección'),
                subtitle: Text('$direccion1${direccion2.isNotEmpty ? ', $direccion2' : ''}'),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                leading: const Icon(Icons.map_outlined),
                title: const Text('Comuna'),
                subtitle: Text(comuna),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                leading: const Icon(Icons.square_foot_outlined),
                title: const Text('Metros²'),
                subtitle: Text('${metros.toStringAsFixed(0)}'),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                leading: const Icon(Icons.bed_outlined),
                title: const Text('Dormitorios'),
                subtitle: Text('$dormitorios'),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                leading: const Icon(Icons.bathroom_outlined),
                title: const Text('Baños'),
                subtitle: Text('$banos'),
              ),
              if (extras.isNotEmpty)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  leading: const Icon(Icons.checklist_outlined),
                  title: const Text('Extras'),
                  subtitle: Text(extras),
                ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                leading: const Icon(Icons.attach_money_outlined),
                title: const Text('Precio'),
                subtitle: Text('${precio.toInt()} UF'),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Gastos Comunes'),
                subtitle: Text('\$${gastos.toInt()}'),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                leading: const Icon(Icons.image_outlined),
                title: const Text('Imágenes'),
                subtitle: Text('${_imagenesUrls.length} foto(s)'),
              ),
              if (cercaniasSeleccionadas.isNotEmpty)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  leading: const Icon(Icons.place_outlined),
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
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
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

  // ✅ ============================================
  // MÉTODO _submit() CON userId AGREGADO
  // ============================================
  Future<void> _submit() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // ✅ NUEVO: Obtener el usuario actual
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes iniciar sesión para publicar')),
        );
        return;
      }

      final cercaniasSeleccionadas =
          _cercanias.entries.where((e) => e.value).map((e) => e.key).toList();

      await FirebaseFirestore.instance.collection('properties').add({
        'tipo': _tipoPropiedad,
        'direccion1': _direccion1Controller.text.trim(),
        'direccion2': _direccion2Controller.text.trim(),
        'comuna': _comuna,
        'metros': double.tryParse(_metrosController.text.trim()) ?? 0,
        'banos': _banos,
        'dormitorios': _dormitorios,
        'estacionamiento': _estacionamiento,
        'bodega': _bodega,
        'mascotas': _mascotas,
        'precio': double.tryParse(_precioController.text.trim()) ?? 0,
        'gastosComunes': double.tryParse(_gastosController.text.trim()) ?? 0,
        'imagenes': _imagenesUrls,
        'cercanias': cercaniasSeleccionadas,
        'userId': user.uid,           // ✅ NUEVO: ID del usuario
        'userEmail': user.email,      // ✅ NUEVO: Email del usuario (opcional)
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop();
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _direccion1Controller.dispose();
    _direccion2Controller.dispose();
    _metrosController.dispose();
    _precioController.dispose();
    _gastosController.dispose();
    _imagenUrlController.dispose();
    super.dispose();
  }

  Widget _buildPaso1(StateSetter setStateSB) => Column(
        children: <Widget>[
          DropdownButtonFormField<String>(
            value: _tipoPropiedad,
            decoration: const InputDecoration(labelText: 'Tipo de propiedad', border: OutlineInputBorder()),
            items: _tiposPropiedad.map((t) => DropdownMenuItem<String>(value: t, child: Text(t))).toList(),
            onChanged: (v) => setStateSB(() => _tipoPropiedad = v ?? _tipoPropiedad),
          ),
          const SizedBox(height: 16),
          TextField(controller: _direccion1Controller, decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _direccion2Controller, decoration: const InputDecoration(labelText: 'Dirección 2 (opcional)', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _comuna,
            decoration: const InputDecoration(labelText: 'Comuna', border: OutlineInputBorder()),
            items: _comunas.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
            onChanged: (v) => setStateSB(() => _comuna = v ?? _comuna),
          ),
        ],
      );

  Widget _buildPaso2(StateSetter setStateSB) => Column(
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
          CheckboxListTile(title: const Text('Estacionamiento'), value: _estacionamiento, onChanged: (v) => setStateSB(() => _estacionamiento = v ?? false)),
          CheckboxListTile(title: const Text('Bodega'), value: _bodega, onChanged: (v) => setStateSB(() => _bodega = v ?? false)),
          CheckboxListTile(title: const Text('Permite Mascotas'), value: _mascotas, onChanged: (v) => setStateSB(() => _mascotas = v ?? false)),
        ],
      );

  Widget _buildPaso3(StateSetter setStateSB) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(controller: _precioController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio (UF)', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _gastosController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Gastos Comunes (\$)', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            Text('Imágenes de la propiedad', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Puedes agregar URLs de imágenes o usar un placeholder', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _imagenUrlController, decoration: const InputDecoration(labelText: 'URL de imagen', hintText: 'https://ejemplo.com/imagen.jpg', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                IconButton(onPressed: () { _agregarImagenUrl(); setStateSB(() {}); }, icon: const Icon(Icons.add), style: IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white)),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: () { _usarImagenPlaceholder(); setStateSB(() {}); }, icon: const Icon(Icons.image), label: const Text('Usar imagen de ejemplo')),
            const SizedBox(height: 16),
            if (_imagenesUrls.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagenesUrls.length,
                  itemBuilder: (context, index) => Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 120,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey)),
                        child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_imagenesUrls[index], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300, child: const Icon(Icons.error)))),
                      ),
                      Positioned(top: 4, right: 12, child: GestureDetector(onTap: () { _removeImagenUrl(index); setStateSB(() {}); }, child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 20)))),
                    ],
                  ),
                ),
              ),
            if (_imagenesUrls.isEmpty) Container(height: 100, decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)), child: const Center(child: Text('No hay imágenes agregadas'))),
          ],
        ),
      );

  Widget _buildPaso4(StateSetter setStateSB) {
    final iconos = {
      'Transporte público': Icons.directions_bus, 'Mall': Icons.shopping_bag_outlined, 'Parque': Icons.park_outlined,
      'Ciclovía': Icons.pedal_bike, 'Hospital': Icons.local_hospital_outlined, 'Restaurantes': Icons.restaurant_outlined,
      'Colegio': Icons.school_outlined, 'Supermercado': Icons.shopping_cart_outlined, 'Jardín infantil': Icons.child_care_outlined,
    };
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Cercanías importantes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Selecciona los lugares cercanos a la propiedad:', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _cercanias.keys.map((cercania) {
              final sel = _cercanias[cercania] ?? false;
              return FilterChip(
                avatar: Icon(iconos[cercania] ?? Icons.place, size: 20, color: sel ? colors.onSecondary : colors.secondary),
                label: Text(cercania),
                selected: sel,
                onSelected: (v) => setStateSB(() => _cercanias[cercania] = v),
                backgroundColor: Colors.transparent,
                selectedColor: colors.secondary.withOpacity(0.85),
                checkmarkColor: colors.onSecondary,
                labelStyle: TextStyle(color: sel ? colors.onSecondary : colors.secondary),
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
    final iconos = {'Transporte público': Icons.directions_bus, 'Mall': Icons.shopping_bag_outlined, 'Parque': Icons.park_outlined, 'Ciclovía': Icons.pedal_bike, 'Hospital': Icons.local_hospital_outlined, 'Restaurantes': Icons.restaurant_outlined, 'Colegio': Icons.school_outlined, 'Supermercado': Icons.shopping_cart_outlined, 'Jardín infantil': Icons.child_care_outlined};

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
                  Image.network(imagenes[0], height: 200, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey.shade300, child: const Icon(Icons.image_not_supported, size: 50))),
                  if (imagenes.length > 1)
                    Positioned(bottom: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.photo_library, size: 14, color: Colors.white), const SizedBox(width: 4), Text('${imagenes.length}', style: const TextStyle(color: Colors.white, fontSize: 12))]))),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${precio.toInt()} UF', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.secondary)),
                const SizedBox(height: 8),
                Text('$tipo • $comuna', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('$direccion1${direccion2.isNotEmpty ? ', $direccion2' : ''}', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                const SizedBox(height: 12),
                Row(children: [Icon(Icons.square_foot, size: 18, color: Colors.grey.shade700), const SizedBox(width: 4), Text('${metros.toInt()} m²'), const SizedBox(width: 16), Icon(Icons.bed_outlined, size: 18, color: Colors.grey.shade700), const SizedBox(width: 4), Text('$dormitorios dorm.'), const SizedBox(width: 16), Icon(Icons.bathroom_outlined, size: 18, color: Colors.grey.shade700), const SizedBox(width: 4), Text('$banos baños')]),
                if (estacionamiento || bodega || mascotas) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    if (estacionamiento) _buildExtraChip('Estacionamiento', Icons.local_parking),
                    if (bodega) _buildExtraChip('Bodega', Icons.warehouse),
                    if (mascotas) _buildExtraChip('Permitido Mascotas', Icons.pets),
                  ]),
                ],
                if (cercanias.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Cerca de:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: cercanias.take(6).map<Widget>((c) {
                      final icono = iconos[c.toString()] ?? Icons.place;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: colors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.secondary.withOpacity(0.3))),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icono, size: 14, color: colors.secondary), const SizedBox(width: 4), Text(c.toString(), style: TextStyle(fontSize: 11, color: colors.secondary, fontWeight: FontWeight.w500))]),
                      );
                    }).toList(),
                  ),
                  if (cercanias.length > 6) Padding(padding: const EdgeInsets.only(top: 6), child: Text('+${cercanias.length - 6} más', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraChip(String label, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: Colors.grey.shade700), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700))]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Propiedades')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('properties').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error al cargar propiedades'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No hay propiedades publicadas'));
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
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Otros'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
        ],
      ),
    );
  }
}