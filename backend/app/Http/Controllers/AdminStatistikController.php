<?php

namespace App\Http\Controllers;

use App\Models\Industri;
use App\Models\Jurusan;
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

        $bulan = collect(range(5, 0))->map(function (int $mundur) use ($perBulan): array {
            $mulai = Carbon::now()->subMonths($mundur);
            $kunci = $mulai->format('Y-m');

            return [
                'label' => $mulai->translatedFormat('M'),
                'menunggu' => $perBulan[$kunci]['menunggu'] ?? 0,
                'disetujui' => $perBulan[$kunci]['disetujui'] ?? 0,
                'ditolak' => $perBulan[$kunci]['ditolak'] ?? 0,
            ];
        });

        // 5 industri paling banyak dilamar — buat grafik bar horizontal.
        $topIndustri = PengajuanPkl::query()
            ->select('industri_id')
            ->selectRaw('count(*) as jumlah')
            ->groupBy('industri_id')
            ->orderByDesc('jumlah')
            ->orderBy('industri_id')
            ->limit(5)
            ->with('industri:id,nama')
            ->get()
            ->map(fn (PengajuanPkl $p): array => [
                'nama' => $p->industri?->nama ?? '-',
                'jumlah' => (int) $p->jumlah,
            ])
            ->values();

        // Jumlah siswa per jurusan (tanpa admin) — urut terbanyak.
        $siswaPerJurusan = Jurusan::query()
            ->withCount(['pengguna as jumlah' => fn ($q) => $q->where('peran', 'siswa')])
            ->orderByDesc('jumlah')
            ->orderBy('id')
            ->get()
            ->map(fn (Jurusan $j): array => [
                'nama' => $j->nama,
                'jumlah' => (int) $j->jumlah,
            ])
            ->values();

        // Kuota tiap industri: terpakai = penempatan disetujui.
        // Diurut dari yang paling penuh supaya yang hampir penuh kelihatan.
        $kuotaIndustri = Industri::query()
            ->withCount([
                'pengajuanPkl as terpakai' => fn ($q) => $q->where('status', 'disetujui'),
                'pengajuanPkl as menunggu' => fn ($q) => $q->where('status', 'menunggu'),
            ])
            ->get(['id', 'nama', 'kuota'])
            ->map(fn (Industri $i): array => [
                'nama' => $i->nama,
                'kuota' => (int) $i->kuota,
                'terpakai' => (int) $i->terpakai,
                'menunggu' => (int) $i->menunggu,
            ])
            ->sortByDesc(fn (array $i): float => $i['kuota'] > 0 ? $i['terpakai'] / $i['kuota'] : 0)
            ->values();

        return response()->json(['data' => [
            'total_siswa' => Pengguna::where('peran', 'siswa')->count(),
            'total_industri' => Industri::count(),
            'pengajuan_menunggu' => PengajuanPkl::where('status', 'menunggu')->count(),
            'pengajuan_disetujui' => PengajuanPkl::where('status', 'disetujui')->count(),
            'pengajuan_ditolak' => PengajuanPkl::where('status', 'ditolak')->count(),
            'pengajuan_per_bulan' => $bulan,
            'top_industri' => $topIndustri,
            'siswa_per_jurusan' => $siswaPerJurusan,
            'kuota_industri' => $kuotaIndustri->values(),
        ]]);
    }
}
