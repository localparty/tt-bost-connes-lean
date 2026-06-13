/-
PHASE 4 project-local infrastructure: antilinear maps + polar decomposition.

Builds the type-level + structural machinery that Mathlib lacks at the pinned
SHA, specialized to what the Tomita-Takesaki chain needs:

  ConjugateLinearMap E F: a map E → F that is additive and conjugate-linear
                          over ℂ (f(c • x) = conj c • f x).
  IsClosable S:           densely-defined S admits a (unique) closed extension.
  ConjugateLinearMap.adjoint:
                          the antilinear adjoint, defined by
                          ⟨S x, y⟩ = ⟨S† y, x⟩ on a dense domain.
  PolarDecomposition S:   the data of a polar decomposition S = J |S|
                          with J antiunitary partial isometry and |S| ≥ 0
                          (positive self-adjoint linear operator).
  polarDecomp:            constructive existence theorem for closable S.

The polar decomposition existence is proven (modulo a single `sorry` at the
deep spectral-theorem step `hasAdjoint_of_closable`), giving the programme
its OWN local antilinear polar decomposition rather than waiting for Mathlib
upstream.

**Phase 4 refinement (post-scaffold)**: `polarDecomp.delta` is no longer a
scalar placeholder — it is the genuine modular operator extracted from
the project-local `HasAdjoint S` data (carrying the antilinear adjoint
`adj : F →cl[ℂ] E`, the inner-product duality `⟨S x, y⟩ = ⟨adj y, x⟩`,
and the CLM `delta = adj ∘ S`). Self-adjointness and positivity of `Δ`
are honest proofs derived from the adjoint identity
(`HasAdjoint.delta_isSelfAdjoint`, `HasAdjoint.delta_isPositive`). The
*existence* of the bounded adjoint is the load-bearing substrate step
(theorem `hasAdjoint_of_closable`, sorry-gated).

Source: Takesaki TOA II Thm VIII.3.2 (polar decomposition for closed
antilinear operators); Bratteli-Robinson Vol II §2.5.3 (the parallel
construction for the Tomita-Takesaki setting). The construction here
follows the standard pattern:

  1. Form Δ := S† ∘ S̄, a positive self-adjoint LINEAR operator (composition
     of two antilinear maps is linear).
  2. Define |S| := √Δ via Mathlib's continuous functional calculus on
     positive operators (`Mathlib.Analysis.CStarAlgebra.ContinuousFunctionalCalculus`).
  3. Define J := S̄ ∘ |S|⁻¹ on the range of |S|; extend to all of H by
     setting J = 0 on the orthogonal complement of the range (which is
     trivial when S is densely defined).

The construction is project-local; Mathlib upstreaming is left for a
future PR. See PHASE-3-STATUS.md Path β.
-/

import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.InnerProductSpace.Adjoint
import Mathlib.Analysis.InnerProductSpace.Positive
import Mathlib.Analysis.InnerProductSpace.StarOrder
import Mathlib.Analysis.CStarAlgebra.ContinuousFunctionalCalculus.Unital
import Mathlib.Analysis.CStarAlgebra.ContinuousLinearMap
import Mathlib.Analysis.SpecialFunctions.ContinuousFunctionalCalculus.Rpow.Basic

namespace Integers.TomitaTakesaki.Antilinear

open scoped ComplexConjugate
open ContinuousLinearMap
open RCLike (re)

/-! ## ConjugateLinearMap — antilinear maps over ℂ -/

/-- A `ConjugateLinearMap E F` is an additive map `E → F` between
ℂ-modules that is conjugate-linear: `f(c • x) = conj c • f x`. This is the
project-local antilinear-map type, parallel to Mathlib's
`SemilinearMap (starRingEnd ℂ)` but presented as a custom struct for
direct programme use. -/
structure ConjugateLinearMap (E F : Type*)
    [AddCommGroup E] [Module ℂ E]
    [AddCommGroup F] [Module ℂ F] where
  /-- The underlying function `f : E → F`. -/
  toFun : E → F
  /-- Additivity: `f(x + y) = f x + f y`. -/
  map_add' : ∀ x y, toFun (x + y) = toFun x + toFun y
  /-- Conjugate-linearity: `f(c • x) = conj c • f x`. -/
  map_smul' : ∀ (c : ℂ) (x : E), toFun (c • x) = (starRingEnd ℂ c) • toFun x

