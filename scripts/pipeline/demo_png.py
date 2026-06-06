"""デモ用合成 PNG 生成ユーティリティ (stdlib のみ)。"""

from __future__ import annotations

import hashlib
import struct
import zlib
from pathlib import Path


def write_gray_png(path: Path, width: int, height: int, pixels: list[int]) -> None:
    assert len(pixels) == width * height
    path.parent.mkdir(parents=True, exist_ok=True)
    raw = b"".join(
        b"\x00" + bytes(pixels[y * width : (y + 1) * width]) for y in range(height)
    )
    compressed = zlib.compress(raw, 9)

    def chunk(tag: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + tag
            + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 0, 0, 0, 0)
    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", ihdr)
        + chunk(b"IDAT", compressed)
        + chunk(b"IEND", b"")
    )
    path.write_bytes(png)


def write_rgb_png(
    path: Path, width: int, height: int, pixels: list[tuple[int, int, int]]
) -> None:
    assert len(pixels) == width * height
    path.parent.mkdir(parents=True, exist_ok=True)
    rows = []
    for y in range(height):
        row = bytearray([0])
        for x in range(width):
            r, g, b = pixels[y * width + x]
            row.extend((r, g, b))
        rows.append(bytes(row))
    raw = b"".join(rows)
    compressed = zlib.compress(raw, 9)

    def chunk(tag: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + tag
            + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", ihdr)
        + chunk(b"IDAT", compressed)
        + chunk(b"IEND", b"")
    )
    path.write_bytes(png)


def _digest_indices(x: int, y: int, length: int) -> tuple[int, int]:
    """Mix (x, y) so width multiples of digest length do not create vertical banding."""
    mixed = (x * 0x9E3779B1) ^ (y * 0x85EBCA6B) ^ ((x * y) & 0xFFFF)
    return mixed % length, (mixed * 13 + 7) % length


def make_sar_pixels(
    seed: str, width: int = 320, height: int = 200, *, coarse: bool = False
) -> list[int]:
    digest = hashlib.sha256(seed.encode()).digest()
    pixels: list[int] = []
    step = 12 if coarse else 4
    for y in range(height):
        for x in range(width):
            a, b = _digest_indices(x, y, len(digest))
            base = digest[a] ^ digest[b]
            base = (base * 3 + (x ^ y)) % 220 + 18
            if coarse and (x // step + y // step) % 3 == 0:
                base = min(255, base + 35)
            if (x + y) % 23 == 0:
                base = max(0, base - 30)
            pixels.append(base)
    return pixels


def make_disaster_phase_pixels(
    event_id: str, phase: str, width: int = 320, height: int = 200
) -> list[int]:
    """SAR-like speckle with phase-specific brightness tweaks for disaster archive."""
    pixels = make_sar_pixels(event_id, width, height)
    if phase == "during":
        for y in range(height // 4, 3 * height // 4):
            for x in range(width):
                i = y * width + x
                a, _ = _digest_indices(x, y, 32)
                pixels[i] = min(255, pixels[i] + 55 + (a % 40))
    elif phase == "after":
        for y in range(height):
            for x in range(width):
                i = y * width + x
                if (x + y) % 17 == 0:
                    pixels[i] = max(0, pixels[i] - 45)
                pixels[i] = min(255, pixels[i] + 12)
    return pixels


def make_optical_pixels(
    seed: str, width: int = 320, height: int = 200
) -> list[tuple[int, int, int]]:
    digest = hashlib.sha256(f"optical:{seed}".encode()).digest()
    pixels: list[tuple[int, int, int]] = []
    for y in range(height):
        for x in range(width):
            a, b = _digest_indices(x, y, len(digest))
            c = (a * 5 + b * 11) % len(digest)
            r = (digest[a] + x) % 200 + 30
            g = (digest[b] + y) % 180 + 40
            b_val = (digest[c] + x + y) % 160 + 50
            if y > height * 0.55:
                g = min(255, g + 25)
                b_val = min(255, b_val + 15)
            pixels.append((r, g, b_val))
    return pixels
