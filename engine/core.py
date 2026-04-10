#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
RAVEN CTF Toolkit - Core Utilities Module

This module contains core utilities used across all RAVEN modules:
- Flag detection and tracking
- Tool availability checking
- Logging and output formatting
- File signature detection
- Common utilities and constants

Version: 6.0
Author: Syaaddd
"""

import os
import sys
import re
import math
import base64
import struct
import hashlib
import binascii
import subprocess
import threading
import shutil
from pathlib import Path
from collections import Counter
from typing import Dict, List, Optional, Tuple, Set

try:
    from colorama import Fore, Back, Style, init
    init(autoreset=True)
    HAS_COLORAMA = True
except ImportError:
    print("ERROR: colorama not installed. Run: pip install colorama")
    HAS_COLORAMA = False
    # Fallback: create dummy classes
    class Fore:
        GREEN = YELLOW = RED = CYAN = MAGENTA = BLUE = RESET = ''
    class Style:
        BRIGHT = DIM = NORMAL = RESET_ALL = ''

try:
    import numpy as np
    HAS_NUMPY = True
except ImportError:
    HAS_NUMPY = False

try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False

# ─────────────────────────────────────────────
# GLOBAL STATE
# ─────────────────────────────────────────────

# Flag tracking with thread safety
flag_summary: List[str] = []
base64_collector: List[str] = []
FLAG_FOUND: bool = False
found_flags_set: Set[str] = set()
tool_log: List[Dict] = []
FLAG_LOCK = threading.Lock()
AVAILABLE_TOOLS: Dict[str, bool] = {}

# ─────────────────────────────────────────────
# FILE SIGNATURES & MAGIC BYTES
# ─────────────────────────────────────────────

FILE_SIGNATURES: Dict[str, bytes] = {
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
    "docx":   b"\x50\x4B\x03\x04",
    "class":  b"\xCA\xFE\xBA\xBE",
    "swf":    b"\x46\x57\x53",
}

MAGIC_MAP: Dict[bytes, Tuple[str, str]] = {
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
    b"\xEB\x52\x90\x4E\x54\x46\x53": ("ntfs_disk", "NTFS Disk Image"),
    b"\xEB\x58\x90\x4E\x54\x46\x53": ("ntfs_disk", "NTFS Disk Image"),
    b"\xEB\x5A\x90\x4E\x54\x46\x53": ("ntfs_disk", "NTFS Disk Image"),
    b"\xEB\x52\x90\x4D\x53\x44\x4F": ("ntfs_disk", "FAT/NTFS Disk Image"),
}

DISK_INDICATORS: List[str] = [
    "dos/mbr boot sector", "ntfs", "fat12", "fat16", "fat32",
    "ext2", "ext3", "ext4", "iso 9660", "squashfs", "vmware",
    "virtualbox", "qemu", "disk image", "oem-id",
]

MEMORY_INDICATORS: List[str] = ["data"]

# ─────────────────────────────────────────────
# WORDLISTS & PATHS
# ─────────────────────────────────────────────

DEFAULT_WORDLIST: List[str] = [
    "", "password", "123456", "12345678", "qwerty", "abc123",
    "monkey", "1234567", "letmein", "trustno1", "dragon",
    "baseball", "iloveyou", "master", "sunshine", "ashley",
    "bailey", "passw0rd", "shadow", "123123", "654321",
    "superman", "qazwsx", "michael", "football", "password1",
    "password123", "welcome", "admin", "admin123", "root",
    "toor", "pass", "test", "guest", "master123",
    "changeme", "letmein123", "qwerty123", "123456789", "1234567890",
    "secret", "flag", "ctf", "steg", "crypto", "forensics",
    "hidden", "phantom", "picoCTF", "lks", "dsj",
    "P@ssw0rd", "s3cr3t", "fl4g", "ctf2024", "ctf2025", "ctf2026",
]

ROCKYOU_PATHS: List[str] = [
    "/usr/share/wordlists/rockyou.txt",
    "/usr/share/seclists/Passwords/rockyou.txt",
    "/opt/wordlists/rockyou.txt",
    "/usr/share/wordlist/rockyou.txt",
    "./rockyou.txt",
    "/usr/share/metasploit-framework/data/wordlists/rockyou.txt",
]

CTF_WORDLIST_PATHS: List[str] = [
    "./wordlists/ctf_passwords.txt",
    "../wordlists/ctf_passwords.txt",
    "../../wordlists/ctf_passwords.txt",
    "$HOME/.raven/wordlists/ctf_passwords.txt",
    "/usr/share/wordlists/ctf_passwords.txt",
]

COMMON_FLAG_PATTERNS: List[str] = [
    r'flag\{[^}]+\}',
    r'FLAG\{[^}]+\}',
    r'Flag\{[^}]+\}',
    r'CTF\{[^}]+\}',
    r'picoCTF\{[^}]+\}',
    r'actf\{[^}]+\}',
    r'utflag\{[^}]+\}',
    r'hsctf\{[^}]+\}',
    r'lks\{[^}]+\}',
    r'dsj\{[^}]+\}',
]

# ─────────────────────────────────────────────
# CORE UTILITY FUNCTIONS
# ─────────────────────────────────────────────

def check_tool_availability() -> Dict[str, bool]:
    """
    Check availability of all optional tools.
    
    Returns:
        Dict[str, bool]: Dictionary mapping tool names to availability status
    """
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
        probe = f"where {cmd}" if os.name == "nt" else f"which {cmd}"
        result = subprocess.run(probe, shell=True, capture_output=True, text=True)
        AVAILABLE_TOOLS[name] = result.returncode == 0
        color = Fore.GREEN if AVAILABLE_TOOLS[name] else Fore.RED
        status = "Available" if AVAILABLE_TOOLS[name] else "Missing"
        print(f"{color}[TOOL] {name}: {status}{Style.RESET_ALL}")
    
    return AVAILABLE_TOOLS


def reset_globals() -> None:
    """Reset all global tracking variables to initial state."""
    global flag_summary, base64_collector, FLAG_FOUND, found_flags_set, tool_log
    flag_summary = []
    base64_collector = []
    FLAG_FOUND = False
    found_flags_set = set()
    tool_log = []


def log_tool(tool_name: str, status: str, result: str = "") -> None:
    """
    Log tool execution with status for tracking and debugging.
    
    Args:
        tool_name: Name of the tool that was run
        status: Status of execution ("✅ Found", "⬜ Nothing", "⏭ Skipped", "❌ Error")
        result: Optional result/output from tool
    """
    tool_log.append({
        "tool": tool_name,
        "status": status,
        "result": result,
    })


def check_early_exit() -> bool:
    """
    Check if flag has been found for early exit optimization.
    
    Returns:
        bool: True if flag was found, False otherwise
    """
    return FLAG_FOUND


def signal_flag_found() -> None:
    """Thread-safe signal that a flag has been discovered."""
    global FLAG_FOUND
    with FLAG_LOCK:
        FLAG_FOUND = True


def add_to_summary(category: str, content: str) -> None:
    """
    Add finding to summary list and check for flags.
    
    Args:
        category: Category of the finding (e.g., "LSB", "B64-FLAG", "STEGHIDE")
        content: Content/description of the finding
    """
    entry = f"[{category}] {content.strip()}"
    if entry not in flag_summary:
        flag_summary.append(entry)
    
    if "FLAG" in category:
        signal_flag_found()


def calculate_entropy(data: bytes) -> float:
    """
    Calculate Shannon entropy of data.
    
    Args:
        data: Bytes to calculate entropy for
        
    Returns:
        float: Entropy value (0.0 to 8.0 for bytes)
    """
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


def decode_base64(candidate: str) -> Optional[str]:
    """
    Attempt to decode a Base64 string.
    
    Args:
        candidate: Potential Base64 string
        
    Returns:
        Optional[str]: Decoded string if valid, None otherwise
    """
    try:
        clean = re.sub(r'[^A-Za-z0-9+/=]', '', candidate)
        if len(clean) < 8 or len(clean) % 4 != 0:
            return None
        
        decoded = base64.b64decode(clean, validate=True)
        s = decoded.decode('utf-8', errors='ignore')
        
        if all(c.isprintable() or c.isspace() for c in s) and len(s.strip()) > 4:
            return s
    except Exception:
        pass
    
    return None


def detect_file_extension(header: bytes) -> str:
    """
    Detect file type from magic bytes.
    
    Args:
        header: First bytes of file
        
    Returns:
        str: File extension/type detection result
    """
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
    if header.startswith(b'\xff\xfb') or header.startswith(b'ID3'):
        return 'mp3'
    return 'bin'


def collect_base64_from_text(text: str) -> None:
    """
    Find and decode Base64 strings in text, scan for flags.
    
    Args:
        text: Text content to scan for Base64
    """
    global found_flags_set
    
    for m in re.findall(r'[A-Za-z0-9+/]{12,}=?', text):
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
                            print(f"  🚩 FLAG from Base64!")
                            print(f"  {Fore.YELLOW}{fm_clean}{Style.RESET_ALL}")
                            print(f"{Fore.GREEN}  Raw B64: {m[:60]}...{Style.RESET_ALL}")
                            print(f"{Fore.GREEN}{'─' * 50}{Style.RESET_ALL}\n")


def detect_scattered_flag(raw_data: bytes) -> None:
    """
    Detect flag patterns scattered across raw binary data.
    
    Args:
        raw_data: Raw bytes to scan
    """
    try:
        cleaned = ''.join(chr(b) for b in raw_data if 32 <= b <= 126)
        for pat in COMMON_FLAG_PATTERNS:
            for m in re.findall(pat, cleaned, re.IGNORECASE):
                add_to_summary("SCATTERED-FLAG", m)
    except Exception:
        pass


def scan_text_for_flags(text: str, source: str = "") -> List[str]:
    """
    Scan text content for flag patterns with deduplication.
    
    Args:
        text: Text content to scan
        source: Source identifier (e.g., "strings", "lsb", "metadata")
        
    Returns:
        List[str]: List of flags found
    """
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
                print(f"  🚩 FLAG FOUND!")
                print(f"  {Fore.YELLOW}{m_clean}{Style.RESET_ALL}")
                print(f"{Fore.GREEN}  Source: {source or 'auto'}{Style.RESET_ALL}")
                print(f"{Fore.GREEN}{'─' * 50}{Style.RESET_ALL}\n")
    
    collect_base64_from_text(text)
    return found


def get_file_type(filepath: str) -> Tuple[str, str]:
    """
    Detect file type using magic bytes.
    
    Args:
        filepath: Path to file
        
    Returns:
        Tuple[str, str]: (file_type, description)
    """
    try:
        with open(filepath, 'rb') as f:
            header = f.read(32)
        
        for magic, (ftype, desc) in MAGIC_MAP.items():
            if header.startswith(magic):
                return ftype, desc
        
        # Fallback to extension
        ext = Path(filepath).suffix.lower().lstrip('.')
        return ext, f"Unknown ({ext.upper() if ext else 'No extension'})"
    
    except Exception as e:
        return "unknown", f"Error reading file: {e}"


def print_banner() -> None:
    """Print RAVEN ASCII art banner."""
    banner_text = r"""

  ██████╗   █████╗  ██╗   ██╗ ███████╗ ███╗  ██╗
  ██╔══██╗ ██╔══██╗ ██║   ██║ ██╔════╝ ████╗ ██║
  ██████╔╝ ███████║ ██║   ██║ █████╗   ██╔██╗██║
  ██╔══██╗ ██╔══██║ ╚██╗ ██╔╝ ██╔══╝   ██║╚████║
  ██║  ██║ ██║  ██║  ╚████╔╝  ███████╗ ██║ ╚███║
  ╚═╝  ╚═╝ ╚═╝  ╚═╝   ╚═══╝   ╚══════╝ ╚═╝  ╚══╝
           CTF Multi-Category Toolkit v6.0  — by Syaaddd
