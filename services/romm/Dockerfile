# Upstream RomM with one local fix, until it ships in a release:
# scan_rom() read rom_attrs["name"] unconditionally, so whenever libretro was
# the only metadata provider that matched a ROM it raised KeyError('name') and
# threw that ROM's whole scan result away - the ROM landed in the library with
# no metadata. Upstream fix: https://github.com/rommapp/romm/pull/5241
#
# ponytail: delete this directory, drop `build:` from services/romm.yaml and
# go back to `image: rommapp/romm:<version>` once a release contains the fix.
FROM rommapp/romm:5.4.1

COPY patch_name_fallback.py /tmp/patch_name_fallback.py
RUN python3 /tmp/patch_name_fallback.py && rm /tmp/patch_name_fallback.py
