"""RAVEN pcap — PCAP analysis functions."""

import re
import subprocess
from pathlib import Path
from colorama import Fore, Style

from . import core


def _tshark(filepath, *args, timeout=60):
    """Run tshark command."""
    if not core.AVAILABLE_TOOLS.get('tshark'):
        return ""
    try:
        return subprocess.run(["tshark", "-r", str(filepath)] + list(args),
                              capture_output=True, text=True, timeout=timeout).stdout
    except:
        return ""


def extract_http_objects(filepath, output_dir=None):
    """Ekstrak HTTP objects dari PCAP."""
    if not core.AVAILABLE_TOOLS.get('tshark'):
        return
    
    out_dir = output_dir / f"{filepath.stem}_http_objects"
    out_dir.mkdir(exist_ok=True)
    
    try:
        subprocess.run(["tshark", "-r", str(filepath), "--export-objects", f"http,{out_dir}", "-q"],
                       capture_output=True, text=True, timeout=120)
        files = list(out_dir.glob("*"))
        if files:
            for f in files[:10]:
                analyze_extracted_file(f)
            core.add_to_summary("PCAP-HTTP", f"{len(files)} objects → '{out_dir.name}'")
    except Exception as e:
        print(f"{Fore.RED}[PCAP] HTTP gagal: {e}{Style.RESET_ALL}")


def extract_dns_queries(filepath, output_dir=None):
    """Ekstrak DNS queries dari PCAP."""
    if not core.AVAILABLE_TOOLS.get('tshark'):
        return
    
    output = _tshark(filepath, "-T", "fields", "-e", "dns.qry.name", "-Y", "dns", "-q")
    if output.strip():
        queries = [q for q in output.split('\n') if q]
        (output_dir / f"{filepath.stem}_dns_queries.txt").write_text(output)
        core.collect_base64_from_text(output)
        core.scan_text_for_flags(output, "PCAP-DNS")
        core.add_to_summary("PCAP-DNS", f"{len(queries)} queries saved")


def extract_credentials(filepath, output_dir=None):
    """Ekstrak credentials (FTP, HTTP-Auth, Telnet) dari PCAP."""
    if not core.AVAILABLE_TOOLS.get('tshark'):
        return
    
    creds = []
    for proto, extra in [("FTP", ["-T", "fields", "-e", "ftp.user", "-e", "ftp.pass", "-Y", "ftp", "-q"]),
                         ("HTTP-Auth", ["-T", "fields", "-e", "http.authbasic", "-Y", "http.authbasic", "-q"]),
                         ("Telnet", ["-T", "fields", "-e", "telnet.data", "-Y", "telnet", "-q"])]:
        out = _tshark(filepath, *extra)
        if out.strip():
            creds.append((proto, out.strip()))
    
    if creds:
        creds_file = output_dir / f"{filepath.stem}_credentials.txt"
        with open(creds_file, 'w') as f:
            for proto, data in creds:
                f.write(f"{proto}:\n{data}\n\n")
                core.scan_text_for_flags(data, f"PCAP-CREDS-{proto}")
        core.add_to_summary("PCAP-CREDENTIALS", f"Saved to '{creds_file.name}'")


def search_pcap_flags(filepath):
    """Cari flag di PCAP data."""
    if not core.AVAILABLE_TOOLS.get('tshark'):
        return
    
    for label, extra in [("data", ["-T", "fields", "-e", "data", "-q"]),
                         ("HTTP", ["-T", "fields", "-e", "http.file_data", "-q"]),
                         ("TCP", ["-T", "fields", "-e", "tcp.payload", "-q"])]:
        out = _tshark(filepath, *extra, timeout=120)
        core.scan_text_for_flags(out, f"PCAP-{label.upper()}")


