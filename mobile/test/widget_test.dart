import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/main.dart';
import 'package:mobile/screens/login_screen.dart';

void main() {
  testWidgets('menampilkan halaman login SI-PKL saat belum ada sesi',
      (WidgetTester tester) async {
    // Tanpa token tersimpan, splash harus mendarat di halaman login.
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SiPklApp());
    await tester.pumpAndSettle();

    // Logo SI-PKL kini berupa gambar, jadi cek lewat asset-nya.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image == const AssetImage('assets/brand/logo_full.png'),
      ),
      findsOneWidget,
    );
    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
