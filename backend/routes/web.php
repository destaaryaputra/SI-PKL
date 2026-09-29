<?php

use Illuminate\Support\Facades\Route;

Route::get('/', fn () => response()->json(['aplikasi' => 'SI-PKL API', 'docs' => '/api']));
