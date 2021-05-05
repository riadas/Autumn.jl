module AutumnBase
# any function in julia base should be available here

# const general_builtInDict = Dict([
  "occurred"        =>  quote
                          function occurred(click)
                            click !== nothing
                          end
                        end,
  
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

abstract type Object end

function addObj(list::Array{<:Object}, obj::Object)
  new_list = vcat(list, obj)
  new_list
end

function addObj(list::Array{<:Object}, objs::Array{<:Object})
  new_list = vcat(list, objs)
  new_list
end

function removeObj(list::Array{<:Object}, obj::Object)
  filter(x -> x.id != obj.id, list)
end

function removeObj(list::Array{<:Object}, fn)
  orig_list = filter(obj -> !fn(obj), list)
end

function removeObj(obj::Object)
  obj.alive = false
  deepcopy(obj)
end

function updateObj(obj::Object, field::String, value)
  fields = fieldnames(typeof(obj))
  custom_fields = fields[5:end-1]
  origin_field = (fields[2],)

  constructor_fields = (custom_fields..., origin_field...)
  constructor_values = map(x -> x == Symbol(field) ? value : getproperty(obj, x), constructor_fields)

  new_obj = typeof(obj)(constructor_values...)
  setproperty!(new_obj, :id, obj.id)
  setproperty!(new_obj, :alive, obj.alive)
  setproperty!(new_obj, :hidden, obj.hidden)

  setproperty!(new_obj, Symbol(field), value)
  state.objectsCreated -= 1    
  new_obj
end

function updateObj(list::Array{<:Object}, map_fn, filter_fn=filter_fallback)
  orig_list = filter(obj -> !filter_fn(obj), list)
  filtered_list = filter(filter_fn, list)
  new_filtered_list = map(map_fn, filtered_list)
  vcat(orig_list, new_filtered_list)
end

function filter_fallback(obj::Object)
  true
end

end 