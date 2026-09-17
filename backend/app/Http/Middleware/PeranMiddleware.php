<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class PeranMiddleware
{
    public function handle(Request $request, Closure $next, string $peran): Response
    {
        if ($request->user()?->peran !== $peran) {
            return response()->json([
                'pesan' => 'Kamu tidak memiliki akses ke fitur ini.',
            ], 403);
        }

        return $next($request);
    }
}
