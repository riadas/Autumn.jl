module AutumnStandardLibrary
using Distributions: Categorical

update_nt(@nospecialize(Γ::NamedTuple), x::Symbol, v) = merge(Γ, NamedTuple{(x,)}((v,)))

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

Click(x, y, @nospecialize(state::NamedTuple)) = Click(x, y)

struct Position
  x::Int
  y::Int
end

Position(x, y, @nospecialize(state::NamedTuple)) = Position(x, y) 

struct Cell 
  position::Position
  color::String
  opacity::Float64
end

Cell(position::Position, color::String) = Cell(position, color, 0.8)
Cell(x::Int, y::Int, color::String) = Cell(Position(floor(Int, x), floor(Int, y)), color, 0.8)
# Cell(x::Int, y::Int, color::String, opacity::Float64) = Cell(Position(floor(Int, x), floor(Int, y)), color, opacity)

Cell(x, y, color::String, @nospecialize(state::NamedTuple)) = Cell(floor(Int, x), floor(Int, y), color)
Cell(position::Position, color::String, @nospecialize(state::NamedTuple)) = Cell(position::Position, color::String)

# struct Scene
#   objects::Array{Object}
#   background::String
# end

# Scene(@nospecialize(objects::AbstractArray)) = Scene(objects, "#ffffff00")

# function render(scene)::Array{Cell}
#   vcat(map(obj -> render(obj), filter(obj -> obj.alive, scene.objects))...)
# end

function prev(@nospecialize(obj::NamedTuple), @nospecialize(state))
  prev_objects = filter(o -> o.id == obj.id, state.scene.objects)
  if prev_objects != []
    prev_objects[1]                            
  else
    obj
  end
end

function render(@nospecialize(obj::NamedTuple), @nospecialize(state=nothing))::Array{Cell}
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


function occurred(click, @nospecialize(state=nothing))
  !isnothing(click)
end

function uniformChoice(freePositions, @nospecialize(state::NamedTuple))
  freePositions[rand(state.rng, Categorical(ones(length(freePositions))/length(freePositions)))]
end

function uniformChoice(freePositions, n::Union{Int, BigInt}, @nospecialize(state::NamedTuple))
  map(idx -> freePositions[idx], rand(state.rng, Categorical(ones(length(freePositions))/length(freePositions)), n))
end

function min(arr, @nospecialize(state=nothing))
  Base.min(arr...)
end

function range(start::Int, stop::Int, @nospecialize(state=nothing))
  [start:stop;]
end

function isWithinBounds(@nospecialize(obj::NamedTuple), @nospecialize(state::NamedTuple))::Bool
  # # println(filter(cell -> !isWithinBounds(cell.position),render(obj)))
  length(filter(cell -> !isWithinBounds(cell.position, state), render(obj))) == 0
end

function clicked(click::Union{Click, Nothing}, @nospecialize(object::NamedTuple), @nospecialize(state::NamedTuple))::Bool
  if isnothing(click)
    false
  else
    GRID_SIZE = state.GRID_SIZEHistory[0]
    if GRID_SIZE isa AbstractArray 
      GRID_SIZE_X = GRID_SIZE[1]
      nums = map(cell -> GRID_SIZE_X*cell.position.y + cell.position.x, render(object))
      (GRID_SIZE_X * click.y + click.x) in nums
    else
      nums = map(cell -> GRID_SIZE*cell.position.y + cell.position.x, render(object))
      (GRID_SIZE * click.y + click.x) in nums
    end

  end
end

function clicked(click::Union{Click, Nothing}, @nospecialize(objects::AbstractArray), @nospecialize(state::NamedTuple))  
  # # println("LOOK AT ME")
  # # println(reduce(&, map(obj -> clicked(click, obj), objects)))
  if isnothing(click)
    false
  else
    foldl(|, map(obj -> clicked(click, obj, state), objects), init=false)
  end
end

function objClicked(click::Union{Click, Nothing}, @nospecialize(objects::AbstractArray), @nospecialize(state=nothing))::Union{NamedTuple, Nothing}
  # # println(click)
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

function clicked(click::Union{Click, Nothing}, x::Int, y::Int, @nospecialize(state::NamedTuple))::Bool
  if click == nothing
    false
  else
    click.x == x && click.y == y                         
  end
end

function clicked(click::Union{Click, Nothing}, pos::Position, @nospecialize(state::NamedTuple))::Bool
  if click == nothing
    false
  else
    click.x == pos.x && click.y == pos.y                         
  end
end

