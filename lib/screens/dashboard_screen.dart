import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io'; // Pour File
import 'package:image_picker/image_picker.dart'; // Import pour la galerie
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data'; // Absolument nécessaire
import 'modifier_photo_page.dart';

class DashboardScreen extends StatefulWidget {
  final String role;
  final String userName; // Ajoute cette ligne
const DashboardScreen({super.key, required this.role, required this.userName});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}
class _DashboardScreenState extends State<DashboardScreen> {
  // --- CONTROLLERS ---
  File? _imageFile; 
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final MapController _mapController = MapController();
int _currentIndex = 0; // L'onglet par défaut (Explorer)

  // --- VARIABLES ---
  // On utilise une variable locale pour gérer l'affichage, 
  // initialisée directement avec la valeur passée par le Login
  String displayName = "Chargement...";

  @override
  void initState() {
    super.initState();
    // On initialise displayName avec la valeur reçue du Login
   displayName = widget.userName.isEmpty ? "Utilisateur ZÉ" : widget.userName;
  _loadUserData(); 
  _loadSavedImage(); 
  _loadLastImage();
}

  // Exemple d'affichage dans le Dashboard
String getTitle() {
  if (widget.role == "CLIENT") return "Mon Espace Client";
  if (widget.role == "ZEDMAN") return "Espace Zédman";
  if (widget.role == "TAXIMAN") return "Espace Taximan";
  if (widget.role == "LIVREUR") return "Espace Livreur";
  return "Mon Compte ZÉ";
}

  // --- STATE ---
  List<dynamic> _suggestions = [];
  bool _isSearchingStart = true;
  bool _isLoadingLocation = false;
  bool _isWaitingForDriver = false;
  bool _isTimeSelected = false; 
  String? _selectedService; 
  String? _savedImagePath; // Pour stocker le chemin de l'image sauvegardée

  LatLng _startPoint = const LatLng(6.1375, 1.2125); 
  LatLng? _destinationPoint;
  LatLng? _chauffeurPoint;

  String userName = "Chargement...";
  double distanceKm = 0.0;
  int prixTotal = 0;
  DateTime? _scheduledDateTime; 

  // --- COULEURS CHARTE ---
  final Color zeGreenDark = const Color(0xFF008C3D);
  final Color zeOrange = const Color(0xFFFF7A00);
  final Color zeYellow = const Color(0xFFFFCF31);
  final Color zeGreenLight = const Color(0xFF6AE870);

  // --- LOGIQUE COMMUNE ---

  void _resetBookingData() {
    setState(() {
      _startController.clear();
      _destinationController.clear();
      _destinationPoint = null;
      _suggestions = [];
      _isTimeSelected = false;
      _scheduledDateTime = null;
      distanceKm = 0.0;
      prixTotal = 0;
      _isWaitingForDriver = false;
    });
  }

   void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != null) {
      setState(() => displayName = user.displayName!);
    } else {
      final prefs = await SharedPreferences.getInstance();
      String? savedName = prefs.getString('user_name');
      if (savedName != null) {
        setState(() => displayName = savedName);
      }
    }
  }

  void _ecouterPositionChauffeur(String courseId) {
    FirebaseFirestore.instance
        .collection('offres_courses')
        .doc(courseId)
        .snapshots()
        .listen((snap) {
      if (snap.exists) {
        var data = snap.data() as Map<String, dynamic>;
        if (data['chauffeur_lat'] != null && data['chauffeur_lon'] != null) {
          if (mounted) {
            setState(() {
              _chauffeurPoint = LatLng(data['chauffeur_lat'], data['chauffeur_lon']);
            });
          }
        }
        if (data['statut'] == 'TERMINEE') {
           _resetBookingData();
        }
      }
    });
  }

  Future<void> _faireAppel(String telephone) async {
    final Uri launchUri = Uri(scheme: 'tel', path: telephone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _getCurrentLocation() async {
      setState(() => _isLoadingLocation = true);    
      try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _startPoint = LatLng(position.latitude, position.longitude);
          _mapController.move(_startPoint, 15.0);
          _startController.text = "Ma position actuelle"; 
          _isLoadingLocation = false;
          _calculateDistanceAndPrice();
        });
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }
  void _calculateDistanceAndPrice() {
    if (_destinationPoint != null) {
      const Distance distanceCalc = Distance();
      double meter = distanceCalc.as(LengthUnit.Meter, _startPoint, _destinationPoint!);
      double distance = double.parse((meter / 1000).toStringAsFixed(1));

     // Détermination du tarif selon le service
    int tarifAuKm;
    switch (_selectedService) {
      case 'ZEMIDJAN':
        tarifAuKm = 150;
        break;
      case 'TAXI':
      default:
        tarifAuKm = 100;
        break;
    }

      setState(() {
        distanceKm = distance;
        prixTotal = (distanceKm * tarifAuKm).toInt();
        if (prixTotal < 500) prixTotal = 500; 
      });
    }
  }
