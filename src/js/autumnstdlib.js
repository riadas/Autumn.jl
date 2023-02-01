module.exports = { Cell, Position, moveLeft, ObjectType };

function Cell(args, state) {
  var [x, y, color] = args;
  console.log("CELL")
  console.log([x, y, color])
  return {"position" : {"x" : x, "y" : y}, "color" : color };
}

function Position(args, state) {
  var [x, y] = args;
  console.log("POSITION")
  console.log([x, y])
  return {"x" : x, "y" : y};
}

function moveLeft(args, state) {
  console.log("MOVELEFT");
  console.log(args);
  obj = args[0];
  obj.origin.x = obj.origin.x - 1;
  return obj;
}

function ObjectType(render, fields) {
  console.log("OBJECT_TYPE");
  console.log({"render" : render, "fields" : fields});
  return {"render" : render, "fields" : fields};
}