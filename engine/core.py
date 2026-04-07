"""RAVEN core — globals, utils, flag scanner, event log."""

import subprocess
import os
import re
import base64
import math
import time
import string
from pathlib import Path
from colorama import Fore, Style
from threading import Lock

# ── Globals ──────────────────────────────────
AVAILABLE_TOOLS = {}
FLAG_FOUND = False
FLAG_LOCK = Lock()
flag_summary = []
base64_collector = []
found_flags_set = set()
tool_log = []
event_log = []  # [{step, tool, result, detail, ts}]

DEFAULT_WORDLIST = [
    "password", "123456", "12345678", "123456789", "flag", "ctf", "steg", "hack", "test",
    "key", "secret", "admin", "root", "user", "pass", "letmein", "welcome", "monkey",
    "dragon", "master", "hello", "shadow", "sunshine", "princess", "football", "baseball",
    "soccer", "password1", "password123", "qwerty", "abc123", "iloveyou", "admin123",
    "666666", "888888", "000000", "111111", "222222", "333333", "444444", "555555",
    "777777", "999999", "aaaaaa", "bbbbbb", "cccccc", "dddddd", "eeeeee", "ffffff",
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
    r'picoCTF\[[^\]]+\]',
    r'CTF\[[^\]]+\]',
    r'flag\[[^\]]+\]',
    r'FLAG\[[^\]]+\]',
    r'REDLIMIT\[[^\]]+\]',
    r'[A-Za-z0-9_]{3,}\[[^\]]{3,}\]',
]

FILE_SIGNATURES = {
    "png": b"\x89\x50\x4E\x47\x0D\x0A\x1A\x0A",
    "jpg": b"\xFF\xD8\xFF",
    "pdf": b"\x25\x50\x44\x46",
    "gif": b"\x47\x49\x46\x38",
    "zip": b"\x50\x4B\x03\x04",
    "rar": b"\x52\x61\x72\x21\x1A\x07",
    "7z": b"\x37\x7A\xBC\xAF\x27\x1C",
    "elf": b"\x7F\x45\x4C\x46",
    "exe": b"\x4D\x5A",
    "sqlite": b"\x53\x51\x4C\x69\x74\x65\x20\x66\x6F\x72\x6D\x61\x74\x20\x33",
    "pcap": b"\xD4\xC3\xB2\xA1",
    "pcapng": b"\x0A\x0D\x0D\x0A",
    "bmp": b"\x42\x4D",
    "wav": b"\x52\x49\x46\x46",
    "mp3": b"\x49\x44\x33",
    "docx": b"\x50\x4B\x03\x04",
    "class": b"\xCA\xFE\xBA\xBE",
    "swf": b"\x46\x57\x53",
}

MAGIC_MAP = {
    b"\x89\x50\x4E\x47": ("png", "PNG Image"),
    b"\xFF\xD8\xFF": ("jpg", "JPEG Image"),
    b"\x50\x4B\x03\x04": ("zip", "ZIP Archive"),
    b"\x50\x4B\x05\x06": ("zip", "ZIP Archive (empty)"),
    b"\x25\x50\x44\x46": ("pdf", "PDF Document"),
    b"\x47\x49\x46\x38": ("gif", "GIF Image"),
    b"\x7F\x45\x4C\x46": ("elf", "ELF Executable"),
    b"\x4D\x5A": ("exe", "Windows PE/EXE"),
    b"\xD4\xC3\xB2\xA1": ("pcap", "PCAP Capture"),
    b"\x0A\x0D\x0D\x0A": ("pcapng", "PCAPNG Capture"),
    b"\x42\x4D": ("bmp", "BMP Image"),
    b"\x52\x61\x72\x21": ("rar", "RAR Archive"),
    b"\x37\x7A\xBC\xAF": ("7z", "7-Zip Archive"),
    b"\xCA\xFE\xBA\xBE": ("class", "Java Class"),
    b"\x1F\x8B": ("gz", "GZIP Archive"),
    b"\x42\x5A\x68": ("bz2", "BZ2 Archive"),
    b"\x75\x73\x74\x61": ("tar", "TAR Archive"),
    b"\xD0\xCF\x11\xE0": ("doc", "MS Office (old)"),
    b"\xEB\x52\x90\x4E\x54\x46\x53": ("ntfs_disk", "NTFS Disk Image"),
    b"\xEB\x58\x90\x4E\x54\x46\x53": ("ntfs_disk", "NTFS Disk Image"),
    b"\xEB\x5A\x90\x4E\x54\x46\x53": ("ntfs_disk", "NTFS Disk Image"),
    b"\xEB\x52\x90\x4D\x53\x44\x4F": ("ntfs_disk", "FAT/NTFS Disk Image"),
}

