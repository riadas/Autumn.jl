println(pwd())
using Autumn

# println("I like pi")
# prog_autumn = au"""(program
# (= GRID_SIZE 16)

# (object Particle (Cell 0 0 "blue"))

# (: particles (List Particle))
# (= particles 
#    (initnext (list) 
#              (updateObj (prev particles) (--> obj (Particle (uniformChoice (adjPositions (.. obj origin)))))))) 

# (on clicked (= particles (addObj (prev particles) (Particle (Position (.. click x) (.. click y))))))
# )"""

# prog_julia = compiletojulia(prog_autumn)

# prog_autumn = au"""(program
# (include "stdlib.au")
# (= GRID_SIZE 16)

# (structure SomeNewType (: x Int) (: y Int))

# (object Particle (Cell 0 0 "blue"))

# (: particles (List Particle))
# (= particles 
#    (initnext (list) 
#              (updateObj (prev particles) (--> obj (Particle (uniformChoice (adjPositions (.. obj origin)))))))) 

# (on clicked (= particles (addObj (prev particles) (Particle (Position (.. click x) (.. click y))))))
# )"""

# prog_autumn = Nothing

io = open("lib/stdlib.au", "r")
prog_autumn = read(io, String)  # this
prog_autumn = parseautumn(prog_autumn)
prog_julia = compiletojulia(prog_autumn)
open("governancetest/CompiledAutumnCode2.jl", "w") do io1
   # write(io1, string(prog_julia))
   write(io1, string(prog_julia.args[1]))
end

# open("lib/stdlib.au", "r") do io
#    prog_autumn = read(io, String)  # this
#    println(prog_autumn)

#    # println(apple)
#    println(compiletojulia)
#    # prog_julia = compiletojulia(prog_autumn)
#    # open("governancetest/CompiledAutumnCode2.jl", "w") do io1
#    #    write(io1, string(prog_julia))
#    # end
# end
