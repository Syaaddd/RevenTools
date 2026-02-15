# SForensicsTools 🕵️‍♂️💻

> **Smart Forensic Toolkit for CTF Challenges** 🔐  
> Alat otomatis untuk analisis file CTF — steganografi, header repair, ekstraksi tersembunyi, network forensics, disk forensics, dan deteksi flag 🚩

**Versi: v2.5** — Mendukung steganography tools, network forensics (PCAP) 🌐 dengan attack detection, disk forensics 💾, Windows Event Log analysis 🪟, dan auto-decode 🔄

---

## 📦 Instalasi

### 1. Dependencies Dasar ⚙️
```bash
sudo apt update && sudo apt install -y \
    binwalk libimage-exiftool-perl tesseract-ocr unrar p7zip-full xz-utils \
    python3-pip steghide foremost pngcheck graphicsmagick tshark tcpdump wireshark-common
```

### 2. Install zsteg 💎
```bash
sudo apt install -y ruby ruby-dev
sudo gem install zsteg
```

### 3. Install outguess 🔍
```bash
sudo apt install -y build-essential libjpeg-dev
wget https://github.com/residentgreg/outguess/archive/refs/heads/master.zip -O outguess.zip
unzip outguess.zip && cd outguess-master
./configure && make && sudo make install
cd .. && rm -rf outguess-master outguess.zip
```

### 4. Install jpseek/jphs 🖼️
```bash
wget https://downloads.sourceforge.net/project/jphs/jphs/jphs-0.9b.tar.gz
tar -xzf jphs-0.9b.tar.gz && cd jphs-0.9b
make && sudo make install
cd .. && rm -rf jphs-0.9b jphs-0.9b.tar.gz
```

### 5. Python Dependencies 🐍
```bash
pip install colorama Pillow numpy
```

### 6. Setup Executable ⚡
```bash
chmod +x ForesTools.py
sudo cp ForesTools.py /usr/local/bin/sfores
```

---

## ▶️ Penggunaan

### 📤 Input
```bash
# Satu file
fores challenge.png

# Beberapa file / wildcard
fores *.png
fores secret.jpg data.zip firmware.bin

# Folder rekursif 📁
fores /path/to/challenges/

# Dengan format flag hint 🚩
fores -f "picoCTF{" suspicious.png
```

### 🤖 Mode Analisis
```bash
fores image.png --auto      # Auto-detect & jalankan tools sesuai tipe file 🧠
fores image.png --all       # Jalankan SEMUA analisis 🔥
```

### 🔒 Steganografi
```bash
fores image.png --lsb        # LSB analysis (zsteg) 🔍
fores image.jpg --steghide   # Ekstrak steghide 🗝️
fores image.jpg --outguess   # Outguess extraction 🕸️
fores image.png --pngcheck   # Validasi PNG ✅
fores image.jpg --jpsteg     # JPEG steganalysis 🖼️
fores image.png --foremost   # File carving 🔪
```

### 🔑 Brute Force
```bash
fores image.png --bruteforce                    # Default (5s delay, 80 passwords) ⏳
fores image.png --bruteforce --delay 10         # Delay custom ⏱️
fores image.png --bruteforce --wordlist dict.txt # Custom wordlist 📖
```

### 🎨 Analisis Gambar Lanjutan
```bash
fores image.png --remap       # Color remapping (8 variants) 🌈
fores image.png --alpha       # Alpha channel analysis 💎
fores image.png --deep        # Full bit plane (0-7) 🔬
```

### 🔄 Auto-Decode
```bash
fores logs.txt --decode       # Auto-decode base64/hex/binary 🔠
fores secret.txt --extract    # Ekstrak semua file tersembunyi 📦
```

### 🌐 Network Forensics (PCAP)
```bash
fores capture.pcap --pcap     # Analisis full PCAP dengan attack detection 📡
```

**PCAP Analysis** secara otomatis mendeteksi:
- **Timeline Analysis** - Melacak HTTP requests berdasarkan waktu ⏱️
- **Attack Patterns** - SQL Injection, XSS, LFI/RFI, Command Injection ⚔️
- **POST Data Analysis** - Mencari flag dan credentials dalam POST requests 📤
- **Data Exfiltration** - Mendeteksi data yang dicuri attacker 📥
- **HTTP Objects** - Ekstrak file dari traffic 📦
- **DNS Queries** - Analisis query mencurigakan 🌐
- **Credentials** - Mencari login/password 🔑