DISK_INDICATORS = [
    "dos/mbr boot sector", "ntfs", "fat12", "fat16", "fat32",
    "ext2", "ext3", "ext4", "iso 9660", "squashfs", "vmware",
    "virtualbox", "qemu", "disk image", "oem-id",
]

MEMORY_INDICATORS = ["data"]


# ── Utility Functions ─────────────────────────


def check_tool_availability():
    """Cek semua tools yang tersedia di sistem."""
    tools = {
        "zsteg": "zsteg", "steghide": "steghide", "stegseek": "stegseek",
        "outguess": "outguess", "foremost": "foremost", "pngcheck": "pngcheck",
        "jpseek": "jpseek", "jphs": "jphs", "exiftool": "exiftool",
        "binwalk": "binwalk", "identify": "gm", "tshark": "tshark",
        "tcpdump": "tcpdump", "capinfos": "capinfos",
        "fcrackzip": "fcrackzip", "john": "john", "hashcat": "hashcat",
        "pdfcrack": "pdfcrack", "pdfinfo": "pdfinfo", "pdftotext": "pdftotext",
        "vol": "vol", "volatility": "volatility", "volatility3": "volatility3",
        "unzip": "unzip", "7z": "7z",
        "mmls": "mmls", "fls": "fls", "icat": "icat",
        "sleuthkit": "mmls",
    }
    global AVAILABLE_TOOLS
    AVAILABLE_TOOLS = {}
    for name, cmd in tools.items():
        probe = f"which {cmd}" if os.name != "nt" else f"where {cmd}"
        result = subprocess.run(probe, shell=True, capture_output=True, text=True)
        AVAILABLE_TOOLS[name] = result.returncode == 0
        color = Fore.GREEN if AVAILABLE_TOOLS[name] else Fore.RED
        status = "Available" if AVAILABLE_TOOLS[name] else "Missing"
        print(f"{color}[TOOL] {name}: {status}{Style.RESET_ALL}")
    return AVAILABLE_TOOLS


def reset_globals():
    """Reset semua global variables."""
    global flag_summary, base64_collector, FLAG_FOUND, found_flags_set, tool_log, event_log
    flag_summary = []
    base64_collector = []
    FLAG_FOUND = False
    found_flags_set = set()
    tool_log = []
    event_log = []


def log_event(step, tool, result, detail=""):
    """Catat event untuk writeup generation."""
    global event_log
    event_log.append({
        "step": step,
        "tool": tool,
        "result": result,
        "detail": detail,
        "ts": time.time(),
    })


def log_tool(tool_name, status, result=""):
    """Catat tool yang dijalankan beserta statusnya."""
    global tool_log
    tool_log.append({
        "tool": tool_name,
        "status": status,
        "result": result,
    })


def check_early_exit():
    """Cek apakah flag sudah ditemukan (early exit)."""
    return FLAG_FOUND


def signal_flag_found():
    """Set flag FOUND (thread-safe)."""
    global FLAG_FOUND
    with FLAG_LOCK:
        FLAG_FOUND = True


def add_to_summary(category, content):
    """Tambah entry ke flag summary."""
    entry = f"[{category}] {content.strip()}"
    if entry not in flag_summary:
        flag_summary.append(entry)
    if "FLAG" in category:
        signal_flag_found()


def calculate_entropy(data):
    """Hitung entropy Shannon dari data binary."""
    if not data:
        return 0.0
    entropy = 0.0
    length = len(data)
    for x in range(256):
        count = data.count(x)
        if count == 0:
            continue
        p = count / length
        entropy -= p * math.log2(p)
    return entropy


def decode_base64(candidate):
    """Decode base64 string, return None jika gagal."""
    try:
        clean = re.sub(r'[^A-Za-z0-9+/=]', '', candidate)
        if len(clean) < 8 or len(clean) % 4 != 0:
            return None
        decoded = base64.b64decode(clean, validate=True)
        s = decoded.decode('utf-8', errors='ignore')
        if all(c.isprintable() or c.isspace() for c in s) and len(s.strip()) > 4:
            return s
    except:
        pass
    return None


def detect_file_extension(header):
    """Deteksi tipe file dari magic bytes."""
    if header.startswith(b'\x89PNG'):
        return 'png'
    if header.startswith(b'\xff\xd8\xff'):
        return 'jpg'
    if header.startswith(b'GIF8'):
        return 'gif'
    if header.startswith(b'%PDF'):
        return 'pdf'
    if header.startswith(b'PK'):
        return 'zip'
    if header.startswith(b'\x42\x4d'):
        return 'bmp'
    return 'bin'