Future<void> _loadLastImage() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    // On récupère le chemin de la dernière image mise
    _savedImagePath = prefs.getString('user_profile_image');
  });
}
// 1. Charger l'image au démarrage
  Future<void> _loadSavedImage() async {
  final prefs = await SharedPreferences.getInstance();
  final String? imagePath = prefs.getString('user_profile_image');
  if (imagePath != null) {
    setState(() {
      _savedImagePath = imagePath;
    });
  }
}
  // 2. LOGIQUE DE RECADRAGE (L'ÉDITION)
 Future<void> _pickImage(ImageSource source) async {
  try {
    final XFile? pickedFile = await _picker.pickImage(
      source: source, 
      preferredCameraDevice: CameraDevice.front,
    );

    if (pickedFile != null) {
      // 1. On prépare le chemin (Path pour Mobile, Blob URL pour Web)
      String imageToEdit = pickedFile.path;

      // 2. On envoie l'image vers la nouvelle page de recadrage
      // Cela remplace l'ancien _cropImage et fonctionne aussi pour le Web
  
final result = await Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => ModifierPhotoPage(imagePath: pickedFile.path)),
);


      // 3. Si l'utilisateur a cliqué sur "Enregistrer" dans ModifierPhotoPage
      if (result != null) {
        setState(() {
          _savedImagePath = result; // Le résultat est déjà en Base64 (DataURL)
          if (!kIsWeb) {
            _imageFile = File(result); 
          }
        });
      }
    }
  } catch (e) {
    print("Erreur de sélection : $e");
  }
}
  // 4. SUPPRESSION
 Future<void> _deleteImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_profile_image');
    setState(() { _savedImagePath = null; _imageFile = null; });
    Navigator.pop(context);
  }

  // 5. FENÊTRE MODALE DESIGN "VITRINE" (ADAPTATIVE)
  void _showProfileOptions() {
    showDialog(
      context: context,
      barrierDismissible: true, // Permet de fermer en cliquant à côté
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A), // Fond sombre vitrine
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min, // La boîte s'adapte au contenu
          children: [
            const Text(
              "Photo de profil",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            
            // Aperçu de l'image actuelle
            CircleAvatar(
              radius: 60,
              backgroundColor: const Color.fromARGB(26, 0, 0, 0),
              child: ClipOval(child: _buildAvatarDisplay(120)),
            ),
            const SizedBox(height: 30),
            
            // Ligne des icônes d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionIcon(Icons.edit_outlined, "Modifier", () async {
                Navigator.pop(context); // Ferme la petite boîte noire
                final String? path = _savedImagePath ?? _imageFile?.path;
                if (path != null) {
             // On ouvre la page de modification et on attend le résultat (la photo rognée)
              final result = await Navigator.push(
              context,
              MaterialPageRoute(
              builder: (context) => ModifierPhotoPage(imagePath: path),
              ),
              );
            // Si on revient avec une photo rognée, on met à jour l'écran principal
            if (result != null) {
            setState(() {
            _savedImagePath = result;
            });
            }
          }
        }),
                _actionIcon(Icons.camera_alt_outlined, "Télécharger", () {
                  Navigator.pop(context); // Ferme la boîte
                  _showSourcePicker(); // Ouvre le choix caméra/galerie
                }),
                _actionIcon(Icons.delete_outline, "Supprimer", () {
                  _deleteImage(); // La fonction de suppression
                }, isDelete: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _actionIcon(IconData icon, String label, VoidCallback onTap, {bool isDelete = false}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: isDelete ? Colors.red : Colors.white70, size: 28),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  // Fenêtre secondaire pour choisir entre Caméra et Galerie
  void _showSourcePicker() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Source", style: TextStyle(color: Colors.white)),
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.white70),
            title: const Text("Appareil Photo", style: TextStyle(color: Colors.white70)),
            onTap: () { 
            Navigator.pop(context); 
           _pickImage(ImageSource.camera); 
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.white70),
            title: const Text("Galerie", style: TextStyle(color: Colors.white70)),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
          ),
        ],
      ),
    );
  }

  
  // 6. WIDGET DE L'AVATAR (APPELÉ DANS LE HEADER)
  Widget _buildUserAvatar() {
    return GestureDetector(
      onTap: _showProfileOptions,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white,
          child: ClipOval(child: _buildAvatarDisplay(56)),
        ),
      ),
    );
  }

  Widget _buildAvatarDisplay(double size) {
  // 1. On récupère le chemin ou la donnée Base64
  final String? path = _savedImagePath ?? _imageFile?.path;

  if (path != null) {
    // CAS 1 : IMAGE EN BASE64 (Générée par le recadrage ou chargée du cache)
    if (path.startsWith('data:image')) {
      try {
        final Uint8List bytes = base64Decode(path.split(',').last);
        return ClipOval(
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      } catch (e) {
        return _buildDefaultAvatar(size);
      }
    }

    // CAS 2 : WEB (Blob URL temporaire)
    if (kIsWeb) {
      return ClipOval(
        child: Image.network(
          path,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(size),
        ),
      );
    } 
    
    // CAS 3 : MOBILE (Fichier local)
    else {
      return ClipOval(
        child: Image.file(
          File(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
  }

  // CAS PAR DÉFAUT : Pas d'image
  return _buildDefaultAvatar(size);
}
// Petit helper pour l'avatar par défaut
Widget _buildDefaultAvatar(double size) {
  return Container(
    color: zeOrange,
    alignment: Alignment.center,
    child: Text(
      widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : "?",
      style: TextStyle(color: Colors.white, fontSize: size * 0.4, fontWeight: FontWeight.bold),
    ),
  );
}


  // ==========================================================
  // LOGIQUE DE NAVIGATION SELON LE RÔLE
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    
    bool isDriver = widget.role != "CLIENT";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      // Dans ton build principal
body: SafeArea(
  child: _currentIndex == 2 
      ? _buildProfileView() // Si onglet Profil
      : (isDriver ? _buildDriverView() : _buildClientView()), // Sinon vue normale
),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- VUE CLIENT ---
  Widget _buildClientView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          _buildWalletSection(),
          _buildPromotionSlider(),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text("Où allons-nous aujourd'hui ?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _buildQuickActions(), // Grille des services avec tes couleurs
          const SizedBox(height: 50),
        ],
      ),
    );
  }
  Widget _buildProfileView() {
  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: Column(
      children: [
        const SizedBox(height: 50),
        const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
        const SizedBox(height: 20),
        Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(widget.role, style: const TextStyle(color: Colors.grey)),
        const Spacer(), // Pousse le bouton vers le bas
        
        // TON BOUTON DE DÉCONNEXION ICI
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: _handleLogout, // La fonction qu'on a créée avant
          icon: const Icon(Icons.exit_to_app, color: Colors.white),
          label: const Text("SE DÉCONNECTER", style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
}

  // --- VUE CHAUFFEUR ---
  Widget _buildDriverView() {
    return Column(
      children: [
        _buildDriverHeader(),
        _buildDriverStats(),
        const Divider(),
        const Padding(
          padding: EdgeInsets.all(15),
          child: Text("Nouvelles offres disponibles", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('offres_courses')
                .where('statut', isEqualTo: 'EN_ATTENTE')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              var courses = snapshot.data!.docs;
              if (courses.isEmpty) return _buildEmptyState("Aucune course à proximité");

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  var data = courses[index].data() as Map<String, dynamic>;
                  return _buildDriverOrderCard(courses[index].id, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // COMPOSANTS UI CHAUFFEUR (LOGIQUE COULEURS SERVICES)
  // ==========================================================


   Widget _buildHeader() {
    return Container(
      width: double.infinity, // Prend toute la largeur
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: zeGreenDark, 
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
          GestureDetector(
          onTap: () => setState(() => _currentIndex = 2), // Redirige vers l'onglet Profil
          child: _buildUserAvatar(),
          ),              
          const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bonjour ${widget.userName}", // Affiche le nom passé depuis le login
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)
                  ),
                  Text(
                    getTitle(), // Affiche "Mon Espace Client"
                    style: const TextStyle(color: Colors.white70, fontSize: 14)
                  ),
                ],
              ),
              const Spacer(),
          // Petit badge "En ligne"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
            child: const Text("EN LIGNE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriverHeader() {
    // On change la couleur du bandeau selon le métier
    Color headerColor = zeGreenDark;
    if (widget.role == "ZEDMAN") headerColor = zeOrange;
    if (widget.role == "TAXIMAN") headerColor = zeYellow;
    if (widget.role == "LIVREUR") headerColor = zeGreenLight;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: headerColor, 
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))
      ),
      child: Row(
        children: [
          GestureDetector(
          onTap: () => setState(() => _currentIndex = 2), // Redirige vers l'onglet Profil
          child: _buildUserAvatar(),
          ), 
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Text(
  "Bonjour $userName", // Utilise displayName ici
  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
),
              Text(
                getTitle(), // Affiche "Espace Zédman" ou "Espace Taximan"
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)
              ),
            ],
          ),
          const Spacer(),
          // Petit badge "En ligne"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
            child: const Text("EN LIGNE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildDriverOrderCard(String docId, Map<String, dynamic> data) {
    // Déterminer la couleur selon le service
    Color serviceColor = data['service'] == 'ZEMIDJAN' ? zeOrange : (data['service'] == 'TAXI' ? zeYellow : zeGreenLight);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 4,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: serviceColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data['service'] ?? "SERVICE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("${data['prix_propose']} FCFA", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.trip_origin, color: Colors.green),
            title: Text(data['depart'], maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: const Text("Point de départ"),
          ),
          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.red),
            title: Text(data['destination'], maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: const Text("Destination"),
          ),
         ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: zeGreenDark,
    minimumSize: const Size(double.infinity, 50), 
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
    ),
  ),
  onPressed: () => _accepterCourseChauffeur(docId, data),
  child: const Text(
    "ACCEPTER LA COURSE", 
    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  ),
)
        ],
      ),
    );
  }

  void _accepterCourseChauffeur(String id, Map<String, dynamic> data) async {
    Position pos = await Geolocator.getCurrentPosition();
    await FirebaseFirestore.instance.collection('offres_courses').doc(id).update({
      'statut': 'ACCEPTEE',
      'chauffeur_nom': userName,
      'chauffeur_lat': pos.latitude,
      'chauffeur_lon': pos.longitude,
      'chauffeur_tel': '90000000', // À dynamiser plus tard
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Course acceptée ! Allez vers ${data['depart']}")));
  }


  // ==========================================================
  // COMPOSANTS UI CLIENT (TA LOGIQUE INITIALE)
  // ==========================================================

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _serviceTile(Icons.motorcycle, "ZEMIDJAN", zeOrange),
          const SizedBox(height: 10),
          _serviceTile(Icons.local_taxi, "TAXI", zeYellow),
          const SizedBox(height: 10),
          _serviceTile(Icons.shopping_bag, "LIVRAISON", zeGreenLight),
        ],
      ),
    );
  }

  Widget _serviceTile(IconData icon, String title, Color color) {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: color.withOpacity(0.3))),
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.white)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: () => _openBookingSheet(title),
    );
  }

  // --- MODALS DE COMMANDE CLIENT (TES FONCTIONS ORIGINALES) ---

 void _openBookingSheet(String service) {
  setState(() {
    _resetBookingData();
    _isTimeSelected = false; 
    _scheduledDateTime = null;
    _selectedService = service;
  });

  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Text("Commander un $service", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _isTimeSelected = true);
                      _showMainOrderSheet(service);
                    },
                    child: const Text("Maintenant"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      // Utilise un Future pour attendre la fin
                      await Future.delayed(const Duration(milliseconds: 100));
                      if (!mounted) return;
                      await _showFrenchDateTimePickerDialog();
                      if (_scheduledDateTime != null && mounted) {
                        _showMainOrderSheet(service);
                      }
                    },
                    child: const Text("Plus tard"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 15),
                      Text("Votre trajet ($service)", style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (_scheduledDateTime != null)
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: zeOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: zeOrange.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today, color: zeOrange, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd MMMM à HH:mm', 'fr_FR').format(_scheduledDateTime!),
                                style: TextStyle(color: zeOrange, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      if (_isTimeSelected) ...[
                        _buildSuggestionsList(setModalState),
                        const SizedBox(height: 10),
                        _buildSearchInputs(setModalState),
                      ],
                      const SizedBox(height: 20),
                      _buildMapContainer(setModalState),
                      const SizedBox(height: 20),
                      if (_destinationPoint != null) 
                        _buildOrderPanel(setModalState) 
                      else 
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: const Text(
                            "Indiquez votre destination", 
                            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)
                          ),
                        ),
                      TextButton(
                        onPressed: () { 
                          _resetBookingData(); 
                          Navigator.pop(context); 
                        }, 
                        child: const Text("Annuler", style: TextStyle(color: Colors.grey))
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    ),
  );
}

