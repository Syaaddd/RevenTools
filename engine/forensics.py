"""RAVEN forensics — disk, memory, pcap, registry, log analysis."""

import re
import subprocess
import gzip
import zipfile
from pathlib import Path
from colorama import Fore, Style
from concurrent.futures import ThreadPoolExecutor, as_completed

from . import core


def analyze_registry(filepath):
    """Baca .reg, decode nilai hex:, cari flag tersembunyi."""
    print(f"{Fore.GREEN}[REGISTRY] Analisis Windows Registry file...{Style.RESET_ALL}")
    out_dir = filepath.parent / f"{filepath.stem}_registry"
    out_dir.mkdir(exist_ok=True)
    
    try:
        content = filepath.read_text(encoding='utf-16', errors='ignore')
    except:
        try:
            content = filepath.read_text(encoding='utf-8', errors='ignore')
        except:
            content = filepath.read_bytes().decode('latin-1', errors='ignore')
    
    print(f"{Fore.CYAN}[REGISTRY] {len(content)} karakter dibaca{Style.RESET_ALL}")
    core.scan_text_for_flags(content, "REGISTRY")
    
    hex_pattern = r'"([^"]+)"\s*=\s*hex:([0-9a-fA-F,\\\s\r\n]+)'
    hex_matches = re.findall(hex_pattern, content, re.MULTILINE)
    
    print(f"{Fore.CYAN}[REGISTRY] {len(hex_matches)} nilai hex ditemukan{Style.RESET_ALL}")
    for name, hex_data in hex_matches:
        clean = re.sub(r'[^0-9a-fA-F]', '', hex_data)
        if len(clean) % 2 == 0:
            try:
                decoded_bytes = bytes.fromhex(clean)
                decoded = ""
                encoding_used = ""
                
                try:
                    decoded = decoded_bytes.decode('utf-8', errors='ignore').strip('\x00')
                    if decoded.strip() and all(32 <= ord(c) <= 126 or c in '\n\r\t' for c in decoded if c.isprintable() or c in '\n\r\t'):
                        encoding_used = "ASCII/UTF-8"
                except:
                    pass
                
                if not decoded.strip():
                    try:
                        decoded = decoded_bytes.decode('utf-16-le', errors='ignore').strip('\x00')
                        if decoded.strip():
                            encoding_used = "UTF-16LE"
                    except:
                        pass
                
                if not decoded.strip():
                    try:
                        decoded = decoded_bytes.decode('utf-16-be', errors='ignore').strip('\x00')
                        if decoded.strip():
                            encoding_used = "UTF-16BE"
                    except:
                        pass
                
                if not decoded.strip():
                    try:
                        decoded = decoded_bytes.decode('latin-1', errors='ignore')
                        if decoded.strip():
                            encoding_used = "Latin-1"
                    except:
                        pass
                
                if decoded.strip():
                    print(f"{Fore.CYAN}  [{name}] hex → \"{decoded}\" ({encoding_used}){Style.RESET_ALL}")
                    core.scan_text_for_flags(decoded, "REGISTRY-HEX")
                    core.collect_base64_from_text(decoded)
                    (out_dir / f"hex_{name.replace(' ','_')}.txt").write_text(
                        f"Name: {name}\nHex: {clean}\nEncoding: {encoding_used}\nDecoded: {decoded}\n")
                    
                    for pat in core.COMMON_FLAG_PATTERNS:
                        if re.search(pat, decoded, re.IGNORECASE):
                            print(f"{Fore.GREEN}  🚩 FLAG tersembunyi di registry hex!{Style.RESET_ALL}")
                            break
            except Exception as e:
                print(f"{Fore.YELLOW}  [{name}] decode gagal: {e}{Style.RESET_ALL}")
    
    suspicious_keys = ["RunOnce", "Run", "RunServices", "RunServicesOnce",
                       "UserInit", "Shell", "Userinit", "Load", "Policies"]
    for key in suspicious_keys:
        if key.lower() in content.lower():
            idx = content.lower().find(key.lower())
            snippet = content[max(0, idx-20):idx+200]
            print(f"{Fore.YELLOW}[REGISTRY] Key mencurigakan '{key}':{Style.RESET_ALL}")
            print(f"  {snippet[:200]}")
            core.scan_text_for_flags(snippet, f"REGISTRY-KEY-{key}")
    
    for vtype in ['dword', 'qword']:
        for m in re.findall(rf'"([^"]+)"\s*=\s*{vtype}:([0-9a-fA-F]+)', content, re.IGNORECASE):
            name, val = m
            print(f"{Fore.CYAN}  [{name}] {vtype} = 0x{val} ({int(val,16)}){Style.RESET_ALL}")
    
    string_vals = re.findall(r'"[^"]+"\s*=\s*"([^"]+)"', content)
    for val in string_vals:
        if len(val) > 6:
            from . import core as core_module
            core_module.analyze_deobfuscation(val, "REGISTRY-STRING") if hasattr(core_module, 'analyze_deobfuscation') else None
    
    new_flags = list(core.found_flags_set)
    core.log_tool("registry-parser", "✅ Found" if new_flags else "⬜ Nothing",
                  ", ".join(new_flags) if new_flags else f"parsed {filepath.name}")
    core.add_to_summary("REGISTRY-ANALYZED", f"Parsed '{filepath.name}'")
    print(f"{Fore.GREEN}[REGISTRY] Selesai. Output: {out_dir.name}{Style.RESET_ALL}")


