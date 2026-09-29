<?php

namespace App\Http\Controllers;

use App\Models\Industri;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminIndustriController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $data = $request->validate([
            'cari' => ['nullable', 'string', 'max:100'],
        ]);

        $industri = Industri::query()
            ->with('jurusan:id,nama')
            ->when($data['cari'] ?? null, function ($query, string $cari): void {
                $query->where(function ($query) use ($cari): void {
                    $query->where('nama', 'like', "%{$cari}%")
                        ->orWhere('alamat', 'like', "%{$cari}%");
                });
            })
            ->orderBy('nama')
            ->get()
            ->map(fn (Industri $item): array => $this->formatIndustri($item));

        return response()->json(['data' => $industri]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'nama' => ['required', 'string', 'max:150'],
            'alamat' => ['required', 'string', 'max:500'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'kuota' => ['required', 'integer', 'min:1', 'max:1000'],
            'jurusan_ids' => ['required', 'array', 'min:1'],
            'jurusan_ids.*' => ['integer', 'exists:jurusan,id'],
        ]);

        $industri = DB::transaction(function () use ($data): Industri {
            $industri = Industri::create([
                'nama' => $data['nama'],
                'alamat' => $data['alamat'],
                'latitude' => $data['latitude'],
                'longitude' => $data['longitude'],
                'kuota' => $data['kuota'],
            ]);
            $industri->jurusan()->sync($data['jurusan_ids']);

            return $industri;
        });

        return response()->json([
            'pesan' => 'Industri berhasil ditambahkan.',
            'data' => $this->formatIndustri($industri->load('jurusan')),
        ], 201);
    }

    public function update(Request $request, Industri $industri): JsonResponse
    {
        $data = $request->validate([
            'nama' => ['required', 'string', 'max:150'],
            'alamat' => ['required', 'string', 'max:500'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            // Kuota tidak boleh di bawah jumlah terpakai saat ini.
            'kuota' => ['required', 'integer', 'min:1', 'max:1000'],
            'jurusan_ids' => ['required', 'array', 'min:1'],
            'jurusan_ids.*' => ['integer', 'exists:jurusan,id'],
        ]);

        $jumlahTerpakai = $industri->pengajuanPkl()
            ->whereIn('status', ['menunggu', 'disetujui'])
            ->count();

        if ($data['kuota'] < $jumlahTerpakai) {
            return response()->json([
                'pesan' => "Kuota tidak boleh lebih kecil dari jumlah terpakai saat ini ({$jumlahTerpakai}).",
            ], 422);
        }

        DB::transaction(function () use ($industri, $data): void {
            $industri->update([
                'nama' => $data['nama'],
                'alamat' => $data['alamat'],
                'latitude' => $data['latitude'],
                'longitude' => $data['longitude'],
                'kuota' => $data['kuota'],
            ]);
            $industri->jurusan()->sync($data['jurusan_ids']);
        });

        return response()->json([
            'pesan' => 'Data industri berhasil diperbarui.',
            'data' => $this->formatIndustri($industri->fresh('jurusan')),
        ]);
    }

    public function destroy(Industri $industri): JsonResponse
    {
        $masihDipakai = $industri->pengajuanPkl()->exists();

        if ($masihDipakai) {
            return response()->json([
                'pesan' => 'Industri tidak dapat dihapus karena sudah memiliki data pengajuan PKL.',
            ], 422);
        }

        $industri->delete();

        return response()->json([
            'pesan' => 'Industri berhasil dihapus.',
        ]);
    }

    private function formatIndustri(Industri $industri): array
    {
        return [
            'id' => $industri->id,
            'nama' => $industri->nama,
            'alamat' => $industri->alamat,
            'latitude' => $industri->latitude,
            'longitude' => $industri->longitude,
            'kuota' => $industri->kuota,
            'jurusan_ids' => $industri->jurusan->pluck('id')->values(),
            'jurusan' => $industri->jurusan->pluck('nama')->values(),
        ];
    }
}
