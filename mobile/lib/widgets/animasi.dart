import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Widget animasi halus & modern SI-PKL.
///
/// Aturan gaya: slide hanya 12px, tanpa bounce/elastic, nilai tetap
/// terbaca dan tombol tetap bisa ditekan selama animasi berjalan.
/// Semua widget mati (langsung tampil) saat pengguna mengaktifkan
/// reduce-motion — cek [tanpaAnimasi].

/// True bila perangkat meminta animasi dimatikan (aksesibilitas).
bool tanpaAnimasi(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

/// Fade + slide naik 12px dengan delay stagger per child
/// (lihat [Motion.stagger]) — untuk section kecil ber-Column:
/// field form, kartu stat, isi layar berhasil/gagal.
class MasukBertahap extends StatelessWidget {
  const MasukBertahap({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++)
          ItemMasuk(index: i, child: children[i]),
      ],
    );
  }
}

/// Satu item yang fade + slide masuk. [index] mengatur delay stagger
/// (40ms per indeks, cap 320ms). Dipakai di `itemBuilder` list atau
/// lewat [MasukBertahap].
class ItemMasuk extends StatelessWidget {
  const ItemMasuk({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (tanpaAnimasi(context)) return child;

    // Satu jendela animasi bersama: delay maks + durasi gerak.
    // Tiap item punya slot Interval sendiri di dalam jendela itu,
    // jadi antar item tampak bertahap tanpa Timer terpisah.
    final jendela = Motion.stagger(8) + Motion.sedang;
    final tunda =
        Motion.stagger(index).inMilliseconds / jendela.inMilliseconds;
    final selesai =
        tunda + Motion.sedang.inMilliseconds / jendela.inMilliseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: jendela,
      curve: Interval(tunda, selesai.clamp(0.0, 1.0), curve: Motion.std),
      child: child,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

/// Tombol aksi dengan feedback modern: scale 0.98 saat ditekan,
/// isi ↔ spinner lewat [AnimatedSwitcher] (bukan swap instan),
/// nonaktif saat [memuat].
///
/// Default FilledButton dari [AppTheme]; [garis] → OutlinedButton.
/// [gaya] untuk delta style (minimumSize, backgroundColor, dsb.)
/// tanpa mengganti chrome tema. [pertahankanTeks] → teks tetap,
/// hanya [ikon] yang berganti spinner (mis. Ajukan PKL).
class TombolMuat extends StatefulWidget {
  const TombolMuat({
    super.key,
    required this.teks,
    required this.onPressed,
    this.memuat = false,
    this.ikon,
    this.pertahankanTeks = false,
    this.garis = false,
    this.gaya,
    this.warnaSpinner,
  });

  final String teks;
  final VoidCallback? onPressed;

  /// Umpan balik saat request berjalan: spinner + nonaktif.
  final bool memuat;
  final IconData? ikon;

  /// Saat [memuat], teks tetap terlihat dan hanya [ikon] → spinner.
  final bool pertahankanTeks;
  final bool garis;
  final ButtonStyle? gaya;
  final Color? warnaSpinner;

  @override
  State<TombolMuat> createState() => _TombolMuatState();
}

class _TombolMuatState extends State<TombolMuat> {
  bool _ditekan = false;

  @override
  Widget build(BuildContext context) {
    final mati = widget.memuat || widget.onPressed == null;
    final skala = tanpaAnimasi(context) ? 1.0 : (_ditekan ? 0.98 : 1.0);
    final warnaSpinner = widget.warnaSpinner ??
        (widget.garis
            ? Theme.of(context).colorScheme.onSurface
            : Colors.white);

    final spinner = SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2.2, color: warnaSpinner),
    );

    final Widget isi;
    if (widget.memuat && widget.pertahankanTeks) {
      isi = Row(
        key: const ValueKey('muat-teks'),
        mainAxisSize: MainAxisSize.min,
        children: [spinner, const SizedBox(width: 8), Flexible(child: Text(widget.teks))],
      );
    } else if (widget.memuat) {
      isi = SizedBox(key: const ValueKey('muat'), width: 18, height: 18, child: spinner);
    } else {
      isi = Row(
        key: const ValueKey('teks'),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.ikon != null) ...[Icon(widget.ikon, size: 18), const SizedBox(width: 8)],
          Flexible(child: Text(widget.teks)),
        ],
      );
    }

    // Cross-fade isi — bukan hard cut teks↔spinner.
    final berpindah = AnimatedSwitcher(
      duration: Motion.cepat,
      switchInCurve: Motion.std,
      switchOutCurve: Motion.std,
      transitionBuilder: (Widget child, Animation<double> anim) {
        return FadeTransition(opacity: anim, child: child);
      },
      child: isi,
    );

    final Widget tombol;
    if (widget.garis) {
      tombol = OutlinedButton(
        onPressed: mati ? null : widget.onPressed,
        style: widget.gaya,
        child: berpindah,
      );
    } else {
      tombol = FilledButton(
        onPressed: mati ? null : widget.onPressed,
        style: widget.gaya,
        child: berpindah,
      );
    }

    // Listener (bukan GestureDetector) supaya tidak berebut gesture
    // dengan tombol di dalamnya.
    return Listener(
      onPointerDown: !mati ? (_) => setState(() => _ditekan = true) : null,
      onPointerUp: (_) => setState(() => _ditekan = false),
      onPointerCancel: (_) => setState(() => _ditekan = false),
      child: AnimatedScale(
        scale: skala,
        duration: Motion.cepat,
        curve: Motion.std,
        child: tombol,
      ),
    );
  }
}

/// Angka statistik count-up dari 0 — untuk kartu ringkasan dashboard.
class AngkaBerjalan extends StatelessWidget {
  const AngkaBerjalan({super.key, required this.nilai, this.style});

  final int nilai;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (tanpaAnimasi(context)) return Text('$nilai', style: style);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: nilai.toDouble()),
      duration: Motion.lambat,
      curve: Motion.std,
      builder: (context, v, _) => Text('${v.round()}', style: style),
    );
  }
}

/// Pop halus: scale 0.85 → 1 + fade (tanpa bounce) — untuk ikon besar
/// centang/silang di layar berhasil & gagal.
class MunculSkala extends StatelessWidget {
  const MunculSkala({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (tanpaAnimasi(context)) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.sedang,
      curve: Motion.std,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
        );
      },
      child: child,
    );
  }
}
