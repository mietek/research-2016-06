module A201606.Common.Context where

open import Data.Fin using (Fin ; zero ; suc) public
open import Data.Nat using (ℕ ; zero ; suc) public
open import Function using (flip) public


-- Contexts.

infixl 2 _,_
data Cx (U : Set) : Set where
  ∅   : Cx U
  _,_ : Cx U → U → Cx U

module _ {U : Set} where
  length : Cx U → ℕ
  length ∅       = zero
  length (Γ , A) = suc (length Γ)


-- Variables, or typed de Bruijn indices.

module _ {U : Set} where
  infix 1 _∈_
  data _∈_ (A : U) : Cx U → Set where
    top : ∀ {Γ} → A ∈ Γ , A
    pop : ∀ {B Γ} → A ∈ Γ → A ∈ Γ , B

  index : ∀ {A Γ} → A ∈ Γ → Fin (length Γ)
  index top     = zero
  index (pop i) = suc (index i)

  i₀ : ∀ {A Γ} → A ∈ Γ , A
  i₀ = top

  i₁ : ∀ {A B Γ} → A ∈ Γ , A , B
  i₁ = pop i₀

  i₂ : ∀ {A B C Γ} → A ∈ Γ , A , B , C
  i₂ = pop i₁


-- Renaming and substitution.

module _ {U : Set} where
  Renᵢ : Cx U → Cx U → Set
  Renᵢ Γ Γ′ = ∀ {A} → A ∈ Γ → A ∈ Γ′

  Ren : ∀ {V : Set} → (Cx U → V → Set) → Cx U → Cx U → Set
  Ren Ξ Γ Γ′ = ∀ {A} → Ξ Γ A → Ξ Γ′ A

  Subᵢ : (Cx U → U → Set) → Cx U → Cx U → Set
  Subᵢ Ξ Γ Γ′ = ∀ {A} → A ∈ Γ → Ξ Γ′ A

  Sub : ∀ {V : Set} → (Cx U → V → Set) → Cx U → Cx U → Set
  Sub Ξ Γ Γ′ = ∀ {A} → Ξ Γ A → Ξ Γ′ A

  wk-renᵢ : ∀ {A Γ Γ′} → Renᵢ Γ Γ′ → Renᵢ (Γ , A) (Γ′ , A)
  wk-renᵢ ρ top     = top
  wk-renᵢ ρ (pop i) = pop (ρ i)


-- Context removals and variable equality.

module _ {U : Set} where
  _-ᵢ_ : ∀ {A} → (Γ : Cx U) → A ∈ Γ → Cx U
  ∅       -ᵢ ()
  (Γ , A) -ᵢ top   = Γ
  (Γ , B) -ᵢ pop i = Γ -ᵢ i , B

  add-var : ∀ {A Γ} → (i : A ∈ Γ) → Renᵢ (Γ -ᵢ i) Γ
  add-var top     j       = pop j
  add-var (pop i) top     = top
  add-var (pop i) (pop j) = pop (add-var i j)

  data _=ᵢ_ {A Γ} (i : A ∈ Γ) : ∀ {B} → B ∈ Γ → Set where
    same : i =ᵢ i
    diff : ∀ {B} → (j : B ∈ Γ -ᵢ i) → i =ᵢ add-var i j

  _≟ᵢ_ : ∀ {A B Γ} → (i : A ∈ Γ) (j : B ∈ Γ) → i =ᵢ j
  top   ≟ᵢ top    = same
  top   ≟ᵢ pop j  = diff j
  pop i ≟ᵢ top    = diff top
  pop i ≟ᵢ pop j  with i ≟ᵢ j
  pop i ≟ᵢ pop .i | same   = same
  pop i ≟ᵢ pop ._ | diff j = diff (pop j)
