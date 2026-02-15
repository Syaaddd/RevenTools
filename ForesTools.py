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

try:
    from PIL import Image
    import numpy as np
    HAS_PIL = True
except ImportError:
    HAS_PIL = False

init(autoreset=True)

AVAILABLE_TOOLS = {}

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
    global flag_summary, base64_collector
    flag_summary = []
    base64_collector = []

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

def analyze_foremost(filepath: Path):
    if not AVAILABLE_TOOLS.get('foremost', False):
        print(f"{Fore.YELLOW}[FOREMOST] Not installed. Skipping.{Style.RESET_ALL}")
        return
    
    print(f"{Fore.GREEN}[FOREMOST] Running file carving...{Style.RESET_ALL}")
    output_dir = filepath.parent / f"{filepath.stem}_foremost"
    
    try:
        subprocess.run(
            ["foremost", "-i", str(filepath), "-o", str(output_dir), "-v"],
            capture_output=True, timeout=60
        )
        if output_dir.exists():
            files_found = list(output_dir.rglob("*"))
            if files_found:
                print(f"{Fore.GREEN}[FOREMOST] Found {len(files_found)} file(s){Style.RESET_ALL}")
                for f in files_found[:10]:
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

def bruteforce_steghide(filepath: Path, wordlist: list = None, delay: float = 5.0):
    if not AVAILABLE_TOOLS.get('steghide', False):
        print(f"{Fore.YELLOW}[BRUTEFORCE] Steghide not installed. Skipping.{Style.RESET_ALL}")
        return
    
    if wordlist is None:
        wordlist = DEFAULT_WORDLIST
    
    print(f"{Fore.GREEN}[BRUTEFORCE] Starting brute force with {len(wordlist)} passwords...{Style.RESET_ALL}")
    print(f"{Fore.YELLOW}[BRUTEFORCE] Delay: {delay} seconds between attempts{Style.RESET_ALL}")
    
    output_dir = filepath.parent / f"{filepath.stem}_bruteforce"
    output_dir.mkdir(exist_ok=True)
    
    found = False
    for i, password in enumerate(wordlist):
        print(f"[{i+1}/{len(wordlist)}] Trying: {password}...", end=" ")
        
        try:
            output_file = output_dir / f"out_{password}.txt"
            result = subprocess.run(
                ["steghide", "extract", "-sf", str(filepath), "-xf", str(output_file), "-f", "-p", password],
                capture_output=True, text=True, timeout=30
            )
            
            if result.returncode == 0 and output_file.exists() and output_file.stat().st_size > 0:
                print(f"{Fore.GREEN}SUCCESS!{Style.RESET_ALL}")
                content = output_file.read_text(errors='ignore')
                print(f"{Fore.CYAN}Content: {content[:200]}{Style.RESET_ALL}")
                collect_base64_from_text(content)
                for pattern in COMMON_FLAG_PATTERNS:
                    matches = re.findall(pattern, content, re.IGNORECASE)
                    for match in matches:
                        add_to_summary("BRUTEFORCE-FLAG", f"Password: '{password}' → {match}")
                found = True
                break
            else:
                print(f"{Fore.RED}failed{Style.RESET_ALL}")
        
        except Exception as e:
            print(f"{Fore.RED}error: {e}{Style.RESET_ALL}")
        
        if delay > 0 and i < len(wordlist) - 1:
            time.sleep(delay)
    
    if not found:
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
                analyze_foremost(repaired)
            if args.auto:
                analyze_with_binwalk(repaired)
        
        if args.bruteforce and is_image:
            wordlist = DEFAULT_WORDLIST
            if args.wordlist:
                wordlist_path = Path(args.wordlist)
                if wordlist_path.exists():
                    wordlist = wordlist_path.read_text().splitlines()
            bruteforce_steghide(repaired, wordlist, args.delay)
        
        if is_disk or args.disk:
            analyze_disk_image(repaired)
    
    else:
        if is_image:
            analyze_image(repaired, deep=args.deep, alpha=args.alpha)
            
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
                bruteforce_steghide(repaired, wordlist, args.delay)
        
        elif is_archive:
            print(f"{Fore.GREEN}[ARCHIVE] Running binwalk...{Style.RESET_ALL}")
            analyze_with_binwalk(repaired)
            if args.foremost:
                analyze_foremost(repaired)
        
        elif is_executable:
            print(f"{Fore.GREEN}[BINARY] Additional binary analysis...{Style.RESET_ALL}")
        
        elif is_disk or args.disk:
            analyze_disk_image(repaired)

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
    parser.add_argument("--delay", type=float, default=5.0, help="Delay between bruteforce attempts (seconds)")
    parser.add_argument("--wordlist", type=str, help="Custom wordlist file for bruteforce")
    parser.add_argument("--remap", action="store_true", help="Color palette remapping (8 variants)")
    parser.add_argument("--alpha", action="store_true", help="Analyze alpha channel")
    parser.add_argument("--deep", action="store_true", help="Deep analysis (all bit planes 0-7)")
    parser.add_argument("--decode", action="store_true", help="Auto-detect and decode encoded data (base64, hex, binary)")
    parser.add_argument("--extract", action="store_true", help="Extract embedded files from encoded text")
    parser.add_argument("--pcap", action="store_true", help="Full PCAP network analysis")
    parser.add_argument("--disk", action="store_true", help="Analyze disk image for flags using strings")
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
