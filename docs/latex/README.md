# DesignWear — LaTeX / TikZ Architecture

`DesignWear-Architecture.tex` is a deep, self-contained technical architecture
document with **9 TikZ diagrams** covering the whole platform:

1. System context (client · API · stores · external services)
2. Flutter clean-architecture layers
3. Backend REST surface (grouped routes)
4. Garment templates vs. products (1 → many)
5. Catalogue sync (Sanity → Firestore)
6. Studio publish (`publish-remix`)
7. Inventory pipeline (mirror + audit + adjust)
8. MCP wiring (Claude → Sanity + Firebase)
9. Deployment topology

Plus chapters on the data model (all 13 Sanity schemas + 7 Firestore collections),
the two-product-type model, operational gotchas, and an endpoint quick-reference.

## Compile

No TeX toolchain is installed on this machine. Pick one:

### Option A — Overleaf (no install)
Upload `DesignWear-Architecture.tex` to <https://overleaf.com>, set the compiler to
**pdfLaTeX**, and click *Recompile*. Done.

### Option B — Local (MiKTeX on Windows, or TeX Live)
```bash
# install MiKTeX: https://miktex.org/download   (or TeX Live)
pdflatex DesignWear-Architecture.tex
pdflatex DesignWear-Architecture.tex   # run twice: table of contents + cross-refs
```

### Option C — Tectonic (single binary, auto-fetches packages)
```bash
# winget install TectonicProject.Tectonic   (or scoop/cargo)
tectonic DesignWear-Architecture.tex
```

## Required packages
All standard and present in any full TeX distribution / auto-fetched by Tectonic:
`tikz` (libraries: positioning, arrows.meta, shapes.geometric, fit, backgrounds, calc),
`listings`, `xcolor`, `hyperref`, `enumitem`, `booktabs`, `array`, `longtable`,
`fancyhdr`, `geometry`.

> Run the compiler **twice** so the table of contents and figure/section
> cross-references resolve.
