using Autumn

# x : Int
# y = x + 3
# y = 2
# on x > y
#    y = y + 1


function test_ainterpret()
  program = au"""
  (program
    (: x Int)
    (= y 2)
    (on (> x y)
        (= y (+ y 1))))
  """
  ainterpret(program)
end