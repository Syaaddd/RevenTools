<div align="center">

# 🐦‍⬛ RAVEN CTF Toolkit

**Toolkit Otomasi CTF Multi-Kategori yang Cerdas**

[![Version](https://img.shields.io/badge/version-v6.0-blue?style=for-the-badge&logo=github)](https://github.com/Syaaddd/raven-ctf)
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-orange?style=for-the-badge&logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Python](https://img.shields.io/badge/python-3.8%2B-yellow?style=for-the-badge&logo=python)](https://www.python.org/)
[![Platform](https://img.shields.io/badge/platform-Linux-lightgrey?style=for-the-badge&logo=linux)](https://www.linux.org/)
[![CTF](https://img.shields.io/badge/CTF-ready-red?style=for-the-badge&logo=hackthebox)](https://github.com/Syaaddd/raven-ctf)
[![Learning](https://img.shields.io/badge/Learning%20Guide-Included-purple?style=for-the-badge&logo=bookstack)](docs/CTF_FUNDAMENTALS.md)

*Alat otomatis untuk semua kategori CTF — forensics, steganografi, kriptografi, network, memory forensics, binary analysis, dan deteksi flag* 🚩

[📦 Instalasi](#-instalasi) · [▶️ Penggunaan](#️-penggunaan) · [📚 Learning Guide](#-learning-guide-new) · [📁 Output](#-output-folder) · [🆕 Changelog](#-changelog)

</div>

---

## 🔍 Tentang RAVEN

RAVEN adalah toolkit CTF berbasis Bash + Python yang dirancang untuk mempercepat proses analisis challenge. Mulai dari steganografi gambar, forensics memori, network PCAP, binary reversing, hingga decoding binary digits, morse code, dan decimal ASCII — semua terintegrasi dalam **satu standalone script**.

**🆕 v6.0 — Modular Architecture & CTF Learning Guide**

RAVEN v6.0 introduces:
- **🎓 CTF Learning Guide** — Complete roadmap from beginner to advanced (see [Learning Guide](#-learning-guide-new))
- **🧩 Modular Architecture** — Cleaner code structure for maintainability
- **📚 Quick Reference** - Per-category command cheatsheets (see [Quick Reference](docs/QUICK_REFERENCE.md))
- **🔧 Enhanced Documentation** - Better code clarity and error handling
- All features from v5.2 plus improved organization

**Kategori yang didukung:**

| Kategori | Tools |
|----------|-------|
| 🔢 Binary Digits | 8-bit MSB/LSB, 7-bit ASCII, image rendering, bit reversal |
| 📡 Morse Code | Full morse decoder (A-Z, 0-9, punctuation) |
| 🔢 Decimal ASCII | Decimal to ASCII converter (space/comma separated) |
| 🖼️ Steganografi | zsteg, steghide, stegseek, outguess, LSB, WAV stego, appended data |
| 🔐 Unicode Stego | Zero-width character detection & decoding (\u200b, \u200c, \u200d, \ufeff) |
| 🔬 Forensics | foremost, binwalk, exiftool, pngcheck |
| 🌐 Network | tshark, PCAP analysis, HTTP objects, DNS tunneling |
| 🧠 Memory | Volatility 3 pipeline, advanced memory analysis |
| 🔒 Cryptography | RSA (small-e, Fermat, weak prime, common mod), Vigenere, XOR, Substitution, Caesar, Atbash |
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
├── raven.sh                    ← Main entry point (Bash wrapper)
├── README.md                   ← Main documentation
├── NEW_FEATURES_V6.md          ← Changelog for v6.0
├── KonsepUpdate.txt            ← Development roadmap
├── engine/                     ← Python engine modules (modular)
│   ├── __init__.py
│   ├── core.py                 ← Core utilities (flags, logging, tools)
│   ├── learning.py             ← CTF learning mode
│   └── ...                     ← Other modules (future)
├── docs/                       ← Documentation
│   ├── CTF_FUNDAMENTALS.md     ← Complete learning guide
│   └── QUICK_REFERENCE.md      ← Command cheatsheets
└── wordlists/
    └── ctf_passwords.txt       ← CTF-optimized wordlist

~/.raven/                       ← Data runtime (dibuat otomatis)
└── engine/                     ← Installed engine modules

/usr/local/bin/raven            ← Binary global (setelah --install-global)
```

---

## 📚 Learning Guide (NEW!)

**RAVEN sekarang termasuk panduan belajar lengkap untuk menguasai CTF!**

### Quick Start Learning
```bash
# Tampilkan roadmap belajar lengkap
raven --learn

# Fokus pada topik tertentu
raven --learn crypto            # Kriptografi
raven --learn web               # Web exploitation
raven --learn pwn               # Binary exploitation
raven --learn forensics         # Forensics
raven --learn reverse           # Reverse engineering
raven --learn list              # Tampilkan semua kategori
```

### Learning Resources

| Resource | Description |
|----------|-------------|
| 📖 **[CTF Fundamentals](docs/CTF_FUNDAMENTALS.md)** | Panduan lengkap dari beginner hingga advanced |
| 🚀 **[Quick Reference](docs/QUICK_REFERENCE.md)** | Cheatsheet perintah per kategori |
| 🎯 **Interactive Learning** | Gunakan `raven --learn` untuk panduan interaktif |

### Learning Path Overview

**Phase 1** - Getting Started (7-9 weeks)
- Linux & Command Line
- Python Scripting
- Number Systems & Encoding
- Basic Networking
- CTF Platforms & Format

**Phase 2** - Web Exploitation (8-12 weeks)
- SQL Injection, XSS, SSRF, Authentication Attacks

**Phase 3** - Cryptography (10-16 weeks)
- Classical Ciphers, Modern Crypto, RSA, Hashing

**Phase 4** - Binary Exploitation (14-22 weeks)
- Assembly, Buffer Overflow, ROP, Heap Exploitation

**Phase 5** - Reverse Engineering (12-20 weeks)
- Static/Dynamic Analysis, Anti-Reverse, Binary Formats

**Phase 6** - Forensics & Misc (10-16 weeks)
- File Analysis, Memory/Disk Forensics, Steganography, OSINT

> 💡 **Tip:** Lihat [CTF_FUNDAMENTALS.md](docs/CTF_FUNDAMENTALS.md) untuk panduan detail dengan contoh perintah RAVEN!

---

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

#### 🔢 Binary Digits, Morse & Decimal (v5.1)
```bash
raven binary.txt --binary                 # Analisis binary digits (0/1)
raven binary.txt --binary --bin-width 64  # Render gambar dengan lebar 64px
raven morse.txt --morse                   # Decode morse code
raven decimal.txt --decimal               # Decode decimal ASCII (70 76 65 71 → FLAG)
# Auto-detection: file dengan >90% karakter 0/1 akan otomatis dianalisis
```

**Binary Digits Features:**
- **8-bit MSB ASCII** — Konversi binary standar (Most Significant Bit first)
- **8-bit LSB ASCII** — Bit-reversed per byte (Least Significant Bit first)
- **7-bit ASCII** — Interpretasi 7-bit ASCII alternatif
- **Full String Reversal** — Reverse seluruh bit string sebelum konversi
- **Image Rendering** — Konversi binary ke gambar hitam-putih (multiple widths: 8-512px)
- **Auto-detection** — Otomatis detect file binary (>90% karakter 0/1, >50 bits)

**Morse Code Features:**
- Full morse code dictionary (A-Z, 0-9, punctuation)
- Word separation dengan '/'
- Auto-detection pola morse dalam file
- Flag scanning dalam output yang didecode

**Decimal ASCII Features:**
- Decimal ke ASCII conversion (values 32-126)
- Handles space dan comma separated values
- Auto-detection pola decimal
- Printable ratio validation (>70% required)

#### 🔒 Cryptography Engine
```bash
raven chall.txt --crypto                # Auto-attack semua: RSA, Vigenere, XOR, Substitution, Classic, Chain
raven rsa_chall.txt --crypto --rsa      # Fokus serangan RSA (small-e, weak prime, Fermat, Common-Modulus, Bellcore)
raven cipher.txt --crypto --vigenere    # Vigenere + akrostik key finder
raven secret.txt --classic              # Atbash + Caesar brute (1-25)
raven enc.bin --xor-plain "CTF{"        # XOR KPA dengan known-plaintext prefix
raven enc.bin --xor-key "DARKSIDE"      # XOR decrypt manual dengan key
raven encoded.txt --encoding-chain      # Multi-stage decode (Base32→Binary→BitRev→B64)
```

**🆕 Crypto Features v5.2:**
- **RSA Small Exponent Attack** — Otomatis attack untuk e=3, 5, 7 (sangat umum di CTF pemula)
- **Substitution Cipher Auto** — Frequency analysis English & Indonesian untuk cipher substitusi
- **Auto-Detection** — Otomatis detect tipe cipher dan pilih attack yang sesuai

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

**🆕 Steganography Features v5.2:**
- **Appended Data Detection** — Otomatis detect data setelah EOF marker (PNG IEND, JPEG FFD9, ZIP EOCD)
- **WAV Steganography** — LSB extraction dari sample audio file WAV (umum di CTF nasional)
- **Zero-Width Character Detection** — Decode steganografi Unicode dalam text file
- **Auto-Detection** — Semua fitur terintegrasi dengan auto-detection engine

### 🔑 Brute Force
```bash
raven image.png --bruteforce
raven image.png --bruteforce --parallel 10
raven image.png --bruteforce --wordlist dict.txt
raven image.jpg --stegseek --wordlist rockyou.txt
raven image.jpg --stegseek --wordlist wordlists/ctf_passwords.txt  # 🆕 CTF-optimized wordlist
```

**🆕 Brute Force Features v5.2:**
- **CTF Wordlist** — 100 passwords teroptimasi untuk kompetisi (jauh lebih cepat dari rockyou.txt)
- **Auto-Integration** — CTF wordlist otomatis digunakan di semua mode brute force

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
| `*_binary_images/` | Binary digits rendered as images |
| `*_decoded_morse/` | Morse code decoded output |
| `*_decoded_decimal/` | Decimal ASCII decoded output |
| `*_appended/` | Data found after EOF markers (PNG/JPEG/ZIP/GIF) |
| `*_wav_stego/` | WAV LSB steganography extraction results |
| `*_unicode_stego/` | Zero-width character steganography decoded |

---

## ⚡ Perbandingan Versi

| Fitur | v1.x | v2.0 | v3.0 | v4.0 | v5.0 | v5.1 | v5.2 |
|-------|------|------|------|------|------|------|------|
| **Global install** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Interactive Menu** | ❌ | ❌ | ❌ | ❌ | ✅ Default | ✅ | ✅ |
| **3 TUI Modes (select/whiptail/fzf)** | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| **Reversing Module** | ❌ | ❌ | ❌ | ❌ | ✅ `--reversing` | ✅ | ✅ |
| **Packer Detection (UPX/etc)** | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| **Ghidra Integration** | ❌ | ❌ | ❌ | ❌ | ✅ `--ghidra` | ✅ | ✅ |
| **Crypto engine (RSA/Vigenere/XOR)** | ❌ | ❌ | ❌ | ✅ | ✅ `--crypto` | ✅ | ✅ |
| **RSA Small-e Attack** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ `--crypto` |
| **Substitution Cipher Auto** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ `--crypto` |
| **Appended Data Detection** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Auto |
| **WAV Steganography** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Auto |
| **Zero-Width Character Detect** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Auto |
| **CTF Wordlist** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Advanced memory analysis** | ❌ | ❌ | ❌ | ✅ | ✅ `--memory` | ✅ | ✅ |
| **NTFS deleted file recovery** | ❌ | ❌ | ❌ | ✅ | ✅ `--ntfs` | ✅ | ✅ |
| **Partition table scan** | ❌ | ❌ | ❌ | ✅ | ✅ `--partition` | ✅ | ✅ |
| **DNS tunneling detector** | ❌ | ❌ | ❌ | ✅ | ✅ `--dns-tunnel` | ✅ | ✅ |
| **Binary Digits Analysis** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ `--binary` | ✅ |
| **Binary → Image Rendering** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ `--bin-width` | ✅ |
| **Morse Code Decoder** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ `--morse` | ✅ |
| **Decimal ASCII Decoder** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ `--decimal` | ✅ |
| **Auto-Detection Engine** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ Enhanced |
| **PDF Password Crack** | ❌ | ❌ | ❌ | ❌ | ✅ `--pdfcrack` | ✅ | ✅ |
| **John the Ripper** | ❌ | ❌ | ❌ | ❌ | ✅ `--john` | ✅ | ✅ |
| **Hashcat** | ❌ | ❌ | ❌ | ❌ | ✅ `--hashcat` | ✅ | ✅ |
| **Stegseek + rockyou** | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **ZIP password crack** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Registry analysis** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Log analysis** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Volatility wrapper** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Deobfuscation engine** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Fake ext detection** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Quick Mode** | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Parallel brute force** | ❌ | ✅ 5t | ✅ 5t | ✅ 5t | ✅ 5t | ✅ 5t | ✅ 5t |
| **Standalone .sh** | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

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
- 🎓 **Belajar CTF?** Gunakan `raven --learn` untuk panduan lengkap!
- 📚 Lihat [docs/CTF_FUNDAMENTALS.md](docs/CTF_FUNDAMENTALS.md) untuk roadmap belajar
- 🚀 Cek [docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md) untuk cheatsheet perintah
- 🔢 File dengan hanya 0/1? Auto-detect binary digits + render gambar!
- 📡 Morse code dalam file? `--morse` langsung decode dengan flag detection
- 🔢 Angka decimal (70 76 65 71)? `--decimal` konversi ke ASCII otomatis
- 🔒 `--crypto` untuk otomatis menyerang semua jenis enkripsi sekaligus — RSA (small-e!), Vigenere, XOR, Substitution, Caesar
- 🆕 File RSA dengan e=3? Auto small-e attack langsung jalan!
- 🆕 Text cipher panjang tanpa spasi? Substitution cipher auto frequency analysis!
- 💡 `--xor-plain` powerful untuk soal yang tahu prefix flag-nya (e.g. `--xor-plain "picoCTF{"`)
- 🔍 `--stegseek` jauh lebih cepat dari `--bruteforce` untuk JPEG
- 🆕 Image dengan data appended setelah EOF? Auto-detect + extract!
- 🆕 File WAV? Auto LSB steganography extraction!
- 🆕 Text file dengan zero-width characters? Auto decode steganografi Unicode!
- 🆕 Gunakan `wordlists/ctf_passwords.txt` untuk brute force 100x lebih cepat dari rockyou!
- 🗂️ `--folder` untuk soal yang kasih banyak file — auto-detect fake extension
- 🧠 `--volatility` untuk pipeline standar; `--memory` untuk analisis lebih dalam (malfind, dump)
- 💽 `--ntfs` untuk recover file yang dihapus dari disk image NTFS
- 🌐 `--dns-tunnel` deteksi dan decode data tersembunyi dalam query DNS
- 🔤 `--deobfuscate` coba semua metode encode sekaligus — reverse, ROT13, caesar 1-25, atbash, b64, hex
- 📋 `--reg` decode semua nilai `hex:` di `.reg` — sering menyembunyikan flag di RunOnce
- 🌐 `--log` deteksi request 200-OK attacker — flag sering di URL path
- 🔎 Periksa `*_bitplanes/` jika flag tidak terdeteksi otomatis di gambar
- 🖼️ Periksa `*_binary_images/` untuk hasil render binary → gambar
- 🆕 Periksa `*_appended/`, `*_wav_stego/`, `*_unicode_stego/` untuk data tersembunyi

---

## 🇺🇸 English

### 🔍 About RAVEN

RAVEN is a Bash + Python CTF toolkit designed to accelerate challenge analysis. From image steganography and memory forensics to network PCAPs, binary analysis, and encoding decoding — all integrated into a **standalone script architecture**.

### 🚀 Quick Start

```bash
git clone https://github.com/Syaaddd/raven-ctf.git
cd raven-ctf && chmod +x raven.sh
./raven.sh --install-global   # Install globally
./raven.sh --install          # Install all system tools
raven challenge.png --auto    # Analyze your first challenge
```

### Key Features (v6.0)

| Feature | Command | Description |
|---------|---------|-------------|
| 🎓 **CTF Learning Guide** | `--learn` | Complete roadmap from beginner to advanced |
| 📚 **Quick Reference** | [docs/](docs/) | Per-category command cheatsheets |
| 🔢 Binary Digits | `--binary` | Binary (0/1) to ASCII, image rendering, flag scan |
| 📡 Morse Code | `--morse` | Full morse code decoder with flag detection |
| 🔢 Decimal ASCII | `--decimal` | Decimal-encoded ASCII decoder |
| 🎯 Interactive Menu | (default) | Multi-select: 3 TUI modes (select/whiptail/fzf) |
| 🔧 Binary Reversing | `--reversing` | strings, objdump, readelf, packer detection |
| 📦 UPX Unpacker | `--unpack` | Auto-detect and unpack UPX packed binaries |
| 🔬 Ghidra Integration | `--ghidra` | Headless Ghidra analysis (requires Ghidra) |
| 🔒 Crypto Engine | `--crypto` | RSA (small-e!), Vigenere, XOR, Substitution, Encoding Chain |
| 🔐 RSA Small-e Attack | `--crypto` | Auto attack for e=3,5,7 (very common in CTF) |
| 🔤 Substitution Cipher | `--crypto` | Frequency analysis (English & Indonesian) |
| 🖼️ Appended Data | Auto | Detect data after EOF (PNG/JPEG/ZIP/GIF) |
| 🎵 WAV Steganography | Auto | LSB extraction from audio samples |
| 🔣 Unicode Stego | Auto | Zero-width character detection & decoding |
| 🧠 Adv. Memory | `--memory` | Advanced Volatility: malfind, process dump, anomaly detection |
| 💽 NTFS Recovery | `--ntfs` | NTFS deleted file recovery (fls/icat/strings) |
| 🗂️ Partition Scan | `--partition` | MBR/GPT partition analysis |
| 🌐 DNS Tunnel | `--dns-tunnel` | DNS tunneling detector + decoder |
| 📄 PDF Cracker | `--pdfcrack` | PDF password cracking with wordlist |
| 🔑 John the Ripper | `--john` | Hash cracking with John the Ripper |
| 🔑 Hashcat | `--hashcat` | Hash cracking with Hashcat |
| 📝 CTF Wordlist | Auto | 100 optimized CTF passwords (100x faster!) |

### Environment Variables

```bash
export RAVEN_THREADS=5                   # Brute force thread count (default: 5)
export RAVEN_WORDLIST="/path/to/list"    # Custom wordlist path
```

---

## 📋 Changelog

### v5.2 — 2026
> **Theme: Advanced Crypto Attacks, Steganography Enhancements & Unicode Stego**

**🆕 New Features**
- **RSA Small Exponent Attack** — Otomatis attack untuk e=3, 5, 7 (sangat umum di CTF pemula)
- **Substitution Cipher Auto** — Frequency analysis English & Indonesian untuk cipher substitusi
- **Appended Data Detection** — Deteksi dan extract data setelah EOF marker (PNG IEND, JPEG FFD9, ZIP EOCD, GIF trailer)
- **WAV Steganography** — LSB extraction dari sample audio file WAV (umum di CTF nasional)
- **Zero-Width Character Detection** — Decode steganografi Unicode (\u200b, \u200c, \u200d, \ufeff, \u2060, \u180e)
- **CTF-Optimized Wordlist** — 100 passwords teroptimasi untuk kompetisi (100x lebih cepat dari rockyou.txt)
- **Enhanced Auto-Detection** — 3 modul deteksi otomatis tambahan: Appended Data, WAV Stego, Unicode Stego

**🐛 Bug Fixes**
- **Fixed `repaired` variable scope bug** di `analyze_crypto_file` (critical bug yang menyebabkan crash)
- **Improved error handling** di semua fungsi baru
- **Enhanced logging** untuk semua analisis

**🔧 Technical Implementation**
- 7 new analysis functions: `rsa_small_e_attack()`, `substitution_cipher_auto()`, `detect_appended_data()`, `analyze_wav_steganography()`, `detect_hidden_unicode()`
- Auto-detection dengan early exit untuk semua fitur baru
- Full integration dengan existing flag scanner dan tool logging
- ~600+ lines of code added
- Integrated ke semua mode: --auto, --all, --crypto, selective

**📊 New Output Folders**
```
{file}_appended/        # Data after EOF markers
{file}_wav_stego/       # WAV LSB extraction results
{file}_unicode_stego/   # Zero-width character decoded
wordlists/              # CTF-optimized wordlist
```

**🎯 Competition Ready**
- Semua fitur auto-detect berdasarkan konten file
- Flag scanning otomatis di semua output
- Tool logging untuk tracking analisis
- Compatible dengan semua mode yang sudah ada

---

### v5.1 — 2026
> **Theme: Binary Digits, Morse Code & Decimal ASCII Analysis**

**🆕 New Features**
- **Binary Digits Analysis** — Deteksi dan decode file berisi 0/1 (8-bit MSB/LSB, 7-bit ASCII, reversal)
- **Binary → Image Rendering** — Konversi binary ke gambar hitam-putih dengan multiple widths (8-512px)
- **Morse Code Decoder** — Decode morse code lengkap (A-Z, 0-9, punctuation) dengan flag detection
- **Decimal ASCII Decoder** — Decode decimal-encoded ASCII (space/comma separated) dengan printable ratio validation
- **Auto-Detection Engine** — 3 modul deteksi otomatis: Binary (>90% 0/1, >50 bits), Morse (pattern match), Decimal (pattern match)
- **PDF Password Cracking** — Crack PDF password dengan pdfcrack + wordlist
- **John the Ripper Integration** — Crack hash dengan John the Ripper
- **Hashcat Integration** — Crack hash dengan Hashcat (supports various hash types)
- **Enhanced CLI Flags** — `--binary`, `--bin-width`, `--morse`, `--decimal`, `--pdfcrack`, `--john`, `--hashcat`, `--hash-type`

**🔧 Technical Implementation**
- 4 new analysis functions: `analyze_binary_digits()`, `_render_binary_as_image()`, `analyze_morse()`, `analyze_decimal_ascii()`
- Auto-detection dengan early exit untuk binary (efficient processing)
- Image rendering menggunakan PIL/Pillow (`Image.new('1', ...)`)
- Full integration dengan existing flag scanner dan tool logging
- ~300+ lines of code added to Python engine

**📊 Detection Flow**
```
INPUT FILE → Binary? (>90% 0/1) → YES → analyze_binary() → render images → DONE
           → Morse? (pattern) → YES → analyze_morse() → continue
           → Decimal? (pattern) → YES → analyze_decimal() → continue
```

**🔧 Improvements**
- Backward compatible: semua flag CLI dan fitur v5.0 tetap berfungsi
- Standalone architecture: semua Python code tetap dalam 1 file `raven.sh` (~6700 baris)
- Enhanced auto-detection untuk challenge berbasis encoding

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
