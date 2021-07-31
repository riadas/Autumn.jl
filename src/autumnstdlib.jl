module AutumnStandardLibrary
using Distributions: Categorical

update_nt(Γ, x::Symbol, v) = merge(Γ, NamedTuple{(x,)}((v,)))

abstract type Object end
abstract type KeyPress end

struct Left <: KeyPress end
struct Right <: KeyPress end
struct Up <: KeyPress end
struct Down <: KeyPress end

struct Click
  x::Int
  y::Int                    
end

Click(x, y, state) = Click(x, y)

struct Position
  x::Int
  y::Int
end

Position(x, y, state) = Position(x, y) 

struct Cell 
  position::Position
  color::String
  opacity::Float64
end

Cell(position::Position, color::String) = Cell(position, color, 0.8)
Cell(x::Int, y::Int, color::String) = Cell(Position(floor(Int, x), floor(Int, y)), color, 0.8)
# Cell(x::Int, y::Int, color::String, opacity::Float64) = Cell(Position(floor(Int, x), floor(Int, y)), color, opacity)

Cell(x, y, color::String, state) = Cell(floor(Int, x), floor(Int, y), color)
Cell(position::Position, color::String, state) = Cell(position::Position, color::String)

# struct Scene
#   objects::Array{Object}
#   background::String
# end

# Scene(objects::AbstractArray) = Scene(objects, "#ffffff00")

# function render(scene)::Array{Cell}
#   vcat(map(obj -> render(obj), filter(obj -> obj.alive, scene.objects))...)
# end

function render(obj::NamedTuple, state=nothing)::Array{Cell}
  if !(:id in keys(obj))
    vcat(map(o -> render(o), filter(x -> x.alive, obj.objects))...)
  else
    if obj.alive
      map(cell -> Cell(move(cell.position, obj.origin), cell.color), obj.render)
    else
      []
    end
  end
end


function occurred(click, state=nothing)
  !isnothing(click)
end

function uniformChoice(freePositions, state)
  freePositions[rand(state.rng, Categorical(ones(length(freePositions))/length(freePositions)))]
end

function uniformChoice(freePositions, n::Union{Int, BigInt}, state)
  map(idx -> freePositions[idx], rand(state.rng, Categorical(ones(length(freePositions))/length(freePositions)), n))
end

function min(arr, state=nothing)
  Base.min(arr...)
end

function range(start::Int, stop::Int, state=nothing)
  [start:stop;]
end

function isWithinBounds(obj::NamedTuple, state)::Bool
  # println(filter(cell -> !isWithinBounds(cell.position),render(obj)))
  length(filter(cell -> !isWithinBounds(cell.position, state), render(obj))) == 0
end

function clicked(click::Union{Click, Nothing}, object::NamedTuple, state)::Bool
  if click == nothing
    false
  else
    GRID_SIZE = state.GRID_SIZEHistory[0]
    nums = map(cell -> GRID_SIZE*cell.position.y + cell.position.x, render(object))
    (GRID_SIZE * click.y + click.x) in nums
  end
end

function clicked(click::Union{Click, Nothing}, objects::AbstractArray, state)  
  # println("LOOK AT ME")
  # println(reduce(&, map(obj -> clicked(click, obj), objects)))
  reduce(|, map(obj -> clicked(click, obj, state), objects))
end

function objClicked(click::Union{Click, Nothing}, objects::AbstractArray, state=nothing)::Union{Object, Nothing}
  println(click)
  if isnothing(click)
    nothing
  else
    clicked_objects = filter(obj -> clicked(click, obj, state), objects)
    if length(clicked_objects) == 0
      nothing
    else
      clicked_objects[1]
    end
  end

end

function clicked(click::Union{Click, Nothing}, x::Int, y::Int, state)::Bool
  if click == nothing
    false
  else
    click.x == x && click.y == y                         
  end
end

function clicked(click::Union{Click, Nothing}, pos::Position, state)::Bool
  if click == nothing
    false
  else
    click.x == pos.x && click.y == pos.y                         
  end
end

