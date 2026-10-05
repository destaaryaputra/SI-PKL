<?php

namespace Tests\Feature;

use Tests\TestCase;

class LogoTest extends TestCase
{
    public function test_logo_dapat_diambil_tanpa_token(): void
    {
        $path = public_path('logo/unit-test.png');
        file_put_contents($path, 'fake-png-bytes');

        try {
            $this->get('/api/logo/unit-test.png')
                ->assertOk()
                ->assertHeader('Access-Control-Allow-Origin', '*');
        } finally {
            @unlink($path);
        }
    }

    public function test_logo_yang_tidak_ada_dikembalikan_404(): void
    {
        $this->get('/api/logo/tidak-ada.png')->assertNotFound();
    }

    public function test_path_traversal_ditolak(): void
    {
        $this->get('/api/logo/..')->assertNotFound();
    }
}
