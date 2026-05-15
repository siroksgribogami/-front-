"""
Decompress Unity WebGL Brotli outputs for local `flutter run -d chrome`.

Flutter's dev server does not send Content-Encoding: br for .br files, so Unity
cannot load compressed assets. Run this after each Unity WebGL build that only
produces *.br files:

  py -3 tool/decompress_unity_webgl_build.py

Requires: pip install brotli
"""
from __future__ import annotations

import sys
from pathlib import Path

try:
    import brotli
except ImportError:
    print("Install brotli: py -3 -m pip install brotli", file=sys.stderr)
    sys.exit(1)


def main() -> None:
    root = Path(__file__).resolve().parent.parent
    build_dir = root / "web" / "UnityBuild" / "Build"
    pairs = [
        ("UnityBuild.data.br", "UnityBuild.data"),
        ("UnityBuild.framework.js.br", "UnityBuild.framework.js"),
        ("UnityBuild.wasm.br", "UnityBuild.wasm"),
    ]

    for src_name, dst_name in pairs:
        src = build_dir / src_name
        dst = build_dir / dst_name
        if not src.is_file():
            print(f"skip (missing): {src}")
            continue
        if dst.is_file() and dst.stat().st_mtime >= src.stat().st_mtime:
            print(f"skip (up to date): {dst_name}")
            continue
        print(f"decompressing {src_name} -> {dst_name} ...")
        raw = brotli.decompress(src.read_bytes())
        dst.write_bytes(raw)
        print(f"  wrote {len(raw):,} bytes")


if __name__ == "__main__":
    main()
