using Test
using Autumn

function test_interpret_basic_particles_1()
  a = au"""(program
  (= GRID_SIZE 16)
  
  (object Particle (Cell 0 0 "blue"))

  (: particle Particle)
  (= particle (initnext (Particle (Position 3 3)) (prev particle)))
  
  (on true (= particle (Particle (Position 4 4))))
)"""
  env = interpret_over_time(a, 3)
  @test env.state.histories[:particle][0].origin.x == 3
  @test env.state.histories[:particle][0].origin.y == 3
  @test env.state.histories[:particle][1].origin.x == 4
  @test env.state.histories[:particle][1].origin.y == 4
  @test env.state.histories[:particle][2].origin.x == 4
  @test env.state.histories[:particle][2].origin.y == 4
  @test env.state.histories[:particle][3].origin.x == 4
  @test env.state.histories[:particle][3].origin.y == 4
end

function test_interpret_basic_particles_2()
  a = au"""(program
  (= GRID_SIZE 16)
  
  (object Particle (Cell 0 0 "blue"))

  (: particle Particle)
  (= particle (initnext (Particle (Position 3 3)) (prev particle)))
  
  (on true (= particle (Particle (Position (.. (.. (prev particle) origin) x) 
                                           (+ (.. (.. (prev particle) origin) y) 1)))))
)"""
  env = interpret_over_time(a, 3)
  @test env.state.histories[:particle][0].origin.x == 3
  @test env.state.histories[:particle][0].origin.y == 3
  @test env.state.histories[:particle][1].origin.x == 3
  @test env.state.histories[:particle][1].origin.y == 4
  @test env.state.histories[:particle][2].origin.x == 3
  @test env.state.histories[:particle][2].origin.y == 5
  @test env.state.histories[:particle][3].origin.x == 3
  @test env.state.histories[:particle][3].origin.y == 6
end

function test_interpret_full_particles()
  a = au"""(program
  (= GRID_SIZE 16)
  
  (object Particle (Cell 0 0 "blue"))

  (: particles (List Particle))
  (= particles 
     (initnext (list) 
               (updateObj (prev particles) (--> obj (Particle (uniformChoice (adjPositions (.. obj origin)))))))) 
  
  (on clicked (= particles (addObj (prev particles) (Particle (Position (.. click x) (.. click y))))))
)"""
  env = interpret_over_time(a, 4, [ (click=Autumn.AutumnStandardLibrary.Click(5,5),), empty_env(), (click=Autumn.AutumnStandardLibrary.Click(9,9),), empty_env()])
  @test length(env.state.histories[:particles][0]) == 0
  @test length(env.state.histories[:particles][1]) == 1
  @test length(env.state.histories[:particles][2]) == 1
  @test length(env.state.histories[:particles][3]) == 2
  @test length(env.state.histories[:particles][4]) == 2

  @test env.state.histories[:particles][1][1].origin.x == 5 
  @test env.state.histories[:particles][1][1].origin.y == 5


end


@testset "interpret" begin
  test_interpret_basic_particles_1()
  test_interpret_basic_particles_2()
  test_interpret_full_particles()
end