def reconstruct_streams(filepath, output_dir=None):
    """Reconstruct TCP streams dari PCAP."""
    if not core.AVAILABLE_TOOLS.get('tshark'):
        return
    
    out_dir = output_dir / f"{filepath.stem}_streams"
    out_dir.mkdir(exist_ok=True)
    
    nums = set(_tshark(filepath, "-T", "fields", "-e", "tcp.stream", "-q").strip().split('\n'))
    nums = [s for s in nums if s]
    if not nums:
        return
    
    for num in nums[:10]:
        try:
            result = subprocess.run(["tshark", "-r", str(filepath), "-q", "-z", f"follow,tcp,ascii,{num}"],
                                    capture_output=True, text=True, timeout=30)
            (out_dir / f"stream_{num}.txt").write_text(result.stdout)
            core.scan_text_for_flags(result.stdout, f"PCAP-STREAM-{num}")
            core.collect_base64_from_text(result.stdout)
        except:
            continue
    
    core.add_to_summary("PCAP-STREAMS", f"{min(len(nums), 10)} streams → '{out_dir.name}'")


def analyze_pcap_timeline(filepath, output_dir=None):
    """Analisis timeline HTTP dari PCAP."""
    if not core.AVAILABLE_TOOLS.get('tshark'):
        return
    
    out = _tshark(filepath, "-T", "fields", "-e", "frame.time", "-e", "http.request.uri",
                  "-e", "http.request.method", "-e", "ip.src", "-Y", "http.request", "-q")
    if not out.strip():
        return
    
    lines = out.strip().split('\n')
    (output_dir / f"{filepath.stem}_timeline.txt").write_text("\n".join(lines))
    core.add_to_summary("PCAP-TIMELINE", f"{len(lines)} requests")


def detect_attack_patterns(filepath, output_dir=None):
    """Deteksi attack patterns di PCAP."""
    if not core.AVAILABLE_TOOLS.get('tshark'):
        return
    
    http = _tshark(filepath, "-T", "fields", "-e", "http.request.uri", "-e", "http.request.method", "-Y", "http", "-q")
    sigs = {
        'SQL Injection': r"(\bunion\b|\bselect\b|\binsert\b|\bdelete\b|\bdrop\b|%27|')",
        'XSS': r"(<script|javascript:|onerror=|onload=|alert\()",
        'LFI/RFI': r"(\.\.\/|\.\.\\|%2e%2e%2f|file:\/\/)",
        'Cmd Injection': r"(;|\||&&|\$\(|`)\s*(cat|ls|pwd|whoami|id)",
        'Path Traversal': r"(%2e%2e%2f|%2e%2e%5c){1,}"
    }
    
    for name, pat in sigs.items():
        matches = re.findall(pat, http, re.IGNORECASE)
        if matches:
            core.add_to_summary("PCAP-ATTACK", f"{name}: {len(matches)}")


def analyze_post_data(filepath, output_dir=None):
    """Analisis POST data dari PCAP."""
    if not core.AVAILABLE_TOOLS.get('tshark'):
        return
    
    out = _tshark(filepath, "-T", "fields", "-e", "http.request.method", "-e", "http.request.uri",
                  "-e", "http.file_data", "-Y", 'http.request.method == "POST"', "-q")
    if not out.strip():
        return
    
    core.scan_text_for_flags(out, "PCAP-POST")


def check_unusual_ports(filepath, output_dir=None):
    """Cek port tidak biasa di PCAP."""
    if not core.AVAILABLE_TOOLS.get('tshark'):
        return
    
    out = _tshark(filepath, "-T", "fields", "-e", "tcp.dstport", "-e", "udp.dstport", "-q")
    common = {'80', '443', '22', '21', '53', '25', '110', '143', '993', '995', '8080', '8443'}
    counts = {}
    
    for line in out.split('\n'):
        for port in line.split('\t'):
            if port:
                counts[port] = counts.get(port, 0) + 1
    
    unusual = {p: c for p, c in counts.items() if p not in common}
    for port, cnt in sorted(unusual.items(), key=lambda x: x[1], reverse=True)[:10]:
        core.add_to_summary("PCAP-PORT", f"Port {port}: {cnt}")


