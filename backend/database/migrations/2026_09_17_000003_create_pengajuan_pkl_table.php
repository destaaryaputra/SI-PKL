<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pengajuan_pkl', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pengguna_id')->constrained('pengguna')->cascadeOnDelete();
            $table->foreignId('industri_id')->constrained('industri')->cascadeOnDelete();
            $table->enum('status', ['menunggu', 'disetujui', 'ditolak'])->default('menunggu');
            $table->year('tahun')->nullable()->index();
            $table->text('catatan')->nullable();
            $table->foreignId('diperiksa_oleh')->nullable()->constrained('pengguna')->nullOnDelete();
            $table->timestamp('diperiksa_pada')->nullable();
            $table->timestamps();

            $table->index(['industri_id', 'status']);
            $table->index(['pengguna_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pengajuan_pkl');
    }
};