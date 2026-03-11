<div align="center">

# 🐦‍⬛ RAVEN CTF Toolkit

**Smart Multi-Category CTF Automation Toolkit**

[![Version](https://img.shields.io/badge/version-v4.0-blue?style=for-the-badge&logo=github)](https://github.com/Syaaddd/raven-ctf)
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-orange?style=for-the-badge&logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Python](https://img.shields.io/badge/python-3.8%2B-yellow?style=for-the-badge&logo=python)](https://www.python.org/)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Docker-lightgrey?style=for-the-badge&logo=linux)](https://www.linux.org/)
[![CTF](https://img.shields.io/badge/CTF-ready-red?style=for-the-badge&logo=hackthebox)](https://github.com/Syaaddd/raven-ctf)

*Alat otomatis untuk semua kategori CTF — forensics, steganografi, cryptography, network, memory forensics, dan deteksi flag* 🚩

[🇮🇩 Bahasa Indonesia](#bahasa-indonesia) · [🇺🇸 English](#english) · [📦 Install](#-instalasi) · [▶️ Usage](#%EF%B8%8F-penggunaan) · [🆕 Changelog](#-changelog)

</div>

---

## 🇮🇩 Bahasa Indonesia

### 🔍 Tentang RAVEN

RAVEN adalah toolkit CTF berbasis Bash + Python yang dirancang untuk mempercepat proses analisis challenge. Mulai dari steganografi gambar, forensics memori, network PCAP, hingga deobfuscation — semua terintegrasi dalam **satu file `.sh`**.

**Kategori yang didukung:**

| Kategori | Tools |
|----------|-------|
| 🖼️ Steganografi | zsteg, steghide, stegseek, outguess, LSB |
| 🔬 Forensics | foremost, binwalk, exiftool, pngcheck |
| 🌐 Network | tshark, PCAP analysis, HTTP objects |
| 🧠 Memory | Volatility 3 pipeline |
| 🔒 Cryptography | ROT13, Caesar, Atbash, Base64, Hex |
| 📁 Disk | Disk image, Event Log, Registry |
| 🤖 AI | Claude API hint (v4.0 NEW) |
| 📊 Report | Auto HTML/PDF report generator (v4.0 NEW) |

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

### 3. Install via Docker 🐳 (v4.0 NEW)
```bash
docker pull syaaddd/raven-ctf:latest

# Jalankan dengan bind mount ke folder challenge
docker run --rm -v $(pwd):/data syaaddd/raven-ctf image.png --auto
docker run --rm -v $(pwd):/data syaaddd/raven-ctf --folder /data/challenges/
```

Atau build sendiri:
```bash
docker build -t raven-ctf .
docker run --rm -v $(pwd):/data raven-ctf challenge.png --all
```

### 4. Install Semua Tools Sistem (Otomatis)
```bash
./raven.sh --install
```
Menginstall: steghide, stegseek, zsteg, foremost, exiftool, tshark, rockyou.txt, fcrackzip, dll.

### 5. Install Manual (Opsional)

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
pip install colorama Pillow numpy requests
```

---

## 📁 Struktur

```
raven-ctf/
├── raven.sh            ← Satu file ini sudah cukup!
├── Dockerfile          ← Docker support (v4.0)
└── docker-compose.yml  ← Docker Compose (v4.0)

~/.raven/               ← Data runtime (dibuat otomatis)
├── venv/               ← Python venv
├── engine.py           ← Python engine (auto-generated)
└── reports/            ← HTML/PDF reports (v4.0)

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

### 🆕 v4.0 — Fitur Baru

#### 🤖 AI-Powered Flag Hint (Claude API)
```bash
# Setup API key sekali saja
export ANTHROPIC_API_KEY="sk-ant-..."

# Minta hint dari AI berdasarkan hasil analisis
raven image.png --ai-hint
raven dump.raw --volatility --ai-hint
raven capture.pcap --pcap --ai-hint
```
> AI akan membaca output analisis dan memberikan hint langkah selanjutnya yang relevan berdasarkan pattern CTF nyata.

#### 🐳 Docker Support
```bash
raven --docker-run image.png --auto
# Otomatis jalankan dalam container terisolasi
```

#### 📊 Auto-Report Generator
```bash
raven image.png --all --report          # Generate HTML report
raven image.png --all --report --pdf    # Generate PDF report
raven --folder ./challs/ --report       # Report untuk seluruh folder

# Output: ~/.raven/reports/raven_report_<timestamp>.html
```
> Report berisi: ringkasan flag ditemukan, tools yang dijalankan, output lengkap per tool, dan screenshot bit-plane.

#### 🖥️ Web UI / Dashboard Lokal
```bash
raven --webui           # Buka dashboard di http://localhost:7734
raven --webui --port 8080
```
> Dashboard menampilkan: drag-drop file upload, progress analisis real-time, hasil flag, dan history challenge.

### 🗝️ CTF Spesifik (v3.0+)
```bash
raven artifact.reg   --reg              # Windows Registry analysis
raven access.log     --log              # Web server log analysis
raven autorun.inf    --autorun          # Autorun/INF file analysis
raven evidence.zip   --zipcrack         # Crack ZIP password otomatis
raven chall.raw      --volatility       # Memory forensics (Volatility 3)
raven secret.txt     --deobfuscate      # Reverse/ROT13/caesar/atbash/b64
raven                --folder ./dir/    # Fake extension scanner
```

### 🔒 Steganografi
```bash
raven image.png --lsb        # LSB analysis (zsteg)
raven image.jpg --steghide   # Steghide extraction
raven image.jpg --stegseek   # Stegseek + rockyou.txt
raven image.jpg --outguess   # Outguess (JPEG)
raven image.png --pngcheck   # Validasi PNG
raven image.jpg --jpsteg     # JPEG steganalysis
raven image.png --foremost   # File carving
raven image.png --exif       # Deep EXIF analysis
raven image.png --stegdetect # Deteksi metode stego
raven image.png --lsbextract # Ekstrak raw LSB bytes
raven image.png --remap      # Color remapping (8 variants)
raven image.png --deep       # Semua 8 bit plane
raven img1.png --compare img2.png
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
raven capture.pcap --pcap
raven disk.img --disk
raven security.evtx --windows
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
| `~/.raven/reports/` | **HTML/PDF reports (v4.0)** |

---

## ⚡ Perbandingan Performa

| Fitur | v1.x | v2.0 | v3.0 | v4.0 |
|-------|------|------|------|------|
| **Global install** | ❌ | ❌ | ✅ | ✅ |
| **Docker support** | ❌ | ❌ | ❌ | ✅ `--docker-run` |
| **AI flag hint** | ❌ | ❌ | ❌ | ✅ `--ai-hint` |
| **Web UI dashboard** | ❌ | ❌ | ❌ | ✅ `--webui` |
| **Auto HTML/PDF report** | ❌ | ❌ | ❌ | ✅ `--report` |
| **Stegseek + rockyou** | ❌ | ✅ | ✅ | ✅ |
| **ZIP password crack** | ❌ | ❌ | ✅ | ✅ |
| **Registry analysis** | ❌ | ❌ | ✅ | ✅ |
| **Log analysis** | ❌ | ❌ | ✅ | ✅ |
| **Volatility wrapper** | ❌ | ❌ | ✅ | ✅ |
| **Deobfuscation engine** | ❌ | ❌ | ✅ | ✅ |
| **Fake ext detection** | ❌ | ❌ | ✅ | ✅ |
| **Quick Mode** | ❌ | ✅ | ✅ | ✅ |
| **Parallel brute force** | ❌ | ✅ 5t | ✅ 8t | ✅ 16t |
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
| Python deps error | `raven --update-deps` |
| Venv error | `rm -rf ~/.raven/venv` lalu jalankan ulang |
| `--ai-hint` not working | Pastikan `ANTHROPIC_API_KEY` sudah di-export |
| Docker error | `docker pull syaaddd/raven-ctf:latest` |
| Web UI port conflict | `raven --webui --port 8888` |

---

## 💡 Tips & Trik

- ⚡ Gunakan `--quick` untuk analisis super cepat saat kompetisi berlangsung
- 🎯 **Early exit** otomatis berhenti begitu flag ditemukan
- 🤖 `--ai-hint` memberikan saran langkah berikutnya berbasis AI — ideal saat stuck
- 📊 `--report --pdf` untuk dokumentasi writeup yang rapi setelah solve
- 🐳 Gunakan Docker untuk environment bersih tanpa install tools di host
- 🔍 `--stegseek` jauh lebih cepat dari `--bruteforce` untuk JPEG
- 🗂️ `--folder` untuk soal yang kasih banyak file — auto-detect fake extension
- 🧠 `--volatility` auto-dump file menarik dari RAM (flag, tiket, data diri, dll)
- 🔤 `--deobfuscate` coba semua metode encode sekaligus — reverse, ROT13, caesar 1-25, atbash, b64, hex
- 📋 `--reg` decode semua nilai `hex:` di `.reg` — sering menyembunyikan flag di RunOnce
- 🌐 `--log` deteksi request 200-OK attacker — flag sering di URL path
- 🔎 Periksa `*_bitplanes/` jika flag tidak terdeteksi otomatis di gambar
- 🌐 Buka `--webui` untuk monitoring challenge banyak secara visual

---

## 🇺🇸 English

### 🔍 About RAVEN

RAVEN is a Bash + Python CTF toolkit designed to accelerate challenge analysis. From image steganography and memory forensics to network PCAPs and deobfuscation — all integrated into **a single `.sh` file**.

### 🚀 Quick Start

```bash
git clone https://github.com/Syaaddd/raven-ctf.git
cd raven-ctf && chmod +x raven.sh
./raven.sh --install-global   # Install globally
./raven.sh --install          # Install all system tools
raven challenge.png --auto    # Analyze your first challenge
```

### Docker
```bash
docker pull syaaddd/raven-ctf:latest
docker run --rm -v $(pwd):/data syaaddd/raven-ctf image.png --auto
```

### Key Features (v4.0)

| Feature | Command | Description |
|---------|---------|-------------|
| 🤖 AI Hint | `--ai-hint` | Claude AI suggests next steps based on analysis output |
| 🐳 Docker | `--docker-run` | Run in isolated container |
| 📊 Report | `--report [--pdf]` | Auto-generate HTML or PDF report |
| 🖥️ Web UI | `--webui` | Local dashboard at `localhost:7734` |
| 🔍 Stegseek | `--stegseek` | Brute-force steghide with rockyou.txt |
| 🧠 Memory | `--volatility` | Volatility 3 auto-pipeline |
| 🔑 Deobfuscate | `--deobfuscate` | ROT13, Caesar, Atbash, Base64, Hex |
| 📁 Fake Ext | `--folder` | Detect and fix mismatched file extensions |
| 📋 Registry | `--reg` | Windows registry hex decoder |
| 🌐 Log | `--log` | Web server log attacker detection |

### Environment Variables

```bash
export ANTHROPIC_API_KEY="sk-ant-..."   # Required for --ai-hint
export RAVEN_THREADS=16                  # Brute force thread count (default: 8)
export RAVEN_WORDLIST="/path/to/list"    # Custom wordlist path
```

---

## 📋 Changelog

### v4.0 — 2026
> **Theme: AI Integration + Docker + Web UI + Auto-Report**

**🆕 New Features**
- `--ai-hint` — Claude AI integration: reads analysis output and suggests next steps based on real CTF patterns. Requires `ANTHROPIC_API_KEY`.
- `--docker-run` — Run RAVEN in an isolated Docker container. Full Docker image available at `syaaddd/raven-ctf:latest`.
- `--webui [--port N]` — Local web dashboard at `http://localhost:7734`. Features: drag-drop upload, real-time progress, flag history, multi-file queue.
- `--report` — Auto-generate HTML report summarizing flags found, tools run, full output per tool, and bit-plane screenshots.
- `--report --pdf` — Export report as PDF (requires `weasyprint`).
- `Dockerfile` + `docker-compose.yml` added to repository.
- Parallel brute-force upgraded to 16 threads default (from 8).
- `RAVEN_THREADS` and `RAVEN_WORDLIST` environment variable support.

**🔧 Fixes & Improvements**
- `~/.raven/reports/` directory for persistent report storage.
- `requests` added to Python dependencies for AI API calls.
- Better error messages when `ANTHROPIC_API_KEY` is not set.
- README fully bilingual (Bahasa Indonesia + English).
- Added shields.io badges for version, license, platform.

---

### v3.0 — 2026
> **Theme: Global Install + Auto-Solve CTF based on 11 real writeups**

**🆕 New Features**
- `--install-global` — Install to `/usr/local/bin/raven`, run from any directory.
- `--uninstall` — Remove binary and data from system.
- `~/.raven/` — Venv & engine stored in home directory (not script folder).
- `--reg` — Windows Registry parser: decode all `hex:` values (REG_BINARY) to UTF-16/UTF-8, scan Run/RunOnce/UserInit keys.
- `--log` — Web server log analyzer: IP frequency, HTTP status, attack pattern detection (SQLi/XSS/LFI), flag in 200-OK URLs.
- `--autorun` — Autorun/INF analyzer: reverse / ROT13 / Caesar brute / Atbash / Base64.
- `--zipcrack` — ZIP password cracker: no-password → empty → rockyou.txt (8 threads) → fcrackzip.
- `--folder DIR` — Fake extension scanner: read magic bytes, detect mismatch, auto-rename and extract.
- `--volatility` — Volatility 3 auto-pipeline: windows.info → pslist → pstree → cmdline → envars → netscan → filescan → dumpfiles → flag scan.
- `--deobfuscate` — Deobfuscation engine: reverse, ROT13, Atbash, Caesar brute (25 shifts), Base64, Hex, reverse+Base64.
- `REDLIMIT{...}` added to flag pattern matcher.

---

### v2.0 — 2026
> **Theme: Standalone .sh + Stegseek + Parallel Brute Force**

**🆕 New Features**
- Standalone — Python engine embedded in `.sh` via heredoc.
- `--stegseek` — Stegseek brute-force with rockyou.txt (~14M passwords).
- `--install` — Auto-install all system tools.
- `--exif` — Deep EXIF metadata analysis via exiftool.
- `--stegdetect` — Detect stego method (LSB ratio, channel variance).
- `--lsbextract` — Extract raw LSB bytes to binary file.
- `--compare FILE` — Pixel diff two images.
- Parallel steghide brute-force with `ThreadPoolExecutor`.
- `--quick` mode: strings → zsteg → stegseek → steghide, stops at first flag.

---

### v1.x — 2025
> **Theme: All-in-one Python forensic tool (AperiSolve style)**

- `sfores` / `fores` command as entry point.
- Image analysis: bit planes, RGB channels, LSB (zsteg), steghide, outguess, pngcheck, jpseek.
- Auto-repair: PNG & JPEG magic bytes.
- File carving: foremost, binwalk.
- Auto-decode: Base64, Hex, Binary.
- PCAP analysis: HTTP objects, DNS, credentials, TCP streams, attack detection, timeline.
- Disk image analysis + Windows Event Log parser.
- Flag patterns: `picoCTF{...}`, `CTF{...}`, `flag{...}`, generic `PREFIX{...}`.
- Entropy calculation & scattered flag detection.

---

<div align="center">

Dikembangkan oleh **Syaaddd** 👨‍💻 — untuk para pejuang CTF! 🏆🚩

Developed by **Syaaddd** 👨‍💻 — for CTF warriors everywhere! 🏆🚩

[![GitHub](https://img.shields.io/badge/GitHub-Syaaddd%2Fraven--ctf-black?style=for-the-badge&logo=github)](https://github.com/Syaaddd/raven-ctf)
[![Stars](https://img.shields.io/github/stars/Syaaddd/raven-ctf?style=for-the-badge&logo=github)](https://github.com/Syaaddd/raven-ctf/stargazers)
[![Issues](https://img.shields.io/github/issues/Syaaddd/raven-ctf?style=for-the-badge&logo=github)](https://github.com/Syaaddd/raven-ctf/issues)

*If RAVEN helped you capture the flag, leave a ⭐!*

</div>