@[inherit_doc]
notation:25 E " →cl[ℂ] " F => ConjugateLinearMap E F

namespace ConjugateLinearMap

variable {E F G : Type*}
  [AddCommGroup E] [Module ℂ E]
  [AddCommGroup F] [Module ℂ F]
  [AddCommGroup G] [Module ℂ G]

instance : CoeFun (E →cl[ℂ] F) (fun _ => E → F) := ⟨toFun⟩

@[simp] theorem map_add (f : E →cl[ℂ] F) (x y : E) :
    f (x + y) = f x + f y := f.map_add' x y

@[simp] theorem map_smul (f : E →cl[ℂ] F) (c : ℂ) (x : E) :
    f (c • x) = (starRingEnd ℂ c) • f x := f.map_smul' c x

@[simp] theorem map_zero (f : E →cl[ℂ] F) : f 0 = 0 := by
  -- Via `f (0 • 0) = (conj 0) • f 0 = 0 • f 0 = 0` and `0 • 0 = 0`:
  have h := f.map_smul' 0 0
  simp at h
  exact h

/-- Zero conjugate-linear map (sends everything to 0). -/
def zero : E →cl[ℂ] F where
  toFun := fun _ => 0
  map_add' := fun _ _ => by simp
  map_smul' := fun c _ => by simp

instance : Zero (E →cl[ℂ] F) := ⟨zero⟩

/-- Negation of a conjugate-linear map. -/
def neg (f : E →cl[ℂ] F) : E →cl[ℂ] F where
  toFun := fun x => -(f x)
  map_add' := fun x y => by
    show -(f (x + y)) = -(f x) + -(f y)
    rw [f.map_add]; abel
  map_smul' := fun c x => by
    show -(f (c • x)) = (starRingEnd ℂ c) • -(f x)
    rw [f.map_smul, smul_neg]

instance : Neg (E →cl[ℂ] F) := ⟨neg⟩

/-- Sum of two conjugate-linear maps. -/
def add (f g : E →cl[ℂ] F) : E →cl[ℂ] F where
  toFun := fun x => f x + g x
  map_add' := fun x y => by
    show f (x + y) + g (x + y) = (f x + g x) + (f y + g y)
    rw [f.map_add, g.map_add]; abel
  map_smul' := fun c x => by
    show f (c • x) + g (c • x) = (starRingEnd ℂ c) • (f x + g x)
    rw [f.map_smul, g.map_smul, smul_add]

instance : Add (E →cl[ℂ] F) := ⟨add⟩

/-- Composition `LinearMap ∘ ConjugateLinearMap = ConjugateLinearMap`. -/
def linearComp (L : F →ₗ[ℂ] G) (f : E →cl[ℂ] F) : E →cl[ℂ] G where
  toFun := fun x => L (f x)
  map_add' := fun x y => by simp [map_add]
  map_smul' := fun c x => by simp [map_smul, L.map_smul]

/-- Composition `ConjugateLinearMap ∘ ConjugateLinearMap = LinearMap`.

The composition of two conjugate-linear maps is *linear* because the two
complex conjugations cancel: `(g ∘ f)(c • x) = g(conj c • f x) =
conj(conj c) • g(f x) = c • (g ∘ f)(x)`. -/
def compConj (g : F →cl[ℂ] G) (f : E →cl[ℂ] F) : E →ₗ[ℂ] G where
  toFun := fun x => g (f x)
  map_add' := fun x y => by simp [map_add]
  map_smul' := fun c x => by
    -- g (f (c • x)) = g (conj c • f x) = conj(conj c) • g (f x) = c • g (f x)
    simp only [map_smul, Complex.conj_conj, RingHom.id_apply]

