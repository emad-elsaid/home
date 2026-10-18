"""Apply upstream's libretro-only name fallback to RomM's scan code.

scan_rom() logs rom_attrs["name"] right after merging provider metadata. Some
providers (libretro) match a ROM without supplying a name, so that key can be
absent and the whole scan result for the ROM is thrown away with
`KeyError: 'name'` - the ROM stays in the library with no metadata at all.

Fix is upstream PR rommapp/romm#5241: fall back to the filename.
"""

import ast
import sys
from pathlib import Path

TARGET = Path("/backend/handler/scan_handler.py")
MARKER = "# Providers like libretro match without supplying a name."

FALLBACK = [
    "    # Providers like libretro match without supplying a name.\n",
    '    if not rom_attrs.get("name"):\n',
    '        rom_attrs["name"] = fs_rom_handler.get_file_name_with_no_tags(\n',
    '            rom_attrs["fs_name"]\n',
    "        )\n",
    "\n",
]


def main() -> int:
    source = TARGET.read_text()
    if MARKER in source:
        print("already patched, nothing to do")
        return 0

    lines = source.splitlines(keepends=True)
    for index, line in enumerate(lines):
        if line.startswith("    log.info(") and "identified as" in lines[index + 1]:
            break
    else:
        print("anchor not found - upstream code changed, refusing to patch", file=sys.stderr)
        return 1

    lines[index:index] = FALLBACK
    patched = "".join(lines)
    ast.parse(patched)  # syntax check before writing
    TARGET.write_text(patched)
    print(f"patched {TARGET} at line {index + 1}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
