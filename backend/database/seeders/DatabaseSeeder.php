<?php

namespace Database\Seeders;

use App\Models\Industri;
use App\Models\Jurusan;
use App\Models\Pengguna;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $rpl = Jurusan::create(['nama' => 'Rekayasa Perangkat Lunak']);
        $tkj = Jurusan::create(['nama' => 'Teknik Komputer dan Jaringan']);

        Pengguna::create([
            'nis' => 'ADMIN001',
            'nama' => 'Admin SI-PKL',
            'password' => 'password',
            'peran' => 'admin',
        ]);

        $siswa = Pengguna::create([
            'nis' => '2413025058',
            'nama' => 'Desta Arya Putra',
            'password' => 'password',
            'jurusan_id' => $rpl->id,
            'peran' => 'siswa',
        ]);

        $industri = Industri::create([
            'nama' => 'PT Maju Sejahtera',
            'alamat' => 'Bandar Lampung',
            'latitude' => -5.3971,
            'longitude' => 105.2668,
            'kuota' => 10,
        ]);

        $industri->jurusan()->attach([$rpl->id, $tkj->id]);
    }
}