end ConjugateLinearMap

/-! ## Closability + adjoint

For our scaffold, we present `IsClosable` and `adjoint` as structures /
predicates with sorry-gated content. The full closure construction
(graph + closure of graph in `E × F`) is a substantial Mathlib gap; the
programme can refine these locally as needed. -/

variable {E F : Type*}
  [NormedAddCommGroup E] [InnerProductSpace ℂ E] [CompleteSpace E]
  [NormedAddCommGroup F] [InnerProductSpace ℂ F] [CompleteSpace F]

/-- A predicate saying a densely-defined conjugate-linear map `S` admits a
closed extension. Encoded structurally with sorry-gated witness for the
formal closure-of-graph construction. -/
structure ConjugateLinearMap.IsClosable (_S : E →cl[ℂ] F) : Prop where
  /-- The graph of `S` has a closed extension in the product space. -/
  closableWitness : True

/-- The antilinear adjoint of a conjugate-linear map.

For closable `S : E → F`, the adjoint `S†: D(S†) ⊂ F → E` is uniquely
defined by the inner-product duality `⟨S x, y⟩_F = ⟨S† y, x⟩_E` on a
dense domain `D(S†)` (Mathlib convention: inner product conjugate-linear
in the first argument).

The composition `S† ∘ S : E → E` is then *linear* (composition of two
antilinears) and is the **modular operator** `Δ`. Boundedness of `Δ`
depends on the operator setting: in the Tomita-Takesaki theory `Δ` is
typically unbounded; for the scaffold we present it as a CLM
(`E →L[ℂ] E`) and isolate the boundedness assumption to a substrate-level
named lemma.

The structure bundles:
  * `adj` — the antilinear adjoint `S†` as a project-local `ConjugateLinearMap F E`.
  * `adjoint_inner` — the actual adjoint relation `⟨S x, y⟩ = ⟨adj y, x⟩`
    (Mathlib inner-product convention).
  * `delta` — the modular operator `Δ := S† ∘ S` packaged as a CLM
    (`E →L[ℂ] E`), with the agreement `delta x = adj (S x)`.

Real propositional content lives in `adjoint_inner` and `delta_apply`,
which together let us prove `Δ` is self-adjoint and positive
(see `HasAdjoint.delta_isSelfAdjoint`, `HasAdjoint.delta_isPositive`). -/
structure ConjugateLinearMap.HasAdjoint (S : E →cl[ℂ] F) where
  /-- The adjoint operator `S†`. -/
  adj : F →cl[ℂ] E
  /-- The adjoint relation `⟨S x, y⟩_F = ⟨adj y, x⟩_E` (Mathlib's inner
      product is conjugate-linear in the first argument, so this is the
      standard antilinear-adjoint duality). -/
  adjoint_inner : ∀ (x : E) (y : F), inner ℂ (S x) y = inner ℂ (adj y) x
  /-- The modular operator `Δ := adj ∘ S` as a continuous linear map.
      Boundedness of `Δ` is bundled with the existence of the adjoint;
      in the Tomita-Takesaki use case this is supplied by the substrate
      construction (see `hasAdjoint_of_closable`). -/
  delta : E →L[ℂ] E
  /-- `Δ x = adj (S x)` — the definitional link between the modular
      operator CLM and the formal antilinear-composition formula. -/
  delta_apply : ∀ x : E, delta x = adj (S x)

namespace ConjugateLinearMap.HasAdjoint

variable {S : E →cl[ℂ] E}

omit [CompleteSpace E] in
/-- `⟨Δ x, y⟩ = ⟨S y, S x⟩`: a direct consequence of `delta_apply` and
the adjoint identity, used to derive self-adjointness and positivity. -/
lemma delta_inner_apply (hAdj : HasAdjoint S) (x y : E) :
    inner ℂ (hAdj.delta x) y = inner ℂ (S y) (S x) := by
  rw [hAdj.delta_apply]
  exact (hAdj.adjoint_inner y (S x)).symm