function intersects(@nospecialize(obj1::NamedTuple), @nospecialize(obj2::NamedTuple), @nospecialize(state::NamedTuple))::Bool
  GRID_SIZE = state.GRID_SIZEHistory[0]
  if GRID_SIZE isa AbstractArray 
    GRID_SIZE_X = GRID_SIZE[1]
    GRID_SIZE_Y = GRID_SIZE[2]
    nums1 = map(cell -> GRID_SIZE_X*cell.position.y + cell.position.x, render(obj1))
    nums2 = map(cell -> GRID_SIZE_X*cell.position.y + cell.position.x, render(obj2))
    length(intersect(nums1, nums2)) != 0
  else
    nums1 = map(cell -> state.GRID_SIZEHistory[0]*cell.position.y + cell.position.x, render(obj1))
    nums2 = map(cell -> state.GRID_SIZEHistory[0]*cell.position.y + cell.position.x, render(obj2))
    length(intersect(nums1, nums2)) != 0
  end
end

function intersects(@nospecialize(obj1::NamedTuple), @nospecialize(obj2::AbstractArray), @nospecialize(state::NamedTuple))::Bool
  GRID_SIZE = state.GRID_SIZEHistory[0]
  if GRID_SIZE isa AbstractArray 
    GRID_SIZE_X = GRID_SIZE[1]
    nums1 = map(cell -> GRID_SIZE_X*cell.position.y + cell.position.x, render(obj1))
    nums2 = map(cell -> GRID_SIZE_X*cell.position.y + cell.position.x, vcat(map(render, obj2)...))
    length(intersect(nums1, nums2)) != 0
  else
    nums1 = map(cell -> state.GRID_SIZEHistory[0]*cell.position.y + cell.position.x, render(obj1))
    nums2 = map(cell -> state.GRID_SIZEHistory[0]*cell.position.y + cell.position.x, vcat(map(render, obj2)...))
    length(intersect(nums1, nums2)) != 0
  end
end

function intersects(@nospecialize(obj2::AbstractArray), @nospecialize(obj1::NamedTuple), @nospecialize(state::NamedTuple))::Bool
  GRID_SIZE = state.GRID_SIZEHistory[0] 
  if GRID_SIZE isa AbstractArray 
    GRID_SIZE_X = GRID_SIZE[1]
    nums1 = map(cell -> GRID_SIZE_X*cell.position.y + cell.position.x, render(obj1))
    nums2 = map(cell -> GRID_SIZE_X*cell.position.y + cell.position.x, vcat(map(render, obj2)...))
    length(intersect(nums1, nums2)) != 0
  else
    nums1 = map(cell -> state.GRID_SIZEHistory[0]*cell.position.y + cell.position.x, render(obj1))
    nums2 = map(cell -> state.GRID_SIZEHistory[0]*cell.position.y + cell.position.x, vcat(map(render, obj2)...))
    length(intersect(nums1, nums2)) != 0
  end
end

function intersects(@nospecialize(obj1::AbstractArray), @nospecialize(obj2::AbstractArray), @nospecialize(state::NamedTuple))::Bool
  # # println("INTERSECTS")
  # # @show typeof(obj1) 
  # # @show typeof(obj2) 
  if (length(obj1) == 0) || (length(obj2) == 0)
    false  
  elseif (obj1[1] isa NamedTuple) && (obj2[1] isa NamedTuple)
    # # println("MADE IT")
    GRID_SIZE = state.GRID_SIZEHistory[0]
    if GRID_SIZE isa AbstractArray 
      GRID_SIZE_X = GRID_SIZE[1]
      nums1 = map(cell -> GRID_SIZE_X*cell.position.y + cell.position.x, vcat(map(render, obj1)...))
      nums2 = map(cell -> GRID_SIZE_X*cell.position.y + cell.position.x, vcat(map(render, obj2)...))
      length(intersect(nums1, nums2)) != 0
    else
      nums1 = map(cell -> state.GRID_SIZEHistory[0]*cell.position.y + cell.position.x, vcat(map(render, obj1)...))
      nums2 = map(cell -> state.GRID_SIZEHistory[0]*cell.position.y + cell.position.x, vcat(map(render, obj2)...))
      length(intersect(nums1, nums2)) != 0
    end
  else
    length(intersect(obj1, obj2)) != 0 
  end
end

function intersects(@nospecialize(object::NamedTuple), @nospecialize(state::NamedTuple))::Bool
  objects = state.scene.objects
  intersects(object, objects, state)
end

function addObj(@nospecialize(list::AbstractArray), @nospecialize(obj::NamedTuple), @nospecialize(state=nothing))
  obj = update_nt(obj, :changed, true)
  new_list = vcat(list, obj)
  new_list
end

function addObj(@nospecialize(list::AbstractArray), @nospecialize(objs::AbstractArray), @nospecialize(state=nothing))
  objs = map(obj -> update_nt(obj, :changed, true), objs)
  new_list = vcat(list, objs)
  new_list
