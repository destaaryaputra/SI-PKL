<?php

namespace App\Http\Controllers;

use App\Services\PengajuanPklService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PengajuanPklController extends Controller
{
    public function __construct(private readonly PengajuanPklService $service)
    {
    }

    public function index(Request $request): JsonResponse
    {
        $pengajuan = $request->user()
            ->pengajuanPkl()
            ->with('industri')
            ->latest()
            ->get();

        return response()->json(['data' => $pengajuan]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'industri_id' => ['required', 'integer', 'exists:industri,id'],
            'catatan' => ['nullable', 'string', 'max:1000'],
        ]);

        $pengajuan = $this->service->ajukan(
            $request->user(),
            $data['industri_id'],
            $data['catatan'] ?? null,
        );

        return response()->json([
            'pesan' => 'Pengajuan PKL berhasil dikirim.',
            'data' => $pengajuan,
        ], 201);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $pengajuan = $request->user()
            ->pengajuanPkl()
            ->with('industri')
            ->findOrFail($id);

        return response()->json(['data' => $pengajuan]);
    }
}
