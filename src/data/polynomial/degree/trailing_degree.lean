/-
Copyright (c) 2020 Damiano Testa. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Damiano Testa
-/
import data.polynomial.degree.basic
import data.polynomial.to_reverse

/-!
# Trailing degree of univariate polynomials

## Main definitions

* `trailing_degree p`: the multiplicity of `X` in the polynomial `p`
* `nat_trailing_degree`: a variant of `trailing_degree` that takes values in the natural numbers
* `trailing_coeff`: the coefficient at index `nat_trailing_degree p`

Converts most results about `degree`, `nat_degree` and `leading_coeff` to results about the bottom
end of a polynomial
-/

noncomputable theory
local attribute [instance, priority 100] classical.prop_decidable

open function polynomial finsupp finset
open_locale big_operators

namespace polynomial
universes u v
variables {R : Type u} {S : Type v} {a b : R} {n m : ℕ}

section semiring
variables [semiring R] {p q r : polynomial R}

/-- `trailing_degree p` is the multiplicity of `x` in the polynomial `p`, i.e. the smallest
`X`-exponent in `p`.
`trailing_degree p = some n` when `p ≠ 0` and `n` is the smallest power of `X` that appears
in `p`, otherwise
`trailing_degree 0 = ⊤`. -/
def trailing_degree (p : polynomial R) : with_top ℕ := p.support.inf some

lemma trailing_degree_lt_wf : well_founded
(λp q : polynomial R, trailing_degree p < trailing_degree q) :=
inv_image.wf trailing_degree (with_top.well_founded_lt nat.lt_wf)

/-- `nat_trailing_degree p` forces `trailing_degree p` to ℕ, by defining nat_trailing_degree 0 = 0. -/
def nat_trailing_degree (p : polynomial R) : ℕ := (trailing_degree p).get_or_else 0

/-- `trailing_coeff p` gives the coefficient of the smallest power of `X` in `p`-/
def trailing_coeff (p : polynomial R) : R := coeff p (nat_trailing_degree p)

/-- a polynomial is `monic_at` if its trailing coefficient is 1 -/
def trailing_monic (p : polynomial R) := trailing_coeff p = (1 : R)

lemma trailing_monic.def : trailing_monic p ↔ trailing_coeff p = 1 := iff.rfl

instance trailing_monic.decidable [decidable_eq R] : decidable (trailing_monic p) :=
by unfold trailing_monic; apply_instance

@[simp] lemma trailing_monic.trailing_coeff {p : polynomial R} (hp : p.trailing_monic) :
  trailing_coeff p = 1 := hp

@[simp] lemma trailing_degree_zero : trailing_degree (0 : polynomial R) = ⊤ := rfl

@[simp] lemma nat_trailing_degree_zero : nat_trailing_degree (0 : polynomial R) = 0 := rfl

lemma trailing_degree_eq_top : trailing_degree p = ⊤ ↔ p = 0 :=
⟨λ h, by rw [trailing_degree, ← min_eq_inf_with_top] at h;
  exact support_eq_empty.1 (min_eq_none.1 h),
λ h, h.symm ▸ rfl⟩

lemma trailing_degree_eq_nat_trailing_degree (hp : p ≠ 0) : trailing_degree p = (nat_trailing_degree p : with_top ℕ) :=
let ⟨n, hn⟩ :=
  not_forall.1 (mt option.eq_none_iff_forall_not_mem.2 (mt trailing_degree_eq_top.1 hp)) in
have hn : trailing_degree p = some n := not_not.1 hn,
by rw [nat_trailing_degree, hn]; refl

lemma trailing_degree_eq_iff_nat_trailing_degree_eq {p : polynomial R} {n : ℕ} (hp : p ≠ 0) :
  p.trailing_degree = n ↔ p.nat_trailing_degree = n :=
by rw [trailing_degree_eq_nat_trailing_degree hp, with_top.coe_eq_coe]

lemma trailing_degree_eq_iff_nat_trailing_degree_eq_of_pos {p : polynomial R} {n : ℕ} (hn : 0 < n) :
  p.trailing_degree = n ↔ p.nat_trailing_degree = n :=
begin
  split,
  { intro H, rwa ← trailing_degree_eq_iff_nat_trailing_degree_eq, rintro rfl,
    rw trailing_degree_zero at H, exact option.no_confusion H },
  { intro H, rwa trailing_degree_eq_iff_nat_trailing_degree_eq, rintro rfl,
    rw nat_trailing_degree_zero at H, rw H at hn, exact lt_irrefl _ hn }
