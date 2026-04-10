#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
RAVEN CTF Toolkit - Learning Mode Module

This module provides interactive CTF learning capabilities:
- Display learning paths by category
- Show recommended RAVEN commands for each topic
- Provide practice challenge recommendations
- Track learning progress (optional)

Version: 6.0
Author: Syaaddd
"""

import os
import sys
from pathlib import Path
from typing import Optional

try:
    from colorama import Fore, Back, Style, init
    init(autoreset=True)
    HAS_COLORAMA = True
except ImportError:
    HAS_COLORAMA = False
    class Fore:
        GREEN = YELLOW = RED = CYAN = MAGENTA = BLUE = WHITE = NC = ''
    class Style:
        BRIGHT = DIM = NORMAL = RESET_ALL = ''

# Learning categories with RAVEN command integration
LEARNING_CATEGORIES = {
    "linux": {
        "title": "🖥️  Linux & Command Line",
        "phase": "Phase 1",
        "description": "Master Linux fundamentals for CTF",
        "commands": [
            "raven --folder ./challenge/          # Analyze multiple files",
            "raven unknown_file.dat --auto        # Quick analysis",
            "strings binary.elf | grep -i flag    # Extract strings",
        ],
        "practice": [
            "OverTheWire: Bandit (levels 0-15)",
            "picoCTF: General Skills",
            "CMD Challenge (online exercises)",
        ],
        "time_estimate": "1-2 weeks",
    },
    "python": {
        "title": "🐍 Python Scripting",
        "phase": "Phase 1",
        "description": "Learn Python for CTF automation",
        "commands": [
            "# Study RAVEN's Python engine architecture",
            "# Create custom scripts for challenges",
            "pip install pwntools requests",
        ],
        "practice": [
            "Python Challenge (riddles)",
            "CryptoHack (Python-based challenges)",
            "Exploit Education (binary exploitation)",
        ],
        "time_estimate": "2-3 weeks",
    },
    "encoding": {
        "title": "🔢 Number Systems & Encoding",
        "phase": "Phase 1",
        "description": "Master binary, hex, Base64, and other encodings",
        "commands": [
            "raven binary.txt --binary            # Binary digits analysis",
            "raven binary.txt --binary --bin-width 64  # Binary to image",
            "raven morse.txt --morse              # Morse code decoding",
            "raven decimal.txt --decimal          # Decimal ASCII conversion",
            "raven encoded.txt --encoding-chain   # Multi-stage decoding",
        ],
        "practice": [
            "picoCTF: Cryptography (encoding challenges)",
            "CyberChef (online tool)",
            "dCode.fr (cipher tools)",
        ],
        "time_estimate": "1 week",
    },
    "networking": {
        "title": "🌐 Basic Networking",
        "phase": "Phase 1",
        "description": "Understand network protocols and analysis",
        "commands": [
            "raven capture.pcap --pcap            # Full PCAP analysis",
            "raven capture.pcap --dns-tunnel      # DNS tunneling detection",
            "raven capture.pcap --ftp-recon       # FTP session reconstruction",
            "raven capture.pcap --email-recon     # Email reconstruction",
        ],
        "practice": [
            "Wireshark 101 (official tutorials)",
            "MalwareTrafficAnalysis.net",
            "picoCTF: Forensics (network challenges)",
        ],
        "time_estimate": "2 weeks",
    },
    "web": {
        "title": "🌐 Web Exploitation",
        "phase": "Phase 2",
        "description": "Find and exploit web vulnerabilities",
        "subcategories": {
            "sqli": "SQL Injection (Union, Blind, Error-based)",
            "xss": "Cross-Site Scripting (Reflected, Stored, DOM)",
            "ssrf": "Server-Side Request Forgery",
            "auth": "Authentication Attacks (JWT, Session, Brute Force)",
        },
        "commands": [
            "raven access.log --log               # Analyze web server logs",
            "raven suspicious.txt --deobfuscate   # Check for encoded payloads",
            "sqlmap -u 'http://target/?id=1' --dbs  # SQL injection testing",
        ],
        "practice": [
            "SQLi Labs (GitHub: Audi-1/sqli-labs)",
            "PortSwigger Web Security Academy",
            "DVWA (Damn Vulnerable Web App)",
            "picoCTF: Web Exploitation",
        ],
        "time_estimate": "8-12 weeks",
    },
    "crypto": {
        "title": "🔐 Cryptography",
        "phase": "Phase 3",
        "description": "Break encryption and crack hashes",
        "subcategories": {
            "classical": "Classical Ciphers (Caesar, Vigenere, Substitution)",
            "modern": "Modern Symmetric Crypto (AES, DES, Block Ciphers)",
            "rsa": "RSA & Asymmetric Cryptography",
            "hash": "Hashing (MD5, SHA, Length Extension)",
        },
        "commands": [
            "raven cipher.txt --crypto            # Full crypto analysis",
            "raven cipher.txt --classic           # Classic cipher brute force",
            "raven cipher.txt --crypto --vigenere # Vigenere with auto-detect",
            "raven rsa_challenge.txt --crypto --rsa  # RSA attacks",
            "raven hash.txt --john                # Crack with John the Ripper",
            "raven hash.txt --hashcat             # Crack with Hashcat",
            "raven encrypted.bin --xor-plain 'CTF{'  # XOR with known plaintext",
        ],
        "practice": [
            "CryptoHack (excellent for learning)",
            "Cryptopals (industry standard)",
            "picoCTF: Cryptography",
            "FactorDB (check RSA factorizations)",
        ],
        "time_estimate": "10-16 weeks",
    },
    "pwn": {
        "title": "💣 Binary Exploitation (Pwn)",
        "phase": "Phase 4",
        "description": "Exploit programs to gain code execution",
        "subcategories": {
            "assembly": "x86/x64 Assembly",
            "buffer": "Buffer Overflow",
            "rop": "Return Oriented Programming (ROP)",
            "heap": "Heap Exploitation",
            "format": "Format String Attacks",
        },
        "commands": [
            "raven binary.elf --reversing         # Basic reversing analysis",
            "raven binary.elf --reversing --ghidra  # Ghidra analysis",
            "raven packed.exe --reversing --unpack  # Unpack packed binaries",
            "strings binary.elf | grep -i flag    # Extract strings",
            "checksec binary.elf                  # Check binary protections",
        ],
        "practice": [
            "picoCTF: Binary Exploitation",
            "Exploit Education (Phoenix, Nebula)",
            "ROP Emporium (learn ROP)",
            "Protostar (classic challenges)",
        ],
        "time_estimate": "14-22 weeks",
    },
    "reverse": {
        "title": "🔍 Reverse Engineering",
        "phase": "Phase 5",
        "description": "Understand binaries without source code",
        "commands": [
            "raven binary.elf --reversing         # Full reversing pipeline",
            "raven binary.elf --reversing --ghidra  # Ghidra decompilation",
            "file binary.elf                      # Check file type",
            "strings binary.elf | less            # Browse strings",
            "readelf -h binary.elf                # ELF header analysis",
        ],
        "practice": [
            "Crackmes.one (community crackmes)",
            "picoCTF: Reverse Engineering",
            "Reverse Engineering Challenges (GitHub)",
        ],
        "time_estimate": "12-20 weeks",
    },
    "forensics": {
        "title": "🧩 Forensics & Misc",
        "phase": "Phase 6",
        "description": "Investigate artifacts and solve diverse challenges",
        "subcategories": {
            "file": "File Analysis (Magic Bytes, Binwalk, Carving)",
            "memory": "Memory & Disk Forensics",
            "network": "Network Forensics (PCAP)",
            "stego": "Steganography (LSB, Spectral, Statistical)",
            "osint": "OSINT (Metadata, Geolocation)",
        },
        "commands": [
            "raven suspicious.file --auto         # Full file analysis",
            "raven firmware.bin --auto            # Extract embedded files",
            "raven image.jpg --exif               # Check EXIF metadata",
            "raven image.jpg --gps-extract        # Extract GPS coordinates",
            "raven memory.raw --volatility        # Memory forensics",
            "raven disk.raw --ntfs                # NTFS deleted file recovery",
            "raven disk.raw --mft                 # MFT analysis",
            "raven capture.pcap --pcap            # PCAP analysis",
            "raven image.png --auto               # Auto steganalysis",
            "raven image.png --lsb                # LSB analysis",
            "raven image.jpg --steghide           # Steghide extraction",
            "raven audio.wav --spectrogram        # Audio spectrogram",
            "raven image.png --chi-square         # Chi-square detection",
        ],
        "practice": [
            "picoCTF: Forensics",
            "Volatility Foundation Challenges",
            "SANS DFIR Challenges",
            "Wireshark 101",
            "MalwareTrafficAnalysis.net",
        ],
        "time_estimate": "10-16 weeks",
    },
}


def display_full_roadmap() -> None:
    """Display the complete CTF learning roadmap."""
    print(f"\n{Fore.CYAN}{Style.BRIGHT}{'=' * 70}")
    print(f"🎯 CTF Competitor Learning Roadmap")
    print(f"{'=' * 70}{Style.RESET_ALL}\n")
    
    print(f"{Fore.YELLOW}This guide provides a complete path from beginner to advanced CTF competitor.")
    print(f"Each section includes RAVEN commands for hands-on practice.{Style.RESET_ALL}\n")
    
    for category_key, category_data in LEARNING_CATEGORIES.items():
        print(f"{Fore.GREEN}{Style.BRIGHT}┌─ {category_data['title']}")
        print(f"│  {Fore.CYAN}Phase: {category_data['phase']}{Style.RESET_ALL}")
        print(f"{Fore.GREEN}│  {Fore.WHITE}{category_data['description']}{Style.RESET_ALL}")
        
        if 'time_estimate' in category_data:
            print(f"{Fore.GREEN}│  {Fore.YELLOW}⏱️  Estimated Time: {category_data['time_estimate']}{Style.RESET_ALL}")
        
        print(f"{Fore.GREEN}├─ RAVEN Commands:{Style.RESET_ALL}")
        for cmd in category_data.get('commands', [])[:3]:  # Show first 3 commands
            print(f"{Fore.GREEN}│  {Fore.WHITE}{cmd}{Style.RESET_ALL}")
        
        print(f"{Fore.GREEN}├─ Practice Platforms:{Style.RESET_ALL}")
        for platform in category_data.get('practice', [])[:2]:  # Show first 2 platforms
            print(f"{Fore.GREEN}│  • {Fore.CYAN}{platform}{Style.RESET_ALL}")
        
        print(f"{Fore.GREEN}└─ Learn more: raven --learn {category_key}{Style.RESET_ALL}\n")
    
    print(f"{Fore.CYAN}{'=' * 70}")
    print(f"📚 Complete guide: docs/CTF_FUNDAMENTALS.md")
    print(f"💡 Tip: Use 'raven --learn <category>' to focus on specific topics")
    print(f"{'=' * 70}{Style.RESET_ALL}\n")


def display_category_guide(category: str) -> None:
    """
    Display detailed guide for a specific learning category.
    
    Args:
        category: Category key (e.g., 'crypto', 'web', 'pwn')
    """
    if category not in LEARNING_CATEGORIES:
        print(f"{Fore.RED}[ERROR] Unknown category: '{category}'{Style.RESET_ALL}")
        print(f"{Fore.YELLOW}Available categories: {', '.join(LEARNING_CATEGORIES.keys())}{Style.RESET_ALL}")
        return
    
    cat = LEARNING_CATEGORIES[category]
    
    print(f"\n{Fore.CYAN}{Style.BRIGHT}{'=' * 70}")
    print(f"{cat['title']}")
    print(f"{'=' * 70}{Style.RESET_ALL}\n")
    
    print(f"{Fore.YELLOW}Phase: {cat['phase']}{Style.RESET_ALL}")
    print(f"{Fore.WHITE}{cat['description']}{Style.RESET_ALL}\n")
    
    if 'subcategories' in cat:
        print(f"{Fore.GREEN}{Style.BRIGHT}📖 Subcategories:{Style.RESET_ALL}")
        for sub_key, sub_desc in cat['subcategories'].items():
            print(f"  • {Fore.CYAN}{sub_key}: {Fore.WHITE}{sub_desc}{Style.RESET_ALL}")
        print()
    
    print(f"{Fore.GREEN}{Style.BRIGHT}🔧 RAVEN Commands for Practice:{Style.RESET_ALL}")
    for i, cmd in enumerate(cat['commands'], 1):
        print(f"  {Fore.YELLOW}{i}.{Style.RESET_ALL} {Fore.WHITE}{cmd}{Style.RESET_ALL}")
    print()
    
    print(f"{Fore.GREEN}{Style.BRIGHT}🎮 Recommended Practice Platforms:{Style.RESET_ALL}")
    for i, platform in enumerate(cat['practice'], 1):
        print(f"  {Fore.YELLOW}{i}.{Style.RESET_ALL} {Fore.CYAN}{platform}{Style.RESET_ALL}")
    print()
    
    if 'time_estimate' in cat:
        print(f"{Fore.YELLOW}⏱️  Estimated Time to Mastery: {cat['time_estimate']}{Style.RESET_ALL}\n")
    
    print(f"{Fore.CYAN}{'=' * 70}")
    print(f"📚 Complete guide: docs/CTF_FUNDAMENTALS.md")
    print(f"💡 Tip: Practice these commands on CTF challenges to improve")
    print(f"{'=' * 70}{Style.RESET_ALL}\n")


def display_available_categories() -> None:
    """Display list of all available learning categories."""
    print(f"\n{Fore.CYAN}{Style.BRIGHT}📚 Available Learning Categories:{Style.RESET_ALL}\n")
    
    for category_key, category_data in LEARNING_CATEGORIES.items():
        print(f"  {Fore.GREEN}{category_key:<15}{Style.RESET_ALL} {Fore.WHITE}{category_data['title']}{Style.RESET_ALL}")
        print(f"                  {Fore.YELLOW}{category_data['phase']}{Style.RESET_ALL} - {category_data['description']}\n")
    
    print(f"{Fore.CYAN}Usage:{Style.RESET_ALL}")
    print(f"  raven --learn              # Show full roadmap")
    print(f"  raven --learn <category>   # Focus on specific topic")
    print(f"  raven --learn list         # Show this list\n")


def get_learning_guide_path() -> Optional[str]:
    """
    Get path to the CTF fundamentals learning guide.
    
    Returns:
        Optional[str]: Path to guide file, or None if not found
    """
    # Try multiple locations
    possible_paths = [
        # Relative to current file
        os.path.join(os.path.dirname(__file__), '..', 'docs', 'CTF_FUNDAMENTALS.md'),
        # Relative to current working directory
        os.path.join('docs', 'CTF_FUNDAMENTALS.md'),
        # RAVEN home directory
        os.path.join(os.path.expanduser('~'), '.raven', 'docs', 'CTF_FUNDAMENTALS.md'),
    ]
    
    for path in possible_paths:
        if os.path.exists(path):
            return path
    
    return None


def display_guide_file_path() -> None:
    """Display the path to the complete learning guide file."""
    guide_path = get_learning_guide_path()
    
    if guide_path and os.path.exists(guide_path):
        print(f"\n{Fore.GREEN}📚 Complete Learning Guide Found:{Style.RESET_ALL}")
        print(f"  {Fore.CYAN}{os.path.abspath(guide_path)}{Style.RESET_ALL}")
        print(f"\n{Fore.YELLOW}Open this file in your text editor to view the full guide.{Style.RESET_ALL}\n")
    else:
        print(f"\n{Fore.YELLOW}📚 Learning guide not found.{Style.RESET_ALL}")
        print(f"{Fore.CYAN}Expected location: docs/CTF_FUNDAMENTALS.md{Style.RESET_ALL}")
        print(f"{Fore.CYAN}Or: ~/.raven/docs/CTF_FUNDAMENTALS.md{Style.RESET_ALL}\n")


def run_learning_mode(category: Optional[str] = None) -> int:
    """
    Main entry point for learning mode.
    
    Args:
        category: Specific category to display, or None for full roadmap
        
    Returns:
        int: Exit code (0 for success, 1 for error)
    """
    try:
        if category == "list" or category == "help" or category == "categories":
            display_available_categories()
        elif category:
            display_category_guide(category)
        else:
            display_full_roadmap()
        
        # Always show guide file location
        display_guide_file_path()
        
        return 0
    
    except Exception as e:
        print(f"{Fore.RED}[ERROR] Failed to display learning guide: {e}{Style.RESET_ALL}")
        return 1


# ─────────────────────────────────────────────
# MODULE INITIALIZATION
# ─────────────────────────────────────────────

def init_module(verbose: bool = False) -> bool:
    """
    Initialize learning module.
    
    Args:
        verbose: Whether to print detailed status
        
    Returns:
        bool: True if initialization successful
    """
    if verbose:
        print(f"{Fore.CYAN}[LEARNING] Initializing learning module...{Style.RESET_ALL}")
    
    # Check if guide file exists
    guide_path = get_learning_guide_path()
    if guide_path:
        if verbose:
            print(f"{Fore.GREEN}[LEARNING] Guide file found: {guide_path}{Style.RESET_ALL}")
    else:
        if verbose:
            print(f"{Fore.YELLOW}[LEARNING] Guide file not found (using embedded data){Style.RESET_ALL}")
    
    if verbose:
        print(f"{Fore.GREEN}[LEARNING] Module initialized successfully{Style.RESET_ALL}")
    
    return True


# ─────────────────────────────────────────────
# MAIN ENTRY POINT
# ─────────────────────────────────────────────

if __name__ == "__main__":
    if not HAS_COLORAMA:
        print("ERROR: colorama not installed. Run: pip install colorama")
        sys.exit(1)
    
    # Test the module
    init_module(verbose=True)
    
    if len(sys.argv) > 1:
        category = sys.argv[1]
    else:
        category = None
    
    exit_code = run_learning_mode(category)
    sys.exit(exit_code)