### 💾 Disk Image Analysis (FAST MODE)
```bash
fores disk.img --disk         # Analisis cepat disk image dengan strings 🔍⚡
fores forensic.dd --disk      # Auto-detect format disk (.dd, .img, .raw, .iso, .vmdk, .qcow2, .vhd) 💿
fores challenge.img --all     # Full analysis dengan semua tools 🔥

# Catatan: Mode disk sekarang 3-5x lebih cepat!
# - Scan hanya 10MB pertama untuk file signatures
# - String minimum 8 karakter (mengurangi noise)
# - Limit hasil keyword dan embedded files
```

### 🪟 Windows Event Log Analysis
```bash
fores security.evtx --windows    # Analisis Windows Event Logs 🪟
fores *.evtx --windows           # Analisis semua file event log 📂
fores logs/ --windows            # Analisis folder berisi event logs 📁
```

**Windows Event Log Analysis** secara otomatis mendeteksi:
- **Installation Evidence** - Mencari bukti instalasi software (MSI, setup, install) 📦
- **Execution Evidence** - Mencari cmd.exe, powershell.exe, process start ⚡
- **Shutdown Evidence** - Mencari EventID 6008, 1074, shutdown events 🔌
- **Logon Evidence** - Mencari EventID 4624, 4625 (logon success/fail) 🔑
- **Flag Extraction** - Mencari flag tersembunyi dalam event log 🚩

---

## 📁 Output Folder

| Folder | Kegunaan |
|--------|----------|
| `*_bitplanes/` | Bit plane visual (0-7) 🔬 |
| `*_channels/` | RGBA channels terpisah 🎨 |
| `*_remap/` | Color palette variants 🌈 |
| `*_zsteg/`, `*_steghide/`, `*_outguess/` | Output steganography tools 🔒 |
| `*_foremost/` | File carving results 🔪 |
| `*_bruteforce/` | Brute force results 🔑 |
| `*_decoded_*` | Hasil decode (b64/hex/bin) 🔠 |
| `*_http_objects/`, `*_streams/` | PCAP analysis results 🌐 |
| `*_disk_analysis/` | Disk image analysis results 💾 |
| `*_event_analysis/` | Windows Event Log analysis results 🪟 |
| `_extracted_*/` | Binwalk extraction 📦 |
| `fixed_*`, `repaired_*` | Repaired headers 🔧 |

---

## 🚀 Cheat Sheet

```bash
# Analisis dasar 🔍
fores file.png

# Steganografi 🖼️🔒
fores file.png --lsb --deep --alpha
fores file.jpg --steghide
fores file.jpg --outguess

# Brute force 🔑
fores file.png --bruteforce

# Auto-decode & network 🔄🌐
fores logs.txt --decode
fores capture.pcap --pcap     # Dengan attack detection otomatis

# Disk forensics 💾
fores disk.img --disk

# Windows Event Log forensics 🪟
fores security.evtx --windows

# Full analysis 💥
fores file.png --all
```

---

## 💡 Tips & Trik

- ✅ Gunakan `--auto` untuk analisis cepat tanpa memilih tools satu per satu 🤖
- ⚠️ Tools yang tidak terinstall akan otomatis dilewati — tidak perlu khawatir! 😌
- 🔎 Periksa folder `*_bitplanes/` dan `*_channels/` jika flag tidak ditemukan otomatis 👀
- 🌐 Untuk file `.pcap`, gunakan `--pcap` untuk analisis lengkap termasuk ekstrak HTTP objects, DNS queries, credentials, dan deteksi attack patterns (SQLi, XSS, LFI, dll.) 🔓
- 💾 Untuk disk image (`.img`, `.dd`, `.raw`), gunakan `--disk` untuk mencari flag dengan strings dan ekstrak file tersembunyi (sekarang 3-5x lebih cepat!) 🕵️⚡
- 🧪 Cobalah `--remap` pada gambar dengan noise tinggi — sering menyembunyikan flag di palette warna! 🌈
- ⚡ Analisis disk image sekarang menggunakan FAST MODE: scan 10MB pertama saja, string min. 8 karakter, dan limit hasil untuk kecepatan maksimal 🚀
- 🪟 Untuk file Windows Event Logs (.evtx), gunakan `--windows` untuk menganalisis malware infection, mencari bukti installation, execution, dan persistence mechanism 🔍

---

Dikembangkan oleh **Syaaddd** 👨‍💻 — untuk para pejuang CTF! 🏆🚩  
[GitHub Repository](https://github.com/Syaaddd/SForensicsTools) 💻✨