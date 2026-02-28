# 📋 CAHIER DE RECETTE MANUELLE - ZE-CONNECT
**Testeur :** Jeannette Agbalenyo  
**Date :** 27/02/2026  
**Version app :** 1.0.0  
**Environnement :** Android / iOS

---

## 🔐 MODULE 1 - AUTHENTIFICATION

| ID | Cas de test | Étapes | Résultat attendu | Statut | Anomalie |
|---|---|---|---|---|---|
| TM01 | Connexion email valide | 1. Ouvrir app 2. Saisir email valide 3. Saisir mot de passe 4. Cliquer SE CONNECTER | Redirection vers dashboard | ⬜ À tester | - |
| TM02 | Connexion email invalide | 1. Saisir email sans @ 2. Cliquer SE CONNECTER | Message d'erreur affiché | ⬜ À tester | - |
| TM03 | Connexion mot de passe erroné | 1. Saisir bon email 2. Saisir mauvais mot de passe | Message "Mot de passe erroné" | ⬜ À tester | - |
| TM04 | Connexion Google | 1. Cliquer bouton Google 2. Sélectionner compte | Redirection vers dashboard | ⬜ À tester | - |
| TM05 | Déconnexion | 1. Aller sur Profil 2. Cliquer Déconnexion | Retour écran Login | ⬜ À tester | - |

---

## 📝 MODULE 2 - INSCRIPTION

| ID | Cas de test | Étapes | Résultat attendu | Statut | Anomalie |
|---|---|---|---|---|---|
| TM06 | Inscription CLIENT complète | 1. Remplir tous les champs 2. Choisir rôle CLIENT 3. Cliquer S'INSCRIRE | Compte créé + redirection | ⬜ À tester | - |
| TM07 | Inscription sans email | 1. Laisser email vide 2. Cliquer S'INSCRIRE | Message "Email obligatoire" | ⬜ À tester | - |
| TM08 | Inscription ZEDMAN avec matricule | 1. Choisir rôle ZEDMAN 2. Remplir matricule 3. S'inscrire | Champ matricule visible + compte créé | ⬜ À tester | - |

---

## 🚗 MODULE 3 - DASHBOARDS

| ID | Cas de test | Étapes | Résultat attendu | Statut | Anomalie |
|---|---|---|---|---|---|
| TM09 | Dashboard CLIENT affiché | 1. Se connecter comme CLIENT | Carte + options client visibles | ⬜ À tester | - |
| TM10 | Dashboard ZEDMAN affiché | 1. Se connecter comme ZEDMAN | Switch en ligne/hors ligne visible | ⬜ À tester | - |
| TM11 | Dashboard TAXIMAN affiché | 1. Se connecter comme TAXIMAN | Mode service visible en jaune | ⬜ À tester | - |
| TM12 | Dashboard LIVREUR affiché | 1. Se connecter comme LIVREUR | Switch disponible visible en vert | ⬜ À tester | - |

---

## 👤 MODULE 4 - PROFIL

| ID | Cas de test | Étapes | Résultat attendu | Statut | Anomalie |
|---|---|---|---|---|---|
| TM13 | Affichage profil | 1. Cliquer onglet Profil | Nom + rôle affichés correctement | ⬜ À tester | - |
| TM14 | Modifier photo galerie | 1. Cliquer avatar 2. Choisir galerie 3. Sélectionner photo | Photo mise à jour | ⬜ À tester | - |
| TM15 | Modifier photo caméra | 1. Cliquer avatar 2. Choisir caméra 3. Prendre photo | Photo mise à jour | ⬜ À tester | - |

---

## 🔄 MODULE 5 - NAVIGATION

| ID | Cas de test | Étapes | Résultat attendu | Statut | Anomalie |
|---|---|---|---|---|---|
| TM16 | Navigation bas de page | 1. Cliquer chaque onglet bas | Changement d'écran correct | ⬜ À tester | - |
| TM17 | Retour arrière | 1. Aller inscription 2. Cliquer retour | Retour écran login | ⬜ À tester | - |

---

## 🤝 MODULE 6 - FORMULAIRE PARTENAIRE

| ID | Cas de test | Étapes | Résultat attendu | Statut | Anomalie |
|---|---|---|---|---|---|
| TM18 | Formulaire complet | 1. Remplir tous les champs 2. Envoyer | Message "Demande envoyée" | ⬜ À tester | - |
| TM19 | Formulaire champ vide | 1. Laisser un champ vide 2. Envoyer | Message erreur affiché | ⬜ À tester | - |
| TM20 | Splash screen | 1. Lancer l'app | Animation + logo visible 4 secondes | ⬜ À tester | - |

---

## 📊 SYNTHÈSE

| Total tests | Passés ✅ | Échoués ❌ | Bloqués ⚠️ |
|---|---|---|---|
| 20 | 0 | 0 | 0 |

---

## 🐛 SUIVI DES ANOMALIES

| ID | Description | Sévérité | Statut |
|---|---|---|---|
| - | - | - | - |