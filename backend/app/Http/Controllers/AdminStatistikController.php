<?php

namespace App\Http\Controllers;

use App\Models\Industri;
use App\Models\PengajuanPkl;
use App\Models\Pengguna;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Carbon;

class AdminStatistikController extends Controller
{
    public function index(): JsonResponse
    {
        $perBulan = PengajuanPkl::query()
            ->where('created_at', '>=', Carbon::now()->subMonths(5)->startOfMonth())
            ->get()
            ->groupBy(fn (PengajuanPkl $p): string => $p->created_at->format('Y-m'))
            ->map(fn ($group): array => [
                'menunggu' => $group->where('status', 'menunggu')->count(),
                'disetujui' => $group->where('status', 'disetujui')->count(),
                'ditolak' => $group->where('status', 'ditolak')->count(),
            ]);

        $bulan = collect(range(5, 0))->map(function (int $mundur): array {
            $mulai = Carbon::now()->subMonths($mundur);
            $kunci = $mulai->format('Y-m');

            return [
                'label' => $mulai->translatedFormat('M'),
                'menunggu' => $perBulan[$kunci]['menunggu'] ?? 0,
                'disetujui' => $perBulan[$kunci]['disetujui'] ?? 0,
                'ditolak' => $perBulan[$kunci]['ditolak'] ?? 0,
            ];
        });

        return response()->json(['data' => [
            'total_siswa' => Pengguna::where('peran', 'siswa')->count(),
            'total_industri' => Industri::count(),
            'pengajuan_menunggu' => PengajuanPkl::where('status', 'menunggu')->count(),
            'pengajuan_disetujui' => PengajuanPkl::where('status', 'disetujui')->count(),
            'pengajuan_ditolak' => PengajuanPkl::where('status', 'ditolak')->count(),
            'pengajuan_per_bulan' => $bulan,
        ]]);
    }
}
