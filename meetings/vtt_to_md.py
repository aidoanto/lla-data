#!/usr/bin/env python3
"""Convert WebVTT transcript to plain markdown (no timestamps)."""
import re
import sys
from pathlib import Path

def vtt_to_markdown(vtt_path: Path) -> str:
    raw = vtt_path.read_text(encoding="utf-8", errors="replace")
    # Remove WEBVTT header and normalize
    if raw.startswith("WEBVTT"):
        raw = raw.split("\n", 1)[-1]
    # Find all speaker cues: <v Name>text</v> (may span lines)
    pattern = re.compile(r"<v\s+([^>]+)>\s*([\s\S]*?)\s*</v>", re.IGNORECASE)
    segments = []
    for m in pattern.finditer(raw):
        speaker = m.group(1).strip()
        text = m.group(2).replace("\n", " ").strip()
        if text:
            segments.append((speaker, text))

    # Merge consecutive same speaker
    merged = []
    for speaker, text in segments:
        if merged and merged[-1][0] == speaker:
            merged[-1][1] += " " + text
        else:
            merged.append([speaker, text])

    lines = []
    for speaker, text in merged:
        lines.append(f"**{speaker}:** {text}")
        lines.append("")
    return "\n".join(lines).strip() + "\n"


def main():
    vtt = Path(__file__).parent / "SEO-weekly-1.vtt"
    out = Path(__file__).parent / "SEO-weekly-1.md"
    md = vtt_to_markdown(vtt)
    out.write_text(md, encoding="utf-8")
    print(f"Wrote {out}")


if __name__ == "__main__":
    main()
