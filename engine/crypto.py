"""RAVEN crypto — RSA, XOR, Vigenere, classic ciphers, encoding chain."""

import re
import math
from pathlib import Path
from colorama import Fore, Style

from . import core


def _crypto_result(label, value):
    """Print hasil crypto dengan format rapi."""
    print(f"  {Fore.CYAN}{label}: {value}{Style.RESET_ALL}")


def _crypto_flag_check(text, source):
    """Cek flag di teks hasil crypto."""
    for pat in core.COMMON_FLAG_PATTERNS:
        if re.search(pat, text, re.IGNORECASE):
            flags = re.findall(pat, text, re.IGNORECASE)
            for flag in flags:
                flag_clean = flag.strip()
                print(f"\n{Fore.GREEN}{'─' * 50}")
                print(f"  🚩 FLAG dari {source}!")
                print(f"  {Fore.YELLOW}{flag_clean}{Style.RESET_ALL}")
                print(f"{'─' * 50}{Style.RESET_ALL}\n")
                core.add_to_summary(f"FLAG-{source}", flag_clean)
                core.signal_flag_found()


# ── Math Utils ──────────────────────────────────


def crypto_gcd(a, b):
    """GCD Euclidean algorithm."""
    while b:
        a, b = b, a % b
    return a


def crypto_extended_gcd(a, b):
    """Extended GCD untuk EEA."""
    if a == 0:
        return b, 0, 1
    gcd, x1, y1 = crypto_extended_gcd(b % a, a)
    x = y1 - (b // a) * x1
    y = x1
    return gcd, x, y


def crypto_modinv(a, m):
    """Modular inverse dengan Extended GCD."""
    g, x, _ = crypto_extended_gcd(a % m, m)
    if g != 1:
        raise Exception('Modular inverse tidak ada')
    return x % m


def crypto_int_to_str(n):
    """Convert integer ke string (bytes)."""
    hex_str = hex(n)[2:]
    if len(hex_str) % 2:
        hex_str = '0' + hex_str
    try:
        return bytes.fromhex(hex_str).decode('utf-8', errors='ignore')
    except:
        return str(n)


# ── 1. RSA: FERMAT FACTORIZATION ──────────────


def rsa_fermat_factor(N, e, c):
    """
    Fermat factorization: N = p * q, p dan q berdekatan.
    N = a² - b² = (a-b)(a+b).
    """
    print(f"\n{Fore.CYAN}[RSA] Mencoba Fermat Factorization...{Style.RESET_ALL}")
    
    a = math.isqrt(N) + 1
    b2 = a * a - N
    
    max_iterations = 1000000
    iterations = 0
    
    while not math.isqrt(b2) ** 2 == b2:
        a += 1
        b2 = a * a - N
        iterations += 1
        
        if iterations > max_iterations or core.check_early_exit():
            print(f"  {Fore.YELLOW}Fermat gagal setelah {iterations} iterasi.{Style.RESET_ALL}")
            return None
    
    b = math.isqrt(b2)
    p = a - b
    q = a + b
    
    if p * q == N:
        _crypto_result("p", str(p)[:60])
        _crypto_result("q", str(q)[:60])
        
        try:
            phi = (p - 1) * (q - 1)
            d = crypto_modinv(e, phi)
            m = pow(c, d, N)
            flag_str = crypto_int_to_str(m)
            _crypto_result("Decrypted", flag_str)
            _crypto_flag_check(flag_str, "RSA-FERMAT")
            return flag_str
        except Exception as ex:
            print(f"  {Fore.RED}Dekripsi gagal: {ex}{Style.RESET_ALL}")
    
    return None


# ── 2. RSA: WEAK PRIME FACTORIZATION ──────────


def rsa_weak_prime(N, e, c):
    """
    Cek apakah p atau q prime kecil/lemah.
    Coba factor dengan trial division untuk prime kecil.
    """
    print(f"\n{Fore.CYAN}[RSA] Mencoba Weak Prime Factorization...{Style.RESET_ALL}")
    
    small_primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47,
                    53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113]
    
    for p in small_primes:
        if N % p == 0:
            q = N // p
            _crypto_result("p", p)
            _crypto_result("q", q)
            
            try:
                phi = (p - 1) * (q - 1)
                d = crypto_modinv(e, phi)
                m = pow(c, d, N)
                flag_str = crypto_int_to_str(m)
                _crypto_result("Decrypted", flag_str)
                _crypto_flag_check(flag_str, "RSA-WEAK-PRIME")
                return flag_str
            except Exception as ex:
                print(f"  {Fore.RED}Dekripsi gagal: {ex}{Style.RESET_ALL}")
    
    print(f"  {Fore.YELLOW}Weak prime tidak ditemukan.{Style.RESET_ALL}")
    return None


