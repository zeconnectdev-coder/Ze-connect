
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    _prepareApp();
    }
    Future<void> _prepareApp() async {
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color zeGreen = Color(0xFF008C3D);
    const Color zeOrange = Color(0xFFFF7A00);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Colors.white, Color(0xFFE8F5E9)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // 1. L'EFFET DE LUMIÈRE EN DÉGRADÉ (GLOW)
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationController.value * 2 * math.pi,
                      child: Container(
                        width: 230, // Un peu plus large pour l'effet de lueur
                        height: 230,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              zeGreen.withOpacity(0.0),
                              zeOrange.withOpacity(0.2),
                              zeGreen.withOpacity(0.5),
                              zeGreen.withOpacity(0.0),
                            ],
                            stops: const [0.0, 0.4, 0.8, 1.0],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // 2. LE CERCLE SEGMENTÉ (TON CODE ORIGINAL)
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationController.value * 2 * math.pi,
                      child: SizedBox(
                        width: 210,
                        height: 210,
                        child: CustomPaint(
                          painter: SegmentedCirclePainter(
                            color1: zeGreen,
                            color2: zeOrange,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                // Fond blanc
                Container(
                  width: 160,
                  height: 160,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 8))
                    ],
                  ),
                ),

                // Ton Logo
                Image.asset(
                  'assets/images/logo.png',
                  width: 110,
                  height: 110,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            const SizedBox(height: 30),
            
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                double scale = 1.0 + (math.sin(_rotationController.value * 2 * math.pi) * 0.05);
                return Transform.scale(
                  scale: scale,
                  child: const Text(
                    "Chargement...",
                    style: TextStyle(
                      fontFamily: 'Montserrat-Regular',
                      fontSize: 15,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w900,
                       color: Color.fromARGB(255, 74, 100, 76),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SegmentedCirclePainter extends CustomPainter {
  final Color color1;
  final Color color2;

  SegmentedCirclePainter({required this.color1, required this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    double strokeWidth = 6.0;
    Rect rect = Offset.zero & size;
    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double gap = 0.3;
    double segmentLength = (2 * math.pi / 4) - gap;

    for (int i = 0; i < 4; i++) {
      paint.color = (i % 2 == 0) ? color1 : color2;
      double startAngle = i * (2 * math.pi / 4);
      canvas.drawArc(rect, startAngle, segmentLength, false, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}