"""RAVEN reversing — binary analysis (strings, objdump, readelf, packer, Ghidra)."""

import os
import re
import string
import subprocess
from pathlib import Path
from colorama import Fore, Style

from . import core


def run_cmd(cmd, timeout=60):
    """Jalanin command dengan timeout."""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return result.stdout + result.stderr
    except subprocess.TimeoutExpired:
        return f"[TIMEOUT] Command exceeded {timeout}s"
    except Exception as e:
        return f"[ERROR] {e}"


def detect_packer(filepath):
    """Deteksi binary packed (UPX, MPRESS, dll)."""
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
            core.add_to_summary("PACKER-DETECT", msg)
    
    if not detected:
        print(f"{Fore.YELLOW}  No common packer detected.{Style.RESET_ALL}")
    
    return detected


def try_unpack_upx(filepath, output_dir):
    """Unpack UPX packed binary."""
    print(f"\n{Fore.CYAN}[REVERSING] Attempting UPX unpack...{Style.RESET_ALL}")
    
    output_path = out_dir / f"{filepath.stem}_unpacked"
    
    if not core.AVAILABLE_TOOLS.get("upx", False):
        result = subprocess.run("which upx", shell=True, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"{Fore.RED}  upx not installed. Install with: sudo apt install upx-ucl{Style.RESET_ALL}")
            return None
    
    cmd = f"upx -d '{filepath}' -o '{output_path}'"
    output = run_cmd(cmd, timeout=120)
    
    if output_path.exists():
        success_msg = f"Unpacked binary saved to: {output_path}"
        print(f"{Fore.GREEN}  ✓ {success_msg}{Style.RESET_ALL}")
        core.add_to_summary("UNPACK-UPX", success_msg)
        return output_path
    else:
        print(f"{Fore.RED}  ✗ UPX unpack failed.{Style.RESET_ALL}")
        return None


def strings_analysis(filepath, min_len=6):
    """Ekstrak strings dari binary."""
    print(f"\n{Fore.CYAN}[REVERSING] Extracting strings (min length: {min_len})...{Style.RESET_ALL}")
    
    output = run_cmd(f"strings -n {min_len} '{filepath}'", timeout=30)
    
    for pat in core.COMMON_FLAG_PATTERNS:
        matches = re.findall(pat, output, re.IGNORECASE)
        if matches:
            for match in matches:
                print(f"{Fore.GREEN}  ✓ FLAG in strings: {match}{Style.RESET_ALL}")
                core.add_to_summary("STRINGS-FLAG", match)
                core.signal_flag_found()
    
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
            unique_matches = list(set(matches))[:10]
            print(f"{Fore.BLUE}  {name} ({len(unique_matches)}):{Style.RESET_ALL}")
            for m in unique_matches[:5]:
                print(f"    • {m}")
            if len(unique_matches) > 5:
                print(f"    ... and {len(unique_matches) - 5} more")
    
    output_file = filepath.parent / f"{filepath.stem}_strings.txt"
    output_file.write_text(output)
    print(f"{Fore.GREEN}  ✓ Full strings saved to: {output_file}{Style.RESET_ALL}")
    
    return output


def objdump_analysis(filepath, output_dir=None):
    """Analisis binary ELF dengan objdump."""
    from pathlib import Path
    if output_dir is None:
        output_dir = filepath.parent
    else:
        output_dir = Path(output_dir)
    
    print(f"\n{Fore.CYAN}[REVERSING] Analyzing with objdump...{Style.RESET_ALL}")

    with open(filepath, 'rb') as f:
        header = f.read(4)
        if header != b'\x7fELF':
            print(f"{Fore.YELLOW}  Not an ELF file, skipping objdump.{Style.RESET_ALL}")
            return

    functions = ['main', 'start', 'entry', 'init', 'fini']
    out_dir = out_dir / f"{filepath.stem}_objdump"
    out_dir.mkdir(exist_ok=True)
    
    for func in functions:
        cmd = f"objdump -d '{filepath}' | grep -A 20 '<{func}>:'"
        output = run_cmd(cmd, timeout=30)
        
        if output and '<main>:' not in output or func != 'main':
            output_file = out_dir / f"{func}.asm"
            output_file.write_text(output)
            print(f"{Fore.GREEN}  ✓ Disassembled {func}() → {output_file}{Style.RESET_ALL}")
    
    cmd = f"objdump -t '{filepath}' | grep -E '\\.text' | awk '{{print $NF}}'"
    functions = run_cmd(cmd, timeout=30).strip().split('\n')
    functions = [f for f in functions if f and not f.startswith('.')]
    
    print(f"{Fore.BLUE}  Found {len(functions)} functions in .text section{Style.RESET_ALL}")
    
    if functions:
        func_file = out_dir / "functions.txt"
        func_file.write_text('\n'.join(functions))
        print(f"{Fore.GREEN}  ✓ Function list saved to: {func_file}{Style.RESET_ALL}")