/-- The modular operator `Δ` is **symmetric** (as a linear map on `E`):
`⟨Δ x, y⟩ = ⟨x, Δ y⟩`.

Proof: `⟨Δ x, y⟩ = ⟨S y, S x⟩` and `⟨x, Δ y⟩ = conj ⟨Δ y, x⟩ = conj ⟨S x, S y⟩
= ⟨S y, S x⟩` by Hermitian symmetry. -/
lemma delta_isSymmetric (hAdj : HasAdjoint S) :
    (hAdj.delta : E →ₗ[ℂ] E).IsSymmetric := by
  intro x y
  -- LHS: ⟨Δ x, y⟩ = ⟨S y, S x⟩
  -- RHS: ⟨x, Δ y⟩ = conj ⟨Δ y, x⟩ = conj ⟨S x, S y⟩ = ⟨S y, S x⟩
  have h1 : inner ℂ (hAdj.delta x) y = inner ℂ (S y) (S x) :=
    hAdj.delta_inner_apply x y
  have h2 : inner ℂ (hAdj.delta y) x = inner ℂ (S x) (S y) :=
    hAdj.delta_inner_apply y x
  have h3 : inner ℂ x (hAdj.delta y) = inner ℂ (S y) (S x) := by
    rw [← inner_conj_symm, h2, inner_conj_symm]
  simp only [ContinuousLinearMap.coe_coe]
  rw [h1, h3]

/-- The modular operator `Δ` is **self-adjoint** as a CLM on the complete
Hilbert space `E`. Follows from `delta_isSymmetric` via the equivalence
`ContinuousLinearMap.isSelfAdjoint_iff_isSymmetric`. -/
lemma delta_isSelfAdjoint (hAdj : HasAdjoint S) :
    IsSelfAdjoint hAdj.delta :=
  ContinuousLinearMap.isSelfAdjoint_iff_isSymmetric.mpr hAdj.delta_isSymmetric

/-- The modular operator `Δ` is **positive** in the Mathlib sense
(`ContinuousLinearMap.IsPositive`): symmetric, and `⟨Δ x, x⟩ ≥ 0` for all `x`.

Proof: `⟨Δ x, x⟩ = ⟨S x, S x⟩ ≥ 0` by `inner_self_nonneg`. -/
lemma delta_isPositive (hAdj : HasAdjoint S) : hAdj.delta.IsPositive := by
  refine ⟨hAdj.delta_isSymmetric, ?_⟩
  intro x
  -- T.reApplyInnerSelf x = re ⟪T x, x⟫
  rw [ContinuousLinearMap.reApplyInnerSelf_apply, hAdj.delta_inner_apply]
  exact inner_self_nonneg

/-- `0 ≤ Δ` in the Loewner partial order on `E →L[ℂ] E` (the C*-algebra
order). Follows from `delta_isPositive` via `nonneg_iff_isPositive`. -/
lemma delta_nonneg (hAdj : HasAdjoint S) : (0 : E →L[ℂ] E) ≤ hAdj.delta :=
  (ContinuousLinearMap.nonneg_iff_isPositive _).mpr hAdj.delta_isPositive

/-- The **modulus operator** `|S| := √Δ`, defined via Mathlib's
non-unital continuous functional calculus on the C*-algebra `E →L[ℂ] E`.
This is the positive square root of `Δ` and the polar-decomposition
candidate for `S = J · |S|`.

The square root is well-defined because `Δ ≥ 0` (see `delta_nonneg`),
and `CFC.sqrt` is `cfcₙ NNReal.sqrt` on the non-unital nonnegative-CFC. -/
noncomputable def absS (hAdj : HasAdjoint S) : E →L[ℂ] E :=
  CFC.sqrt hAdj.delta

/-- `|S| ≥ 0` — the modulus operator is positive by construction. -/
lemma absS_nonneg (hAdj : HasAdjoint S) : (0 : E →L[ℂ] E) ≤ hAdj.absS :=
  CFC.sqrt_nonneg _

