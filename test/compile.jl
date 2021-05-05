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

function isinferred(f, args...; allow = Union{})
  ret = f(args...)
  inftypes = Base.return_types(f, Base.typesof(args...))
  rettype = ret isa Type ? Type{ret} : typeof(ret)
  rettype <: allow || rettype == Test.typesubtract(inftypes[1], allow)
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

function test_compile_external()
  data = construct_data()
  aexpr = au"""(external (: click Click))"""
  @test compile(aexpr, data) == :()
end

function test_compile_let()
  data = construct_data()
  aexpr = au"""(let ((= y 3) (= x y)) x)"""

  @test compile(aexpr, data).args[end - 2: end] == [:(y = 3), :(x = y), :x]
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

function test_compile_structure()
  data = construct_data()
  aexpr = au"""(structure Name (: x Int) (: y Bool))"""
  eval(compile(aexpr, data))  
  expected = quote
    struct Expected
      x::Int
      y::Bool
    end
  end
  eval(expected)
  @test fieldnames(Name) == fieldnames(Expected)
  @test fieldtypes(Name) == fieldtypes(Expected)
end

function test_compile_particles()
  a = au"""(program
    (: GRID_SIZE Int)
    (= GRID_SIZE 16)

    (type alias Position ((: x Int) (: y Int)))
    (type alias Particle ((: position Position)))

    (external (: click Click))

    (: particles (List Particle))
    (= particles (initnext (list) (if (occurred click) 
                                then (push! (prev particles) (particleGen (Position 1 1))) 
                                else (map nextParticle (prev particles)))))
    (: nparticles Int)
    (= nparticles (length particles))
    
    (: isFree (-> Position Bool))
    (= isFree (fn (position) 
                  (== (length (filter (--> particle (== (.. particle position) position)) (prev particles))) 0)))

    (: isWithinBounds (-> Position Bool))
    (= isWithinBounds (fn (position) 
                          (& (>= (.. position x) 0) (& (< (.. position x) GRID_SIZE) (& (>= (.. position y) 0) (< (.. position y) GRID_SIZE))))))
    
    (: adjacentPositions (-> Position (List Position)))
    (= adjacentPositions (fn (position) 
                            (let ((= x (.. position x)) 
                                  (= y (.. position y)) 
                                  (= positions (filter isWithinBounds (list (Position (+ x 1) y) (Position (- x 1) y) (Position x (+ y 1)) (Position x (- y 1))))))
                                  positions)))

    (: nextParticle (-> Particle Particle))
    (= nextParticle (fn (particle) 
                        (let ((= freePositions (filter isFree (adjacentPositions (.. particle position))))) 
                            (case freePositions
                                  (=> (list) particle)
                                  (=> _ (Particle (uniformChoice freePositions)))))))

    (: particleGen (-> Position Particle))
    (= particleGen (fn (initPosition) (Particle initPosition)))
  )"""
  @test string(compiletojulia(a)) == "\$(Expr(:toplevel, :(module CompiledProgram\n  export init, next\n  import Base.min\n  using Distributions\n  using MLStyle: @match\n  begin\n      function occurred(click)\n          click !== nothing\n      end\n  end\n  begin\n      function uniformChoice(freePositions)\n          freePositions[rand(Categorical(ones(length(freePositions)) / length(freePositions)))]\n      end\n  end\n  begin\n      function uniformChoice(freePositions, n)\n          map((idx->begin\n                      freePositions[idx]\n                  end), rand(Categorical(ones(length(freePositions)) / length(freePositions)), n))\n      end\n  end\n  begin\n      function min(arr)\n          min(arr...)\n      end\n  end\n  begin\n      struct Click\n          x::BigInt\n          y::BigInt\n      end\n  end\n  begin\n      function range(start::BigInt, stop::BigInt)\n          [start:stop;]\n      end\n  end\n  begin\n      struct Position\n          x::Int\n          y::Int\n      end\n  end\n  begin\n      struct Particle\n          position::Position\n      end\n  end\n  begin\n      function isFree(position::Position)::Bool\n          length(filter((particle->begin\n                              particle.position == position\n                          end), particlesPrev())) == 0\n      end\n  end\n  begin\n      function isWithinBounds(position::Position)::Bool\n          (position.x >= 0) & ((position.x < GRID_SIZE) & ((position.y >= 0) & (position.y < GRID_SIZE)))\n      end\n  end\n  begin\n      function adjacentPositions(position::Position)::Array{Position}\n          begin\n              x = position.x\n              y = position.y\n              positions = filter(isWithinBounds, [Position(x + 1, y), Position(x - 1, y), Position(x, y + 1), Position(x, y - 1)])\n              positions\n          end\n      end\n  end\n  begin\n      function nextParticle(particle::Particle)::Particle\n          begin\n              freePositions = filter(isFree, adjacentPositions(particle.position))\n              begin\n                  @match freePositions begin\n                          [] => particle\n                          _ => Particle(uniformChoice(freePositions))\n                      end\n              end\n          end\n      end\n  end\n  begin\n      function particleGen(initPosition::Position)::Particle\n          Particle(initPosition)\n      end\n  end\n  begin\n      mutable struct STATE\n          time::Int\n          particlesHistory::Dict{Int64, Array{Particle}}\n          GRID_SIZEHistory::Dict{Int64, Int}\n          nparticlesHistory::Dict{Int64, Int}\n          clickHistory::Dict{Int64, Union{Click, Nothing}}\n      end\n  end\n  state = STATE(0, Dict{Int64, Array{Particle}}(), Dict{Int64, Int}(), Dict{Int64, Int}(), Dict{Int64, Union{Click, Nothing}}())\n  begin\n      function particlesPrev(n::Int=1)::Array{Particle}\n          state.particlesHistory[if state.time - n >= 0\n                  state.time - n\n              else\n                  0\n              end]\n      end\n  end\n  begin\n      function GRID_SIZEPrev(n::Int=1)::Int\n          state.GRID_SIZEHistory[if state.time - n >= 0\n                  state.time - n\n              else\n                  0\n              end]\n      end\n  end\n  begin\n      function nparticlesPrev(n::Int=1)::Int\n          state.nparticlesHistory[if state.time - n >= 0\n                  state.time - n\n              else\n                  0\n              end]\n      end\n  end\n  begin\n      function clickPrev(n::Int=1)::Union{Click, Nothing}\n          state.clickHistory[if state.time - n >= 0\n                  state.time - n\n              else\n                  0\n              end]\n      end\n  end\n  begin\n      function init(click::Union{Click, Nothing})::STATE\n          state = STATE(0, Dict{Int64, Array{Particle}}(), Dict{Int64, Int}(), Dict{Int64, Int}(), Dict{Int64, Union{Click, Nothing}}())\n          particles = []\n          GRID_SIZE = 16\n          nparticles = length(particles)\n          state.clickHistory[state.time] = click\n          state.particlesHistory[state.time] = particles\n          state.GRID_SIZEHistory[state.time] = GRID_SIZE\n          state.nparticlesHistory[state.time] = nparticles\n          deepcopy(state)\n      end\n  end\n  begin\n      function next(old_state::STATE, click::Union{Click, Nothing})::STATE\n          global state = deepcopy(old_state)\n          state.time = state.time + 1\n          particles = if occurred(click)\n                  push!(particlesPrev(), particleGen(Position(1, 1)))\n              else\n                  map(nextParticle, particlesPrev())\n              end\n          GRID_SIZE = 16\n          nparticles = length(particles)\n          state.clickHistory[state.time] = click\n          state.particlesHistory[state.time] = particles\n          state.GRID_SIZEHistory[state.time] = GRID_SIZE\n          state.nparticlesHistory[state.time] = nparticles\n          deepcopy(state)\n      end\n  end\n  end)))"
  global mod = eval(compiletojulia(a))
end

function test_compile_types_inferred()
  @test isinferred(mod.init, nothing)
  @test isinferred(mod.init, mod.Click(5,5))
  state = mod.init(nothing)
  @test isinferred(mod.next, state, mod.Click(5,5))
  @test isinferred(mod.next, state, nothing)
end


@testset "compile" begin
  test_compile_if()
  test_compile_assign()
  test_compile_typedecl()
  test_compile_external()
  test_compile_let()
  test_compile_list()
  test_compile_call()
  test_compile_field()
  test_compile_structure()
  test_compile_particles()
  test_compile_types_inferred()
end

