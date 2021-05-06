"Julia primitives"
module AutumnBase

using Distributions: Categorical

export uniformChoice, uniformChoice2, min, range

function uniformChoice(rng, freePositions)
  freePositions[rand(rng, Categorical(ones(length(freePositions))/length(freePositions)))]
end

function uniformChoice2(rng, freePositions, n)
  map(idx -> freePositions[idx], rand(rng, Categorical(ones(length(freePositions))/length(freePositions)), n))
end

# WARNING: using AutumnBase.min in module CompiledProgram conflicts with an existing identifier.
function min(arr)
  min(arr...)
end

function range(start::Int, stop::Int)
  [start:stop;]
end

end