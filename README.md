<div align="center">

# 🐦‍⬛ RAVEN CTF Toolkit

**Toolkit Otomasi CTF Multi-Kategori yang Cerdas**

[![Version](https://img.shields.io/badge/version-v5.1-blue?style=for-the-badge&logo=github)](https://github.com/Syaaddd/raven-ctf)
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-orange?style=for-the-badge&logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Python](https://img.shields.io/badge/python-3.8%2B-yellow?style=for-the-badge&logo=python)](https://www.python.org/)
[![Platform](https://img.shields.io/badge/platform-Linux-lightgrey?style=for-the-badge&logo=linux)](https://www.linux.org/)
[![CTF](https://img.shields.io/badge/CTF-ready-red?style=for-the-badge&logo=hackthebox)](https://github.com/Syaaddd/raven-ctf)

*Alat otomatis untuk semua kategori CTF — forensics, steganografi, kriptografi, network, memory forensics, dan deteksi flag* 🚩

[📦 Instalasi](#-instalasi) · [▶️ Penggunaan](#️-penggunaan) · [📁 Output](#-output-folder) · [🆕 Changelog](#-changelog)

</div>

---

## 🔍 Tentang RAVEN

RAVEN adalah toolkit CTF berbasis Bash + Python yang dirancang untuk mempercepat proses analisis challenge. Mulai dari steganografi gambar, forensics memori, network PCAP, hingga deobfuscation — semua terintegrasi dalam **modular Python engine**.

**🆕 v5.1 — Modular Engine Architecture**

RAVEN v5.1 hadir dengan arsitektur modular yang lebih clean dan maintainable:
- **9 file Python terpisah** (dari sebelumnya 1 heredoc 6360 baris)
- **Event logging system** untuk writeup generation
- **Writeup-ready output** dalam 3 format (Terminal/Markdown/JSON)
- **Code style natural** — tidak AI-looking, mudah dibaca dan di-maintain

**Struktur Engine:**
```
engine/
├── core.py (~390 baris)         ← Globals, utils, flag scanner, event_log
├── stego.py (~500 baris)        ← Steganografi (zsteg, steghide, LSB, bitplane)
├── forensics.py (~630 baris)    ← Disk, memory, registry, log, autorun
├── crypto.py (~650 baris)       ← RSA, XOR, Vigenere, classic ciphers
├── reversing.py (~370 baris)    ← Strings, objdump, readelf, packer, Ghidra
├── pcap.py (~270 baris)         ← PCAP analysis (tshark, DNS tunneling)
└── report.py (~260 baris)       ← WriteupBuilder (terminal/Markdown/JSON)
```

**Kategori yang didukung:**

| Kategori | Tools |
|----------|-------|
| 🖼️ Steganografi | zsteg, steghide, stegseek, outguess, LSB |
| 🔬 Forensics | foremost, binwalk, exiftool, pngcheck |
| 🌐 Network | tshark, PCAP analysis, HTTP objects, DNS tunneling |
| 🧠 Memory | Volatility 3 pipeline, advanced memory analysis |
| 🔒 Cryptography | RSA attacks (multi-file), Vigenere, XOR KPA, Caesar, Atbash, Encoding Maze |
| 🔧 Reversing | strings, objdump, readelf, Ghidra, UPX unpacker |
| 📁 Disk | Disk image, NTFS recovery, Partition scan, Event Log, Registry (hex decode) |
| 🔎 Deobfuscate | ROT13, Caesar brute (1-25), Atbash, Base64, Hex, reverse |
| 📊 Log Analysis | Apache/Nginx log parser, attacker IP detection, timeline, flag in URLs |

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
├── raven.sh            ← Bash wrapper (menu, venv, dispatch)
└── engine/             ← Modular Python engine (v5.1)
    ├── __init__.py     ← Package initialization
    ├── __main__.py     ← Entry point
    ├── core.py         ← Globals, utils, event_log, flag scanner
    ├── stego.py        ← Steganografi functions
    ├── forensics.py    ← Disk, memory, registry, log analysis
    ├── crypto.py       ← RSA, XOR, Vigenere, classic ciphers
    ├── reversing.py    ← Binary reversing functions
    ├── pcap.py         ← PCAP analysis functions
    └── report.py       ← Writeup generator (terminal/Markdown/JSON)

~/.raven/               ← Data runtime (dibuat otomatis)
├── venv/               ← Python venv
└── engine/             ← Copied modular engine files

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

#### 🆕 v5.0+ — Interactive Menu (Default, Multi-Select)
```bash
raven challenge.png              # Opens interactive menu
raven file1.png file2.bin file3.elf  # Multi-file support
raven                            # Shows menu first
```

**Menu Features:**
- **Multi-Select**: Pilih beberapa kategori sekaligus
- **3 TUI Modes**: Native `select`, `whiptail` checklist, `fzf` fuzzy finder
- **Auto-Detect di Atas**: Mode paling atas (default ON di whiptail)
- **Multi-File Support**: Analisis beberapa file sekaligus dalam satu sesi
- **Smart Defaults**: Automatically selects best TUI based on available tools

#### Traditional Modes (Backwards Compatible)
```bash
raven image.png --auto      # Auto-detect semua tools sesuai tipe file
raven image.png --all       # Jalankan SEMUA analisis
raven image.png --quick     # ULTRA-FAST: strings + zsteg + stegseek + early exit
```

### 🆕 Fitur Baru v4.0+

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

#### 🔧 Advanced Binary Reversing
```bash
raven binary.elf --reversing              # Full reversing pipeline
raven binary.exe --reversing --unpack     # Auto-unpack UPX packed binary
raven binary.elf --reversing --ghidra     # Ghidra headless analysis
```

**Reversing Features:**
- **Packer Detection**: UPX, MPRESS, ASPack, Themida, VMProtect
- **Auto-Unpacker**: UPX unpacking with automatic detection
- **Strings Analysis**: Extract strings, search for flags, URLs, IPs, secrets
- **Disassembly**: objdump for ELF binaries
- **Binary Structure**: readelf analysis (headers, sections, symbols, relocations)
- **Ghidra Integration**: Headless analyzer for advanced reverse engineering

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

**Output folders dibuat di current working directory (CWD), bukan di sebelah file input.**

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
| `*_reversing/` | Binary reversing output |
| `*_objdump/` | Disassembly files |
| `*_readelf/` | Binary structure analysis |
| `*_strings.txt` | Extracted strings |

---

## ⚡ Perbandingan Versi

| Fitur | v1.x | v2.0 | v3.0 | v4.0 | v5.0 | v5.1 |
|-------|------|------|------|------|------|------|
| **Global install** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Interactive Menu** | ❌ | ❌ | ❌ | ❌ | ✅ Default | ✅ |
| **3 TUI Modes (select/whiptail/fzf)** | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Reversing Module** | ❌ | ❌ | ❌ | ❌ | ✅ `--reversing` | ✅ |
| **Packer Detection (UPX/etc)** | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Ghidra Integration** | ❌ | ❌ | ❌ | ❌ | ✅ `--ghidra` | ✅ |
| **Crypto engine (RSA/Vigenere/XOR)** | ❌ | ❌ | ❌ | ✅ | ✅ `--crypto` | ✅ |
| **Advanced memory analysis** | ❌ | ❌ | ❌ | ✅ | ✅ `--memory` | ✅ |
| **NTFS deleted file recovery** | ❌ | ❌ | ❌ | ✅ | ✅ `--ntfs` | ✅ |
| **Partition table scan** | ❌ | ❌ | ❌ | ✅ | ✅ `--partition` | ✅ |
| **DNS tunneling detector** | ❌ | ❌ | ❌ | ✅ | ✅ `--dns-tunnel` | ✅ |
| **Modular Engine** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Event Logging** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Writeup Generation** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Output di CWD** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Enhanced Summary** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Stegseek + rockyou** | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **ZIP password crack** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Registry analysis** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Log analysis** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Volatility wrapper** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Deobfuscation engine** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Fake ext detection** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Quick Mode** | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Parallel brute force** | ❌ | ✅ 5t | ✅ 5t | ✅ 5t | ✅ 5t | ✅ 5t |
| **Standalone .sh** | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |

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

RAVEN is a Bash + Python CTF toolkit designed to accelerate challenge analysis. From image steganography and memory forensics to network PCAPs and deobfuscation — all integrated into a **modular Python engine architecture**.

### 🚀 Quick Start

```bash
git clone https://github.com/Syaaddd/raven-ctf.git
cd raven-ctf && chmod +x raven.sh
./raven.sh --install-global   # Install globally
./raven.sh --install          # Install all system tools
raven challenge.png --auto    # Analyze your first challenge
```

### Key Features (v5.1)

| Feature | Command | Description |
|---------|---------|-------------|
| 🎯 Interactive Menu | (default) | Multi-select: 3 TUI modes (select/whiptail/fzf) |
| 🔧 Binary Reversing | `--reversing` | strings, objdump, readelf, packer detection |
| 📦 UPX Unpacker | `--unpack` | Auto-detect and unpack UPX packed binaries |
| 🔬 Ghidra Integration | `--ghidra` | Headless Ghidra analysis (requires Ghidra) |
| 🔒 Crypto Engine | `--crypto` | RSA, Vigenere, XOR KPA, Classic Cipher, Encoding Chain |
| 🧠 Adv. Memory | `--memory` | Advanced Volatility: malfind, process dump, anomaly detection |
| 💽 NTFS Recovery | `--ntfs` | NTFS deleted file recovery (fls/icat/strings) |
| 🗂️ Partition Scan | `--partition` | MBR/GPT partition analysis |
| 🌐 DNS Tunnel | `--dns-tunnel` | DNS tunneling detector + decoder |
| 📁 Output di CWD | (auto) | Output folders created in current working directory |
| 📊 Enhanced Summary | (auto) | Full analysis summary with flags, tools, and folders |

### Environment Variables

```bash
export RAVEN_THREADS=5                   # Brute force thread count (default: 5)
export RAVEN_WORDLIST="/path/to/list"    # Custom wordlist path
```

---

## 📋 Changelog

### v5.1 — 2026
> **Theme: Modular Engine + Writeup Generation**

**🆕 New Features**
- **Modular Engine Architecture** — Python engine dipisah dari 1 heredoc (6360 baris) menjadi 9 file modular (~3000 baris total)
- **Event Logging System** — Tracking setiap tool execution untuk writeup generation
- **Writeup-Ready Output** — 3 format output: Terminal, Markdown, JSON
- **Output di CWD** — Semua output folders dibuat di current working directory, bukan di sebelah file input
- **Enhanced Summary** — Ringkasan lengkap di akhir: flags yang ditemukan, tools yang dijalankan, output folders
- **Path Resolution** — File arguments di-resolve ke absolute path sebelum `cd`, jadi relative path bekerja dari mana saja
- **Natural Code Style** — Docstring 1 baris, nama variabel singkat, inline logic, tidak AI-looking

**📁 Engine Structure**
```
engine/
├── core.py           ← Globals, utils, event_log, flag scanner, deobfuscation
├── stego.py          ← Steganografi (zsteg, steghide, LSB, bitplane, compare, remap)
├── forensics.py      ← Disk, memory, registry, log, autorun, zip crack
├── crypto.py         ← RSA (weak/Fermat/Common/Bellcore), XOR, Vigenere, classic, chain
├── reversing.py      ← Strings, objdump, readelf, packer detection, Ghidra
├── pcap.py           ← PCAP analysis (tshark, HTTP/DNS, streams, DNS tunneling)
└── report.py         ← WriteupBuilder (terminal/Markdown/JSON reports)
```

**🔧 Improvements**
- Separation of concerns: setiap module fokus pada satu domain
- Easier to test, lint, dan maintain code secara terpisah
- Backward compatible: semua flag CLI dan fitur v5.0 tetap berfungsi
- Engine bisa di-import sebagai Python module: `from engine import core, stego, ...`

---

### v5.0 — 2026
> **Theme: Interactive Menu System + Binary Reversing**

**🆕 New Features**
- `--interactive` — Interactive category menu with **multi-select support** (default mode).
- **3 TUI Modes with Multi-Select**: Native bash `select`, `whiptail` checklist, `fzf` fuzzy finder
- **Multi-File Support**: Analyze multiple files in one session
- `--reversing` — Full binary reversing pipeline: strings, objdump, readelf, Ghidra integration.
- `--unpack` — Auto-unpack packed binaries (UPX detection and unpacking).
- **Packer Detection**: UPX, MPRESS, ASPack, Themida, VMProtect.

---

### v4.0 — 2026
> **Tema: Crypto Engine + Forensics Disk & Memori Lanjutan**

**🆕 Fitur Baru**
- `--crypto` — Mesin kriptografi lengkap: RSA, Vigenere, XOR KPA, Classic Cipher, Encoding Chain.
- `--memory` — Analisis Volatility lanjutan: malfind, dump proses, deteksi anomali.
- `--ntfs` — Recovery file terhapus di NTFS.
- `--partition` — Analisis tabel partisi (MBR/GPT).
- `--dns-tunnel` — Deteksi DNS tunneling.

---

### v3.0 — 2026
> **Tema: Install Global + Auto-Solve CTF**

**🆕 Fitur Baru**
- `--install-global` — Install ke `/usr/local/bin/raven`.
- `~/.raven/` — Venv & engine disimpan di home directory.
- `--reg`, `--log`, `--autorun`, `--zipcrack`, `--volatility`, `--deobfuscate`, `--folder`.

---

### v2.0 — 2026
> **Tema: Standalone .sh + Stegseek + Brute Force Paralel**

**🆕 Fitur Baru**
- Standalone — Python engine tertanam di dalam `.sh` via heredoc.
- `--stegseek`, `--install`, `--exif`, `--stegdetect`, `--lsbextract`, `--compare`.
- Brute-force paralel dengan `ThreadPoolExecutor`.
- Mode `--quick`.

---

### v1.x — 2025
> **Tema: Tool forensik Python all-in-one**

- Analisis gambar: bit planes, channel RGB, LSB (zsteg), steghide, outguess.
- Auto-repair: magic bytes PNG & JPEG.
- File carving: foremost, binwalk.
- Auto-decode: Base64, Hex, Binary.
- Analisis PCAP + disk image + Windows Event Log.
- Pola flag: `picoCTF{...}`, `CTF{...}`, `flag{...}`.
