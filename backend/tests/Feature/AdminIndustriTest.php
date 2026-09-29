<?php

namespace Tests\Feature;

use App\Models\Industri;
use App\Models\Jurusan;
use App\Models\Pengguna;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminIndustriTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_dapat_menambah_industri(): void
    {
        $admin = $this->buatAdmin();
        $rpl = Jurusan::create(['nama' => 'RPL']);
        $tkj = Jurusan::create(['nama' => 'TKJ']);

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/admin/industri', [
                'nama' => 'PT Sumber Rejeki',
                'alamat' => 'Jl. Sudirman No. 1, Bandar Lampung',
                'latitude' => -5.42,
                'longitude' => 105.26,
                'kuota' => 7,
                'jurusan_ids' => [$rpl->id, $tkj->id],
            ]);

        $response->assertCreated()
            ->assertJsonPath('data.nama', 'PT Sumber Rejeki')
            ->assertJsonCount(2, 'data.jurusan_ids');
        $this->assertDatabaseHas('industri', ['nama' => 'PT Sumber Rejeki', 'kuota' => 7]);
        $this->assertDatabaseCount('industri_jurusan', 2);
    }

    public function test_kuota_tidak_boleh_lebih_kecil_dari_terpakai(): void
    {
        $admin = $this->buatAdmin();
        $industri = $this->buatIndustriDenganPengajuan($admin, 2);

        $response = $this->actingAs($admin, 'sanctum')
            ->putJson("/api/admin/industri/{$industri->id}", [
                'nama' => $industri->nama,
                'alamat' => $industri->alamat,
                'latitude' => $industri->latitude,
                'longitude' => $industri->longitude,
                'kuota' => 1,
                'jurusan_ids' => $industri->jurusan->pluck('id')->all(),
            ]);

        $response->assertUnprocessable();
    }

    public function test_industri_dengan_pengajuan_tidak_bisa_dihapus(): void
    {
        $admin = $this->buatAdmin();
        $industri = $this->buatIndustriDenganPengajuan($admin, 1);

        $response = $this->actingAs($admin, 'sanctum')
            ->deleteJson("/api/admin/industri/{$industri->id}");

        $response->assertUnprocessable();
        $this->assertDatabaseHas('industri', ['id' => $industri->id]);
    }

    public function test_siswa_tidak_dapat_menambah_industri(): void
    {
        $rpl = Jurusan::create(['nama' => 'RPL '.uniqid()]);
        $siswa = Pengguna::create([
            'nis' => '2413025001',
            'nama' => 'Ahmad',
            'password' => 'password',
            'jurusan_id' => $rpl->id,
            'peran' => 'siswa',
        ]);

        $response = $this->actingAs($siswa, 'sanctum')
            ->postJson('/api/admin/industri', [
                'nama' => 'PT Baru',
                'alamat' => 'Alamat',
                'latitude' => -5.4,
                'longitude' => 105.2,
                'kuota' => 5,
                'jurusan_ids' => [$rpl->id],
            ]);

        $response->assertForbidden();
    }

    private function buatAdmin()
    {
        return \App\Models\Pengguna::create([
            'nis' => 'ADMIN-'.uniqid(),
            'nama' => 'Admin SI-PKL',
            'password' => 'password',
            'peran' => 'admin',
        ]);
    }

    private function buatIndustriDenganPengajuan($admin, int $jumlahPengajuan)
    {
        $rpl = Jurusan::create(['nama' => 'RPL '.uniqid()]);
        $siswa = \App\Models\Pengguna::create([
            'nis' => 'S-'.uniqid(),
            'nama' => 'Siswa Uji',
            'password' => 'password',
            'jurusan_id' => $rpl->id,
            'peran' => 'siswa',
        ]);
        $industri = Industri::create([
            'nama' => 'PT Maju',
            'alamat' => 'Bandar Lampung',
            'latitude' => -5.3971,
            'longitude' => 105.2668,
            'kuota' => 5,
        ]);
        $industri->jurusan()->attach($rpl);

        for ($i = 0; $i < $jumlahPengajuan; $i++) {
            \App\Models\PengajuanPkl::create([
                'pengguna_id' => $siswa->id,
                'industri_id' => $industri->id,
                'status' => 'disetujui',
            ]);
        }

        return $industri;
    }
}
