<?php

namespace App\Http\Controllers;

use App\Models\Jurusan;
use Illuminate\Http\JsonResponse;

class JurusanController extends Controller
{
    public function index(): JsonResponse
    {
        $jurusan = Jurusan::query()
            ->orderBy('nama')
            ->get()
            ->map(fn (Jurusan $item): array => [
                'id' => $item->id,
                'nama' => $item->nama,
            ]);

        return response()->json(['data' => $jurusan]);
    }
}
