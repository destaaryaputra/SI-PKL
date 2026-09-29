<?php

namespace App\Http\Controllers;

use App\Models\Industri;
use App\Models\PengajuanPkl;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/// Riwayat penempatan PKL per tahun (FR-17).
///
/// Dua sudut pandang:
/// - Per industri: siapa saja yang pernah ditempatkan di industri tersebut,
///   dikelompokkan per tahun — untuk layar detail industri.
/// - Per siswa: riwayat pengajuan siswa yang sedang login, dikelompokkan
///   per tahun — untuk tab "Riwayat" di dashboard.
class RiwayatController extends Controller
{
    public function perIndustri(Request $request, Industri $industri): JsonResponse
    {
        $data = $request->validate([
            'tahun' => ['nullable', 'integer', 'min:2000', 'max:2100'],
        ]);

        $query = PengajuanPkl::query()
            ->where('industri_id', $industri->id)
            ->where('status', 'disetujui')
            ->with('pengguna:id,nis,nama,jurusan_id');

        if (!empty($data['tahun'])) {
            $query->where('tahun', $data['tahun']);
        }

        $pengajuan = $query->orderByDesc('tahun')->get();

        // Kelompokkan per tahun: [{tahun, jumlah, siswa: [{nis, nama, jurusan}]}]
        $riwayat = $pengajuan
            ->groupBy('tahun')
            ->map(function ($group, $tahun) {
                return [
                    'tahun' => (int) $tahun,
                    'jumlah' => $group->count(),
                    'siswa' => $group->map(function (PengajuanPkl $item) {
                        $pengguna = $item->pengguna;

                        return [
                            'nis' => $pengguna?->nis,
                            'nama' => $pengguna?->nama,
                            'jurusan' => $pengguna?->jurusan?->nama,
                        ];
                    })->values(),
                ];
            })
            ->values();

        return response()->json(['data' => $riwayat]);
    }

    public function perSiswa(Request $request): JsonResponse
    {
        $pengajuan = $request->user()
            ->pengajuanPkl()
            ->with('industri:id,nama,alamat')
            ->orderByDesc('created_at')
            ->get();

        // Kelompokkan per tahun penempatan (kolom tahun, fallback tahun
        // tanggal pengajuan): [{tahun, industri: [...]}, ...]
        $riwayat = $pengajuan
            ->groupBy(fn (PengajuanPkl $item) => $item->tahun ?? (int) $item->created_at->format('Y'))
            ->map(function ($group, $tahun) {
                return [
                    'tahun' => (int) $tahun,
                    'pengajuan' => $group->map(fn (PengajuanPkl $item) => [
                        'id' => $item->id,
                        'industri' => [
                            'id' => $item->industri?->id,
                            'nama' => $item->industri?->nama,
                            'alamat' => $item->industri?->alamat,
                        ],
                        'status' => $item->status,
                        'tanggal' => $item->created_at?->toDateString(),
                    ])->values(),
                ];
            })
            ->sortByDesc('tahun')
            ->values();

        return response()->json(['data' => $riwayat]);
    }
}