end

function removeObj(@nospecialize(list::AbstractArray), @nospecialize(obj::NamedTuple), @nospecialize(state=nothing))
  new_list = deepcopy(list)
  for x in filter(o -> o.id == obj.id, new_list)
    index = findall(o -> o.id == x.id, new_list)[1]
    new_list[index] = update_nt(update_nt(x, :alive, false), :changed, true)
    #x.alive = false 
    #x.changed = true
  end
  new_list
end

function removeObj(@nospecialize(list::AbstractArray), fn, @nospecialize(state=nothing))
  new_list = deepcopy(list)
  for x in filter(obj -> fn(obj), new_list)
    index = findall(o -> o.id == x.id, new_list)[1]
    new_list[index] = update_nt(update_nt(x, :alive, false), :changed, true)
    #x.alive = false 
    #x.changed = true
  end
  new_list
end

function removeObj(@nospecialize(obj::NamedTuple), @nospecialize(state=nothing))
  new_obj = deepcopy(obj)
  new_obj = update_nt(update_nt(new_obj, :alive, false), :changed, true)
  # new_obj.alive = false
  # new_obj.changed = true
  # new_obj
end

function updateObj(@nospecialize(obj::NamedTuple), field::String, value, @nospecialize(state=nothing))
  fields = fieldnames(typeof(obj))
  custom_fields = fields[5:end-1]
  origin_field = (fields[2],)

  constructor_fields = (custom_fields..., origin_field...)
  constructor_values = map(x -> x == Symbol(field) ? value : getproperty(obj, x), constructor_fields)

  new_obj = typeof(obj)(constructor_values...)
  setproperty!(new_obj, :id, obj.id)
  setproperty!(new_obj, :alive, obj.alive)
  setproperty!(new_obj, :changed, true)

  setproperty!(new_obj, Symbol(field), value)
  state.objectsCreated -= 1    
  new_obj
end

function filter_fallback(@nospecialize(obj::NamedTuple), @nospecialize(state=nothing))
  true
end

# function updateObj(@nospecialize(list::AbstractArray), map_fn, filter_fn, @nospecialize(state=nothing))
#   orig_list = filter(obj -> !filter_fn(obj), list)
#   filtered_list = filter(filter_fn, list)
#   new_filtered_list = map(map_fn, filtered_list)
#   foreach(obj -> obj.changed = true, new_filtered_list)
#   vcat(orig_list, new_filtered_list)
# end

# function updateObj(@nospecialize(list::AbstractArray), map_fn, @nospecialize(state=nothing))
#   orig_list = filter(obj -> false, list)
#   filtered_list = filter(obj -> true, list)
#   new_filtered_list = map(map_fn, filtered_list)
#   foreach(obj -> obj.changed = true, new_filtered_list)
#   vcat(orig_list, new_filtered_list)
# end

function adjPositions(position::Position, @nospecialize(state::NamedTuple))::Array{Position}
  filter(x -> isWithinBounds(x, state), [Position(position.x, position.y + 1), Position(position.x, position.y - 1), Position(position.x + 1, position.y), Position(position.x - 1, position.y)])
end

function isWithinBounds(position::Position, @nospecialize(state::NamedTuple))::Bool
  GRID_SIZE = state.GRID_SIZEHistory[0] 
  if GRID_SIZE isa AbstractArray 
    GRID_SIZE_X = GRID_SIZE[1]
    GRID_SIZE_Y = GRID_SIZE[2]
  else
    GRID_SIZE_X = GRID_SIZE
    GRID_SIZE_Y = GRID_SIZE
  end
  (position.x >= 0) && (position.x < GRID_SIZE_X) && (position.y >= 0) && (position.y < GRID_SIZE_Y)                  
end

function isFree(position::Position, @nospecialize(state::NamedTuple))::Bool
  length(filter(cell -> cell.position.x == position.x && cell.position.y == position.y, render(state.scene))) == 0
end

function isFree(click::Union{Click, Nothing}, @nospecialize(state::NamedTuple))::Bool
  if click == nothing
    false
  else
    isFree(Position(click.x, click.y), state)
  end
end

function isFree(positions::AbstractArray)::Bool 
  foldl(&, map(pos -> isFree(pos), positions), init=true)
end

function rect(pos1::Position, pos2::Position, @nospecialize(state=nothing))
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

function unitVector(position1::Position, position2::Position, @nospecialize(state::NamedTuple))::Position
  deltaX = position2.x - position1.x
  deltaY = position2.y - position1.y
  if (floor(Int, abs(sign(deltaX))) == 1 && floor(Int, abs(sign(deltaY))) == 1)
    Position(sign(deltaX), 0)
    # uniformChoice(rng, [Position(sign(deltaX), 0), Position(0, sign(deltaY))])
  else
    Position(sign(deltaX), sign(deltaY))  
  end
