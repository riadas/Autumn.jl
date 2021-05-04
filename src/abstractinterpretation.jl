"Propagate Abstract Information Autumn Program"
module AbstractInterpretation
using ..AExpressions

# partial order, meet, join, top, bottom, and their identities

import Base: ≤, ==, <, show

abstract type LatticeElement end

struct Const <: LatticeElement
  val::Int
end

struct TopElement <: LatticeElement end
struct BotElement <: LatticeElement end

const ⊤ = TopElement()
const ⊥ = BotElement()

show(io::IO, ::TopElement) = print(io, '⊤')
show(io::IO, ::BotElement) = print(io, '⊥')

≤(x::LatticeElement, y::LatticeElement) = x≡y
≤(::BotElement,      ::TopElement)      = true
≤(::BotElement,      ::LatticeElement)  = true
≤(::LatticeElement,  ::TopElement)      = true

# NOTE: == and < are defined such that future LatticeElements only need to implement ≤
==(x::LatticeElement, y::LatticeElement) = x≤y && y≤x
<(x::LatticeElement,  y::LatticeElement) = x≤y && !(y≤x)

# join
⊔(x::LatticeElement, y::LatticeElement) = x≤y ? y : y≤x ? x : ⊤

# meet
⊓(x::LatticeElement, y::LatticeElement) = x≤y ? x : y≤x ? y : ⊥



export ainterpret

function join end
function meet end

join(t1::Type{T1}, t2::Type{T2}) where {T1,T2} = typeintersect(t1, t2)

"Perform abstract interpretation on `aex` -- propage until `converged`"
function ainterpret(aex, converged)
  while !converged()
      x = 3
  end
end

end