import 'package:flutter_test/flutter_test.dart';
import 'package:ze_connect/main.dart';
import 'package:ze_connect/screens/splash_screen.dart';

void main() {
  testWidgets('Vérification du chargement du SplashScreen', (WidgetTester tester) async {
    // On construit l'application ZeConnectApp au lieu de MyApp
    await tester.pumpWidget(const ZeConnectApp());

    // On vérifie que le SplashScreen est bien le premier écran affiché
    expect(find.byType(SplashScreen), findsOneWidget);

    // On vérifie que le texte du logo est présent
    expect(find.text('ZE CONNECT'), findsOneWidget);
  });
}