end

function unitVector(object1::NamedTuple, object2::NamedTuple, @nospecialize(state::NamedTuple))::Position
  position1 = object1.origin
  position2 = object2.origin
  unitVector(position1, position2, state)
end

function unitVector(@nospecialize(object::NamedTuple), position::Position, @nospecialize(state::NamedTuple))::Position
  unitVector(object.origin, position, state)
end

function unitVector(position::Position, @nospecialize(object::NamedTuple), @nospecialize(state::NamedTuple))::Position
  unitVector(position, object.origin, state)
end

function unitVector(position::Position, @nospecialize(state::NamedTuple))::Position
  unitVector(Position(0,0), position, state)
end 

function displacement(position1::Position, position2::Position, @nospecialize(state=nothing))::Position
  Position(floor(Int, position2.x - position1.x), floor(Int, position2.y - position1.y))
end

function displacement(cell1::Cell, cell2::Cell, @nospecialize(state=nothing))::Position
  displacement(cell1.position, cell2.position)
end

function adjacent(position1::Position, position2::Position, @nospecialize(state=nothing))::Bool
  displacement(position1, position2) in [Position(0,1), Position(1, 0), Position(0, -1), Position(-1, 0)]
end

function adjacent(cell1::Cell, cell2::Cell, @nospecialize(state=nothing))::Bool
  adjacent(cell1.position, cell2.position)
end

function adjacent(cell::Cell, cells::AbstractArray, @nospecialize(state=nothing))
  length(filter(x -> adjacent(cell, x), cells)) != 0
end

function adjacentObjs(@nospecialize(obj::NamedTuple), @nospecialize(state::NamedTuple))
  filter(o -> adjacent(o.origin, obj.origin) && (obj.id != o.id), state.scene.objects)
end

function adjacentObjsDiag(@nospecialize(obj::NamedTuple), @nospecialize(state::NamedTuple))
  filter(o -> adjacentDiag(o.origin, obj.origin) && (obj.id != o.id), state.scene.objects)
end

function adjacentDiag(position1::Position, position2::Position, @nospecialize(state=nothing))
  displacement(position1, position2) in [Position(0,1), Position(1, 0), Position(0, -1), Position(-1, 0),
                                         Position(1,1), Position(1, -1), Position(-1, 1), Position(-1, -1)]
end

function rotate(@nospecialize(object::NamedTuple), @nospecialize(state=nothing))::NamedTuple
  new_object = deepcopy(object)
  new_object = update_nt(new_object, :render, map(x -> Cell(rotate(x.position), x.color), new_object.render))
  new_object
end

function rotate(position::Position, @nospecialize(state=nothing))::Position
  Position(-position.y, position.x)
 end

function rotateNoCollision(@nospecialize(object::NamedTuple), @nospecialize(state::NamedTuple))::NamedTuple
  (isWithinBounds(rotate(object), state) && isFree(rotate(object), object, state)) ? rotate(object) : object
end

function move(position1::Position, position2::Position, @nospecialize(state=nothing))
  Position(position1.x + position2.x, position1.y + position2.y)
end

function move(position::Position, cell::Cell, @nospecialize(state=nothing))
  Position(position.x + cell.position.x, position.y + cell.position.y)
end

function move(cell::Cell, position::Position, @nospecialize(state=nothing))
  Position(position.x + cell.position.x, position.y + cell.position.y)
end

function move(@nospecialize(object::NamedTuple), position::Position, @nospecialize(state=nothing))
  new_object = deepcopy(object)
  new_object = update_nt(new_object, :origin, move(object.origin, position))
  new_object
end

function move(@nospecialize(object::NamedTuple), x::Int, y::Int, @nospecialize(state=nothing))::NamedTuple
  move(object, Position(x, y))                          
end

# ----- begin left/right move ----- #

function moveLeft(@nospecialize(object::NamedTuple), @nospecialize(state=nothing))::NamedTuple
  move(object, Position(-1, 0))                          
end

function moveRight(@nospecialize(object::NamedTuple), @nospecialize(state=nothing))::NamedTuple
  move(object, Position(1, 0))                          
end

function moveUp(@nospecialize(object::NamedTuple), @nospecialize(state=nothing))::NamedTuple
  move(object, Position(0, -1))                          
end

function moveDown(@nospecialize(object::NamedTuple), @nospecialize(state=nothing))::NamedTuple
  move(object, Position(0, 1))                          
end

# ----- end left/right move ----- #

