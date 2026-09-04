import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/main.dart';
import 'package:login_signup/screens/welcome_screen.dart';

void main() {
  testWidgets('App smoke test loads WelcomeScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify WelcomeScreen elements are present
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