// Fonction pour afficher le sélecteur de date/heure avec design français
Future<void> _showFrenchDateTimePickerDialog() async {
  DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 365)),
    locale: const Locale('fr', 'FR'),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: zeOrange,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black87,
          ),
          dialogBackgroundColor: Colors.white,
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: zeOrange,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        child: child!,
      );
    },
  );

  if (pickedDate != null && mounted) {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: zeOrange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: zeOrange,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
      },
    );

    if (pickedTime != null && mounted) {
      setState(() {
        _scheduledDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        _isTimeSelected = true;
      });
    }
  }
}
  Widget _buildMapContainer(StateSetter setModalState) {
    return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Stack(
      children: [
        // 1. LA CARTE (Toujours visible)
    Container(
      height: 250, width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _startPoint,
            initialZoom: 14.0,
            onTap: (tapPosition, point) {
              setModalState(() {
                _destinationPoint = point;
                _destinationController.text = "${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}";
                _calculateDistanceAndPrice();
              });
            }
          ),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
            MarkerLayer(markers: [
              Marker(point: _startPoint, child: Icon(Icons.my_location, color: zeGreenDark)),
              if (_destinationPoint != null) Marker(point: _destinationPoint!, child: const Icon(Icons.location_on, color: Colors.red)),
              if (_chauffeurPoint != null) Marker(point: _chauffeurPoint!, child: Icon((_selectedService == 'ZEMIDJAN') ? Icons.motorcycle : Icons.local_taxi, color: Colors.blue, size: 40)),
            
            ]),
          ],
        ),
        
      ),
       ),
    // 2. LA BARRE DE CHARGEMENT (Apparaît seulement si _isLoadingLocation est vrai)
        if (_isLoadingLocation)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              color: Colors.green,
              minHeight: 4,
            ),
          ),
      ],
    ),
  );
}

  Widget _buildOrderPanel(StateSetter setModalState) {
    return Container(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Text("Distance: ${distanceKm}km", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$prixTotal FCFA", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: zeGreenDark),
                onPressed: _isWaitingForDriver ? null : () async {
                  setModalState(() => _isWaitingForDriver = true);
                  DocumentReference docRef = await FirebaseFirestore.instance.collection('offres_courses').add({
                    'client_nom': userName,
                    'prix_propose': prixTotal,
                    'depart': _startController.text,
                    'destination': _destinationController.text,
                    'service': _selectedService,
                    'statut': 'EN_ATTENTE',
                    'is_reservation': _scheduledDateTime != null,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                  _showWaitingPanel(docRef.id);
                },
                child: _isWaitingForDriver ? const CircularProgressIndicator(color: Colors.white) : const Text("COMMANDER", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- RECHERCHE D'ADRESSES (TA LOGIQUE ORIGINALE) ---

  Widget _buildSearchInputs(StateSetter setModalState) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        _buildInputField(_startController, "Ma position", true, setModalState),
        const Divider(),
        _buildInputField(_destinationController, "Où allez-vous ?", false, setModalState),
      ]),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint, bool isStart, StateSetter setModalState) {
    return TextField(
      controller: controller,
      onTap: () => setModalState(() => _isSearchingStart = isStart),
      onChanged: (val) async {
        if (val.length > 2) {
          final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$val&format=json&countrycodes=tg&limit=5');
          final response = await http.get(url, headers: {'User-Agent': 'ZeConnectApp'});
          if (response.statusCode == 200) setModalState(() => _suggestions = json.decode(response.body));
        } else {
          setModalState(() => _suggestions = []);
        }
      },
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(isStart ? Icons.trip_origin : Icons.location_on, color: isStart ? zeGreenDark : Colors.red),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildSuggestionsList(StateSetter setModalState) {
    if (_suggestions.isEmpty && !(_isSearchingStart && _startController.text.isEmpty)) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      child: ListView(
        shrinkWrap: true,
        children: [
          if (_isSearchingStart && _startController.text.isEmpty)
            ListTile(
              leading: Icon(Icons.gps_fixed, color: zeGreenDark),
              title: const Text("Utiliser ma position actuelle"),
              onTap: () { _getCurrentLocation(); setModalState(() => _suggestions = []); },
            ),
          ..._suggestions.map((s) => ListTile(
            title: Text(s['display_name'], style: const TextStyle(fontSize: 12)),
            onTap: () {
              setModalState(() {
                LatLng pos = LatLng(double.parse(s['lat']), double.parse(s['lon']));
                if (_isSearchingStart) { _startPoint = pos; _startController.text = s['display_name']; }
                else { _destinationPoint = pos; _destinationController.text = s['display_name']; }
                _suggestions = [];
                _calculateDistanceAndPrice();
                _mapController.move(pos, 14.0);
              });
            },
          )),
        ],
      ),
    );
  }

  // --- STATUT ET ATTENTE (TES FONCTIONS) ---

  void _showWaitingPanel(String courseId) {
    showModalBottomSheet(
      context: context, isDismissible: false,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const LinearProgressIndicator(color: Colors.green),
          const SizedBox(height: 20),
          const Text("Recherche de chauffeurs..."),
          const Spacer(),
          ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("ANNULER")),
        ]),
      ),
    );
    _ecouterStatutCourse(courseId);
  }

  void _ecouterStatutCourse(String courseId) {
    FirebaseFirestore.instance.collection('offres_courses').doc(courseId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        if (data['statut'] == 'ACCEPTEE') {
          if (Navigator.canPop(context)) Navigator.pop(context);
          _showDriverFoundDialog(data);
          _ecouterPositionChauffeur(courseId);
        }
      }
    });
  }

  void _showDriverFoundDialog(Map<String, dynamic> data) {
    showModalBottomSheet(context: context, builder: (context) => _buildDriverInfos(data));
  }

  Widget _buildDriverInfos(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(data['chauffeur_nom'] ?? "Chauffeur"),
          trailing: IconButton(icon: const Icon(Icons.phone, color: Colors.green), onPressed: () => _faireAppel(data['chauffeur_tel'])),
        ),
      ]),
    );
  }

