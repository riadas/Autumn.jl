using Test
using Autumn
using Random

aexpr = au"""(program
(= GRID_SIZE 16)

(object Particle (Cell 0 0 "blue"))

(: particles (List Particle))
(= particles 
   (initnext (list) 
             (updateObj (prev particles) (--> obj (Particle (uniformChoice (adjPositions (.. obj origin))))))))        

(on clicked (= particles (addObj (prev particles) (Particle (Position (.. click x) (.. click y))))))
)"""
#
compiledMod = eval(compiletojulia(aexpr))

# time 0
state = compiledMod.init(nothing, nothing, nothing, nothing, nothing, MersenneTwister(0))
@test compiledMod.render(state.scene) == []

# time 1
state = compiledMod.next(state, nothing, nothing, nothing, nothing, nothing)
@test compiledMod.render(state.scene) == []

# time 2
state = compiledMod.next(state, compiledMod.Click(5,5), nothing, nothing, nothing, nothing)
@test compiledMod.render(state.scene) == [compiledMod.Cell(compiledMod.Position(5, 5), "blue", 0.8)]

# time 3
state = compiledMod.next(state, nothing, nothing, nothing, nothing, nothing)
@test compiledMod.render(state.scene) == [compiledMod.Cell(compiledMod.Position(4, 5), "blue", 0.8)]

# time 4
state = compiledMod.next(state, nothing, nothing, nothing, nothing, nothing)
@test compiledMod.render(state.scene) == [compiledMod.Cell(compiledMod.Position(3, 5), "blue", 0.8)]
