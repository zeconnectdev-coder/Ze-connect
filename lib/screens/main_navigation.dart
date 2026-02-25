import 'package:flutter/material.dart';
import 'client_dash.dart';
import 'zedman_dash.dart';
import 'taxi_driver_dash.dart';
import 'delivery_dash.dart';
import 'profile_page.dart';

class MainNavigation extends StatefulWidget {
  final String role;
  final String userName;
  const MainNavigation({super.key, required this.role, required this.userName});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // --- LOGIQUE D'AIGUILLAGE DU PREMIER ONGLET ---
    Widget currentDash;
    
    switch (widget.role) {
      case "ZEDMAN":
        currentDash = const ZedmanDash();
        break;
      case "TAXIMAN":
        currentDash = const TaxiDriverDash();
        break;
      case "LIVREUR":
        currentDash = const DeliveryDash();
        break;
      case "CLIENT":
      default:
        currentDash =  ClientDash(
          userName: widget.userName, // On transmet le nom
          role: widget.role,         // On transmet le rôle
        ); // C'est ici que se trouve ta carte OpenStreetMap
        break;
    }

    final List<Widget> pages = [
      currentDash, 
      const Center(child: Text("Historique des activités")),
      ProfilePage(name: widget.userName, role: widget.role),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF008C3D), 
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Pour garder les labels visibles
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: "Activité"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profil"),
        ],
      ),
    );
  }
}