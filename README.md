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
| 🌐 Network | tshark, PCAP analysis, HTTP objects, DNS tunneling |
| 🧠 Memory | Volatility 3 pipeline, advanced memory analysis |
| 🔒 Cryptography | RSA attacks, Vigenere, XOR KPA, Caesar, Atbash, Encoding Chain |
| 📁 Disk | Disk image, NTFS recovery, Partition scan, Event Log, Registry |
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

### 🆕 v4.0 — Fitur Baru

#### 🔒 Cryptography Engine (v4.0)
```bash
raven chall.txt --crypto                # Auto-attack semua: RSA, Vigenere, XOR, Classic, Chain
raven rsa_chall.txt --crypto --rsa      # Fokus RSA attacks (weak prime, Fermat, Common-Modulus, Bellcore)
raven cipher.txt --crypto --vigenere    # Vigenere + akrostik key finder
raven secret.txt --classic              # Atbash + Caesar brute (1-25)
raven enc.bin --xor-plain "CTF{"        # XOR KPA dengan known-plaintext prefix
raven enc.bin --xor-key "DARKSIDE"      # XOR decrypt manual dengan key
raven encoded.txt --encoding-chain      # Multi-stage decode (Base32→Binary→BitRev→B64)
```

#### 🧠 Advanced Memory Analysis
```bash
raven dump.raw --volatility             # Volatility 3 auto-pipeline standar
raven dump.raw --memory                 # Advanced: malfind + process dump + anomaly detection
```

#### 💽 Advanced Disk Forensics
```bash
raven disk.img --ntfs                   # NTFS deleted file recovery (fls/icat/strings/carving)
raven disk.img --partition              # Partition table analysis (MBR/GPT, hidden partition scan)
```

#### 🌐 DNS Tunneling Detector
```bash
raven capture.pcap --pcap              # PCAP analysis standard
raven capture.pcap --dns-tunnel        # DNS tunneling detector + Base32/64/hex chunk decoder
```
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
raven capture.pcap --pcap              # PCAP analysis + attack detection
raven capture.pcap --dns-tunnel        # DNS tunneling detector
raven disk.img --disk                  # Disk image analysis
raven disk.img --ntfs                  # NTFS deleted file recovery
raven disk.img --partition             # Partition table analysis (MBR/GPT)
raven security.evtx --windows         # Windows Event Log forensics
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
| `*_ntfs/` | NTFS deleted file recovery |
| `*_partitions/` | Partition scan results |
| `*_dns_tunnel/` | DNS tunneling decoded chunks |
| `*_crypto/` | Crypto attack results |

---

## ⚡ Perbandingan Performa

| Fitur | v1.x | v2.0 | v3.0 | v4.0 |
|-------|------|------|------|------|
| **Global install** | ❌ | ❌ | ✅ | ✅ |
| **Crypto engine (RSA/Vigenere/XOR)** | ❌ | ❌ | ❌ | ✅ `--crypto` |
| **Advanced memory analysis** | ❌ | ❌ | ❌ | ✅ `--memory` |
| **NTFS deleted file recovery** | ❌ | ❌ | ❌ | ✅ `--ntfs` |
| **Partition table scan** | ❌ | ❌ | ❌ | ✅ `--partition` |
| **DNS tunneling detector** | ❌ | ❌ | ❌ | ✅ `--dns-tunnel` |
| **Stegseek + rockyou** | ❌ | ✅ | ✅ | ✅ |
| **ZIP password crack** | ❌ | ❌ | ✅ | ✅ |
| **Registry analysis** | ❌ | ❌ | ✅ | ✅ |
| **Log analysis** | ❌ | ❌ | ✅ | ✅ |
| **Volatility wrapper** | ❌ | ❌ | ✅ | ✅ |
| **Deobfuscation engine** | ❌ | ❌ | ✅ | ✅ |
| **Fake ext detection** | ❌ | ❌ | ✅ | ✅ |
| **Quick Mode** | ❌ | ✅ | ✅ | ✅ |
| **Parallel brute force** | ❌ | ✅ 5t | ✅ 5t | ✅ 5t |
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

---

## 💡 Tips & Trik

- ⚡ Gunakan `--quick` untuk analisis super cepat saat kompetisi berlangsung
- 🎯 **Early exit** otomatis berhenti begitu flag ditemukan
- 🔒 `--crypto` untuk otomatis menyerang semua jenis enkripsi sekaligus — RSA, Vigenere, XOR, Caesar
- 💡 `--xor-plain` powerful untuk soal yang tahu prefix flag-nya (e.g. `--xor-plain "picoCTF{"`)
- 🔍 `--stegseek` jauh lebih cepat dari `--bruteforce` untuk JPEG
- 🗂️ `--folder` untuk soal yang kasih banyak file — auto-detect fake extension
- 🧠 `--volatility` untuk pipeline standar; `--memory` untuk analisis lebih dalam (malfind, dump)
- 💽 `--ntfs` untuk recover file yang dihapus dari disk image NTFS
- 🌐 `--dns-tunnel` deteksi dan decode data tersembunyi dalam query DNS
- 🔤 `--deobfuscate` coba semua metode encode sekaligus — reverse, ROT13, caesar 1-25, atbash, b64, hex
- 📋 `--reg` decode semua nilai `hex:` di `.reg` — sering menyembunyikan flag di RunOnce
- 🌐 `--log` deteksi request 200-OK attacker — flag sering di URL path
- 🔎 Periksa `*_bitplanes/` jika flag tidak terdeteksi otomatis di gambar

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

