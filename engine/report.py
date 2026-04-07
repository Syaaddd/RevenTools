"""RAVEN report — writeup generator (terminal/Markdown/JSON)."""

import json
import re
import time
from pathlib import Path
from colorama import Fore, Style

from . import core


def calculate_time(ts):
    """Hitung durasi dari timestamp."""
    return time.time() - ts


def format_duration(seconds):
    """Format durasi ke string yang readable."""
    if seconds < 1:
        return f"{seconds * 1000:.0f}ms"
    return f"{seconds:.1f}s"


def generate_terminal_report(filepath, flags, extractions):
    """Generate terminal report yang enriched dengan timeline."""
    fp = Path(filepath)
    
    print(f"\n{Fore.CYAN}{'=' * 60}")
    print(f"  RAVEN REPORT — {fp.name}")
    print(f"{'=' * 60}{Style.RESET_ALL}\n")
    
    # File info
    print(f"  {Fore.YELLOW}📋 FILE INFO{Style.RESET_ALL}")
    print(f"  {'─' * 56}")
    print(f"  Name     : {fp.name}")
    print(f"  Size     : {fp.stat().st_size:,} bytes ({fp.stat().st_size / 1024:.1f} KB)")
    print(f"  Path     : {fp.absolute()}{Style.RESET_ALL}\n")
    
    # Analysis timeline
    if core.event_log:
        print(f"  {Fore.YELLOW}🔍 ANALYSIS TIMELINE{Style.RESET_ALL}")
        print(f"  {'─' * 56}")
        
        for i, event in enumerate(core.event_log, 1):
            step_num = f"{i:02d}"
            tool = event['tool']
            result = event['result']
            detail = event.get('detail', '')
            
            # Format result dengan warna
            if result == "found":
                result_display = f"{Fore.GREEN}✅ FOUND{Style.RESET_ALL}"
            elif result == "nothing":
                result_display = f"{Fore.CYAN}⬜ Nothing{Style.RESET_ALL}"
            elif result == "error":
                result_display = f"{Fore.RED}❌ Error{Style.RESET_ALL}"
            elif result == "skipped":
                result_display = f"{Fore.YELLOW}⏭ Skipped{Style.RESET_ALL}"
            else:
                result_display = result
            
            # Print timeline entry
            print(f"  [{step_num}] {tool:<15} → {result_display}", end='')
            if detail:
                print(f"  ← {detail}", end='')
            print()
        
        print()
    
    # Flags found
    if flags:
        print(f"  {Fore.GREEN}🚩 FLAGS FOUND ({len(flags)}){Style.RESET_ALL}")
        print(f"  {'─' * 56}")
        for i, flag in enumerate(flags, 1):
            print(f"  {i}. {Fore.YELLOW}{flag}{Style.RESET_ALL}")
        print()
    
    # Extractions
    if extractions:
        print(f"  {Fore.BLUE}📦 EXTRACTIONS ({len(extractions)}){Style.RESET_ALL}")
        print(f"  {'─' * 56}")
        for item in extractions:
            print(f"  • {item}")
        print()
    
    # Writeup snippet
    if core.event_log and flags:
        print(f"  {Fore.MAGENTA}📝 WRITEUP SNIPPET (copy-paste ready){Style.RESET_ALL}")
        print(f"  {'─' * 56}")
        
        # Generate narrative
        file_ext = fp.suffix.lower().lstrip('.')
        print(f"  The challenge provides a {file_ext.upper()} file ({fp.name}).")
        
        # Summarize tools used
        tools_used = [e['tool'] for e in core.event_log if e['result'] == 'found']
        if tools_used:
            print(f"  Running {', '.join(tools_used)} reveals hidden data.")
        
        if flags:
            print(f"  The flag is: {flags[0]}")
        
        print()
    
    # Total duration
    if core.event_log:
        start_ts = core.event_log[0]['ts']
        end_ts = core.event_log[-1]['ts']
        duration = end_ts - start_ts
        print(f"  {Fore.CYAN}⏱  Total analysis time: {format_duration(duration)}{Style.RESET_ALL}")
    
    print(f"\n{Fore.CYAN}{'=' * 60}{Style.RESET_ALL}\n")


