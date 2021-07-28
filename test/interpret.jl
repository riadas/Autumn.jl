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
  @test env.state.particleHistory[0].origin.x == 3
  @test env.state.particleHistory[0].origin.y == 3
  @test env.state.particleHistory[1].origin.x == 4
  @test env.state.particleHistory[1].origin.y == 4
  @test env.state.particleHistory[2].origin.x == 4
  @test env.state.particleHistory[2].origin.y == 4
  @test env.state.particleHistory[3].origin.x == 4
  @test env.state.particleHistory[3].origin.y == 4
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
  @test env.state.particleHistory[0].origin.x == 3
  @test env.state.particleHistory[0].origin.y == 3
  @test env.state.particleHistory[1].origin.x == 3
  @test env.state.particleHistory[1].origin.y == 4
  @test env.state.particleHistory[2].origin.x == 3
  @test env.state.particleHistory[2].origin.y == 5
  @test env.state.particleHistory[3].origin.x == 3
  @test env.state.particleHistory[3].origin.y == 6
end


@testset "interpret" begin
  test_interpret_basic_particles_1()
end

