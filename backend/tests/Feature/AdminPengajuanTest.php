<?php

namespace Tests\Feature;

use App\Models\Industri;
use App\Models\Jurusan;
use App\Models\PengajuanPkl;
use App\Models\Pengguna;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminPengajuanTest extends TestCase
{
    use RefreshDatabase;

    public function test_siswa_tidak_dapat_mengakses_pengajuan_admin(): void
    {
        [$siswa, $admin, $pengajuan] = $this->buatPengajuan();

        $response = $this->actingAs($siswa, 'sanctum')
            ->getJson('/api/admin/pengajuan');

        $response->assertForbidden();
    }

    public function test_admin_dapat_menyetujui_pengajuan(): void
    {
        [$siswa, $admin, $pengajuan] = $this->buatPengajuan();

        $response = $this->actingAs($admin, 'sanctum')
            ->patchJson('/api/admin/pengajuan/'.$pengajuan->id.'/setujui');

        $response->assertOk()
            ->assertJsonPath('data.status', 'disetujui');
        $this->assertDatabaseHas('pengajuan_pkl', [
            'id' => $pengajuan->id,
            'status' => 'disetujui',
            'diperiksa_oleh' => $admin->id,
        ]);
    }

    public function test_admin_dapat_menolak_pengajuan(): void
    {
        [$siswa, $admin, $pengajuan] = $this->buatPengajuan();

        $response = $this->actingAs($admin, 'sanctum')
            ->patchJson('/api/admin/pengajuan/'.$pengajuan->id.'/tolak', [
                'catatan' => 'Kuota jurusan sudah penuh.',
            ]);

        $response->assertOk()
            ->assertJsonPath('data.status', 'ditolak')
            ->assertJsonPath('data.catatan', 'Kuota jurusan sudah penuh.');
    }

    private function buatPengajuan(): array
    {
        $jurusan = Jurusan::create(['nama' => 'Rekayasa Perangkat Lunak']);
        $siswa = Pengguna::create([
            'nis' => '2413025058',
            'nama' => 'Desta Arya Putra',
            'password' => 'password',
            'jurusan_id' => $jurusan->id,
            'peran' => 'siswa',
        ]);
        $admin = Pengguna::create([
            'nis' => 'ADMIN001',
            'nama' => 'Admin SI-PKL',
            'password' => 'password',
            'peran' => 'admin',
        ]);
        $industri = Industri::create([
            'nama' => 'PT Maju Sejahtera',
            'alamat' => 'Bandar Lampung',
            'latitude' => -5.3971,
            'longitude' => 105.2668,
            'kuota' => 5,
        ]);
        $industri->jurusan()->attach($jurusan);
        $pengajuan = PengajuanPkl::create([
            'pengguna_id' => $siswa->id,
            'industri_id' => $industri->id,
            'status' => 'menunggu',
        ]);

        return [$siswa, $admin, $pengajuan];
    }
}