# ── 3. RSA: COMMON MODULUS ATTACK ─────────────


def rsa_common_modulus(N, e1, e2, c1, c2):
    """
    Common modulus: N sama, e1 dan e2 berbeda, pesan sama.
    gcd(e1,e2)=1 → EEA → M = C1^s * C2^t mod N.
    """
    print(f"\n{Fore.CYAN}[RSA] Common Modulus Attack...{Style.RESET_ALL}")
    
    g, s, t = crypto_extended_gcd(e1, e2)
    _crypto_result(f"gcd(e1={e1}, e2={e2})", g)
    
    if g != 1:
        print(f"  {Fore.RED}gcd ≠ 1, Common Modulus Attack tidak berlaku!{Style.RESET_ALL}")
        return None
    
    _crypto_result("s", s)
    _crypto_result("t", t)
    
    if s < 0:
        c1_inv = pow(c1, -1, N)
        part1 = pow(c1_inv, -s, N)
    else:
        part1 = pow(c1, s, N)
    
    if t < 0:
        c2_inv = pow(c2, -1, N)
        part2 = pow(c2_inv, -t, N)
    else:
        part2 = pow(c2, t, N)
    
    M = (part1 * part2) % N
    flag_str = crypto_int_to_str(M)
    _crypto_result("Recovered plaintext", flag_str)
    _crypto_flag_check(flag_str, "RSA-COMMON-MOD")
    return flag_str


# ── 4. RSA: BELLCORE CRT FAULT ATTACK ─────────


def rsa_bellcore_crt(N, e, C, sig_faulty, M_msg):
    """
    Bellcore CRT fault attack: gcd(sig_faulty^e - M, N) = p atau q.
    """
    print(f"\n{Fore.CYAN}[RSA] Bellcore CRT Fault Attack...{Style.RESET_ALL}")
    
    diff = (pow(sig_faulty, e, N) - M_msg) % N
    p = math.gcd(diff, N)
    
    if p in (1, N):
        print(f"  {Fore.YELLOW}GCD tidak menghasilkan faktor nontrivial.{Style.RESET_ALL}")
        return None
    
    q = N // p
    if p * q != N:
        print(f"  {Fore.RED}p * q ≠ N, faktorisasi gagal.{Style.RESET_ALL}")
        return None
    
    _crypto_result("p", str(p)[:60])
    _crypto_result("q", str(q)[:60])
    
    try:
        phi = (p - 1) * (q - 1)
        d = crypto_modinv(e, phi)
        m = pow(C, d, N)
        flag_str = crypto_int_to_str(m)
        _crypto_result("Decrypted", flag_str)
        _crypto_flag_check(flag_str, "RSA-BELLCORE")
        return flag_str
    except Exception as ex:
        print(f"  {Fore.RED}Dekripsi gagal: {ex}{Style.RESET_ALL}")
    
    return None


# ── 5. RSA: AUTO-DETECT & TRY ALL ATTACKS ─────


