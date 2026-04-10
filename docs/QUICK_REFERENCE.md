# 🚀 RAVEN Quick Reference Guide

> **Per-category command cheatsheets for CTF competitions**  
> *Print this page for quick reference during competitions*

---

## 📖 How to Use This Guide

- **Left Column:** Category and scenario
- **Right Column:** Commands to run
- **Tip:** Combine multiple flags for comprehensive analysis
- **Example:** `raven image.png --auto --quick` (auto-detect with quick mode)

---

## 🔍 General Analysis

| Scenario | Command |
|----------|---------|
| Quick analysis (fastest) | `raven file --quick` |
| Auto-detect all | `raven file --auto` |
| Full analysis | `raven file --all` |
| Interactive menu | `raven file` (default) |
| Custom flag format | `raven -f "LKS{" file --auto` |
| Multiple files | `raven file1 file2 file3 --auto` |
| Folder scan | `raven --folder ./challenges/` |

---

## 🖼️ Steganography

### Image Steganography

| Scenario | Command |
|----------|---------|
| Auto steganalysis | `raven image.png --auto` |
| LSB analysis (zsteg) | `raven image.png --lsb` |
| Steghide extraction | `raven image.jpg --steghide` |
| Stegseek brute-force | `raven image.jpg --stegseek` |
| Outguess extraction | `raven image.jpg --outguess` |
| PNG validation | `raven image.png --pngcheck` |
| EXIF metadata | `raven image.jpg --exif` |
| Deep bit planes | `raven image.png --deep` |
| Color remapping | `raven image.png --remap` |
| Raw LSB extraction | `raven image.png --lsbextract` |
| Image comparison | `raven img1.png --compare img2.png` |
| File carving | `raven image.png --foremost` |
| Alpha channel | `raven image.png --alpha` |

### Advanced Steganography

| Scenario | Command |
|----------|---------|
| Chi-square detection | `raven image.png --chi-square` |
| JPEG DCT analysis | `raven image.jpg --dct-analysis` |
| Audio spectrogram | `raven audio.wav --spectrogram` |
| WAV LSB steganography | `raven audio.wav --auto` (auto-detect) |
| Appended data detection | `raven file --auto` (auto-detect) |

### Brute Force

| Scenario | Command |
|----------|---------|
| Steghide brute-force | `raven image.jpg --bruteforce` |
| Custom wordlist | `raven image.jpg --bruteforce --wordlist list.txt` |
| Parallel cracking | `raven image.jpg --bruteforce --parallel 10` |

---

## 🔐 Cryptography

| Scenario | Command |
|----------|---------|
| Full crypto analysis | `raven cipher.txt --crypto` |
| Classic ciphers (Caesar, Atbash) | `raven cipher.txt --classic` |
| Vigenère with auto-detect | `raven cipher.txt --crypto --vigenere` |
| RSA attacks (auto-detect) | `raven rsa.txt --crypto --rsa` |
| XOR with known plaintext | `raven enc.bin --xor-plain "CTF{"` |
| XOR with known key | `raven enc.bin --xor-key "SECRET"` |
| Multi-stage encoding | `raven enc.txt --encoding-chain` |
| Manual key (Vigenère/Caesar) | `raven cipher.txt --crypto-key "KEY"` |

### Hash Cracking

| Scenario | Command |
|----------|---------|
| John the Ripper | `raven hash.txt --john` |
| Hashcat | `raven hash.txt --hashcat` |
| Specific hash type | `raven hash.txt --john --hash-type sha256` |

### PDF Cracking

| Scenario | Command |
|----------|---------|
| PDF password crack | `raven protected.pdf --pdfcrack` |

---

## 💣 Binary Exploitation (Pwn)

| Scenario | Command |
|----------|---------|
| Basic reversing | `raven binary.elf --reversing` |
| Ghidra analysis | `raven binary.elf --reversing --ghidra` |
| UPX unpacking | `raven packed.exe --reversing --unpack` |
| Extract strings | `strings binary.elf \| grep -i "flag\|password"` |
| Check protections | `checksec binary.elf` |
| Skip objdump | `raven binary.elf --reversing --skip-objdump` |
| Skip readelf | `raven binary.elf --reversing --skip-readelf` |

---

## 🔍 Reverse Engineering

