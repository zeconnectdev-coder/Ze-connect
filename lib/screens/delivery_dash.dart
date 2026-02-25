import 'package:flutter/material.dart';

class DeliveryDash extends StatefulWidget {
  const DeliveryDash({super.key});

  @override
  State<DeliveryDash> createState() => _DeliveryDashState();
}

class _DeliveryDashState extends State<DeliveryDash> {
  bool _isOnline = false;
  final Color zeGreenLight = const Color(0xFF6AE870);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Livraisons ZÉ", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: zeGreenLight,
      ),
      body: Column(
        children: [
          ListTile(
            tileColor: zeGreenLight.withOpacity(0.3),
            title: Text(_isOnline ? "Disponible pour livraison" : "Indisponible"),
            trailing: Switch(value: _isOnline, onChanged: (v) => setState(() => _isOnline = v)),
          ),
          const Expanded(
            child: Center(child: Text("Aucun colis à proximité", style: TextStyle(color: Colors.grey))),
          )
        ],
      ),
    );
  }
}