"""RAVEN stego — semua fungsi steganografi."""

import re
import subprocess
import numpy as np
from pathlib import Path
from colorama import Fore, Style

from . import core

try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False


def analyze_image(filepath, deep=False, alpha=False):
    """Analisis visual stego: bit planes + channel RGB."""
    if not HAS_PIL:
        print(f"{Fore.RED}[!] Pillow tidak terinstall.{Style.RESET_ALL}")
        return
    
    print(f"{Fore.GREEN}[IMAGE] Analisis visual stego...{Style.RESET_ALL}")
    core.log_event(len(core.event_log) + 1, "image-analysis", "running")
    
    try:
        img = Image.open(filepath)
        if img.mode == 'RGBA' or (alpha and img.mode == 'P'):
            img = img.convert("RGBA")
        elif img.mode != 'RGB':
            img = img.convert("RGB")
        
        channels = list(img.split()[:3])
        names = ["red", "green", "blue"]
        if img.mode == 'RGBA':
            channels.append(img.split()[3])
            names.append("alpha")
        
        bp_dir = filepath.parent / f"{filepath.stem}_bitplanes"
        bp_dir.mkdir(exist_ok=True)
        
        bit_range = range(8) if deep else [6, 7]
        for ch, name in zip(channels, names):
            arr = np.array(ch)
            for bit in bit_range:
                plane = ((arr >> bit) & 1) * 255
                Image.fromarray(plane.astype(np.uint8), mode="L").save(bp_dir / f"{name}_bit{bit}.png")
        
        print(f"{Fore.CYAN}[+] Bit planes → {bp_dir.name}{Style.RESET_ALL}")
        core.add_to_summary("BIT-PLANE", f"Saved to '{bp_dir.name}'")
        
        for f in bp_dir.glob("*.png"):
            out = subprocess.getoutput(f"strings '{f}'")
            core.scan_text_for_flags(out, f"BITPLANE-{f.name}")
        
        ch_dir = filepath.parent / f"{filepath.stem}_channels"
        ch_dir.mkdir(exist_ok=True)
        r, g, b = img.split()[:3]
        r.save(ch_dir / "red.png")
        g.save(ch_dir / "green.png")
        b.save(ch_dir / "blue.png")
        if img.mode == 'RGBA':
            img.split()[3].save(ch_dir / "alpha.png")
        core.add_to_summary("RGB-CHANNELS", f"Saved to '{ch_dir.name}'")
        
        core.log_event(len(core.event_log), "image-analysis", "nothing", "bit planes + channels saved")
    except Exception as e:
        print(f"{Fore.RED}[!] Image analysis gagal: {e}{Style.RESET_ALL}")
        core.log_event(len(core.event_log), "image-analysis", "error", str(e))


def extract_lsb_data(filepath):
    """Ekstrak raw LSB bytes dari gambar."""
    if not HAS_PIL:
        return
    
    print(f"{Fore.GREEN}[LSB-EXTRACT] Ekstrak raw LSB...{Style.RESET_ALL}")
    core.log_event(len(core.event_log) + 1, "lsb-extract", "running")
    
    try:
        img = Image.open(filepath)
        arr = np.array(img)
        if len(arr.shape) == 2:
            arr = arr.reshape(*arr.shape, 1)
        
        h, w, c = arr.shape
        lsb = [arr[:, :, ch].flatten() & 1 for ch in range(min(c, 4))]
        combined = np.concatenate(lsb)
        lsb_bytes = np.packbits(combined)
        
        out_dir = filepath.parent / f"{filepath.stem}_lsb_raw"
        out_dir.mkdir(exist_ok=True)
        out_file = out_dir / "lsb_raw.bin"
        out_file.write_bytes(lsb_bytes.tobytes())
        
        text = lsb_bytes.tobytes()[:1000].decode('utf-8', errors='ignore')
        if any(c.isprintable() for c in text):
            print(f"{Fore.CYAN}[+] LSB preview: {text[:100]}{Style.RESET_ALL}")
            core.collect_base64_from_text(text)
        
        raw = lsb_bytes.tobytes().decode('latin-1', errors='ignore')
        core.scan_text_for_flags(raw, "LSB")
        core.add_to_summary("LSB-EXTRACT", f"Saved to '{out_file.name}'")
        
        core.log_event(len(core.event_log), "lsb-extract", "nothing", f"saved to {out_file.name}")
    except Exception as e:
        print(f"{Fore.RED}[LSB-EXTRACT] Gagal: {e}{Style.RESET_ALL}")
        core.log_event(len(core.event_log), "lsb-extract", "error", str(e))


