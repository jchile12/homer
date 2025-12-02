import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:homer/screens/inicio.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  File? _pickedImageFile;
  final _picker = ImagePicker();

  void _onTabTapped(int index) {
    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProductsScreen()),
      );
    }
  }

  // 1. Seecciona imagen del dispositivo
  void _pickImage() async {
    final pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Opcional: optimización de calidad
      maxWidth: 150,
    );

    if (pickedImage != null) {
      _pickedImageFile = File(pickedImage.path);
    }
  }

  // 2. Sube la imagen a Firebase Storage y retorna la URL, està em una direcciòn
  Future<String?> _uploadImage(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('product_images') // Carpeta en Storage
          .child('${DateTime.now().toIso8601String()}.jpg');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (error) {
      if (kDebugMode) {
        print('Error al subir la imagen: $error');
      }
      return null;
    }
  }

  void _addProduct(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();

    setState(() {
      _pickedImageFile = null;
    });

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 300),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Agregar producto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    GestureDetector(
                      onTap: () async {
                        _pickImage();
                        // Actualizar solo el estado del diàlogo para mostrar la imagen
                        setDialogState(() {});
                      },
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey.shade200,
                        // Muestra la imagen si está seleccionada
                        foregroundImage: _pickedImageFile != null
                            ? FileImage(_pickedImageFile!)
                            : null,
                        child: _pickedImageFile == null
                            ? const Icon(
                                Icons.camera_alt,
                                color: Colors.grey,
                                size: 30,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campos de texto...
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Precio',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                          ),
                          onPressed: () async {
                            final title = titleController.text.trim();
                            final description = descriptionController.text
                                .trim();
                            final price = double.tryParse(
                              priceController.text.trim(),
                            );

                            if (title.isNotEmpty &&
                                description.isNotEmpty &&
                                price != null &&
                                _pickedImageFile != null) {
                              // Cerrar el diálogo y mostrar un indicador de carga
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Subiendo imagen y guardando producto...',
                                  ),
                                ),
                              );

                              // 1. Subir imagen a Storage
                              final imageUrl = await _uploadImage(
                                _pickedImageFile!,
                              );

                              if (imageUrl != null) {
                                // 2. Guardar producto con la URL de la imagen
                                await FirebaseFirestore.instance
                                    .collection('products')
                                    .add({
                                      'title': title,
                                      'description': description,
                                      'price': price,
                                      'imageUrl': imageUrl,
                                      'timestamp': FieldValue.serverTimestamp(),
                                    });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Producto agregado correctamente',
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Error al subir la imagen.'),
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Por favor, complete todos los campos y seleccione una imagen.',
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text('Guardar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _editProduct(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final titleController = TextEditingController(text: data['title']);
    final descriptionController = TextEditingController(
      text: data['description'],
    );
    final priceController = TextEditingController(
      text: data['price'].toString(),
    );

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Editar producto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Precio',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final description = descriptionController.text.trim();
                        final price = double.tryParse(
                          priceController.text.trim(),
                        );

                        if (title.isNotEmpty &&
                            description.isNotEmpty &&
                            price != null) {
                          await FirebaseFirestore.instance
                              .collection('products')
                              .doc(docId)
                              .update({
                                'title': title,
                                'description': description,
                                'price': price,
                              });

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Producto actualizado correctamente',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteProduct(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este producto?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto eliminado correctamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: const Text('Productos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProductsScreen()),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addProduct(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar productos'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No hay productos registrados'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final imageUrl = data['imageUrl'];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),

                  // Mostrar la imagen
                  leading: imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            // Manejo de carga de imagen
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            // Manejo de error (ej. si la URL ya n existe)
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.image_not_supported,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                          ),
                        )
                      : const Icon(
                          Icons.shopping_bag,
                          size: 60,
                          color: Colors.grey,
                        ), // Icono por defecto

                  title: Text(
                    data['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(data['description'] ?? ''),
                      const SizedBox(height: 4),
                      Text('\$${data['price']?.toStringAsFixed(2) ?? '0.00'}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'editar') {
                        _editProduct(context, doc.id, data);
                      } else if (value == 'eliminar') {
                        _deleteProduct(context, doc.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Text('Editar'),
                      ),
                      const PopupMenuItem(
                        value: 'eliminar',
                        child: Text('Eliminar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: _onTabTapped,

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Otros'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Productos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        ],
      ),
    );
  }
}
