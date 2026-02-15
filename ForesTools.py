#!/usr/bin/env python3
import subprocess
import argparse
import os
import re
import base64
import shutil
import math
import time
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

AVAILABLE_TOOLS = {}
FLAG_FOUND = False
FLAG_LOCK = Lock()

DEFAULT_WORDLIST = [
    "password", "123456", "12345678", "123456789", "flag", "ctf", "steg",
    "hack", "test", "key", "secret", "admin", "root", "user", "pass",
    "letmein", "welcome", "monkey", "dragon", "master", "hello", "secret",
    "shadow", "sunshine", "princess", "football", "baseball", "soccer",
    "password1", "password123", "qwerty", "abc123", "iloveyou", "admin123",
    "666666", "888888", "000000", "111111", "222222", "333333", "444444",
    "555555", "666666", "777777", "888888", "999999", "aaaaaa", "bbbbbb",
    "cccccc", "dddddd", "eeeeee", "ffffff", "00000a", "00000b", "hello1",
    "hello123", "love", "loveyou", "computer", "internet", "server", "data",
    "file", "image", "photo", "picture", "music", "video", "movie", "game"
]

def check_tool_availability():
    tools = {
        'zsteg': 'zsteg',
        'steghide': 'steghide',
        'outguess': 'outguess',
        'foremost': 'foremost',
        'pngcheck': 'pngcheck',
        'jpseek': 'jpseek',
        'jphs': 'jphs',
        'exiftool': 'exiftool',
        'binwalk': 'binwalk',
        'identify': 'gm',
        'tshark': 'tshark',
        'tcpdump': 'tcpdump',
        'capinfos': 'capinfos'
    }
    
    global AVAILABLE_TOOLS
    AVAILABLE_TOOLS = {}
    
    for name, cmd in tools.items():
        try:
            result = subprocess.run(
                f"where {cmd}" if os.name == 'nt' else f"which {cmd}",
                shell=True, capture_output=True, text=True
            )
            if result.returncode == 0:
                AVAILABLE_TOOLS[name] = True
                print(f"{Fore.GREEN}[TOOL] {name}: Available{Style.RESET_ALL}")
            else:
                AVAILABLE_TOOLS[name] = False
        except:
            AVAILABLE_TOOLS[name] = False
    
    return AVAILABLE_TOOLS

def reset_globals():
    global flag_summary, base64_collector, FLAG_FOUND
    flag_summary = []
    base64_collector = []
    FLAG_FOUND = False

def check_early_exit():
    global FLAG_FOUND
    return FLAG_FOUND

def signal_flag_found():
    global FLAG_FOUND
    with FLAG_LOCK:
        FLAG_FOUND = True

COMMON_FLAG_PATTERNS = [
    r'picoCTF\{[^}]+\}',
    r'CTF\{[^}]+\}',
    r'flag\{[^}]+\}',
    r'[A-Za-z0-9_]{3,}\{[^}]+\}'  # fallback: any prefix with {content}
]

def add_to_summary(category: str, content: str):
    entry = f"[{category}] {content.strip()}"
    if entry not in flag_summary:
        flag_summary.append(entry)
    if "FLAG" in category:
        signal_flag_found()
        print(f"{Fore.GREEN}[EARLY EXIT] Flag found! Signaling stop...{Style.RESET_ALL}")

FILE_SIGNATURES = {
    "png": b"\x89\x50\x4E\x47\x0D\x0A\x1A\x0A",
    "jpg": b"\xFF\xD8\xFF",
    "jpeg": b"\xFF\xD8\xFF",
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
    "mp3": b"\x49\x44\x33"
}

def calculate_entropy(data: bytes) -> float:
    if not data: return 0.0
    entropy = 0.0
    length = len(data)
    for x in range(256):
        count = data.count(x)
        if count == 0: continue
        p_x = count / length
        entropy -= p_x * math.log2(p_x)
    return entropy

def decode_base64(candidate: str):
    try:
        clean = re.sub(r'[^A-Za-z0-9+/=]', '', candidate)
        if len(clean) < 8 or len(clean) % 4 != 0: return None
        decoded = base64.b64decode(clean, validate=True)
        decoded_str = decoded.decode('utf-8', errors='ignore')
        if all(c.isprintable() or c.isspace() for c in decoded_str) and len(decoded_str.strip()) > 4:
            return decoded_str
    except: pass
    return None

def decode_hex(candidate: str):
    try:
        clean = re.sub(r'[^0-9a-fA-F]', '', candidate)
        if len(clean) < 4 or len(clean) % 2 != 0: return None
        decoded = bytes.fromhex(clean)
        # Check if it looks like a file header
        if len(decoded) > 10:
            return decoded
    except: pass
    return None

def decode_binary(candidate: str):
    try:
        clean = re.sub(r'[^01]', '', candidate)
        if len(clean) < 16 or len(clean) % 8 != 0: return None
        decoded = bytes(int(clean[i:i+8], 2) for i in range(0, len(clean), 8))
        if len(decoded) > 4:
            return decoded
    except: pass
    return None

def auto_decode_and_extract(filepath: Path):
    if check_early_exit():
        print(f"{Fore.YELLOW}[AUTO-DECODE] Skipping - flag already found{Style.RESET_ALL}")
        return
    
    print(f"{Fore.CYAN}[AUTO-DECODE] Checking for encoded data...{Style.RESET_ALL}")
    
    try:
        with open(filepath, 'rb') as f:
            raw_data = f.read()
        
        # Try to decode as text
        try:
            text_content = raw_data.decode('utf-8', errors='ignore')
        except:
            text_content = raw_data.decode('latin-1', errors='ignore')
        
        extracted_files = []
        
        # 1. Check for Base64 encoded data
        b64_pattern = r'[A-Za-z0-9+/]{20,}={0,2}'
        b64_matches = re.findall(b64_pattern, text_content)
        
        for i, b64_match in enumerate(b64_matches[:5]):  # Check first 5 matches
            try:
                decoded = base64.b64decode(b64_match, validate=True)
                if len(decoded) > 50:  # Likely a file
                    # Check file signature
                    ext = detect_file_extension(decoded[:16])
                    output_file = filepath.parent / f"{filepath.stem}_decoded_b64_{i}.{ext}"
                    with open(output_file, 'wb') as out:
                        out.write(decoded)
                    extracted_files.append(output_file)
                    print(f"{Fore.GREEN}[+] Base64 decoded: {output_file.name} ({len(decoded)} bytes){Style.RESET_ALL}")
                    add_to_summary("AUTO-DECODE", f"Base64 → {output_file.name}")
                    
                    # Analyze the extracted file
                    analyze_extracted_file(output_file)
            except:
                continue
        
        # 2. Check for Hex encoded data
        hex_pattern = r'[0-9a-fA-F]{40,}'
        hex_matches = re.findall(hex_pattern, text_content)
        
        for i, hex_match in enumerate(hex_matches[:3]):  # Check first 3 matches
            try:
                if len(hex_match) % 2 == 0:
                    decoded = bytes.fromhex(hex_match)
                    if len(decoded) > 50:
                        ext = detect_file_extension(decoded[:16])
                        output_file = filepath.parent / f"{filepath.stem}_decoded_hex_{i}.{ext}"
                        with open(output_file, 'wb') as out:
                            out.write(decoded)
                        extracted_files.append(output_file)
                        print(f"{Fore.GREEN}[+] Hex decoded: {output_file.name} ({len(decoded)} bytes){Style.RESET_ALL}")
                        add_to_summary("AUTO-DECODE", f"Hex → {output_file.name}")
                        analyze_extracted_file(output_file)
            except:
                continue
        
        # 3. Check for Binary encoded data
        bin_pattern = r'[01]{40,}'
        bin_matches = re.findall(bin_pattern, text_content)
        
        for i, bin_match in enumerate(bin_matches[:2]):
            try:
                if len(bin_match) % 8 == 0:
                    decoded = bytes(int(bin_match[j:j+8], 2) for j in range(0, len(bin_match), 8))
                    if len(decoded) > 20:
                        ext = detect_file_extension(decoded[:16])
                        output_file = filepath.parent / f"{filepath.stem}_decoded_bin_{i}.{ext}"
                        with open(output_file, 'wb') as out:
                            out.write(decoded)
                        extracted_files.append(output_file)
                        print(f"{Fore.GREEN}[+] Binary decoded: {output_file.name} ({len(decoded)} bytes){Style.RESET_ALL}")
                        add_to_summary("AUTO-DECODE", f"Binary → {output_file.name}")
                        analyze_extracted_file(output_file)
            except:
                continue
        
        if extracted_files:
            print(f"{Fore.CYAN}[+] Total files extracted: {len(extracted_files)}{Style.RESET_ALL}")
        else:
            print(f"{Fore.YELLOW}[!] No encoded data found{Style.RESET_ALL}")
            
    except Exception as e:
        print(f"{Fore.RED}[!] Auto-decode failed: {e}{Style.RESET_ALL}")

def detect_file_extension(header: bytes) -> str:
    if header.startswith(b'\x89PNG'):
        return 'png'
    elif header.startswith(b'\xff\xd8\xff'):
        return 'jpg'
    elif header.startswith(b'GIF8'):
        return 'gif'
    elif header.startswith(b'%PDF'):
        return 'pdf'
    elif header.startswith(b'PK'):
        return 'zip'
    elif header.startswith(b'\x42\x4d'):
        return 'bmp'
    elif header.startswith(b'\xff\xfb') or header.startswith(b'ID3'):
        return 'mp3'
    elif b'%!PS' in header[:10]:
        return 'ps'
    else:
        return 'bin'

def analyze_extracted_file(filepath: Path):
    try:
        # Check for flags
        result = subprocess.run(['strings', str(filepath)], capture_output=True, text=True)
        strings_output = result.stdout
        
        for pattern in COMMON_FLAG_PATTERNS:
            matches = re.findall(pattern, strings_output, re.IGNORECASE)
            for match in matches:
                print(f"{Fore.GREEN}[!] FLAG in extracted file: {match}{Style.RESET_ALL}")
                add_to_summary("EXTRACTED-FLAG", f"{match} in {filepath.name}")
    except:
        pass

def collect_base64_from_text(text: str):
    pattern = r'[A-Za-z0-9+/]{12,}=*'
    matches = re.findall(pattern, text)
    for m in matches:
        decoded = decode_base64(m)
        if decoded:
            entry = f"Raw: {m} -> Decoded: {decoded}"
            if entry not in base64_collector:
                base64_collector.append(entry)
                add_to_summary("B64-COLLECTOR", decoded)

def detect_scattered_flag(raw_data: bytes):
    try:
        cleaned = ''.join(chr(b) for b in raw_data if 32 <= b <= 126)
        for pattern in COMMON_FLAG_PATTERNS:
            matches = re.findall(pattern, cleaned, re.IGNORECASE)
            for match in matches:
                add_to_summary("SCATTERED-FLAG", match)
    except: pass

def fix_header(filepath: Path) -> Path:
    try:
        with open(filepath, 'rb') as f:
            header = f.read(64)
            full_data = header + f.read()

        entropy = calculate_entropy(full_data)
        color = Fore.RED if entropy > 7.5 else Fore.CYAN
        print(f"{Fore.YELLOW}[+] Entropy: {color}{entropy:.4f}{Style.RESET_ALL}")

        detect_scattered_flag(header)
        hex_preview = header[:16].hex(' ').upper()
        print(f"{Fore.CYAN}[+] Header: {hex_preview}{Style.RESET_ALL}")

        current_ext = filepath.suffix.lower().lstrip('.')
        detected_type = None
        for ext, sig in FILE_SIGNATURES.items():
            if header.startswith(sig):
                detected_type = ext
                break

        if detected_type and current_ext != detected_type:
            fixed = filepath.parent / f"fixed_{filepath.name}.{detected_type}"
            shutil.copy(filepath, fixed)
            add_to_summary("AUTO-FIX", f"→ {fixed.name}")
            return fixed

        if b"JFIF" in header:
            fixed = filepath.parent / f"repaired_{filepath.name}.jpg"
            with open(fixed, 'wb') as out:
                out.write(b"\xFF\xD8\xFF\xE0" + full_data[4:])
            add_to_summary("REPAIR", f"JPEG via JFIF → {fixed.name}")
            return fixed

        if b"IHDR" in header:
            fixed = filepath.parent / f"repaired_{filepath.name}.png"
            with open(fixed, 'wb') as out:
                out.write(FILE_SIGNATURES["png"] + full_data[8:])
            add_to_summary("REPAIR", f"PNG via IHDR → {fixed.name}")
            return fixed

        return filepath
    except Exception as e:
        print(f"{Fore.RED}[!] Header repair failed: {e}{Style.RESET_ALL}")
        return filepath

def analyze_strings_and_flags(filepath: Path, custom_format: str = None):
    try:
        # Get file type
        file_type = subprocess.getoutput(f"file -b '{filepath}'").strip()
        print(f"{Fore.CYAN}[BASIC] Type: {file_type}{Style.RESET_ALL}")

        # Extract strings
        utf8 = subprocess.getoutput(f"strings '{filepath}'")
        utf16 = subprocess.getoutput(f"strings -e l '{filepath}'")
        combined = utf8 + "\n" + utf16

        # Collect Base64
        collect_base64_from_text(combined)

        # Search for COMMON flag patterns
        all_text = combined
        for pattern in COMMON_FLAG_PATTERNS:
            matches = re.findall(pattern, all_text, re.IGNORECASE)
            for match in matches:
                add_to_summary("AUTO-FLAG", match)

        # Search for CUSTOM format (from -f)
        if custom_format:
            escaped = re.escape(custom_format)
            if escaped.endswith(r'\{'):
                pattern = escaped.replace(r'\{', r'\{[^}]*\}')
            else:
                pattern = escaped
            custom_matches = re.findall(pattern, all_text, re.IGNORECASE)
            for match in custom_matches:
                add_to_summary("CUSTOM-FLAG", match)

    except Exception as e:
        print(f"{Fore.RED}[!] Basic string analysis failed: {e}{Style.RESET_ALL}")