| Scenario | Command |
|----------|---------|
| Full reversing pipeline | `raven binary.elf --reversing` |
| Ghidra decompilation | `raven binary.elf --reversing --ghidra` |
| Extract strings | `raven binary.elf --reversing` (includes strings) |
| ELF analysis | `readelf -h binary.elf` |
| Disassembly | `objdump -d binary.elf` |

---

## 🌐 Web Exploitation

| Scenario | Command |
|----------|---------|
| Web server log analysis | `raven access.log --log` |
| Deobfuscation check | `raven suspicious.txt --deobfuscate` |

### External Tools (not in RAVEN)

| Scenario | Command |
|----------|---------|
| SQL injection testing | `sqlmap -u "http://target/?id=1" --dbs` |
| Directory brute-force | `gobuster dir -u http://target -w wordlist.txt` |
| Burp Suite | Manual testing with proxy |

---

## 🧩 Forensics

### File Analysis

| Scenario | Command |
|----------|---------|
| Full file analysis | `raven suspicious.file --auto` |
| Check file type | `file suspicious.dat` |
| Extract strings | `strings suspicious.dat \| less` |
| Binwalk scan | `binwalk firmware.bin -e` |
| Foremost carving | `raven disk.raw --foremost` |

### Memory Forensics

| Scenario | Command |
|----------|---------|
| Volatility analysis | `raven memory.raw --volatility` |
| Advanced memory | `raven memory.raw --memory` |
| Custom plugin | `raven memory.raw --volatility --vol-plugin malfind` |

### Disk Forensics

| Scenario | Command |
|----------|---------|
| Disk image analysis | `raven disk.raw --disk` |
| NTFS recovery | `raven disk.raw --ntfs` |
| MFT parser | `raven disk.raw --mft` |
| Partition analysis | `raven disk.raw --partition` |

### Network Forensics

| Scenario | Command |
|----------|---------|
| Full PCAP analysis | `raven capture.pcap --pcap` |
| DNS tunneling | `raven capture.pcap --dns-tunnel` |
| FTP reconstruction | `raven capture.pcap --ftp-recon` |
| Email reconstruction | `raven capture.pcap --email-recon` |
| Deep packet inspection | `raven capture.pcap --pcap-deep` |

---

## 🔢 Encoding & Decoding

| Scenario | Command |
|----------|---------|
| Binary digits analysis | `raven binary.txt --binary` |
| Binary to image | `raven binary.txt --binary --bin-width 64` |
| Morse code decoding | `raven morse.txt --morse` |
| Decimal ASCII | `raven decimal.txt --decimal` |
| Full deobfuscation | `raven encoded.txt --deobfuscate` |
| Base64/Hex extraction | `raven file.txt --decode` |
| Extract hidden files | `raven file.txt --extract` |

---

## 🌍 OSINT

| Scenario | Command |
|----------|---------|
| GPS extraction | `raven image.jpg --gps-extract` |
| EXIF metadata | `raven image.jpg --exif` |
| Document metadata | `raven document.pdf --auto` |

---

## 🔧 Specialized Analysis

| Scenario | Command |
|----------|---------|
| Windows Registry | `raven artifact.reg --reg` |
| Autorun/INF file | `raven autorun.inf --autorun` |
| ZIP password crack | `raven evidence.zip --zipcrack` |
| Forensic ZIP | `raven evidence.zip --forensic-zip` |
| Windows Event Log | `raven security.evtx --windows` |

---

## 📊 Workflow Examples

### Steganography Challenge
```bash
# Step 1: Quick check
raven image.png --quick

# Step 2: Full auto analysis
raven image.png --auto

# Step 3: Specific tools if needed
raven image.png --lsb --steghide --stegseek

# Step 4: Advanced detection
raven image.png --chi-square --dct-analysis

# Step 5: Brute force if password-protected
raven image.jpg --stegseek --wordlist rockyou.txt
```

### Cryptography Challenge
```bash
# Step 1: Auto-detect and attack
raven cipher.txt --crypto

# Step 2: If classical cipher
raven cipher.txt --classic

# Step 3: If RSA
raven rsa.txt --crypto --rsa

# Step 4: If hash
raven hash.txt --john --hash-type md5
```