end

lemma nat_trailing_degree_eq_of_trailing_degree_eq_some {p : polynomial R} {n : ℕ}
  (h : trailing_degree p = n) : nat_trailing_degree p = n :=
have hp0 : p ≠ 0, from λ hp0, by rw hp0 at h; exact option.no_confusion h,
option.some_inj.1 $ show (nat_trailing_degree p : with_top ℕ) = n,
  by rwa [← trailing_degree_eq_nat_trailing_degree hp0]

@[simp] lemma nat_trailing_degree_le_trailing_degree : ↑(nat_trailing_degree p) ≤ trailing_degree p :=
begin
  by_cases hp : p = 0, { rw hp, exact le_top },
  rw [trailing_degree_eq_nat_trailing_degree hp],
  exact le_refl _
end

lemma nat_trailing_degree_eq_of_trailing_degree_eq [semiring S] {q : polynomial S} (h : trailing_degree p = trailing_degree q) :
nat_trailing_degree p = nat_trailing_degree q :=
by unfold nat_trailing_degree; rw h

lemma le_trailing_degree_of_ne_zero (h : coeff p n ≠ 0) : trailing_degree p ≤ n :=
show @has_le.le (with_top ℕ) _ (p.support.inf some : with_top ℕ) (some n : with_top ℕ),
from finset.inf_le (finsupp.mem_support_iff.2 h)

lemma nat_trailing_degree_le_of_ne_zero (h : coeff p n ≠ 0) : nat_trailing_degree p ≤ n :=
begin
  rw [← with_top.coe_le_coe, ← trailing_degree_eq_nat_trailing_degree],
  { exact le_trailing_degree_of_ne_zero h, },
  { assume h, subst h, exact h rfl }
end

lemma trailing_degree_le_trailing_degree (h : coeff q (nat_trailing_degree p) ≠ 0) : trailing_degree q ≤ trailing_degree p :=
begin
  by_cases hp : p = 0,
  { rw hp, exact le_top },
  { rw trailing_degree_eq_nat_trailing_degree hp, exact le_trailing_degree_of_ne_zero h }
end

lemma trailing_degree_ne_of_nat_trailing_degree_ne {n : ℕ} :
  p.nat_trailing_degree ≠ n → trailing_degree p ≠ n :=
