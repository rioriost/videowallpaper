#!/usr/bin/env python3
from __future__ import annotations

import argparse
import math
import os
import random
import struct
import subprocess
import zlib
from pathlib import Path

import numpy as np


TWO_PI = math.tau


def fract(v: np.ndarray | float) -> np.ndarray | float:
    return v - np.floor(v)


def hsv_to_rgb_np(h: np.ndarray, s: float, v: float) -> np.ndarray:
    h = np.mod(h, 360.0) / 60.0
    c = v * s
    x = c * (1.0 - np.abs(np.mod(h, 2.0) - 1.0))
    z = np.zeros_like(h)

    rgb = np.empty((h.size, 3), dtype=np.float32)
    masks = [
        (0 <= h) & (h < 1),
        (1 <= h) & (h < 2),
        (2 <= h) & (h < 3),
        (3 <= h) & (h < 4),
        (4 <= h) & (h < 5),
        (5 <= h) & (h < 6),
    ]
    vals = [
        (c + z, x, z),
        (x, c + z, z),
        (z, c + z, x),
        (z, x, c + z),
        (x, z, c + z),
        (c + z, z, x),
    ]
    for mask, channels in zip(masks, vals):
        if np.any(mask):
            rgb[mask, 0] = channels[0][mask]
            rgb[mask, 1] = channels[1][mask]
            rgb[mask, 2] = channels[2][mask]
    return rgb


def hsv_to_rgb_scalar(h: float, s: float, v: float) -> np.ndarray:
    return hsv_to_rgb_np(np.array([h], dtype=np.float32), s, v)[0]


def png_chunk(tag: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


def write_png_rgb(path: Path, image: np.ndarray) -> None:
    height, width, channels = image.shape
    if channels != 3:
        raise ValueError("write_png_rgb expects an RGB image")

    rows = b"".join(
        b"\x00" + np.ascontiguousarray(image[y]).tobytes() for y in range(height)
    )
    data = b"".join(
        [
            b"\x89PNG\r\n\x1a\n",
            png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)),
            png_chunk(b"IDAT", zlib.compress(rows, level=3)),
            png_chunk(b"IEND", b""),
        ]
    )
    path.write_bytes(data)


def gaussian_kernel(radius: int, sigma: float) -> np.ndarray:
    coords = np.arange(-radius, radius + 1, dtype=np.float32)
    xx, yy = np.meshgrid(coords, coords)
    kernel = np.exp(-(xx * xx + yy * yy) / (2.0 * sigma * sigma))
    return kernel.astype(np.float32)


class Renderer:
    def __init__(
        self,
        width: int,
        height: int,
        total_frames: int,
        bands: int,
        seed: float,
        fade_alpha: float,
        points_per_band: int,
        particle_count: int,
        line_step: float,
    ) -> None:
        self.width = width
        self.height = height
        self.cx = width * 0.5
        self.cy = height * 0.5
        self.total_frames = total_frames
        self.bands = bands
        self.seed = seed
        self.fade_alpha = fade_alpha
        self.points_per_band = points_per_band
        self.particle_count = particle_count
        self.line_step = line_step
        self.canvas = np.zeros((height, width, 3), dtype=np.float32)
        self.line_kernels: dict[int, np.ndarray] = {}
        self.particle_kernel = gaussian_kernel(1, 0.72)

        self.particle_ids = np.arange(particle_count, dtype=np.float32)
        self.particle_noise = fract(np.sin(self.particle_ids * 12.9898) * 43758.5453)

    def kernel_for_weight(self, stroke_weight: float) -> np.ndarray:
        radius = max(1, int(math.ceil(stroke_weight * 0.85)))
        if radius not in self.line_kernels:
            self.line_kernels[radius] = gaussian_kernel(radius, max(0.8, stroke_weight * 0.55))
        return self.line_kernels[radius]

    def add_kernel(self, x: float, y: float, color: np.ndarray, alpha: float, kernel: np.ndarray) -> None:
        ix = int(round(x))
        iy = int(round(y))
        radius = kernel.shape[0] // 2
        x0 = max(0, ix - radius)
        x1 = min(self.width, ix + radius + 1)
        y0 = max(0, iy - radius)
        y1 = min(self.height, iy + radius + 1)
        if x0 >= x1 or y0 >= y1:
            return

        kx0 = x0 - (ix - radius)
        ky0 = y0 - (iy - radius)
        k = kernel[ky0 : ky0 + (y1 - y0), kx0 : kx0 + (x1 - x0)]
        self.canvas[y0:y1, x0:x1, :] += k[:, :, None] * color[None, None, :] * alpha

    def draw_polyline(self, xs: np.ndarray, ys: np.ndarray, color: np.ndarray, weight: float, alpha: float) -> None:
        kernel = self.kernel_for_weight(weight)
        count = len(xs)
        for i in range(count):
            j = 0 if i + 1 == count else i + 1
            x0 = xs[i]
            y0 = ys[i]
            x1 = xs[j]
            y1 = ys[j]
            distance = math.hypot(float(x1 - x0), float(y1 - y0))
            samples = max(1, int(math.ceil(distance / self.line_step)))
            for t in range(samples):
                u = t / samples
                self.add_kernel(
                    float(x0 + (x1 - x0) * u),
                    float(y0 + (y1 - y0) * u),
                    color,
                    alpha,
                    kernel,
                )

    def render_frame(self, frame_index: int) -> np.ndarray:
        phase = TWO_PI * frame_index / float(self.total_frames)
        self.canvas *= 1.0 - self.fade_alpha

        a = np.linspace(0.0, TWO_PI, self.points_per_band, endpoint=False, dtype=np.float32)

        for b in range(self.bands):
            hue = (210.0 + b * 18.0 + 40.0 * math.sin(phase + b)) % 360.0
            color = hsv_to_rgb_scalar(hue, 0.90, 1.00)
            weight = 2.0 + b * 0.35

            n1 = np.sin(a * 3.0 + phase * 2.0 + b + self.seed)
            n2 = np.sin(a * 7.0 - phase * 3.0 + b * 1.7)
            n3 = np.cos(a * 11.0 + phase + b * 2.3)
            base = 260.0 + b * 75.0
            amp = 120.0 + 60.0 * math.sin(phase + b)
            r = base + amp * n1 + 65.0 * n2 + 35.0 * n3

            xs = self.cx + np.cos(a + 0.22 * math.sin(phase + b)) * r
            ys = self.cy + np.sin(a + 0.22 * math.cos(phase + b)) * r
            self.draw_polyline(xs, ys, color, weight, 0.18)

        ids = self.particle_ids
        pa = TWO_PI * fract(ids * 0.017 + frame_index / float(self.total_frames))
        ring = 220.0 + 820.0 * self.particle_noise
        wobble = 80.0 * np.sin(phase * 2.0 + ids * 0.13)
        pr = ring + wobble
        px = self.cx + np.cos(pa * 1.7 + phase + ids) * pr
        py = self.cy + np.sin(pa * 1.3 - phase + ids * 0.7) * pr
        hues = (190.0 + 90.0 * np.sin(phase + ids * 0.01)) % 360.0
        colors = hsv_to_rgb_np(hues.astype(np.float32), 0.80, 1.00)

        for x, y, color in zip(px, py, colors):
            self.add_kernel(float(x), float(y), color, 0.22, self.particle_kernel)

        return np.clip(self.canvas * 255.0, 0.0, 255.0).astype(np.uint8)


