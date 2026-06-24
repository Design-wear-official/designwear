#!/usr/bin/env python3
"""Generate a curved 'inflated garment' GLB for the Design Studio 3D preview.

The mesh is two curved panels (front bulge +Z, back bulge -Z) meeting at a
rounded torso-proportioned rim. The front faces map to the LEFT half of the
texture atlas (UV.x 0..0.5) and the back faces to the RIGHT half (0.5..1.0),
so a [front | back] atlas displays correctly when rotated.

At runtime the app swaps the embedded placeholder texture for the user's
captured design via model-viewer's scene-graph API. Output is a complete,
self-contained .glb (single buffer, embedded placeholder texture).
"""
import json
import math
import struct
import zlib
from pathlib import Path

N = 24          # subdivisions across width (u)
M = 32          # subdivisions down height (v)
W = 0.85        # panel width
H = 1.0         # panel height
D = 0.16        # bulge depth


def bulge(u: float, v: float) -> float:
    return D * math.sin(math.pi * u) * math.sin(math.pi * v)


def build_surface(sign: float, uv_x0: float):
    """One curved panel. sign +1 = front (+Z), -1 = back (-Z)."""
    verts = []  # (px,py,pz, nx,ny,nz, u,v)
    for j in range(M + 1):
        v = j / M
        for i in range(N + 1):
            u = i / N
            x = (u - 0.5) * W
            y = (0.5 - v) * H
            z = sign * bulge(u, v)
            # analytic normal from tangents dP/du x dP/dv
            zu = sign * D * math.pi * math.cos(math.pi * u) * math.sin(math.pi * v)
            zv = sign * D * math.pi * math.sin(math.pi * u) * math.cos(math.pi * v)
            # dPu = (W,0,zu); dPv = (0,-H,zv)
            nx = 0 * zv - zu * (-H)
            ny = zu * 0 - W * zv
            nz = W * (-H) - 0
            # orient outward: front -> +Z, back -> -Z
            if (sign > 0 and nz < 0) or (sign < 0 and nz > 0):
                nx, ny, nz = -nx, -ny, -nz
            ln = math.sqrt(nx * nx + ny * ny + nz * nz) or 1.0
            nx, ny, nz = nx / ln, ny / ln, nz / ln
            tu = uv_x0 + u * 0.5
            verts.append((x, y, z, nx, ny, nz, tu, v))

    idx = []
    stride = N + 1
    for j in range(M):
        for i in range(N):
            a = j * stride + i
            b = a + 1
            c = a + stride
            d = c + 1
            if sign > 0:  # CCW from +Z
                idx += [a, c, b, b, c, d]
            else:         # reverse winding for back
                idx += [a, b, c, b, d, c]
    return verts, idx


