import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homer/screens/propiedades.dart';
import 'package:homer/screens/roomies.dart';
import 'package:homer/screens/inicio.dart';
import 'package:homer/screens/inicio_sesion.dart';
import 'package:homer/screens/detalle_propiedades.dart';

class MiCuentaScreen extends StatefulWidget {
  const MiCuentaScreen({Key? key}) : super(key: key);

  @override
  State<MiCuentaScreen> createState() => _MiCuentaScreenState();
}

class _MiCuentaScreenState extends State<MiCuentaScreen> {
  int _currentIndex = 3;

  final _nombresController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _rutController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // CRUD - READ: Cargar datos del usuario
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      final userId = user.uid;
      
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nombresController.text = data['nombres'] ?? '';
          _apellidoPaternoController.text = data['apellidoPaterno'] ?? '';
          _apellidoMaternoController.text = data['apellidoMaterno'] ?? '';
          _rutController.text = data['rut'] ?? '';
          _correoController.text = data['correo'] ?? user.email ?? '';
          _telefonoController.text = data['telefono'] ?? '';
          _isLoading = false;
        });
      } else {
        // CRUD - CREATE: Si no existe el documento, crear uno inicial
        await _crearPerfilInicial(userId, user.email);
        setState(() {
          _correoController.text = user.email ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al cargar datos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  // CRUD - CREATE: Crear perfil inicial del usuario
  Future<void> _crearPerfilInicial(String userId, String? email) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'nombres': '',
        'apellidoPaterno': '',
        'apellidoMaterno': '',
        'rut': '',
        'correo': email ?? '',
        'telefono': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al crear perfil inicial: $e');
    }
  }

  // CRUD - UPDATE: Guardar/actualizar datos del usuario
  Future<void> _saveUserData() async {
    // Validaciones
    if (_nombresController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es obligatorio')),
      );
      return;
    }

    if (_apellidoPaternoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El apellido paterno es obligatorio')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }
      
      final userId = user.uid;
      
      // Actualizar datos en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'nombres': _nombresController.text.trim(),
        'apellidoPaterno': _apellidoPaternoController.text.trim(),
        'apellidoMaterno': _apellidoMaternoController.text.trim(),
        'rut': _rutController.text.trim(),
        'correo': _correoController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos guardados correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error al guardar: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // CRUD - DELETE: Eliminar cuenta de usuario
  Future<void> _deleteUserAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar Cuenta'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar tu cuenta? Esta acción no se puede deshacer y perderás todos tus datos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        // Eliminar datos del usuario de Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();

        // Eliminar cuenta de autenticación
        await user.delete();

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar cuenta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PublishPropertyScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatsScreen()),
      );
    } else if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProductsScreen()),
      );
    } else {
      setState(() => _currentIndex = index);
    }
  }

  void _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }

  Future<void> _deleteProperty(String propertyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar Propiedad'),
        content: const Text('¿Estás seguro de que deseas eliminar esta propiedad? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('propiedades')
            .doc(propertyId)
            .delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Propiedad eliminada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _editProperty(String propertyId, Map<String, dynamic> propertyData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPropertyScreen(
          propertyId: propertyId,
          propertyData: propertyData,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _rutController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  String _getInitials() {
    final nombres = _nombresController.text.trim();
    final apellido = _apellidoPaternoController.text.trim();
    
    String initials = '';
    if (nombres.isNotEmpty) initials += nombres[0];
    if (apellido.isNotEmpty) initials += apellido[0];
    
    return initials.toUpperCase();
  }

  Widget _buildPropertyCard(String propertyId, Map<String, dynamic> data) {
    final tipo = data['tipo'] ?? '';
    // ACTUALIZADO: Usar campo 'direccion' en lugar de 'direccion1'
    final direccion = data['direccion'] ?? data['direccion1'] ?? '';
    final numeroDepto = data['numeroDepto'] ?? '';
    final direccionCompleta = numeroDepto.isNotEmpty 
        ? '$direccion, Depto $numeroDepto' 
        : direccion;
    final comuna = data['comuna'] ?? '';
    final precio = (data['precio'] ?? 0).toDouble();
    final metros = (data['metros'] ?? 0).toDouble();
    final dormitorios = data['dormitorios'] ?? 0;
    final banos = data['banos'] ?? 0;
    final imagenes = data['imagenes'] as List<dynamic>? ?? [];
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailScreen(
                propertyData: data,
                propertyId: propertyId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imagenes.isNotEmpty
                    ? Image.network(
                        imagenes[0],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image_not_supported, size: 40),
                        ),
                      )
                    : Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.home, size: 40),
                      ),
              ),
              const SizedBox(width: 12),
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${precio.toInt()} UF',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$tipo • $comuna',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      direccionCompleta,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.square_foot, size: 14, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Text('${metros.toInt()}m²', style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 12),
                        Icon(Icons.bed_outlined, size: 14, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Text('$dormitorios', style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 12),
                        Icon(Icons.bathroom_outlined, size: 14, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Text('$banos', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              // Botones de acción
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: colors.primary, size: 20),
                    onPressed: () => _editProperty(propertyId, data),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _deleteProperty(propertyId),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        title: const Text('Mi Cuenta'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'delete_account') {
                _deleteUserAccount();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_account',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar cuenta', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header con avatar y saludo
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: colors.primary,
                          child: Text(
                            _getInitials().isNotEmpty ? _getInitials() : '?',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: colors.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hola ${_nombresController.text.isNotEmpty ? _nombresController.text.split(' ').first : 'Usuario'}!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.onPrimaryContainer.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sección de datos personales
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Datos personales',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isEditing ? Icons.close : Icons.edit,
                                    color: colors.primary,
                                  ),
                                  onPressed: () {
                                    if (_isEditing) {
                                      _loadUserData();
                                    }
                                    setState(() => _isEditing = !_isEditing);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Nombres
                            Text(
                              'Nombres *',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _nombresController,
                              enabled: _isEditing,
                              decoration: InputDecoration(
                                hintText: 'Ej: Juan Pablo',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: !_isEditing,
                                fillColor: _isEditing ? null : Colors.grey.shade100,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Apellido Paterno
                            Text(
                              'Apellido Paterno *',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _apellidoPaternoController,
                              enabled: _isEditing,
                              decoration: InputDecoration(
                                hintText: 'Ej: González',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: !_isEditing,
                                fillColor: _isEditing ? null : Colors.grey.shade100,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Apellido Materno
                            Text(
                              'Apellido Materno',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _apellidoMaternoController,
                              enabled: _isEditing,
                              decoration: InputDecoration(
                                hintText: 'Ej: López',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: !_isEditing,
                                fillColor: _isEditing ? null : Colors.grey.shade100,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // RUT
                            Text(
                              'RUT',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _rutController,
                              enabled: _isEditing,
                              decoration: InputDecoration(
                                hintText: 'Ej: 12.345.678-9',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: !_isEditing,
                                fillColor: _isEditing ? null : Colors.grey.shade100,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Correo
                            Text(
                              'Correo',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _correoController,
                              enabled: _isEditing,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'contacto@mail.com',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: !_isEditing,
                                fillColor: _isEditing ? null : Colors.grey.shade100,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Teléfono
                            Text(
                              'Teléfono',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _telefonoController,
                              enabled: _isEditing,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: '+56 9 1234 5678',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: !_isEditing,
                                fillColor: _isEditing ? null : Colors.grey.shade100,
                              ),
                            ),

                            // Botón guardar
                            if (_isEditing) ...[
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _saveUserData,
                                  icon: const Icon(Icons.save),
                                  label: const Text('Guardar cambios'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.primary,
                                    foregroundColor: colors.onPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Sección de Mis Propiedades
                  if (user != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Mis Propiedades',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Icon(Icons.home_work, color: colors.primary),
                                ],
                              ),
                              const SizedBox(height: 16),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('propiedades')
                                    .where('userId', isEqualTo: user.uid)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(Icons.error_outline, size: 40, color: Colors.red.shade700),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Error al cargar propiedades',
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                    return Container(
                                      padding: const EdgeInsets.all(32),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.home_outlined,
                                            size: 48,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'No tienes propiedades publicadas',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  final docs = snapshot.data!.docs;
                                  docs.sort((a, b) {
                                    final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                                    final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                                    
                                    if (aTime == null || bTime == null) return 0;
                                    return bTime.compareTo(aTime);
                                  });

                                  return Column(
                                    children: docs.map((doc) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      return _buildPropertyCard(doc.id, data);
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Botón Cerrar Sesión
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Cerrar Sesión'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
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

// La clase EditPropertyScreen permanece igual...
class EditPropertyScreen extends StatefulWidget {
  final String propertyId;
  final Map<String, dynamic> propertyData;

  const EditPropertyScreen({
    Key? key,
    required this.propertyId,
    required this.propertyData,
  }) : super(key: key);

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  late String _tipoPropiedad;
  late String _comuna;
  late int _banos;
  late int _dormitorios;
  late bool _estacionamiento;
  late bool _bodega;
  late bool _mascotas;
  late List<String> _imagenesUrls;
  late Map<String, bool> _cercanias;

  final _direccion1Controller = TextEditingController();
  final _direccion2Controller = TextEditingController();
  final _metrosController = TextEditingController();
  final _precioController = TextEditingController();
  final _gastosController = TextEditingController();
  final _imagenUrlController = TextEditingController();

  final List<String> _tiposPropiedad = const ['Casa', 'Departamento'];
  final List<String> _comunas = const ['Las Condes', 'Providencia', 'Ñuñoa'];
  final List<int> _banosList = const [1, 2, 3, 4];
  final List<int> _dormitoriosList = const [1, 2, 3, 4, 5];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPropertyData();
  }

  void _loadPropertyData() {
    final data = widget.propertyData;
    
    _tipoPropiedad = data['tipo'] ?? 'Casa';
    _direccion1Controller.text = data['direccion1'] ?? data['direccion'] ?? '';
    _direccion2Controller.text = data['direccion2'] ?? '';
    _comuna = data['comuna'] ?? 'Las Condes';
    _metrosController.text = (data['metros'] ?? 0).toString();
    _banos = data['banos'] ?? 1;
    _dormitorios = data['dormitorios'] ?? 1;
    _estacionamiento = data['estacionamiento'] ?? false;
    _bodega = data['bodega'] ?? false;
    _mascotas = data['mascotas'] ?? false;
    _precioController.text = (data['precio'] ?? 0).toString();
    _gastosController.text = (data['gastosComunes'] ?? 0).toString();
    _imagenesUrls = List<String>.from(data['imagenes'] ?? []);
    
    final cercaniasData = data['cercanias'] as List<dynamic>? ?? [];
    _cercanias = {
      'Transporte público': cercaniasData.contains('Transporte público'),
      'Mall': cercaniasData.contains('Mall'),
      'Parque': cercaniasData.contains('Parque'),
      'Ciclovía': cercaniasData.contains('Ciclovía'),
      'Hospital': cercaniasData.contains('Hospital'),
      'Restaurantes': cercaniasData.contains('Restaurantes'),
      'Colegio': cercaniasData.contains('Colegio'),
      'Supermercado': cercaniasData.contains('Supermercado'),
      'Jardín infantil': cercaniasData.contains('Jardín infantil'),
    };
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

  void _removeImagenUrl(int index) {
    setState(() {
      _imagenesUrls.removeAt(index);
    });
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      final cercaniasSeleccionadas =
          _cercanias.entries.where((e) => e.value).map((e) => e.key).toList();

      await FirebaseFirestore.instance
          .collection('propiedades')
          .doc(widget.propertyId)
          .update({
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
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Propiedad actualizada correctamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        title: const Text('Editar Propiedad'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información Básica',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _tipoPropiedad,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de propiedad',
                      border: OutlineInputBorder(),
                    ),
                    items: _tiposPropiedad
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _tipoPropiedad = v!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _direccion1Controller,
                    decoration: const InputDecoration(
                      labelText: 'Dirección',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _direccion2Controller,
                    decoration: const InputDecoration(
                      labelText: 'Dirección 2 (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _comuna,
                    decoration: const InputDecoration(
                      labelText: 'Comuna',
                      border: OutlineInputBorder(),
                    ),
                    items: _comunas
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _comuna = v!),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Detalles',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _metrosController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Metros cuadrados',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _dormitorios,
                          decoration: const InputDecoration(
                            labelText: 'Dormitorios',
                            border: OutlineInputBorder(),
                          ),
                          items: _dormitoriosList
                              .map((d) => DropdownMenuItem(value: d, child: Text(d.toString())))
                              .toList(),
                          onChanged: (v) => setState(() => _dormitorios = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _banos,
                          decoration: const InputDecoration(
                            labelText: 'Baños',
                            border: OutlineInputBorder(),
                          ),
                          items: _banosList
                              .map((b) => DropdownMenuItem(value: b, child: Text(b.toString())))
                              .toList(),
                          onChanged: (v) => setState(() => _banos = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Estacionamiento'),
                    value: _estacionamiento,
                    onChanged: (v) => setState(() => _estacionamiento = v ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('Bodega'),
                    value: _bodega,
                    onChanged: (v) => setState(() => _bodega = v ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('Permite Mascotas'),
                    value: _mascotas,
                    onChanged: (v) => setState(() => _mascotas = v ?? false),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Precio',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
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

                  const SizedBox(height: 32),

                  Text(
                    'Imágenes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _imagenUrlController,
                          decoration: const InputDecoration(
                            labelText: 'URL de imagen',
                            hintText: 'https://ejemplo.com/imagen.jpg',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _agregarImagenUrl,
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
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
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _imagenesUrls[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.error),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 12,
                              child: GestureDetector(
                                onTap: () => _removeImagenUrl(index),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  Text(
                    'Cercanías',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _cercanias.keys.map((cercania) {
                      final sel = _cercanias[cercania] ?? false;
                      return FilterChip(
                        label: Text(cercania),
                        selected: sel,
                        onSelected: (v) => setState(() => _cercanias[cercania] = v),
                        selectedColor: colors.primary.withOpacity(0.3),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Guardar Cambios',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}