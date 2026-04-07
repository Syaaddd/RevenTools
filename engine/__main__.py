"""RAVEN engine entry point — dijalankan sebagai: python -m engine"""

import sys
import os
import argparse
from pathlib import Path

from . import core, stego, forensics, crypto, reversing, pcap, report


def build_parser():
    """Bangun argument parser dengan semua opsi RAVEN."""
    parser = argparse.ArgumentParser(
        description="RAVEN v5.1 — CTF Multi-Category Toolkit",
        add_help=True
    )
    parser.add_argument("files", nargs="*", help="File(s) untuk dianalisis")

    # Mode utama
    mode = parser.add_argument_group("Mode")
    mode.add_argument("--quick", action="store_true", help="Ultra-fast mode")
    mode.add_argument("--auto", action="store_true", help="Auto-detect mode")
    mode.add_argument("--all", action="store_true", help="Jalankan semua tool")
    mode.add_argument("--interactive", action="store_true", help="Interactive menu")

    # CTF Spesifik
    ctf = parser.add_argument_group("CTF Spesifik")
    ctf.add_argument("--pcap", action="store_true", help="PCAP analysis")
    ctf.add_argument("--disk", action="store_true", help="Disk image analysis")
    ctf.add_argument("--windows", action="store_true", help="Windows Event Log")
    ctf.add_argument("--folder", type=str, help="Scan folder (fake ext)")
    ctf.add_argument("--reg", action="store_true", help="Registry analysis")
    ctf.add_argument("--log", action="store_true", help="Log analysis")
    ctf.add_argument("--autorun", action="store_true", help="Autorun/INF analysis")
    ctf.add_argument("--zipcrack", action="store_true", help="ZIP password crack")
    ctf.add_argument("--pdfcrack", action="store_true", help="PDF password crack")
    ctf.add_argument("--john", action="store_true", help="John the Ripper")
    ctf.add_argument("--hashcat", action="store_true", help="Hashcat")
    ctf.add_argument("--hash-type", type=str, help="Hash type untuk john/hashcat")
    ctf.add_argument("--volatility", action="store_true", help="Volatility 3")
    ctf.add_argument("--vol-plugin", type=str, help="Plugin Volatility tambahan")
    ctf.add_argument("--deobfuscate", action="store_true", help="Deobfuscation")
    ctf.add_argument("--reversing", action="store_true", help="Binary reversing")
    ctf.add_argument("--ghidra", action="store_true", help="Ghidra analysis")
    ctf.add_argument("--unpack", action="store_true", help="Auto-unpack UPX")

    # Crypto
    cr = parser.add_argument_group("Cryptography")
    cr.add_argument("--crypto", action="store_true", help="Auto-attack crypto")
    cr.add_argument("--rsa", action="store_true", help="RSA attacks")
    cr.add_argument("--vigenere", action="store_true", help="Vigenere analysis")
    cr.add_argument("--classic", action="store_true", help="Classic Cipher")
    cr.add_argument("--xor-plain", type=str, help="Known-plaintext XOR")
    cr.add_argument("--xor-key", type=str, help="XOR key")
    cr.add_argument("--crypto-key", type=str, help="Manual key")
    cr.add_argument("--encoding-chain", action="store_true", help="Encoding chain")

    # Stego
    st = parser.add_argument_group("Steganografi")
    st.add_argument("--lsb", action="store_true", help="LSB analysis")
    st.add_argument("--steghide", action="store_true", help="Steghide")
    st.add_argument("--stegseek", action="store_true", help="Stegseek")
    st.add_argument("--outguess", action="store_true", help="Outguess")
    st.add_argument("--pngcheck", action="store_true", help="PNG check")
    st.add_argument("--jpsteg", action="store_true", help="JPEG steg")
    st.add_argument("--remap", action="store_true", help="Color remap")
    st.add_argument("--exif", action="store_true", help="EXIF analysis")
    st.add_argument("--stegdetect", action="store_true", help="Stego detect")
    st.add_argument("--lsbextract", action="store_true", help="LSB extract")
    st.add_argument("--deep", action="store_true", help="Deep bit plane")
    st.add_argument("--alpha", action="store_true", help="Alpha channel")
    st.add_argument("--compare", type=str, help="Compare image")
    st.add_argument("--foremost", action="store_true", help="File carving")

    # Encoding
    enc = parser.add_argument_group("Encoding")
    enc.add_argument("--decode", action="store_true", help="Auto-decode")
    enc.add_argument("--extract", action="store_true", help="Extract hidden")

    # Brute Force
    bf = parser.add_argument_group("Brute Force")
    bf.add_argument("--bruteforce", action="store_true", help="Brute-force")
    bf.add_argument("--wordlist", type=str, help="Custom wordlist")
    bf.add_argument("--delay", type=float, default=0.1, help="Delay (sec)")
    bf.add_argument("--parallel", type=int, default=5, help="Threads")

    # Misc
    misc = parser.add_argument_group("Misc")
    misc.add_argument("-f", "--format", type=str, help="Flag prefix")
    misc.add_argument("--memory", action="store_true", help="Advanced memory")
    misc.add_argument("--ntfs", action="store_true", help="NTFS recovery")
    misc.add_argument("--partition", action="store_true", help="Partition scan")
    misc.add_argument("--dns-tunnel", action="store_true", help="DNS tunnel")
    misc.add_argument("--update-deps", action="store_true", help="Update deps")

    return parser


