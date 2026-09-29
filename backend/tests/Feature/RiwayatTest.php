<?php

namespace Tests\Feature;

use App\Models\Industri;
use App\Models\Jurusan;
use App\Models\PengajuanPkl;
use App\Models\Pengguna;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RiwayatTest extends TestCase
{
    use RefreshDatabase;

    public function test_riwayat_per_industri_mengelompokkan_siswa_per_tahun(): void
    {
        [$industri, $tahunLalu] = $this->siapkanData();

        $response = $this->actingAs($this->buatSiswa(), 'sanctum')
            ->getJson("/api/industri/{$industri->id}/riwayat");

        $response->assertOk()
            ->assertJsonCount(2, 'data');

        // Tahun terbaru dulu.
        $this->assertSame((int) date('Y'), $response->json('data.0.tahun'));
        $this->assertSame(2, $response->json('data.0.jumlah'));
        $this->assertSame($tahunLalu, $response->json('data.1.tahun'));
        $this->assertSame(1, $response->json('data.1.jumlah'));
        $this->assertStringContainsString('Budi', $response->json('data.1.siswa.0.nama'));
    }

    public function test_riwayat_per_industri_bisa_difilter_per_tahun(): void
    {
        [$industri, $tahunLalu] = $this->siapkanData();

        $response = $this->actingAs($this->buatSiswa(), 'sanctum')
            ->getJson("/api/industri/{$industri->id}/riwayat?tahun={$tahunLalu}");

        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.tahun', $tahunLalu)
            ->assertJsonPath('data.0.jumlah', 1);
    }

    public function test_riwayat_hanya_memuat_pengajuan_disetujui(): void
    {
        [$industri] = $this->siapkanData();
        // Pengajuan tambahan: menunggu + ditolak, tidak boleh muncul.
        $lain = $this->buatSiswa('S-'.uniqid());
        PengajuanPkl::create([
            'pengguna_id' => $lain->id,
            'industri_id' => $industri->id,
            'status' => 'menunggu',
        ]);
        PengajuanPkl::create([
            'pengguna_id' => $lain->id,
            'industri_id' => $industri->id,
            'status' => 'ditolak',
        ]);

        $response = $this->actingAs($this->buatSiswa(), 'sanctum')
            ->getJson("/api/industri/{$industri->id}/riwayat");

        $response->assertOk();
        $total = collect($response->json('data'))->sum('jumlah');
        $this->assertSame(3, $total);
    }

    public function test_riwayat_siswa_mengelompokkan_pengajuan_per_tahun(): void
    {
        $siswa = $this->buatSiswa();
        $industri = $this->buatIndustri();

        PengajuanPkl::create([
            'pengguna_id' => $siswa->id,
            'industri_id' => $industri->id,
            'status' => 'menunggu',
        ]);

        $response = $this->actingAs($siswa, 'sanctum')
            ->getJson('/api/riwayat');

        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.tahun', (int) date('Y'))
            ->assertJsonPath('data.0.pengajuan.0.status', 'menunggu')
            ->assertJsonPath('data.0.pengajuan.0.industri.nama', 'PT Maju');
    }

    private function siapkanData(): array
    {
        $tahunLalu = (int) date('Y') - 1;
        $industri = $this->buatIndustri();

        // 2 siswa disetujui tahun ini.
        PengajuanPkl::create([
            'pengguna_id' => $this->buatSiswa('S-A-'.uniqid())->id,
            'industri_id' => $industri->id,
            'status' => 'disetujui',
            'tahun' => (int) date('Y'),
        ]);
        PengajuanPkl::create([
            'pengguna_id' => $this->buatSiswa('S-B-'.uniqid())->id,
            'industri_id' => $industri->id,
            'status' => 'disetujui',
            'tahun' => (int) date('Y'),
        ]);
        // 1 siswa disetujui tahun lalu.
        PengajuanPkl::create([
            'pengguna_id' => $this->buatSiswa('S-C-'.uniqid(), 'Budi Santoso')->id,
            'industri_id' => $industri->id,
            'status' => 'disetujui',
            'tahun' => $tahunLalu,
        ]);

        return [$industri, $tahunLalu];
    }

    private function buatSiswa(?string $nis = null, string $nama = 'Siswa Uji'): Pengguna
    {
        $jurusan = Jurusan::create(['nama' => 'RPL '.uniqid()]);

        return Pengguna::create([
            'nis' => $nis ?? 'S-'.uniqid(),
            'nama' => $nama,
            'password' => 'password',
            'jurusan_id' => $jurusan->id,
            'peran' => 'siswa',
        ]);
    }

    private function buatIndustri(): Industri
    {
        return Industri::create([
            'nama' => 'PT Maju',
            'alamat' => 'Bandar Lampung',
            'latitude' => -5.3971,
            'longitude' => 105.2668,
            'kuota' => 10,
        ]);
    }
}
