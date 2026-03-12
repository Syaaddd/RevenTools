<div align="center">

# 🐦‍⬛ RAVEN CTF Toolkit

**Toolkit Otomasi CTF Multi-Kategori yang Cerdas**

[![Version](https://img.shields.io/badge/versi-v4.0-blue?style=for-the-badge&logo=github)](https://github.com/Syaaddd/raven-ctf)
[![License](https://img.shields.io/badge/lisensi-MIT-green?style=for-the-badge)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-orange?style=for-the-badge&logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Python](https://img.shields.io/badge/python-3.8%2B-yellow?style=for-the-badge&logo=python)](https://www.python.org/)
[![Platform](https://img.shields.io/badge/platform-Linux-lightgrey?style=for-the-badge&logo=linux)](https://www.linux.org/)
[![CTF](https://img.shields.io/badge/CTF-ready-red?style=for-the-badge&logo=hackthebox)](https://github.com/Syaaddd/raven-ctf)

*Alat otomatis untuk semua kategori CTF — forensics, steganografi, kriptografi, network, memory forensics, dan deteksi flag* 🚩

[📦 Instalasi](#-instalasi) · [▶️ Penggunaan](#%EF%B8%8F-penggunaan) · [📁 Output](#-output-folder) · [🆕 Changelog](#-changelog)

</div>

---

## 🔍 Tentang RAVEN

RAVEN adalah toolkit CTF berbasis Bash + Python yang dirancang untuk mempercepat proses analisis challenge. Mulai dari steganografi gambar, forensics memori, network PCAP, hingga deobfuscation — semua terintegrasi dalam **satu file `.sh`**.

**Kategori yang didukung:**

| Kategori | Tools |
|----------|-------|
| 🖼️ Steganografi | zsteg, steghide, stegseek, outguess, LSB |
| 🔬 Forensics | foremost, binwalk, exiftool, pngcheck |
| 🌐 Network | tshark, analisis PCAP, HTTP objects, DNS tunneling |
| 🧠 Memory | Volatility 3 pipeline, analisis memori lanjutan |
| 🔒 Kriptografi | Serangan RSA, Vigenere, XOR KPA, Caesar, Atbash, Encoding Chain |
| 💽 Disk | Disk image, recovery NTFS, scan partisi, Event Log, Registry |
| 🔎 Deobfuscate | ROT13, Caesar brute (1-25), Atbash, Base64, Hex, reverse |

---

## 📦 Instalasi

### 1. Clone / Download
```bash
git clone https://github.com/Syaaddd/raven-ctf.git
cd raven-ctf
chmod +x raven.sh
```

### 2. Install Global ⚡ (Jalankan dari mana saja)
```bash
./raven.sh --install-global
```
Setelah ini, cukup ketik `raven` dari direktori mana pun:
```bash
raven image.png --auto
raven access.log --log
raven --folder ./challenge/
```

### 3. Install Semua Tools Sistem (Otomatis)
```bash
./raven.sh --install
```
Menginstall: steghide, stegseek, zsteg, foremost, exiftool, tshark, rockyou.txt, fcrackzip, dan lainnya.

### 4. Install Manual (Opsional)

#### Dependensi Dasar ⚙️
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

#### Dependensi Python 🐍
Diinstall **otomatis** saat pertama kali dijalankan. Atau secara manual:
```bash
pip install colorama Pillow numpy requests
```

---

## 📁 Struktur

```
raven-ctf/
└── raven.sh            ← Satu file ini sudah cukup!

~/.raven/               ← Data runtime (dibuat otomatis)
├── venv/               ← Python venv
└── engine.py           ← Python engine (auto-generated)

/usr/local/bin/raven    ← Binary global (setelah --install-global)
```

---

## ▶️ Penggunaan

```bash
# Setelah --install-global:
raven [FILE(S)] [OPTIONS]

# Atau langsung dari folder download:
./raven.sh [FILE(S)] [OPTIONS]
```

### 📤 Input
```bash
raven challenge.png
raven *.png
raven secret.jpg data.zip firmware.bin
raven /path/to/challenges/
raven -f "picoCTF{" suspicious.png
```

### 🤖 Mode Analisis
```bash
raven image.png --auto      # Auto-detect semua tools sesuai tipe file
raven image.png --all       # Jalankan SEMUA analisis
raven image.png --quick     # ULTRA-FAST: strings + zsteg + stegseek + early exit
```

### 🆕 Fitur Baru v4.0

#### 🔒 Cryptography Engine
```bash
raven chall.txt --crypto                # Auto-attack semua: RSA, Vigenere, XOR, Classic, Chain
raven rsa_chall.txt --crypto --rsa      # Fokus serangan RSA (weak prime, Fermat, Common-Modulus, Bellcore)
raven cipher.txt --crypto --vigenere    # Vigenere + akrostik key finder
raven secret.txt --classic              # Atbash + Caesar brute (1-25)
raven enc.bin --xor-plain "CTF{"        # XOR KPA dengan known-plaintext prefix
raven enc.bin --xor-key "DARKSIDE"      # XOR decrypt manual dengan key
raven encoded.txt --encoding-chain      # Multi-stage decode (Base32→Binary→BitRev→B64)
```

#### 🧠 Analisis Memori Lanjutan
```bash
raven dump.raw --volatility             # Volatility 3 auto-pipeline standar
raven dump.raw --memory                 # Lanjutan: malfind + process dump + anomaly detection
```

#### 💽 Forensics Disk Lanjutan
```bash
raven disk.img --ntfs                   # Recovery file terhapus di NTFS (fls/icat/strings/carving)
raven disk.img --partition              # Analisis tabel partisi (MBR/GPT, scan hidden partition)
```

#### 🌐 Deteksi DNS Tunneling
```bash
raven capture.pcap --pcap              # Analisis PCAP standar
raven capture.pcap --dns-tunnel        # Deteksi DNS tunneling + decode Base32/64/hex
```

### 🗝️ CTF Spesifik (v3.0+)
```bash
raven artifact.reg   --reg              # Analisis Windows Registry
raven access.log     --log              # Analisis web server log
raven autorun.inf    --autorun          # Analisis file Autorun/INF
raven evidence.zip   --zipcrack         # Crack password ZIP otomatis
raven chall.raw      --volatility       # Memory forensics (Volatility 3)
raven secret.txt     --deobfuscate      # Reverse/ROT13/caesar/atbash/b64
raven               --folder ./dir/     # Scanner fake extension
```

### 🖼️ Steganografi
```bash
raven image.png --lsb                       # Analisis LSB (zsteg)
raven image.jpg --steghide                  # Ekstraksi Steghide
raven image.jpg --stegseek                  # Stegseek + rockyou.txt
raven image.jpg --outguess                  # Outguess (JPEG)
raven image.png --pngcheck                  # Validasi PNG
raven image.jpg --jpsteg                    # Steganalisis JPEG
raven image.png --foremost                  # File carving
raven image.png --exif                      # Analisis EXIF mendalam
raven image.png --deep                      # Semua 8 bit plane
raven img1.png --compare img2.png           # Perbandingan piksel
```

### 🔑 Brute Force
```bash
raven image.png --bruteforce
raven image.png --bruteforce --parallel 10
raven image.png --bruteforce --wordlist dict.txt
raven image.jpg --stegseek --wordlist rockyou.txt
```

### 🌐 Network & Disk
```bash
raven capture.pcap --pcap              # Analisis PCAP + deteksi serangan
raven capture.pcap --dns-tunnel        # Deteksi DNS tunneling
raven disk.img --disk                  # Analisis disk image
raven disk.img --ntfs                  # Recovery file terhapus NTFS
raven disk.img --partition             # Analisis tabel partisi (MBR/GPT)
raven security.evtx --windows          # Forensics Windows Event Log
```

### ⚙️ Environment Variables
```bash
export RAVEN_THREADS=5                 # Jumlah thread brute force (default: 5)
export RAVEN_WORDLIST="/path/to/list"  # Path wordlist kustom
```

---

## 📁 Output Folder

| Folder | Kegunaan |
|--------|----------|
| `*_bitplanes/` | Visual bit plane (0-7) |
| `*_channels/` | Channel RGBA terpisah |
| `*_remap/` | Variasi color palette |
| `*_stegseek/` | Hasil Stegseek |
| `*_steghide/`, `*_outguess/` | Hasil ekstraksi stego |
| `*_foremost/` | Hasil file carving |
| `*_bruteforce/` | Hasil brute force Steghide |
| `*_decoded_*` | Hasil decode (b64/hex/bin) |
| `*_http_objects/`, `*_streams/` | Hasil analisis PCAP |
| `*_disk_analysis/` | Hasil analisis disk image |
| `*_lsb_raw/` | Raw bytes LSB |
| `*_compare/` | Perbandingan gambar (diff) |
| `*_exif/` | Metadata EXIF |
| `*_registry/` | Hasil decode registry |
| `*_log_analysis/` | Hasil analisis log |
| `*_autorun/` | Hasil decode autorun |
| `*_zipcrack/` | File hasil ekstraksi ZIP |
| `*_volatility/` | Output plugin Volatility |
| `*_ntfs/` | Hasil recovery file NTFS |
| `*_partitions/` | Hasil scan partisi |
| `*_dns_tunnel/` | Hasil decode DNS tunneling |
| `*_crypto/` | Hasil serangan kriptografi |
| `_extracted_*/` | Hasil ekstraksi binwalk |
| `fixed_*`, `repaired_*` | Header yang diperbaiki |

---

## ⚡ Perbandingan Versi

| Fitur | v1.x | v2.0 | v3.0 | v4.0 |
|-------|------|------|------|------|
| **Install global** | ❌ | ❌ | ✅ | ✅ |
| **Crypto engine (RSA/Vigenere/XOR)** | ❌ | ❌ | ❌ | ✅ `--crypto` |
| **Analisis memori lanjutan** | ❌ | ❌ | ❌ | ✅ `--memory` |
| **Recovery file NTFS** | ❌ | ❌ | ❌ | ✅ `--ntfs` |
| **Scan tabel partisi** | ❌ | ❌ | ❌ | ✅ `--partition` |
| **Deteksi DNS tunneling** | ❌ | ❌ | ❌ | ✅ `--dns-tunnel` |
| **Stegseek + rockyou** | ❌ | ✅ | ✅ | ✅ |
| **Crack password ZIP** | ❌ | ❌ | ✅ | ✅ |
| **Analisis Registry** | ❌ | ❌ | ✅ | ✅ |
| **Analisis log** | ❌ | ❌ | ✅ | ✅ |
| **Wrapper Volatility** | ❌ | ❌ | ✅ | ✅ |
| **Mesin deobfuscation** | ❌ | ❌ | ✅ | ✅ |
| **Deteksi fake extension** | ❌ | ❌ | ✅ | ✅ |
| **Mode Quick** | ❌ | ✅ | ✅ | ✅ |
| **Brute force paralel** | ❌ | ✅ 5t | ✅ 5t | ✅ 5t |
| **Standalone .sh** | ❌ | ✅ | ✅ | ✅ |

---

## 🛠️ Troubleshooting

| Masalah | Solusi |
|---------|--------|
| `Permission denied` | `chmod +x raven.sh` |
| `Python not found` | `sudo apt install python3` |
| `stegseek not found` | `./raven.sh --install` |
| `rockyou.txt not found` | `sudo apt install wordlists && sudo gunzip /usr/share/wordlists/rockyou.txt.gz` |
| `volatility not found` | `pip install volatility3` |
| `raven: command not found` | `./raven.sh --install-global` |
| Error dependensi Python | `raven --update-deps` |
| Error venv | `rm -rf ~/.raven/venv` lalu jalankan ulang |

---

## 💡 Tips & Trik

- ⚡ Gunakan `--quick` untuk analisis super cepat saat kompetisi berlangsung
- 🎯 **Early exit** — otomatis berhenti begitu flag ditemukan
- 🔒 `--crypto` untuk menyerang semua jenis enkripsi sekaligus — RSA, Vigenere, XOR, Caesar
- 💡 `--xor-plain` sangat berguna bila tahu prefix flag-nya (misal `--xor-plain "picoCTF{"`)
- 🔍 `--stegseek` jauh lebih cepat dari `--bruteforce` untuk file JPEG
- 🗂️ `--folder` untuk soal yang menyertakan banyak file — auto-detect fake extension
- 🧠 `--volatility` untuk pipeline standar; `--memory` untuk analisis lebih dalam (malfind, dump proses)
- 💽 `--ntfs` untuk memulihkan file yang dihapus dari disk image NTFS
- 🌐 `--dns-tunnel` mendeteksi dan mendecode data tersembunyi dalam query DNS
- 🔤 `--deobfuscate` mencoba semua metode encode sekaligus — reverse, ROT13, caesar 1-25, atbash, b64, hex
- 📋 `--reg` decode semua nilai `hex:` di file `.reg` — sering menyembunyikan flag di RunOnce
- 🌐 `--log` deteksi request 200-OK dari attacker — flag sering tersembunyi di URL path
- 🔎 Periksa folder `*_bitplanes/` jika flag tidak terdeteksi otomatis pada gambar

---

## 📋 Changelog

### v4.0 — 2026
> **Tema: Crypto Engine + Forensics Disk & Memori Lanjutan**

**🆕 Fitur Baru**
- `--crypto` — Mesin kriptografi lengkap: auto-detect & serang RSA (weak prime/Fermat/Common-Modulus/Bellcore-CRT), Vigenere + akrostik key finder, XOR KPA, Classic Cipher (brute Atbash/Caesar), dan decoder Encoding Chain multi-tahap.
- `--rsa` — Paksa mode serangan RSA saja (gunakan bersama `--crypto`).
- `--vigenere` — Paksa analisis Vigenere dengan akrostik key finder.
- `--classic` — Brute force Atbash + Caesar (1-25 shift).
- `--xor-plain STR` — Serangan XOR known-plaintext (prefix default: `CTF{`).
- `--xor-key STR` — Dekripsi XOR langsung dengan key yang diberikan.
- `--crypto-key STR` — Key manual untuk Vigenere/Caesar.
- `--encoding-chain` — Decoder multi-tahap: Base32 → Binary → BitRev → Base64 → Hex, dan kombinasinya.
- `--memory` — Analisis Volatility lanjutan: malfind, dump proses, deteksi anomali.
- `--ntfs` — Recovery file terhapus di NTFS menggunakan `fls`/`icat`/strings/carving.
- `--partition` — Analisis tabel partisi (MBR/GPT), mount tiap partisi, scan data tersembunyi.
- `--dns-tunnel` — Deteksi DNS tunneling: decode chunk Base32/64/hex dari data query DNS.

**🔧 Perbaikan & Peningkatan**
- Banner diperbarui ke v4.0.
- Pola flag `REDLIMIT{...}` ditambahkan ke flag pattern matcher.
- Mesin deobfuscate diperluas dengan dukungan XOR brute.
- Analisis PCAP ditingkatkan dengan jalur deteksi DNS tunneling.

---

### v3.0 — 2026
> **Tema: Install Global + Auto-Solve CTF berdasarkan 11 writeup nyata**

**🆕 Fitur Baru**
- `--install-global` — Install ke `/usr/local/bin/raven`, bisa dijalankan dari direktori mana pun.
- `--uninstall` — Hapus binary dan data dari sistem.
- `~/.raven/` — Venv & engine disimpan di home directory (bukan folder script).
- `--reg` — Parser Windows Registry: decode semua nilai `hex:` (REG_BINARY) ke UTF-16/UTF-8, scan key Run/RunOnce/UserInit.
- `--log` — Analyzer log web server: frekuensi IP, status HTTP, deteksi pola serangan (SQLi/XSS/LFI), flag di URL 200-OK.
- `--autorun` — Analyzer Autorun/INF: reverse / ROT13 / Caesar brute / Atbash / Base64.
- `--zipcrack` — Crack password ZIP: tanpa password → kosong → rockyou.txt → fcrackzip.
- `--folder DIR` — Scanner fake extension: baca magic bytes, deteksi ketidakcocokan, rename otomatis dan ekstrak.
- `--volatility` — Auto-pipeline Volatility 3: windows.info → pslist → pstree → cmdline → envars → netscan → filescan → dumpfiles → scan flag.
- `--deobfuscate` — Mesin deobfuscation: reverse, ROT13, Atbash, Caesar brute (25 shift), Base64, Hex, reverse+Base64.

---

### v2.0 — 2026
> **Tema: Standalone .sh + Stegseek + Brute Force Paralel**

**🆕 Fitur Baru**
- Standalone — Python engine tertanam di dalam `.sh` via heredoc.
- `--stegseek` — Brute-force Stegseek dengan rockyou.txt (~14 juta password).
- `--install` — Auto-install semua tools sistem.
- `--exif` — Analisis metadata EXIF mendalam via exiftool.
- `--stegdetect` — Deteksi metode stego yang digunakan (rasio LSB, variansi channel).
- `--lsbextract` — Ekstrak raw bytes LSB ke file binary.
- `--compare FILE` — Perbandingan piksel dua gambar.
- Brute-force Steghide paralel dengan `ThreadPoolExecutor`.
- Mode `--quick`: strings → zsteg → stegseek → steghide, berhenti saat flag pertama ditemukan.

---

### v1.x — 2025
> **Tema: Tool forensik Python all-in-one (gaya AperiSolve)**

- Perintah `sfores` / `fores` sebagai entry point.
- Analisis gambar: bit planes, channel RGB, LSB (zsteg), steghide, outguess, pngcheck, jpseek.
- Auto-repair: magic bytes PNG & JPEG.
- File carving: foremost, binwalk.
- Auto-decode: Base64, Hex, Binary.
- Analisis PCAP: HTTP objects, DNS, kredensial, TCP streams, deteksi serangan, timeline.
- Analisis disk image + parser Windows Event Log.
- Pola flag: `picoCTF{...}`, `CTF{...}`, `flag{...}`, generik `PREFIX{...}`.
- Kalkulasi entropi & deteksi flag tersebar.

---

<div align="center">

Dikembangkan oleh **Syaaddd** 👨‍💻 — untuk para pejuang CTF! 🏆🚩

[![GitHub](https://img.shields.io/badge/GitHub-Syaaddd%2Fraven--ctf-black?style=for-the-badge&logo=github)](https://github.com/Syaaddd/raven-ctf)
[![Stars](https://img.shields.io/github/stars/Syaaddd/raven-ctf?style=for-the-badge&logo=github)](https://github.com/Syaaddd/raven-ctf/stargazers)
[![Issues](https://img.shields.io/github/issues/Syaaddd/raven-ctf?style=for-the-badge&logo=github)](https://github.com/Syaaddd/raven-ctf/issues)

*Kalau RAVEN membantu kamu dapat flag, tinggalkan ⭐!*

</div>
