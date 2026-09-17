<?php

namespace Tests\Feature;

use App\Models\Jurusan;
use App\Models\Pengguna;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AutentikasiTest extends TestCase
{
    use RefreshDatabase;

    public function test_pengguna_dapat_login_menggunakan_nis(): void
    {
        $jurusan = Jurusan::create(['nama' => 'Rekayasa Perangkat Lunak']);
        Pengguna::create([
            'nis' => '2413025058',
            'nama' => 'Desta Arya Putra',
            'password' => 'password',
            'jurusan_id' => $jurusan->id,
            'peran' => 'siswa',
        ]);

        $response = $this->postJson('/api/login', [
            'nis' => '2413025058',
            'password' => 'password',
        ]);

        $response->assertOk()
            ->assertJsonPath('pengguna.nis', '2413025058')
            ->assertJsonStructure(['token', 'pengguna']);
    }

    public function test_login_menolak_kredensial_tidak_valid(): void
    {
        $response = $this->postJson('/api/login', [
            'nis' => 'tidak-ada',
            'password' => 'salah',
        ]);

        $response->assertUnauthorized();
    }
}