def analyze_image(filepath: Path, deep: bool = False, alpha: bool = False):
    if not HAS_PIL:
        print(f"{Fore.RED}[!] Pillow not installed. Skipping image analysis.{Style.RESET_ALL}")
        return

    print(f"{Fore.GREEN}[IMAGE] Running visual stego analysis...{Style.RESET_ALL}")

    try:
        img = Image.open(filepath)
        if img.mode == 'RGBA' or (alpha and img.mode == 'P'):
            img = img.convert("RGBA")
        elif img.mode != 'RGB':
            img = img.convert("RGB")
        
        r, g, b = img.split()[:3]
        channels = [np.array(r), np.array(g), np.array(b)]
        names = ["red", "green", "blue"]
        
        if img.mode == 'RGBA':
            a = img.split()[3]
            channels.append(np.array(a))
            names.append("alpha")
        
        bp_dir = filepath.parent / f"{filepath.stem}_bitplanes"
        bp_dir.mkdir(exist_ok=True)

        bit_range = range(8) if deep else [6, 7]
        
        for ch, name in zip(channels, names):
            for bit in bit_range:
                bit_plane = ((ch >> bit) & 1) * 255
                Image.fromarray(bit_plane.astype(np.uint8), mode="L").save(bp_dir / f"{name}_bit{bit}.png")

        print(f"{Fore.CYAN}[+] Bit planes saved to: {bp_dir.name}{Style.RESET_ALL}")
        add_to_summary("BIT-PLANE", f"Saved to '{bp_dir.name}'")

        for f in bp_dir.glob("*.png"):
            out = subprocess.getoutput(f"strings '{f}'")
            for pattern in COMMON_FLAG_PATTERNS:
                matches = re.findall(pattern, out, re.IGNORECASE)
                for match in matches:
                    print(f"{Fore.GREEN}[!] FLAG FOUND in {f.name}: {match}{Style.RESET_ALL}")
                    add_to_summary("VISUAL-FLAG", match)
                    return

    except Exception as e:
        print(f"{Fore.RED}[!] Bit plane analysis failed: {e}{Style.RESET_ALL}")

    try:
        channel_dir = filepath.parent / f"{filepath.stem}_channels"
        channel_dir.mkdir(exist_ok=True)
        r.save(channel_dir / "red.png")
        g.save(channel_dir / "green.png")
        b.save(channel_dir / "blue.png")
        
        if img.mode == 'RGBA':
            a.save(channel_dir / "alpha.png")
            print(f"{Fore.CYAN}[+] RGBA channels saved to: {channel_dir.name}{Style.RESET_ALL}")
            add_to_summary("RGB-CHANNELS", f"Saved to '{channel_dir.name}' (with Alpha)")
        else:
            print(f"{Fore.CYAN}[+] RGB channels saved to: {channel_dir.name}{Style.RESET_ALL}")
            add_to_summary("RGB-CHANNELS", f"Saved to '{channel_dir.name}'")
    except: pass