### Key Features (v4.0)

| Feature | Command | Description |
|---------|---------|-------------|
| 🔒 Crypto Engine | `--crypto` | RSA attacks (weak/Fermat/CommonMod/Bellcore), Vigenere+acrostic, XOR KPA, Classic Cipher, Encoding Chain |
| 🔑 RSA Attack | `--rsa` | Force RSA-only attack (use with `--crypto`) |
| 🔤 Vigenere | `--vigenere` | Vigenere analysis + acrostic key finder |
| ⊕ XOR KPA | `--xor-plain STR` | Known-plaintext XOR attack |
| 📝 Classic Cipher | `--classic` | Atbash + Caesar brute force (1-25) |
| 🔗 Encoding Chain | `--encoding-chain` | Multi-stage decoder (Base32/64/Binary/BitRev/Hex) |
| 🧠 Adv. Memory | `--memory` | Advanced Volatility: malfind, process dump, anomaly detection |
| 💽 NTFS Recovery | `--ntfs` | NTFS deleted file recovery (fls/icat/strings) |
| 🗂️ Partition Scan | `--partition` | MBR/GPT partition analysis + hidden partition scan |
| 🌐 DNS Tunnel | `--dns-tunnel` | DNS tunneling detector + Base32/64/hex chunk decoder |
| 🔍 Stegseek | `--stegseek` | Brute-force steghide with rockyou.txt |
| 🧠 Memory | `--volatility` | Volatility 3 auto-pipeline |
| 🔑 Deobfuscate | `--deobfuscate` | ROT13, Caesar, Atbash, Base64, Hex, reverse |
| 📁 Fake Ext | `--folder` | Detect and fix mismatched file extensions |
| 📋 Registry | `--reg` | Windows registry hex decoder |
| 🌐 Log | `--log` | Web server log attacker detection |

### Environment Variables

```bash
export RAVEN_THREADS=5                   # Brute force thread count (default: 5)
export RAVEN_WORDLIST="/path/to/list"    # Custom wordlist path
```

---

## 📋 Changelog

### v4.0 — 2026
> **Theme: Crypto Engine + Advanced Disk & Memory Forensics**

**🆕 New Features**
- `--crypto` — Full cryptography engine: auto-detect & attack RSA (weak prime/Fermat/Common-Modulus/Bellcore-CRT), Vigenere+acrostic key finder, XOR KPA, Classic Cipher (Atbash/Caesar brute), and multi-stage Encoding Chain decoder.
- `--rsa` — Force RSA-only attack mode (use with `--crypto`).
- `--vigenere` — Force Vigenere analysis with acrostic key finder.
- `--classic` — Atbash + Caesar brute force (1-25 shifts).
- `--xor-plain STR` — Known-plaintext XOR attack (default prefix: `CTF{`).
- `--xor-key STR` — Direct XOR decrypt with a given key.
- `--crypto-key STR` — Manual key for Vigenere/Caesar.
- `--encoding-chain` — Multi-stage encoding decoder: Base32 → Binary → BitRev → Base64 → Hex, and combinations.
- `--memory` — Advanced Volatility analysis: malfind, process dump, anomaly detection.
- `--ntfs` — NTFS deleted file recovery using `fls`/`icat`/strings/carving.
- `--partition` — Partition table analysis (MBR/GPT), mount partitions, scan for hidden data.
- `--dns-tunnel` — DNS tunneling detector: Base32/64/hex chunk decoder from DNS query data.

**🔧 Fixes & Improvements**
- Banner updated to show v4.0.
- `REDLIMIT{...}` added to flag pattern matcher.
- Deobfuscate engine extended with XOR brute support.
- Improved PCAP analysis with DNS tunneling path.

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
- `--zipcrack` — ZIP password cracker: no-password → empty → rockyou.txt → fcrackzip.
- `--folder DIR` — Fake extension scanner: read magic bytes, detect mismatch, auto-rename and extract.
- `--volatility` — Volatility 3 auto-pipeline: windows.info → pslist → pstree → cmdline → envars → netscan → filescan → dumpfiles → flag scan.
- `--deobfuscate` — Deobfuscation engine: reverse, ROT13, Atbash, Caesar brute (25 shifts), Base64, Hex, reverse+Base64.

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
