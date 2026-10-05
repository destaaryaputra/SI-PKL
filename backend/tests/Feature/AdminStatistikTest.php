<?php

namespace Tests\Feature;

use App\Models\Industri;
use App\Models\Jurusan;
use App\Models\PengajuanPkl;
use App\Models\Pengguna;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminStatistikTest extends TestCase
{
    use RefreshDatabase;

    public function test_siswa_tidak_dapat_mengakses_statistik(): void
    {
        $siswa = $this->buatSiswa();

        $response = $this->actingAs($siswa, 'sanctum')
            ->getJson('/api/admin/statistik');

        $response->assertForbidden();
    }

    public function test_statistik_admin_berisi_ringkasan_dan_data_grafik(): void
    {
        [$siswa, $admin, $industri] = $this->buatData();
        $jurusanRpl = Jurusan::where('nama', 'Rekayasa Perangkat Lunak')->firstOrFail();

        PengajuanPkl::create([
            'pengguna_id' => $siswa->id,
            'industri_id' => $industri->id,
            'status' => 'disetujui',
        ]);
        PengajuanPkl::create([
            'pengguna_id' => $siswa->id,
            'industri_id' => $industri->id,
            'status' => 'menunggu',
        ]);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/admin/statistik');

        $response->assertOk()
            ->assertJsonPath('data.total_siswa', 1)
            ->assertJsonPath('data.total_industri', 1)
            ->assertJsonPath('data.pengajuan_menunggu', 1)
            ->assertJsonPath('data.pengajuan_disetujui', 1)
            ->assertJsonPath('data.pengajuan_ditolak', 0)
            ->assertJsonPath('data.pengajuan_per_bulan.5.label', now()->translatedFormat('M'))
            ->assertJsonPath('data.pengajuan_per_bulan.5.menunggu', 1)
            ->assertJsonPath('data.pengajuan_per_bulan.5.disetujui', 1)
            ->assertJsonPath('data.top_industri.0.nama', 'PT Maju Sejahtera')
            ->assertJsonPath('data.top_industri.0.jumlah', 2)
            ->assertJsonPath('data.siswa_per_jurusan.0.nama', $jurusanRpl->nama)
            ->assertJsonPath('data.siswa_per_jurusan.0.jumlah', 1)
            ->assertJsonPath('data.kuota_industri.0.nama', 'PT Maju Sejahtera')
            ->assertJsonPath('data.kuota_industri.0.kuota', 5)
            ->assertJsonPath('data.kuota_industri.0.terpakai', 1)
            ->assertJsonPath('data.kuota_industri.0.menunggu', 1);
    }

    public function test_statistik_kosong_tetap_aman(): void
    {
        $admin = Pengguna::create([
            'nis' => 'ADMIN001',
            'nama' => 'Admin SI-PKL',
            'password' => 'password',
            'peran' => 'admin',
        ]);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/admin/statistik');

        $response->assertOk()
            ->assertJsonPath('data.total_siswa', 0)
            ->assertJsonPath('data.top_industri', [])
            ->assertJsonPath('data.siswa_per_jurusan', [])
            ->assertJsonPath('data.kuota_industri', []);
    }

    private function buatSiswa(): Pengguna
    {
        $jurusan = Jurusan::create(['nama' => 'Rekayasa Perangkat Lunak']);

        return Pengguna::create([
            'nis' => '2413025058',
            'nama' => 'Desta Arya Putra',
            'password' => 'password',
            'jurusan_id' => $jurusan->id,
            'peran' => 'siswa',
        ]);
    }

    private function buatData(): array
    {
        $siswa = $this->buatSiswa();
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

        return [$siswa, $admin, $industri];
    }
}
