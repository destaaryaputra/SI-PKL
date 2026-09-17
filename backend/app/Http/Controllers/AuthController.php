<?php

namespace App\Http\Controllers;

use App\Models\Pengguna;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'nis' => ['required', 'string'],
            'password' => ['required', 'string'],
        ]);

        if (! Auth::attempt(['nis' => $data['nis'], 'password' => $data['password']])) {
            return response()->json([
                'pesan' => 'NIS atau password tidak valid.',
            ], 401);
        }

        /** @var Pengguna $pengguna */
        $pengguna = Auth::user();
        $pengguna->tokens()->delete();

        return response()->json([
            'pesan' => 'Login berhasil.',
            'token' => $pengguna->createToken('aplikasi-mobile')->plainTextToken,
            'pengguna' => $pengguna->load('jurusan'),
        ]);
    }

    public function profil(Request $request): JsonResponse
    {
        return response()->json([
            'pengguna' => $request->user()->load('jurusan'),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json([
            'pesan' => 'Logout berhasil.',
        ]);
    }
}
