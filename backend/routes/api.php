<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\IndustriController;
use App\Http\Controllers\JurusanController;
use App\Http\Controllers\PengajuanPklController;
use App\Http\Controllers\AdminPengajuanController;
use App\Http\Controllers\AdminSiswaController;
use App\Http\Controllers\AdminJurusanController;
use App\Http\Controllers\AdminIndustriController;
use App\Http\Controllers\AdminStatistikController;
use App\Http\Controllers\TempatSekitarController;
use App\Http\Controllers\RiwayatController;

Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:login');

Route::middleware('auth:sanctum')->group(function (): void {
    Route::get('/profil', [AuthController::class, 'profil']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/jurusan', [JurusanController::class, 'index']);
    Route::get('/industri', [IndustriController::class, 'index']);
    Route::get('/industri/{industri}', [IndustriController::class, 'show']);
    Route::get('/industri/{industri}/riwayat', [RiwayatController::class, 'perIndustri']);
    Route::get('/riwayat', [RiwayatController::class, 'perSiswa']);
    Route::get('/tempat-sekitar', [TempatSekitarController::class, 'index']);
    Route::get('/pengajuan', [PengajuanPklController::class, 'index']);
    Route::post('/pengajuan', [PengajuanPklController::class, 'store']);
    Route::get('/pengajuan/{id}', [PengajuanPklController::class, 'show']);

    Route::prefix('admin')->middleware('peran:admin')->group(function (): void {
        Route::get('/statistik', [AdminStatistikController::class, 'index']);

        Route::get('/pengajuan', [AdminPengajuanController::class, 'index']);
        Route::get('/pengajuan/{id}', [AdminPengajuanController::class, 'show']);
        Route::patch('/pengajuan/{id}/setujui', [AdminPengajuanController::class, 'setujui']);
        Route::patch('/pengajuan/{id}/tolak', [AdminPengajuanController::class, 'tolak']);

        Route::get('/siswa', [AdminSiswaController::class, 'index']);
        Route::post('/siswa', [AdminSiswaController::class, 'store']);
        Route::put('/siswa/{siswa}', [AdminSiswaController::class, 'update']);
        Route::delete('/siswa/{siswa}', [AdminSiswaController::class, 'destroy']);

        Route::get('/jurusan', [AdminJurusanController::class, 'index']);
        Route::post('/jurusan', [AdminJurusanController::class, 'store']);
        Route::put('/jurusan/{jurusan}', [AdminJurusanController::class, 'update']);
        Route::delete('/jurusan/{jurusan}', [AdminJurusanController::class, 'destroy']);

        Route::get('/industri', [AdminIndustriController::class, 'index']);
        Route::post('/industri', [AdminIndustriController::class, 'store']);
        Route::put('/industri/{industri}', [AdminIndustriController::class, 'update']);
        Route::delete('/industri/{industri}', [AdminIndustriController::class, 'destroy']);
    });
});