function intersects(obj1::NamedTuple, obj2::NamedTuple, state)::Bool
  nums1 = map(cell -> state.GRID_SIZEHistory[0]*cell.position.y + cell.position.x, render(obj1))
  nums2 = map(cell -> state.GRID_SIZEHistory[0]*cell.position.y + cell.position.x, render(obj2))
  length(intersect(nums1, nums2)) != 0
end

function intersects(obj1::NamedTuple, obj2::AbstractArray, state)::Bool
  nums1 = map(cell -> state.GRID_SIZEHistory[0]*cell.position.y + cell.position.x, render(obj1))
  nums2 = map(cell -> state.GRID_SIZEHistory[0]*cell.position.y + cell.position.x, vcat(map(render, obj2)...))
  length(intersect(nums1, nums2)) != 0
end

function intersects(obj1::AbstractArray, obj2::AbstractArray, state)::Bool
  nums1 = map(cell -> state.GRID_SIZEHistory[0]*cell.position.y + cell.position.x, vcat(map(render, obj1)...))
  nums2 = map(cell -> state.GRID_SIZEHistory[0]*cell.position.y + cell.position.x, vcat(map(render, obj2)...))
  length(intersect(nums1, nums2)) != 0
end

function intersects(list1, list2, state=nothing)::Bool
  length(intersect(list1, list2)) != 0 
end

function intersects(object::NamedTuple, state)::Bool
  objects = state.scene.objects
  intersects(object, objects, state)
end

function addObj(list::AbstractArray, obj::NamedTuple, state=nothing)
  obj = update_nt(obj, :changed, true)
  new_list = vcat(list, obj)
  new_list
end

function addObj(list::AbstractArray, objs::AbstractArray, state=nothing)
  objs = map(obj -> update_nt(obj, :changed, true), objs)
  new_list = vcat(list, objs)
  new_list
end

function removeObj(list::AbstractArray, obj::NamedTuple, state=nothing)
  new_list = deepcopy(list)
  for x in filter(o -> o.id == obj.id, new_list)
    index = findall(o -> o.id == x.id, new_list)[1]
    new_list[index] = update_nt(update_nt(x, :alive, false), :changed, true)
    #x.alive = false 
    #x.changed = true
  end
  new_list
end

function removeObj(list::AbstractArray, fn, state=nothing)
  new_list = deepcopy(list)
  for x in filter(obj -> fn(obj), new_list)
    index = findall(o -> o.id == x.id, new_list)[1]
    new_list[index] = update_nt(update_nt(x, :alive, false), :changed, true)
    #x.alive = false 
    #x.changed = true
  end
  new_list
end

function removeObj(obj::NamedTuple, state=nothing)
  new_obj = deepcopy(obj)
  new_obj = update_nt(update_nt(new_obj, :alive, false), :changed, true)
  # new_obj.alive = false
  # new_obj.changed = true
  # new_obj
end

function updateObj(obj::NamedTuple, field::String, value, state=nothing)
  fields = fieldnames(typeof(obj))
  custom_fields = fields[5:end-1]
  origin_field = (fields[2],)

  constructor_fields = (custom_fields..., origin_field...)
  constructor_values = map(x -> x == Symbol(field) ? value : getproperty(obj, x), constructor_fields)

  new_obj = typeof(obj)(constructor_values...)
  setproperty!(new_obj, :id, obj.id)
  setproperty!(new_obj, :alive, obj.alive)
  setproperty!(new_obj, :changed, obj.changed)

  setproperty!(new_obj, Symbol(field), value)
  state.objectsCreated -= 1    
  new_obj
end

function filter_fallback(obj::NamedTuple, state=nothing)
  true
end

function updateObj(list::AbstractArray, map_fn, filter_fn, state::NamedTuple=nothing)
  orig_list = filter(obj -> !filter_fn(obj), list)
  filtered_list = filter(filter_fn, list)
  new_filtered_list = map(map_fn, filtered_list)
  foreach(obj -> obj.changed = true, new_filtered_list)
  vcat(orig_list, new_filtered_list)
end

function updateObj(list::AbstractArray, map_fn, state::NamedTuple=nothing)
  orig_list = filter(obj -> false, list)
  filtered_list = filter(obj -> true, list)
  new_filtered_list = map(map_fn, filtered_list)
  foreach(obj -> obj.changed = true, new_filtered_list)
  vcat(orig_list, new_filtered_list)
