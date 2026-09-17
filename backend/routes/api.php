<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\IndustriController;
use App\Http\Controllers\PengajuanPklController;
use App\Http\Controllers\AdminPengajuanController;
use App\Http\Controllers\TempatSekitarController;

Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:login');

Route::middleware('auth:sanctum')->group(function (): void {
    Route::get('/profil', [AuthController::class, 'profil']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/industri', [IndustriController::class, 'index']);
    Route::get('/industri/{industri}', [IndustriController::class, 'show']);
    Route::get('/tempat-sekitar', [TempatSekitarController::class, 'index']);
    Route::get('/pengajuan', [PengajuanPklController::class, 'index']);
    Route::post('/pengajuan', [PengajuanPklController::class, 'store']);
    Route::get('/pengajuan/{id}', [PengajuanPklController::class, 'show']);

    Route::prefix('admin')->middleware('peran:admin')->group(function (): void {
        Route::get('/pengajuan', [AdminPengajuanController::class, 'index']);
        Route::get('/pengajuan/{id}', [AdminPengajuanController::class, 'show']);
        Route::patch('/pengajuan/{id}/setujui', [AdminPengajuanController::class, 'setujui']);
        Route::patch('/pengajuan/{id}/tolak', [AdminPengajuanController::class, 'tolak']);
    });
});