def compare_images(filepath1, filepath2):
    """Bandingkan dua gambar, hitung pixel berbeda."""
    if not HAS_PIL:
        return
    
    print(f"{Fore.GREEN}[IMAGE-COMPARE] Membandingkan gambar...{Style.RESET_ALL}")
    
    try:
        arr1 = np.array(Image.open(filepath1))
        arr2 = np.array(Image.open(filepath2))
        
        if arr1.shape != arr2.shape:
            s = tuple(min(a, b) for a, b in zip(arr1.shape, arr2.shape))
            arr1 = arr1[:s[0], :s[1]] if arr1.ndim == 2 else arr1[:s[0], :s[1], :s[2]]
            arr2 = arr2[:s[0], :s[1]] if arr2.ndim == 2 else arr2[:s[0], :s[1], :s[2]]
        
        diff = np.abs(arr1.astype(np.int16) - arr2.astype(np.int16))
        out_dir = filepath1.parent / f"{filepath1.stem}_compare"
        out_dir.mkdir(exist_ok=True)
        Image.fromarray(diff.astype(np.uint8)).save(out_dir / "difference.png")
        
        non_zero = int(np.sum(diff > 0))
        print(f"{Fore.CYAN}[+] Pixel berbeda: {non_zero}{Style.RESET_ALL}")
        core.add_to_summary("IMAGE-COMPARE", f"diff_pixels={non_zero}")
    except Exception as e:
        print(f"{Fore.RED}[IMAGE-COMPARE] Gagal: {e}{Style.RESET_ALL}")


def analyze_steg_methods(filepath):
    """Deteksi metode steganografi yang mungkin digunakan."""
    if not HAS_PIL:
        return
    
    print(f"{Fore.GREEN}[STEG-DETECT] Mendeteksi metode steganografi...{Style.RESET_ALL}")
    
    try:
        img = Image.open(filepath)
        pixels = np.array(img).flatten()
        ones = int(np.sum(pixels % 2 == 1))
        ratio = ones / (len(pixels) + 1)
        lsb_likely = 0.48 < ratio < 0.52
        
        print(f"{Fore.CYAN}[STEG-DETECT] LSB ratio: {ratio:.4f}{Style.RESET_ALL}")
        if lsb_likely:
            print("  ⚠  LSB hampir random → kemungkinan LSB stego")
        
        arr = np.array(img)
        zsteg_likely = False
        if arr.ndim == 3 and arr.shape[2] >= 3:
            rv, gv, bv = float(np.var(arr[:, :, 0])), float(np.var(arr[:, :, 1])), float(np.var(arr[:, :, 2]))
            if abs(rv - gv) > 1000 or abs(gv - bv) > 1000:
                zsteg_likely = True
        
        is_jpeg = filepath.suffix.lower() in ['.jpg', '.jpeg']
        core.add_to_summary("STEG-DETECT", f"LSB:{lsb_likely},Zsteg:{zsteg_likely},JPEG:{is_jpeg}")
    except Exception as e:
        print(f"{Fore.RED}[STEG-DETECT] Gagal: {e}{Style.RESET_ALL}")


