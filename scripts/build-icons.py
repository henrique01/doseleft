#!/usr/bin/env python3
"""
Generate raster fallback AppIcon-1024.png from AppIcon.icon/.

The primary app icon on iOS 26+ / watchOS 26+ is the Apple Icon Composer
document at `AppIcon.icon/`, which Xcode hands directly to the OS so it can
render the Liquid Glass material at runtime. This script exists to produce
a flat-raster fallback for users on iOS 17–25 and watchOS 10–25, which
don't support the .icon format.

It reads `icon.json` and the SVG layers in `Assets/`, rasterises them, and
writes a 1024×1024 PNG to each of:

  - App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
  - Watch/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png

Xcode prefers `.icon` when running on iOS/watchOS 26+ and falls back to
the `.appiconset` PNG on older OSes.

Run from the repo root: `python3 scripts/build-icons.py`.
Wired as a pre-build phase on both DoseLeft and DoseWatch in project.yml.
"""
from __future__ import annotations

import ctypes
import ctypes.util
import json
import os
import re
import sys
from pathlib import Path


def _ensure_cairo_on_path() -> None:
    """cairocffi calls `dlopen("libcairo.2.dylib")` which only searches dyld
    defaults — that misses Homebrew's prefix (/opt/homebrew/lib on Apple
    Silicon, /usr/local/lib on Intel). DYLD env vars are read at exec time,
    so if cairo isn't already discoverable we re-exec ourselves with
    DYLD_FALLBACK_LIBRARY_PATH set to the brew lib dir.
    """
    if ctypes.util.find_library("cairo"):
        return

    brew_libs = [d for d in ("/opt/homebrew/lib", "/usr/local/lib")
                 if os.path.exists(os.path.join(d, "libcairo.2.dylib"))]
    if not brew_libs:
        return  # let cairosvg's import raise the original error

    if os.environ.get("_BUILD_ICONS_CAIRO_RELOAD") == "1":
        return  # already re-execed, don't loop

    env = os.environ.copy()
    existing = env.get("DYLD_FALLBACK_LIBRARY_PATH", "")
    paths = brew_libs + ([existing] if existing else [])
    env["DYLD_FALLBACK_LIBRARY_PATH"] = ":".join(paths)
    env["_BUILD_ICONS_CAIRO_RELOAD"] = "1"
    os.execvpe(sys.executable, [sys.executable, *sys.argv], env)


_ensure_cairo_on_path()

try:
    import cairosvg
except ImportError:
    sys.stderr.write(
        "error: cairosvg is required.\n"
        "  pip3 install -r scripts/requirements.txt\n"
        "  (cairosvg needs the Cairo native lib: `brew install cairo`)\n"
    )
    sys.exit(1)

try:
    from PIL import Image
except ImportError:
    sys.stderr.write("error: Pillow is required. pip3 install -r scripts/requirements.txt\n")
    sys.exit(1)


ROOT = Path(__file__).resolve().parent.parent
ICON_DIR = ROOT / "AppIcon.icon"
ICON_JSON = ICON_DIR / "icon.json"
ASSETS_DIR = ICON_DIR / "Assets"

APPICON_OUTS_BY_TARGET = {
    "ios":   [ROOT / "App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"],
    "watch": [ROOT / "Watch/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"],
}

# Brand tokens (mirror DL.Light in DoseCore/DesignSystem/DLTokens.swift).
BG_HEX = "#FAFAF7"

ICON_PX = 1024


def _hex_to_rgb(h: str) -> tuple[int, int, int]:
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


def _displayp3_to_rgb(spec: str) -> tuple[int, int, int]:
    """Parse `display-p3:r,g,b,a` (and `extended-gray:v,a`) as sRGB.

    This is a coarse passthrough — Display P3 has a wider gamut, but our two
    layer colours (dusty blue + light grey) sit well inside sRGB so the
    approximation is visually faithful.
    """
    prefix, rest = spec.split(":", 1)
    parts = [float(x) for x in rest.split(",")]
    if prefix == "extended-gray":
        v = max(0.0, min(1.0, parts[0]))
        return (int(v * 255), int(v * 255), int(v * 255))
    r, g, b = parts[0], parts[1], parts[2]
    return (
        int(max(0.0, min(1.0, r)) * 255),
        int(max(0.0, min(1.0, g)) * 255),
        int(max(0.0, min(1.0, b)) * 255),
    )


