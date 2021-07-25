using Test
using Autumn

function construct_data()
  Dict([("external" => []),
        ("initnext" => []),
        ("lifted" => []),
        ("types" => Dict()),
        ("on" => []),
        ("objects" => [])])
end

mod = nothing

if VERSION > v"1.6-"
  const ts = Test.typesplit
else
  const ts = Test.typesubtract
end

function isinferred(f, args...; allow = Union{})
  ret = f(args...)
  inftypes = Base.return_types(f, Base.typesof(args...))
  rettype = ret isa Type ? Type{ret} : typeof(ret)
  rettype <: allow || rettype == ts(inftypes[1], allow)
end

function test_compile_if()
  data = construct_data()
  aexpr = au"""(if (== x 3) then (= y 4) else (= y 5))"""
  @test string(compile(aexpr, data)) == "if x == 3\n    y = 4\nelse\n    y = 5\nend"   
end

function test_compile_assign()
  data = construct_data()
  aexpr = au"""(= x 3)"""
  @test compile(aexpr, data) == :(x = 3)
end

function test_compile_typedecl()
  data = construct_data()
  aexpr = au"""(: x Int)"""
  @test compile(aexpr, data) == :(local x::Int)
end

# function test_compile_external()
#   data = construct_data()
#   aexpr = au"""(external (: click Click))"""
#   @test compile(aexpr, data) == :()
# end

function test_compile_let()
  data = construct_data()
  aexpr = au"""(let ((= y 3) (= x y)))"""

  @test compile(aexpr, data).args[end-1:end] == [:(y = 3), :(x = y)]  
end

function test_compile_list()
  data = construct_data()
  aexpr = au"""(list 1 2 3 4 5)"""
  @test compile(aexpr, data) == :([1, 2, 3, 4, 5])
end

function test_compile_call()
  data = construct_data()
  aexpr = au"""(f 1 2 3) """
  @test compile(aexpr, data) == :(f(1, 2, 3))
end

function test_compile_field()
  data = construct_data()
  aexpr = au"""(.. position x)"""
  @test compile(aexpr, data) == :(position.x)
end

