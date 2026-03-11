"""
Packs project files into a Godot .pck and optionally embeds it into an executable.

Usage:
    python pack.py <project_dir> <output.pck>
    python pack.py <project_dir> <output.pck> --embed <executable>
"""

import hashlib
import os
import struct
import sys

PACK_HEADER_MAGIC = 0x43504447  # "GDPC"
PACK_FORMAT_VERSION = 3
PACK_ALIGNMENT = 64
PACK_REL_FILEBASE = 1 << 1
ALLOWED_PROJECT_DATA_FILES = {
    ".godot/global_script_class_cache.cfg",
}
IGNORED_PACK_FILES = {
    "gdcpp_log.txt",
}


def pad_to(n, alignment):
    remainder = n % alignment
    if remainder == 0:
        return 0
    return alignment - remainder


def collect_files(project_dir):
    """Collect project files using canonical pack-relative paths."""
    files = []
    for root, dirs, filenames in os.walk(project_dir):
        rel_root = os.path.relpath(root, project_dir).replace("\\", "/")

        # Skip debug extension artifacts entirely.
        dirs[:] = [d for d in dirs if d != "bin"]

        # Only include explicitly whitelisted runtime cache files from .godot.
        if rel_root == ".godot":
            dirs[:] = []
        elif rel_root.startswith(".godot/"):
            dirs[:] = []
            continue

        for fname in filenames:
            full_path = os.path.join(root, fname)
            rel_path = os.path.relpath(full_path, project_dir).replace("\\", "/")
            if fname in IGNORED_PACK_FILES:
                continue
            if rel_path.startswith(".godot/") and rel_path not in ALLOWED_PROJECT_DATA_FILES:
                continue
            files.append((rel_path, full_path))
    return sorted(files)


def write_pck(project_dir, output_path):
    """Write a Godot 4.x PCK v3 file."""
    files = collect_files(project_dir)
    print(f"Packing {len(files)} files from {project_dir}")

    with open(output_path, "wb") as f:
        f.write(struct.pack("<I", PACK_HEADER_MAGIC))
        f.write(struct.pack("<I", PACK_FORMAT_VERSION))
        f.write(struct.pack("<III", 4, 5, 1))
        f.write(struct.pack("<I", PACK_REL_FILEBASE))

        file_base_pos = f.tell()
        f.write(struct.pack("<Q", 0))

        dir_offset_pos = f.tell()
        f.write(struct.pack("<Q", 0))

        f.write(b"\x00" * 64)  # Reserved (16 x uint32).

        padding = pad_to(f.tell(), PACK_ALIGNMENT)
        f.write(b"\x00" * padding)
        file_base = f.tell()

        f.seek(file_base_pos)
        f.write(struct.pack("<Q", file_base))
        f.seek(file_base)

        file_entries = []
        for pack_path, full_path in files:
            padding = pad_to(f.tell(), PACK_ALIGNMENT)
            f.write(b"\x00" * padding)

            offset = f.tell()
            with open(full_path, "rb") as src:
                data = src.read()

            md5 = hashlib.md5(data).digest()
            f.write(data)
            file_entries.append((pack_path, offset - file_base, len(data), md5))
            print(f"  res://{pack_path} ({len(data)} bytes)")

        padding = pad_to(f.tell(), PACK_ALIGNMENT)
        f.write(b"\x00" * padding)
        dir_offset = f.tell()

        f.seek(dir_offset_pos)
        f.write(struct.pack("<Q", dir_offset))
        f.seek(dir_offset)

        f.write(struct.pack("<I", len(file_entries)))

        for pack_path, offset, size, md5 in file_entries:
            path_bytes = pack_path.encode("utf-8")
            path_pad = pad_to(len(path_bytes), 4)

            f.write(struct.pack("<I", len(path_bytes) + path_pad))
            f.write(path_bytes)
            f.write(b"\x00" * path_pad)
            f.write(struct.pack("<Q", offset))
            f.write(struct.pack("<Q", size))
            f.write(md5)
            f.write(struct.pack("<I", 0))

    print(f"Wrote {output_path} ({os.path.getsize(output_path)} bytes)")
    return output_path


def embed_pck(exe_path, pck_path):
    """Append a .pck to an executable so Godot can mount it at startup."""
    with open(pck_path, "rb") as src:
        pck_data = src.read()

    exe_size = os.path.getsize(exe_path)

    with open(exe_path, "ab") as f:
        padding = pad_to(exe_size, 8)
        f.write(b"\x00" * padding)

        pck_start = f.tell()
        f.write(pck_data)

        # Footer format:
        #   [embedded_pck_size: uint64] [PACK_HEADER_MAGIC: uint32]
        embedded_pck_size = f.tell() - pck_start
        f.write(struct.pack("<Q", embedded_pck_size))
        f.write(struct.pack("<I", PACK_HEADER_MAGIC))

    print(f"Embedded PCK into {exe_path} (final size: {os.path.getsize(exe_path)} bytes)")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: pack.py <project_dir> <output.pck> [--embed <executable>]")
        sys.exit(1)

    project_dir = sys.argv[1]
    pck_path = sys.argv[2]

    write_pck(project_dir, pck_path)

    if len(sys.argv) >= 5 and sys.argv[3] == "--embed":
        embed_pck(sys.argv[4], pck_path)
        os.remove(pck_path)
        print("Removed standalone .pck (embedded into exe)")