def analyze_log(filepath):
    """Analisis web server log — IP freq, attack pattern, flag di URL."""
    print(f"{Fore.GREEN}[LOG] Analisis web server log...{Style.RESET_ALL}")
    out_dir = filepath.parent / f"{filepath.stem}_log_analysis"
    out_dir.mkdir(exist_ok=True)
    
    try:
        content = filepath.read_text(encoding='utf-8', errors='ignore')
    except:
        content = filepath.read_bytes().decode('latin-1', errors='ignore')
    
    lines = [l for l in content.splitlines() if l.strip()]
    print(f"{Fore.CYAN}[LOG] {len(lines)} baris ditemukan{Style.RESET_ALL}")
    
    flags_found = core.scan_text_for_flags(content, "LOG")
    core.collect_base64_from_text(content)
    
    ip_counts = {}
    ip_pat = re.compile(r'^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})')
    for line in lines:
        m = ip_pat.match(line)
        if m:
            ip = m.group(1)
            ip_counts[ip] = ip_counts.get(ip, 0) + 1
    
    if ip_counts:
        sorted_ips = sorted(ip_counts.items(), key=lambda x: x[1], reverse=True)
        print(f"\n{Fore.CYAN}[LOG] Top IP Addresses:{Style.RESET_ALL}")
        for ip, cnt in sorted_ips[:10]:
            marker = f" {Fore.RED}← MENCURIGAKAN!{Style.RESET_ALL}" if cnt >= 5 and cnt == sorted_ips[0][1] and len(sorted_ips) > 1 else ""
            print(f"  {cnt:>6}x  {ip}{marker}")
        core.add_to_summary("LOG-IP-FREQ", f"Top IP: {sorted_ips[0][0]} ({sorted_ips[0][1]} hits)")
    
    print(f"\n{Fore.CYAN}[LOG] Deteksi attack patterns...{Style.RESET_ALL}")
    attack_sigs = {
        'Path Traversal': r'(\.\./|%2e%2e%2f|\.\.%2f|%2e%2e/)',
        'SQL Injection': r'(\bunion\b|\bselect\b|\binsert\b|\bdrop\b|%27|\'|1=1)',
        'XSS': r'(<script|javascript:|onerror=|onload=|alert\()',
        'LFI/RFI': r'(etc/passwd|etc/shadow|win\.ini|/proc/self)',
        'Command Injection': r'(;|\||&&|\$\(|`)\s*(cat|ls|pwd|whoami|id|wget|curl)',
        'Scanner/Recon': r'(nikto|nmap|sqlmap|dirb|gobuster|masscan|wfuzz)',
        'Webshell': r'(cmd=|exec=|system=|passthru=|shell\.php|webshell)',
    }
    
    attacker_ips = {}
    for line in lines:
        for attack_name, pattern in attack_sigs.items():
            if re.search(pattern, line, re.IGNORECASE):
                m = ip_pat.match(line)
                if m:
                    ip = m.group(1)
                    if ip not in attacker_ips:
                        attacker_ips[ip] = set()
                    attacker_ips[ip].add(attack_name)
    
    for attack, pat in attack_sigs.items():
        matches = re.findall(pat, content, re.IGNORECASE)
        if matches:
            print(f"  {Fore.RED}[!] {attack}: {len(matches)} hit(s){Style.RESET_ALL}")
            core.add_to_summary("LOG-ATTACK", f"{attack}: {len(matches)} hits")
    
    suspicious_ips = []
    if attacker_ips:
        print(f"\n{Fore.RED}[LOG] IP MENCURIGAKAN (melakukan attack):{Style.RESET_ALL}")
        for ip, attacks in attacker_ips.items():
            print(f"  {Fore.RED}🎯 {ip} — Attacks: {', '.join(attacks)}{Style.RESET_ALL}")
            suspicious_ips.append(ip)
            core.add_to_summary("LOG-SUSPICIOUS-IP", f"{ip} ({', '.join(attacks)})")
    
    if not suspicious_ips and ip_counts:
        suspicious_ips = [sorted_ips[0][0]]
        print(f"\n{Fore.YELLOW}[LOG] Tidak ada attack pattern terdeteksi. Menganalisis IP teratas: {suspicious_ips[0]}{Style.RESET_ALL}")
    
    for attacker_ip in suspicious_ips:
        attacker_lines = [l for l in lines if l.startswith(attacker_ip)]
        print(f"\n{Fore.YELLOW}{'=' * 60}{Style.RESET_ALL}")
        print(f"{Fore.YELLOW}[LOG] TIMELINE SERANGAN — IP: {attacker_ip}{Style.RESET_ALL}")
        print(f"{Fore.YELLOW}[LOG] Total requests: {len(attacker_lines)}{Style.RESET_ALL}")
        print(f"{Fore.YELLOW}{'=' * 60}{Style.RESET_ALL}")
        
        (out_dir / f"attacker_{attacker_ip.replace('.', '_')}_all.txt").write_text('\n'.join(attacker_lines))
        
        url_pattern = re.compile(r'"(GET|POST|PUT|DELETE|HEAD|OPTIONS|PATCH)\s+(\S+)\s+HTTP')
        status_pattern = re.compile(r'HTTP/\d\.\d"\s+(\d{3})\s+(\d+)')
        time_pattern = re.compile(r'\[(\d{2}/\w+/\d{4}:\d{2}:\d{2}:\d{2})')
        
        print(f"\n{Fore.CYAN}[LOG] Timeline aktivitas penyerang:{Style.RESET_ALL}")
        print(f"{'Waktu':<22} {'Method':<10} {'URL Path':<50} {'Status':<8} {'Keterangan'}")
        print(f"{'─' * 22} {'─' * 10} {'─' * 50} {'─' * 8} {'─' * 30}")
        
        timeline_data = []
        for line in attacker_lines:
            time_match = time_pattern.search(line)
            timestamp = time_match.group(1) if time_match else "?"
            
            url_match = url_pattern.search(line)
            if url_match:
                method = url_match.group(1)
                url_path = url_match.group(2)
            else:
                method = "?"
                url_path = "?"
            
            status_match = status_pattern.search(line)
            status = status_match.group(1) if status_match else "?"
            size = status_match.group(2) if status_match else "?"
            
            description = ""
            if status == "200":
                description = f"{Fore.GREEN}✓ BERHASIL{Style.RESET_ALL}"
            elif status in ["400", "403"]:
                description = f"{Fore.RED}✗ Ditolak{Style.RESET_ALL}"
            elif status == "404":
                description = f"{Fore.YELLOW}✗ Not Found{Style.RESET_ALL}"
            
            for pat in core.COMMON_FLAG_PATTERNS:
                flag_matches = re.findall(pat, url_path, re.IGNORECASE)
                if flag_matches:
                    for flag in flag_matches:
                        flag_clean = flag.strip().replace('[', '{').replace(']', '}')
                        if 'CTF{' in flag_clean or 'FLAG{' in flag_clean.upper():
                            print(f"\n{Fore.GREEN}{'=' * 60}{Style.RESET_ALL}")
                            print(f"{Fore.GREEN}🚩 FLAG DITEMUKAN di URL!{Style.RESET_ALL}")
                            print(f"{Fore.GREEN}   {flag_clean}{Style.RESET_ALL}")
                            print(f"{Fore.GREEN}{'=' * 60}{Style.RESET_ALL}")
                            core.add_to_summary("LOG-FLAG-IN-URL", flag_clean)
                            core.signal_flag_found()
            
            timeline_data.append({
                'timestamp': timestamp,
                'method': method,
                'url': url_path,
                'status': status,
                'description': description,
                'line': line
            })
        
        timeline_data.sort(key=lambda x: x['timestamp'])
        for entry in timeline_data:
            url_display = entry['url'][:48] + '...' if len(entry['url']) > 50 else entry['url']
            print(f"{entry['timestamp']:<22} {entry['method']:<10} {url_display:<50} {entry['status']:<8} {entry['description']}")
        
        ok_requests = [l for l in attacker_lines if '" 200 ' in l]
        if ok_requests:
            print(f"\n{Fore.GREEN}[LOG] ✓ Requests yang BERHASIL (200 OK) dari penyerang: {len(ok_requests)}{Style.RESET_ALL}")
            for line in ok_requests:
                print(f"  → {line}")
                core.scan_text_for_flags(line, "LOG-ATTACKER-200")
            (out_dir / f"attacker_{attacker_ip.replace('.', '_')}_success.txt").write_text('\n'.join(ok_requests))
    
    status_counts = {}
    status_pat = re.compile(r'" (\d{3}) ')
    for line in lines:
        m = status_pat.search(line)
        if m:
            s = m.group(1)
            status_counts[s] = status_counts.get(s, 0) + 1
    
    if status_counts:
        print(f"\n{Fore.CYAN}[LOG] HTTP Status Distribution (Global):{Style.RESET_ALL}")
        for code, cnt in sorted(status_counts.items()):
            color = Fore.GREEN if code.startswith('2') else Fore.YELLOW if code.startswith('3') else Fore.RED
            print(f"  {color}{code}: {cnt} requests{Style.RESET_ALL}")
    
    time_pat = re.compile(r'\[(\d{2}/\w+/\d{4}:\d{2}:\d{2}:\d{2})')
    timestamps = [time_pat.search(l).group(1) for l in lines if time_pat.search(l)]
    if timestamps:
        print(f"\n{Fore.CYAN}[LOG] Timeline Global: {timestamps[0]} → {timestamps[-1]}{Style.RESET_ALL}")
        core.add_to_summary("LOG-TIMELINE", f"{timestamps[0]} → {timestamps[-1]}")
    
    (out_dir / "full_analysis.txt").write_text(
        f"Log Analysis: {filepath.name}\n"
        f"Total lines: {len(lines)}\n"
        f"IPs: {len(ip_counts)}\n"
        f"Suspicious IPs: {len(suspicious_ips)}\n"
        f"Flags: {flags_found}\n")
    
    new_flags = list(core.found_flags_set)
    core.log_tool("log-analyzer", "✅ Found" if new_flags else "⬜ Nothing",
                  ", ".join(new_flags) if new_flags else f"{len(lines)} lines analyzed, no flag")
    core.add_to_summary("LOG-ANALYZED", f"Parsed '{filepath.name}' ({len(lines)} lines)")
    print(f"{Fore.GREEN}[LOG] Selesai. Output: {out_dir.name}{Style.RESET_ALL}")


