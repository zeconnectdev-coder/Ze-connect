import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'modifier_photo_page.dart'; 

class ProfilePage extends StatefulWidget {
  final String name;
  final String role;

  static const Color zeGreen = Color(0xFF0F2E14);
  static const Color zeOrange = Color.fromRGBO(255, 122, 0, 1);

  const ProfilePage({super.key, required this.name, required this.role});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _savedImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSavedImage();
  }

  // --- LOGIQUE EXTRAITE DE TON ANCIEN DASHBOARD ---

  Future<void> _loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedImagePath = prefs.getString('user_profile_image');
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      // On envoie vers la page de modification (ton nouveau système)
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ModifierPhotoPage(imagePath: pickedFile.path),
        ),
      );

      if (result != null) {
        setState(() {
          _savedImagePath = result;
        });
      }
    }
  }

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("Choisir depuis la galerie"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Prendre une photo"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  // --- INTERFACE (UI) EXTRAITE DE TON DASHBOARD ---

  @override
  Widget build(BuildContext context) {
    bool isDriver = widget.role == "ZEDMAN" || widget.role == "TAXIMAN" || widget.role == "LIVREUR";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Mon Profil", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // L'Avatar 
            Center(
              child: GestureDetector(
                onTap: _showProfileOptions,
                child: Stack(
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF008C3D), width: 3),
                      ),
                      child: ClipOval(
                        child: _buildAvatarDisplay(130),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: const Color(0xFF008C3D),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(widget.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            Text(
              widget.role,
              style: TextStyle(color: isDriver ? ProfilePage.zeOrange : Colors.grey[600], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            
            // Les boutons d'options (Comme dans ton dashboard)
            _buildOptionItem(Icons.person_outline, "Informations personnelles"),
            if (isDriver) _buildOptionItem(Icons.verified_user, "Documents du véhicule"),
            _buildOptionItem(Icons.history, "Historique des courses"),
            _buildOptionItem(Icons.payment, "Portefeuille / Paiement"),
            _buildOptionItem(Icons.settings, "Paramètres"),
            const SizedBox(height: 30),
            // Bouton déconnexion
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text("Déconnexion", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarDisplay(double size) {
    if (_savedImagePath != null && _savedImagePath!.isNotEmpty) {
      if (_savedImagePath!.startsWith('data:image')) {
        return Image.memory(
          base64Decode(_savedImagePath!.split(',').last),
          fit: BoxFit.cover,
        );
      }
    }
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.person, size: size * 0.6, color: Colors.grey[400]),
    );
  }

 Widget _buildOptionItem(IconData icon, String title) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF008C3D).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF008C3D), size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: () {},
    );
  }
}