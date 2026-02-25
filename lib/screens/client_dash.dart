import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'profile_page.dart'; 


class ClientDash extends StatefulWidget {
const ClientDash({super.key, required this.userName, required this.role});
  final String userName;
  final String role;

  @override
  State<ClientDash> createState() => _ClientDash();
}

class _ClientDash extends State<ClientDash> {
  // --- VARIABLES ET CONTROLLERS ---
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final MapController _mapController = MapController();
  
  LatLng? _currentLocation;
  LatLng? _startPoint;
  LatLng? _destinationPoint;
  
  List<dynamic> _suggestions = [];
  bool _isStartSearch = true;
  bool _isSearchingStart = true;
  String _userName = "Utilisateur";
  
  // --- ÉTAT RÉSERVATION ---
  DateTime? _scheduledDateTime;
  bool _isTimeSelected = false;

  // --- COULEURS CHARTE ---
  final Color zeGreenDark = const Color(0xFF008C3D);
  final Color zeOrange = const Color(0xFFFF7A00);
  final Color zeYellow = const Color(0xFFFFCF31);
  final Color zeGreenLight = const Color(0xFF6AE870);

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "Utilisateur";
    });
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _startPoint = _currentLocation;
      });
    }
  }

  Future<void> _useCurrentLocation(StateSetter setModalState) async {
  // 1. Vérifier si le GPS est activé
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Veuillez activer votre GPS")),
    );
    return;
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;
  }

  // 3. Demander confirmation à l'utilisateur
  bool? confirm = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Position GPS"),
      content: const Text("Voulez-vous utiliser votre position actuelle comme point de départ ?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Non, saisir")),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Oui, utiliser")),
      ],
    ),
  );

  if (confirm == true) {
    Position position = await Geolocator.getCurrentPosition();
    LatLng current = LatLng(position.latitude, position.longitude);
    
    setState(() {
      _startPoint = current;
      _startController.text = "Ma position actuelle"; // Texte affiché dans le champ
      _mapController.move(current, 15.0); // Centre la carte sur la position
    });
    
    // Met à jour l'affichage dans le BottomSheet ouvert
    setModalState(() {}); 
  }
}

  Future<void> _searchLocation(String query) async {
  if (query.isEmpty) {
    setState(() => _suggestions = []);
    return;
  }
  final url = "https://nominatim.openstreetmap.org/search?format=json&q=$query&countrycodes=tg&addressdetails=1&limit=10";
  
  try {
    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'ZE_App_Client', // Identifiant pour éviter les blocages OSM
    });

    if (response.statusCode == 200) {
      setState(() {
        _suggestions = json.decode(response.body);
      });
    }
  } catch (e) {
    debugPrint("Erreur lors de la recherche : $e");
  }
}
  // --- LOGIQUE DE RÉSERVATION ---

  void _showMainOrderSheet(String service) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Center(
            child: SingleChildScrollView(
              child: Dialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 15),
                      Text("Votre trajet ($service)", style: const TextStyle(fontWeight: FontWeight.bold)),
                      
                      // Sélection de l'heure
                      TextButton.icon(
                        onPressed: () => _showFrenchDateTimePickerDialog(setModalState),
                        icon: Icon(Icons.calendar_today, color: zeOrange),
                        label: Text(_scheduledDateTime == null 
                          ? "Planifier un départ" 
                          : DateFormat('dd MMMM à HH:mm', 'fr_FR').format(_scheduledDateTime!),
                          style: TextStyle(color: zeOrange)
                        ),
                      ),

                      const Divider(),
                      _buildInputField(_startController, "Point de départ", true, setModalState),
                      _buildInputField(_destinationController, "Destination", false, setModalState),
                      
                      if (_suggestions.isNotEmpty) _buildSuggestionsList(setModalState),

                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed:  _isTimeSelected ? () {
                         if (_startPoint != null && _destinationPoint != null) {
                        FirebaseFirestore.instance.collection('rides').add({
                        'depart': GeoPoint(_startPoint!.latitude, _startPoint!.longitude),
                        'arrivee': GeoPoint(_destinationPoint!.latitude, _destinationPoint!.longitude),
                        'client': _userName,
                        'date': _scheduledDateTime ?? DateTime.now(),
                        });
                         Navigator.pop(context);
                         }
                       } : null,            
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isTimeSelected ? zeGreenDark : Colors.grey,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                        ),
                        child: Text(
                        _isTimeSelected ? "CONFIRMER LA COURSE" : "CHOISISSEZ UNE HEURE",
                        style: const TextStyle(color: Colors.white)
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Future<void> _showFrenchDateTimePickerDialog(StateSetter setModalState) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setModalState(() {
          _scheduledDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
          _isTimeSelected = true;
        });
        setState(() {}); // Update main UI too
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String firstName = widget.userName.split(' ').first;
    return Scaffold(
      body: Stack(
        children: [
          // 1. LA CARTE
          FlutterMap(
  mapController: _mapController,
  options: MapOptions(
    initialCenter: _currentLocation ?? const LatLng(6.3654, 2.4183),
    initialZoom: 13.0,
  ),
  children: [
    TileLayer(
      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
      userAgentPackageName: 'com.example.ze_connect',
    ),
    
    // Ton marqueur de position actuelle (on ne touche à rien)
    if (_currentLocation != null)
      MarkerLayer(
        markers: [
          Marker(
            point: _currentLocation!,
            width: 40, height: 40,
            child: Icon(Icons.location_on, color: zeGreenDark, size: 40),
          ),
        ],
      ),

    // --- AJOUT DU STREAMBUILDER POUR LES CHAUFFEURS ---
    StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('drivers')
          .where('isOnline', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        // Création de la liste des marqueurs chauffeurs
        final driverMarkers = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final lat = data['lat'] ?? 0.0;
          final lng = data['lng'] ?? 0.0;
          final type = data['type'] ?? 'ZEDMAN';

          return Marker(
            point: LatLng(lat, lng),
            width: 40,
            height: 40,
            child: Icon(
              type == 'ZEDMAN' ? Icons.motorcycle : Icons.local_taxi,
              color: Colors.green, // Vert pour indiquer qu'ils sont actifs
              size: 30,
            ),
          );
        }).toList();

        return MarkerLayer(markers: driverMarkers);
      },
    ),
  ],
),

          // 2. LE HEADER (Utilise ta couleur ProfileScreen.zeGreen)
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
              decoration: BoxDecoration(
                color: zeGreenDark, 
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
  onTap: () {
    // C'est cette ligne qui utilise ProfileScreen et enlève le JAUNE
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(name: _userName, role: "CLIENT"),
      ),
    );
  },
  child: Text(
    "Bonjour, $firstName", 
    style: const TextStyle(
      color: Colors.white, 
      fontSize: 18, 
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.underline, // Optionnel: pour montrer que c'est cliquable
    )
  ),
),
                    ],
                  ),  
                ],
              ),
            ),
          ),

          // 3. SUGGESTIONS SUR LA CARTE
          if (_suggestions.isNotEmpty)
            Positioned(
              top: 200, left: 20, right: 20,
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_suggestions[index]['display_name'], style: const TextStyle(fontSize: 12)),
                      onTap: () {
                        setState(() {
                          if (_isStartSearch) {
                            _startController.text = _suggestions[index]['display_name'];
                          } else {
                            _destinationController.text = _suggestions[index]['display_name'];
                          }
                          _suggestions = [];
                        });
                      },
                    );
                  },
                ),
              ),
            ),
            
          // 4. LES BOUTONS DE SERVICE EN BAS
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: _buildQuickActions(),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE SUPPORT ---
Widget _buildInputField(TextEditingController controller, String hint, bool isStart, StateSetter setModalState) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    margin: const EdgeInsets.symmetric(vertical: 5),
    decoration: BoxDecoration(
      color: Colors.grey[100], 
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: InputBorder.none,
        // Icône dynamique : GPS pour le départ, Recherche pour la destination
        suffixIcon: isStart 
          ? IconButton(
              icon: const Icon(Icons.my_location, color: Color(0xFF008C3D)),
              onPressed: () => _useCurrentLocation(setModalState),
            )
          : const Icon(Icons.location_on, color: Colors.red),
      ),
      onChanged: (value) {
        _isStartSearch = isStart;
        _searchLocation(value);
      },
    ),
  );
}
  

  Widget _buildSuggestionsList(StateSetter setModalState) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      child: ListView(
        shrinkWrap: true,
        children: _suggestions.map((s) => ListTile(
          title: Text(s['display_name'], style: const TextStyle(fontSize: 11)),
          onTap: () {
            setModalState(() {
              if (_isSearchingStart) { _startController.text = s['display_name']; }
              else { _destinationController.text = s['display_name']; }
              _suggestions = [];
            });
          },
        )).toList(),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _actionButton(Icons.motorcycle, "ZED", zeOrange),
          _actionButton(Icons.local_taxi, "TAXI", zeYellow),
          _actionButton(Icons.delivery_dining, "LIVRAISON", zeGreenLight),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () => _showMainOrderSheet(label),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}