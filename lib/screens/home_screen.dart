
import 'package:flutter/material.dart';
import 'dart:ui';

import 'login_screen.dart';
import 'register_screen.dart';

// ========================================
// ANIMATION SIMPLE
// ========================================
class FadeIn extends StatelessWidget {
  final Widget child;
  final double delay;

  const FadeIn({super.key, required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (delay * 200).toInt()),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ========================================
// GLOW WAVE LOGO
// ========================================
class GlowWaveLogoWidget extends StatefulWidget {
  const GlowWaveLogoWidget({super.key});

  @override
  State<GlowWaveLogoWidget> createState() => _GlowWaveLogoWidgetState();
}

class _GlowWaveLogoWidgetState extends State<GlowWaveLogoWidget> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _rotateController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _rotateController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowController, _rotateController, _scaleController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotateController.value * 0.2,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6AE870).withOpacity(0.5 * (0.5 + _glowController.value * 0.5)),
                    blurRadius: 18 + (_glowController.value * 12),
                    spreadRadius: 3 + (_glowController.value * 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFF008C3D).withOpacity(0.3 * (0.5 + _glowController.value * 0.5)),
                    blurRadius: 25 + (_glowController.value * 15),
                    spreadRadius: 5 + (_glowController.value * 5),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6AE870).withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF6AE870), Color(0xFF008C3D)],
                        ),
                      ),
                      child: const Icon(Icons.motorcycle_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ========================================
// MODAL CONNEXION/INSCRIPTION
// ========================================
void showAuthModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Commencer avec ZÉ-CONNECT",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            _buildButton(
              label: "Créer un compte",
              color: const Color(0xFFFF7A00),
              isOutlined: true,
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
              },
            ),
            const SizedBox(height: 12),
            _buildButton(
              label: "Se connecter",
              color: const Color(0xFF008C3D),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              },
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    ),
  );
}

Widget _buildButton({
  required String label,
  required Color color,
  bool isOutlined = false,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isOutlined ? Colors.white : color,
        foregroundColor: isOutlined ? color : Colors.white,
        elevation: isOutlined ? 0 : 2,
        side: isOutlined ? BorderSide(color: color, width: 2) : BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    ),
  );
}

// ========================================
// ONBOARDING SCREEN
// ========================================
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}

// ========================================
// HOME PAGE COMPLÈTE
// ========================================
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final Color zeGreenDark = const Color(0xFF008C3D);
  final Color zeOrange = const Color(0xFFFF7A00);
  final Color zeYellow = const Color(0xFFFFCF31);
  final Color zeGreenLight = const Color(0xFF6AE870);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildTopHeroBanner(context),
              const SizedBox(height: 20),
              const SizedBox(height: 50),
              _buildHowItWorks(context),
              const SizedBox(height: 50),
              _buildWhyChoose(context),
              const SizedBox(height: 50),
              _buildServicesGrid(context),
              const SizedBox(height: 50),
              _buildStats(context),
              const SizedBox(height: 50),
              _buildAppDownload(context),
              const SizedBox(height: 50),
              _buildNewsletterSection(context),
              const SizedBox(height: 50),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // HEADER
  // ========================================
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: FadeIn(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const GlowWaveLogoWidget(),
                const SizedBox(width: 12),
                const Text(
                  "ZÉ-CONNECT",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF008C3D),
                    height: 1.0,
                  ),
                ),
              ],
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.menu_rounded, size: 22),
                onPressed: () {},
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }


