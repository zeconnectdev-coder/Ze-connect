import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; 
import 'register_screen.dart';
import 'main_navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  final Color zeGreenDark = const Color(0xFF008C3D);  
  final Color zeGreenLight = const Color(0xFF6AE870); 
  final Color zeOrange = const Color(0xFFFF7A00);     
  final Color zeYellow = const Color(0xFFFFCF31);     

  String _selectedRole = "CLIENT"; 
  bool _rememberMe = false; 

  @override
  void initState() {
    super.initState();
    _loadSavedAccount();
  }

  Future<void> _loadSavedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('saved_email') ?? "";
      _rememberMe = _emailController.text.isNotEmpty;
    });
  }

  Future<void> _saveAccount() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', _emailController.text.trim());
    } else {
      await prefs.remove('saved_email');
    }
  }

  // --- LOGIQUE DE NAVIGATION UNIFIÉE (L'AIGUILLAGE) ---
  void _goToDashboard(User? user) async {
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    
    // 1. Récupération des infos Firestore pour être sûr du rôle
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    
    String role;
    String realName;
    role = _selectedRole;
    if (userDoc.exists) {
      realName = userDoc['nom'] ?? user.displayName ?? "Utilisateur ZÉ";
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'role': role,
      });
    } else {
      
      realName = user.displayName ?? user.email?.split('@')[0] ?? "Utilisateur ZÉ";
      
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'nom': realName,
        'email': user.email,
        'role': role, 
        'date_inscription': DateTime.now(),
        'statut_compte': 'ACTIF',
      }, SetOptions(merge: true));
    }
    
    await prefs.setString('user_name', realName);
    await prefs.setString('user_role', role);

    if (!mounted) return;

    // --- SYSTÈME D'AIGUILLAGE VERS LES 4 PROFILS ---
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => MainNavigation(
          role: role, 
          userName: realName
        )
      ),
      (route) => false,
    );
  }

  void _handleLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isNotEmpty && password.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Material(
          color: Colors.black54,
          child: Center(child: CircularProgressIndicator(color: zeGreenDark)),
        ),
      );

      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (mounted) Navigator.pop(context); // Ferme le loader
        await _saveAccount();
        _goToDashboard(userCredential.user);

      } on FirebaseAuthException catch (e) {
        if (mounted) Navigator.pop(context);
        String message = "Erreur de connexion";
        if (e.code == 'user-not-found') message = "Compte inexistant.";
        else if (e.code == 'wrong-password') message = "Mot de passe erroné.";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; 

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      _goToDashboard(userCredential.user); // Utilise l'aiguillage unifié

    } catch (e) {
      debugPrint("Erreur Google SignIn: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Échec de la connexion Google")),
      );
    }
  }

  // --- COMPOSANTS UI ---
  Widget _roleBadge(String role, IconData icon, Color color) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.grey[100],
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
            ),
            child: Icon(icon, color: isSelected ? Colors.white : Colors.grey[400], size: 28),
          ),
          const SizedBox(height: 8),
          Text(role, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? color : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, bool isObscure, IconData icon) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey[400]),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
      ),
    );
  }

  Widget _socialButton(String label, String iconUrl, VoidCallback action) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: action, 
        icon: Image.network(iconUrl, height: 20, errorBuilder: (c, e, s) => const Icon(Icons.login)),
        label: Text(label, style: const TextStyle(color: Colors.black87, fontSize: 12)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const Icon(Icons.directions_bike, size: 50, color: Color(0xFF008C3D)),
            const SizedBox(height: 10),
            Text("Bon retour !", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: zeGreenDark)),
            const SizedBox(height: 30),
            const Text("Je me connecte en tant que :", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _roleBadge("CLIENT", Icons.person, zeGreenDark),
                _roleBadge("ZEDMAN", Icons.motorcycle, zeOrange),
                _roleBadge("TAXIMAN", Icons.local_taxi, zeYellow),
                _roleBadge("LIVREUR", Icons.delivery_dining, zeGreenLight),
              ],
            ),
            const SizedBox(height: 35),
            _buildTextField(_emailController, "E-mail", false, Icons.email_outlined),
            const SizedBox(height: 15),
            _buildTextField(_passwordController, "Mot de passe", true, Icons.lock_outline),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: zeGreenDark,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _handleLogin,
              child: const Text("SE CONNECTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                _socialButton("Google", "https://cdn1.iconfinder.com/data/icons/google_jfk_icons_by_om_21/32/google.png", _handleGoogleSignIn),
              ],
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
              },
              child: const Text("Pas de compte ? Inscrivez-vous"),
            )
          ],
        ),
      ),
    );
  }
}