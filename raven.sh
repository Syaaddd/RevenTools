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
           CTF Multi-Category Toolkit v5.0  — by Syaaddd
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
  --disk           Disk image analysis
  --windows        Windows Event Log forensics
  --folder DIR     Scan semua file di folder (fake extension detection)

${BOLD}CTF Spesifik (v3.0+):${NC}
  --reg            Windows Registry (.reg) — decode hex: values
  --log            Web server log analysis (Apache/Nginx) — IP, attack, flag
  --autorun        Autorun.inf / INF file — reverse, ROT13, caesar, b64
  --zipcrack       Crack ZIP password (wordlist / rockyou.txt)
  --pdfcrack       Crack PDF password (pdfcrack + wordlist)
  --john           Crack hash dengan John the Ripper
  --hashcat        Crack hash dengan Hashcat
  --hash-type STR  Hash type untuk john/hashcat (md5, sha256, sha512, dll)
  --volatility     Memory forensics via Volatility 3
  --vol-plugin P   Plugin Volatility tambahan (e.g. windows.cmdline)
  --deobfuscate    Coba semua decode: reverse/ROT13/caesar/atbash/b64/hex
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

${BOLD}Encoding:${NC}
  --decode         Auto-decode base64 / hex / binary
  --extract        Ekstrak file tersembunyi dari encoded text

${BOLD}Brute Force:${NC}
  --bruteforce     Brute-force steghide (wordlist default/custom)
  --wordlist FILE  Custom wordlist (default: rockyou.txt)
  --delay SECS     Delay antar attempt (default: 0.1)
  --parallel N     Jumlah thread (default: 5)

${BOLD}Misc:${NC}
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
  ./raven.sh evidence.zip --zipcrack      # Crack ZIP password
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

    # Pre-setup venv sekarang juga
    local py
    py=$(check_python) || die "Python 3.8+ tidak ditemukan."
    setup_venv "$py"
    write_python_engine

    success "RAVEN terinstall secara global!"
    echo ""
    echo -e "  ${GREEN}Sekarang kamu bisa jalankan dari mana saja:${NC}"
    echo -e "  ${BOLD}  raven image.png --auto${NC}"
    echo -e "  ${BOLD}  raven access.log --log${NC}"
    echo -e "  ${BOLD}  raven --folder ./challenge/${NC}"
    echo ""
    echo -e "  ${CYAN}Data tersimpan di: $RAVEN_HOME${NC}"
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
# TULIS PYTHON ENGINE KE FILE TEMP
# ─────────────────────────────────────────────

