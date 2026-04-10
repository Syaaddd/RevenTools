#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  RAVEN v4.0 — CTF Multi-Category Toolkit
#  Jalankan dari mana saja setelah install: raven [FILE] [OPTIONS]
#  Install global: ./raven.sh --install-global
#  Usage: ./raven.sh [FILE(S)] [OPTIONS]
# ══════════════════════════════════════════════════════════════════

set -euo pipefail

# ─────────────────────────────────────────────
# WARNA & HELPERS
# ─────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; BLUE='\033[0;34m'
BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err_msg() { echo -e "${RED}[ERR]${NC}   $*" >&2; }
die()     { err_msg "$*"; exit 1; }

# ── Data disimpan di ~/.raven (bukan folder script)
# ── sehingga bisa dijalankan dari direktori mana saja
RAVEN_HOME="${RAVEN_HOME:-$HOME/.raven}"
VENV_DIR="$RAVEN_HOME/venv"
PYTHON_INLINE="$RAVEN_HOME/engine.py"
GLOBAL_BIN="/usr/local/bin/raven"

# ─────────────────────────────────────────────
# BANNER
# ─────────────────────────────────────────────
banner() {
cat << 'BANNER'

  ██████╗   █████╗  ██╗   ██╗ ███████╗ ███╗  ██╗
  ██╔══██╗ ██╔══██╗ ██║   ██║ ██╔════╝ ████╗ ██║
  ██████╔╝ ███████║ ██║   ██║ █████╗   ██╔██╗██║
  ██╔══██╗ ██╔══██║ ╚██╗ ██╔╝ ██╔══╝   ██║╚████║
  ██║  ██║ ██║  ██║  ╚████╔╝  ███████╗ ██║ ╚███║
  ╚═╝  ╚═╝ ╚═╝  ╚═╝   ╚═══╝   ╚══════╝ ╚═╝  ╚══╝
           CTF Multi-Category Toolkit v6.0.1  — by Syaaddd
BANNER
}

# ─────────────────────────────────────────────
# USAGE
# ─────────────────────────────────────────────
usage() {
cat << EOF
${BOLD}Usage:${NC}
  ./raven.sh [OPTIONS] FILE [FILE...]

${BOLD}Modes:${NC}
  --quick          Ultra-fast: strings + zsteg + stegseek + early exit
  --auto           Auto-detect dan jalankan semua tools yang sesuai
  --all            Paksa jalankan semua tool
  --interactive    Interactive category menu (multi-select, default mode)
  --pcap           Full PCAP analysis + attack detection
  --pcap-deep      Per-packet payload decode + flag reassembler (Ph4nt0m-style)
  --disk           Disk image analysis
  --windows        Windows Event Log forensics
  --folder DIR     Scan semua file di folder (fake extension detection)

${BOLD}CTF Spesifik (v3.0+):${NC}
  --reg            Windows Registry (.reg) — decode hex: values
  --log            Web server log analysis (Apache/Nginx) — IP, attack, flag
  --autorun        Autorun.inf / INF file — reverse, ROT13, caesar, b64
  --zipcrack       Crack ZIP password (multi-strategy: context/CTF/fcrackzip/john/rockyou)
  --forensic-zip   Forensic ZIP: evidence collection + smart password recovery
  --mft            NTFS MFT parser for deleted file recovery
  --ftp-recon      FTP session reconstruction from PCAP
  --email-recon    Email (SMTP/POP3/IMAP) reconstruction from PCAP
  --gps-extract    Extract GPS coordinates from EXIF metadata
  --pdfcrack       Crack PDF password (pdfcrack + wordlist)
  --john           Crack hash dengan John the Ripper
  --hashcat        Crack hash dengan Hashcat
  --hash-type STR  Hash type untuk john/hashcat (md5, sha256, sha512, dll)
  --volatility     Memory forensics via Volatility 3
  --vol-plugin P   Plugin Volatility tambahan (e.g. windows.cmdline)
  --deobfuscate    Coba semua decode: reverse/ROT13/caesar/atbash/b64/hex
  --binary         Force binary digits analysis (file berisi 0/1)
  --bin-width INT  Paksa lebar spesifik saat render gambar (e.g. 64)
  --render-image   Binary digits → decode bytes → render image (CyberChef mode)
  --bit-order STR  msb (default) atau lsb — urutan bit per byte
  --byte-len INT   Panjang byte group (default: 8)
  --morse          Decode Morse code dari file
  --decimal        Decode decimal ASCII dari file
  --reversing      Binary reversing (strings/objdump/readelf)
  --ghidra         Ghidra headless analysis (requires Ghidra installed)
  --unpack         Auto-unpack packed binaries (UPX)

${BOLD}Cryptography (v4.0):${NC}
  --crypto         Auto-attack crypto: RSA, Vigenere+acrostic, XOR KPA,
                   Classic Cipher (Atbash/Caesar), Encoding Chain
  --rsa            Paksa RSA attacks (weak prime/Fermat/Common-Modulus/Bellcore)
  --vigenere       Paksa Vigenere + akrostik key finder
  --classic        Paksa Classic Cipher brute (Atbash, Caesar, kombinasi)
  --xor-plain STR  Known-plaintext untuk XOR KPA (default: 'CTF{')
  --xor-key STR    Decrypt XOR langsung dengan key
  --crypto-key STR Kunci manual untuk Vigenere/Caesar
  --encoding-chain Paksa encoding chain decoder (Base32→Binary→BitRev→B64)

${BOLD}Steganografi:${NC}
  --lsb            LSB analysis (zsteg)
  --steghide       Steghide extraction (password kosong)
  --stegseek       Stegseek brute-force dengan rockyou.txt
  --outguess       Outguess extraction (JPEG)
  --pngcheck       Validasi struktur PNG
  --jpsteg         JPEG steganalysis (jpseek/jphs)
  --remap          Color palette remapping (8 variants)
  --exif           Deep EXIF metadata analysis
  --stegdetect     Deteksi metode stego yang digunakan
  --lsbextract     Ekstrak raw LSB bytes
  --deep           Analisis semua 8 bit plane
  --alpha          Sertakan alpha channel
  --compare FILE   Bandingkan dua gambar
  --foremost       File carving (foremost)
  --spectrogram    Audio spectrogram generator (WAV/MP3/FLAC)
  --chi-square     Chi-square statistical LSB steganalysis
  --dct-analysis   JPEG DCT coefficient analysis

${BOLD}Encoding:${NC}
  --decode         Auto-decode base64 / hex / binary
  --extract        Ekstrak file tersembunyi dari encoded text

${BOLD}Brute Force:${NC}
  --bruteforce     Brute-force steghide (wordlist default/custom)
  --wordlist FILE  Custom wordlist (default: rockyou.txt)
  --delay SECS     Delay antar attempt (default: 0.1)
  --parallel N     Jumlah thread (default: 5)

${BOLD}Misc:${NC}
  --learn [CAT]    Display CTF learning guide (no file needed)
                   Categories: linux, python, encoding, networking, web, crypto, pwn, reverse, forensics
                   Use 'list' to show all available categories
  -f, --format STR Custom flag prefix (e.g. 'picoCTF{')
  --install        Install semua optional tools
  --update         Update RAVEN yang sudah terinstall ke versi baru ini
  --install-global Install raven ke /usr/local/bin (jalankan dari mana saja)
  --uninstall      Hapus raven dari sistem
  --update-deps    Reinstall Python dependencies
  -h, --help       Tampilkan help ini

${BOLD}Contoh:${NC}
  ./raven.sh image.png                    # Analisis dasar
  ./raven.sh image.png --quick            # Ultra-fast CTF mode
  ./raven.sh image.jpg --stegseek         # Brute-force stegseek
  ./raven.sh artifact.reg --reg           # Registry analysis
  ./raven.sh access.log --log             # Log analysis
  ./raven.sh autorun.inf --autorun        # Autorun + deobfuscate
  ./raven.sh evidence.zip --zipcrack      # Crack ZIP password (multi-strategy)
  ./raven.sh evidence.zip --forensic-zip  # Forensic ZIP with evidence collection
  ./raven.sh secret.pdf --pdfcrack        # Crack PDF password
  ./raven.sh hash.txt --john              # Crack hash dengan John
  ./raven.sh hash.txt --hashcat           # Crack hash dengan Hashcat
  ./raven.sh hash.txt --john --hash-type sha256  # Crack dengan format spesifik
  ./raven.sh --folder ./challenge/        # Scan folder (fake ext)
  ./raven.sh chall.raw --volatility       # Memory forensics
  ./raven.sh secret.txt --deobfuscate     # Reverse/ROT13/caesar
  ./raven.sh *.png --auto                 # Batch auto mode
  ./raven.sh --install                    # Install semua tools
  ./raven.sh --install-global             # Install global (bisa dipanggil sebagai: raven)
  raven image.png --auto                  # Setelah install-global
  raven chall.txt --crypto                # Auto-attack semua crypto
  raven rsa_chall.txt --crypto --rsa      # Fokus RSA attacks
  raven cipher.txt --crypto --vigenere    # Vigenere + akrostik
  raven secret.txt --classic              # Atbash/Caesar brute
  raven enc.bin --xor-plain "CTF{"        # XOR KPA dengan prefix
  raven enc.bin --xor-key "DARKSIDE"      # XOR decrypt manual
  raven encoded.txt --encoding-chain      # Multi-stage decode
EOF
}

# ─────────────────────────────────────────────
# INSTALL TOOLS
# ─────────────────────────────────────────────
install_tools() {
    info "Menginstall optional system tools..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y \
            steghide foremost pngcheck binwalk exiftool \
            tshark wireshark-common ruby ruby-dev \
            build-essential libjpeg-dev python3-venv \
            john hashcat pdfcrack \
            2>/dev/null || warn "Beberapa paket gagal diinstall."

        # stegseek
        if ! command -v stegseek &>/dev/null; then
            info "Menginstall stegseek..."
            local tmp_deb="/tmp/stegseek.deb"
            wget -q "https://github.com/RickdeJager/stegseek/releases/download/v0.6/stegseek_0.6-1.deb" \
                -O "$tmp_deb" 2>/dev/null && \
            sudo apt-get install -y "$tmp_deb" 2>/dev/null && \
            success "stegseek terinstall." || warn "stegseek gagal, install manual dari https://github.com/RickdeJager/stegseek"
            rm -f "$tmp_deb"
        else
            success "stegseek sudah ada."
        fi

        # rockyou.txt
        if [[ ! -f /usr/share/wordlists/rockyou.txt ]]; then
            info "Mengekstrak rockyou.txt..."
            if [[ -f /usr/share/wordlists/rockyou.txt.gz ]]; then
                sudo gunzip /usr/share/wordlists/rockyou.txt.gz && success "rockyou.txt siap."
            else
                warn "rockyou.txt tidak ditemukan. Install: sudo apt install wordlists"
            fi
        else
            success "rockyou.txt sudah ada."
        fi

        # zsteg
        if ! command -v zsteg &>/dev/null; then
            sudo gem install zsteg 2>/dev/null && success "zsteg terinstall." || warn "zsteg gagal."
        fi

        # outguess — coba apt dulu, fallback build dari source
        if ! command -v outguess &>/dev/null; then
            info "Menginstall outguess..."
            if sudo apt-get install -y outguess 2>/dev/null; then
                success "outguess terinstall via apt."
            else
                info "apt gagal, build outguess dari source..."
                local og_tmp="/tmp/outguess_build"
                rm -rf "$og_tmp" && mkdir -p "$og_tmp"
                if command -v git &>/dev/null; then
                    git clone -q https://github.com/crorvick/outguess "$og_tmp" 2>/dev/null &&                     cd "$og_tmp" &&                     sudo apt-get install -y autoconf automake libjpeg-dev 2>/dev/null &&                     autoreconf -i 2>/dev/null &&                     ./configure --quiet 2>/dev/null &&                     make -s 2>/dev/null &&                     sudo make install -s 2>/dev/null &&                     cd - > /dev/null &&                     success "outguess berhasil diinstall dari source!" ||                     warn "outguess gagal build. Install manual: sudo apt install outguess"
                    rm -rf "$og_tmp"
                else
                    warn "outguess tidak bisa diinstall (git tidak tersedia). Install manual: sudo apt install outguess"
                fi
            fi
        else
            success "outguess sudah ada."
        fi

        # jphs / jpseek — JPEG steganography tools
        if ! command -v jphs &>/dev/null && ! command -v jpseek &>/dev/null; then
            info "Menginstall jphs (JPEG stego)..."
            if sudo apt-get install -y jphs 2>/dev/null; then
                success "jphs terinstall."
            else
                info "jphs tidak ada di apt, build dari source..."
                local jphs_tmp="/tmp/jphs_build"
                rm -rf "$jphs_tmp" && mkdir -p "$jphs_tmp"
                if command -v git &>/dev/null; then
                    git clone -q https://github.com/h3xx/jphs "$jphs_tmp" 2>/dev/null &&                     cd "$jphs_tmp" &&                     sudo apt-get install -y libjpeg-dev 2>/dev/null &&                     make -s 2>/dev/null &&                     sudo cp jphs jpseek /usr/local/bin/ 2>/dev/null &&                     cd - > /dev/null &&                     success "jphs/jpseek terinstall!" ||                     warn "jphs gagal. Tidak kritis untuk CTF."
                    rm -rf "$jphs_tmp"
                else
                    warn "jphs tidak bisa diinstall. Tidak kritis untuk CTF."
                fi
            fi
        else
            success "jphs/jpseek sudah ada."
        fi

    elif command -v brew &>/dev/null; then
        brew install steghide binwalk exiftool wireshark 2>/dev/null || true
        gem install zsteg 2>/dev/null || warn "zsteg gagal."
        warn "stegseek: install manual dari https://github.com/RickdeJager/stegseek"
    else
        warn "Tidak ada package manager yang didukung (apt/brew)."
    fi
    success "Instalasi selesai."
    exit 0
}

# ─────────────────────────────────────────────
# INSTALL GLOBAL (ke /usr/local/bin)
# ─────────────────────────────────────────────
update_global() {
    info "Update RAVEN ke versi terbaru..."

    local src="${BASH_SOURCE[0]}"
    local dest="$GLOBAL_BIN"

    if [[ ! -f "$dest" ]]; then
        warn "RAVEN belum terinstall secara global."
        info "Jalankan dulu: ./raven.sh --install-global"
        exit 1
    fi

    # Tentukan apakah perlu sudo
    local use_sudo=0
    [[ ! -w "$(dirname $dest)" ]] && use_sudo=1

    # Backup versi lama (simpan di $RAVEN_HOME bukan di /usr/local/bin)
    mkdir -p "$RAVEN_HOME/backups"
    local backup="$RAVEN_HOME/backups/raven.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$dest" "$backup" 2>/dev/null || true
    info "Backup versi lama: $backup"

    # Copy versi baru
    if [[ $use_sudo -eq 1 ]]; then
        sudo cp "$src" "$dest"
        sudo chmod +x "$dest"
    else
        cp "$src" "$dest"
        chmod +x "$dest"
    fi

    # Hapus engine lama supaya di-regenerate dari versi baru
    rm -f "$PYTHON_INLINE"

    # Pre-generate engine baru
    local py
    py=$(check_python) || die "Python 3.8+ tidak ditemukan."
    setup_venv "$py"
    write_python_engine

    success "RAVEN berhasil diupdate!"
    echo ""
    echo -e "  ${GREEN}Backup tersimpan di: $backup${NC}"
    echo -e "  ${GREEN}Engine baru: $PYTHON_INLINE${NC}"
    exit 0
}

install_global() {
    info "Install RAVEN secara global..."

    # Salin script ini ke /usr/local/bin/raven
    local src="${BASH_SOURCE[0]}"
    local dest="$GLOBAL_BIN"

    # Check if already installed and backup
    if [[ -f "$dest" ]]; then
        info "RAVEN sudah terinstall di $dest"
        info "Membuat backup versi lama..."
        local backup="${dest}.backup.$(date +%Y%m%d_%H%M%S)"
        if cp "$dest" "$backup" 2>/dev/null || sudo cp "$dest" "$backup" 2>/dev/null; then
            success "Backup dibuat: $backup"
        else
            warn "Gagal membuat backup, melanjutkan tanpa backup..."
        fi
    fi

    if [[ ! -w "$(dirname $dest)" ]]; then
        info "Butuh sudo untuk install ke $dest"
        sudo cp "$src" "$dest"
        sudo chmod +x "$dest"
    else
        cp "$src" "$dest"
        chmod +x "$dest"
    fi

    # Buat direktori home
    mkdir -p "$RAVEN_HOME"
    
    # Copy engine files (untuk --learn dan fitur lainnya)
    if [[ -d "$(dirname "$0")/engine" ]]; then
        info "Copying engine modules to $RAVEN_HOME/engine..."
        mkdir -p "$RAVEN_HOME/engine"
        cp -f "$(dirname "$0")/engine/"*.py "$RAVEN_HOME/engine/" 2>/dev/null || true
        success "Engine modules copied: $(ls "$RAVEN_HOME/engine/"*.py 2>/dev/null | wc -l) files"
    fi

    # Pre-setup venv sekarang juga
    local py
    py=$(check_python) || die "Python 3.8+ tidak ditemukan."
    setup_venv "$py"
    write_python_engine

    success "RAVEN v6.0.1 berhasil terinstall secara global!"
    echo ""
    echo -e "  ${GREEN}Sekarang kamu bisa jalankan dari mana saja:${NC}"
    echo -e "  ${BOLD}  raven image.png --auto${NC}"
    echo -e "  ${BOLD}  raven access.log --log${NC}"
    echo -e "  ${BOLD}  raven --folder ./challenge/${NC}"
    echo -e "  ${BOLD}  raven --learn              # CTF Learning Guide!${NC}"
    echo ""
    echo -e "  ${CYAN}Data tersimpan di: $RAVEN_HOME${NC}"
    echo ""
    echo -e "  ${YELLOW}💡 New in v6.0.1:${NC}"
    echo -e "  • Detailed analysis output (no more missing output!)"
    echo -e "  • CTF Learning Guide (--learn)"
    echo -e "  • Better error handling & logging"
    echo -e "  • All tools now show comprehensive reports${NC}"
    exit 0
}

# ─────────────────────────────────────────────
# UNINSTALL GLOBAL
# ─────────────────────────────────────────────
uninstall_global() {
    info "Menghapus RAVEN dari sistem..."
    if [[ -f "$GLOBAL_BIN" ]]; then
        sudo rm -f "$GLOBAL_BIN" 2>/dev/null || rm -f "$GLOBAL_BIN"
        success "Binary dihapus: $GLOBAL_BIN"
    else
        warn "Binary tidak ditemukan di $GLOBAL_BIN"
    fi
    if [[ -d "$RAVEN_HOME" ]]; then
        read -rp "Hapus juga $RAVEN_HOME? [y/N] " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            rm -rf "$RAVEN_HOME"
            success "Direktori data dihapus."
        fi
    fi
    exit 0
}

# ─────────────────────────────────────────────
# PYTHON SETUP
# ─────────────────────────────────────────────
check_python() {
    for py in python3 python python3.12 python3.11 python3.10 python3.9 python3.8; do
        if command -v "$py" &>/dev/null; then
            if "$py" -c "import sys; exit(0 if sys.version_info>=(3,8) else 1)" 2>/dev/null; then
                echo "$py"; return 0
            fi
        fi
    done
    return 1
}

setup_venv() {
    local py="$1"
    mkdir -p "$RAVEN_HOME"
    if [[ ! -d "$VENV_DIR" ]]; then
        info "Membuat virtual environment di $RAVEN_HOME/venv..."
        "$py" -m venv "$VENV_DIR" || die "Gagal buat venv. Install python3-venv?"
        success "Virtual environment dibuat."
    fi
    source "$VENV_DIR/bin/activate"
    local pip="$VENV_DIR/bin/pip"
    local missing=()
    python -c "import colorama" 2>/dev/null || missing+=("colorama")
    python -c "from PIL import Image" 2>/dev/null || missing+=("Pillow")
    python -c "import numpy" 2>/dev/null || missing+=("numpy")
    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "Menginstall: ${missing[*]}"
        "$pip" install --quiet --upgrade pip
        "$pip" install --quiet "${missing[@]}" || die "pip install gagal."
        success "Dependencies terinstall."
    fi
}

check_system_tools() {
    local tools=(zsteg steghide stegseek outguess foremost pngcheck binwalk exiftool tshark capinfos)
    local missing=()
    for t in "${tools[@]}"; do
        command -v "$t" &>/dev/null || missing+=("$t")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "Tools opsional tidak ditemukan: ${missing[*]}"
        warn "Jalankan './raven.sh --install' untuk install otomatis."
        echo ""
    fi
}

# ─────────────────────────────────────────────
# SETUP MODULAR ENGINE (v5.1)
# ─────────────────────────────────────────────
setup_engine() {
    local engine_src="${SCRIPT_DIR}/engine"
    local engine_dst="$RAVEN_HOME/engine"

    # If source engine exists (running from repo), copy it
    if [[ -d "$engine_src" ]]; then
        info "Copying modular engine to $engine_dst..."
        mkdir -p "$engine_dst"
        cp -f "$engine_src"/*.py "$engine_dst/"
        success "Engine files copied: $(ls "$engine_dst"/*.py 2>/dev/null | wc -l) files"
        return 0
    fi

    # If running from global install, engine should already be in RAVEN_HOME
    if [[ -d "$engine_dst" && -f "$engine_dst/core.py" ]]; then
        return 0  # Engine already installed
    fi

    # Fallback: engine not found
    err_msg "Engine files not found at $engine_src or $engine_dst"
    err_msg "Make sure you're running from the repo directory or run --install-global"
    return 1
}

# ─────────────────────────────────────────────
# INTERACTIVE CATEGORY MENU (v5.1)
# ─────────────────────────────────────────────

# Global variable untuk menyimpan hasil menu
MENU_SELECTED_FLAGS=""
MENU_TEMP_FILE=$(mktemp -t raven_menu.XXXXXX 2>/dev/null || echo "/tmp/raven_menu.$$")

# Cleanup temp file on exit
cleanup_menu_temp() {
    rm -f "$MENU_TEMP_FILE" 2>/dev/null
}
trap cleanup_menu_temp EXIT

# Detect available TUI tools
detect_tui_support() {
    if command -v fzf &>/dev/null; then
        echo "fzf"
    elif command -v whiptail &>/dev/null; then
        echo "whiptail"
    elif command -v dialog &>/dev/null; then
        echo "dialog"
    else
        echo "select"
    fi
}

# ─────────────────────────────────────────────
# PYTHON ENGINE (inline for portability)
# ─────────────────────────────────────────────
write_python_engine() {
    cat > "$PYTHON_INLINE" << 'PYTHON_ENGINE'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""RAVEN Python Engine - Generated by raven.sh"""

import os
import sys
import re
import math
import base64
import struct
import hashlib
import binascii
import subprocess
import argparse
import threading
import shutil
import gzip
from pathlib import Path
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed

try:
    from colorama import Fore, Back, Style, init
    init(autoreset=True)
except ImportError:
    print("ERROR: colorama not installed. Run: pip install colorama")
    sys.exit(1)

try:
    import numpy as np
except ImportError:
    print("WARNING: numpy not installed. Some features may not work.")
    pass

try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    print("WARNING: Pillow not installed. Some image features may not work.")
    HAS_PIL = False

FILE_SIGNATURES = {
    "png":    b"\x89\x50\x4E\x47\x0D\x0A\x1A\x0A",
    "jpg":    b"\xFF\xD8\xFF",
    "pdf":    b"\x25\x50\x44\x46",
    "gif":    b"\x47\x49\x46\x38",
    "zip":    b"\x50\x4B\x03\x04",
    "rar":    b"\x52\x61\x72\x21\x1A\x07",
    "7z":     b"\x37\x7A\xBC\xAF\x27\x1C",
    "elf":    b"\x7F\x45\x4C\x46",
    "exe":    b"\x4D\x5A",
    "sqlite": b"\x53\x51\x4C\x69\x74\x65\x20\x66\x6F\x72\x6D\x61\x74\x20\x33",
    "pcap":   b"\xD4\xC3\xB2\xA1",
    "pcapng": b"\x0A\x0D\x0D\x0A",
    "bmp":    b"\x42\x4D",
    "wav":    b"\x52\x49\x46\x46",
    "mp3":    b"\x49\x44\x33",
    "docx":   b"\x50\x4B\x03\x04",  # docx/xlsx/pptx juga ZIP
    "class":  b"\xCA\xFE\xBA\xBE",
    "swf":    b"\x46\x57\x53",
}

# Magic bytes yang dipakai untuk deteksi fake extension
MAGIC_MAP = {
    b"\x89\x50\x4E\x47": ("png",  "PNG Image"),
    b"\xFF\xD8\xFF":      ("jpg",  "JPEG Image"),
    b"\x50\x4B\x03\x04": ("zip",  "ZIP Archive"),
    b"\x50\x4B\x05\x06": ("zip",  "ZIP Archive (empty)"),
    b"\x25\x50\x44\x46": ("pdf",  "PDF Document"),
    b"\x47\x49\x46\x38": ("gif",  "GIF Image"),
    b"\x7F\x45\x4C\x46": ("elf",  "ELF Executable"),
    b"\x4D\x5A":          ("exe",  "Windows PE/EXE"),
    b"\xD4\xC3\xB2\xA1": ("pcap", "PCAP Capture"),
    b"\x0A\x0D\x0D\x0A": ("pcapng","PCAPNG Capture"),
    b"\x42\x4D":          ("bmp",  "BMP Image"),
    b"\x52\x61\x72\x21": ("rar",  "RAR Archive"),
    b"\x37\x7A\xBC\xAF": ("7z",   "7-Zip Archive"),
    b"\xCA\xFE\xBA\xBE": ("class","Java Class"),
    b"\x1F\x8B":          ("gz",   "GZIP Archive"),
    b"\x42\x5A\x68":      ("bz2",  "BZ2 Archive"),
    b"\x75\x73\x74\x61": ("tar",  "TAR Archive"),
    b"\xD0\xCF\x11\xE0": ("doc",  "MS Office (old)"),
    # Disk images — NTFS boot sector (EB 52 90 4E 54 46 53)
    b"\xEB\x52\x90\x4E\x54\x46\x53": ("ntfs_disk", "NTFS Disk Image"),
    b"\xEB\x58\x90\x4E\x54\x46\x53": ("ntfs_disk", "NTFS Disk Image"),
    b"\xEB\x5A\x90\x4E\x54\x46\x53": ("ntfs_disk", "NTFS Disk Image"),
    b"\xEB\x52\x90\x4D\x53\x44\x4F": ("ntfs_disk", "FAT/NTFS Disk Image"),
    # MBR (starts with EB xx 90 atau EB xx 00, ends with 55 AA at byte 510)
    # Kita detect via 'dos/mbr' string nanti di file_desc
}

DISK_INDICATORS = [
    "dos/mbr boot sector", "ntfs", "fat12", "fat16", "fat32",
    "ext2", "ext3", "ext4", "iso 9660", "squashfs", "vmware",
    "virtualbox", "qemu", "disk image", "oem-id",
]
MEMORY_INDICATORS = [
    "data",  # .raw dengan entropy rendah
]

# ── Global Variables ──────────────────────────────────
flag_summary = []
base64_collector = []
FLAG_FOUND = False
found_flags_set = set()
tool_log = []
FLAG_LOCK = threading.Lock()
AVAILABLE_TOOLS = {}

# Default wordlist for brute force (optimized for CTF)
DEFAULT_WORDLIST = [
    "",  # Empty password - very common in CTF!
    "password", "123456", "12345678", "qwerty", "abc123",
    "monkey", "1234567", "letmein", "trustno1", "dragon",
    "baseball", "iloveyou", "master", "sunshine", "ashley",
    "bailey", "passw0rd", "shadow", "123123", "654321",
    "superman", "qazwsx", "michael", "football", "password1",
    "password123", "welcome", "admin", "admin123", "root",
    "toor", "pass", "test", "guest", "master123",
    "changeme", "letmein123", "qwerty123", "123456789", "1234567890",
    # CTF-specific
    "secret", "flag", "ctf", "steg", "crypto", "forensics",
    "hidden", "phantom", "picoCTF", "lks", "dsj",
    "P@ssw0rd", "s3cr3t", "fl4g", "ctf2024", "ctf2025", "ctf2026",
]

# Common rockyou.txt locations
ROCKYOU_PATHS = [
    "/usr/share/wordlists/rockyou.txt",
    "/usr/share/seclists/Passwords/rockyou.txt",
    "/opt/wordlists/rockyou.txt",
    "/usr/share/wordlist/rockyou.txt",
    "./rockyou.txt",
    "/usr/share/metasploit-framework/data/wordlists/rockyou.txt",
]

# CTF-specific wordlist (faster than rockyou for competitions)
CTF_WORDLIST_PATHS = [
    "./wordlists/ctf_passwords.txt",
    "../wordlists/ctf_passwords.txt",
    "../../wordlists/ctf_passwords.txt",
    "$HOME/.raven/wordlists/ctf_passwords.txt",
    "/usr/share/wordlists/ctf_passwords.txt",
]

# Common flag patterns to search for
COMMON_FLAG_PATTERNS = [
    r'flag\{[^}]+\}',
    r'FLAG\{[^}]+\}',
    r'Flag\{[^}]+\}',
    r'CTF\{[^}]+\}',
    r'picoCTF\{[^}]+\}',
    r'actf\{[^}]+\}',
    r'utflag\{[^}]+\}',
    r'hsctf\{[^}]+\}',
]

# ── Utility ──────────────────────────────────

def check_tool_availability():
    tools = {
        "zsteg":"zsteg","steghide":"steghide","stegseek":"stegseek",
        "outguess":"outguess","foremost":"foremost","pngcheck":"pngcheck",
        "jpseek":"jpseek","jphs":"jphs","exiftool":"exiftool",
        "binwalk":"binwalk","identify":"gm","tshark":"tshark",
        "tcpdump":"tcpdump","capinfos":"capinfos",
        "fcrackzip":"fcrackzip","john":"john","hashcat":"hashcat",
        "pdfcrack":"pdfcrack","pdfinfo":"pdfinfo","pdftotext":"pdftotext",
        "vol":"vol","volatility":"volatility","volatility3":"volatility3",
        "unzip":"unzip","7z":"7z",
        "mmls":"mmls","fls":"fls","icat":"icat",
        "sleuthkit":"mmls",
    }
    global AVAILABLE_TOOLS
    AVAILABLE_TOOLS = {}
    for name, cmd in tools.items():
        probe  = f"which {cmd}" if os.name != "nt" else f"where {cmd}"
        result = subprocess.run(probe, shell=True, capture_output=True, text=True)
        AVAILABLE_TOOLS[name] = result.returncode == 0
        color  = Fore.GREEN if AVAILABLE_TOOLS[name] else Fore.RED
        status = "Available" if AVAILABLE_TOOLS[name] else "Missing"
        print(f"{color}[TOOL] {name}: {status}{Style.RESET_ALL}")
    return AVAILABLE_TOOLS

def reset_globals():
    global flag_summary, base64_collector, FLAG_FOUND, found_flags_set, tool_log
    flag_summary=[]; base64_collector=[]; FLAG_FOUND=False
    found_flags_set=set(); tool_log=[]

def log_tool(tool_name, status, result=""):
    """Catat tool yang dijalankan beserta statusnya"""
    tool_log.append({
        "tool":   tool_name,
        "status": status,   # "✅ Found" | "⬜ Nothing" | "⏭ Skipped" | "❌ Error"
        "result": result,
    })

def check_early_exit(): return FLAG_FOUND

def signal_flag_found():
    global FLAG_FOUND
    with FLAG_LOCK: FLAG_FOUND=True

def add_to_summary(category, content):
    entry = f"[{category}] {content.strip()}"
    if entry not in flag_summary:
        flag_summary.append(entry)
    if "FLAG" in category:
        signal_flag_found()

def calculate_entropy(data):
    if not data: return 0.0
    entropy=0.0; length=len(data)
    for x in range(256):
        count=data.count(x)
        if count==0: continue
        p=count/length; entropy-=p*math.log2(p)
    return entropy

def decode_base64(candidate):
    try:
        clean=re.sub(r'[^A-Za-z0-9+/=]','',candidate)
        if len(clean)<8 or len(clean)%4!=0: return None
        decoded=base64.b64decode(clean,validate=True)
        s=decoded.decode('utf-8',errors='ignore')
        if all(c.isprintable() or c.isspace() for c in s) and len(s.strip())>4:
            return s
    except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
    return None

def detect_file_extension(header):
    if header.startswith(b'\x89PNG'):      return 'png'
    if header.startswith(b'\xff\xd8\xff'): return 'jpg'
    if header.startswith(b'GIF8'):         return 'gif'
    if header.startswith(b'%PDF'):         return 'pdf'
    if header.startswith(b'PK'):           return 'zip'
    if header.startswith(b'\x42\x4d'):     return 'bmp'
    if header.startswith(b'\xff\xfb') or header.startswith(b'ID3'): return 'mp3'
    return 'bin'

def collect_base64_from_text(text):
    global found_flags_set
    for m in re.findall(r'[A-Za-z0-9+/]{12,}=*', text):
        decoded=decode_base64(m)
        if decoded:
            entry=f"Raw: {m} -> Decoded: {decoded}"
            if entry not in base64_collector:
                base64_collector.append(entry)
                add_to_summary("B64-COLLECTOR",decoded)
                for pat in COMMON_FLAG_PATTERNS:
                    for fm in re.findall(pat,decoded,re.IGNORECASE):
                        fm_clean = fm.strip()
                        add_to_summary("B64-FLAG",fm_clean)
                        if fm_clean not in found_flags_set:
                            found_flags_set.add(fm_clean)
                            print(f"\n{Fore.GREEN}{'─'*50}")
                            print(f"  🚩 FLAG dari Base64!")
                            print(f"  {Fore.YELLOW}{fm_clean}{Style.RESET_ALL}")
                            print(f"{Fore.GREEN}  Raw B64: {m[:60]}...{Style.RESET_ALL}")
                            print(f"{Fore.GREEN}{'─'*50}{Style.RESET_ALL}\n")

def detect_scattered_flag(raw_data):
    try:
        cleaned=''.join(chr(b) for b in raw_data if 32<=b<=126)
        for pat in COMMON_FLAG_PATTERNS:
            for m in re.findall(pat,cleaned,re.IGNORECASE):
                add_to_summary("SCATTERED-FLAG",m)
    except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))

def scan_text_for_flags(text, source=""):
    """Scan teks apapun untuk flag patterns — dedup ketat"""
    global found_flags_set
    found=[]
    for pat in COMMON_FLAG_PATTERNS:
        for m in re.findall(pat,text,re.IGNORECASE):
            m_clean = m.strip()
            label = f"FLAG-{source}" if source else "AUTO-FLAG"
            add_to_summary(label, m_clean)
            # Print hanya sekali per flag unik
            if m_clean not in found_flags_set:
                found_flags_set.add(m_clean)
                found.append(m_clean)
                print(f"\n{Fore.GREEN}{'─'*50}")
                print(f"  🚩 FLAG DITEMUKAN!")
                print(f"  {Fore.YELLOW}{m_clean}{Style.RESET_ALL}")
                print(f"{Fore.GREEN}  Sumber : {source or 'auto'}{Style.RESET_ALL}")
                print(f"{Fore.GREEN}{'─'*50}{Style.RESET_ALL}\n")
    collect_base64_from_text(text)
    return found

# ═══════════════════════════════════════════════════════
# ══ FITUR v3.1 ═════════════════════════════════════════
# ═══════════════════════════════════════════════════════

# ── 1. DEOBFUSCATION ENGINE ──────────────────

def deobfuscate_string(s):
    """Coba semua teknik deobfuscation pada sebuah string. Return dict hasil."""
    results = {}

    # Reverse
    rev = s[::-1]
    results['reverse'] = rev

    # ROT13
    rot13 = s.translate(str.maketrans(
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz',
        'NOPQRSTUVWXYZABCDEFGHIJKLMnopqrstuvwxyzabcdefghijklm'))
    results['rot13'] = rot13

    # Atbash
    atbash = s.translate(str.maketrans(
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz',
        'ZYXWVUTSRQPONMLKJIHGFEDCBAzyxwvutsrqponmlkjihgfedcba'))
    results['atbash'] = atbash

    # Caesar brute (semua 25 shift)
    for shift in range(1,26):
        result=[]
        for c in s:
            if c.isupper(): result.append(chr((ord(c)-65+shift)%26+65))
            elif c.islower(): result.append(chr((ord(c)-97+shift)%26+97))
            else: result.append(c)
        results[f'caesar_{shift}'] = ''.join(result)

    # Base64 decode
    b64 = decode_base64(s)
    if b64: results['base64'] = b64

    # Hex decode
    try:
        clean_hex = re.sub(r'[^0-9a-fA-F]','',s)
        if len(clean_hex)>=8 and len(clean_hex)%2==0:
            results['hex'] = bytes.fromhex(clean_hex).decode('utf-8',errors='ignore')
    except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))

    # Reverse + Base64
    try:
        rb64 = decode_base64(s[::-1])
        if rb64: results['reverse_then_b64'] = rb64
    except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))

    return results

def analyze_deobfuscation(text, source=""):
    """Analisis teks dengan semua deobfuscation technique"""
    print(f"{Fore.GREEN}[DEOBFUSCATE] Mencoba semua teknik decode pada teks mencurigakan...{Style.RESET_ALL}")
    found_flags = []

    # Cari string yang mirip flag (dibalik/encoded)
    candidates = []

    # 1. Cari string yang mengandung karakter flag-like
    for m in re.findall(r'[A-Za-z0-9_\{\}]{8,}', text):
        candidates.append(m)

    # 2. Khusus: reverse detection - string yang ada '}' di awal atau '{' di akhir
    for m in re.findall(r'\}[A-Za-z0-9_]{4,}\{[A-Z]{2,3}', text):
        results = deobfuscate_string(m)
        rev = results.get('reverse','')
        for pat in COMMON_FLAG_PATTERNS:
            if re.search(pat, rev, re.IGNORECASE):
                print(f"{Fore.GREEN}[DEOBFUSCATE] Reverse string → {rev}{Style.RESET_ALL}")
                add_to_summary("DEOBF-REVERSE", rev)
                found_flags.append(rev)

    # 3. Scan semua candidates dengan semua metode
    for cand in candidates[:50]:  # batasi 50 untuk performa
        results = deobfuscate_string(cand)
        for method, decoded in results.items():
            if decoded and len(decoded) > 4:
                for pat in COMMON_FLAG_PATTERNS:
                    if re.search(pat, decoded, re.IGNORECASE):
                        flags = re.findall(pat, decoded, re.IGNORECASE)
                        for flag in flags:
                            print(f"{Fore.GREEN}[DEOBFUSCATE] {method}: '{cand}' → '{flag}'{Style.RESET_ALL}")
                            add_to_summary(f"DEOBF-{method.upper()}", flag)
                            found_flags.append(flag)

    if not found_flags:
        print(f"{Fore.YELLOW}[DEOBFUSCATE] Tidak ada flag ditemukan via deobfuscation{Style.RESET_ALL}")
    return found_flags

# ── 2. REGISTRY ANALYSIS ─────────────────────

def analyze_registry(filepath):
    """Parse .reg file, decode hex: values, cari flag tersembunyi"""
    print(f"{Fore.GREEN}[REGISTRY] Analisis Windows Registry file...{Style.RESET_ALL}")
    out_dir = filepath.parent / f"{filepath.stem}_registry"
    out_dir.mkdir(exist_ok=True)

    try:
        content = filepath.read_text(encoding='utf-16', errors='ignore')
    except:
        try:
            content = filepath.read_text(encoding='utf-8', errors='ignore')
        except:
            content = filepath.read_bytes().decode('latin-1', errors='ignore')

    print(f"{Fore.CYAN}[REGISTRY] {len(content)} karakter dibaca{Style.RESET_ALL}")

    # Scan flag langsung di teks
    scan_text_for_flags(content, "REGISTRY")

    # Decode semua nilai hex: (REG_BINARY)
    hex_pattern = r'"([^"]+)"\s*=\s*hex:([0-9a-fA-F,\\\s\r\n]+)'
    hex_matches = re.findall(hex_pattern, content, re.MULTILINE)

    print(f"{Fore.CYAN}[REGISTRY] {len(hex_matches)} nilai hex ditemukan{Style.RESET_ALL}")
    for name, hex_data in hex_matches:
        clean = re.sub(r'[^0-9a-fA-F]', '', hex_data)
        if len(clean) % 2 == 0:
            try:
                decoded_bytes = bytes.fromhex(clean)
                
                # Coba decode sebagai UTF-8/ASCII dulu (paling umum)
                decoded = ""
                encoding_used = ""
                try:
                    decoded = decoded_bytes.decode('utf-8', errors='ignore').strip('\x00')
                    if decoded.strip() and all(32 <= ord(c) <= 126 or c in '\n\r\t' for c in decoded if c.isprintable() or c in '\n\r\t'):
                        encoding_used = "ASCII/UTF-8"
                except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
                
                # Jika UTF-8 gagal atau kosong, coba UTF-16LE
                if not decoded.strip():
                    try:
                        decoded = decoded_bytes.decode('utf-16-le', errors='ignore').strip('\x00')
                        if decoded.strip():
                            encoding_used = "UTF-16LE"
                    except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
                
                # Jika masih kosong, coba UTF-16BE
                if not decoded.strip():
                    try:
                        decoded = decoded_bytes.decode('utf-16-be', errors='ignore').strip('\x00')
                        if decoded.strip():
                            encoding_used = "UTF-16BE"
                    except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
                
                # Jika masih kosong, coba latin-1 (byte-per-byte)
                if not decoded.strip():
                    try:
                        decoded = decoded_bytes.decode('latin-1', errors='ignore')
                        if decoded.strip():
                            encoding_used = "Latin-1"
                    except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
                
                if decoded.strip():
                    print(f"{Fore.CYAN}  [{name}] hex → \"{decoded}\" ({encoding_used}){Style.RESET_ALL}")
                    
                    # Scan untuk flag
                    scan_text_for_flags(decoded, "REGISTRY-HEX")
                    collect_base64_from_text(decoded)
                    
                    # Simpan hex dan decoded value
                    (out_dir / f"hex_{name.replace(' ','_')}.txt").write_text(
                        f"Name: {name}\nHex: {clean}\nEncoding: {encoding_used}\nDecoded: {decoded}\n")
                    
                    # Jika flag ditemukan, print dengan highlight
                    for pat in COMMON_FLAG_PATTERNS:
                        if re.search(pat, decoded, re.IGNORECASE):
                            print(f"{Fore.GREEN}  🚩 FLAG tersembunyi di registry hex!{Style.RESET_ALL}")
                            break
            except Exception as e:
                print(f"{Fore.YELLOW}  [{name}] decode gagal: {e}{Style.RESET_ALL}")

    # Scan key-key mencurigakan
    suspicious_keys = ["RunOnce","Run","RunServices","RunServicesOnce",
                       "UserInit","Shell","Userinit","Load","Policies"]
    for key in suspicious_keys:
        if key.lower() in content.lower():
            idx = content.lower().find(key.lower())
            snippet = content[max(0,idx-20):idx+200]
            print(f"{Fore.YELLOW}[REGISTRY] Key mencurigakan '{key}':{Style.RESET_ALL}")
            print(f"  {snippet[:200]}")
            scan_text_for_flags(snippet, f"REGISTRY-KEY-{key}")

    # Decode semua nilai dword: dan qword:
    for vtype in ['dword','qword']:
        for m in re.findall(rf'"([^"]+)"\s*=\s*{vtype}:([0-9a-fA-F]+)', content, re.IGNORECASE):
            name, val = m
            print(f"{Fore.CYAN}  [{name}] {vtype} = 0x{val} ({int(val,16)}){Style.RESET_ALL}")

    # Deobfuscation pada semua nilai string
    string_vals = re.findall(r'"[^"]+"\s*=\s*"([^"]+)"', content)
    for val in string_vals:
        if len(val) > 6:
            analyze_deobfuscation(val, "REGISTRY-STRING")

    new_flags = list(found_flags_set)
    log_tool("registry-parser", "✅ Found" if new_flags else "⬜ Nothing",
             ", ".join(new_flags) if new_flags else f"parsed {filepath.name}")
    add_to_summary("REGISTRY-ANALYZED", f"Parsed '{filepath.name}'")
    print(f"{Fore.GREEN}[REGISTRY] Selesai. Output: {out_dir.name}{Style.RESET_ALL}")

# ── 2.5 BINARY DIGITS ANALYSIS ─────────────────────

def analyze_binary_digits(filepath, forced_width=None):
    """
    Solver untuk file berisi '0' dan '1' (Binary Digits challenge).
    Coba semua interpretasi secara otomatis.
    """
    print(f"\n{Fore.MAGENTA}{'='*60}")
    print(f"BINARY DIGITS ANALYSIS: {filepath.name}")
    print(f"{'='*60}{Style.RESET_ALL}")

    try:
        content = filepath.read_text(errors='ignore')
    except Exception as e:
        print(f"{Fore.RED}[BINARY] Error reading file: {e}{Style.RESET_ALL}")
        log_tool("binary-digits", "❌ Error", str(e))
        return

    # Bersihkan whitespace
    bits = re.sub(r'[^01]', '', content)
    
    if len(bits) < 8:
        print(f"{Fore.YELLOW}[BINARY] Tidak cukup bit untuk dianalisis ({len(bits)} bits){Style.RESET_ALL}")
        log_tool("binary-digits", "⬜ Nothing", "too few bits")
        return

    print(f"{Fore.CYAN}[BINARY] Total bits: {len(bits)}{Style.RESET_ALL}")
    print(f"{Fore.CYAN}[BINARY] Kemungkinan: {len(bits)//8} karakter ASCII (8-bit){Style.RESET_ALL}")
    if len(bits) % 8 == 0:
        print(f"{Fore.GREEN}[BINARY] ✓ Bit count is multiple of 8{Style.RESET_ALL}")
    elif len(bits) % 7 == 0:
        print(f"{Fore.YELLOW}[BINARY] ⚠ Bit count is multiple of 7 (7-bit ASCII mode){Style.RESET_ALL}")

    results = {}
    found_any = False

    # --- Interpretasi 1: 8-bit chunks → ASCII (MSB first) ---
    if len(bits) % 8 == 0:
        try:
            chars = []
            for i in range(0, len(bits), 8):
                byte_val = int(bits[i:i+8], 2)
                if 32 <= byte_val <= 126 or byte_val in [10, 13, 9]:  # printable + whitespace
                    chars.append(chr(byte_val))
                else:
                    chars.append('?')
            text = ''.join(chars)
            printable_ratio = sum(1 for c in text if c.isprintable() or c in '\n\r\t') / len(text)
            if printable_ratio > 0.7:
                results['8bit_msb'] = text
                print(f"\n{Fore.GREEN}[BINARY] 8-bit MSB: {text[:80]}{'...' if len(text) > 80 else ''}{Style.RESET_ALL}")
                scan_text_for_flags(text, "BINARY-8BIT-MSB")
                found_any = True
        except Exception as e:
            pass

    # --- Interpretasi BARU: raw_bytes → cek image magic (Stage B - CyberChef mode) ---
    if len(bits) % 8 == 0:
        try:
            # Convert bits → raw bytes (MSB-first)
            raw_bytes = bytes(
                int(bits[i:i+8], 2)
                for i in range(0, len(bits), 8)
            )

            # Coba render sebagai image (Stage B)
            rendered = render_image_from_bytes(raw_bytes, filepath, label="msb")
            if rendered:
                found_any = True
                add_to_summary("BIN-RENDER", f"Image extracted: {rendered.name}")

            # Juga coba LSB-first (bit-reversed per byte)
            raw_bytes_lsb = bytes(
                int(bits[i:i+8][::-1], 2)   # bit-reversed per byte
                for i in range(0, len(bits), 8)
            )
            rendered_lsb = render_image_from_bytes(raw_bytes_lsb, filepath, label="lsb")
            if rendered_lsb:
                found_any = True
                add_to_summary("BIN-RENDER-LSB", f"Image extracted (LSB): {rendered_lsb.name}")

        except Exception as e:
            print(f"{Fore.YELLOW}[BIN-RENDER] Gagal: {e}{Style.RESET_ALL}")

    # --- Interpretasi 2: 8-bit LSB first (bit reversed per byte) ---
    if len(bits) % 8 == 0:
        try:
            chars = []
            for i in range(0, len(bits), 8):
                byte_val = int(bits[i:i+8][::-1], 2)
                if 32 <= byte_val <= 126 or byte_val in [10, 13, 9]:
                    chars.append(chr(byte_val))
                else:
                    chars.append('?')
            text = ''.join(chars)
            printable_ratio = sum(1 for c in text if c.isprintable() or c in '\n\r\t') / len(text)
            if printable_ratio > 0.7:
                results['8bit_lsb'] = text
                print(f"{Fore.GREEN}[BINARY] 8-bit LSB: {text[:80]}{'...' if len(text) > 80 else ''}{Style.RESET_ALL}")
                scan_text_for_flags(text, "BINARY-8BIT-LSB")
                found_any = True
        except Exception as e:
            pass

    # --- Interpretasi 3: 7-bit ASCII ---
    if len(bits) % 7 == 0:
        try:
            chars = []
            for i in range(0, len(bits), 7):
                byte_val = int(bits[i:i+7], 2)
                if 32 <= byte_val <= 126 or byte_val in [10, 13, 9]:
                    chars.append(chr(byte_val))
                else:
                    chars.append('?')
            text = ''.join(chars)
            printable_ratio = sum(1 for c in text if c.isprintable() or c in '\n\r\t') / len(text)
            if printable_ratio > 0.7:
                results['7bit_ascii'] = text
                print(f"{Fore.GREEN}[BINARY] 7-bit ASCII: {text[:80]}{'...' if len(text) > 80 else ''}{Style.RESET_ALL}")
                scan_text_for_flags(text, "BINARY-7BIT")
                found_any = True
        except Exception as e:
            pass

    # --- Interpretasi 4: Reverse seluruh string ---
    bits_rev = bits[::-1]
    if len(bits_rev) % 8 == 0:
        try:
            chars = []
            for i in range(0, len(bits_rev), 8):
                byte_val = int(bits_rev[i:i+8], 2)
                if 32 <= byte_val <= 126 or byte_val in [10, 13, 9]:
                    chars.append(chr(byte_val))
                else:
                    chars.append('?')
            text = ''.join(chars)
            printable_ratio = sum(1 for c in text if c.isprintable() or c in '\n\r\t') / len(text)
            if printable_ratio > 0.7:
                results['8bit_msb_reversed'] = text
                print(f"{Fore.GREEN}[BINARY] 8-bit MSB (reversed): {text[:80]}{'...' if len(text) > 80 else ''}{Style.RESET_ALL}")
                scan_text_for_flags(text, "BINARY-REVERSED")
                found_any = True
        except Exception as e:
            pass

    # --- Interpretasi 5: Rekonstruksi gambar (1 bit = 1 pixel) ---
    total_bits = len(bits)
    rendered_images = []
    
    # Width brute-force - cari lebar yang masuk akal
    widths_to_try = [8, 16, 24, 32, 40, 48, 56, 64, 80, 100, 120, 128, 200, 256, 320, 512]
    
    # Jika forced_width diberikan, coba itu dulu
    if forced_width and forced_width > 0:
        if forced_width not in widths_to_try:
            widths_to_try.insert(0, forced_width)
    
    for width in widths_to_try:
        if total_bits % width == 0:
            height = total_bits // width
            if 4 <= height <= 2000:
                img_path = _render_binary_as_image(bits, width, height, filepath)
                if img_path:
                    rendered_images.append((width, height, img_path))
                    # Scan strings pada gambar
                    try:
                        strings_out = subprocess.getoutput(f"strings '{img_path}'")
                        if strings_out:
                            scan_text_for_flags(strings_out, f"BINARY-IMG-{width}x{height}")
                    except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))

    if rendered_images:
        print(f"\n{Fore.GREEN}[BINARY-IMG] {len(rendered_images)} image(s) rendered{Style.RESET_ALL}")
        for w, h, path in rendered_images:
            print(f"{Fore.CYAN}  • {w}x{h} → {path.name}{Style.RESET_ALL}")
        found_any = True

    if not found_any:
        print(f"{Fore.YELLOW}[BINARY] Tidak ada interpretasi yang menghasilkan teks valid{Style.RESET_ALL}")
        log_tool("binary-digits", "⬜ Nothing", "no valid interpretation")
    else:
        new_flags = list(found_flags_set)
        log_tool("binary-digits", "✅ Found" if new_flags else "⬜ Analyzed",
                 ", ".join(new_flags) if new_flags else f"binary analysis on {filepath.name}")

def _render_binary_as_image(bits, width, height, source_filepath):
    """Render string bit sebagai gambar hitam-putih, simpan sebagai PNG."""
    try:
        img = Image.new('1', (width, height))  # mode '1' = 1-bit pixels
        pixels = [int(b) * 255 for b in bits[:width*height]]
        img.putdata(pixels)

        # Buat nama output yang unik
        out_name = f"{source_filepath.stem}_bin_w{width}h{height}.png"
        out_path = source_filepath.parent / out_name

        # Jika file sudah ada, tambahkan suffix angka
        counter = 1
        while out_path.exists():
            out_name = f"{source_filepath.stem}_bin_w{width}h{height}_{counter}.png"
            out_path = source_filepath.parent / out_name
            counter += 1

        img.save(str(out_path))
        print(f"{Fore.CYAN}[BINARY-IMG] Rendered {width}x{height} → {out_path.name}{Style.RESET_ALL}")
        return out_path
    except Exception as e:
        print(f"{Fore.RED}[BINARY-IMG] Error rendering image: {e}{Style.RESET_ALL}")
        return None

def render_image_from_bytes(raw_bytes, source_filepath, label=""):
    """
    Stage B: jika bytes array mengandung magic bytes gambar,
    langsung buka dengan PIL dan simpan — persis seperti CyberChef 'Render Image'.
    """
    try:
        from io import BytesIO

        IMAGE_MAGIC = {
            b'\x89PNG':     ('png', 'PNG'),
            b'\xFF\xD8\xFF':('jpg', 'JPEG'),
            b'GIF8':        ('gif', 'GIF'),
            b'BM':          ('bmp', 'BMP'),
            b'RIFF':        ('webp','WebP'),
        }

        # Cek magic bytes
        header = raw_bytes[:8]
        detected = None
        for sig, (ext, fmt) in IMAGE_MAGIC.items():
            if header[:len(sig)] == sig:
                detected = (ext, fmt)
                break

        # Buat output directory
        out_dir = source_filepath.parent / f"{source_filepath.stem}_binary_render"
        out_dir.mkdir(exist_ok=True)

        if detected:
            ext, fmt = detected
            out_path = out_dir / f"{source_filepath.stem}_{label}_extracted.{ext}"
            out_path.write_bytes(raw_bytes)
            print(f"{Fore.GREEN}[BIN-RENDER] Magic bytes {fmt} terdeteksi! → {out_path.name}{Style.RESET_ALL}")

            # Buka dan re-save via PIL (normalize)
            try:
                img = Image.open(BytesIO(raw_bytes))
                normalized = out_dir / f"{source_filepath.stem}_{label}_rendered.png"
                img.save(str(normalized))
                print(f"{Fore.GREEN}[BIN-RENDER] Image rendered: {normalized.name} ({img.size}, {img.mode}){Style.RESET_ALL}")
                add_to_summary("BIN-RENDER-IMAGE", f"Rendered {fmt}: {normalized.name}")

                # Scan strings pada hasil
                try:
                    sr = subprocess.getoutput(f"strings '{normalized}'")
                    if sr:
                        scan_text_for_flags(sr, "BIN-RENDER-STRINGS")
                except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))

                log_tool("binary-render", "✅ Found", f"Rendered {fmt} image: {normalized.name}")
                return normalized
            except Exception as e:
                print(f"{Fore.YELLOW}[BIN-RENDER] PIL open gagal: {e}{Style.RESET_ALL}")
                log_tool("binary-render", "⚠ Partial", f"Extracted {fmt} but PIL failed: {e}")
                return out_path

        else:
            # Tidak ada magic → coba render sebagai raw pixel (Mode C)
            print(f"{Fore.CYAN}[BIN-RENDER] Tidak ada image magic, mencoba raw pixel render...{Style.RESET_ALL}")
            
            # Coba berbagai width untuk render sebagai 1-bit image
            total_bytes = len(raw_bytes)
            total_bits = total_bytes * 8
            
            # Konversi raw bytes ke binary string
            bits = ''.join(format(byte, '08b') for byte in raw_bytes)
            
            widths_to_try = [8, 16, 24, 32, 40, 48, 56, 64, 80, 100, 120, 128, 200, 256]
            rendered_count = 0
            
            for width in widths_to_try:
                if total_bits % width == 0:
                    height = total_bits // width
                    if 4 <= height <= 2000:
                        try:
                            img = Image.new('1', (width, height))
                            pixels = [int(b) * 255 for b in bits[:width*height]]
                            img.putdata(pixels)
                            
                            out_name = f"{source_filepath.stem}_{label}_pixel_w{width}h{height}.png"
                            out_path = out_dir / out_name
                            img.save(str(out_path))
                            
                            print(f"{Fore.CYAN}[BIN-RENDER] Pixel render {width}x{height} → {out_name}{Style.RESET_ALL}")
                            rendered_count += 1
                            
                            # Scan strings
                            try:
                                sr = subprocess.getoutput(f"strings '{out_path}'")
                                if sr:
                                    scan_text_for_flags(sr, f"BIN-RENDER-PIXEL-{width}x{height}")
                            except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
                        except Exception as e:
                            print(f"{Fore.RED}[BIN-RENDER] Pixel render failed {width}x{height}: {e}{Style.RESET_ALL}")
            
            if rendered_count > 0:
                add_to_summary("BIN-RENDER-PIXEL", f"Rendered {rendered_count} pixel images")
                log_tool("binary-render", "✅ Found", f"Rendered {rendered_count} pixel images")
            
            return None

    except Exception as e:
        print(f"{Fore.RED}[BIN-RENDER] Error: {e}{Style.RESET_ALL}")
        log_tool("binary-render", "❌ Error", str(e))
        return None

def analyze_morse(filepath):
    """Decode Morse code dari file teks"""
    print(f"\n{Fore.MAGENTA}[MORSE] Analisis Morse code...{Style.RESET_ALL}")
    
    try:
        content = filepath.read_text(errors='ignore')
    except Exception as e:
        print(f"{Fore.RED}[MORSE] Error reading file: {e}{Style.RESET_ALL}")
        log_tool("morse", "❌ Error", str(e))
        return

    # Morse code dictionary
    MORSE_CODE = {
        '.-': 'A', '-...': 'B', '-.-.': 'C', '-..': 'D', '.': 'E',
        '..-.': 'F', '--.': 'G', '....': 'H', '..': 'I', '.---': 'J',
        '-.-': 'K', '.-..': 'L', '--': 'M', '-.': 'N', '---': 'O',
        '.--.': 'P', '--.-': 'Q', '.-.': 'R', '...': 'S', '-': 'T',
        '..-': 'U', '...-': 'V', '.--': 'W', '-..-': 'X', '-.--': 'Y',
        '--..': 'Z', '-----': '0', '.----': '1', '..---': '2', '...--': '3',
        '....-': '4', '.....': '5', '-....': '6', '--...': '7', '---..': '8',
        '----.': '9', '.-.-.-': '.', '--..--': ',', '..--..': '?', '.----.': "'",
        '-.-.--': '!', '-..-.': '/', '-.--.': '(', '-.--.-': ')', '.-...': '&',
        '---...': ':', '-.-.-.': ';', '-...-': '=', '.-.-.': '+', '-....-': '-',
        '..--.-': '_', '.-..-.': '"', '...-..-': '$', '.--.-.': '@', '/': ' ',
    }

    # Cari pattern morse (huruf dipisah spasi, kata dipisah /)
    morse_pattern = r'[.\-/ ]{5,}'
    matches = re.findall(morse_pattern, content)
    
    found_any = False
    for morse_text in matches:
        try:
            # Bersihkan dan decode
            morse_text = morse_text.strip()
            words = morse_text.split('/')
            decoded = []
            
            for word in words:
                chars = word.strip().split()
                decoded_word = ''
                for char in chars:
                    if char in MORSE_CODE:
                        decoded_word += MORSE_CODE[char]
                    else:
                        decoded_word += '?'
                decoded.append(decoded_word)
            
            result = ' '.join(decoded)
            if result and len(result) > 3:
                print(f"{Fore.GREEN}[MORSE] {morse_text[:60]} → {result}{Style.RESET_ALL}")
                scan_text_for_flags(result, "MORSE")
                found_any = True
        except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
    
    if not found_any:
        print(f"{Fore.YELLOW}[MORSE] Tidak ada morse code ditemukan{Style.RESET_ALL}")
        log_tool("morse", "⬜ Nothing", "no morse found")
    else:
        new_flags = list(found_flags_set)
        log_tool("morse", "✅ Found" if new_flags else "⬜ Analyzed",
                 ", ".join(new_flags) if new_flags else "morse decoded")

def analyze_decimal_ascii(filepath):
    """Decode decimal ASCII dari file (contoh: 70 76 65 71 → FLAG)"""
    print(f"\n{Fore.MAGENTA}[DECIMAL] Analisis Decimal ASCII...{Style.RESET_ALL}")
    
    try:
        content = filepath.read_text(errors='ignore')
    except Exception as e:
        print(f"{Fore.RED}[DECIMAL] Error reading file: {e}{Style.RESET_ALL}")
        log_tool("decimal", "❌ Error", str(e))
        return

    # Cari pattern decimal (angka 32-126 dipisah spasi/koma)
    decimal_pattern = r'\b([0-9]{1,3}(?:[,\s]+[0-9]{1,3}){3,})\b'
    matches = re.findall(decimal_pattern, content)
    
    found_any = False
    for match in matches:
        try:
            # Pisahkan angka
            numbers = re.findall(r'\d+', match)
            decoded = []
            
            for num_str in numbers:
                num = int(num_str)
                if 32 <= num <= 126:
                    decoded.append(chr(num))
                elif num == 10 or num == 13:
                    decoded.append('\n')
                else:
                    decoded.append('?')
            
            result = ''.join(decoded)
            printable_ratio = sum(1 for c in result if c.isprintable() or c in '\n\r\t') / max(len(result), 1)
            
            if printable_ratio > 0.7 and len(result) > 3:
                print(f"{Fore.GREEN}[DECIMAL] {match[:60]} → {result[:80]}{'...' if len(result) > 80 else ''}{Style.RESET_ALL}")
                scan_text_for_flags(result, "DECIMAL")
                found_any = True
        except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
    
    if not found_any:
        print(f"{Fore.YELLOW}[DECIMAL] Tidak ada decimal ASCII ditemukan{Style.RESET_ALL}")
        log_tool("decimal", "⬜ Nothing", "no decimal found")
    else:
        new_flags = list(found_flags_set)
        log_tool("decimal", "✅ Found" if new_flags else "⬜ Analyzed",
                 ", ".join(new_flags) if new_flags else "decimal decoded")

# ── 3. LOG FILE ANALYSIS ─────────────────────

def analyze_log(filepath):
    """Analisis web server log (Apache/Nginx/IIS) — IP freq, attack pattern, flag di URL"""
    print(f"{Fore.GREEN}[LOG] Analisis web server log...{Style.RESET_ALL}")
    out_dir = filepath.parent / f"{filepath.stem}_log_analysis"
    out_dir.mkdir(exist_ok=True)

    try:
        content = filepath.read_text(encoding='utf-8', errors='ignore')
    except:
        content = filepath.read_bytes().decode('latin-1', errors='ignore')

    lines = [l for l in content.splitlines() if l.strip()]
    print(f"{Fore.CYAN}[LOG] {len(lines)} baris ditemukan{Style.RESET_ALL}")

    # ── Scan flag langsung di log
    print(f"{Fore.CYAN}[LOG] Scan flag di URL/path...{Style.RESET_ALL}")
    flags_found = scan_text_for_flags(content, "LOG")
    collect_base64_from_text(content)

    # ── IP frequency analysis
    ip_counts = {}
    ip_pat = re.compile(r'^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})')
    for line in lines:
        m = ip_pat.match(line)
        if m:
            ip = m.group(1)
            ip_counts[ip] = ip_counts.get(ip, 0) + 1

    if ip_counts:
        sorted_ips = sorted(ip_counts.items(), key=lambda x:x[1], reverse=True)
        print(f"\n{Fore.CYAN}[LOG] Top IP Addresses:{Style.RESET_ALL}")
        for ip, cnt in sorted_ips[:10]:
            marker = f" {Fore.RED}← MENCURIGAKAN!{Style.RESET_ALL}" if cnt >= 5 and cnt == sorted_ips[0][1] and len(sorted_ips) > 1 else ""
            print(f"  {cnt:>6}x  {ip}{marker}")
        add_to_summary("LOG-IP-FREQ", f"Top IP: {sorted_ips[0][0]} ({sorted_ips[0][1]} hits)")

    # ── Attack pattern detection (untuk identify suspicious IPs)
    print(f"\n{Fore.CYAN}[LOG] Deteksi attack patterns...{Style.RESET_ALL}")
    attack_sigs = {
        'Path Traversal':    r'(\.\./|%2e%2e%2f|\.\.%2f|%2e%2e/)',
        'SQL Injection':     r'(\bunion\b|\bselect\b|\binsert\b|\bdrop\b|%27|\'|1=1)',
        'XSS':               r'(<script|javascript:|onerror=|onload=|alert\()',
        'LFI/RFI':           r'(etc/passwd|etc/shadow|win\.ini|/proc/self)',
        'Command Injection': r'(;|\||&&|\$\(|`)\s*(cat|ls|pwd|whoami|id|wget|curl)',
        'Scanner/Recon':     r'(nikto|nmap|sqlmap|dirb|gobuster|masscan|wfuzz)',
        'Webshell':          r'(cmd=|exec=|system=|passthru=|shell\.php|webshell)',
    }
    
    # Track IP mana yang melakukan attack
    attacker_ips = {}
    for line in lines:
        for attack_name, pattern in attack_sigs.items():
            if re.search(pattern, line, re.IGNORECASE):
                m = ip_pat.match(line)
                if m:
                    ip = m.group(1)
                    if ip not in attacker_ips:
                        attacker_ips[ip] = set()
                    attacker_ips[ip].add(attack_name)
    
    # Print attack summary
    for attack, pat in attack_sigs.items():
        matches = re.findall(pat, content, re.IGNORECASE)
        if matches:
            print(f"  {Fore.RED}[!] {attack}: {len(matches)} hit(s){Style.RESET_ALL}")
            add_to_summary("LOG-ATTACK", f"{attack}: {len(matches)} hits")
    
    # ── Identify suspicious IPs (yang melakukan attack, bukan hanya yang paling banyak)
    suspicious_ips = []
    if attacker_ips:
        print(f"\n{Fore.RED}[LOG] IP MENCURIGAKAN (melakukan attack):{Style.RESET_ALL}")
        for ip, attacks in attacker_ips.items():
            print(f"  {Fore.RED}🎯 {ip} — Attacks: {', '.join(attacks)}{Style.RESET_ALL}")
            suspicious_ips.append(ip)
            add_to_summary("LOG-SUSPICIOUS-IP", f"{ip} ({', '.join(attacks)})")

    # Jika tidak ada IP mencurigakan dari attack pattern, gunakan IP dengan frequency tertinggi
    if not suspicious_ips and ip_counts:
        suspicious_ips = [sorted_ips[0][0]]
        print(f"\n{Fore.YELLOW}[LOG] Tidak ada attack pattern terdeteksi. Menganalisis IP teratas: {suspicious_ips[0]}{Style.RESET_ALL}")

    # ── Analisis per suspicious IP
    for attacker_ip in suspicious_ips:
        attacker_lines = [l for l in lines if l.startswith(attacker_ip)]
        print(f"\n{Fore.YELLOW}{'='*60}{Style.RESET_ALL}")
        print(f"{Fore.YELLOW}[LOG] TIMELINE SERANGAN — IP: {attacker_ip}{Style.RESET_ALL}")
        print(f"{Fore.YELLOW}[LOG] Total requests: {len(attacker_lines)}{Style.RESET_ALL}")
        print(f"{Fore.YELLOW}{'='*60}{Style.RESET_ALL}")
        
        # Save all attacker requests
        (out_dir / f"attacker_{attacker_ip.replace('.','_')}_all.txt").write_text('\n'.join(attacker_lines))
        
        # ── Extract URL paths from attacker requests
        url_pattern = re.compile(r'"(GET|POST|PUT|DELETE|HEAD|OPTIONS|PATCH)\s+(\S+)\s+HTTP')
        status_pattern = re.compile(r'HTTP/\d\.\d"\s+(\d{3})\s+(\d+)')
        time_pattern = re.compile(r'\[(\d{2}/\w+/\d{4}:\d{2}:\d{2}:\d{2})')
        
        print(f"\n{Fore.CYAN}[LOG] Timeline aktivitas penyerang:{Style.RESET_ALL}")
        print(f"{'Waktu':<22} {'Method':<10} {'URL Path':<50} {'Status':<8} {'Keterangan'}")
        print(f"{'─'*22} {'─'*10} {'─'*50} {'─'*8} {'─'*30}")
        
        timeline_data = []
        for line in attacker_lines:
            # Extract timestamp
            time_match = time_pattern.search(line)
            timestamp = time_match.group(1) if time_match else "?"
            
            # Extract method and URL
            url_match = url_pattern.search(line)
            if url_match:
                method = url_match.group(1)
                url_path = url_match.group(2)
            else:
                method = "?"
                url_path = "?"
            
            # Extract status code
            status_match = status_pattern.search(line)
            status = status_match.group(1) if status_match else "?"
            size = status_match.group(2) if status_match else "?"
            
            # Determine description
            description = ""
            if status == "200":
                description = f"{Fore.GREEN}✓ BERHASIL{Style.RESET_ALL}"
            elif status in ["400", "403"]:
                description = f"{Fore.RED}✗ Ditolak{Style.RESET_ALL}"
            elif status == "404":
                description = f"{Fore.YELLOW}✗ Not Found{Style.RESET_ALL}"
            
            # Scan for flag in URL path
            for pat in COMMON_FLAG_PATTERNS:
                flag_matches = re.findall(pat, url_path, re.IGNORECASE)
                if flag_matches:
                    for flag in flag_matches:
                        # Clean flag: ganti [ → { dan ] → }
                        flag_clean = flag.strip().replace('[', '{').replace(']', '}')
                        # Normalize ke format standard
                        if 'CTF{' in flag_clean or 'FLAG{' in flag_clean.upper():
                            print(f"\n{Fore.GREEN}{'='*60}{Style.RESET_ALL}")
                            print(f"{Fore.GREEN}🚩 FLAG DITEMUKAN di URL!{Style.RESET_ALL}")
                            print(f"{Fore.GREEN}   {flag_clean}{Style.RESET_ALL}")
                            print(f"{Fore.GREEN}{'='*60}{Style.RESET_ALL}")
                            add_to_summary("LOG-FLAG-IN-URL", flag_clean)
                            signal_flag_found()
            
            # Add to timeline data for sorting
            timeline_data.append({
                'timestamp': timestamp,
                'method': method,
                'url': url_path,
                'status': status,
                'description': description,
                'line': line
            })
        
        # Sort by timestamp dan tampilkan
        timeline_data.sort(key=lambda x: x['timestamp'])
        for entry in timeline_data:
            # Truncate URL jika terlalu panjang
            url_display = entry['url'][:48] + '...' if len(entry['url']) > 50 else entry['url']
            print(f"{entry['timestamp']:<22} {entry['method']:<10} {url_display:<50} {entry['status']:<8} {entry['description']}")
        
        # ── Analisis khusus: requests yang berhasil (200 OK)
        ok_requests = [l for l in attacker_lines if '" 200 ' in l]
        if ok_requests:
            print(f"\n{Fore.GREEN}[LOG] ✓ Requests yang BERHASIL (200 OK) dari penyerang: {len(ok_requests)}{Style.RESET_ALL}")
            for line in ok_requests:
                print(f"  → {line}")
                # Scan flag di successful requests
                scan_text_for_flags(line, "LOG-ATTACKER-200")
            (out_dir / f"attacker_{attacker_ip.replace('.','_')}_success.txt").write_text('\n'.join(ok_requests))
        
        # ── Analisis khusus: requests yang gagal (400, 403, 404)
        failed_requests = [l for l in attacker_lines if any(f'" {code} ' in l for code in ['400', '403', '404'])]
        if failed_requests:
            print(f"\n{Fore.RED}[LOG] ✗ Requests yang GAGAL dari penyerang: {len(failed_requests)}{Style.RESET_ALL}")
            for line in failed_requests[:10]:  # Limit to 10
                print(f"  → {line[:120]}")
            if len(failed_requests) > 10:
                print(f"  ... dan {len(failed_requests) - 10} request lainnya")
    
    # ── HTTP status analysis (global)
    status_counts = {}
    status_pat = re.compile(r'" (\d{3}) ')
    for line in lines:
        m = status_pat.search(line)
        if m:
            s = m.group(1)
            status_counts[s] = status_counts.get(s, 0) + 1
    if status_counts:
        print(f"\n{Fore.CYAN}[LOG] HTTP Status Distribution (Global):{Style.RESET_ALL}")
        for code, cnt in sorted(status_counts.items()):
            color = Fore.GREEN if code.startswith('2') else Fore.YELLOW if code.startswith('3') else Fore.RED
            print(f"  {color}{code}: {cnt} requests{Style.RESET_ALL}")

    # ── Timeline (global)
    time_pat = re.compile(r'\[(\d{2}/\w+/\d{4}:\d{2}:\d{2}:\d{2})')
    timestamps = [time_pat.search(l).group(1) for l in lines if time_pat.search(l)]
    if timestamps:
        print(f"\n{Fore.CYAN}[LOG] Timeline Global: {timestamps[0]} → {timestamps[-1]}{Style.RESET_ALL}")
        add_to_summary("LOG-TIMELINE", f"{timestamps[0]} → {timestamps[-1]}")

    (out_dir / "full_analysis.txt").write_text(
        f"Log Analysis: {filepath.name}\n"
        f"Total lines: {len(lines)}\n"
        f"IPs: {len(ip_counts)}\n"
        f"Suspicious IPs: {len(suspicious_ips)}\n"
        f"Flags: {flags_found}\n")

    new_flags = list(found_flags_set)
    log_tool("log-analyzer", "✅ Found" if new_flags else "⬜ Nothing",
             ", ".join(new_flags) if new_flags else f"{len(lines)} lines analyzed, no flag")
    add_to_summary("LOG-ANALYZED", f"Parsed '{filepath.name}' ({len(lines)} lines)")
    print(f"{Fore.GREEN}[LOG] Selesai. Output: {out_dir.name}{Style.RESET_ALL}")

# ── 4. AUTORUN / INF ANALYSIS ────────────────

def analyze_autorun(filepath):
    """Parse .inf / autorun.inf, deteksi reverse string & encoding di komentar"""
    print(f"{Fore.GREEN}[AUTORUN] Analisis autorun/INF file...{Style.RESET_ALL}")
    out_dir = filepath.parent / f"{filepath.stem}_autorun"
    out_dir.mkdir(exist_ok=True)

    try:
        content = filepath.read_text(encoding='utf-8', errors='ignore')
    except:
        content = filepath.read_bytes().decode('latin-1', errors='ignore')

    print(f"{Fore.CYAN}[AUTORUN] Isi file:{Style.RESET_ALL}")
    print(content)

    # Scan flag langsung
    scan_text_for_flags(content, "AUTORUN")

    # Scan semua komentar (baris yang dimulai ; atau #)
    comments = [l.strip() for l in content.splitlines()
                if l.strip().startswith(';') or l.strip().startswith('#')]
    if comments:
        print(f"\n{Fore.CYAN}[AUTORUN] {len(comments)} komentar ditemukan:{Style.RESET_ALL}")
        for comment in comments:
            print(f"  {Fore.YELLOW}{comment}{Style.RESET_ALL}")
            # Strip ; atau #
            clean = comment.lstrip(';#').strip()

            # Scan flag di komentar
            scan_text_for_flags(clean, "AUTORUN-COMMENT")

            # Deobfuscation pada komentar
            if len(clean) > 6:
                results = deobfuscate_string(clean)

                # Cek reverse
                rev = results.get('reverse','')
                print(f"    Reverse: {rev}")
                scan_text_for_flags(rev, "AUTORUN-REVERSE")

                # Cek ROT13
                rot = results.get('rot13','')
                for pat in COMMON_FLAG_PATTERNS:
                    if re.search(pat, rot, re.IGNORECASE):
                        print(f"{Fore.GREEN}    ROT13: {rot}{Style.RESET_ALL}")
                        scan_text_for_flags(rot, "AUTORUN-ROT13")

                # Cek Base64
                b64 = results.get('base64')
                if b64:
                    print(f"    Base64: {b64}")
                    scan_text_for_flags(b64, "AUTORUN-B64")

                # Caesar brute
                for shift in range(1,26):
                    shifted = results.get(f'caesar_{shift}','')
                    for pat in COMMON_FLAG_PATTERNS:
                        if re.search(pat, shifted, re.IGNORECASE):
                            print(f"{Fore.GREEN}    Caesar +{shift}: {shifted}{Style.RESET_ALL}")
                            scan_text_for_flags(shifted, f"AUTORUN-CAESAR{shift}")

    # Scan nilai semua key
    for m in re.findall(r'^[^;#\[].+=(.+)$', content, re.MULTILINE):
        val = m.strip()
        if len(val) > 4:
            scan_text_for_flags(val, "AUTORUN-VALUE")
            analyze_deobfuscation(val, "AUTORUN-VALUE")

    # Scan checksums / hashes
    for m in re.findall(r'[0-9a-f]{32,}', content, re.IGNORECASE):
        print(f"{Fore.CYAN}[AUTORUN] Hash/checksum: {m}{Style.RESET_ALL}")
        add_to_summary("AUTORUN-HASH", m)

    new_flags = list(found_flags_set)
    log_tool("autorun-parser", "✅ Found" if new_flags else "⬜ Nothing",
             ", ".join(new_flags) if new_flags else "tidak ada flag/encoding tersembunyi")
    add_to_summary("AUTORUN-ANALYZED", f"Parsed '{filepath.name}'")
    print(f"{Fore.GREEN}[AUTORUN] Selesai.{Style.RESET_ALL}")

# ── 5. ZIP PASSWORD CRACK & FORENSIC ─────────────────────

# CTF-specific wordlist — lebih efisien dari rockyou untuk kompetisi
CTF_WORDLIST = [
    "", "password", "123456", "admin", "root", "test", "guest",
    "flag", "ctf", "secret", "hidden", "steg", "crypto", "forensics",
    "picoctf", "lks", "dsj", "smk", "2024", "2025", "2026",
    "password123", "admin123", "ctf2025", "ctf2026",
    "P@ssw0rd", "s3cr3t", "fl4g", "h4ck3r",
    "rahasia", "kunci", "sandi", "indonesia",
    "challenge", "chall", "answer", "solution", "key",
    "phantom", "shadow", "master", "dragon", "sunshine",
    "letmein", "monkey", "qwerty", "abc123",
]


def _generate_context_passwords(filepath):
    """Generate passwords berdasarkan konteks file — sangat efektif di CTF"""
    passwords = []
    stem = filepath.stem
    name = filepath.name
    parent = filepath.parent.name

    # Dari nama file dan direktori
    candidates = [stem, name, parent]
    for base in candidates:
        if not base:
            continue
        passwords.extend([
            base,
            base.lower(),
            base.upper(),
            base.capitalize(),
            base + "123",
            base + "2025",
            base + "2026",
            base.lower() + "123",
            base.lower() + "!",
            base + "_ctf",
            "ctf_" + base,
            base + "2024",
            base.lower() + "2026",
        ])

    # Deduplicate dan filter kosong
    return list(dict.fromkeys(p for p in passwords if p))


def _try_passwords_zip(filepath, out_dir, passwords, label="CTX"):
    """Coba list password dengan Python zipfile — akurat dan reliable"""
    import zipfile

    print(f"{Fore.CYAN}[ZIP-CRACK] Trying {len(passwords)} passwords ({label})...{Style.RESET_ALL}")

    for pw in passwords:
        try:
            with zipfile.ZipFile(filepath) as zf:
                zf.extractall(out_dir, pwd=pw.encode('utf-8') if pw else b'')

            # Berhasil!
            pw_display = f"'{pw}'" if pw else "(empty)"
            print(f"{Fore.GREEN}[ZIP-CRACK] ✅ Password ditemukan: {pw_display}{Style.RESET_ALL}")
            add_to_summary("ZIP-PASSWORD", f"Password: {pw_display} [{label}]")
            log_tool("zipcrack", "✅ Found", f"Password: {pw_display}")
            _scan_extracted_dir(out_dir, f"ZIP-{label}")
            return pw
        except (RuntimeError, zipfile.BadZipFile):
            continue
        except Exception:
            continue

    return None


def _try_passwords_zip_threaded(filepath, out_dir, passwords, label="ROCKYOU", workers=8):
    """Parallel password cracking dengan ThreadPoolExecutor"""
    import zipfile

    print(f"{Fore.CYAN}[ZIP-CRACK] Threaded crack ({workers} workers): {len(passwords)} passwords ({label})...{Style.RESET_ALL}")

    found = {"pw": None}

    def try_one(pw):
        if found["pw"] is not None:
            return None
        try:
            with zipfile.ZipFile(filepath) as zf:
                zf.extractall(out_dir, pwd=pw.encode('utf-8') if pw else b'')
            return pw
        except:
            return None

    with ThreadPoolExecutor(max_workers=workers) as ex:
        futures = {ex.submit(try_one, pw): pw for pw in passwords}
        for future in as_completed(futures):
            result = future.result()
            if result is not None and found["pw"] is None:
                found["pw"] = result
                pw_display = f"'{result}'" if result else "(empty)"
                print(f"{Fore.GREEN}[ZIP-CRACK] ✅ Password: {pw_display}{Style.RESET_ALL}")
                add_to_summary("ZIP-PASSWORD", f"Password: {pw_display} [{label}]")
                log_tool("zipcrack", "✅ Found", f"Password: {pw_display}")
                _scan_extracted_dir(out_dir, f"ZIP-{label}")

    return found["pw"]


def _crack_zip_with_fcrackzip(filepath, out_dir, wordlist_path=None):
    """Crack menggunakan fcrackzip — jauh lebih cepat dari Python loop"""
    if not AVAILABLE_TOOLS.get('fcrackzip'):
        return None

    wl = wordlist_path
    if not wl:
        wl = next((p for p in ROCKYOU_PATHS if Path(p).exists()), None)
    if not wl:
        print(f"{Fore.YELLOW}[FCRACKZIP] Wordlist tidak ditemukan{Style.RESET_ALL}")
        return None

    print(f"{Fore.CYAN}[FCRACKZIP] Cracking dengan wordlist: {wl}...{Style.RESET_ALL}")

    try:
        result = subprocess.run(
            ["fcrackzip", "-v", "-u", "-D", "-p", wl, str(filepath)],
            capture_output=True, text=True, timeout=300
        )
        output = result.stdout + result.stderr

        # Parse output
        pw_match = re.search(r'PASSWORD FOUND.*?:\s*pw==(\S+)', output, re.IGNORECASE)
        if not pw_match:
            pw_match = re.search(r'possible pw found:\s*(\S+)', output, re.IGNORECASE)

        if pw_match:
            pw = pw_match.group(1).strip().strip("'\"")
            print(f"{Fore.GREEN}[FCRACKZIP] ✅ Password: '{pw}'{Style.RESET_ALL}")
            add_to_summary("ZIP-FCRACKZIP", f"Password: '{pw}'")
            # Ekstrak dengan password
            subprocess.run(
                ["unzip", "-o", "-P", pw, str(filepath), "-d", str(out_dir)],
                capture_output=True, timeout=30
            )
            _scan_extracted_dir(out_dir, "ZIP-FCRACKZIP")
            return pw

        print(f"{Fore.YELLOW}[FCRACKZIP] Password tidak ditemukan{Style.RESET_ALL}")
    except subprocess.TimeoutExpired:
        print(f"{Fore.YELLOW}[FCRACKZIP] Timeout (5 menit){Style.RESET_ALL}")
    except Exception as e:
        print(f"{Fore.RED}[FCRACKZIP] Error: {e}{Style.RESET_ALL}")

    return None


def _crack_zip_with_john(filepath, out_dir, wordlist_path=None):
    """Crack dengan John the Ripper via zip2john"""
    if not AVAILABLE_TOOLS.get('john'):
        return None

    # Cek apakah zip2john tersedia
    z2j = subprocess.run("which zip2john", shell=True, capture_output=True)
    if z2j.returncode != 0:
        print(f"{Fore.YELLOW}[JOHN-ZIP] zip2john tidak ditemukan{Style.RESET_ALL}")
        return None

    print(f"{Fore.CYAN}[JOHN-ZIP] Cracking dengan John the Ripper...{Style.RESET_ALL}")

    try:
        # Step 1: Extract hash dengan zip2john
        hash_file = out_dir / "zip.hash"
        z2j_result = subprocess.run(
            f"zip2john '{filepath}' > '{hash_file}'",
            shell=True, capture_output=True, text=True, timeout=30
        )

        if not hash_file.exists() or hash_file.stat().st_size == 0:
            print(f"{Fore.YELLOW}[JOHN-ZIP] zip2john gagal mengekstrak hash{Style.RESET_ALL}")
            return None

        print(f"{Fore.CYAN}[JOHN-ZIP] Hash diekstrak: {hash_file.read_text()[:80]}...{Style.RESET_ALL}")

        # Step 2: Crack dengan john
        wl = wordlist_path or next((p for p in ROCKYOU_PATHS if Path(p).exists()), None)
        pot_file = out_dir / "john.pot"

        cmd = ["john", str(hash_file), f"--pot={pot_file}"]
        if wl:
            cmd.append(f"--wordlist={wl}")

        subprocess.run(cmd, capture_output=True, text=True, timeout=300)

        # Step 3: Tampilkan hasil
        show_result = subprocess.run(
            ["john", "--show", str(hash_file), f"--pot={pot_file}"],
            capture_output=True, text=True, timeout=30
        )

        # Parse password dari output john --show
        pw_match = re.search(r':([^:]+):\$zip', show_result.stdout)
        if not pw_match:
            pw_match = re.search(r'\$zip\$.*?:([^:]+):', show_result.stdout)

        if show_result.stdout and "password hash" not in show_result.stdout.lower():
            # Coba parse langsung
            lines = show_result.stdout.strip().splitlines()
            for line in lines:
                if ':' in line and not line.startswith('No password'):
                    parts = line.split(':')
                    if len(parts) >= 2:
                        pw = parts[1]
                        print(f"{Fore.GREEN}[JOHN-ZIP] ✅ Password: '{pw}'{Style.RESET_ALL}")
                        add_to_summary("ZIP-JOHN", f"Password: '{pw}'")
                        subprocess.run(
                            ["unzip", "-o", "-P", pw, str(filepath), "-d", str(out_dir)],
                            capture_output=True, timeout=30
                        )
                        _scan_extracted_dir(out_dir, "ZIP-JOHN")
                        return pw

        print(f"{Fore.YELLOW}[JOHN-ZIP] Password tidak ditemukan{Style.RESET_ALL}")

    except subprocess.TimeoutExpired:
        print(f"{Fore.YELLOW}[JOHN-ZIP] Timeout{Style.RESET_ALL}")
    except Exception as e:
        print(f"{Fore.RED}[JOHN-ZIP] Error: {e}{Style.RESET_ALL}")

    return None


def forensic_zip_analysis(filepath, args=None):
    """Enhanced forensic ZIP analysis dengan evidence collection"""
    import zipfile
    from datetime import datetime
    
    print(f"\n{Fore.MAGENTA}{'='*60}")
    print(f"FORENSIC ANALYSIS: {filepath.name}")
    print(f"{'='*60}{Style.RESET_ALL}\n")
    
    # Create investigation directory
    inv_dir = filepath.parent / f"forensic_{filepath.stem}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    inv_dir.mkdir(exist_ok=True)
    print(f"{Fore.CYAN}[i] Investigation directory: {inv_dir}{Style.RESET_ALL}\n")
    
    # Phase 1: Information Gathering
    print(f"{Style.BRIGHT}{'─'*60}{Style.RESET_ALL}")
    print(f"{Style.BRIGHT}PHASE 1: Information Gathering{Style.RESET_ALL}")
    print(f"{Style.BRIGHT}{'─'*60}{Style.RESET_ALL}\n")
    
    # 1.1 Metadata extraction
    print(f"{Fore.CYAN}[1.1] Metadata Extraction (exiftool){Style.RESET_ALL}")
    try:
        meta_file = inv_dir / "metadata.txt"
        exif_result = subprocess.run(
            ["exiftool", str(filepath)],
            capture_output=True, text=True, timeout=10)
        if exif_result.stdout.strip():
            meta_file.write_text(exif_result.stdout)
            print(f"{Fore.GREEN}[✓] Metadata saved to {meta_file}{Style.RESET_ALL}")
            # Show key info
            for line in exif_result.stdout.splitlines():
                if any(x in line.lower() for x in ['bit flag', 'encrypted', 'password']):
                    print(f"  {Fore.YELLOW}{line.strip()}{Style.RESET_ALL}")
    except Exception as e:
        print(f"{Fore.YELLOW}[!] exiftool gagal: {e}{Style.RESET_ALL}")
    
    # 1.2 Strings extraction
    print(f"\n{Fore.CYAN}[1.2] Strings Extraction{Style.RESET_ALL}")
    try:
        strings_file = inv_dir / "strings.txt"
        strings_result = subprocess.run(
            ["strings", str(filepath)],
            capture_output=True, text=True, timeout=10)
        if strings_result.stdout.strip():
            strings_file.write_text(strings_result.stdout)
            lines = strings_result.stdout.strip().splitlines()
            print(f"{Fore.GREEN}[✓] Extracted {len(lines)} strings{Style.RESET_ALL}")
            # Cari clues
            clue_count = 0
            for line in lines:
                line = line.strip()
                if 3 <= len(line) <= 50 and line.isprintable():
                    if any(x in line.lower() for x in ['pass', 'key', 'secret', 'flag', 'ctf', 'admin']):
                        print(f"  {Fore.YELLOW}[CLUE] {line}{Style.RESET_ALL}")
                        clue_count += 1
                    scan_text_for_flags(line, "ZIP-STRINGS")
            if clue_count == 0:
                print(f"  {Fore.CYAN}Tidak ada clue menarik{Style.RESET_ALL}")
    except Exception as e:
        print(f"{Fore.YELLOW}[!] strings gagal: {e}{Style.RESET_ALL}")
    
    # 1.3 ZIP structure analysis
    print(f"\n{Fore.CYAN}[1.3] ZIP Structure Analysis{Style.RESET_ALL}")
    try:
        import zipfile
        with zipfile.ZipFile(filepath) as zf:
            members = zf.namelist()
            print(f"{Fore.GREEN}[✓] Isi ZIP: {members}{Style.RESET_ALL}")
            
            # Cek encryption
            needs_password = False
            for info in zf.infolist():
                if info.flag_bits & 0x1:
                    needs_password = True
                    print(f"  {Fore.YELLOW}[ENCRYPTED] {info.filename} (size: {info.file_size} bytes){Style.RESET_ALL}")
            
            if not needs_password:
                print(f"{Fore.GREEN}[✓] ZIP tidak terpassword!{Style.RESET_ALL}")
                out_dir = inv_dir / "extracted"
                out_dir.mkdir(exist_ok=True)
                zf.extractall(out_dir)
                _scan_extracted_dir(out_dir, "ZIP-NOPASS")
                return True
    except zipfile.BadZipFile:
        print(f"{Fore.RED}[✗] File bukan ZIP valid!{Style.RESET_ALL}")
        return False
    except RuntimeError as e:
        if "encrypted" in str(e).lower():
            print(f"{Fore.YELLOW}[✓] Terenkripsi, lanjut ke cracking...{Style.RESET_ALL}")
    
    # Phase 2: Password Recovery
    print(f"\n{Style.BRIGHT}{'─'*60}{Style.RESET_ALL}")
    print(f"{Style.BRIGHT}PHASE 2: Password Recovery{Style.RESET_ALL}")
    print(f"{Style.BRIGHT}{'─'*60}{Style.RESET_ALL}\n")
    
    out_dir = inv_dir / "extracted"
    out_dir.mkdir(exist_ok=True)
    
    # Strategy 1: Context passwords (cepat, <1 detik)
    print(f"{Fore.CYAN}[2.1] Context-aware passwords...{Style.RESET_ALL}")
    context_pw = _generate_context_passwords(filepath)
    found = _try_passwords_zip(filepath, out_dir, context_pw[:50], "CTX")
    if found:
        return True
    
    # Strategy 2: CTF wordlist (cepat, ~50 kata, <1 detik)
    print(f"\n{Fore.CYAN}[2.2] CTF wordlist ({len(CTF_WORDLIST)} passwords)...{Style.RESET_ALL}")
    found = _try_passwords_zip(filepath, out_dir, CTF_WORDLIST, "CTF")
    if found:
        return True
    
    # Strategy 3: fcrackzip dengan CTF wordlist (bukan rockyou!)
    if AVAILABLE_TOOLS.get('fcrackzip'):
        print(f"\n{Fore.CYAN}[2.3] fcrackzip (CTF wordlist)...{Style.RESET_ALL}")
        # Buat temp wordlist dari CTF_WORDLIST
        import tempfile
        with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as tmp_wl:
            tmp_wl.write('\n'.join(CTF_WORDLIST))
            tmp_wl_path = tmp_wl.name
        
        found = _crack_zip_with_fcrackzip(filepath, out_dir, tmp_wl_path)
        Path(tmp_wl_path).unlink(missing_ok=True)  # Cleanup temp file
        if found:
            return True
    
    # NOTE: Untuk forensic mode, kita skip strategi lambat (john/rockyou)
    # karena CTF biasanya pakai password sederhana.
    # Jika masih gagal, beri rekomendasi manual cracking.
    
    print(f"\n{Fore.YELLOW}[!] Password tidak ditemukan di wordlist CTF.{Style.RESET_ALL}")
    print(f"{Fore.CYAN}[i] Rekomendasi untuk cracking manual:{Style.RESET_ALL}")
    print(f"    1. fcrackzip + rockyou: fcrackzip -v -u -D -p /usr/share/wordlists/rockyou.txt {filepath.name}")
    print(f"    2. john the ripper: zip2john {filepath.name} > hash.txt && john hash.txt")
    print(f"    3. raven zipcrack: raven {filepath.name} --zipcrack")
    
    # Save investigation summary
    summary_file = inv_dir / "investigation_summary.txt"
    summary = f"""FORENSIC INVESTIGATION SUMMARY
================================
Target: {filepath.name}
Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
Result: Password not found in CTF wordlists

Strategies Used:
1. Context passwords ({len(context_pw[:50])} passwords)
2. CTF wordlist ({len(CTF_WORDLIST)} passwords)
3. fcrackzip + CTF wordlist

Recommendations for Manual Cracking:
1. fcrackzip -v -u -D -p /usr/share/wordlists/rockyou.txt {filepath.name}
2. zip2john {filepath.name} > hash.txt && john hash.txt
3. raven {filepath.name} --zipcrack
"""
    summary_file.write_text(summary)
    print(f"{Fore.CYAN}[i] Investigation summary saved to: {summary_file}{Style.RESET_ALL}")
    
    return False


def crack_zip(filepath, wordlist_path=None, args=None):
    """Enhanced ZIP cracker dengan multiple strategies (backward compatible)"""
    print(f"{Fore.GREEN}[ZIP-CRACK] Enhanced ZIP cracking...{Style.RESET_ALL}")
    out_dir = filepath.parent / f"{filepath.stem}_zipcrack"
    out_dir.mkdir(exist_ok=True)

    # ── Strategy 0: Cek apakah ZIP memang butuh password
    print(f"{Fore.CYAN}[ZIP-CRACK] Mengecek struktur ZIP...{Style.RESET_ALL}")
    try:
        import zipfile
        with zipfile.ZipFile(filepath) as zf:
            # List isi ZIP
            members = zf.namelist()
            print(f"{Fore.CYAN}[ZIP-CRACK] Isi ZIP: {members[:10]}{Style.RESET_ALL}")

            # Cek apakah ada file yang terenkripsi
            needs_password = False
            for info in zf.infolist():
                if info.flag_bits & 0x1:  # bit 0 = encrypted
                    needs_password = True
                    print(f"{Fore.YELLOW}[ZIP-CRACK] File terenkripsi: {info.filename}{Style.RESET_ALL}")

            if not needs_password:
                print(f"{Fore.GREEN}[ZIP-CRACK] ZIP tidak terpassword, langsung ekstrak!{Style.RESET_ALL}")
                zf.extractall(out_dir)
                _scan_extracted_dir(out_dir, "ZIP-NOPASS")
                log_tool("zipcrack", "✅ Found", "No password needed")
                return True
    except zipfile.BadZipFile:
        print(f"{Fore.RED}[ZIP-CRACK] File bukan ZIP yang valid!{Style.RESET_ALL}")
        return False
    except RuntimeError as e:
        if "encrypted" in str(e).lower():
            print(f"{Fore.YELLOW}[ZIP-CRACK] Terenkripsi, lanjut ke cracking...{Style.RESET_ALL}")

    # ── Strategy 1: Context-aware password generation
    print(f"\n{Fore.CYAN}[ZIP-CRACK] Generating context-aware passwords...{Style.RESET_ALL}")
    context_passwords = _generate_context_passwords(filepath)

    found_pw = _try_passwords_zip(filepath, out_dir, context_passwords, "CTX")
    if found_pw:
        return True

    # ── Strategy 2: CTF-specific wordlist (cepat, ~100 kata)
    print(f"\n{Fore.CYAN}[ZIP-CRACK] Mencoba CTF wordlist ({len(CTF_WORDLIST)} passwords)...{Style.RESET_ALL}")
    found_pw = _try_passwords_zip(filepath, out_dir, CTF_WORDLIST, "CTF")
    if found_pw:
        return True

    # ── Strategy 3: fcrackzip (tool terbaik, jika ada)
    if AVAILABLE_TOOLS.get('fcrackzip'):
        found_pw = _crack_zip_with_fcrackzip(filepath, out_dir, wordlist_path)
        if found_pw:
            return True

    # ── Strategy 4: john the ripper via zip2john
    if AVAILABLE_TOOLS.get('john'):
        found_pw = _crack_zip_with_john(filepath, out_dir, wordlist_path)
        if found_pw:
            return True

    # ── Strategy 5: Rockyou (lambat, last resort)
    print(f"\n{Fore.CYAN}[ZIP-CRACK] Last resort: rockyou.txt...{Style.RESET_ALL}")
    rockyou = next((p for p in ROCKYOU_PATHS if Path(p).exists()), None)
    if rockyou:
        wl = open(rockyou, errors='ignore').read().splitlines()[:200000]
        found_pw = _try_passwords_zip_threaded(filepath, out_dir, wl, "ROCKYOU")
        if found_pw:
            return True

    print(f"{Fore.RED}[ZIP-CRACK] Semua strategi gagal.{Style.RESET_ALL}")
    log_tool("zipcrack", "⬜ Nothing", "password tidak ditemukan")
    return False

def _scan_extracted_dir(out_dir, source):
    """Scan semua file yang diekstrak untuk flag"""
    for f in Path(out_dir).rglob("*"):
        if f.is_file():
            print(f"{Fore.CYAN}[EXTRACTED] {f.name}{Style.RESET_ALL}")
            try:
                txt = f.read_text(errors='ignore')
                scan_text_for_flags(txt, source)
                collect_base64_from_text(txt)
            except:
                try:
                    raw = f.read_bytes()
                    txt = raw.decode('latin-1', errors='ignore')
                    scan_text_for_flags(txt, source)
                except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
            # Juga jalankan strings
            sr = subprocess.getoutput(f"strings '{f}'")
            scan_text_for_flags(sr, f"{source}-STRINGS")

# ── 6. PDF PASSWORD CRACK ─────────────────────

def crack_pdf(filepath, wordlist_path=None):
    """Crack password PDF menggunakan pdfcrack"""
    print(f"{Fore.GREEN}[PDF-CRACK] Analisis PDF terproteksi...{Style.RESET_ALL}")
    out_dir = filepath.parent / f"{filepath.stem}_pdfcrack"
    out_dir.mkdir(exist_ok=True)

    # Cek apakah PDF terproteksi
    print(f"{Fore.CYAN}[PDF-CRACK] Mengecek proteksi PDF...{Style.RESET_ALL}")
    result = subprocess.run(
        ["pdfinfo", str(filepath)],
        capture_output=True, text=True, timeout=10)
    
    is_encrypted = False
    if "Encrypted" in result.stdout:
        is_encrypted = True
        print(f"{Fore.YELLOW}[PDF-CRACK] PDF terenkripsi!{Style.RESET_ALL}")
        add_to_summary("PDF-ENCRYPTED", f"{filepath.name} is password protected")
    
    if not is_encrypted:
        print(f"{Fore.GREEN}[PDF-CRACK] PDF tidak terproteksi{Style.RESET_ALL}")
        # Coba extract teks langsung
        try:
            result_txt = subprocess.run(
                ["pdftotext", str(filepath), str(out_dir / "content.txt")],
                capture_output=True, text=True, timeout=30)
            if result_txt.returncode == 0:
                print(f"{Fore.GREEN}[PDF-CRACK] Teks diekstrak ke {out_dir / 'content.txt'}{Style.RESET_ALL}")
                content = (out_dir / "content.txt").read_text(errors='ignore')
                scan_text_for_flags(content, "PDF-UNPROTECTED")
                collect_base64_from_text(content)
        except Exception as e:
            print(f"{Fore.YELLOW}[PDF-CRACK] Gagal extract teks: {e}{Style.RESET_ALL}")
        log_tool("pdfcrack", "⬜ Nothing", "PDF tidak terproteksi")
        return

    # Siapkan wordlist
    wl_lines = DEFAULT_WORDLIST[:]
    if wordlist_path and Path(wordlist_path).exists():
        wl_lines = Path(wordlist_path).read_text(errors='ignore').splitlines()[:50000]
        print(f"{Fore.CYAN}[PDF-CRACK] Wordlist custom: {len(wl_lines)} kata{Style.RESET_ALL}")
    else:
        for rp in ROCKYOU_PATHS:
            if Path(rp).exists():
                wl_lines = open(rp, errors='ignore').read().splitlines()[:100000]
                print(f"{Fore.CYAN}[PDF-CRACK] Rockyou: {len(wl_lines)} kata{Style.RESET_ALL}")
                break

    # Gunakan pdfcrack dengan wordlist
    if AVAILABLE_TOOLS.get('pdfcrack'):
        print(f"{Fore.CYAN}[PDF-CRACK] Mencoba crack dengan pdfcrack...{Style.RESET_ALL}")
        try:
            # pdfcrack dengan wordlist
            cmd = ["pdfcrack", str(filepath)]
            if wordlist_path:
                cmd.extend(["-w", wordlist_path])
            else:
                # Coba rockyou
                for rp in ROCKYOU_PATHS:
                    if Path(rp).exists():
                        cmd.extend(["-w", rp])
                        break
            
            result_crack = subprocess.run(
                cmd,
                capture_output=True, text=True, timeout=300)
            
            output = result_crack.stdout + result_crack.stderr
            
            # Cari password di output
            pw_match = re.search(r'found password:\s*(\S+)', output, re.IGNORECASE)
            if pw_match:
                pw = pw_match.group(1).strip()
                print(f"{Fore.GREEN}[PDF-CRACK] Password ditemukan: '{pw}'{Style.RESET_ALL}")
                add_to_summary("PDF-PASSWORD", f"Password: '{pw}'")
                
                # Coba extract dengan password
                try:
                    subprocess.run(
                        ["pdftotext", "-upw", pw, str(filepath), str(out_dir / "content.txt")],
                        capture_output=True, text=True, timeout=30)
                    content = (out_dir / "content.txt").read_text(errors='ignore')
                    scan_text_for_flags(content, "PDF-CRACKED")
                    collect_base64_from_text(content)
                except Exception as e:
                    print(f"{Fore.YELLOW}[PDF-CRACK] Gagal extract meski password ditemukan: {e}{Style.RESET_ALL}")
                return
            else:
                print(f"{Fore.YELLOW}[PDF-CRACK] Password tidak ditemukan{Style.RESET_ALL}")
                print(f"{Fore.CYAN}[PDF-CRACK] Output: {output[:500]}{Style.RESET_ALL}")
                
        except subprocess.TimeoutExpired:
            print(f"{Fore.YELLOW}[PDF-CRACK] Timeout setelah 5 menit{Style.RESET_ALL}")
        except Exception as e:
            print(f"{Fore.YELLOW}[PDF-CRACK] Error: {e}{Style.RESET_ALL}")
    else:
        print(f"{Fore.YELLOW}[PDF-CRACK] pdfcrack tidak terinstall{Style.RESET_ALL}")
        print(f"{Fore.CYAN}[PDF-CRACK] Install dengan: sudo apt install pdfcrack{Style.RESET_ALL}")
    
    log_tool("pdfcrack", "⬜ Nothing", "password tidak ditemukan")

# ── 7. HASH CRACK (JOHN THE RIPPER) ──────────

def crack_hash_john(filepath, wordlist_path=None, hash_type=None):
    """Crack hash menggunakan John the Ripper"""
    print(f"{Fore.GREEN}[JOHN] Analisis hash dengan John the Ripper...{Style.RESET_ALL}")
    out_dir = filepath.parent / f"{filepath.stem}_john"
    out_dir.mkdir(exist_ok=True)

    # Baca file hash
    try:
        hash_content = filepath.read_text(errors='ignore').strip()
        print(f"{Fore.CYAN}[JOHN] Hash: {hash_content[:80]}...{Style.RESET_ALL}")
    except Exception as e:
        print(f"{Fore.RED}[JOHN] Gagal membaca file: {e}{Style.RESET_ALL}")
        log_tool("john", "❌ Error", str(e))
        return

    # Siapkan wordlist
    wl = wordlist_path
    if not wl:
        for rp in ROCKYOU_PATHS:
            if Path(rp).exists():
                wl = rp
                print(f"{Fore.CYAN}[JOHN] Menggunakan rockyou.txt{Style.RESET_ALL}")
                break
    
    if not wl or not Path(wl).exists():
        print(f"{Fore.YELLOW}[JOHN] Wordlist tidak ditemukan{Style.RESET_ALL}")
        wl = None

    # Tentukan format hash jika tidak diberikan
    format_opt = []
    if hash_type:
        format_opt = ["--format=" + hash_type]
        print(f"{Fore.CYAN}[JOHN] Format: {hash_type}{Style.RESET_ALL}")

    # Jalankan john
    if AVAILABLE_TOOLS.get('john'):
        try:
            cmd = ["john", str(filepath)]
            if wl:
                cmd.extend(["--wordlist=" + wl])
            if format_opt:
                cmd.extend(format_opt)
            cmd.extend(["--pot=" + str(out_dir / "john.pot")])
            
            print(f"{Fore.CYAN}[JOHN] Running: {' '.join(cmd)}{Style.RESET_ALL}")
            result = subprocess.run(
                cmd,
                capture_output=True, text=True, timeout=600)
            
            output = result.stdout + result.stderr
            print(f"{Fore.CYAN}[JOHN] Output:{Style.RESET_ALL}\n{output[:1000]}")
            
            # Tampilkan hasil
            show_cmd = ["john", "--show", str(filepath)]
            if format_opt:
                show_cmd.extend(format_opt)
            show_result = subprocess.run(
                show_cmd,
                capture_output=True, text=True, timeout=30)
            
            if show_result.returncode == 0 and show_result.stdout.strip():
                print(f"{Fore.GREEN}[JOHN] Hash berhasil di-crack!{Style.RESET_ALL}")
                print(f"{Fore.GREEN}{show_result.stdout}{Style.RESET_ALL}")
                add_to_summary("JOHN-CRACKED", show_result.stdout.strip())
                
                # Scan output untuk flag
                scan_text_for_flags(show_result.stdout, "JOHN")
            else:
                print(f"{Fore.YELLOW}[JOHN] Hash tidak berhasil di-crack{Style.RESET_ALL}")
                log_tool("john", "⬜ Nothing", "hash tidak ter-crack")
                
        except subprocess.TimeoutExpired:
            print(f"{Fore.YELLOW}[JOHN] Timeout setelah 10 menit{Style.RESET_ALL}")
        except Exception as e:
            print(f"{Fore.RED}[JOHN] Error: {e}{Style.RESET_ALL}")
            log_tool("john", "❌ Error", str(e))
    else:
        print(f"{Fore.YELLOW}[JOHN] John the Ripper tidak terinstall{Style.RESET_ALL}")
        print(f"{Fore.CYAN}[JOHN] Install dengan: sudo apt install john{Style.RESET_ALL}")

# ── 8. HASH CRACK (HASHCAT) ───────────────────

def crack_hash_hashcat(filepath, wordlist_path=None, hash_type=None):
    """Crack hash menggunakan Hashcat"""
    print(f"{Fore.GREEN}[HASHCAT] Analisis hash dengan Hashcat...{Style.RESET_ALL}")
    out_dir = filepath.parent / f"{filepath.stem}_hashcat"
    out_dir.mkdir(exist_ok=True)

    # Baca file hash
    try:
        hash_content = filepath.read_text(errors='ignore').strip()
        print(f"{Fore.CYAN}[HASHCAT] Hash: {hash_content[:80]}...{Style.RESET_ALL}")
    except Exception as e:
        print(f"{Fore.RED}[HASHCAT] Gagal membaca file: {e}{Style.RESET_ALL}")
        log_tool("hashcat", "❌ Error", str(e))
        return

    # Siapkan wordlist
    wl = wordlist_path
    if not wl:
        for rp in ROCKYOU_PATHS:
            if Path(rp).exists():
                wl = rp
                print(f"{Fore.CYAN}[HASHCAT] Menggunakan rockyou.txt{Style.RESET_ALL}")
                break
    
    if not wl or not Path(wl).exists():
        print(f"{Fore.YELLOW}[HASHCAT] Wordlist tidak ditemukan{Style.RESET_ALL}")
        wl = None

    # Tentukan hash type (-m)
    hash_type_opt = []
    if hash_type:
        hash_type_opt = ["-m", hash_type]
        print(f"{Fore.CYAN}[HASHCAT] Hash type (-m): {hash_type}{Style.RESET_ALL}")
    else:
        # Auto-detect hash type
        print(f"{Fore.CYAN}[HASHCAT] Mencoba auto-detect hash type...{Style.RESET_ALL}")
        hash_type_opt = ["-m", "0"]  # Default MD5

    # Jalankan hashcat
    if AVAILABLE_TOOLS.get('hashcat'):
        try:
            potfile = str(out_dir / "hashcat.pot")
            cmd = [
                "hashcat",
                "-o", str(out_dir / "cracked.txt"),
                "--potfile-path", potfile,
                str(filepath)
            ]
            if wl:
                cmd.append(wl)
            if hash_type_opt:
                cmd.extend(hash_type_opt)
            
            print(f"{Fore.CYAN}[HASHCAT] Running: {' '.join(cmd)}{Style.RESET_ALL}")
            result = subprocess.run(
                cmd,
                capture_output=True, text=True, timeout=600)
            
            output = result.stdout + result.stderr
            print(f"{Fore.CYAN}[HASHCAT] Output:{Style.RESET_ALL}\n{output[:1000]}")
            
            # Cek hasil
            cracked_file = out_dir / "cracked.txt"
            if cracked_file.exists() and cracked_file.stat().st_size > 0:
                cracked = cracked_file.read_text(errors='ignore')
                print(f"{Fore.GREEN}[HASHCAT] Hash berhasil di-crack!{Style.RESET_ALL}")
                print(f"{Fore.GREEN}{cracked}{Style.RESET_ALL}")
                add_to_summary("HASHCAT-CRACKED", cracked.strip())
                scan_text_for_flags(cracked, "HASHCAT")
            else:
                print(f"{Fore.YELLOW}[HASHCAT] Hash tidak berhasil di-crack{Style.RESET_ALL}")
                log_tool("hashcat", "⬜ Nothing", "hash tidak ter-crack")
                
        except subprocess.TimeoutExpired:
            print(f"{Fore.YELLOW}[HASHCAT] Timeout setelah 10 menit{Style.RESET_ALL}")
        except Exception as e:
            print(f"{Fore.RED}[HASHCAT] Error: {e}{Style.RESET_ALL}")
            log_tool("hashcat", "❌ Error", str(e))
    else:
        print(f"{Fore.YELLOW}[HASHCAT] Hashcat tidak terinstall{Style.RESET_ALL}")
        print(f"{Fore.CYAN}[HASHCAT] Install dengan: sudo apt install hashcat{Style.RESET_ALL}")

# ── 9. FOLDER / FAKE EXTENSION SCAN ──────────

def analyze_folder_magic(dirpath):
    """
    Scan semua file di folder:
    - Detect fake extensions via magic bytes
    - Auto-rename dan extract jika ZIP/archive
    - Flag scan di semua file teks
    """
    dirpath = Path(dirpath)
    print(f"{Fore.GREEN}[FOLDER-SCAN] Analisis semua file di: {dirpath}{Style.RESET_ALL}")

    files = [f for f in dirpath.rglob("*") if f.is_file()]
    print(f"{Fore.CYAN}[FOLDER-SCAN] {len(files)} file ditemukan{Style.RESET_ALL}")

    for f in files:
        _analyze_single_magic(f)

def _get_real_type(filepath):
    """Baca magic bytes dan kembalikan (ext, description) sebenarnya"""
    try:
        header = filepath.read_bytes()[:16]
        for sig_bytes, (ext, desc) in MAGIC_MAP.items():
            if header[:len(sig_bytes)] == sig_bytes:
                return ext, desc
    except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
    return None, None

def _analyze_single_magic(filepath):
    """Cek satu file: apakah ekstensinya sesuai magic bytes?"""
    real_ext, real_desc = _get_real_type(filepath)
    claimed_ext = filepath.suffix.lower().lstrip('.')

    if real_ext is None:
        # Tidak dikenal — scan strings saja
        sr = subprocess.getoutput(f"strings '{filepath}'")
        scan_text_for_flags(sr, f"FILE-{filepath.name}")
        collect_base64_from_text(sr)
        return

    # Mapping ekstensi yang dianggap sama
    SAME_FAMILY = {
        'zip': {'zip','jar','docx','xlsx','pptx','apk','war'},
        'jpg': {'jpg','jpeg'},
        'gz':  {'gz','tgz'},
    }
    is_mismatch = True
    for fam, exts in SAME_FAMILY.items():
        if real_ext in exts and claimed_ext in exts:
            is_mismatch = False

    if real_ext == claimed_ext:
        is_mismatch = False

    if is_mismatch:
        print(f"\n{Fore.RED}[FAKE-EXT] ⚠  {filepath.name}{Style.RESET_ALL}")
        print(f"  Ekstensi klaim : .{claimed_ext}")
        print(f"  Tipe sebenarnya: {real_desc} (.{real_ext})")
        add_to_summary("FAKE-EXT", f"{filepath.name}: .{claimed_ext} → {real_desc}")

        # Rename dan process
        new_path = filepath.parent / f"{filepath.stem}_real.{real_ext}"
        shutil.copy(str(filepath), str(new_path))
        print(f"  Disalin ke: {new_path.name}")

        # Jika ZIP → extract
        if real_ext in ['zip','jar','docx','xlsx','pptx','apk']:
            print(f"{Fore.CYAN}[FAKE-EXT] Ekstrak sebagai ZIP...{Style.RESET_ALL}")
            out_dir = filepath.parent / f"{filepath.stem}_extracted_zip"
            out_dir.mkdir(exist_ok=True)
            r = subprocess.run(["unzip","-o",str(new_path),"-d",str(out_dir)],
                                capture_output=True, text=True, timeout=30)
            if r.returncode == 0:
                _scan_extracted_dir(out_dir, f"FAKE-EXT-ZIP-{filepath.name}")

        # Jika PDF → extract text
        elif real_ext == 'pdf':
            text = subprocess.getoutput(f"pdftotext '{new_path}' - 2>/dev/null || strings '{new_path}'")
            scan_text_for_flags(text, f"FAKE-EXT-PDF")

        # Jika gambar → exiftool
        elif real_ext in ['png','jpg','gif','bmp']:
            exif = subprocess.getoutput(f"exiftool '{new_path}'")
            scan_text_for_flags(exif, f"FAKE-EXT-IMG")
            strings_out = subprocess.getoutput(f"strings '{new_path}'")
            scan_text_for_flags(strings_out, f"FAKE-EXT-STRINGS")

        else:
            strings_out = subprocess.getoutput(f"strings '{new_path}'")
            scan_text_for_flags(strings_out, f"FAKE-EXT-STRINGS")

    else:
        # Ekstensi cocok — tetap scan untuk flag
        try:
            text = filepath.read_text(errors='ignore')
            scan_text_for_flags(text, f"FILE-{filepath.name}")
            collect_base64_from_text(text)
            # Strings scan juga
            sr = subprocess.getoutput(f"strings '{filepath}'")
            scan_text_for_flags(sr, f"STRINGS-{filepath.name}")
        except:
            sr = subprocess.getoutput(f"strings '{filepath}'")
            scan_text_for_flags(sr, f"STRINGS-{filepath.name}")

# ── 7. VOLATILITY WRAPPER ────────────────────

def analyze_volatility(filepath, vol_args=None):
    """
    Wrapper Volatility 3 untuk memory forensics.
    Otomatis jalankan: windows.info, pslist, envars, filescan, cmdline, netscan
    """
    print(f"{Fore.GREEN}[VOLATILITY] Analisis memory dump...{Style.RESET_ALL}")

    # Cari binary volatility
    vol_cmd = None
    for candidate in ['vol', 'volatility3', 'volatility', 'vol.py', 'python3 vol.py']:
        check = subprocess.run(f"which {candidate.split()[0]}",
                               shell=True, capture_output=True)
        if check.returncode == 0:
            vol_cmd = candidate
            break

    if not vol_cmd:
        # Cari di PATH umum
        for path in ['/usr/local/bin/vol', '/usr/bin/vol', '/opt/volatility3/vol.py']:
            if Path(path).exists():
                vol_cmd = f"python3 {path}" if path.endswith('.py') else path
                break

    if not vol_cmd:
        print(f"{Fore.RED}[VOLATILITY] Volatility tidak ditemukan!{Style.RESET_ALL}")
        print(f"{Fore.YELLOW}  Install: pip install volatility3{Style.RESET_ALL}")
        print(f"{Fore.YELLOW}  Atau: sudo apt install volatility{Style.RESET_ALL}")
        add_to_summary("VOLATILITY-ERROR", "Binary tidak ditemukan")
        return

    print(f"{Fore.CYAN}[VOLATILITY] Menggunakan: {vol_cmd}{Style.RESET_ALL}")
    out_dir = filepath.parent / f"{filepath.stem}_volatility"
    out_dir.mkdir(exist_ok=True)

    def run_vol(plugin, extra_args=None, label=None):
        cmd = f"{vol_cmd} -f '{filepath}' {plugin}"
        if extra_args: cmd += f" {extra_args}"
        label = label or plugin.replace('.', '_')
        print(f"\n{Fore.CYAN}[VOL] {plugin}{Style.RESET_ALL}")
        try:
            r = subprocess.run(cmd, shell=True, capture_output=True,
                               text=True, timeout=300)
            out = r.stdout + r.stderr
            if out.strip():
                print(out[:2000])
                (out_dir / f"{label}.txt").write_text(out)
                scan_text_for_flags(out, f"VOL-{label.upper()}")
                collect_base64_from_text(out)
                return out
        except subprocess.TimeoutExpired:
            print(f"{Fore.RED}[VOL] Timeout pada {plugin}{Style.RESET_ALL}")
        except Exception as e:
            print(f"{Fore.RED}[VOL] Gagal {plugin}: {e}{Style.RESET_ALL}")
        return ""

    # ── Auto-detect OS
    info_out = run_vol("windows.info", label="windows_info")
    is_windows = "windows" in info_out.lower() or "KDBG" in info_out

    if is_windows:
        print(f"{Fore.GREEN}[VOLATILITY] Windows memory image terdeteksi{Style.RESET_ALL}")

        # Plugin-plugin dasar
        run_vol("windows.pslist",   label="pslist")
        run_vol("windows.pstree",   label="pstree")
        run_vol("windows.cmdline",  label="cmdline")
        run_vol("windows.envars", "--filter USERNAME", label="envars_username")
        run_vol("windows.netscan",  label="netscan")

        # Cari file mencurigakan
        print(f"\n{Fore.CYAN}[VOL] Scan files di memori...{Style.RESET_ALL}")
        filescan_out = run_vol("windows.filescan", label="filescan")

        # Cari file menarik: txt, jpg, flag, passwd, dll
        interesting = []
        for line in filescan_out.splitlines():
            if any(kw in line.lower() for kw in
                   ['flag','secret','password','passwd','key','hint',
                    '.txt','.jpg','.png','.pdf','.doc','.zip']):
                interesting.append(line)

        if interesting:
            print(f"\n{Fore.YELLOW}[VOL] File menarik di memori:{Style.RESET_ALL}")
            for line in interesting[:20]:
                print(f"  {line}")

            # Dump file menarik secara otomatis
            print(f"\n{Fore.CYAN}[VOL] Dump file menarik...{Style.RESET_ALL}")
            dump_dir = out_dir / "dumped_files"
            dump_dir.mkdir(exist_ok=True)
            for line in interesting[:10]:
                # Ekstrak virtual address (kolom pertama biasanya)
                addr_match = re.search(r'(0x[0-9a-fA-F]+)', line)
                if addr_match:
                    addr = addr_match.group(1)
                    try:
                        r = subprocess.run(
                            f"{vol_cmd} -f '{filepath}' windows.dumpfiles "
                            f"--virtaddr {addr} --dump-dir '{dump_dir}'",
                            shell=True, capture_output=True, text=True, timeout=60)
                        if r.returncode == 0:
                            print(f"  Dump {addr}: OK")
                    except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))

            # Scan file yang sudah di-dump
            _scan_extracted_dir(dump_dir, "VOL-DUMP")

        # Hashes untuk cracking
        run_vol("windows.hashdump", label="hashdump")

        # Registry
        run_vol("windows.registry.hivelist",  label="hivelist")
        run_vol("windows.registry.printkey",   label="printkey_run",
                extra_args='--key "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run"')

    else:
        # Linux / generic
        run_vol("linux.pslist",  label="linux_pslist")
        run_vol("linux.bash",    label="linux_bash")
        run_vol("linux.check_syscall", label="linux_syscall")

    # Custom args dari user
    if vol_args:
        for arg in vol_args:
            run_vol(arg, label=arg.replace('.','_').replace(' ','_'))

    new_flags = list(found_flags_set)
    log_tool("volatility", "✅ Found" if new_flags else "⬜ Analyzed",
             ", ".join(new_flags) if new_flags else f"output: {out_dir.name}")
    add_to_summary("VOLATILITY-DONE", f"Output: '{out_dir.name}'")
    print(f"{Fore.GREEN}[VOLATILITY] Selesai. Output: {out_dir.name}{Style.RESET_ALL}")

# ═══════════════════════════════════════════════════════
# ══ FUNGSI LAMA (SUDAH ADA) ════════════════════════════
# ═══════════════════════════════════════════════════════

# ── Header Repair ────────────────────────────

def fix_header(filepath):
    log_tool("header-check", "running")
    try:
        with open(filepath,'rb') as f:
            header=f.read(64); full_data=header+f.read()
        entropy=calculate_entropy(full_data)
        ec=Fore.RED if entropy>7.5 else Fore.CYAN
        print(f"{Fore.YELLOW}[+] Entropy: {ec}{entropy:.4f}{Style.RESET_ALL}")
        detect_scattered_flag(header)
        print(f"{Fore.CYAN}[+] Header: {header[:16].hex(' ').upper()}{Style.RESET_ALL}")
        cur=filepath.suffix.lower().lstrip('.')
        det=None
        for ext,sig in FILE_SIGNATURES.items():
            if header.startswith(sig): det=ext; break
        if det and cur!=det and det not in ['docx']:
            fixed=filepath.parent/f"fixed_{filepath.name}.{det}"
            shutil.copy(filepath,fixed)
            add_to_summary("AUTO-FIX",f"→ {fixed.name}")
            return fixed
        if b"JFIF" in header:
            fixed=filepath.parent/f"repaired_{filepath.name}.jpg"
            with open(fixed,'wb') as o: o.write(b"\xFF\xD8\xFF\xE0"+full_data[4:])
            add_to_summary("REPAIR",f"JPEG via JFIF → {fixed.name}"); return fixed
        if b"IHDR" in header:
            fixed=filepath.parent/f"repaired_{filepath.name}.png"
            with open(fixed,'wb') as o: o.write(FILE_SIGNATURES["png"]+full_data[8:])
            add_to_summary("REPAIR",f"PNG via IHDR → {fixed.name}"); return fixed
    except Exception as e:
        print(f"{Fore.RED}[!] Header repair gagal: {e}{Style.RESET_ALL}")
        log_tool("header-check", "❌ Error", str(e))
    log_tool("header-check", "⬜ OK", "signature normal / diperbaiki")
    return filepath

# ── Auto Decode ──────────────────────────────

def analyze_extracted_file(filepath):
    try:
        result=subprocess.run(['strings',str(filepath)],capture_output=True,text=True)
        scan_text_for_flags(result.stdout, f"EXTRACTED-{filepath.name}")
    except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))

def auto_decode_and_extract(filepath):
    if check_early_exit(): return
    log_tool("auto-decode", "running")
    found_before = len(found_flags_set)
    print(f"{Fore.CYAN}[AUTO-DECODE] Memeriksa encoded data...{Style.RESET_ALL}")
    try:
        raw=filepath.read_bytes()
        text=raw.decode('utf-8',errors='ignore')
        extracted=[]
        for i,m in enumerate(re.findall(r'[A-Za-z0-9+/]{20,}={0,2}',text)[:5]):
            try:
                dec=base64.b64decode(m,validate=True)
                if len(dec)>50:
                    ext=detect_file_extension(dec[:16])
                    out=filepath.parent/f"{filepath.stem}_decoded_b64_{i}.{ext}"
                    out.write_bytes(dec); extracted.append(out)
                    print(f"{Fore.GREEN}[+] Base64 decoded: {out.name}{Style.RESET_ALL}")
                    add_to_summary("AUTO-DECODE",f"Base64 → {out.name}")
                    analyze_extracted_file(out)
            except: continue
        for i,m in enumerate(re.findall(r'[0-9a-fA-F]{40,}',text)[:3]):
            try:
                if len(m)%2==0:
                    dec=bytes.fromhex(m)
                    if len(dec)>50:
                        ext=detect_file_extension(dec[:16])
                        out=filepath.parent/f"{filepath.stem}_decoded_hex_{i}.{ext}"
                        out.write_bytes(dec); extracted.append(out)
                        print(f"{Fore.GREEN}[+] Hex decoded: {out.name}{Style.RESET_ALL}")
                        add_to_summary("AUTO-DECODE",f"Hex → {out.name}")
                        analyze_extracted_file(out)
            except: continue
        for i,m in enumerate(re.findall(r'[01]{40,}',text)[:2]):
            try:
                if len(m)%8==0:
                    dec=bytes(int(m[j:j+8],2) for j in range(0,len(m),8))
                    if len(dec)>20:
                        ext=detect_file_extension(dec[:16])
                        out=filepath.parent/f"{filepath.stem}_decoded_bin_{i}.{ext}"
                        out.write_bytes(dec); extracted.append(out)
                        print(f"{Fore.GREEN}[+] Binary decoded: {out.name}{Style.RESET_ALL}")
                        add_to_summary("AUTO-DECODE",f"Binary → {out.name}")
                        analyze_extracted_file(out)
            except: continue
        if extracted: print(f"{Fore.CYAN}[+] Total extracted: {len(extracted)}{Style.RESET_ALL}")
        else: print(f"{Fore.YELLOW}[!] Tidak ada encoded data ditemukan{Style.RESET_ALL}")
        new_flags = list(found_flags_set)[found_before:]
        log_tool("auto-decode", "✅ Found" if new_flags else "⬜ Nothing",
                 ", ".join(new_flags) if new_flags else f"{len(extracted)} file(s) decoded" if extracted else "tidak ada encoded data")
    except Exception as e:
        print(f"{Fore.RED}[!] Auto-decode gagal: {e}{Style.RESET_ALL}")
        log_tool("auto-decode", "❌ Error", str(e))

# ── Strings & Flags ──────────────────────────

def analyze_strings_and_flags(filepath, custom_format=None):
    # Skip very large files (>100MB) to prevent hanging
    max_size = 100 * 1024 * 1024  # 100MB
    try:
        file_size = filepath.stat().st_size
        if file_size > max_size:
            size_mb = file_size / (1024*1024)
            print(f"{Fore.YELLOW}[STRINGS] ⏭ Skip large file: {filepath.name} ({size_mb:.1f}MB){Style.RESET_ALL}")
            log_tool("strings", "⏭ Skipped", f"file too large ({size_mb:.1f}MB)")
            return
    except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))

    log_tool("strings", "running")
    found_before = len(found_flags_set)
    try:
        ft=subprocess.getoutput(f"file -b '{filepath}'").strip()
        print(f"{Fore.CYAN}[BASIC] Type: {ft}{Style.RESET_ALL}")
        
        # Add timeout to strings command (30 seconds max)
        import subprocess as sp
        try:
            utf8 = sp.run(f"strings '{filepath}'", shell=True, capture_output=True, text=True, timeout=30).stdout
            utf16 = sp.run(f"strings -e l '{filepath}'", shell=True, capture_output=True, text=True, timeout=30).stdout
        except sp.TimeoutExpired:
            print(f"{Fore.YELLOW}[STRINGS] ⏱ Timeout (30s) on {filepath.name}{Style.RESET_ALL}")
            log_tool("strings", "⏱ Timeout", "file too large or slow")
            return
        
        combined=utf8+"\n"+utf16
        collect_base64_from_text(combined)
        scan_text_for_flags(combined, "STRINGS")
        if custom_format:
            esc=re.escape(custom_format)
            pat=esc.replace(r'\{',r'\{[^}]*\}') if esc.endswith(r'\{') else esc
            for m in re.findall(pat,combined,re.IGNORECASE):
                add_to_summary("CUSTOM-FLAG",m)
        # Tambahan: multi-encoding decode (base32/b58/hex/xor)
        if combined.strip():
            auto_decode_multi(combined, "STRINGS")
        new_flags = list(found_flags_set)[found_before:]
        log_tool("strings", "✅ Found" if new_flags else "⬜ Nothing",
                 f"{len(new_flags)} flag(s)" if new_flags else "tidak ada flag")
    except Exception as e:
        print(f"{Fore.RED}[!] String analysis gagal: {e}{Style.RESET_ALL}")
        log_tool("strings", "❌ Error", str(e))

# ── Image Analysis ───────────────────────────

def analyze_image(filepath, deep=False, alpha=False):
    if not HAS_PIL:
        print(f"{Fore.RED}[!] Pillow tidak terinstall.{Style.RESET_ALL}"); return
    print(f"{Fore.GREEN}[IMAGE] Analisis visual stego...{Style.RESET_ALL}")
    try:
        img=Image.open(filepath)
        if img.mode=='RGBA' or (alpha and img.mode=='P'): img=img.convert("RGBA")
        elif img.mode!='RGB': img=img.convert("RGB")
        channels=list(img.split()[:3]); names=["red","green","blue"]
        if img.mode=='RGBA': channels.append(img.split()[3]); names.append("alpha")
        bp_dir=filepath.parent/f"{filepath.stem}_bitplanes"; bp_dir.mkdir(exist_ok=True)
        bit_range=range(8) if deep else [6,7]
        for ch,name in zip(channels,names):
            arr=np.array(ch)
            for bit in bit_range:
                plane=((arr>>bit)&1)*255
                Image.fromarray(plane.astype(np.uint8),mode="L").save(bp_dir/f"{name}_bit{bit}.png")
        print(f"{Fore.CYAN}[+] Bit planes → {bp_dir.name}{Style.RESET_ALL}")
        add_to_summary("BIT-PLANE",f"Saved to '{bp_dir.name}'")
        for f in bp_dir.glob("*.png"):
            out=subprocess.getoutput(f"strings '{f}'")
            scan_text_for_flags(out, f"BITPLANE-{f.name}")
        ch_dir=filepath.parent/f"{filepath.stem}_channels"; ch_dir.mkdir(exist_ok=True)
        r,g,b=img.split()[:3]; r.save(ch_dir/"red.png"); g.save(ch_dir/"green.png"); b.save(ch_dir/"blue.png")
        if img.mode=='RGBA': img.split()[3].save(ch_dir/"alpha.png")
        add_to_summary("RGB-CHANNELS",f"Saved to '{ch_dir.name}'")
    except Exception as e:
        print(f"{Fore.RED}[!] Image analysis gagal: {e}{Style.RESET_ALL}")

def extract_lsb_data(filepath):
    if not HAS_PIL: return
    print(f"{Fore.GREEN}[LSB-EXTRACT] Ekstrak raw LSB...{Style.RESET_ALL}")
    try:
        img=Image.open(filepath); arr=np.array(img)
        if len(arr.shape)==2: arr=arr.reshape(*arr.shape,1)
        h,w,c=arr.shape
        lsb=[arr[:,:,ch].flatten()&1 for ch in range(min(c,4))]
        combined=np.concatenate(lsb); lsb_bytes=np.packbits(combined)
        out_dir=filepath.parent/f"{filepath.stem}_lsb_raw"; out_dir.mkdir(exist_ok=True)
        out_file=out_dir/"lsb_raw.bin"; out_file.write_bytes(lsb_bytes.tobytes())
        text=lsb_bytes.tobytes()[:1000].decode('utf-8',errors='ignore')
        if any(c.isprintable() for c in text):
            print(f"{Fore.CYAN}[+] LSB preview: {text[:100]}{Style.RESET_ALL}")
            collect_base64_from_text(text)
        raw=lsb_bytes.tobytes().decode('latin-1',errors='ignore')
        scan_text_for_flags(raw, "LSB")
        add_to_summary("LSB-EXTRACT",f"Saved to '{out_file.name}'")
    except Exception as e:
        print(f"{Fore.RED}[LSB-EXTRACT] Gagal: {e}{Style.RESET_ALL}")

def compare_images(filepath1, filepath2):
    if not HAS_PIL: return
    print(f"{Fore.GREEN}[IMAGE-COMPARE] Membandingkan gambar...{Style.RESET_ALL}")
    try:
        arr1=np.array(Image.open(filepath1)); arr2=np.array(Image.open(filepath2))
        if arr1.shape!=arr2.shape:
            s=tuple(min(a,b) for a,b in zip(arr1.shape,arr2.shape))
            arr1=arr1[:s[0],:s[1]] if arr1.ndim==2 else arr1[:s[0],:s[1],:s[2]]
            arr2=arr2[:s[0],:s[1]] if arr2.ndim==2 else arr2[:s[0],:s[1],:s[2]]
        diff=np.abs(arr1.astype(np.int16)-arr2.astype(np.int16))
        out_dir=filepath1.parent/f"{filepath1.stem}_compare"; out_dir.mkdir(exist_ok=True)
        Image.fromarray(diff.astype(np.uint8)).save(out_dir/"difference.png")
        non_zero=int(np.sum(diff>0))
        print(f"{Fore.CYAN}[+] Pixel berbeda: {non_zero}{Style.RESET_ALL}")
        add_to_summary("IMAGE-COMPARE",f"diff_pixels={non_zero}")
    except Exception as e:
        print(f"{Fore.RED}[IMAGE-COMPARE] Gagal: {e}{Style.RESET_ALL}")

def analyze_steg_methods(filepath):
    if not HAS_PIL: return
    print(f"{Fore.GREEN}[STEG-DETECT] Mendeteksi metode steganografi...{Style.RESET_ALL}")
    try:
        img=Image.open(filepath); pixels=np.array(img).flatten()
        ones=int(np.sum(pixels%2==1)); ratio=ones/(len(pixels)+1)
        lsb_likely=0.48<ratio<0.52
        print(f"{Fore.CYAN}[STEG-DETECT] LSB ratio: {ratio:.4f}{Style.RESET_ALL}")
        if lsb_likely: print("  ⚠  LSB hampir random → kemungkinan LSB stego")
        arr=np.array(img); zsteg_likely=False
        if arr.ndim==3 and arr.shape[2]>=3:
            rv,gv,bv=float(np.var(arr[:,:,0])),float(np.var(arr[:,:,1])),float(np.var(arr[:,:,2]))
            if abs(rv-gv)>1000 or abs(gv-bv)>1000:
                zsteg_likely=True
        is_jpeg=filepath.suffix.lower() in ['.jpg','.jpeg']
        add_to_summary("STEG-DETECT",f"LSB:{lsb_likely},Zsteg:{zsteg_likely},JPEG:{is_jpeg}")
    except Exception as e:
        print(f"{Fore.RED}[STEG-DETECT] Gagal: {e}{Style.RESET_ALL}")

def color_remapping(filepath):
    if not HAS_PIL: return
    print(f"{Fore.GREEN}[COLOR-REMAP] Membuat 8 palette variant...{Style.RESET_ALL}")
    try:
        img=Image.open(filepath).convert('RGBA' if Image.open(filepath).mode=='RGBA' else 'RGB')
        np_img=np.array(img)
        out_dir=filepath.parent/f"{filepath.stem}_remap"; out_dir.mkdir(exist_ok=True)
        for i in range(8):
            np.random.seed(i*42); remapped=np_img.copy()
            for c in range(min(3,remapped.shape[2])):
                ch=remapped[:,:,c]; vals=np.unique(ch)
                if len(vals)>1:
                    shuf=np.random.permutation(vals)
                    for orig,new in zip(vals,shuf): remapped[ch==orig,c]=new
            Image.fromarray(remapped.astype(np.uint8),mode=img.mode).save(out_dir/f"variant_{i+1}.png")
        add_to_summary("COLOR-REMAP",f"Saved to '{out_dir.name}'")
    except Exception as e:
        print(f"{Fore.RED}[COLOR-REMAP] Gagal: {e}{Style.RESET_ALL}")

# ── External Tools ───────────────────────────

def analyze_with_binwalk(filepath):
    if check_early_exit(): return
    log_tool("binwalk", "running")
    found_before = len(found_flags_set)
    out_dir=filepath.parent/f"_extracted_{filepath.name}"
    try:
        subprocess.run(["binwalk","-eM","--quiet",f"--directory={out_dir}",str(filepath)],
                       stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
        if out_dir.exists():
            print(f"{Fore.GREEN}[BINWALK] Ekstraksi: {out_dir.name}{Style.RESET_ALL}")
            for nested in out_dir.rglob("*"):
                if nested.is_file():
                    # Skip large extracted files (>100MB)
                    try:
                        if nested.stat().st_size > 100*1024*1024:
                            size_mb = nested.stat().st_size / (1024*1024)
                            print(f"{Fore.YELLOW}[BINWALK] ⏭ Skip large: {nested.name} ({size_mb:.1f}MB){Style.RESET_ALL}")
                            continue
                    except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
                    
                    analyze_strings_and_flags(nested)
                    if check_early_exit():
                        log_tool("binwalk", "✅ Found", f"Early exit after flag found")
                        return
            new_flags = list(found_flags_set)[found_before:]
            log_tool("binwalk", "✅ Found" if new_flags else "⬜ Extracted",
                     ", ".join(new_flags) if new_flags else f"output: {out_dir.name}")
        else:
            log_tool("binwalk", "⬜ Nothing", "tidak ada embedded file")
    except FileNotFoundError:
        print(f"{Fore.YELLOW}[BINWALK] Tidak terinstall.{Style.RESET_ALL}")
        log_tool("binwalk", "⏭ Skipped", "tidak terinstall")
    except Exception as e:
        print(f"{Fore.RED}[BINWALK] Gagal: {e}{Style.RESET_ALL}")
        log_tool("binwalk", "❌ Error", str(e))

def analyze_zsteg(filepath):
    if not AVAILABLE_TOOLS.get('zsteg'):
        log_tool("zsteg", "⏭ Skipped", "tidak terinstall"); return
    if check_early_exit(): return
    print(f"{Fore.GREEN}[ZSTEG] Full LSB analysis...{Style.RESET_ALL}")
    log_tool("zsteg", "running")
    found_before = len(found_flags_set)
    try:
        result=subprocess.run(["zsteg","-a",str(filepath)],capture_output=True,text=True,timeout=60)
        output=result.stdout+result.stderr
        print(output[:2000] if len(output)>2000 else output)
        collect_base64_from_text(output)
        scan_text_for_flags(output, "ZSTEG")
        new_flags = list(found_flags_set)[found_before:]
        log_tool("zsteg", "✅ Found" if new_flags else "⬜ Nothing",
                 ", ".join(new_flags) if new_flags else "tidak ada data tersembunyi")
    except subprocess.TimeoutExpired:
        print(f"{Fore.RED}[ZSTEG] Timeout.{Style.RESET_ALL}")
        log_tool("zsteg", "❌ Error", "timeout 60s")
    except Exception as e:
        print(f"{Fore.RED}[ZSTEG] Gagal: {e}{Style.RESET_ALL}")
        log_tool("zsteg", "❌ Error", str(e))

def analyze_steghide(filepath, password=None):
    if not AVAILABLE_TOOLS.get('steghide'):
        log_tool("steghide", "⏭ Skipped", "tidak terinstall"); return
    if check_early_exit(): return
    print(f"{Fore.GREEN}[STEGHIDE] Mencoba ekstraksi...{Style.RESET_ALL}")
    log_tool("steghide", "running")
    found_before = len(found_flags_set)
    out_dir=filepath.parent/f"{filepath.stem}_steghide"; out_dir.mkdir(exist_ok=True)
    out_file=out_dir/"extracted.txt"
    try:
        cmd=["steghide","extract","-sf",str(filepath),"-xf",str(out_file),"-f"]
        if password: cmd+=["-p",password]
        result=subprocess.run(cmd,capture_output=True,text=True,timeout=30)
        if result.returncode==0 and out_file.exists() and out_file.stat().st_size>0:
            txt=out_file.read_text(errors='ignore')
            print(f"{Fore.GREEN}[STEGHIDE] Berhasil ekstrak!{Style.RESET_ALL}")
            print(txt[:500])
            collect_base64_from_text(txt)
            scan_text_for_flags(txt, "STEGHIDE")
            add_to_summary("STEGHIDE-EXTRACT",f"Saved to '{out_file.name}'")
            new_flags = list(found_flags_set)[found_before:]
            log_tool("steghide", "✅ Found" if new_flags else "⬜ Extracted (no flag)",
                     ", ".join(new_flags) if new_flags else f"data diekstrak: {out_file.name}")
        else:
            log_tool("steghide", "⬜ Nothing", "tidak ada data tersembunyi (tanpa password)")
    except subprocess.TimeoutExpired:
        print(f"{Fore.RED}[STEGHIDE] Timeout.{Style.RESET_ALL}")
        log_tool("steghide", "❌ Error", "timeout 30s")
    except Exception as e:
        print(f"{Fore.RED}[STEGHIDE] Gagal: {e}{Style.RESET_ALL}")
        log_tool("steghide", "❌ Error", str(e))

def analyze_stegseek(filepath, wordlist=None):
    if not AVAILABLE_TOOLS.get('stegseek'):
        log_tool("stegseek", "⏭ Skipped", "tidak terinstall"); return
    if check_early_exit(): return
    log_tool("stegseek", "running")
    found_before = len(found_flags_set)
    wl = wordlist
    if not wl:
        for path in ROCKYOU_PATHS:
            if Path(path).exists(): wl = path; break
    if not wl:
        print(f"{Fore.YELLOW}[STEGSEEK] rockyou.txt tidak ditemukan.{Style.RESET_ALL}"); return
    print(f"{Fore.GREEN}[STEGSEEK] Brute-force dengan: {wl}{Style.RESET_ALL}")
    out_dir=filepath.parent/f"{filepath.stem}_stegseek"; out_dir.mkdir(exist_ok=True)
    out_file=out_dir/"stegseek_out"
    try:
        result=subprocess.run(["stegseek",str(filepath),wl,str(out_file)],
                              capture_output=True,text=True,timeout=600)
        output=result.stdout+result.stderr
        print(output[:3000] if len(output)>3000 else output)
        pw_match=re.search(r'Found passphrase:\s*"([^"]*)"',output)
        if pw_match:
            pw=pw_match.group(1)
            print(f"{Fore.GREEN}[STEGSEEK] Password: \"{pw}\"{Style.RESET_ALL}")
            add_to_summary("STEGSEEK-PASS",f"Password: '{pw}'")
        scan_text_for_flags(output, "STEGSEEK")
        extracted_count = 0
        for f in out_dir.glob("*"):
            if f.is_file() and f.stat().st_size>0:
                txt=f.read_text(errors='ignore')
                scan_text_for_flags(txt, "STEGSEEK-EXTRACT")
                collect_base64_from_text(txt)
                add_to_summary("STEGSEEK-EXTRACT",f"Saved to '{f.name}'")
                extracted_count += 1
        new_flags = list(found_flags_set)[found_before:]
        if new_flags:
            log_tool("stegseek", "✅ Found", ", ".join(new_flags))
        elif pw_match:
            log_tool("stegseek", "⬜ Extracted", f"password='{pw_match.group(1)}', {extracted_count} file")
        else:
            log_tool("stegseek", "⬜ Nothing", "tidak ada payload ditemukan")
    except subprocess.TimeoutExpired:
        print(f"{Fore.RED}[STEGSEEK] Timeout (600s).{Style.RESET_ALL}")
        log_tool("stegseek", "❌ Error", "timeout 600s")
    except Exception as e:
        print(f"{Fore.RED}[STEGSEEK] Gagal: {e}{Style.RESET_ALL}")
        log_tool("stegseek", "❌ Error", str(e))

def analyze_outguess(filepath):
    if not AVAILABLE_TOOLS.get('outguess'):
        log_tool("outguess", "⏭ Skipped", "tidak terinstall"); return
    log_tool("outguess", "running")
    found_before = len(found_flags_set)
    print(f"{Fore.GREEN}[OUTGUESS] Ekstraksi...{Style.RESET_ALL}")
    out_dir=filepath.parent/f"{filepath.stem}_outguess"; out_dir.mkdir(exist_ok=True)
    out_file=out_dir/"outguess.txt"
    try:
        result=subprocess.run(["outguess","-r",str(filepath),str(out_file)],
                               capture_output=True,text=True,timeout=30)
        if result.returncode==0 and out_file.exists():
            txt=out_file.read_text(errors='ignore')
            collect_base64_from_text(txt)
            scan_text_for_flags(txt, "OUTGUESS")
            add_to_summary("OUTGUESS-EXTRACT",f"Saved to '{out_file.name}'")
            new_flags = list(found_flags_set)[found_before:]
            log_tool("outguess", "✅ Found" if new_flags else "⬜ Extracted",
                     ", ".join(new_flags) if new_flags else out_file.name)
        else:
            log_tool("outguess", "⬜ Nothing", "tidak ada payload")
    except Exception as e:
        print(f"{Fore.RED}[OUTGUESS] Gagal: {e}{Style.RESET_ALL}")
        log_tool("outguess", "❌ Error", str(e))

def analyze_foremost(filepath, quick=True):
    if not AVAILABLE_TOOLS.get('foremost'):
        log_tool("foremost", "⏭ Skipped", "tidak terinstall"); return
    if quick and filepath.stat().st_size>50*1024*1024:
        log_tool("foremost", "⏭ Skipped", "file terlalu besar (>50MB)"); return
    print(f"{Fore.GREEN}[FOREMOST] File carving...{Style.RESET_ALL}")
    log_tool("foremost", "running")
    found_before = len(found_flags_set)
    out_dir=filepath.parent/f"{filepath.stem}_foremost"
    try:
        subprocess.run(["foremost","-i",str(filepath),"-o",str(out_dir),"-v"],
                       capture_output=True,timeout=15 if quick else 60)
        files=list(out_dir.rglob("*")) if out_dir.exists() else []
        carved = [f for f in files if f.is_file()]
        if carved:
            for f in carved[:5]: analyze_strings_and_flags(f)
            add_to_summary("FOREMOST-EXTRACT",f"Saved to '{out_dir.name}'")
            new_flags = list(found_flags_set)[found_before:]
            log_tool("foremost", "✅ Found" if new_flags else "⬜ Carved",
                     ", ".join(new_flags) if new_flags else f"{len(carved)} file(s) carved")
        else:
            log_tool("foremost", "⬜ Nothing", "tidak ada file carved")
    except Exception as e:
        print(f"{Fore.RED}[FOREMOST] Gagal: {e}{Style.RESET_ALL}")
        log_tool("foremost", "❌ Error", str(e))

def analyze_pngcheck(filepath):
    if not AVAILABLE_TOOLS.get('pngcheck'): return
    try:
        result=subprocess.run(["pngcheck","-v",str(filepath)],capture_output=True,text=True,timeout=30)
        output=result.stdout+result.stderr
        collect_base64_from_text(output)
        if "error" in output.lower(): add_to_summary("PNGCHECK-ERROR","PNG bermasalah")
    except Exception as e: print(f"{Fore.RED}[PNGCHECK] Gagal: {e}{Style.RESET_ALL}")

def analyze_jpseek(filepath):
    tool=next((t for t in ['jpseek','jphs'] if AVAILABLE_TOOLS.get(t)),None)
    if not tool: return
    out_dir=filepath.parent/f"{filepath.stem}_jpsteg"; out_dir.mkdir(exist_ok=True)
    try:
        cmd=["jpseek",str(filepath),str(out_dir)] if tool=='jpseek' else \
            ["jphs","-e",str(filepath),str(out_dir/"jphs_output.txt")]
        result=subprocess.run(cmd,capture_output=True,text=True,timeout=30)
        collect_base64_from_text(result.stdout+result.stderr)
    except Exception as e: print(f"{Fore.RED}[JPSTEG] Gagal: {e}{Style.RESET_ALL}")

def analyze_graphicsmagick(filepath):
    if not AVAILABLE_TOOLS.get('identify'): return
    try:
        result=subprocess.run(["gm","identify","-verbose",str(filepath)],
                               capture_output=True,text=True,timeout=30)
        collect_base64_from_text(result.stdout)
    except Exception: pass

def analyze_exif_deep(filepath):
    print(f"{Fore.GREEN}[EXIF-DEEP] EXIF metadata mendalam...{Style.RESET_ALL}")
    log_tool("exiftool", "running")
    found_before = len(found_flags_set)
    try:
        result=subprocess.run(["exiftool","-a","-u","-g1",str(filepath)],
                               capture_output=True,text=True,timeout=30)
        output=result.stdout
        print(output[:2000])
        collect_base64_from_text(output)
        scan_text_for_flags(output, "EXIF")
        exif_dir=filepath.parent/f"{filepath.stem}_exif"; exif_dir.mkdir(exist_ok=True)
        (exif_dir/"full_exif.txt").write_text(output)
        add_to_summary("EXIF-EXTRACT","Saved to 'full_exif.txt'")
        new_flags = list(found_flags_set)[found_before:]
        log_tool("exiftool", "✅ Found" if new_flags else "⬜ Nothing",
                 ", ".join(new_flags) if new_flags else "tidak ada flag di metadata")
    except FileNotFoundError:
        print(f"{Fore.YELLOW}[EXIF-DEEP] ExifTool tidak terinstall.{Style.RESET_ALL}")
        log_tool("exiftool", "⏭ Skipped", "tidak terinstall")
    except Exception as e:
        print(f"{Fore.RED}[EXIF-DEEP] Gagal: {e}{Style.RESET_ALL}")
        log_tool("exiftool", "❌ Error", str(e))

def detect_appended_data(filepath):
    """
    Deteksi data yang ditambahkan setelah EOF marker.
    Teknik umum di CTF:
    - PNG: data setelah IEND chunk
    - JPEG: data setelah FFD9 marker
    - ZIP: dual archive trick
    - GIF: data setelah GIF trailer
    """
    print(f"\n{Fore.CYAN}[APPENDED-DATA] Checking for data after EOF marker...{Style.RESET_ALL}")
    log_tool("appended-data", "running")
    
    try:
        data = filepath.read_bytes()
        file_size = len(data)
        appended_data = None
        eof_type = None
        eof_position = None
        
        # Check PNG - look for IEND chunk
        if filepath.suffix.lower() == '.png' or data[:4] == b'\x89PNG':
            iend_marker = b'IEND'
            # IEND chunk is 4 bytes, followed by 4 bytes CRC
            iend_pos = data.find(iend_marker)
            if iend_pos != -1:
                # IEND chunk structure: 4 bytes length (00000000) + 4 bytes 'IEND' + 4 bytes CRC
                eof_position = iend_pos + 8  # After 'IEND' + CRC
                if eof_position < file_size:
                    appended_data = data[eof_position:]
                    eof_type = 'PNG (after IEND)'
        
        # Check JPEG - look for FFD9 marker
        elif filepath.suffix.lower() in ['.jpg', '.jpeg'] or data[:3] == b'\xff\xd8\xff':
            # Find last FFD9 occurrence
            ffd9_marker = b'\xff\xd9'
            last_pos = -1
            pos = 0
            while True:
                pos = data.find(ffd9_marker, pos)
                if pos == -1:
                    break
                last_pos = pos
                pos += 2
            
            if last_pos != -1:
                eof_position = last_pos + 2
                if eof_position < file_size:
                    appended_data = data[eof_position:]
                    eof_type = 'JPEG (after FFD9)'
        
        # Check ZIP - look for end of central directory
        elif filepath.suffix.lower() == '.zip' or data[:2] == b'PK':
            # ZIP end of central directory signature: 50 4B 05 06
            zip_end_marker = b'\x50\x4b\x05\x06'
            last_pos = -1
            pos = 0
            while True:
                pos = data.find(zip_end_marker, pos)
                if pos == -1:
                    break
                last_pos = pos
                pos += 4
            
            if last_pos != -1:
                # End of central directory is 22 bytes minimum
                eof_position = last_pos + 22
                if eof_position < file_size:
                    appended_data = data[eof_position:]
                    eof_type = 'ZIP (after EOCD)'
        
        # Check GIF - look for GIF trailer (00 3B)
        elif filepath.suffix.lower() == '.gif' or data[:4] == b'GIF8':
            gif_trailer = b'\x00\x3B'
            last_pos = -1
            pos = 0
            while True:
                pos = data.find(gif_trailer, pos)
                if pos == -1:
                    break
                last_pos = pos
                pos += 2
            
            if last_pos != -1:
                eof_position = last_pos + 2
                if eof_position < file_size:
                    appended_data = data[eof_position:]
                    eof_type = 'GIF (after trailer)'
        
        # Report findings
        if appended_data and len(appended_data) > 10:  # At least 10 bytes to be interesting
            print(f"{Fore.GREEN}  ✓ Appended data detected: {len(appended_data)} bytes after {eof_type}{Style.RESET_ALL}")
            add_to_summary("APPENDED-DATA", f"{len(appended_data)} bytes after {eof_type}")
            
            # Save appended data
            out_dir = filepath.parent / f"{filepath.stem}_appended"
            out_dir.mkdir(exist_ok=True)
            output_file = out_dir / "appended.bin"
            output_file.write_bytes(appended_data)
            print(f"{Fore.GREEN}  ✓ Saved to: {output_file}{Style.RESET_ALL}")
            
            # Analyze the appended data
            print(f"{Fore.CYAN}  [INFO] Analyzing appended data...{Style.RESET_ALL}")
            
            # Check for file signatures in appended data
            for ext, sig in FILE_SIGNATURES.items():
                if appended_data[:len(sig)] == sig:
                    print(f"{Fore.GREEN}  ✓ Appended data starts with {ext.upper()} signature!{Style.RESET_ALL}")
                    add_to_summary("APPENDED-FILE-TYPE", ext.upper())
                    
                    # Extract as the detected file type
                    extracted_file = out_dir / f"hidden.{ext}"
                    extracted_file.write_bytes(appended_data)
                    print(f"{Fore.GREEN}  ✓ Extracted as: {extracted_file}{Style.RESET_ALL}")
                    break
            
            # Scan for strings/flags in appended data
            strings_output = subprocess.getoutput(f"strings -n 4 '{output_file}'")
            if strings_output:
                scan_text_for_flags(strings_output, "APPENDED-STRINGS")
                collect_base64_from_text(strings_output)
            
            # Check if it's text-like
            try:
                text_sample = appended_data[:500].decode('utf-8', errors='ignore')
                if any(c.isprintable() for c in text_sample):
                    print(f"{Fore.CYAN}  [INFO] First 500 chars (text):{Style.RESET_ALL}")
                    print(f"  {text_sample[:200]}...")
                    scan_text_for_flags(text_sample, "APPENDED-TEXT")
            except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
            
            log_tool("appended-data", "✅ Found", f"{len(appended_data)} bytes after {eof_type}")
        else:
            print(f"{Fore.YELLOW}  ℹ No significant appended data found{Style.RESET_ALL}")
            log_tool("appended-data", "⬜ Nothing", "no data after EOF")
    
    except Exception as e:
        print(f"{Fore.RED}  ✗ Appended data detection failed: {e}{Style.RESET_ALL}")
        log_tool("appended-data", "❌ Error", str(e))

def analyze_wav_steganography(filepath):
    """
    LSB steganography pada file WAV — sering keluar di CTF nasional.
    Decode LSB dari sample audio → ASCII/binary.
    """
    print(f"\n{Fore.CYAN}[WAV-STEGO] Analyzing WAV file for LSB steganography...{Style.RESET_ALL}")
    log_tool("wav-stego", "running")
    
    try:
        import wave
        import struct
        
        # Open WAV file
        wav = wave.open(str(filepath), 'rb')
        n_channels = wav.getnchannels()
        sample_width = wav.getsampwidth()
        frame_rate = wav.getframerate()
        n_frames = wav.getnframes()
        
        print(f"  {Fore.CYAN}Channels: {n_channels}{Style.RESET_ALL}")
        print(f"  {Fore.CYAN}Sample width: {sample_width} bytes{Style.RESET_ALL}")
        print(f"  {Fore.CYAN}Frame rate: {frame_rate}{Style.RESET_ALL}")
        print(f"  {Fore.CYAN}Frames: {n_frames}{Style.RESET_ALL}")
        
        # Read all frames
        frames = wav.readframes(n_frames)
        wav.close()
        
        # Extract LSB from samples
        # Assuming 8-bit or 16-bit samples
        if sample_width == 1:  # 8-bit
            samples = list(frames)
        elif sample_width == 2:  # 16-bit
            samples = struct.unpack('<' + 'h' * (len(frames) // 2), frames)
        else:
            print(f"  {Fore.YELLOW}Unsupported sample width: {sample_width}{Style.RESET_ALL}")
            log_tool("wav-stego", "⏭ Skipped", f"unsupported sample width: {sample_width}")
            return
        
        # Extract LSB
        lsb_bits = [abs(sample) & 1 for sample in samples[:10000]]  # Limit to first 10k samples
        
        # Convert bits to bytes
        lsb_bytes = []
        for i in range(0, len(lsb_bits) - 7, 8):
            byte = 0
            for j in range(8):
                byte = (byte << 1) | lsb_bits[i + j]
            lsb_bytes.append(byte)
        
        # Convert to text
        try:
            text = bytes(lsb_bytes).decode('ascii', errors='ignore')
            print(f"  {Fore.GREEN}Extracted {len(lsb_bytes)} bytes from LSB{Style.RESET_ALL}")
            print(f"  {Fore.CYAN}First 200 chars:{Style.RESET_ALL}")
            print(f"  {text[:200]}")
            
            # Scan for flags
            scan_text_for_flags(text, "WAV-LSB")
            collect_base64_from_text(text)
            
            # Save extracted data
            out_dir = filepath.parent / f"{filepath.stem}_wav_stego"
            out_dir.mkdir(exist_ok=True)
            (out_dir / "lsb_extracted.txt").write_text(text)
            (out_dir / "lsb_extracted.bin").write_bytes(bytes(lsb_bytes))
            add_to_summary("WAV-LSB", f"Extracted {len(lsb_bytes)} bytes")
            
            log_tool("wav-stego", "✅ Found" if FLAG_FOUND else "⬜ Nothing",
                     f"Extracted {len(lsb_bytes)} bytes")
        except Exception as e:
            print(f"  {Fore.YELLOW}LSB extraction produced no readable text: {e}{Style.RESET_ALL}")
            log_tool("wav-stego", "⬜ Nothing", "extraction failed")
    
    except ImportError:
        print(f"  {Fore.RED}wave module not available{Style.RESET_ALL}")
        log_tool("wav-stego", "❌ Error", "wave module missing")
    except Exception as e:
        print(f"  {Fore.RED}WAV steganography analysis failed: {e}{Style.RESET_ALL}")
        log_tool("wav-stego", "❌ Error", str(e))


# ── Advanced Steganography (SPRINT 1) ──────────────────

def generate_audio_spectrogram(filepath):
    """
    Generate spectrogram dari file audio (WAV/MP3/FLAC).
    Banyak CTF menyembunyikan flag sebagai gambar dalam spektrum frekuensi.
    """
    print(f"\n{Fore.CYAN}[SPECTROGRAM] Generating audio spectrogram...{Style.RESET_ALL}")
    log_tool("spectrogram", "running")
    
    out_dir = filepath.parent / f"{filepath.stem}_spectrogram"
    out_dir.mkdir(exist_ok=True)
    
    try:
        # Try using scipy for spectrogram
        try:
            from scipy.io import wavfile
            import numpy as np
            
            # Read audio file
            sample_rate, audio_data = wavfile.read(str(filepath))
            
            # Convert to mono if stereo
            if len(audio_data.shape) > 1:
                audio_data = audio_data.mean(axis=1)
            
            # Generate spectrogram
            from scipy.signal import spectrogram
            f, t, Sxx = spectrogram(audio_data, sample_rate, nperseg=1024)
            
            # Save as image using matplotlib
            import matplotlib
            matplotlib.use('Agg')  # Non-interactive backend
            import matplotlib.pyplot as plt
            
            img_path = out_dir / "spectrogram.png"
            plt.figure(figsize=(12, 6))
            plt.pcolormesh(t, f, 10 * np.log10(Sxx), shading='gouraud', cmap='viridis')
            plt.title(f'Spectrogram: {filepath.name}')
            plt.ylabel('Frequency [Hz]')
            plt.xlabel('Time [sec]')
            plt.colorbar(label='Intensity [dB]')
            plt.tight_layout()
            plt.savefig(img_path, dpi=150)
            plt.close()
            
            print(f"  {Fore.GREEN}✓ Spectrogram saved to: {img_path}{Style.RESET_ALL}")
            print(f"  {Fore.CYAN}  Check visually for hidden text/images in frequency domain{Style.RESET_ALL}")
            add_to_summary("SPECTROGRAM", str(img_path))
            log_tool("spectrogram", "✅ Found", str(img_path))
            return True
            
        except ImportError:
            print(f"  {Fore.YELLOW}scipy/matplotlib not installed, using fallback method{Style.RESET_ALL}")
            # Fallback: simple frequency analysis
            print(f"  {Fore.CYAN}Install: pip install scipy matplotlib{Style.RESET_ALL}")
            log_tool("spectrogram", "⏭ Skipped", "scipy/matplotlib missing")
            return False
            
    except Exception as e:
        print(f"  {Fore.RED}Spectrogram generation failed: {e}{Style.RESET_ALL}")
        log_tool("spectrogram", "❌ Error", str(e))
        return False


def chi_square_lsb_detection(filepath):
    """
    Chi-square statistical test untuk mendeteksi LSB steganography.
    Lebih akurat dari sekedar memeriksa LSB ratio.
    """
    if not HAS_PIL:
        print(f"  {Fore.RED}[!] Pillow tidak installed{Style.RESET_ALL}")
        return False
    
    print(f"\n{Fore.CYAN}[CHI-SQUARE] Statistical LSB steganalysis...{Style.RESET_ALL}")
    log_tool("chi-square", "running")
    
    try:
        img = Image.open(filepath).convert('RGB')
        pixels = list(img.getdata())
        
        # Analyze each color channel
        for channel_idx, channel_name in enumerate(['Red', 'Green', 'Blue']):
            # Extract channel values
            values = [p[channel_idx] for p in pixels]
            
            # Chi-square test for LSB randomness
            # Pair of values: (2i, 2i+1) should have similar frequency if stego
            pairs = {}
            for v in values:
                pair_idx = v // 2
                if pair_idx not in pairs:
                    pairs[pair_idx] = [0, 0]
                pairs[pair_idx][v % 2] += 1
            
            # Calculate chi-square statistic
            chi_sq = 0
            total_pairs = len(pairs)
            
            for pair in pairs.values():
                expected = sum(pair) / 2
                if expected > 0:
                    for observed in pair:
                        chi_sq += (observed - expected) ** 2 / expected
            
            # Normalized chi-square (0-1 range)
            chi_sq_norm = chi_sq / len(values) if len(values) > 0 else 0
            
            # Detection threshold (empirical)
            is_stego = chi_sq_norm < 0.1  # Low chi-square = likely stego
            
            print(f"  {channel_name} channel:")
            print(f"    Chi-square: {chi_sq:.4f} (normalized: {chi_sq_norm:.6f})")
            if is_stego:
                print(f"    {Fore.RED}⚠ HIGH probability of LSB steganography!{Style.RESET_ALL}")
                add_to_summary("CHI-SQUARE", f"{channel_name}: STEGO DETECTED (χ²={chi_sq_norm:.6f})")
            else:
                print(f"    {Fore.GREEN}✓ No steganography detected{Style.RESET_ALL}")
        
        log_tool("chi-square", "✅ Complete", f"Channels analyzed: 3")
        return True
        
    except Exception as e:
        print(f"  {Fore.RED}Chi-square analysis failed: {e}{Style.RESET_ALL}")
        log_tool("chi-square", "❌ Error", str(e))
        return False


def analyze_dct_coefficients(filepath):
    """
    Analisis DCT coefficients untuk JPEG steganography.
    Flag sering disembunyikan di koefisien DCT, bukan domain spasial.
    """
    print(f"\n{Fore.CYAN}[DCT-ANALYSIS] JPEG DCT coefficient analysis...{Style.RESET_ALL}")
    log_tool("dct-analysis", "running")
    
    try:
        # Use binwalk to extract DCT data
        result = subprocess.run(
            ["binwalk", "-e", "-D", "jpeg_image", str(filepath)],
            capture_output=True, text=True, timeout=30
        )
        
        out_dir = filepath.parent / f"{filepath.stem}_dct"
        out_dir.mkdir(exist_ok=True)
        
        # Analyze JPEG quantization tables
        with open(filepath, 'rb') as f:
            data = f.read()
            
        # Look for DQT (Define Quantization Table) markers
        dqt_marker = b'\xFF\xDB'
        dqt_positions = []
        pos = 0
        while True:
            pos = data.find(dqt_marker, pos)
            if pos == -1:
                break
            dqt_positions.append(pos)
            pos += 2
        
        print(f"  Found {len(dqt_positions)} DQT markers")
        
        # Analyze coefficient distribution
        # Simple heuristic: check for unusual patterns in DCT coefficients
        # This is a simplified version - full analysis would require libjpeg
        
        if dqt_positions:
            print(f"  {Fore.GREEN}✓ DCT analysis complete{Style.RESET_ALL}")
            add_to_summary("DCT-ANALYSIS", f"{len(dqt_positions)} DQT markers found")
            log_tool("dct-analysis", "✅ Complete", f"{len(dqt_positions)} DQT markers")
        else:
            print(f"  {Fore.YELLOW}No DQT markers found{Style.RESET_ALL}")
            log_tool("dct-analysis", "⬜ Nothing", "no DQT markers")
        
        return True
        
    except Exception as e:
        print(f"  {Fore.RED}DCT analysis failed: {e}{Style.RESET_ALL}")
        log_tool("dct-analysis", "❌ Error", str(e))
        return False


# ── NTFS MFT Parser (SPRINT 1) ──────────────────

def parse_mft_direct(mft_path):
    """
    Parse NTFS Master File Table ($MFT) langsung tanpa mount.
    Berguna untuk forensik disk image.
    """
    print(f"\n{Fore.CYAN}[MFT-PARSER] Parsing NTFS Master File Table...{Style.RESET_ALL}")
    log_tool("mft-parser", "running")
    
    try:
        import struct
        
        mft_file = Path(mft_path)
        if not mft_file.exists():
            print(f"  {Fore.RED}MFT file not found: {mft_path}{Style.RESET_ALL}")
            log_tool("mft-parser", "❌ Error", "file not found")
            return False
        
        # MFT record size is typically 1024 bytes
        RECORD_SIZE = 1024
        
        with open(mft_path, 'rb') as f:
            mft_data = f.read()
        
        print(f"  {Fore.CYAN}MFT file size: {len(mft_data)} bytes{Style.RESET_ALL}")
        print(f"  {Fore.CYAN}Estimated records: {len(mft_data) // RECORD_SIZE}{Style.RESET_ALL}")
        
        # Parse first few records to get structure
        records_found = 0
        deleted_files = []
        active_files = []
        
        offset = 0
        while offset < len(mft_data) - 42:  # Minimum MFT record header is 42 bytes
            # Check for MFT record signature "FILE"
            if mft_data[offset:offset+4] == b'FILE':
                records_found += 1
                
                # Parse MFT record header
                fixup_offset = struct.unpack_from('<H', mft_data, offset + 4)[0]
                fixup_size = struct.unpack_from('<H', mft_data, offset + 6)[0]
                lsns = struct.unpack_from('<Q', mft_data, offset + 8)[0]
                sequence_number = struct.unpack_from('<H', mft_data, offset + 16)[0]
                hard_link_count = struct.unpack_from('<H', mft_data, offset + 18)[0]
                attribute_offset = struct.unpack_from('<H', mft_data, offset + 20)[0]
                flags = struct.unpack_from('<H', mft_data, offset + 22)[0]
                
                # Check if file is deleted (bit 0 of flags = 0)
                is_deleted = not (flags & 0x0001)
                
                # Extract filename from $STANDARD_INFORMATION and $FILE_NAME attributes
                # This is simplified - full parsing would walk all attributes
                attr_off = attribute_offset
                filename = None
                file_size = 0
                
                while attr_off < offset + RECORD_SIZE:
                    # Check attribute header
                    if attr_off + 16 > len(mft_data):
                        break
                    
                    attr_type = struct.unpack_from('<I', mft_data, offset + attr_off)[0]
                    attr_len = struct.unpack_from('<I', mft_data, offset + attr_off + 4)[0]
                    
                    # $FILE_NAME attribute (type 0x30)
                    if attr_type == 0x30 and attr_off + 66 < len(mft_data):
                        name_len = mft_data[offset + attr_off + 64]
                        name_off = offset + attr_off + 66
                        filename = mft_data[name_off:name_off + name_len * 2].decode('utf-16', errors='ignore')
                    
                    # $DATA attribute (type 0x80)
                    if attr_type == 0x80:
                        # Get file size from attribute
                        if attr_off + 56 < len(mft_data):
                            file_size = struct.unpack_from('<Q', mft_data, offset + attr_off + 48)[0]
                    
                    # End of attributes marker
                    if attr_type == 0xFFFFFFFF:
                        break
                    
                    attr_off += attr_len
                    if attr_len == 0:
                        break
                
                if filename and filename.strip():
                    if is_deleted:
                        deleted_files.append((filename, file_size))
                    else:
                        active_files.append((filename, file_size))
                
                # Limit parsing for performance
                if records_found >= 1000:
                    print(f"  {Fore.YELLOW}  Limiting to first 1000 records{Style.RESET_ALL}")
                    break
            
            offset += RECORD_SIZE
        
        # Output results
        out_dir = Path(mft_path).parent / "mft_analysis"
        out_dir.mkdir(exist_ok=True)
        
        print(f"\n  {Fore.GREEN}MFT Analysis Results:{Style.RESET_ALL}")
        print(f"  Total records scanned: {records_found}")
        print(f"  Active files: {len(active_files)}")
        print(f"  Deleted files: {len(deleted_files)}")
        
        if deleted_files:
            print(f"\n  {Fore.RED}Deleted Files (potential CTF targets):{Style.RESET_ALL}")
            for fname, fsize in deleted_files[:20]:  # Show first 20
                print(f"    {Fore.YELLOW}[DELETED]{Style.RESET_ALL} {fname} ({fsize} bytes)")
        
        # Save full results
        results_file = out_dir / "mft_results.txt"
        with open(results_file, 'w', encoding='utf-8') as f:
            f.write("MFT ANALYSIS REPORT\n")
            f.write("=" * 80 + "\n\n")
            f.write(f"Total records: {records_found}\n")
            f.write(f"Active files: {len(active_files)}\n")
            f.write(f"Deleted files: {len(deleted_files)}\n\n")
            
            if deleted_files:
                f.write("DELETED FILES:\n")
                f.write("-" * 80 + "\n")
                for fname, fsize in deleted_files:
                    f.write(f"{fname}\t{fsize}\n")
            
            f.write("\nACTIVE FILES:\n")
            f.write("-" * 80 + "\n")
            for fname, fsize in active_files:
                f.write(f"{fname}\t{fsize}\n")
        
        print(f"\n  {Fore.GREEN}✓ Full results saved to: {results_file}{Style.RESET_ALL}")
        add_to_summary("MFT-PARSER", f"{len(deleted_files)} deleted files found")
        log_tool("mft-parser", "✅ Complete", f"{len(deleted_files)} deleted, {len(active_files)} active")
        
        return True
        
    except Exception as e:
        print(f"  {Fore.RED}MFT parsing failed: {e}{Style.RESET_ALL}")
        import traceback
        traceback.print_exc()
        log_tool("mft-parser", "❌ Error", str(e))
        return False


# ── Network Protocol Reconstructors (SPRINT 1) ──────────────────

def reconstruct_ftp_sessions(pcap_path):
    """
    Rekonstruksi sesi FTP dari PCAP: gabungkan control + data channel,
    extract file yang di-transfer.
    """
    print(f"\n{Fore.CYAN}[FTP-RECON] Reconstructing FTP sessions from PCAP...{Style.RESET_ALL}")
    log_tool("ftp-recon", "running")
    
    try:
        if not AVAILABLE_TOOLS.get('tshark'):
            print(f"  {Fore.YELLOW}tshark not available{Style.RESET_ALL}")
            log_tool("ftp-recon", "⏭ Skipped", "tshark missing")
            return False
        
        out_dir = Path(pcap_path).parent / "ftp_reconstruction"
        out_dir.mkdir(exist_ok=True)
        
        # Extract FTP control commands
        result = subprocess.run(
            ["tshark", "-r", str(pcap_path), "-Y", "ftp.request.command",
             "-T", "fields", "-e", "ip.src", "-e", "ip.dst", "-e", "ftp.request.command"],
            capture_output=True, text=True, timeout=60
        )
        
        if result.stdout.strip():
            commands_file = out_dir / "ftp_commands.txt"
            commands_file.write_text(result.stdout)
            
            print(f"  {Fore.GREEN}✓ FTP commands extracted{Style.RESET_ALL}")
            print(f"  {Fore.CYAN}  Output: {commands_file}{Style.RESET_ALL}")
            
            # Parse commands for file transfers
            lines = result.stdout.strip().split('\n')
            transfers = []
            for line in lines:
                if any(cmd in line.upper() for cmd in ['RETR', 'STOR', 'LIST']):
                    transfers.append(line)
            
            print(f"  {Fore.CYAN}  File transfer commands: {len(transfers)}{Style.RESET_ALL}")
            for t in transfers[:10]:  # Show first 10
                print(f"    {Fore.YELLOW}{t}{Style.RESET_ALL}")
            
            add_to_summary("FTP-RECON", f"{len(transfers)} transfers found")
            log_tool("ftp-recon", "✅ Complete", f"{len(transfers)} transfers")
            return True
        else:
            print(f"  {Fore.YELLOW}No FTP traffic found{Style.RESET_ALL}")
            log_tool("ftp-recon", "⬜ Nothing", "no FTP traffic")
            return False
            
    except Exception as e:
        print(f"  {Fore.RED}FTP reconstruction failed: {e}{Style.RESET_ALL}")
        log_tool("ftp-recon", "❌ Error", str(e))
        return False


def reconstruct_email_sessions(pcap_path):
    """
    Rekonstruksi sesi email (SMTP/POP3/IMAP) dari PCAP.
    Extract attachment, decode MIME, recover messages.
    """
    print(f"\n{Fore.CYAN}[EMAIL-RECON] Reconstructing email sessions from PCAP...{Style.RESET_ALL}")
    log_tool("email-recon", "running")
    
    try:
        if not AVAILABLE_TOOLS.get('tshark'):
            print(f"  {Fore.YELLOW}tshark not available{Style.RESET_ALL}")
            log_tool("email-recon", "⏭ Skipped", "tshark missing")
            return False
        
        out_dir = Path(pcap_path).parent / "email_reconstruction"
        out_dir.mkdir(exist_ok=True)
        
        emails_found = 0
        
        # Extract SMTP traffic
        smtp_result = subprocess.run(
            ["tshark", "-r", str(pcap_path), "-Y", "smtp",
             "-T", "fields", "-e", "frame.time", "-e", "ip.src", "-e", "smtp.req.command"],
            capture_output=True, text=True, timeout=60
        )
        
        if smtp_result.stdout.strip():
            smtp_file = out_dir / "smtp_commands.txt"
            smtp_file.write_text(smtp_result.stdout)
            emails_found += 1
            
            print(f"  {Fore.GREEN}✓ SMTP traffic extracted{Style.RESET_ALL}")
        
        # Extract email addresses
        email_result = subprocess.run(
            ["tshark", "-r", str(pcap_path), "-Y", "smtp",
             "-T", "fields", "-e", "smtp.mail.from", "-e", "smtp.rcpt.to"],
            capture_output=True, text=True, timeout=60
        )
        
        if email_result.stdout.strip():
            emails_file = out_dir / "email_addresses.txt"
            emails_file.write_text(email_result.stdout)
            
            print(f"  {Fore.GREEN}✓ Email addresses extracted{Style.RESET_ALL}")
            lines = [l for l in email_result.stdout.strip().split('\n') if l.strip()]
            print(f"  {Fore.CYAN}  Email addresses: {len(lines)}{Style.RESET_ALL}")
            
            for line in lines[:10]:  # Show first 10
                print(f"    {Fore.YELLOW}{line}{Style.RESET_ALL}")
            
            add_to_summary("EMAIL-RECON", f"{len(lines)} emails found")
        
        log_tool("email-recon", "✅ Complete" if emails_found else "⬜ Nothing", f"{emails_found} sessions")
        return emails_found > 0
        
    except Exception as e:
        print(f"  {Fore.RED}Email reconstruction failed: {e}{Style.RESET_ALL}")
        log_tool("email-recon", "❌ Error", str(e))
        return False


# ── OSINT: GPS & Geolocation Extractor (SPRINT 1) ──────────────────

def extract_gps_coordinates(filepath):
    """
    Extract GPS coordinates dari EXIF metadata.
    Convert DMS ke decimal, generate Google Maps link.
    """
    print(f"\n{Fore.CYAN}[GPS-OSINT] Extracting GPS coordinates from metadata...{Style.RESET_ALL}")
    log_tool("gps-extract", "running")
    
    try:
        if not AVAILABLE_TOOLS.get('exiftool'):
            print(f"  {Fore.YELLOW}exiftool not available{Style.RESET_ALL}")
            log_tool("gps-extract", "⏭ Skipped", "exiftool missing")
            return False
        
        # Run exiftool to get GPS data
        result = subprocess.run(
            ["exiftool", "-GPSLatitude", "-GPSLongitude", "-GPSAltitude",
             "-GPSLatitudeRef", "-GPSLongitudeRef", filepath],
            capture_output=True, text=True, timeout=10
        )
        
        if result.stdout.strip():
            print(f"  {Fore.GREEN}✓ GPS metadata found{Style.RESET_ALL}")
            
            # Parse GPS coordinates
            lines = result.stdout.strip().split('\n')
            gps_data = {}
            
            for line in lines:
                if ':' in line:
                    key, value = line.split(':', 1)
                    gps_data[key.strip()] = value.strip()
            
            # Extract coordinates
            lat = gps_data.get('GPS Latitude', '')
            lon = gps_data.get('GPS Longitude', '')
            
            if lat and lon:
                print(f"  {Fore.CYAN}  Latitude: {lat}{Style.RESET_ALL}")
                print(f"  {Fore.CYAN}  Longitude: {lon}{Style.RESET_ALL}")
                
                # Try to convert to decimal (simplified)
                # Full conversion would parse DMS format
                print(f"\n  {Fore.GREEN}📍 Google Maps link:{Style.RESET_ALL}")
                print(f"  {Fore.BLUE}https://www.google.com/maps?q={lat},{lon}{Style.RESET_ALL}")
                
                # Save results
                out_dir = Path(filepath).parent / "gps_osint"
                out_dir.mkdir(exist_ok=True)
                
                results_file = out_dir / "gps_coordinates.txt"
                with open(results_file, 'w') as f:
                    f.write("GPS COORDINATES REPORT\n")
                    f.write("=" * 80 + "\n\n")
                    f.write(f"File: {filepath}\n")
                    f.write(f"Latitude: {lat}\n")
                    f.write(f"Longitude: {lon}\n")
                    f.write(f"\nGoogle Maps: https://www.google.com/maps?q={lat},{lon}\n\n")
                    f.write("Full GPS data:\n")
                    f.write(result.stdout)
                
                print(f"\n  {Fore.GREEN}✓ Full results saved to: {results_file}{Style.RESET_ALL}")
                add_to_summary("GPS-OSINT", f"{lat}, {lon}")
                log_tool("gps-extract", "✅ Found", f"{lat}, {lon}")
                return True
            else:
                print(f"  {Fore.YELLOW}No GPS coordinates found{Style.RESET_ALL}")
                log_tool("gps-extract", "⬜ Nothing", "no GPS data")
                return False
        else:
            print(f"  {Fore.YELLOW}No GPS metadata found{Style.RESET_ALL}")
            log_tool("gps-extract", "⬜ Nothing", "no GPS metadata")
            return False
            
    except Exception as e:
        print(f"  {Fore.RED}GPS extraction failed: {e}{Style.RESET_ALL}")
        log_tool("gps-extract", "❌ Error", str(e))
        return False

def detect_hidden_unicode(text):
    """
    Zero-width characters sebagai steganografi:
    \\u200b (ZERO WIDTH SPACE)
    \\u200c (ZERO WIDTH NON-JOINER)
    \\u200d (ZERO WIDTH JOINER)
    \\ufeff (ZERO WIDTH NO-BREAK SPACE / BOM)
    Sering di soal misc/web CTF.
    """
    print(f"\n{Fore.CYAN}[UNICODE] Checking for zero-width character steganography...{Style.RESET_ALL}")
    log_tool("unicode-stego", "running")
    
    # Map zero-width characters to binary
    zwc_map = {
        '\u200b': '0',  # ZERO WIDTH SPACE
        '\u200c': '0',  # ZERO WIDTH NON-JOINER
        '\u200d': '1',  # ZERO WIDTH JOINER
        '\ufeff': '1',  # ZERO WIDTH NO-BREAK SPACE
        '\u2060': '0',  # WORD JOINER
        '\u180e': '1',  # MONGOLIAN VOWEL SEPARATOR
    }
    
    # Extract zero-width characters
    bits = []
    zwc_count = 0
    for char in text:
        if char in zwc_map:
            bits.append(zwc_map[char])
            zwc_count += 1
    
    if zwc_count == 0:
        print(f"  {Fore.YELLOW}  ℹ No zero-width characters found{Style.RESET_ALL}")
        log_tool("unicode-stego", "⬜ Nothing", "no ZWC detected")
        return None
    
    print(f"  {Fore.GREEN}  ✓ Found {zwc_count} zero-width characters{Style.RESET_ALL}")
    add_to_summary("UNICODE-ZWC", f"{zwc_count} zero-width characters detected")
    
    # Convert bits to ASCII
    bit_string = ''.join(bits)
    print(f"  {Fore.CYAN}  Binary stream: {bit_string[:100]}...{Style.RESET_ALL}")
    
    # Try to decode as ASCII (8 bits per char)
    decoded_chars = []
    for i in range(0, len(bit_string) - 7, 8):
        byte = bit_string[i:i+8]
        try:
            char = chr(int(byte, 2))
            if char.isprintable() or char in ['\n', '\r', '\t', ' ']:
                decoded_chars.append(char)
        except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
    
    if decoded_chars:
        decoded_text = ''.join(decoded_chars)
        print(f"  {Fore.GREEN}  ✓ Decoded message ({len(decoded_chars)} chars):{Style.RESET_ALL}")
        print(f"  {Fore.GREEN}  {decoded_text[:200]}{Style.RESET_ALL}")
        
        # Scan for flags
        scan_text_for_flags(decoded_text, "UNICODE-ZWC")
        collect_base64_from_text(decoded_text)
        
        # Save extracted data
        out_dir = filepath.parent / f"{filepath.stem}_unicode_stego" if 'filepath' in dir() else Path("output_unicode_stego")
        out_dir.mkdir(exist_ok=True)
        (out_dir / "zwc_extracted.txt").write_text(decoded_text)
        (out_dir / "zwc_binary.txt").write_text(bit_string)
        add_to_summary("UNICODE-DECODED", f"Extracted {len(decoded_chars)} characters")
        
        log_tool("unicode-stego", "✅ Found" if FLAG_FOUND else "⬜ Something",
                 f"{zwc_count} ZWC → {len(decoded_chars)} chars")
        
        return decoded_text
    else:
        print(f"  {Fore.YELLOW}  ℹ Could not decode to readable text{Style.RESET_ALL}")
        log_tool("unicode-stego", "⬜ Nothing", "decode failed")
        return None

def bruteforce_steghide(filepath, wordlist=None, delay=0.1, parallel=5):
    if not AVAILABLE_TOOLS.get('steghide'): return
    wordlist=wordlist or DEFAULT_WORDLIST
    print(f"{Fore.GREEN}[BRUTEFORCE] {parallel} thread, {len(wordlist)} password...{Style.RESET_ALL}")
    out_dir=filepath.parent/f"{filepath.stem}_bruteforce"; out_dir.mkdir(exist_ok=True)
    found={"value":False}
    def try_pw(pw):
        if found["value"] or check_early_exit(): return None
        try:
            out_file=out_dir/f"out_{re.sub(r'[^a-z0-9]','_',pw)}.txt"
            result=subprocess.run(["steghide","extract","-sf",str(filepath),
                                   "-xf",str(out_file),"-f","-p",pw],
                                  capture_output=True,text=True,timeout=15)
            if result.returncode==0 and out_file.exists() and out_file.stat().st_size>0:
                return (pw, out_file.read_text(errors='ignore'))
        except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
        return None
    with ThreadPoolExecutor(max_workers=parallel) as ex:
        futures={ex.submit(try_pw,pw):pw for pw in wordlist}
        for future in as_completed(futures):
            if check_early_exit(): break
            res=future.result()
            if res:
                pw,content=res
                print(f"{Fore.GREEN}[BRUTEFORCE] Password: {pw}{Style.RESET_ALL}")
                collect_base64_from_text(content)
                scan_text_for_flags(content, "BRUTEFORCE")
                found["value"]=True; break

# ── PCAP ─────────────────────────────────────

def _tshark(filepath, *args, timeout=60):
    if not AVAILABLE_TOOLS.get('tshark'): return ""
    try:
        return subprocess.run(["tshark","-r",str(filepath)]+list(args),
                              capture_output=True,text=True,timeout=timeout).stdout
    except: return ""

def analyze_pcap_basic(filepath):
    if not AVAILABLE_TOOLS.get('capinfos'): return
    try:
        result=subprocess.run(["capinfos",str(filepath)],capture_output=True,text=True,timeout=30)
        print(f"{Fore.CYAN}{result.stdout}{Style.RESET_ALL}")
        (filepath.parent/f"{filepath.stem}_pcap_info.txt").write_text(result.stdout)
        collect_base64_from_text(result.stdout)
    except Exception as e: print(f"{Fore.RED}[PCAP] Gagal: {e}{Style.RESET_ALL}")

def extract_http_objects(filepath):
    if not AVAILABLE_TOOLS.get('tshark'): return
    out_dir=filepath.parent/f"{filepath.stem}_http_objects"; out_dir.mkdir(exist_ok=True)
    try:
        subprocess.run(["tshark","-r",str(filepath),"--export-objects",f"http,{out_dir}","-q"],
                       capture_output=True,text=True,timeout=120)
        files=list(out_dir.glob("*"))
        if files:
            for f in files[:10]: analyze_extracted_file(f)
            add_to_summary("PCAP-HTTP",f"{len(files)} objects → '{out_dir.name}'")
    except Exception as e: print(f"{Fore.RED}[PCAP] HTTP gagal: {e}{Style.RESET_ALL}")

def extract_dns_queries(filepath):
    if not AVAILABLE_TOOLS.get('tshark'): return
    output=_tshark(filepath,"-T","fields","-e","dns.qry.name","-Y","dns","-q")
    if output.strip():
        queries=[q for q in output.split('\n') if q]
        (filepath.parent/f"{filepath.stem}_dns_queries.txt").write_text(output)
        collect_base64_from_text(output)
        scan_text_for_flags(output, "PCAP-DNS")
        add_to_summary("PCAP-DNS",f"{len(queries)} queries saved")

def extract_credentials(filepath):
    if not AVAILABLE_TOOLS.get('tshark'): return
    creds=[]
    for proto,extra in [("FTP",["-T","fields","-e","ftp.user","-e","ftp.pass","-Y","ftp","-q"]),
                        ("HTTP-Auth",["-T","fields","-e","http.authbasic","-Y","http.authbasic","-q"]),
                        ("Telnet",["-T","fields","-e","telnet.data","-Y","telnet","-q"])]:
        out=_tshark(filepath,*extra)
        if out.strip(): creds.append((proto,out.strip()))
    if creds:
        creds_file=filepath.parent/f"{filepath.stem}_credentials.txt"
        with open(creds_file,'w') as f:
            for proto,data in creds:
                f.write(f"{proto}:\n{data}\n\n")
                scan_text_for_flags(data, f"PCAP-CREDS-{proto}")
        add_to_summary("PCAP-CREDENTIALS",f"Saved to '{creds_file.name}'")

def search_pcap_flags(filepath):
    if not AVAILABLE_TOOLS.get('tshark'): return
    for label,extra in [("data",["-T","fields","-e","data","-q"]),
                        ("HTTP",["-T","fields","-e","http.file_data","-q"]),
                        ("TCP", ["-T","fields","-e","tcp.payload","-q"])]:
        out=_tshark(filepath,*extra,timeout=120)
        scan_text_for_flags(out, f"PCAP-{label.upper()}")

def reconstruct_streams(filepath):
    if not AVAILABLE_TOOLS.get('tshark'): return
    out_dir=filepath.parent/f"{filepath.stem}_streams"; out_dir.mkdir(exist_ok=True)
    nums=set(_tshark(filepath,"-T","fields","-e","tcp.stream","-q").strip().split('\n'))
    nums=[s for s in nums if s]
    if not nums: return
    for num in nums[:10]:
        try:
            result=subprocess.run(["tshark","-r",str(filepath),"-q","-z",f"follow,tcp,ascii,{num}"],
                                  capture_output=True,text=True,timeout=30)
            (out_dir/f"stream_{num}.txt").write_text(result.stdout)
            scan_text_for_flags(result.stdout, f"PCAP-STREAM-{num}")
            collect_base64_from_text(result.stdout)
        except: continue
    add_to_summary("PCAP-STREAMS",f"{min(len(nums),10)} streams → '{out_dir.name}'")

def analyze_pcap_timeline(filepath):
    if not AVAILABLE_TOOLS.get('tshark'): return
    out=_tshark(filepath,"-T","fields","-e","frame.time","-e","http.request.uri",
                "-e","http.request.method","-e","ip.src","-Y","http.request","-q")
    if not out.strip(): return
    lines=out.strip().split('\n')
    (filepath.parent/f"{filepath.stem}_timeline.txt").write_text("\n".join(lines))
    add_to_summary("PCAP-TIMELINE",f"{len(lines)} requests")

def detect_attack_patterns(filepath):
    if not AVAILABLE_TOOLS.get('tshark'): return
    http=_tshark(filepath,"-T","fields","-e","http.request.uri","-e","http.request.method","-Y","http","-q")
    sigs={'SQL Injection':r"(\bunion\b|\bselect\b|\binsert\b|\bdelete\b|\bdrop\b|%27|')",
          'XSS':r"(<script|javascript:|onerror=|onload=|alert\()",
          'LFI/RFI':r"(\.\.\/|\.\.\\|%2e%2e%2f|file:\/\/)",
          'Cmd Injection':r"(;|\||&&|\$\(|`)\s*(cat|ls|pwd|whoami|id)",
          'Path Traversal':r"(%2e%2e%2f|%2e%2e%5c){1,}"}
    for name,pat in sigs.items():
        matches=re.findall(pat,http,re.IGNORECASE)
        if matches: add_to_summary("PCAP-ATTACK",f"{name}: {len(matches)}")

def analyze_post_data(filepath):
    if not AVAILABLE_TOOLS.get('tshark'): return
    out=_tshark(filepath,"-T","fields","-e","http.request.method","-e","http.request.uri",
                "-e","http.file_data","-Y",'http.request.method == "POST"',"-q")
    if not out.strip(): return
    scan_text_for_flags(out, "PCAP-POST")

def check_unusual_ports(filepath):
    if not AVAILABLE_TOOLS.get('tshark'): return
    out=_tshark(filepath,"-T","fields","-e","tcp.dstport","-e","udp.dstport","-q")
    common={'80','443','22','21','53','25','110','143','993','995','8080','8443'}
    counts={}
    for line in out.split('\n'):
        for port in line.split('\t'):
            if port: counts[port]=counts.get(port,0)+1
    unusual={p:c for p,c in counts.items() if p not in common}
    for port,cnt in sorted(unusual.items(),key=lambda x:x[1],reverse=True)[:10]:
        add_to_summary("PCAP-PORT",f"Port {port}: {cnt}")

def analyze_pcap_full(filepath):
    print(f"\n{Fore.BLUE}{'='*60}\nPCAP FULL: {filepath.name}\n{'='*60}{Style.RESET_ALL}")
    analyze_pcap_basic(filepath)
    if check_early_exit(): return
    extract_http_objects(filepath)
    extract_dns_queries(filepath)
    if check_early_exit(): return
    
    # Segmented payload decoder (untuk soal Ph4nt0m-style)
    analyze_pcap_segmented_payload(filepath)
    if check_early_exit(): return
    
    analyze_dns_tunneling(filepath)  # DNS tunneling detector
    if check_early_exit(): return
    extract_credentials(filepath)
    analyze_pcap_timeline(filepath); detect_attack_patterns(filepath)
    analyze_post_data(filepath); search_pcap_flags(filepath)
    reconstruct_streams(filepath); check_unusual_ports(filepath)

# ── Disk Image ───────────────────────────────

def extract_compressed_disk(filepath):
    out_dir=filepath.parent/f"{filepath.stem}_extracted"; out_dir.mkdir(exist_ok=True)
    file_type=subprocess.getoutput(f"file -b '{filepath}'").lower()
    try:
        if "gzip" in file_type:
            import gzip
            out=out_dir/"disk_image.dd"
            with gzip.open(filepath,'rb') as fi, open(out,'wb') as fo: shutil.copyfileobj(fi,fo)
            if out.exists(): return out
        elif "zip" in file_type:
            import zipfile
            sub=out_dir/f"{filepath.stem}_zip"; sub.mkdir(exist_ok=True)
            with zipfile.ZipFile(filepath,'r') as zf: zf.extractall(sub)
            files=[f for f in sub.rglob("*") if f.is_file()]
            if files: return max(files,key=lambda x:x.stat().st_size)
    except Exception as e: print(f"{Fore.YELLOW}[!] Ekstraksi gagal: {e}{Style.RESET_ALL}")
    return filepath

def analyze_disk_image(filepath):
    print(f"{Fore.GREEN}[DISK] Analisis disk image...{Style.RESET_ALL}")
    out_dir=filepath.parent/f"{filepath.stem}_disk_analysis"; out_dir.mkdir(exist_ok=True)
    try:
        cmd=f"strings -n 8 '{filepath}' | head -20000"
        str_out=subprocess.run(cmd,shell=True,capture_output=True,text=True,timeout=30).stdout
        (out_dir/"extracted_strings.txt").write_text(str_out[:100000],errors='ignore')
        scan_text_for_flags(str_out, "DISK")
        collect_base64_from_text(str_out[:50000])
        scan_size=min(10*1024*1024,filepath.stat().st_size)
        raw=filepath.read_bytes()[:scan_size]
        for ext,sig in {"png":b"\x89PNG","jpg":b"\xff\xd8\xff","zip":b"PK\x03\x04","pdf":b"%PDF"}.items():
            idx=raw.find(sig)
            if idx!=-1:
                add_to_summary("DISK-FILE",f"{ext.upper()} at offset {idx}")
        add_to_summary("DISK-ANALYSIS",f"Results in '{out_dir.name}'")
        new_flags = list(found_flags_set)
        log_tool("disk-analysis", "✅ Found" if new_flags else "⬜ Analyzed",
                 ", ".join(new_flags) if new_flags else f"output: {out_dir.name}")
    except Exception as e:
        print(f"{Fore.RED}[DISK] Gagal: {e}{Style.RESET_ALL}")
        log_tool("disk-analysis", "❌ Error", str(e))

# ── Windows Event Log ────────────────────────

def parse_raw_event_log(filepath):
    try:
        raw=filepath.read_bytes()
        strings_data=''.join(chr(b) if 32<=b<=126 else '\n' for b in raw)
        scan_text_for_flags(strings_data, "EVENT")
        for b64 in re.findall(r'[A-Za-z0-9+/]{20,}={0,2}',strings_data)[:10]:
            decoded=decode_base64(b64)
            if decoded:
                collect_base64_from_text(decoded)
                scan_text_for_flags(decoded, "EVENT-B64")
    except Exception as e: print(f"{Fore.RED}[RAW-EVENT] Gagal: {e}{Style.RESET_ALL}")

def analyze_windows_event_logs(filepath):
    print(f"{Fore.GREEN}[WINDOWS-EVENT] Analisis Windows Event Logs...{Style.RESET_ALL}")
    parse_raw_event_log(filepath)

# ── Post-Analysis Output Scanner ─────────────

def scan_all_outputs_for_flags(filepath):
    """
    Scan SEMUA output files/folders yang dibuat selama analisis.
    Dipanggil SEBELUM print_final_report() untuk memastikan tidak ada flag yang terlewat.
    """
    if check_early_exit():
        return 0
    
    print(f"\n{Fore.CYAN}[POST-SCAN] Scanning all output files for hidden flags...{Style.RESET_ALL}")
    
    parent = filepath.parent
    scanned_files = 0
    new_flags = 0
    
    # 1. Auto-detect semua output directories (pattern: namafile_*/ atau *_folder)
    output_patterns = [
        f"{filepath.stem}_*",      # digits_binary_render, digits_steghide, etc
        f"*_{filepath.stem}*",     # extracted_digits, decoded_digits, etc
    ]
    
    for pattern in output_patterns:
        for item in parent.glob(pattern):
            if item.is_dir():
                # Scan semua file di folder
                for f in item.rglob('*'):
                    if f.is_file() and f.suffix in ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.txt', '.bin', '.dat', '']:
                        try:
                            # strings scan dengan threshold rendah
                            strings_out = subprocess.getoutput(f"strings -n 3 '{f}'")
                            if strings_out:
                                found = scan_text_for_flags(strings_out, f"POST-SCAN-{f.name}")
                                new_flags += len(found)
                            
                            # Coba decode base64 dari output
                            b64_matches = re.findall(r'[A-Za-z0-9+/]{20,}={0,2}', strings_out)
                            for b64 in b64_matches[:5]:
                                decoded = decode_base64(b64)
                                if decoded:
                                    found = scan_text_for_flags(decoded, f"POST-SCAN-B64-{f.name}")
                                    new_flags += len(found)
                        except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
                        scanned_files += 1
            elif item.is_file():
                # File langsung (bukan folder)
                try:
                    strings_out = subprocess.getoutput(f"strings -n 3 '{item}'")
                    if strings_out:
                        found = scan_text_for_flags(strings_out, f"POST-SCAN-{item.name}")
                        new_flags += len(found)
                except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
                scanned_files += 1
    
    # 2. Scan juga output files dengan pattern khusus
    specific_patterns = [
        f"{filepath.stem}_binary_render",
        f"{filepath.stem}_steghide",
        f"{filepath.stem}_stegseek",
        f"{filepath.stem}_outguess",
        f"{filepath.stem}_decoded_*",
        f"{filepath.stem}_crypto",
        f"{filepath.stem}_reversing",
        f"{filepath.stem}_foremost",
        f"{filepath.stem}_bruteforce",
        f"{filepath.stem}_bitplanes",
        f"{filepath.stem}_channels",
        f"{filepath.stem}_remap",
        f"{filepath.stem}_exif",
        f"{filepath.stem}_strings.txt",
    ]
    
    for pattern in specific_patterns:
        for item in parent.glob(pattern):
            if item.is_dir():
                for f in item.rglob('*'):
                    if f.is_file():
                        try:
                            strings_out = subprocess.getoutput(f"strings -n 3 '{f}'")
                            if strings_out:
                                found = scan_text_for_flags(strings_out, f"POST-SCAN-{f.name}")
                                new_flags += len(found)
                        except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
                        scanned_files += 1
            elif item.is_file():
                try:
                    strings_out = subprocess.getoutput(f"strings -n 3 '{item}'")
                    if strings_out:
                        found = scan_text_for_flags(strings_out, f"POST-SCAN-{item.name}")
                        new_flags += len(found)
                except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
                scanned_files += 1
    
    if scanned_files > 0:
        print(f"{Fore.GREEN}[POST-SCAN] ✅ Scanned {scanned_files} output files, found {new_flags} new flag(s){Style.RESET_ALL}")
    else:
        print(f"{Fore.YELLOW}[POST-SCAN] No output files found to scan{Style.RESET_ALL}")
    
    return new_flags

# ── Report ────────────────────────────────────

def print_final_report(filename):
    W = 62
    print(f"\n{Fore.YELLOW}{'═'*W}")
    print(f"  📋  FINAL REPORT — {filename}")
    print(f"{'═'*W}{Style.RESET_ALL}")

    # ── TOOL LOG TABLE (selalu tampil, berurutan)
    if tool_log:
        # Filter duplikat tool (simpan entry terakhir per tool)
        seen = {}
        for entry in tool_log:
            if entry["status"] != "running":
                seen[entry["tool"]] = entry
        unique_log = list(seen.values())

        print(f"\n{Fore.CYAN}{'─'*W}")
        print(f"  🛠  TOOLS YANG DIJALANKAN ({len(unique_log)})")
        print(f"{'─'*W}{Style.RESET_ALL}")
        print(f"  {'Tool':<20} {'Status':<20} Hasil")
        print(f"  {'─'*18} {'─'*18} {'─'*20}")
        for entry in unique_log:
            tool   = entry["tool"]
            status = entry["status"]
            result = entry["result"][:35] + "..." if len(entry["result"]) > 35 else entry["result"]
            if "✅" in status:
                color = Fore.GREEN
            elif "⬜" in status:
                color = Fore.WHITE
            elif "⏭" in status:
                color = Fore.YELLOW
            else:
                color = Fore.RED
            print(f"  {color}{tool:<20} {status:<20} {result}{Style.RESET_ALL}")

    # ── FLAG(s) — hanya flag unik, format jelas
    unique_flags = sorted(found_flags_set)
    if unique_flags:
        print(f"\n{Fore.GREEN}{'─'*W}")
        print(f"  🚩  FLAG DITEMUKAN ({len(unique_flags)})")
        print(f"{'─'*W}{Style.RESET_ALL}")
        for i, flag in enumerate(unique_flags, 1):
            print(f"  {Fore.GREEN}{Style.BRIGHT}{i}. {flag}{Style.RESET_ALL}")
    else:
        print(f"\n{Fore.YELLOW}  ⚠  Belum ada flag ditemukan.{Style.RESET_ALL}")

    # ── Base64 decoded
    if base64_collector:
        print(f"\n{Fore.CYAN}{'─'*W}")
        print(f"  🔓  BASE64 DECODED ({len(base64_collector)})")
        print(f"{'─'*W}{Style.RESET_ALL}")
        for i, item in enumerate(base64_collector[:5], 1):
            print(f"  {i}. {item[:90]}{'...' if len(item)>90 else ''}")

    # ── Extractions
    extractions = [i for i in flag_summary if "-EXTRACT" in i or "-ANALYZED" in i]
    if extractions:
        print(f"\n{Fore.BLUE}{'─'*W}")
        print(f"  📦  EXTRACTIONS ({len(extractions)})")
        print(f"{'─'*W}{Style.RESET_ALL}")
        for item in extractions:
            m = re.search(r'\[.*?\]\s*(.+)', item)
            print(f"  • {m.group(1) if m else item}")

    print(f"\n{Fore.YELLOW}{'═'*W}{Style.RESET_ALL}\n")

# ── Detailed Verbose Report (v6.0) ───────────────────

def print_detailed_report(filepath, file_info=None):
    """
    Print comprehensive analysis report with all findings.
    This is ALWAYS called to ensure output is shown.
    """
    import sys
    
    W = 70
    filename = Path(filepath).name
    
    print(f"\n{Fore.CYAN}{'═' * W}", flush=True)
    print(f"  📊  RAVEN DETAILED ANALYSIS REPORT — {filename}", flush=True)
    print(f"{'═' * W}{Style.RESET_ALL}", flush=True)
    
    # File information
    if file_info:
        print(f"\n{Fore.YELLOW}📁 File Information:{Style.RESET_ALL}", flush=True)
        for key, value in file_info.items():
            print(f"  {Fore.CYAN}{key}:{Style.RESET_ALL} {value}", flush=True)
    
    # Tool execution log (detailed)
    if tool_log:
        seen = {}
        for entry in tool_log:
            if entry["status"] != "running":
                seen[entry["tool"]] = entry
        unique_log = list(seen.values())
        
        print(f"\n{Fore.GREEN}🔧 Tools Executed ({len(unique_log)}):{Style.RESET_ALL}", flush=True)
        success_count = sum(1 for t in unique_log if "✅" in t["status"])
        skip_count = sum(1 for t in unique_log if "⏭" in t["status"])
        error_count = sum(1 for t in unique_log if "❌" in t["status"])
        
        print(f"  {Fore.GREEN}✅ Success: {success_count}{Style.RESET_ALL} | ", end="", flush=True)
        print(f"{Fore.YELLOW}⏭ Skipped: {skip_count}{Style.RESET_ALL} | ", end="", flush=True)
        print(f"{Fore.RED}❌ Errors: {error_count}{Style.RESET_ALL}", flush=True)
        print()
        
        for i, entry in enumerate(unique_log, 1):
            tool = entry["tool"]
            status = entry["status"]
            result = entry.get("result", "")
            
            # Color code status
            if "✅" in status:
                icon = f"{Fore.GREEN}✅{Style.RESET_ALL}"
            elif "⬜" in status:
                icon = f"{Fore.WHITE}⬜{Style.RESET_ALL}"
            elif "⏭" in status:
                icon = f"{Fore.YELLOW}⏭{Style.RESET_ALL}"
            else:
                icon = f"{Fore.RED}❌{Style.RESET_ALL}"
            
            print(f"  {i}. {icon} {Fore.CYAN}{tool}{Style.RESET_ALL}: {status}", flush=True)
            if result and len(result) > 0:
                # Show first 100 chars of result
                preview = result[:100] + "..." if len(result) > 100 else result
                print(f"     {Fore.WHITE}→ {preview}{Style.RESET_ALL}", flush=True)
    
    # All findings (not just flags)
    if flag_summary:
        print(f"\n{Fore.MAGENTA}📝 All Findings ({len(flag_summary)}):{Style.RESET_ALL}", flush=True)
        
        # Group by category
        categories = {}
        for item in flag_summary:
            match = re.search(r'\[(.*?)\]', item)
            if match:
                cat = match.group(1)
                if cat not in categories:
                    categories[cat] = []
                categories[cat].append(item)
        
        for cat, items in sorted(categories.items()):
            print(f"\n  {Fore.YELLOW}📂 {cat} ({len(items)} findings):{Style.RESET_ALL}", flush=True)
            for item in items[:5]:  # Show max 5 per category
                content = re.sub(r'\[.*?\]\s*', '', item)
                print(f"    • {content[:80]}", flush=True)
            if len(items) > 5:
                print(f"    {Fore.YELLOW}... and {len(items) - 5} more{Style.RESET_ALL}", flush=True)
    
    # Base64 decoded (verbose)
    if base64_collector:
        print(f"\n{Fore.BLUE}🔓 Base64 Decoded ({len(base64_collector)}):{Style.RESET_ALL}", flush=True)
        for i, item in enumerate(base64_collector[:10], 1):
            print(f"  {i}. {item[:100]}{'...' if len(item) > 100 else ''}", flush=True)
        if len(base64_collector) > 10:
            print(f"  {Fore.YELLOW}... and {len(base64_collector) - 10} more{Style.RESET_ALL}", flush=True)
    
    # Flags section
    unique_flags = sorted(found_flags_set)
    if unique_flags:
        print(f"\n{Fore.GREEN}{'─' * W}{Style.RESET_ALL}", flush=True)
        print(f"  🚩  FLAGS FOUND ({len(unique_flags)})", flush=True)
        print(f"{'─' * W}", flush=True)
        for i, flag in enumerate(unique_flags, 1):
            print(f"  {Fore.GREEN}{Style.BRIGHT}{i}. {flag}{Style.RESET_ALL}", flush=True)
        print(f"{Fore.GREEN}{'─' * W}{Style.RESET_ALL}\n", flush=True)
    else:
        print(f"\n{Fore.YELLOW}{'─' * W}{Style.RESET_ALL}", flush=True)
        print(f"  ⚠️  No flags found in this file", flush=True)
        print(f"{'─' * W}", flush=True)
        print(f"\n{Fore.CYAN}💡 Recommendations:{Style.RESET_ALL}", flush=True)
        print(f"  • Try different analysis modes (e.g., --steghide, --lsb, --crypto)", flush=True)
        print(f"  • Use --all for comprehensive scan", flush=True)
        print(f"  • Check output folders for detailed tool results", flush=True)
        print(f"  • Try manual inspection with strings, exiftool, binwalk", flush=True)
        print(f"\n{Fore.YELLOW}Example commands:{Style.RESET_ALL}", flush=True)
        print(f"  raven {filename} --auto         # Auto-detect all tools", flush=True)
        print(f"  raven {filename} --all          # Force all tools", flush=True)
        print(f"  raven {filename} --quick        # Fast scan", flush=True)
        print(f"  strings {filename} | grep flag  # Manual string search", flush=True)
        print(f"{Fore.YELLOW}{'─' * W}{Style.RESET_ALL}\n", flush=True)
    
    # Output folders
    print(f"{Fore.CYAN}📂 Check output folders for detailed results:{Style.RESET_ALL}", flush=True)
    print(f"  • {filename}_*/  - Tool-specific output folders", flush=True)
    print(f"  • Use 'ls -la {filename}_*/' to see all results", flush=True)
    
    print(f"\n{Fore.CYAN}{'═' * W}{Style.RESET_ALL}\n", flush=True)


# ── Main Processor ────────────────────────────

def _build_result():
    return {'flags':[i for i in flag_summary if "FLAG" in i.upper() and "-FLAG" in i],
            'extractions':[i for i in flag_summary if "-EXTRACT" in i],
            'base64':base64_collector.copy()}


# ═══════════════════════════════════════════════════════
# ══ FITUR v3.1 ═════════════════════════════════════════
# ═══════════════════════════════════════════════════════

# ── EXTENDED DECODE ENGINE ───────────────────

def decode_base32(candidate):
    """Decode Base32 — case-insensitive, auto-padding
    DNS tunneling sering kirim lowercase → harus .upper() dulu
    """
    import base64 as _b64
    try:
        clean = re.sub(r'[^A-Za-z2-7]', '', candidate).upper()
        if len(clean) < 8: return None
        pad = (8 - len(clean) % 8) % 8
        decoded = _b64.b32decode(clean + '=' * pad)
        s = decoded.decode('utf-8', errors='ignore')
        if len(s.strip()) > 3 and all(c.isprintable() or c.isspace() for c in s):
            return s
    except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
    return None

def decode_base58(candidate):
    """Decode Base58 (Bitcoin-style)"""
    ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
    try:
        if not all(c in ALPHABET for c in candidate): return None
        if len(candidate) < 4: return None
        n = 0
        for char in candidate:
            n = n * 58 + ALPHABET.index(char)
        result = []
        while n > 0:
            result.append(n % 256)
            n //= 256
        result.reverse()
        s = bytes(result).decode('utf-8', errors='ignore')
        if len(s.strip()) > 3 and all(c.isprintable() for c in s.strip()):
            return s
    except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
    return None

def decode_base85(candidate):
    import base64 as _b64
    try:
        decoded = _b64.b85decode(candidate)
        s = decoded.decode('utf-8', errors='ignore')
        if len(s.strip()) > 3: return s
    except:
        try:
            decoded = _b64.a85decode(candidate)
            s = decoded.decode('utf-8', errors='ignore')
            if len(s.strip()) > 3: return s
        except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
    return None

def decode_url_encoding(candidate):
    """Decode URL percent-encoding"""
    try:
        from urllib.parse import unquote
        decoded = unquote(candidate)
        if decoded != candidate and len(decoded) > 3:
            return decoded
    except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
    return None

def decode_hex_string(candidate):
    """Decode hex string (pure hex, no spaces)"""
    try:
        clean = re.sub(r'[^0-9a-fA-F]', '', candidate)
        if len(clean) >= 8 and len(clean) % 2 == 0:
            decoded = bytes.fromhex(clean).decode('utf-8', errors='ignore')
            if len(decoded.strip()) > 3 and all(c.isprintable() or c.isspace() for c in decoded):
                return decoded
    except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
    return None

def decode_xor_brute(data_bytes, key_range=256):
    """Brute-force XOR single-byte key, return candidates with flag patterns"""
    results = []
    for key in range(key_range):
        decoded = bytes(b ^ key for b in data_bytes)
        try:
            s = decoded.decode('utf-8', errors='ignore')
            for pat in COMMON_FLAG_PATTERNS:
                if re.search(pat, s, re.IGNORECASE):
                    results.append((key, s))
                    break
        except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
    return results

def auto_decode_multi(text, source=""):
    """Coba semua encoding: b64, b32, b58, b85, hex, url, xor pada semua kandidat"""
    global found_flags_set
    import base64 as _b64
    found = []

    decoders = [
        ("base64",  decode_base64),
        ("base32",  decode_base32),
        ("base58",  decode_base58),
        ("base85",  decode_base85),
        ("hex",     decode_hex_string),
        ("url",     decode_url_encoding),
    ]

    # Kandidat string panjang dari teks
    candidates = re.findall(r'[A-Za-z0-9+/=%]{8,}', text)

    for cand in candidates[:100]:
        for enc_name, decoder in decoders:
            result = decoder(cand)
            if result and result.strip() != cand:
                # Scan hasil decode untuk flag
                for pat in COMMON_FLAG_PATTERNS:
                    for m in re.findall(pat, result, re.IGNORECASE):
                        m_clean = m.strip()
                        if m_clean not in found_flags_set:
                            found_flags_set.add(m_clean)
                            found.append(m_clean)
                            print(f"\n{Fore.GREEN}{'─'*50}")
                            print(f"  🚩 FLAG dari {enc_name.upper()}!")
                            print(f"  {Fore.YELLOW}{m_clean}{Style.RESET_ALL}")
                            print(f"{Fore.GREEN}  Raw   : {cand[:60]}")
                            print(f"  Sumber: {source}{Style.RESET_ALL}")
                            print(f"{Fore.GREEN}{'─'*50}{Style.RESET_ALL}\n")
                            add_to_summary(f"FLAG-{enc_name.upper()}", m_clean)

    # XOR brute pada chunk raw bytes
    raw_chunks = re.findall(r'[^\x20-\x7e]{8,}', text)
    for chunk in raw_chunks[:5]:
        xor_results = decode_xor_brute(chunk.encode('latin-1', errors='ignore'))
        for key, decoded in xor_results:
            for pat in COMMON_FLAG_PATTERNS:
                for m in re.findall(pat, decoded, re.IGNORECASE):
                    m_clean = m.strip()
                    if m_clean not in found_flags_set:
                        found_flags_set.add(m_clean)
                        found.append(m_clean)
                        print(f"\n{Fore.GREEN}{'─'*50}")
                        print(f"  🚩 FLAG dari XOR (key=0x{key:02x})!")
                        print(f"  {Fore.YELLOW}{m_clean}{Style.RESET_ALL}")
                        print(f"{Fore.GREEN}{'─'*50}{Style.RESET_ALL}\n")
                        add_to_summary("FLAG-XOR", m_clean)
    return found


# ── DISK: PARTITION TABLE ANALYSIS ───────────

def analyze_disk_partitions(filepath):
    """
    Parse MBR/GPT partition table, mount tiap partisi, scan isinya.
    Khusus deteksi: partisi hidden (0x83 Linux, 0x05 Extended, dll.)
    """
    print(f"{Fore.GREEN}[PARTITION] Analisis struktur partisi...{Style.RESET_ALL}")
    log_tool("partition-scan", "running")
    found_before = len(found_flags_set)
    out_dir = filepath.parent / f"{filepath.stem}_partitions"
    out_dir.mkdir(exist_ok=True)

    # ── Gunakan mmls (Sleuth Kit) atau fdisk
    partition_info = ""
    tool_used = None

    # Coba mmls dulu
    mmls_out = subprocess.getoutput(f"mmls '{filepath}' 2>&1")
    if "cannot" not in mmls_out.lower() and "error" not in mmls_out.lower() and mmls_out.strip():
        partition_info = mmls_out
        tool_used = "mmls"
    else:
        # Fallback ke fdisk
        fdisk_out = subprocess.getoutput(f"fdisk -l '{filepath}' 2>&1")
        if fdisk_out.strip():
            partition_info = fdisk_out
            tool_used = "fdisk"

    if partition_info:
        print(f"{Fore.CYAN}[PARTITION] Tabel partisi ({tool_used}):{Style.RESET_ALL}")
        print(partition_info)
        (out_dir / "partition_table.txt").write_text(partition_info)

    # ── Parse partisi dari output
    PARTITION_TYPES = {
        '0x0b': 'FAT32', '0x0c': 'FAT32 LBA', '0x0e': 'FAT16 LBA',
        '0x06': 'FAT16',  '0x07': 'NTFS/HPFS', '0x83': 'Linux ext',
        '0x82': 'Linux swap', '0x05': 'Extended', '0x0f': 'Extended LBA',
        '0x8e': 'Linux LVM', '0xa5': 'FreeBSD', '0xee': 'GPT',
        '0xef': 'EFI System',
    }

    partitions = []

    # Parse mmls output: "000:  Meta  0000000000  0000000000  0000000001  Primary Table (#0)"
    # "002:  00   0000000063  0000008126  0000008064  NTFS / exFAT (0x07)"
    for line in partition_info.splitlines():
        # Format mmls
        m = re.search(r'(\d+):\s+\S+\s+(\d+)\s+(\d+)\s+(\d+)', line)
        if m:
            idx, start, end, size = m.groups()
            type_match = re.search(r'\(0x([0-9a-fA-F]+)\)', line)
            ptype = f"0x{type_match.group(1).lower().zfill(2)}" if type_match else "unknown"
            hidden = ptype in ['0x83','0x82','0x8e','0xa5']
            partitions.append({
                'idx': idx, 'start': int(start), 'size': int(size),
                'type': ptype, 'desc': PARTITION_TYPES.get(ptype, ptype),
                'hidden': hidden, 'line': line.strip()
            })

        # Format fdisk: "/dev/loop0p1  *     2048  10239999  10237952  4.9G 83 Linux"
        m2 = re.search(r'(\d+)\s+(\d+)\s+\d+\s+[\d.]+[KMGT]\s+([0-9a-fA-F]+)\s+(.+)', line)
        if m2 and 'Device' not in line:
            start, end_val, ptype_hex, desc = m2.groups()
            ptype = f"0x{ptype_hex.lower().zfill(2)}"
            hidden = ptype in ['0x83','0x82','0x8e','0xa5']
            partitions.append({
                'idx': str(len(partitions)), 'start': int(start), 'size': 0,
                'type': ptype, 'desc': PARTITION_TYPES.get(ptype, desc.strip()),
                'hidden': hidden, 'line': line.strip()
            })

    if partitions:
        print(f"\n{Fore.CYAN}[PARTITION] {len(partitions)} partisi ditemukan:{Style.RESET_ALL}")
        for p in partitions:
            marker = f" {Fore.RED}← HIDDEN/LINUX (tidak terlihat di Windows)!{Style.RESET_ALL}" if p['hidden'] else ""
            print(f"  [{p['idx']}] Start={p['start']} Size={p['size']} Type={p['type']} ({p['desc']}){marker}")
            add_to_summary("PARTITION", f"[{p['idx']}] {p['desc']} start={p['start']}")

    # ── Scan strings dari setiap partisi (via dd offset)
    print(f"\n{Fore.CYAN}[PARTITION] Scan strings tiap partisi...{Style.RESET_ALL}")

    # Jika tidak ada partisi terparse, scan seluruh image
    scan_targets = partitions if partitions else [{'idx':'0','start':0,'size':0,'desc':'full','hidden':False}]

    for p in scan_targets:
        start_byte = p['start'] * 512  # asumsi sector 512 bytes
        size_byte  = p['size']  * 512 if p['size'] > 0 else 5*1024*1024

        label = f"part{p['idx']}_{p['desc'].replace(' ','_')}"
        print(f"\n{Fore.CYAN}  Scanning {label} (offset={start_byte})...{Style.RESET_ALL}")

        # strings dari offset partisi
        try:
            cmd = f"dd if='{filepath}' bs=512 skip={p['start']} count={min(p['size'],10240) if p['size']>0 else 10240} 2>/dev/null | strings -n 6"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30)
            strings_out = result.stdout
            if strings_out.strip():
                (out_dir / f"{label}_strings.txt").write_text(strings_out[:200000])
                scan_text_for_flags(strings_out, f"PARTITION-{label.upper()}")
                auto_decode_multi(strings_out, f"PARTITION-{label}")
                add_to_summary(f"PARTITION-STRINGS", f"{label}: {len(strings_out.splitlines())} lines")
        except Exception as e:
            print(f"{Fore.YELLOW}    dd/strings gagal: {e}{Style.RESET_ALL}")

        # Coba mount dengan loop device (butuh sudo / root)
        if p['hidden'] or p.get('force_mount'):
            _try_mount_partition(filepath, p, out_dir)

    new_flags = list(found_flags_set)[found_before:]
    log_tool("partition-scan", "✅ Found" if new_flags else "⬜ Analyzed",
             ", ".join(new_flags) if new_flags else f"{len(partitions)} partisi ditemukan")
    print(f"{Fore.GREEN}[PARTITION] Selesai. Output: {out_dir.name}{Style.RESET_ALL}")


def _try_mount_partition(filepath, partition, out_dir):
    """Coba mount partisi tersembunyi dan baca isinya"""
    start = partition['start']
    mount_point = out_dir / f"mount_part{partition['idx']}"
    mount_point.mkdir(exist_ok=True)

    offset = start * 512
    print(f"{Fore.CYAN}  [MOUNT] Mencoba mount partisi {partition['idx']} (offset={offset})...{Style.RESET_ALL}")

    # Coba mount dengan sudo
    try:
        r = subprocess.run(
            f"sudo mount -o loop,offset={offset},ro '{filepath}' '{mount_point}' 2>&1",
            shell=True, capture_output=True, text=True, timeout=15)

        if r.returncode == 0:
            print(f"{Fore.GREEN}  [MOUNT] Berhasil! Scanning isi partisi...{Style.RESET_ALL}")
            # Scan semua file di mount point
            for f in mount_point.rglob("*"):
                if f.is_file():
                    print(f"    📄 {f.relative_to(mount_point)}")
                    try:
                        txt = f.read_text(errors='ignore')
                        scan_text_for_flags(txt, f"MOUNT-PART{partition['idx']}")
                        collect_base64_from_text(txt)
                    except:
                        sr = subprocess.getoutput(f"strings '{f}'")
                        scan_text_for_flags(sr, f"MOUNT-PART{partition['idx']}-STRINGS")

            # Umount
            subprocess.run(f"sudo umount '{mount_point}' 2>/dev/null", shell=True, timeout=10)
            add_to_summary("MOUNT-SUCCESS", f"Partisi {partition['idx']} berhasil di-mount")
        else:
            print(f"{Fore.YELLOW}  [MOUNT] Gagal (butuh sudo/root atau tipe tidak dikenal): {r.stdout[:100]}{Style.RESET_ALL}")
            # Fallback: coba baca raw dengan file types
            _carve_partition_raw(filepath, partition, out_dir)
    except Exception as e:
        print(f"{Fore.YELLOW}  [MOUNT] Exception: {e}{Style.RESET_ALL}")
        _carve_partition_raw(filepath, partition, out_dir)


def _carve_partition_raw(filepath, partition, out_dir):
    """Fallback: carve raw bytes dari partisi dan scan"""
    start = partition['start']
    size  = min(partition['size'], 20480) if partition['size'] > 0 else 10240
    try:
        carve_file = out_dir / f"part{partition['idx']}_raw.bin"
        cmd = f"dd if='{filepath}' of='{carve_file}' bs=512 skip={start} count={size} 2>/dev/null"
        subprocess.run(cmd, shell=True, timeout=20)
        if carve_file.exists() and carve_file.stat().st_size > 0:
            sr = subprocess.getoutput(f"strings -n 6 '{carve_file}'")
            scan_text_for_flags(sr, f"CARVE-PART{partition['idx']}")
            auto_decode_multi(sr, f"CARVE-PART{partition['idx']}")
            add_to_summary("CARVE-PARTITION", f"Part{partition['idx']}: {carve_file.name}")
    except Exception as e:
        print(f"{Fore.YELLOW}  [CARVE] Gagal: {e}{Style.RESET_ALL}")


# ── DISK: NTFS DELETED FILE RECOVERY ─────────

def analyze_ntfs_deleted(filepath):
    """
    Recovery file yang dihapus dari NTFS menggunakan Sleuth Kit (fls/icat)
    atau fallback strings scan + file carving
    """
    print(f"{Fore.GREEN}[NTFS-RECOVER] Analisis NTFS deleted files...{Style.RESET_ALL}")
    log_tool("ntfs-recover", "running")
    found_before = len(found_flags_set)
    out_dir = filepath.parent / f"{filepath.stem}_ntfs_recovery"
    out_dir.mkdir(exist_ok=True)

    # ── Cek apakah ini NTFS
    file_type = subprocess.getoutput(f"file -b '{filepath}'").lower()
    is_ntfs = "ntfs" in file_type or "oem-id" in file_type

    if is_ntfs:
        print(f"{Fore.CYAN}[NTFS-RECOVER] NTFS volume terdeteksi{Style.RESET_ALL}")
    else:
        print(f"{Fore.YELLOW}[NTFS-RECOVER] Bukan NTFS, tetap mencoba recovery...{Style.RESET_ALL}")

    # ── Metode 1: fls (Sleuth Kit) — list deleted files
    fls_out = subprocess.getoutput(f"fls -r -d '{filepath}' 2>&1")
    if fls_out.strip() and "command not found" not in fls_out and "not found" not in fls_out:
        print(f"\n{Fore.CYAN}[NTFS-RECOVER] fls — File yang dihapus:{Style.RESET_ALL}")
        print(fls_out[:3000])
        (out_dir / "deleted_files_fls.txt").write_text(fls_out)
        scan_text_for_flags(fls_out, "FLS-DELETED")

        # Ekstrak inode numbers dari deleted files
        inode_pat = re.compile(r'\*\s+(\d+-\d+|\d+):?\s+(.+)')
        deleted_inodes = []
        for line in fls_out.splitlines():
            m = inode_pat.match(line)
            if m:
                inode, name = m.groups()
                deleted_inodes.append((inode.split('-')[0], name.strip()))

        print(f"{Fore.CYAN}[NTFS-RECOVER] {len(deleted_inodes)} file terhapus ditemukan{Style.RESET_ALL}")

        # Dump setiap file dengan icat
        for inode, name in deleted_inodes[:20]:
            try:
                safe_name = re.sub(r'[^\w.]', '_', name)[:50]
                out_file = out_dir / f"recovered_{inode}_{safe_name}"
                r = subprocess.run(
                    f"icat '{filepath}' {inode} > '{out_file}' 2>/dev/null",
                    shell=True, timeout=15)
                if out_file.exists() and out_file.stat().st_size > 0:
                    print(f"  ✅ Recovered: {name} ({out_file.stat().st_size} bytes)")
                    try:
                        txt = out_file.read_text(errors='ignore')
                        scan_text_for_flags(txt, f"ICAT-{name}")
                        auto_decode_multi(txt, f"ICAT-RECOVERED")
                        collect_base64_from_text(txt)
                    except:
                        sr = subprocess.getoutput(f"strings '{out_file}'")
                        scan_text_for_flags(sr, f"ICAT-STRINGS")
                    add_to_summary("NTFS-RECOVERED", f"Recovered: {name}")
            except Exception as e:
                print(f"{Fore.YELLOW}  icat {inode} gagal: {e}{Style.RESET_ALL}")
    else:
        print(f"{Fore.YELLOW}[NTFS-RECOVER] fls tidak tersedia, fallback ke strings+carving{Style.RESET_ALL}")

    # ── Metode 2: Strings scan full image (selalu jalan)
    print(f"\n{Fore.CYAN}[NTFS-RECOVER] Full strings scan...{Style.RESET_ALL}")
    try:
        cmd = f"strings -n 8 '{filepath}' | head -50000"
        str_out = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=60).stdout
        (out_dir / "full_strings.txt").write_text(str_out[:500000])
        scan_text_for_flags(str_out, "NTFS-STRINGS")
        auto_decode_multi(str_out, "NTFS-STRINGS")
        collect_base64_from_text(str_out)
    except Exception as e:
        print(f"{Fore.YELLOW}[NTFS-RECOVER] Strings scan gagal: {e}{Style.RESET_ALL}")

    # ── Metode 3: File carving dengan foremost/scalpel
    if AVAILABLE_TOOLS.get('foremost'):
        print(f"\n{Fore.CYAN}[NTFS-RECOVER] File carving dengan foremost...{Style.RESET_ALL}")
        carve_dir = out_dir / "carved"
        try:
            subprocess.run(
                ["foremost", "-i", str(filepath), "-o", str(carve_dir), "-t", "all"],
                capture_output=True, timeout=60)
            if carve_dir.exists():
                carved = list(carve_dir.rglob("*"))
                carved_files = [f for f in carved if f.is_file()]
                print(f"  {len(carved_files)} file di-carve")
                for f in carved_files[:20]:
                    try:
                        txt = f.read_text(errors='ignore')
                        scan_text_for_flags(txt, "CARVED-FILE")
                    except:
                        sr = subprocess.getoutput(f"strings '{f}'")
                        scan_text_for_flags(sr, "CARVED-STRINGS")
                if carved_files:
                    add_to_summary("NTFS-CARVED", f"{len(carved_files)} files carved")
        except Exception as e:
            print(f"{Fore.YELLOW}  Foremost gagal: {e}{Style.RESET_ALL}")

    # ── Scan signature file umum di raw bytes
    print(f"\n{Fore.CYAN}[NTFS-RECOVER] Signature scan (file headers)...{Style.RESET_ALL}")
    try:
        scan_size = min(50 * 1024 * 1024, filepath.stat().st_size)
        raw = filepath.read_bytes()[:scan_size]
        sigs = {
            "ZIP":  b"PK\x03\x04",
            "PNG":  b"\x89PNG",
            "JPEG": b"\xff\xd8\xff",
            "PDF":  b"%PDF",
            "ELF":  b"\x7fELF",
            "TXT":  None,  # skip
        }
        for fmt, sig in sigs.items():
            if sig is None: continue
            offset = 0
            count = 0
            while True:
                idx = raw.find(sig, offset)
                if idx == -1 or count >= 5: break
                count += 1
                print(f"  {fmt} @ offset 0x{idx:x}")
                add_to_summary("NTFS-SIG", f"{fmt} at 0x{idx:x}")
                # Extract & scan chunk
                chunk = raw[idx:idx+min(10240, len(raw)-idx)]
                try:
                    txt = chunk.decode('utf-8', errors='ignore')
                    scan_text_for_flags(txt, f"SIG-{fmt}")
                except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
                offset = idx + 1
    except Exception as e:
        print(f"{Fore.YELLOW}[NTFS-RECOVER] Signature scan gagal: {e}{Style.RESET_ALL}")

    new_flags = list(found_flags_set)[found_before:]
    log_tool("ntfs-recover", "✅ Found" if new_flags else "⬜ Scanned",
             ", ".join(new_flags) if new_flags else f"output: {out_dir.name}")
    add_to_summary("NTFS-DONE", f"Output: '{out_dir.name}'")
    print(f"{Fore.GREEN}[NTFS-RECOVER] Selesai. Output: {out_dir.name}{Style.RESET_ALL}")


# ── PCAP: SEGMENTED PAYLOAD ANALYSIS (Ph4nt0m-style) ─────────────

def analyze_pcap_segmented_payload(filepath):
    """
    Solver untuk soal seperti Ph4nt0m 1ntrud3r picoCTF:
    Base64 tersebar di beberapa TCP packet → decode per-packet → reassemble → flag.

    Teknik: tshark -T fields -e tcp.payload per frame → hex → bytes → decode
    """
    if not AVAILABLE_TOOLS.get('tshark'):
        log_tool("pcap-segment", "⏭ Skipped", "tshark tidak tersedia")
        return

    print(f"\n{Fore.GREEN}[PCAP-SEGMENT] Analisis payload per-packet (segmented B64 mode)...{Style.RESET_ALL}")
    log_tool("pcap-segment", "running")
    found_before = len(found_flags_set)

    out_dir = filepath.parent / f"{filepath.stem}_pcap_segments"
    out_dir.mkdir(exist_ok=True)

    # ── STEP 1: Extract payload hex per frame
    print(f"{Fore.CYAN}[PCAP-SEGMENT] Mengekstrak payload per frame...{Style.RESET_ALL}")
    try:
        result = subprocess.run(
            ["tshark", "-r", str(filepath), "-T", "fields",
             "-e", "frame.number", "-e", "tcp.payload",
             "-e", "udp.payload", "-q"],
            capture_output=True, text=True, timeout=120
        )
        raw_output = result.stdout
    except Exception as e:
        print(f"{Fore.RED}[PCAP-SEGMENT] tshark gagal: {e}{Style.RESET_ALL}")
        log_tool("pcap-segment", "❌ Error", str(e))
        return

    # Parse: frame_num → hex_payload
    frame_payloads = {}
    for line in raw_output.splitlines():
        parts = line.strip().split('\t')
        if len(parts) >= 2:
            frame_num = parts[0].strip()
            hex_payload = parts[1].strip() if len(parts) > 1 and parts[1].strip() else (parts[2].strip() if len(parts) > 2 else '')
            if hex_payload and frame_num.isdigit():
                frame_payloads[int(frame_num)] = hex_payload

    print(f"{Fore.CYAN}[PCAP-SEGMENT] {len(frame_payloads)} frame dengan payload ditemukan{Style.RESET_ALL}")

    if not frame_payloads:
        print(f"{Fore.YELLOW}[PCAP-SEGMENT] Tidak ada TCP/UDP payload. Skip.{Style.RESET_ALL}")
        log_tool("pcap-segment", "⬜ Nothing", "tidak ada payload")
        return

    # ── STEP 2: Decode payload per frame
    decoded_per_frame = {}  # frame_num → list of decoded strings
    summary_rows = []

    for frame_num in sorted(frame_payloads.keys()):
        hex_data = frame_payloads[frame_num].replace(':', '')

        try:
            raw_bytes = bytes.fromhex(hex_data)
        except:
            continue

        # Coba decode sebagai ASCII dulu
        ascii_text = raw_bytes.decode('ascii', errors='ignore').strip()

        row = {
            'frame': frame_num,
            'hex': hex_data[:40],
            'ascii': ascii_text[:60],
            'decoded': []
        }

        # Coba berbagai encoding pada ascii_text
        candidates = _try_all_encodings_on_payload(ascii_text, raw_bytes)

        if candidates:
            decoded_per_frame[frame_num] = candidates
            row['decoded'] = candidates

            for dec in candidates:
                scan_text_for_flags(dec, f"PCAP-FRAME-{frame_num}")
                collect_base64_from_text(dec)

        summary_rows.append(row)

    # ── STEP 3: Tampilkan tabel per-frame
    print(f"\n{Fore.CYAN}[PCAP-SEGMENT] Tabel decode per frame:{Style.RESET_ALL}")
    print(f"{'Frame':<8} {'ASCII (raw)':<30} {'Decoded':<40}")
    print(f"{'─'*8} {'─'*30} {'─'*40}")

    for row in summary_rows:
        decoded_str = ' | '.join(row['decoded'])[:38] if row['decoded'] else '-'
        ascii_disp = row['ascii'][:28] if row['ascii'] else '-'
        flag_marker = f" {Fore.GREEN}<-- FLAG?{Style.RESET_ALL}" if any(
            re.search(pat, d, re.IGNORECASE)
            for d in row['decoded']
            for pat in COMMON_FLAG_PATTERNS
        ) else ""
        print(f"  {row['frame']:<6} {ascii_disp:<30} {decoded_str}{flag_marker}")

    # ── STEP 4: Reassemble — gabungkan semua decoded secara berurutan
    print(f"\n{Fore.CYAN}[PCAP-SEGMENT] Mencoba reassemble flag dari semua frame...{Style.RESET_ALL}")

    # Method A: gabungkan decoded strings berurutan
    all_decoded_ordered = []
    for frame_num in sorted(decoded_per_frame.keys()):
        all_decoded_ordered.extend(decoded_per_frame[frame_num])

    for sep in ['', ' ', '\n']:
        combined = sep.join(all_decoded_ordered)
        scan_text_for_flags(combined, "PCAP-REASSEMBLED")
        collect_base64_from_text(combined)

    # Method B: gabungkan ASCII raw berurutan, lalu decode sekali
    all_ascii = ''.join(
        row['ascii'] for row in summary_rows if row['ascii']
    )
    _try_all_encodings_on_payload(all_ascii, b'')
    scan_text_for_flags(all_ascii, "PCAP-ASCII-ALL")

    # Method C: ekstrak hanya karakter Base64-valid dari semua payload, gabungkan
    b64_chars_all = re.sub(r'[^A-Za-z0-9+/=]', '', all_ascii)
    if len(b64_chars_all) >= 8:
        print(f"{Fore.CYAN}[PCAP-SEGMENT] Combined B64 chars: {b64_chars_all[:80]}...{Style.RESET_ALL}")
        decoded_combined = decode_base64(b64_chars_all)
        if decoded_combined:
            print(f"{Fore.GREEN}[PCAP-SEGMENT] Combined decode: {decoded_combined[:100]}{Style.RESET_ALL}")
            scan_text_for_flags(decoded_combined, "PCAP-B64-COMBINED")

        # Coba juga tiap chunk 4 karakter (kelipatan base64)
        _try_chunked_b64(b64_chars_all, out_dir)

    # ── STEP 5: Smart flag assembler — coba partial flag detection
    print(f"\n{Fore.CYAN}[PCAP-SEGMENT] Smart flag assembler...{Style.RESET_ALL}")
    _smart_flag_assembler(decoded_per_frame, out_dir)

    # ── STEP 6: Generate equivalent tshark one-liner (untuk referensi user)
    oneliner = (
        f"tshark -r '{filepath.name}' -T fields -e tcp.payload -q 2>/dev/null "
        f"| xxd -r -p 2>/dev/null | base64 -d 2>/dev/null"
    )
    oneliner2 = (
        f"tshark -r '{filepath.name}' -Y 'tcp.payload' -T fields -e tcp.payload "
        f"| tr -d '\\n' | xxd -r -p | base64 -d"
    )
    print(f"\n{Fore.CYAN}[PCAP-SEGMENT] tshark one-liner equivalents:{Style.RESET_ALL}")
    print(f"  {oneliner}")
    print(f"  {oneliner2}")

    # Simpan summary
    summary_lines = [
        f"PCAP Segment Analysis: {filepath.name}",
        f"Total frames with payload: {len(frame_payloads)}",
        f"Frames with decoded content: {len(decoded_per_frame)}",
        "",
        "Per-frame breakdown:",
    ]
    for row in summary_rows:
        summary_lines.append(
            f"  Frame {row['frame']}: ascii={row['ascii'][:40]} | decoded={row['decoded']}"
        )
    summary_lines.extend([
        "",
        "Reassembled (all decoded joined):",
        ' '.join(all_decoded_ordered),
        "",
        "tshark one-liner:",
        oneliner,
    ])
    (out_dir / "pcap_segments_decoded.txt").write_text('\n'.join(summary_lines))

    new_flags = list(found_flags_set)[found_before:]
    log_tool("pcap-segment", "✅ Found" if new_flags else "⬜ Analyzed",
             ", ".join(new_flags) if new_flags else f"{len(frame_payloads)} frames analyzed")
    print(f"{Fore.GREEN}[PCAP-SEGMENT] Selesai. Output: {out_dir.name}{Style.RESET_ALL}")


def _try_all_encodings_on_payload(text, raw_bytes):
    """
    Coba semua encoding pada satu payload string/bytes.
    Return list of successfully decoded strings.
    """
    results = []

    if not text and not raw_bytes:
        return results

    # Base64 decode (paling umum di soal ini)
    clean_b64 = re.sub(r'[^A-Za-z0-9+/=]', '', text)
    if len(clean_b64) >= 4:
        # Coba dengan berbagai padding
        for pad in range(4):
            try:
                import base64 as _b64
                padded = clean_b64 + '=' * pad
                decoded = _b64.b64decode(padded).decode('utf-8', errors='ignore').strip()
                if decoded and any(c.isprintable() for c in decoded) and len(decoded) >= 2:
                    if decoded not in results:
                        results.append(decoded)
                    break
            except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))

    # Base32 decode
    b32_result = decode_base32(text)
    if b32_result and b32_result not in results:
        results.append(b32_result)

    # Hex decode (jika text adalah pure hex)
    hex_result = decode_hex_string(text)
    if hex_result and hex_result not in results:
        results.append(hex_result)

    # URL decode
    url_result = decode_url_encoding(text)
    if url_result and url_result != text and url_result not in results:
        results.append(url_result)

    # ROT13
    if text:
        rot = text.translate(str.maketrans(
            'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz',
            'NOPQRSTUVWXYZABCDEFGHIJKLMnopqrstuvwxyzabcdefghijklm'))
        for pat in COMMON_FLAG_PATTERNS:
            if re.search(pat, rot, re.IGNORECASE):
                if rot not in results:
                    results.append(rot)
                break

    # Iterative B64: b64(b64(x)) → decode 2x
    for prev in list(results):
        clean = re.sub(r'[^A-Za-z0-9+/=]', '', prev)
        if len(clean) >= 4:
            try:
                import base64 as _b64
                second = _b64.b64decode(clean + '==').decode('utf-8', errors='ignore').strip()
                if second and len(second) >= 2 and second not in results:
                    results.append(second)
            except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))

    return results


def _try_chunked_b64(b64_string, out_dir):
    """
    Coba decode setiap chunk 4-8 karakter dari string Base64 besar.
    Berguna ketika flag tersebar di banyak packet kecil.
    """
    print(f"{Fore.CYAN}[PCAP-SEGMENT] Chunked B64 decode ({len(b64_string)} chars)...{Style.RESET_ALL}")

    import base64 as _b64

    # Coba chunk 4, 8, 12, 16, 24 karakter
    chunk_results = {}
    for chunk_size in [4, 8, 12, 16, 24]:
        decoded_chunks = []
        for i in range(0, len(b64_string), chunk_size):
            chunk = b64_string[i:i+chunk_size]
            if len(chunk) < 2:
                continue
            # Pad ke kelipatan 4
            padded = chunk + '=' * ((4 - len(chunk) % 4) % 4)
            try:
                dec = _b64.b64decode(padded).decode('utf-8', errors='ignore').strip('\x00')
                if dec and any(c.isprintable() for c in dec):
                    decoded_chunks.append(dec)
            except:
                decoded_chunks.append(chunk)  # keep raw jika gagal

        if decoded_chunks:
            assembled = ''.join(decoded_chunks)
            chunk_results[chunk_size] = assembled
            scan_text_for_flags(assembled, f"PCAP-CHUNK-{chunk_size}")

            # Scan juga tiap chunk individual untuk partial flag
            for dc in decoded_chunks:
                scan_text_for_flags(dc, f"PCAP-CHUNK-{chunk_size}-INDIVIDUAL")

    # Simpan semua hasil chunk ke file
    if chunk_results:
        chunk_file = out_dir / "chunked_b64_results.txt"
        with open(chunk_file, 'w') as f:
            for size, result in chunk_results.items():
                f.write(f"\nChunk size {size}:\n{result}\n")
        print(f"{Fore.CYAN}[PCAP-SEGMENT] Chunk results → {chunk_file.name}{Style.RESET_ALL}")


def _smart_flag_assembler(decoded_per_frame, out_dir):
    """
    Cerdas: cari partial flag di tiap frame, lalu susun ulang berdasarkan CONTENT, bukan frame number.
    
    Contoh: Frame 15=picoCTF, Frame 5={1t_w4s, Frame 2=nt_th4t
    → Urutkan: picoCTF → {1t_w4s → nt_th4t → ... → }
    """
    # ── STEP 1: Extract semua decoded content, filter noise
    all_decoded = []
    for frame_num in sorted(decoded_per_frame.keys()):
        for decoded in decoded_per_frame[frame_num]:
            # Ekstrak hanya flag-valid chars: alphanumeric, underscore, curly braces, dash
            clean = re.sub(r'[^a-zA-Z0-9_{}\-]', '', decoded)
            if clean:
                all_decoded.append(clean)
    
    if not all_decoded:
        return
    
    # ── STEP 2: Gabungkan semua content
    combined = ''.join(all_decoded)
    print(f"{Fore.CYAN}[SMART-ASSEMBLER] Combined content: {combined[:150]}{Style.RESET_ALL}")
    scan_text_for_flags(combined, "SMART-COMBINED")
    
    # ── STEP 3: Try direct regex match first
    flag_regex = r'(picoCTF|CTF|flag|FLAG)\{[a-zA-Z0-9_\-]+\}'
    for m in re.finditer(flag_regex, combined, re.IGNORECASE):
        flag = m.group(0)
        print(f"{Fore.GREEN}[SMART-ASSEMBLER] ✅ FLAG FOUND: {flag}{Style.RESET_ALL}")
        add_to_summary("SMART-FLAG", flag)
        signal_flag_found()
        return
    
    # ── STEP 4: Smart reordering — find flag start, collect until end
    FLAG_PREFIXES = ['picoCTF', 'CTF', 'flag', 'FLAG']
    
    for prefix in FLAG_PREFIXES:
        if FLAG_FOUND:
            break
        if prefix not in combined:
            continue
        
        print(f"{Fore.CYAN}[SMART-ASSEMBLER] Found '{prefix}', reconstructing flag...{Style.RESET_ALL}")
        
        # Find where prefix starts
        prefix_idx = combined.index(prefix)
        after_prefix = combined[prefix_idx:]
        
        # Try to find closing brace
        if '}' in after_prefix:
            close_idx = after_prefix.index('}') + 1
            candidate = after_prefix[:close_idx]
            
            # Validate
            if re.match(r'(?:picoCTF|CTF|flag|FLAG)\{[a-zA-Z0-9_\-]{3,}\}', candidate, re.IGNORECASE):
                print(f"{Fore.GREEN}[SMART-ASSEMBLER] ✅ FLAG RECONSTRUCTED: {candidate}{Style.RESET_ALL}")
                add_to_summary("SMART-FLAG", candidate)
                signal_flag_found()
                return
        
        # ── STEP 5: If direct extraction fails, try to reorder segments
        print(f"{Fore.CYAN}[SMART-ASSEMBLER] Reordering segments by flag structure...{Style.RESET_ALL}")
        
        # Find all flag-like segments
        flag_chars_pattern = re.compile(r'[a-zA-Z0-9_{}\-]+')
        segments = []
        
        for frame_num in sorted(decoded_per_frame.keys()):
            for decoded in decoded_per_frame[frame_num]:
                matches = flag_chars_pattern.findall(decoded)
                for match in matches:
                    if len(match) >= 2 or any(c in match for c in ['{', '}']):
                        segments.append(match)
        
        print(f"{Fore.CYAN}[SMART-ASSEMBLER] Extracted {len(segments)} segments{Style.RESET_ALL}")
        for i, seg in enumerate(segments[:15]):
            print(f"  [{i:2d}] {seg}")
        
        # Find prefix segment index
        prefix_seg_idx = -1
        for i, seg in enumerate(segments):
            if seg.startswith(prefix) or prefix in seg:
                prefix_seg_idx = i
                print(f"{Fore.GREEN}[SMART-ASSEMBLER] Found prefix '{prefix}' at segment [{i}]: {seg}{Style.RESET_ALL}")
                break
        
        if prefix_seg_idx >= 0:
            # Collect segments from prefix onwards, stopping at }
            flag_parts = []
            found_open_brace = '{' in segments[prefix_seg_idx]
            
            for i in range(prefix_seg_idx, len(segments)):
                seg = segments[i]
                flag_parts.append(seg)
                
                if '}' in seg:
                    break
            
            # Join and extract flag
            assembled = ''.join(flag_parts)
            print(f"{Fore.CYAN}[SMART-ASSEMBLER] Assembled: {assembled[:120]}{Style.RESET_ALL}")
            
            # Try regex match on assembled
            for m in re.finditer(flag_regex, assembled, re.IGNORECASE):
                flag = m.group(0)
                print(f"{Fore.GREEN}[SMART-ASSEMBLER] ✅ FLAG FOUND: {flag}{Style.RESET_ALL}")
                add_to_summary("SMART-FLAG", flag)
                signal_flag_found()
                return
            
            # Try to extract flag with permissive regex
            permissive = r'(picoCTF|CTF|flag|FLAG)\{[a-zA-Z0-9_\-]+'
            match = re.search(permissive, assembled, re.IGNORECASE)
            if match:
                partial = match.group(0)
                if '}' in assembled[match.end():]:
                    close_idx = assembled[match.end():].index('}') + 1
                    full_flag = partial + assembled[match.end():match.end()+close_idx]
                    
                    if re.match(r'(?:picoCTF|CTF|flag|FLAG)\{[a-zA-Z0-9_\-]{3,}\}', full_flag, re.IGNORECASE):
                        print(f"{Fore.GREEN}[SMART-ASSEMBLER] ✅ FLAG RECONSTRUCTED: {full_flag}{Style.RESET_ALL}")
                        add_to_summary("SMART-FLAG", full_flag)
                        signal_flag_found()
                        return
    
    # Save for debugging
    (out_dir / "assembled_content.txt").write_text(f"Combined:\n{combined}\n")


# ── PCAP: DNS TUNNELING DETECTOR ─────────────

def analyze_dns_tunneling(filepath):
    """
    Deteksi DNS tunneling:
    - Extract semua DNS queries
    - Deteksi subdomain dengan entropy tinggi
    - Grup berdasarkan domain, urutkan chunk berdasarkan sequence number
    - Decode Base32/Base64/hex dari subdomain terurut → flag
    """
    if not AVAILABLE_TOOLS.get('tshark'):
        log_tool("dns-tunnel", "⏭ Skipped", "tshark tidak tersedia")
        return

    print(f"{Fore.GREEN}[DNS-TUNNEL] Analisis DNS tunneling...{Style.RESET_ALL}")
    log_tool("dns-tunnel", "running")
    found_before = len(found_flags_set)
    out_dir = filepath.parent / f"{filepath.stem}_dns_tunnel"
    out_dir.mkdir(exist_ok=True)

    # ── Extract semua DNS queries
    dns_out = _tshark(filepath, "-T", "fields", "-e", "dns.qry.name",
                      "-Y", "dns.flags.response == 0", "-q")
    queries = [q.strip() for q in dns_out.splitlines() if q.strip()]

    if not queries:
        print(f"{Fore.YELLOW}[DNS-TUNNEL] Tidak ada DNS query ditemukan{Style.RESET_ALL}")
        log_tool("dns-tunnel", "⬜ Nothing", "tidak ada DNS query")
        return

    print(f"{Fore.CYAN}[DNS-TUNNEL] {len(queries)} DNS queries ditemukan{Style.RESET_ALL}")
    (out_dir / "all_dns_queries.txt").write_text('\n'.join(queries))

    # ── Scan langsung untuk flag di queries
    scan_text_for_flags('\n'.join(queries), "DNS-QUERY")

    # ── Hitung entropy setiap subdomain untuk deteksi tunneling
    def subdomain_entropy(domain):
        parts = domain.split('.')
        if not parts: return 0
        sub = parts[0]  # subdomain terluar
        if len(sub) < 4: return 0
        return calculate_entropy(sub.encode())

    # ── Grup domain berdasarkan parent domain (level -2, -1)
    domain_groups = {}
    for q in queries:
        parts = q.split('.')
        if len(parts) >= 3:
            parent = '.'.join(parts[-2:])  # misal: evilcorp.net
            sub    = '.'.join(parts[:-2])  # misal: 00-inkem63e
            domain_groups.setdefault(parent, []).append((q, sub))

    suspicious_domains = []
    for parent, entries in domain_groups.items():
        if len(entries) < 2: continue
        avg_entropy = sum(subdomain_entropy(q) for q, _ in entries) / len(entries)
        if avg_entropy > 3.5 or len(entries) >= 4:
            suspicious_domains.append((parent, entries, avg_entropy))
            print(f"\n{Fore.RED}[DNS-TUNNEL] Suspicious domain: {parent}")
            print(f"  {len(entries)} queries, avg entropy={avg_entropy:.2f} ← DNS TUNNELING!{Style.RESET_ALL}")
            add_to_summary("DNS-TUNNEL-DOMAIN", f"{parent} ({len(entries)} queries, entropy={avg_entropy:.2f})")

    if not suspicious_domains:
        # Cek juga domain yang muncul >= 4 kali
        from collections import Counter
        parent_counts = Counter('.'.join(q.split('.')[-2:]) for q in queries)
        for parent, count in parent_counts.most_common(5):
            if count >= 4 and parent not in ['google.com','microsoft.com','apple.com',
                                              'cloudflare.com','amazon.com','googleapis.com']:
                entries = [(q, '.'.join(q.split('.')[:-2])) for q in queries
                           if q.endswith(parent)]
                suspicious_domains.append((parent, entries, 0))
                print(f"{Fore.YELLOW}[DNS-TUNNEL] Possible tunnel: {parent} ({count}x){Style.RESET_ALL}")

    # ── Untuk setiap domain mencurigakan, rekonstruksi payload
    for parent, entries, _ in suspicious_domains:
        print(f"\n{Fore.CYAN}[DNS-TUNNEL] Rekonstruksi payload dari {parent}...{Style.RESET_ALL}")

        # Sort berdasarkan sequence number di awal subdomain
        chunked = []
        for q, sub in entries:
            first_label = sub.split('.')[0] if sub else sub
            # Format 1 (dari writeup): "00-inkem63e" → seq=0, data="inkem63e"
            m1 = re.match(r'^(\d+)[-_](.+)$', first_label)
            # Format 2: "data_00" atau "chunk00"
            m2 = re.match(r'^(.+?)[-_]?(\d+)$', first_label)
            if m1:
                seq  = int(m1.group(1))
                data = m1.group(2)
                chunked.append((seq, data, sub))
            elif m2:
                data = m2.group(1)
                seq  = int(m2.group(2))
                chunked.append((seq, data, sub))
            else:
                # Tidak ada nomor urut — append saja, sort by order of appearance
                chunked.append((len(chunked), first_label, sub))

        chunked.sort(key=lambda x: x[0])
        print(f"  Chunks terurut:")
        for seq, data, orig in chunked:
            print(f"    [{seq:02d}] {data:20s}  ← {orig}")

        # Gabungkan semua chunks
        combined = ''.join(data for _, data, _ in chunked)
        print(f"\n{Fore.CYAN}  Combined: {combined}{Style.RESET_ALL}")
        (out_dir / f"{parent.replace('.','_')}_combined.txt").write_text(combined)

        # Scan langsung
        scan_text_for_flags(combined, f"DNS-TUNNEL-{parent}")

        # Coba semua encoding
        print(f"{Fore.CYAN}  Mencoba decode...{Style.RESET_ALL}")
        decoders = [
            ("Base32",  decode_base32),
            ("Base64",  decode_base64),
            ("Hex",     decode_hex_string),
            ("Base58",  decode_base58),
            ("URL",     decode_url_encoding),
        ]
        for enc_name, decoder in decoders:
            result = decoder(combined)
            if result:
                print(f"  {Fore.GREEN}{enc_name}: {result}{Style.RESET_ALL}")
                scan_text_for_flags(result, f"DNS-{enc_name.upper()}")
                add_to_summary(f"DNS-DECODED-{enc_name.upper()}", result[:100])
                # Coba juga uppercase/lowercase variant
                result_u = decoder(combined.upper())
                result_l = decoder(combined.lower())
                for r in [result_u, result_l]:
                    if r and r != result:
                        scan_text_for_flags(r, f"DNS-{enc_name.upper()}-VARIANT")

        # Coba juga setiap subdomain individual
        print(f"{Fore.CYAN}  Scan subdomain individual...{Style.RESET_ALL}")
        for seq, data, orig in chunked:
            for enc_name, decoder in decoders:
                result = decoder(data)
                if result and len(result.strip()) > 3:
                    scan_text_for_flags(result, f"DNS-CHUNK-{enc_name}")

    # ── Scan ICMP/UDP payload juga (tools lain untuk DNS over non-53)
    icmp_out = _tshark(filepath, "-T", "fields", "-e", "data.data", "-Y", "icmp", "-q")
    if icmp_out.strip():
        scan_text_for_flags(icmp_out, "ICMP-PAYLOAD")
        auto_decode_multi(icmp_out, "ICMP")

    new_flags = list(found_flags_set)[found_before:]
    log_tool("dns-tunnel", "✅ Found" if new_flags else "⬜ Analyzed",
             ", ".join(new_flags) if new_flags else f"{len(queries)} queries, {len(suspicious_domains)} suspicious domains")
    print(f"{Fore.GREEN}[DNS-TUNNEL] Selesai. Output: {out_dir.name}{Style.RESET_ALL}")


# ── VOLATILITY ENHANCED ──────────────────────

def analyze_memory_advanced(filepath, vol_cmd=None):
    """
    Advanced memory forensics:
    - Cari proses anomali (nama mencurigakan, parent tidak wajar)
    - windows.malfind (process injection detector)
    - Dump memori proses mencurigakan
    - Scan injected regions untuk flag
    """
    print(f"{Fore.GREEN}[MEMORY-ADV] Analisis lanjutan memory dump...{Style.RESET_ALL}")
    log_tool("memory-advanced", "running")
    found_before = len(found_flags_set)
    out_dir = filepath.parent / f"{filepath.stem}_memory_advanced"
    out_dir.mkdir(exist_ok=True)

    # Cari vol command
    if not vol_cmd:
        for candidate in ['vol', 'volatility3', 'volatility', 'vol.py']:
            check = subprocess.run(f"which {candidate.split()[0]}",
                                   shell=True, capture_output=True)
            if check.returncode == 0:
                vol_cmd = candidate
                break
        for path in ['/usr/local/bin/vol', '/usr/bin/vol', '/opt/volatility3/vol.py']:
            if Path(path).exists():
                vol_cmd = f"python3 {path}" if path.endswith('.py') else path
                break

    def run_vol_adv(plugin, extra="", label=None, timeout=180):
        label = label or plugin.replace('.', '_')
        cmd = f"{vol_cmd} -f '{filepath}' {plugin} {extra}"
        try:
            r = subprocess.run(cmd, shell=True, capture_output=True,
                               text=True, timeout=timeout)
            out = r.stdout + r.stderr
            if out.strip():
                (out_dir / f"{label}.txt").write_text(out)
                scan_text_for_flags(out, f"VOL-{label.upper()}")
                auto_decode_multi(out, f"VOL-{label}")
                return out
        except subprocess.TimeoutExpired:
            print(f"{Fore.RED}[MEMORY-ADV] Timeout: {plugin}{Style.RESET_ALL}")
        except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
        return ""

    if not vol_cmd:
        print(f"{Fore.YELLOW}[MEMORY-ADV] Volatility tidak ditemukan, fallback ke strings+raw scan{Style.RESET_ALL}")
        _memory_fallback_scan(filepath, out_dir)
        new_flags = list(found_flags_set)[found_before:]
        log_tool("memory-advanced", "⬜ Fallback",
                 ", ".join(new_flags) if new_flags else "strings scan saja")
        return

    # ── 1. Deteksi proses anomali
    print(f"\n{Fore.CYAN}[MEMORY-ADV] Deteksi proses anomali...{Style.RESET_ALL}")
    pslist_out = run_vol_adv("windows.pslist", label="pslist_adv")

    SUSPICIOUS_NAMES = [
        'systemupdate','updater','svchost32','lsass32','winlogon32',
        'explorer32','chrome32','notepad32','cmd32','powershell32',
        'wscript32','cscript32','regsvr32x','rundll32x','mshta',
        'wmic','certutil','msiexec','regasm','regsvcs',
    ]
    LEGIT_PARENTS = {
        'svchost.exe':   ['services.exe','wininit.exe'],
        'lsass.exe':     ['wininit.exe'],
        'explorer.exe':  ['userinit.exe','winlogon.exe'],
        'cmd.exe':       ['explorer.exe','powershell.exe','cmd.exe'],
    }

    suspicious_pids = []
    for line in pslist_out.splitlines():
        line_lower = line.lower()
        # Cek nama mencurigakan
        for name in SUSPICIOUS_NAMES:
            if name in line_lower:
                print(f"  {Fore.RED}[!] Proses mencurigakan: {line.strip()}{Style.RESET_ALL}")
                add_to_summary("MEMORY-SUSPICIOUS-PROC", line.strip()[:80])
                pid_match = re.search(r'\b(\d{3,6})\b', line)
                if pid_match:
                    suspicious_pids.append(pid_match.group(1))
                break
        # Cek parent anomali
        for proc, legit_parents in LEGIT_PARENTS.items():
            if proc in line_lower:
                if not any(p.lower() in pslist_out.lower() for p in legit_parents):
                    pass  # simplified check

    # ── 2. windows.malfind — deteksi injected memory
    print(f"\n{Fore.CYAN}[MEMORY-ADV] windows.malfind (injected memory)...{Style.RESET_ALL}")
    malfind_out = run_vol_adv("windows.malfind", label="malfind", timeout=300)

    if malfind_out:
        # Extract PIDs dari malfind
        for m in re.finditer(r'PID:\s*(\d+)', malfind_out):
            pid = m.group(1)
            if pid not in suspicious_pids:
                suspicious_pids.append(pid)

        # Deteksi RWX regions (execute + write = injected shellcode)
        rwx_count = malfind_out.count('PAGE_EXECUTE_READWRITE')
        if rwx_count > 0:
            print(f"{Fore.RED}  [!] {rwx_count} RWX memory region(s) ditemukan — kemungkinan injected code!{Style.RESET_ALL}")
            add_to_summary("MEMORY-MALFIND", f"{rwx_count} RWX regions found")

    # ── 3. Dump memori proses mencurigakan
    if suspicious_pids:
        print(f"\n{Fore.CYAN}[MEMORY-ADV] Dump memori {len(suspicious_pids[:5])} proses mencurigakan...{Style.RESET_ALL}")
        dump_dir = out_dir / "process_dumps"
        dump_dir.mkdir(exist_ok=True)

        for pid in suspicious_pids[:5]:
            print(f"  Dumping PID {pid}...")
            try:
                r = subprocess.run(
                    f"{vol_cmd} -f '{filepath}' windows.memmap --pid {pid} --dump",
                    shell=True, capture_output=True, text=True,
                    timeout=120, cwd=str(dump_dir))
                if r.returncode == 0:
                    for f in dump_dir.glob(f"pid.{pid}.*"):
                        sr = subprocess.getoutput(f"strings -n 8 '{f}'")
                        flags_in_dump = scan_text_for_flags(sr, f"MEMDUMP-PID{pid}")
                        auto_decode_multi(sr, f"MEMDUMP-PID{pid}")
                        if flags_in_dump:
                            print(f"  {Fore.GREEN}FLAG di PID {pid}: {flags_in_dump}{Style.RESET_ALL}")
                        add_to_summary("MEMORY-DUMP", f"PID {pid}: {f.name}")
            except Exception as e:
                print(f"  {Fore.YELLOW}Dump PID {pid} gagal: {e}{Style.RESET_ALL}")
    else:
        print(f"{Fore.YELLOW}[MEMORY-ADV] Tidak ada proses mencurigakan terdeteksi{Style.RESET_ALL}")

    # ── 4. Plugin tambahan
    run_vol_adv("windows.cmdline",  label="cmdline_adv")
    run_vol_adv("windows.dlllist",  label="dlllist_adv")
    run_vol_adv("windows.netscan",  label="netscan_adv")

    # Cari string credential/secret
    print(f"\n{Fore.CYAN}[MEMORY-ADV] Scan memory untuk secrets...{Style.RESET_ALL}")
    _memory_fallback_scan(filepath, out_dir)

    new_flags = list(found_flags_set)[found_before:]
    log_tool("memory-advanced", "✅ Found" if new_flags else "⬜ Analyzed",
             ", ".join(new_flags) if new_flags else f"output: {out_dir.name}")
    add_to_summary("MEMORY-ADV-DONE", f"Output: '{out_dir.name}'")
    print(f"{Fore.GREEN}[MEMORY-ADV] Selesai. Output: {out_dir.name}{Style.RESET_ALL}")


def _memory_fallback_scan(filepath, out_dir):
    """Fallback memory scan tanpa Volatility: strings + multi-decode"""
    print(f"{Fore.CYAN}[MEMORY-SCAN] Raw strings + decode scan...{Style.RESET_ALL}")
    try:
        cmd = f"strings -n 8 '{filepath}' | head -100000"
        str_out = subprocess.run(cmd, shell=True, capture_output=True,
                                 text=True, timeout=120).stdout
        (out_dir / "memory_strings.txt").write_text(str_out[:1000000])
        scan_text_for_flags(str_out, "MEMORY-STRINGS")
        auto_decode_multi(str_out, "MEMORY-STRINGS")
        collect_base64_from_text(str_out)

        # Scan dengan UTF-16
        cmd16 = f"strings -e l -n 8 '{filepath}' | head -10000"
        str16 = subprocess.run(cmd16, shell=True, capture_output=True,
                               text=True, timeout=30).stdout
        scan_text_for_flags(str16, "MEMORY-UTF16")
        collect_base64_from_text(str16)
    except Exception as e:
        print(f"{Fore.YELLOW}[MEMORY-SCAN] Gagal: {e}{Style.RESET_ALL}")



# ═══════════════════════════════════════════════════════════════
# ══ RAVEN v4.0 — CRYPTO MODULE ══════════════════════════════════
# ═══════════════════════════════════════════════════════════════
# Berdasarkan writeup: RSA Weak Prime, Fermat, Common-Modulus,
# Bellcore CRT Fault, Vigenere+Acrostic, XOR KPA, AES-CBC Padding
# Oracle (offline), Classic Cipher (Atbash+Caesar), Encoding Chain,
# Number Theory Brute.

# ── Crypto Utilities ─────────────────────────────────────────────

def crypto_gcd(a, b):
    while b: a, b = b, a % b
    return a

def crypto_extended_gcd(a, b):
    """Extended Euclidean — return (g, s, t) s.t. a*s + b*t = g"""
    if b == 0: return a, 1, 0
    g, x, y = crypto_extended_gcd(b, a % b)
    return g, y, x - (a // b) * y

def crypto_modinv(a, m):
    g, x, _ = crypto_extended_gcd(a % m, m)
    if g != 1: raise ValueError(f"No modular inverse: gcd({a},{m})={g}")
    return x % m

def crypto_isqrt(n):
    if n < 0: raise ValueError("Square root of negative number")
    if n == 0: return 0
    x = int(math.isqrt(n))
    # correct for Python < 3.8 or float precision
    while x * x > n: x -= 1
    while (x + 1) * (x + 1) <= n: x += 1
    return x

def crypto_int_to_str(n):
    try:
        b = n.to_bytes((n.bit_length() + 7) // 8, 'big')
        return b.decode('utf-8', errors='replace')
    except Exception:
        return ""

def _crypto_banner(title):
    print(f"\n{Fore.MAGENTA}{'─'*60}")
    print(f"  🔐 CRYPTO: {title}")
    print(f"{'─'*60}{Style.RESET_ALL}")

def _crypto_result(label, value):
    print(f"  {Fore.GREEN}{label}: {Fore.YELLOW}{value}{Style.RESET_ALL}")
    add_to_summary(f"CRYPTO-{label.upper().replace(' ','_')}", str(value)[:200])

def _crypto_flag_check(text, source):
    text = str(text)
    found = scan_text_for_flags(text, source)
    return found

# ── 1. RSA: WEAK PRIME (N = 2 × q) ──────────────────────────────

def rsa_weak_prime(N, e, c):
    """
    Attack: salah satu faktor prima adalah bilangan kecil (cth: 2).
    Jika N = 2 × q, faktorisasi trivial.
    Ref: writeup RSA Weak Prime picoCTF.
    """
    _crypto_banner("RSA Weak Prime Factorization")
    print(f"  N = {str(N)[:60]}...")
    print(f"  e = {e}")

    # Coba faktor-faktor kecil (primes up to 10^6)
    small_primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47]
    # Tambah sampai 10^5 dengan sieve sederhana
    sieve_limit = 100000
    sieve = list(range(sieve_limit + 1))
    for i in range(2, int(sieve_limit**0.5) + 1):
        if sieve[i] == i:
            for j in range(i*i, sieve_limit + 1, i):
                if sieve[j] == j: sieve[j] = i
    small_primes_full = [i for i in range(2, sieve_limit + 1) if sieve[i] == i]

    p_found = None
    for p in small_primes_full:
        if N % p == 0:
            p_found = p
            break

    if p_found:
        q = N // p_found
        _crypto_result("p (small prime)", p_found)
        _crypto_result("q", str(q)[:60])
        try:
            phi = (p_found - 1) * (q - 1)
            d = crypto_modinv(e, phi)
            m = pow(c, d, N)
            flag_str = crypto_int_to_str(m)
            _crypto_result("Decrypted", flag_str)
            _crypto_flag_check(flag_str, "RSA-WEAK-PRIME")
            return flag_str
        except Exception as ex:
            print(f"  {Fore.RED}Dekripsi gagal: {ex}{Style.RESET_ALL}")
    else:
        print(f"  {Fore.YELLOW}Tidak ada faktor kecil (< {sieve_limit}) ditemukan.{Style.RESET_ALL}")
    return None

# ── 2. RSA: FERMAT FACTORIZATION ─────────────────────────────────

def rsa_fermat_factor(N, e, c, max_iter=500000):
    """
    Attack: p dan q sangat berdekatan nilainya.
    N = a^2 - b^2 = (a+b)(a-b), mulai dari a = ceil(sqrt(N)).
    Ref: writeup RSA Baby Steps — Fermat's Factorization.
    """
    _crypto_banner("RSA Fermat Factorization (|p-q| kecil)")
    print(f"  N = {str(N)[:60]}...")

    a = crypto_isqrt(N)
    if a * a < N: a += 1
    b2 = a * a - N
    b = crypto_isqrt(b2)
    steps = 0

    while b * b != b2 and steps < max_iter:
        a += 1
        b2 = a * a - N
        b = crypto_isqrt(b2)
        steps += 1

    if b * b == b2:
        p, q = a - b, a + b
        _crypto_result("Ditemukan dalam N iterasi", steps)
        _crypto_result("p", str(p)[:60])
        _crypto_result("q", str(q)[:60])
        _crypto_result("|p-q|", str(abs(p - q)))
        try:
            phi = (p - 1) * (q - 1)
            d = crypto_modinv(e, phi)
            m = pow(c, d, N)
            flag_str = crypto_int_to_str(m)
            _crypto_result("Decrypted", flag_str)
            _crypto_flag_check(flag_str, "RSA-FERMAT")
            return flag_str
        except Exception as ex:
            print(f"  {Fore.RED}Dekripsi gagal: {ex}{Style.RESET_ALL}")
    else:
        print(f"  {Fore.YELLOW}Fermat: faktor tidak ditemukan dalam {max_iter} iterasi.{Style.RESET_ALL}")
    return None

# ── 3. RSA: COMMON MODULUS ATTACK ────────────────────────────────

def rsa_common_modulus(N, e1, e2, c1, c2):
    """
    Attack: N sama, e1 dan e2 berbeda, pesan sama dienkripsi dua kali.
    gcd(e1,e2)=1 → EEA → M = C1^s * C2^t mod N.
    Ref: writeup RSA Dual Cipher Part A.
    """
    _crypto_banner("RSA Common Modulus Attack")
    g, s, t = crypto_extended_gcd(e1, e2)
    _crypto_result(f"gcd(e1={e1}, e2={e2})", g)
    if g != 1:
        print(f"  {Fore.RED}gcd ≠ 1, Common Modulus Attack tidak berlaku!{Style.RESET_ALL}")
        return None
    _crypto_result("s", s)
    _crypto_result("t", t)

    # Handle negatif: C^(-k) = (C^-1 mod N)^k
    if s < 0:
        c1_inv = pow(c1, -1, N)
        part1 = pow(c1_inv, -s, N)
    else:
        part1 = pow(c1, s, N)

    if t < 0:
        c2_inv = pow(c2, -1, N)
        part2 = pow(c2_inv, -t, N)
    else:
        part2 = pow(c2, t, N)

    M = (part1 * part2) % N
    flag_str = crypto_int_to_str(M)
    _crypto_result("Recovered plaintext", flag_str)
    _crypto_flag_check(flag_str, "RSA-COMMON-MOD")
    return flag_str

# ── 4. RSA: BELLCORE CRT FAULT ATTACK ────────────────────────────

def rsa_bellcore_crt(N, e, C, sig_faulty, M_msg):
    """
    Attack: signature RSA-CRT yang cacat akibat bit-flip hardware.
    gcd(sig_faulty^e - M, N) = p atau q.
    Ref: writeup RSA Dual Cipher Part B.
    """
    _crypto_banner("RSA Bellcore CRT Fault Attack")
    diff = (pow(sig_faulty, e, N) - M_msg) % N
    p = crypto_gcd(diff, N)

    if p in (1, N):
        print(f"  {Fore.YELLOW}GCD tidak menghasilkan faktor nontrivial.{Style.RESET_ALL}")
        return None

    q = N // p
    if p * q != N:
        print(f"  {Fore.RED}p * q ≠ N, faktorisasi gagal.{Style.RESET_ALL}")
        return None

    _crypto_result("p", str(p)[:60])
    _crypto_result("q", str(q)[:60])

    try:
        phi = (p - 1) * (q - 1)
        d = crypto_modinv(e, phi)
        m = pow(C, d, N)
        flag_str = crypto_int_to_str(m)
        _crypto_result("Decrypted", flag_str)
        _crypto_flag_check(flag_str, "RSA-BELLCORE")
        return flag_str
    except Exception as ex:
        print(f"  {Fore.RED}Dekripsi gagal: {ex}{Style.RESET_ALL}")
    return None

def substitution_cipher_auto(ciphertext):
    """
    Monoalphabetic substitution cipher — frequency analysis otomatis.
    Sangat sering di soal crypto 'easy' CTF.
    Menggunakan analisis frekuensi huruf Inggris/Indonesia.
    """
    _crypto_banner("Substitution Cipher - Frequency Analysis")
    
    # English letter frequency (most to least common)
    english_freq = "ETAOINSHRDLCUMWFGYPBVKJXQZ"
    # Indonesian letter frequency (approximate)
    indonesian_freq = "AENITRUSKDLMOPBGJYCFHVWZ"
    
    # Only analyze alphabetic characters
    alpha_only = re.sub(r'[^a-zA-Z]', '', ciphertext)
    
    if len(alpha_only) < 20:
        print(f"  {Fore.YELLOW}Text too short for frequency analysis (need >20 chars){Style.RESET_ALL}")
        return []
    
    # Count letter frequencies in ciphertext
    freq = Counter(alpha_only.upper())
    total = sum(freq.values())
    
    # Sort by frequency (most common first)
    cipher_freq_order = ''.join([k for k, v in freq.most_common()])
    
    print(f"  {Fore.CYAN}Letter frequency analysis:{Style.RESET_ALL}")
    print(f"  {Fore.CYAN}Most common: {cipher_freq_order[:10]}{Style.RESET_ALL}")
    print(f"  {Fore.CYAN}Total letters: {total}{Style.RESET_ALL}")
    
    results = []
    
    # Try English frequency mapping
    print(f"\n  {Fore.YELLOW}[English Frequency Mapping]{Style.RESET_ALL}")
    english_mapping = {}
    for i, char in enumerate(cipher_freq_order):
        if i < len(english_freq):
            english_mapping[char] = english_freq[i]
    
    # Decode with English mapping
    english_decoded = []
    for char in alpha_only.upper():
        english_decoded.append(english_mapping.get(char, char))
    english_result = ''.join(english_decoded)
    
    # Print first 200 chars
    print(f"  {Fore.GREEN}English: {english_result[:200]}{Style.RESET_ALL}")
    scan_text_for_flags(english_result, "SUBST-ENGLISH")
    results.append(("English-Freq", english_result[:200]))
    
    # Try Indonesian frequency mapping
    print(f"\n  {Fore.YELLOW}[Indonesian Frequency Mapping]{Style.RESET_ALL}")
    indo_mapping = {}
    for i, char in enumerate(cipher_freq_order):
        if i < len(indonesian_freq):
            indo_mapping[char] = indonesian_freq[i]
    
    # Decode with Indonesian mapping
    indo_decoded = []
    for char in alpha_only.upper():
        indo_decoded.append(indo_mapping.get(char, char))
    indo_result = ''.join(indo_decoded)
    
    # Print first 200 chars
    print(f"  {Fore.GREEN}Indonesian: {indo_result[:200]}{Style.RESET_ALL}")
    scan_text_for_flags(indo_result, "SUBST-INDONESIAN")
    results.append(("Indonesian-Freq", indo_result[:200]))
    
    # Also try ROT13 as it's sometimes confused with substitution
    rot13_result = ciphertext.translate(str.maketrans(
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz',
        'NOPQRSTUVWXYZABCDEFGHIJKLMnopqrstuvwxyzabcdefghijklm'))
    print(f"\n  {Fore.YELLOW}[ROT13 (for comparison)]{Style.RESET_ALL}")
    print(f"  {Fore.GREEN}{rot13_result[:200]}{Style.RESET_ALL}")
    scan_text_for_flags(rot13_result, "SUBST-ROT13")
    results.append(("ROT13", rot13_result[:200]))
    
    # Check for flag patterns in all results
    found_flags = []
    for method, result in results:
        for pat in COMMON_FLAG_PATTERNS:
            matches = re.findall(pat, result, re.IGNORECASE)
            for match in matches:
                found_flags.append((method, match))
                print(f"\n{Fore.GREEN}{'─'*50}")
                print(f"  🚩 FLAG dari Substitution Cipher!")
                print(f"  {Fore.YELLOW}{match}{Style.RESET_ALL}")
                print(f"  Method: {method}")
                print(f"{Fore.GREEN}{'─'*50}{Style.RESET_ALL}\n")
    
    if found_flags:
        add_to_summary("SUBST-CIPHER-FLAG", f"Found {len(found_flags)} flag(s)")
    else:
        print(f"\n  {Fore.YELLOW}No clear flags found. Try manual analysis of the decoded text.{Style.RESET_ALL}")
    
    log_tool("substitution-cipher", "✅ Found" if found_flags else "⬜ Nothing",
             f"English/Indonesian frequency analysis")
    
    return results

# ── 7. CLASSIC CIPHER: ATBASH + CAESAR BRUTE ─────────────────────

def rsa_small_e_attack(N, e, c):
    """
    RSA Small Exponent Attack — ketika e kecil (biasanya e=3) dan pesan pendek.
    Jika m^e < N, maka c = m^e mod N = m^e (tidak ter-modulo).
    Cukup hitung akar pangkat e dari c untuk mendapat m.
    Sangat sering di CTF pemula!
    """
    try:
        # Try to use gmpy2 for efficient root calculation
        try:
            import gmpy2
            m, exact = gmpy2.iroot(c, e)
            if exact:
                m_int = int(m)
                flag_str = crypto_int_to_str(m_int)
                _crypto_result(f"Small-e Attack (e={e})", flag_str)
                _crypto_flag_check(flag_str, f"RSA-SMALL-E-{e}")
                return flag_str
        except ImportError:
            # Fallback: integer root without gmpy2
            def integer_root(n, e):
                """Calculate integer e-th root of n using Newton's method"""
                if n == 0:
                    return 0, True
                if n < 0:
                    return None, False
                
                # Initial guess
                x = int(n ** (1.0 / e))
                
                # Newton's method iteration
                for _ in range(100):
                    x_new = ((e - 1) * x + n // pow(x, e - 1)) // e
                    if x_new == x:
                        break
                    x = x_new
                
                # Check if exact
                power = pow(x, e)
                return x, (power == n)
            
            m, exact = integer_root(c, e)
            if exact:
                flag_str = crypto_int_to_str(m)
                _crypto_result(f"Small-e Attack (e={e})", flag_str)
                _crypto_flag_check(flag_str, f"RSA-SMALL-E-{e}")
                return flag_str
        
        print(f"  {Fore.YELLOW}Small-e attack: c bukan e-th perfect root{Style.RESET_ALL}")
    except Exception as ex:
        print(f"  {Fore.YELLOW}Small-e attack gagal: {ex}{Style.RESET_ALL}")
    return None

# ── 5. RSA: AUTO-DETECT & TRY ALL ATTACKS ────────────────────────

def rsa_auto_attack(N, e, c, e2=None, c2=None, sig_faulty=None, msg=None):
    """
    Coba semua RSA attacks secara otomatis berdasarkan parameter yang tersedia.
    """
    _crypto_banner("RSA Auto-Attack Pipeline")
    results = []

    # Small e attack (cepat, sangat umum di CTF)
    print(f"\n{Fore.CYAN}[RSA] Mencoba Small Exponent Attack (e={e})...{Style.RESET_ALL}")
    r = rsa_small_e_attack(N, e, c)
    if r: results.append(("Small-e", r))

    # Fermat dulu (cepat)
    print(f"\n{Fore.CYAN}[RSA] Mencoba Fermat Factorization...{Style.RESET_ALL}")
    r = rsa_fermat_factor(N, e, c)
    if r: results.append(("Fermat", r))

    # Weak prime
    print(f"\n{Fore.CYAN}[RSA] Mencoba Weak Prime Factorization...{Style.RESET_ALL}")
    r = rsa_weak_prime(N, e, c)
    if r: results.append(("WeakPrime", r))

    # Common modulus (butuh e2, c2)
    if e2 and c2:
        print(f"\n{Fore.CYAN}[RSA] Mencoba Common Modulus Attack...{Style.RESET_ALL}")
        r = rsa_common_modulus(N, e, e2, c, c2)
        if r: results.append(("CommonMod", r))

    # Bellcore (butuh sig_faulty, msg)
    if sig_faulty and msg:
        print(f"\n{Fore.CYAN}[RSA] Mencoba Bellcore CRT Fault Attack...{Style.RESET_ALL}")
        r = rsa_bellcore_crt(N, e, c, sig_faulty, msg)
        if r: results.append(("Bellcore", r))

    if results:
        print(f"\n{Fore.GREEN}{'═'*50}")
        print(f"  🚩 RSA ATTACK BERHASIL!")
        for method, val in results:
            print(f"  [{method}] {val}")
        print(f"{'═'*50}{Style.RESET_ALL}")
    else:
        print(f"\n{Fore.YELLOW}[RSA] Semua serangan dasar gagal. Coba sympy/factordb untuk N yang lebih besar.{Style.RESET_ALL}")
    return results

# ── 5b. AES-CBC PADDING ORACLE ATTACK ─────────────────────────

def padding_oracle_attack(iv_hex, ct_hex, oracle_func):
    """
    Padding Oracle Attack pada AES-CBC.
    oracle_func(iv_hex, ct_hex) -> True jika padding VALID.
    """
    _crypto_banner("AES-CBC Padding Oracle Attack")
    
    iv = bytes.fromhex(iv_hex)
    ct = bytes.fromhex(ct_hex)
    block_size = 16
    
    if len(iv) != block_size:
        print(f"  {Fore.RED}IV harus 16 bytes!{Style.RESET_ALL}")
        return None
    
    if len(ct) % block_size != 0:
        print(f"  {Fore.RED}Ciphertext harus kelipatan 16 bytes!{Style.RESET_ALL}")
        return None
    
    num_blocks = len(ct) // block_size
    print(f"  {Fore.CYAN}IV: {iv_hex}{Style.RESET_ALL}")
    print(f"  {Fore.CYAN}CT: {ct_hex[:64]}...{Style.RESET_ALL}")
    print(f"  {Fore.CYAN}Jumlah block: {num_blocks}{Style.RESET_ALL}")
    
    plaintext = b""
    
    # Attack setiap block
    for block_idx in range(num_blocks):
        ct_block = ct[block_idx*block_size:(block_idx+1)*block_size]
        prev_block = iv if block_idx == 0 else ct[(block_idx-1)*block_size:block_idx*block_size]
        
        print(f"\n  {Fore.YELLOW}[Block {block_idx+1}/{num_blocks}] Attacking...{Style.RESET_ALL}")
        
        intermediate = bytearray(block_size)
        
        for byte_pos in range(block_size - 1, -1, -1):
            padding_value = block_size - byte_pos
            
            # Brute force byte ini
            for guess in range(256):
                modified_iv = bytearray(block_size)
                
                # Set byte setelah posisi saat ini untuk padding yang valid
                for i in range(byte_pos + 1, block_size):
                    modified_iv[i] = intermediate[i] ^ padding_value
                
                # Try guess ini
                modified_iv[byte_pos] = guess
                
                # Query oracle
                if oracle_func(modified_iv.hex(), ct_block.hex()):
                    # Padding valid!
                    intermediate[byte_pos] = guess ^ padding_value
                    
                    # Verifikasi untuk last byte (bisa false positive)
                    if byte_pos == block_size - 1:
                        verify_iv = bytearray(modified_iv)
                        verify_iv[block_size - 2] ^= 1
                        if oracle_func(verify_iv.hex(), ct_block.hex()):
                            # False positive, lanjutkan
                            continue
                    
                    break
        
        # Decrypt block: plaintext = intermediate ^ prev_block
        pt_block = bytes(a ^ b for a, b in zip(intermediate, prev_block))
        plaintext += pt_block
        print(f"  {Fore.GREEN}✓ Decrypted: {pt_block}{Style.RESET_ALL}")
    
    # Hapus PKCS#7 padding
    if plaintext:
        padding_len = plaintext[-1]
        if 1 <= padding_len <= block_size and all(b == padding_len for b in plaintext[-padding_len:]):
            plaintext = plaintext[:-padding_len]
    
    # Coba decode sebagai string
    try:
        flag_str = plaintext.decode('utf-8')
        _crypto_result("Decrypted", flag_str)
        _crypto_flag_check(flag_str, "PADDING-ORACLE")
        return flag_str
    except:
        _crypto_result("Raw plaintext (hex)", plaintext.hex())
        return None

def padding_oracle_standalone(iv_hex, ct_hex, oracle_script_path):
    """
    Padding Oracle Attack dengan oracle dari file eksternal (oracle.py).
    """
    import subprocess
    
    def oracle_query(iv_h, ct_h):
        try:
            result = subprocess.run(
                ['python3', oracle_script_path, iv_h, ct_h],
                capture_output=True, text=True, timeout=5
            )
            return result.stdout.strip() == "VALID"
        except:
            return False
    
    return padding_oracle_attack(iv_hex, ct_hex, oracle_query)

# ── 6. VIGENERE CIPHER + ACROSTIC KEY FINDER ─────────────────────

def vigenere_decrypt(ciphertext, key):
    """
    Dekripsi Vigenere cipher. Karakter non-alpha disisipkan kembali.
    Ref: writeup Vigenere's Secret — key PHANTOM dari akrostik.
    """
    key = key.upper()
    result = []
    key_idx = 0
    for c in ciphertext:
        if c.isalpha():
            shift = ord(key[key_idx % len(key)]) - ord('A')
            plain = chr((ord(c.lower()) - ord('a') - shift + 26) % 26 + ord('a'))
            # Preserve original case
            result.append(plain.upper() if c.isupper() else plain)
            key_idx += 1
        else:
            result.append(c)
    return ''.join(result)

def find_acrostic_key(text):
    """
    Cari kunci akrostik: huruf pertama setiap kalimat/baris bermakna.
    Ref: writeup — kunci PHANTOM tersembunyi sebagai akrostik paragraf.
    """
    lines = [l.strip() for l in text.splitlines() if l.strip()]
    # Ambil huruf pertama dari tiap baris yang dimulai huruf kapital
    acrostic = ''
    for line in lines:
        # Skip baris header/separator (=== ... ===)
        if re.match(r'^[=\-\*#]{3,}', line): continue
        # Skip baris metadata (Date:, Classification:)
        if re.match(r'^[A-Za-z]+:', line) and len(line.split()[0]) > 3 and line.split()[0].endswith(':'):
            continue
        m = re.match(r'([A-Za-z])', line)
        if m:
            acrostic += m.group(1).upper()
    return acrostic

def analyze_vigenere(ciphertext, context_text=""):
    """
    Analisis Vigenere:
    1. Cari kunci dari akrostik context_text
    2. Brute-force kunci pendek (1-8 karakter) jika perlu
    3. Frequency analysis untuk kunci panjang
    """
    _crypto_banner("Vigenere Cipher Analysis")
    print(f"  Ciphertext: {ciphertext[:80]}")

    found_flags = []

    # ── Step 1: Acrostic key dari context
    if context_text:
        acrostic = find_acrostic_key(context_text)
        print(f"\n{Fore.CYAN}[VIGENERE] Akrostik dari teks konteks: '{acrostic}'{Style.RESET_ALL}")

        # Coba sub-sequences dari akrostik (panjang 4-10)
        for length in range(4, min(len(acrostic) + 1, 12)):
            for start in range(max(1, len(acrostic) - length + 1)):
                candidate_key = acrostic[start:start + length]
                decrypted = vigenere_decrypt(ciphertext, candidate_key)
                _crypto_flag_check(decrypted, f"VIGENERE-ACROSTIC-{candidate_key}")
                for pat in COMMON_FLAG_PATTERNS:
                    if re.search(pat, decrypted, re.IGNORECASE):
                        _crypto_result(f"Key '{candidate_key}'", decrypted)
                        found_flags.append(decrypted)

        # Juga coba akrostik penuh
        if len(acrostic) >= 3:
            decrypted = vigenere_decrypt(ciphertext, acrostic)
            _crypto_flag_check(decrypted, "VIGENERE-ACROSTIC-FULL")

    # ── Step 2: Common CTF keys
    common_keys = [
        "KEY","SECRET","FLAG","CTF","CRYPTO","HACK","CIPHER","VIGENERE",
        "PHANTOM","SHADOW","DRAGON","MASTER","DARK","LIGHT","ALPHA","OMEGA",
        "PASSWORD","KEYWORD","ENCODE","DECODE","ATTACK","DEFEND","SECURE"
    ]
    print(f"\n{Fore.CYAN}[VIGENERE] Mencoba {len(common_keys)} kunci umum CTF...{Style.RESET_ALL}")
    for key in common_keys:
        decrypted = vigenere_decrypt(ciphertext, key)
        for pat in COMMON_FLAG_PATTERNS:
            if re.search(pat, decrypted, re.IGNORECASE):
                _crypto_result(f"Key '{key}'", decrypted)
                _crypto_flag_check(decrypted, f"VIGENERE-KEY-{key}")
                found_flags.append(decrypted)

    if not found_flags:
        print(f"  {Fore.YELLOW}Kunci tidak ditemukan secara otomatis.{Style.RESET_ALL}")
        print(f"  {Fore.YELLOW}Tip: gunakan --crypto-key YOURKEY untuk dekripsi manual.{Style.RESET_ALL}")

    return found_flags

# ── 7. CLASSIC CIPHERS: ATBASH + CAESAR AUTO ─────────────────────

def atbash_cipher(text):
    """
    Atbash: A↔Z, B↔Y, dll. Self-inverse.
    Ref: writeup Operation NIGHTFALL — Atbash → Caesar.
    """
    result = []
    for c in text:
        if c.isupper():
            result.append(chr(ord('Z') - (ord(c) - ord('A'))))
        elif c.islower():
            result.append(chr(ord('z') - (ord(c) - ord('a'))))
        else:
            result.append(c)
    return ''.join(result)

def caesar_cipher(text, shift):
    result = []
    for c in text:
        if c.isupper():
            result.append(chr((ord(c) - ord('A') + shift) % 26 + ord('A')))
        elif c.islower():
            result.append(chr((ord(c) - ord('a') + shift) % 26 + ord('a')))
        else:
            result.append(c)
    return ''.join(result)

def analyze_classic_cipher(ciphertext, known_plaintext_prefix=None):
    """
    Auto-analisis cipher klasik:
    - Coba Atbash saja
    - Coba Caesar semua shift
    - Coba Atbash → Caesar (pola dari writeup NIGHTFALL)
    - Coba Caesar → Atbash
    Ref: writeup Operation NIGHTFALL — enkripsi: Caesar+6 lalu Atbash.
    """
    _crypto_banner("Classic Cipher Analysis (Atbash / Caesar / Kombinasi)")
    print(f"  Input: {ciphertext[:80]}")

    found_flags = []

    def check_and_report(label, text):
        for pat in COMMON_FLAG_PATTERNS:
            if re.search(pat, text, re.IGNORECASE):
                _crypto_result(label, text)
                _crypto_flag_check(text, f"CLASSIC-{label.upper().replace(' ','_')}")
                found_flags.append((label, text))
                return True
        return False

    # Atbash saja
    r = atbash_cipher(ciphertext)
    check_and_report("Atbash", r)

    # Caesar semua shift
    for shift in range(1, 26):
        r = caesar_cipher(ciphertext, shift)
        if check_and_report(f"Caesar+{shift}", r): pass

    # Atbash → Caesar
    atbash_first = atbash_cipher(ciphertext)
    for shift in range(1, 26):
        r = caesar_cipher(atbash_first, shift)
        if check_and_report(f"Atbash→Caesar{shift:+}", r): pass
        # Negatif shift (= dekripsi dengan shift positif)
        r = caesar_cipher(atbash_first, -shift)
        if check_and_report(f"Atbash→Caesar{-shift:+}", r): pass

    # Caesar → Atbash
    for shift in range(1, 26):
        caesar_first = caesar_cipher(ciphertext, shift)
        r = atbash_cipher(caesar_first)
        if check_and_report(f"Caesar{shift:+}→Atbash", r): pass

    # Jika ada known_plaintext_prefix, gunakan untuk menemukan shift
    if known_plaintext_prefix:
        print(f"\n{Fore.CYAN}[CLASSIC] Known-plaintext prefix '{known_plaintext_prefix}' — mencari shift...{Style.RESET_ALL}")
        prefix_cipher = ciphertext[:len(known_plaintext_prefix)]
        # Atbash → Caesar dengan prefix
        atbash_prefix = atbash_cipher(prefix_cipher)
        for shift in range(-25, 26):
            candidate = caesar_cipher(atbash_prefix, shift)
            if candidate.upper() == known_plaintext_prefix.upper():
                full_dec = caesar_cipher(atbash_cipher(ciphertext), shift)
                _crypto_result(f"Found! Atbash→Caesar{shift:+}", full_dec)
                _crypto_flag_check(full_dec, "CLASSIC-KNOWN-PREFIX")
                found_flags.append((f"Atbash→Caesar{shift:+}", full_dec))

    if not found_flags:
        print(f"  {Fore.YELLOW}Tidak ada flag ditemukan dengan cipher klasik.{Style.RESET_ALL}")
    return found_flags

# ── 8. XOR: MULTI-BYTE REPEATING KEY — KNOWN PLAINTEXT ATTACK ─────

def xor_kpa_attack(enc_bytes, known_plaintext_bytes, key_len=None):
    """
    Known-Plaintext Attack pada XOR repeating key.
    Jika key_len tidak diketahui, coba 1-32.
    Ref: writeup XOR Chronicles — key DARKSIDE dari DOCUMENT + CTF{.
    """
    _crypto_banner("XOR Multi-Byte KPA (Known-Plaintext Attack)")

    results = []

    def try_key_len(klen):
        # Ekstrak kunci dari known plaintext
        if len(known_plaintext_bytes) < klen:
            return None
        key_partial = bytes(known_plaintext_bytes[i] ^ enc_bytes[i]
                            for i in range(min(klen, len(enc_bytes), len(known_plaintext_bytes))))
        if len(key_partial) < klen:
            return None

        # Cek apakah kunci printable
        if not all(32 <= b <= 126 for b in key_partial):
            return None

        # Dekripsi enc_bytes dengan kunci
        decrypted = bytes(enc_bytes[i] ^ key_partial[i % klen] for i in range(len(enc_bytes)))
        return key_partial, decrypted

    key_lengths = [key_len] if key_len else range(1, 33)
    for klen in key_lengths:
        res = try_key_len(klen)
        if res:
            key_bytes, decrypted = res
            try:
                key_str = key_bytes.decode('ascii', errors='replace')
                dec_str = decrypted.decode('utf-8', errors='replace')
                # Filter: apakah hasil printable?
                printable_ratio = sum(1 for c in decrypted if 32 <= c <= 126) / len(decrypted)
                if printable_ratio > 0.8:
                    _crypto_result(f"Key (len={klen})", key_str)
                    _crypto_result("Decrypted", dec_str[:100])
                    _crypto_flag_check(dec_str, f"XOR-KPA-KEY{klen}")
                    results.append((key_str, dec_str))
            except Exception:
                pass

    if not results:
        print(f"  {Fore.YELLOW}KPA gagal — coba XOR brute force single-byte...{Style.RESET_ALL}")
    return results

def xor_decrypt(enc_bytes, key_bytes):
    """Dekripsi XOR dengan key repeating."""
    klen = len(key_bytes)
    return bytes(enc_bytes[i] ^ key_bytes[i % klen] for i in range(len(enc_bytes)))

def analyze_xor(filepath_or_bytes, known_plain=b'CTF{', key_str=None):
    """
    Analisis file dengan XOR:
    1. Single-byte brute force (256 keys)
    2. Known-plaintext dengan CTF{ prefix
    3. Jika key_str diberikan, langsung decrypt
    """
    _crypto_banner("XOR Analysis")

    if isinstance(filepath_or_bytes, bytes):
        data = filepath_or_bytes
    else:
        try:
            data = Path(filepath_or_bytes).read_bytes()
        except Exception as e:
            print(f"  {Fore.RED}Gagal baca file: {e}{Style.RESET_ALL}")
            return []

    results = []

    # Manual key
    if key_str:
        key_b = key_str.encode('utf-8') if isinstance(key_str, str) else key_str
        dec = xor_decrypt(data, key_b)
        try:
            dec_str = dec.decode('utf-8', errors='replace')
            _crypto_result(f"Key '{key_str}'", dec_str[:100])
            _crypto_flag_check(dec_str, "XOR-MANUAL")
            results.append(dec_str)
        except Exception:
            pass
        return results

    # KPA dengan known_plain
    print(f"\n{Fore.CYAN}[XOR] Known-plaintext: {known_plain}{Style.RESET_ALL}")
    kpa_results = xor_kpa_attack(data, known_plain)
    results.extend(kpa_results)

    # Single-byte brute
    print(f"\n{Fore.CYAN}[XOR] Single-byte brute (256 keys)...{Style.RESET_ALL}")
    xor_found = decode_xor_brute(data)
    for key_val, dec_str in xor_found:
        _crypto_result(f"XOR key=0x{key_val:02x}", dec_str[:80])
        results.append((f"0x{key_val:02x}", dec_str))

    return results

# ── 9. AES-CBC PADDING ORACLE (OFFLINE / LOCAL) ───────────────────

def pkcs7_valid(data):
    """Validasi PKCS#7 padding."""
    if not data: return False
    pad_len = data[-1]
    if pad_len == 0 or pad_len > 16: return False
    return data[-pad_len:] == bytes([pad_len] * pad_len)

def pkcs7_unpad(data):
    pad_len = data[-1]
    return data[:-pad_len]

def aes_cbc_padding_oracle_attack(blocks, oracle_fn, block_size=16):
    """
    Padding Oracle Attack pada AES-CBC.
    blocks: list of 16-byte blocks [IV, CT1, CT2, ...]
    oracle_fn: function(iv_bytes, ct_bytes) -> bool (True = valid padding)
    Ref: writeup Padding Oracle AES-128-CBC.
    """
    _crypto_banner("AES-CBC Padding Oracle Attack")
    print(f"  {len(blocks)-1} ciphertext blocks × {block_size} bytes")

    plaintext = b''

    for block_idx in range(1, len(blocks)):
        target = blocks[block_idx]
        prev   = blocks[block_idx - 1]

        print(f"\n{Fore.CYAN}[ORACLE] Attacking block {block_idx}/{len(blocks)-1}...{Style.RESET_ALL}")

        intermediate = [0] * block_size

        for byte_pos in range(block_size - 1, -1, -1):
            pad_val = block_size - byte_pos

            # Suffix: intermediate ^ pad_val (byte-byte yang sudah diketahui)
            suffix = bytes(intermediate[j] ^ pad_val
                           for j in range(byte_pos + 1, block_size))

            found = False
            for guess in range(256):
                crafted_prev = bytes(byte_pos) + bytes([guess]) + suffix
                if oracle_fn(crafted_prev, target):
                    # Verifikasi: pastikan bukan kebetulan (ubah byte sebelumnya)
                    if byte_pos > 0:
                        verify = (crafted_prev[:byte_pos - 1] +
                                  bytes([crafted_prev[byte_pos - 1] ^ 1]) +
                                  crafted_prev[byte_pos:])
                        if not oracle_fn(verify, target):
                            continue  # Kebetulan valid, skip
                    intermediate[byte_pos] = guess ^ pad_val
                    found = True
                    break

            if not found:
                print(f"  {Fore.YELLOW}Byte pos {byte_pos}: tidak ditemukan (mungkin multi-byte pad edge case){Style.RESET_ALL}")

        # XOR intermediate dengan prev untuk dapat plaintext
        pt_block = bytes(intermediate[i] ^ prev[i] for i in range(block_size))
        print(f"  → {pt_block}")
        plaintext += pt_block

    # Unpad
    try:
        if pkcs7_valid(plaintext):
            plaintext = pkcs7_unpad(plaintext)
    except Exception:
        pass

    flag_str = plaintext.decode('utf-8', errors='replace')
    _crypto_result("Plaintext", flag_str)
    _crypto_flag_check(flag_str, "PADDING-ORACLE")
    return flag_str

def parse_aes_cbc_data(hex_iv, hex_ct_concat):
    """
    Parse IV dan CT dari hex string.
    hex_ct_concat bisa berupa string hex panjang yang mengandung beberapa blok.
    """
    try:
        iv = bytes.fromhex(hex_iv)
        ct = bytes.fromhex(hex_ct_concat)
        blocks = [iv]
        for i in range(0, len(ct), 16):
            blocks.append(ct[i:i+16])
        return blocks
    except Exception as e:
        print(f"  {Fore.RED}Parse error: {e}{Style.RESET_ALL}")
        return []

# ── 10. ENCODING CHAIN DECODER ──────────────────────────────────

def decode_bit_reverse(data_bytes):
    """Balik urutan bit setiap byte. Byte 0xBC (10111100) → 0x3D (00111101)."""
    return bytes(int(format(b, '08b')[::-1], 2) for b in data_bytes)

def solve_encoding_maze(data):
    """
    Dedicated solver untuk challenge "Encoding Maze":
    Pipeline: Base32 → Binary(no spaces) → BitReverse → Reverse → Base64 → Flag
    Ref: CTF{3nc0d1ng_1s_n0t_3ncrypt10n}
    """
    _crypto_banner("Encoding Maze Solver (CTF Writeup)")
    print(f"  Input ({len(data)} chars): {data[:60]}...")
    
    try:
        # Step 1: Base32 decode → binary string (ASCII '0'/'1')
        clean = re.sub(r'[^A-Za-z2-7]', '', data).upper()
        if len(clean) % 8 != 0:
            clean += '=' * ((8 - len(clean) % 8) % 8)
        binary_str = base64.b32decode(clean).decode('ascii')
        print(f"  [1/5] Base32 decode → binary string ({len(binary_str)} chars)")
        
        # Step 2: Binary string → bytes
        # Could be space-separated or continuous
        if ' ' in binary_str:
            groups = binary_str.split()
        else:
            groups = [binary_str[i:i+8] for i in range(0, len(binary_str), 8)]
        
        bytes_val = bytes([int(g, 2) for g in groups if len(g) == 8])
        print(f"  [2/5] Binary → bytes ({len(bytes_val)} bytes): {bytes_val.hex()[:40]}...")
        
        # Step 3: Reverse bits in each byte
        rev_bits = bytes([int(format(b, '08b')[::-1], 2) for b in bytes_val])
        print(f"  [3/5] Bit-reverse each byte → {rev_bits[:20]}...")
        
        # Step 4: Reverse string (to get correct Base64 order)
        correct_b64 = rev_bits.decode('ascii')[::-1]
        print(f"  [4/5] Reverse string → Base64: {correct_b64[:40]}...")
        
        # Step 5: Base64 decode → FLAG
        flag = base64.b64decode(correct_b64).decode('utf-8')
        print(f"\n{Fore.GREEN}{'='*60}{Style.RESET_ALL}")
        print(f"{Fore.GREEN}  🚩 FLAG DITEMUKAN (Encoding Maze)!{Style.RESET_ALL}")
        print(f"{Fore.GREEN}  {flag}{Style.RESET_ALL}")
        print(f"{Fore.GREEN}{'='*60}{Style.RESET_ALL}")
        add_to_summary("ENCODING-MAZE", flag)
        signal_flag_found()
        return flag
    except Exception as e:
        print(f"  {Fore.YELLOW}Encoding Maze solver gagal: {e}{Style.RESET_ALL}")
        return None

def decode_encoding_chain(encoded_str):
    """
    Mencoba decode encoding chain seperti writeup Encoding Maze:
    Base32 → Binary string → bit-reverse each byte → reverse string → Base64 → flag.
    Juga coba variasi urutan.
    Ref: writeup Encoding Maze — CTF{3nc0d1ng_1s_n0t_3ncrypt10n}.
    """
    _crypto_banner("Encoding Chain Decoder (Multi-Stage)")
    print(f"  Input ({len(encoded_str)} chars): {encoded_str[:60]}...")

    # First try the dedicated Encoding Maze solver
    maze_result = solve_encoding_maze(encoded_str)
    if maze_result:
        return [("EncodingMaze", maze_result)]

    found_flags = []

    def try_decode(data, methods_so_far):
        """Rekursif coba decode berbagai kombinasi."""
        if len(methods_so_far) > 6: return  # Batasi depth

        # Cek apakah sudah ada flag
        text = data if isinstance(data, str) else data.decode('utf-8', errors='replace')
        for pat in COMMON_FLAG_PATTERNS:
            if re.search(pat, text, re.IGNORECASE):
                label = " → ".join(methods_so_far)
                _crypto_result(f"Chain [{label}]", text[:100])
                _crypto_flag_check(text, f"CHAIN-{len(methods_so_far)}")
                found_flags.append((label, text))
                return

        # Coba berbagai decoding berikutnya
        text_s = data if isinstance(data, str) else data.decode('utf-8', errors='ignore')
        data_b = data if isinstance(data, bytes) else data.encode('latin-1', errors='ignore')

        # Base32 decode
        try:
            clean = re.sub(r'[^A-Za-z2-7]', '', text_s).upper()
            if len(clean) >= 8:
                pad = (8 - len(clean) % 8) % 8
                decoded = base64.b32decode(clean + '=' * pad)
                try_decode(decoded, methods_so_far + ["Base32"])
        except Exception: pass

        # Base64 decode
        try:
            clean = re.sub(r'[^A-Za-z0-9+/=]', '', text_s)
            if len(clean) >= 4 and len(clean) % 4 == 0:
                decoded = base64.b64decode(clean)
                try_decode(decoded, methods_so_far + ["Base64"])
        except Exception: pass

        # Binary string to bytes (space-separated)
        if 'binary' not in ' '.join(methods_so_far):
            parts = text_s.split()
            if parts and all(re.match(r'^[01]{4,8}$', p) for p in parts[:8]):
                try:
                    decoded = bytes(int(p, 2) for p in parts if re.match(r'^[01]+$', p))
                    try_decode(decoded, methods_so_far + ["BinaryString"])
                except Exception: pass
            # Also try continuous binary (no spaces) - for Encoding Maze
            if re.match(r'^[01]{8,}$', text_s.strip()) and 'binary' not in ' '.join(methods_so_far):
                try:
                    groups = [text_s.strip()[i:i+8] for i in range(0, len(text_s.strip()), 8)]
                    decoded = bytes([int(g, 2) for g in groups if len(g) == 8])
                    try_decode(decoded, methods_so_far + ["BinaryContinuous"])
                except Exception: pass

        # Bit-reverse each byte
        if 'bitrev' not in ' '.join(methods_so_far) and isinstance(data, bytes):
            rev = decode_bit_reverse(data_b)
            try_decode(rev, methods_so_far + ["BitReverse"])

        # Reverse string/bytes
        if 'reverse' not in ' '.join(methods_so_far).lower():
            if isinstance(data, str):
                try_decode(data[::-1], methods_so_far + ["ReverseStr"])
            else:
                try_decode(data_b[::-1], methods_so_far + ["ReverseBytes"])

        # Hex decode
        try:
            clean_hex = re.sub(r'[^0-9a-fA-F]', '', text_s)
            if len(clean_hex) >= 8 and len(clean_hex) % 2 == 0:
                decoded = bytes.fromhex(clean_hex)
                try_decode(decoded, methods_so_far + ["Hex"])
        except Exception: pass

    try_decode(encoded_str, [])

    if not found_flags:
        print(f"  {Fore.YELLOW}Tidak ada flag dalam chain decoding.{Style.RESET_ALL}")
    return found_flags

# ── 11. NUMBER THEORY / MATH BRUTE ──────────────────────────────

def number_theory_brute(constraints_fn, search_range=(1, 10**7), description=""):
    """
    Brute-force bilangan yang memenuhi constraint kustom.
    constraints_fn(n) -> bool
    Ref: writeup Absolute Cinema — perfect square, >99000, 5 unique digits.
    """
    _crypto_banner(f"Number Theory Brute Force{' — ' + description if description else ''}")
    print(f"  Range: {search_range[0]} → {search_range[1]}")

    found = []
    for n in range(search_range[0], search_range[1]):
        if constraints_fn(n):
            found.append(n)
            if len(found) <= 10:
                _crypto_result(f"Kandidat #{len(found)}", n)
            if len(found) >= 100:
                break  # Cukup kandidat

    print(f"  Total kandidat: {len(found)}")
    if found:
        add_to_summary("MATH-BRUTE", f"{len(found)} kandidat, pertama: {found[0]}")
    return found

def find_perfect_square_with_unique_digits(min_val=99000, unique_count=5):
    """
    Cari perfect square > min_val dengan tepat N digit unik.
    Ref: writeup Absolute Cinema — 317^2 = 100489.
    """
    _crypto_banner(f"Perfect Square > {min_val} dengan {unique_count} digit unik")
    start = crypto_isqrt(min_val) + 1
    end   = crypto_isqrt(10**8) + 1
    found = []

    for n in range(start, end):
        sq = n * n
        if len(set(str(sq))) == unique_count:
            found.append((n, sq, sorted(set(str(sq)))))
            _crypto_result(f"{n}^2 = {sq}", f"digit unik: {sorted(set(str(sq)))}")
            if len(found) >= 5:
                break

    return found

# ── 12. CRYPTO AUTO-ANALYZE (dari file teks) ─────────────────────

def _parse_rsa_from_text(text):
    """Ekstrak parameter RSA dari teks (N, e, c, dll.)."""
    params = {}

    # N bisa sangat panjang (multi-line di beberapa soal)
    for key, pats in {
        'N':  [r'[Nn]\s*[:=]\s*(\d{10,})', r'modulus\s*[:=]\s*(\d{10,})'],
        'e':  [r'\be\s*[:=]\s*(\d+)', r'public.?exponent\s*[:=]\s*(\d+)', r'exponent\s*[:=]\s*(\d+)'],
        'c':  [r'\bc\s*[:=]\s*(\d{10,})', r'cipher(?:text)?\s*[:=]\s*(\d{10,})', r'cyphertext\s*[:=]\s*(\d{10,})'],
        'e1': [r'e1\s*[:=]\s*(\d+)'],
        'e2': [r'e2\s*[:=]\s*(\d+)'],
        'c1': [r'[Cc]1\s*[:=]\s*(\d{10,})'],
        'c2': [r'[Cc]2\s*[:=]\s*(\d{10,})'],
        'p':  [r'\bp\s*[:=]\s*(\d{10,})'],
        'q':  [r'\bq\s*[:=]\s*(\d{10,})'],
        'sig_faulty': [r'sig(?:_faulty|faulty|_fault)\s*[:=]\s*(\d{10,})'],
        'sig_correct': [r'sig(?:_correct|correct)\s*[:=]\s*(\d{10,})'],
        'msg': [r'\bM\s*[:=]\s*(\d{10,})', r'message\s*[:=]\s*(\d{10,})'],
    }.items():
        for pat in pats:
            m = re.search(pat, text, re.IGNORECASE)
            if m:
                params[key] = int(m.group(1))
                break

    # Parse RSA dalam format PEM-like dengan N dan e eksplisit
    # Format: -----BEGIN RSA PUBLIC KEY-----\nN = ...\ne = ...\n-----END RSA PUBLIC KEY-----
    if 'BEGIN RSA PUBLIC KEY' in text or 'BEGIN PUBLIC KEY' in text:
        # Extract N
        n_match = re.search(r'[Nn]\s*[:=]\s*(\d{10,})', text)
        if n_match:
            params['N'] = int(n_match.group(1))
        # Extract e
        e_match = re.search(r'\be\s*[:=]\s*(\d+)', text)
        if e_match:
            params['e'] = int(e_match.group(1))

        # Jika tidak ada N dan e eksplisit, coba parse dari base64 PEM
        if 'N' not in params or 'e' not in params:
            pem_match = re.search(r'-----BEGIN.*?-----\s*(.+?)\s*-----END.*?-----', text, re.DOTALL)
            if pem_match:
                pem_data = pem_match.group(1).replace('\n', '').replace('\r', '').replace(' ', '')
                try:
                    import base64 as b64
                    der_bytes = b64.b64decode(pem_data)
                    # Simple ASN.1 parsing untuk extract N dan e
                    idx = 0
                    if der_bytes[0] == 0x30:  # SEQUENCE
                        idx = 2
                        if der_bytes[1] > 0x80:
                            idx += der_bytes[1] - 0x80
                    # Parse INTEGER (N)
                    if idx < len(der_bytes) and der_bytes[idx] == 0x02:  # INTEGER
                        idx += 1
                        n_len = der_bytes[idx]
                        if n_len > 0x80:
                            idx += 1
                            n_len = der_bytes[idx]
                        idx += 1
                        if 'N' not in params:
                            params['N'] = int.from_bytes(der_bytes[idx:idx+n_len], 'big')
                        idx += n_len
                    # Parse INTEGER (e)
                    if idx < len(der_bytes) and der_bytes[idx] == 0x02:  # INTEGER
                        idx += 1
                        e_len = der_bytes[idx]
                        if e_len > 0x80:
                            idx += 1
                            e_len = der_bytes[idx]
                        idx += 1
                        if 'e' not in params:
                            params['e'] = int.from_bytes(der_bytes[idx:idx+e_len], 'big')
                except Exception:
                    pass

    return params

def _parse_aes_from_text(text):
    """Ekstrak IV dan CT hex dari teks."""
    iv_m = re.search(r'[Ii][Vv]\s*[:=]?\s*([0-9a-fA-F]{32})', text)
    ct_m = re.search(r'[Cc][Tt]\s*[:=]?\s*([0-9a-fA-F]{32,})', text)
    iv = iv_m.group(1) if iv_m else None
    ct = ct_m.group(1) if ct_m else None
    return iv, ct

def solve_multi_file_rsa(files_dict, oracle_script_path=None):
    """
    Solve RSA challenge when parameters are in different files.
    files_dict: {'pubkey': text, 'ciphertext': text, ...}
    oracle_script_path: path to oracle.py for padding oracle attacks
    """
    _crypto_banner("RSA Multi-File Solver")

    # Collect all RSA parameters from all files
    combined_params = {}
    for fname, text in files_dict.items():
        params = _parse_rsa_from_text(text)
        combined_params.update(params)

    N = combined_params.get('N')
    e = combined_params.get('e')
    c = combined_params.get('c')
    e1 = combined_params.get('e1')
    e2 = combined_params.get('e2')
    c1 = combined_params.get('c1')
    c2 = combined_params.get('c2')
    sig_faulty = combined_params.get('sig_faulty')
    msg = combined_params.get('msg')

    # Check for Common Modulus Attack (N, e1, e2, c1, c2)
    if N and e1 and e2 and c1 and c2:
        print(f"\n{Fore.CYAN}[RSA] Common Modulus Attack detected!{Style.RESET_ALL}")
        print(f"  {Fore.GREEN}✓ N, e1, e2, c1, c2 tersedia{Style.RESET_ALL}")
        result = rsa_common_modulus(N, e1, e2, c1, c2)
        if result:
            return result

    # Check for Bellcore CRT Fault Attack (N, e, C, sig_faulty, M)
    if N and e and c and sig_faulty and msg:
        print(f"\n{Fore.CYAN}[RSA] Bellcore CRT Fault Attack detected!{Style.RESET_ALL}")
        print(f"  {Fore.GREEN}✓ N, e, C, sig_faulty, M tersedia{Style.RESET_ALL}")
        result = rsa_bellcore_crt(N, e, c, sig_faulty, msg)
        if result:
            return result

    # Standard RSA (N, e, c)
    if N and e and c:
        print(f"  {Fore.GREEN}✓ Parameter RSA lengkap!{Style.RESET_ALL}")
        print(f"    N = {str(N)[:50]}...")
        print(f"    e = {e}")
        print(f"    c = {str(c)[:50]}...")

        # Try auto attacks
        result = rsa_auto_attack(N, e, c, e2, c2, sig_faulty, msg)
        if result:
            return result

    # Check for Padding Oracle (IV + CT in files, with oracle script)
    if oracle_script_path and os.path.exists(oracle_script_path):
        for fname, text in files_dict.items():
            iv_m = re.search(r'[Ii][Vv]\s*[:=]?\s*([0-9a-fA-F]{32})', text)
            ct_m = re.search(r'[Cc][Tt]\s*[:=]?\s*([0-9a-fA-F]{32,})', text)
            if iv_m and ct_m:
                iv_hex = iv_m.group(1)
                ct_hex = ct_m.group(1)
                print(f"\n{Fore.CYAN}[CRYPTO] Padding Oracle Attack mode!{Style.RESET_ALL}")
                print(f"  {Fore.GREEN}✓ Oracle script: {oracle_script_path}{Style.RESET_ALL}")
                result = padding_oracle_standalone(iv_hex, ct_hex, oracle_script_path)
                if result:
                    return result

    print(f"\n{Fore.YELLOW}[RSA] Parameter tidak lengkap atau serangan tidak dikenali.{Style.RESET_ALL}")
    print(f"  N: {'✓' if N else '✗'}  e: {'✓' if e else '✗'}  c: {'✓' if c else '✗'}")
    print(f"  e1: {'✓' if e1 else '✗'}  e2: {'✓' if e2 else '✗'}  c1: {'✓' if c1 else '✗'}  c2: {'✓' if c2 else '✗'}")
    print(f"  sig_faulty: {'✓' if sig_faulty else '✗'}  msg: {'✓' if msg else '✗'}{Style.RESET_ALL}")
    return None

def _parse_vigenere_from_text(text):
    """Cari ciphertext Vigenere (pola PREFIX{...})."""
    for pat in [r'[A-Z]{2,4}\{[A-Za-z0-9_!@#$%^&*()]+\}', r'[a-z]{2,4}\{[A-Za-z0-9_!@#$%^&*()]+\}']:
        m = re.search(pat, text)
        if m:
            return m.group(0)
    return None

def analyze_crypto_file(filepath, args):
    """
    Entry point untuk --crypto mode.
    Baca file, deteksi tipe problem, jalankan serangan yang relevan.
    """
    _crypto_banner(f"RAVEN CRYPTO ENGINE v4.0 — {filepath.name}")

    try:
        text = filepath.read_text(encoding='utf-8', errors='ignore')
    except Exception:
        text = filepath.read_bytes().decode('latin-1', errors='ignore')

    # Fix bug: repaired variable was not defined
    repaired = fix_header(filepath)

    results_all = []

    # ── Scan flag langsung di file
    scan_text_for_flags(text, "CRYPTO-RAW")
    collect_base64_from_text(text)

    # ── Deteksi dan serang RSA
    rsa_params = _parse_rsa_from_text(text)
    if 'N' in rsa_params and 'e' in rsa_params and 'c' in rsa_params:
        print(f"\n{Fore.CYAN}[CRYPTO] Parameter RSA terdeteksi!{Style.RESET_ALL}")
        N, e, c = rsa_params['N'], rsa_params['e'], rsa_params['c']
        e2  = rsa_params.get('e2')
        c2  = rsa_params.get('c2')
        sig = rsa_params.get('sig_faulty')
        msg = rsa_params.get('msg')
        r = rsa_auto_attack(N, e, c, e2, c2, sig, msg)
        results_all.extend(r)

    # ── Deteksi Vigenere
    vigenere_ct = _parse_vigenere_from_text(text)
    if vigenere_ct:
        print(f"\n{Fore.CYAN}[CRYPTO] Potensi Vigenere ciphertext: {vigenere_ct}{Style.RESET_ALL}")
        r = analyze_vigenere(vigenere_ct, context_text=text)
        results_all.extend(r)

    # ── Deteksi Classic Cipher (prefix 2-4 huruf + {})
    classic_m = re.search(r'\b([A-Z]{2,4})\{([A-Za-z0-9_!@#$%^&*()]+)\}', text)
    if classic_m:
        full_cipher = classic_m.group(0)
        print(f"\n{Fore.CYAN}[CRYPTO] Potensi classic cipher: {full_cipher}{Style.RESET_ALL}")
        r = analyze_classic_cipher(full_cipher, known_plaintext_prefix="CTF")
        results_all.extend(r)

    # ── Deteksi Substitution Cipher (text panjang tanpa spasi/pola jelas)
    # Check for long alphabetic-only text (common in substitution ciphers)
    alpha_blocks = re.findall(r'\b[A-Z]{30,}\b', text)
    if alpha_blocks and not classic_m:
        for block in alpha_blocks[:3]:  # Check first 3 blocks
            # Check if it looks like a substitution cipher (not base64, not hex)
            if not re.match(r'^[A-Za-z0-9+/]+=*$', block) and len(block) > 30:
                print(f"\n{Fore.CYAN}[CRYPTO] Potensi substitution cipher: {block[:50]}...{Style.RESET_ALL}")
                r = substitution_cipher_auto(block)
                if r:
                    results_all.extend(r)

    # ── Deteksi AES-CBC (IV + CT hex)
    iv, ct_hex = _parse_aes_from_text(text)
    if iv and ct_hex:
        print(f"\n{Fore.CYAN}[CRYPTO] AES-CBC IV+CT terdeteksi.{Style.RESET_ALL}")
        print(f"  IV : {iv}")
        print(f"  CT : {ct_hex[:64]}...")
        
        # Check if there's an oracle.py in the same directory
        oracle_script = filepath.parent / "oracle.py"
        if oracle_script.exists():
            print(f"  {Fore.GREEN}[INFO] Oracle script ditemukan: {oracle_script}{Style.RESET_ALL}")
            print(f"  {Fore.CYAN}[CRYPTO] Menjalankan Padding Oracle Attack...{Style.RESET_ALL}")
            try:
                result = padding_oracle_standalone(iv, ct_hex, str(oracle_script))
                if result:
                    results_all.append(("PaddingOracle", result))
            except Exception as ex:
                print(f"  {Fore.RED}[ERR] Padding Oracle Attack gagal: {ex}{Style.RESET_ALL}")
        else:
            print(f"  {Fore.YELLOW}[INFO] Padding Oracle membutuhkan oracle function eksternal.{Style.RESET_ALL}")
            print(f"  {Fore.YELLOW}[TIP] Buat file oracle.py di folder yang sama untuk auto-attack.{Style.RESET_ALL}")
            blocks = parse_aes_cbc_data(iv, ct_hex)
            add_to_summary("AES-DETECTED", f"IV={iv}, {len(blocks)-1} CT blocks")

    # ── Encoding chain (jika ada Base32-like string panjang)
    b32_candidates = re.findall(r'[A-Z2-7]{40,}', text)
    for cand in b32_candidates[:3]:
        print(f"\n{Fore.CYAN}[CRYPTO] Potensi encoding chain: {cand[:40]}...{Style.RESET_ALL}")
        r = decode_encoding_chain(cand)
        results_all.extend(r)

    # ── Deobfuscation penuh
    analyze_deobfuscation(text, "CRYPTO-DEOBF")
    auto_decode_multi(text, "CRYPTO-FILE")

    scan_all_outputs_for_flags(repaired)
    return _build_result()
    return _build_result()


# ── Reversing Module (v6.0.1) ──────────────────────────────────

def run_cmd(cmd, timeout=60):
    """Run command with timeout and capture output."""
    try:
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, timeout=timeout
        )
        return result.stdout + result.stderr
    except subprocess.TimeoutExpired:
        return f"[TIMEOUT] Command exceeded {timeout}s"
    except Exception as e:
        return f"[ERROR] {e}"

def detect_packer(filepath):
    """Detect if binary is packed (UPX, custom packer, etc.)."""
    print(f"\n{Fore.CYAN}[REVERSING] Detecting packer...{Style.RESET_ALL}")
    
    output = run_cmd(f"file '{filepath}'")
    
    packers = {
        "UPX": "UPX packed binary detected!",
        "MPRESS": "MPRESS packed binary detected!",
        "ASPack": "ASPack packed binary detected!",
        "Themida": "Themida packed binary detected!",
        "VMProtect": "VMProtect packed binary detected!",
    }
    
    detected = []
    for packer, msg in packers.items():
        if packer.lower() in output.lower():
            print(f"{Fore.GREEN}  ✓ {msg}{Style.RESET_ALL}")
            detected.append(packer)
            add_to_summary("PACKER-DETECT", msg)
    
    if not detected:
        print(f"{Fore.YELLOW}  No common packer detected.{Style.RESET_ALL}")
    
    return detected

def try_unpack_upx(filepath, output_dir):
    """Try to unpack UPX packed binary."""
    print(f"\n{Fore.CYAN}[REVERSING] Attempting UPX unpack...{Style.RESET_ALL}")
    
    output_path = output_dir / f"{filepath.stem}_unpacked"
    
    if not AVAILABLE_TOOLS.get("upx", False):
        # Check if upx is available
        result = subprocess.run("which upx", shell=True, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"{Fore.RED}  upx not installed. Install with: sudo apt install upx-ucl{Style.RESET_ALL}")
            return None
    
    cmd = f"upx -d '{filepath}' -o '{output_path}'"
    output = run_cmd(cmd, timeout=120)
    
    if output_path.exists():
        success_msg = f"Unpacked binary saved to: {output_path}"
        print(f"{Fore.GREEN}  ✓ {success_msg}{Style.RESET_ALL}")
        add_to_summary("UNPACK-UPX", success_msg)
        return output_path
    else:
        print(f"{Fore.RED}  ✗ UPX unpack failed.{Style.RESET_ALL}")
        return None

def strings_analysis(filepath, min_len=6):
    """Extract strings from binary."""
    print(f"\n{Fore.CYAN}[REVERSING] Extracting strings (min length: {min_len})...{Style.RESET_ALL}")
    
    output = run_cmd(f"strings -n {min_len} '{filepath}'", timeout=30)
    
    # Search for flags in strings
    for pat in COMMON_FLAG_PATTERNS:
        matches = re.findall(pat, output, re.IGNORECASE)
        if matches:
            for match in matches:
                print(f"{Fore.GREEN}  ✓ FLAG in strings: {match}{Style.RESET_ALL}")
                add_to_summary("STRINGS-FLAG", match)
                signal_flag_found()
    
    # Extract interesting strings (URLs, IPs, registry keys, etc.)
    patterns = {
        "URLs": r'https?://[^\s<>"]+|www\.[^\s<>"]+',
        "IPs": r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b',
        "Emails": r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
        "Registry": r'HKEY_[A-Z_]+',
        "Functions": r'\b[A-Za-z_][A-Za-z0-9_]*\s*\(',
    }
    
    for name, pattern in patterns.items():
        matches = re.findall(pattern, output, re.IGNORECASE)
        if matches:
            unique_matches = list(set(matches))[:10]  # Limit to 10
            print(f"{Fore.BLUE}  {name} ({len(unique_matches)}):{Style.RESET_ALL}")
            for m in unique_matches[:5]:
                print(f"    • {m}")
            if len(unique_matches) > 5:
                print(f"    ... and {len(unique_matches) - 5} more")
    
    # Save all strings to file
    output_file = filepath.parent / f"{filepath.stem}_strings.txt"
    output_file.write_text(output)
    print(f"{Fore.GREEN}  ✓ Full strings saved to: {output_file}{Style.RESET_ALL}")
    
    return output

def objdump_analysis(filepath):
    """Analyze binary with objdump (ELF files)."""
    print(f"\n{Fore.CYAN}[REVERSING] Analyzing with objdump...{Style.RESET_ALL}")
    
    # Check if ELF
    with open(filepath, 'rb') as f:
        header = f.read(4)
        if header != b'\x7fELF':
            print(f"{Fore.YELLOW}  Not an ELF file, skipping objdump.{Style.RESET_ALL}")
            return
    
    # Disassemble main functions
    functions = ['main', 'start', 'entry', 'init', 'fini']
    output_dir = filepath.parent / f"{filepath.stem}_objdump"
    output_dir.mkdir(exist_ok=True)
    
    for func in functions:
        cmd = f"objdump -d '{filepath}' | grep -A 20 '<{func}>:'"
        output = run_cmd(cmd, timeout=30)
        
        if output and '<main>:' not in output or func != 'main':
            output_file = output_dir / f"{func}.asm"
            output_file.write_text(output)
            print(f"{Fore.GREEN}  ✓ Disassembled {func}() → {output_file}{Style.RESET_ALL}")
    
    # Extract all functions
    cmd = f"objdump -t '{filepath}' | grep -E '\\.text' | awk '{{print $NF}}'"
    functions = run_cmd(cmd, timeout=30).strip().split('\n')
    functions = [f for f in functions if f and not f.startswith('.')]
    
    print(f"{Fore.BLUE}  Found {len(functions)} functions in .text section{Style.RESET_ALL}")
    
    if functions:
        func_file = output_dir / "functions.txt"
        func_file.write_text('\n'.join(functions))
        print(f"{Fore.GREEN}  ✓ Function list saved to: {func_file}{Style.RESET_ALL}")

def readelf_analysis(filepath):
    """Analyze ELF binary structure with readelf."""
    print(f"\n{Fore.CYAN}[REVERSING] Analyzing with readelf...{Style.RESET_ALL}")
    
    # Check if ELF
    with open(filepath, 'rb') as f:
        header = f.read(4)
        if header != b'\x7fELF':
            print(f"{Fore.YELLOW}  Not an ELF file, skipping readelf.{Style.RESET_ALL}")
            return
    
    output_dir = filepath.parent / f"{filepath.stem}_readelf"
    output_dir.mkdir(exist_ok=True)
    
    analyses = {
        "headers": "ELF headers",
        "sections": "Section headers",
        "segments": "Program headers",
        "symbols": "Symbol table",
        "relocations": "Relocation entries",
        "dynamic": "Dynamic section",
    }
    
    for name, desc in analyses.items():
        cmd = f"readelf -{name[0]} '{filepath}'"
        output = run_cmd(cmd, timeout=30)
        
        output_file = output_dir / f"{name}.txt"
        output_file.write_text(output)
        print(f"{Fore.GREEN}  ✓ {desc} saved to: {output_file}{Style.RESET_ALL}")
        
        # Search for interesting symbols
        if name == "symbols":
            for pat in COMMON_FLAG_PATTERNS:
                matches = re.findall(pat, output, re.IGNORECASE)
                if matches:
                    for match in matches:
                        print(f"{Fore.GREEN}    ✓ FLAG in symbols: {match}{Style.RESET_ALL}")
                        add_to_summary("SYMBOL-FLAG", match)

def ghidra_analysis(filepath, output_dir):
    """
    Analyze binary with Ghidra headless analyzer.
    Requires Ghidra to be installed and configured.
    """
    print(f"\n{Fore.CYAN}[REVERSING] Ghidra headless analysis...{Style.RESET_ALL}")
    
    # Check if Ghidra is available
    ghidra_path = os.environ.get("GHIDRA_INSTALL_DIR")
    if not ghidra_path:
        # Try common locations
        possible_paths = [
            "/opt/ghidra",
            "/usr/local/ghidra",
            "~/ghidra",
        ]
        for p in possible_paths:
            p = Path(p).expanduser()
            if p.exists():
                ghidra_path = str(p)
                break
    
    if not ghidra_path:
        print(f"{Fore.YELLOW}  Ghidra not found. Set GHIDRA_INSTALL_DIR environment variable.{Style.RESET_ALL}")
        print(f"{Fore.YELLOW}  Download from: https://ghidra-sre.org/{Style.RESET_ALL}")
        return
    
    analyzeHeadless = Path(ghidra_path) / "support" / "analyzeHeadless"
    if not analyzeHeadless.exists():
        analyzeHeadless = Path(ghidra_path) / "analyzeHeadless"
    
    if not analyzeHeadless.exists():
        print(f"{Fore.RED}  ✗ Ghidra analyzeHeadless not found at: {ghidra_path}{Style.RESET_ALL}")
        return
    
    project_dir = output_dir / "ghidra_project"
    project_name = filepath.stem
    
    print(f"{Fore.BLUE}  Running Ghidra analysis (this may take a while)...{Style.RESET_ALL}")
    
    cmd = (
        f"'{analyzeHeadless}' "
        f"'{project_dir}' "
        f"'{project_name}' "
        f"-import '{filepath}' "
        f"-postScript PrintFunctionHashes.py "
        f"-scriptPath '{ghidra_path}/docs/Ghidra/Features/Headless"
    )
    
    output = run_cmd(cmd, timeout=600)  # 10 minutes timeout
    
    print(f"{Fore.GREEN}  ✓ Ghidra analysis complete. Check: {project_dir}{Style.RESET_ALL}")

def xor_analysis_on_binary(filepath, output_dir):
    """
    Analyze ELF binary for XOR-obfuscated strings and flags.
    Looks for XOR operations with constant keys, common patterns like:
    - XOR with single byte key
    - XOR with multi-byte key
    - XOR with flag format patterns (CTF{, flag{, etc.)
    """
    print(f"\n{Fore.CYAN}[REVERSING] Analyzing XOR-obfuscated data...{Style.RESET_ALL}")
    
    try:
        data = filepath.read_bytes()
    except:
        print(f"  {Fore.RED}✗ Cannot read binary file{Style.RESET_ALL}")
        return None
    
    results = []
    flags_found = []
    
    # Method 1: Single-byte XOR brute force on all data segments
    print(f"  {Fore.YELLOW}[XOR] Single-byte XOR brute force (256 keys)...{Style.RESET_ALL}")
    
    # Optimize: only check chunks, not entire binary at once
    chunk_size = 4096
    step_size = 1024
    
    for key in range(1, 256):  # Skip 0 (no XOR)
        # Slide window through binary
        for offset in range(0, max(1, len(data) - chunk_size), step_size):
            chunk = data[offset:offset + chunk_size]
            decrypted = bytes(b ^ key for b in chunk)
            
            # Check for flag patterns
            for pattern in COMMON_FLAG_PATTERNS:
                matches = re.findall(pattern.encode(), decrypted, re.IGNORECASE)
                if matches:
                    for match in matches:
                        try:
                            flag_str = match.decode('utf-8')
                            if flag_str not in flags_found:
                                flags_found.append(flag_str)
                                print(f"  {Fore.GREEN}✓ FLAG found (XOR key=0x{key:02x}): {flag_str}{Style.RESET_ALL}")
                                add_to_summary("XOR-FLAG", f"key=0x{key:02x}: {flag_str}")
                                signal_flag_found()
                                return flags_found  # Early exit on flag found
                        except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
        
        # Progress indicator for slow scans
        if key % 50 == 0 and not check_early_exit():
            print(f"  {Fore.BLUE}[XOR] Scanned {key}/255 keys...{Style.RESET_ALL}")
    
    # Method 2: Multi-byte XOR with common key lengths (2-8 bytes)
    print(f"\n  {Fore.YELLOW}[XOR] Multi-byte XOR analysis (key lengths 2-8)...{Style.RESET_ALL}")
    
    # Try known plaintext attack with "CTF{" as known prefix
    known_prefix = b'CTF{'
    for key_len in range(2, 9):
        # Try to derive key from known plaintext at various offsets
        for offset in range(0, min(len(data) - key_len, 1000)):
            potential_key = bytes(data[offset + i] ^ known_prefix[i] for i in range(len(known_prefix)))
            
            # Check if key is printable/repeating pattern
            try:
                key_str = potential_key.decode('ascii')
                if all(c in string.printable for c in key_str):
                    # Try this key on surrounding data
                    start = max(0, offset - 20)
                    end = min(len(data), offset + 100)
                    decrypted_segment = bytes(data[i] ^ potential_key[(i - offset) % key_len] for i in range(start, end))
                    
                    # Check for flag
                    for pattern in COMMON_FLAG_PATTERNS:
                        matches = re.findall(pattern.encode(), decrypted_segment, re.IGNORECASE)
                        if matches:
                            for match in matches:
                                try:
                                    flag_str = match.decode('utf-8')
                                    if flag_str not in flags_found:
                                        flags_found.append(flag_str)
                                        print(f"  {Fore.GREEN}✓ FLAG found (XOR key={potential_key.hex()}): {flag_str}{Style.RESET_ALL}")
                                        add_to_summary("XOR-FLAG", f"key={potential_key.hex()}: {flag_str}")
                                        signal_flag_found()
                                        return flags_found
                                except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
            except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
    
    # Method 3: Look for XOR instructions in disassembly
    print(f"\n  {Fore.YELLOW}[XOR] Searching for XOR operations in binary...{Style.RESET_ALL}")
    
    # Common XOR patterns in x86_64: 81 F0 (xor eax, imm32), 83 F0 (xor eax, imm8)
    xor_patterns = [
        (b'\x81\xf0', 'xor eax, imm32'),
        (b'\x81\xf1', 'xor ecx, imm32'),
        (b'\x81\xf2', 'xor edx, imm32'),
        (b'\x81\xf3', 'xor ebx, imm32'),
        (b'\x83\xf0', 'xor eax, imm8'),
        (b'\x30', 'xor r/m8, r8'),
        (b'\x31', 'xor r/m16/32, r16/32'),
    ]
    
    xor_locations = []
    for pattern, desc in xor_patterns:
        offset = 0
        while True:
            pos = data.find(pattern, offset)
            if pos == -1:
                break
            if pos < len(data) - 4:
                xor_locations.append((pos, desc))
            offset = pos + 1
    
    if xor_locations:
        print(f"  {Fore.GREEN}✓ Found {len(xor_locations)} XOR operations{Style.RESET_ALL}")
        # Show first 10 XOR locations
        for loc, desc in xor_locations[:10]:
            context = data[max(0,loc-4):loc+8]
            print(f"  {Fore.BLUE}[0x{loc:06x}] {desc}: {context.hex()}{Style.RESET_ALL}")
    else:
        print(f"  {Fore.YELLOW}✗ No obvious XOR operations found{Style.RESET_ALL}")
    
    # Method 4: Extract all strings and check if they might be XOR'd
    print(f"\n  {Fore.YELLOW}[XOR] Checking for obfuscated strings...{Style.RESET_ALL}")
    
    # Get readable strings
    readable_strings = re.findall(rb'[\x20-\x7e]{4,}', data)
    suspicious_strings = []
    
    for s in readable_strings:
        text = s.decode('ascii', errors='ignore')
        # Check if string looks like encoded/obfuscated data
        if re.match(r'^[A-Za-z0-9+/=]{10,}$', text):  # Base64-like or hex-like
            # Try XOR on this string
            for key in range(1, 256):
                decoded = bytes(b ^ key for b in s)
                try:
                    decoded_str = decoded.decode('utf-8')
                    if any(pat in decoded_str for pat in ['CTF{', 'flag{', 'FLAG{', 'picoCTF{']):
                        print(f"  {Fore.GREEN}✓ Decoded string (key=0x{key:02x}): {decoded_str}{Style.RESET_ALL}")
                        add_to_summary("XOR-DECODED", decoded_str)
                        if decoded_str not in flags_found:
                            flags_found.append(decoded_str)
                            signal_flag_found()
                except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
    
    # Method 5: Check for data sections with high entropy (likely encrypted/XOR'd)
    print(f"\n  {Fore.YELLOW}[XOR] Analyzing data sections for obfuscation...{Style.RESET_ALL}")
    
    # Look for .rodata, .data sections (common places for obfuscated strings)
    # Simple heuristic: find large chunks of printable-but-not-readable data
    high_entropy_regions = []
    for i in range(0, len(data) - 256, 64):
        chunk = data[i:i+256]
        entropy = calculate_entropy(list(chunk))
        if 3.0 < entropy < 6.0:  # Moderate entropy suggests obfuscation (not random)
            high_entropy_regions.append((i, entropy))
    
    if high_entropy_regions:
        print(f"  {Fore.GREEN}✓ Found {len(high_entropy_regions)} potentially obfuscated regions{Style.RESET_ALL}")
        # Try XOR on first few regions
        for offset, entropy in high_entropy_regions[:5]:
            chunk = data[offset:offset+128]
            for key in range(1, 256):
                decoded = bytes(b ^ key for b in chunk)
                try:
                    text = decoded.decode('utf-8')
                    if any(pat in text for pat in ['CTF{', 'flag{', 'FLAG{', 'picoCTF{']):
                        print(f"  {Fore.GREEN}✓ FLAG in obfuscated region (offset=0x{offset:06x}, key=0x{key:02x}){Style.RESET_ALL}")
                        # Extract full flag
                        for pattern in COMMON_FLAG_PATTERNS:
                            matches = re.findall(pattern, text)
                            for match in matches:
                                if match not in flags_found:
                                    flags_found.append(match)
                                    add_to_summary("XOR-FLAG", f"region@0x{offset:06x}: {match}")
                                    signal_flag_found()
                except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
    
    if flags_found:
        print(f"\n{Fore.GREEN}{'='*50}")
        print(f"  🚩 XOR FLAGS FOUND: {len(flags_found)}")
        for f in flags_found:
            print(f"  {f}")
        print(f"{'='*50}{Style.RESET_ALL}")
        return flags_found
    
    if results:
        print(f"\n{Fore.BLUE}[XOR] Found {len(results)} suspicious XOR'd strings{Style.RESET_ALL}")
        return results
    
    print(f"  {Fore.YELLOW}✗ No XOR-obfuscated flags detected{Style.RESET_ALL}")
    return None

def reversing_pipeline(filepath, args):
    """Full reversing pipeline for binary analysis."""
    print(f"\n{Fore.MAGENTA}{'='*60}")
    print(f"REVERSING ANALYSIS: {filepath.name}")
    print(f"{'='*60}{Style.RESET_ALL}")

    output_dir = filepath.parent / f"{filepath.stem}_reversing"
    output_dir.mkdir(exist_ok=True)

    # Step 1: Detect packer
    packers = detect_packer(filepath)

    # Step 2: Try to unpack if packed
    unpacked = filepath
    if "UPX" in packers and args.unpack:
        unpacked_path = try_unpack_upx(filepath, output_dir)
        if unpacked_path:
            unpacked = unpacked_path

    # Step 3: Strings analysis
    strings_output = strings_analysis(unpacked)

    # Step 4: XOR analysis (NEW!)
    xor_results = xor_analysis_on_binary(unpacked, output_dir)

    # Step 5: objdump analysis (ELF only)
    if not args.skip_objdump:
        objdump_analysis(unpacked)

    # Step 6: readelf analysis (ELF only)
    if not args.skip_readelf:
        readelf_analysis(unpacked)

    # Step 7: Ghidra analysis (if available)
    if args.ghidra:
        ghidra_analysis(unpacked, output_dir)

    # Step 8: Search for hardcoded passwords/keys
    print(f"\n{Fore.CYAN}[REVERSING] Searching for hardcoded secrets...{Style.RESET_ALL}")
    password_patterns = [
        r'password\s*[:=]\s*["\']([^"\']{3,})["\']',
        r'passwd\s*[:=]\s*["\']([^"\']{3,})["\']',
        r'secret\s*[:=]\s*["\']([^"\']{3,})["\']',
        r'key\s*[:=]\s*["\']([^"\']{3,})["\']',
        r'token\s*[:=]\s*["\']([^"\']{3,})["\']',
    ]

    for pattern in password_patterns:
        matches = re.findall(pattern, strings_output, re.IGNORECASE)
        if matches:
            for match in matches:
                print(f"{Fore.GREEN}  ✓ Potential secret: {match}{Style.RESET_ALL}")
                add_to_summary("HARDCODED-SECRET", match)

    return _build_result()

# ── 8. PADDING ORACLE ATTACK (AES-CBC) ────────────────────────

def padding_oracle_attack(iv_hex, ct_hex, oracle_func, block_size=16):
    """
    Padding Oracle Attack pada AES-128-CBC.
    Memulihkan plaintext tanpa mengetahui kunci AES.
    
    Args:
        iv_hex: IV dalam hex (32 chars)
        ct_hex: Ciphertext dalam hex (multiple of 32 chars)
        oracle_func: Function(iv_bytes, ct_block_bytes) -> bool
                     Return True jika padding valid, False jika invalid
        block_size: Block size (default 16 untuk AES)
    
    Returns:
        Plaintext bytes atau None jika gagal
    """
    _crypto_banner("Padding Oracle Attack — AES-CBC")
    
    try:
        iv = bytes.fromhex(iv_hex)
        ct = bytes.fromhex(ct_hex)
    except Exception as e:
        print(f"  {Fore.RED}Error parsing hex: {e}{Style.RESET_ALL}")
        return None
    
    if len(ct) % block_size != 0:
        print(f"  {Fore.RED}Ciphertext length not multiple of block size!{Style.RESET_ALL}")
        return None
    
    num_blocks = len(ct) // block_size
    print(f"  {Fore.CYAN}IV     = {iv_hex}{Style.RESET_ALL}")
    print(f"  {Fore.CYAN}CT     = {ct_hex[:64]}...{Style.RESET_ALL}")
    print(f"  {Fore.CYAN}Blocks = {num_blocks}{Style.RESET_ALL}")
    
    all_plaintext = b''
    total_queries = 0
    
    for block_idx in range(num_blocks):
        print(f"\n  {Fore.YELLOW}[*] Attacking block {block_idx+1}/{num_blocks} ...{Style.RESET_ALL}")
        
        # Get current block and previous block (or IV for first block)
        curr_block = ct[block_idx*block_size:(block_idx+1)*block_size]
        prev_block = iv if block_idx == 0 else ct[(block_idx-1)*block_size:block_idx*block_size]
        
        # Recover intermediate values byte-by-byte (right to left)
        intermediate = [0] * block_size
        
        for byte_pos in range(block_size - 1, -1, -1):
            pad_val = block_size - byte_pos
            found = False
            
            # Try all 256 possible values for this byte
            for guess in range(256):
                total_queries += 1
                
                # Build crafted previous block
                # Bytes before target position: 0
                # Target byte: guess
                # Bytes after target position: intermediate[j] XOR pad_val
                crafted = bytearray(block_size)
                
                # Set suffix bytes (already recovered)
                for j in range(byte_pos + 1, block_size):
                    crafted[j] = intermediate[j] ^ pad_val
                
                # Set target byte to guess
                crafted[byte_pos] = guess
                
                # Query oracle
                if oracle_func(bytes(crafted), curr_block):
                    # Found valid padding!
                    intermediate[byte_pos] = guess ^ pad_val
                    found = True
                    
                    # Show progress
                    recovered = bytes(intermediate[j] ^ prev_block[j] for j in range(byte_pos, block_size))
                    print(f"    Byte {byte_pos:2d}: 0x{guess:02x} ✓ → {recovered}", end='')
                    try:
                        print(f"  ({recovered.decode('utf-8', errors='replace')})")
                    except:
                        print()
                    break
            
            if not found:
                print(f"  {Fore.RED}    ✗ Failed to recover byte {byte_pos}{Style.RESET_ALL}")
                return None
        
        # Decrypt this block: plaintext = intermediate XOR prev_block
        plaintext_block = bytes(intermediate[j] ^ prev_block[j] for j in range(block_size))
        all_plaintext += plaintext_block
        
        print(f"  {Fore.GREEN}    → {plaintext_block}{Style.RESET_ALL}")
    
    # Remove PKCS#7 padding
    try:
        pad_len = all_plaintext[-1]
        if 1 <= pad_len <= block_size and all(b == pad_len for b in all_plaintext[-pad_len:]):
            all_plaintext = all_plaintext[:-pad_len]
    except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
    
    print(f"\n{'='*60}")
    print(f"{Fore.GREEN}[+] FLAG (hex) : {all_plaintext.hex()}{Style.RESET_ALL}")
    print(f"{Fore.GREEN}[+] FLAG (str) : {all_plaintext.decode('utf-8', errors='replace')}{Style.RESET_ALL}")
    print(f"{Fore.GREEN}[+] Queries    : {total_queries}{Style.RESET_ALL}")
    print(f"{'='*60}")
    
    flag_str = all_plaintext.decode('utf-8', errors='replace')
    _crypto_flag_check(flag_str, "PADDING-ORACLE")
    add_to_summary("PADDING-ORACLE", flag_str)
    signal_flag_found()
    
    return all_plaintext

def create_oracle_from_file(iv_hex, ct_hex, oracle_file):
    """
    Create oracle function from external oracle.py script.
    """
    import importlib.util
    import sys
    
    try:
        spec = importlib.util.spec_from_file_location("oracle_module", oracle_file)
        oracle_module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(oracle_module)
        
        # Try to find oracle function
        if hasattr(oracle_module, 'oracle'):
            return oracle_module.oracle
        elif hasattr(oracle_module, 'check_padding'):
            return oracle_module.check_padding
        else:
            # Try to call with IV and CT
            if hasattr(oracle_module, 'main'):
                return lambda iv, ct_block: True  # Placeholder
    except Exception as e:
        print(f"  {Fore.YELLOW}Warning: Could not load oracle script: {e}{Style.RESET_ALL}")
    return None

def detect_and_attack_padding_oracle(filepath, args):
    """
    Detect padding oracle challenge and attempt attack.
    Looks for:
    - IV and CT in hex format
    - oracle.py or similar in same directory
    - Challenge files with IV/CT patterns
    """
    _crypto_banner("Padding Oracle Attack Detector")
    
    try:
        content = filepath.read_text(encoding='utf-8', errors='ignore')
    except:
        return None
    
    # Detect IV and CT
    iv_match = re.search(r'[Ii][Vv]\s*[:=]?\s*([0-9a-fA-F]{32})', content)
    ct_match = re.search(r'[Cc][Tt]\s*[:=]?\s*([0-9a-fA-F]{64,})', content)
    
    if not iv_match or not ct_match:
        print(f"  {Fore.YELLOW}No IV/CT pattern detected.{Style.RESET_ALL}")
        return None
    
    iv_hex = iv_match.group(1)
    ct_hex = ct_match.group(1)
    
    print(f"  {Fore.GREEN}✓ Detected IV: {iv_hex}{Style.RESET_ALL}")
    print(f"  {Fore.GREEN}✓ Detected CT: {ct_hex[:40]}...{Style.RESET_ALL}")
    
    # Look for oracle script in same directory
    oracle_file = filepath.parent / 'oracle.py'
    if oracle_file.exists():
        print(f"  {Fore.CYAN}Found oracle script: {oracle_file}{Style.RESET_ALL}")
        oracle_func = create_oracle_from_file(iv_hex, ct_hex, oracle_file)
        if oracle_func:
            return padding_oracle_attack(iv_hex, ct_hex, oracle_func)
    
    # If no oracle script, try to detect if oracle is inline in the file
    # Or provide instructions for manual attack
    print(f"\n{Fore.YELLOW}[INFO] No oracle script found.{Style.RESET_ALL}")
    print(f"{Fore.YELLOW}[INFO] To solve this challenge:{Style.RESET_ALL}")
    print(f"  1. Locate the oracle.py or similar script")
    print(f"  2. Place it in the same directory as the challenge file")
    print(f"  3. Re-run RAVEN")
    print(f"\n{Fore.YELLOW}IV: {iv_hex}{Style.RESET_ALL}")
    print(f"{Fore.YELLOW}CT: {ct_hex}{Style.RESET_ALL}")
    
    # Try to find any Python files in directory that might be the oracle
    py_files = list(filepath.parent.glob('*.py'))
    if py_files:
        print(f"\n{Fore.CYAN}Found Python files that might be the oracle:{Style.RESET_ALL}")
        for pyf in py_files:
            print(f"  • {pyf.name}")
    
    return None

# ── Crypto Engine (v4.0) ─────────────────────────────────────────────

def process_file(filepath, args):
    """
    Process a single file with all available tools.
    Always prints report even if errors occur (v6.0 fix).
    """
    try:
        _process_file_internal(filepath, args)
    except Exception as e:
        print(f"\n{Fore.RED}{'═' * 60}")
        print(f"  ❌ ERROR during analysis: {e}{Style.RESET_ALL}")
        print(f"{Fore.RED}  💡 The analysis encountered an unexpected error.{Style.RESET_ALL}")
        print(f"{Fore.RED}  📝 Error details have been logged above.{Style.RESET_ALL}")
        print(f"{Fore.CYAN}{'═' * 60}{Style.RESET_ALL}\n")
        import traceback
        traceback.print_exc()
    finally:
        # ALWAYS print final report, even on error
        try:
            scan_all_outputs_for_flags(filepath)
            return _build_result()
            # Also print detailed report for better visibility
            print_detailed_report(filepath)
        except Exception as report_error:
            print(f"\n{Fore.RED}[ERROR] Failed to print report: {report_error}{Style.RESET_ALL}")


def _process_file_internal(filepath, args):
    """Internal file processing logic (separated for error handling)."""
    print(f"\n{Fore.BLUE}{'='*60}\nPROCESSING: {filepath.name}\n{'='*60}{Style.RESET_ALL}", flush=True)
    reset_globals()

    # ── Deteksi tipe file (gunakan juga magic bytes)
    real_ext, real_desc = _get_real_type(filepath)
    claimed_ext = filepath.suffix.lower().lstrip('.')

    # Kalau ada mismatch ekstensi, langsung lapor
    if real_ext and real_ext != claimed_ext and not (real_ext=='zip' and claimed_ext in {'docx','xlsx','pptx','jar','apk'}):
        print(f"{Fore.RED}[FAKE-EXT] Ekstensi mismatch! Klaim=.{claimed_ext} Nyata={real_desc}{Style.RESET_ALL}")
        add_to_summary("FAKE-EXT", f".{claimed_ext} → {real_desc}")

    repaired=fix_header(filepath)
    print(f"\n{Fore.GREEN}[METADATA]{Style.RESET_ALL}")
    file_desc=subprocess.getoutput(f"file -b '{repaired}'").lower()
    print(f"Type: {file_desc}")
    try:
        exif_out=subprocess.getoutput(f"exiftool '{repaired}'")
        print(f"{Fore.CYAN}{exif_out}{Style.RESET_ALL}")
        collect_base64_from_text(exif_out)
        scan_text_for_flags(exif_out, "EXIF-AUTO")
    except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))

    analyze_strings_and_flags(repaired, args.format)

    if check_early_exit():
        scan_all_outputs_for_flags(repaired)
        return _build_result()  # Report will be printed in finally block

    # ═══════════════════════════════════════════════════════════
    # AUTO-DETECTION ENGINE (v5.1) — Content-Based Analysis
    # ═══════════════════════════════════════════════════════════
    
    # Read file content once for all detections
    try:
        file_content = repaired.read_text(encoding='utf-8', errors='ignore')
    except:
        file_content = repaired.read_bytes().decode('latin-1', errors='ignore')
    
    # 1. Encoding Maze Detection (Base32-heavy with specific pattern)
    if real_ext == 'txt':
        cleaned = re.sub(r'[\s\r\n\t]+', '', file_content)
        b32_chunks = re.findall(r'[A-Z2-7]{40,}', cleaned)
        if b32_chunks:
            full_b32 = ''.join(b32_chunks)
            if len(full_b32) > 100:
                # Verify it's actually Base32-encoded binary (not just text)
                try:
                    padded = full_b32 + '=' * ((8 - len(full_b32) % 8) % 8)
                    decoded_test = base64.b32decode(padded)
                    # Check if decoded looks like binary/string mix (encoding maze signature)
                    printable_ratio = sum(1 for b in decoded_test if 32 <= b <= 126) / len(decoded_test)
                    if 0.5 < printable_ratio < 0.95:  # Encoding maze typically has mix
                        print(f"\n{Fore.GREEN}[AUTO] 🎯 Encoding Maze detected!{Style.RESET_ALL}")
                        print(f"{Fore.CYAN}    • Base32 data: {len(full_b32)} chars{Style.RESET_ALL}")
                        print(f"{Fore.CYAN}    • Pattern: Base32 → Binary → BitReverse → Reverse → Base64{Style.RESET_ALL}")
                        result = solve_encoding_maze(full_b32)
                        if result:
                            scan_all_outputs_for_flags(repaired)
                            return _build_result()
                            return _build_result()
                except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
    
    # 2. Log File Detection (Apache/Nginx format)
    if real_ext in ['txt', 'log']:
        log_pattern = re.compile(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\s+-\s+-\s+\[.+\]\s+"(GET|POST|PUT|DELETE)')
        log_lines = [l for l in file_content.split('\n') if log_pattern.match(l)]
        if len(log_lines) > len(file_content.split('\n')) * 0.3:  # >30% match
            print(f"\n{Fore.GREEN}[AUTO]  Log file detected!{Style.RESET_ALL}")
            print(f"{Fore.CYAN}    • Format: Apache/Nginx access log{Style.RESET_ALL}")
            print(f"{Fore.CYAN}    • Log entries: {len(log_lines)}{Style.RESET_ALL}")
            analyze_log(repaired)
            scan_all_outputs_for_flags(repaired)
            return _build_result()
            return _build_result()
    
    # 3. Registry File Detection
    if real_ext == 'txt' or repaired.suffix.lower() == '.reg':
        if 'Windows Registry Editor' in file_content or '[HKEY_' in file_content:
            has_hex_values = bool(re.search(r'"[^"]+"\s*=\s*hex:[0-9a-fA-F,]+', file_content))
            print(f"\n{Fore.GREEN}[AUTO] 📋 Registry file detected!{Style.RESET_ALL}")
            if has_hex_values:
                print(f"{Fore.CYAN}    • Contains hex-encoded values (potential hidden data){Style.RESET_ALL}")
            analyze_registry(repaired)
            scan_all_outputs_for_flags(repaired)
            return _build_result()
            return _build_result()
    
    # 4. Crypto/Encoding Detection
    if real_ext == 'txt':
        # RSA parameters
        rsa_patterns = [r'N\s*[:=]\s*\d{10,}', r'modulus\s*[:=]\s*\d{10,}']
        has_rsa = any(re.search(p, file_content, re.IGNORECASE) for p in rsa_patterns)

        # Check for PEM RSA public key
        has_pem_rsa = 'BEGIN RSA PUBLIC KEY' in file_content or 'BEGIN PUBLIC KEY' in file_content

        # Ciphertext (large number)
        has_ciphertext = bool(re.search(r'\bc\s*[:=]\s*\d{10,}', file_content, re.IGNORECASE))

        # Hex-encoded data
        hex_chunks = re.findall(r'[0-9a-fA-F]{20,}', file_content)
        has_long_hex = any(len(c) > 40 for c in hex_chunks)

        # Ciphertext patterns (PREFIX{...})
        has_ciphertext_pattern = bool(re.search(r'\b[A-Z]{2,5}\{[A-Za-z0-9_]+\}', file_content))

        if has_rsa or has_pem_rsa or has_ciphertext:
            print(f"\n{Fore.GREEN}[AUTO] 🔒 RSA challenge detected!{Style.RESET_ALL}")
            if has_pem_rsa:
                print(f"{Fore.CYAN}    • PEM RSA public key format{Style.RESET_ALL}")

    # 5. Binary Digits Detection (file berisi 0 dan 1)
    # Cek semua file text-like (termasuk yang ekstensinya .bin tapi isinya ASCII 0/1)
    if real_ext in ['txt', 'bin', '', None] or not repaired.suffix:
        # Bersihkan whitespace dan cek apakah hanya berisi 0/1
        only_binary = re.sub(r'[\s\r\n\t]', '', file_content)
        if re.match(r'^[01]+$', only_binary) and len(only_binary) > 50:
            binary_ratio = len(only_binary) / max(len(file_content.strip()), 1)
            if binary_ratio > 0.9:  # >90% karakter adalah 0/1
                print(f"\n{Fore.GREEN}[AUTO] 🔢 Binary digits file detected!{Style.RESET_ALL}")
                print(f"{Fore.CYAN}    • Total bits: {len(only_binary)}{Style.RESET_ALL}")
                print(f"{Fore.CYAN}    • Kemungkinan: {len(only_binary)//8} karakter ASCII (8-bit){Style.RESET_ALL}")
                print(f"{Fore.CYAN}    • Atau: {len(only_binary)//7} karakter ASCII (7-bit){Style.RESET_ALL}")

                # Cek apakah format spaced binary (space-separated 8-bit tokens)
                tokens = file_content.strip().split()
                if tokens and all(re.match(r'^[01]{8}$', t) for t in tokens[:20]):
                    print(f"{Fore.GREEN}[AUTO] Spaced binary format (8-bit per token) detected!{Style.RESET_ALL}")
                    print(f"{Fore.CYAN}    • Tokens: {len(tokens)}{Style.RESET_ALL}")
                    # Langsung decode ke bytes dan coba render
                    try:
                        raw_bytes = bytes(int(t, 2) for t in tokens if re.match(r'^[01]{8}$', t))
                        print(f"{Fore.CYAN}    • Decoded bytes: {len(raw_bytes)}{Style.RESET_ALL}")
                        render_image_from_bytes(raw_bytes, repaired, label="spaced")
                    except Exception as e:
                        print(f"{Fore.YELLOW}[AUTO] Spaced binary decode gagal: {e}{Style.RESET_ALL}")

                analyze_binary_digits(repaired, forced_width=getattr(args, 'bin_width', None))
                scan_all_outputs_for_flags(repaired)
                return _build_result()
                return _build_result()

    # 6. Morse Code Detection
    if real_ext in ['txt', '']:
        morse_pattern_check = r'[.\-]{2,}[ \/][.\-]{2,}'
        if re.search(morse_pattern_check, file_content):
            morse_chars = re.findall(r'[.\- /]+', file_content)
            if morse_chars:
                total_morse = sum(len(c.strip()) for c in morse_chars)
                if total_morse > 20:  # minimal 20 karakter morse
                    print(f"\n{Fore.GREEN}[AUTO] 📡 Morse code detected!{Style.RESET_ALL}")
                    print(f"{Fore.CYAN}    • Morse characters: ~{total_morse}{Style.RESET_ALL}")
                    analyze_morse(repaired)
                    # Don't return here, continue with other analysis

    # 7. Decimal ASCII Detection
    if real_ext in ['txt', '']:
        decimal_check = r'\b([3-9][0-9]|1[0-1][0-9]|12[0-6])(\s+[3-9][0-9]|\s+1[0-1][0-9]|\s+12[0-6]){4,}'
        if re.search(decimal_check, file_content):
            print(f"\n{Fore.GREEN}[AUTO] 🔢 Decimal ASCII detected!{Style.RESET_ALL}")
            analyze_decimal_ascii(repaired)
            # Don't return here, continue with other analysis

        # 8. Zero-Width Character Detection (for all text files)
        zwc_patterns = ['\u200b', '\u200c', '\u200d', '\ufeff', '\u2060', '\u180e']
        has_zwc = any(zwc in file_content for zwc in zwc_patterns)
        if has_zwc:
            print(f"\n{Fore.GREEN}[AUTO] 🔤 Zero-width character steganography detected!{Style.RESET_ALL}")
            detect_hidden_unicode(file_content)
            # Don't return here, continue with other analysis

        if has_rsa:
            print(f"{Fore.CYAN}    • RSA parameters (N, e) found{Style.RESET_ALL}")
        if has_ciphertext:
            print(f"{Fore.CYAN}    • Ciphertext (c) found{Style.RESET_ALL}")
            
            # Multi-file RSA: combine N, e from one file with c from another
            # This is handled in analyze_crypto_file which collects from all files
            return analyze_crypto_file(repaired, args)
        
        if has_ciphertext_pattern:
            print(f"\n{Fore.GREEN}[AUTO] 🔒 Cryptography challenge detected!{Style.RESET_ALL}")
            print(f"{Fore.CYAN}    • Ciphertext pattern detected{Style.RESET_ALL}")
            return analyze_crypto_file(repaired, args)

        if has_long_hex:
            print(f"\n{Fore.GREEN}[AUTO] 🔐 Hex-encoded data detected!{Style.RESET_ALL}")
            print(f"{Fore.CYAN}    • Attempting hex decode and analysis...{Style.RESET_ALL}")
            # Try to decode hex and check for flag
            for chunk in hex_chunks:
                if len(chunk) % 2 == 0:
                    try:
                        decoded = bytes.fromhex(chunk).decode('utf-8', errors='ignore')
                        scan_text_for_flags(decoded, "HEX-DECODE")
                        if FLAG_FOUND:
                            scan_all_outputs_for_flags(repaired)
                            return _build_result()
                            return _build_result()
                    except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))

    # 5. Autorun/INF Detection
    if repaired.name.lower() in ['autorun.inf', 'autorun.ini'] or repaired.suffix.lower() in ['.inf', '.ini']:
        print(f"\n{Fore.GREEN}[AUTO] 💾 Autorun/INF file detected!{Style.RESET_ALL}")
        analyze_autorun(repaired)
        scan_all_outputs_for_flags(repaired)
        return _build_result()
        return _build_result()
    
    # 6. Disk Image Detection
    if repaired.suffix.lower() in ['.dd', '.img', '.raw', '.iso', '.vmdk', '.qcow2', '.vhd']:
        print(f"\n{Fore.GREEN}[AUTO] 💽 Disk image detected!{Style.RESET_ALL}")
        # Try to detect filesystem
        if "ntfs" in file_desc.lower() or "oem-id" in file_desc.lower():
            print(f"{Fore.CYAN}    • Filesystem: NTFS{Style.RESET_ALL}")
            analyze_ntfs_deleted(repaired)
        else:
            print(f"{Fore.CYAN}    • Running partition analysis...{Style.RESET_ALL}")
            analyze_disk_partitions(repaired)
        scan_all_outputs_for_flags(repaired)
        return _build_result()
        return _build_result()

    # 7. Memory Dump Detection
    if repaired.suffix.lower() in ['.raw', '.mem', '.dmp', '.vmem'] and 'ascii' not in file_desc.lower():
        print(f"\n{Fore.GREEN}[AUTO] 🧠 Memory dump detected!{Style.RESET_ALL}")
        analyze_memory_advanced(repaired)
        scan_all_outputs_for_flags(repaired)
        return _build_result()
        return _build_result()

    # If no auto-detection matched, proceed with standard analysis
    print(f"\n{Fore.YELLOW}[AUTO] No specific pattern detected. Running standard analysis...{Style.RESET_ALL}")

    if args.decode or args.extract or args.all or args.auto:
        auto_decode_and_extract(repaired)

    # ── Penentuan tipe
    is_image  =any(k in file_desc for k in ["image","jpeg","png","bitmap","gif"])
    is_archive=any(k in file_desc for k in ["archive","zip","rar","7-zip","tar"])
    is_exec   ="executable" in file_desc or "elf" in file_desc
    is_png    ="png" in file_desc
    is_jpg    ="jpeg" in file_desc or "jpg" in file_desc
    is_pcap   =("pcap" in file_desc or "capture" in file_desc
                or repaired.suffix.lower() in ['.pcap','.pcapng','.cap'])
    is_disk   =(repaired.suffix.lower() in ['.dd','.img','.raw','.iso','.vmdk','.qcow2','.vhd']
                or args.disk)
    is_evtlog =repaired.suffix.lower() in ['.evtx','.evt'] or args.windows
    is_reg    =repaired.suffix.lower() == '.reg' or args.reg
    is_log    =(repaired.suffix.lower() in ['.log','.txt','.access'] or args.log
                or "apache" in file_desc or "nginx" in file_desc)
    is_autorun=(repaired.name.lower() in ['autorun.inf','autorun.ini'] or
                repaired.suffix.lower() in ['.inf','.ini'] or args.autorun)
    is_pdf    =(real_ext == 'pdf' or repaired.suffix.lower() == '.pdf' or args.pdfcrack)
    is_zip    =(real_ext == 'zip' or is_archive or args.zipcrack)
    is_memdump=(repaired.suffix.lower() in ['.raw','.mem','.dmp','.vmem'] or args.volatility)
    is_wav    =(repaired.suffix.lower() in ['.wav'] or 'wave' in file_desc or 'wav' in file_desc)

    # ── CRYPTO MODE (v4.0+)
    if getattr(args, 'crypto', False) or getattr(args, 'encoding_chain', False):
        return analyze_crypto_file(repaired, args)

    # ── Deteksi disk image secara mendalam (NTFS/MBR/FAT)
    is_ntfs_disk = (
        real_ext == 'ntfs_disk' or
        "ntfs" in file_desc or
        "oem-id" in file_desc
    )
    is_mbr_disk = (
        "dos/mbr boot sector" in file_desc or
        "mbr" in file_desc or
        any(ind in file_desc for ind in DISK_INDICATORS)
    )
    # Memory dump: file .raw/.mem/.dmp + entropy sangat rendah (< 1.0)
    _raw_entropy = 0.0
    if repaired.suffix.lower() in ['.raw','.mem','.dmp','.vmem']:
        try:
            _sample = repaired.read_bytes()[:65536]
            _raw_entropy = calculate_entropy(_sample)
        except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))
    is_memory_dump = (
        is_memdump and
        (repaired.suffix.lower() in ['.raw','.mem','.dmp','.vmem']) and
        not is_ntfs_disk and not is_mbr_disk
    )

    if "gzip" in file_desc and (".dd" in file_desc or ".img" in file_desc):
        repaired=extract_compressed_disk(repaired); is_disk=True
    elif is_disk and ("gzip" in file_desc or "zip" in file_desc):
        repaired=extract_compressed_disk(repaired)

    # ── Tipe file khusus (registry, log, autorun, volatility)
    if is_reg:
        analyze_registry(repaired)
        scan_all_outputs_for_flags(repaired)
        return _build_result()

    if is_autorun:
        analyze_autorun(repaired)
        scan_all_outputs_for_flags(repaired)
        return _build_result()

    # ── MEMORY DUMP auto-route
    if is_memory_dump or args.volatility:
        print(f"{Fore.MAGENTA}[AUTO] Memory dump terdeteksi → memory analysis pipeline{Style.RESET_ALL}")
        # Strategi: strings scan dulu (cepat), baru volatility
        _memory_fallback_scan(repaired, repaired.parent / f"{repaired.stem}_memscan")
        if check_early_exit():
            scan_all_outputs_for_flags(repaired)
            return _build_result()
        # Lanjutkan ke volatility untuk analisis lebih dalam
        analyze_volatility(repaired, getattr(args,'vol_args',None))
        if not check_early_exit():
            analyze_memory_advanced(repaired)
        scan_all_outputs_for_flags(repaired)
        return _build_result()

    if args.volatility:
        analyze_volatility(repaired, getattr(args,'vol_args',None))
        scan_all_outputs_for_flags(repaired)
        return _build_result()

    # ── Manual flag override
    if hasattr(args, 'ntfs') and args.ntfs:
        print(f"{Fore.MAGENTA}[AUTO] --ntfs: NTFS recovery mode{Style.RESET_ALL}")
        analyze_ntfs_deleted(repaired)
        scan_all_outputs_for_flags(repaired)
        return _build_result()

    if hasattr(args, 'partition') and args.partition:
        print(f"{Fore.MAGENTA}[AUTO] --partition: Partition scan mode{Style.RESET_ALL}")
        analyze_disk_partitions(repaired)
        scan_all_outputs_for_flags(repaired)
        return _build_result()

    # ── DISK IMAGE ROUTING (NTFS / MBR / generic)
    if is_ntfs_disk or (is_disk and "ntfs" in file_desc):
        print(f"{Fore.MAGENTA}[AUTO] NTFS disk image terdeteksi → NTFS recovery pipeline{Style.RESET_ALL}")
        analyze_ntfs_deleted(repaired)
        if not check_early_exit():
            analyze_disk_partitions(repaired)
        scan_all_outputs_for_flags(repaired)
        return _build_result()

    if is_mbr_disk or (is_disk and "mbr" in file_desc):
        print(f"{Fore.MAGENTA}[AUTO] MBR disk image terdeteksi → partition analysis pipeline{Style.RESET_ALL}")
        analyze_disk_partitions(repaired)
        if not check_early_exit():
            analyze_ntfs_deleted(repaired)
        scan_all_outputs_for_flags(repaired)
        return _build_result()

    # ── QUICK MODE
    if args.quick:
        print(f"\n{Fore.MAGENTA}[QUICK-MODE] Ultra-fast{Style.RESET_ALL}")
        analyze_strings_and_flags(repaired,args.format)
        auto_decode_and_extract(repaired)
        if is_log: analyze_log(repaired)
        if is_autorun: analyze_autorun(repaired)
        if is_reg: analyze_registry(repaired)
        if is_image:
            if is_png and AVAILABLE_TOOLS.get('zsteg'): analyze_zsteg(repaired)
            if check_early_exit():
                scan_all_outputs_for_flags(repaired)
                return _build_result()
            if AVAILABLE_TOOLS.get('stegseek'): analyze_stegseek(repaired, getattr(args,'wordlist',None))
            if check_early_exit():
                scan_all_outputs_for_flags(repaired)
                return _build_result()
            if AVAILABLE_TOOLS.get('steghide'): analyze_steghide(repaired)
        if is_pcap:
            analyze_pcap_basic(repaired); search_pcap_flags(repaired)
            if not check_early_exit(): analyze_dns_tunneling(repaired)
            # Network protocol reconstruction (SPRINT 1)
            if args.ftp_recon: reconstruct_ftp_sessions(repaired)
            if args.email_recon: reconstruct_email_sessions(repaired)
            # Auto-detect FTP/SMTP in pcap
            if not args.quick:
                reconstruct_ftp_sessions(repaired)
                reconstruct_email_sessions(repaired)
        if is_zip:
            # Forensic analysis before cracking
            forensic_zip_analysis(repaired, args)
            if check_early_exit():
                scan_all_outputs_for_flags(repaired)
                return _build_result()
            crack_zip(repaired, getattr(args,'wordlist',None), args)
        scan_all_outputs_for_flags(repaired)
        return _build_result()

    # ── PCAP ONLY
    if args.pcap and is_pcap:
        analyze_pcap_full(repaired)
        scan_all_outputs_for_flags(repaired)
        return _build_result()

    # ── ALL / AUTO
    if args.all or args.auto:
        # Log analysis
        if is_log: analyze_log(repaired)
        if is_autorun: analyze_autorun(repaired)
        if is_reg: analyze_registry(repaired)
        if is_zip:
            # Forensic analysis before cracking
            forensic_zip_analysis(repaired, args)
            if check_early_exit():
                scan_all_outputs_for_flags(repaired)
                return _build_result()
            crack_zip(repaired, getattr(args,'wordlist',None), args)
        if is_image:
            analyze_image(repaired,deep=args.deep,alpha=args.alpha)
            analyze_graphicsmagick(repaired); analyze_exif_deep(repaired)
            # OSINT GPS extraction
            extract_gps_coordinates(repaired)
            detect_appended_data(repaired)  # Check for data after EOF
            analyze_steg_methods(repaired)
            if args.lsbextract or args.all: extract_lsb_data(repaired)
            if args.compare: compare_images(repaired,Path(args.compare))
            if is_png:
                analyze_zsteg(repaired); analyze_steghide(repaired)
                analyze_stegseek(repaired, getattr(args,'wordlist',None))
                analyze_pngcheck(repaired)
            if is_jpg:
                analyze_outguess(repaired); analyze_steghide(repaired)
                analyze_stegseek(repaired, getattr(args,'wordlist',None))
                analyze_jpseek(repaired)
            if args.remap or args.all: color_remapping(repaired)
        if is_archive:
            analyze_foremost(repaired, quick=args.auto and not args.all)
            if args.auto: analyze_with_binwalk(repaired)
        if is_pdf:
            if args.auto: crack_pdf(repaired, getattr(args,'wordlist',None))
        if args.bruteforce and is_image:
            wl=DEFAULT_WORDLIST
            if args.wordlist and Path(args.wordlist).exists():
                wl=Path(args.wordlist).read_text().splitlines()
            bruteforce_steghide(repaired,wl,args.delay,args.parallel)
        if is_disk or is_mbr_disk or is_ntfs_disk:
            analyze_disk_partitions(repaired)
            if not check_early_exit(): analyze_ntfs_deleted(repaired)
            if not check_early_exit(): analyze_disk_image(repaired)
        if is_memory_dump:
            _memory_fallback_scan(repaired, repaired.parent/f"{repaired.stem}_memscan")
            if not check_early_exit(): analyze_memory_advanced(repaired)
        if is_wav:
            analyze_wav_steganography(repaired)
        if is_evtlog: analyze_windows_event_logs(repaired)
        if is_pcap:
            analyze_pcap_full(repaired)
            if not check_early_exit(): analyze_dns_tunneling(repaired)
        
        # AUTO reversing for ELF binaries (NEW!)
        if is_exec:
            print(f"\n{Fore.MAGENTA}[AUTO] Executable detected → reversing analysis pipeline{Style.RESET_ALL}")
            reversing_pipeline(repaired, args)

    # ── SELECTIVE
    else:
        # Tipe-tipe khusus
        if is_log:   analyze_log(repaired)
        elif is_image:
            analyze_image(repaired,deep=args.deep,alpha=args.alpha)
            if args.exif:       analyze_exif_deep(repaired)
            detect_appended_data(repaired)  # Check for data after EOF
            if args.stegdetect: analyze_steg_methods(repaired)
            if args.lsbextract: extract_lsb_data(repaired)
            if args.compare:    compare_images(repaired,Path(args.compare))
            if args.lsb:        analyze_zsteg(repaired)
            if args.steghide:   analyze_steghide(repaired)
            if args.stegseek:   analyze_stegseek(repaired, getattr(args,'wordlist',None))
            if args.outguess:   analyze_outguess(repaired)
            if args.pngcheck:   analyze_pngcheck(repaired)
            if args.jpsteg:     analyze_jpseek(repaired)
            if args.remap:      color_remapping(repaired)
            if args.foremost:   analyze_foremost(repaired)
            if args.bruteforce:
                wl=DEFAULT_WORDLIST
                if args.wordlist and Path(args.wordlist).exists():
                    wl=Path(args.wordlist).read_text().splitlines()
                bruteforce_steghide(repaired,wl,args.delay,args.parallel)
        elif is_zip or is_archive:
            if args.forensic_zip:
                forensic_zip_analysis(repaired, args)
            if args.zipcrack: crack_zip(repaired, getattr(args,'wordlist',None), args)
            if not args.forensic_zip and not args.zipcrack:
                analyze_with_binwalk(repaired)
            if args.foremost: analyze_foremost(repaired)
        elif is_wav:
            analyze_wav_steganography(repaired)
            if args.spectrogram: generate_audio_spectrogram(repaired)
        elif is_image and (args.chi_square or args.stegdetect):
            if args.chi_square: chi_square_lsb_detection(repaired)
            if args.stegdetect: detect_stego_method(repaired)
        elif is_image and is_jpg and args.dct_analysis:
            analyze_dct_coefficients(repaired)
        elif args.mft or (is_ntfs_disk and args.deep):
            # Try to find and parse MFT from NTFS disk
            mft_path = repaired.parent / "$MFT"
            if mft_path.exists():
                parse_mft_direct(str(mft_path))
            else:
                print(f"{Fore.YELLOW}[MFT] $MFT file not found in {repaired.parent}{Style.RESET_ALL}")
        elif real_ext == 'pdf' or args.pdfcrack:
            if args.pdfcrack: crack_pdf(repaired, getattr(args,'wordlist',None))
            else: analyze_with_binwalk(repaired)
            if args.foremost: analyze_foremost(repaired)
        elif args.john or args.hashcat:
            # Hash cracking mode
            hash_type = getattr(args, 'hash_type', None)
            if args.john: crack_hash_john(repaired, getattr(args,'wordlist',None), hash_type)
            if args.hashcat: crack_hash_hashcat(repaired, getattr(args,'wordlist',None), hash_type)
        elif is_ntfs_disk or (is_disk and "ntfs" in file_desc):
            analyze_ntfs_deleted(repaired)
            if not check_early_exit(): analyze_disk_partitions(repaired)
        elif is_mbr_disk or is_disk:
            analyze_disk_partitions(repaired)
            if not check_early_exit(): analyze_ntfs_deleted(repaired)
        elif is_memory_dump:
            _memory_fallback_scan(repaired, repaired.parent/f"{repaired.stem}_memscan")
            if not check_early_exit(): analyze_memory_advanced(repaired)
        elif is_evtlog: analyze_windows_event_logs(repaired)

        # Reversing mode for binaries (explicit)
        if args.reversing:
            reversing_pipeline(repaired, args)
        
        # AUTO reversing for ELF binaries in default mode (NEW!)
        # This ensures binaries are analyzed even without --reversing flag
        if is_exec and not args.reversing and not args.crypto:
            print(f"\n{Fore.MAGENTA}[AUTO] Executable detected → running basic reversing analysis{Style.RESET_ALL}")
            reversing_pipeline(repaired, args)

        # Binary digits analysis (manual trigger)
        if args.binary:
            analyze_binary_digits(repaired, forced_width=getattr(args, 'bin_width', None))

        # Morse code analysis (manual trigger)
        if args.morse:
            analyze_morse(repaired)

        # Decimal ASCII analysis (manual trigger)
        if args.decimal:
            analyze_decimal_ascii(repaired)

        # Deobfuscation selektif
        if args.deobfuscate:
            try:
                text = repaired.read_text(errors='ignore')
                analyze_deobfuscation(text, "MANUAL")
            except Exception as e:\n        print(f"{Fore.YELLOW}[WARN] Exception in {function_name}: {e}{Style.RESET_ALL}")\n        log_tool("error", "?? Warning", str(e))

    scan_all_outputs_for_flags(repaired)
    return _build_result()
    return _build_result()

# ── Entry Point ───────────────────────────────

def main():
    print(f"{Fore.CYAN}{'='*55}\n   RAVEN v6.0.1 — CTF Multi-Category Toolkit\n{'='*55}{Style.RESET_ALL}")
    check_tool_availability()
    p=argparse.ArgumentParser(
        description="RAVEN v6.0.1 — CTF Multi-Category Toolkit",
        formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("files",nargs="*",help="File(s), wildcard, atau direktori")
    p.add_argument("-f","--format",default=None,help="Custom flag prefix (e.g. 'picoCTF{')")
    p.add_argument("--learn", nargs="?", const=True, default=None, metavar="CAT",
                     help="Display CTF learning guide. Categories: linux, python, encoding, networking, web, crypto, pwn, reverse, forensics. Use 'list' to show all.")
    p.add_argument("-v", "--verbose", action="store_true",
                     help="Show detailed analysis output (all findings, tool logs, and recommendations)")

    modes=p.add_argument_group("Modes")
    modes.add_argument("--quick",     action="store_true",help="Ultra-fast: strings+zsteg+stegseek+early exit")
    modes.add_argument("--auto",      action="store_true",help="Auto-detect semua tools")
    modes.add_argument("--all",       action="store_true",help="Paksa semua tool")
    modes.add_argument("--pcap",      action="store_true",help="Full PCAP analysis")
    modes.add_argument("--pcap-deep", action="store_true", dest="pcap_deep",
                     help="Exhaustive per-packet payload decode (B64/B32/hex/ROT13, reassemble flag)")
    modes.add_argument("--disk",      action="store_true",help="Disk image analysis")
    modes.add_argument("--windows",   action="store_true",help="Windows Event Log")
    modes.add_argument("--folder",    type=str,           help="Scan semua file di folder (fake ext detection)")

    ctf=p.add_argument_group("CTF Spesifik (v3.1+)")
    ctf.add_argument("--reg",        action="store_true",help="Windows Registry (.reg) analysis")
    ctf.add_argument("--log",        action="store_true",help="Web server log analysis (Apache/Nginx)")
    ctf.add_argument("--autorun",    action="store_true",help="Autorun.inf / INF file analysis")
    ctf.add_argument("--zipcrack",   action="store_true",help="Crack ZIP password (wordlist/rockyou)")
    ctf.add_argument("--forensic-zip", action="store_true", dest="forensic_zip",
                     help="Forensic analysis ZIP file (strings, context clues, smart password guessing)")
    ctf.add_argument("--mft",          action="store_true", help="NTFS MFT parser (deleted file recovery)")
    ctf.add_argument("--ftp-recon",    action="store_true", dest="ftp_recon",
                     help="FTP session reconstruction from PCAP")
    ctf.add_argument("--email-recon",  action="store_true", dest="email_recon",
                     help="Email (SMTP/POP3/IMAP) reconstruction from PCAP")
    ctf.add_argument("--gps-extract",  action="store_true", dest="gps_extract",
                     help="Extract GPS coordinates from EXIF metadata")
    ctf.add_argument("--pdfcrack",   action="store_true",help="Crack PDF password (pdfcrack)")
    ctf.add_argument("--john",       action="store_true",help="Crack hash dengan John the Ripper")
    ctf.add_argument("--hashcat",    action="store_true",help="Crack hash dengan Hashcat")
    ctf.add_argument("--hash-type",  type=str,           help="Hash type untuk john/hashcat (e.g., md5, sha256, sha512)")
    ctf.add_argument("--volatility", action="store_true",help="Memory forensics dengan Volatility 3")
    ctf.add_argument("--vol-plugin", type=str, dest="vol_args", nargs="+",
                     help="Tambahan plugin Volatility (e.g. windows.pslist)")
    ctf.add_argument("--memory",     action="store_true",
                     help="Advanced memory analysis (malfind, process dump, anomaly detection)")
    ctf.add_argument("--ntfs",       action="store_true",
                     help="NTFS deleted file recovery (fls/icat/strings/carving)")
    ctf.add_argument("--partition",  action="store_true",
                     help="Partition table analysis (MBR/GPT, hidden partition scan)")
    ctf.add_argument("--dns-tunnel", action="store_true", dest="dns_tunnel",
                     help="DNS tunneling detector + Base32/64/hex chunk decoder")
    ctf.add_argument("--deobfuscate",action="store_true",
                     help="Coba semua decode: reverse/ROT13/caesar/atbash/b64/hex/xor")
    ctf.add_argument("--binary",     action="store_true",
                     help="Force binary digits analysis (file berisi 0/1)")
    ctf.add_argument("--bin-width",  type=int, default=None,
                     help="Paksa lebar spesifik saat render gambar (e.g. 64)")
    ctf.add_argument("--render-image", action="store_true", dest="render_image",
                     help="Force binary → render image mode (CyberChef From Binary + Render Image)")
    ctf.add_argument("--bit-order",  choices=["msb","lsb"], default="msb", dest="bit_order",
                     help="Bit order saat decode binary: MSB-first (default) atau LSB-first")
    ctf.add_argument("--byte-len",   type=int, default=8, dest="byte_len",
                     help="Panjang tiap byte group (default: 8, bisa 7 untuk 7-bit ASCII)")
    ctf.add_argument("--morse",      action="store_true",
                     help="Decode Morse code dari file")
    ctf.add_argument("--decimal",    action="store_true",
                     help="Decode decimal ASCII dari file")
    ctf.add_argument("--reversing",  action="store_true",
                     help="Binary reversing (strings/objdump/readelf)")
    ctf.add_argument("--ghidra",     action="store_true",
                     help="Ghidra headless analysis (requires Ghidra)")
    ctf.add_argument("--unpack",     action="store_true",
                     help="Auto-unpack packed binaries (UPX)")
    ctf.add_argument("--skip-objdump", action="store_true",
                     help="Skip objdump analysis")
    ctf.add_argument("--skip-readelf", action="store_true",
                     help="Skip readelf analysis")

    crypto_grp=p.add_argument_group("Cryptography (v4.0)")
    crypto_grp.add_argument("--crypto",       action="store_true",
                     help="Auto-detect & attack: RSA (weak/Fermat/CommonMod/Bellcore), "
                          "Vigenere+acrostic, XOR KPA, Classic Cipher, Encoding Chain")
    crypto_grp.add_argument("--rsa",          action="store_true",
                     help="Paksa RSA attack saja (butuh --crypto)")
    crypto_grp.add_argument("--vigenere",     action="store_true",
                     help="Paksa Vigenere analysis (butuh --crypto)")
    crypto_grp.add_argument("--classic",      action="store_true",
                     help="Paksa Classic Cipher (Atbash/Caesar) brute force")
    crypto_grp.add_argument("--xor-plain",    type=str, dest="xor_plain", default="CTF{",
                     help="Known-plaintext prefix untuk XOR KPA (default: 'CTF{')")
    crypto_grp.add_argument("--xor-key",      type=str, dest="xor_key",
                     help="Decrypt XOR langsung dengan key ini")
    crypto_grp.add_argument("--crypto-key",   type=str, dest="crypto_key",
                     help="Kunci manual untuk Vigenere/Caesar")
    crypto_grp.add_argument("--encoding-chain", action="store_true", dest="encoding_chain",
                     help="Paksa encoding chain decoder (Base32/64/Binary/BitRev/Hex)")

    stego=p.add_argument_group("Steganografi")
    stego.add_argument("--lsb",       action="store_true",help="LSB (zsteg)")
    stego.add_argument("--steghide",  action="store_true",help="Steghide extraction")
    stego.add_argument("--stegseek",  action="store_true",help="Stegseek brute-force (rockyou.txt)")
    stego.add_argument("--outguess",  action="store_true",help="Outguess (JPEG)")
    stego.add_argument("--pngcheck",  action="store_true",help="Validasi PNG")
    stego.add_argument("--jpsteg",    action="store_true",help="JPEG steganalysis")
    stego.add_argument("--remap",     action="store_true",help="Color remapping")
    stego.add_argument("--exif",      action="store_true",help="Deep EXIF")
    stego.add_argument("--stegdetect",action="store_true",help="Deteksi metode stego")
    stego.add_argument("--lsbextract",action="store_true",help="Ekstrak raw LSB")
    stego.add_argument("--compare",   type=str,           help="Bandingkan dengan gambar kedua")
    stego.add_argument("--foremost",  action="store_true",help="File carving")
    stego.add_argument("--deep",      action="store_true",help="Semua 8 bit plane")
    stego.add_argument("--alpha",     action="store_true",help="Analisis alpha channel")
    
    # Advanced Steganography (SPRINT 1)
    stego.add_argument("--spectrogram", action="store_true",help="Audio spectrogram generator")
    stego.add_argument("--chi-square",  action="store_true", dest="chi_square", help="Chi-square LSB detection")
    stego.add_argument("--dct-analysis", action="store_true", dest="dct_analysis", help="JPEG DCT coefficient analysis")

    enc=p.add_argument_group("Encoding")
    enc.add_argument("--decode", action="store_true",help="Auto-decode base64/hex/binary")
    enc.add_argument("--extract",action="store_true",help="Ekstrak file tersembunyi")

    bf=p.add_argument_group("Brute Force")
    bf.add_argument("--bruteforce",action="store_true",help="Brute-force steghide")
    bf.add_argument("--wordlist",  type=str,           help="Custom wordlist")
    bf.add_argument("--delay",     type=float,default=0.1,help="Delay (default: 0.1)")
    bf.add_argument("--parallel",  type=int,  default=5,  help="Threads (default: 5)")

    args=p.parse_args()

    # ── Learning mode (no file needed)
    if args.learn is not None:
        try:
            from learning import run_learning_mode
            if args.learn is True:  # --learn without argument
                exit_code = run_learning_mode()
            else:  # --learn with category argument
                exit_code = run_learning_mode(args.learn)
            sys.exit(exit_code)
        except ImportError:
            print(f"{Fore.RED}[ERROR] Learning module not found.{Style.RESET_ALL}")
            print(f"{Fore.YELLOW}Please ensure engine/learning.py exists or run --install-global{Style.RESET_ALL}")
            sys.exit(1)

    # ── Mode khusus: folder scan
    if args.folder:
        folder = Path(args.folder)
        if not folder.is_dir():
            print(f"{Fore.RED}[!] Folder tidak valid: {args.folder}{Style.RESET_ALL}")
            return
        analyze_folder_magic(folder)
        print_final_report(args.folder)
        return

    # ── Dispatch flag baru yang tidak butuh file tipe khusus
    # (ditangani di process_file, tapi set args dulu)
    if hasattr(args, 'memory') and args.memory:
        args.volatility = True  # memory → aktifkan volatility path
    if hasattr(args, 'dns_tunnel') and args.dns_tunnel:
        args.pcap = True        # dns-tunnel → aktifkan pcap path

    if not args.files:
        p.print_help(); return

    input_paths=[]
    for pat in args.files:
        path=Path(pat)
        if path.is_file():    input_paths.append(path.resolve())
        elif path.is_dir():   input_paths.extend(path.rglob("*"))
        else:                 input_paths.extend(Path().glob(pat))
    files=[f for f in input_paths if f.is_file()]
    if not files: print(f"{Fore.RED}[!] Tidak ada file valid.{Style.RESET_ALL}"); return

    print(f"{Fore.CYAN}[INFO] {len(files)} file akan dianalisis.{Style.RESET_ALL}")
    
    # ── MULTI-FILE RSA DETECTION
    if len(files) >= 2:
        rsa_files = {}
        has_all_rsa_params = False
        
        print(f"\n{Fore.CYAN}[AUTO] Checking for multi-file RSA challenge...{Style.RESET_ALL}")
        
        for fp in files:
            try:
                text = fp.read_text(encoding='utf-8', errors='ignore')
                params = _parse_rsa_from_text(text)
                
                # Debug: show what was found
                print(f"{Fore.CYAN}[AUTO] Scanning {fp.name}...{Style.RESET_ALL}")
                
                # Additional check for PEM format with N and e
                if 'BEGIN RSA PUBLIC KEY' in text or 'BEGIN PUBLIC KEY' in text:
                    print(f"{Fore.CYAN}  → PEM format detected{Style.RESET_ALL}")
                    # Try to extract N and e from PEM-like format
                    n_match = re.search(r'[Nn]\s*[:=]\s*(\d{10,})', text)
                    e_match = re.search(r'\be\s*[:=]\s*(\d+)', text)
                    if n_match:
                        params['N'] = int(n_match.group(1))
                        print(f"{Fore.CYAN}  → Found N: {str(params['N'])[:40]}...{Style.RESET_ALL}")
                    if e_match:
                        params['e'] = int(e_match.group(1))
                        print(f"{Fore.CYAN}  → Found e: {params['e']}{Style.RESET_ALL}")
                
                # Check if file is just a large number (ciphertext without prefix)
                stripped = text.strip()
                # Remove all whitespace
                no_whitespace = re.sub(r'\s+', '', stripped)
                # Check if it's purely numeric
                if no_whitespace.isdigit() and len(no_whitespace) > 30:
                    # File contains only a large number - likely ciphertext
                    if 'c' not in params:
                        params['c'] = int(no_whitespace)
                        print(f"{Fore.CYAN}  → Detected ciphertext (large number: {len(no_whitespace)} digits){Style.RESET_ALL}")
                
                # Check if this file has any RSA parameters
                has_rsa_params = any(k in params for k in ['N', 'e', 'c'])
                if has_rsa_params:
                    rsa_files[fp.name] = params
                    rsa_keys = [k for k in ['N', 'e', 'c'] if k in params]
                    print(f"{Fore.GREEN}  ✓ RSA params found: {', '.join(rsa_keys)}{Style.RESET_ALL}")
                    if 'N' in params and 'e' in params and 'c' in params:
                        has_all_rsa_params = True
                else:
                    print(f"{Fore.YELLOW}  ✗ No RSA params found{Style.RESET_ALL}")
            except Exception as e:
                print(f"{Fore.YELLOW}[AUTO] Error reading {fp.name}: {e}{Style.RESET_ALL}")
        
        # If we have multiple RSA-related files but no single file has all params
        print(f"\n{Fore.CYAN}[AUTO] RSA detection summary: {len(rsa_files)} file(s) with RSA params{Style.RESET_ALL}")
        
        if len(rsa_files) >= 2 and not has_all_rsa_params:
            # Combine all params
            combined = {}
            for fname, params in rsa_files.items():
                combined.update(params)

            print(f"{Fore.CYAN}[AUTO] Combined params: N={'✓' if 'N' in combined else '✗'}, e={'✓' if 'e' in combined else '✗'}, c={'✓' if 'c' in combined else '✗'}{Style.RESET_ALL}")
            print(f"{Fore.CYAN}[AUTO] Extended params: e1={'✓' if 'e1' in combined else '✗'}, e2={'✓' if 'e2' in combined else '✗'}, c1={'✓' if 'c1' in combined else '✗'}, c2={'✓' if 'c2' in combined else '✗'}{Style.RESET_ALL}")
            print(f"{Fore.CYAN}[AUTO] Fault params: sig_faulty={'✓' if 'sig_faulty' in combined else '✗'}, msg={'✓' if 'msg' in combined else '✗'}{Style.RESET_ALL}")

            if 'N' in combined and 'e' in combined and 'c' in combined:
                print(f"\n{Fore.GREEN}[AUTO] 🔒 Multi-file RSA challenge detected!{Style.RESET_ALL}")
                print(f"{Fore.CYAN}    • Files: {', '.join(rsa_files.keys())}{Style.RESET_ALL}")

                # Build files_dict for solve_multi_file_rsa
                files_dict = {}
                for fname, params in rsa_files.items():
                    # Re-read file content
                    for fp in files:
                        if fp.name == fname:
                            try:
                                files_dict[fname] = fp.read_text(encoding='utf-8', errors='ignore')
                            except:
                                files_dict[fname] = fp.read_bytes().decode('latin-1', errors='ignore')
                            break

                # Check for oracle.py
                oracle_path = None
                for fp in files:
                    if fp.name.lower() == 'oracle.py':
                        oracle_path = str(fp)
                        break

                # Solve using multi-file RSA solver
                result = solve_multi_file_rsa(files_dict, oracle_path)
                if result:
                    print(f"\n{Fore.GREEN}{'='*70}{Style.RESET_ALL}")
                    print(f"{Fore.GREEN}✅ RSA challenge SOLVED!{Style.RESET_ALL}")
                    print(f"{Fore.GREEN}{'='*70}{Style.RESET_ALL}")
                    return
                else:
                    print(f"{Fore.YELLOW}[AUTO] Multi-file RSA failed, processing files individually...{Style.RESET_ALL}")
            else:
                print(f"{Fore.YELLOW}[AUTO] Incomplete RSA parameters for multi-file solving{Style.RESET_ALL}")

    all_flags=[]; all_exts=[]
    for filepath in files:
        try:
            result=process_file(filepath,args)
            if result:
                all_flags+=[f"[{filepath.name}] {f}" for f in result['flags']]
                all_exts+=[f"[{filepath.name}] {e}" for e in result['extractions']]
        except Exception as e:
            print(f"{Fore.RED}Gagal: {filepath}: {e}{Style.RESET_ALL}")
    if len(files)>1:
        print(f"\n{Fore.CYAN}{'='*70}\n📊 MASTER SUMMARY ({len(files)} files)\n{'='*70}{Style.RESET_ALL}")
        if all_flags:
            print(f"\n{Fore.GREEN}🚩 SEMUA FLAG ({len(all_flags)}):{Style.RESET_ALL}")
            for i,flag in enumerate(all_flags,1): print(f"{Fore.GREEN}  {i}. {flag}{Style.RESET_ALL}")
        if all_exts:
            print(f"\n{Fore.BLUE}📦 SEMUA EXTRACTIONS ({len(all_exts)}):{Style.RESET_ALL}")
            for item in all_exts: print(f"  • {item}")
        if not all_flags and not all_exts:
            print(f"\n{Fore.YELLOW}  ⚠  Tidak ada temuan signifikan.{Style.RESET_ALL}")
        print(f"\n{Fore.CYAN}{'='*70}{Style.RESET_ALL}")
    print(f"\n{Fore.GREEN}✅ SELESAI. Cek folder output untuk hasil lengkap.{Style.RESET_ALL}")

if __name__ == "__main__":
    main()


PYTHON_ENGINE
}



# ─────────────────────────────────────────────
# INTERACTIVE CATEGORY MENU (v6.0.1)
# ─────────────────────────────────────────────

# Store selected mode flags globally
declare -A MODE_FLAGS=(
    [forensics]="--disk --volatility --memory --foremost"
    [crypto]="--crypto"
    [web]="--log --pcap"
    [reversing]="--reversing --unpack"
    [pwn]=""
    [misc]="--decode --extract --deobfuscate"
)

# Global variable untuk menyimpan hasil menu (already defined above)
# MENU_SELECTED_FLAGS=""  # Already defined at line ~438
# MENU_TEMP_FILE already defined at line ~439

# Mode A: Native bash select menu (zero dependency)
show_category_menu_select() {
    local files=("$@")

    echo ""
    echo -e "${CYAN}  ╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}  ║     RAVEN v6.0.1 — Interactive Mode Selector  ║${NC}"
    echo -e "${CYAN}  ╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}  Files to analyze: ${#files[@]}${NC}"
    for f in "${files[@]}"; do
        echo -e "    • ${GREEN}$f${NC}"
    done
    echo ""
    echo -e "${YELLOW}  Pilih kategori analisis CTF (multi-select):${NC}"
    echo -e "${CYAN}  Pilih beberapa mode, lalu tekan '9' untuk konfirmasi & run${NC}"
    echo -e "${CYAN}  Tekan Ctrl+C untuk batal${NC}"
    echo ""

    local selected_flags=""
    local selected_count=0

    PS3="  ${GREEN}> Masukkan nomor [1-10]:${NC} "

    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  MODES YANG DIPILIH: (belum ada)                         ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    select choice in \
        "⚡ Auto-detect (biarkan RAVEN memilih)" \
        "🖼️  Steganografi (PNG/JPG/audio/LSB)" \
        "🔬 Forensik Digital (Disk/Memory/PCAP)" \
        "🔒 Kriptografi (RSA/XOR/Cipher klasik)" \
        "🌐 Web & Log Analysis (Apache/Nginx/HTTP)" \
        "🔧 Reversing (ELF/PE/bytecode)" \
        "💥 Pwn / Exploit (Buffer/ROP/heap)" \
        "🎭 Misc / Encode (B64/Hex/Brainfuck)" \
        "✅ Jalankan dengan pilihan di atas" \
        "❌ Keluar"
    do
        case $REPLY in
            1)
                if [[ "$selected_flags" != *"--auto"* ]]; then
                    selected_flags="$selected_flags --auto"
                    ((selected_count++))
                    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
                    echo -e "${GREEN}║  ✓ Auto-detect ditambahkan (${selected_count} mode dipilih)           ║${NC}"
                    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
                else
                    echo -e "${YELLOW}  ⚠ Auto-detect sudah dipilih${NC}"
                fi
                ;;
            2)
                if [[ "$selected_flags" != *"--lsb"* ]]; then
                    selected_flags="$selected_flags --lsb --steghide --stegseek --outguess --pngcheck --exif --stegdetect --lsbextract --remap --deep --alpha"
                    ((selected_count++))
                    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
                    echo -e "${GREEN}║  ✓ Steganografi ditambahkan (${selected_count} mode dipilih)          ║${NC}"
                    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
                else
                    echo -e "${YELLOW}  ⚠ Steganografi sudah dipilih${NC}"
                fi
                ;;
            3)
                if [[ "$selected_flags" != *"--disk"* ]]; then
                    selected_flags="$selected_flags --disk --volatility --memory --foremost"
                    ((selected_count++))
                    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
                    echo -e "${GREEN}║  ✓ Forensik Digital ditambahkan (${selected_count} mode dipilih)      ║${NC}"
                    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
                else
                    echo -e "${YELLOW}  ⚠ Forensik Digital sudah dipilih${NC}"
                fi
                ;;
            4)
                if [[ "$selected_flags" != *"--crypto"* ]]; then
                    selected_flags="$selected_flags --crypto"
                    ((selected_count++))
                    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
                    echo -e "${GREEN}║  ✓ Kriptografi ditambahkan (${selected_count} mode dipilih)           ║${NC}"
                    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
                else
                    echo -e "${YELLOW}  ⚠ Kriptografi sudah dipilih${NC}"
                fi
                ;;
            5)
                if [[ "$selected_flags" != *"--log"* ]]; then
                    selected_flags="$selected_flags --log --pcap"
                    ((selected_count++))
                    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
                    echo -e "${GREEN}║  ✓ Web & Log Analysis ditambahkan (${selected_count} mode dipilih)    ║${NC}"
                    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
                else
                    echo -e "${YELLOW}  ⚠ Web & Log Analysis sudah dipilih${NC}"
                fi
                ;;
            6)
                if [[ "$selected_flags" != *"--reversing"* ]]; then
                    selected_flags="$selected_flags --reversing --unpack"
                    ((selected_count++))
                    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
                    echo -e "${GREEN}║  ✓ Reversing ditambahkan (${selected_count} mode dipilih)             ║${NC}"
                    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
                else
                    echo -e "${YELLOW}  ⚠ Reversing sudah dipilih${NC}"
                fi
                ;;
            7)
                echo -e "${YELLOW}  ⚠ Mode Pwn/Exploit masih dalam pengembangan${NC}"
                ;;
            8)
                if [[ "$selected_flags" != *"--decode"* ]]; then
                    selected_flags="$selected_flags --decode --extract --deobfuscate"
                    ((selected_count++))
                    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
                    echo -e "${GREEN}║  ✓ Misc / Encode ditambahkan (${selected_count} mode dipilih)         ║${NC}"
                    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
                else
                    echo -e "${YELLOW}  ⚠ Misc / Encode sudah dipilih${NC}"
                fi
                ;;
            9)
                if [[ $selected_count -eq 0 ]]; then
                    echo -e "${RED}  ✖ Belum ada mode dipilih! Silakan pilih minimal 1 mode.${NC}"
                else
                    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
                    echo -e "${GREEN}║  ✓ Menjalankan dengan ${selected_count} mode...                         ║${NC}"
                    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
                    MENU_SELECTED_FLAGS="$selected_flags"
                    break  # Keluar dari select loop
                fi
                ;;
            10)
                echo -e "${CYAN}  Keluar dari RAVEN${NC}"
                MENU_SELECTED_FLAGS=""
                break  # Keluar dari select loop
                ;;
            *)
                echo -e "${RED}  ✖ Pilihan tidak valid. Masukkan nomor 1-10.${NC}"
                ;;
        esac
        echo ""
    done
    
    # Check if we have selected flags after loop exits
    if [[ -n "$MENU_SELECTED_FLAGS" ]]; then
        return 0
    else
        return 1
    fi
}

# Mode B: whiptail TUI (checkbox + multi-select)
show_category_menu_whiptail() {
    local files=("$@")

    local file_list=""
    for f in "${files[@]}"; do
        file_list+="$f "
    done

    # Use checklist for multi-select
    local choices
    choices=$(whiptail --title "RAVEN v6.0.1 — Multi-Select Mode" \
        --backtitle "CTF Multi-Category Toolkit | Space: select | Enter: confirm" \
        --checklist "\nFiles: $file_list\nPilih beberapa mode (Space untuk pilih):" 22 78 9 \
        "auto" "⚡ Auto-detect" ON \
        "stego" "🖼️  Steganografi" OFF \
        "forensics" "🔬 Forensik Digital" OFF \
        "crypto" "🔒 Kriptografi" OFF \
        "web" "🌐 Web & Log Analysis" OFF \
        "reversing" "🔧 Reversing" OFF \
        "pwn" "💥 Pwn/Exploit (WIP)" OFF \
        "misc" "🎭 Misc/Encode" OFF \
        3>&1 1>&2 2>&3)

    local exit_status=$?
    
    # whiptail returns 0 when OK is pressed, even with default selection
    if [[ $exit_status -ne 0 ]]; then
        MENU_SELECTED_FLAGS=""
        return 1
    fi

    # Parse selected choices
    local flags=""
    for choice in $choices; do
        # Remove quotes if present
        choice="${choice//\"/}"
        
        case $choice in
            auto) flags="$flags --auto" ;;
            stego) flags="$flags --lsb --steghide --stegseek --outguess --pngcheck --exif --stegdetect --lsbextract --remap --deep --alpha" ;;
            forensics) flags="$flags --disk --volatility --memory --foremost" ;;
            crypto) flags="$flags --crypto" ;;
            web) flags="$flags --log --pcap" ;;
            reversing) flags="$flags --reversing --unpack" ;;
            pwn) ;; # Skip, not implemented
            misc) flags="$flags --decode --extract --deobfuscate" ;;
            ai) ;; # Skip, not implemented
        esac
    done

    if [[ -z "$flags" ]]; then
        MENU_SELECTED_FLAGS=""
        return 1
    fi

    MENU_SELECTED_FLAGS="$flags"
    return 0
}

# Mode C: fzf fuzzy finder (power user)
show_category_menu_fzf() {
    local files=("$@")

    echo -e "${CYAN}  ╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}  ║     RAVEN v6.0.1 — FZF Multi-Select Mode       ║${NC}"
    echo -e "${CYAN}  ╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}  Files to analyze: ${#files[@]}${NC}"
    for f in "${files[@]}"; do
        echo -e "    • ${GREEN}$f${NC}"
    done
    echo ""
    echo -e "${CYAN}  Tekan Tab untuk multi-select, Enter untuk konfirmasi${NC}"
    echo ""

    local options=(
        "⚡ auto:Auto-detect mode"
        "🖼️  steganografi:PNG/JPG/audio/LSB"
        "🔬 forensics:Disk/Memory/PCAP"
        "🔒 crypto:RSA/XOR/Cipher"
        "🌐 web:Apache/Nginx/HTTP"
        "🔧 reversing:ELF/PE/bytecode"
        "💥 pwn:Buffer/ROP/heap"
        "🎭 misc:B64/Hex/Brainfuck"
    )

    local choices
    choices=$(printf "%s\n" "${options[@]}" | fzf --multi --height 60% \
        --prompt="> Pilih mode (Tab untuk select): " \
        --preview="echo {}" \
        --preview-window=down:1 \
        --border \
        --ansi)

    if [[ -z "$choices" ]]; then
        MENU_SELECTED_FLAGS=""
        return 1
    fi

    # Parse selected choices
    local flags=""
    while IFS= read -r choice; do
        [[ -z "$choice" ]] && continue
        
        local mode="${choice%%:*}"
        
        case $mode in
            *"auto"*) flags="$flags --auto" ;;
            *"steganografi"*) flags="$flags --lsb --steghide --stegseek --outguess --pngcheck --exif --stegdetect --lsbextract --remap --deep --alpha" ;;
            *"forensics"*) flags="$flags --disk --volatility --memory --foremost" ;;
            *"crypto"*) flags="$flags --crypto" ;;
            *"web"*) flags="$flags --log --pcap" ;;
            *"reversing"*) flags="$flags --reversing --unpack" ;;
            *"pwn"*) warn "Mode Pwn/Exploit masih dalam pengembangan" ;;
            *"misc"*) flags="$flags --decode --extract --deobfuscate" ;;
        esac
    done <<< "$choices"

    if [[ -z "$flags" ]]; then
        MENU_SELECTED_FLAGS=""
        return 1
    fi

    MENU_SELECTED_FLAGS="$flags"
    return 0
}

# Main menu dispatcher
show_category_menu() {
    local files=("$@")

    # Detect best available TUI
    local tui_type
    tui_type=$(detect_tui_support)

    case $tui_type in
        "fzf")
            show_category_menu_fzf "${files[@]}" || return 1
            ;;
        "whiptail")
            show_category_menu_whiptail "${files[@]}" || return 1
            ;;
        *)
            show_category_menu_select "${files[@]}" || return 1
            ;;
    esac

    # Return selected flags via global variable
    if [[ -n "$MENU_SELECTED_FLAGS" ]]; then
        return 0
    else
        return 1
    fi
}

# ─────────────────────────────────────────────
# LEARN MODE HANDLER
# ─────────────────────────────────────────────
handle_learn_mode() {
    local learn_args=("$@")
    local category=""
    
    # Extract category if provided
    for arg in "${learn_args[@]}"; do
        if [[ "$arg" != "--learn" ]]; then
            category="$arg"
            break
        fi
    done
    
    # Call Python learning module
    local py
    py=$(check_python) || die "Python 3.8+ tidak ditemukan."
    
    # Setup venv if needed
    setup_venv "$py" 2>/dev/null || true
    
    # Run learning module
    if [[ -n "$category" ]]; then
        "$VENV_DIR/bin/python" -c "
import sys
sys.path.insert(0, '$(dirname "$PYTHON_INLINE")')
sys.path.insert(0, '$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/engine')

try:
    from learning import run_learning_mode
    exit_code = run_learning_mode('$category')
    sys.exit(exit_code)
except ImportError:
    # Fallback: try from RAVEN_HOME
    import os
    raven_home = os.path.expanduser('~/.raven')
    sys.path.insert(0, os.path.join(raven_home, 'engine'))
    try:
        from learning import run_learning_mode
        exit_code = run_learning_mode('$category')
        sys.exit(exit_code)
    except:
        print('Learning module not found. Please run --install-global first.')
        sys.exit(1)
"
    else
        "$VENV_DIR/bin/python" -c "
import sys
sys.path.insert(0, '$(dirname "$PYTHON_INLINE")')
sys.path.insert(0, '$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/engine')

try:
    from learning import run_learning_mode
    exit_code = run_learning_mode()
    sys.exit(exit_code)
except ImportError:
    # Fallback: try from RAVEN_HOME
    import os
    raven_home = os.path.expanduser('~/.raven')
    sys.path.insert(0, os.path.join(raven_home, 'engine'))
    try:
        from learning import run_learning_mode
        exit_code = run_learning_mode()
        sys.exit(exit_code)
    except:
        print('Learning module not found. Please run --install-global first.')
        sys.exit(1)
"
    fi
}


# ─────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────
main() {
    banner

    for arg in "$@"; do
        case "$arg" in
            --install)         install_tools ;;
            --update)          update_global ;;
            --install-global)  install_global ;;
            --uninstall)       uninstall_global ;;
            --learn)           handle_learn_mode "$@" ; exit 0 ;;
            -h|--help)         usage; exit 0 ;;
        esac
    done

    if [[ $# -eq 0 ]]; then usage; exit 0; fi

    # Check if --interactive flag is present (or default to interactive mode)
    local interactive_mode=0
    local python_args=()
    
    for arg in "$@"; do
        if [[ "$arg" == "--interactive" ]]; then
            interactive_mode=1
        elif [[ "$arg" != "--auto" && "$arg" != "--quick" && "$arg" != "--all" ]]; then
            # Collect file arguments for menu display
            if [[ -f "$arg" || -d "$arg" ]]; then
                python_args+=("$arg")
            fi
        fi
    done
    
    # If no specific mode flag, default to interactive
    local has_mode_flag=0
    for arg in "$@"; do
        case "$arg" in
            --auto|--quick|--all|--pcap|--pcap-deep|--disk|--windows|--crypto|--reg|--log|--autorun|\
            --zipcrack|--pdfcrack|--john|--hashcat|--volatility|--deobfuscate|--reversing|\
            --ghidra|--unpack|--binary|--render-image|--morse|--decimal)
                has_mode_flag=1
                break
                ;;
        esac
    done
    
    # Show interactive menu if no mode flag specified
    if [[ $has_mode_flag -eq 0 && ${#python_args[@]} -gt 0 ]]; then
        info "No specific mode selected. Opening interactive menu..."
        echo ""
        
        if show_category_menu "${python_args[@]}"; then
            # Prepend selected flags to python args
            python_args=($MENU_SELECTED_FLAGS "${python_args[@]}")
            success "Mode selected. Starting analysis..."
        else
            info "Menu cancelled. Exiting."
            exit 0
        fi
    fi

    local py
    py=$(check_python) || die "Python 3.8+ tidak ditemukan. Install: sudo apt install python3"
    info "Python: $py ($(${py} --version 2>&1))"

    for arg in "$@"; do
        if [[ "$arg" == "--update-deps" ]]; then
            [[ -d "$VENV_DIR" ]] && rm -rf "$VENV_DIR"
            info "Venv di $RAVEN_HOME dihapus, akan dibuat ulang..."
            break
        fi
    done

    setup_venv "$py"
    check_system_tools

    # Tulis Python engine ke file temp
    write_python_engine
    chmod +x "$PYTHON_INLINE"

    # Filter flag milik shell sebelum dikirim ke Python
    local final_python_args=()
    local _shell_flags=(--install --update --install-global --uninstall --update-deps -h --help --interactive)
    for arg in "${python_args[@]}"; do
        local _skip=0
        for _sf in "${_shell_flags[@]}"; do
            [[ "$arg" == "$_sf" ]] && _skip=1 && break
        done
        [[ $_skip -eq 0 ]] && final_python_args+=("$arg")
    done

    echo ""
    info "Menjalankan RAVEN..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    python "$PYTHON_INLINE" "${final_python_args[@]}"

    # Bersihkan file engine temp (opsional, bisa di-comment kalau ingin debug)
    # rm -f "$PYTHON_INLINE"
}

main "$@"