end

function adjPositions(position::Position, state)::Array{Position}
  filter(x -> isWithinBounds(x, state), [Position(position.x, position.y + 1), Position(position.x, position.y - 1), Position(position.x + 1, position.y), Position(position.x - 1, position.y)])
end

function isWithinBounds(position::Position, state)::Bool
  (position.x >= 0) && (position.x < state.GRID_SIZEHistory[0]) && (position.y >= 0) && (position.y < state.GRID_SIZEHistory[0])                          
end

function isFree(position::Position, state)::Bool
  length(filter(cell -> cell.position.x == position.x && cell.position.y == position.y, render(state.scene))) == 0
end

function isFree(click::Union{Click, Nothing}, state)::Bool
  if click == nothing
    false
  else
    isFree(Position(click.x, click.y), state)
  end
end

function rect(pos1::Position, pos2::Position, state=nothing)
  min_x = pos1.x 
  max_x = pos2.x 
  min_y = pos1.y
  max_y = pos2.y 

  positions = []
  for x in min_x:max_x 
    for y in min_y:max_y
      push!(positions, Position(x, y))
    end
  end
  positions
end

function unitVector(position1::Position, position2::Position, state)::Position
  deltaX = position2.x - position1.x
  deltaY = position2.y - position1.y
  if (floor(Int, abs(sign(deltaX))) == 1 && floor(Int, abs(sign(deltaY))) == 1)
    Position(sign(deltaX), 0)
    # uniformChoice(rng, [Position(sign(deltaX), 0), Position(0, sign(deltaY))])
  else
    Position(sign(deltaX), sign(deltaY))  
  end
end

function unitVector(object1::NamedTuple, object2::NamedTuple, state)::Position
  position1 = object1.origin
  position2 = object2.origin
  unitVector(position1, position2, state)
end

function unitVector(object::NamedTuple, position::Position, state)::Position
  unitVector(object.origin, position, state)
end

function unitVector(position::Position, object::NamedTuple, state)::Position
  unitVector(position, object.origin, state)
end

function unitVector(position::Position, state)::Position
  unitVector(Position(0,0), position, state)
end 

function displacement(position1::Position, position2::Position, state)::Position
  Position(floor(Int, position2.x - position1.x), floor(Int, position2.y - position1.y))
end

function displacement(cell1::Cell, cell2::Cell, state=nothing)::Position
  displacement(cell1.position, cell2.position)
end

function adjacent(position1::Position, position2::Position, state=nothing)::Bool
  displacement(position1, position2) in [Position(0,1), Position(1, 0), Position(0, -1), Position(-1, 0)]
end

function adjacent(cell1::Cell, cell2::Cell, state=nothing)::Bool
  adjacent(cell1.position, cell2.position)
end

function adjacent(cell::Cell, cells::Array{Cell}, state=nothing)
  length(filter(x -> adjacent(cell, x), cells)) != 0
end

function adjacentObjs(obj::NamedTuple, state)
  filter(o -> adjacent(o.origin, obj.origin) && (obj.id != o.id), state.scene.objects)
end

function adjacentObjsDiag(obj::NamedTuple, state)
  filter(o -> adjacentDiag(o.origin, obj.origin) && (obj.id != o.id), state.scene.objects)
end

function adjacentDiag(position1::Position, position2::Position, state=nothing)
  displacement(position1, position2) in [Position(0,1), Position(1, 0), Position(0, -1), Position(-1, 0),
                                         Position(1,1), Position(1, -1), Position(-1, 1), Position(-1, -1)]
end

function rotate(object::NamedTuple, state=nothing)::NamedTuple
  new_object = deepcopy(object)
  new_object = update_nt(new_object, :render, map(x -> Cell(rotate(x.position), x.color), new_object.render))
  new_object
end

function rotate(position::Position, state=nothing)::Position
  Position(-position.y, position.x)
 end

function rotateNoCollision(object::NamedTuple, state)::NamedTuple
  (isWithinBounds(rotate(object), state) && isFree(rotate(object), object), state) ? rotate(object) : object
end

