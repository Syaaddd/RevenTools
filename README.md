# ForesTools 🕵️‍♂️💻

> **Smart Forensic Toolkit for CTF Challenges** 🔐  
> Alat otomatis untuk analisis file CTF — steganografi, header repair, ekstraksi tersembunyi, network forensics, disk forensics, dan deteksi flag 🚩

**Versi: v2.0** — 🚀 **ULTRA-FAST CTF MODE** - Parallel brute force, early exit mechanism, smart tool selection 🔄⚡

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
Script akan otomatis menginstall semua tools yang dibutuhkan via `apt` atau `brew`.

### 3. Install Manual (Opsional)

#### Dependencies Dasar ⚙️
```bash
sudo apt update && sudo apt install -y \
    binwalk libimage-exiftool-perl tesseract-ocr unrar p7zip-full xz-utils \
    python3-pip steghide foremost pngcheck graphicsmagick tshark tcpdump \
    wireshark-common python3-venv
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
Diinstall **otomatis** saat pertama kali menjalankan `forestools.sh` via virtual environment. Atau manual:
```bash
pip install colorama Pillow numpy
```

---

## 📁 Struktur File

```
SForensicsTools/
├── forestools.sh     <- Launcher utama (jalankan ini!)
└── ForesTools.py     <- Python engine (harus ada di folder yang sama)
```

> **Penting:** Kedua file harus berada di folder yang sama.

---

## ▶️ Penggunaan

### Cara Menjalankan
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

# Dengan format flag hint
./forestools.sh -f "picoCTF{" suspicious.png
```

### 🤖 Mode Analisis
```bash
./forestools.sh image.png --auto      # Auto-detect & jalankan tools sesuai tipe file
./forestools.sh image.png --all       # Jalankan SEMUA analisis
./forestools.sh image.png --quick     # ULTRA-FAST: Quick scan + early exit
```

### 🔒 Steganografi
```bash
./forestools.sh image.png --lsb        # LSB analysis (zsteg)
./forestools.sh image.jpg --steghide   # Ekstrak steghide
./forestools.sh image.jpg --outguess   # Outguess extraction
./forestools.sh image.png --pngcheck   # Validasi PNG
./forestools.sh image.jpg --jpsteg     # JPEG steganalysis
./forestools.sh image.png --foremost   # File carving
./forestools.sh image.png --exif       # Deep EXIF analysis
./forestools.sh image.png --stegdetect # Deteksi metode stego yang digunakan
./forestools.sh image.png --lsbextract # Ekstrak raw LSB bytes
```

### 🔑 Brute Force (PARALLEL)
```bash
./forestools.sh image.png --bruteforce                      # Fast mode (0.1s delay, 5 threads)
./forestools.sh image.png --bruteforce --delay 0.05         # Ultra-fast (50ms delay)
./forestools.sh image.png --bruteforce --parallel 10        # 10 parallel threads
./forestools.sh image.png --bruteforce --wordlist dict.txt  # Custom wordlist
```

### 🎨 Analisis Gambar Lanjutan
```bash
./forestools.sh image.png --remap            # Color remapping (8 variants)
./forestools.sh image.png --alpha            # Alpha channel analysis
./forestools.sh image.png --deep             # Full bit plane (0-7)
./forestools.sh img1.png --compare img2.png  # Bandingkan dua gambar
```

### 🔄 Auto-Decode
```bash
./forestools.sh logs.txt --decode    # Auto-decode base64/hex/binary
./forestools.sh secret.txt --extract # Ekstrak semua file tersembunyi
```

### 🌐 Network Forensics (PCAP)
```bash
./forestools.sh capture.pcap --pcap  # Analisis full PCAP dengan attack detection
```

**PCAP Analysis** secara otomatis mendeteksi:
- **Timeline Analysis** — Melacak HTTP requests berdasarkan waktu
- **Attack Patterns** — SQL Injection, XSS, LFI/RFI, Command Injection
- **POST Data Analysis** — Mencari flag dan credentials dalam POST requests
- **Data Exfiltration** — Mendeteksi data yang dicuri attacker
- **HTTP Objects** — Ekstrak file dari traffic
- **DNS Queries** — Analisis query mencurigakan
- **Credentials** — Mencari login/password via FTP, HTTP Basic Auth, Telnet

### 💾 Disk Image Analysis (FAST MODE)
```bash
./forestools.sh disk.img --disk     # Analisis cepat disk image dengan strings
./forestools.sh forensic.dd --disk  # Auto-detect format (.dd, .img, .raw, .iso, .vmdk, .qcow2, .vhd)
./forestools.sh challenge.img --all # Full analysis dengan semua tools
```

Catatan performa disk mode:
- Scan hanya 10MB pertama untuk file signatures
- String minimum 8 karakter (mengurangi noise)
- Limit hasil keyword dan embedded files

### 🪟 Windows Event Log Analysis
```bash
./forestools.sh security.evtx --windows  # Analisis Windows Event Logs
./forestools.sh *.evtx --windows         # Analisis semua file event log
./forestools.sh logs/ --windows          # Analisis folder berisi event logs
```

