import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaxiDriverDash extends StatefulWidget {
  const TaxiDriverDash({super.key});

  @override
  State<TaxiDriverDash> createState() => _TaxiDriverDashState();
}

class _TaxiDriverDashState extends State<TaxiDriverDash> {
  bool _isOnline = false;
  final Color zeYellow = const Color(0xFFFFCF31);

  void _toggleStatus() async {
    setState(() => _isOnline = !_isOnline);
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    await FirebaseFirestore.instance.collection('drivers').doc(uid).set({
      'isOnline': _isOnline,
      'type': 'TAXIMAN',
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Espace TAXIMAN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: zeYellow,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: zeYellow,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_isOnline ? "MODE SERVICE ACTIF" : "MODE REPOS", 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                Switch(value: _isOnline, onChanged: (val) => _toggleStatus(), activeColor: Colors.black),
              ],
            ),
          ),
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
    );
  }
}