def analyze_autorun(filepath):
    """Parse .inf / autorun.inf, deteksi reverse string & encoding di komentar."""
    print(f"{Fore.GREEN}[AUTORUN] Analisis autorun/INF file...{Style.RESET_ALL}")
    out_dir = filepath.parent / f"{filepath.stem}_autorun"
    out_dir.mkdir(exist_ok=True)
    
    try:
        content = filepath.read_text(encoding='utf-8', errors='ignore')
    except:
        content = filepath.read_bytes().decode('latin-1', errors='ignore')
    
    print(f"{Fore.CYAN}[AUTORUN] Isi file:{Style.RESET_ALL}")
    print(content)
    core.scan_text_for_flags(content, "AUTORUN")
    
    comments = [l.strip() for l in content.splitlines()
                if l.strip().startswith(';') or l.strip().startswith('#')]
    if comments:
        print(f"\n{Fore.CYAN}[AUTORUN] {len(comments)} komentar ditemukan:{Style.RESET_ALL}")
        for comment in comments:
            print(f"  {Fore.YELLOW}{comment}{Style.RESET_ALL}")
            clean = comment.lstrip(';#').strip()
            core.scan_text_for_flags(clean, "AUTORUN-COMMENT")
            
            if len(clean) > 6:
                results = core.deobfuscate_string(clean)
                rev = results.get('reverse', '')
                print(f"    Reverse: {rev}")
                core.scan_text_for_flags(rev, "AUTORUN-REVERSE")
                
                rot = results.get('rot13', '')
                for pat in core.COMMON_FLAG_PATTERNS:
                    if re.search(pat, rot, re.IGNORECASE):
                        print(f"{Fore.GREEN}    ROT13: {rot}{Style.RESET_ALL}")
                        core.scan_text_for_flags(rot, "AUTORUN-ROT13")
                
                b64 = results.get('base64')
                if b64:
                    print(f"    Base64: {b64}")
                    core.scan_text_for_flags(b64, "AUTORUN-B64")
    
    for m in re.findall(r'^[^;#\[].+=(.+)$', content, re.MULTILINE):
        val = m.strip()
        if len(val) > 4:
            core.scan_text_for_flags(val, "AUTORUN-VALUE")
    
    for m in re.findall(r'[0-9a-f]{32,}', content, re.IGNORECASE):
        print(f"{Fore.CYAN}[AUTORUN] Hash/checksum: {m}{Style.RESET_ALL}")
        core.add_to_summary("AUTORUN-HASH", m)
    
    new_flags = list(core.found_flags_set)
    core.log_tool("autorun-parser", "✅ Found" if new_flags else "⬜ Nothing",
                  ", ".join(new_flags) if new_flags else "tidak ada flag/encoding tersembunyi")
    core.add_to_summary("AUTORUN-ANALYZED", f"Parsed '{filepath.name}'")
    print(f"{Fore.GREEN}[AUTORUN] Selesai.{Style.RESET_ALL}")


