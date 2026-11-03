import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_invitation/main.dart';
import 'package:my_invitation/providers/auth_provider.dart';
import 'package:my_invitation/providers/template_provider.dart';
import 'package:my_invitation/providers/personalization_provider.dart';

void main() {
  testWidgets('My Invitation app launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => TemplateProvider()),
          ChangeNotifierProvider(create: (_) => PersonalizationProvider()),
        ],
        child: const MyInvitationApp(),
      ),
    );

    // Initial frame renders splash branding
    expect(find.text('My Invitation'), findsOneWidget);

    // Advance time past the splash delay to drain pending timers
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
