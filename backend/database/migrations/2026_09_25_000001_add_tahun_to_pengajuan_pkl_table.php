<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Tahun penempatan PKL, diisi saat pengajuan disetujui (FR-17).
        Schema::table('pengajuan_pkl', function (Blueprint $table): void {
            $table->year('tahun')->nullable()->after('status')->index();
        });
    }

    public function down(): void
    {
        Schema::table('pengajuan_pkl', function (Blueprint $table): void {
            $table->dropIndex(['tahun']);
            $table->dropColumn('tahun');
        });
    }
};
