# ForesTools 🕵️‍♂️💻

> **Smart Forensic Toolkit for CTF Challenges** 🔐  
> Alat otomatis untuk analisis file CTF — steganografi, header repair, ekstraksi tersembunyi, network forensics, disk forensics, dan deteksi flag 🚩

**Versi: v3.0** — 🚀 **GLOBAL INSTALL + AUTO-SOLVE CTF** - Jalankan dari mana saja, 8 fitur baru berbasis writeup nyata

---

## 📦 Instalasi

### 1. Clone / Download
```bash
git clone https://github.com/Syaaddd/SForensicsTools.git
cd SForensicsTools
chmod +x forestools.sh
```

### 2. Install Global ⚡ (BARU v3.0 — Jalankan dari mana saja!)
```bash
./forestools.sh --install-global
```
Setelah ini, cukup ketik `forestools` dari direktori mana pun:
```bash
forestools image.png --auto
forestools access.log --log
forestools --folder ./challenge/
```

### 3. Install Semua Tools Sistem (Otomatis)
```bash
./forestools.sh --install
```
Menginstall: steghide, stegseek, zsteg, foremost, exiftool, tshark, rockyou.txt, fcrackzip, dll.

### 4. Install Manual (Opsional)

#### Dependencies Dasar ⚙️
```bash
sudo apt update && sudo apt install -y \
    binwalk libimage-exiftool-perl tesseract-ocr unrar p7zip-full xz-utils \
    python3-pip steghide foremost pngcheck graphicsmagick tshark tcpdump \
    wireshark-common python3-venv wordlists fcrackzip
```

#### Install stegseek 🔍
```bash
wget https://github.com/RickdeJager/stegseek/releases/download/v0.6/stegseek_0.6-1.deb
sudo apt install ./stegseek_0.6-1.deb
sudo gunzip /usr/share/wordlists/rockyou.txt.gz
```

#### Install zsteg 💎
```bash
sudo apt install -y ruby ruby-dev
sudo gem install zsteg
```

#### Install Volatility 3 🧠
```bash
pip install volatility3
# atau
git clone https://github.com/volatilityfoundation/volatility3.git
cd volatility3 && pip install -e .
```

#### Python Dependencies 🐍
Diinstall **otomatis** saat pertama kali dijalankan. Atau manual:
```bash
pip install colorama Pillow numpy
```

---

## 📁 Struktur

```
SForensicsTools/
└── forestools.sh          ← Satu file ini sudah cukup!

~/.forestools/             ← Data runtime (dibuat otomatis)
├── venv/                  ← Python venv
└── engine.py              ← Python engine (auto-generated)

/usr/local/bin/forestools  ← Binary global (setelah --install-global)
```

---

## ▶️ Penggunaan

```bash
# Setelah --install-global:
forestools [FILE(S)] [OPTIONS]

# Atau langsung dari folder download:
./forestools.sh [FILE(S)] [OPTIONS]
```

### 📤 Input
```bash
forestools challenge.png
forestools *.png
forestools secret.jpg data.zip firmware.bin
forestools /path/to/challenges/
forestools -f "picoCTF{" suspicious.png
```

### 🤖 Mode Analisis
```bash
forestools image.png --auto      # Auto-detect semua tools sesuai tipe file
forestools image.png --all       # Jalankan SEMUA analisis
forestools image.png --quick     # ULTRA-FAST: strings + zsteg + stegseek + early exit
```

### 🗝️ CTF Spesifik (v3.0)
```bash
forestools artifact.reg   --reg              # Windows Registry analysis
forestools access.log     --log              # Web server log analysis
forestools autorun.inf    --autorun          # Autorun/INF file analysis
forestools evidence.zip   --zipcrack         # Crack ZIP password otomatis
forestools chall.raw      --volatility       # Memory forensics (Volatility 3)
forestools secret.txt     --deobfuscate      # Reverse/ROT13/caesar/atbash/b64
forestools                --folder ./dir/    # Fake extension scanner
```

### 🔒 Steganografi
```bash
forestools image.png --lsb        # LSB analysis (zsteg)
forestools image.jpg --steghide   # Steghide extraction
forestools image.jpg --stegseek   # Stegseek + rockyou.txt
forestools image.jpg --outguess   # Outguess (JPEG)
forestools image.png --pngcheck   # Validasi PNG
forestools image.jpg --jpsteg     # JPEG steganalysis
forestools image.png --foremost   # File carving
forestools image.png --exif       # Deep EXIF analysis
forestools image.png --stegdetect # Deteksi metode stego
forestools image.png --lsbextract # Ekstrak raw LSB bytes
forestools image.png --remap      # Color remapping (8 variants)
forestools image.png --deep       # Semua 8 bit plane
forestools img1.png --compare img2.png
```

