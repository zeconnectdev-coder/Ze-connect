import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Ajouté
import 'package:cloud_firestore/cloud_firestore.dart'; // Ajouté
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();


  // Contrôleurs
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _matriculeController = TextEditingController();

  // Charte graphique ZÉ-CONNECT
  final Color zeGreenDark = const Color(0xFF008C3D);  
  final Color zeGreenLight = const Color(0xFF6AE870); 
  final Color zeOrange = const Color(0xFFFF7A00);     
  final Color zeYellow = const Color(0xFFFFCF31);     

  String _selectedRole = "CLIENT";

  // --- LOGIQUE DE REDIRECTION ET SAUVEGARDE FIRESTORE ---
  void _goToDashboard(User? user) async {
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    
    // 1. Récupération du nom (pour Google ou Inscription classique)
    String realName = user.displayName ?? "${_firstNameController.text} ${_lastNameController.text}";
    if (realName.trim().isEmpty) realName = user.email?.split('@')[0] ?? "Utilisateur ZÉ";

    // 2. Sauvegarde locale
    await prefs.setString('user_name', realName);
    await prefs.setString('user_role', _selectedRole);

    // 3. Inscription automatique dans Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'nom': realName,
      'email': user.email,
      'role': _selectedRole, // ZEDMAN, TAXIMAN, etc.
      'matricule': _matriculeController.text,
      'date_inscription': DateTime.now(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    
    // 4. Redirection vers Dashboard
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardScreen(role: _selectedRole, userName: realName)
      ),
      (route) => false,
    );
  }

  // --- LOGIQUE GOOGLE SIGN-IN ---
  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // On utilise la même logique que pour l'inscription classique
      _goToDashboard(userCredential.user);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur Google : $e"), backgroundColor: Colors.redAccent)
      );
    }
  }

  // --- LOGIQUE D'INSCRIPTION RÉELLE AVEC FIREBASE ---
  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      // 1. Affichage du chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator(color: zeGreenDark)),
      );

      try {
        // 2. Création du compte dans Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // 3. MISE À JOUR DU NOM (DisplayName) DANS FIREBASE
        String fullName = "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}";
        await userCredential.user?.updateDisplayName(fullName);

        // 4. Sauvegarde locale (Backup)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', fullName);
        await prefs.setString('user_role', _selectedRole);
        
        if (!mounted) return;
        Navigator.pop(context); // Fermer le chargement

        // APPEL DE LA LOGIQUE COMMUNE
        _goToDashboard(userCredential.user);

       // 5. Redirection vers Dashboard
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(
    builder: (context) => DashboardScreen(
      role: _selectedRole, 
      userName: "${_firstNameController.text} ${_lastNameController.text}", // On envoie le nom ici
    ),
  ),
  (route) => false,
);
      } on FirebaseAuthException catch (e) {
        Navigator.pop(context);
        String errorMsg = "Erreur lors de l'inscription";
        if (e.code == 'email-already-in-use') errorMsg = "Cet email est déjà utilisé.";
        else if (e.code == 'weak-password') errorMsg = "Le mot de passe est trop faible.";
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent));
      } catch (e) {
        Navigator.pop(context);
        debugPrint("Erreur : $e");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez corriger les erreurs"), backgroundColor: Colors.redAccent),
      );
    }
  }

  // Widget icône sociale (inchangé mais propre)
 Widget _socialIcon(String url) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey[300]!),
      borderRadius: BorderRadius.circular(15),
      color: Colors.white,
    ),
    child: Image.network(
      url,
      height: 25,
      width: 25,
    ),
  );
}

  // Widget Badge de rôle
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
              boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)] : [],
            ),
            child: Icon(icon, color: isSelected ? Colors.white : Colors.grey[400], size: 24),
          ),
          const SizedBox(height: 5),
          Text(role, style: TextStyle(
            fontSize: 9, 
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, 
            color: isSelected ? color : Colors.grey
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: zeGreenDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                "Création de compte",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: zeGreenDark),
              ),
              const SizedBox(height: 20),
              const Text("Choisissez votre profil :", style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _roleBadge("CLIENT", Icons.person, zeGreenDark),
                  _roleBadge("ZEDMAN", Icons.motorcycle, zeOrange),
                  _roleBadge("TAXIMAN", Icons.local_taxi, zeYellow),
                  _roleBadge("LIVREUR", Icons.delivery_dining, zeGreenLight),
                ],
              ),
              const SizedBox(height: 30),

              _buildInputField("Nom", _lastNameController, Icons.person_outline),
              _buildInputField("Prénom", _firstNameController, Icons.person_outline),
              _buildInputField("Numéro de téléphone", _phoneController, Icons.phone_android),
              
              _buildInputField(
                "Adresse e-mail", 
                _emailController, 
                Icons.email_outlined,
                validator: (val) {
                  if (val == null || val.isEmpty) return "Email obligatoire";
                  if (!val.contains("@") || !val.contains(".")) return "Format invalide";
                  return null;
                }
              ),

              _buildInputField(
                "Mot de passe", 
                _passwordController, 
                Icons.lock_outline, 
                isPassword: true,
                validator: (val) {
                  if (val == null || val.isEmpty) return "Mot de passe obligatoire";
                  if (val.length < 6) return "6 caractères minimum";
                  return null;
                }
              ),

              if (_selectedRole != "CLIENT")
                _buildInputField("Numéro de matricule / Permis", _matriculeController, Icons.assignment_ind_outlined),

              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: zeGreenDark,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _handleRegister, 
                child: const Text(
                  "S'INSCRIRE",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              _socialRegister(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialRegister() {
  return Column(
    children: [
      const SizedBox(height: 25),
      const Text("Ou s'inscrire avec", style: TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 15),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // --- BOUTON GOOGLE ---
          MouseRegion(
            cursor: SystemMouseCursors.click, // Change le curseur sur Chrome
            child: GestureDetector(
              onTap: () {
                debugPrint("Bouton Google cliqué !");
                _handleGoogleSignIn(); // Appelle ta fonction
              },
              child: _socialIcon('https://cdn-icons-png.flaticon.com/512/2991/2991148.png'),
            ),
          ),
        ],
      ),
    ],
  );
}

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {bool isPassword = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
              children: const [
                TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: isPassword,
            validator: validator ?? (val) => val!.isEmpty ? "Ce champ est obligatoire" : null,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
              hintText: label,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.all(15),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: zeGreenDark)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
            ),
          ),
        ],
      ),
    );
  }
}