<?php

namespace App\Http\Controllers;

use App\Models\Pengguna;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminSiswaController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $data = $request->validate([
            'cari' => ['nullable', 'string', 'max:100'],
        ]);

        $siswa = Pengguna::query()
            ->where('peran', 'siswa')
            ->with('jurusan:id,nama')
            ->when($data['cari'] ?? null, function ($query, string $cari): void {
                $query->where(function ($query) use ($cari): void {
                    $query->where('nama', 'like', "%{$cari}%")
                        ->orWhere('nis', 'like', "%{$cari}%");
                });
            })
            ->orderBy('nama')
            ->get()
            ->map(fn (Pengguna $item): array => $this->formatSiswa($item));

        return response()->json(['data' => $siswa]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'nis' => ['required', 'string', 'max:20', 'unique:pengguna,nis'],
            'nama' => ['required', 'string', 'max:100'],
            'jurusan_id' => ['nullable', 'integer', 'exists:jurusan,id'],
            'password' => ['required', 'string', 'min:6'],
        ]);

        $siswa = Pengguna::create([
            'nis' => $data['nis'],
            'nama' => $data['nama'],
            'jurusan_id' => $data['jurusan_id'] ?? null,
            'password' => $data['password'],
            'peran' => 'siswa',
        ]);

        return response()->json([
            'pesan' => 'Siswa berhasil ditambahkan.',
            'data' => $this->formatSiswa($siswa->load('jurusan')),
        ], 201);
    }

    public function update(Request $request, Pengguna $siswa): JsonResponse
    {
        if ($siswa->peran !== 'siswa') {
            return response()->json([
                'pesan' => 'Pengguna ini bukan siswa.',
            ], 404);
        }

        $data = $request->validate([
            'nis' => [
                'required', 'string', 'max:20',
                Rule::unique('pengguna', 'nis')->ignore($siswa->id),
            ],
            'nama' => ['required', 'string', 'max:100'],
            'jurusan_id' => ['nullable', 'integer', 'exists:jurusan,id'],
            'password' => ['nullable', 'string', 'min:6'],
        ]);

        $siswa->update([
            'nis' => $data['nis'],
            'nama' => $data['nama'],
            'jurusan_id' => $data['jurusan_id'] ?? null,
            ...($data['password'] ?? '' !== '' ? ['password' => $data['password']] : []),
        ]);

        return response()->json([
            'pesan' => 'Data siswa berhasil diperbarui.',
            'data' => $this->formatSiswa($siswa->fresh('jurusan')),
        ]);
    }

    public function destroy(Pengguna $siswa): JsonResponse
    {
        if ($siswa->peran !== 'siswa') {
            return response()->json([
                'pesan' => 'Pengguna ini bukan siswa.',
            ], 403);
        }

        $siswa->delete();

        return response()->json([
            'pesan' => 'Siswa berhasil dihapus.',
        ]);
    }

    private function formatSiswa(Pengguna $siswa): array
    {
        return [
            'id' => $siswa->id,
            'nis' => $siswa->nis,
            'nama' => $siswa->nama,
            'jurusan' => $siswa->jurusan?->only(['id', 'nama']),
        ];
    }
}