function move(position1::Position, position2::Position, state=nothing)
  Position(position1.x + position2.x, position1.y + position2.y)
end

function move(position::Position, cell::Cell, state=nothing)
  Position(position.x + cell.position.x, position.y + cell.position.y)
end

function move(cell::Cell, position::Position, state=nothing)
  Position(position.x + cell.position.x, position.y + cell.position.y)
end

function move(object::NamedTuple, position::Position, state=nothing)
  new_object = deepcopy(object)
  new_object = update_nt(new_object, :origin, move(object.origin, position))
  new_object
end

function move(object::NamedTuple, x::Int, y::Int, state=nothing)::NamedTuple
  move(object, Position(x, y))                          
end

# ----- begin left/right move ----- #

function moveLeft(object::NamedTuple, state=nothing)::NamedTuple
  move(object, Position(-1, 0))                          
end

function moveRight(object::NamedTuple, state=nothing)::NamedTuple
  move(object, Position(1, 0))                          
end

function moveUp(object::NamedTuple, state=nothing)::NamedTuple
  move(object, Position(0, -1))                          
end

function moveDown(object::NamedTuple, state=nothing)::NamedTuple
  move(object, Position(0, 1))                          
end

# ----- end left/right move ----- #

function moveNoCollision(object::NamedTuple, position::Position, state)::NamedTuple
  (isWithinBounds(move(object, position), state) && isFree(move(object, position.x, position.y), object, state)) ? move(object, position.x, position.y) : object 
end

function moveNoCollision(object::NamedTuple, x::Int, y::Int, state)
  (isWithinBounds(move(object, x, y), state) && isFree(move(object, x, y), object, state)) ? move(object, x, y) : object 
end

# ----- begin left/right moveNoCollision ----- #

function moveLeftNoCollision(object::NamedTuple, state)::NamedTuple
  (isWithinBounds(move(object, -1, 0), state) && isFree(move(object, -1, 0), object, state)) ? move(object, -1, 0) : object 
end

function moveRightNoCollision(object::NamedTuple, state)::NamedTuple
  (isWithinBounds(move(object, 1, 0), state) && isFree(move(object, 1, 0), object, state)) ? move(object, 1, 0) : object 
end

function moveUpNoCollision(object::NamedTuple, state)::NamedTuple
  (isWithinBounds(move(object, 0, -1), state) && isFree(move(object, 0, -1), object, state)) ? move(object, 0, -1) : object 
end

function moveDownNoCollision(object::NamedTuple, state)::NamedTuple
  (isWithinBounds(move(object, 0, 1), state) && isFree(move(object, 0, 1), object, state)) ? move(object, 0, 1) : object 
end

# ----- end left/right moveNoCollision ----- #

function moveWrap(object::NamedTuple, position::Position, state)::NamedTuple
  new_object = deepcopy(object)
  new_object = update_nt(new_object, :origin, moveWrap(object.origin, position.x, position.y, state))
  new_object
end

function moveWrap(cell::Cell, position::Position, state)
  moveWrap(cell.position, position.x, position.y, state)
end

function moveWrap(position::Position, cell::Cell, state)
  moveWrap(cell.position, position, state)
end

function moveWrap(object::NamedTuple, x::Int, y::Int, state)::NamedTuple
  new_object = deepcopy(object)
  new_object = update_nt(new_object, :origin, moveWrap(object.origin, x, y, state))
  new_object
end

function moveWrap(position1::Position, position2::Position, state)::Position
  moveWrap(position1, position2.x, position2.y, state)
end

function moveWrap(position::Position, x::Int, y::Int, state)::Position
  GRID_SIZE = state.GRID_SIZEHistory[0]
  # println("hello")
  # println(Position((position.x + x + GRID_SIZE) % GRID_SIZE, (position.y + y + GRID_SIZE) % GRID_SIZE))
  Position((position.x + x + GRID_SIZE) % GRID_SIZE, (position.y + y + GRID_SIZE) % GRID_SIZE)
end

# ----- begin left/right moveWrap ----- #

function moveLeftWrap(object::NamedTuple, state=nothing)::NamedTuple
  new_object = deepcopy(object)
  new_object = update_nt(new_object, :origin, moveWrap(object.origin, -1, 0, state))
  new_object
