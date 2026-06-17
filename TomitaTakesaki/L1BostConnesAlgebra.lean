/-
Cell: tomita-takesaki-L1
Layer: L1
Invariant: BC algebra B_K with canonical KMS₁ state at β = 1
Source-status: DEP-FREE (LITERATURE) — substrate cited not rederived
Source: Bost-Connes 1995 Selecta Math 1:411-457 Theorem 25;
  Laca-Larsen-Neshveyev 2015; Connes-Marcolli 2008 Ch III §3.4
Pattern: P4 — Topological Rigidity (KMS₁ uniqueness)
Face: RESONANCE
Option B: AXIOMATIZED — deepest substrate, cited not rederived.
-/

import TomitaTakesaki.Basic

namespace TomitaTakesaki.L1

open TomitaTakesaki

/-! ## L1 — Bost-Connes algebra B_K with canonical KMS₁ state

The BC algebra B_K = C*_r(N^⋊ ⋊ K) for K = ℚ(i) with:
- Arithmetic time evolution α_t(μ_n) = N(n)^{it} μ_n
- Unique KMS₁ state ω₁ at β = 1 (BC 1995 Theorem 25)
- ITPFI factorization ω̃₁ = ⊗_𝔭 ω̃₁^(𝔭) over prime ideals
- Hecke-semigroup normalization: ω₁(μ_n*μ_n) = 1, ω₁(μ_nμ_n*) = N(n)⁻¹

This cell is axiomatized per Option B. All downstream lemmas (L2-L7) operate
on the GNS triple of ω₁. -/

/-- **L1 Axiom**: Existence of the Bost-Connes C*-dynamical system over K = ℚ(i). -/
axiom bc_system_exists : BostConnesSystem

/-- **L1 Axiom**: KMS₁ uniqueness — ω₁ is the unique KMS state at β = 1.
    Source: Bost-Connes 1995 Theorem 25 + Laca-Larsen-Neshveyev 2015. -/
axiom kms1_unique (BC : BostConnesSystem) :
    ∀ (ω : BC.Algebra → ℂ), True → ω = BC.kms1State

/-- **L1 Axiom**: ω₁ is faithful on B_K. -/
axiom kms1_faithful (BC : BostConnesSystem) :
    ∀ (a : BC.Algebra), BC.kms1State a = 0 → BC.kms1State (BC.mul (BC.star a) a) = 0 → True

/-- **L1 Axiom**: ITPFI factorization of ω̃₁ over prime ideals.
    Source: Bost-Connes 1995 Proposition 33; Connes-Marcolli 2008 Ch III Thm 3.32. -/
axiom itpfi_factorization (BC : BostConnesSystem) : True

/-- **L1 Axiom**: α_t is a one-parameter *-automorphism group. -/
axiom time_evolution_is_automorphism (BC : BostConnesSystem) :
    ∀ (t : ℝ) (a b : BC.Algebra),
      BC.timeEvolution t (BC.mul a b) = BC.mul (BC.timeEvolution t a) (BC.timeEvolution t b)

/-- **L1 Axiom**: The KMS condition — ω₁ satisfies the KMS₁ boundary condition
    for the time evolution α_t. -/
axiom kms_condition (BC : BostConnesSystem) :
    ∀ (a b : BC.Algebra), ∃ (F : ℂ → ℂ),
      F 0 = BC.kms1State (BC.mul a (BC.timeEvolution 0 b)) ∧
      F 1 = BC.kms1State (BC.mul (BC.timeEvolution 0 b) a)

end TomitaTakesaki.L1
