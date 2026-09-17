<?php

namespace Tests\Feature;

use App\Models\Industri;
use App\Models\Jurusan;
use App\Models\PengajuanPkl;
use App\Models\Pengguna;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PengajuanPklTest extends TestCase
{
    use RefreshDatabase;

    public function test_siswa_dapat_mengajukan_pkl_saat_kuota_tersedia(): void
    {
        [$siswa, $industri] = $this->buatDataPengajuan(2);

        $response = $this->actingAs($siswa, 'sanctum')->postJson('/api/pengajuan', [
            'industri_id' => $industri->id,
            'catatan' => 'Saya berminat mengikuti PKL.',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.status', 'menunggu');
        $this->assertDatabaseHas('pengajuan_pkl', [
            'pengguna_id' => $siswa->id,
            'industri_id' => $industri->id,
            'status' => 'menunggu',
        ]);
    }

    public function test_sistem_menolak_pengajuan_saat_kuota_penuh(): void
    {
        [$siswa, $industri] = $this->buatDataPengajuan(1);
        PengajuanPkl::create([
            'pengguna_id' => $siswa->id,
            'industri_id' => $industri->id,
            'status' => 'menunggu',
        ]);

        $siswaKedua = Pengguna::create([
            'nis' => '2413025059',
            'nama' => 'Siswa Kedua',
            'password' => 'password',
            'jurusan_id' => $siswa->jurusan_id,
            'peran' => 'siswa',
        ]);

        $response = $this->actingAs($siswaKedua, 'sanctum')->postJson('/api/pengajuan', [
            'industri_id' => $industri->id,
        ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors('industri_id');
    }

    public function test_siswa_tidak_dapat_memiliki_pengajuan_aktif_ganda(): void
    {
        [$siswa, $industri] = $this->buatDataPengajuan(2);
        PengajuanPkl::create([
            'pengguna_id' => $siswa->id,
            'industri_id' => $industri->id,
            'status' => 'menunggu',
        ]);

        $response = $this->actingAs($siswa, 'sanctum')->postJson('/api/pengajuan', [
            'industri_id' => $industri->id,
        ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors('pengajuan');
    }

    private function buatDataPengajuan(int $kuota): array
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
            'nama' => 'PT Maju Sejahtera',
            'alamat' => 'Bandar Lampung',
            'latitude' => -5.3971,
            'longitude' => 105.2668,
            'kuota' => $kuota,
        ]);
        $industri->jurusan()->attach($jurusan);

        return [$siswa, $industri];
    }
}
