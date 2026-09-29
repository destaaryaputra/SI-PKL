<?php

namespace App\Http\Controllers;

use App\Models\Jurusan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminJurusanController extends Controller
{
    public function index(): JsonResponse
    {
        $jurusan = Jurusan::query()
            ->withCount('pengguna as jumlah_siswa')
            ->orderBy('nama')
            ->get()
            ->map(fn (Jurusan $item): array => [
                'id' => $item->id,
                'nama' => $item->nama,
                'jumlah_siswa' => $item->jumlah_siswa,
            ]);

        return response()->json(['data' => $jurusan]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'nama' => ['required', 'string', 'max:100', 'unique:jurusan,nama'],
        ]);

        $jurusan = Jurusan::create(['nama' => $data['nama']]);

        return response()->json([
            'pesan' => 'Jurusan berhasil ditambahkan.',
            'data' => $jurusan,
        ], 201);
    }

    public function update(Request $request, Jurusan $jurusan): JsonResponse
    {
        $data = $request->validate([
            'nama' => [
                'required', 'string', 'max:100',
                Rule::unique('jurusan', 'nama')->ignore($jurusan->id),
            ],
        ]);

        $jurusan->update(['nama' => $data['nama']]);

        return response()->json([
            'pesan' => 'Jurusan berhasil diperbarui.',
            'data' => $jurusan,
        ]);
    }

    public function destroy(Jurusan $jurusan): JsonResponse
    {
        $masihDipakai = $jurusan->pengguna()->exists() || $jurusan->industri()->exists();

        if ($masihDipakai) {
            return response()->json([
                'pesan' => 'Jurusan tidak dapat dihapus karena masih dipakai oleh siswa atau industri.',
            ], 422);
        }

        $jurusan->delete();

        return response()->json([
            'pesan' => 'Jurusan berhasil dihapus.',
        ]);
    }
}
