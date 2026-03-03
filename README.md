# ForesTools 🕵️‍♂️💻

> **Smart Forensic Toolkit for CTF Challenges** 🔐  
> Alat otomatis untuk analisis file CTF — steganografi, header repair, ekstraksi tersembunyi, network forensics, disk forensics, dan deteksi flag 🚩

**Versi: v2.0** — 🚀 **ULTRA-FAST CTF MODE** - Stegseek + rockyou.txt, parallel brute force, early exit, smart tool selection

---

## 📦 Instalasi

### 1. Clone / Download
```bash
git clone https://github.com/Syaaddd/SForensicsTools.git
cd SForensicsTools
chmod +x forestools.sh
```

### 2. Install Semua Sekaligus (Otomatis) ⚡
```bash
./forestools.sh --install
```
Script akan otomatis menginstall semua tools via `apt` atau `brew`, termasuk **stegseek** dan **rockyou.txt**.

### 3. Install Manual (Opsional)

#### Dependencies Dasar ⚙️
```bash
sudo apt update && sudo apt install -y \
    binwalk libimage-exiftool-perl tesseract-ocr unrar p7zip-full xz-utils \
    python3-pip steghide foremost pngcheck graphicsmagick tshark tcpdump \
    wireshark-common python3-venv wordlists
```

#### Install stegseek (BARU) 🔍
```bash
# Download .deb dari GitHub releases
wget https://github.com/RickdeJager/stegseek/releases/download/v0.6/stegseek_0.6-1.deb
sudo apt install ./stegseek_0.6-1.deb

# Pastikan rockyou.txt tersedia
sudo gunzip /usr/share/wordlists/rockyou.txt.gz
```

#### Install zsteg 💎
```bash
sudo apt install -y ruby ruby-dev
sudo gem install zsteg
```

#### Install outguess 🔍
```bash
sudo apt install -y build-essential libjpeg-dev
wget https://github.com/residentgreg/outguess/archive/refs/heads/master.zip -O outguess.zip
unzip outguess.zip && cd outguess-master
./configure && make && sudo make install
cd .. && rm -rf outguess-master outguess.zip
```

#### Install jpseek/jphs 🖼️
```bash
wget https://downloads.sourceforge.net/project/jphs/jphs/jphs-0.9b.tar.gz
tar -xzf jphs-0.9b.tar.gz && cd jphs-0.9b
make && sudo make install
cd .. && rm -rf jphs-0.9b jphs-0.9b.tar.gz
```

#### Python Dependencies 🐍
Diinstall **otomatis** saat pertama kali menjalankan `forestools.sh`. Atau manual:
```bash
pip install colorama Pillow numpy
```

---

## 📁 Struktur

```
SForensicsTools/
└── forestools.sh     ← Satu file ini sudah cukup! Python engine ada di dalamnya.
```

> **Catatan:** v2.0 adalah standalone — hanya butuh satu file `.sh`. Python engine di-embed otomatis saat dijalankan.

---

## ▶️ Penggunaan

```bash
./forestools.sh [FILE(S)] [OPTIONS]
```

### 📤 Input
```bash
# Satu file
./forestools.sh challenge.png

# Beberapa file / wildcard
./forestools.sh *.png
./forestools.sh secret.jpg data.zip firmware.bin

# Folder rekursif
./forestools.sh /path/to/challenges/

# Dengan format flag custom
./forestools.sh -f "picoCTF{" suspicious.png
```

### 🤖 Mode Analisis
```bash
./forestools.sh image.png --auto      # Auto-detect semua tools sesuai tipe file
./forestools.sh image.png --all       # Jalankan SEMUA analisis
./forestools.sh image.png --quick     # ULTRA-FAST: strings + zsteg + stegseek + early exit
```

### 🔒 Steganografi
```bash
./forestools.sh image.png --lsb        # LSB analysis via zsteg
./forestools.sh image.jpg --steghide   # Steghide extraction (tanpa password)
./forestools.sh image.jpg --stegseek   # Stegseek brute-force dengan rockyou.txt  ← BARU
./forestools.sh image.jpg --outguess   # Outguess extraction (JPEG)
./forestools.sh image.png --pngcheck   # Validasi struktur PNG
./forestools.sh image.jpg --jpsteg     # JPEG steganalysis (jpseek/jphs)
./forestools.sh image.png --foremost   # File carving
./forestools.sh image.png --exif       # Deep EXIF analysis
./forestools.sh image.png --stegdetect # Deteksi metode stego yang digunakan
./forestools.sh image.png --lsbextract # Ekstrak raw LSB bytes
```

### 🔍 Stegseek (BARU — Rockyou Wordlist)
```bash
# Default: pakai rockyou.txt otomatis
./forestools.sh image.jpg --stegseek

# Custom wordlist
./forestools.sh image.jpg --stegseek --wordlist /path/to/wordlist.txt

# Jalan otomatis di --quick, --auto, dan --all
./forestools.sh image.jpg --quick
```

**Stegseek** menggunakan rockyou.txt (~14 juta password) dan **jauh lebih cepat** dari brute force manual:
- Secara otomatis mencari di `/usr/share/wordlists/rockyou.txt`
- Menampilkan password yang ditemukan
- Mengekstrak dan scan konten untuk flag
- Timeout 600 detik untuk file besar

### 🔑 Brute Force (steghide manual)
```bash
./forestools.sh image.png --bruteforce                      # Default wordlist
./forestools.sh image.png --bruteforce --delay 0.05         # Ultra-fast
./forestools.sh image.png --bruteforce --parallel 10        # 10 threads
./forestools.sh image.png --bruteforce --wordlist dict.txt  # Custom wordlist
```

