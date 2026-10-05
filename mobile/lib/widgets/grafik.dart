import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kumpulan grafik dashboard admin.
///
/// Prinsip visualisasinya:
/// - Warna status (menunggu/disetujui/ditolak) selalu ditemani ikon + label —
///   merah dan hijau sulit dibedakan penderita buta warna, jadi warna tidak
///   boleh jadi satu-satunya pembeda.
/// - Bar satu seri (top industri, per jurusan) memakai satu warna untuk
///   semua bar — panjang bar sudah membawa nilainya.
/// - Teks nilai/label selalu pakai warna teks, bukan warna data.
/// - Setiap nilai bisa dibaca tanpa interaksi (label langsung / legenda),
///   tap hanya pelengkap.

// ===== Donut status pengajuan =====

/// Donut part-to-whole status pengajuan + legenda bernilai.
///
/// Legenda (ikon + label + jumlah + persen) berfungsi sekaligus sebagai
/// tabel data: semua angka terbaca tanpa harus menyentuh grafik.
class GrafikDonat extends StatelessWidget {
  const GrafikDonat({
    super.key,
    required this.menunggu,
    required this.disetujui,
    required this.ditolak,
  });

  final int menunggu;
  final int disetujui;
  final int ditolak;

  @override
  Widget build(BuildContext context) {
    final total = menunggu + disetujui + ditolak;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: total == 0
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Belum ada pengajuan.'),
                ),
              )
            : Column(
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Motion.lambat,
                      curve: Motion.std,
                      builder: (context, t, _) => CustomPaint(
                        painter: _DonatPainter(
                          bagian: [
                            (menunggu, AppTheme.statusMenunggu.fg),
                            (disetujui, AppTheme.statusDisetujui.fg),
                            (ditolak, AppTheme.statusDitolak.fg),
                          ],
                          total: total,
                          faktor: t,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$total',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'pengajuan',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _BarisLegenda(
                    ikon: Icons.schedule,
                    label: 'Menunggu',
                    nilai: menunggu,
                    total: total,
                    warna: AppTheme.statusMenunggu.fg,
                  ),
                  const SizedBox(height: 8),
                  _BarisLegenda(
                    ikon: Icons.check_circle,
                    label: 'Disetujui',
                    nilai: disetujui,
                    total: total,
                    warna: AppTheme.statusDisetujui.fg,
                  ),
                  const SizedBox(height: 8),
                  _BarisLegenda(
                    ikon: Icons.cancel,
                    label: 'Ditolak',
                    nilai: ditolak,
                    total: total,
                    warna: AppTheme.statusDitolak.fg,
                  ),
                ],
              ),
      ),
    );
  }
}

/// Satu baris legenda: ikon berwarna (pembeda bentuk, bukan warna saja)
/// + label + jumlah & persen. Nilai selalu terlihat — tanpa tooltip.
class _BarisLegenda extends StatelessWidget {
  const _BarisLegenda({
    required this.ikon,
    required this.label,
    required this.nilai,
    required this.total,
    required this.warna,
  });