def _rasterise_svg_layer(svg_path: Path, fill_rgb: tuple[int, int, int], size: int) -> Image.Image:
    """Load the SVG, override every `fill="..."` attribute with the layer
    colour from icon.json, then rasterise at the target square size."""
    svg = svg_path.read_text()
    hex_fill = "#{:02X}{:02X}{:02X}".format(*fill_rgb)
    # Override hex fills only — preserve `fill-rule`, `fill-opacity`, etc.
    svg = re.sub(r'fill="#[0-9A-Fa-f]{3,8}"', f'fill="{hex_fill}"', svg)
    png_bytes = cairosvg.svg2png(
        bytestring=svg.encode("utf-8"),
        output_width=size,
        output_height=size,
    )
    return Image.open(__import__("io").BytesIO(png_bytes)).convert("RGBA")


def _composite_icon() -> Image.Image:
    manifest = json.loads(ICON_JSON.read_text())

    # Flat brand background — icon.json's automatic-gradient is essentially
    # flat off-white, so we use the brand token directly for parity with
    # DL.Light.bg.
    base = Image.new("RGBA", (ICON_PX, ICON_PX), _hex_to_rgb(BG_HEX) + (255,))

    for group in manifest.get("groups", []):
        for layer in group.get("layers", []):
            image_name = layer.get("image-name")
            if not image_name:
                continue
            svg_path = ASSETS_DIR / image_name
            if not svg_path.exists():
                sys.stderr.write(f"error: missing layer asset {svg_path}\n")
                sys.exit(1)

            fill = layer.get("fill", {})
            if "solid" in fill:
                rgb = _displayp3_to_rgb(fill["solid"])
            elif "linear-gradient" in fill:
                # Single-fill rasteriser: average the stops so the PNG tracks
                # palette edits to icon.json without code changes.
                stops = [_displayp3_to_rgb(s) for s in fill["linear-gradient"]]
                rgb = tuple(sum(c) // len(stops) for c in zip(*stops))  # type: ignore[assignment]
            else:
                rgb = _hex_to_rgb("#A78BD5")  # lavender fallback

            layer_img = _rasterise_svg_layer(svg_path, rgb, ICON_PX)

            opacity = float(layer.get("opacity", 1.0))
            if opacity < 1.0:
                alpha = layer_img.split()[3].point(lambda a: int(a * opacity))
                layer_img.putalpha(alpha)

            base = Image.alpha_composite(base, layer_img)

    return base


def _is_up_to_date(inputs: list[Path], outputs: list[Path]) -> bool:
    if not all(p.exists() for p in outputs):
        return False
    newest_in = max(p.stat().st_mtime for p in inputs)
    oldest_out = min(p.stat().st_mtime for p in outputs)
    return oldest_out >= newest_in


def main() -> int:
    # Optional target arg: `ios`, `watch`, or omitted (= both). Each Xcode
    # prebuild phase passes its own platform so the two scripts don't claim
    # the same output file — that would be a duplicate-producer error.
    target = sys.argv[1] if len(sys.argv) > 1 else None
    if target and target not in APPICON_OUTS_BY_TARGET:
        sys.stderr.write(f"error: unknown target '{target}' (expected: ios | watch)\n")
        return 2

    outputs = (
        APPICON_OUTS_BY_TARGET[target]
        if target
        else [p for paths in APPICON_OUTS_BY_TARGET.values() for p in paths]
    )
    inputs = [ICON_JSON, *sorted(ASSETS_DIR.glob("*.svg")), Path(__file__)]

    if _is_up_to_date(inputs, outputs):
        print("build-icons: up to date, skipping")
        return 0

    icon = _composite_icon()
    for out in outputs:
        out.parent.mkdir(parents=True, exist_ok=True)
        icon.save(out, "PNG")
        print(f"build-icons: wrote {out.relative_to(ROOT)}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
