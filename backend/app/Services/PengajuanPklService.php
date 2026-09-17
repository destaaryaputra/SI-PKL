<?php

namespace App\Services;

use App\Models\Industri;
use App\Models\PengajuanPkl;
use App\Models\Pengguna;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class PengajuanPklService
{
    public function ajukan(Pengguna $pengguna, int $industriId, ?string $catatan): PengajuanPkl
    {
        return DB::transaction(function () use ($pengguna, $industriId, $catatan): PengajuanPkl {
            $industri = Industri::query()->lockForUpdate()->findOrFail($industriId);

            $sudahMengajukan = PengajuanPkl::query()
                ->where('pengguna_id', $pengguna->id)
                ->whereIn('status', ['menunggu', 'disetujui'])
                ->exists();

            if ($sudahMengajukan) {
                throw ValidationException::withMessages([
                    'pengajuan' => 'Kamu masih memiliki pengajuan PKL yang aktif.',
                ]);
            }

            if ($pengguna->jurusan_id === null || ! $industri->jurusan()->whereKey($pengguna->jurusan_id)->exists()) {
                throw ValidationException::withMessages([
                    'industri_id' => 'Industri ini tidak menerima jurusan kamu.',
                ]);
            }

            $jumlahTerpakai = PengajuanPkl::query()
                ->where('industri_id', $industri->id)
                ->whereIn('status', ['menunggu', 'disetujui'])
                ->count();

            if ($jumlahTerpakai >= $industri->kuota) {
                throw ValidationException::withMessages([
                    'industri_id' => 'Kuota industri sudah penuh.',
                ]);
            }

            return PengajuanPkl::create([
                'pengguna_id' => $pengguna->id,
                'industri_id' => $industri->id,
                'status' => 'menunggu',
                'catatan' => $catatan,
            ])->load('industri');
        });
    }
}
