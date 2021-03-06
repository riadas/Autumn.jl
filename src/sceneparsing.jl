using Random
using Distributions

colors = ["red", "yellow", "green", "blue"]

function generatescene(; gridsize::Int=16)
  numObjects = rand(1:30)
  numTypes = rand(1:10)
  types = [] # each type has form (list of position tuples, index in types list)

  objectPositions = [(rand(1:gridsize), rand(1:gridsize)) for x in 1:numObjects]
  objects = [] # each object has form (type, position tuple, color, index in objects list)

  for type in 1:numTypes
    renderSize = rand(1:5)
    shape = [(0,0)]
    while length(shape) != renderSize
      boundaryPositions = neighbors(shape)
      push!(shape, boundaryPositions[rand(1:length(boundaryPositions))])
    end
    push!(types, (shape, length(types) + 1))
  end

  for i in 1:numObjects
    objPosition = objectPositions[i]
    objColor = colors[rand(1:length(colors))]
    objType = types[rand(1:length(types))]

    push!(objects, (objType, objPosition, objColor, length(objects) + 1))    
  end

  """
  (program
    (= GRID_SIZE $(gridsize))
    $(join(map(t -> "(object ObjType$(t[2]) (: color String) (list $(join(map(cell -> "(Cell $(cell[1]) $(cell[2]) color)", t[1]), " "))))", types), "\n  "))

    $((join(map(obj -> """(: obj$(obj[4]) ObjType$(obj[1][2]))""", objects), "\n  "))...)

    $((join(map(obj -> """(= obj$(obj[4]) (initnext (ObjType$(obj[1][2]) "$(obj[3])" (Position $(obj[2][1]) $(obj[2][2]))) (prev obj$(obj[4]))))""", objects), "\n  ")))
  )
  """
end

function neighbors(shape::AbstractArray)
  neighborPositions = vcat(map(pos -> neighbors(pos), shape)...)
  unique(filter(pos -> !(pos in shape), neighborPositions))
end

function neighbors(position)
  x = position[1]
  y = position[2]
  [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
end