# ─────────────────────────────────────────────
# TULIS PYTHON ENGINE KE FILE TEMP
# ─────────────────────────────────────────────
write_python_engine() {
    cat > "$PYTHON_INLINE" << 'PYTHON_ENGINE'
#!/usr/bin/env python3
"""RAVEN v5.0 — Python Engine (auto-generated by raven.sh)
Tambahan v3.1: registry, log analysis, autorun, zip crack, folder scan,
               volatility wrapper, deobfuscation (reverse/ROT13/caesar/atbash)
Tambahan v4.0: --crypto mode — RSA attacks (weak prime/Fermat/Common-Modulus/Bellcore-CRT),
               Vigenere+acrostic solver, XOR multi-byte KPA, AES-CBC Padding Oracle,
               Classic cipher (Atbash+Caesar auto), Encoding chain decoder,
               Number theory brute (perfect square / constraint solver)
Tambahan v5.0: --reversing mode — Binary analysis (strings/objdump/readelf/Ghidra),
               packer detection (UPX), auto-unpacker, interactive menu system
"""

import subprocess, argparse, os, re, base64, shutil, math, time, string, hashlib, struct
from pathlib import Path
from colorama import Fore, Style, init
from concurrent.futures import ThreadPoolExecutor, as_completed
from threading import Lock

try:
    from PIL import Image
    import numpy as np
    HAS_PIL = True
except ImportError:
    HAS_PIL = False

init(autoreset=True)

# ── Globals ──────────────────────────────────
AVAILABLE_TOOLS  = {}
FLAG_FOUND       = False
FLAG_LOCK        = Lock()
flag_summary     = []
base64_collector = []
found_flags_set  = set()   # deduplikasi flag, cegah print berulang
tool_log         = []      # log setiap tool yang dijalankan: (tool, status, hasil)

DEFAULT_WORDLIST = [
    "password","123456","12345678","123456789","flag","ctf","steg","hack","test",
    "key","secret","admin","root","user","pass","letmein","welcome","monkey",
    "dragon","master","hello","shadow","sunshine","princess","football","baseball",
    "soccer","password1","password123","qwerty","abc123","iloveyou","admin123",
    "666666","888888","000000","111111","222222","333333","444444","555555",
    "777777","999999","aaaaaa","bbbbbb","cccccc","dddddd","eeeeee","ffffff",
]

ROCKYOU_PATHS = [
    "/usr/share/wordlists/rockyou.txt",
    "/opt/rockyou.txt",
    "/usr/share/wordlists/rockyou.txt.gz",
]

COMMON_FLAG_PATTERNS = [
    r'picoCTF\{[^}]+\}',
    r'CTF\{[^}]+\}',
    r'flag\{[^}]+\}',
    r'FLAG\{[^}]+\}',
    r'REDLIMIT\{[^}]+\}',
    r'[A-Za-z0-9_]{3,}\{[^}]{3,}\}',
]

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
    except: pass
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
    except: pass

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
    except: pass

    # Reverse + Base64
    try:
        rb64 = decode_base64(s[::-1])
        if rb64: results['reverse_then_b64'] = rb64
    except: pass

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
                # Coba decode sebagai UTF-16LE (Windows default)
                try:
                    decoded = decoded_bytes.decode('utf-16-le', errors='ignore').strip('\x00')
                except:
                    decoded = decoded_bytes.decode('utf-8', errors='ignore')

                if decoded.strip():
                    print(f"{Fore.CYAN}  [{name}] hex → \"{decoded}\"{Style.RESET_ALL}")
                    scan_text_for_flags(decoded, "REGISTRY-HEX")
                    collect_base64_from_text(decoded)
                    (out_dir / f"hex_{name.replace(' ','_')}.txt").write_text(
                        f"Name: {name}\nHex: {clean}\nDecoded: {decoded}\n")
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

        # Analisis per-IP mencurigakan
        if len(sorted_ips) > 1:
            attacker_ip = sorted_ips[0][0]
            attacker_lines = [l for l in lines if l.startswith(attacker_ip)]
            print(f"\n{Fore.YELLOW}[LOG] Aktivitas IP teratas ({attacker_ip}): {len(attacker_lines)} requests{Style.RESET_ALL}")
            (out_dir / f"ip_{attacker_ip.replace('.','_')}.txt").write_text('\n'.join(attacker_lines))

            # Scan flag di requests attacker
            for line in attacker_lines:
                scan_text_for_flags(line, "LOG-IP")

    # ── HTTP status analysis
    status_counts = {}
    status_pat = re.compile(r'" (\d{3}) ')
    for line in lines:
        m = status_pat.search(line)
        if m:
            s = m.group(1)
            status_counts[s] = status_counts.get(s, 0) + 1
    if status_counts:
        print(f"\n{Fore.CYAN}[LOG] HTTP Status Distribution:{Style.RESET_ALL}")
        for code, cnt in sorted(status_counts.items()):
            color = Fore.GREEN if code.startswith('2') else Fore.YELLOW if code.startswith('3') else Fore.RED
            print(f"  {color}{code}: {cnt} requests{Style.RESET_ALL}")

    # ── Attack pattern detection
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
    for attack, pat in attack_sigs.items():
        matches = re.findall(pat, content, re.IGNORECASE)
        if matches:
            print(f"  {Fore.RED}[!] {attack}: {len(matches)} hit(s){Style.RESET_ALL}")
            add_to_summary("LOG-ATTACK", f"{attack}: {len(matches)} hits")

    # ── 200 OK requests — mungkin berhasil diakses
    ok_lines = [l for l in lines if '" 200 ' in l]
    if ok_lines:
        print(f"\n{Fore.CYAN}[LOG] Requests yang berhasil (200 OK): {len(ok_lines)}{Style.RESET_ALL}")
        for line in ok_lines[:20]:
            print(f"  → {line[:120]}")
            scan_text_for_flags(line, "LOG-200")
        (out_dir / "200_ok_requests.txt").write_text('\n'.join(ok_lines))

    # ── Timeline
    time_pat = re.compile(r'\[(\d{2}/\w+/\d{4}:\d{2}:\d{2}:\d{2})')
    timestamps = [time_pat.search(l).group(1) for l in lines if time_pat.search(l)]
    if timestamps:
        print(f"\n{Fore.CYAN}[LOG] Timeline: {timestamps[0]} → {timestamps[-1]}{Style.RESET_ALL}")
        add_to_summary("LOG-TIMELINE", f"{timestamps[0]} → {timestamps[-1]}")

    (out_dir / "full_analysis.txt").write_text(
        f"Log Analysis: {filepath.name}\n"
        f"Total lines: {len(lines)}\n"
        f"IPs: {len(ip_counts)}\n"
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

# ── 5. ZIP PASSWORD CRACK ─────────────────────

def crack_zip(filepath, wordlist_path=None):
    """Coba buka ZIP: tanpa password → password kosong → wordlist → fcrackzip"""
    print(f"{Fore.GREEN}[ZIP-CRACK] Analisis ZIP terproteksi...{Style.RESET_ALL}")
    out_dir = filepath.parent / f"{filepath.stem}_zipcrack"
    out_dir.mkdir(exist_ok=True)

    # ── Step 1: Coba tanpa password dulu
    print(f"{Fore.CYAN}[ZIP-CRACK] Step 1: Coba ekstrak tanpa password...{Style.RESET_ALL}")
    result = subprocess.run(
        ["unzip", "-o", str(filepath), "-d", str(out_dir)],
        capture_output=True, text=True, timeout=30)
    if result.returncode == 0:
        print(f"{Fore.GREEN}[ZIP-CRACK] Berhasil ekstrak tanpa password!{Style.RESET_ALL}")
        _scan_extracted_dir(out_dir, "ZIP-NOPASS")
        return

    # ── Step 2: Coba password kosong ""
    result2 = subprocess.run(
        ["unzip", "-o", "-P", "", str(filepath), "-d", str(out_dir)],
        capture_output=True, text=True, timeout=15)
    if result2.returncode == 0:
        print(f"{Fore.GREEN}[ZIP-CRACK] Berhasil dengan password kosong!{Style.RESET_ALL}")
        _scan_extracted_dir(out_dir, "ZIP-EMPTYPASS")
        return

    # ── Step 3: Coba wordlist
    wl_lines = DEFAULT_WORDLIST[:]
    if wordlist_path and Path(wordlist_path).exists():
        wl_lines = Path(wordlist_path).read_text(errors='ignore').splitlines()[:50000]
        print(f"{Fore.CYAN}[ZIP-CRACK] Wordlist custom: {len(wl_lines)} kata{Style.RESET_ALL}")
    else:
        # Cari rockyou.txt
        for rp in ROCKYOU_PATHS:
            if Path(rp).exists():
                wl_lines = open(rp, errors='ignore').read().splitlines()[:100000]
                print(f"{Fore.CYAN}[ZIP-CRACK] Rockyou: {len(wl_lines)} kata{Style.RESET_ALL}")
                break

    # ── Step 3a: fcrackzip (jauh lebih cepat)
    if AVAILABLE_TOOLS.get('fcrackzip') and wordlist_path:
        print(f"{Fore.CYAN}[ZIP-CRACK] fcrackzip dengan wordlist...{Style.RESET_ALL}")
        try:
            wl = wordlist_path or next((p for p in ROCKYOU_PATHS if Path(p).exists()), None)
            if wl:
                result3 = subprocess.run(
                    ["fcrackzip", "-v", "-u", "-D", "-p", wl, str(filepath)],
                    capture_output=True, text=True, timeout=120)
                output = result3.stdout + result3.stderr
                pw_match = re.search(r'PASSWORD FOUND.*?:(.*)', output, re.IGNORECASE)
                if pw_match:
                    pw = pw_match.group(1).strip().strip("'\"")
                    print(f"{Fore.GREEN}[ZIP-CRACK] Password: '{pw}'{Style.RESET_ALL}")
                    add_to_summary("ZIP-PASSWORD", f"Password: '{pw}'")
                    subprocess.run(["unzip","-o","-P",pw,str(filepath),"-d",str(out_dir)],
                                   capture_output=True, timeout=30)
                    _scan_extracted_dir(out_dir, "ZIP-CRACK")
                    return
        except Exception as e:
            print(f"{Fore.YELLOW}[ZIP-CRACK] fcrackzip gagal: {e}{Style.RESET_ALL}")

    # ── Step 3b: Manual brute-force dengan unzip
    print(f"{Fore.CYAN}[ZIP-CRACK] Manual brute-force: {len(wl_lines)} kata...{Style.RESET_ALL}")
    found_pw = None

    def try_zip_pw(pw):
        try:
            r = subprocess.run(
                ["unzip", "-o", "-P", pw, str(filepath), "-d", str(out_dir)],
                capture_output=True, text=True, timeout=10)
            if r.returncode == 0: return pw
        except: pass
        return None

    # Paralel dengan ThreadPoolExecutor
    with ThreadPoolExecutor(max_workers=8) as ex:
        futures = {ex.submit(try_zip_pw, pw): pw for pw in wl_lines[:5000]}
        for future in as_completed(futures):
            if found_pw: break
            res = future.result()
            if res:
                found_pw = res
                print(f"{Fore.GREEN}[ZIP-CRACK] Password ditemukan: '{found_pw}'{Style.RESET_ALL}")
                add_to_summary("ZIP-PASSWORD", f"Password: '{found_pw}'")
                _scan_extracted_dir(out_dir, "ZIP-CRACK")
                break

    if not found_pw:
        print(f"{Fore.YELLOW}[ZIP-CRACK] Password tidak ditemukan dalam wordlist.{Style.RESET_ALL}")
        log_tool("zipcrack", "⬜ Nothing", "password tidak ditemukan dalam wordlist")

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
                except: pass
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
    except: pass
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
                    except: pass

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
    except: pass

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
    log_tool("strings", "running")
    found_before = len(found_flags_set)
    try:
        ft=subprocess.getoutput(f"file -b '{filepath}'").strip()
        print(f"{Fore.CYAN}[BASIC] Type: {ft}{Style.RESET_ALL}")
        utf8=subprocess.getoutput(f"strings '{filepath}'")
        utf16=subprocess.getoutput(f"strings -e l '{filepath}'")
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
                if nested.is_file(): analyze_strings_and_flags(nested)
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
        except: pass
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
            print(f"  {Fore.GREEN}{Fore.BRIGHT}{i}. {flag}{Style.RESET_ALL}")
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
    except: pass
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
    except: pass
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
        except: pass
    return None

def decode_url_encoding(candidate):
    """Decode URL percent-encoding"""
    try:
        from urllib.parse import unquote
        decoded = unquote(candidate)
        if decoded != candidate and len(decoded) > 3:
            return decoded
    except: pass
    return None

def decode_hex_string(candidate):
    """Decode hex string (pure hex, no spaces)"""
    try:
        clean = re.sub(r'[^0-9a-fA-F]', '', candidate)
        if len(clean) >= 8 and len(clean) % 2 == 0:
            decoded = bytes.fromhex(clean).decode('utf-8', errors='ignore')
            if len(decoded.strip()) > 3 and all(c.isprintable() or c.isspace() for c in decoded):
                return decoded
    except: pass
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
        except: pass
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
                except: pass
                offset = idx + 1
    except Exception as e:
        print(f"{Fore.YELLOW}[NTFS-RECOVER] Signature scan gagal: {e}{Style.RESET_ALL}")

    new_flags = list(found_flags_set)[found_before:]
    log_tool("ntfs-recover", "✅ Found" if new_flags else "⬜ Scanned",
             ", ".join(new_flags) if new_flags else f"output: {out_dir.name}")
    add_to_summary("NTFS-DONE", f"Output: '{out_dir.name}'")
    print(f"{Fore.GREEN}[NTFS-RECOVER] Selesai. Output: {out_dir.name}{Style.RESET_ALL}")


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
        except: pass
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

# ── 5. RSA: AUTO-DETECT & TRY ALL ATTACKS ────────────────────────

def rsa_auto_attack(N, e, c, e2=None, c2=None, sig_faulty=None, msg=None):
    """
    Coba semua RSA attacks secara otomatis berdasarkan parameter yang tersedia.
    """
    _crypto_banner("RSA Auto-Attack Pipeline")
    results = []

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

def decode_encoding_chain(encoded_str):
    """
    Mencoba decode encoding chain seperti writeup Encoding Maze:
    Base32 → Binary string → bit-reverse each byte → reverse string → Base64 → flag.
    Juga coba variasi urutan.
    Ref: writeup Encoding Maze — CTF{3nc0d1ng_1s_n0t_3ncrypt10n}.
    """
    _crypto_banner("Encoding Chain Decoder (Multi-Stage)")
    print(f"  Input ({len(encoded_str)} chars): {encoded_str[:60]}...")

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
        'e2': [r'e2\s*[:=]\s*(\d+)'],
        'c2': [r'[Cc]2\s*[:=]\s*(\d{10,})'],
        'p':  [r'\bp\s*[:=]\s*(\d{10,})'],
        'q':  [r'\bq\s*[:=]\s*(\d{10,})'],
        'sig_faulty': [r'sig(?:_faulty|faulty|_fault)\s*[:=]\s*(\d{10,})'],
        'msg': [r'\bM\s*[:=]\s*(\d{10,})', r'message\s*[:=]\s*(\d{10,})'],
    }.items():
        for pat in pats:
            m = re.search(pat, text, re.IGNORECASE)
            if m:
                params[key] = int(m.group(1))
                break

    return params

def _parse_aes_from_text(text):
    """Ekstrak IV dan CT hex dari teks."""
    iv_m = re.search(r'[Ii][Vv]\s*[:=]?\s*([0-9a-fA-F]{32})', text)
    ct_m = re.search(r'[Cc][Tt]\s*[:=]?\s*([0-9a-fA-F]{32,})', text)
    iv = iv_m.group(1) if iv_m else None
    ct = ct_m.group(1) if ct_m else None
    return iv, ct

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

    # ── Deteksi AES-CBC (IV + CT hex)
    iv, ct_hex = _parse_aes_from_text(text)
    if iv and ct_hex:
        print(f"\n{Fore.CYAN}[CRYPTO] AES-CBC IV+CT terdeteksi.{Style.RESET_ALL}")
        print(f"  {Fore.YELLOW}[INFO] Padding Oracle membutuhkan oracle function eksternal.{Style.RESET_ALL}")
        print(f"  IV : {iv}")
        print(f"  CT : {ct_hex[:64]}...")
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

    print_final_report(filepath.name)
    return _build_result()


# ── Reversing Module (v5.0) ──────────────────────────────────

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
    cmd = f"objdump -t '{filepath}' | grep -E '\.text' | awk '{{print $NF}}'"
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
    
    # Step 4: objdump analysis (ELF only)
    if not args.skip_objdump:
        objdump_analysis(unpacked)
    
    # Step 5: readelf analysis (ELF only)
    if not args.skip_readelf:
        readelf_analysis(unpacked)
    
    # Step 6: Ghidra analysis (if available)
    if args.ghidra:
        ghidra_analysis(unpacked, output_dir)
    
    # Step 7: Search for hardcoded passwords/keys
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
    
    print_final_report(filepath.name)
    return _build_result()

# ═══════════════════════════════════════════════════════════════
# ══ END REVERSING MODULE ═══════════════════════════════════════
# ═══════════════════════════════════════════════════════════════

# ── Crypto Engine (v4.0) ─────────────────────────────────────────────

def process_file(filepath, args):
    print(f"\n{Fore.BLUE}{'='*60}\nPROCESSING: {filepath.name}\n{'='*60}{Style.RESET_ALL}")
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
    except: pass

    analyze_strings_and_flags(repaired, args.format)

    if check_early_exit():
        print_final_report(filepath.name); return _build_result()

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

    # ── CRYPTO MODE (v4.0)
    if getattr(args, 'crypto', False):
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
        except: pass
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
        print_final_report(filepath.name); return _build_result()

    if is_autorun:
        analyze_autorun(repaired)
        print_final_report(filepath.name); return _build_result()

    # ── MEMORY DUMP auto-route
    if is_memory_dump or args.volatility:
        print(f"{Fore.MAGENTA}[AUTO] Memory dump terdeteksi → memory analysis pipeline{Style.RESET_ALL}")
        # Strategi: strings scan dulu (cepat), baru volatility
        _memory_fallback_scan(repaired, repaired.parent / f"{repaired.stem}_memscan")
        if check_early_exit():
            print_final_report(filepath.name); return _build_result()
        # Lanjutkan ke volatility untuk analisis lebih dalam
        analyze_volatility(repaired, getattr(args,'vol_args',None))
        if not check_early_exit():
            analyze_memory_advanced(repaired)
        print_final_report(filepath.name); return _build_result()

    if args.volatility:
        analyze_volatility(repaired, getattr(args,'vol_args',None))
        print_final_report(filepath.name); return _build_result()

    # ── Manual flag override
    if hasattr(args, 'ntfs') and args.ntfs:
        print(f"{Fore.MAGENTA}[AUTO] --ntfs: NTFS recovery mode{Style.RESET_ALL}")
        analyze_ntfs_deleted(repaired)
        print_final_report(filepath.name); return _build_result()

    if hasattr(args, 'partition') and args.partition:
        print(f"{Fore.MAGENTA}[AUTO] --partition: Partition scan mode{Style.RESET_ALL}")
        analyze_disk_partitions(repaired)
        print_final_report(filepath.name); return _build_result()

    # ── DISK IMAGE ROUTING (NTFS / MBR / generic)
    if is_ntfs_disk or (is_disk and "ntfs" in file_desc):
        print(f"{Fore.MAGENTA}[AUTO] NTFS disk image terdeteksi → NTFS recovery pipeline{Style.RESET_ALL}")
        analyze_ntfs_deleted(repaired)
        if not check_early_exit():
            analyze_disk_partitions(repaired)
        print_final_report(filepath.name); return _build_result()

    if is_mbr_disk or (is_disk and "mbr" in file_desc):
        print(f"{Fore.MAGENTA}[AUTO] MBR disk image terdeteksi → partition analysis pipeline{Style.RESET_ALL}")
        analyze_disk_partitions(repaired)
        if not check_early_exit():
            analyze_ntfs_deleted(repaired)
        print_final_report(filepath.name); return _build_result()

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
            if check_early_exit(): print_final_report(filepath.name); return _build_result()
            if AVAILABLE_TOOLS.get('stegseek'): analyze_stegseek(repaired, getattr(args,'wordlist',None))
            if check_early_exit(): print_final_report(filepath.name); return _build_result()
            if AVAILABLE_TOOLS.get('steghide'): analyze_steghide(repaired)
        if is_pcap:
            analyze_pcap_basic(repaired); search_pcap_flags(repaired)
            if not check_early_exit(): analyze_dns_tunneling(repaired)
        if is_zip: crack_zip(repaired, getattr(args,'wordlist',None))
        print_final_report(filepath.name); return _build_result()

    # ── PCAP ONLY
    if args.pcap and is_pcap:
        analyze_pcap_full(repaired); print_final_report(filepath.name); return _build_result()

    # ── ALL / AUTO
    if args.all or args.auto:
        # Log analysis
        if is_log: analyze_log(repaired)
        if is_autorun: analyze_autorun(repaired)
        if is_reg: analyze_registry(repaired)
        if is_zip: crack_zip(repaired, getattr(args,'wordlist',None))
        if is_image:
            analyze_image(repaired,deep=args.deep,alpha=args.alpha)
            analyze_graphicsmagick(repaired); analyze_exif_deep(repaired)
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
        if is_evtlog: analyze_windows_event_logs(repaired)
        if is_pcap:
            analyze_pcap_full(repaired)
            if not check_early_exit(): analyze_dns_tunneling(repaired)

    # ── SELECTIVE
    else:
        # Tipe-tipe khusus
        if is_log:   analyze_log(repaired)
        elif is_image:
            analyze_image(repaired,deep=args.deep,alpha=args.alpha)
            if args.exif:       analyze_exif_deep(repaired)
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
            if args.zipcrack: crack_zip(repaired, getattr(args,'wordlist',None))
            else: analyze_with_binwalk(repaired)
            if args.foremost: analyze_foremost(repaired)
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

        # Reversing mode for binaries
        if args.reversing:
            reversing_pipeline(repaired, args)

        # Deobfuscation selektif
        if args.deobfuscate:
            try:
                text = repaired.read_text(errors='ignore')
                analyze_deobfuscation(text, "MANUAL")
            except: pass

    print_final_report(filepath.name)
    return _build_result()

# ── Entry Point ───────────────────────────────

def main():
    print(f"{Fore.CYAN}{'='*55}\n   RAVEN v5.0 — CTF Multi-Category Toolkit\n{'='*55}{Style.RESET_ALL}")
    check_tool_availability()
    p=argparse.ArgumentParser(
        description="RAVEN v5.0 — CTF Multi-Category Toolkit",
        formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("files",nargs="*",help="File(s), wildcard, atau direktori")
    p.add_argument("-f","--format",default=None,help="Custom flag prefix (e.g. 'picoCTF{')")

    modes=p.add_argument_group("Modes")
    modes.add_argument("--quick",     action="store_true",help="Ultra-fast: strings+zsteg+stegseek+early exit")
    modes.add_argument("--auto",      action="store_true",help="Auto-detect semua tools")
    modes.add_argument("--all",       action="store_true",help="Paksa semua tool")
    modes.add_argument("--pcap",      action="store_true",help="Full PCAP analysis")
    modes.add_argument("--disk",      action="store_true",help="Disk image analysis")
    modes.add_argument("--windows",   action="store_true",help="Windows Event Log")
    modes.add_argument("--folder",    type=str,           help="Scan semua file di folder (fake ext detection)")

    ctf=p.add_argument_group("CTF Spesifik (v3.1+)")
    ctf.add_argument("--reg",        action="store_true",help="Windows Registry (.reg) analysis")
    ctf.add_argument("--log",        action="store_true",help="Web server log analysis (Apache/Nginx)")
    ctf.add_argument("--autorun",    action="store_true",help="Autorun.inf / INF file analysis")
    ctf.add_argument("--zipcrack",   action="store_true",help="Crack ZIP password (wordlist/rockyou)")
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

    enc=p.add_argument_group("Encoding")
    enc.add_argument("--decode", action="store_true",help="Auto-decode base64/hex/binary")
    enc.add_argument("--extract",action="store_true",help="Ekstrak file tersembunyi")

    bf=p.add_argument_group("Brute Force")
    bf.add_argument("--bruteforce",action="store_true",help="Brute-force steghide")
    bf.add_argument("--wordlist",  type=str,           help="Custom wordlist")
    bf.add_argument("--delay",     type=float,default=0.1,help="Delay (default: 0.1)")
    bf.add_argument("--parallel",  type=int,  default=5,  help="Threads (default: 5)")

    args=p.parse_args()

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
# INTERACTIVE CATEGORY MENU (v5.0)
# ─────────────────────────────────────────────

# Store selected mode flags globally
declare -A MODE_FLAGS
MODE_FLAGS=(
    [auto]="--auto"
    [steganografi]="--lsb --steghide --stegseek --outguess --pngcheck --exif --stegdetect --lsbextract --remap --deep --alpha"
    [forensics]="--disk --volatility --memory --foremost"
    [crypto]="--crypto"
    [web]="--log --pcap"
    [reversing]="--reversing --unpack"
    [pwn]=""
    [misc]="--decode --extract --deobfuscate"
    [ai]=""
)

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

# Mode A: Native bash select menu (zero dependency)
show_category_menu_select() {
    local files=("$@")

    echo ""
    echo -e "${CYAN}  ╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}  ║     RAVEN v5.0 — Interactive Mode Selector  ║${NC}"
    echo -e "${CYAN}  ╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}  Files to analyze: ${#files[@]}${NC}"
    for f in "${files[@]}"; do
        echo -e "    • ${GREEN}$f${NC}"
    done
    echo ""
    echo -e "${YELLOW}  Pilih kategori analisis CTF (multi-select):${NC}"
    echo -e "${CYAN}  Pilih beberapa mode, lalu tekan '10' untuk konfirmasi & run${NC}"
    echo ""

    local selected_flags=""
    local selected_count=0

    PS3="  ${GREEN}> Masukkan nomor [1-10]:${NC} "

    local choice
    select choice in \
        "⚡ Auto-detect (biarkan RAVEN memilih)" \
        "🖼️  Steganografi (PNG/JPG/audio/LSB)" \
        "🔬 Forensik Digital (Disk/Memory/PCAP)" \
        "🔒 Kriptografi (RSA/XOR/Cipher klasik)" \
        "🌐 Web & Log Analysis (Apache/Nginx/HTTP)" \
        "🔧 Reversing (ELF/PE/bytecode)" \
        "💥 Pwn / Exploit (Buffer/ROP/heap)" \
        "🎭 Misc / Encode (B64/Hex/Brainfuck)" \
        "🤖 AI-Assisted (Claude API solver)" \
        "✅ Jalankan dengan pilihan di atas" \
        "❌ Keluar"
    do
        case $REPLY in
            1)
                if [[ "$selected_flags" != *"--auto"* ]]; then
                    selected_flags="$selected_flags --auto"
                    ((selected_count++))
                    info "✓ Auto-detect ditambahkan (${selected_count} mode dipilih)"
                else
                    warn "Auto-detect sudah dipilih"
                fi
                ;;
            2)
                if [[ "$selected_flags" != *"--lsb"* ]]; then
                    selected_flags="$selected_flags --lsb --steghide --stegseek --outguess --pngcheck --exif --stegdetect --lsbextract --remap --deep --alpha"
                    ((selected_count++))
                    info "✓ Steganografi ditambahkan (${selected_count} mode dipilih)"
                else
                    warn "Steganografi sudah dipilih"
                fi
                ;;
            3)
                if [[ "$selected_flags" != *"--disk"* ]]; then
                    selected_flags="$selected_flags --disk --volatility --memory --foremost"
                    ((selected_count++))
                    info "✓ Forensik Digital ditambahkan (${selected_count} mode dipilih)"
                else
                    warn "Forensik Digital sudah dipilih"
                fi
                ;;
            4)
                if [[ "$selected_flags" != *"--crypto"* ]]; then
                    selected_flags="$selected_flags --crypto"
                    ((selected_count++))
                    info "✓ Kriptografi ditambahkan (${selected_count} mode dipilih)"
                else
                    warn "Kriptografi sudah dipilih"
                fi
                ;;
            5)
                if [[ "$selected_flags" != *"--log"* ]]; then
                    selected_flags="$selected_flags --log --pcap"
                    ((selected_count++))
                    info "✓ Web & Log Analysis ditambahkan (${selected_count} mode dipilih)"
                else
                    warn "Web & Log Analysis sudah dipilih"
                fi
                ;;
            6)
                if [[ "$selected_flags" != *"--reversing"* ]]; then
                    selected_flags="$selected_flags --reversing --unpack"
                    ((selected_count++))
                    info "✓ Reversing ditambahkan (${selected_count} mode dipilih)"
                else
                    warn "Reversing sudah dipilih"
                fi
                ;;
            7)
                warn "Mode Pwn/Exploit masih dalam pengembangan"
                ;;
            8)
                if [[ "$selected_flags" != *"--decode"* ]]; then
                    selected_flags="$selected_flags --decode --extract --deobfuscate"
                    ((selected_count++))
                    info "✓ Misc / Encode ditambahkan (${selected_count} mode dipilih)"
                else
                    warn "Misc / Encode sudah dipilih"
                fi
                ;;
            9)
                warn "AI-Assisted Solver belum tersedia"
                ;;
            10)
                if [[ $selected_count -eq 0 ]]; then
                    warn "Belum ada mode dipilih!"
                else
                    success "Menjalankan dengan ${selected_count} mode..."
                    echo "$selected_flags"
                    return 0
                fi
                ;;
            11)
                info "Keluar dari RAVEN"
                return 1
                ;;
            *)
                err_msg "Pilihan tidak valid. Masukkan nomor 1-11."
                ;;
        esac
    done
}