"""
    print(f"{Fore.CYAN}{banner_text}{Style.RESET_ALL}")


def print_summary() -> None:
    """Print final summary of all findings and flags."""
    print(f"\n{Fore.CYAN}{'=' * 60}")
    print(f"{Fore.CYAN}{Style.BRIGHT}📊 RAVEN Analysis Summary{Style.RESET_ALL}")
    print(f"{Fore.CYAN}{'=' * 60}{Style.RESET_ALL}")
    
    if flag_summary:
        print(f"\n{Fore.YELLOW}{Style.BRIGHT}Findings ({len(flag_summary)} total):{Style.RESET_ALL}")
        for i, entry in enumerate(flag_summary, 1):
            print(f"  {i}. {entry}")
    else:
        print(f"\n{Fore.YELLOW}No specific findings.{Style.RESET_ALL}")
    
    if found_flags_set:
        print(f"\n{Fore.GREEN}{Style.BRIGHT}🚩 FLAGS FOUND ({len(found_flags_set)} unique):{Style.RESET_ALL}")
        for i, flag in enumerate(sorted(found_flags_set), 1):
            print(f"  {Fore.GREEN}{i}. {flag}{Style.RESET_ALL}")
    
    if tool_log:
        print(f"\n{Fore.CYAN}{Style.BRIGHT}🔧 Tools Executed:{Style.RESET_ALL}")
        success_count = sum(1 for t in tool_log if "✅" in t["status"])
        skip_count = sum(1 for t in tool_log if "⏭" in t["status"])
        print(f"  Total: {len(tool_log)} | Success: {success_count} | Skipped: {skip_count}")
    
    print(f"\n{Fore.CYAN}{'=' * 60}{Style.RESET_ALL}\n")


# ─────────────────────────────────────────────
# MODULE INITIALIZATION
# ─────────────────────────────────────────────

def init_module(verbose: bool = False) -> bool:
    """
    Initialize core module - check dependencies and setup.
    
    Args:
        verbose: Whether to print detailed status
        
    Returns:
        bool: True if initialization successful
    """
    if verbose:
        print(f"{Fore.CYAN}[CORE] Initializing RAVEN core module...{Style.RESET_ALL}")
    
    # Check colorama
    if not HAS_COLORAMA:
        print(f"{Fore.RED}[CORE] ERROR: colorama not installed{Style.RESET_ALL}")
        return False
    
    # Check optional dependencies
    if verbose:
        print(f"{Fore.CYAN}[CORE] numpy: {'✅' if HAS_NUMPY else '⚠️  Not installed'}{Style.RESET_ALL}")
        print(f"{Fore.CYAN}[CORE] PIL: {'✅' if HAS_PIL else '⚠️  Not installed'}{Style.RESET_ALL}")
    
    if verbose:
        print(f"{Fore.GREEN}[CORE] Core module initialized successfully{Style.RESET_ALL}")
    
    return True


# Auto-initialize on import
if __name__ == "__main__":
    print_banner()
    init_module(verbose=True)
    print(f"\n{Fore.CYAN}Core utilities module loaded successfully.{Style.RESET_ALL}")
    print(f"Available tools: {len(AVAILABLE_TOOLS)} tracked")
    print(f"Flag patterns: {len(COMMON_FLAG_PATTERNS)} patterns")
