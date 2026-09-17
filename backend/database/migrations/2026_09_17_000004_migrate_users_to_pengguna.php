<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('users') && ! Schema::hasTable('pengguna')) {
            Schema::rename('users', 'pengguna');
        }

        if (! Schema::hasTable('jurusan')) {
            Schema::create('jurusan', function (Blueprint $table) {
                $table->id();
                $table->string('nama')->unique();
                $table->timestamps();
            });
        }

        if (Schema::hasTable('pengguna')) {
            Schema::table('pengguna', function (Blueprint $table) {
                if (Schema::hasColumn('pengguna', 'name')) {
                    $table->renameColumn('name', 'nama');
                }
                if (Schema::hasColumn('pengguna', 'email')) {
                    $table->dropUnique('users_email_unique');
                    $table->dropColumn('email');
                }
                if (Schema::hasColumn('pengguna', 'email_verified_at')) {
                    $table->dropColumn('email_verified_at');
                }
                if (Schema::hasColumn('pengguna', 'remember_token')) {
                    $table->dropColumn('remember_token');
                }
                if (! Schema::hasColumn('pengguna', 'nis')) {
                    $table->string('nis')->nullable()->unique();
                }
                if (! Schema::hasColumn('pengguna', 'jurusan_id')) {
                    $table->foreignId('jurusan_id')->nullable()->constrained('jurusan')->nullOnDelete();
                }
                if (! Schema::hasColumn('pengguna', 'peran')) {
                    $table->enum('peran', ['siswa', 'admin'])->default('siswa');
                }
            });

            DB::table('pengguna')->whereNull('nis')->get()->each(function ($pengguna): void {
                DB::table('pengguna')
                    ->where('id', $pengguna->id)
                    ->update(['nis' => 'LEGACY-'.$pengguna->id]);
            });
        }
    }

    public function down(): void
    {
        // This migration preserves existing data and is intentionally irreversible.
    }
};