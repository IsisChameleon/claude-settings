---
name: html-architecture-diagrams
description: Use when asked to create an architecture diagram, system/flow/orchestration visualization, or a "diagram as an HTML page / mini app" — especially when the result should look designed rather than like mermaid/excalidraw/diagram-tool output.
---

# HTML Architecture Diagrams (SVG stage + foreignObject)

## Overview

Render the whole diagram inside ONE fixed coordinate system: an SVG `viewBox` "stage". Connectors are SVG paths; node cards are rich HTML inside `<foreignObject>` at the same viewBox coordinates. Because both live in one coordinate space and the SVG has `width:100%; height:auto`, **everything — text, cards, arrows — scales together responsively with zero JS measurement**.

## When to use

- Architecture / process / orchestration diagrams delivered as a single self-contained HTML file (no build, no server, opens via `file://`).
- Multiple related diagrams → one mini-app with tabs.

**Not for:** data-driven charts (use a chart lib), auto-layout from arbitrary graph data, or user-editable diagrams.

## Core pattern — the load-bearing rules

1. **Fixed canvas.** Design on e.g. `viewBox="0 0 1240 760"`. CSS: `svg.stage { width:100%; height:auto; }`. Responsive by definition.
2. **Nodes are foreignObject.** `<foreignObject x y w h><div xmlns="http://www.w3.org/1999/xhtml" class="node">…</div></foreignObject>`. The `xmlns` is required. Font sizes in px are viewBox units → they scale with the stage.
3. **Plan coordinates first.** Write down every card's `(x, y, w, h)` (lanes/columns), THEN derive each path endpoint from card edges: right edge = `(x+w, y+h/2)`, etc. Leave ≥60px gutters for labels.
4. **Connectors are cubic béziers** with `marker-end` arrowheads. One `<marker>` per color (markers don't inherit stroke). Encode semantics: color per plane (control vs data flows), dashed vs solid.
5. **Motion sells it.** Traveling signal pulse: `<circle r="3.6" fill="…"><animateMotion dur="2s" repeatCount="indefinite" path="SAME d as the edge"/></circle>` (the path `d` is duplicated verbatim). Draw-in edges: `stroke-dasharray/-offset = --len` animated to 0. Staggered card pop-in via `animation-delay`.
   **Conflict:** draw-in and dashed-for-meaning both use `stroke-dasharray`. Edges that must STAY dashed (control plane) get an opacity **fade-in** instead of the draw-in.
6. **Edge labels** = `<text>` over a small background `<rect>`, eyeballed near the path midpoint; nudge until clear of cards/edges.
7. **Two edges between the same pair of nodes** (call + return): offset their anchor y by ±25px and bow the curves in opposite directions, or label one direction only.
8. **External / third-party systems**: give them their own color token AND a dashed card border; add to the legend.
9. **NEVER measure with JS.** No `getBoundingClientRect`, no `ResizeObserver`, no resize redraw. If an arrow detaches from a card, a coordinate is wrong — fix the number.

## Design quality bar

- Commit to a distinctive theme (e.g. dark oscilloscope lab, blueprint, editorial); define color tokens as CSS custom properties; add a legend mapping colors → meaning.
- Distinctive font pairing via Google Fonts CDN: a characterful display face + a mono for ports/labels. Never Inter/Arial/system.
- Put the *interesting* facts (bugs, fixes, gotchas, asymmetries) in highlighted boxes inside cards + a row of callout note-cards below the stage — not just boxes-and-arrows.
- Tabs for multiple views: toggle `.active`, then re-trigger animations: `el.style.animation='none'; void el.offsetWidth; el.style.animation=''`.

## Common mistakes

| Mistake | Fix |
|---|---|
| `foreignObject` div renders blank | Add `xmlns="http://www.w3.org/1999/xhtml"` to the div |
| Diagram doesn't scale | Remove width/height attrs; CSS `width:100%; height:auto` |
| All arrowheads one color | One `<marker>` def per color |
| HTML overlay positioned with % drifts from SVG paths | Don't overlay — put cards in `foreignObject` |
| Connector misses card after edit | Recompute endpoint from the card's (x,y,w,h) |
| Pulse doesn't move | `animateMotion` needs its own copy of the path `d` |
| Dashed edge turns solid after draw-in | `.draw` overrides the dash pattern — use fade-in for dashed edges |
| Stage letterboxes inside its frame | Page `max-width` must equal the viewBox width |

## Template

Copy `template.html` (this directory) and extend — it contains the stage, tokens, markers, a draw-in edge, a pulse, labeled cards, and a legend, all commented.