def readelf_analysis(filepath, output_dir=None):
    """Analisis struktur ELF dengan readelf."""
    from pathlib import Path
    if output_dir is None:
        output_dir = filepath.parent
    else:
        output_dir = Path(output_dir)
    
    print(f"\n{Fore.CYAN}[REVERSING] Analyzing with readelf...{Style.RESET_ALL}")

    with open(filepath, 'rb') as f:
        header = f.read(4)
        if header != b'\x7fELF':
            print(f"{Fore.YELLOW}  Not an ELF file, skipping readelf.{Style.RESET_ALL}")
            return

    out_dir = out_dir / f"{filepath.stem}_readelf"
    out_dir.mkdir(exist_ok=True)
    
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
        
        output_file = out_dir / f"{name}.txt"
        output_file.write_text(output)
        print(f"{Fore.GREEN}  ✓ {desc} saved to: {output_file}{Style.RESET_ALL}")
        
        if name == "symbols":
            for pat in core.COMMON_FLAG_PATTERNS:
                matches = re.findall(pat, output, re.IGNORECASE)
                if matches:
                    for match in matches:
                        print(f"{Fore.GREEN}    ✓ FLAG in symbols: {match}{Style.RESET_ALL}")
                        core.add_to_summary("SYMBOL-FLAG", match)


def ghidra_analysis(filepath, output_dir):
    """Ghidra headless analysis (butuh Ghidra terinstall)."""
    print(f"\n{Fore.CYAN}[REVERSING] Ghidra headless analysis...{Style.RESET_ALL}")
    
    ghidra_path = os.environ.get("GHIDRA_INSTALL_DIR")
    if not ghidra_path:
        possible_paths = ["/opt/ghidra", "/usr/local/ghidra", "~/ghidra"]
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
    
    project_dir = out_dir / "ghidra_project"
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
    
    output = run_cmd(cmd, timeout=600)
    print(f"{Fore.GREEN}  ✓ Ghidra analysis complete. Check: {project_dir}{Style.RESET_ALL}")