### Binary Exploitation
```bash
# Step 1: Basic reversing
raven binary.elf --reversing

# Step 2: Check for packers
raven binary.exe --reversing --unpack

# Step 3: Ghidra analysis (if available)
raven binary.elf --reversing --ghidra

# Step 4: Extract strings
strings binary.elf | grep -E "flag|success|win"
```

### Forensics Challenge
```bash
# Step 1: File analysis
raven suspicious.file --auto

# Step 2: If disk image
raven disk.raw --disk --ntfs --mft

# Step 3: If memory dump
raven memory.raw --volatility --memory

# Step 4: If PCAP
raven capture.pcap --pcap --dns-tunnel
```

---

## 🎯 Quick Decision Tree

### What type of file is it?

**Image (PNG/JPG/GIF):**
1. `raven image.png --quick` (fast check)
2. `raven image.png --auto` (full analysis)
3. If nothing found → `raven image.png --chi-square` (statistical detection)

**Text File:**
1. `raven cipher.txt --crypto` (crypto analysis)
2. `raven cipher.txt --deobfuscate` (encoding check)
3. Look for patterns: Base64, hex, morse, binary

**Binary (ELF/EXE):**
1. `raven binary.elf --reversing` (basic analysis)
2. `strings binary.elf | grep -i flag` (quick win)
3. `raven binary.elf --reversing --ghidra` (deep analysis)

**PCAP:**
1. `raven capture.pcap --pcap` (standard analysis)
2. `raven capture.pcap --dns-tunnel` (DNS analysis)
3. Look for HTTP, FTP, email traffic

**Disk/Memory Image:**
1. `raven disk.raw --disk` (disk analysis)
2. `raven memory.raw --volatility` (memory analysis)
3. Check for deleted files, processes, network connections

**Unknown File:**
1. `file unknown.dat` (check type)
2. `raven unknown.dat --auto` (full analysis)
3. `strings unknown.dat | head -20` (check strings)

---

## 💡 Pro Tips

### Performance Optimization
- ✅ Use `--quick` for fast results during competitions
- ✅ Combine flags: `--auto --quick` for optimized auto-detect
- ✅ Use `--parallel 10` for faster brute-force
- ✅ Use CTF wordlist (100x faster than rockyou): already integrated

### Flag Detection
- ✅ RAVEN auto-detects flag patterns: `flag{}`, `CTF{}`, `picoCTF{}`, etc.
- ✅ Custom flag format: `-f "LKS{"`
- ✅ Flags printed in green with source information

### Output Folders
All analysis results saved to folders in current directory:
- `{file}_steghide/` - Steghide extractions
- `{file}_stegseek/` - Stegseek results
- `{file}_lsb/` - LSB analysis
- `{file}_crypto/` - Crypto analysis
- `{file}_reversing/` - Binary reversing output
- `{file}_volatility/` - Memory forensics
- `{file}_foremost/` - Carved files
- ... and many more (see README.md for full list)

### Environment Variables
```bash
export RAVEN_THREADS=10          # Set thread count (default: 5)
export RAVEN_WORDLIST="/path"    # Custom wordlist path
```

---

## 📚 Additional Resources

### Learning
- `raven --learn` - Display CTF learning roadmap
- `raven --learn crypto` - Focus on cryptography
- `raven --learn list` - Show all categories
- `docs/CTF_FUNDAMENTALS.md` - Complete learning guide

### Help & Documentation
- `raven --help` - Show all options
- `raven --install` - Install all tools
- `raven --install-global` - Install globally (use as `raven`)

### Online Resources
- **CyberChef:** https://gchq.github.io/CyberChef
- **dCode.fr:** https://www.dcode.fr
- **FactorDB:** https://factordb.com
- **CTFtime:** https://ctftime.org

---

## 🚨 Emergency Cheat Sheet

**Running out of time? Try these:**

```bash
# Fastest analysis
raven file --quick

# Check for easy flags
strings file | grep -i "flag\|CTF\|key"

# Auto everything
raven file --auto

# If stego suspected
raven image.jpg --stegseek

# If crypto challenge
raven cipher.txt --crypto

# If binary
raven binary.elf --reversing

# If network
raven capture.pcap --pcap

# If forensics
raven disk.raw --auto
raven memory.raw --volatility
```

---

**Good luck in your CTF competitions! 🚩**

*Print this page and keep it handy during competitions*
