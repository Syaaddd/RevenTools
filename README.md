#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  ForesTools v2.0 — CTF Forensic Toolkit (STANDALONE .sh)
#  Tidak perlu file Python terpisah — semua ada di sini
#  Usage: ./forestools.sh [FILE(S)] [OPTIONS]
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"
PYTHON_INLINE="$SCRIPT_DIR/.forestools_engine.py"

# ─────────────────────────────────────────────
# BANNER
# ─────────────────────────────────────────────
banner() {
cat << 'BANNER'

  ███████╗ ██████╗ ██████╗ ███████╗███████╗████████╗ ██████╗  ██████╗ ██╗     ███████╗
  ██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝
  █████╗  ██║   ██║██████╔╝█████╗  ███████╗   ██║   ██║   ██║██║   ██║██║     ███████╗
  ██╔══╝  ██║   ██║██╔══██╗██╔══╝  ╚════██║   ██║   ██║   ██║██║   ██║██║     ╚════██║
  ██║     ╚██████╔╝██║  ██║███████╗███████║   ██║   ╚██████╔╝╚██████╔╝███████╗███████║
  ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝   ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝
                          CTF Forensic Toolkit v2.0  — Standalone Edition
BANNER
}

# ─────────────────────────────────────────────
# USAGE
# ─────────────────────────────────────────────
usage() {
cat << EOF
${BOLD}Usage:${NC}
  ./forestools.sh [OPTIONS] FILE [FILE...]

${BOLD}Modes:${NC}
  --quick          Ultra-fast: strings + zsteg + stegseek + early exit
  --auto           Auto-detect dan jalankan semua tools yang sesuai
  --all            Paksa jalankan semua tool
  --pcap           Full PCAP analysis + attack detection
  --disk           Disk image analysis
  --windows        Windows Event Log forensics

${BOLD}Steganografi:${NC}
  --lsb            LSB analysis (zsteg)
  --steghide       Steghide extraction (password kosong)
  --stegseek       Stegseek brute-force dengan rockyou.txt  ← BARU
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
  --wordlist FILE  Custom wordlist (default: rockyou.txt untuk stegseek)
  --delay SECS     Delay antar attempt (default: 0.1)
  --parallel N     Jumlah thread (default: 5)

${BOLD}Misc:${NC}
  -f, --format STR Custom flag prefix (e.g. 'picoCTF{')
  --install        Install semua optional tools (butuh sudo/brew)
  --update-deps    Reinstall Python dependencies
  -h, --help       Tampilkan help ini

${BOLD}Contoh:${NC}
  ./forestools.sh image.png
  ./forestools.sh image.png --all
  ./forestools.sh image.png --stegseek
  ./forestools.sh image.jpg --stegseek --wordlist /usr/share/wordlists/rockyou.txt
  ./forestools.sh image.png --lsb --steghide --exif
  ./forestools.sh image.png --bruteforce --wordlist rockyou.txt
  ./forestools.sh traffic.pcap --pcap
  ./forestools.sh disk.img --disk
  ./forestools.sh *.png --quick
  ./forestools.sh --install
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

        # outguess
        if ! command -v outguess &>/dev/null; then
            sudo apt-get install -y outguess 2>/dev/null || \
            warn "outguess tidak ada di repo, install manual."
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
    if [[ ! -d "$VENV_DIR" ]]; then
        info "Membuat virtual environment..."
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
        warn "Jalankan './forestools.sh --install' untuk install otomatis."
        echo ""
    fi
}

