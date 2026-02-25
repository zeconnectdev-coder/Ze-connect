import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class ModifierPhotoPage extends StatefulWidget {
  final String imagePath;
  const ModifierPhotoPage({super.key, required this.imagePath});

  @override
  State<ModifierPhotoPage> createState() => _ModifierPhotoPageState();
}

class _ModifierPhotoPageState extends State<ModifierPhotoPage> {
  final _cropController = CropController();
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = kIsWeb 
          ? (await NetworkAssetBundle(Uri.parse(widget.imagePath)).load(widget.imagePath)).buffer.asUint8List()
          : await File(widget.imagePath).readAsBytes();
      setState(() => _imageBytes = bytes);
    } catch (e) {
      debugPrint("Erreur chargement image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Modifier", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => _cropController.crop(),
            child: const Text("Enregistrer", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _imageBytes == null 
                ? const Center(child: CircularProgressIndicator(color: Colors.white)) 
                : Crop(
                    image: _imageBytes!,
                    controller: _cropController,
                   onCropped: (result) async { // On l'appelle result
  // On vérifie si le résultat est un succès et on récupère les bytes
  if (result is CropSuccess) {
    final Uint8List imageBytes = result.croppedImage;

    // 1. Convertir en Base64
    final String base64Image = base64Encode(imageBytes);
    final String dataUrl = "data:image/png;base64,$base64Image";

    // 2. Sauvegarde
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile_image', dataUrl);

    if (mounted) Navigator.pop(context, dataUrl);
  } else if (result is CropFailure) {
    print("Erreur de rognage");
  }
},
                    withCircleUi: true,
                    maskColor: Colors.black.withOpacity(0.7),
                    baseColor: Colors.black,
                  ),
          ),
          // Barre de menu style LinkedIn (Filtres/Ajuster)
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _bottomAction(Icons.crop, "Rogner", isSelected: true),
                _bottomAction(Icons.auto_awesome, "Filtres"),
                _bottomAction(Icons.tune, "Ajuster"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomAction(IconData icon, String label, {bool isSelected = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isSelected ? Colors.blue : Colors.grey, size: 28),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: isSelected ? Colors.blue : Colors.grey, fontSize: 12)),
      ],
    );
  }
}