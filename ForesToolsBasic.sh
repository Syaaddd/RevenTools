#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  ForesTools v2.0 — CTF Forensic Toolkit Launcher
#  Usage: ./forestools.sh [FILE(S)] [OPTIONS]
# ══════════════════════════════════════════════════════════════════

set -euo pipefail

# ──────────────────────────────────────────────
# CONFIG
# ──────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/ForesTools.py"
VENV_DIR="$SCRIPT_DIR/.venv"
MIN_PYTHON="3.8"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ──────────────────────────────────────────────
# HELPERS
# ──────────────────────────────────────────────
info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERR]${NC}  $*" >&2; }
die()     { error "$*"; exit 1; }

banner() {
cat << 'EOF'
 ███████╗ ██████╗ ██████╗ ███████╗███████╗████████╗ ██████╗  ██████╗ ██╗     ███████╗
 ██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝
 █████╗  ██║   ██║██████╔╝█████╗  ███████╗   ██║   ██║   ██║██║   ██║██║     ███████╗
 ██╔══╝  ██║   ██║██╔══██╗██╔══╝  ╚════██║   ██║   ██║   ██║██║   ██║██║     ╚════██║
 ██║     ╚██████╔╝██║  ██║███████╗███████║   ██║   ╚██████╔╝╚██████╔╝███████╗███████║
 ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝   ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝
                         CTF Forensic Toolkit v2.0
EOF
}

# ──────────────────────────────────────────────
# PYTHON VERSION CHECK
# ──────────────────────────────────────────────
check_python() {
    local py
    for candidate in python3 python python3.11 python3.10 python3.9 python3.8; do
        if command -v "$candidate" &>/dev/null; then
            local ver
            ver=$("$candidate" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null)
            if python3 -c "import sys; exit(0 if sys.version_info >= (3,8) else 1)" &>/dev/null 2>&1; then
                echo "$candidate"
                return 0
            fi
        fi
    done
    return 1
}

# ──────────────────────────────────────────────
# VIRTUAL ENV & DEPENDENCY SETUP
# ──────────────────────────────────────────────
setup_venv() {
    local py="$1"

    if [[ ! -d "$VENV_DIR" ]]; then
        info "Creating virtual environment at $VENV_DIR ..."
        "$py" -m venv "$VENV_DIR" || die "Failed to create venv. Install python3-venv?"
        success "Virtual environment created."
    fi

    # Activate
    # shellcheck disable=SC1091
    source "$VENV_DIR/bin/activate"

    info "Checking Python dependencies..."
    local pip="$VENV_DIR/bin/pip"
    local missing=()

    python -c "import colorama" 2>/dev/null || missing+=("colorama")
    python -c "from PIL import Image" 2>/dev/null || missing+=("Pillow")
    python -c "import numpy" 2>/dev/null || missing+=("numpy")

    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "Installing missing packages: ${missing[*]}"
        "$pip" install --quiet --upgrade pip
        "$pip" install --quiet "${missing[@]}" || die "pip install failed."
        success "Dependencies installed."
    else
        success "All Python dependencies present."
    fi
}

# ──────────────────────────────────────────────
# OPTIONAL TOOL CHECK (non-fatal)
# ──────────────────────────────────────────────
check_system_tools() {
    local tools=(zsteg steghide outguess foremost pngcheck binwalk exiftool tshark capinfos)
    local missing=()
    for t in "${tools[@]}"; do
        command -v "$t" &>/dev/null || missing+=("$t")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "Optional tools not found: ${missing[*]}"
        warn "Some analyses will be skipped. Install with your package manager."
        echo ""
    fi
}

# ──────────────────────────────────────────────
# INSTALL HELPER (--install flag)
# ──────────────────────────────────────────────
install_tools() {
    info "Attempting to install optional system tools..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y \
            steghide foremost pngcheck binwalk exiftool \
            tshark wireshark-common ruby \
            || warn "Some packages failed to install."
        # zsteg via gem
        if command -v gem &>/dev/null; then
            sudo gem install zsteg 2>/dev/null && success "zsteg installed." || warn "zsteg install failed."
        fi
        # outguess
        if ! command -v outguess &>/dev/null; then
            sudo apt-get install -y outguess 2>/dev/null || warn "outguess not available in repos."
        fi
    elif command -v brew &>/dev/null; then
        brew install steghide binwalk exiftool wireshark || true
        gem install zsteg 2>/dev/null || warn "zsteg install failed."
    else
        warn "No supported package manager found (apt/brew). Install tools manually."
    fi
    success "Install step complete."
    exit 0
}