def analyze_with_binwalk(filepath: Path):
    if check_early_exit():
        print(f"{Fore.YELLOW}[BINWALK] Skipping - flag already found{Style.RESET_ALL}")
        return
    
    output_dir = filepath.parent / f"_extracted_{filepath.name}"
    try:
        subprocess.run(
            ["binwalk", "-eM", "--quiet", f"--directory={output_dir}", str(filepath)],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        if output_dir.exists():
            print(f"{Fore.GREEN}[BINWALK] Extraction complete: {output_dir.name}{Style.RESET_ALL}")
            for nested in output_dir.rglob("*"):
                if nested.is_file():
                    analyze_strings_and_flags(nested)
        else:
            print(f"{Fore.YELLOW}[BINWALK] No embedded files found.{Style.RESET_ALL}")
    except FileNotFoundError:
        print(f"{Fore.YELLOW}[BINWALK] Not installed. Skipping.{Style.RESET_ALL}")
    except Exception as e:
        print(f"{Fore.RED}[BINWALK] Failed: {e}{Style.RESET_ALL}")

def analyze_zsteg(filepath: Path):
    if not AVAILABLE_TOOLS.get('zsteg', False):
        print(f"{Fore.YELLOW}[ZSTEG] Not installed. Skipping.{Style.RESET_ALL}")
        return
    
    if check_early_exit():
        print(f"{Fore.YELLOW}[ZSTEG] Skipping - flag already found{Style.RESET_ALL}")
        return
    
    print(f"{Fore.GREEN}[ZSTEG] Running full LSB analysis...{Style.RESET_ALL}")
    try:
        result = subprocess.run(
            ["zsteg", "-a", str(filepath)],
            capture_output=True, text=True, timeout=60
        )
        output = result.stdout + result.stderr
        print(f"{Fore.CYAN}[ZSTEG] Output:{Style.RESET_ALL}")
        print(output[:2000] if len(output) > 2000 else output)
        
        collect_base64_from_text(output)
        for pattern in COMMON_FLAG_PATTERNS:
            matches = re.findall(pattern, output, re.IGNORECASE)
            for match in matches:
                add_to_summary("ZSTEG-FLAG", match)
        
        zsteg_dir = filepath.parent / f"{filepath.stem}_zsteg"
        zsteg_dir.mkdir(exist_ok=True)
        for pattern in ['all', 'bmp', 'png']:
            try:
                subprocess.run(
                    ["zsteg", "-E", f"extr/{pattern}={str(zsteg_dir)}/{pattern}.dat", str(filepath)],
                    capture_output=True, text=True, timeout=30
                )
            except:
                pass
        if any(zsteg_dir.iterdir()):
            add_to_summary("ZSTEG-EXTRACT", f"Saved to '{zsteg_dir.name}'")
    except subprocess.TimeoutExpired:
        print(f"{Fore.RED}[ZSTEG] Timeout.{Style.RESET_ALL}")
    except Exception as e:
        print(f"{Fore.RED}[ZSTEG] Failed: {e}{Style.RESET_ALL}")

def analyze_steghide(filepath: Path, password: str = None):
    if not AVAILABLE_TOOLS.get('steghide', False):
        print(f"{Fore.YELLOW}[STEGHIDE] Not installed. Skipping.{Style.RESET_ALL}")
        return
    
    if check_early_exit():
        print(f"{Fore.YELLOW}[STEGHIDE] Skipping - flag already found{Style.RESET_ALL}")
        return
    
    print(f"{Fore.GREEN}[STEGHIDE] Attempting extraction...{Style.RESET_ALL}")
    output_dir = filepath.parent / f"{filepath.stem}_steghide"
    output_dir.mkdir(exist_ok=True)
    output_file = output_dir / "extracted.txt"
    
    try:
        cmd = ["steghide", "extract", "-sf", str(filepath), "-xf", str(output_file), "-f"]
        if password:
            cmd.extend(["-p", password])
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            print(f"{Fore.GREEN}[STEGHIDE] Extraction successful!{Style.RESET_ALL}")
            if output_file.exists() and output_file.stat().st_size > 0:
                content = output_file.read_text(errors='ignore')
                print(f"{Fore.CYAN}[STEGHIDE] Extracted content preview:{Style.RESET_ALL}")
                print(content[:500])
                collect_base64_from_text(content)
                for pattern in COMMON_FLAG_PATTERNS:
                    matches = re.findall(pattern, content, re.IGNORECASE)
                    for match in matches:
                        add_to_summary("STEGHIDE-FLAG", match)
                add_to_summary("STEGHIDE-EXTRACT", f"Saved to '{output_file.name}'")
        else:
            if "no archived data" not in result.stderr.lower():
                print(f"{Fore.YELLOW}[STEGHIDE] {result.stderr[:200]}{Style.RESET_ALL}")
            else:
                print(f"{Fore.YELLOW}[STEGHIDE] No embedded data found.{Style.RESET_ALL}")
    except subprocess.TimeoutExpired:
        print(f"{Fore.RED}[STEGHIDE] Timeout.{Style.RESET_ALL}")
    except Exception as e:
        print(f"{Fore.RED}[STEGHIDE] Failed: {e}{Style.RESET_ALL}")

def analyze_outguess(filepath: Path):
    if not AVAILABLE_TOOLS.get('outguess', False):
        print(f"{Fore.YELLOW}[OUTGUESS] Not installed. Skipping.{Style.RESET_ALL}")
        return
    
    print(f"{Fore.GREEN}[OUTGUESS] Running extraction...{Style.RESET_ALL}")
    output_dir = filepath.parent / f"{filepath.stem}_outguess"
    output_dir.mkdir(exist_ok=True)
    output_file = output_dir / "outguess.txt"
    
    try:
        result = subprocess.run(
            ["outguess", "-r", str(filepath), str(output_file)],
            capture_output=True, text=True, timeout=30
        )
        
        if result.returncode == 0 and output_file.exists():
            content = output_file.read_text(errors='ignore')
            print(f"{Fore.GREEN}[OUTGUESS] Extraction successful!{Style.RESET_ALL}")
            print(content[:500])
            collect_base64_from_text(content)
            for pattern in COMMON_FLAG_PATTERNS:
                matches = re.findall(pattern, content, re.IGNORECASE)
                for match in matches:
                    add_to_summary("OUTGUESS-FLAG", match)
            add_to_summary("OUTGUESS-EXTRACT", f"Saved to '{output_file.name}'")
        else:
            print(f"{Fore.YELLOW}[OUTGUESS] No embedded data found.{Style.RESET_ALL}")
    except subprocess.TimeoutExpired:
        print(f"{Fore.RED}[OUTGUESS] Timeout.{Style.RESET_ALL}")
    except Exception as e:
        print(f"{Fore.RED}[OUTGUESS] Failed: {e}{Style.RESET_ALL}")

def analyze_foremost(filepath: Path, quick: bool = True):
    if not AVAILABLE_TOOLS.get('foremost', False):
        print(f"{Fore.YELLOW}[FOREMOST] Not installed. Skipping.{Style.RESET_ALL}")
        return
    
    # Check file size - skip very large files in quick mode
    file_size = filepath.stat().st_size
    if quick and file_size > 50 * 1024 * 1024:  # 50MB
        print(f"{Fore.YELLOW}[FOREMOST] File too large ({file_size / 1024 / 1024:.1f}MB), skipping in quick mode.{Style.RESET_ALL}")
        return
    
    print(f"{Fore.GREEN}[FOREMOST] Running file carving...{Style.RESET_ALL}")
    output_dir = filepath.parent / f"{filepath.stem}_foremost"
    
    try:
        # Use shorter timeout for quick mode
        timeout = 15 if quick else 60
        subprocess.run(
            ["foremost", "-i", str(filepath), "-o", str(output_dir), "-v"],
            capture_output=True, timeout=timeout
        )
        if output_dir.exists():
            files_found = list(output_dir.rglob("*"))
            if files_found:
                print(f"{Fore.GREEN}[FOREMOST] Found {len(files_found)} file(s){Style.RESET_ALL}")
                for f in files_found[:5]:  # Limit to 5 files in quick mode
                    if f.is_file():
                        print(f"  - {f.name}")
                        analyze_strings_and_flags(f)
                add_to_summary("FOREMOST-EXTRACT", f"Saved to '{output_dir.name}'")
            else:
                print(f"{Fore.YELLOW}[FOREMOST] No files extracted.{Style.RESET_ALL}")
    except subprocess.TimeoutExpired:
        print(f"{Fore.RED}[FOREMOST] Timeout.{Style.RESET_ALL}")
    except Exception as e:
        print(f"{Fore.RED}[FOREMOST] Failed: {e}{Style.RESET_ALL}")

def analyze_pngcheck(filepath: Path):
    if not AVAILABLE_TOOLS.get('pngcheck', False):
        print(f"{Fore.YELLOW}[PNGCHECK] Not installed. Skipping.{Style.RESET_ALL}")
        return
    
    print(f"{Fore.GREEN}[PNGCHECK] Validating PNG...{Style.RESET_ALL}")
    try:
        result = subprocess.run(
            ["pngcheck", "-v", str(filepath)],
            capture_output=True, text=True, timeout=30
        )
        output = result.stdout + result.stderr
        print(f"{Fore.CYAN}{output}{Style.RESET_ALL}")
        
        collect_base64_from_text(output)
        if "error" in output.lower():
            add_to_summary("PNGCHECK-ERROR", "PNG has issues")
    except subprocess.TimeoutExpired:
        print(f"{Fore.RED}[PNGCHECK] Timeout.{Style.RESET_ALL}")
    except Exception as e:
        print(f"{Fore.RED}[PNGCHECK] Failed: {e}{Style.RESET_ALL}")

def analyze_jpseek(filepath: Path):
    tool_name = None
    for t in ['jpseek', 'jphs']:
        if AVAILABLE_TOOLS.get(t, False):
            tool_name = t
            break
    
    if not tool_name:
        print(f"{Fore.YELLOW}[JPSTEG] Not installed. Skipping.{Style.RESET_ALL}")
        return
    
    print(f"{Fore.GREEN}[JPSTEG] Running analysis...{Style.RESET_ALL}")
    output_dir = filepath.parent / f"{filepath.stem}_jpsteg"
    output_dir.mkdir(exist_ok=True)
    
    try:
        if tool_name == 'jpseek':
            result = subprocess.run(
                ["jpseek", str(filepath), str(output_dir)],
                capture_output=True, text=True, timeout=30
            )
        else:
            result = subprocess.run(
                ["jphs", "-e", str(filepath), str(output_dir / "jphs_output.txt")],
                capture_output=True, text=True, timeout=30
            )
        
        output = result.stdout + result.stderr
        print(f"{Fore.CYAN}[JPSTEG] Output:{Style.RESET_ALL}")
        print(output[:1000])
        
        collect_base64_from_text(output)
    except subprocess.TimeoutExpired:
        print(f"{Fore.RED}[JPSTEG] Timeout.{Style.RESET_ALL}")
    except Exception as e:
        print(f"{Fore.RED}[JPSTEG] Failed: {e}{Style.RESET_ALL}")

def analyze_graphicsmagick(filepath: Path):
    if not AVAILABLE_TOOLS.get('identify', False):
        return
    
    print(f"{Fore.GREEN}[GM-IDENTIFY] Getting image properties...{Style.RESET_ALL}")
    try:
        result = subprocess.run(
            ["gm", "identify", "-verbose", str(filepath)],
            capture_output=True, text=True, timeout=30
        )
        output = result.stdout
        print(f"{Fore.CYAN}[GM-IDENTIFY] Output:{Style.RESET_ALL}")
        print(output[:1500])
        
        collect_base64_from_text(output)
    except Exception as e:
        print(f"{Fore.YELLOW}[GM-IDENTIFY] Failed: {e}{Style.RESET_ALL}")

def analyze_exif_deep(filepath: Path):
    """Deep EXIF analysis for steganography detection"""
    print(f"{Fore.GREEN}[EXIF-DEEP] Analyzing EXIF metadata...{Style.RESET_ALL}")
    
    flags_found = []
    suspicious_data = []
    
    try:
        result = subprocess.run(
            ["exiftool", "-a", "-u", "-g1", str(filepath)],
            capture_output=True, text=True, timeout=30
        )
        
        output = result.stdout
        print(f"{Fore.CYAN}[EXIF-DEEP] Full EXIF Data:{Style.RESET_ALL}")
        print(output[:2000])
        
        collect_base64_from_text(output)
        
        suspicious_tags = [
            'Comment', 'ImageDescription', 'UserComment', 'XPComment',
            'Artist', 'Copyright', 'Software', 'Make', 'Model'
        ]
        
        for tag in suspicious_tags:
            if tag.lower() in output.lower():
                pattern = f"{tag}.*?:.*?([A-Za-z0-9+/]{{20,}})"
                matches = re.findall(pattern, output, re.IGNORECASE)
                if matches:
                    suspicious_data.append((tag, matches))
        
        hidden_patterns = [
            r'data:image/(?:base64|jpeg|png);base64,([A-Za-z0-9+/=]+)',
            r'(?:steganography|steghide|outguess|zsteg)',
            r'(?:hidden|secret|embedded).*?([A-Za-z0-9+/]{20,})',
        ]
        
        for pattern in hidden_patterns:
            matches = re.findall(pattern, output, re.IGNORECASE)
            for match in matches:
                suspicious_data.append(("HiddenPattern", match))
        
        for pattern in COMMON_FLAG_PATTERNS:
            flag_matches = re.findall(pattern, output, re.IGNORECASE)
            for match in flag_matches:
                flags_found.append(match)
                print(f"{Fore.GREEN}[!] FLAG in EXIF: {match}{Style.RESET_ALL}")
                add_to_summary("EXIF-FLAG", match)
        
        if suspicious_data:
            print(f"{Fore.YELLOW}[!] Suspicious EXIF data found:{Style.RESET_ALL}")
            for tag, data in suspicious_data:
                print(f"  {tag}: {str(data)[:80]}")
                add_to_summary("EXIF-SUSPICIOUS", f"{tag}: {str(data)[:60]}")
        
        exif_dir = filepath.parent / f"{filepath.stem}_exif"
        exif_dir.mkdir(exist_ok=True)
        exif_file = exif_dir / "full_exif.txt"
        with open(exif_file, 'w') as f:
            f.write(output)
        
        add_to_summary("EXIF-EXTRACT", f"Saved to '{exif_file.name}'")
        
    except FileNotFoundError:
        print(f"{Fore.YELLOW}[EXIF-DEEP] ExifTool not installed.{Style.RESET_ALL}")
    except Exception as e:
        print(f"{Fore.RED}[EXIF-DEEP] Failed: {e}{Style.RESET_ALL}")

def analyze_steg_methods(filepath: Path):
    """Detect which steganography method might have been used"""
    print(f"{Fore.GREEN}[STEG-DETECT] Detecting steganography method...{Style.RESET_ALL}")
    
    if not HAS_PIL:
        print(f"{Fore.RED}[!] Pillow not installed. Skipping.{Style.RESET_ALL}")
        return
    
    results = {
        'lsb_likely': False,
        'zsteg_likely': False,
        'steghide_likely': False,
        'outguess_likely': False,
        'pixel_indicators': []
    }
    
    try:
        img = Image.open(filepath)
        pixels = np.array(img)
        
        if len(pixels.shape) == 3:
            height, width, channels = pixels.shape
        else:
            height, width = pixels.shape
            channels = 1
        
        flat_pixels = pixels.flatten()
        
        lsb_zero_count = np.sum(flat_pixels % 2 == 0)
        lsb_one_count = np.sum(flat_pixels % 2 == 1)
        lsb_ratio = lsb_one_count / (lsb_zero_count + lsb_one_count + 1)
        
        if 0.48 < lsb_ratio < 0.52:
            results['lsb_likely'] = True
            results['pixel_indicators'].append("LSB distribution is nearly random - possible LSB steganography")
            print(f"{Fore.CYAN}[STEG-DETECT] LSB ratio: {lsb_ratio:.4f} (random = 0.5){Style.RESET_ALL}")
        
        if channels >= 3:
            r_channel = pixels[:,:,0]
            g_channel = pixels[:,:,1]
            b_channel = pixels[:,:,2]
            
            r_variance = np.var(r_channel)
            g_variance = np.var(g_channel)
            b_variance = np.var(b_channel)
            
            if abs(r_variance - g_variance) > 1000 or abs(g_variance - b_variance) > 1000:
                results['zsteg_likely'] = True
                results['pixel_indicators'].append("High variance difference between color channels")
                print(f"{Fore.CYAN}[STEG-DETECT] Color channel variance: R={r_variance:.0f}, G={g_variance:.0f}, B={b_variance:.0f}{Style.RESET_ALL}")
        
        if filepath.suffix.lower() in ['.jpg', '.jpeg']:
            if AVAILABLE_TOOLS.get('steghide'):
                results['steghide_likely'] = True
                results['pixel_indicators'].append("JPEG file - steghide/outguess are common methods")
                print(f"{Fore.CYAN}[STEG-DETECT] JPEG detected - try steghide or outguess{Style.RESET_ALL}")
        
        unique_values = len(np.unique(flat_pixels[:10000]))
        total_values = min(10000, len(flat_pixels))
        uniqueness_ratio = unique_values / total_values
        
        if uniqueness_ratio > 0.8:
            results['pixel_indicators'].append(f"High color diversity ({uniqueness_ratio:.2%}) - natural image")
        elif uniqueness_ratio < 0.3:
            results['pixel_indicators'].append(f"Low color diversity ({uniqueness_ratio:.2%}) - possible processed/hidden data")
            print(f"{Fore.YELLOW}[!] Low color diversity detected - suspicious{Style.RESET_ALL}")
        
        print(f"\n{Fore.CYAN}[STEG-DETECT] Summary:{Style.RESET_ALL}")
        print(f"  - LSB steganography likely: {results['lsb_likely']}")
        print(f"  - Zsteg recommended: {results['zsteg_likely']}")
        print(f"  - Steghide recommended: {results['steghide_likely']}")
        
        for indicator in results['pixel_indicators']:
            print(f"  - {indicator}")
        
        add_to_summary("STEG-DETECT", f"LSB:{results['lsb_likely']}, Zsteg:{results['zsteg_likely']}, Steghide:{results['steghide_likely']}")
        
    except Exception as e:
        print(f"{Fore.RED}[STEG-DETECT] Failed: {e}{Style.RESET_ALL}")

def compare_images(filepath1: Path, filepath2: Path):
    """Compare two images to find hidden data in differences"""
    if not HAS_PIL:
        print(f"{Fore.RED}[!] Pillow not installed. Skipping image comparison.{Style.RESET_ALL}")
        return
    
    print(f"{Fore.GREEN}[IMAGE-COMPARE] Comparing two images for differences...{Style.RESET_ALL}")
    
    try:
        img1 = Image.open(filepath1)
        img2 = Image.open(filepath2)
        
        arr1 = np.array(img1)
        arr2 = np.array(img2)
        
        if arr1.shape != arr2.shape:
            print(f"{Fore.YELLOW}[!] Images have different dimensions: {arr1.shape} vs {arr2.shape}{Style.RESET_ALL}")
            min_shape = tuple(min(a, b) for a, b in zip(arr1.shape, arr2.shape))
            arr1 = arr1[:min_shape[0], :min_shape[1], :min_shape[2]] if len(arr1.shape) == 3 else arr1[:min_shape[0], :min_shape[1]]
            arr2 = arr2[:min_shape[0], :min_shape[1], :min_shape[2]] if len(arr2.shape) == 3 else arr2[:min_shape[0], :min_shape[1]]
        
        diff = np.abs(arr1.astype(np.int16) - arr2.astype(np.int16))
        diff_sum = np.sum(diff)
        
        print(f"{Fore.CYAN}[IMAGE-COMPARE] Total pixel difference: {diff_sum}{Style.RESET_ALL}")
        
        diff_output_dir = filepath1.parent / f"{filepath1.stem}_compare"
        diff_output_dir.mkdir(exist_ok=True)
        
        diff_img = Image.fromarray(diff.astype(np.uint8))
        diff_img.save(diff_output_dir / "difference.png")
        
        print(f"{Fore.GREEN}[+] Difference image saved to: {diff_output_dir.name}/difference.png{Style.RESET_ALL}")
        
        if diff_sum > 0:
            diff_gray = np.mean(diff, axis=2) if len(diff.shape) == 3 else diff
            threshold = np.percentile(diff_gray[diff_gray > 0], 95) if np.any(diff_gray > 0) else 0
            
            significant_diff = (diff_gray > threshold).astype(np.uint8) * 255
            sig_diff_img = Image.fromarray(significant_diff)
            sig_diff_img.save(diff_output_dir / "significant_diff.png")
            
            print(f"{Fore.GREEN}[+] Significant differences saved to: {diff_output_dir.name}/significant_diff.png{Style.RESET_ALL}")
            
            flat_diff = diff.flatten()
            non_zero_pixels = np.sum(flat_diff > 0)
            print(f"{Fore.CYAN}[+] Number of pixels with differences: {non_zero_pixels}{Style.RESET_ALL}")
            
            collect_base64_from_text(str(diff[:100]))
            
            add_to_summary("IMAGE-COMPARE", f"Differences found: {non_zero_pixels} pixels, total diff: {diff_sum}")
        else:
            print(f"{Fore.YELLOW}[!] No visible differences between images{Style.RESET_ALL}")
            add_to_summary("IMAGE-COMPARE", "No differences found")
        
    except Exception as e:
        print(f"{Fore.RED}[IMAGE-COMPARE] Failed: {e}{Style.RESET_ALL}")

def extract_lsb_data(filepath: Path):
    """Extract raw LSB data from image"""
    if not HAS_PIL:
        print(f"{Fore.RED}[!] Pillow not installed. Skipping LSB extraction.{Style.RESET_ALL}")
        return
    
    print(f"{Fore.GREEN}[LSB-EXTRACT] Extracting raw LSB data...{Style.RESET_ALL}")
    
    try:
        img = Image.open(filepath)
        arr = np.array(img)
        
        if len(arr.shape) == 3:
            height, width, channels = arr.shape
        else:
            height, width = arr.shape
            channels = 1
            arr = arr.reshape(height, width, 1)
        
        lsb_data = []
        for c in range(min(channels, 4)):
            channel = arr[:,:,c]
            lsb = channel & 1
            lsb_data.append(lsb.flatten())
        
        combined_lsb = np.concatenate(lsb_data)
        
        lsb_bytes = np.packbits(combined_lsb)
        
        output_dir = filepath.parent / f"{filepath.stem}_lsb_raw"
        output_dir.mkdir(exist_ok=True)
        output_file = output_dir / "lsb_raw.bin"
        
        with open(output_file, 'wb') as f:
            f.write(lsb_bytes.tobytes())
        
        print(f"{Fore.GREEN}[+] LSB data extracted: {output_file.name} ({len(lsb_bytes)} bytes){Style.RESET_ALL}")
        
        try:
            text_result = lsb_bytes.tobytes()[:1000].decode('utf-8', errors='ignore')
            if any(c.isprintable() for c in text_result):
                print(f"{Fore.CYAN}[+] LSB contains text: {text_result[:100]}...{Style.RESET_ALL}")
                collect_base64_from_text(text_result)
        except:
            pass
        
        for pattern in COMMON_FLAG_PATTERNS:
            matches = re.findall(pattern, lsb_bytes.tobytes().decode('latin-1', errors='ignore'), re.IGNORECASE)
            for match in matches:
                print(f"{Fore.GREEN}[!] FLAG in LSB data: {match}{Style.RESET_ALL}")
                add_to_summary("LSB-FLAG", match)
        
        add_to_summary("LSB-EXTRACT", f"Saved to '{output_file.name}'")
        
    except Exception as e:
        print(f"{Fore.RED}[LSB-EXTRACT] Failed: {e}{Style.RESET_ALL}")

def color_remapping(filepath: Path):
    if not HAS_PIL:
        print(f"{Fore.RED}[!] Pillow not installed. Skipping color remapping.{Style.RESET_ALL}")
        return
    
    print(f"{Fore.GREEN}[COLOR-REMAP] Generating 8 palette variants...{Style.RESET_ALL}")
    try:
        img = Image.open(filepath)
        if img.mode not in ['RGB', 'RGBA']:
            img = img.convert('RGBA')
        
        remap_dir = filepath.parent / f"{filepath.stem}_remap"
        remap_dir.mkdir(exist_ok=True)
        
        np_img = np.array(img)
        
        for i in range(8):
            np.random.seed(i * 42)
            remapped = np_img.copy()
            
            for c in range(min(3, remapped.shape[2])):
                channel = remapped[:, :, c]
                original_vals = np.unique(channel)
                if len(original_vals) > 1:
                    shuffled = np.random.permutation(original_vals)
                    mapping = {orig: new for orig, new in zip(original_vals, shuffled)}
                    for orig, new in mapping.items():
                        remapped[channel == orig] = new
            
            remapped_img = Image.fromarray(remapped.astype(np.uint8), mode=img.mode)
            remapped_img.save(remap_dir / f"variant_{i+1}.png")
        
        print(f"{Fore.CYAN}[COLOR-REMAP] Saved 8 variants to: {remap_dir.name}{Style.RESET_ALL}")
        add_to_summary("COLOR-REMAP", f"Saved to '{remap_dir.name}'")
        
        for f in remap_dir.glob("variant_*.png"):
            out = subprocess.getoutput(f"strings '{f}'")
            for pattern in COMMON_FLAG_PATTERNS:
                matches = re.findall(pattern, out, re.IGNORECASE)
                for match in matches:
                    print(f"{Fore.GREEN}[!] FLAG FOUND in {f.name}: {match}{Style.RESET_ALL}")
                    add_to_summary("REMAP-FLAG", f"{match} in {f.name}")
    except Exception as e:
        print(f"{Fore.RED}[!] Color remapping failed: {e}{Style.RESET_ALL}")

def bruteforce_steghide(filepath: Path, wordlist: list = None, delay: float = 0.1, parallel: int = 5):
    if not AVAILABLE_TOOLS.get('steghide', False):
        print(f"{Fore.YELLOW}[BRUTEFORCE] Steghide not installed. Skipping.{Style.RESET_ALL}")
        return
    
    if wordlist is None:
        wordlist = DEFAULT_WORDLIST
    
    print(f"{Fore.GREEN}[BRUTEFORCE] Starting PARALLEL brute force ({parallel} threads) with {len(wordlist)} passwords...{Style.RESET_ALL}")
    print(f"{Fore.YELLOW}[BRUTEFORCE] Delay: {delay}s (fast mode){Style.RESET_ALL}")
    
    output_dir = filepath.parent / f"{filepath.stem}_bruteforce"
    output_dir.mkdir(exist_ok=True)
    
    found = {"value": False}
    found_password = {"value": None}
    found_content = {"value": None}
    
    def try_password(password):
        if found["value"]:
            return None
        try:
            output_file = output_dir / f"out_{password}.txt"
            result = subprocess.run(
                ["steghide", "extract", "-sf", str(filepath), "-xf", str(output_file), "-f", "-p", password],
                capture_output=True, text=True, timeout=15
            )
            
            if result.returncode == 0 and output_file.exists() and output_file.stat().st_size > 0:
                content = output_file.read_text(errors='ignore')
                return (password, content)
        except:
            pass
        return None
    
    with ThreadPoolExecutor(max_workers=parallel) as executor:
        futures = {executor.submit(try_password, pw): pw for pw in wordlist}
        
        for future in as_completed(futures):
            if check_early_exit():
                break
            result = future.result()
            if result:
                password, content = result
                print(f"{Fore.GREEN}[BRUTEFORCE] SUCCESS! Password: {password}{Style.RESET_ALL}")
                print(f"{Fore.CYAN}Content: {content[:200]}{Style.RESET_ALL}")
                collect_base64_from_text(content)
                for pattern in COMMON_FLAG_PATTERNS:
                    matches = re.findall(pattern, content, re.IGNORECASE)
                    for match in matches:
                        add_to_summary("BRUTEFORCE-FLAG", f"Password: '{password}' → {match}")
                found["value"] = True
                break
    
    if not found["value"]:
        print(f"{Fore.YELLOW}[BRUTEFORCE] No password found.{Style.RESET_ALL}")

def analyze_pcap_basic(filepath: Path):
    if not AVAILABLE_TOOLS.get('capinfos', False):
        print(f"{Fore.YELLOW}[PCAP] Capinfos not installed. Skipping.{Style.RESET_ALL}")
        return
    
    print(f"{Fore.GREEN}[PCAP] Getting capture info...{Style.RESET_ALL}")
    try:
        result = subprocess.run(
            ["capinfos", str(filepath)],
            capture_output=True, text=True, timeout=30
        )
        output = result.stdout
        print(f"{Fore.CYAN}{output}{Style.RESET_ALL}")
        
        # Save to file
        info_file = filepath.parent / f"{filepath.stem}_pcap_info.txt"
        with open(info_file, 'w') as f:
            f.write(output)
        add_to_summary("PCAP-INFO", f"Saved to '{info_file.name}'")
        
        # Search for flags in capinfos output
        collect_base64_from_text(output)
    except Exception as e:
        print(f"{Fore.RED}[PCAP] Capinfos failed: {e}{Style.RESET_ALL}")

def extract_http_objects(filepath: Path):
    if not AVAILABLE_TOOLS.get('tshark', False):
        print(f"{Fore.YELLOW}[PCAP] Tshark not installed. Skipping HTTP extraction.{Style.RESET_ALL}")
        return
    
    print(f"{Fore.GREEN}[PCAP] Extracting HTTP objects...{Style.RESET_ALL}")
    output_dir = filepath.parent / f"{filepath.stem}_http_objects"
    output_dir.mkdir(exist_ok=True)
    
    try:
        result = subprocess.run(
            ["tshark", "-r", str(filepath), "--export-objects", f"http,{output_dir}", "-q"],
            capture_output=True, text=True, timeout=120
        )
        
        files_extracted = list(output_dir.glob("*"))
        if files_extracted:
            print(f"{Fore.GREEN}[+] Extracted {len(files_extracted)} HTTP object(s){Style.RESET_ALL}")
            for f in files_extracted[:10]:
                print(f"  - {f.name}")
                # Analyze extracted file for flags
                analyze_extracted_file(f)
            add_to_summary("PCAP-HTTP", f"{len(files_extracted)} objects saved to '{output_dir.name}'")
        else:
            print(f"{Fore.YELLOW}[!] No HTTP objects found{Style.RESET_ALL}")
    except Exception as e:
        print(f"{Fore.RED}[PCAP] HTTP extraction failed: {e}{Style.RESET_ALL}")

def extract_dns_queries(filepath: Path):
    if not AVAILABLE_TOOLS.get('tshark', False):
        print(f"{Fore.YELLOW}[PCAP] Tshark not installed. Skipping DNS analysis.{Style.RESET_ALL}")
        return
    
    print(f"{Fore.GREEN}[PCAP] Extracting DNS queries...{Style.RESET_ALL}")
    try:
        result = subprocess.run(
            ["tshark", "-r", str(filepath), "-T", "fields", "-e", "dns.qry.name", "-Y", "dns", "-q"],
            capture_output=True, text=True, timeout=60
        )
        
        output = result.stdout.strip()
        if output:
            queries = [q for q in output.split('\n') if q]
            print(f"{Fore.CYAN}[+] Found {len(queries)} DNS queries{Style.RESET_ALL}")
            
            # Save to file
            dns_file = filepath.parent / f"{filepath.stem}_dns_queries.txt"
            with open(dns_file, 'w') as f:
                f.write(output)
            
            # Check for flags in DNS queries
            for query in queries[:20]:  # Check first 20
                for pattern in COMMON_FLAG_PATTERNS:
                    matches = re.findall(pattern, query, re.IGNORECASE)
                    for match in matches:
                        print(f"{Fore.GREEN}[!] FLAG in DNS query: {match}{Style.RESET_ALL}")
                        add_to_summary("PCAP-DNS-FLAG", match)
            
            # Check for base64 in DNS queries
            collect_base64_from_text(output)
            add_to_summary("PCAP-DNS", f"{len(queries)} queries saved to '{dns_file.name}'")
        else:
            print(f"{Fore.YELLOW}[!] No DNS queries found{Style.RESET_ALL}")
    except Exception as e:
        print(f"{Fore.RED}[PCAP] DNS extraction failed: {e}{Style.RESET_ALL}")

def extract_credentials(filepath: Path):
    if not AVAILABLE_TOOLS.get('tshark', False):
        print(f"{Fore.YELLOW}[PCAP] Tshark not installed. Skipping credentials extraction.{Style.RESET_ALL}")
        return
    
    print(f"{Fore.GREEN}[PCAP] Searching for credentials...{Style.RESET_ALL}")
    creds_found = []
    
    try:
        # FTP credentials
        result = subprocess.run(
            ["tshark", "-r", str(filepath), "-T", "fields", "-e", "ftp.user", "-e", "ftp.pass", 
             "-Y", "ftp", "-q"],
            capture_output=True, text=True, timeout=60
        )
        if result.stdout.strip():
            creds_found.append(("FTP", result.stdout.strip()))
        
        # HTTP Basic Auth
        result = subprocess.run(
            ["tshark", "-r", str(filepath), "-T", "fields", "-e", "http.authbasic", 
             "-Y", "http.authbasic", "-q"],
            capture_output=True, text=True, timeout=60
        )
        if result.stdout.strip():
            creds_found.append(("HTTP Basic Auth", result.stdout.strip()))
        
        # Telnet
        result = subprocess.run(
            ["tshark", "-r", str(filepath), "-T", "fields", "-e", "telnet.data", 
             "-Y", "telnet", "-q"],
            capture_output=True, text=True, timeout=60
        )
        if result.stdout.strip():
            creds_found.append(("Telnet", result.stdout.strip()))
        
        if creds_found:
            print(f"{Fore.GREEN}[+] Found credentials:{Style.RESET_ALL}")
            creds_file = filepath.parent / f"{filepath.stem}_credentials.txt"
            with open(creds_file, 'w') as f:
                for proto, data in creds_found:
                    print(f"  {proto}: {data[:100]}")
                    f.write(f"{proto}:\n{data}\n\n")
            add_to_summary("PCAP-CREDENTIALS", f"Saved to '{creds_file.name}'")
            
            # Check for flags in credentials
            for proto, data in creds_found:
                for pattern in COMMON_FLAG_PATTERNS:
                    matches = re.findall(pattern, data, re.IGNORECASE)
                    for match in matches:
                        add_to_summary("PCAP-CREDS-FLAG", match)
        else:
            print(f"{Fore.YELLOW}[!] No credentials found{Style.RESET_ALL}")
    except Exception as e:
        print(f"{Fore.RED}[PCAP] Credentials extraction failed: {e}{Style.RESET_ALL}")

def search_pcap_flags(filepath: Path):
    if not AVAILABLE_TOOLS.get('tshark', False):
        print(f"{Fore.YELLOW}[PCAP] Tshark not installed. Skipping flag search.{Style.RESET_ALL}")
        return
    
    print(f"{Fore.GREEN}[PCAP] Searching for flags in packets...{Style.RESET_ALL}")
    
    try:
        # Extract data from various protocols
        result = subprocess.run(
            ["tshark", "-r", str(filepath), "-T", "fields", "-e", "data", "-q"],
            capture_output=True, text=True, timeout=120
        )
        
        data = result.stdout
        flags_found = []
        
        for pattern in COMMON_FLAG_PATTERNS:
            matches = re.findall(pattern, data, re.IGNORECASE)
            flags_found.extend(matches)
        
        if flags_found:
            print(f"{Fore.GREEN}[!] FLAGS FOUND in PCAP:{Style.RESET_ALL}")
            for flag in set(flags_found):
                print(f"  - {flag}")
                add_to_summary("PCAP-FLAG", flag)
        else:
            print(f"{Fore.YELLOW}[!] No flags found in packet data{Style.RESET_ALL}")
        
        # Also check HTTP data
        result = subprocess.run(
            ["tshark", "-r", str(filepath), "-T", "fields", "-e", "http.file_data", "-q"],
            capture_output=True, text=True, timeout=60
        )
        
        for pattern in COMMON_FLAG_PATTERNS:
            matches = re.findall(pattern, result.stdout, re.IGNORECASE)
            for match in matches:
                print(f"{Fore.GREEN}[!] FLAG in HTTP data: {match}{Style.RESET_ALL}")
                add_to_summary("PCAP-HTTP-FLAG", match)
        
        # Check TCP payload
        result = subprocess.run(
            ["tshark", "-r", str(filepath), "-T", "fields", "-e", "tcp.payload", "-q"],
            capture_output=True, text=True, timeout=60
        )
        
        for pattern in COMMON_FLAG_PATTERNS:
            matches = re.findall(pattern, result.stdout, re.IGNORECASE)
            for match in matches:
                print(f"{Fore.GREEN}[!] FLAG in TCP payload: {match}{Style.RESET_ALL}")
                add_to_summary("PCAP-TCP-FLAG", match)
                
    except Exception as e:
        print(f"{Fore.RED}[PCAP] Flag search failed: {e}{Style.RESET_ALL}")

def reconstruct_streams(filepath: Path):
    if not AVAILABLE_TOOLS.get('tshark', False):
        print(f"{Fore.YELLOW}[PCAP] Tshark not installed. Skipping stream reconstruction.{Style.RESET_ALL}")
        return
    
    print(f"{Fore.GREEN}[PCAP] Reconstructing TCP streams...{Style.RESET_ALL}")
    output_dir = filepath.parent / f"{filepath.stem}_streams"
    output_dir.mkdir(exist_ok=True)
    
    try:
        # Get number of streams
        result = subprocess.run(
            ["tshark", "-r", str(filepath), "-T", "fields", "-e", "tcp.stream", "-q"],
            capture_output=True, text=True, timeout=60
        )
        
        streams = set(result.stdout.strip().split('\n'))
        streams = [s for s in streams if s]
        
        if streams:
            print(f"{Fore.CYAN}[+] Found {len(streams)} TCP stream(s){Style.RESET_ALL}")
            
            for stream_num in streams[:10]:  # Process first 10 streams
                try:
                    result = subprocess.run(
                        ["tshark", "-r", str(filepath), "-q", "-z", f"follow,tcp,ascii,{stream_num}"],
                        capture_output=True, text=True, timeout=30
                    )
                    
                    stream_file = output_dir / f"stream_{stream_num}.txt"
                    with open(stream_file, 'w') as f:
                        f.write(result.stdout)
                    
                    # Check for flags in stream
                    for pattern in COMMON_FLAG_PATTERNS:
                        matches = re.findall(pattern, result.stdout, re.IGNORECASE)
                        for match in matches:
                            print(f"{Fore.GREEN}[!] FLAG in stream {stream_num}: {match}{Style.RESET_ALL}")
                            add_to_summary("PCAP-STREAM-FLAG", f"Stream {stream_num}: {match}")
                    
                    # Check base64
                    collect_base64_from_text(result.stdout)
                except:
                    continue
            
            add_to_summary("PCAP-STREAMS", f"{min(len(streams), 10)} streams saved to '{output_dir.name}'")
        else:
            print(f"{Fore.YELLOW}[!] No TCP streams found{Style.RESET_ALL}")
    except Exception as e:
        print(f"{Fore.RED}[PCAP] Stream reconstruction failed: {e}{Style.RESET_ALL}")

def analyze_windows_event_logs(filepath: Path):
    """Analyze Windows Event Logs (.evtx) for forensic evidence"""
    print(f"{Fore.GREEN}[WINDOWS-EVENT] Analyzing Windows Event Logs...{Style.RESET_ALL}")
    
    flags_found = []
    events_found = []
    
    try:
        import xml.etree.ElementTree as ET
        
        output_dir = filepath.parent / f"{filepath.stem}_event_analysis"
        output_dir.mkdir(exist_ok=True)
        
        result = subprocess.run(
            ["powershell", "-Command", 
             f"Get-WinEvent -Path '{filepath}' -Oldest | Select-Object -First 500 | ConvertTo-Xml -As String"],
            capture_output=True, text=True, timeout=60
        )
        
        if result.returncode != 0 or not result.stdout.strip():
            result = subprocess.run(
                ["powershell", "-Command", 
                 f"$events = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new('{filepath}')"],
                capture_output=True, text=True, timeout=30
            )
            print(f"{Fore.YELLOW}[WINDOWS-EVENT] Trying alternative parsing method...{Style.RESET_ALL}")
            
            import struct
            with open(filepath, 'rb') as f:
                raw_data = f.read()
            
            strings_data = ''.join(chr(b) if 32 <= b <= 126 else ' ' for b in raw_data)
            
            search_patterns = {
                'Installation': r'(install|setup|software|msi|uninstall)',
                'Execution': r'(execute|run|start|process|cmd|powershell)',
                'Shutdown': r'(shutdown|stop|exit|terminate|power)',
                'Logon': r'(logon|login|user|session|auth)',
            }
            
            for category, pattern in search_patterns.items():
                matches = re.findall(pattern, strings_data, re.IGNORECASE)
                if matches:
                    print(f"{Fore.CYAN}[+] Found {len(matches)} {category} related entries{Style.RESET_ALL}")
                    events_found.append(f"{category}: {len(matches)} entries")
                    add_to_summary(f"EVENT-{category.upper()}", f"{len(matches)} entries found")
            
            for pattern in COMMON_FLAG_PATTERNS:
                flag_matches = re.findall(pattern, strings_data, re.IGNORECASE)
                for match in flag_matches:
                    if match not in flags_found:
                        flags_found.append(match)
                        print(f"{Fore.GREEN}[!] FLAG FOUND in Event Log: {match}{Style.RESET_ALL}")
                        add_to_summary("EVENT-FLAG", match)
            
            return
        
        xml_output = result.stdout
        
        try:
            root = ET.fromstring(xml_output)
        except:
            xml_output = strings_data = ''.join(chr(b) if 32 <= b <= 126 else ' ' for b in open(filepath, 'rb').read())
            root = None
        
        if root is not None:
            events = root.findall(".//Object")
            
            event_summary = {
                'Info': [],
                'Warning': [],
                'Error': [],
            }
            
            for event in events[:500]:
                event_xml = ET.tostring(event, encoding='unicode')
                
                for pattern in COMMON_FLAG_PATTERNS:
                    matches = re.findall(pattern, event_xml, re.IGNORECASE)
                    for match in matches:
                        if match not in flags_found:
                            flags_found.append(match)
                            print(f"{Fore.GREEN}[!] FLAG FOUND: {match}{Style.RESET_ALL}")
                            add_to_summary("EVENT-FLAG", match)
                
                event_lower = event_xml.lower()
                if 'install' in event_lower or 'setup' in event_lower or 'msi' in event_lower:
                    event_summary['Info'].append(f"Installation event found")
                if 'execute' in event_lower or 'run' in event_lower or 'cmd.exe' in event_lower:
                    event_summary['Info'].append(f"Execution event found")
                if 'shutdown' in event_lower or 'power off' in event_lower:
                    event_summary['Error'].append(f"Shutdown event found")
                if 'logon' in event_lower or 'login' in event_lower:
                    event_summary['Info'].append(f"Logon event found")
            
            for level, events_list in event_summary.items():
                unique_events = list(set(events_list))[:5]
                if unique_events:
                    print(f"{Fore.CYAN}[+] {level}: {len(unique_events)} unique event types{Style.RESET_ALL}")
                    add_to_summary(f"EVENT-{level.upper()}", f"{len(unique_events)} event types")
        
        else:
            for pattern in COMMON_FLAG_PATTERNS:
                matches = re.findall(pattern, xml_output, re.IGNORECASE)
                for match in matches:
                    if match not in flags_found:
                        flags_found.append(match)
                        print(f"{Fore.GREEN}[!] FLAG FOUND: {match}{Style.RESET_ALL}")
                        add_to_summary("EVENT-FLAG", match)
            
            lines = xml_output.split('\n')
            for line in lines:
                line_lower = line.lower()
                if 'install' in line_lower or 'setup' in line_lower:
                    print(f"{Fore.CYAN}[+] Installation related: {line[:80]}...{Style.RESET_ALL}")
                    events_found.append("Installation event found")
                    break
            
            for line in lines:
                line_lower = line.lower()
                if 'execute' in line_lower or 'run' in line_lower or 'cmd' in line_lower:
                    print(f"{Fore.CYAN}[+] Execution related: {line[:80]}...{Style.RESET_ALL}")
                    events_found.append("Execution event found")
                    break
            
            for line in lines:
                line_lower = line.lower()
                if 'shutdown' in line_lower or 'power' in line_lower:
                    print(f"{Fore.RED}[!] Shutdown related: {line[:80]}...{Style.RESET_ALL}")
                    events_found.append("Shutdown event found")
                    break
        
        summary_file = output_dir / "event_analysis.txt"
        with open(summary_file, 'w') as f:
            f.write("Windows Event Log Analysis\n")
            f.write("="*50 + "\n\n")
            f.write(f"Source: {filepath.name}\n\n")
            f.write("Events Found:\n")
            for event in events_found:
                f.write(f"  - {event}\n")
            f.write(f"\nFlags Found: {len(flags_found)}\n")
            for flag in flags_found:
                f.write(f"  - {flag}\n")
        
        add_to_summary("EVENT-ANALYSIS", f"Results saved to '{summary_file.name}'")
        
        if not flags_found:
            print(f"{Fore.YELLOW}[WINDOWS-EVENT] No flags found in event log.{Style.RESET_ALL}")
            
    except subprocess.TimeoutExpired:
        print(f"{Fore.RED}[WINDOWS-EVENT] Timeout parsing event log.{Style.RESET_ALL}")
    except Exception as e:
        print(f"{Fore.RED}[WINDOWS-EVENT] Analysis failed: {e}{Style.RESET_ALL}")

def parse_raw_event_log(filepath: Path):
    """Parse raw event log file for flags and artifacts"""
    print(f"{Fore.GREEN}[RAW-EVENT] Parsing raw event log data...{Style.RESET_ALL}")
    
    flags_found = []
    
    try:
        with open(filepath, 'rb') as f:
            raw_data = f.read()
        
        strings_data = ''.join(chr(b) if 32 <= b <= 126 else '\n' for b in raw_data)
        
        print(f"{Fore.CYAN}[+] Searching for installation evidence...{Style.RESET_ALL}")
        install_patterns = [
            r'MSI.*install',
            r'Software.*Install',
            r'Installation',
            r'\.exe.*installed',
            r'program.*files',
        ]
        
        for pattern in install_patterns:
            matches = re.findall(pattern, strings_data, re.IGNORECASE)
            if matches:
                print(f"  Found: {len(matches)} matches for '{pattern}'")
                add_to_summary("INSTALL-EVIDENCE", f"{pattern}: {len(matches)} matches")
        
        print(f"{Fore.CYAN}[+] Searching for execution evidence...{Style.RESET_ALL}")
        exec_patterns = [
            r'cmd\.exe',
            r'powershell\.exe',
            r'Process.*Start',
            r'CreatedProcess',
            r'New Process',
        ]
        
        for pattern in exec_patterns:
            matches = re.findall(pattern, strings_data, re.IGNORECASE)
            if matches:
                print(f"  Found: {len(matches)} matches for '{pattern}'")
                add_to_summary("EXEC-EVIDENCE", f"{pattern}: {len(matches)} matches")
        
        print(f"{Fore.CYAN}[+] Searching for shutdown/reboot evidence...{Style.RESET_ALL}")
        shutdown_patterns = [
            r'Shutdown',
            r'System.*Power',
            r'PowerOff',
            r'BSOD',
            r'Crash',
            r'EventID.*6008',
            r'EventID.*1074',
        ]
        
        for pattern in shutdown_patterns:
            matches = re.findall(pattern, strings_data, re.IGNORECASE)
            if matches:
                print(f"  Found: {len(matches)} matches for '{pattern}'")
                add_to_summary("SHUTDOWN-EVIDENCE", f"{pattern}: {len(matches)} matches")
        
        print(f"{Fore.CYAN}[+] Searching for logon events...{Style.RESET_ALL}")
        logon_patterns = [
            r'Logon',
            r'LogonType',
            r'EventID.*4624',
            r'EventID.*4625',
            r'Session.*Connect',
        ]
        
        for pattern in logon_patterns:
            matches = re.findall(pattern, strings_data, re.IGNORECASE)
            if matches:
                print(f"  Found: {len(matches)} matches for '{pattern}'")
                add_to_summary("LOGON-EVIDENCE", f"{pattern}: {len(matches)} matches")
        
        print(f"{Fore.GREEN}[+] Searching for flags...{Style.RESET_ALL}")
        for pattern in COMMON_FLAG_PATTERNS:
            matches = re.findall(pattern, strings_data, re.IGNORECASE)
            for match in matches:
                if match not in flags_found:
                    flags_found.append(match)
                    print(f"{Fore.GREEN}[!] FLAG FOUND: {match}{Style.RESET_ALL}")
                    add_to_summary("EVENT-FLAG", match)
        
        if not flags_found:
            b64_matches = re.findall(r'[A-Za-z0-9+/]{20,}={0,2}', strings_data)
            for b64 in b64_matches[:10]:
                decoded = decode_base64(b64)
                if decoded:
                    print(f"{Fore.CYAN}[+] Base64 decoded: {decoded[:50]}...{Style.RESET_ALL}")
                    collect_base64_from_text(decoded)
                    for pattern in COMMON_FLAG_PATTERNS:
                        flag_matches = re.findall(pattern, decoded, re.IGNORECASE)
                        for match in flag_matches:
                            if match not in flags_found:
                                flags_found.append(match)
                                print(f"{Fore.GREEN}[!] FLAG from base64: {match}{Style.RESET_ALL}")
                                add_to_summary("EVENT-B64-FLAG", match)
        
        output_dir = filepath.parent / f"{filepath.stem}_event_analysis"
        output_dir.mkdir(exist_ok=True)
        summary_file = output_dir / "event_evidence.txt"
        
        with open(summary_file, 'w') as f:
            f.write("Event Log Evidence Summary\n")
            f.write("="*50 + "\n\n")
            f.write(f"File: {filepath.name}\n")
            f.write(f"Size: {len(raw_data)} bytes\n\n")
            f.write("Analysis:\n")
            for item in flag_summary[-20:]:
                f.write(f"  {item}\n")
        
        add_to_summary("EVENT-ANALYSIS", f"Evidence saved to '{summary_file.name}'")
        
    except Exception as e:
        print(f"{Fore.RED}[RAW-EVENT] Failed: {e}{Style.RESET_ALL}")

def check_unusual_ports(filepath: Path):
    if not AVAILABLE_TOOLS.get('tshark', False):
        return
    
    print(f"{Fore.GREEN}[PCAP] Checking for unusual ports...{Style.RESET_ALL}")
    
    try:
        # Get all destination ports
        result = subprocess.run(
            ["tshark", "-r", str(filepath), "-T", "fields", "-e", "tcp.dstport", "-e", "udp.dstport", "-q"],
            capture_output=True, text=True, timeout=60
        )
        
        ports = result.stdout.strip().split('\n')
        port_counts = {}
        
        for line in ports:
            for port in line.split('\t'):
                if port:
                    port_counts[port] = port_counts.get(port, 0) + 1
        
        # Common ports
        common_ports = {'80', '443', '22', '21', '53', '25', '110', '143', '993', '995', '8080', '8443'}
        unusual = {p: c for p, c in port_counts.items() if p not in common_ports and c > 0}
        
        if unusual:
            print(f"{Fore.CYAN}[+] Unusual ports detected:{Style.RESET_ALL}")
            for port, count in sorted(unusual.items(), key=lambda x: x[1], reverse=True)[:10]:
                print(f"  Port {port}: {count} packets")
                add_to_summary("PCAP-PORT", f"Port {port}: {count} packets")
    except Exception as e:
        print(f"{Fore.YELLOW}[PCAP] Port analysis failed: {e}{Style.RESET_ALL}")

# ============================================================
# PH4NT0M 1NTRUD3R - Advanced PCAP Analysis for CTF Challenges
# ============================================================

def analyze_pcap_timeline(filepath: Path):
    """Analyze PCAP timeline to track attacks chronologically"""
    if not AVAILABLE_TOOLS.get('tshark', False):
        return
    
    print(f"{Fore.GREEN}[PCAP-TIMELINE] Analyzing attack timeline...{Style.RESET_ALL}")
    
    try:
        # Get all HTTP requests with timestamps
        result = subprocess.run(
            ["tshark", "-r", str(filepath), "-T", "fields", 
             "-e", "frame.time", "-e", "http.request.uri", 
             "-e", "http.request.method", "-e", "ip.src",
             "-Y", "http.request", "-q"],
            capture_output=True, text=True, timeout=60
        )
        
        if result.stdout.strip():
            print(f"{Fore.CYAN}[+] HTTP Request Timeline:{Style.RESET_ALL}")
            lines = result.stdout.strip().split('\n')
            for i, line in enumerate(lines[:20], 1):  # Show first 20
                parts = line.split('\t')
                if len(parts) >= 3:
                    time_str = parts[0][:30] if len(parts[0]) > 30 else parts[0]
                    method = parts[2] if len(parts) > 2 else "GET"
                    uri = parts[1][:60] if len(parts[1]) > 60 else parts[1]
                    print(f"  [{i}] {time_str} | {method} {uri}")
            
            add_to_summary("PCAP-TIMELINE", f"{len(lines)} HTTP requests tracked")
            
            # Save timeline
            timeline_file = filepath.parent / f"{filepath.stem}_timeline.txt"
            with open(timeline_file, 'w') as f:
                f.write("Attack Timeline Analysis\n")
                f.write("="*60 + "\n\n")
                for line in lines:
                    f.write(line + "\n")
            
            print(f"{Fore.CYAN}[+] Timeline saved to: {timeline_file.name}{Style.RESET_ALL}")
            
    except Exception as e:
        print(f"{Fore.YELLOW}[PCAP-TIMELINE] Failed: {e}{Style.RESET_ALL}")

def detect_attack_patterns(filepath: Path):
    """Detect common attack patterns in PCAP"""
    if not AVAILABLE_TOOLS.get('tshark', False):
        return
    
    print(f"{Fore.GREEN}[PCAP-ATTACK] Detecting attack patterns...{Style.RESET_ALL}")
    
    # Attack patterns to detect
    attack_signatures = {
        'SQL Injection': r"(\bunion\b|\bselect\b|\binsert\b|\bdelete\b|\bdrop\b|%27|')",
        'XSS': r"(<script|javascript:|onerror=|onload=|alert\()",
        'LFI/RFI': r"(\.\.\/|\.\.\\|%2e%2e%2f|file:\/\/)",
        'Command Injection': r"(;|\||&&|\$\(|`)\s*(cat|ls|pwd|whoami|id)",
        'Directory Traversal': r"(\.\.\/){2,}",
        'Path Traversal': r"(%2e%2e%2f|%2e%2e%5c){1,}",
    }
    
    attacks_found = []
    
    try:
        # Get HTTP data
        result = subprocess.run(
            ["tshark", "-r", str(filepath), "-T", "fields",
             "-e", "http.request.uri", "-e", "http.request.method",
             "-e", "frame.time", "-Y", "http", "-q"],
            capture_output=True, text=True, timeout=60
        )
        
        http_data = result.stdout
        
        # Check for each attack pattern
        for attack_type, pattern in attack_signatures.items():
            matches = re.findall(pattern, http_data, re.IGNORECASE)
            if matches:
                count = len(matches)
                print(f"{Fore.RED}[!] {attack_type} detected: {count} occurrences{Style.RESET_ALL}")
                attacks_found.append((attack_type, count))
                add_to_summary("PCAP-ATTACK", f"{attack_type}: {count} hits")
        
        # Look for suspicious HTTP methods or paths
        suspicious_patterns = [
            (r"\/admin", "Admin panel access"),
            (r"\/wp-login", "WordPress login attempt"),
            (r"\/phpmyadmin", "phpMyAdmin access"),
            (r"\b(cmd|command|exec|eval)\b", "Command execution attempt"),
        ]
        
        for pattern, description in suspicious_patterns:
            matches = re.findall(pattern, http_data, re.IGNORECASE)
            if matches:
                print(f"{Fore.YELLOW}[!] {description}: {len(matches)} occurrences{Style.RESET_ALL}")
                add_to_summary("PCAP-SUSPICIOUS", f"{description}: {len(matches)}")
        
        if not attacks_found:
            print(f"{Fore.CYAN}[+] No obvious attack patterns detected{Style.RESET_ALL}")
            
    except Exception as e:
        print(f"{Fore.YELLOW}[PCAP-ATTACK] Failed: {e}{Style.RESET_ALL}")

def analyze_post_data(filepath: Path):
    """Analyze POST request data for flags and credentials"""
    if not AVAILABLE_TOOLS.get('tshark', False):
        return
    
    print(f"{Fore.GREEN}[PCAP-POST] Analyzing POST data...{Style.RESET_ALL}")
    
    try:
        # Extract POST data
        result = subprocess.run(
            ["tshark", "-r", str(filepath), "-T", "fields",
             "-e", "http.request.method", "-e", "http.request.uri",
             "-e", "http.file_data", "-Y", "http.request.method == \"POST\"", "-q"],
            capture_output=True, text=True, timeout=60
        )
        
        post_data = result.stdout
        
        if post_data.strip():
            print(f"{Fore.CYAN}[+] POST requests found:{Style.RESET_ALL}")
            
            # Search for flags in POST data
            for pattern in COMMON_FLAG_PATTERNS:
                matches = re.findall(pattern, post_data, re.IGNORECASE)
                for match in matches:
                    print(f"{Fore.GREEN}[!] FLAG in POST data: {match}{Style.RESET_ALL}")
                    add_to_summary("PCAP-POST-FLAG", match)
            
            # Look for credentials
            cred_patterns = [
                r"(username|user|login)=[^&\s]{3,}",
                r"(password|pass|pwd)=[^&\s]{3,}",
                r"email=[^&\s]+@[^&\s]+",
            ]
            
            for pattern in cred_patterns:
                matches = re.findall(pattern, post_data, re.IGNORECASE)
                if matches:
                    print(f"{Fore.YELLOW}[!] Credentials found in POST data{Style.RESET_ALL}")
                    for match in matches[:5]:
                        print(f"    {match[:80]}")
                    add_to_summary("PCAP-CREDENTIALS", f"Found {len(matches)} credential patterns")
                    break
            
            # Check for data exfiltration (large POSTs)
            lines = post_data.split('\n')
            for line in lines:
                parts = line.split('\t')
                if len(parts) >= 3 and len(parts[2]) > 100:
                    print(f"{Fore.CYAN}[+] Large POST detected ({len(parts[2])} bytes) to: {parts[1]}{Style.RESET_ALL}")
                    
                    # Try to decode base64 in large POSTs
                    b64_pattern = r'[A-Za-z0-9+/]{40,}={0,2}'
                    b64_matches = re.findall(b64_pattern, parts[2])
                    for b64 in b64_matches[:3]:
                        try:
                            decoded = base64.b64decode(b64).decode('utf-8', errors='ignore')
                            if len(decoded) > 10 and any(c.isprintable() for c in decoded):
                                print(f"{Fore.GREEN}[+] Base64 decoded from POST: {decoded[:100]}{Style.RESET_ALL}")
                                add_to_summary("PCAP-POST-DATA", f"Base64: {decoded[:50]}")
                        except:
                            pass
        else:
            print(f"{Fore.CYAN}[+] No POST data found{Style.RESET_ALL}")
            
    except Exception as e:
        print(f"{Fore.YELLOW}[PCAP-POST] Failed: {e}{Style.RESET_ALL}")

def find_data_exfiltration(filepath: Path):
    """Detect potential data exfiltration patterns"""
    if not AVAILABLE_TOOLS.get('tshark', False):
        return
    
    print(f"{Fore.GREEN}[PCAP-EXFIL] Searching for data exfiltration...{Style.RESET_ALL}")
    
    try:
        # Check for large outbound transfers
        result = subprocess.run(
            ["tshark", "-r", str(filepath), "-T", "fields",
             "-e", "frame.len", "-e", "ip.src", "-e", "ip.dst",
             "-e", "frame.time", "-Y", "tcp", "-q"],
            capture_output=True, text=True, timeout=60
        )
        
        # Find large packets
        large_packets = []
        for line in result.stdout.strip().split('\n')[:1000]:  # Check first 1000
            parts = line.split('\t')
            if len(parts) >= 4:
                try:
                    pkt_len = int(parts[0])
                    if pkt_len > 5000:  # Large packets
                        large_packets.append((pkt_len, parts[1], parts[2], parts[3]))
                except:
                    pass
        
        if large_packets:
            print(f"{Fore.CYAN}[+] Large data transfers detected:{Style.RESET_ALL}")
            # Sort by size
            large_packets.sort(reverse=True)
            for size, src, dst, time in large_packets[:10]:
                print(f"  {size} bytes: {src} -> {dst}")
            add_to_summary("PCAP-EXFIL", f"{len(large_packets)} large transfers detected")
        
        # Check for encoded data in requests
        result = subprocess.run(
            ["tshark", "-r", str(filepath), "-T", "fields",
             "-e", "http.request.uri", "-Y", "http", "-q"],
            capture_output=True, text=True, timeout=60
        )
        
        # Look for encoded/encrypted data in URIs
        encoded_patterns = [
            r"data=[A-Za-z0-9+/]{50,}",
            r"file=[A-Za-z0-9+/]{50,}",
            r"content=[A-Za-z0-9+/]{50,}",
        ]
        
        for pattern in encoded_patterns:
            matches = re.findall(pattern, result.stdout)
            if matches:
                print(f"{Fore.RED}[!] Possible data exfiltration in URI parameters{Style.RESET_ALL}")
                for match in matches[:3]:
                    print(f"    {match[:80]}")
                add_to_summary("PCAP-EXFIL", f"Encoded data in URI: {len(matches)} matches")
                break
                
    except Exception as e:
        print(f"{Fore.YELLOW}[PCAP-EXFIL] Failed: {e}{Style.RESET_ALL}")

def extract_compressed_disk(filepath: Path) -> Path:
    """Extract compressed disk image (GZIP, ZIP, etc.) and return extracted file path"""
    print(f"{Fore.CYAN}[DISK] Detected compressed file, extracting...{Style.RESET_ALL}")
    
    output_dir = filepath.parent / f"{filepath.stem}_extracted"
    output_dir.mkdir(exist_ok=True)
    
    file_type = subprocess.getoutput(f"file -b '{filepath}'").lower()
    
    try:
        # Handle GZIP - use Python's gzip module for better control
        if "gzip" in file_type:
            import gzip
            # Try to get original filename from file output
            orig_name = "disk_image.dd"
            if "was \"" in file_type:
                # Extract filename from "was \"filename\""
                start = file_type.find("was \"") + 5
                end = file_type.find("\"", start)
                if end > start:
                    orig_name = file_type[start:end]
            
            extracted_path = output_dir / orig_name
            
            # Extract with progress indicator
            print(f"{Fore.CYAN}[DISK] Extracting GZIP file...{Style.RESET_ALL}")
            with gzip.open(filepath, 'rb') as f_in:
                with open(extracted_path, 'wb') as f_out:
                    # Copy in chunks to show progress
                    chunk_size = 1024 * 1024  # 1MB chunks
                    while True:
                        chunk = f_in.read(chunk_size)
                        if not chunk:
                            break
                        f_out.write(chunk)
            
            if extracted_path.exists() and extracted_path.stat().st_size > 0:
                print(f"{Fore.GREEN}[+] Extracted GZIP to: {extracted_path.name} ({extracted_path.stat().st_size / 1024 / 1024:.1f}MB){Style.RESET_ALL}")
                add_to_summary("DISK-EXTRACT", f"GZIP extracted to {extracted_path.name}")
                return extracted_path
        
        # Handle ZIP
        elif "zip" in file_type:
            import zipfile
            extracted_path = output_dir / f"{filepath.stem}_zip"
            extracted_path.mkdir(exist_ok=True)
            
            print(f"{Fore.CYAN}[DISK] Extracting ZIP file...{Style.RESET_ALL}")
            with zipfile.ZipFile(filepath, 'r') as zip_ref:
                zip_ref.extractall(extracted_path)
            
            # Find the largest file (likely the disk image)
            files = [f for f in extracted_path.rglob("*") if f.is_file()]
            if files:
                largest = max(files, key=lambda x: x.stat().st_size)
                print(f"{Fore.GREEN}[+] Extracted ZIP, largest file: {largest.name} ({largest.stat().st_size / 1024 / 1024:.1f}MB){Style.RESET_ALL}")
                add_to_summary("DISK-EXTRACT", f"ZIP extracted, largest: {largest.name}")
                return largest
        
        # Handle 7Z
        elif "7-zip" in file_type or "7z" in file_type or filepath.suffix.lower() == '.7z':
            extracted_path = output_dir / f"{filepath.stem}_7z"
            extracted_path.mkdir(exist_ok=True)
            
            print(f"{Fore.CYAN}[DISK] Extracting 7Z file...{Style.RESET_ALL}")
            subprocess.run(
                ["7z", "x", "-y", str(filepath), f"-o{extracted_path}"],
                capture_output=True, timeout=60
            )
            
            files = [f for f in extracted_path.rglob("*") if f.is_file()]
            if files:
                largest = max(files, key=lambda x: x.stat().st_size)
                print(f"{Fore.GREEN}[+] Extracted 7Z, largest file: {largest.name} ({largest.stat().st_size / 1024 / 1024:.1f}MB){Style.RESET_ALL}")
                add_to_summary("DISK-EXTRACT", f"7Z extracted, largest: {largest.name}")
                return largest
                
    except Exception as e:
        print(f"{Fore.YELLOW}[!] Extraction failed: {e}{Style.RESET_ALL}")
    
    print(f"{Fore.YELLOW}[!] Could not extract, using original file{Style.RESET_ALL}")
    return filepath

def analyze_disk_image(filepath: Path):
    """Analyze disk image using strings to find flags (for DISKO CTF challenges) - FAST VERSION"""
    print(f"{Fore.GREEN}[DISK] Analyzing disk image for hidden flags (FAST MODE)...{Style.RESET_ALL}")
    
    output_dir = filepath.parent / f"{filepath.stem}_disk_analysis"
    output_dir.mkdir(exist_ok=True)
    
    flags_found = []
    MIN_STRING_LEN = 8  # Increased from 4 to reduce noise
    MAX_KEYWORD_RESULTS = 10  # Limit keyword matches
    MAX_EMBEDDED_EXTRACT = 5  # Limit embedded file extraction
    CHUNK_SIZE = 1024 * 1024  # 1MB chunks for reading
    
    try:
        # Run both ASCII and Unicode strings in parallel for speed
        print(f"{Fore.CYAN}[DISK] Extracting strings (ASCII + Unicode)...{Style.RESET_ALL}")
        
        # Use grep to filter for potential flags directly (much faster)
        flag_patterns_grep = ['picoCTF', 'CTF{', 'flag{', 'FLAG{']
        grep_pattern = '|'.join(flag_patterns_grep)
        
        # Extract strings with higher minimum length and grep filter
        cmd_ascii = f"strings -n {MIN_STRING_LEN} '{filepath}' | grep -iE '({grep_pattern})' 2>/dev/null || strings -n {MIN_STRING_LEN} '{filepath}' | head -10000"
        cmd_unicode = f"strings -e l -n {MIN_STRING_LEN} '{filepath}' | grep -iE '({grep_pattern})' 2>/dev/null || strings -e l -n {MIN_STRING_LEN} '{filepath}' | head -5000"
        
        result_ascii = subprocess.run(cmd_ascii, shell=True, capture_output=True, text=True, timeout=30)
        ascii_strings = result_ascii.stdout
        
        result_unicode = subprocess.run(cmd_unicode, shell=True, capture_output=True, text=True, timeout=30)
        unicode_strings = result_unicode.stdout
        
        # Combine all strings
        all_strings = ascii_strings + "\n" + unicode_strings
        
        # Save strings to file (async/write in background would be better but keeping it simple)
        strings_file = output_dir / "extracted_strings.txt"
        with open(strings_file, 'w', encoding='utf-8', errors='ignore') as f:
            f.write(all_strings[:100000])  # Limit output file size
        print(f"{Fore.CYAN}[+] Strings saved to: {strings_file.name}{Style.RESET_ALL}")
        
        # Search for common flag patterns
        print(f"{Fore.GREEN}[DISK] Searching for flags in strings...{Style.RESET_ALL}")
        for pattern in COMMON_FLAG_PATTERNS:
            matches = re.findall(pattern, all_strings, re.IGNORECASE)
            for match in matches[:5]:  # Limit to first 5 matches per pattern
                if match not in flags_found:
                    flags_found.append(match)
                    print(f"{Fore.GREEN}[!] FLAG FOUND: {match}{Style.RESET_ALL}")
                    add_to_summary("DISK-FLAG", match)
        
        # Search for common CTF keywords (optimized)
        ctf_keywords = ['flag{', 'ctf{', 'picoctf', 'password', 'secret']
        print(f"{Fore.CYAN}[DISK] Searching for CTF keywords...{Style.RESET_ALL}")
        
        keyword_matches = []
        lines = all_strings.split('\n')
        seen_lines = set()
        
        for line in lines[:1000]:  # Limit to first 1000 lines
            if len(keyword_matches) >= MAX_KEYWORD_RESULTS:
                break
            
            line_lower = line.lower()
            for keyword in ctf_keywords:
                if keyword in line_lower and line.strip() and line.strip() not in seen_lines:
                    keyword_matches.append((keyword, line.strip()))
                    seen_lines.add(line.strip())
                    break
        
        if keyword_matches:
            print(f"{Fore.CYAN}[+] Found {len(keyword_matches)} potential hints:{Style.RESET_ALL}")
            for keyword, line in keyword_matches:
                print(f"  [{keyword}] {line[:80]}")
                add_to_summary("DISK-KEYWORD", f"{keyword}: {line[:60]}")
        
        # Check for Base64 encoded data (limited)
        print(f"{Fore.CYAN}[DISK] Checking for Base64 encoded data...{Style.RESET_ALL}")
        collect_base64_from_text(all_strings[:50000])  # Limit text size
        
        # Search for file signatures (optimized - only scan first 10MB)
        print(f"{Fore.CYAN}[DISK] Checking for embedded files...{Style.RESET_ALL}")
        
        # Only read first 10MB for signature scanning (much faster)
        file_size = filepath.stat().st_size
        scan_size = min(10 * 1024 * 1024, file_size)  # 10MB max
        
        with open(filepath, 'rb') as f:
            raw_data = f.read(scan_size)
        
        embedded_files = []
        # Only check most common file types
        common_sigs = {
            "png": b"\x89\x50\x4E\x47\x0D\x0A\x1A\x0A",
            "jpg": b"\xFF\xD8\xFF",
            "zip": b"\x50\x4B\x03\x04",
            "pdf": b"\x25\x50\x44\x46",
            "gif": b"\x47\x49\x46\x38",
        }
        
        for ext, sig in common_sigs.items():
            idx = raw_data.find(sig)
            if idx != -1:
                embedded_files.append((ext, idx))
                print(f"  [+] Found {ext.upper()} signature at offset {idx}")
                add_to_summary("DISK-FILE", f"{ext.upper()} at offset {idx}")
        
        if embedded_files:
            print(f"{Fore.GREEN}[+] Found {len(embedded_files)} file signatures{Style.RESET_ALL}")
            # Try to extract only first few files
            for ext, offset in embedded_files[:MAX_EMBEDDED_EXTRACT]:
                try:
                    # Extract up to 5KB after the signature
                    extract_size = min(5120, len(raw_data) - offset)
                    extracted_data = raw_data[offset:offset + extract_size]
                    
                    extract_file = output_dir / f"extracted_{ext}_offset_{offset}.bin"
                    with open(extract_file, 'wb') as ef:
                        ef.write(extracted_data)
                    
                    # Quick strings search for flags
                    result = subprocess.run(['strings', '-n', '8'], input=extracted_data, 
                                          capture_output=True, text=True, timeout=5)
                    extracted_strings = result.stdout
                    
                    for pattern in COMMON_FLAG_PATTERNS[:2]:  # Only first 2 patterns
                        matches = re.findall(pattern, extracted_strings, re.IGNORECASE)
                        for match in matches[:2]:  # Limit matches
                            if match not in flags_found:
                                flags_found.append(match)
                                print(f"{Fore.GREEN}[!] FLAG in embedded {ext}: {match}{Style.RESET_ALL}")
                                add_to_summary("DISK-EMBEDDED-FLAG", f"{match} in {ext} at offset {offset}")
                except Exception as e:
                    continue
        
        # Save summary
        summary_file = output_dir / "analysis_summary.txt"
        with open(summary_file, 'w') as f:
            f.write(f"Disk Image Analysis Summary\n")
            f.write(f"="*50 + "\n")
            f.write(f"File: {filepath.name}\n")
            f.write(f"Size: {filepath.stat().st_size} bytes\n\n")
            f.write(f"Flags Found: {len(flags_found)}\n")
            for flag in flags_found:
                f.write(f"  - {flag}\n")
            f.write(f"\nFile Signatures Found: {len(embedded_files)}\n")
            for ext, offset in embedded_files:
                f.write(f"  - {ext.upper()} at offset {offset}\n")
        
        add_to_summary("DISK-ANALYSIS", f"Results saved to '{output_dir.name}'")
        
        if not flags_found:
            print(f"{Fore.YELLOW}[!] No flags found in disk image{Style.RESET_ALL}")
        
    except subprocess.TimeoutExpired:
        print(f"{Fore.RED}[DISK] Analysis timeout.{Style.RESET_ALL}")
    except Exception as e:
        print(f"{Fore.RED}[DISK] Analysis failed: {e}{Style.RESET_ALL}")

def analyze_pcap_full(filepath: Path):
    print(f"{Fore.BLUE}{'='*60}")
    print(f"PCAP ANALYSIS: {filepath.name}")
    print(f"{'='*60}{Style.RESET_ALL}")
    
    analyze_pcap_basic(filepath)
    extract_http_objects(filepath)
    extract_dns_queries(filepath)
    extract_credentials(filepath)
    
    # Advanced Attack Analysis (for intrusion detection challenges)
    print(f"\n{Fore.MAGENTA}{'='*60}")
    print(f"🔍 ADVANCED ATTACK ANALYSIS")
    print(f"{'='*60}{Style.RESET_ALL}")
    
    analyze_pcap_timeline(filepath)
    detect_attack_patterns(filepath)
    analyze_post_data(filepath)
    find_data_exfiltration(filepath)
    search_pcap_flags(filepath)
    reconstruct_streams(filepath)
    check_unusual_ports(filepath)
    
    print(f"{Fore.GREEN}[PCAP] Analysis complete!{Style.RESET_ALL}")

def process_file(filepath: Path, args):
    print(f"\n{Fore.BLUE}{'='*60}")
    print(f"PROCESSING: {filepath.name}")
    print(f"{'='*60}{Style.RESET_ALL}")

    reset_globals()
    repaired = fix_header(filepath)

    print(f"\n{Fore.GREEN}[METADATA]{Style.RESET_ALL}")
    file_desc = subprocess.getoutput(f"file -b '{repaired}'").lower()
    print(f"Type: {file_desc}")
    try:
        exif_output = subprocess.getoutput(f"exiftool '{repaired}'")
        print(f"{Fore.CYAN}{exif_output}{Style.RESET_ALL}")
        collect_base64_from_text(exif_output)
    except Exception as e:
        print(f"{Fore.YELLOW}ExifTool failed or not installed: {e}{Style.RESET_ALL}")

    analyze_strings_and_flags(repaired, args.format)

    # Auto-decode encoded data if requested
    if args.decode or args.extract or args.all or args.auto:
        auto_decode_and_extract(repaired)

    is_image = any(kw in file_desc for kw in ["image", "jpeg", "png", "bitmap", "gif"])
    is_archive = any(kw in file_desc for kw in ["archive", "zip", "rar", "7-zip", "tar"])
    is_executable = "executable" in file_desc or "elf" in file_desc
    is_png = "png" in file_desc
    is_jpg = "jpeg" in file_desc or "jpg" in file_desc
    is_pcap = "pcap" in file_desc or "capture" in file_desc or repaired.suffix.lower() in ['.pcap', '.pcapng', '.cap']
    is_disk = repaired.suffix.lower() in ['.dd', '.img', '.raw', '.iso', '.vmdk', '.qcow2', '.vhd'] or args.disk
    is_eventlog = repaired.suffix.lower() in ['.evtx', '.evt'] or args.windows
    
    # Check if it's a compressed disk image (e.g., .crdownload, .gz containing .dd)
    is_compressed_disk = False
    if "gzip" in file_desc and (".dd" in file_desc or ".img" in file_desc):
        is_compressed_disk = True
        print(f"{Fore.CYAN}[INFO] Detected compressed disk image (GZIP containing disk){Style.RESET_ALL}")
        repaired = extract_compressed_disk(repaired)
        is_disk = True
    elif is_disk and ("gzip" in file_desc or "zip" in file_desc):
        is_compressed_disk = True
        print(f"{Fore.CYAN}[INFO] Disk file appears to be compressed, extracting...{Style.RESET_ALL}")
        repaired = extract_compressed_disk(repaired)

    if args.quick:
        print(f"\n{Fore.MAGENTA}[QUICK-MODE] 🚀 Ultra-fast CTF analysis - Early exit enabled{Style.RESET_ALL}")
        analyze_strings_and_flags(repaired, args.format)
        auto_decode_and_extract(repaired)
        
        if is_image:
            if is_png and AVAILABLE_TOOLS.get('zsteg'):
                analyze_zsteg(repaired)
                if check_early_exit():
                    print_final_report(filepath.name)
                    return {'flags': [f for f in flag_summary if 'FLAG' in f], 'extractions': [e for e in flag_summary if 'EXTRACT' in e], 'base64': base64_collector.copy()}
            if is_jpg and AVAILABLE_TOOLS.get('steghide'):
                analyze_steghide(repaired)
                if check_early_exit():
                    print_final_report(filepath.name)
                    return {'flags': [f for f in flag_summary if 'FLAG' in f], 'extractions': [e for e in flag_summary if 'EXTRACT' in e], 'base64': base64_collector.copy()}
        
        if is_pcap:
            analyze_pcap_basic(filepath)
            search_pcap_flags(filepath)
            if check_early_exit():
                print_final_report(filepath.name)
                return {'flags': [f for f in flag_summary if 'FLAG' in f], 'extractions': [e for e in flag_summary if 'EXTRACT' in e], 'base64': base64_collector.copy()}
        
        print_final_report(filepath.name)
        return {
            'flags': [item for item in flag_summary if "-FLAG" in item or "FLAG-" in item],
            'extractions': [item for item in flag_summary if "-EXTRACT" in item],
            'base64': base64_collector.copy()
        }

    if args.pcap and is_pcap:
        analyze_pcap_full(repaired)
        print_final_report(filepath.name)
        return {
            'flags': [item for item in flag_summary if "-FLAG" in item or "FLAG-" in item],
            'extractions': [item for item in flag_summary if "-EXTRACT" in item],
            'base64': base64_collector.copy()
        }

    if args.all or args.auto:
        print(f"\n{Fore.CYAN}[AUTO-MODE] Running all available analyses...{Style.RESET_ALL}")
        
        if is_image:
            analyze_image(repaired, deep=args.deep, alpha=args.alpha)
            analyze_graphicsmagick(repaired)
            analyze_exif_deep(repaired)
            analyze_steg_methods(repaired)
            
            if args.lsbextract or args.all:
                extract_lsb_data(repaired)
            
            if args.compare:
                compare_images(repaired, Path(args.compare))
            
            if is_png:
                if args.lsb or args.all or args.auto:
                    analyze_zsteg(repaired)
                if args.steghide or args.all or args.auto:
                    analyze_steghide(repaired)
                if args.pngcheck or args.all or args.auto:
                    analyze_pngcheck(repaired)
            
            if is_jpg:
                if args.outguess or args.all or args.auto:
                    analyze_outguess(repaired)
                if args.steghide or args.all or args.auto:
                    analyze_steghide(repaired)
                if args.jpsteg or args.all or args.auto:
                    analyze_jpseek(repaired)
            
            if args.remap or args.all:
                color_remapping(repaired)
        
        if is_archive:
            if args.foremost or args.all or args.auto:
                # Use quick mode for auto to prevent hanging on large files
                is_quick = args.auto and not args.all
                analyze_foremost(repaired, quick=is_quick)
            if args.auto:
                analyze_with_binwalk(repaired)
        
        if args.bruteforce and is_image:
            wordlist = DEFAULT_WORDLIST
            if args.wordlist:
                wordlist_path = Path(args.wordlist)
                if wordlist_path.exists():
                    wordlist = wordlist_path.read_text().splitlines()
            bruteforce_steghide(repaired, wordlist, args.delay, args.parallel)
        
        if is_disk or args.disk:
            analyze_disk_image(repaired)
        
        if is_eventlog or args.windows:
            analyze_windows_event_logs(repaired)
            parse_raw_event_log(repaired)
    
    else:
        if is_image:
            analyze_image(repaired, deep=args.deep, alpha=args.alpha)
            
            if args.exif:
                analyze_exif_deep(repaired)
            if args.stegdetect:
                analyze_steg_methods(repaired)
            if args.lsbextract:
                extract_lsb_data(repaired)
            if args.compare:
                compare_images(repaired, Path(args.compare))
            
            if args.lsb:
                analyze_zsteg(repaired)
            if args.steghide:
                analyze_steghide(repaired)
            if args.outguess:
                analyze_outguess(repaired)
            if args.pngcheck:
                analyze_pngcheck(repaired)
            if args.jpsteg:
                analyze_jpseek(repaired)
            if args.remap:
                color_remapping(repaired)
            if args.foremost:
                analyze_foremost(repaired)
            if args.bruteforce:
                wordlist = DEFAULT_WORDLIST
                if args.wordlist:
                    wordlist_path = Path(args.wordlist)
                    if wordlist_path.exists():
                        wordlist = wordlist_path.read_text().splitlines()
                bruteforce_steghide(repaired, wordlist, args.delay, args.parallel)
        
        elif is_archive:
            print(f"{Fore.GREEN}[ARCHIVE] Running binwalk...{Style.RESET_ALL}")
            analyze_with_binwalk(repaired)
            if args.foremost:
                analyze_foremost(repaired)
        
        elif is_executable:
            print(f"{Fore.GREEN}[BINARY] Additional binary analysis...{Style.RESET_ALL}")
        
        elif is_disk or args.disk:
            analyze_disk_image(repaired)
        
        elif is_eventlog or args.windows:
            analyze_windows_event_logs(repaired)
            parse_raw_event_log(repaired)

    # Generate detailed final report
    print_final_report(filepath.name)
    
    # Return summary data for master summary
    return {
        'flags': [item for item in flag_summary if "-FLAG" in item or "FLAG-" in item],
        'extractions': [item for item in flag_summary if "-EXTRACT" in item],
        'base64': base64_collector.copy()
    }

def print_final_report(filename: str):
    print(f"\n{Fore.YELLOW}{'='*60}")
    print(f"📋 FINAL REPORT: {filename}")
    print(f"{'='*60}{Style.RESET_ALL}")
    
    # Categorize findings
    flags_found = []
    extractions = []
    analysis_results = []
    errors_warnings = []
    
    for item in flag_summary:
        if "-FLAG" in item or "FLAG-" in item:
            flags_found.append(item)
        elif "-EXTRACT" in item or "EXTRACT-" in item:
            extractions.append(item)
        elif "-ERROR" in item or "ERROR-" in item:
            errors_warnings.append(item)
        else:
            analysis_results.append(item)
    
    # 1. FLAGS FOUND (Most Important)
    if flags_found:
        print(f"\n{Fore.GREEN}🚩 FLAGS FOUND ({len(flags_found)}):{Style.RESET_ALL}")
        print(f"{Fore.GREEN}{'-'*50}{Style.RESET_ALL}")
        for i, flag in enumerate(flags_found, 1):
            # Extract the actual flag from the summary
            match = re.search(r'\[.*?\]\s*(.+)', flag)
            if match:
                flag_content = match.group(1)
                print(f"{Fore.GREEN}  {i}. {flag_content}{Style.RESET_ALL}")
            else:
                print(f"{Fore.GREEN}  {i}. {flag}{Style.RESET_ALL}")
    
    # 2. BASE64 DECODED (if any)
    if base64_collector:
        print(f"\n{Fore.CYAN}🔓 BASE64 DECODED ({len(base64_collector)}):{Style.RESET_ALL}")
        print(f"{Fore.CYAN}{'-'*50}{Style.RESET_ALL}")
        for i, b64_item in enumerate(base64_collector[:5], 1):  # Show max 5
            print(f"  {i}. {b64_item[:100]}..." if len(b64_item) > 100 else f"  {i}. {b64_item}")
        if len(base64_collector) > 5:
            print(f"  ... and {len(base64_collector) - 5} more")
    
    # 3. EXTRACTIONS
    if extractions:
        print(f"\n{Fore.BLUE}📦 FILES EXTRACTED ({len(extractions)}):{Style.RESET_ALL}")
        print(f"{Fore.BLUE}{'-'*50}{Style.RESET_ALL}")
        for item in extractions:
            print(f"  • {item}")
    
    # 4. ANALYSIS RESULTS
    if analysis_results:
        print(f"\n{Fore.MAGENTA}🔍 ANALYSIS RESULTS ({len(analysis_results)}):{Style.RESET_ALL}")
        print(f"{Fore.MAGENTA}{'-'*50}{Style.RESET_ALL}")
        for item in analysis_results:
            print(f"  • {item}")
    
    # 5. ERRORS/WARNINGS
    if errors_warnings:
        print(f"\n{Fore.RED}⚠️  ERRORS/WARNINGS ({len(errors_warnings)}):{Style.RESET_ALL}")
        print(f"{Fore.RED}{'-'*50}{Style.RESET_ALL}")
        for item in errors_warnings:
            print(f"  • {item}")
    
    # 6. SUMMARY STATS
    print(f"\n{Fore.YELLOW}📊 SUMMARY:{Style.RESET_ALL}")
    print(f"{Fore.YELLOW}{'-'*50}{Style.RESET_ALL}")
    print(f"  Total Findings: {len(flag_summary)}")
    print(f"  Flags Found: {len(flags_found)}")
    print(f"  Files Extracted: {len(extractions)}")
    print(f"  Base64 Decoded: {len(base64_collector)}")
    if errors_warnings:
        print(f"  {Fore.RED}Errors/Warnings: {len(errors_warnings)}{Style.RESET_ALL}")
    
    if not flag_summary and not base64_collector:
        print(f"\n{Fore.YELLOW}  ⚠️  No significant findings detected.{Style.RESET_ALL}")
        print(f"  {Fore.YELLOW}💡 Try using: --all or --auto for deeper analysis{Style.RESET_ALL}")
    
    print(f"\n{Fore.YELLOW}{'='*60}{Style.RESET_ALL}")

def main():
    print(f"{Fore.CYAN}{'='*50}")
    print(f"   FORENSIC TOOLS v2.0 — AperiSolve Style")
    print(f"{'='*50}{Style.RESET_ALL}")

    check_tool_availability()

    parser = argparse.ArgumentParser(
        description="CTF Forensic Tools - AperiSolve Style Multi-Tools",
        epilog="Examples:\n  python ForesTools.py image.png\n  python ForesTools.py image.png --all\n  python ForesTools.py image.png --bruteforce --delay 7\n  python ForesTools.py disk.img --disk"
    )
    parser.add_argument("files", nargs="+", help="File(s), wildcard (*), or directory (.)")
    parser.add_argument("-f", "--format", default=None, help="Custom flag format to search (e.g., 'picoCTF{')")
    parser.add_argument("--auto", action="store_true", help="Auto-detect & run all available tools")
    parser.add_argument("--all", action="store_true", help="Run all analyses (force all tools)")
    parser.add_argument("--lsb", action="store_true", help="Full LSB analysis (zsteg)")
    parser.add_argument("--steghide", action="store_true", help="Steghide extraction")
    parser.add_argument("--outguess", action="store_true", help="Outguess extraction (JPEG)")
    parser.add_argument("--zsteg", action="store_true", help="Zsteg full analysis")
    parser.add_argument("--foremost", action="store_true", help="File carving with foremost")
    parser.add_argument("--pngcheck", action="store_true", help="PNG validation")
    parser.add_argument("--jpsteg", action="store_true", help="JPEG steganalysis (jpseek/jphs)")
    parser.add_argument("--bruteforce", action="store_true", help="Brute force steghide passwords")
    parser.add_argument("--delay", type=float, default=0.1, help="Delay between bruteforce attempts (seconds, default: 0.1 for fast mode)")
    parser.add_argument("--parallel", type=int, default=5, help="Parallel threads for bruteforce (default: 5)")
    parser.add_argument("--wordlist", type=str, help="Custom wordlist file for bruteforce")
    parser.add_argument("--remap", action="store_true", help="Color palette remapping (8 variants)")
    parser.add_argument("--alpha", action="store_true", help="Analyze alpha channel")
    parser.add_argument("--deep", action="store_true", help="Deep analysis (all bit planes 0-7)")
    parser.add_argument("--decode", action="store_true", help="Auto-detect and decode encoded data (base64, hex, binary)")
    parser.add_argument("--extract", action="store_true", help="Extract embedded files from encoded text")
    parser.add_argument("--pcap", action="store_true", help="Full PCAP network analysis with attack detection")
    parser.add_argument("--disk", action="store_true", help="Analyze disk image for flags using strings")
    parser.add_argument("--windows", action="store_true", help="Analyze Windows Event Logs for forensic evidence")
    parser.add_argument("--quick", action="store_true", help="QUICK mode: Ultra-fast CTF analysis (strings + zsteg + basic tools + early exit)")
    parser.add_argument("--exif", action="store_true", help="Deep EXIF analysis for hidden data")
    parser.add_argument("--stegdetect", action="store_true", help="Detect steganography method used")
    parser.add_argument("--compare", type=str, help="Compare two images (path to second image)")
    parser.add_argument("--lsbextract", action="store_true", help="Extract raw LSB data from image")
    args = parser.parse_args()

    # Resolve input files
    input_paths = []
    for pattern in args.files:
        path = Path(pattern)
        if path.is_file():
            input_paths.append(path.resolve())
        elif path.is_dir():
            input_paths.extend(path.rglob("*"))
        else:
            input_paths.extend(Path().glob(pattern))

    files_to_process = [f for f in input_paths if f.is_file()]
    if not files_to_process:
        print(f"{Fore.RED}[!] No valid files found.{Style.RESET_ALL}")
        return

    print(f"{Fore.CYAN}[INFO] Found {len(files_to_process)} file(s) to analyze.{Style.RESET_ALL}")

    all_flags = []
    all_extractions = []
    
    all_results = []
    
    for filepath in files_to_process:
        try:
            result = process_file(filepath, args)
            if result:
                all_results.append((filepath.name, result))
                # Collect all flags and extractions for master summary
                for flag in result['flags']:
                    all_flags.append(f"[{filepath.name}] {flag}")
                for extract in result['extractions']:
                    all_extractions.append(f"[{filepath.name}] {extract}")
        except Exception as e:
            print(f"{Fore.RED}Failed to process {filepath}: {e}{Style.RESET_ALL}")

    # Print master summary if multiple files
    if len(files_to_process) > 1:
        print(f"\n{Fore.CYAN}{'='*70}")
        print(f"📊 MASTER SUMMARY - ALL FILES ({len(files_to_process)} files processed)")
        print(f"{'='*70}{Style.RESET_ALL}")
        
        if all_flags:
            print(f"\n{Fore.GREEN}🚩 ALL FLAGS FOUND ({len(all_flags)} total):{Style.RESET_ALL}")
            for i, flag in enumerate(all_flags, 1):
                print(f"{Fore.GREEN}  {i}. {flag}{Style.RESET_ALL}")
        
        if all_extractions:
            print(f"\n{Fore.BLUE}📦 ALL EXTRACTIONS ({len(all_extractions)} total):{Style.RESET_ALL}")
            for item in all_extractions:
                print(f"  • {item}")
        
        if not all_flags and not all_extractions:
            print(f"\n{Fore.YELLOW}  ⚠️  No significant findings across all files.{Style.RESET_ALL}")
        
        print(f"\n{Fore.CYAN}{'='*70}{Style.RESET_ALL}")
    
    print(f"\n{Fore.GREEN}✅ ALL ANALYSIS COMPLETE{Style.RESET_ALL}")
    print(f"{Fore.CYAN}Check output folders for detailed results.{Style.RESET_ALL}")

if __name__ == "__main__":
    main()
