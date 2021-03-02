"Propagate Abstract Information Autumn Program"
module AbstractInterpretation
using ..AExpressions

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