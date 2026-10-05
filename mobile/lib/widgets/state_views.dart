import 'package:flutter/material.dart';

import 'animasi.dart';

/// Tiga tampilan state layar (loading / kosong / error) yang dipakai
/// bersama oleh semua list & detail, supaya konsisten satu aplikasi.
///
/// Semuanya flat tanpa card: hierarki dari ikon + tipografi saja.

/// Spinner dengan label opsional. Selalu kasih [label] kalau user
/// harus menunggu lebih dari sekilas — spinner polos tidak menjelaskan apa pun.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final warna = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ItemMasuk(index: 0, child: const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          )),
          if (label != null) ...[
            ItemMasuk(index: 1, child: const SizedBox(height: 12)),
            ItemMasuk(index: 2, child: Text(
              label!,
              style: TextStyle(color: warna.onSurfaceVariant, fontSize: 14),
            )),
          ],
        ],
      ),
    );
  }
}

/// Layar/list kosong: ikon outline besar + judul + keterangan opsional.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final warna = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MunculSkala(child: Icon(icon, size: 56, color: warna.outline)),
            ItemMasuk(index: 1, child: const SizedBox(height: 16)),
            ItemMasuk(index: 2, child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: warna.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            )),
            if (message != null) ...[
              ItemMasuk(index: 3, child: const SizedBox(height: 4)),
              ItemMasuk(index: 4, child: Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: warna.onSurfaceVariant, fontSize: 13),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

/// Gagal memuat: ikon, pesan, dan tombol coba lagi (opsional).
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final warna = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 56, color: warna.outline),
            const SizedBox(height: 16),
            Text(
              'Terjadi masalah',
              style: TextStyle(
                color: warna.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: warna.onSurfaceVariant, fontSize: 13),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
