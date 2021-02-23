using Test
using Autumn

@test showstring(au"""(program
(= GRID_SIZE 16)

(type alias Position ((: x Int) (: y Int)))
(type alias Particle ((: position Position)))

(external (: click Click))

(: particles (List Particle))
(= particles (initnext (list) (if (occurred click) 
                             then (push! (prev particles) (particleGen (Position 1 1))) 
                             else (map nextParticle particles))))

(= nparticles (length particles))

(: isFree (-> Position Bool))
(= isFree (fn (position) 
              (length (filter (--> particle (!= (.. particle position) position)) particles))))

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
)""") == "GRID_SIZE = 16\ntype alias Position = { x : Int, y : Int }\ntype alias Particle = { position : Position }\nexternal click : Click\nparticles : List Particle\nparticles = init () next if ((occurred click)) then ((push! (prev particles) (particleGen (Position 1 1)))) else ((map nextParticle particles))\nnparticles = (length particles)\nisFree : (Position -> Bool)\nisFree = fn (position) ((length (filter (particle -> ((!= particle.position position))) particles)))\nisWithinBounds : (Position -> Bool)\nisWithinBounds = fn (position) ((& position.x >= 0 (& position.x < GRID_SIZE (& position.y >= 0 position.y < GRID_SIZE))))\nadjacentPositions : (Position -> List Position)\nadjacentPositions = fn (position) (let \n\tx = position.x\n\ty = position.y\n\tpositions = (filter isWithinBounds ((Position x + 1 y), (Position x - 1 y), (Position x y + 1), (Position x y - 1)))\nin\n\tpositions)\nnextParticle : (Particle -> Particle)\nnextParticle = fn (particle) (let \n\tfreePositions = (filter isFree (adjacentPositions particle.position))\nin\n\t\n\tcase freePositions of \n\t\t() => particle\n\t\t_ => (Particle (uniformChoice freePositions)))\nparticleGen : (Position -> Particle)\nparticleGen = fn (initPosition) ((Particle initPosition))"