# ─────────────────────────────────────────────
# TULIS PYTHON ENGINE KE FILE TEMP
# ─────────────────────────────────────────────
write_python_engine() {
    cat > "$PYTHON_INLINE" << 'PYTHON_ENGINE'
#!/usr/bin/env python3
"""ForesTools v2.0 — Python Engine (auto-generated by forestools.sh)"""

import subprocess, argparse, os, re, base64, shutil, math, time
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

DEFAULT_WORDLIST = [
    "password","123456","12345678","123456789","flag","ctf","steg","hack","test",
    "key","secret","admin","root","user","pass","letmein","welcome","monkey",
    "dragon","master","hello","shadow","sunshine","princess","football","baseball",
    "soccer","password1","password123","qwerty","abc123","iloveyou","admin123",
    "666666","888888","000000","111111","222222","333333","444444","555555",
    "777777","999999","aaaaaa","bbbbbb","cccccc","dddddd","eeeeee","ffffff",
    "hello1","hello123","love","loveyou","computer","internet","server","data",
    "file","image","photo","picture","music","video","movie","game",
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
    r'[A-Za-z0-9_]{3,}\{[^}]+\}',
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
}

# ── Utility ──────────────────────────────────

def check_tool_availability():
    tools = {
        "zsteg":"zsteg","steghide":"steghide","stegseek":"stegseek",
        "outguess":"outguess","foremost":"foremost","pngcheck":"pngcheck",
        "jpseek":"jpseek","jphs":"jphs","exiftool":"exiftool",
        "binwalk":"binwalk","identify":"gm","tshark":"tshark",
        "tcpdump":"tcpdump","capinfos":"capinfos",
    }
    global AVAILABLE_TOOLS
    AVAILABLE_TOOLS = {}
    for name, cmd in tools.items():
        probe  = f"where {cmd}" if os.name=="nt" else f"which {cmd}"
        result = subprocess.run(probe, shell=True, capture_output=True, text=True)
        AVAILABLE_TOOLS[name] = result.returncode == 0
        color  = Fore.GREEN if AVAILABLE_TOOLS[name] else Fore.RED
        status = "Available" if AVAILABLE_TOOLS[name] else "Missing"
        print(f"{color}[TOOL] {name}: {status}{Style.RESET_ALL}")
    return AVAILABLE_TOOLS

def reset_globals():
    global flag_summary, base64_collector, FLAG_FOUND
    flag_summary=[]; base64_collector=[]; FLAG_FOUND=False

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
        print(f"{Fore.GREEN}[EARLY EXIT] Flag ditemukan!{Style.RESET_ALL}")

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
    if header.startswith(b'\x89PNG'):     return 'png'
    if header.startswith(b'\xff\xd8\xff'):return 'jpg'
    if header.startswith(b'GIF8'):        return 'gif'
    if header.startswith(b'%PDF'):        return 'pdf'
    if header.startswith(b'PK'):          return 'zip'
    if header.startswith(b'\x42\x4d'):    return 'bmp'
    if header.startswith(b'\xff\xfb') or header.startswith(b'ID3'): return 'mp3'
    return 'bin'

def collect_base64_from_text(text):
    for m in re.findall(r'[A-Za-z0-9+/]{12,}=*', text):
        decoded=decode_base64(m)
        if decoded:
            entry=f"Raw: {m} -> Decoded: {decoded}"
            if entry not in base64_collector:
                base64_collector.append(entry)
                add_to_summary("B64-COLLECTOR",decoded)

def detect_scattered_flag(raw_data):
    try:
        cleaned=''.join(chr(b) for b in raw_data if 32<=b<=126)
        for pat in COMMON_FLAG_PATTERNS:
            for m in re.findall(pat,cleaned,re.IGNORECASE):
                add_to_summary("SCATTERED-FLAG",m)
    except: pass

# ── Header Repair ────────────────────────────

def fix_header(filepath):
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
        if det and cur!=det:
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
    return filepath

# ── Auto Decode ──────────────────────────────

def analyze_extracted_file(filepath):
    try:
        result=subprocess.run(['strings',str(filepath)],capture_output=True,text=True)
        for pat in COMMON_FLAG_PATTERNS:
            for m in re.findall(pat,result.stdout,re.IGNORECASE):
                print(f"{Fore.GREEN}[!] FLAG di extracted file: {m}{Style.RESET_ALL}")
                add_to_summary("EXTRACTED-FLAG",f"{m} in {filepath.name}")
    except: pass

def auto_decode_and_extract(filepath):
    if check_early_exit(): return
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
    except Exception as e:
        print(f"{Fore.RED}[!] Auto-decode gagal: {e}{Style.RESET_ALL}")

# ── Strings & Flags ──────────────────────────

def analyze_strings_and_flags(filepath, custom_format=None):
    try:
        ft=subprocess.getoutput(f"file -b '{filepath}'").strip()
        print(f"{Fore.CYAN}[BASIC] Type: {ft}{Style.RESET_ALL}")
        utf8=subprocess.getoutput(f"strings '{filepath}'")
        utf16=subprocess.getoutput(f"strings -e l '{filepath}'")
        combined=utf8+"\n"+utf16
        collect_base64_from_text(combined)
        for pat in COMMON_FLAG_PATTERNS:
            for m in re.findall(pat,combined,re.IGNORECASE):
                add_to_summary("AUTO-FLAG",m)
        if custom_format:
            esc=re.escape(custom_format)
            pat=esc.replace(r'\{',r'\{[^}]*\}') if esc.endswith(r'\{') else esc
            for m in re.findall(pat,combined,re.IGNORECASE):
                add_to_summary("CUSTOM-FLAG",m)
    except Exception as e:
        print(f"{Fore.RED}[!] String analysis gagal: {e}{Style.RESET_ALL}")

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
            for pat in COMMON_FLAG_PATTERNS:
                for m in re.findall(pat,out,re.IGNORECASE):
                    print(f"{Fore.GREEN}[!] FLAG di {f.name}: {m}{Style.RESET_ALL}")
                    add_to_summary("VISUAL-FLAG",m); return
        ch_dir=filepath.parent/f"{filepath.stem}_channels"; ch_dir.mkdir(exist_ok=True)
        r,g,b=img.split()[:3]; r.save(ch_dir/"red.png"); g.save(ch_dir/"green.png"); b.save(ch_dir/"blue.png")
        if img.mode=='RGBA': img.split()[3].save(ch_dir/"alpha.png")
        print(f"{Fore.CYAN}[+] Channels → {ch_dir.name}{Style.RESET_ALL}")
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
        print(f"{Fore.GREEN}[+] LSB data: {out_file.name} ({len(lsb_bytes)} bytes){Style.RESET_ALL}")
        text=lsb_bytes.tobytes()[:1000].decode('utf-8',errors='ignore')
        if any(c.isprintable() for c in text):
            print(f"{Fore.CYAN}[+] LSB preview: {text[:100]}{Style.RESET_ALL}")
            collect_base64_from_text(text)
        raw=lsb_bytes.tobytes().decode('latin-1',errors='ignore')
        for pat in COMMON_FLAG_PATTERNS:
            for m in re.findall(pat,raw,re.IGNORECASE):
                print(f"{Fore.GREEN}[!] FLAG di LSB: {m}{Style.RESET_ALL}")
                add_to_summary("LSB-FLAG",m)
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
        diff_sum=int(np.sum(diff))
        print(f"{Fore.CYAN}[+] Total pixel diff: {diff_sum}{Style.RESET_ALL}")
        out_dir=filepath1.parent/f"{filepath1.stem}_compare"; out_dir.mkdir(exist_ok=True)
        Image.fromarray(diff.astype(np.uint8)).save(out_dir/"difference.png")
        non_zero=int(np.sum(diff>0))
        print(f"{Fore.CYAN}[+] Pixel berbeda: {non_zero}{Style.RESET_ALL}")
        add_to_summary("IMAGE-COMPARE",f"diff={non_zero}, total={diff_sum}")
    except Exception as e:
        print(f"{Fore.RED}[IMAGE-COMPARE] Gagal: {e}{Style.RESET_ALL}")

def analyze_steg_methods(filepath):
    if not HAS_PIL: return
    print(f"{Fore.GREEN}[STEG-DETECT] Mendeteksi metode steganografi...{Style.RESET_ALL}")
    try:
        img=Image.open(filepath); pixels=np.array(img).flatten()
        ones=int(np.sum(pixels%2==1)); ratio=ones/(len(pixels)+1)
        lsb_likely=0.48<ratio<0.52
        print(f"{Fore.CYAN}[STEG-DETECT] LSB ratio: {ratio:.4f} (random≈0.5){Style.RESET_ALL}")
        if lsb_likely: print("  ⚠  LSB hampir random → kemungkinan LSB stego")
        arr=np.array(img); zsteg_likely=False
        if arr.ndim==3 and arr.shape[2]>=3:
            rv,gv,bv=float(np.var(arr[:,:,0])),float(np.var(arr[:,:,1])),float(np.var(arr[:,:,2]))
            if abs(rv-gv)>1000 or abs(gv-bv)>1000:
                zsteg_likely=True; print("  ⚠  Variance channel tinggi → coba zsteg")
        is_jpeg=filepath.suffix.lower() in ['.jpg','.jpeg']
        print(f"\n  LSB likely: {lsb_likely}")
        print(f"  Zsteg recommended: {zsteg_likely}")
        print(f"  Steghide/Stegseek recommended: {is_jpeg}")
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
        print(f"{Fore.CYAN}[+] Variants → {out_dir.name}{Style.RESET_ALL}")
        add_to_summary("COLOR-REMAP",f"Saved to '{out_dir.name}'")
        for f in out_dir.glob("variant_*.png"):
            out=subprocess.getoutput(f"strings '{f}'")
            for pat in COMMON_FLAG_PATTERNS:
                for m in re.findall(pat,out,re.IGNORECASE):
                    print(f"{Fore.GREEN}[!] FLAG di {f.name}: {m}{Style.RESET_ALL}")
                    add_to_summary("REMAP-FLAG",f"{m} in {f.name}")
    except Exception as e:
        print(f"{Fore.RED}[COLOR-REMAP] Gagal: {e}{Style.RESET_ALL}")

# ── External Tools ───────────────────────────

def analyze_with_binwalk(filepath):
    if check_early_exit(): return
    out_dir=filepath.parent/f"_extracted_{filepath.name}"
    try:
        subprocess.run(["binwalk","-eM","--quiet",f"--directory={out_dir}",str(filepath)],
                       stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
        if out_dir.exists():
            print(f"{Fore.GREEN}[BINWALK] Ekstraksi selesai: {out_dir.name}{Style.RESET_ALL}")
            for nested in out_dir.rglob("*"):
                if nested.is_file(): analyze_strings_and_flags(nested)
        else: print(f"{Fore.YELLOW}[BINWALK] Tidak ada file tersembunyi.{Style.RESET_ALL}")
    except FileNotFoundError: print(f"{Fore.YELLOW}[BINWALK] Tidak terinstall.{Style.RESET_ALL}")
    except Exception as e: print(f"{Fore.RED}[BINWALK] Gagal: {e}{Style.RESET_ALL}")

def analyze_zsteg(filepath):
    if not AVAILABLE_TOOLS.get('zsteg'):
        print(f"{Fore.YELLOW}[ZSTEG] Tidak terinstall.{Style.RESET_ALL}"); return
    if check_early_exit(): return
    print(f"{Fore.GREEN}[ZSTEG] Full LSB analysis...{Style.RESET_ALL}")
    try:
        result=subprocess.run(["zsteg","-a",str(filepath)],capture_output=True,text=True,timeout=60)
        output=result.stdout+result.stderr
        print(output[:2000] if len(output)>2000 else output)
        collect_base64_from_text(output)
        for pat in COMMON_FLAG_PATTERNS:
            for m in re.findall(pat,output,re.IGNORECASE):
                add_to_summary("ZSTEG-FLAG",m)
    except subprocess.TimeoutExpired: print(f"{Fore.RED}[ZSTEG] Timeout.{Style.RESET_ALL}")
    except Exception as e: print(f"{Fore.RED}[ZSTEG] Gagal: {e}{Style.RESET_ALL}")

def analyze_steghide(filepath, password=None):
    if not AVAILABLE_TOOLS.get('steghide'):
        print(f"{Fore.YELLOW}[STEGHIDE] Tidak terinstall.{Style.RESET_ALL}"); return
    if check_early_exit(): return
    print(f"{Fore.GREEN}[STEGHIDE] Mencoba ekstraksi...{Style.RESET_ALL}")
    out_dir=filepath.parent/f"{filepath.stem}_steghide"; out_dir.mkdir(exist_ok=True)
    out_file=out_dir/"extracted.txt"
    try:
        cmd=["steghide","extract","-sf",str(filepath),"-xf",str(out_file),"-f"]
        if password: cmd+=["-p",password]
        result=subprocess.run(cmd,capture_output=True,text=True,timeout=30)
        if result.returncode==0 and out_file.exists() and out_file.stat().st_size>0:
            content=out_file.read_text(errors='ignore')
            print(f"{Fore.GREEN}[STEGHIDE] Berhasil!{Style.RESET_ALL}")
            print(content[:500])
            collect_base64_from_text(content)
            for pat in COMMON_FLAG_PATTERNS:
                for m in re.findall(pat,content,re.IGNORECASE):
                    add_to_summary("STEGHIDE-FLAG",m)
            add_to_summary("STEGHIDE-EXTRACT",f"Saved to '{out_file.name}'")
        else: print(f"{Fore.YELLOW}[STEGHIDE] Tidak ada data tersembunyi.{Style.RESET_ALL}")
    except subprocess.TimeoutExpired: print(f"{Fore.RED}[STEGHIDE] Timeout.{Style.RESET_ALL}")
    except Exception as e: print(f"{Fore.RED}[STEGHIDE] Gagal: {e}{Style.RESET_ALL}")

def analyze_stegseek(filepath, wordlist=None):
    """Brute-force steghide payload menggunakan stegseek + rockyou.txt"""
    if not AVAILABLE_TOOLS.get('stegseek'):
        print(f"{Fore.YELLOW}[STEGSEEK] Tidak terinstall. Jalankan --install.{Style.RESET_ALL}"); return
    if check_early_exit(): return

    # Cari wordlist
    wl = wordlist
    if not wl:
        for path in ROCKYOU_PATHS:
            if Path(path).exists():
                wl = path; break
    if not wl:
        print(f"{Fore.YELLOW}[STEGSEEK] rockyou.txt tidak ditemukan.{Style.RESET_ALL}")
        print(f"{Fore.YELLOW}           Gunakan --wordlist <path> atau install: sudo apt install wordlists{Style.RESET_ALL}")
        return

    print(f"{Fore.GREEN}[STEGSEEK] Brute-force dengan: {wl}{Style.RESET_ALL}")
    out_dir  = filepath.parent / f"{filepath.stem}_stegseek"
    out_dir.mkdir(exist_ok=True)
    out_file = out_dir / "stegseek_out"

    try:
        result = subprocess.run(
            ["stegseek", str(filepath), wl, str(out_file)],
            capture_output=True, text=True, timeout=600,
        )
        output = result.stdout + result.stderr
        print(f"{Fore.CYAN}[STEGSEEK] Output:{Style.RESET_ALL}")
        print(output[:3000] if len(output) > 3000 else output)

        # Ambil password dari output
        pw_match = re.search(r'Found passphrase:\s*"([^"]*)"', output)
        if pw_match:
            pw = pw_match.group(1)
            print(f"{Fore.GREEN}[STEGSEEK] Password ditemukan: \"{pw}\"{Style.RESET_ALL}")
            add_to_summary("STEGSEEK-PASS", f"Password: '{pw}'")

        # Cek flag di output stegseek
        for pat in COMMON_FLAG_PATTERNS:
            for m in re.findall(pat, output, re.IGNORECASE):
                add_to_summary("STEGSEEK-FLAG", m)

        # Baca file hasil ekstraksi
        # stegseek mungkin rename output file
        extracted_files = list(out_dir.glob("*"))
        for f in extracted_files:
            if f.is_file() and f.stat().st_size > 0:
                try:
                    content = f.read_text(errors='ignore')
                    print(f"{Fore.GREEN}[STEGSEEK] Konten dari {f.name}:{Style.RESET_ALL}")
                    print(content[:500])
                    collect_base64_from_text(content)
                    for pat in COMMON_FLAG_PATTERNS:
                        for m in re.findall(pat, content, re.IGNORECASE):
                            print(f"{Fore.GREEN}[!] FLAG: {m}{Style.RESET_ALL}")
                            add_to_summary("STEGSEEK-FLAG", m)
                    add_to_summary("STEGSEEK-EXTRACT", f"Saved to '{f.name}'")
                except: pass

        if result.returncode != 0 and not pw_match:
            print(f"{Fore.YELLOW}[STEGSEEK] Tidak ada password ditemukan.{Style.RESET_ALL}")

    except subprocess.TimeoutExpired:
        print(f"{Fore.RED}[STEGSEEK] Timeout (600s). File terlalu besar atau wordlist sangat panjang.{Style.RESET_ALL}")
    except Exception as e:
        print(f"{Fore.RED}[STEGSEEK] Gagal: {e}{Style.RESET_ALL}")

def analyze_outguess(filepath):
    if not AVAILABLE_TOOLS.get('outguess'):
        print(f"{Fore.YELLOW}[OUTGUESS] Tidak terinstall.{Style.RESET_ALL}"); return
    print(f"{Fore.GREEN}[OUTGUESS] Ekstraksi...{Style.RESET_ALL}")
    out_dir=filepath.parent/f"{filepath.stem}_outguess"; out_dir.mkdir(exist_ok=True)
    out_file=out_dir/"outguess.txt"
    try:
        result=subprocess.run(["outguess","-r",str(filepath),str(out_file)],
                               capture_output=True,text=True,timeout=30)
        if result.returncode==0 and out_file.exists():
            content=out_file.read_text(errors='ignore')
            print(content[:500])
            collect_base64_from_text(content)
            for pat in COMMON_FLAG_PATTERNS:
                for m in re.findall(pat,content,re.IGNORECASE):
                    add_to_summary("OUTGUESS-FLAG",m)
            add_to_summary("OUTGUESS-EXTRACT",f"Saved to '{out_file.name}'")
        else: print(f"{Fore.YELLOW}[OUTGUESS] Tidak ada data.{Style.RESET_ALL}")
    except subprocess.TimeoutExpired: print(f"{Fore.RED}[OUTGUESS] Timeout.{Style.RESET_ALL}")
    except Exception as e: print(f"{Fore.RED}[OUTGUESS] Gagal: {e}{Style.RESET_ALL}")

def analyze_foremost(filepath, quick=True):
    if not AVAILABLE_TOOLS.get('foremost'):
        print(f"{Fore.YELLOW}[FOREMOST] Tidak terinstall.{Style.RESET_ALL}"); return
    if quick and filepath.stat().st_size > 50*1024*1024:
        print(f"{Fore.YELLOW}[FOREMOST] File terlalu besar, skip quick mode.{Style.RESET_ALL}"); return
    print(f"{Fore.GREEN}[FOREMOST] File carving...{Style.RESET_ALL}")
    out_dir=filepath.parent/f"{filepath.stem}_foremost"
    try:
        subprocess.run(["foremost","-i",str(filepath),"-o",str(out_dir),"-v"],
                       capture_output=True,timeout=15 if quick else 60)
        files=list(out_dir.rglob("*")) if out_dir.exists() else []
        if files:
            print(f"{Fore.GREEN}[FOREMOST] {len(files)} file(s){Style.RESET_ALL}")
            for f in files[:5]:
                if f.is_file(): print(f"  - {f.name}"); analyze_strings_and_flags(f)
            add_to_summary("FOREMOST-EXTRACT",f"Saved to '{out_dir.name}'")
        else: print(f"{Fore.YELLOW}[FOREMOST] Tidak ada file.{Style.RESET_ALL}")
    except subprocess.TimeoutExpired: print(f"{Fore.RED}[FOREMOST] Timeout.{Style.RESET_ALL}")
    except Exception as e: print(f"{Fore.RED}[FOREMOST] Gagal: {e}{Style.RESET_ALL}")

def analyze_pngcheck(filepath):
    if not AVAILABLE_TOOLS.get('pngcheck'):
        print(f"{Fore.YELLOW}[PNGCHECK] Tidak terinstall.{Style.RESET_ALL}"); return
    print(f"{Fore.GREEN}[PNGCHECK] Validasi PNG...{Style.RESET_ALL}")
    try:
        result=subprocess.run(["pngcheck","-v",str(filepath)],capture_output=True,text=True,timeout=30)
        output=result.stdout+result.stderr
        print(f"{Fore.CYAN}{output}{Style.RESET_ALL}")
        collect_base64_from_text(output)
        if "error" in output.lower(): add_to_summary("PNGCHECK-ERROR","PNG bermasalah")
    except Exception as e: print(f"{Fore.RED}[PNGCHECK] Gagal: {e}{Style.RESET_ALL}")

def analyze_jpseek(filepath):
    tool=next((t for t in ['jpseek','jphs'] if AVAILABLE_TOOLS.get(t)),None)
    if not tool: print(f"{Fore.YELLOW}[JPSTEG] Tidak terinstall.{Style.RESET_ALL}"); return
    print(f"{Fore.GREEN}[JPSTEG] Analisis JPEG...{Style.RESET_ALL}")
    out_dir=filepath.parent/f"{filepath.stem}_jpsteg"; out_dir.mkdir(exist_ok=True)
    try:
        cmd=["jpseek",str(filepath),str(out_dir)] if tool=='jpseek' else \
            ["jphs","-e",str(filepath),str(out_dir/"jphs_output.txt")]
        result=subprocess.run(cmd,capture_output=True,text=True,timeout=30)
        output=result.stdout+result.stderr
        print(output[:1000])
        collect_base64_from_text(output)
    except subprocess.TimeoutExpired: print(f"{Fore.RED}[JPSTEG] Timeout.{Style.RESET_ALL}")
    except Exception as e: print(f"{Fore.RED}[JPSTEG] Gagal: {e}{Style.RESET_ALL}")

def analyze_graphicsmagick(filepath):
    if not AVAILABLE_TOOLS.get('identify'): return
    print(f"{Fore.GREEN}[GM-IDENTIFY] Properties gambar...{Style.RESET_ALL}")
    try:
        result=subprocess.run(["gm","identify","-verbose",str(filepath)],
                               capture_output=True,text=True,timeout=30)
        print(result.stdout[:1500])
        collect_base64_from_text(result.stdout)
    except Exception as e: print(f"{Fore.YELLOW}[GM-IDENTIFY] Gagal: {e}{Style.RESET_ALL}")

def analyze_exif_deep(filepath):
    print(f"{Fore.GREEN}[EXIF-DEEP] EXIF metadata mendalam...{Style.RESET_ALL}")
    try:
        result=subprocess.run(["exiftool","-a","-u","-g1",str(filepath)],
                               capture_output=True,text=True,timeout=30)
        output=result.stdout
        print(output[:2000])
        collect_base64_from_text(output)
        for pat in COMMON_FLAG_PATTERNS:
            for m in re.findall(pat,output,re.IGNORECASE):
                print(f"{Fore.GREEN}[!] FLAG di EXIF: {m}{Style.RESET_ALL}")
                add_to_summary("EXIF-FLAG",m)
        exif_dir=filepath.parent/f"{filepath.stem}_exif"; exif_dir.mkdir(exist_ok=True)
        (exif_dir/"full_exif.txt").write_text(output)
        add_to_summary("EXIF-EXTRACT","Saved to 'full_exif.txt'")
    except FileNotFoundError: print(f"{Fore.YELLOW}[EXIF-DEEP] ExifTool tidak terinstall.{Style.RESET_ALL}")
    except Exception as e: print(f"{Fore.RED}[EXIF-DEEP] Gagal: {e}{Style.RESET_ALL}")

# ── Brute Force (steghide manual) ────────────

def bruteforce_steghide(filepath, wordlist=None, delay=0.1, parallel=5):
    if not AVAILABLE_TOOLS.get('steghide'):
        print(f"{Fore.YELLOW}[BRUTEFORCE] Steghide tidak terinstall.{Style.RESET_ALL}"); return
    wordlist=wordlist or DEFAULT_WORDLIST
    print(f"{Fore.GREEN}[BRUTEFORCE] {parallel} thread, {len(wordlist)} password...{Style.RESET_ALL}")
    out_dir=filepath.parent/f"{filepath.stem}_bruteforce"; out_dir.mkdir(exist_ok=True)
    found={"value":False}
    def try_pw(pw):
        if found["value"] or check_early_exit(): return None
        try:
            out_file=out_dir/f"out_{pw}.txt"
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
                print(f"{Fore.GREEN}[BRUTEFORCE] BERHASIL! Password: {pw}{Style.RESET_ALL}")
                print(content[:200])
                collect_base64_from_text(content)
                for pat in COMMON_FLAG_PATTERNS:
                    for m in re.findall(pat,content,re.IGNORECASE):
                        add_to_summary("BRUTEFORCE-FLAG",f"pw='{pw}' → {m}")
                found["value"]=True; break
    if not found["value"]: print(f"{Fore.YELLOW}[BRUTEFORCE] Password tidak ditemukan.{Style.RESET_ALL}")

# ── PCAP ─────────────────────────────────────

def _tshark(filepath, *args, timeout=60):
    if not AVAILABLE_TOOLS.get('tshark'): return ""
    try:
        return subprocess.run(["tshark","-r",str(filepath)]+list(args),
                              capture_output=True,text=True,timeout=timeout).stdout
    except: return ""

def analyze_pcap_basic(filepath):
    if not AVAILABLE_TOOLS.get('capinfos'):
        print(f"{Fore.YELLOW}[PCAP] capinfos tidak terinstall.{Style.RESET_ALL}"); return
    print(f"{Fore.GREEN}[PCAP] Info capture...{Style.RESET_ALL}")
    try:
        result=subprocess.run(["capinfos",str(filepath)],capture_output=True,text=True,timeout=30)
        print(f"{Fore.CYAN}{result.stdout}{Style.RESET_ALL}")
        (filepath.parent/f"{filepath.stem}_pcap_info.txt").write_text(result.stdout)
        collect_base64_from_text(result.stdout)
        add_to_summary("PCAP-INFO","Info saved")
    except Exception as e: print(f"{Fore.RED}[PCAP] Gagal: {e}{Style.RESET_ALL}")

def extract_http_objects(filepath):
    if not AVAILABLE_TOOLS.get('tshark'): return
    print(f"{Fore.GREEN}[PCAP] Ekstrak HTTP objects...{Style.RESET_ALL}")
    out_dir=filepath.parent/f"{filepath.stem}_http_objects"; out_dir.mkdir(exist_ok=True)
    try:
        subprocess.run(["tshark","-r",str(filepath),"--export-objects",f"http,{out_dir}","-q"],
                       capture_output=True,text=True,timeout=120)
        files=list(out_dir.glob("*"))
        if files:
            print(f"{Fore.GREEN}[+] {len(files)} HTTP object(s){Style.RESET_ALL}")
            for f in files[:10]: print(f"  - {f.name}"); analyze_extracted_file(f)
            add_to_summary("PCAP-HTTP",f"{len(files)} objects → '{out_dir.name}'")
        else: print(f"{Fore.YELLOW}[!] Tidak ada HTTP objects{Style.RESET_ALL}")
    except Exception as e: print(f"{Fore.RED}[PCAP] HTTP gagal: {e}{Style.RESET_ALL}")

def extract_dns_queries(filepath):
    if not AVAILABLE_TOOLS.get('tshark'): return
    print(f"{Fore.GREEN}[PCAP] DNS queries...{Style.RESET_ALL}")
    output=_tshark(filepath,"-T","fields","-e","dns.qry.name","-Y","dns","-q")
    if output.strip():
        queries=[q for q in output.split('\n') if q]
        print(f"{Fore.CYAN}[+] {len(queries)} DNS queries{Style.RESET_ALL}")
        (filepath.parent/f"{filepath.stem}_dns_queries.txt").write_text(output)
        collect_base64_from_text(output)
        for q in queries[:20]:
            for pat in COMMON_FLAG_PATTERNS:
                for m in re.findall(pat,q,re.IGNORECASE): add_to_summary("PCAP-DNS-FLAG",m)
        add_to_summary("PCAP-DNS",f"{len(queries)} queries saved")
    else: print(f"{Fore.YELLOW}[!] Tidak ada DNS queries{Style.RESET_ALL}")

def extract_credentials(filepath):
    if not AVAILABLE_TOOLS.get('tshark'): return
    print(f"{Fore.GREEN}[PCAP] Mencari credentials...{Style.RESET_ALL}")
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
                print(f"  {proto}: {data[:100]}")
                f.write(f"{proto}:\n{data}\n\n")
                for pat in COMMON_FLAG_PATTERNS:
                    for m in re.findall(pat,data,re.IGNORECASE):
                        add_to_summary("PCAP-CREDS-FLAG",m)
        add_to_summary("PCAP-CREDENTIALS",f"Saved to '{creds_file.name}'")
    else: print(f"{Fore.YELLOW}[!] Tidak ada credentials{Style.RESET_ALL}")

def search_pcap_flags(filepath):
    if not AVAILABLE_TOOLS.get('tshark'): return
    print(f"{Fore.GREEN}[PCAP] Mencari flag dalam paket...{Style.RESET_ALL}")
    for label,extra in [("data",["-T","fields","-e","data","-q"]),
                        ("HTTP",["-T","fields","-e","http.file_data","-q"]),
                        ("TCP", ["-T","fields","-e","tcp.payload","-q"])]:
        out=_tshark(filepath,*extra,timeout=120)
        for pat in COMMON_FLAG_PATTERNS:
            for m in re.findall(pat,out,re.IGNORECASE):
                print(f"{Fore.GREEN}[!] FLAG di {label}: {m}{Style.RESET_ALL}")
                add_to_summary(f"PCAP-{label.upper()}-FLAG",m)

def reconstruct_streams(filepath):
    if not AVAILABLE_TOOLS.get('tshark'): return
    print(f"{Fore.GREEN}[PCAP] Rekonstruksi TCP streams...{Style.RESET_ALL}")
    out_dir=filepath.parent/f"{filepath.stem}_streams"; out_dir.mkdir(exist_ok=True)
    nums=set(_tshark(filepath,"-T","fields","-e","tcp.stream","-q").strip().split('\n'))
    nums=[s for s in nums if s]
    if not nums: print(f"{Fore.YELLOW}[!] Tidak ada TCP streams{Style.RESET_ALL}"); return
    print(f"{Fore.CYAN}[+] {len(nums)} stream(s){Style.RESET_ALL}")
    for num in nums[:10]:
        try:
            result=subprocess.run(["tshark","-r",str(filepath),"-q","-z",f"follow,tcp,ascii,{num}"],
                                  capture_output=True,text=True,timeout=30)
            (out_dir/f"stream_{num}.txt").write_text(result.stdout)
            for pat in COMMON_FLAG_PATTERNS:
                for m in re.findall(pat,result.stdout,re.IGNORECASE):
                    add_to_summary("PCAP-STREAM-FLAG",f"Stream {num}: {m}")
            collect_base64_from_text(result.stdout)
        except: continue
    add_to_summary("PCAP-STREAMS",f"{min(len(nums),10)} streams → '{out_dir.name}'")

def analyze_pcap_timeline(filepath):
    if not AVAILABLE_TOOLS.get('tshark'): return
    print(f"{Fore.GREEN}[PCAP-TIMELINE] Timeline HTTP...{Style.RESET_ALL}")
    out=_tshark(filepath,"-T","fields","-e","frame.time","-e","http.request.uri",
                "-e","http.request.method","-e","ip.src","-Y","http.request","-q")
    if not out.strip(): return
    lines=out.strip().split('\n')
    for i,line in enumerate(lines[:20],1):
        parts=line.split('\t')
        t=parts[0][:30] if parts else ''; m=parts[2][:8] if len(parts)>2 else ''
        uri=parts[1][:60] if len(parts)>1 else ''
        print(f"  [{i}] {t} | {m} {uri}")
    (filepath.parent/f"{filepath.stem}_timeline.txt").write_text("\n".join(lines))
    add_to_summary("PCAP-TIMELINE",f"{len(lines)} requests")

def detect_attack_patterns(filepath):
    if not AVAILABLE_TOOLS.get('tshark'): return
    print(f"{Fore.GREEN}[PCAP-ATTACK] Deteksi attack patterns...{Style.RESET_ALL}")
    http=_tshark(filepath,"-T","fields","-e","http.request.uri","-e","http.request.method","-Y","http","-q")
    sigs={'SQL Injection':r"(\bunion\b|\bselect\b|\binsert\b|\bdelete\b|\bdrop\b|%27|')",
          'XSS':r"(<script|javascript:|onerror=|onload=|alert\()",
          'LFI/RFI':r"(\.\.\/|\.\.\\|%2e%2e%2f|file:\/\/)",
          'Cmd Injection':r"(;|\||&&|\$\(|`)\s*(cat|ls|pwd|whoami|id)",
          'Path Traversal':r"(%2e%2e%2f|%2e%2e%5c){1,}"}
    found=False
    for name,pat in sigs.items():
        matches=re.findall(pat,http,re.IGNORECASE)
        if matches:
            found=True
            print(f"{Fore.RED}[!] {name}: {len(matches)} hits{Style.RESET_ALL}")
            add_to_summary("PCAP-ATTACK",f"{name}: {len(matches)}")
    if not found: print(f"{Fore.CYAN}[+] Tidak ada attack pattern{Style.RESET_ALL}")

def analyze_post_data(filepath):
    if not AVAILABLE_TOOLS.get('tshark'): return
    print(f"{Fore.GREEN}[PCAP-POST] Analisis POST data...{Style.RESET_ALL}")
    out=_tshark(filepath,"-T","fields","-e","http.request.method","-e","http.request.uri",
                "-e","http.file_data","-Y",'http.request.method == "POST"',"-q")
    if not out.strip(): print(f"{Fore.CYAN}[+] Tidak ada POST data{Style.RESET_ALL}"); return
    for pat in COMMON_FLAG_PATTERNS:
        for m in re.findall(pat,out,re.IGNORECASE): add_to_summary("PCAP-POST-FLAG",m)
    for pat in [r"(username|user|login)=[^&\s]{3,}",r"(password|pass|pwd)=[^&\s]{3,}"]:
        for m in re.findall(pat,out,re.IGNORECASE)[:5]:
            print(f"  Cred: {m[:80]}"); add_to_summary("PCAP-CREDENTIALS",str(m[:60]))

def check_unusual_ports(filepath):
    if not AVAILABLE_TOOLS.get('tshark'): return
    print(f"{Fore.GREEN}[PCAP] Port tidak biasa...{Style.RESET_ALL}")
    out=_tshark(filepath,"-T","fields","-e","tcp.dstport","-e","udp.dstport","-q")
    common={'80','443','22','21','53','25','110','143','993','995','8080','8443'}
    counts={}
    for line in out.split('\n'):
        for port in line.split('\t'):
            if port: counts[port]=counts.get(port,0)+1
    unusual={p:c for p,c in counts.items() if p not in common}
    if unusual:
        for port,cnt in sorted(unusual.items(),key=lambda x:x[1],reverse=True)[:10]:
            print(f"  Port {port}: {cnt} packets"); add_to_summary("PCAP-PORT",f"Port {port}: {cnt}")

def analyze_pcap_full(filepath):
    print(f"\n{Fore.BLUE}{'='*60}\nPCAP FULL ANALYSIS: {filepath.name}\n{'='*60}{Style.RESET_ALL}")
    analyze_pcap_basic(filepath); extract_http_objects(filepath)
    extract_dns_queries(filepath); extract_credentials(filepath)
    analyze_pcap_timeline(filepath); detect_attack_patterns(filepath)
    analyze_post_data(filepath); search_pcap_flags(filepath)
    reconstruct_streams(filepath); check_unusual_ports(filepath)
    print(f"{Fore.GREEN}[PCAP] Analisis selesai!{Style.RESET_ALL}")

# ── Disk Image ───────────────────────────────

def extract_compressed_disk(filepath):
    print(f"{Fore.CYAN}[DISK] Ekstrak compressed disk...{Style.RESET_ALL}")
    out_dir=filepath.parent/f"{filepath.stem}_extracted"; out_dir.mkdir(exist_ok=True)
    file_type=subprocess.getoutput(f"file -b '{filepath}'").lower()
    try:
        if "gzip" in file_type:
            import gzip
            orig="disk_image.dd"
            if 'was "' in file_type:
                s=file_type.find('was "')+5; e=file_type.find('"',s)
                if e>s: orig=file_type[s:e]
            out=out_dir/orig
            with gzip.open(filepath,'rb') as fi, open(out,'wb') as fo: shutil.copyfileobj(fi,fo)
            if out.exists() and out.stat().st_size>0:
                print(f"{Fore.GREEN}[+] GZIP → {out.name}{Style.RESET_ALL}"); return out
        elif "zip" in file_type:
            import zipfile
            sub=out_dir/f"{filepath.stem}_zip"; sub.mkdir(exist_ok=True)
            with zipfile.ZipFile(filepath,'r') as zf: zf.extractall(sub)
            files=[f for f in sub.rglob("*") if f.is_file()]
            if files:
                largest=max(files,key=lambda x:x.stat().st_size)
                print(f"{Fore.GREEN}[+] ZIP → {largest.name}{Style.RESET_ALL}"); return largest
    except Exception as e: print(f"{Fore.YELLOW}[!] Ekstraksi gagal: {e}{Style.RESET_ALL}")
    return filepath

def analyze_disk_image(filepath):
    print(f"{Fore.GREEN}[DISK] Analisis disk image (fast mode)...{Style.RESET_ALL}")
    out_dir=filepath.parent/f"{filepath.stem}_disk_analysis"; out_dir.mkdir(exist_ok=True)
    flags_found=[]; GREP="picoCTF|CTF{|flag{|FLAG{"
    try:
        print(f"{Fore.CYAN}[DISK] Ekstrak strings...{Style.RESET_ALL}")
        cmd1=f"strings -n 8 '{filepath}' | grep -iE '({GREP})' 2>/dev/null || strings -n 8 '{filepath}' | head -10000"
        cmd2=f"strings -e l -n 8 '{filepath}' | grep -iE '({GREP})' 2>/dev/null || strings -e l -n 8 '{filepath}' | head -5000"
        ascii_out=subprocess.run(cmd1,shell=True,capture_output=True,text=True,timeout=30).stdout
        uni_out=subprocess.run(cmd2,shell=True,capture_output=True,text=True,timeout=30).stdout
        all_str=ascii_out+"\n"+uni_out
        (out_dir/"extracted_strings.txt").write_text(all_str[:100000],errors='ignore')
        for pat in COMMON_FLAG_PATTERNS:
            for m in re.findall(pat,all_str,re.IGNORECASE)[:5]:
                if m not in flags_found:
                    flags_found.append(m)
                    print(f"{Fore.GREEN}[!] FLAG: {m}{Style.RESET_ALL}")
                    add_to_summary("DISK-FLAG",m)
        collect_base64_from_text(all_str[:50000])
        scan_size=min(10*1024*1024,filepath.stat().st_size)
        raw=filepath.read_bytes()[:scan_size]
        for ext,sig in {"png":b"\x89PNG","jpg":b"\xff\xd8\xff","zip":b"PK\x03\x04","pdf":b"%PDF","gif":b"GIF8"}.items():
            idx=raw.find(sig)
            if idx!=-1:
                print(f"  [+] {ext.upper()} at offset {idx}"); add_to_summary("DISK-FILE",f"{ext.upper()} at offset {idx}")
                chunk=raw[idx:idx+5120]
                result=subprocess.run(['strings','-n','8'],input=chunk,capture_output=True,text=True,timeout=5)
                for pat in COMMON_FLAG_PATTERNS[:2]:
                    for m in re.findall(pat,result.stdout,re.IGNORECASE)[:2]:
                        if m not in flags_found:
                            flags_found.append(m)
                            print(f"{Fore.GREEN}[!] FLAG embedded {ext}: {m}{Style.RESET_ALL}")
                            add_to_summary("DISK-EMBEDDED-FLAG",m)
        (out_dir/"analysis_summary.txt").write_text(
            f"Disk Analysis\n{'='*40}\nFile: {filepath.name}\n"
            f"Size: {filepath.stat().st_size}\nFlags: {len(flags_found)}\n"+"".join(f"  - {f}\n" for f in flags_found))
        add_to_summary("DISK-ANALYSIS",f"Results in '{out_dir.name}'")
        if not flags_found: print(f"{Fore.YELLOW}[!] Tidak ada flag ditemukan{Style.RESET_ALL}")
    except subprocess.TimeoutExpired: print(f"{Fore.RED}[DISK] Timeout.{Style.RESET_ALL}")
    except Exception as e: print(f"{Fore.RED}[DISK] Gagal: {e}{Style.RESET_ALL}")

# ── Windows Event Log ────────────────────────

def parse_raw_event_log(filepath):
    print(f"{Fore.GREEN}[RAW-EVENT] Parse event log...{Style.RESET_ALL}")
    try:
        raw=filepath.read_bytes()
        strings_data=''.join(chr(b) if 32<=b<=126 else '\n' for b in raw)
        for cat,pats in {"INSTALL":[r'MSI.*install',r'Installation'],"EXEC":[r'cmd\.exe',r'powershell\.exe'],
                         "SHUTDOWN":[r'Shutdown',r'EventID.*6008'],"LOGON":[r'Logon',r'EventID.*4624']}.items():
            for pat in pats:
                m=re.findall(pat,strings_data,re.IGNORECASE)
                if m: print(f"  [{cat}] {pat}: {len(m)} hits"); add_to_summary(f"EVENT-{cat}",f"{pat}: {len(m)}")
        flags_found=[]
        for pat in COMMON_FLAG_PATTERNS:
            for m in re.findall(pat,strings_data,re.IGNORECASE):
                if m not in flags_found:
                    flags_found.append(m)
                    print(f"{Fore.GREEN}[!] FLAG: {m}{Style.RESET_ALL}")
                    add_to_summary("EVENT-FLAG",m)
        if not flags_found:
            for b64 in re.findall(r'[A-Za-z0-9+/]{20,}={0,2}',strings_data)[:10]:
                decoded=decode_base64(b64)
                if decoded:
                    collect_base64_from_text(decoded)
                    for pat in COMMON_FLAG_PATTERNS:
                        for m in re.findall(pat,decoded,re.IGNORECASE):
                            print(f"{Fore.GREEN}[!] FLAG dari b64: {m}{Style.RESET_ALL}")
                            add_to_summary("EVENT-B64-FLAG",m)
    except Exception as e: print(f"{Fore.RED}[RAW-EVENT] Gagal: {e}{Style.RESET_ALL}")

def analyze_windows_event_logs(filepath):
    print(f"{Fore.GREEN}[WINDOWS-EVENT] Analisis Windows Event Logs...{Style.RESET_ALL}")
    parse_raw_event_log(filepath)

# ── Report ────────────────────────────────────

def print_final_report(filename):
    print(f"\n{Fore.YELLOW}{'='*60}\n📋 FINAL REPORT: {filename}\n{'='*60}{Style.RESET_ALL}")
    flags_found =[i for i in flag_summary if "-FLAG" in i or "FLAG-" in i]
    extractions =[i for i in flag_summary if "-EXTRACT" in i]
    analysis    =[i for i in flag_summary if "-FLAG" not in i and "FLAG-" not in i and "-EXTRACT" not in i]
    if flags_found:
        print(f"\n{Fore.GREEN}🚩 FLAGS ({len(flags_found)}):{Style.RESET_ALL}")
        for i,item in enumerate(flags_found,1):
            m=re.search(r'\[.*?\]\s*(.+)',item)
            print(f"{Fore.GREEN}  {i}. {m.group(1) if m else item}{Style.RESET_ALL}")
    if base64_collector:
        print(f"\n{Fore.CYAN}🔓 BASE64 ({len(base64_collector)}):{Style.RESET_ALL}")
        for i,item in enumerate(base64_collector[:5],1):
            print(f"  {i}. {item[:100]}{'...' if len(item)>100 else ''}")
        if len(base64_collector)>5: print(f"  ... dan {len(base64_collector)-5} lagi")
    if extractions:
        print(f"\n{Fore.BLUE}📦 EXTRACTIONS ({len(extractions)}):{Style.RESET_ALL}")
        for item in extractions: print(f"  • {item}")
    if analysis:
        print(f"\n{Fore.MAGENTA}🔍 ANALYSIS ({len(analysis)}):{Style.RESET_ALL}")
        for item in analysis: print(f"  • {item}")
    print(f"\n{Fore.YELLOW}📊 STATS: total={len(flag_summary)}, flags={len(flags_found)}, "
          f"extractions={len(extractions)}, base64={len(base64_collector)}{Style.RESET_ALL}")
    print(f"{Fore.YELLOW}{'='*60}{Style.RESET_ALL}")

# ── Main Processor ────────────────────────────

def _build_result():
    return {'flags':[i for i in flag_summary if "-FLAG" in i or "FLAG-" in i],
            'extractions':[i for i in flag_summary if "-EXTRACT" in i],
            'base64':base64_collector.copy()}

def process_file(filepath, args):
    print(f"\n{Fore.BLUE}{'='*60}\nPROCESSING: {filepath.name}\n{'='*60}{Style.RESET_ALL}")
    reset_globals()
    repaired=fix_header(filepath)
    print(f"\n{Fore.GREEN}[METADATA]{Style.RESET_ALL}")
    file_desc=subprocess.getoutput(f"file -b '{repaired}'").lower()
    print(f"Type: {file_desc}")
    try:
        exif_out=subprocess.getoutput(f"exiftool '{repaired}'")
        print(f"{Fore.CYAN}{exif_out}{Style.RESET_ALL}")
        collect_base64_from_text(exif_out)
    except: pass
    analyze_strings_and_flags(repaired, args.format)
    if args.decode or args.extract or args.all or args.auto:
        auto_decode_and_extract(repaired)
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
    if "gzip" in file_desc and (".dd" in file_desc or ".img" in file_desc):
        repaired=extract_compressed_disk(repaired); is_disk=True
    elif is_disk and ("gzip" in file_desc or "zip" in file_desc):
        repaired=extract_compressed_disk(repaired)

    # ── QUICK MODE ─────────────────────────────
    if args.quick:
        print(f"\n{Fore.MAGENTA}[QUICK-MODE] Ultra-fast{Style.RESET_ALL}")
        analyze_strings_and_flags(repaired,args.format)
        auto_decode_and_extract(repaired)
        if is_image:
            if is_png and AVAILABLE_TOOLS.get('zsteg'): analyze_zsteg(repaired)
            if check_early_exit(): print_final_report(filepath.name); return _build_result()
            # Stegseek quick (lebih cepat dari steghide brute force)
            if AVAILABLE_TOOLS.get('stegseek'): analyze_stegseek(repaired, getattr(args,'wordlist',None))
            if check_early_exit(): print_final_report(filepath.name); return _build_result()
            if AVAILABLE_TOOLS.get('steghide'): analyze_steghide(repaired)
        if is_pcap: analyze_pcap_basic(repaired); search_pcap_flags(repaired)
        print_final_report(filepath.name); return _build_result()

    # ── PCAP ONLY ──────────────────────────────
    if args.pcap and is_pcap:
        analyze_pcap_full(repaired); print_final_report(filepath.name); return _build_result()

    # ── ALL / AUTO ─────────────────────────────
    if args.all or args.auto:
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
        if args.bruteforce and is_image:
            wl=DEFAULT_WORDLIST
            if args.wordlist and Path(args.wordlist).exists():
                wl=Path(args.wordlist).read_text().splitlines()
            bruteforce_steghide(repaired,wl,args.delay,args.parallel)
        if is_disk: analyze_disk_image(repaired)
        if is_evtlog: analyze_windows_event_logs(repaired)

    # ── SELECTIVE ──────────────────────────────
    else:
        if is_image:
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
        elif is_archive:
            analyze_with_binwalk(repaired)
            if args.foremost: analyze_foremost(repaired)
        elif is_disk: analyze_disk_image(repaired)
        elif is_evtlog: analyze_windows_event_logs(repaired)

    print_final_report(filepath.name)
    return _build_result()

# ── Entry Point ───────────────────────────────

def main():
    print(f"{Fore.CYAN}{'='*50}\n   ForesTools v2.0 — CTF Forensic Toolkit\n{'='*50}{Style.RESET_ALL}")
    check_tool_availability()
    p=argparse.ArgumentParser(
        description="ForesTools v2.0 — CTF Forensic Toolkit",
        formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("files",nargs="+",help="File(s), wildcard, atau direktori")
    p.add_argument("-f","--format",default=None,help="Custom flag prefix (e.g. 'picoCTF{')")
    modes=p.add_argument_group("Modes")
    modes.add_argument("--quick",  action="store_true",help="Ultra-fast: strings+zsteg+stegseek+early exit")
    modes.add_argument("--auto",   action="store_true",help="Auto-detect semua tools")
    modes.add_argument("--all",    action="store_true",help="Paksa semua tool")
    modes.add_argument("--pcap",   action="store_true",help="Full PCAP analysis")
    modes.add_argument("--disk",   action="store_true",help="Disk image analysis")
    modes.add_argument("--windows",action="store_true",help="Windows Event Log")
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
    bf.add_argument("--bruteforce",action="store_true",help="Brute-force steghide (wordlist)")
    bf.add_argument("--wordlist",  type=str,           help="Custom wordlist (default: rockyou.txt untuk stegseek)")
    bf.add_argument("--delay",     type=float,default=0.1,help="Delay (default: 0.1)")
    bf.add_argument("--parallel",  type=int,  default=5,  help="Threads (default: 5)")
    args=p.parse_args()
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
# MAIN
# ─────────────────────────────────────────────
main() {
    banner

    for arg in "$@"; do
        case "$arg" in
            --install)   install_tools ;;
            -h|--help)   usage; exit 0 ;;
        esac
    done

    if [[ $# -eq 0 ]]; then usage; exit 0; fi

    local py
    py=$(check_python) || die "Python 3.8+ tidak ditemukan. Install: sudo apt install python3"
    info "Python: $py ($(${py} --version 2>&1))"

    for arg in "$@"; do
        if [[ "$arg" == "--update-deps" ]]; then
            [[ -d "$VENV_DIR" ]] && rm -rf "$VENV_DIR"
            info "Venv dihapus, akan dibuat ulang..."
            break
        fi
    done

    setup_venv "$py"
    check_system_tools

    # Tulis Python engine ke file temp
    write_python_engine
    chmod +x "$PYTHON_INLINE"

    # Filter flag milik shell sebelum dikirim ke Python
    local python_args=()
    for arg in "$@"; do
        [[ "$arg" != "--update-deps" ]] && python_args+=("$arg")
    done

    echo ""
    info "Menjalankan ForesTools..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    python "$PYTHON_INLINE" "${python_args[@]}"

    # Bersihkan file engine temp (opsional, bisa di-comment kalau ingin debug)
    # rm -f "$PYTHON_INLINE"
}

main "$@"