def rsa_auto_attack(N, e, c, e2=None, c2=None, sig_faulty=None, msg=None):
    """
    Coba semua RSA attacks secara otomatis berdasarkan parameter yang tersedia.
    """
    print(f"\n{Fore.CYAN}[RSA] Auto-Attack Pipeline...{Style.RESET_ALL}")
    
    results = []
    
    print(f"  {Fore.YELLOW}Mencoba Fermat Factorization...{Style.RESET_ALL}")
    r = rsa_fermat_factor(N, e, c)
    if r:
        results.append(("Fermat", r))
    
    print(f"  {Fore.YELLOW}Mencoba Weak Prime Factorization...{Style.RESET_ALL}")
    r = rsa_weak_prime(N, e, c)
    if r:
        results.append(("WeakPrime", r))
    
    if e2 and c2:
        print(f"  {Fore.YELLOW}Mencoba Common Modulus Attack...{Style.RESET_ALL}")
        r = rsa_common_modulus(N, e, e2, c, c2)
        if r:
            results.append(("CommonMod", r))
    
    if sig_faulty and msg:
        print(f"  {Fore.YELLOW}Mencoba Bellcore CRT Fault Attack...{Style.RESET_ALL}")
        r = rsa_bellcore_crt(N, e, c, sig_faulty, msg)
        if r:
            results.append(("Bellcore", r))
    
    if results:
        print(f"\n{Fore.GREEN}{'═' * 50}")
        print(f"  🚩 RSA ATTACK BERHASIL!")
        for method, val in results:
            print(f"  [{method}] {val}")
        print(f"{'═' * 50}{Style.RESET_ALL}")
    else:
        print(f"\n{Fore.YELLOW}[RSA] Semua serangan dasar gagal.{Style.RESET_ALL}")
    
    return results


# ── 6. VIGENERE CIPHER + ACROSTIC KEY FINDER ──


def vigenere_decrypt(ciphertext, key):
    """Dekripsi Vigenere cipher."""
    key = key.upper()
    result = []
    key_idx = 0
    
    for c in ciphertext:
        if c.isalpha():
            shift = ord(key[key_idx % len(key)]) - ord('A')
            plain = chr((ord(c.lower()) - ord('a') - shift + 26) % 26 + ord('a'))
            result.append(plain.upper() if c.isupper() else plain)
            key_idx += 1
        else:
            result.append(c)
    
    return ''.join(result)


def find_acrostic_key(text):
    """Cari kunci akrostik: huruf pertama setiap kalimat/baris."""
    lines = [l.strip() for l in text.splitlines() if l.strip()]
    acrostic = ''
    
    for line in lines:
        if re.match(r'^[=\-\*#]{3,}', line):
            continue
        if re.match(r'^[A-Za-z]+:', line) and len(line.split()[0]) > 3 and line.split()[0].endswith(':'):
            continue
        m = re.match(r'([A-Za-z])', line)
        if m:
            acrostic += m.group(1).upper()
    
    return acrostic