**Windows Event Log Analysis** secara otomatis mendeteksi:
- **Installation Evidence** — Mencari bukti instalasi software (MSI, setup, install)
- **Execution Evidence** — Mencari cmd.exe, powershell.exe, process start
- **Shutdown Evidence** — Mencari EventID 6008, 1074, shutdown events
- **Logon Evidence** — Mencari EventID 4624, 4625 (logon success/fail)
- **Flag Extraction** — Mencari flag tersembunyi dalam event log

---

## 📁 Output Folder

| Folder | Kegunaan |
|--------|----------|
| `*_bitplanes/` | Bit plane visual (0-7) |
| `*_channels/` | RGBA channels terpisah |
| `*_remap/` | Color palette variants |
| `*_zsteg/`, `*_steghide/`, `*_outguess/` | Output steganography tools |
| `*_foremost/` | File carving results |
| `*_bruteforce/` | Brute force results |
| `*_decoded_*` | Hasil decode (b64/hex/bin) |
| `*_http_objects/`, `*_streams/` | PCAP analysis results |
| `*_disk_analysis/` | Disk image analysis results |
| `*_event_analysis/` | Windows Event Log analysis results |
| `*_lsb_raw/` | Raw LSB extracted bytes |
| `*_compare/` | Image comparison diff |
| `*_exif/` | EXIF metadata export |
| `_extracted_*/` | Binwalk extraction |
| `fixed_*`, `repaired_*` | Repaired headers |

---

## ⚡ Perbandingan Performa

| Fitur | v1.x | v2.0 | Peningkatan |
|-------|------|------|-------------|
| **Quick Mode** | ❌ | ✅ `--quick` | **5-10x** lebih cepat |
| **Brute Force** | Single thread | Parallel threads | **50x** lebih cepat |
| **Early Exit** | ❌ | ✅ Otomatis | Hemat waktu |
| **Shell Launcher** | ❌ | ✅ `forestools.sh` | Lebih mudah dijalankan |
| **Auto venv** | ❌ | ✅ Otomatis | Tidak perlu setup manual |
| **Disk Mode** | Lambat | Fast (10MB scan) | **3-5x** lebih cepat |

---

## 🚀 Cheat Sheet

```bash
# Analisis dasar
./forestools.sh file.png

# QUICK MODE - Sangat cepat untuk CTF competition!
./forestools.sh file.png --quick

# Steganografi
./forestools.sh file.png --lsb --deep --alpha
./forestools.sh file.jpg --steghide
./forestools.sh file.jpg --outguess

# Brute force
./forestools.sh file.png --bruteforce                  # Default fast mode
./forestools.sh file.png --bruteforce --parallel 10    # 10 threads max speed

# Auto-decode & network
./forestools.sh logs.txt --decode
./forestools.sh capture.pcap --pcap

# Disk forensics
./forestools.sh disk.img --disk

# Windows Event Log forensics
./forestools.sh security.evtx --windows

# Full analysis
./forestools.sh file.png --all

# Install/update tools & deps
./forestools.sh --install
./forestools.sh --update-deps
```

---

## 🛠️ Troubleshooting

| Masalah | Solusi |
|---------|--------|
| `Permission denied` | `chmod +x forestools.sh` |
| `Python not found` | Install Python 3.8+: `sudo apt install python3` |
| `ForesTools.py not found` | Pastikan kedua file ada di folder yang sama |
| Tool tertentu tidak jalan | Jalankan `./forestools.sh --install` |
| Dependencies Python error | Jalankan `./forestools.sh --update-deps` |
| Venv error | Hapus folder `.venv/` lalu jalankan ulang |

---

## 💡 Tips & Trik

- ✅ Gunakan `--quick` untuk analisis **SUPER CEPAT** saat CTF competition
- 🎯 **Early exit**: Tool otomatis berhenti saat flag ditemukan — hemat waktu!
- ⚡ Brute force paralel: Gunakan `--parallel 10` untuk speed maksimum
- ⚠️ Tools yang tidak terinstall akan otomatis dilewati — tidak perlu khawatir
- 🔎 Periksa folder `*_bitplanes/` dan `*_channels/` jika flag tidak ditemukan otomatis
- 🌐 Untuk `.pcap`, `--pcap` akan mengekstrak HTTP objects, DNS queries, credentials, dan mendeteksi attack patterns (SQLi, XSS, LFI, dll.)
- 💾 Untuk disk image (`.img`, `.dd`, `.raw`), `--disk` menggunakan fast mode dengan scan 10MB pertama
- 🧪 Coba `--remap` pada gambar dengan noise tinggi — sering menyembunyikan flag di palette warna!
- 🪟 Untuk `.evtx`, gunakan `--windows` untuk menganalisis bukti installation, execution, dan persistence mechanism

---

Dikembangkan oleh **Syaaddd** 👨‍💻 — untuk para pejuang CTF! 🏆🚩  
[GitHub Repository](https://github.com/Syaaddd/SForensicsTools) 💻✨
