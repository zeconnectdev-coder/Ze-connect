import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart'; 
import 'dart:io'; // Import nécessaire pour récupérer l'IP
import 'package:flutter/foundation.dart'; // Pour kIsWeb
import 'package:flutter_localizations/flutter_localizations.dart'; // Pour la localisation
import 'package:intl/date_symbol_data_local.dart'; // Pour initialiser les dates en français
import 'screens/login_screen.dart'; // Vérifie bien le nom de ton dossier et du fichier


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); 
  if (kIsWeb) {
    print("-------------------------------------------------------");
    print("🚀 ZÉ-CONNECT EST PRÊT !");
    print("📱 Pour voir l'app sur ton iPhone, ouvre Chrome et tape :");
    
    try {
      // On récupère l'IP locale de ton PC
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            print("👉 http://${addr.address}:8080");
          }
        }
      }
    } catch (e) {
      print("👉 http://192.168.1.22:8080 (IP par défaut)");
    }
    print("-------------------------------------------------------");
  }

  // Initialisation de la locale française pour les dates
  await initializeDateFormatting('fr_FR', null);
  
  runApp(const ZeConnectApp());
}

class ZeConnectApp extends StatelessWidget {
  const ZeConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ze Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Montserrat', // On définit la police globale ici
      ),
      // Configuration de la localisation en français
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
      ],
      locale: const Locale('fr', 'FR'),
      // L'application démarre maintenant sur le Splash
      home: const SplashScreen(), 
       routes: {
      '/login': (context) => const LoginScreen(), // AJOUTE CETTE LIGNE
    },
    );
  }
}