def generate_markdown_report(filepath, flags, extractions, output_dir=None):
    """Generate Markdown writeup file."""
    fp = Path(filepath)
    if output_dir is None:
        output_dir = fp.parent
    
    md_file = output_dir / f"{fp.stem}_writeup.md"
    
    lines = []
    lines.append(f"# {fp.name} — CTF Writeup\n")
    lines.append("## Challenge Info\n")
    lines.append(f"- **File**: {fp.name}")
    lines.append(f"- **Size**: {fp.stat().st_size:,} bytes ({fp.stat().st_size / 1024:.1f} KB)")
    lines.append(f"- **Path**: {fp.absolute()}\n")
    
    # Approach
    if core.event_log:
        lines.append("## Approach\n")
        for i, event in enumerate(core.event_log, 1):
            tool = event['tool']
            result = event['result']
            detail = event.get('detail', '')
            
            status = "✅ **found**" if result == 'found' else "⬜ nothing"
            line = f"{i}. Ran `{tool}` → {status}"
            if detail:
                line += f" ({detail})"
            lines.append(line)
        lines.append("")
    
    # Solution
    if flags:
        lines.append("## Solution\n")
        lines.append("```bash")
        # Tambahkan command yang digunakan (simplified)
        tools_found = [e['tool'] for e in core.event_log if e['result'] == 'found']
        if tools_found:
            for tool in tools_found:
                lines.append(f"# {tool} output...")
        lines.append("```\n")
        
        lines.append("## Flag\n")
        lines.append(f"```\n{flags[0]}\n```\n")
    
    # Extractions
    if extractions:
        lines.append("## Extracted Files\n")
        for item in extractions:
            lines.append(f"- {item}")
        lines.append("")
    
    md_file.write_text('\n'.join(lines))
    print(f"{Fore.GREEN}[REPORT] Markdown writeup saved: {md_file.name}{Style.RESET_ALL}")
    
    return md_file


def generate_json_report(filepath, flags, extractions, output_dir=None):
    """Generate JSON report untuk automation pipeline."""
    fp = Path(filepath)
    if output_dir is None:
        output_dir = fp.parent
    
    json_file = output_dir / f"{fp.stem}_report.json"
    
    report = {
        "file": fp.name,
        "size": fp.stat().st_size,
        "flags": flags,
        "extractions": extractions,
        "timeline": [],
        "duration": 0,
    }
    
    # Build timeline
    for i, event in enumerate(core.event_log, 1):
        report["timeline"].append({
            "step": i,
            "tool": event['tool'],
            "result": event['result'],
            "detail": event.get('detail', ''),
        })
    
    # Calculate duration
    if core.event_log:
        start_ts = core.event_log[0]['ts']
        end_ts = core.event_log[-1]['ts']
        report["duration"] = end_ts - start_ts
    
    json_file.write_text(json.dumps(report, indent=2))
    print(f"{Fore.GREEN}[REPORT] JSON report saved: {json_file.name}{Style.RESET_ALL}")
    
    return json_file


def generate_all_reports(filepath, flags, extractions, output_dir=None):
    """Generate semua format report (terminal, Markdown, JSON)."""
    # Terminal (stdout)
    generate_terminal_report(filepath, flags, extractions)

    # Markdown file
    md_file = generate_markdown_report(filepath, flags, extractions, output_dir)

    # JSON file
    json_file = generate_json_report(filepath, flags, extractions, output_dir)

    return {
        "markdown": md_file,
        "json": json_file,
    }


class WriteupBuilder:
    """Build writeup dari tool_log dan flag_summary."""

    def __init__(self, tool_log, flag_summary):
        self.tool_log = tool_log
        self.flag_summary = flag_summary

    def print_terminal_summary(self):
        """Print ringkasan ke terminal."""
        if not self.tool_log and not self.flag_summary:
            return

        print(f"\n{Fore.CYAN}{'=' * 60}")
        print(f"  RAVEN v5.1 — ANALYSIS SUMMARY")
        print(f"{'=' * 60}{Style.RESET_ALL}\n")

        if self.flag_summary:
            print(f"  {Fore.GREEN}🚩 FLAGS FOUND: {len(self.flag_summary)}{Style.RESET_ALL}")
            for i, flag in enumerate(self.flag_summary, 1):
                print(f"  {i}. {flag}")
            print()

        if self.tool_log:
            success = sum(1 for t in self.tool_log if "Found" in t.get("status", ""))
            total = len(self.tool_log)
            print(f"  {Fore.YELLOW}TOOLS EXECUTED: {total} total, {success} found results{Style.RESET_ALL}")
            for t in self.tool_log[:10]:  # Show first 10
                status_icon = "✅" if "Found" in t.get("status", "") else "⬜"
                print(f"  {status_icon} {t['tool']}: {t['status']}")
            if total > 10:
                print(f"  ... and {total - 10} more tools")
            print()
