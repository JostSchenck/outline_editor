import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_runners/flutter_test_runners.dart';

import '../common/test_outline_editor.dart';

void main() {
  group('OutlineEditorPlugin > desktop >', () {

    // setUp(() {
    //   document = OutlineMutableDocumentByNodeMetadata();
    //   prepareVisibilityTestDocument(document);
    // });

    testWidgetsOnWindows('OutlineEditor', (tester) async {
      await tester.pumpWidget(
          const TestOutlineEditor(),
      );
      await tester.pumpAndSettle();
      //
      // TODO: We can not test here in widget tests for really hidden fields,
      // because right now they aren't actually gone when hidden, but animated
      // away. Find a different way.
      //
      expect(find.text('Two more', findRichText: true), findsOneWidget);
      expect(find.text('Three more', findRichText: true), findsOneWidget); // should be findsNone
    });
  });
}