function moveNoCollision(@nospecialize(object::NamedTuple), position::Position, @nospecialize(state::NamedTuple))::NamedTuple
  (isWithinBounds(move(object, position), state) && isFree(move(object, position.x, position.y), object, state)) ? move(object, position.x, position.y) : object 
end

function moveNoCollision(@nospecialize(object::NamedTuple), x::Int, y::Int, @nospecialize(state::NamedTuple))
  (isWithinBounds(move(object, x, y), state) && isFree(move(object, x, y), object, state)) ? move(object, x, y) : object 
end

function moveNoCollisionColor(@nospecialize(object::NamedTuple), position::Position, color::String, @nospecialize(state::NamedTuple))::NamedTuple
  new_object = move(object, position) 
  matching_color_objects = filter(obj -> intersects(new_object, obj, state) && (color in map(cell -> cell.color, render(obj, state))), state.scene.objects)
  if matching_color_objects == []
    new_object
  else
    object 
  end
end

function moveNoCollisionColor(@nospecialize(object::NamedTuple), x::Int, y::Int, color::String, @nospecialize(state::NamedTuple))::NamedTuple
  new_object = move(object, Position(x, y)) 
  matching_color_objects = filter(obj -> intersects(new_object, obj, state) && (color in map(cell -> cell.color, render(obj, state))), state.scene.objects)
  if matching_color_objects == []
    new_object
  else
    object 
  end
end

# ----- begin left/right moveNoCollision ----- #

function moveLeftNoCollision(@nospecialize(object::NamedTuple), @nospecialize(state::NamedTuple))::NamedTuple
  (isWithinBounds(move(object, -1, 0), state) && isFree(move(object, -1, 0), object, state)) ? move(object, -1, 0) : object 
end

function moveRightNoCollision(@nospecialize(object::NamedTuple), @nospecialize(state::NamedTuple))::NamedTuple
  (isWithinBounds(move(object, 1, 0), state) && isFree(move(object, 1, 0), object, state)) ? move(object, 1, 0) : object 
end

function moveUpNoCollision(@nospecialize(object::NamedTuple), @nospecialize(state::NamedTuple))::NamedTuple
  (isWithinBounds(move(object, 0, -1), state) && isFree(move(object, 0, -1), object, state)) ? move(object, 0, -1) : object 
end

function moveDownNoCollision(@nospecialize(object::NamedTuple), @nospecialize(state::NamedTuple))::NamedTuple
  (isWithinBounds(move(object, 0, 1), state) && isFree(move(object, 0, 1), object, state)) ? move(object, 0, 1) : object 
end

# ----- end left/right moveNoCollision ----- #

function moveWrap(@nospecialize(object::NamedTuple), position::Position, @nospecialize(state::NamedTuple))::NamedTuple
  new_object = deepcopy(object)
  new_object = update_nt(new_object, :origin, moveWrap(object.origin, position.x, position.y, state))
  new_object
end

function moveWrap(cell::Cell, position::Position, @nospecialize(state::NamedTuple))
  moveWrap(cell.position, position.x, position.y, state)
end

function moveWrap(position::Position, cell::Cell, @nospecialize(state::NamedTuple))
  moveWrap(cell.position, position, state)
end

function moveWrap(@nospecialize(object::NamedTuple), x::Int, y::Int, @nospecialize(state::NamedTuple))::NamedTuple
  new_object = deepcopy(object)
  new_object = update_nt(new_object, :origin, moveWrap(object.origin, x, y, state))
  new_object
end

function moveWrap(position1::Position, position2::Position, @nospecialize(state::NamedTuple))::Position
  moveWrap(position1, position2.x, position2.y, state)
end

function moveWrap(position::Position, x::Int, y::Int, @nospecialize(state::NamedTuple))::Position
  GRID_SIZE = state.GRID_SIZEHistory[0]
  if GRID_SIZE isa AbstractArray 
    GRID_SIZE_X = GRID_SIZE[1]
    GRID_SIZE_Y = GRID_SIZE[2]
    # # println("hello")
    # # println(Position((position.x + x + GRID_SIZE) % GRID_SIZE, (position.y + y + GRID_SIZE) % GRID_SIZE))
    Position((position.x + x + GRID_SIZE_X) % GRID_SIZE_X, (position.y + y + GRID_SIZE_Y) % GRID_SIZE_Y)
  else
    Position((position.x + x + GRID_SIZE) % GRID_SIZE, (position.y + y + GRID_SIZE) % GRID_SIZE)
  end

end

# ----- begin left/right moveWrap ----- #

function moveLeftWrap(@nospecialize(object::NamedTuple), @nospecialize(state=nothing))::NamedTuple
  new_object = deepcopy(object)
  new_object = update_nt(new_object, :origin, moveWrap(object.origin, -1, 0, state))
  new_object
end
  