### 🔑 Brute Force
```bash
forestools image.png --bruteforce
forestools image.png --bruteforce --parallel 10
forestools image.png --bruteforce --wordlist dict.txt
forestools image.jpg --stegseek --wordlist rockyou.txt
```

### 🌐 Network & Disk
```bash
forestools capture.pcap --pcap
forestools disk.img --disk
forestools security.evtx --windows
```

---

## 📁 Output Folder

| Folder | Kegunaan |
|--------|----------|
| `*_bitplanes/` | Bit plane visual (0-7) |
| `*_channels/` | RGBA channels terpisah |
| `*_remap/` | Color palette variants |
| `*_stegseek/` | Stegseek result |
| `*_steghide/`, `*_outguess/` | Stego extraction |
| `*_foremost/` | File carving |
| `*_bruteforce/` | Steghide brute force |
| `*_decoded_*` | Hasil decode (b64/hex/bin) |
| `*_http_objects/`, `*_streams/` | PCAP results |
| `*_disk_analysis/` | Disk image results |
| `*_lsb_raw/` | Raw LSB bytes |
| `*_compare/` | Image diff |
| `*_exif/` | EXIF metadata |
| `*_registry/` | Registry decode results |
| `*_log_analysis/` | Log analysis results |
| `*_autorun/` | Autorun decode results |
| `*_zipcrack/` | ZIP extracted files |
| `*_volatility/` | Volatility plugin outputs |
| `_extracted_*/` | Binwalk extraction |
| `fixed_*`, `repaired_*` | Header yang diperbaiki |

---

## ⚡ Perbandingan Performa

| Fitur | v1.x | v2.0 | v3.0 |
|-------|------|------|------|
| **Global install** | ❌ | ❌ | ✅ `--install-global` |
| **Stegseek + rockyou** | ❌ | ✅ | ✅ |
| **ZIP password crack** | ❌ | ❌ | ✅ `--zipcrack` |
| **Registry analysis** | ❌ | ❌ | ✅ `--reg` |
| **Log analysis** | ❌ | ❌ | ✅ `--log` |
| **Volatility wrapper** | ❌ | ❌ | ✅ `--volatility` |
| **Deobfuscation engine** | ❌ | ❌ | ✅ `--deobfuscate` |
| **Fake ext detection** | ❌ | ❌ | ✅ `--folder` |
| **Quick Mode** | ❌ | ✅ | ✅ |
| **Parallel brute force** | ❌ | ✅ 5 thread | ✅ 8 thread |
| **Standalone .sh** | ❌ | ✅ | ✅ |
| **Auto venv** | ❌ | ✅ `.venv/` | ✅ `~/.forestools/` |

---

## 🛠️ Troubleshooting

| Masalah | Solusi |
|---------|--------|
| `Permission denied` | `chmod +x forestools.sh` |
| `Python not found` | `sudo apt install python3` |
| `stegseek not found` | `./forestools.sh --install` |
| `rockyou.txt not found` | `sudo apt install wordlists && sudo gunzip /usr/share/wordlists/rockyou.txt.gz` |
| `volatility not found` | `pip install volatility3` |
| `forestools: command not found` | `./forestools.sh --install-global` |
| Python deps error | `forestools --update-deps` |
| Venv error | `rm -rf ~/.forestools/venv` lalu jalankan ulang |

---

## 💡 Tips & Trik

- ⚡ Gunakan `--quick` untuk analisis super cepat saat kompetisi berlangsung
- 🎯 **Early exit** otomatis berhenti begitu flag ditemukan
- 🔍 `--stegseek` jauh lebih cepat dari `--bruteforce` untuk JPEG
- 🗂️ `--folder` untuk soal yang kasih banyak file — auto-detect fake extension
- 🧠 `--volatility` auto-dump file menarik dari RAM (flag, tiket, datadiri, dll)
- 🔤 `--deobfuscate` coba semua metode encode sekaligus — reverse, ROT13, caesar 1-25, atbash, b64, hex
- 📋 `--reg` decode semua nilai `hex:` di .reg — sering menyembunyikan flag di RunOnce
- 🌐 `--log` deteksi request 200-OK attacker — flag sering di URL path
- 🔎 Periksa `*_bitplanes/` jika flag tidak terdeteksi otomatis di gambar

---

## 📋 Changelog

### v3.0 — 2026
> **Tema: Global Install + Auto-Solve CTF berbasis 11 writeup nyata**

