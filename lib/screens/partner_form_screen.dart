import 'package:flutter/material.dart';

class PartnerFormScreen extends StatefulWidget {
  const PartnerFormScreen({super.key});

  @override
  State<PartnerFormScreen> createState() => _PartnerFormScreenState();
}

class _PartnerFormScreenState extends State<PartnerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color zeGreen = const Color(0xFF0F2E14);
  final Color zeOrange = const Color.fromRGBO(255, 122, 0, 1);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: zeGreen,
        title: const Text("Devenir Partenaire", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : screenWidth * 0.2, 
          vertical: 30
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Rejoignez l'aventure ZÉ-CONNECT",
                style: TextStyle(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.w900, color: zeGreen),
              ),
              const SizedBox(height: 10),
              const Text("Remplissez le formulaire ci-dessous, notre équipe vous contactera sous 24h."),
              const SizedBox(height: 30),
              
              _buildField("Nom complet", Icons.person_outline),
              _buildField("Numéro de téléphone (T-Money/Flooz)", Icons.phone_android),
              _buildField("Type de véhicule (Moto, Voiture, etc.)", Icons.directions_car_filled_outlined),
              _buildField("Ville de résidence (Lomé, Kara, etc.)", Icons.location_on_outlined),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: zeOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Demande envoyée avec succès !'))
                      );
                    }
                  },
                  child: const Text("ENVOYER MA CANDIDATURE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: zeGreen),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: zeOrange, width: 2),
          ),
        ),
        validator: (value) => value!.isEmpty ? "Ce champ est obligatoire" : null,
      ),
    );
  }
}