end
  
function moveRightWrap(object::NamedTuple, state=nothing)::NamedTuple
  new_object = deepcopy(object)
  new_object = update_nt(new_object, :origin, moveWrap(object.origin, 1, 0, state))
  new_object
end

function moveUpWrap(object::NamedTuple, state=nothing)::NamedTuple
  new_object = deepcopy(object)
  new_object = update_nt(new_object, :origin, moveWrap(object.origin, 0, -1, state))
  new_object
end

function moveDownWrap(object::NamedTuple, state=nothing)::NamedTuple
  new_object = deepcopy(object)
  new_object = update_nt(new_object, :origin, moveWrap(object.origin, 0, 1, state))
  new_object
end

# ----- end left/right moveWrap ----- #

function randomPositions(GRID_SIZE::Int, n::Int, state=nothing)::Array{Position}
  nums = uniformChoice([0:(GRID_SIZE * GRID_SIZE - 1);], n, state)
  # println(nums)
  # println(map(num -> Position(num % GRID_SIZE, floor(Int, num / GRID_SIZE)), nums))
  map(num -> Position(num % GRID_SIZE, floor(Int, num / GRID_SIZE)), nums)
end

function distance(position1::Position, position2::Position, state=nothing)::Int
  abs(position1.x - position2.x) + abs(position1.y - position2.y)
end

function distance(object1::NamedTuple, object2::NamedTuple, state=nothing)::Int
  position1 = object1.origin
  position2 = object2.origin
  distance(position1, position2)
end

function distance(object::NamedTuple, position::Position, state=nothing)::Int
  distance(object.origin, position)
end

function distance(position::Position, object::NamedTuple, state=nothing)::Int
  distance(object.origin, position)
end

function closest(object::NamedTuple, type::Symbol, state)::Position
  objects_of_type = filter(obj -> (obj.type == type) && (obj.alive), state.scene.objects)
  if length(objects_of_type) == 0
    object.origin
  else
    min_distance = min(map(obj -> distance(object, obj), objects_of_type))
    filter(obj -> distance(object, obj) == min_distance, objects_of_type)[1].origin
  end
end

function mapPositions(constructor, GRID_SIZE::Int, filterFunction, args, state=nothing)::Union{Object, Array{<:Object}}
  map(pos -> constructor(args..., pos), filter(filterFunction, allPositions(GRID_SIZE)))
end

function allPositions(GRID_SIZE::Int, state=nothing)
  nums = [0:(GRID_SIZE * GRID_SIZE - 1);]
  map(num -> Position(num % GRID_SIZE, floor(Int, num / GRID_SIZE)), nums)
end

function updateOrigin(object::NamedTuple, new_origin::Position, state=nothing)::NamedTuple
  new_object = deepcopy(object)
  new_object = update_nt(new_object, :origin, new_origin)
  new_object
end

function updateAlive(object::NamedTuple, new_alive::Bool, state=nothing)::NamedTuple
  new_object = deepcopy(object)
  new_object = update_nt(new_object, :alive, new_alive)
  new_object
end