def main():
    fv, fi = build_surface(+1.0, 0.0)
    bv, bi = build_surface(-1.0, 0.5)
    base = len(fv)
    verts = fv + bv
    idx = fi + [i + base for i in bi]

    # Pack interleaved? Keep separate blocks: pos | nor | uv | indices
    pos = b"".join(struct.pack("<3f", v[0], v[1], v[2]) for v in verts)
    nor = b"".join(struct.pack("<3f", v[3], v[4], v[5]) for v in verts)
    uv = b"".join(struct.pack("<2f", v[6], v[7]) for v in verts)
    ind = b"".join(struct.pack("<H", i) for i in idx)

    def pad4(b: bytes) -> bytes:
        return b + b"\x00" * ((4 - len(b) % 4) % 4)

    pos, nor, uv, ind = pad4(pos), pad4(nor), pad4(uv), pad4(ind)

    # Placeholder texture: 4x4 light grey PNG.
    png = make_png(4, 4, (210, 210, 210))
    png_p = pad4(png)

    blob = pos + nor + uv + ind + png_p
    o_pos, o_nor = 0, len(pos)
    o_uv = o_nor + len(nor)
    o_ind = o_uv + len(uv)
    o_png = o_ind + len(ind)

    xs = [v[0] for v in verts]
    ys = [v[1] for v in verts]
    zs = [v[2] for v in verts]

    gltf = {
        "asset": {"version": "2.0", "generator": "designwear-tshirt-gen"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"mesh": 0, "name": "Garment"}],
        "meshes": [{
            "name": "Garment",
            "primitives": [{
                "attributes": {"POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2},
                "indices": 3,
                "material": 0,
            }],
        }],
        "materials": [{
            "name": "GarmentMat",
            "doubleSided": True,
            "pbrMetallicRoughness": {
                "baseColorTexture": {"index": 0},
                "metallicFactor": 0.0,
                "roughnessFactor": 0.85,
            },
        }],
        "textures": [{"source": 0, "sampler": 0}],
        "images": [{"bufferView": 4, "mimeType": "image/png"}],
        "samplers": [{"magFilter": 9729, "minFilter": 9987, "wrapS": 33071, "wrapT": 33071}],
        "accessors": [
            {"bufferView": 0, "componentType": 5126, "count": len(verts),
             "type": "VEC3", "min": [min(xs), min(ys), min(zs)],
             "max": [max(xs), max(ys), max(zs)]},
            {"bufferView": 1, "componentType": 5126, "count": len(verts), "type": "VEC3"},
            {"bufferView": 2, "componentType": 5126, "count": len(verts), "type": "VEC2"},
            {"bufferView": 3, "componentType": 5123, "count": len(idx), "type": "SCALAR"},
        ],
        "bufferViews": [
            {"buffer": 0, "byteOffset": o_pos, "byteLength": len(pos), "target": 34962},
            {"buffer": 0, "byteOffset": o_nor, "byteLength": len(nor), "target": 34962},
            {"buffer": 0, "byteOffset": o_uv, "byteLength": len(uv), "target": 34962},
            {"buffer": 0, "byteOffset": o_ind, "byteLength": len(ind), "target": 34963},
            {"buffer": 0, "byteOffset": o_png, "byteLength": len(png)},
        ],
        "buffers": [{"byteLength": len(blob)}],
    }

    models = Path(__file__).resolve().parent.parent / "assets" / "models"
    models.mkdir(parents=True, exist_ok=True)
    out = models / "tshirt_panel.glb"
    write_glb(out, gltf, blob)

    # Geometry-only buffer (pos|nor|uv|ind, no texture) for runtime atlas baking.
    geom = pos + nor + uv + ind
    (models / "tshirt_mesh.bin").write_bytes(geom)

    print(f"wrote {out} ({out.stat().st_size} bytes, {len(verts)} verts, {len(idx)} idx)")
    print("--- Dart metadata (paste into Garment3DModel) ---")
    print(f"vertexCount = {len(verts)}")
    print(f"indexCount  = {len(idx)}")
    print(f"oPos={o_pos} oNor={o_nor} oUv={o_uv} oInd={o_ind} geomLen={len(geom)}")
    print(f"posMin = {[min(xs), min(ys), min(zs)]}")
    print(f"posMax = {[max(xs), max(ys), max(zs)]}")


def make_png(w: int, h: int, rgb) -> bytes:
    raw = b""
    row = b"\x00" + bytes(rgb) * w
    raw = row * h

    def chunk(typ: bytes, data: bytes) -> bytes:
        c = typ + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)

    sig = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)
    return sig + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")


def write_glb(path: Path, gltf: dict, bin_blob: bytes):
    json_bytes = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
    json_bytes += b" " * ((4 - len(json_bytes) % 4) % 4)
    bin_blob += b"\x00" * ((4 - len(bin_blob) % 4) % 4)
    total = 12 + 8 + len(json_bytes) + 8 + len(bin_blob)
    with open(path, "wb") as f:
        f.write(b"glTF")
        f.write(struct.pack("<II", 2, total))
        f.write(struct.pack("<I", len(json_bytes)))
        f.write(b"JSON")
        f.write(json_bytes)
        f.write(struct.pack("<I", len(bin_blob)))
        f.write(b"BIN\x00")
        f.write(bin_blob)


if __name__ == "__main__":
    main()
