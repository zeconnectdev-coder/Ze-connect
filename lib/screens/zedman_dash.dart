import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ZedmanDash extends StatefulWidget {
  const ZedmanDash({super.key});

  @override
  State<ZedmanDash> createState() => _ZedmanDashState();
}

class _ZedmanDashState extends State<ZedmanDash> {
  bool _isOnline = false;
  final Color zeOrange = const Color(0xFFFF7A00);

  void _toggleStatus() async {
    setState(() => _isOnline = !_isOnline);
    
    // Met à jour Firestore pour que le CLIENT voie le chauffeur sur la carte
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (uid.isNotEmpty) {
      await FirebaseFirestore.instance.collection('drivers').doc(uid).set({
        'isOnline': _isOnline,
        'lastUpdate': FieldValue.serverTimestamp(),
        'type': 'ZEDMAN',
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tableau de bord ZÉDMAN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: zeOrange,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildOnlinePanel(),
          const SizedBox(height: 20),
          _buildStatCard("Courses du jour", "0", Icons.motorcycle),
          _buildStatCard("Gains estimés", "0 FCFA", Icons.account_balance_wallet),
        ],
      ),
    );
  }

  Widget _buildOnlinePanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: zeOrange,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_isOnline ? "VOUS ÊTES EN LIGNE" : "VOUS ÊTES HORS LIGNE", 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(_isOnline ? "Prêt à recevoir des clients" : "Activez pour travailler", 
                style: const TextStyle(color: Colors.white70, fontSize: 12)),

                 Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rides')
                  .where('status', isEqualTo: 'WAITING')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Aucune course pour le moment"));
                
                return ListView(
                  children: snapshot.data!.docs.map((doc) => ListTile(
                    title: Text("Vers: ${doc['destination_name']}"),
                    subtitle: Text("Prix: ${doc['price']} F CFA"),
                    trailing: ElevatedButton(
                      onPressed: () {}, // Logique d'acceptation ici
                      child: const Text("Accepter"),
                    ),
                  )).toList(),
                );
              },
            ),
          ),
            ],
          ),
          Switch(
            value: _isOnline,
            onChanged: (val) => _toggleStatus(),
            activeColor: Colors.white,
            activeTrackColor: Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: zeOrange, size: 30),
        title: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }
}