def crack_zip(filepath, wordlist_path=None):
    """Coba buka ZIP: tanpa password → wordlist → fcrackzip."""
    print(f"{Fore.GREEN}[ZIP-CRACK] Analisis ZIP terproteksi...{Style.RESET_ALL}")
    out_dir = filepath.parent / f"{filepath.stem}_zipcrack"
    out_dir.mkdir(exist_ok=True)
    
    print(f"{Fore.CYAN}[ZIP-CRACK] Step 1: Coba ekstrak tanpa password...{Style.RESET_ALL}")
    result = subprocess.run(
        ["unzip", "-o", str(filepath), "-d", str(out_dir)],
        capture_output=True, text=True, timeout=30)
    if result.returncode == 0:
        print(f"{Fore.GREEN}[ZIP-CRACK] Berhasil ekstrak tanpa password!{Style.RESET_ALL}")
        _scan_extracted_dir(out_dir, "ZIP-NOPASS")
        return
    
    result2 = subprocess.run(
        ["unzip", "-o", "-P", "", str(filepath), "-d", str(out_dir)],
        capture_output=True, text=True, timeout=15)
    if result2.returncode == 0:
        print(f"{Fore.GREEN}[ZIP-CRACK] Berhasil dengan password kosong!{Style.RESET_ALL}")
        _scan_extracted_dir(out_dir, "ZIP-EMPTYPASS")
        return
    
    wl_lines = core.DEFAULT_WORDLIST[:]
    if wordlist_path and Path(wordlist_path).exists():
        wl_lines = Path(wordlist_path).read_text(errors='ignore').splitlines()[:50000]
        print(f"{Fore.CYAN}[ZIP-CRACK] Wordlist custom: {len(wl_lines)} kata{Style.RESET_ALL}")
    else:
        for rp in core.ROCKYOU_PATHS:
            if Path(rp).exists():
                wl_lines = open(rp, errors='ignore').read().splitlines()[:100000]
                print(f"{Fore.CYAN}[ZIP-CRACK] Rockyou: {len(wl_lines)} kata{Style.RESET_ALL}")
                break
    
    if core.AVAILABLE_TOOLS.get('fcrackzip') and wordlist_path:
        print(f"{Fore.CYAN}[ZIP-CRACK] fcrackzip dengan wordlist...{Style.RESET_ALL}")
        try:
            wl = wordlist_path or next((p for p in core.ROCKYOU_PATHS if Path(p).exists()), None)
            if wl:
                result3 = subprocess.run(
                    ["fcrackzip", "-v", "-u", "-D", "-p", wl, str(filepath)],
                    capture_output=True, text=True, timeout=120)
                output = result3.stdout + result3.stderr
                pw_match = re.search(r'PASSWORD FOUND.*?:(.*)', output, re.IGNORECASE)
                if pw_match:
                    pw = pw_match.group(1).strip().strip("'\"")
                    print(f"{Fore.GREEN}[ZIP-CRACK] Password: '{pw}'{Style.RESET_ALL}")
                    core.add_to_summary("ZIP-PASSWORD", f"Password: '{pw}'")
                    subprocess.run(["unzip", "-o", "-P", pw, str(filepath), "-d", str(out_dir)],
                                   capture_output=True, timeout=30)
                    _scan_extracted_dir(out_dir, "ZIP-CRACK")
                    return
        except Exception as e:
            print(f"{Fore.YELLOW}[ZIP-CRACK] fcrackzip gagal: {e}{Style.RESET_ALL}")
    
    print(f"{Fore.CYAN}[ZIP-CRACK] Manual brute-force: {len(wl_lines)} kata...{Style.RESET_ALL}")
    found_pw = None
    
    def try_zip_pw(pw):
        try:
            r = subprocess.run(
                ["unzip", "-o", "-P", pw, str(filepath), "-d", str(out_dir)],
                capture_output=True, text=True, timeout=10)
            if r.returncode == 0:
                return pw
        except:
            pass
        return None
    
    with ThreadPoolExecutor(max_workers=8) as ex:
        futures = {ex.submit(try_zip_pw, pw): pw for pw in wl_lines[:5000]}
        for future in as_completed(futures):
            if found_pw:
                break
            res = future.result()
            if res:
                found_pw = res
                print(f"{Fore.GREEN}[ZIP-CRACK] Password ditemukan: '{found_pw}'{Style.RESET_ALL}")
                core.add_to_summary("ZIP-PASSWORD", f"Password: '{found_pw}'")
                _scan_extracted_dir(out_dir, "ZIP-CRACK")
                break
    
    if not found_pw:
        print(f"{Fore.YELLOW}[ZIP-CRACK] Password tidak ditemukan dalam wordlist.{Style.RESET_ALL}")
        core.log_tool("zipcrack", "⬜ Nothing", "password tidak ditemukan dalam wordlist")