def color_remapping(filepath):
    """Buat 8 variasi palette dari gambar."""
    if not HAS_PIL:
        return
    
    print(f"{Fore.GREEN}[COLOR-REMAP] Membuat 8 palette variant...{Style.RESET_ALL}")
    
    try:
        img = Image.open(filepath).convert('RGBA' if Image.open(filepath).mode == 'RGBA' else 'RGB')
        np_img = np.array(img)
        out_dir = filepath.parent / f"{filepath.stem}_remap"
        out_dir.mkdir(exist_ok=True)
        
        for i in range(8):
            np.random.seed(i * 42)
            remapped = np_img.copy()
            for c in range(min(3, remapped.shape[2])):
                ch = remapped[:, :, c]
                vals = np.unique(ch)
                if len(vals) > 1:
                    shuf = np.random.permutation(vals)
                    for orig, new in zip(vals, shuf):
                        remapped[ch == orig, c] = new
            Image.fromarray(remapped.astype(np.uint8), mode=img.mode).save(out_dir / f"variant_{i + 1}.png")
        
        core.add_to_summary("COLOR-REMAP", f"Saved to '{out_dir.name}'")
    except Exception as e:
        print(f"{Fore.RED}[COLOR-REMAP] Gagal: {e}{Style.RESET_ALL}")


def analyze_zsteg(filepath):
    """Full LSB analysis dengan zsteg."""
    if not core.AVAILABLE_TOOLS.get('zsteg'):
        core.log_tool("zsteg", "⏭ Skipped", "tidak terinstall")
        return
    
    if core.check_early_exit():
        return
    
    print(f"{Fore.GREEN}[ZSTEG] Full LSB analysis...{Style.RESET_ALL}")
    core.log_event(len(core.event_log) + 1, "zsteg", "running")
    found_before = len(core.found_flags_set)
    
    try:
        result = subprocess.run(["zsteg", "-a", str(filepath)], capture_output=True, text=True, timeout=60)
        output = result.stdout + result.stderr
        print(output[:2000] if len(output) > 2000 else output)
        
        core.collect_base64_from_text(output)
        core.scan_text_for_flags(output, "ZSTEG")
        
        new_flags = list(core.found_flags_set)[found_before:]
        if new_flags:
            core.log_event(len(core.event_log), "zsteg", "found", ", ".join(new_flags))
        else:
            core.log_event(len(core.event_log), "zsteg", "nothing", "tidak ada data tersembunyi")
    except subprocess.TimeoutExpired:
        print(f"{Fore.RED}[ZSTEG] Timeout.{Style.RESET_ALL}")
        core.log_event(len(core.event_log), "zsteg", "error", "timeout 60s")
    except Exception as e:
        print(f"{Fore.RED}[ZSTEG] Gagal: {e}{Style.RESET_ALL}")
        core.log_event(len(core.event_log), "zsteg", "error", str(e))


def analyze_steghide(filepath, password=None):
    """Ekstraksi data tersembunyi dengan steghide."""
    if not core.AVAILABLE_TOOLS.get('steghide'):
        core.log_tool("steghide", "⏭ Skipped", "tidak terinstall")
        return
    
    if core.check_early_exit():
        return
    
    print(f"{Fore.GREEN}[STEGHIDE] Mencoba ekstraksi...{Style.RESET_ALL}")
    found_before = len(core.found_flags_set)
    out_dir = filepath.parent / f"{filepath.stem}_steghide"
    out_dir.mkdir(exist_ok=True)
    out_file = out_dir / "extracted.txt"
    
    try:
        cmd = ["steghide", "extract", "-sf", str(filepath), "-xf", str(out_file), "-f"]
        if password:
            cmd += ["-p", password]
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0 and out_file.exists() and out_file.stat().st_size > 0:
            txt = out_file.read_text(errors='ignore')
            print(f"{Fore.GREEN}[STEGHIDE] Berhasil ekstrak!{Style.RESET_ALL}")
            print(txt[:500])
            core.collect_base64_from_text(txt)
            core.scan_text_for_flags(txt, "STEGHIDE")
            core.add_to_summary("STEGHIDE-EXTRACT", f"Saved to '{out_file.name}'")
            
            new_flags = list(core.found_flags_set)[found_before:]
            if new_flags:
                core.log_event(len(core.event_log) + 1, "steghide", "found", ", ".join(new_flags))
            else:
                core.log_event(len(core.event_log) + 1, "steghide", "nothing", f"data diekstrak: {out_file.name}")
        else:
            core.log_event(len(core.event_log) + 1, "steghide", "nothing", "tidak ada data tersembunyi (tanpa password)")
    except subprocess.TimeoutExpired:
        print(f"{Fore.RED}[STEGHIDE] Timeout.{Style.RESET_ALL}")
        core.log_event(len(core.event_log) + 1, "steghide", "error", "timeout 30s")
    except Exception as e:
        print(f"{Fore.RED}[STEGHIDE] Gagal: {e}{Style.RESET_ALL}")
        core.log_event(len(core.event_log) + 1, "steghide", "error", str(e))