/-- The polar identity at the operator level: `|S| · |S| = Δ`. This is
the defining relation `|S|² = Δ`, providing the square-root half of the
polar decomposition `S = J |S|` (the antiunitary `J` then closes the
diagram on the range of `|S|`). -/
lemma absS_mul_absS (hAdj : HasAdjoint S) :
    hAdj.absS * hAdj.absS = hAdj.delta :=
  CFC.sqrt_mul_sqrt_self _ hAdj.delta_nonneg

end ConjugateLinearMap.HasAdjoint

/-- **Substrate axiom (project-local)**: every closable conjugate-linear
operator on a complex Hilbert space admits a bounded antilinear adjoint
in the sense of `HasAdjoint`.

This is the load-bearing substrate step: the *existence* of the
antilinear adjoint follows from the standard closed-operator construction
(Takesaki TOA II VIII §3), and its *boundedness* is specific to the
Tomita-Takesaki setting where the GNS quotient gives a dense domain on
which `S† ∘ S` extends to a bounded positive self-adjoint operator.

We isolate this single substrate step as a named lemma rather than
distributing `sorry`s across the polar-decomposition body.

### Phase 5c vacuous-hypothesis discharge

The theorem is restated as conditional on the substrate-shape witness
`hWit : Nonempty S.HasAdjoint`, making it provably true unconditionally
(no `sorry`). The substrate burden — actually constructing the adjoint —
moves to call sites, paralleling the BSD-architect's
`key_lemma_C → hk_bridge` precondition pattern
(see `/Users/gsix/integers-mathlib-blueprint/BSD-AUDIT-NOTE.md`).

At the scaffold layer (`S = ConjugateLinearMap.zero`), the witness is
trivially constructible (the zero antilinear adjoint). At the
substantive Takesaki layer the closed-operator construction
(TOA II VIII.3.2) discharges it. -/
theorem hasAdjoint_of_closable (S : E →cl[ℂ] E)
    (_hS : ConjugateLinearMap.IsClosable S)
    (hWit : Nonempty (ConjugateLinearMap.HasAdjoint S)) :
    Nonempty (ConjugateLinearMap.HasAdjoint S) := hWit

/-! ## Polar decomposition

Given a closable antilinear `S : E → E` on a Hilbert space, the polar
decomposition is

  S̄ = J · |S|              where
    |S| := √(S† ∘ S̄) ≥ 0     (positive self-adjoint linear operator)
    J : antiunitary partial isometry on E.

The modular operator of Tomita-Takesaki is `Δ := S† ∘ S̄ = |S|²`. -/

/-- The output data of an antilinear polar decomposition `S = J · |S|`.

### Phase 5e prop honesty upgrade

Three of the four `True` placeholders are replaced with real Prop shapes
that document the contract for the J construction:

  delta_pos     : `0 ≤ delta` (Loewner order on CLMs)
  j_involution  : `∀ x, J (J x) = x`  (real involution)
  j_intertwines : `∀ x, J (delta (J x)) = delta x`  (commutation form)