def analyze_vigenere(ciphertext, context_text=""):
    """Analisis Vigenere: akrostik + brute common keys."""
    print(f"\n{Fore.CYAN}[VIGENERE] Analyzing Vigenere cipher...{Style.RESET_ALL}")
    print(f"  Ciphertext: {ciphertext[:80]}")
    
    found_flags = []
    
    if context_text:
        acrostic = find_acrostic_key(context_text)
        print(f"\n{Fore.CYAN}[VIGENERE] Akrostik dari teks konteks: '{acrostic}'{Style.RESET_ALL}")
        
        for length in range(4, min(len(acrostic) + 1, 12)):
            for start in range(max(1, len(acrostic) - length + 1)):
                candidate_key = acrostic[start:start + length]
                decrypted = vigenere_decrypt(ciphertext, candidate_key)
                _crypto_flag_check(decrypted, f"VIGENERE-ACROSTIC-{candidate_key}")
                for pat in core.COMMON_FLAG_PATTERNS:
                    if re.search(pat, decrypted, re.IGNORECASE):
                        _crypto_result(f"Key '{candidate_key}'", decrypted)
                        found_flags.append(decrypted)
    
    common_keys = [
        "KEY", "SECRET", "FLAG", "CTF", "CRYPTO", "HACK", "CIPHER", "VIGENERE",
        "PHANTOM", "SHADOW", "DRAGON", "MASTER", "DARK", "LIGHT", "ALPHA", "OMEGA",
        "PASSWORD", "KEYWORD", "ENCODE", "DECODE", "ATTACK", "DEFEND", "SECURE"
    ]
    
    print(f"\n{Fore.CYAN}[VIGENERE] Mencoba {len(common_keys)} kunci umum CTF...{Style.RESET_ALL}")
    for key in common_keys:
        decrypted = vigenere_decrypt(ciphertext, key)
        for pat in core.COMMON_FLAG_PATTERNS:
            if re.search(pat, decrypted, re.IGNORECASE):
                _crypto_result(f"Key '{key}'", decrypted)
                _crypto_flag_check(decrypted, f"VIGENERE-KEY-{key}")
                found_flags.append(decrypted)
    
    if not found_flags:
        print(f"  {Fore.YELLOW}Kunci tidak ditemukan secara otomatis.{Style.RESET_ALL}")
        print(f"  {Fore.YELLOW}Tip: gunakan --crypto-key YOURKEY untuk dekripsi manual.{Style.RESET_ALL}")
    
    return found_flags


# ── 7. CLASSIC CIPHERS: ATBASH + CAESAR AUTO ──


def atbash_cipher(text):
    """Atbash: A↔Z, B↔Y, dll."""
    result = []
    for c in text:
        if c.isupper():
            result.append(chr(ord('Z') - (ord(c) - ord('A'))))
        elif c.islower():
            result.append(chr(ord('z') - (ord(c) - ord('a'))))
        else:
            result.append(c)
    return ''.join(result)


def caesar_cipher(text, shift):
    """Caesar cipher dengan shift tertentu."""
    result = []
    for c in text:
        if c.isupper():
            result.append(chr((ord(c) - ord('A') + shift) % 26 + ord('A')))
        elif c.islower():
            result.append(chr((ord(c) - ord('a') + shift) % 26 + ord('a')))
        else:
            result.append(c)
    return ''.join(result)


def analyze_classic_cipher(ciphertext, known_plaintext_prefix=None):
    """
    Auto-analisis cipher klasik:
    - Atbash saja
    - Caesar semua shift
    - Atbash → Caesar
    - Caesar → Atbash
    """
    print(f"\n{Fore.CYAN}[CLASSIC] Analyzing classic ciphers...{Style.RESET_ALL}")
    print(f"  Input: {ciphertext[:80]}")
    
    found_flags = []
    
    def check_and_report(label, text):
        for pat in core.COMMON_FLAG_PATTERNS:
            if re.search(pat, text, re.IGNORECASE):
                _crypto_result(label, text)
                _crypto_flag_check(text, f"CLASSIC-{label.upper().replace(' ','_')}")
                found_flags.append((label, text))
                return True
        return False
    
    r = atbash_cipher(ciphertext)
    check_and_report("Atbash", r)
    
    for shift in range(1, 26):
        r = caesar_cipher(ciphertext, shift)
        if check_and_report(f"Caesar+{shift}", r):
            pass
    
    atbash_first = atbash_cipher(ciphertext)
    for shift in range(1, 26):
        r = caesar_cipher(atbash_first, shift)
        if check_and_report(f"Atbash→Caesar{shift:+}", r):
            pass
        r = caesar_cipher(atbash_first, -shift)
        if check_and_report(f"Atbash→Caesar{-shift:+}", r):
            pass
    
    for shift in range(1, 26):
        caesar_first = caesar_cipher(ciphertext, shift)
        r = atbash_cipher(caesar_first)
        if check_and_report(f"Caesar{shift:+}→Atbash", r):
            pass
    
    if not found_flags:
        print(f"  {Fore.YELLOW}Tidak ada flag ditemukan dengan cipher klasik.{Style.RESET_ALL}")
    
    return found_flags