def analyze_stegseek(filepath, wordlist=None):
    """Brute-force stegseek dengan rockyou.txt."""
    if not core.AVAILABLE_TOOLS.get('stegseek'):
        core.log_tool("stegseek", "⏭ Skipped", "tidak terinstall")
        return
    
    if core.check_early_exit():
        return
    
    wl = wordlist
    if not wl:
        for path in core.ROCKYOU_PATHS:
            if Path(path).exists():
                wl = path
                break
    
    if not wl:
        print(f"{Fore.YELLOW}[STEGSEEK] rockyou.txt tidak ditemukan.{Style.RESET_ALL}")
        return
    
    print(f"{Fore.GREEN}[STEGSEEK] Brute-force dengan: {wl}{Style.RESET_ALL}")
    core.log_event(len(core.event_log) + 1, "stegseek", "running")
    found_before = len(core.found_flags_set)
    out_dir = filepath.parent / f"{filepath.stem}_stegseek"
    out_dir.mkdir(exist_ok=True)
    out_file = out_dir / "stegseek_out"
    
    try:
        result = subprocess.run(["stegseek", str(filepath), wl, str(out_file)],
                                capture_output=True, text=True, timeout=600)
        output = result.stdout + result.stderr
        print(output[:3000] if len(output) > 3000 else output)
        
        pw_match = re.search(r'Found passphrase:\s*"([^"]*)"', output)
        if pw_match:
            pw = pw_match.group(1)
            print(f"{Fore.GREEN}[STEGSEEK] Password: \"{pw}\"{Style.RESET_ALL}")
            core.add_to_summary("STEGSEEK-PASS", f"Password: '{pw}'")
        
        core.scan_text_for_flags(output, "STEGSEEK")
        
        extracted_count = 0
        for f in out_dir.glob("*"):
            if f.is_file() and f.stat().st_size > 0:
                txt = f.read_text(errors='ignore')
                core.scan_text_for_flags(txt, "STEGSEEK-EXTRACT")
                core.collect_base64_from_text(txt)
                core.add_to_summary("STEGSEEK-EXTRACT", f"Saved to '{f.name}'")
                extracted_count += 1
        
        new_flags = list(core.found_flags_set)[found_before:]
        if new_flags:
            core.log_event(len(core.event_log), "stegseek", "found", ", ".join(new_flags))
        elif pw_match:
            core.log_event(len(core.event_log), "stegseek", "nothing", f"password='{pw_match.group(1)}', {extracted_count} file")
        else:
            core.log_event(len(core.event_log), "stegseek", "nothing", "tidak ada payload ditemukan")
    except subprocess.TimeoutExpired:
        print(f"{Fore.RED}[STEGSEEK] Timeout (600s).{Style.RESET_ALL}")
        core.log_event(len(core.event_log), "stegseek", "error", "timeout 600s")
    except Exception as e:
        print(f"{Fore.RED}[STEGSEEK] Gagal: {e}{Style.RESET_ALL}")
        core.log_event(len(core.event_log), "stegseek", "error", str(e))