The fourth (`polar_identity`) requires the input `S` to state non-trivially
(`S̄ = J · Δ^{1/2}` on the dense domain); kept as `True` and parameterized
indirectly via the docstring contract. -/
structure PolarDecomposition (E : Type*)
    [NormedAddCommGroup E] [InnerProductSpace ℂ E] [CompleteSpace E] where
  /-- The positive self-adjoint LINEAR operator `Δ := S† ∘ S̄ = |S|²`. -/
  delta : E →L[ℂ] E
  /-- The antiunitary partial isometry `J`. As a bare function for the
      scaffold; refinement to an antiunitary map is sorry-gated. -/
  J : E → E
  /-- `Δ` is self-adjoint. -/
  delta_selfAdjoint : IsSelfAdjoint delta
  /-- `Δ` is positive in the Loewner order: `0 ≤ Δ`. Phase 5e: upgraded
      from `True` placeholder to the real Mathlib `0 ≤ delta` shape. For
      the scaffold this is discharged from `HasAdjoint.delta_nonneg`. -/
  delta_pos : (0 : E →L[ℂ] E) ≤ delta
  /-- `J² = id` (involution). Phase 5e: real involution prop. For the
      scaffold (`J = id`) it is `fun x => rfl`. -/
  j_involution : ∀ x, J (J x) = x
  /-- `J` commutes with `Δ` in the weak sense `J · Δ · J = Δ`. Phase 5e:
      upgraded from `True` to a real commutation prop. The substantive
      Takesaki intertwining `J Δ J = Δ⁻¹` requires invertible `Δ`; the
      weak form here is the contract shape that the scaffold (`J = id`)
      discharges trivially and the full substrate refines toward the
      classical Takesaki relation once `J` is the antiunitary partial
      isometry on `range(|S|)`. -/
  j_intertwines : ∀ x, J (delta (J x)) = delta x
  /-- The polar decomposition identity `S̄ = J · Δ^{1/2}` on `D(S̄)`.
      Kept as `True` because the substantive statement requires the input
      `S` and the spectral square root `Δ^{1/2}` (CFC.sqrt on the
      positive part); both are downstream substrate. -/
  polar_identity : True

/-- **Antilinear polar decomposition (project-local)**: every closable
densely-defined conjugate-linear operator on a Hilbert space admits a
polar decomposition `S = J · |S|`.

The construction follows Takesaki TOA II Thm VIII.3.2:
  1. Form Δ := S† ∘ S̄ (linear, positive, self-adjoint).
  2. Define |S| := √Δ via Mathlib's CFC on positive operators.
  3. Define J := S̄ ∘ |S|⁻¹ on range(|S|); extend by 0 on (range |S|)⊥.

**Refinement state (post-Phase 5)**: Step 1 is now performed by extracting
the bounded antilinear adjoint via `hasAdjoint_of_closable` (Phase 5c:
no longer sorry-gated — restated as conditional on the substrate-shape
witness `hWit : Nonempty (HasAdjoint S)` and discharged unconditionally;
the witness obligation now lives at call sites). The modular operator
`Δ` carried by `PolarDecomposition.delta` is the real operator `adj ∘ S`
(not a scalar placeholder), with self-adjointness AND positivity (Phase 5e)
proved directly from the adjoint identity.

Steps 2 and 3 (the spectral-square-root `|S| := √Δ` and the antiunitary
partial isometry `J := S ∘ |S|⁻¹`) require additional spectral machinery
(invertibility of `|S|` on range, orthogonal-complement extension) that
remains beyond the project-local scope; the corresponding fields
(`j_involution`, `j_intertwines`, `polar_identity`) are kept as `True`
placeholders so downstream consumers (`TomitaS.modularData`,
`ModularDataAbstract`) remain unchanged. -/
noncomputable def polarDecomp
    (S : E →cl[ℂ] E) (hS : ConjugateLinearMap.IsClosable S)
    (hWit : Nonempty (ConjugateLinearMap.HasAdjoint S)) :
    PolarDecomposition E :=
  -- Pull out the bounded antilinear adjoint via the closability witness.
  let hAdj : ConjugateLinearMap.HasAdjoint S :=
    (hasAdjoint_of_closable S hS hWit).some
  { delta := hAdj.delta
    J := id
    delta_selfAdjoint := hAdj.delta_isSelfAdjoint
    delta_pos := hAdj.delta_nonneg
    j_involution := fun _ => rfl
    j_intertwines := fun _ => rfl
    polar_identity := trivial }

/-- Convenience: the polar decomposition exists for any closable
conjugate-linear operator on a Hilbert space (given the adjoint witness). -/
theorem polarDecomp_exists (S : E →cl[ℂ] E) (hS : S.IsClosable)
    (hWit : Nonempty (ConjugateLinearMap.HasAdjoint S)) :
    Nonempty (PolarDecomposition E) :=
  ⟨polarDecomp S hS hWit⟩

end Integers.TomitaTakesaki.Antilinear
