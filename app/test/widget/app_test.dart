import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kyc_app/app.dart';

void main() {
  testWidgets('Unauthenticated app shows login', (WidgetTester tester) async {
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:3000');
    await tester.pumpWidget(const ProviderScope(child: KycApp()));

    await tester.pumpAndSettle();

    expect(find.text('Login'), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