function nextLiquid(object::NamedTuple, state)::NamedTuple 
  # println("nextLiquid")
  GRID_SIZE = state.GRID_SIZEHistory[0]
  new_object = deepcopy(object)
  if object.origin.y != GRID_SIZE - 1 && isFree(move(object.origin, Position(0, 1)), state)
    new_object = update_nt(new_object, :origin, move(object.origin, Position(0, 1)))
  else
    leftHoles = filter(pos -> (pos.y == object.origin.y + 1)
                               && (pos.x < object.origin.x)
                               && isFree(pos, state), allPositions(state))
    rightHoles = filter(pos -> (pos.y == object.origin.y + 1)
                               && (pos.x > object.origin.x)
                               && isFree(pos, state), allPositions(state))
    if (length(leftHoles) != 0) || (length(rightHoles) != 0)
      if (length(leftHoles) == 0)
        closestHole = closest(object, rightHoles)
        if isFree(move(closestHole, Position(0, -1)), move(object.origin, Position(1, 0)), state)
          new_object = update_nt(new_object, :origin, move(object.origin, unitVector(object, move(closestHole, Position(0, -1)), state), state))
        end
      elseif (length(rightHoles) == 0)
        closestHole = closest(object, leftHoles)
        if isFree(move(closestHole, Position(0, -1)), move(object.origin, Position(-1, 0)), state)
          new_object = update_nt(new_object, :origin, move(object.origin, unitVector(object, move(closestHole, Position(0, -1)), state)))                      
        end
      else
        closestLeftHole = closest(object, leftHoles)
        closestRightHole = closest(object, rightHoles)
        if distance(object.origin, closestLeftHole) > distance(object.origin, closestRightHole)
          if isFree(move(object.origin, Position(1, 0)), move(closestRightHole, Position(0, -1)), state)
            new_object = update_nt(new_object, :origin, move(object.origin, unitVector(new_object, move(closestRightHole, Position(0, -1)), state)))
          elseif isFree(move(closestLeftHole, Position(0, -1)), move(object.origin, Position(-1, 0)), state)
            new_object = update_nt(new_object, :origin, move(object.origin, unitVector(new_object, move(closestLeftHole, Position(0, -1)), state)))
          end
        else
          if isFree(move(closestLeftHole, Position(0, -1)), move(object.origin, Position(-1, 0)), state)
            new_object = update_nt(new_object, :origin, move(object.origin, unitVector(new_object, move(closestLeftHole, Position(0, -1)), state)))
          elseif isFree(move(object.origin, Position(1, 0)), move(closestRightHole, Position(0, -1)), state)
            new_object = update_nt(new_object, :origin, move(object.origin, unitVector(new_object, move(closestRightHole, Position(0, -1)), state)))
          end
        end
      end
    end
  end
  new_object
end

function nextSolid(object::NamedTuple, state)::NamedTuple 
  # println("nextSolid")
  GRID_SIZE = state.GRID_SIZEHistory[0] 
  new_object = deepcopy(object)
  if (isWithinBounds(move(object, Position(0, 1)), state) && reduce(&, map(x -> isFree(x, object, state), map(cell -> move(cell.position, Position(0, 1)), render(object)))))
    new_object = update_nt(new_object, :origin, move(object.origin, Position(0, 1)))
  end
  new_object
end

function closest(object::NamedTuple, positions::Array{Position}, state=nothing)::Position
  closestDistance = sort(map(pos -> distance(pos, object.origin), positions))[1]
  closest = filter(pos -> distance(pos, object.origin) == closestDistance, positions)[1]
  closest
end

function isFree(start::Position, stop::Position, state)::Bool 
  GRID_SIZE = state.GRID_SIZEHistory[0]
  nums = [(GRID_SIZE * start.y + start.x):(GRID_SIZE * stop.y + stop.x);]
  reduce(&, map(num -> isFree(Position(num % GRID_SIZE, floor(Int, num / GRID_SIZE)), state), nums))
end

function isFree(start::Position, stop::Position, object::NamedTuple, state)::Bool 
  GRID_SIZE = state.GRID_SIZEHistory[0]
  nums = [(GRID_SIZE * start.y + start.x):(GRID_SIZE * stop.y + stop.x);]
  reduce(&, map(num -> isFree(Position(num % GRID_SIZE, floor(Int, num / GRID_SIZE)), object, state), nums))
end

function isFree(position::Position, object::NamedTuple, state)
  length(filter(cell -> cell.position.x == position.x && cell.position.y == position.y, 
  render((objects=filter(obj -> obj.id != object.id , state.scene.objects), background=state.scene.background)))) == 0
end

function isFree(object::NamedTuple, orig_object::NamedTuple, state)::Bool
  reduce(&, map(x -> isFree(x, orig_object, state), map(cell -> cell.position, render(object))))
end

function allPositions(state)
  GRID_SIZE = state.GRID_SIZEHistory[0]
  nums = [1:GRID_SIZE*GRID_SIZE - 1;]
  map(num -> Position(num % GRID_SIZE, floor(Int, num / GRID_SIZE)), nums)
end

function unfold(A, state=nothing)
  V = []
  for x in A
      for elt in x
        push!(V, elt)
      end
  end
  V
end

end