**🆕 Fitur Baru**
- `--install-global` — Install ke `/usr/local/bin/forestools`, jalankan dari direktori mana saja
- `--uninstall` — Hapus binary dan data dari sistem
- `~/.forestools/` — Venv & engine disimpan di home user (bukan folder script), sehingga script bisa dipindah/dipanggil dari mana saja
- `--reg` — Windows Registry parser: decode semua nilai `hex:` (REG_BINARY) ke UTF-16/UTF-8, scan key Run/RunOnce/UserInit, deobfuscate string values
- `--log` — Web server log analyzer: IP frequency (attacker detection), HTTP status distribution, attack pattern detection (SQLi/XSS/LFI/traversal/webshell), flag di URL 200-OK, timeline
- `--autorun` — Autorun/INF file analyzer: baca semua komentar, coba reverse / ROT13 / caesar brute (1-25) / atbash / base64 otomatis
- `--zipcrack` — ZIP password cracker 4 tahap: (1) tanpa password → (2) password kosong → (3) rockyou.txt parallel 8 thread → (4) fcrackzip
- `--folder DIR` — Fake extension scanner: baca magic bytes semua file, deteksi mismatch ekstensi, auto-rename & extract ZIP/PDF/image
- `--volatility` — Volatility 3 auto-pipeline: windows.info → pslist → pstree → cmdline → envars → netscan → filescan → dumpfiles → flag scan
- `--vol-plugin` — Plugin Volatility tambahan dari user
- `--deobfuscate` — Deobfuscation engine: reverse, ROT13, atbash, caesar brute (25 shift), base64, hex, reverse+base64
- Auto fake-extension detection di setiap file yang diproses (cek magic bytes vs ekstensi klaim)
- `REDLIMIT{...}` ditambahkan ke flag pattern matcher
- `scan_text_for_flags()` — helper terpusat yang dipakai semua fungsi untuk konsistensi

**🔧 Perbaikan**
- Argparse `files` dari `nargs="+"` ke `nargs="*"` agar `--folder` bisa jalan tanpa file argument
- Output folder baru: `*_registry/`, `*_log_analysis/`, `*_autorun/`, `*_zipcrack/`, `*_volatility/`
- Parallel ZIP brute-force dengan `ThreadPoolExecutor` (8 thread default)
- README diperbarui dengan tabel peta soal CTF → fitur

---

### v2.0 — 2026
> **Tema: Standalone .sh + Stegseek + Parallel Brute Force**

**🆕 Fitur Baru**
- **Standalone** — Python engine di-embed langsung dalam `.sh` via heredoc, tidak perlu `ForesTools.py` terpisah
- `--stegseek` — Stegseek brute-force dengan rockyou.txt (~14 juta password)
- `--install` — Auto-install semua tools sistem via apt/brew termasuk stegseek & rockyou
- `--update-deps` — Reinstall Python dependencies di venv
- Auto venv di `.venv/` — tidak perlu manual setup Python
- `--exif` — Deep EXIF metadata analysis via exiftool
- `--stegdetect` — Deteksi metode stego (LSB ratio, channel variance)
- `--lsbextract` — Ekstrak raw LSB bytes ke file binary
- `--compare FILE` — Pixel diff dua gambar
- Parallel brute-force steghide dengan `ThreadPoolExecutor`
- Rockyou.txt auto-detect di `/usr/share/wordlists/` dan `/opt/`
- Banner ASCII art ForesTools

**🔧 Perbaikan**
- `_tshark()` helper mengurangi duplikasi kode PCAP
- `_build_result()` untuk return flag/extraction summary per file
- Early exit otomatis saat flag ditemukan
- `--quick` mode: strings → zsteg → stegseek → steghide, berhenti di flag pertama

---

### v1.x — 2025
> **Tema: All-in-one Python forensic tool (AperiSolve style)**

**Fitur Awal**
- `sfores` / `fores` command sebagai entry point
- Analisis gambar: bit planes, RGB channels, LSB (zsteg), steghide, outguess, pngcheck, jpseek
- Header repair otomatis: PNG & JPEG magic bytes
- File carving: foremost, binwalk
- Auto-decode: base64, hex, binary
- PCAP analysis: HTTP objects, DNS, credentials, TCP streams, attack detection, timeline
- Disk image analysis: strings, file signature scan, compressed disk extract
- Windows Event Log parser: raw string extraction
- Brute force steghide dengan default wordlist
- Strings hunt: UTF-8 + UTF-16 scan untuk flag patterns
- Flag patterns: `picoCTF{...}`, `CTF{...}`, `flag{...}`, generic `PREFIX{...}`
- Entropy calculation & scattered flag detection

---

Dikembangkan oleh **Syaaddd** 👨‍💻 — untuk para pejuang CTF! 🏆🚩  
[GitHub Repository](https://github.com/Syaaddd/SForensicsTools) 💻✨