Widget _buildTopHeroBanner(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        // Badge en haut
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [zeGreenLight, zeGreenDark],
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: zeGreenLight.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "N°1 DU TRANSPORT AU TOGO",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 25),
        
        // Titre principal
        Text(
          "Le transport togolais,\nréinventé par ZÉ-CONNECT",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: zeGreenDark,
            height: 1.2,
            letterSpacing: -0.8,
          ),
        ),
        
        const SizedBox(height: 15),
        
        // Sous-titre accrocheur
        Text(
          "Fini l'attente, fini les négociations de prix",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Boutons CTA
        Row(
          children: [
            Expanded(
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [zeGreenDark, zeGreenLight],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: zeGreenDark.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => showAuthModal(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Commencer",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 54,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: zeGreenDark,
                    side: BorderSide(color: zeGreenDark, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    "En savoir plus",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 30),
        
        // Features en 3 colonnes - Style numérique
        Row(
          children: [
            Expanded(
              child: _buildNumericFeature("⚡", "2min", "Course", zeGreenLight),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildNumericFeature("🔒", "100%", "Sécurisé", zeOrange),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildNumericFeature("💰", "-40%", "Économies", zeYellow),
            ),
          ],
        ),
        
        const SizedBox(height: 25),
        
        // Card avec avantages détaillés
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: zeGreenLight.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Premier point
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [zeGreenLight.withOpacity(0.3), zeGreenLight.withOpacity(0.1)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.attach_money_rounded, color: zeGreenDark, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Tarifs transparents",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: zeGreenDark,
                          ),
                        ),
                        Text(
                          "Prix fixes sans surprise",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 18),
              
              // Deuxième point
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [zeOrange.withOpacity(0.3), zeOrange.withOpacity(0.1)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.payment_rounded, color: zeOrange, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Paiement flexible",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: zeGreenDark,
                          ),
                        ),
                        Text(
                          "Espèces ou mobile money",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 18),
              
              // Troisième point
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [zeYellow.withOpacity(0.3), zeYellow.withOpacity(0.1)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.location_on_rounded, color: zeYellow.withOpacity(0.8), size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Suivi en temps réel",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: zeGreenDark,
                          ),
                        ),
                        Text(
                          "Visualisez votre trajet",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Divider
              Container(
                height: 1,
                color: Colors.grey[200],
              ),
              
              const SizedBox(height: 20),
              
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: zeGreenLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.verified_rounded, color: zeGreenDark, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Déjà 50 000+ utilisateurs\nsatisfaits au Togo",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: zeGreenDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// Widget pour les features numériques
Widget _buildNumericFeature(String emoji, String value, String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withOpacity(0.15),
          color.withOpacity(0.05),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 1.5,
      ),
    ),
    child: Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color.opacity > 0.5 ? color : zeGreenDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    ),
  );
}


  // ========================================
  // LES ÉTAPES POUR COMMENCER
  // ========================================
  Widget _buildHowItWorks(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [zeGreenLight.withOpacity(0.1), zeGreenDark.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          FadeIn(
            delay: 0.8,
            child: Text(
              "Les étapes pour commencer",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: zeGreenDark),
            ),
          ),
          const SizedBox(height: 10),
          FadeIn(
            delay: 0.9,
            child: Text(
              "Simple et sans tracas ! Suivez simplement trois étapes\nfaciles pour démarrer sans effort dès aujourd'hui.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
            ),
          ),
          const SizedBox(height: 35),
          FadeIn(delay: 1.0, child: _buildTimelineStep("1", "Ouvrez l'app", "Indiquez votre position et destination", zeGreenLight, true)),
          FadeIn(delay: 1.1, child: _buildTimelineStep("2", "Choisissez", "Sélectionnez votre chauffeur et tarif", zeOrange, true)),
          FadeIn(delay: 1.2, child: _buildTimelineStep("3", "C'est parti !", "Suivez votre course en temps réel", zeGreenDark, false)),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String number, String title, String description, Color color, bool showLine) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)],
                  ),
                  child: Center(
                    child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (showLine)
                  Container(
                    width: 2,
                    height: 40,
                    color: color.withOpacity(0.3),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(description, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ========================================
  // POURQUOI CHOISIR ZÉ-CONNECT
  // ========================================
  Widget _buildWhyChoose(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          FadeIn(
            delay: 1.3,
            child: Text(
              "Pourquoi choisir ZÉ-CONNECT ?",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: zeGreenDark),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          FadeIn(delay: 1.4, child: _buildWhyCard(Icons.speed_rounded, "Ultra-rapide", "Trouvez un chauffeur en quelques secondes", zeGreenLight)),
          const SizedBox(height: 16),
          FadeIn(delay: 1.5, child: _buildWhyCard(Icons.location_on_rounded, "Géolocalisation", "Suivez votre course en temps réel", zeGreenDark)),
          const SizedBox(height: 16),
          FadeIn(delay: 1.6, child: _buildWhyCard(Icons.payments_rounded, "Prix transparents", "Pas de surprise, prix fixés à l'avance", zeOrange)),
          const SizedBox(height: 16),
          FadeIn(delay: 1.7, child: _buildWhyCard(Icons.shield_rounded, "100% sécurisé", "Chauffeurs vérifiés et assurés", zeYellow)),
        ],
      ),
    );
  }

  Widget _buildWhyCard(IconData icon, String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // SERVICES GRID
  // ========================================
  Widget _buildServicesGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          FadeIn(
            delay: 1.8,
            child: Text("Nos services", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: zeGreenDark)),
          ),
          const SizedBox(height: 30),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.95,
            children: [
              FadeIn(delay: 1.9, child: _buildServiceCard("🏍️", "Zémidjan", "Rapide et économique", zeGreenLight)),
              FadeIn(delay: 2.0, child: _buildServiceCard("🚕", "Taxi-Ze", "Confort premium", zeGreenDark)),
              FadeIn(delay: 2.1, child: _buildServiceCard("📦", "Livraison", "Express 30min", zeOrange)),
              FadeIn(delay: 2.2, child: _buildServiceCard("💎", "Premium", "Luxe & VIP", zeYellow)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String emoji, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ========================================
  // STATS
  // ========================================
  Widget _buildStats(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [zeGreenDark, const Color(0xFF004D21)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const FadeIn(
            delay: 2.3,
            child: Text("ZÉ-CONNECT en chiffres", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              FadeIn(delay: 2.4, child: _buildStatItem("50K+", "Utilisateurs")),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
              FadeIn(delay: 2.5, child: _buildStatItem("4.9⭐", "Note")),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
              FadeIn(delay: 2.6, child: _buildStatItem("24/7", "Support")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
      ],
    );
  }

  // ========================================
  // TÉLÉCHARGER L'APP
  // ========================================
  Widget _buildAppDownload(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          FadeIn(
            delay: 2.7,
            child: Text(
              "Simple et sans tracas !",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: zeGreenDark),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          FadeIn(
            delay: 2.8,
            child: Text(
              "Suivez simplement trois étapes faciles pour\ndémarrer sans effort dès aujourd'hui.",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: FadeIn(
                  delay: 2.9,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.apple, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Télécharger sur", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                            const Text("App Store", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FadeIn(
                  delay: 3.0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: zeGreenDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Télécharger sur", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11)),
                            const Text("Google Play", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================
  // NEWSLETTER
  // ========================================
  Widget _buildNewsletterSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: zeGreenDark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const FadeIn(
            delay: 3.1,
            child: Text("Newsletter", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          const FadeIn(
            delay: 3.2,
            child: Text(
              "Abonnez-vous à notre\nNewsletter",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1.2),
            ),
          ),
          const SizedBox(height: 30),
          FadeIn(
            delay: 3.3,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Entrez votre email",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                      color: zeGreenDark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeIn(
            delay: 3.4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63).withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(-10, 0),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(-20, 0),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: zeYellow.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        "+15K",
                        style: TextStyle(color: zeGreenDark, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Plus de 15k utilisateurs actifs!", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text("Rejoignez-les maintenant >", style: TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // FOOTER
  // ========================================
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1D2E),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [zeGreenLight, zeGreenDark]),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.motorcycle_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Text("ZÉ-CONNECT", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Transport rapide et sécurisé\nau Togo et dans le monde.",
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildSocialIcon(Icons.facebook),
                        const SizedBox(width: 12),
                        _buildSocialIcon(Icons.telegram),
                        const SizedBox(width: 12),
                        _buildSocialIcon(Icons.camera_alt),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Liens Rapides", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildFooterLink("À Propos"),
                    _buildFooterLink("FAQ"),
                    _buildFooterLink("Contactez-nous"),
                    _buildFooterLink("Confidentialité"),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Contactez-nous", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildContactItem(Icons.location_on_rounded, "Lomé - Togo"),
                    _buildContactItem(Icons.phone_rounded, "00228 92604179"),
                    _buildContactItem(Icons.email_rounded, "support@zeconnect.com"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 20),
          Text(
            "Copyright © 2025 ZÉ-CONNECT. Tous droits réservés.",
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildFooterLink(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.chevron_right, color: zeGreenLight, size: 18),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: zeGreenLight, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        ],
      ),
    );
  }
}