# ── 8. XOR: MULTI-BYTE KPA ────────────────────


def xor_kpa_attack(enc_bytes, known_plaintext_bytes, key_len=None):
    """Known-Plaintext Attack pada XOR repeating key."""
    print(f"\n{Fore.CYAN}[XOR] Known-Plaintext Attack...{Style.RESET_ALL}")
    
    results = []
    
    def try_key_len(klen):
        if len(known_plaintext_bytes) < klen:
            return None
        
        key_partial = bytes(
            known_plaintext_bytes[i] ^ enc_bytes[i]
            for i in range(min(klen, len(enc_bytes), len(known_plaintext_bytes)))
        )
        
        if len(key_partial) < klen:
            return None
        
        if not all(32 <= b <= 126 for b in key_partial):
            return None
        
        decrypted = bytes(
            enc_bytes[i] ^ key_partial[i % klen]
            for i in range(len(enc_bytes))
        )
        return key_partial, decrypted
    
    key_lengths = [key_len] if key_len else range(1, 33)
    
    for klen in key_lengths:
        res = try_key_len(klen)
        if res:
            key_bytes, decrypted = res
            try:
                key_str = key_bytes.decode('ascii', errors='replace')
                dec_str = decrypted.decode('utf-8', errors='replace')
                
                printable_ratio = sum(1 for c in decrypted if 32 <= c <= 126) / len(decrypted)
                if printable_ratio > 0.8:
                    _crypto_result(f"Key (len={klen})", key_str)
                    _crypto_result("Decrypted", dec_str[:100])
                    _crypto_flag_check(dec_str, f"XOR-KPA-KEY{klen}")
                    results.append((key_str, dec_str))
            except Exception:
                pass
    
    if not results:
        print(f"  {Fore.YELLOW}KPA gagal.{Style.RESET_ALL}")
    
    return results


def xor_decrypt(enc_bytes, key_bytes):
    """Dekripsi XOR dengan key repeating."""
    klen = len(key_bytes)
    return bytes(enc_bytes[i] ^ key_bytes[i % klen] for i in range(len(enc_bytes)))


def analyze_xor(filepath_or_bytes, known_plain=b'CTF{', key_str=None):
    """Analisis file dengan XOR."""
    print(f"\n{Fore.CYAN}[XOR] Analyzing XOR encryption...{Style.RESET_ALL}")
    
    if isinstance(filepath_or_bytes, bytes):
        data = filepath_or_bytes
    else:
        try:
            data = Path(filepath_or_bytes).read_bytes()
        except Exception as e:
            print(f"  {Fore.RED}Gagal baca file: {e}{Style.RESET_ALL}")
            return []
    
    results = []
    
    if key_str:
        key_b = key_str.encode('utf-8') if isinstance(key_str, str) else key_str
        dec = xor_decrypt(data, key_b)
        try:
            dec_str = dec.decode('utf-8', errors='replace')
            _crypto_result(f"Key '{key_str}'", dec_str[:100])
            _crypto_flag_check(dec_str, "XOR-MANUAL")
            results.append(dec_str)
        except Exception:
            pass
        return results
    
    print(f"  {Fore.YELLOW}Known-plaintext: {known_plain}{Style.RESET_ALL}")
    kpa_results = xor_kpa_attack(data, known_plain)
    results.extend(kpa_results)
    
    return results


# ── 9. ENCODING CHAIN DECODER ─────────────────


def decode_base32(candidate):
    """Decode Base32."""
    import base64 as _b64
    try:
        clean = re.sub(r'[^A-Za-z2-7]', '', candidate).upper()
        if len(clean) < 8:
            return None
        pad = (8 - len(clean) % 8) % 8
        decoded = _b64.b32decode(clean + '=' * pad)
        s = decoded.decode('utf-8', errors='ignore')
        if len(s.strip()) > 3 and all(c.isprintable() or c.isspace() for c in s):
            return s
    except:
        pass
    return None


