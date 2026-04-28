#!/usr/bin/env python3
"""Sanitize terminal-copied text: fix hard line wraps while preserving structure."""

import re
import sys
import textwrap


def _clean(l: str) -> str:
    l = l.rstrip()
    l = l.replace(' ', ' ')  # non-breaking space → regular space
    if '⏺' in l or '⎿' in l:
        l = l.replace('⏺', '').replace('⎿', '')
        l = re.sub(r'  +', ' ', l).strip()
    return l


def sanitize(text: str) -> str:
    lines = [_clean(l) for l in text.split('\n')]
    out: list[str] = []
    in_code = False

    for line in lines:
        # Toggle code fences
        if re.match(r'^```', line):
            in_code = not in_code
            out.append(line)
            continue

        if in_code:
            out.append(line)
            continue

        # Strip Claude Code block-quote border outside code fences
        if re.match(r'^\s*▎', line):
            line = re.sub(r'^\s*▎\s?', '', line)

        # Empty line — paragraph break, always keep
        if not line:
            out.append(line)
            continue

        # List item — always its own line
        if re.match(r'^\s*[-*+]\s', line) or re.match(r'^\s*\d+[.)]\s', line):
            out.append(line)
            continue

        # Indented block (unfenced code / command output)
        if line.startswith('    ') or line.startswith('\t'):
            out.append(line)
            continue

        # No previous content yet
        if not out:
            out.append(line)
            continue

        prev = out[-1]

        # Previous line is a natural break point — don't join
        if (
            not prev                                      # empty
            or prev.endswith(':')                         # intro line ("here are the steps:")
            or re.match(r'^\s*[-*+]\s', prev)            # previous was list item
            or re.match(r'^\s*\d+[.)]\s', prev)          # previous was numbered item
            or re.match(r'^```', prev)                    # just closed/opened a fence
        ):
            out.append(line)
            continue

        # Terminal wrap — join to previous line
        out[-1] = prev + ' ' + line.lstrip(' ')

    return textwrap.dedent('\n'.join(out))


if __name__ == '__main__':
    print(sanitize(sys.stdin.read()), end='')