function test_compile_particles()
  a = au"""(program
         (= GRID_SIZE 16)

         (object Particle (Cell 0 0 "blue"))

         (: particles (List Particle))
         (= particles
            (initnext (list)
                      (updateObj (prev particles) (--> obj (Particle (uniformChoice (adjPositions (.. obj origin))))))))

         (on clicked (= particles (addObj (prev particles) (Particle (Position (.. click x) (.. click y))))))
         )"""

  @test string(compiletojulia(a)) == "\$(Expr(:toplevel, :(module CompiledProgram\n  export init, next\n  import Base.min\n  using Distributions\n  using MLStyle: @match\n  using Random\n  rng = Random.GLOBAL_RNG\n  begin\n      function occurred(click)\n          !(isnothing(click))\n      end\n  end\n  begin\n      abstract type Object end\n      abstract type KeyPress end\n      struct Left <: KeyPress\n      end\n      struct Right <: KeyPress\n      end\n      struct Up <: KeyPress\n      end\n      struct Down <: KeyPress\n      end\n      struct Click\n          x::Int\n          y::Int\n      end\n      struct Position\n          x::Int\n          y::Int\n      end\n      struct Cell\n          position::Position\n          color::String\n          opacity::Float64\n      end\n      Cell(position::Position, color::String) = begin\n              Cell(position, color, 0.8)\n          end\n      Cell(x::Int, y::Int, color::String) = begin\n              Cell(Position(floor(Int, x), floor(Int, y)), color, 0.8)\n          end\n      Cell(x::Int, y::Int, color::String, opacity::Float64) = begin\n              Cell(Position(floor(Int, x), floor(Int, y)), color, opacity)\n          end\n      struct Scene\n          objects::Array{Object}\n          background::String\n      end\n      Scene(objects::AbstractArray) = begin\n              Scene(objects, \"#ffffff00\")\n          end\n      function render(scene::Scene)::Array{Cell}\n          vcat(map((obj->begin\n                          render(obj)\n                      end), filter((obj->begin\n                              obj.alive\n                          end), scene.objects))...)\n      end\n      function render(obj::Object)::Array{Cell}\n          if obj.alive\n              map((cell->begin\n                          Cell(move(cell.position, obj.origin), cell.color)\n                      end), obj.render)\n          else\n              []\n          end\n      end\n      function isWithinBounds(obj::Object)::Bool\n          length(filter((cell->begin\n                              !(isWithinBounds(cell.position))\n                          end), render(obj))) == 0\n      end\n      function clicked(click::Union{Click, Nothing}, object::Object)::Bool\n          if click == nothing\n              false\n          else\n              GRID_SIZE = state.GRID_SIZEHistory[0]\n              nums = map((cell->begin\n                              GRID_SIZE * cell.position.y + cell.position.x\n                          end), render(object))\n              GRID_SIZE * click.y + click.x in nums\n          end\n      end\n      function clicked(click::Union{Click, Nothing}, objects::AbstractArray)\n          reduce(|, map((obj->begin\n                          clicked(click, obj)\n                      end), objects))\n      end\n      function objClicked(click::Union{Click, Nothing}, objects::AbstractArray)::Union{Object, Nothing}\n          println(click)\n          if isnothing(click)\n              nothing\n          else\n              clicked_objects = filter((obj->begin\n                              clicked(click, obj)\n                          end), objects)\n              if length(clicked_objects) == 0\n                  nothing\n              else\n                  clicked_objects[1]\n              end\n          end\n      end\n      function clicked(click::Union{Click, Nothing}, x::Int, y::Int)::Bool\n          if click == nothing\n              false\n          else\n              click.x == x && click.y == y\n          end\n      end\n      function clicked(click::Union{Click, Nothing}, pos::Position)::Bool\n          if click == nothing\n              false\n          else\n              click.x == pos.x && click.y == pos.y\n          end\n      end\n      function intersects(obj1::Object, obj2::Object)::Bool\n          println(\"INTERSECTS 1\")\n          nums1 = map((cell->begin\n                          state.GRID_SIZEHistory[0] * cell.position.y + cell.position.x\n                      end), render(obj1))\n          nums2 = map((cell->begin\n                          state.GRID_SIZEHistory[0] * cell.position.y + cell.position.x\n                      end), render(obj2))\n          length(intersect(nums1, nums2)) != 0\n      end\n      function intersects(obj1::Object, obj2::Array{<:Object})::Bool\n          println(\"INTERSECTS 2\")\n          nums1 = map((cell->begin\n                          state.GRID_SIZEHistory[0] * cell.position.y + cell.position.x\n                      end), render(obj1))\n          nums2 = map((cell->begin\n                          state.GRID_SIZEHistory[0] * cell.position.y + cell.position.x\n                      end), vcat(map(render, obj2)...))\n          println(length(intersect(nums1, nums2)) != 0)\n          length(intersect(nums1, nums2)) != 0\n      end\n      function intersects(obj1::Array{<:Object}, obj2::Array{<:Object})::Bool\n          nums1 = map((cell->begin\n                          state.GRID_SIZEHistory[0] * cell.position.y + cell.position.x\n                      end), vcat(map(render, obj1)...))\n          nums2 = map((cell->begin\n                          state.GRID_SIZEHistory[0] * cell.position.y + cell.position.x\n                      end), vcat(map(render, obj2)...))\n          println(length(intersect(nums1, nums2)) != 0)\n          length(intersect(nums1, nums2)) != 0\n      end\n      function intersects(list1, list2)::Bool\n          length(intersect(list1, list2)) != 0\n      end\n      function intersects(object::Object)::Bool\n          objects = state.scene.objects\n          intersects(object, objects)\n      end\n      function addObj(list::Array{<:Object}, obj::Object)\n          obj.changed = true\n          new_list = vcat(list, obj)\n          new_list\n      end\n      function addObj(list::Array{<:Object}, objs::Array{<:Object})\n          foreach((obj->begin\n                      obj.changed = true\n                  end), objs)\n          new_list = vcat(list, objs)\n          new_list\n      end\n      function removeObj(list::Array{<:Object}, obj::Object)\n          new_list = deepcopy(list)\n          for x = filter((o->begin\n                              o.id == obj.id\n                          end), new_list)\n              x.alive = false\n              x.changed = true\n          end\n          new_list\n      end\n      function removeObj(list::Array{<:Object}, fn)\n          new_list = deepcopy(list)\n          for x = filter((obj->begin\n                              fn(obj)\n                          end), new_list)\n              x.alive = false\n              x.changed = true\n          end\n          new_list\n      end\n      function removeObj(obj::Object)\n          new_obj = deepcopy(obj)\n          new_obj.alive = false\n          new_obj.changed = true\n          new_obj\n      end\n      function updateObj(obj::Object, field::String, value)\n          fields = fieldnames(typeof(obj))\n          custom_fields = fields[5:end - 1]\n          origin_field = (fields[2],)\n          constructor_fields = (custom_fields..., origin_field...)\n          constructor_values = map((x->begin\n                          if x == Symbol(field)\n                              value\n                          else\n                              getproperty(obj, x)\n                          end\n                      end), constructor_fields)\n          new_obj = (typeof(obj))(constructor_values...)\n          setproperty!(new_obj, :id, obj.id)\n          setproperty!(new_obj, :alive, obj.alive)\n          setproperty!(new_obj, :changed, obj.changed)\n          setproperty!(new_obj, Symbol(field), value)\n          state.objectsCreated -= 1\n          new_obj\n      end\n      function filter_fallback(obj::Object)\n          true\n      end\n      function updateObj(list::Array{<:Object}, map_fn, filter_fn = filter_fallback)\n          orig_list = filter((obj->begin\n                          !(filter_fn(obj))\n                      end), list)\n          filtered_list = filter(filter_fn, list)\n          new_filtered_list = map(map_fn, filtered_list)\n          foreach((obj->begin\n                      obj.changed = true\n                  end), new_filtered_list)\n          vcat(orig_list, new_filtered_list)\n      end\n      function adjPositions(position::Position)::Array{Position}\n          filter(isWithinBounds, [Position(position.x, position.y + 1), Position(position.x, position.y - 1), Position(position.x + 1, position.y), Position(position.x - 1, position.y)])\n      end\n      function isWithinBounds(position::Position)::Bool\n          position.x >= 0 && (position.x < state.GRID_SIZEHistory[0] && (position.y >= 0 && position.y < state.GRID_SIZEHistory[0]))\n      end\n      function isFree(position::Position)::Bool\n          length(filter((cell->begin\n                              cell.position.x == position.x && cell.position.y == position.y\n                          end), render(state.scene))) == 0\n      end\n      function isFree(click::Union{Click, Nothing})::Bool\n          if click == nothing\n              false\n          else\n              isFree(Position(click.x, click.y))\n          end\n      end\n      function rect(pos1::Position, pos2::Position)\n          min_x = pos1.x\n          max_x = pos2.x\n          min_y = pos1.y\n          max_y = pos2.y\n          positions = []\n          for x = min_x:max_x\n              for y = min_y:max_y\n                  push!(positions, Position(x, y))\n              end\n          end\n          positions\n      end\n      function unitVector(position1::Position, position2::Position)::Position\n          deltaX = position2.x - position1.x\n          deltaY = position2.y - position1.y\n          if floor(Int, abs(sign(deltaX))) == 1 && floor(Int, abs(sign(deltaY))) == 1\n              Position(sign(deltaX), 0)\n          else\n              Position(sign(deltaX), sign(deltaY))\n          end\n      end\n      function unitVector(object1::Object, object2::Object)::Position\n          position1 = object1.origin\n          position2 = object2.origin\n          unitVector(position1, position2)\n      end\n      function unitVector(object::Object, position::Position)::Position\n          unitVector(object.origin, position)\n      end\n      function unitVector(position::Position, object::Object)::Position\n          unitVector(position, object.origin)\n      end\n      function unitVector(position::Position)::Position\n          unitVector(Position(0, 0), position)\n      end\n      function displacement(position1::Position, position2::Position)::Position\n          Position(floor(Int, position2.x - position1.x), floor(Int, position2.y - position1.y))\n      end\n      function displacement(cell1::Cell, cell2::Cell)::Position\n          displacement(cell1.position, cell2.position)\n      end\n      function adjacent(position1::Position, position2::Position)\n          :Bool\n          displacement(position1, position2) in [Position(0, 1), Position(1, 0), Position(0, -1), Position(-1, 0)]\n      end\n      function adjacent(cell1::Cell, cell2::Cell)::Bool\n          adjacent(cell1.position, cell2.position)\n      end\n      function adjacent(cell::Cell, cells::Array{Cell})\n          length(filter((x->begin\n                              adjacent(cell, x)\n                          end), cells)) != 0\n      end\n      function adjacentObjs(obj::Object)\n          filter((o->begin\n                      adjacent(o.origin, obj.origin) && obj.id != o.id\n                  end), state.scene.objects)\n      end\n      function adjacentObjsDiag(obj::Object)\n          filter((o->begin\n                      adjacentDiag(o.origin, obj.origin) && obj.id != o.id\n                  end), state.scene.objects)\n      end\n      function adjacentDiag(position1::Position, position2::Position)\n          displacement(position1, position2) in [Position(0, 1), Position(1, 0), Position(0, -1), Position(-1, 0), Position(1, 1), Position(1, -1), Position(-1, 1), Position(-1, -1)]\n      end\n      function rotate(object::Object)::Object\n          new_object = deepcopy(object)\n          new_object.render = map((x->begin\n                          Cell(rotate(x.position), x.color)\n                      end), new_object.render)\n          new_object\n      end\n      function rotate(position::Position)::Position\n          Position(-(position.y), position.x)\n      end\n      function rotateNoCollision(object::Object)::Object\n          if isWithinBounds(rotate(object)) && isFree(rotate(object), object)\n              rotate(object)\n          else\n              object\n          end\n      end\n      function move(position1::Position, position2::Position)\n          Position(position1.x + position2.x, position1.y + position2.y)\n      end\n      function move(position::Position, cell::Cell)\n          Position(position.x + cell.position.x, position.y + cell.position.y)\n      end\n      function move(cell::Cell, position::Position)\n          Position(position.x + cell.position.x, position.y + cell.position.y)\n      end\n      function move(object::Object, position::Position)\n          new_object = deepcopy(object)\n          new_object.origin = move(object.origin, position)\n          new_object\n      end\n      function move(object::Object, x::Int, y::Int)::Object\n          move(object, Position(x, y))\n      end\n      function moveLeft(object::Object)::Object\n          move(object, Position(-1, 0))\n      end\n      function moveRight(object::Object)::Object\n          move(object, Position(1, 0))\n      end\n      function moveUp(object::Object)::Object\n          move(object, Position(0, -1))\n      end\n      function moveDown(object::Object)::Object\n          move(object, Position(0, 1))\n      end\n      function moveNoCollision(object::Object, position::Position)::Object\n          if isWithinBounds(move(object, position)) && isFree(move(object, position.x, position.y), object)\n              move(object, position.x, position.y)\n          else\n              object\n          end\n      end\n      function moveNoCollision(object::Object, x::Int, y::Int)\n          if isWithinBounds(move(object, x, y)) && isFree(move(object, x, y), object)\n              move(object, x, y)\n          else\n              object\n          end\n      end\n      function moveLeftNoCollision(object::Object)::Object\n          if isWithinBounds(move(object, -1, 0)) && isFree(move(object, -1, 0), object)\n              move(object, -1, 0)\n          else\n              object\n          end\n      end\n      function moveRightNoCollision(object::Object)::Object\n          if isWithinBounds(move(object, 1, 0)) && isFree(move(object, 1, 0), object)\n              move(object, 1, 0)\n          else\n              object\n          end\n      end\n      function moveUpNoCollision(object::Object)::Object\n          if isWithinBounds(move(object, 0, -1)) && isFree(move(object, 0, -1), object)\n              move(object, 0, -1)\n          else\n              object\n          end\n      end\n      function moveDownNoCollision(object::Object)::Object\n          if isWithinBounds(move(object, 0, 1)) && isFree(move(object, 0, 1), object)\n              move(object, 0, 1)\n          else\n              object\n          end\n      end\n      function moveWrap(object::Object, position::Position)::Object\n          new_object = deepcopy(object)\n          new_object.position = moveWrap(object.origin, position.x, position.y)\n          new_object\n      end\n      function moveWrap(cell::Cell, position::Position)\n          moveWrap(cell.position, position.x, position.y)\n      end\n      function moveWrap(position::Position, cell::Cell)\n          moveWrap(cell.position, position)\n      end\n      function moveWrap(object::Object, x::Int, y::Int)::Object\n          new_object = deepcopy(object)\n          new_object.position = moveWrap(object.origin, x, y)\n          new_object\n      end\n      function moveWrap(position1::Position, position2::Position)::Position\n          moveWrap(position1, position2.x, position2.y)\n      end\n      function moveWrap(position::Position, x::Int, y::Int)::Position\n          GRID_SIZE = state.GRID_SIZEHistory[0]\n          Position((position.x + x + GRID_SIZE) % GRID_SIZE, (position.y + y + GRID_SIZE) % GRID_SIZE)\n      end\n      function moveLeftWrap(object::Object)::Object\n          new_object = deepcopy(object)\n          new_object.origin = moveWrap(object.origin, -1, 0)\n          new_object\n      end\n      function moveRightWrap(object::Object)::Object\n          new_object = deepcopy(object)\n          new_object.origin = moveWrap(object.origin, 1, 0)\n          new_object\n      end\n      function moveUpWrap(object::Object)::Object\n          new_object = deepcopy(object)\n          new_object.origin = moveWrap(object.origin, 0, -1)\n          new_object\n      end\n      function moveDownWrap(object::Object)::Object\n          new_object = deepcopy(object)\n          new_object.origin = moveWrap(object.origin, 0, 1)\n          new_object\n      end\n      function randomPositions(GRID_SIZE::Int, n::Int)::Array{Position}\n          nums = uniformChoice(rng, [0:GRID_SIZE * GRID_SIZE - 1;], n)\n          map((num->begin\n                      Position(num % GRID_SIZE, floor(Int, num / GRID_SIZE))\n                  end), nums)\n      end\n      function distance(position1::Position, position2::Position)::Int\n          abs(position1.x - position2.x) + abs(position1.y - position2.y)\n      end\n      function distance(object1::Object, object2::Object)::Int\n          position1 = object1.origin\n          position2 = object2.origin\n          distance(position1, position2)\n      end\n      function distance(object::Object, position::Position)::Int\n          distance(object.origin, position)\n      end\n      function distance(position::Position, object::Object)::Int\n          distance(object.origin, position)\n      end\n      function closest(object::Object, type::DataType)::Position\n          objects_of_type = filter((obj->begin\n                          obj isa type && obj.alive\n                      end), state.scene.objects)\n          if length(objects_of_type) == 0\n              object.origin\n          else\n              min_distance = min(map((obj->begin\n                                  distance(object, obj)\n                              end), objects_of_type))\n              ((filter((obj->(distance(object, obj) == min_distance;)), objects_of_type))[1]).origin\n          end\n      end\n      function mapPositions(constructor, GRID_SIZE::Int, filterFunction, args...)::Union{Object, Array{<:Object}}\n          map((pos->begin\n                      constructor(args..., pos)\n                  end), filter(filterFunction, allPositions(GRID_SIZE)))\n      end\n      function allPositions(GRID_SIZE::Int)\n          nums = [0:GRID_SIZE * GRID_SIZE - 1;]\n          map((num->begin\n                      Position(num % GRID_SIZE, floor(Int, num / GRID_SIZE))\n                  end), nums)\n      end\n      function updateOrigin(object::Object, new_origin::Position)::Object\n          new_object = deepcopy(object)\n          new_object.origin = new_origin\n          new_object\n      end\n      function updateAlive(object::Object, new_alive::Bool)::Object\n          new_object = deepcopy(object)\n          new_object.alive = new_alive\n          new_object\n      end\n      function nextLiquid(object::Object)::Object\n          GRID_SIZE = state.GRID_SIZEHistory[0]\n          new_object = deepcopy(object)\n          if object.origin.y != GRID_SIZE - 1 && isFree(move(object.origin, Position(0, 1)))\n              new_object.origin = move(object.origin, Position(0, 1))\n          else\n              leftHoles = filter((pos->begin\n                              pos.y == object.origin.y + 1 && (pos.x < object.origin.x && isFree(pos))\n                          end), allPositions())\n              rightHoles = filter((pos->begin\n                              pos.y == object.origin.y + 1 && (pos.x > object.origin.x && isFree(pos))\n                          end), allPositions())\n              if length(leftHoles) != 0 || length(rightHoles) != 0\n                  if length(leftHoles) == 0\n                      closestHole = closest(object, rightHoles)\n                      if isFree(move(closestHole, Position(0, -1)), move(object.origin, Position(1, 0)))\n                          new_object.origin = move(object.origin, unitVector(object, move(closestHole, Position(0, -1))))\n                      end\n                  elseif length(rightHoles) == 0\n                      closestHole = closest(object, leftHoles)\n                      if isFree(move(closestHole, Position(0, -1)), move(object.origin, Position(-1, 0)))\n                          new_object.origin = move(object.origin, unitVector(object, move(closestHole, Position(0, -1))))\n                      end\n                  else\n                      closestLeftHole = closest(object, leftHoles)\n                      closestRightHole = closest(object, rightHoles)\n                      if distance(object.origin, closestLeftHole) > distance(object.origin, closestRightHole)\n                          if isFree(move(object.origin, Position(1, 0)), move(closestRightHole, Position(0, -1)))\n                              new_object.origin = move(object.origin, unitVector(new_object, move(closestRightHole, Position(0, -1))))\n                          elseif isFree(move(closestLeftHole, Position(0, -1)), move(object.origin, Position(-1, 0)))\n                              new_object.origin = move(object.origin, unitVector(new_object, move(closestLeftHole, Position(0, -1))))\n                          end\n                      else\n                          if isFree(move(closestLeftHole, Position(0, -1)), move(object.origin, Position(-1, 0)))\n                              new_object.origin = move(object.origin, unitVector(new_object, move(closestLeftHole, Position(0, -1))))\n                          elseif isFree(move(object.origin, Position(1, 0)), move(closestRightHole, Position(0, -1)))\n                              new_object.origin = move(object.origin, unitVector(new_object, move(closestRightHole, Position(0, -1))))\n                          end\n                      end\n                  end\n              end\n          end\n          new_object\n      end\n      function nextSolid(object::Object)::Object\n          GRID_SIZE = state.GRID_SIZEHistory[0]\n          new_object = deepcopy(object)\n          if isWithinBounds(move(object, Position(0, 1))) && reduce(&, map((x->begin\n                                  isFree(x, object)\n                              end), map((cell->begin\n                                      move(cell.position, Position(0, 1))\n                                  end), render(object))))\n              new_object.origin = move(object.origin, Position(0, 1))\n          end\n          new_object\n      end\n      function closest(object::Object, positions::Array{Position})::Position\n          closestDistance = (sort(map((pos->(distance(pos, object.origin);)), positions)))[1]\n          closest = (filter((pos->(distance(pos, object.origin) == closestDistance;)), positions))[1]\n          closest\n      end\n      function isFree(start::Position, stop::Position)::Bool\n          GRID_SIZE = state.GRID_SIZEHistory[0]\n          nums = [GRID_SIZE * start.y + start.x:GRID_SIZE * stop.y + stop.x;]\n          reduce(&, map((num->begin\n                          isFree(Position(num % GRID_SIZE, floor(Int, num / GRID_SIZE)))\n                      end), nums))\n      end\n      function isFree(start::Position, stop::Position, object::Object)::Bool\n          GRID_SIZE = state.GRID_SIZEHistory[0]\n          nums = [GRID_SIZE * start.y + start.x:GRID_SIZE * stop.y + stop.x;]\n          reduce(&, map((num->begin\n                          isFree(Position(num % GRID_SIZE, floor(Int, num / GRID_SIZE)), object)\n                      end), nums))\n      end\n      function isFree(position::Position, object::Object)\n          length(filter((cell->begin\n                              cell.position.x == position.x && cell.position.y == position.y\n                          end), render(Scene(filter((obj->begin\n                                          obj.id != object.id\n                                      end), state.scene.objects), state.scene.background)))) == 0\n      end\n      function isFree(object::Object, orig_object::Object)::Bool\n          reduce(&, map((x->begin\n                          isFree(x, orig_object)\n                      end), map((cell->begin\n                              cell.position\n                          end), render(object))))\n      end\n      function allPositions()\n          GRID_SIZE = state.GRID_SIZEHistory[0]\n          nums = [1:GRID_SIZE * GRID_SIZE - 1;]\n          map((num->begin\n                      Position(num % GRID_SIZE, floor(Int, num / GRID_SIZE))\n                  end), nums)\n      end\n      function unfold(A)\n          V = []\n          for x = A\n              for elt = x\n                  push!(V, elt)\n              end\n          end\n          V\n      end\n  end\n  begin\n      function uniformChoice(rng, freePositions)\n          freePositions[rand(rng, Categorical(ones(length(freePositions)) / length(freePositions)))]\n      end\n  end\n  begin\n      function uniformChoice(rng, freePositions, n)\n          map((idx->begin\n                      freePositions[idx]\n                  end), rand(rng, Categorical(ones(length(freePositions)) / length(freePositions)), n))\n      end\n  end\n  begin\n      function min(arr)\n          min(arr...)\n      end\n  end\n  begin\n      function range(start::Int, stop::Int)\n          [start:stop;]\n      end\n  end\n  begin\n      mutable struct Particle <: Object\n          id::Int\n          origin::Position\n          alive::Bool\n          changed::Bool\n          render::Array{Cell}\n      end\n      function Particle(origin::Position)::Particle\n          state.objectsCreated += 1\n          rendering = Cell(0, 0, \"blue\")\n          Particle(state.objectsCreated, origin, true, false, if rendering isa AbstractArray\n                  vcat(rendering...)\n              else\n                  [rendering]\n              end)\n      end\n  end\n  begin\n      mutable struct STATE\n          time::Int\n          objectsCreated::Int\n          scene::Scene\n          particlesHistory::Dict{Int64, Array{Particle}}\n          GRID_SIZEHistory::Dict{Int64, Int}\n          clickHistory::Dict{Int64, Union{Click, Nothing}}\n          leftHistory::Dict{Int64, Union{KeyPress, Nothing}}\n          rightHistory::Dict{Int64, Union{KeyPress, Nothing}}\n          upHistory::Dict{Int64, Union{KeyPress, Nothing}}\n          downHistory::Dict{Int64, Union{KeyPress, Nothing}}\n      end\n  end\n  state = STATE(0, 0, Scene([]), Dict{Int64, Array{Particle}}(), Dict{Int64, Int}(), Dict{Int64, Union{Click, Nothing}}(), Dict{Int64, Union{KeyPress, Nothing}}(), Dict{Int64, Union{KeyPress, Nothing}}(), Dict{Int64, Union{KeyPress, Nothing}}(), Dict{Int64, Union{KeyPress, Nothing}}())\n  begin\n      function particlesPrev(n::Int = 1)::Array{Particle}\n          state.particlesHistory[if state.time - n >= 0\n                  state.time - n\n              else\n                  0\n              end]\n      end\n  end\n  begin\n      function GRID_SIZEPrev(n::Int = 1)::Int\n          state.GRID_SIZEHistory[if state.time - n >= 0\n                  state.time - n\n              else\n                  0\n              end]\n      end\n  end\n  begin\n      function clickPrev(n::Int = 1)::Union{Click, Nothing}\n          state.clickHistory[if state.time - n >= 0\n                  state.time - n\n              else\n                  0\n              end]\n      end\n  end\n  begin\n      function leftPrev(n::Int = 1)::Union{KeyPress, Nothing}\n          state.leftHistory[if state.time - n >= 0\n                  state.time - n\n              else\n                  0\n              end]\n      end\n  end\n  begin\n      function rightPrev(n::Int = 1)::Union{KeyPress, Nothing}\n          state.rightHistory[if state.time - n >= 0\n                  state.time - n\n              else\n                  0\n              end]\n      end\n  end\n  begin\n      function upPrev(n::Int = 1)::Union{KeyPress, Nothing}\n          state.upHistory[if state.time - n >= 0\n                  state.time - n\n              else\n                  0\n              end]\n      end\n  end\n  begin\n      function downPrev(n::Int = 1)::Union{KeyPress, Nothing}\n          state.downHistory[if state.time - n >= 0\n                  state.time - n\n              else\n                  0\n              end]\n      end\n  end\n  begin\n      function init(click::Union{Click, Nothing}, left::Union{KeyPress, Nothing}, right::Union{KeyPress, Nothing}, up::Union{KeyPress, Nothing}, down::Union{KeyPress, Nothing}, custom_rng = rng)::STATE\n          global rng = custom_rng\n          state = STATE(0, 0, Scene([]), Dict{Int64, Array{Particle}}(), Dict{Int64, Int}(), Dict{Int64, Union{Click, Nothing}}(), Dict{Int64, Union{KeyPress, Nothing}}(), Dict{Int64, Union{KeyPress, Nothing}}(), Dict{Int64, Union{KeyPress, Nothing}}(), Dict{Int64, Union{KeyPress, Nothing}}())\n          begin\n              GRID_SIZE = 16\n              particles = []\n              foreach((x->begin\n                          x.changed = false\n                      end), particles)\n          end\n          state.clickHistory[state.time] = click\n          state.leftHistory[state.time] = left\n          state.rightHistory[state.time] = right\n          state.upHistory[state.time] = up\n          state.downHistory[state.time] = down\n          state.particlesHistory[state.time] = particles\n          state.GRID_SIZEHistory[state.time] = GRID_SIZE\n          state.scene = Scene(vcat([particles]...), if :backgroundHistory in fieldnames(STATE)\n                      state.backgroundHistory[state.time]\n                  else\n                      \"#ffffff00\"\n                  end)\n          global state = state\n          state\n      end\n  end\n  begin\n      function next(old_state::STATE, click::Union{Click, Nothing}, left::Union{KeyPress, Nothing}, right::Union{KeyPress, Nothing}, up::Union{KeyPress, Nothing}, down::Union{KeyPress, Nothing})::STATE\n          global state = old_state\n          state.time = state.time + 1\n          GRID_SIZE = 16\n          begin\n              particles = state.particlesHistory[state.time - 1]\n              GRID_SIZE = state.GRID_SIZEHistory[state.time - 1]\n              begin\n                  if occurred(click)\n                      particles = addObj(particlesPrev(), Particle(Position(click.x, click.y)))\n                  end\n              end\n              begin\n                  particlesChanged = filter((o->begin\n                                  o.changed\n                              end), particles)\n                  particles = filter((o->begin\n                                  !(o.id in map((x->begin\n                                                      x.id\n                                                  end), particlesChanged))\n                              end), updateObj(particlesPrev(), (obj->begin\n                                      Particle(uniformChoice(rng, adjPositions(obj.origin)))\n                                  end)))\n                  particles = vcat(particlesChanged..., particles...)\n                  particles = filter((o->begin\n                                  o.alive\n                              end), particles)\n                  foreach((o->begin\n                              o.changed = false\n                          end), particles)\n              end\n          end\n          state.clickHistory[state.time] = click\n          state.leftHistory[state.time] = left\n          state.rightHistory[state.time] = right\n          state.upHistory[state.time] = up\n          state.downHistory[state.time] = down\n          state.particlesHistory[state.time] = particles\n          state.GRID_SIZEHistory[state.time] = GRID_SIZE\n          state.scene = Scene(vcat([particles]...), if :backgroundHistory in fieldnames(STATE)\n                      state.backgroundHistory[state.time]\n                  else\n                      \"#ffffff00\"\n                  end)\n          global state = state\n          state\n      end\n  end\n  end)))"

  global mod = eval(compiletojulia(a))
end

function test_compile_types_inferred()
  @test isinferred(mod.init, nothing, nothing, nothing, nothing, nothing)
  @test isinferred(mod.init, mod.Click(5,5), nothing, nothing, nothing, nothing)
  state = mod.init(nothing, nothing, nothing, nothing, nothing)
  @test isinferred(mod.next, state, mod.Click(5,5), nothing, nothing, nothing, nothing)
  @test isinferred(mod.next, state, nothing, nothing, nothing, nothing, nothing)
end


@testset "compile" begin
  test_compile_if()
  test_compile_assign()
  test_compile_typedecl()
  # test_compile_external()
  test_compile_let()
  test_compile_list()
  test_compile_call()
  test_compile_field()
  test_compile_particles()
  test_compile_types_inferred()
end

