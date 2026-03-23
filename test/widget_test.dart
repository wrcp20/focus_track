import 'package:flutter_test/flutter_test.dart';
import 'package:focus_track/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('FocusTrack app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: FocusTrackApp()),
    );
    expect(find.text('FocusTrack'), findsAny);
  });
}