def xor_analysis_on_binary(filepath, output_dir):
    """Analisis XOR-obfuscated strings dan flags di binary."""
    print(f"\n{Fore.CYAN}[REVERSING] Analyzing XOR-obfuscated data...{Style.RESET_ALL}")
    
    try:
        data = filepath.read_bytes()
    except:
        print(f"  {Fore.RED}✗ Cannot read binary file{Style.RESET_ALL}")
        return None
    
    results = []
    flags_found = []
    
    print(f"  {Fore.YELLOW}[XOR] Single-byte XOR brute force (256 keys)...{Style.RESET_ALL}")
    
    chunk_size = 4096
    step_size = 1024
    
    for key in range(1, 256):
        for offset in range(0, max(1, len(data) - chunk_size), step_size):
            chunk = data[offset:offset + chunk_size]
            decrypted = bytes(b ^ key for b in chunk)
            
            for pattern in core.COMMON_FLAG_PATTERNS:
                matches = re.findall(pattern.encode(), decrypted, re.IGNORECASE)
                if matches:
                    for match in matches:
                        try:
                            flag_str = match.decode('utf-8')
                            if flag_str not in flags_found:
                                flags_found.append(flag_str)
                                print(f"  {Fore.GREEN}✓ FLAG found (XOR key=0x{key:02x}): {flag_str}{Style.RESET_ALL}")
                                core.add_to_summary("XOR-FLAG", f"key=0x{key:02x}: {flag_str}")
                                core.signal_flag_found()
                                return flags_found
                        except:
                            pass
        
        if key % 50 == 0 and not core.check_early_exit():
            print(f"  {Fore.BLUE}[XOR] Scanned {key}/255 keys...{Style.RESET_ALL}")
    
    print(f"\n  {Fore.YELLOW}[XOR] Multi-byte XOR analysis (key lengths 2-8)...{Style.RESET_ALL}")
    
    known_prefix = b'CTF{'
    for key_len in range(2, 9):
        for offset in range(0, min(len(data) - key_len, 1000)):
            potential_key = bytes(data[offset + i] ^ known_prefix[i] for i in range(len(known_prefix)))
            
            try:
                key_str = potential_key.decode('ascii')
                if all(c in string.printable for c in key_str):
                    start = max(0, offset - 20)
                    end = min(len(data), offset + 100)
                    decrypted_segment = bytes(data[i] ^ potential_key[(i - offset) % key_len] for i in range(start, end))
                    
                    for pattern in core.COMMON_FLAG_PATTERNS:
                        matches = re.findall(pattern.encode(), decrypted_segment, re.IGNORECASE)
                        if matches:
                            for match in matches:
                                try:
                                    flag_str = match.decode('utf-8')
                                    if flag_str not in flags_found:
                                        flags_found.append(flag_str)
                                        print(f"  {Fore.GREEN}✓ FLAG found (XOR key={potential_key.hex()}): {flag_str}{Style.RESET_ALL}")
                                        core.add_to_summary("XOR-FLAG", f"key={potential_key.hex()}: {flag_str}")
                                        core.signal_flag_found()
                                        return flags_found
                                except:
                                    pass
            except:
                pass
    
    if flags_found:
        print(f"\n{Fore.GREEN}{'=' * 50}")
        print(f"  🚩 XOR FLAGS FOUND: {len(flags_found)}")
        for f in flags_found:
            print(f"  {f}")
        print(f"{'=' * 50}{Style.RESET_ALL}")
        return flags_found
    
    print(f"  {Fore.YELLOW}✗ No XOR-obfuscated flags detected{Style.RESET_ALL}")
    return None


def reversing_pipeline(filepath, args):
    """Full reversing pipeline untuk binary analysis."""
    from pathlib import Path
    from . import core
    
    output_base = getattr(args, 'output_dir', filepath.parent)
    output_dir = Path(output_base) / f"{filepath.stem}_reversing"
    output_dir.mkdir(exist_ok=True)
    
    print(f"\n{Fore.MAGENTA}{'=' * 60}")
    print(f"REVERSING ANALYSIS: {filepath.name}")
    print(f"{'=' * 60}{Style.RESET_ALL}")

    packers = detect_packer(filepath)
    
    unpacked = filepath
    if "UPX" in packers and getattr(args, 'unpack', False):
        unpacked_path = try_unpack_upx(filepath, output_dir)
        if unpacked_path:
            unpacked = unpacked_path
    
    strings_output = strings_analysis(unpacked)

    xor_results = xor_analysis_on_binary(unpacked, output_dir)

    if not getattr(args, 'skip_objdump', False):
        objdump_analysis(unpacked, output_dir=output_base)

    if not getattr(args, 'skip_readelf', False):
        readelf_analysis(unpacked, output_dir=output_base)

    if getattr(args, 'ghidra', False):
        ghidra_analysis(unpacked, output_dir)
    
    core.add_to_summary("REVERSING-DONE", f"Output: '{output_dir.name}'")
    print(f"\n{Fore.GREEN}[REVERSING] Analysis complete. Check: {output_dir}{Style.RESET_ALL}")


def analyze_file(filepath, args):
    """Alias untuk reversing_pipeline."""
    reversing_pipeline(filepath, args)
