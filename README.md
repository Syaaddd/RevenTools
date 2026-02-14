# 🕵️‍♂️ SForensicsTools

> **Smart Forensic Toolkit for CTF Challenges**  
> Alat otomatis untuk menganalisis file dalam kompetisi keamanan siber — mendukung steganografi visual, header repair, ekstraksi tersembunyi, dan deteksi flag cerdas.
> 
> Versi: **v2.0 (AperiSolve Style)** — dengan dukungan penuh steganography tools seperti zsteg, steghide, outguess, foremost, dan lainnya.


## 📦 Instalasi

Ikuti langkah-langkah berikut untuk menginstal dan menyiapkan tools:

### **1. Instalasi Dasar (tersedia di repo)**
```bash
sudo apt update && sudo apt install -y \
    binwalk \
    libimage-exiftool-perl \
    tesseract-ocr \
    unrar \
    p7zip-full \
    xz-utils \
    python3-pip \
    steghide \
    foremost \
    pngcheck \
    graphicsmagick
```

### **2. Instalasi zsteg (Ruby Gem)**
```bash
# Install Ruby jika belum ada
sudo apt install -y ruby ruby-dev

# Install zsteg via gem
sudo gem install zsteg
```

### **3. Install outguess (Compile from source)**
```bash
# Install dependensi build
sudo apt install -y build-essential libjpeg-dev

# Download & compile
wget https://github.com/residentgreg/outguess/archive/refs/heads/master.zip -O outguess.zip
unzip outguess.zip
cd outguess-master
./configure && make && sudo make install
cd ..
rm -rf outguess-master outguess.zip
```

### **4. Install jpseek / jphs (JPEG steganography)**
```bash
# Install dari source
sudo apt install -y build-essential libjpeg-dev

# jphs (JPEG Hidden Data Selector)
wget https://downloads.sourceforge.net/project/jphs/jphs/jphs-0.9b.tar.gz
tar -xzf jphs-0.9b.tar.gz
cd jphs-0.9b
make && sudo make install
cd ..
rm -rf jphs-0.9b jphs-0.9b.tar.gz
```

### **5. Instal dependensi Python**
```bash
pip install colorama Pillow numpy
```

### **6. Jadikan executable & pasang ke PATH**
```bash
chmod +x ForesTools.py
sudo cp ForesTools.py /usr/local/bin/fores
```

> 💡 **Catatan**:  
> - `tesseract-ocr` digunakan untuk OCR (optical character recognition) jika diperlukan di fitur lanjutan.  
> - `Pillow` dan `numpy` wajib untuk analisis gambar (bit plane & channel splitting).
> - Tools steganografi (`zsteg`, `steghide`, `outguess`, dll) bersifat **opsional** — jika tidak terinstall, tools akan otomatis dilewati.

---

## 🚀 Cara Menjalankan (CLI)

Tools ini mendukung berbagai pola input untuk memudahkan analisis massal dalam tantangan CTF.

### 1. **Satu File**
```bash
fores challenge.png
```

### 2. **Beberapa File atau Wildcard**
```bash
# Semua file PNG di direktori saat ini
fores *.png

# Beberapa file sekaligus
fores secret.jpg data.zip firmware.bin
```

### 3. **Seluruh Folder (Rekursif)**
```bash
# Analisis semua file di folder saat ini
fores .

# Analisis folder tertentu
fores /path/to/ctf/challenges/
```

### 4. **Dengan Petunjuk Format Flag (Opsional)**
Jika Anda tahu format flagnya (misalnya `picoCTF{...}`), berikan sebagai hint:
```bash
fores -f "picoCTF{" suspicious.png
fores --format "CTF{" *.jpg
```

### 5. **Auto-Decode Encoded Data (Baru!)**
Otomatis mendeteksi dan mendecode data yang di-encode (base64, hex, binary):
```bash
# Decode file yang berisi base64 encoded image
fores logs.txt --decode

# Ekstrak semua file tersembunyi
fores encoded_data.txt --extract

# Kombinasi dengan mode auto
fores mystery_file --auto
```

---

## 🆕 Mode Analisis (v2.0)