def make_video(frames_dir: Path, output: Path, fps: int, crf: int) -> None:
    command = [
        "ffmpeg",
        "-y",
        "-framerate",
        str(fps),
        "-start_number",
        "1",
        "-i",
        str(frames_dir / "frame-%06d.png"),
        "-c:v",
        "libx264",
        "-pix_fmt",
        "yuv420p",
        "-crf",
        str(crf),
        "-r",
        str(fps),
        str(output),
    ]
    subprocess.run(command, check=True)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Render the supplied Processing loop as PNG frames and optionally encode it with ffmpeg."
    )
    parser.add_argument("--width", type=int, default=1920)
    parser.add_argument("--height", type=int, default=1080)
    parser.add_argument("--fps", type=int, default=30)
    parser.add_argument("--seconds", type=int, default=10)
    parser.add_argument("--bands", type=int, default=9)
    parser.add_argument("--seed", type=float, default=None)
    parser.add_argument("--frames-dir", type=Path, default=Path("frames"))
    parser.add_argument("--output", type=Path, default=Path("processing-loop.mp4"))
    parser.add_argument("--make-video", action="store_true")
    parser.add_argument("--clean", action="store_true", help="Delete old frame-*.png files before rendering.")
    parser.add_argument("--crf", type=int, default=18)
    parser.add_argument(
        "--warmup-loops",
        type=float,
        default=1.0,
        help="Render this many unsaved loops first so frame 1 already contains trail history.",
    )
    parser.add_argument("--points-per-band", type=int, default=720)
    parser.add_argument("--particle-count", type=int, default=2200)
    parser.add_argument(
        "--line-step",
        type=float,
        default=1.7,
        help="Lower values draw denser, smoother lines and take longer.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    total_frames = args.fps * args.seconds
    seed = args.seed if args.seed is not None else random.random() * 10000.0
    args.frames_dir.mkdir(parents=True, exist_ok=True)

    if args.clean:
        for frame in args.frames_dir.glob("frame-*.png"):
            frame.unlink()

    renderer = Renderer(
        width=args.width,
        height=args.height,
        total_frames=total_frames,
        bands=args.bands,
        seed=seed,
        fade_alpha=0.18,
        points_per_band=args.points_per_band,
        particle_count=args.particle_count,
        line_step=args.line_step,
    )

    print(f"seed={seed:.6f}")
    warmup_frames = int(round(total_frames * args.warmup_loops))
    if warmup_frames > 0:
        print(f"warming up {warmup_frames} unsaved frames")
        for frame_index in range(-warmup_frames, 0):
            renderer.render_frame(frame_index)
            current = frame_index + warmup_frames + 1
            print(f"{current:04d}/{warmup_frames}", end="\r", flush=True)
        print()

    print(f"rendering {total_frames} frames to {args.frames_dir}")
    for frame_index in range(total_frames):
        image = renderer.render_frame(frame_index)
        write_png_rgb(args.frames_dir / f"frame-{frame_index + 1:06d}.png", image)
        print(f"{frame_index + 1:04d}/{total_frames}", end="\r", flush=True)
    print()

    if args.make_video:
        print(f"encoding {args.output}")
        make_video(args.frames_dir, args.output, args.fps, args.crf)


if __name__ == "__main__":
    os.environ.setdefault("PYTHONUNBUFFERED", "1")
    main()