def collect_base64_from_text(text):
    """Cari dan decode base64 dari teks."""
    global found_flags_set
    for m in re.findall(r'[A-Za-z0-9+/]{12,}=*', text):
        decoded = decode_base64(m)
        if decoded:
            entry = f"Raw: {m} -> Decoded: {decoded}"
            if entry not in base64_collector:
                base64_collector.append(entry)
                add_to_summary("B64-COLLECTOR", decoded)
                for pat in COMMON_FLAG_PATTERNS:
                    for fm in re.findall(pat, decoded, re.IGNORECASE):
                        fm_clean = fm.strip()
                        add_to_summary("B64-FLAG", fm_clean)
                        if fm_clean not in found_flags_set:
                            found_flags_set.add(fm_clean)
                            print(f"\n{Fore.GREEN}{'─' * 50}")
                            print(f"  🚩 FLAG dari Base64!")
                            print(f"  {Fore.YELLOW}{fm_clean}{Style.RESET_ALL}")
                            print(f"{Fore.GREEN}  Raw B64: {m[:60]}...{Style.RESET_ALL}")
                            print(f"{Fore.GREEN}{'─' * 50}{Style.RESET_ALL}\n")


def detect_scattered_flag(raw_data):
    """Deteksi flag yang tersebar di raw bytes."""
    try:
        cleaned = ''.join(chr(b) for b in raw_data if 32 <= b <= 126)
        for pat in COMMON_FLAG_PATTERNS:
            for m in re.findall(pat, cleaned, re.IGNORECASE):
                add_to_summary("SCATTERED-FLAG", m)
    except:
        pass


def scan_text_for_flags(text, source=""):
    """Scan teks untuk flag patterns — dedup ketat."""
    global found_flags_set
    found = []
    for pat in COMMON_FLAG_PATTERNS:
        for m in re.findall(pat, text, re.IGNORECASE):
            m_clean = m.strip()
            label = f"FLAG-{source}" if source else "AUTO-FLAG"
            add_to_summary(label, m_clean)
            if m_clean not in found_flags_set:
                found_flags_set.add(m_clean)
                found.append(m_clean)
                print(f"\n{Fore.GREEN}{'─' * 50}")
                print(f"  🚩 FLAG DITEMUKAN!")
                print(f"  {Fore.YELLOW}{m_clean}{Style.RESET_ALL}")
                print(f"{Fore.GREEN}  Sumber : {source or 'auto'}{Style.RESET_ALL}")
                print(f"{Fore.GREEN}{'─' * 50}{Style.RESET_ALL}\n")
    collect_base64_from_text(text)
    return found


# ── Deobfuscation ─────────────────────────────


def deobfuscate_string(s):
    """Coba semua teknik deobfuscation pada sebuah string."""
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
    for shift in range(1, 26):
        result = []
        for c in s:
            if c.isupper():
                result.append(chr((ord(c) - 65 + shift) % 26 + 65))
            elif c.islower():
                result.append(chr((ord(c) - 97 + shift) % 26 + 97))
            else:
                result.append(c)
        results[f'caesar_{shift}'] = ''.join(result)
    
    # Base64 decode
    b64 = decode_base64(s)
    if b64:
        results['base64'] = b64
    
    # Hex decode
    try:
        clean_hex = re.sub(r'[^0-9a-fA-F]', '', s)
        if len(clean_hex) >= 8 and len(clean_hex) % 2 == 0:
            results['hex'] = bytes.fromhex(clean_hex).decode('utf-8', errors='ignore')
    except:
        pass

    return results


def auto_detect_and_run(filepath, args):
    """Auto-detect tipe file dan jalankan tools yang sesuai."""
    from pathlib import Path
    fp = Path(filepath)
    ext = fp.suffix.lower()

    # Image files
    if ext in [".png", ".jpg", ".jpeg", ".gif", ".bmp"]:
        from . import stego
        stego.analyze_file(fp, args)

    # PCAP files
    elif ext in [".pcap", ".pcapng", ".cap"]:
        from . import pcap
        pcap.analyze_file(fp, args)

    # Binary files
    elif ext in [".elf", ".exe", ".bin", ".out"] or not ext:
        # Cek apakah ELF/PE binary
        header = fp.read_bytes()[:4]
        if header[:2] == b'\x7fELF' or header[:2] == b'MZ':
            from . import reversing
            reversing.analyze_file(fp, args)

    # Text files
    elif ext in [".txt", ".csv", ".md", ".json", ".xml"]:
        content = fp.read_text(errors="ignore")
        # Check for crypto patterns
        if any(kw in content.lower() for kw in ["rsa", "n=", "e=", "ciphertext", "encrypted"]):
            from . import crypto
            crypto.analyze_file(fp, args)

    # Log files
    elif ext in [".log"]:
        from . import forensics
        forensics.analyze_file(fp, args)

    # Registry files
    elif ext == ".reg":
        from . import forensics
        forensics.analyze_file(fp, args)

    # Archive files
    elif ext in [".zip", ".rar", ".7z"]:
        from . import forensics
        forensics.analyze_file(fp, args)