def _scan_extracted_dir(out_dir, source):
    """Scan semua file yang diekstrak untuk flag."""
    for f in Path(out_dir).rglob("*"):
        if f.is_file():
            print(f"{Fore.CYAN}[EXTRACTED] {f.name}{Style.RESET_ALL}")
            try:
                txt = f.read_text(errors='ignore')
                core.scan_text_for_flags(txt, source)
                core.collect_base64_from_text(txt)
            except:
                try:
                    raw = f.read_bytes()
                    txt = raw.decode('latin-1', errors='ignore')
                    core.scan_text_for_flags(txt, source)
                except:
                    pass
            sr = subprocess.getoutput(f"strings '{f}'")
            core.scan_text_for_flags(sr, f"{source}-STRINGS")


def analyze_pcap_basic(filepath):
    """Basic PCAP analysis dengan capinfos."""
    if not core.AVAILABLE_TOOLS.get('capinfos'):
        return
    
    try:
        result = subprocess.run(["capinfos", str(filepath)], capture_output=True, text=True, timeout=30)
        print(f"{Fore.CYAN}{result.stdout}{Style.RESET_ALL}")
        (filepath.parent / f"{filepath.stem}_pcap_info.txt").write_text(result.stdout)
        core.collect_base64_from_text(result.stdout)
    except Exception as e:
        print(f"{Fore.RED}[PCAP] Gagal: {e}{Style.RESET_ALL}")


