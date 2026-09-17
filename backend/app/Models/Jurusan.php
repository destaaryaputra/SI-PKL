<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Jurusan extends Model
{
    use HasFactory;

    protected $table = 'jurusan';

    protected $fillable = ['nama'];

    public function pengguna()
    {
        return $this->hasMany(Pengguna::class);
    }

    public function industri()
    {
        return $this->belongsToMany(Industri::class, 'industri_jurusan');
    }
}