function moveRightWrap(@nospecialize(object::NamedTuple), @nospecialize(state=nothing))::NamedTuple
  new_object = deepcopy(object)
  new_object = update_nt(new_object, :origin, moveWrap(object.origin, 1, 0, state))
  new_object
end

function moveUpWrap(@nospecialize(object::NamedTuple), @nospecialize(state=nothing))::NamedTuple
  new_object = deepcopy(object)
  new_object = update_nt(new_object, :origin, moveWrap(object.origin, 0, -1, state))
  new_object
end

function moveDownWrap(@nospecialize(object::NamedTuple), @nospecialize(state=nothing))::NamedTuple
  new_object = deepcopy(object)
  new_object = update_nt(new_object, :origin, moveWrap(object.origin, 0, 1, state))
  new_object
end

# ----- end left/right moveWrap ----- #

function randomPositions(GRID_SIZE, n::Int, @nospecialize(state=nothing))::Array{Position}
  if GRID_SIZE isa AbstractArray 
    GRID_SIZE_X = GRID_SIZE[1]
    GRID_SIZE_Y = GRID_SIZE[2]
    nums = uniformChoice([0:(GRID_SIZE_X * GRID_SIZE_Y - 1);], n, state)
    map(num -> Position(num % GRID_SIZE_X, floor(Int, num / GRID_SIZE_X)), nums)    
  else
    nums = uniformChoice([0:(GRID_SIZE * GRID_SIZE - 1);], n, state)
    map(num -> Position(num % GRID_SIZE, floor(Int, num / GRID_SIZE)), nums)
  end
end

function distance(position1::Position, position2::Position, @nospecialize(state=nothing))::Int
  abs(position1.x - position2.x) + abs(position1.y - position2.y)
end

function distance(object1::NamedTuple, object2::NamedTuple, @nospecialize(state=nothing))::Int
  position1 = object1.origin
  position2 = object2.origin
  distance(position1, position2)
end

function distance(@nospecialize(object::NamedTuple), position::Position, @nospecialize(state=nothing))::Int
  distance(object.origin, position)
end

function distance(position::Position, @nospecialize(object::NamedTuple), @nospecialize(state=nothing))::Int
  distance(object.origin, position)
end

function closest(@nospecialize(object::NamedTuple), type::Symbol, @nospecialize(state::NamedTuple))::Position
  objects_of_type = filter(obj -> (obj.type == type) && (obj.alive), state.scene.objects)
  if length(objects_of_type) == 0
    object.origin
  else
    min_distance = min(map(obj -> distance(object, obj), objects_of_type))
    objects_of_min_distance = filter(obj -> distance(object, obj) == min_distance, objects_of_type)
    sort(objects_of_min_distance, by=o -> (o.origin.x, o.origin.y))[1].origin
  end
end

function closest(@nospecialize(object::NamedTuple), types::AbstractArray, @nospecialize(state::NamedTuple))::Position
  objects_of_type = filter(obj -> (obj.type in types) && (obj.alive), state.scene.objects)
  if length(objects_of_type) == 0
    object.origin
  else
    min_distance = min(map(obj -> distance(object, obj), objects_of_type))
    objects_of_min_distance = filter(obj -> distance(object, obj) == min_distance, objects_of_type)
    sort(objects_of_min_distance, by=o -> (o.origin.x, o.origin.y))[1].origin
  end
end

function closestRandom(@nospecialize(object::NamedTuple), types::AbstractArray, unit_size::Int, @nospecialize(state::NamedTuple))::Position
  objects_of_type = filter(obj -> (obj.type in types) && (obj.alive), state.scene.objects)
  if length(objects_of_type) == 0
    Position(0, 0)
  else
    min_distance = min(map(obj -> distance(object, obj), objects_of_type))
    objects_of_min_distance = filter(obj -> distance(object, obj) == min_distance, objects_of_type)
    vec = unitVector(object, rand(objects_of_min_distance).origin, state)
    scaled_vec = Position(vec.x * unit_size, vec.y * unit_size)
    scaled_vec
  end
end

function closestLeft(@nospecialize(object::NamedTuple), types::AbstractArray, unit_size::Int, @nospecialize(state::NamedTuple))::Position
  objects_of_type = filter(obj -> (obj.type in types) && (obj.alive), state.scene.objects)
  if length(objects_of_type) == 0
    Position(0, 0)
  else
    min_distance = min(map(obj -> distance(object, obj), objects_of_type))
    objects_of_min_distance = filter(obj -> distance(object, obj) == min_distance, objects_of_type)
    negative_x_displacements = filter(x -> x < 0, map(o -> (o.origin.x - object.origin.x), objects_of_min_distance))
    if length(negative_x_displacements) > 0
      Position(-unit_size, 0)
    else
      vec = unitVector(object, sort(objects_of_min_distance, by=o -> (o.origin.x, o.origin.y))[1].origin, state)
      scaled_vec = Position(vec.x * unit_size, vec.y * unit_size)
      scaled_vec        
    end
  end