# Mode B: whiptail TUI (checkbox + multi-select)
show_category_menu_whiptail() {
    local files=("$@")

    local file_list=""
    for f in "${files[@]}"; do
        file_list+="• $f\n"
    done

    # Use checklist for multi-select
    local choices
    choices=$(whiptail --title "RAVEN v5.0 — Multi-Select Mode" \
        --backtitle "CTF Multi-Category Toolkit | Space: select | Enter: confirm" \
        --checklist "\nFiles: ${file_list}\nPilih beberapa mode (Space untuk pilih):" 22 78 10 \
        "auto" "⚡ Auto-detect" ON \
        "stego" "🖼️  Steganografi" OFF \
        "forensics" "🔬 Forensik Digital" OFF \
        "crypto" "🔒 Kriptografi" OFF \
        "web" "🌐 Web & Log Analysis" OFF \
        "reversing" "🔧 Reversing" OFF \
        "pwn" "💥 Pwn/Exploit (WIP)" OFF \
        "misc" "🎭 Misc/Encode" OFF \
        "ai" "🤖 AI Solver (WIP)" OFF \
        3>&1 1>&2 2>&3)

    local exit_status=$?
    if [[ $exit_status -ne 0 ]]; then
        return 1
    fi

    # Parse selected choices
    local flags=""
    for choice in $choices; do
        case $choice in
            auto) flags="$flags --auto" ;;
            stego) flags="$flags --lsb --steghide --stegseek --outguess --pngcheck --exif --stegdetect --lsbextract --remap --deep --alpha" ;;
            forensics) flags="$flags --disk --volatility --memory --foremost" ;;
            crypto) flags="$flags --crypto" ;;
            web) flags="$flags --log --pcap" ;;
            reversing) flags="$flags --reversing --unpack" ;;
            pwn) warn "Mode Pwn/Exploit masih dalam pengembangan" ;;
            misc) flags="$flags --decode --extract --deobfuscate" ;;
            ai) warn "AI Solver belum tersedia" ;;
        esac
    done

    if [[ -z "$flags" ]]; then
        warn "Tidak ada mode dipilih!"
        return 1
    fi

    echo "$flags"
    return 0
}

