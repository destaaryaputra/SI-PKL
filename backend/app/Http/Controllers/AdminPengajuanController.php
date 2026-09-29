<?php

namespace App\Http\Controllers;

use App\Models\PengajuanPkl;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class AdminPengajuanController extends Controller
{
    public function index(): JsonResponse
    {
        $pengajuan = PengajuanPkl::query()
            ->with(['pengguna:id,nis,nama', 'industri:id,nama', 'pemeriksa:id,nama'])
            ->latest()
            ->get();

        return response()->json(['data' => $pengajuan]);
    }

    public function show(int $id): JsonResponse
    {
        $pengajuan = PengajuanPkl::with(['pengguna.jurusan', 'industri', 'pemeriksa'])
            ->findOrFail($id);

        return response()->json(['data' => $pengajuan]);
    }

    public function setujui(Request $request, int $id): JsonResponse
    {
        $pengajuan = DB::transaction(function () use ($request, $id): PengajuanPkl {
            $pengajuan = PengajuanPkl::query()
                ->with('industri')
                ->lockForUpdate()
                ->findOrFail($id);

            $this->pastikanMenunggu($pengajuan);

            $jumlahTerpakai = PengajuanPkl::query()
                ->where('industri_id', $pengajuan->industri_id)
                ->whereIn('status', ['menunggu', 'disetujui'])
                ->count();

            if ($jumlahTerpakai > $pengajuan->industri->kuota) {
                throw ValidationException::withMessages([
                    'pengajuan' => 'Kuota industri sudah tidak mencukupi.',
                ]);
            }

            $pengajuan->update([
                'status' => 'disetujui',
                // Tahun penempatan dicatat saat disetujui (FR-17).
                'tahun' => now()->year,
                'catatan' => $request->input('catatan', $pengajuan->catatan),
                'diperiksa_oleh' => $request->user()->id,
                'diperiksa_pada' => now(),
            ]);

            return $pengajuan->fresh(['pengguna', 'industri', 'pemeriksa']);
        });

        return response()->json([
            'pesan' => 'Pengajuan berhasil disetujui.',
            'data' => $pengajuan,
        ]);
    }

    public function tolak(Request $request, int $id): JsonResponse
    {
        $data = $request->validate([
            'catatan' => ['nullable', 'string', 'max:1000'],
        ]);

        $pengajuan = PengajuanPkl::findOrFail($id);
        $this->pastikanMenunggu($pengajuan);
        $pengajuan->update([
            'status' => 'ditolak',
            'catatan' => $data['catatan'] ?? null,
            'diperiksa_oleh' => $request->user()->id,
            'diperiksa_pada' => now(),
        ]);

        return response()->json([
            'pesan' => 'Pengajuan berhasil ditolak.',
            'data' => $pengajuan->fresh(['pengguna', 'industri', 'pemeriksa']),
        ]);
    }

    private function pastikanMenunggu(PengajuanPkl $pengajuan): void
    {
        if ($pengajuan->status !== 'menunggu') {
            throw ValidationException::withMessages([
                'pengajuan' => 'Pengajuan ini sudah diproses.',
            ]);
        }
    }
}