def main():
    """RAVEN v5.1 entry point."""
    parser = build_parser()
    args = parser.parse_args()

    if not args.files:
        parser.print_help()
        return 1

    # Set working directory untuk output dari env var CWD (dari raven.sh)
    import os
    args.output_dir = Path(os.environ.get('CWD', os.getcwd()))

    print(f"\n{core.Fore.CYAN}{'=' * 55}")
    print(f"   RAVEN v5.1 — CTF Multi-Category Toolkit")
    print(f"{'=' * 55}{core.Style.RESET_ALL}\n")

    core.check_tool_availability()

    # Reset globals untuk sesi baru
    core.reset_globals()

    # Process setiap file
    for filepath in args.files:
        fp = Path(filepath)
        if not fp.exists():
            print(f"{core.Fore.RED}[!] File tidak ditemukan: {fp}{core.Style.RESET_ALL}")
            continue

        print(f"\n{core.Fore.YELLOW}[→] Menganalisis: {fp.name}{core.Style.RESET_ALL}\n")

        # Dispatch ke module sesuai flag — safe attribute access dengan getattr
        if getattr(args, 'lsb', False) or getattr(args, 'steghide', False) or \
           getattr(args, 'stegseek', False) or getattr(args, 'outguess', False) or \
           getattr(args, 'pngcheck', False) or getattr(args, 'exif', False) or \
           getattr(args, 'remap', False) or getattr(args, 'lsbextract', False) or \
           getattr(args, 'stegdetect', False) or getattr(args, 'jpsteg', False) or \
           getattr(args, 'deep', False) or getattr(args, 'alpha', False) or \
           getattr(args, 'foremost', False):
            stego.analyze_file(str(fp), args)

        if getattr(args, 'crypto', False) or getattr(args, 'rsa', False) or \
           getattr(args, 'vigenere', False) or getattr(args, 'classic', False) or \
           getattr(args, 'xor_plain', False) or getattr(args, 'xor_key', False) or \
           getattr(args, 'encoding_chain', False):
            crypto.analyze_file(str(fp), args)

        if getattr(args, 'reversing', False) or getattr(args, 'unpack', False) or \
           getattr(args, 'ghidra', False):
            reversing.analyze_file(str(fp), args)

        if getattr(args, 'pcap', False) or getattr(args, 'dns_tunnel', False):
            pcap.analyze_file(str(fp), args)

        if getattr(args, 'disk', False) or getattr(args, 'ntfs', False) or \
           getattr(args, 'partition', False) or getattr(args, 'reg', False) or \
           getattr(args, 'log', False) or getattr(args, 'autorun', False) or \
           getattr(args, 'zipcrack', False) or getattr(args, 'memory', False) or \
           getattr(args, 'volatility', False) or getattr(args, 'windows', False):
            forensics.analyze_file(str(fp), args)

        if getattr(args, 'auto', False) or getattr(args, 'all', False) or getattr(args, 'quick', False):
            core.auto_detect_and_run(str(fp), args)

    # Print ringkasan lengkap di akhir
    if core.flag_summary or core.tool_log:
        print(f"\n{core.Fore.CYAN}{'=' * 60}")
        print(f"  📊 HASIL ANALISIS")
        print(f"{'=' * 60}{core.Style.RESET_ALL}\n")

        # Tampilkan flags yang ditemukan
        if core.flag_summary:
            print(f"  {core.Fore.GREEN}[🚩] FLAGS DITEMUKAN ({len(core.flag_summary)}):{core.Style.RESET_ALL}")
            print(f"  {'─' * 56}")
            for i, flag in enumerate(core.flag_summary, 1):
                print(f"    {i}. {flag}")
            print()

        # Tampilkan ringkasan tools yang dijalankan
        if core.tool_log:
            success_count = sum(1 for t in core.tool_log if "Found" in t.get("status", ""))
            total_count = len(core.tool_log)
            print(f"  {core.Fore.CYAN}[🔧] TOOLS YANG DIJALANKAN ({total_count}):{core.Style.RESET_ALL}")
            print(f"  {'─' * 56}")
            for t in core.tool_log:
                icon = "✅" if "Found" in t.get("status", "") else "⬜"
                print(f"    {icon} {t['tool']}: {t['status']}")
                if t.get('result'):
                    print(f"       → {t['result']}")
            print()

        # Tampilkan folder output yang dibuat di CWD
        cwd = Path(os.environ.get('CWD', os.getcwd()))
        if cwd.exists():
            output_folders = [d for d in cwd.iterdir() if d.is_dir() and any(
                d.name.endswith(suffix) for suffix in ['_bitplanes', '_channels', '_remap', '_stegseek',
                '_steghide', '_outguess', '_foremost', '_bruteforce', '_decoded', '_http_objects',
                '_streams', '_disk_analysis', '_lsb_raw', '_compare', '_exif', '_registry',
                '_log_analysis', '_autorun', '_zipcrack', '_volatility', '_ntfs', '_partitions',
                '_dns_tunnel', '_crypto', '_extracted_', '_reversing', '_objdump', '_readelf', '_strings'])]

            if output_folders:
                print(f"  {core.Fore.MAGENTA}[📁] OUTPUT FOLDERS (di CWD):{core.Style.RESET_ALL}")
                print(f"  {'─' * 56}")
                for folder in sorted(output_folders):
                    item_count = len(list(folder.iterdir())) if folder.is_dir() else 0
                    print(f"    📂 {folder.name}/ ({item_count} items)")
                print()

    print(f"\n{core.Fore.GREEN}✅ SELESAI.{core.Style.RESET_ALL}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
