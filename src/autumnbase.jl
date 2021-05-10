"Julia primitives"
module AutumnBase

using Distributions: Categorical
import Base.range, Base.min
export uniformChoice, uniformChoice2, min, range

function uniformChoice(rng, freePositions)
  freePositions[rand(rng, Categorical(ones(length(freePositions))/length(freePositions)))]
end

function uniformChoice2(rng, freePositions, n)
  map(idx -> freePositions[idx], rand(rng, Categorical(ones(length(freePositions))/length(freePositions)), n))
end

# WARNING: using AutumnBase.min in module CompiledProgram conflicts with an existing identifier.
function Base.min(arr)
  min(arr...)
end

function Base.range(start::Int, stop::Int)
  Base.range(start, stop=stop)
end

end