Future<void> _handleLogout() async {
  // 1. Déconnexion de Firebase
  await FirebaseAuth.instance.signOut();
  
  // 2. Déconnexion de Google (si utilisé)
  await GoogleSignIn().signOut();

  // 3. Nettoyage du nom et du rôle sauvegardés sur le téléphone
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  if (!mounted) return;

  // 4. Retour à l'écran de Login et effacement de tout l'historique de navigation
  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
}

  // --- UI ACCESSOIRES ---



  Widget _buildWalletSection() {
    return Container(
      margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Row(children: [
        Icon(Icons.account_balance_wallet, color: zeGreenDark),
        const SizedBox(width: 10),
        const Text("Solde: 0 F CFA"),
        const Spacer(),
        ElevatedButton(onPressed: () {}, child: const Text("Recharger"))
      ]),
    );
  }

  Widget _buildPromotionSlider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 50,
      decoration: BoxDecoration(color: zeOrange, borderRadius: BorderRadius.circular(15)),
      child: const Center(child: Text("PROMO : -20% sur votre trajet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildDriverStats() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _statItem("Gains", "0 F"),
      _statItem("Courses", "0"),
      _statItem("Note", "5.0"),
    ]);
  }

  Widget _statItem(String label, String value) {
  return Column(
    children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ],
  );
}

 // 2. Pour le message quand il n'y a pas de courses
Widget _buildEmptyState(String message) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          Icon(Icons.inbox, size: 50, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    ),
  );
}
  

  Widget _buildBottomNav() {
  return BottomNavigationBar(
    currentIndex: _currentIndex, // L'onglet actif
    onTap: (index) {
      setState(() {
        _currentIndex = index; // On change d'onglet
      });
    },
    selectedItemColor: zeGreenDark,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Explorer"),
      BottomNavigationBarItem(icon: Icon(Icons.history), label: "Activité"),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
    ],
  );
}
}

