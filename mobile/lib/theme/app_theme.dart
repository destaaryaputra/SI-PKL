import 'package:flutter/material.dart';

/// Token motion — durasi & kurva standar animasi di seluruh app.
///
/// Aturan gaya: halus & modern. Slide hanya 12px, scale tombol 0.98,
/// tanpa bounce. Durasi feedback interaktif ≤ 500ms (intro splash
/// satu-satunya pengecualian).
abstract final class Motion {
  /// Press scale, chip — feedback kecil.
  static const Duration cepat = Duration(milliseconds: 200);

  /// Masuk item, switcher, badge.
  static const Duration sedang = Duration(milliseconds: 350);

  /// Section besar, chart.
  static const Duration lambat = Duration(milliseconds: 500);

  /// Transisi antar layar.
  static const Duration transisi = Duration(milliseconds: 280);

  /// Kurva standar — hampir semua animasi.
  static const Curve std = Curves.easeOutCubic;

  /// Kurva penekanan — transisi layar.
  static const Curve emph = Curves.easeInOutCubic;

  /// Delay stagger per indeks: 40ms/item, maks 320ms supaya
  /// item terakhir tidak nunggu lama.
  static Duration stagger(int index) =>
      Duration(milliseconds: (index * 40).clamp(0, 320));
}

/// Transisi layar standar SI-PKL: slide tipis dari kanan + fade, 280ms.
///
/// Didaftarkan global lewat [PageTransitionsTheme] di [AppTheme.light],
/// sehingga semua route — named maupun [MaterialPageRoute] langsung —
/// otomatis kena tanpa ubah tiap titik navigasi.
class GeserMemudar extends PageTransitionsBuilder {
  const GeserMemudar();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Hormati reduce-motion perangkat (aksesibilitas).
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final curved = CurvedAnimation(parent: animation, curve: Motion.emph);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
            .animate(curved),
        child: child,
      ),
    );
  }
}

/// Design system SI-PKL.
///
/// Identitas warna diambil dari logo: navy #042B53 (pin) + teal (aksen).
/// Kartu flat ber-outline, radius sedang, shadow minim —
/// hierarki dibangun lewat warna & tipografi, bukan dekorasi berlebih.
abstract final class AppTheme {
  /// Navy brand dari logo pin.
  static const Color navy = Color(0xFF042B53);

  /// Teal aksen brand — untuk highlight lembut & indikator terpilih.
  static const Color teal = Color(0xFF0D9488);
  static const Color tealGelap = Color(0xFF0F766E);
  static const Color tealLembut = Color(0xFFCCFBF1);

  // Warna status (fg = teks/ikon, bg = latar) — konsisten di semua layar.
  static const statusMenunggu = (fg: Color(0xFF92400E), bg: Color(0xFFFEF3C7));
  static const statusDisetujui = (fg: Color(0xFF166534), bg: Color(0xFFDCFCE7));
  static const statusDitolak = (fg: Color(0xFF991B1B), bg: Color(0xFFFEE2E2));
  static const statusNetral = (fg: Color(0xFF374151), bg: Color(0xFFF3F4F6));

  static ({Color fg, Color bg}) warnaStatus(String status) => switch (status) {
        'disetujui' => statusDisetujui,
        'ditolak' => statusDitolak,
        'menunggu' => statusMenunggu,
        _ => statusNetral,
      };

  static IconData ikonStatus(String status) => switch (status) {
        'disetujui' => Icons.check_circle,
        'ditolak' => Icons.cancel,
        'menunggu' => Icons.schedule,
        _ => Icons.help_outline,
      };

  /// Gradasi brand navy → teal (drawer header, avatar ring).
  static const LinearGradient gradasiBrand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, tealGelap],
  );

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: navy,
      // Netral cenderung dingin agar senada dengan navy.
      brightness: Brightness.light,
    ).copyWith(
      // Aksen teal — tombol utama tetap navy, teal dipakai untuk
      // indikator terpilih & highlight kecil.
      secondary: teal,
      onSecondary: Colors.white,
      secondaryContainer: tealLembut,
      onSecondaryContainer: tealGelap,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF6F7F9),
      // Slide+fade halus untuk SEMUA route (named & MaterialPageRoute).
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: GeserMemudar(),
        TargetPlatform.iOS: GeserMemudar(),
        TargetPlatform.fuchsia: GeserMemudar(),
        TargetPlatform.linux: GeserMemudar(),
        TargetPlatform.macOS: GeserMemudar(),
        TargetPlatform.windows: GeserMemudar(),
      }),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        // Pil terpilih soft-teal: navy tetap warna aksi, teal penanda pilihan.
        indicatorColor: scheme.secondaryContainer,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => base.textTheme.labelSmall!.copyWith(
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surfaceContainerLow,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: base.textTheme.labelMedium,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: base.textTheme.labelLarge,
        indicatorColor: scheme.primary,
        dividerColor: scheme.outlineVariant,
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Badge status kecil: [Disetujui] dsb. Dipakai semua layar
/// agar tampilan status konsisten.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.ikon = false});

  final String status;
  final bool ikon;

  @override
  Widget build(BuildContext context) {
    final (:fg, :bg) = AppTheme.warnaStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon) ...[
            Icon(AppTheme.ikonStatus(status), size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Ikon dalam kotak rounded berwarna lembut — untuk leading list/menu
/// agar lebih rapi daripada ikon polos.
class IkonKotak extends StatelessWidget {
  const IkonKotak({
    super.key,
    required this.icon,
    required this.fg,
    required this.bg,
    this.size = 40,
  });

  final IconData icon;
  final Color fg;
  final Color bg;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: fg, size: size * 0.5),
    );
  }
}

/// Latar dekoratif brand: gradasi navy-teal sangat lembut + lingkaran
/// transparan. Dipakai splash & login agar terasa satu identitas.
class LatarBrand extends StatelessWidget {
  const LatarBrand({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE7EFF6), Color(0xFFF6F7F9), Colors.white],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _LingkaranDekor(warna: AppTheme.teal.withValues(alpha: 0.12), size: 220),
          ),
          Positioned(
            bottom: -100,
            left: -70,
            child: _LingkaranDekor(warna: AppTheme.navy.withValues(alpha: 0.08), size: 260),
          ),
          Positioned(
            top: 160,
            left: -40,
            child: _LingkaranDekor(warna: AppTheme.teal.withValues(alpha: 0.07), size: 120),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _LingkaranDekor extends StatelessWidget {
  const _LingkaranDekor({required this.warna, required this.size});

  final Color warna;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
    );
  }
}
