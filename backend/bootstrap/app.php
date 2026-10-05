<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'peran' => \App\Http\Middleware\PeranMiddleware::class,
        ]);
        // API tanpa sesi tidak boleh redirect ke route "login" (tidak ada):
        // kembalikan null agar exception handler mengirim 401 JSON.
        $middleware->redirectGuestsTo(function (\Illuminate\Http\Request $request) {
            if ($request->is('api/*')) {
                return null;
            }
            return null;
        });
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // API murni JSON: unauthenticated dikembalikan sebagai JSON 401
        // (dengan Accept: application/json), bukan redirect HTML ke route
        // bernama "login" yang memang tidak terdaftar.
        $exceptions->render(function (\Illuminate\Auth\AuthenticationException $e, \Illuminate\Http\Request $request) {
            return response()->json(
                ['pesan' => 'Sesi tidak valid, silakan login ulang.'],
                401,
            );
        });
    })->create();
