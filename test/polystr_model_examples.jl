using Autumn

arithmatic = au"""(program
  (: x Int)
  (: y Int)
  (: z Int)
  (= x (initnext 0 (+ (prev x) 2)))
  (= y (initnext 1 (+ 1 (prev y))))
  (= z (initnext (+ x y) (+ x y)))

  (runner R)
  (in R (: z Bool))
  (in R (= z (initnext (== (% (+ x y) 2) 1) (== (% (+ x y) 2) 1))))
  (run R)
)"""

env_arith = polystr_interpret_over_time(arithmatic, 4, [])

light_switch = au"""(program
  (= GRID_SIZE 16)
  (in HIGH_LEVEL 
    (: light Bool)
    (= light (initnext false (prev light)))
  )

  (: switch Bool)
  (= switch (initnext false (prev switch)))

  (on clicked (= switch (! switch)))
  (on switch (= light true))
  (on (! switch) (= light false))

  (runner R)
  (in R
    (: light Bool)
    (= light (initnext false (prev light)))
    (: powercut Bool)
    (= powercut (initnext false (prev powercut)))
    (on switch (= light (! powercut)))
  )

  (runner P)
  (in P
    (: light Int)
    (= light (initnext 0 (prev light)))
    (: volt Int)
    (= volt (initnext 7 (prev volt)))
    (on switch (= light volt))
  )
  
  (run P)
)"""

env_light = polystr_interpret_over_time(light_switch, 4, [(click=Autumn.AutumnStandardLibrary.Click(5,5),), empty_env(), (click=Autumn.AutumnStandardLibrary.Click(9,9),), empty_env()])

lamp_example = au"""(program
    (= GRID_SIZE 16)

    (object Lamp (: on Bool) (map (--> pos (Cell pos (if on then "gold" else "gray"))) (vcat (list (Position 0 0)) 
                                                                        (rect (Position -1 1) (Position 1 1))
                                                                        (rect (Position -2 2) (Position 2 3))
                                                                        (rect (Position 0 4) (Position 0 6))
                                                                        (rect (Position -2 7) (Position 2 7))
                                                )) )
    (object Switch (: on Bool) (Cell 0 0 (if on then "red" else "black")))
    (object Outlet (: powerOut Bool) (map (--> pos (Cell pos "darkorange")) (rect (Position 0 -1) (Position 0 1))))
    (object Wire (: attached Bool) (if attached then (map (--> pos (Cell pos "brown")) (vcat (rect (Position 0 0) (Position 4 0)) (rect (Position 4 -2) (Position 4 -1)) (Position 5 -2))) 
                                                else (map (--> pos (Cell pos "brown")) (vcat (rect (Position 0 0) (Position 4 0)) (rect (Position 4 1) (Position 4 2)) (Position 5 2)))
                                ))

    (: lamp Lamp)
    (= lamp (initnext (Lamp false (Position 5 5)) (prev lamp)))

    (: switch Switch)
    (= switch (initnext (Switch false (Position 3 11)) (prev switch)))

    (: outlet Outlet)
    (= outlet (initnext (Outlet false (Position 14 10)) (prev outlet)))

    (: wire Wire)
    (= wire (initnext (Wire true (Position 8 12)) (prev wire)))

    (on (clicked switch) (= switch (updateObj switch "on" (! (.. switch on)))))
    (on (.. switch on) (= lamp (updateObj lamp "on" true)))
    (on (! (.. switch on)) (= lamp (updateObj lamp "on" false)))

    (runner Full)
    (in Full 
    (on (clicked outlet) (= outlet (updateObj outlet "powerOut" (! (.. outlet powerOut)))))
    (on (clicked wire) (= wire (updateObj wire "attached" (! (.. wire attached)))))
    (on (& (! (.. outlet powerOut)) (& (.. switch on) (.. wire attached))) (= lamp (updateObj lamp "on" true)))
    (on (! (& (! (.. outlet powerOut)) (& (.. switch on) (.. wire attached)))) (= lamp (updateObj lamp "on" false))))

    (runner WithoutPowerOut)
    (in WithoutPowerOut
      (on (clicked wire) (= wire (updateObj wire "attached" (! (.. wire attached)))))
      (on (& (.. switch on) (.. wire attached)) (= lamp (updateObj lamp "on" true)))
      (on (! (& (.. switch on) (.. wire attached))) (= lamp (updateObj lamp "on" false)))
    )
)"""

env_lamp = polystr_interpret_over_time(lamp_example, 3, [(click = Autumn.AutumnStandardLibrary.Click(3, 11), ), (click=Autumn.AutumnStandardLibrary.Click(8,12),), (click=Autumn.AutumnStandardLibrary.Click(3, 11),)])

particles = au"""(program
    (= GRID_SIZE 16)

    (= particleSize (initnext 1 (prev particleSize)))

    (runner R1)
    (in R1 (= particleSize (initnext 2 (prev particleSize))))
    
    (runner R2)
    (in R2 (= particleSize (initnext 3 (prev particleSize))))

    (object Particle (: size Int) (map (--> pos (Cell pos "blue")) (rect (Position 0 0) (Position (- size 1) (- size 1)))))

    (= particles (initnext (list) (updateObj (prev particles) (--> obj (uniformChoice (list (moveNoCollision obj (- 0 particleSize) 0) (moveNoCollision obj particleSize 0) (moveNoCollision obj 0 particleSize) (moveNoCollision obj 0 (- 0 particleSize))) ))))) 
    (on clicked (= particles (addObj (prev particles) (Particle particleSize (Position (- (.. click x) (% (.. click x) particleSize)) (- (.. click y) (% (.. click y) particleSize)) )))))

    (run R1)
)"""

env_particles = polystr_interpret_over_time(particles, 4, [(click=Autumn.AutumnStandardLibrary.Click(5,5),), empty_env(), (click=Autumn.AutumnStandardLibrary.Click(9,9),), empty_env()])
