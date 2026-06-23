# tt-bost-connes Lean 4 formalization

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.20674891.svg)](https://doi.org/10.5281/zenodo.20674891)
[![Companion paper DOI](https://img.shields.io/badge/Paper-10.5281%2Fzenodo.20674870-blue)](https://doi.org/10.5281/zenodo.20674870)

Companion repository to the paper:

> **Tomita–Takesaki modular theory of the Bost–Connes algebra at β = 1,
> formalized in Lean 4**
> *G Six*. math.OA submission, 2026.

This repository contains the Lean 4 formalization of the paper's structural
chain, extracted from `integers-mathlib-blueprint` at the Phase 6 sweep
commit `1ca33cb` (zero `sorry` count; eight named programme-level axioms;
six documented scaffold-layer placeholders; one Lean substrate hypothesis
`hSubstrate_iii` for Theorem C — see Open Problem 9.1 of the paper).

## Build

```bash
elan default leanprover/lean4:v4.29.1
lake update
lake build TomitaTakesaki.Assembly      # full chain L1 → L7 + Theorem A–E
lake build TomitaTakesaki.TomitaS       # §4.1, §4.3 (Tomita S + modular data)
lake build TomitaTakesaki.Antilinear    # §4 antilinear-operator substrate
```

Toolchain: Lean 4 v4.29.1. Mathlib pinned at
`5e932f97dd25535344f80f9dd8da3aab83df0fe6`.

## Module structure

| Module | Paper §  | Content |
|---|---|---|
| `TomitaTakesaki/Basic.lean` | §§2–7 typing | Core types: `BostConnesSystem`, `GNSTriple`, `TypeIII1FactorWitness`, `ModularPair`, etc. |
| `L1BostConnesAlgebra.lean` | §§2.1–2.4 | Bost–Connes system with KMS₁ state, ITPFI factorization, KMS condition |
| `L2GNSCyclicSeparating.lean` | §3 | GNS triple, cyclic separating Ω₁, type III₁ factor identification |
| `L3PolarDecomposition.lean` | §4.3 | Polar decomposition S̄ = J · Δ^{1/2} |
| `Antilinear.lean` | §4 substrate | Project-local antilinear-operator + polar-decomposition theory (Mathlib upstream candidate) |
| `TomitaS.lean` | §§4.1, 4.3 | Tomita S operator + modular data via polar decomposition |
| `L4ModularFlow.lean` | §5 | Modular flow theorem σ_t = α_t (unconditional via [BR97, Thm. 5.3.10]) |
| `L5GaloisAction.lean` | §6 | Galois action and compatibility with the modular conjugation |
| `L6MainTheorem.lean` | §§3–6 | Four-clause main theorem composing L1–L5 |
| `L7SpectralRealization.lean` | §7 | Spectral realization data D_∞ = log Δ |
| `Assembly.lean` | (composition) | Full chain L1 → L7 + downstream bridges |

## Verification

```bash
# zero code-level sorries:
grep -rE "^[[:space:]]*sorry|:= sorry" TomitaTakesaki/*.lean
# → no output

# eight named axioms:
grep -hE "^axiom " TomitaTakesaki/*.lean | wc -l
# → 8
```

The eight named axioms and the six scaffold-layer placeholders are
inventoried in §§8.2 and §8.3 of the paper, each with a stated discharge
route.

## License

CC-BY-4.0. See `LICENSE`.

## Provenance

Extracted from `integers-mathlib-blueprint-tt-impl` at commit `1ca33cb`
(Phase 6 sorry-sweep, 2026). The full programme blueprint with additional
substrate, including Phase 7 RH-bridge files (`Galerkin.lean`,
`RHWitness.lean`), is maintained at the programme's blueprint repository.
This extraction is the canonical state cited in Appendix A of the paper.

During the preparation of this work, the author used Claude Opus 4.7. The author reviewed all content and takes full responsibility for the formalization.
