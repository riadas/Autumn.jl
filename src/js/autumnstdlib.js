module.exports = { Cell, Position, moveLeft, moveRight, moveUp, moveDown, ObjectType, updateObj, removeObj };

function Position(args, state) {
  var [x, y] = args;
  console.log("POSITION")
  console.log([x, y])
  return {"x" : x, "y" : y};
}

function Cell(args, state) {
  var [x, y, color] = args;
  console.log("CELL")
  console.log([x, y, color])
  return {"position" : {"x" : x, "y" : y}, "color" : color };
}

function moveLeft(args, state) {
  console.log("MOVELEFT");
  console.log(args);
  var obj = args[0];
  obj.origin.x = obj.origin.x - 1;
  return obj;
}

function moveRight(args, state) {
  console.log("MOVERIGHT");
  console.log(args);
  var obj = args[0];
  obj.origin.x = obj.origin.x + 1;
  return obj;
}

function moveUp(args, state) {
  console.log("MOVEUP");
  console.log(args);
  var obj = args[0];
  obj.origin.x = obj.origin.y - 1;
  return obj;
}

function moveDown(args, state) {
  console.log("MOVEDOWN");
  console.log(args);
  var obj = args[0];
  obj.origin.x = obj.origin.y + 1;
  return obj;
}

function ObjectType(render, fields) {
  console.log("OBJECT_TYPE");
  console.log({"render" : render, "fields" : fields});
  return {"render" : render, "fields" : fields};
}

function prev() {

}

function render() {

}

function renderScene() {

}

function occurred() {

}

function uniformChoice() {

}

function isWithinBounds() {

}

function isOutsideBounds() {

}

function clicked() {

}

function objClicked() {

}

function pushConfiguration() {

}

function pushConfiguration() {

}

function moveIntersects() {

}

function intersects() {

}

function addObj() {

}

function removeObj(args, state) {

}

function updateObj(args, state) {

}

function filter_fallback() {
  return true;
}

function adjPositions() {

}

function isFree() {

}

function rect() {

}

function unitVector() {

}

function displacement() {

}

function adjacent() {

}

function adjacentObjs() {

}

function adjacentObjsDiag() {

}

function adj() {

}

function adjCorner() {

}

function rotate() {

}

function rotateNoCollision() {

}

function move() {

}

function moveNoCollision() {

}

function moveNoCollisionColor() {

}

function moveNoCollisionColor() {

}

function moveLeftNoCollision() {

}

function moveRightNoCollision() {

}

function moveUpNoCollision() {

}

function moveDownNoCollision() {

}

function moveWrap() {

}

function moveLeftWrap() {

}

function moveRightWrap() {

}

function moveUpWrap() {

}

function moveDownWrap() {

}

function randomPositions() {

}

function distance() {

}

function firstWithDefault() {

}

function farthestRandom() {

}

function farthestLeft() {

}

function farthestRight() {

}

function farthestUp() {

}

function farthestDown() {

}

function closest() {

}

function closestRandom() {

}

function closestLeft() {

}

function closestRight() {

}

function closestUp() {

}

function closestDown() {

}

function mapPositions() {

}

function allPositions() {

}

function updateOrigin() {

}

function updateAlive() {

}

function nextLiquid() {

}

function nextSolid() {

}

function allPositions() {

}

function unfold() {

}