def analyze_outguess(filepath):
    """Ekstraksi dengan outguess (JPEG)."""
    if not core.AVAILABLE_TOOLS.get('outguess'):
        core.log_tool("outguess", "⏭ Skipped", "tidak terinstall")
        return
    
    found_before = len(core.found_flags_set)
    print(f"{Fore.GREEN}[OUTGUESS] Ekstraksi...{Style.RESET_ALL}")
    out_dir = filepath.parent / f"{filepath.stem}_outguess"
    out_dir.mkdir(exist_ok=True)
    out_file = out_dir / "outguess.txt"
    
    try:
        result = subprocess.run(["outguess", "-r", str(filepath), str(out_file)],
                                capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0 and out_file.exists():
            txt = out_file.read_text(errors='ignore')
            core.collect_base64_from_text(txt)
            core.scan_text_for_flags(txt, "OUTGUESS")
            core.add_to_summary("OUTGUESS-EXTRACT", f"Saved to '{out_file.name}'")
            
            new_flags = list(core.found_flags_set)[found_before:]
            if new_flags:
                core.log_event(len(core.event_log) + 1, "outguess", "found", ", ".join(new_flags))
            else:
                core.log_event(len(core.event_log) + 1, "outguess", "nothing", out_file.name)
        else:
            core.log_event(len(core.event_log) + 1, "outguess", "nothing", "tidak ada payload")
    except Exception as e:
        print(f"{Fore.RED}[OUTGUESS] Gagal: {e}{Style.RESET_ALL}")
        core.log_event(len(core.event_log) + 1, "outguess", "error", str(e))


def analyze_pngcheck(filepath):
    """Validasi struktur PNG."""
    if not core.AVAILABLE_TOOLS.get('pngcheck'):
        return
    
    try:
        result = subprocess.run(["pngcheck", "-v", str(filepath)], capture_output=True, text=True, timeout=30)
        output = result.stdout + result.stderr
        core.collect_base64_from_text(output)
        
        if "error" in output.lower():
            core.add_to_summary("PNGCHECK-ERROR", "PNG bermasalah")
        else:
            core.log_event(len(core.event_log) + 1, "pngcheck", "nothing", "PNG valid")
    except Exception as e:
        print(f"{Fore.RED}[PNGCHECK] Gagal: {e}{Style.RESET_ALL}")


def analyze_jpseek(filepath):
    """JPEG steganalysis dengan jpseek/jphs."""
    tool = next((t for t in ['jpseek', 'jphs'] if core.AVAILABLE_TOOLS.get(t)), None)
    if not tool:
        return
    
    out_dir = filepath.parent / f"{filepath.stem}_jpsteg"
    out_dir.mkdir(exist_ok=True)
    
    try:
        cmd = ["jpseek", str(filepath), str(out_dir)] if tool == 'jpseek' else \
              ["jphs", "-e", str(filepath), str(out_dir / "jphs_output.txt")]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        core.collect_base64_from_text(result.stdout + result.stderr)
    except Exception as e:
        print(f"{Fore.RED}[JPSTEG] Gagal: {e}{Style.RESET_ALL}")


def analyze_exif_deep(filepath):
    """EXIF metadata mendalam dengan exiftool."""
    print(f"{Fore.GREEN}[EXIF-DEEP] EXIF metadata mendalam...{Style.RESET_ALL}")
    found_before = len(core.found_flags_set)
    
    try:
        result = subprocess.run(["exiftool", "-a", "-u", "-g1", str(filepath)],
                                capture_output=True, text=True, timeout=30)
        output = result.stdout
        print(output[:2000])
        core.collect_base64_from_text(output)
        core.scan_text_for_flags(output, "EXIF")
        
        exif_dir = filepath.parent / f"{filepath.stem}_exif"
        exif_dir.mkdir(exist_ok=True)
        (exif_dir / "full_exif.txt").write_text(output)
        core.add_to_summary("EXIF-EXTRACT", "Saved to 'full_exif.txt'")
        
        new_flags = list(core.found_flags_set)[found_before:]
        if new_flags:
            core.log_event(len(core.event_log) + 1, "exiftool", "found", ", ".join(new_flags))
        else:
            core.log_event(len(core.event_log) + 1, "exiftool", "nothing", "tidak ada flag di metadata")
    except FileNotFoundError:
        print(f"{Fore.YELLOW}[EXIF-DEEP] ExifTool tidak terinstall.{Style.RESET_ALL}")
        core.log_event(len(core.event_log) + 1, "exiftool", "skipped", "tidak terinstall")
    except Exception as e:
        print(f"{Fore.RED}[EXIF-DEEP] Gagal: {e}{Style.RESET_ALL}")
        core.log_event(len(core.event_log) + 1, "exiftool", "error", str(e))