def analyze_pcap_full(filepath):
    """Full PCAP analysis pipeline."""
    print(f"\n{Fore.BLUE}{'=' * 60}\nPCAP FULL: {filepath.name}\n{'=' * 60}{Style.RESET_ALL}")
    
    analyze_pcap_basic(filepath)
    if core.check_early_exit():
        return
    
    from . import pcap
    if hasattr(pcap, 'extract_http_objects'):
        pcap.extract_http_objects(filepath)
    if hasattr(pcap, 'extract_dns_queries'):
        pcap.extract_dns_queries(filepath)
    if hasattr(pcap, 'extract_credentials'):
        pcap.extract_credentials(filepath)
    if hasattr(pcap, 'search_pcap_flags'):
        pcap.search_pcap_flags(filepath)
    if hasattr(pcap, 'reconstruct_streams'):
        pcap.reconstruct_streams(filepath)


def analyze_disk_image(filepath):
    """Analisis disk image."""
    print(f"{Fore.GREEN}[DISK] Analisis disk image...{Style.RESET_ALL}")
    out_dir = filepath.parent / f"{filepath.stem}_disk_analysis"
    out_dir.mkdir(exist_ok=True)
    
    try:
        cmd = f"strings -n 8 '{filepath}' | head -20000"
        str_out = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30).stdout
        (out_dir / "extracted_strings.txt").write_text(str_out[:100000], errors='ignore')
        core.scan_text_for_flags(str_out, "DISK")
        core.collect_base64_from_text(str_out[:50000])
        
        scan_size = min(10 * 1024 * 1024, filepath.stat().st_size)
        raw = filepath.read_bytes()[:scan_size]
        for ext, sig in {"png": b"\x89PNG", "jpg": b"\xff\xd8\xff", "zip": b"PK\x03\x04", "pdf": b"%PDF"}.items():
            idx = raw.find(sig)
            if idx != -1:
                core.add_to_summary("DISK-FILE", f"{ext.upper()} at offset {idx}")
        
        core.add_to_summary("DISK-ANALYSIS", f"Results in '{out_dir.name}'")
        new_flags = list(core.found_flags_set)
        core.log_tool("disk-analysis", "✅ Found" if new_flags else "⬜ Analyzed",
                      ", ".join(new_flags) if new_flags else f"output: {out_dir.name}")
    except Exception as e:
        print(f"{Fore.RED}[DISK] Gagal: {e}{Style.RESET_ALL}")
        core.log_tool("disk-analysis", "❌ Error", str(e))