end

function closestRight(@nospecialize(object::NamedTuple), types::AbstractArray, unit_size::Int, @nospecialize(state::NamedTuple))::Position
  objects_of_type = filter(obj -> (obj.type in types) && (obj.alive), state.scene.objects)
  if length(objects_of_type) == 0
    object.origin
  else
    min_distance = min(map(obj -> distance(object, obj), objects_of_type))
    objects_of_min_distance = filter(obj -> distance(object, obj) == min_distance, objects_of_type)
    positive_x_displacements = filter(x -> x > 0, map(o -> (o.origin.x - object.origin.x), objects_of_min_distance))
    if length(positive_x_displacements) > 0
      Position(unit_size, 0)
    else
      vec = unitVector(object, sort(objects_of_min_distance, by=o -> (o.origin.x, o.origin.y) )[1].origin, state)
      scaled_vec = Position(vec.x * unit_size, vec.y * unit_size)
      scaled_vec        
    end
  end
end

function closestUp(@nospecialize(object::NamedTuple), types::AbstractArray, unit_size::Int, @nospecialize(state::NamedTuple))::Position
  objects_of_type = filter(obj -> (obj.type in types) && (obj.alive), state.scene.objects)
  if length(objects_of_type) == 0
    object.origin
  else
    min_distance = min(map(obj -> distance(object, obj), objects_of_type))
    objects_of_min_distance = filter(obj -> distance(object, obj) == min_distance, objects_of_type)
    negative_y_displacements = filter(x -> x < 0, map(o -> (o.origin.y - object.origin.y), objects_of_min_distance))
    if length(negative_y_displacements) > 0
      Position(0, -unit_size)
    else
      vec = unitVector(object, sort(objects_of_min_distance, by=o -> (o.origin.x, o.origin.y))[1].origin, state)
      scaled_vec = Position(vec.x * unit_size, vec.y * unit_size)
      scaled_vec        
    end
  end
end

function closestDown(@nospecialize(object::NamedTuple), types::AbstractArray, unit_size::Int, @nospecialize(state::NamedTuple))::Position
  objects_of_type = filter(obj -> (obj.type in types) && (obj.alive), state.scene.objects)
  if length(objects_of_type) == 0
    object.origin
  else
    min_distance = min(map(obj -> distance(object, obj), objects_of_type))
    objects_of_min_distance = filter(obj -> distance(object, obj) == min_distance, objects_of_type)
    positive_y_displacements = filter(x -> x > 0, map(o -> (o.origin.y - object.origin.y), objects_of_min_distance))
    if length(positive_y_displacements) > 0
      Position(0, unit_size)
    else
      vec = unitVector(object, sort(objects_of_min_distance, by=o -> (o.origin.x, o.origin.y))[1].origin, state)
      scaled_vec = Position(vec.x * unit_size, vec.y * unit_size)
      scaled_vec        
    end
  end
end

function mapPositions(constructor, GRID_SIZE, filterFunction, args, @nospecialize(state=nothing))::Union{NamedTuple, Array{<:NamedTuple}}
  map(pos -> constructor(args..., pos), filter(filterFunction, allPositions(GRID_SIZE)))
end

function allPositions(GRID_SIZE, @nospecialize(state=nothing))
  if GRID_SIZE isa AbstractArray 
    GRID_SIZE_X = GRID_SIZE[1]
    GRID_SIZE_Y = GRID_SIZE[2]
    nums = [0:(GRID_SIZE_X * GRID_SIZE_Y - 1);]
    map(num -> Position(num % GRID_SIZE_X, floor(Int, num / GRID_SIZE_X)), nums)
  else
    nums = [0:(GRID_SIZE * GRID_SIZE - 1);]
    map(num -> Position(num % GRID_SIZE, floor(Int, num / GRID_SIZE)), nums)
  end
end

function updateOrigin(@nospecialize(object::NamedTuple), new_origin::Position, @nospecialize(state=nothing))::NamedTuple
  new_object = deepcopy(object)
  new_object = update_nt(new_object, :origin, new_origin)
  new_object
end

function updateAlive(@nospecialize(object::NamedTuple), new_alive::Bool, @nospecialize(state=nothing))::NamedTuple
  new_object = deepcopy(object)
  new_object = update_nt(new_object, :alive, new_alive)
  new_object
end