def decode_base58(candidate):
    """Decode Base58 (Bitcoin-style)."""
    ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
    try:
        if not all(c in ALPHABET for c in candidate):
            return None
        if len(candidate) < 4:
            return None
        
        n = 0
        for char in candidate:
            n = n * 58 + ALPHABET.index(char)
        
        result = []
        while n > 0:
            result.append(n % 256)
            n //= 256
        
        result.reverse()
        s = bytes(result).decode('utf-8', errors='ignore')
        
        if len(s.strip()) > 3 and all(c.isprintable() for c in s.strip()):
            return s
    except:
        pass
    return None


def decode_encoding_chain(candidate):
    """
    Decode encoding chain: Base32→Binary→BitRev→Base64→Hex.
    Coba semua kombinasi.
    """
    print(f"\n{Fore.CYAN}[ENCODING-CHAIN] Decoding chain...{Style.RESET_ALL}")
    print(f"  Input: {candidate[:60]}...")
    
    results = []
    
    # Stage 1: Try Base32
    b32_decoded = decode_base32(candidate)
    if b32_decoded:
        print(f"  {Fore.GREEN}✓ Base32 decoded: {b32_decoded[:60]}{Style.RESET_ALL}")
        results.append(("Base32", b32_decoded))
        
        # Stage 2: Try decode result
        if b32_decoded:
            for pat in core.COMMON_FLAG_PATTERNS:
                if re.search(pat, b32_decoded, re.IGNORECASE):
                    _crypto_flag_check(b32_decoded, "ENCODING-CHAIN-BASE32")
    
    # Try Base58
    b58_decoded = decode_base58(candidate)
    if b58_decoded:
        print(f"  {Fore.GREEN}✓ Base58 decoded: {b58_decoded[:60]}{Style.RESET_ALL}")
        results.append(("Base58", b58_decoded))
        
        for pat in core.COMMON_FLAG_PATTERNS:
            if re.search(pat, b58_decoded, re.IGNORECASE):
                _crypto_flag_check(b58_decoded, "ENCODING-CHAIN-BASE58")
    
    # Try hex decode
    try:
        clean_hex = re.sub(r'[^0-9a-fA-F]', '', candidate)
        if len(clean_hex) >= 8 and len(clean_hex) % 2 == 0:
            hex_decoded = bytes.fromhex(clean_hex).decode('utf-8', errors='ignore')
            if len(hex_decoded.strip()) > 3:
                print(f"  {Fore.GREEN}✓ Hex decoded: {hex_decoded[:60]}{Style.RESET_ALL}")
                results.append(("Hex", hex_decoded))
                
                for pat in core.COMMON_FLAG_PATTERNS:
                    if re.search(pat, hex_decoded, re.IGNORECASE):
                        _crypto_flag_check(hex_decoded, "ENCODING-CHAIN-HEX")
    except:
        pass
    
    if not results:
        print(f"  {Fore.YELLOW}Tidak bisa decode encoding chain.{Style.RESET_ALL}")

    return results


def analyze_file(filepath, args):
    """Dispatch crypto analysis berdasarkan args."""
    content = Path(filepath).read_text(errors="ignore")

    if args.rsa or args.auto or args.all:
        rsa_auto_attack(content, filepath)
    if args.vigenere or args.auto or args.all:
        analyze_vigenere(content)
    if args.classic or args.auto or args.all:
        analyze_classic_cipher(content)
    if args.xor_plain or args.xor_key or args.auto:
        known = args.xor_plain.encode() if args.xor_plain else b'CTF{'
        key = args.xor_key if args.xor_key else None
        analyze_xor(filepath, known, key)
    if args.encoding_chain or args.auto or args.all:
        decode_encoding_chain(content)
