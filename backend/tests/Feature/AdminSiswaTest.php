<?php

namespace Tests\Feature;

use App\Models\Jurusan;
use App\Models\Pengguna;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminSiswaTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_dapat_melihat_daftar_siswa(): void
    {
        $admin = $this->buatAdmin();
        $this->buatSiswa('2413025001', 'Ahmad Rizal');

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/admin/siswa');

        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.nama', 'Ahmad Rizal');
        $this->assertStringContainsString('Rekayasa Perangkat Lunak', $response->json('data.0.jurusan.nama'));
    }

    public function test_admin_dapat_menambah_siswa(): void
    {
        $admin = $this->buatAdmin();
        $jurusan = Jurusan::create(['nama' => 'Teknik Komputer dan Jaringan']);

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/admin/siswa', [
                'nis' => '2413025099',
                'nama' => 'Siswa Baru',
                'jurusan_id' => $jurusan->id,
                'password' => 'rahasia123',
            ]);

        $response->assertCreated()
            ->assertJsonPath('data.nama', 'Siswa Baru');
        $this->assertDatabaseHas('pengguna', [
            'nis' => '2413025099',
            'peran' => 'siswa',
        ]);
    }

    public function test_nis_duplikat_ditolak(): void
    {
        $admin = $this->buatAdmin();
        $this->buatSiswa('2413025001', 'Ahmad Rizal');

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/admin/siswa', [
                'nis' => '2413025001',
                'nama' => 'Duplikat',
                'password' => 'rahasia123',
            ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['nis']);
    }

    public function test_admin_dapat_mengubah_siswa(): void
    {
        $admin = $this->buatAdmin();
        $siswa = $this->buatSiswa('2413025001', 'Ahmad Rizal');

        $response = $this->actingAs($admin, 'sanctum')
            ->putJson("/api/admin/siswa/{$siswa->id}", [
                'nis' => '2413025001',
                'nama' => 'Ahmad Rizal S.Pd',
                'password' => 'password-baru-123',
            ]);

        $response->assertOk()
            ->assertJsonPath('data.nama', 'Ahmad Rizal S.Pd');
    }

    public function test_admin_dapat_menghapus_siswa(): void
    {
        $admin = $this->buatAdmin();
        $siswa = $this->buatSiswa('2413025001', 'Ahmad Rizal');

        $response = $this->actingAs($admin, 'sanctum')
            ->deleteJson("/api/admin/siswa/{$siswa->id}");

        $response->assertOk();
        $this->assertDatabaseMissing('pengguna', ['id' => $siswa->id]);
    }

    public function test_admin_tidak_dapat_menghapus_admin_lain(): void
    {
        $admin = $this->buatAdmin();
        $adminLain = $this->buatAdmin();

        $response = $this->actingAs($admin, 'sanctum')
            ->deleteJson("/api/admin/siswa/{$adminLain->id}");

        $response->assertForbidden();
        $this->assertDatabaseHas('pengguna', ['id' => $adminLain->id]);
    }

    public function test_siswa_tidak_dapat_mengakses_crud_siswa(): void
    {
        $siswa = $this->buatSiswa('2413025001', 'Ahmad Rizal');

        $response = $this->actingAs($siswa, 'sanctum')
            ->getJson('/api/admin/siswa');

        $response->assertForbidden();
    }

    private function buatAdmin(): Pengguna
    {
        return Pengguna::create([
            'nis' => 'ADMIN-'.uniqid(),
            'nama' => 'Admin SI-PKL',
            'password' => 'password',
            'peran' => 'admin',
        ]);
    }

    private function buatSiswa(string $nis, string $nama): Pengguna
    {
        $jurusan = Jurusan::create(['nama' => 'Rekayasa Perangkat Lunak '.uniqid()]);

        return Pengguna::create([
            'nis' => $nis,
            'nama' => $nama,
            'password' => 'password',
            'jurusan_id' => $jurusan->id,
            'peran' => 'siswa',
        ]);
    }
}
