"Julia primitives"
module AutumnBase

using Distributions: Categorical
import StatsBase: sample
import Base: range, min, sort
export uniformChoice, min, range, sort, slice, updateObj, sample

function uniformChoice(rng, freePositions)
  freePositions[rand(rng, Categorical(ones(length(freePositions))/length(freePositions)))]
end

function uniformChoice(rng, freePositions, n)
  map(idx -> freePositions[idx], rand(rng, Categorical(ones(length(freePositions))/length(freePositions)), n))
end

# WARNING: using AutumnBase.min in module CompiledProgram conflicts with an existing identifier.
function Base.min(arr)
  min(arr...)
end

function Base.range(start::Int, stop::Int)
  Base.range(start, stop=stop)
end

function Base.sort(list, rev)
  Base.sort(list; by=first, rev=rev)
end

function slice(list::Array, start::Int, stop::Int)
  list[start:stop]
end

function updateObj(obj, field::String, value)
  fields = fieldnames(typeof(obj))
  constructor_values = map(x -> x == Symbol(field) ? value : getproperty(obj, x), fields)

  new_obj = typeof(obj)(constructor_values...)
  new_obj
end

function updateObj(list::Array, map_fn, filter_fn=filter_fallback)
  orig_list = filter(obj -> !filter_fn(obj), list)
  filtered_list = filter(filter_fn, list)
  new_filtered_list = map(map_fn, filtered_list)
  vcat(orig_list, new_filtered_list)
end

function filter_fallback(obj)
  true
end

function sample(list::Array, n::Int)
  sample(list, n; replace=false)
end

end