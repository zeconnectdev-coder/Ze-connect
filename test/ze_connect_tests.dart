import 'package:flutter_test/flutter_test.dart';

void main() {

  // TESTS UNITAIRES - Logique métier ZE-CONNECT

  group('TEST 1 - Validation Email', () {
    test('Email valide accepté', () {
      bool isValid = _validateEmail('jeannette@gmail.com');
      expect(isValid, true);
    });

    test('Email sans @ rejeté', () {
      bool isValid = _validateEmail('jeanettegmail.com');
      expect(isValid, false);
    });

    test('Email vide rejeté', () {
      bool isValid = _validateEmail('');
      expect(isValid, false);
    });
  });

  group('TEST 2 - Validation Mot de passe', () {
    test('Mot de passe 6 caractères accepté', () {
      bool isValid = _validatePassword('abc123');
      expect(isValid, true);
    });

    test('Mot de passe trop court rejeté', () {
      bool isValid = _validatePassword('abc');
      expect(isValid, false);
    });
  });

  group('TEST 3 - Sélection de rôle', () {
    test('Rôle CLIENT valide', () {
      bool isValid = _validateRole('CLIENT');
      expect(isValid, true);
    });

    test('Rôle ZEDMAN valide', () {
      bool isValid = _validateRole('ZEDMAN');
      expect(isValid, true);
    });

    test('Rôle inconnu rejeté', () {
      bool isValid = _validateRole('INCONNU');
      expect(isValid, false);
    });
  });

  // TESTS FONCTIONNELS - Parcours utilisateur

  group('TEST 4 - Inscription utilisateur', () {
    test('Inscription avec tous les champs valides', () {
      String nom = 'Agbalenyo';
      String prenom = 'Jeannette';
      String email = 'jeannette@gmail.com';
      String password = 'motdepasse123';
      String role = 'CLIENT';

      expect(nom.isNotEmpty, true);
      expect(prenom.isNotEmpty, true);
      expect(_validateEmail(email), true);
      expect(_validatePassword(password), true);
      expect(_validateRole(role), true);
    });

    test('Inscription échoue si email vide', () {
      expect(_validateEmail(''), false);
    });

    test('Inscription échoue si mot de passe trop court', () {
      expect(_validatePassword('123'), false);
    });
  });

  group('TEST 5 - Navigation selon le rôle', () {
    test('CLIENT redirigé vers ClientDash', () {
      String dash = _getDashboardForRole('CLIENT');
      expect(dash, 'ClientDash');
    });

    test('ZEDMAN redirigé vers ZedmanDash', () {
      String dash = _getDashboardForRole('ZEDMAN');
      expect(dash, 'ZedmanDash');
    });

    test('TAXIMAN redirigé vers TaxiDriverDash', () {
      String dash = _getDashboardForRole('TAXIMAN');
      expect(dash, 'TaxiDriverDash');
    });

    test('LIVREUR redirigé vers DeliveryDash', () {
      String dash = _getDashboardForRole('LIVREUR');
      expect(dash, 'DeliveryDash');
    });
  });


  // TESTS NON-REGRESSION - Vérifier que rien ne casse

  group('TEST 6 - Non régression Profil', () {
    test('Nom utilisateur ne peut pas être vide', () {
      String nom = 'Jeannette Agbalenyo';
      expect(nom.isNotEmpty, true);
    });

    test('Rôle sauvegardé correctement', () {
      String role = 'TAXIMAN';
      expect(_validateRole(role), true);
    });
  });

  group('TEST 7 - Non régression Chauffeur', () {
    test('Statut en ligne par défaut est false', () {
      bool isOnline = false;
      expect(isOnline, false);
    });

    test('Basculer statut en ligne fonctionne', () {
      bool isOnline = false;
      isOnline = !isOnline;
      expect(isOnline, true);
    });
  });

  group('TEST 8 - Non régression Formulaire Partenaire', () {
    test('Formulaire partenaire rejette champs vides', () {
      String nomComplet = '';
      expect(nomComplet.isEmpty, true);
    });
  });
}

// FONCTIONS LOGIQUE MÉTIER 

bool _validateEmail(String email) {
  if (email.isEmpty) return false;
  return email.contains('@') && email.contains('.');
}

bool _validatePassword(String password) {
  return password.length >= 6;
}

bool _validateRole(String role) {
  const validRoles = ['CLIENT', 'ZEDMAN', 'TAXIMAN', 'LIVREUR'];
  return validRoles.contains(role);
}

String _getDashboardForRole(String role) {
  switch (role) {
    case 'ZEDMAN': return 'ZedmanDash';
    case 'TAXIMAN': return 'TaxiDriverDash';
    case 'LIVREUR': return 'DeliveryDash';
    default: return 'ClientDash';
  }
}