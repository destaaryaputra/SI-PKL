<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Industri extends Model
{
    use HasFactory;

    protected $table = 'industri';

    protected $fillable = [
        'nama',
        'alamat',
        'logo_url',
        'latitude',
        'longitude',
        'kuota',
    ];

    protected function casts(): array
    {
        return [
            'latitude' => 'float',
            'longitude' => 'float',
            'kuota' => 'integer',
        ];
    }

    public function jurusan()
    {
        return $this->belongsToMany(Jurusan::class, 'industri_jurusan');
    }

    public function pengajuanPkl()
    {
        return $this->hasMany(PengajuanPkl::class);
    }
}
