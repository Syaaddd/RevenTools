# RAVEN v5.1 — Modular Engine

## Struktur File

```
engine/
├── __init__.py       # Package initialization
├── __main__.py       # Entry point: python -m engine
├── core.py           # ~350 baris — globals, utils, event_log, flag scanner, deobfuscation
├── stego.py          # ~450 baris — steganografi (zsteg, steghide, LSB, bitplane, exif)
├── forensics.py      # ~600 baris — disk, memory, registry, log, autorun, zip crack
├── crypto.py         # ~630 baris — RSA attacks, XOR, Vigenere, classic ciphers, encoding chain
├── reversing.py      # ~350 baris — strings, objdump, readelf, packer detection, Ghidra
├── pcap.py           # ~250 baris — PCAP analysis (tshark, DNS tunneling, streams)
└── report.py         # ~225 baris — WriteupBuilder (terminal/Markdown/JSON)
```

## Penggunaan

### Sebagai Module Python
```bash
# Jalankan dari folder parent
python -m engine [FILE] [OPTIONS]

# Import di script Python
from engine import core, stego, forensics, crypto, reversing, pcap, report
```

### Dari raven.sh
Script bash `raven.sh` akan:
1. Setup virtual environment di `~/.raven/venv`
2. Copy engine files ke `~/.raven/engine/`
3. Dispatch ke Python module sesuai mode yang dipilih

## Code Style

Semua file mengikuti aturan:
- Docstring: Maksimal 1 baris, bahasa Indonesia informal
- Nama variabel: Singkat dan jelas (`fp`, `out`, `n`)
- Inline logic untuk kondisi sederhana (3-5 baris)
- Komentar hanya untuk logika non-obvious
- Blank line untuk grouping logika

## Event Logging

Setiap module menggunakan `core.log_event()` dan `core.log_tool()` untuk:
- Tracking analisis step-by-step
- Generate writeup otomatis
- Debugging dan audit trail

## Writeup Generation

Module `report.py` menyediakan 3 format output:
1. **Terminal**: Enhanced report dengan timeline dan writeup snippet
2. **Markdown**: File `*_writeup.md` untuk dokumentasi
3. **JSON**: File `*_report.json` untuk automation pipeline

## Migration dari v5.0

v5.0 → v5.1:
- `write_python_engine()` (6360 baris heredoc) → 9 file modular (~2850 baris total)
- Semua fungsi tetap sama, hanya struktur yang berubah
- Backward compatible: semua flag CLI tetap berfungsi
- Penambahan: event logging dan writeup generator
