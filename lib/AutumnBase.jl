module AutumnBase
# Julia "primitive" stuff
  
function uniformChoice(rng, freePositions)
  freePositions[rand(rng, Categorical(ones(length(freePositions))/length(freePositions)))]
end

function uniformChoice2(rng, freePositions, n)
  map(idx -> freePositions[idx], rand(rng, Categorical(ones(length(freePositions))/length(freePositions)), n))
end

function min(arr)
  min(arr...)
end

function range(start::Int, stop::Int)
  [start:stop;]
end

end