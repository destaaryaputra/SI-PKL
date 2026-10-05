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
        // Create Jurusan
        $rpl = Jurusan::create(['nama' => 'Rekayasa Perangkat Lunak']);
        $tkj = Jurusan::create(['nama' => 'Teknik Komputer dan Jaringan']);
        $tbk = Jurusan::create(['nama' => 'Teknik Bangunan']);
        $tj = Jurusan::create(['nama' => 'Teknik Elektro']);
        $pm = Jurusan::create(['nama' => 'Penerbangan']);

        // Create Admin
        Pengguna::create([
            'nis' => 'ADMIN001',
            'nama' => 'Admin SI-PKL',
            'password' => 'password',
            'peran' => 'admin',
        ]);

        // Create Siswa
        $siswas = [
            ['nis' => '2413025058', 'nama' => 'Desta Arya Putra', 'jurusan_id' => $rpl->id],
            ['nis' => '2413025001', 'nama' => 'Ahmad Rizal', 'jurusan_id' => $rpl->id],
            ['nis' => '2413025002', 'nama' => 'Siti Nurhaliza', 'jurusan_id' => $rpl->id],
            ['nis' => '2413025003', 'nama' => 'Budi Santoso', 'jurusan_id' => $tkj->id],
            ['nis' => '2413025004', 'nama' => 'Dewi Lestari', 'jurusan_id' => $tkj->id],
            ['nis' => '2413025005', 'nama' => 'Eko Prasetyo', 'jurusan_id' => $tbk->id],
            ['nis' => '2413025006', 'nama' => 'Fani Putri', 'jurusan_id' => $tj->id],
            ['nis' => '2413025007', 'nama' => 'Guna Brata', 'jurusan_id' => $pm->id],
        ];

        foreach ($siswas as $siswa) {
            Pengguna::create([
                'nis' => $siswa['nis'],
                'nama' => $siswa['nama'],
                'password' => 'password',
                'jurusan_id' => $siswa['jurusan_id'],
                'peran' => 'siswa',
            ]);
        }

        // Create Industri
        // Nama + alamat perusahaan asli di Bandar Lampung; koordinat hasil
        // geocoding OpenStreetMap (Nominatim), titik di jalan terdekat.
        // Logo via favicon domain resmi perusahaan (layanan publik Google S2).
        $industri1 = Industri::create([
            'nama' => 'Newus Technology',
            'alamat' => 'Jl. Salim Batubara No. 118, Kupang Teba, Tlk. Betung Utara',
            'logo_url' => '/logo/newus.png',
            'latitude' => -5.4389667,
            'longitude' => 105.2657216,
            'kuota' => 10,
        ]);
        $industri1->jurusan()->attach([$rpl->id, $tkj->id]);

        $industri2 = Industri::create([
            'nama' => 'Microdata Indonesia',
            'alamat' => 'Jl. Endro Suratmin No. 53-F, Way Dadi, Sukarame',
            'logo_url' => '/logo/microdata.jpg',
            'latitude' => -5.3893467,
            'longitude' => 105.2884412,
            'kuota' => 8,
        ]);
        $industri2->jurusan()->attach([$rpl->id, $tj->id]);

        $industri3 = Industri::create([
            'nama' => 'CV Agung Indotech Pratama',
            'alamat' => 'Jl. Wolter Monginsidi Gg. Murai No. 30, Pengajaran, Tlk. Betung Utara',
            'latitude' => -5.4324088,
            'longitude' => 105.2539744,
            'kuota' => 6,
        ]);
        $industri3->jurusan()->attach([$tbk->id]);

        $industri4 = Industri::create([
            'nama' => 'PT Hanjung Indonesia',
            'alamat' => 'Jl. Raya Soekarno Hatta Km. 11,5, Srengsem, Panjang',
            'latitude' => -5.4590804,
            'longitude' => 105.3174030,
            'kuota' => 12,
        ]);
        $industri4->jurusan()->attach([$tj->id, $tkj->id]);

        $industri5 = Industri::create([
            'nama' => 'Djcorp (DCS Building)',
            'alamat' => 'DCS Building Lt. 2, Jl. ZA. Pagar Alam No. 93, Labuhan Ratu',
            'latitude' => -5.3664482,
            'longitude' => 105.2307513,
            'kuota' => 5,
        ]);
        $industri5->jurusan()->attach([$pm->id, $tkj->id]);

        // Batch kedua: perusahaan nyata lain di Bandar Lampung & Lampung.
        // Koordinat hasil geocoding Nominatim di tingkat jalan/kecamatan
        // terdekat (beberapa jalan tidak terpetakan di OSM).
        $industri6 = Industri::create([
            'nama' => 'Ginktech',
            'alamat' => 'Jl. Way Pengubuan No. 16, Bandar Lampung',
            'logo_url' => '/logo/ginktech.png',
            'latitude' => -5.4258695,
            'longitude' => 105.2726540,
            'kuota' => 8,
        ]);
        $industri6->jurusan()->attach([$rpl->id, $tkj->id]);

        $industri7 = Industri::create([
            'nama' => 'PT Silsoft',
            'alamat' => 'Jl. P. Tidore, Jagabaya II, Bandar Lampung',
            'latitude' => -5.3924371,
            'longitude' => 105.2664223,
            'kuota' => 6,
        ]);
        $industri7->jurusan()->attach([$rpl->id]);

        $industri8 = Industri::create([
            'nama' => 'PT Mandala Lintas Nusa (Nusanet Lampung)',
            'alamat' => 'Jl. Cut Nyak Dien No. 39B, Durian Payung, Tj. Karang Pusat',
            'logo_url' => '/logo/nusanet.png',
            'latitude' => -5.4186618,
            'longitude' => 105.2498718,
            'kuota' => 10,
        ]);
        $industri8->jurusan()->attach([$tkj->id, $rpl->id]);

        $industri9 = Industri::create([
            'nama' => 'REPCOM',
            'alamat' => 'Jl. Urip Sumoharjo No. 9, Bandar Lampung',
            'latitude' => -5.3901353,
            'longitude' => 105.2872549,
            'kuota' => 5,
        ]);
        $industri9->jurusan()->attach([$tkj->id]);

        $industri10 = Industri::create([
            'nama' => 'PT Semen Baturaja (Pabrik Panjang)',
            'alamat' => 'Jl. Yos Sudarso Km. 7, Panjang, Bandar Lampung',
            'logo_url' => '/logo/semen-baturaja.png',
            'latitude' => -5.4787053,
            'longitude' => 105.3284666,
            'kuota' => 15,
        ]);
        $industri10->jurusan()->attach([$tbk->id, $tj->id]);

        $industri11 = Industri::create([
            'nama' => 'PT Nestle Indonesia (Panjang Factory)',
            'alamat' => 'Kawasan Industri Panjang, Bandar Lampung',
            'logo_url' => '/logo/nestle.png',
            'latitude' => -5.4523924,
            'longitude' => 105.2595864,
            'kuota' => 12,
        ]);
        $industri11->jurusan()->attach([$tj->id]);

        $industri12 = Industri::create([
            'nama' => 'PT Aman Jaya Perdana',
            'alamat' => 'Jl. Ir. Sutami Km. 7, Campang Jaya, Sukabumi',
            'latitude' => -5.3974767,
            'longitude' => 105.2946540,
            'kuota' => 8,
        ]);
        $industri12->jurusan()->attach([$tj->id, $tbk->id]);

        $industri13 = Industri::create([
            'nama' => 'TMSNet',
            'alamat' => 'Jl. Imam Bonjol Gg. Waluh V No. 9, Kemiling Raya, Kemiling',
            'logo_url' => '/logo/tmsnet.png',
            'latitude' => -5.3721751,
            'longitude' => 105.2124318,
            'kuota' => 6,
        ]);
        $industri13->jurusan()->attach([$tkj->id]);
    }
}
