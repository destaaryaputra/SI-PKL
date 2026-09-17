<?php

namespace App\Http\Controllers;

use App\Models\Industri;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class IndustriController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $data = $request->validate([
            'cari' => ['nullable', 'string', 'max:100'],
            'jurusan_id' => ['nullable', 'integer', 'exists:jurusan,id'],
        ]);

        $industri = Industri::query()
            ->with('jurusan:id,nama')
            ->withCount([
                'pengajuanPkl as jumlah_menunggu' => fn ($query) => $query->where('status', 'menunggu'),
                'pengajuanPkl as jumlah_disetujui' => fn ($query) => $query->where('status', 'disetujui'),
            ])
            ->when($data['cari'] ?? null, function ($query, string $cari): void {
                $query->where(function ($query) use ($cari): void {
                    $query->where('nama', 'like', "%{$cari}%")
                        ->orWhere('alamat', 'like', "%{$cari}%");
                });
            })
            ->when($data['jurusan_id'] ?? null, function ($query, int $jurusanId): void {
                $query->whereHas('jurusan', fn ($query) => $query->whereKey($jurusanId));
            })
            ->orderBy('nama')
            ->get()
            ->map(fn (Industri $item): array => $this->formatIndustri($item));

        return response()->json(['data' => $industri]);
    }

    public function show(Industri $industri): JsonResponse
    {
        $industri->load('jurusan:id,nama')->loadCount([
            'pengajuanPkl as jumlah_menunggu' => fn ($query) => $query->where('status', 'menunggu'),
            'pengajuanPkl as jumlah_disetujui' => fn ($query) => $query->where('status', 'disetujui'),
        ]);

        return response()->json(['data' => $this->formatIndustri($industri)]);
    }

    private function formatIndustri(Industri $industri): array
    {
        $jumlahTerpakai = $industri->jumlah_menunggu + $industri->jumlah_disetujui;

        return [
            'id' => $industri->id,
            'nama' => $industri->nama,
            'alamat' => $industri->alamat,
            'latitude' => $industri->latitude,
            'longitude' => $industri->longitude,
            'kuota' => $industri->kuota,
            'jumlah_menunggu' => $industri->jumlah_menunggu,
            'jumlah_disetujui' => $industri->jumlah_disetujui,
            'sisa_kuota' => max(0, $industri->kuota - $jumlahTerpakai),
            'jurusan' => $industri->jurusan->pluck('nama')->values(),
        ];
    }
}