def analyze_extracted_file(filepath):
    """Analisis file yang diekstrak dari PCAP."""
    try:
        result = subprocess.run(['strings', str(filepath)], capture_output=True, text=True)
        core.scan_text_for_flags(result.stdout, f"EXTRACTED-{filepath.name}")
    except:
        pass


def analyze_dns_tunneling(filepath, output_dir=None):
    """Deteksi DNS tunneling dari PCAP."""
    if not core.AVAILABLE_TOOLS.get('tshark'):
        return
    
    print(f"\n{Fore.CYAN}[DNS-TUNNEL] Deteksi DNS tunneling...{Style.RESET_ALL}")
    output = _tshark(filepath, "-T", "fields", "-e", "dns.qry.name", "-Y", "dns", "-q")
    
    if not output.strip():
        print(f"  {Fore.YELLOW}Tidak ada DNS queries ditemukan.{Style.RESET_ALL}")
        return
    
    # Cari DNS queries yang panjang/mencurigakan
    suspicious_queries = []
    for line in output.split('\n'):
        if line.strip():
            # Queries panjang (>50 chars) biasanya tunneling
            if len(line.strip()) > 50:
                suspicious_queries.append(line.strip())
    
    if suspicious_queries:
        print(f"  {Fore.GREEN}✓ Ditemukan {len(suspicious_queries)} suspicious DNS queries{Style.RESET_ALL}")
        for q in suspicious_queries[:10]:
            print(f"    • {q[:80]}...")
        
        # Coba decode Base32/64 dari subdomain
        for q in suspicious_queries[:20]:
            parts = q.split('.')
            for part in parts:
                if len(part) > 10:
                    # Coba decode sebagai Base32
                    try:
                        import base64
                        decoded = base64.b32decode(part.upper() + '=' * ((8 - len(part) % 8) % 8))
                        text = decoded.decode('utf-8', errors='ignore')
                        if any(c.isprintable() for c in text):
                            print(f"  {Fore.GREEN}✓ Base32 decoded: {text[:50]}{Style.RESET_ALL}")
                            core.scan_text_for_flags(text, "DNS-BASE32")
                    except:
                        pass
                    
                    # Coba decode sebagai Base64
                    try:
                        import base64
                        decoded = base64.b64decode(part + '=' * ((4 - len(part) % 4) % 4))
                        text = decoded.decode('utf-8', errors='ignore')
                        if any(c.isprintable() for c in text):
                            print(f"  {Fore.GREEN}✓ Base64 decoded: {text[:50]}{Style.RESET_ALL}")
                            core.scan_text_for_flags(text, "DNS-BASE64")
                    except:
                        pass
        
        core.add_to_summary("DNS-TUNNEL", f"{len(suspicious_queries)} suspicious queries")
    else:
        print(f"  {Fore.YELLOW}Tidak ada indikasi DNS tunneling.{Style.RESET_ALL}")


def analyze_file(filepath, args):
    """Dispatch PCAP analysis berdasarkan args."""
    from pathlib import Path
    output_dir = getattr(args, 'output_dir', None)
    if output_dir is None:
        output_dir = Path(filepath).parent
    else:
        output_dir = Path(output_dir)
    
    extract_http_objects(filepath, output_dir=output_dir)
    extract_dns_queries(filepath, output_dir=output_dir)
    extract_credentials(filepath, output_dir=output_dir)
    search_pcap_flags(filepath)
    reconstruct_streams(filepath, output_dir=output_dir)
    analyze_pcap_timeline(filepath, output_dir=output_dir)
    detect_attack_patterns(filepath, output_dir=output_dir)
    analyze_post_data(filepath, output_dir=output_dir)
    check_unusual_ports(filepath, output_dir=output_dir)

    if args.dns_tunnel:
        analyze_dns_tunneling(filepath, output_dir=output_dir)