### 🎨 Analisis Gambar Lanjutan
```bash
./forestools.sh image.png --remap            # Color remapping (8 variants)
./forestools.sh image.png --alpha            # Alpha channel analysis
./forestools.sh image.png --deep             # Semua 8 bit plane
./forestools.sh img1.png --compare img2.png  # Bandingkan dua gambar
```

### 🔄 Auto-Decode
```bash
./forestools.sh logs.txt --decode    # Auto-decode base64/hex/binary
./forestools.sh secret.txt --extract # Ekstrak file tersembunyi
```

### 🌐 Network Forensics (PCAP)
```bash
./forestools.sh capture.pcap --pcap  # Full PCAP + attack detection
```

Deteksi otomatis:
- Timeline HTTP requests
- Attack Patterns (SQLi, XSS, LFI/RFI, Command Injection)
- POST data & credentials
- Data exfiltration
- HTTP Objects, DNS Queries, TCP streams

### 💾 Disk Image Analysis
```bash
./forestools.sh disk.img --disk     # Fast mode (scan 10MB pertama)
./forestools.sh forensic.dd --disk  # Format: .dd .img .raw .iso .vmdk .qcow2 .vhd
```

### 🪟 Windows Event Log
```bash
./forestools.sh security.evtx --windows  # Analisis EVTX
./forestools.sh *.evtx --windows
```

---

## 📁 Output Folder

| Folder | Kegunaan |
|--------|----------|
| `*_bitplanes/` | Bit plane visual (0-7) |
| `*_channels/` | RGBA channels terpisah |
| `*_remap/` | Color palette variants |
| `*_stegseek/` | Stegseek brute-force result ← BARU |
| `*_zsteg/`, `*_steghide/`, `*_outguess/` | Output steganography tools |
| `*_foremost/` | File carving results |
| `*_bruteforce/` | Steghide brute force results |
| `*_decoded_*` | Hasil decode (b64/hex/bin) |
| `*_http_objects/`, `*_streams/` | PCAP results |
| `*_disk_analysis/` | Disk image results |
| `*_event_analysis/` | Windows Event Log results |
| `*_lsb_raw/` | Raw LSB bytes |
| `*_compare/` | Image comparison diff |
| `*_exif/` | EXIF metadata |
| `_extracted_*/` | Binwalk extraction |
| `fixed_*`, `repaired_*` | Header yang diperbaiki |

---

## ⚡ Perbandingan Performa

| Fitur | v1.x | v2.0 | Peningkatan |
|-------|------|------|-------------|
| **Stegseek + rockyou** | ❌ | ✅ `--stegseek` | **Sangat cepat** |
| **Quick Mode** | ❌ | ✅ `--quick` | **5-10x** lebih cepat |
| **Brute Force** | Single thread | Parallel threads | **50x** lebih cepat |
| **Early Exit** | ❌ | ✅ Otomatis | Hemat waktu |
| **Standalone .sh** | ❌ | ✅ 1 file saja | Lebih simpel |
| **Auto venv** | ❌ | ✅ Otomatis | Tidak perlu setup |
| **Disk Mode** | Lambat | Fast (10MB scan) | **3-5x** lebih cepat |

---

## 🚀 Cheat Sheet

```bash
# Analisis dasar
./forestools.sh file.png

# QUICK MODE — tercepat untuk CTF
./forestools.sh file.png --quick

# Stegseek dengan rockyou (BARU!)
./forestools.sh file.jpg --stegseek
./forestools.sh file.jpg --stegseek --wordlist /usr/share/wordlists/rockyou.txt

# Steganografi lengkap
./forestools.sh file.png --lsb --deep --alpha
./forestools.sh file.jpg --steghide
./forestools.sh file.jpg --outguess

# Brute force steghide manual
./forestools.sh file.png --bruteforce --parallel 10

# Auto-decode & network
./forestools.sh logs.txt --decode
./forestools.sh capture.pcap --pcap

# Disk & Windows forensics
./forestools.sh disk.img --disk
./forestools.sh security.evtx --windows

# Full analysis
./forestools.sh file.png --all

# Install/update
./forestools.sh --install
./forestools.sh --update-deps
```

---

## 🛠️ Troubleshooting

| Masalah | Solusi |
|---------|--------|
| `Permission denied` | `chmod +x forestools.sh` |
| `Python not found` | `sudo apt install python3` |
| `stegseek not found` | `./forestools.sh --install` |
| `rockyou.txt not found` | `sudo apt install wordlists && sudo gunzip /usr/share/wordlists/rockyou.txt.gz` |
| Dependencies Python error | `./forestools.sh --update-deps` |
| Venv error | Hapus folder `.venv/` lalu jalankan ulang |

---

## 💡 Tips & Trik

- 🔍 Gunakan `--stegseek` untuk JPEG yang kemungkinan punya password — rockyou.txt sangat powerful!
- ✅ Gunakan `--quick` untuk analisis **SUPER CEPAT** saat CTF competition
- 🎯 **Early exit**: Tool otomatis berhenti saat flag ditemukan
- ⚡ Stegseek jauh lebih cepat dari `--bruteforce` untuk file JPEG
- ⚠️ Tools yang tidak terinstall akan dilewati otomatis
- 🔎 Periksa `*_bitplanes/` dan `*_channels/` jika flag tidak terdeteksi otomatis
- 🌐 Untuk `.pcap`, `--pcap` ekstrak HTTP objects, DNS, credentials, dan attack patterns
- 🧪 Coba `--remap` pada gambar dengan noise tinggi — sering menyembunyikan flag di palette!
- 🪟 Untuk `.evtx`, `--windows` analisis installation, execution, dan persistence evidence

---

Dikembangkan oleh **Syaaddd** 👨‍💻 — untuk para pejuang CTF! 🏆🚩  
[GitHub Repository](https://github.com/Syaaddd/SForensicsTools) 💻✨
