<?php

namespace App\Http\Controllers;

use Symfony\Component\HttpFoundation\BinaryFileResponse;

class LogoController extends Controller
{
    /**
     * Sajikan file logo dari public/logo/ — dengan header CORS.
     *
     * File statis di root server disajikan web server tanpa lewat Laravel,
     * sehingga tanpa header Access-Control-Allow-Origin. Akibatnya
     * Image.network di Flutter web (Chrome/CanvasKit) selalu gagal dan
     * jatuh ke ikon fallback. Lewat route /api/logo/{file} ini respons
     * melewati middleware CORS Laravel, jadi logo tampil di web maupun mobile.
     */
    public function show(string $file): BinaryFileResponse
    {
        $folder = realpath(public_path('logo'));
        $path = $folder === false
            ? false
            : realpath($folder.DIRECTORY_SEPARATOR.$file);

        // Tolak path traversal (mis. `..` atau `../../.env`) dan file yang
        // berada di luar folder logo.
        $aman = $folder !== false
            && $path !== false
            && is_file($path)
            && str_starts_with($path, $folder.DIRECTORY_SEPARATOR);

        abort_unless($aman, 404);

        return response()->file($path, [
            'Access-Control-Allow-Origin' => '*',
            'Cross-Origin-Resource-Policy' => 'cross-origin',
        ]);
    }
}