function nextLiquid(@nospecialize(object::NamedTuple), @nospecialize(state::NamedTuple))::NamedTuple 
  # # println("nextLiquid")
  GRID_SIZE = state.GRID_SIZEHistory[0]
  if GRID_SIZE isa AbstractArray 
    GRID_SIZE_X = GRID_SIZE[1]
    GRID_SIZE_Y = GRID_SIZE[2]
  else
    GRID_SIZE_X = GRID_SIZE
    GRID_SIZE_Y = GRID_SIZE
  end
  new_object = deepcopy(object)
  if object.origin.y != GRID_SIZE_Y - 1 && isFree(move(object.origin, Position(0, 1)), state)
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

function nextSolid(@nospecialize(object::NamedTuple), @nospecialize(state::NamedTuple))::NamedTuple 
  # # println("nextSolid")
  new_object = deepcopy(object)
  if (isWithinBounds(move(object, Position(0, 1)), state) && reduce(&, map(x -> isFree(x, object, state), map(cell -> move(cell.position, Position(0, 1)), render(object)))))
    new_object = update_nt(new_object, :origin, move(object.origin, Position(0, 1)))
  end
  new_object
end

function closest(@nospecialize(object::NamedTuple), positions::Array{Position}, @nospecialize(state=nothing))::Position
  closestDistance = sort(map(pos -> distance(pos, object.origin), positions))[1]
  closest = filter(pos -> distance(pos, object.origin) == closestDistance, positions)[1]
  closest
end

function isFree(start::Position, stop::Position, @nospecialize(state::NamedTuple))::Bool 
  GRID_SIZE = state.GRID_SIZEHistory[0]
  if GRID_SIZE isa AbstractArray 
    GRID_SIZE_X = GRID_SIZE[1]
    GRID_SIZE_Y = GRID_SIZE[2]
  else
    GRID_SIZE_X = GRID_SIZE
    GRID_SIZE_Y = GRID_SIZE
  end
  translated_start = GRID_SIZE_X * start.y + start.x 
  translated_stop = GRID_SIZE_X * stop.y + stop.x
  if translated_start < translated_stop
    ordered_start = translated_start
    ordered_end = translated_stop
  else
    ordered_start = translated_stop
    ordered_end = translated_start
  end
  nums = [ordered_start:ordered_end;]
  reduce(&, map(num -> isFree(Position(num % GRID_SIZE_X, floor(Int, num / GRID_SIZE_X)), state), nums))
end

function isFree(start::Position, stop::Position, @nospecialize(object::NamedTuple), @nospecialize(state::NamedTuple))::Bool 
  GRID_SIZE = state.GRID_SIZEHistory[0]
  if GRID_SIZE isa AbstractArray 
    GRID_SIZE_X = GRID_SIZE[1]
    GRID_SIZE_Y = GRID_SIZE[2]
  else
    GRID_SIZE_X = GRID_SIZE
    GRID_SIZE_Y = GRID_SIZE
  end
  translated_start = GRID_SIZE_X * start.y + start.x 
  translated_stop = GRID_SIZE_X * stop.y + stop.x
  if translated_start < translated_stop
    ordered_start = translated_start
    ordered_end = translated_stop
  else
    ordered_start = translated_stop
    ordered_end = translated_start
  end
  nums = [ordered_start:ordered_end;]
  reduce(&, map(num -> isFree(Position(num % GRID_SIZE_X, floor(Int, num / GRID_SIZE_X)), object, state), nums))
end

function isFree(position::Position, @nospecialize(object::NamedTuple), @nospecialize(state::NamedTuple))
  length(filter(cell -> cell.position.x == position.x && cell.position.y == position.y, 
  render((objects=filter(obj -> obj.id != object.id , state.scene.objects), background=state.scene.background)))) == 0
end

function isFree(@nospecialize(object::NamedTuple), @nospecialize(orig_object::NamedTuple), @nospecialize(state::NamedTuple))::Bool
  reduce(&, map(x -> isFree(x, orig_object, state), map(cell -> cell.position, render(object))))
end

function allPositions(@nospecialize(state::NamedTuple))
  GRID_SIZE = state.GRID_SIZEHistory[0]
  if GRID_SIZE isa AbstractArray 
    GRID_SIZE_X = GRID_SIZE[1]
    GRID_SIZE_Y = GRID_SIZE[2]
  else
    GRID_SIZE_X = GRID_SIZE
    GRID_SIZE_Y = GRID_SIZE
  end
  nums = [1:GRID_SIZE_X*GRID_SIZE_Y - 1;]
  map(num -> Position(num % GRID_SIZE_X, floor(Int, num / GRID_SIZE_X)), nums)
end

function unfold(A, @nospecialize(state=nothing))
  V = []
  for x in A
      for elt in x
        push!(V, elt)
      end
  end
  V
end

end