# ──────────────────────────────────────────────
# USAGE
# ──────────────────────────────────────────────
usage() {
cat << EOF
${BOLD}Usage:${NC}
  ./forestools.sh [OPTIONS] FILE [FILE...]

${BOLD}Modes:${NC}
  --quick          Ultra-fast: strings + zsteg + early exit
  --auto           Auto-detect and run all suitable tools
  --all            Force-run every available tool
  --pcap           Full PCAP analysis with attack detection
  --disk           Disk image analysis
  --windows        Windows Event Log forensics

${BOLD}Steganography:${NC}
  --lsb            LSB analysis via zsteg
  --steghide       Steghide extraction
  --outguess       Outguess extraction (JPEG)
  --pngcheck       Validate PNG structure
  --jpsteg         JPEG steganalysis (jpseek/jphs)
  --remap          Color palette remapping (8 variants)
  --exif           Deep EXIF metadata analysis
  --stegdetect     Detect steganography method
  --lsbextract     Extract raw LSB bytes
  --deep           Analyze all 8 bit planes
  --alpha          Include alpha channel
  --compare FILE   Compare with second image
  --foremost       File carving (foremost)

${BOLD}Encoding:${NC}
  --decode         Auto-decode base64 / hex / binary
  --extract        Extract embedded files from encoded text

${BOLD}Brute Force:${NC}
  --bruteforce     Brute-force steghide passwords
  --wordlist FILE  Custom password wordlist
  --delay SECS     Delay between attempts (default: 0.1)
  --parallel N     Thread count (default: 5)

${BOLD}Misc:${NC}
  -f, --format STR Custom flag prefix (e.g. 'picoCTF{')
  --install        Install optional system tools (needs sudo/brew)
  --update-deps    Reinstall Python dependencies
  -h, --help       Show this help

${BOLD}Examples:${NC}
  ./forestools.sh image.png
  ./forestools.sh image.png --all
  ./forestools.sh image.png --lsb --steghide --exif
  ./forestools.sh image.png --bruteforce --wordlist /usr/share/wordlists/rockyou.txt
  ./forestools.sh traffic.pcap --pcap
  ./forestools.sh disk.img --disk
  ./forestools.sh *.png --quick
  ./forestools.sh --install
EOF
}

# ──────────────────────────────────────────────
# MAIN
# ──────────────────────────────────────────────
main() {
    banner

    # Handle special flags before anything else
    for arg in "$@"; do
        case "$arg" in
            --install)      install_tools ;;
            -h|--help)      usage; exit 0 ;;
        esac
    done

    if [[ $# -eq 0 ]]; then
        usage
        exit 0
    fi

    # Locate Python
    local py
    py=$(check_python) || die "Python ${MIN_PYTHON}+ not found. Please install Python 3."
    info "Using Python: $py ($(${py} --version 2>&1))"

    # Handle --update-deps
    for arg in "$@"; do
        if [[ "$arg" == "--update-deps" ]]; then
            [[ -d "$VENV_DIR" ]] && rm -rf "$VENV_DIR"
            break
        fi
    done

    # Set up venv + deps
    setup_venv "$py"

    # Check optional system tools
    check_system_tools

    # Verify the Python script exists
    [[ -f "$PYTHON_SCRIPT" ]] || die "ForesTools.py not found at $PYTHON_SCRIPT"

    # Filter out our own flags before passing to Python
    local python_args=()
    for arg in "$@"; do
        [[ "$arg" != "--update-deps" ]] && python_args+=("$arg")
    done

    echo ""
    info "Launching ForesTools..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    python "$PYTHON_SCRIPT" "${python_args[@]}"
}

main "$@"
