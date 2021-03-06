using Test
using Autumn

@testset begin
  prog = au"""
    (program
    (external (: z Int))
    (: x Int)
    (= x 3)
    (: y Int)
    (= y (initnext (+ 1 2) (/ 3 this)))
    (: map (-> (-> a b) (List a) (List b)))
    (: f (-> Int Int))
    (= f (fn (x) (+ x z)))
    (= ys (map f xs))
    (= zs (map (--> a (a + 1)) xs))
    (type alias Particle ((: x Int) (: y Int)))
    (= field (.. particle x))
    (: g (-> (Particle a) (Int)))
    (= g (fn (particle) 
            (case particle
                  (=> (Particle a_) 4)
                  (=> (Dog a_ b_) 5))))
    (: o Int)
    (= o (let ((= q 3) (= d 12)) (+ q d)))
    (if (x == 3) then (y == 4) else (y == 5))
  )
  """
end

## Should parse to
  """
  external z : Int
  x : Int
  x = 3
  y : Int
  y = init 1 + 2 next 3 / this
  map : (a -> b) -> List a -> List b
  f : (Int -> Int)
  f = fn (x) (x + z)
  ys = (map f xs)
  zs = (map (a -> ((a + 1))) xs)
  type alias Particle = { x : Int, y : Int }
  field = particle.x
  g : (Particle a -> Int)
  g = fn (particle) (
    case particle of 
      (Particle a_) => 4
      (Dog a_ b_) => 5)
  o : Int
  o = (let (q = 3 d = 12) q + d)
  if ((x == 3))
    then ((y == 4))
    else ((y == 5))
  """