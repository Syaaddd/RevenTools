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
ENGINE_DIR="$RAVEN_HOME/engine"
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
           CTF Multi-Category Toolkit v5.1  — by Syaaddd
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
    rm -rf "$ENGINE_DIR"

    # Pre-generate engine baru
    local py
    py=$(check_python) || die "Python 3.8+ tidak ditemukan."
    setup_venv "$py"
    setup_engine

    success "RAVEN berhasil diupdate!"
    echo ""
    echo -e "  ${GREEN}Backup tersimpan di: $backup${NC}"
    echo -e "  ${GREEN}Engine modular: $ENGINE_DIR${NC}"
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
    setup_engine

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
# SETUP MODULAR ENGINE
# ─────────────────────────────────────────────
setup_engine() {
    mkdir -p "$ENGINE_DIR"

    # Get the directory where raven.sh is located
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local src_engine="$script_dir/engine"

    if [[ -d "$src_engine" ]]; then
        # Always overwrite untuk ensure versi terbaru
        info "Copy engine files dari $src_engine..."
        cp "$src_engine"/*.py "$ENGINE_DIR/"
        success "Engine modular ter-copy: $(ls "$ENGINE_DIR"/*.py | wc -l) files"
        return 0
    fi

    # Jika source tidak ada, cek apakah engine sudah ada
    if [[ -d "$ENGINE_DIR" ]] && [[ -f "$ENGINE_DIR/__main__.py" ]]; then
        success "Engine modular sudah terinstall di $ENGINE_DIR"
        return 0
    fi

    # Jika kedua sumber tidak ada, beri peringatan
    warn "Engine files tidak ditemukan."
    warn "Pastikan folder engine/ ada di direktori asal raven.sh"
    return 1
}

# ─────────────────────────────────────────────



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

# Mode A: Native bash select menu (zero dependency)
show_category_menu_select() {
    local files=("$@")

    echo ""
    echo -e "${CYAN}  ╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}  ║     RAVEN v5.1 — Interactive Mode Selector  ║${NC}"
    echo -e "${CYAN}  ╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}  Files to analyze: ${#files[@]}${NC}"
    for f in "${files[@]}"; do
        echo -e "    • ${GREEN}$f${NC}"
    done
    echo ""
    echo -e "${YELLOW}  Pilih kategori analisis CTF (multi-select):${NC}"
    echo -e "${CYAN}  Pilih beberapa mode, lalu tekan '10' untuk konfirmasi & run${NC}"
    echo -e "${CYAN}  Tekan Ctrl+C untuk batal${NC}"
    echo ""

    local selected_flags=""
    local selected_count=0

    PS3="  ${GREEN}> Masukkan nomor [1-11]:${NC} "

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
        "🤖 AI-Assisted (Claude API solver)" \
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
                echo -e "${YELLOW}  ⚠ AI-Assisted Solver belum tersedia${NC}"
                ;;
            10)
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
            11)
                echo -e "${CYAN}  Keluar dari RAVEN${NC}"
                MENU_SELECTED_FLAGS=""
                break  # Keluar dari select loop
                ;;
            *)
                echo -e "${RED}  ✖ Pilihan tidak valid. Masukkan nomor 1-11.${NC}"
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
    choices=$(whiptail --title "RAVEN v5.1 — Multi-Select Mode" \
        --backtitle "CTF Multi-Category Toolkit | Space: select | Enter: confirm" \
        --checklist "\nFiles: $file_list\nPilih beberapa mode (Space untuk pilih):" 22 78 10 \
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
    echo -e "${CYAN}  ║     RAVEN v5.1 — FZF Multi-Select Mode       ║${NC}"
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
            *"ai"*) warn "AI Solver belum tersedia" ;;
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

    # Setup modular engine
    setup_engine

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

    # Resolve file arguments ke absolute path sebelum cd
    local resolved_args=()
    for arg in "${final_python_args[@]}"; do
        if [[ -f "$arg" ]]; then
            resolved_args+=("$(realpath "$arg")")
        elif [[ -d "$arg" ]]; then
            resolved_args+=("$(realpath "$arg")")
        else
            resolved_args+=("$arg")
        fi
    done

    echo ""
    info "Menjalankan RAVEN..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Save CWD ke env var supaya Python tahu output directory
    local current_cwd="$PWD"
    
    # Run modular engine dari parent directory
    cd "$RAVEN_HOME"
    PYTHONPATH="$RAVEN_HOME" CWD="$current_cwd" python -m engine "${resolved_args[@]}"
}

main "$@"