def analyze_memory_advanced(filepath):
    """Advanced memory forensics dengan Volatility 3."""
    print(f"{Fore.GREEN}[MEMORY] Advanced memory analysis...{Style.RESET_ALL}")
    
    vol_cmd = None
    for candidate in ['vol', 'volatility3', 'volatility', 'vol.py', 'python3 vol.py']:
        check = subprocess.run(f"which {candidate.split()[0]}", shell=True, capture_output=True)
        if check.returncode == 0:
            vol_cmd = candidate
            break
    
    if not vol_cmd:
        for path in ['/usr/local/bin/vol', '/usr/bin/vol', '/opt/volatility3/vol.py']:
            if Path(path).exists():
                vol_cmd = f"python3 {path}" if path.endswith('.py') else path
                break
    
    if not vol_cmd:
        print(f"{Fore.RED}[MEMORY] Volatility tidak ditemukan!{Style.RESET_ALL}")
        print(f"{Fore.YELLOW}  Install: pip install volatility3{Style.RESET_ALL}")
        core.add_to_summary("MEMORY-ERROR", "Binary tidak ditemukan")
        return
    
    print(f"{Fore.CYAN}[MEMORY] Menggunakan: {vol_cmd}{Style.RESET_ALL}")
    out_dir = filepath.parent / f"{filepath.stem}_memory"
    out_dir.mkdir(exist_ok=True)
    
    def run_vol(plugin, extra_args=None, label=None):
        cmd = f"{vol_cmd} -f '{filepath}' {plugin}"
        if extra_args:
            cmd += f" {extra_args}"
        label = label or plugin.replace('.', '_')
        print(f"\n{Fore.CYAN}[VOL] {plugin}{Style.RESET_ALL}")
        
        try:
            r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=300)
            out = r.stdout + r.stderr
            if out.strip():
                print(out[:2000])
                (out_dir / f"{label}.txt").write_text(out)
                core.scan_text_for_flags(out, f"VOL-{label.upper()}")
                core.collect_base64_from_text(out)
                return out
        except subprocess.TimeoutExpired:
            print(f"{Fore.RED}[VOL] Timeout pada {plugin}{Style.RESET_ALL}")
        except Exception as e:
            print(f"{Fore.RED}[VOL] Gagal {plugin}: {e}{Style.RESET_ALL}")
        return ""
    
    info_out = run_vol("windows.info", label="windows_info")
    is_windows = "windows" in info_out.lower() or "KDBG" in info_out
    
    if is_windows:
        print(f"{Fore.GREEN}[MEMORY] Windows memory image terdeteksi{Style.RESET_ALL}")
        run_vol("windows.pslist", label="pslist")
        run_vol("windows.pstree", label="pstree")
        run_vol("windows.cmdline", label="cmdline")
        run_vol("windows.envars", "--filter USERNAME", label="envars_username")
        run_vol("windows.netscan", label="netscan")
        run_vol("windows.filescan", label="filescan")
        run_vol("windows.hashdump", label="hashdump")
    else:
        run_vol("linux.pslist", label="linux_pslist")
        run_vol("linux.bash", label="linux_bash")
    
    new_flags = list(core.found_flags_set)
    core.log_tool("volatility", "✅ Found" if new_flags else "⬜ Analyzed",
                  ", ".join(new_flags) if new_flags else f"output: {out_dir.name}")
    core.add_to_summary("MEMORY-DONE", f"Output: '{out_dir.name}'")
    print(f"{Fore.GREEN}[MEMORY] Selesai. Output: {out_dir.name}{Style.RESET_ALL}")