  final IconData ikon;
  final String label;
  final int nilai;
  final int total;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    final persen = total == 0 ? 0 : (nilai / total * 100).round();
    return Row(
      children: [
        Icon(ikon, size: 16, color: warna),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(
          '$nilai',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '$persen%',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _DonatPainter extends CustomPainter {
  _DonatPainter({
    required this.bagian,
    required this.total,
    required this.faktor,
  });

  /// (jumlah, warna) tiap segmen, urutan tetap.
  final List<(int, Color)> bagian;
  final int total;
  final double faktor;

  @override
  void paint(Canvas canvas, Size size) {
    final pusat = size.center(Offset.zero);
    final tebal = 28.0;
    final jari = (size.shortestSide - tebal) / 2;
    final kotak = Rect.fromCircle(center: pusat, radius: jari);

    // Jarak 2px antar segmen (permukaan card tembus di antaranya).
    final jarakSudut = 2 / jari;
    var sudutMulai = -math.pi / 2;

    for (final (jumlah, warna) in bagian) {
      if (jumlah <= 0) continue;
      final lebarSudut = jumlah / total * 2 * math.pi;
      final sapuan = math.max(lebarSudut * faktor - jarakSudut, 0.001);
      canvas.drawArc(
        kotak,
        sudutMulai + jarakSudut / 2,
        sapuan,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = tebal
          ..strokeCap = StrokeCap.butt
          ..color = warna,
      );
      sudutMulai += lebarSudut;
    }
  }

  @override
  bool shouldRepaint(_DonatPainter lama) =>
      lama.faktor != faktor || lama.total != total;
}

// ===== Grafik batang bertumpuk per bulan =====

// Geometri grafik bulanan. Total tinggi = label nilai + plot + label bulan.
// Label nilai dan jarak antar segmen WAJIB dihitung — kalau tidak,
// kolom tertinggi overflow ke atas (bug "bottom overflowed").
const _tinggiPlot = 120.0;
const _tinggiLabelNilai = 24.0; // 20px teks + 4px jarak ke bar
const _tinggiLabelBulan = 28.0;
const _tinggiTotal = _tinggiLabelNilai + _tinggiPlot + _tinggiLabelBulan;
const _lebarKolom = 24.0;
const _jarakSegmen = 2.0;

/// Kolom bertumpuk pengajuan per bulan (menunggu/disetujui/ditolak).
///
/// - Batang tumbuh beranimasi dari baseline.
/// - Jarak 2px antar segmen; ujung atas membulat 4px, dasar rata.
/// - Total di kepala kolom; detail per status dibuka dengan tap
///   atau lewat tabel data — nilai tidak disembunyikan di tooltip saja.
class GrafikBatangBertumpuk extends StatefulWidget {
  const GrafikBatangBertumpuk({
    super.key,
    required this.dataBulan,
    required this.onBukaTabel,
  });

  final List<Map<String, dynamic>> dataBulan;
  final VoidCallback onBukaTabel;

  @override
  State<GrafikBatangBertumpuk> createState() => _GrafikBatangBertumpukState();
}

class _GrafikBatangBertumpukState extends State<GrafikBatangBertumpuk> {
  int? _bulanTerpilih;

  @override
  Widget build(BuildContext context) {
    final maksimal = widget.dataBulan.fold<int>(0, (maks, bulan) {
      final total = _totalBulan(bulan);
      return total > maks ? total : maks;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: widget.dataBulan.isEmpty || maksimal == 0
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Belum ada pengajuan dalam 6 bulan terakhir.'),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Lihat tabel data',
                      icon: const Icon(Icons.table_chart_outlined, size: 20),
                      onPressed: widget.onBukaTabel,
                    ),
                  ),
                  // Grid hairline + area kolom. TinggiTotal sudah termasuk
                  // label nilai di atas bar dan label bulan di bawah.
                  SizedBox(
                    height: _tinggiTotal,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _GridPainter(
                              maksimal: maksimal,
                              tinggiPlot: _tinggiPlot,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: _tinggiLabelBulan,
                          height: _tinggiLabelNilai + _tinggiPlot,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Motion.lambat,
                            curve: Motion.std,
                            builder: (context, t, _) => Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (var i = 0;
                                    i < widget.dataBulan.length;
                                    i++)
                                  Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => setState(() {
                                        _bulanTerpilih =
                                            _bulanTerpilih == i ? null : i;
                                      }),
                                      child: _KolomBulan(
                                        bulan: widget.dataBulan[i],
                                        maksimal: maksimal,
                                        faktor: t,
                                        terpilih: _bulanTerpilih == i,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: _tinggiLabelBulan,
                          child: Row(
                            children: widget.dataBulan
                                .map(
                                  (bulan) => Expanded(
                                    child: Center(
                                      child: Text(
                                        bulan['label'] as String? ?? '-',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Legenda status — ikon + label + total periode.
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      _LegendaChip(
                        ikon: Icons.schedule,
                        label: 'Menunggu',
                        warna: AppTheme.statusMenunggu.fg,
                        nilai: widget.dataBulan.fold(
                          0,
                          (s, b) => s + (b['menunggu'] as num? ?? 0).toInt(),
                        ),
                      ),
                      _LegendaChip(
                        ikon: Icons.check_circle,
                        label: 'Disetujui',
                        warna: AppTheme.statusDisetujui.fg,
                        nilai: widget.dataBulan.fold(
                          0,
                          (s, b) => s + (b['disetujui'] as num? ?? 0).toInt(),
                        ),
                      ),
                      _LegendaChip(
                        ikon: Icons.cancel,
                        label: 'Ditolak',
                        warna: AppTheme.statusDitolak.fg,
                        nilai: widget.dataBulan.fold(
                          0,
                          (s, b) => s + (b['ditolak'] as num? ?? 0).toInt(),
                        ),
                      ),
                    ],
                  ),
                  if (_bulanTerpilih != null) ...[
                    const SizedBox(height: 12),
                    AnimatedSize(
                      duration: Motion.sedang,
                      curve: Motion.std,
                      child: _DetailBulan(bulan: widget.dataBulan[_bulanTerpilih!]),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  static int _totalBulan(Map<String, dynamic> bulan) =>
      (bulan['menunggu'] as num? ?? 0).toInt() +
      (bulan['disetujui'] as num? ?? 0).toInt() +
      (bulan['ditolak'] as num? ?? 0).toInt();
}

/// Satu kolom: total di kepala + tumpukan segmen status
/// (ditolak di atas, menunggu di baseline) dengan jarak 2px.
class _KolomBulan extends StatelessWidget {
  const _KolomBulan({
    required this.bulan,
    required this.maksimal,
    required this.faktor,
    required this.terpilih,
  });

  final Map<String, dynamic> bulan;
  final int maksimal;
  final double faktor;
  final bool terpilih;

  @override
  Widget build(BuildContext context) {
    final menunggu = (bulan['menunggu'] as num? ?? 0).toInt();
    final disetujui = (bulan['disetujui'] as num? ?? 0).toInt();
    final ditolak = (bulan['ditolak'] as num? ?? 0).toInt();
    final total = menunggu + disetujui + ditolak;

    final dataSegmen = [
      if (ditolak > 0) (ditolak, AppTheme.statusDitolak.fg),
      if (disetujui > 0) (disetujui, AppTheme.statusDisetujui.fg),
      if (menunggu > 0) (menunggu, AppTheme.statusMenunggu.fg),
    ];

    // Jarak 2px antar segmen memakan tinggi — kurangi dari ruang isian
    // supaya tumpukan + jaraknya tepat setinggi _tinggiPlot.
    final jumlahJarak = dataSegmen.isEmpty ? 0 : dataSegmen.length - 1;
    final ruangIsi = _tinggiPlot - jumlahJarak * _jarakSegmen;
    double tinggi(int n) => n / maksimal * ruangIsi * faktor;

    // Sisipkan jarak 2px antar segmen (bukan border — permukaan yang memisah).
    final tumpukan = <Widget>[];
    for (var i = 0; i < dataSegmen.length; i++) {
      if (i > 0) tumpukan.add(const SizedBox(height: _jarakSegmen));
      final (jumlah, warna) = dataSegmen[i];
      tumpukan.add(Container(height: tinggi(jumlah), color: warna));
    }

    return SizedBox(
      height: _tinggiLabelNilai + _tinggiPlot,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Tinggi tetap 20px + FittedBox: label tidak pernah melebihi
          // pita labelnya, walau skala teks sistem diperbesar.
          SizedBox(
            height: 20,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$total',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: terpilih ? FontWeight.w700 : FontWeight.w400,
                      color: terpilih
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            child: SizedBox(
              width: _lebarKolom,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: tumpukan,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Garis grid horizontal hairline — hanya di angka bersih (0, tengah, maks).
class _GridPainter extends CustomPainter {
  _GridPainter({required this.maksimal, required this.tinggiPlot});

  final int maksimal;
  final double tinggiPlot;

  @override
  void paint(Canvas canvas, Size size) {
    final garis = Paint()
      ..strokeWidth = 1
      ..color = const Color(0xFFE1E0D9);
    final dasar = size.height - _tinggiLabelBulan;

    // 0, tengah, maks — cukup; grid tetap recessive.
    for (final fraksi in [0.0, 0.5, 1.0]) {
      final y = dasar - fraksi * tinggiPlot;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), garis);
    }
  }

  @override
  bool shouldRepaint(_GridPainter lama) => lama.maksimal != maksimal;
}

/// Legenda chip: ikon berwarna + label + jumlah (teks tetap warna teks).
class _LegendaChip extends StatelessWidget {
  const _LegendaChip({
    required this.ikon,
    required this.label,
    required this.warna,
    required this.nilai,
  });

  final IconData ikon;
  final String label;
  final Color warna;
  final int nilai;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ikon, size: 14, color: warna),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: 4),
        Text(
          '$nilai',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// Panel detail bulan terpilih — "tooltip" yang menempel di bawah grafik,
/// menampilkan semua seri sekaligus.
class _DetailBulan extends StatelessWidget {
  const _DetailBulan({required this.bulan});

  final Map<String, dynamic> bulan;

  @override
  Widget build(BuildContext context) {
    final menunggu = (bulan['menunggu'] as num? ?? 0).toInt();
    final disetujui = (bulan['disetujui'] as num? ?? 0).toInt();
    final ditolak = (bulan['ditolak'] as num? ?? 0).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bulan ${bulan['label']}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            '$menunggu menunggu · $disetujui disetujui · $ditolak ditolak',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ===== Bar horizontal satu warna =====

/// Daftar bar horizontal (top industri / siswa per jurusan).
///
/// Semua bar satu warna: kategori bersifat nominal, panjang bar sudah
/// membawa perbandingan. Nama + nilai selalu terlihat di tiap baris.
class DaftarBarHorizontal extends StatelessWidget {
  const DaftarBarHorizontal({
    super.key,
    required this.data,
    this.satuan = '',
    this.warna,
  });

  /// [{nama: String, jumlah: int}]
  final List<Map<String, dynamic>> data;
  final String satuan;
  final Color? warna;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Belum ada data.')),
        ),
      );
    }

    final maksimal = data.fold<int>(
      0,
      (m, d) => math.max(m, (d['jumlah'] as num? ?? 0).toInt()),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < data.length; i++) ...[
              if (i > 0) const Divider(height: 16),
              _BarisBarHorizontal(
                label: data[i]['nama'] as String? ?? '-',
                nilai: (data[i]['jumlah'] as num? ?? 0).toInt(),
                maksimal: maksimal,
                satuan: satuan,
                warna: warna ?? AppTheme.tealGelap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BarisBarHorizontal extends StatelessWidget {
  const _BarisBarHorizontal({
    required this.label,
    required this.nilai,
    required this.maksimal,
    required this.satuan,
    required this.warna,
  });

  final String label;
  final int nilai;
  final int maksimal;
  final String satuan;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    final fraksi = maksimal == 0 ? 0.0 : nilai / maksimal;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                satuan.isEmpty ? '$nilai' : '$nilai $satuan',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Track netral + isian bar. Ujung kanan (sisi data) membulat 4px.
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(4)),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraksi),
                duration: Motion.lambat,
                curve: Motion.std,
                builder: (context, t, _) => FractionallySizedBox(
                  widthFactor: t == 0 ? 0.001 : t,
                  child: Container(height: 12, color: warna),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Meter kuota industri =====

/// Daftar meter kuota: isian membawa kepadatan (teal → amber → merah),
/// track = langkah lebih muda dari warna isian. Label status (Hampir
/// penuh / Penuh) selalu bersama ikon — bukan warna saja.
class DaftarMeterKuota extends StatelessWidget {
  const DaftarMeterKuota({super.key, required this.data});

  /// [{nama, kuota, terpakai, menunggu}]
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Belum ada data industri.')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < data.length; i++) ...[
              if (i > 0) const Divider(height: 20),
              _BarisMeter(item: data[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _BarisMeter extends StatelessWidget {
  const _BarisMeter({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final nama = item['nama'] as String? ?? '-';
    final kuota = (item['kuota'] as num? ?? 0).toInt();
    final terpakai = (item['terpakai'] as num? ?? 0).toInt();
    final menunggu = (item['menunggu'] as num? ?? 0).toInt();
    final fraksi = kuota == 0 ? 0.0 : (terpakai / kuota).clamp(0.0, 1.0);

    // Tingkat keparahan: normal → hampir penuh (≥75%) → penuh (100%).
    final (isi, track, chipIkon, chipLabel) = switch ((
      fraksi >= 1.0,
      fraksi >= 0.75
    )) {
      (true, _) => (
          AppTheme.statusDitolak.fg,
          AppTheme.statusDitolak.bg,
          Icons.error_outline,
          'Penuh'
        ),
      (false, true) => (
          AppTheme.statusMenunggu.fg,
          AppTheme.statusMenunggu.bg,
          Icons.warning_amber_outlined,
          'Hampir penuh'
        ),
      _ => (AppTheme.tealGelap, AppTheme.tealLembut, null, null),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$terpakai/$kuota terisi',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      // Track: langkah lebih muda dari warna isian.
                      Container(height: 10, color: track),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: fraksi),
                        duration: Motion.lambat,
                        curve: Motion.std,
                        builder: (context, t, _) => FractionallySizedBox(
                          widthFactor: t,
                          child: Container(height: 10, color: isi),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (chipLabel != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: track,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(chipIkon, size: 12, color: isi),
                      const SizedBox(width: 4),
                      Text(
                        chipLabel,
                        style: TextStyle(
                          color: isi,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (menunggu > 0) ...[
            const SizedBox(height: 4),
            Text(
              '$menunggu pengajuan menunggu',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

// ===== Tabel data (pembaca WCAG / nilai pasti) =====

/// Bottom sheet tabel: padanan grafik yang selalu bisa diakses,
/// supaya nilai tidak bergantung pada warna atau tap di grafik.
void tampilkanTabelData(
  BuildContext context, {
  required String judul,
  required List<String> kolom,
  required List<List<String>> baris,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              judul,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 36,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 44,
                  columns: [
                    for (final k in kolom)
                      DataColumn(
                        label: Text(
                          k,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                  rows: [
                    for (final r in baris)
                      DataRow(
                        cells: [for (final c in r) DataCell(Text(c))],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
