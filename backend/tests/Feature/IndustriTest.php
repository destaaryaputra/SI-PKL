<?php

namespace Tests\Feature;

use App\Models\Industri;
use App\Models\Jurusan;
use App\Models\Pengguna;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class IndustriTest extends TestCase
{
    use RefreshDatabase;

    public function test_siswa_dapat_mencari_dan_memfilter_industri(): void
    {
        $jurusan = Jurusan::create(['nama' => 'Rekayasa Perangkat Lunak']);
        $siswa = Pengguna::create([
            'nis' => '2413025058',
            'nama' => 'Desta Arya Putra',
            'password' => 'password',
            'jurusan_id' => $jurusan->id,
            'peran' => 'siswa',
        ]);

        $industri = Industri::create([
            'nama' => 'PT Teknologi Lampung',
            'alamat' => 'Bandar Lampung',
            'latitude' => -5.3971,
            'longitude' => 105.2668,
            'kuota' => 5,
        ]);
        $industri->jurusan()->attach($jurusan);

        $response = $this->actingAs($siswa, 'sanctum')
            ->getJson('/api/industri?cari=Teknologi&jurusan_id='.$jurusan->id);

        $response->assertOk()
            ->assertJsonPath('data.0.nama', 'PT Teknologi Lampung')
            ->assertJsonPath('data.0.sisa_kuota', 5)
            ->assertJsonPath('data.0.jurusan.0', 'Rekayasa Perangkat Lunak');
    }
}
