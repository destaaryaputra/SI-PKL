<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class TempatSekitarController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $data = $request->validate([
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'radius' => ['nullable', 'integer', 'min:100', 'max:5000'],
            'cari' => ['nullable', 'string', 'max:80'],
        ]);

        $latitude = (float) $data['latitude'];
        $longitude = (float) $data['longitude'];
        $radius = (int) ($data['radius'] ?? 3000);
        $cari = trim((string) ($data['cari'] ?? ''));
        $safeCari = str_replace(['"', '\\'], '', $cari);
        $nameFilter = $cari === '' ? '' : sprintf('["name"~"%s",i]', $safeCari);

        $query = sprintf(
            '[out:json][timeout:15];(nwr["shop"]%s(around:%d,%F,%F);nwr["office"]%s(around:%d,%F,%F);nwr["craft"]%s(around:%d,%F,%F););out center tags;',
            $nameFilter,
            $radius,
            $latitude,
            $longitude,
            $nameFilter,
            $radius,
            $latitude,
            $longitude,
            $nameFilter,
            $radius,
            $latitude,
            $longitude,
        );

        $response = collect([
            'https://overpass-api.de/api/interpreter',
            'https://overpass.kumi.systems/api/interpreter',
        ])->map(function (string $endpoint) use ($query) {
            try {
                return Http::withHeaders([
                    'User-Agent' => 'SI-PKL/1.0',
                    'Accept' => 'application/json',
                ])->asForm()->timeout(30)->post($endpoint, ['data' => $query]);
            } catch (\Throwable) {
                return null;
            }
        })
            ->filter()
            ->first(fn ($response) => $response->successful());

        if ($response === null) {
            return response()->json([
                'pesan' => 'Pencarian tempat sekitar sedang tidak tersedia.',
            ], 502);
        }

        $places = collect($response->json('elements', []))
            ->map(function (array $element): array {
                $tags = $element['tags'] ?? [];
                $latitude = $element['lat'] ?? data_get($element, 'center.lat');
                $longitude = $element['lon'] ?? data_get($element, 'center.lon');

                return [
                    'id' => (string) ($element['id'] ?? ''),
                    'nama' => $tags['name'] ?? 'Tempat tanpa nama',
                    'kategori' => $tags['shop'] ?? $tags['office'] ?? $tags['craft'] ?? 'usaha',
                    'alamat' => $this->alamat($tags),
                    'latitude' => $latitude,
                    'longitude' => $longitude,
                ];
            })
            ->filter(fn (array $place): bool => $place['latitude'] !== null && $place['longitude'] !== null)
            ->unique('id')
            ->values();

        return response()->json(['data' => $places]);
    }

    private function alamat(array $tags): string
    {
        return collect([
            $tags['addr:street'] ?? null,
            $tags['addr:housenumber'] ?? null,
            $tags['addr:city'] ?? null,
        ])->filter()->implode(', ');
    }
}