### **Mode Otomatis (--auto)**
Jalankan semua tools yang tersedia secara otomatis berdasarkan tipe file:
```bash
fores image.png --auto
```
Akan otomatis mendeteksi file type dan menjalankan:
- Image → bit plane, RGB channels, zsteg, steghide, pngcheck, dll
- Archive → binwalk, foremost

### **Mode Lengkap (--all)**
Paksa jalankan **semua** analisis termasuk tools yang mungkin tidak tersedia:
```bash
fores image.png --all
```

---

## 🔧 Opsi Steganografi (v2.0)

### **LSB Analysis**
```bash
# Zsteg full analysis untuk PNG/BMP
fores image.png --lsb
```

### **Steghide**
```bash
# Ekstraksi steghide (tanpa password)
fores image.jpg --steghide
```

### **Outguess**
```bash
# Outguess extraction untuk JPEG
fores image.jpg --outguess
```

### **Zsteg**
```bash
# Analisis lengkap zsteg
fores image.png --zsteg
```

### **PNG Check**
```bash
# Validasi PNG
fores image.png --pngcheck
```

### **JPEG Steganography**
```bash
# JPEG steganalysis (jpseek/jphs)
fores image.jpg --jpsteg
```

### **File Carving**
```bash
# Ekstraksi file dengan foremost
fores image.png --foremost
```

---

## 🔓 Brute Force (v2.0)

### **Brute Force Steghide**
```bash
# Brute force dengan delay default 5 detik
fores image.png --bruteforce

# Brute force dengan delay 7 detik
fores image.png --bruteforce --delay 7

# Brute force dengan wordlist kustom
fores image.png --bruteforce --wordlist mypasswords.txt
```

> ⚠️ Default wordlist berisi 80+ password umum (password, flag, ctf, hack, dll)

---

## 🎨 Analisis Gambar Lanjutan (v2.0)

### **Color Remapping**
Buat 8 variant palette remap seperti AperiSolve:
```bash
fores image.png --remap
```
Output: `*_remap/variant_1.png` hingga `variant_8.png`

### **Alpha Channel**
Ekstrak dan analisis alpha channel (untuk PNG):
```bash
fores image.png --alpha
```

### **Deep Analysis**
Analisis full bit plane (bit 0-7, bukan hanya 6-7):
```bash
fores image.png --deep
```

### **Kombinasi Lengkap**
```bash
# Full analysis untuk image
fores image.png --all

# Kombinasi spesifik
fores image.png --deep --alpha --remap --steghide
```

---

## 🔓 Auto-Decode & Extract (v2.1)

### **Menggunakan --decode**
Otomatis mendeteksi dan mendecode data terenkripsi dalam file:

```bash
# Contoh: File logs.txt berisi base64 encoded image
fores logs.txt --decode

# Output akan otomatis:
# 1. Mendeteksi encoding (base64/hex/binary)
# 2. Decode dan save sebagai file (jpg/png/gif/zip/etc)
# 3. Auto-analisis file hasil decode
```

### **Menggunakan --extract**
Ekstrak semua file tersembunyi dari encoded text:

```bash
fores encoded_data.txt --extract
```

### **Cara Kerja Auto-Decode**
Tools akan secara otomatis:
1. **Scan** konten file untuk pola encoding
2. **Deteksi** tipe encoding (Base64, Hex, Binary)
3. **Decode** data yang ditemukan
4. **Identifikasi** tipe file dari header
5. **Simpan** dengan ekstensi yang sesuai
6. **Analisis** file hasil decode untuk flag

### **Contoh Penggunaan Real**

**Soal CTF:** File `logs.txt` berisi base64 encoded image
```bash
# Terminal manual:
base64 -d logs.txt > hidden_image.jpg

# Dengan ForesTools (otomatis):
fores logs.txt --decode
# Output: logs_decoded_b64_0.jpg (auto-detected sebagai JPG)
```

**Soal CTF:** File `secret.txt` berisi hex encoded zip
```bash
fores secret.txt --decode
# Output: secret_decoded_hex_0.zip
```

---

## 📁 Output Folder

