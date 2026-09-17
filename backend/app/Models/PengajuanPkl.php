<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PengajuanPkl extends Model
{
    use HasFactory;

    protected $table = 'pengajuan_pkl';

    protected $fillable = [
        'pengguna_id',
        'industri_id',
        'status',
        'catatan',
        'diperiksa_oleh',
        'diperiksa_pada',
    ];

    protected function casts(): array
    {
        return [
            'diperiksa_pada' => 'datetime',
        ];
    }

    public function pengguna()
    {
        return $this->belongsTo(Pengguna::class);
    }

    public function industri()
    {
        return $this->belongsTo(Industri::class);
    }

    public function pemeriksa()
    {
        return $this->belongsTo(Pengguna::class, 'diperiksa_oleh');
    }
}