@option.cases_on _ (λ d, d.get_or_else 0 ≠ n → d ≠ n) p.trailing_degree
  (λ _ h, option.no_confusion h)
  (λ n' h, mt option.some_inj.mp h)

theorem nat_trailing_degree_le_of_trailing_degree_le {n : ℕ} {hp : p ≠ 0} (H : (n : with_top ℕ) ≤ trailing_degree p) : n ≤ nat_trailing_degree p :=
begin
  rw trailing_degree_eq_nat_trailing_degree hp at H,
  exact with_top.coe_le_coe.mp H,
end

lemma nat_trailing_degree_le_nat_trailing_degree {hq : q ≠ 0} (hpq : p.trailing_degree ≤ q.trailing_degree) : p.nat_trailing_degree ≤ q.nat_trailing_degree :=
begin
  by_cases hp : p = 0, { rw [hp, nat_trailing_degree_zero], exact zero_le _ },
  rwa [trailing_degree_eq_nat_trailing_degree hp, trailing_degree_eq_nat_trailing_degree hq, with_top.coe_le_coe] at hpq
end

@[simp] lemma trailing_degree_C (ha : a ≠ 0) : trailing_degree (C a) = (0 : with_top ℕ) :=
show inf (ite (a = 0) ∅ {0}) some = 0, by rw if_neg ha; refl

lemma le_trailing_degree_C : (0 : with_top ℕ) ≤ trailing_degree (C a) :=
by by_cases h : a = 0; [rw [h, C_0], rw [trailing_degree_C h]]; [exact bot_le, exact le_refl _]

lemma trailing_degree_one_le : (0 : with_top ℕ) ≤ trailing_degree (1 : polynomial R) :=
by rw [← C_1]; exact le_trailing_degree_C

@[simp] lemma nat_trailing_degree_C (a : R) : nat_trailing_degree (C a) = 0 :=
begin
  by_cases ha : a = 0,
  { rw [ha, C_0, nat_trailing_degree_zero], },
  { rw [nat_trailing_degree, trailing_degree_C ha], refl }
end

@[simp] lemma nat_trailing_degree_one : nat_trailing_degree (1 : polynomial R) = 0 := nat_trailing_degree_C 1

@[simp] lemma nat_trailing_degree_nat_cast (n : ℕ) : nat_trailing_degree (n : polynomial R) = 0 :=
by simp only [←C_eq_nat_cast, nat_trailing_degree_C]

@[simp] lemma trailing_degree_monomial (n : ℕ) (ha : a ≠ 0) : trailing_degree (C a * X ^ n) = n :=
by rw [← single_eq_C_mul_X, trailing_degree, monomial, support_single_ne_zero ha]; refl

lemma monomial_le_trailing_degree (n : ℕ) (a : R) : (n : with_top ℕ) ≤ trailing_degree (C a * X ^ n) :=
if h : a = 0 then by rw [h, C_0, zero_mul]; exact le_top else le_of_eq (trailing_degree_monomial n h).symm

lemma coeff_eq_zero_of_trailing_degree_lt (h : (n : with_top ℕ) < trailing_degree p) : coeff p n = 0 :=
not_not.1 (mt le_trailing_degree_of_ne_zero (not_le_of_gt h))

lemma coeff_eq_zero_of_lt_nat_trailing_degree {p : polynomial R} {n : ℕ} (h : n < p.nat_trailing_degree) :
  p.coeff n = 0 :=
begin
  apply coeff_eq_zero_of_trailing_degree_lt,
  by_cases hp : p = 0,
  { subst hp, exact with_top.coe_lt_top n, },
  { rwa [trailing_degree_eq_nat_trailing_degree hp, with_top.coe_lt_coe] },
end

@[simp] lemma coeff_nat_trailing_degree_pred_eq_zero {p : polynomial R} {hp : (0 : with_top ℕ) < nat_trailing_degree p} : p.coeff (p.nat_trailing_degree - 1) = 0 :=
coeff_eq_zero_of_lt_nat_trailing_degree $ nat.sub_lt
  ((with_top.zero_lt_coe (nat_trailing_degree p)).mp hp) nat.one_pos

theorem le_trailing_degree_C_mul_X_pow (r : R) (n : ℕ) : (n : with_top ℕ) ≤ trailing_degree (C r * X^n) :=
begin
  rw [← single_eq_C_mul_X],
  refine finset.le_inf (λ b hb, _),
  rw list.eq_of_mem_singleton (finsupp.support_single_subset hb),
  exact le_refl _,
end

theorem le_trailing_degree_X_pow (n : ℕ) : (n : with_top ℕ) ≤ trailing_degree (X^n : polynomial R) :=
by simpa only [C_1, one_mul] using le_trailing_degree_C_mul_X_pow (1:R) n

theorem le_trailing_degree_X : (1 : with_top ℕ) ≤ trailing_degree (X : polynomial R) :=
by simpa only [C_1, one_mul, pow_one] using le_trailing_degree_C_mul_X_pow (1:R) 1

lemma nat_trailing_degree_X_le : (X : polynomial R).nat_trailing_degree ≤ 1 :=
begin
  by_cases h : X = 0,
  { rw [h, nat_trailing_degree_zero],
    exact zero_le 1, },
  { unfold nat_trailing_degree,
    unfold trailing_degree,
    rw [support_X, inf_singleton, option.get_or_else_some],
    intro,
    apply h,
    rw [← mul_one X, ← C_1, a, C_0, mul_zero], },
end

@[simp] lemma trailing_coeff_eq_zero : trailing_coeff p = 0 ↔ p = 0 :=
⟨λ h, by_contradiction $ λ hp, mt mem_support_iff.1
  (not_not.2 h) (mem_of_min (trailing_degree_eq_nat_trailing_degree hp)),
λ h, h.symm ▸ leading_coeff_zero⟩

lemma trailing_coeff_nonzero_iff_nonzero : trailing_coeff p ≠ 0 ↔ p ≠ 0 :=
not_congr trailing_coeff_eq_zero

lemma nat_trailing_degree_mem_support_of_nonzero : p ≠ 0 → nat_trailing_degree p ∈ p.support :=
(mem_support_iff_coeff_ne_zero.mpr ∘ trailing_coeff_nonzero_iff_nonzero.mpr)

lemma nat_trailing_degree_le_of_mem_supp (a : ℕ) :
  a ∈ p.support → nat_trailing_degree p ≤ a:=
nat_trailing_degree_le_of_ne_zero ∘ mem_support_iff_coeff_ne_zero.mp

lemma nat_trailing_degree_eq_support_min' (h : p ≠ 0) :
  nat_trailing_degree p = p.support.min' (nonempty_support_iff.mpr h) :=
begin
  apply le_antisymm,
  { apply le_min',
    intros y hy,
    exact nat_trailing_degree_le_of_mem_supp y hy },
  { apply finset.min'_le,
    exact mem_support_iff_coeff_ne_zero.mpr (trailing_coeff_nonzero_iff_nonzero.mpr h), },
end

end semiring


section nonzero_semiring
variables [semiring R] [nontrivial R] {p q : polynomial R}

@[simp] lemma trailing_degree_one : trailing_degree (1 : polynomial R) = (0 : with_top ℕ) :=
trailing_degree_C (show (1 : R) ≠ 0, from zero_ne_one.symm)

@[simp] lemma trailing_degree_X : trailing_degree (X : polynomial R) = 1 :=
begin
  unfold X trailing_degree monomial single finsupp.support,
  rw if_neg (one_ne_zero : (1 : R) ≠ 0),
  refl
end

@[simp] lemma nat_trailing_degree_X : (X : polynomial R).nat_trailing_degree = 1 :=
nat_trailing_degree_eq_of_trailing_degree_eq_some trailing_degree_X

end nonzero_semiring


section ring
variables [ring R]

@[simp] lemma trailing_degree_neg (p : polynomial R) : trailing_degree (-p) = trailing_degree p :=
by unfold trailing_degree; rw support_neg

@[simp] lemma nat_trailing_degree_neg (p : polynomial R) : nat_trailing_degree (-p) = nat_trailing_degree p :=
by simp [nat_trailing_degree]

@[simp] lemma nat_trailing_degree_int_cast (n : ℤ) : nat_trailing_degree (n : polynomial R) = 0 :=
by simp only [←C_eq_int_cast, nat_trailing_degree_C]

end ring

section semiring
variables [semiring R] {p q : polynomial R} {ι : Type*}

/-- The second-lowest coefficient, or 0 for constants -/
def next_coeff_up (p : polynomial R) : R :=
if p.nat_trailing_degree = 0 then 0 else p.coeff (p.nat_trailing_degree + 1)

@[simp]
lemma next_coeff_up_C_eq_zero (c : R) :
  next_coeff_up (C c) = 0 := by { rw next_coeff_up, simp }

lemma next_coeff_up_of_pos_nat_trailing_degree (p : polynomial R) (hp : 0 < p.nat_trailing_degree) :
  next_coeff_up p = p.coeff (p.nat_trailing_degree + 1) :=
by { rw [next_coeff_up, if_neg], contrapose! hp, simpa }

lemma coeff_nat_trailing_degree_eq_zero_of_trailing_degree_lt (h : trailing_degree p < trailing_degree q) :
  coeff q (nat_trailing_degree p) = 0 :=
begin
  refine coeff_eq_zero_of_trailing_degree_lt _,
  rcases h with ⟨n, hn, hq⟩,
  rw option.mem_def at hn,
  simp_rw [option.mem_def] at hq,
  unfold nat_trailing_degree,
  rw [hn, option.get_or_else_some],
  exact ⟨n, ⟨rfl, hq⟩⟩,
end

lemma ne_zero_of_trailing_degree_lt {n : with_top ℕ} (h : trailing_degree p < n) : p ≠ 0 :=
begin
  intro p0,
  rw (trailing_degree_eq_top.mpr p0) at h,
  revert h,
  exact dec_trivial,
end

@[simp] lemma trailing_coeff_one : (1 : polynomial R).trailing_coeff = 1 :=
by rw [trailing_coeff, nat_trailing_degree_one, coeff_one_zero]

lemma nat_trailing_degree_le_nat_degree : p.nat_trailing_degree ≤ p.nat_degree :=
begin
  by_cases p0 : p = 0,
  { rw [p0, nat_degree_zero, nat_trailing_degree_zero], },
  rw [nat_degree_eq_support_max' p0, nat_trailing_degree_eq_support_min' p0],
  exact p.support.min'_le (p.support.max' _) (p.support.max'_mem _),
end

@[simp] lemma nat_trailing_degree_eq_zero (h : p.coeff 0 ≠ 0) : p.nat_trailing_degree = 0 :=
begin
  rw nat_trailing_degree_eq_support_min',
  { exact nat.eq_zero_of_le_zero (min'_le _ _ (mem_support_iff_coeff_ne_zero.mpr h)),
    intro p0,
    apply h,
    rw [p0, coeff_zero], },
end

end semiring
end polynomial