Semua hasil ekstraksi disimpan di **folder yang sama dengan file input**:

| Folder | Kegunaan |
|--------|----------|
| `*_bitplanes/` | Representasi visual bit 0-7 per channel (R/G/B/Alpha) |
| `*_channels/` | Saluran warna terpisah (red.png, green.png, blue.png, alpha.png) |
| `*_remap/` | 8 variant color palette remap |
| `*_zsteg/` | Output dari zsteg extraction |
| `*_steghide/` | Output dari steghide extraction |
| `*_outguess/` | Output dari outguess extraction |
| `*_foremost/` | File yang di-carve oleh foremost |
| `*_bruteforce/` | Hasil brute force attempt |
| `*_decoded_b64_*` | File hasil decode base64 (auto-detect) |
| `*_decoded_hex_*` | File hasil decode hex (auto-detect) |
| `*_decoded_bin_*` | File hasil decode binary (auto-detect) |
| `_extracted_*/` | File tersembunyi dari binwalk |
| `fixed_*`, `repaired_*` | File dengan header diperbaiki |

---

## 📋 Cheat Sheet

```bash
# ===== DASAR =====
fores file.png                    # Analisis dasar
fores -f "picoCTF{" file.png     # Dengan custom flag format

# ===== OTOMATIS =====
fores file.png --auto             # Auto-detect & jalankan tools
fores file.png --all              # Full analysis

# ===== STEGANOGRAPHY =====
fores file.png --lsb              # LSB analysis (zsteg)
fores file.jpg --steghide         # Steghide
fores file.jpg --outguess         # Outguess
fores file.png --pngcheck         # PNG validation
fores file.jpg --jpsteg           # JPEG steganalysis
fores file.png --foremost         # File carving

# ===== BRUTE FORCE =====
fores file.png --bruteforce                       # Default (5s delay, 80 passwords)
fores file.png --bruteforce --delay 10            # Delay 10 detik
fores file.png --bruteforce --wordlist dict.txt   # Custom wordlist

# ===== AUTO-DECODE (BARU!) =====
fores logs.txt --decode           # Auto-decode base64/hex/binary
fores secret.txt --extract        # Ekstrak semua file tersembunyi
fores mystery.bin --decode        # Decode otomatis dengan deteksi tipe file

# ===== GAMBAR LANJUTAN =====
fores file.png --remap            # Color remapping (8 variants)
fores file.png --alpha            # Alpha channel analysis
fores file.png --deep             # Full bit plane (0-7)
fores file.png --deep --alpha     # Kombinasi
```

---

## 🔍 Tips

- ✅ Tools **otomatis mendeteksi jenis file** dan menjalankan analisis yang sesuai
- ✅ Tools steganografi yang tidak terinstall akan **otomatis dilewati**
- 🔍 Jika flag **tidak ditemukan otomatis**, periksa folder `*_bitplanes/` atau `*_channels/` secara manual
- 💡 Gunakan `--auto` untuk analisis cepat tanpa perlu memilih tools satu per satu
- 🎯 **Soal encoding**: Jika file berisi base64/hex (contoh: `logs.txt`), gunakan `--decode` untuk otomatis decode jadi image/file
- 📦 **File tersembunyi**: Hasil decode otomatis disimpan dengan format yang benar (jpg, png, zip, dll)

### **Contoh Kasus CTF Umum**

**Kasus 1: File berisi base64 image**
```bash
# Soal: logs.txt berisi base64 yang jadi image
fores logs.txt --decode
# Output: logs_decoded_b64_0.jpg
```

**Kasus 2: Steganography dengan password**
```bash
# Soal: image.jpg dengan steghide, password "ctf"
fores image.jpg --steghide
# Atau brute force jika password tidak diketahui
fores image.jpg --bruteforce
```

**Kasus 3: LSB dalam PNG**
```bash
# Soal: hidden data di bit-plane
fores image.png --lsb --deep
```

---

> 🛠️ Dikembangkan oleh **Syaaddd** — untuk para pejuang CTF!  
> 🌐 [GitHub Repository](https://github.com/Syaaddd/SForensicsTools)
