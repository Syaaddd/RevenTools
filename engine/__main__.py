"""RAVEN engine entry point — dijalankan sebagai: python -m raven.engine"""

import sys
import os
from pathlib import Path

# Add parent directory to path so we can import engine modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from engine import core, report

def main():
    """RAVEN v5.1 entry point."""
    print(f"\n{core.Fore.CYAN}{'=' * 55}")
    print(f"   RAVEN v5.1 — CTF Multi-Category Toolkit")
    print(f"{'=' * 55}{core.Style.RESET_ALL}\n")
    
    core.check_tool_availability()
    
    # TODO: Parse arguments and dispatch to appropriate modules
    # This is a placeholder - full implementation will be in raven.sh
    print(f"{core.Fore.YELLOW}[INFO] Engine modular v5.1 siap digunakan!{core.Style.RESET_ALL}")
    print(f"{core.Fore.CYAN}Jalankan dari raven.sh untuk fitur lengkap.{core.Style.RESET_ALL}\n")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