# Mode C: fzf fuzzy finder (power user)
show_category_menu_fzf() {
    local files=("$@")

    echo -e "${CYAN}  ╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}  ║     RAVEN v5.0 — FZF Multi-Select Mode       ║${NC}"
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
        "🤖 ai:Claude API solver"
    )

    local choices
    choices=$(printf "%s\n" "${options[@]}" | fzf --multi --height 60% \
        --prompt="> Pilih mode (Tab untuk select): " \
        --preview="echo {}" \
        --preview-window=down:1 \
        --border \
        --ansi)

    if [[ -z "$choices" ]]; then
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
            *"ai"*) warn "AI Solver belum tersedia" ;;
        esac
    done <<< "$choices"

    if [[ -z "$flags" ]]; then
        return 1
    fi

    echo "$flags"
    return 0
}

# Main menu dispatcher
show_category_menu() {
    local files=("$@")
    
    # Detect best available TUI
    local tui_type
    tui_type=$(detect_tui_support)
    
    local flags=""
    
    case $tui_type in
        "fzf")
            flags=$(show_category_menu_fzf "${files[@]}") || return 1
            ;;
        "whiptail")
            flags=$(show_category_menu_whiptail "${files[@]}") || return 1
            ;;
        *)
            flags=$(show_category_menu_select "${files[@]}") || return 1
            ;;
    esac
    
    # Return selected flags
    if [[ -n "$flags" ]]; then
        echo "$flags"
        return 0
    else
        return 1
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
            --auto|--quick|--all|--pcap|--disk|--windows|--crypto|--reg|--log|--autorun|\
            --zipcrack|--pdfcrack|--john|--hashcat|--volatility|--deobfuscate|--reversing|\
            --ghidra|--unpack)
                has_mode_flag=1
                break
                ;;
        esac
    done
    
    # Show interactive menu if no mode flag specified
    if [[ $has_mode_flag -eq 0 && ${#python_args[@]} -gt 0 ]]; then
        info "No specific mode selected. Opening interactive menu..."
        local selected_flags
        if selected_flags=$(show_category_menu "${python_args[@]}"); then
            # Prepend selected flags to python args
            python_args=($selected_flags "${python_args[@]}")
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
