import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homer/screens/roomies.dart';
import 'package:homer/screens/propiedades.dart';
import 'package:homer/screens/miCuenta.dart';
import 'package:homer/screens/resultado_busqueda.dart';
import 'package:homer/screens/inicio_sesion.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  int _currentIndex = 0;

  // Toggle Venta / Arriendo
  String _modoSeleccionado = 'venta';

  // Campos del formulario
  String? _tipoPropiedadSeleccionado;
  final TextEditingController _sectorController = TextEditingController();

  // Expansión de secciones
  bool _cercaniaExpandida = true;
  bool _incluyeExpandido = true;
  bool _cargando = false;

  // ---------- CERCANÍA CON ----------
  final List<OpcionCercania> _opcionesCercania = const [
    OpcionCercania('Transporte público', Icons.directions_bus),
    OpcionCercania('Mall', Icons.local_mall),
    OpcionCercania('Parque', Icons.park),
    OpcionCercania('Ciclovía', Icons.directions_bike),
    OpcionCercania('Hospital', Icons.local_hospital),
    OpcionCercania('Restaurantes', Icons.restaurant),
    OpcionCercania('Colegio', Icons.school),
    OpcionCercania('Supermercado', Icons.local_grocery_store),
    OpcionCercania('Jardín infantil', Icons.child_care),
  ];

  final Set<String> _cercaniaSeleccionada = {};

  // ---------- INCLUYE ----------
  final Map<String, String> _opcionesIncluye = const {
    'Estacionamiento': 'estacionamiento',
    'Bodega': 'bodega',
    'Mascotas': 'mascotas',
  };

  final Set<String> _incluyeSeleccionado = {};

  @override
  void dispose() {
    _sectorController.dispose();
    super.dispose();
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
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MiCuentaScreen()),
      );
    } else {
      setState(() => _currentIndex = index);
    }
  }

  // ✅ MÉTODO DE BÚSQUEDA - Navega a pantalla de resultados
  Future<void> _realizarBusqueda() async {
    setState(() => _cargando = true);

    try {
      // Obtener todas las propiedades
      Query query = FirebaseFirestore.instance.collection('propiedades');

      // Filtro por tipo de propiedad
      if (_tipoPropiedadSeleccionado != null && _tipoPropiedadSeleccionado!.isNotEmpty) {
        query = query.where('tipo', isEqualTo: _tipoPropiedadSeleccionado);
      }

      // Filtro por sector/comuna
      if (_sectorController.text.trim().isNotEmpty) {
        query = query.where('comuna', isEqualTo: _sectorController.text.trim());
      }

      // Ejecutar consulta
      final snapshot = await query.get();
      
      // Filtrar resultados en memoria (para cercanías e incluye)
      List<DocumentSnapshot> resultados = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Filtrar por cercanías
        if (_cercaniaSeleccionada.isNotEmpty) {
          final cercanias = List<String>.from(data['cercanias'] ?? []);
          bool tieneCercania = _cercaniaSeleccionada.any(
            (cercania) => cercanias.contains(cercania)
          );
          if (!tieneCercania) return false;
        }

        // Filtrar por "Incluye"
        if (_incluyeSeleccionado.isNotEmpty) {
          for (String opcion in _incluyeSeleccionado) {
            final campo = _opcionesIncluye[opcion];
            if (campo != null && data[campo] != true) {
              return false;
            }
          }
        }

        return true;
      }).toList();

      setState(() => _cargando = false);

      // Navegar a pantalla de resultados
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchResultsScreen(
              resultados: resultados,
              filtrosAplicados: {
                'tipo': _tipoPropiedadSeleccionado,
                'comuna': _sectorController.text.trim().isNotEmpty 
                    ? _sectorController.text.trim() 
                    : null,
                'cercanias': _cercaniaSeleccionada,
                'incluye': _incluyeSeleccionado,
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error en búsqueda: $e');
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al buscar: $e')),
        );
      }
    }
  }

  Widget _buildBotonToggle(String texto) {
    final bool seleccionado = _modoSeleccionado == texto.toLowerCase();
    final colors = Theme.of(context).colorScheme;

    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          setState(() => _modoSeleccionado = texto.toLowerCase());
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: colors.secondary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: seleccionado ? colors.secondary : Colors.transparent,
          foregroundColor: seleccionado ? colors.onSecondary : colors.secondary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        child: Text(texto),
      ),
    );
  }

  Widget _buildSeccionHeader({
    required String titulo,
    required bool expandido,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            Icon(
              expandido ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipsCercania() {
    final colors = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _opcionesCercania.map((opcion) {
        final bool seleccionado = _cercaniaSeleccionada.contains(opcion.etiqueta);

        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(opcion.icono, size: 16),
              const SizedBox(width: 4),
              Text(opcion.etiqueta),
            ],
          ),
          selected: seleccionado,
          onSelected: (value) {
            setState(() {
              if (value) {
                _cercaniaSeleccionada.add(opcion.etiqueta);
              } else {
                _cercaniaSeleccionada.remove(opcion.etiqueta);
              }
            });
          },
          shape: StadiumBorder(
            side: BorderSide(color: colors.secondary, width: 1.3),
          ),
          backgroundColor: Colors.transparent,
          selectedColor: colors.secondary.withOpacity(0.85),
          checkmarkColor: colors.onSecondary,
          labelStyle: TextStyle(
            color: seleccionado ? colors.onSecondary : colors.secondary,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIncluyeGrid() {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: _opcionesIncluye.keys.map((label) {
        final seleccionado = _incluyeSeleccionado.contains(label);
        return CheckboxListTile(
          value: seleccionado,
          activeColor: colors.secondary,
          title: Text(label),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _incluyeSeleccionado.add(label);
              } else {
                _incluyeSeleccionado.remove(label);
              }
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        centerTitle: true,
        title: SizedBox(
          height: 40,
          child: Image.asset(
            "assets/images/homerLogoBlanco.png",
            fit: BoxFit.contain,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Qué quieres buscar hoy?',
                style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  _buildBotonToggle('Venta'),
                  const SizedBox(width: 12),
                  _buildBotonToggle('Arriendo'),
                ],
              ),
              const SizedBox(height: 24),

              // Tipo de Propiedad
              DropdownButtonFormField<String>(
                value: _tipoPropiedadSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Propiedad',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Departamento', child: Text('Departamento')),
                  DropdownMenuItem(value: 'Casa', child: Text('Casa')),
                ],
                onChanged: (value) => setState(() {
                  _tipoPropiedadSeleccionado = value;
                }),
              ),
              const SizedBox(height: 16),

              // Sector/Comuna
              TextField(
                controller: _sectorController,
                decoration: const InputDecoration(
                  labelText: 'Ingresar Comuna',
                  hintText: 'Ej: Las Condes, Providencia, Ñuñoa',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 8),

              // CERCANÍA CON
              _buildSeccionHeader(
                titulo: 'Cercanía con',
                expandido: _cercaniaExpandida,
                onTap: () => setState(() {
                  _cercaniaExpandida = !_cercaniaExpandida;
                }),
              ),
              if (_cercaniaExpandida) _buildChipsCercania(),
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 8),

              // INCLUYE
              _buildSeccionHeader(
                titulo: 'Incluye',
                expandido: _incluyeExpandido,
                onTap: () => setState(() {
                  _incluyeExpandido = !_incluyeExpandido;
                }),
              ),
              if (_incluyeExpandido) _buildIncluyeGrid(),
              const SizedBox(height: 32),

              // BOTÓN BUSCAR
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _realizarBusqueda,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.secondary,
                    foregroundColor: colors.onSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  child: _cargando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Buscar'),
                ),
              ),
            ],
          ),
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

class OpcionCercania {
  final String etiqueta;
  final IconData icono;

  const OpcionCercania(this.etiqueta, this.icono);
}