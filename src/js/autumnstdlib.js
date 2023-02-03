module.exports = { Cell, Position, moveLeft, moveRight, moveUp, moveDown, ObjectType, updateObj, removeObj };

function ObjectType(render, fields) {
  console.log("OBJECT_TYPE");
  console.log({"render" : render, "fields" : fields});
  return {"render" : render, "fields" : fields};
}

function Position(args, state=null) {
  var [x, y] = args;
  console.log("POSITION")
  console.log([x, y])
  return {"x" : x, "y" : y};
}

function Cell(args, state=null) {
  var [x, y, color] = args;
  console.log("CELL")
  console.log([x, y, color])
  return {"position" : {"x" : x, "y" : y}, "color" : color };
}

function moveLeft(args, state=null) {
  console.log("MOVELEFT");
  console.log(args);
  var obj = args[0];
  obj.origin.x = obj.origin.x - 1;
  return obj;
}

function moveRight(args, state=null) {
  console.log("MOVERIGHT");
  console.log(args);
  var obj = args[0];
  obj.origin.x = obj.origin.x + 1;
  return obj;
}

function moveUp(args, state=null) {
  console.log("MOVEUP");
  console.log(args);
  var obj = args[0];
  obj.origin.x = obj.origin.y - 1;
  return obj;
}

function moveDown(args, state=null) {
  console.log("MOVEDOWN");
  console.log(args);
  var obj = args[0];
  obj.origin.x = obj.origin.y + 1;
  return obj;
}

function prev(args, state=null) {
  var obj = args[0];
  var prev_objects = state.scene.objects.filter(o => o.id == obj.id);
  if (prev_objects.length != 0) {
    return prev_objects[0];
  } else {
    return obj;
  }
}

function render(args, state=null) {
  var obj = args[0];
  if (obj.alive) {
    if (obj.render == null) {
      render_ =state.object_types[obj.type].render;
      return render_.map(cell => Cell([move(cell.position, obj.origin), cell.color]));
    } else {
      return obj.render.map(cell => Cell([move(cell.position, obj.origin), cell.color]));
    }
  } else {
    return [];
  }
}

function renderScene(args, state=null) {
  var scene = args[0];
  return unfold([scene.objects.filter(x => x.alive).map(o => render([o], state))]);
}

function occurred(args, state=null) {
  var click = args[0];
  return (click != null);
}

function uniformChoice(args, state=null) {
  var freePositions = args[0];
  return freePositions[Math.floor(Math.random()*freePositions.length)];
}

function isWithinBounds(args, state=null) {
  var obj = args[0];
  return render(obj, state).filter(cell => !isWithinBounds(cell.position, state)).length == 0;
}

function isOutsideBounds(args, state=null) {
  var obj = args[0];
  return render(obj, state).filter(cell => isWithinBounds(cell.position, state)).length == 0;
}

function clicked(args, state=null) {
  if (args.length == 2) {
    if (Array.isArray(args[1])) { // clicked array of objects
      var [click, objects] = args;
      if (click == null) {
        return false;
      } else {
        var GRID_SIZE = state.histories.GRID_SIZE['0'];
        if (Array.isArray(GRID_SIZE)) {
          var GRID_SIZE_X = GRID_SIZE[0]
          var nums = objects.map(object => render([object], state).map(cell => GRID_SIZE_X*cell.position.y + cell.position.x));
          return nums.includes(GRID_SIZE_X * click.y + click.x);
        } else {
          nums = objects.map(object => render([object], state).map(cell => GRID_SIZE*cell.position.y + cell.position.x));
          return nums.include(GRID_SIZE * click.y + click.x)
        }
      }

    } else if (args[1].id != undefined) { // clicked(click, object)

      var [click, object] = args;
      if (click == null) {
        return false;
      } else {
        var GRID_SIZE = state.histories.GRID_SIZE['0'];
        if (Array.isArray(GRID_SIZE)) {
          var GRID_SIZE_X = GRID_SIZE[0]
          var nums = render([object], state).map(cell => GRID_SIZE_X*cell.position.y + cell.position.x);
          return nums.includes(GRID_SIZE_X * click.y + click.x);
        } else {
          nums = render([object], state).map(cell => GRID_SIZE*cell.position.y + cell.position.x)
          return nums.include(GRID_SIZE * click.y + click.x)
        }
      }

    } else { // clicked(click, position)
      var [click, position] = args;
      if (click == null) {
        return false;
      } else {
        return (click.x == position.x) && (click.y == position.y);
      }
    }
  } else { // clicked(click, x, y)
    var [click, x, y] = args;
      if (click == null) {
        return false;
      } else {
        return (click.x == x) && (click.y == y);
      }
    }
}

function objClicked(args, state=null) {
  var [click, objects] = args;
  if (click == null) {
    return null;
  } else {
    var clicked_objects = objects.filter(obj => clicked([click, obj], state));
    if (clicked_objects.length == 0) {
      return null;
    } else {
      return clicked_objects[0];
    }
  }
}

// function pushConfiguration(args, state=null) {

// }

// function moveIntersects(args, state=null) {

// }

function intersects(args, state=null) {
  if (args.length == 2) {
    var [obj1, obj2] = args;

    if (!Array.isArray(obj1) && !Array.isArray(obj2)) {

      var GRID_SIZE = state.histories.GRID_SIZE['0'];
      if (Array.isArray(GRID_SIZE)) {
        var [GRID_SIZE_X, GRID_SIZE_Y] = GRID_SIZE;
        var nums1 = render([obj1], state).map(cell => GRID_SIZE_X*cell.position.y + cell.position.x);
        var nums2 = render([obj2], state).map(cell => GRID_SIZE_X*cell.position.y + cell.position.x);
        return nums1.filter(n => nums2.includes(n)).length != 0;
      } else {
        nums1 = render([obj1], state).map(cell => GRID_SIZE*cell.position.y + cell.position.x);
        nums2 = render([obj2], state).map(cell => GRID_SIZE*cell.position.y + cell.position.x);
        return nums1.filter(n => nums2.includes(n)).length != 0;
      }

    } else if (!Array.isArray(obj1) && Array.isArray(obj2)) {

      var GRID_SIZE = state.histories.GRID_SIZE['0'];
      if (Array.isArray(GRID_SIZE)) {
        var [GRID_SIZE_X, GRID_SIZE_Y] = GRID_SIZE;
        var nums1 = render([obj1], state).map(cell => GRID_SIZE_X*cell.position.y + cell.position.x);
        var nums2 = unfold([obj2.map(o => render([o], state))]).map(cell => GRID_SIZE_X*cell.position.y + cell.position.x);
        return nums1.filter(n => nums2.includes(n)).length != 0;
      } else {
        var nums1 = render([obj1], state).map(cell => GRID_SIZE*cell.position.y + cell.position.x);
        var nums2 = unfold([obj2.map(o => render([o], state))]).map(cell => GRID_SIZE*cell.position.y + cell.position.x);
        return nums1.filter(n => nums2.includes(n)).length != 0;
      }

    } else if (Array.isArray(obj1) && !Array.isArray(obj2)) {

      var GRID_SIZE = state.histories.GRID_SIZE['0'];
      if (Array.isArray(GRID_SIZE)) {
        var [GRID_SIZE_X, GRID_SIZE_Y] = GRID_SIZE;
        var nums2 = render([obj2], state).map(cell => GRID_SIZE_X*cell.position.y + cell.position.x);
        var nums1 = unfold([obj1.map(o => render([o], state))]).map(cell => GRID_SIZE_X*cell.position.y + cell.position.x);
        return nums1.filter(n => nums2.includes(n)).length != 0;
      } else {
        var nums2 = render([obj2], state).map(cell => GRID_SIZE*cell.position.y + cell.position.x);
        var nums1 = unfold([obj1.map(o => render([o], state))]).map(cell => GRID_SIZE*cell.position.y + cell.position.x);
        return nums1.filter(n => nums2.includes(n)).length != 0;
      }

    } else if (Array.isArray(obj1) && Array.isArray(obj2)) {

      var GRID_SIZE = state.histories.GRID_SIZE['0'];
      if (Array.isArray(GRID_SIZE)) {
        var [GRID_SIZE_X, GRID_SIZE_Y] = GRID_SIZE;
        var nums2 = unfold([obj2.map(o => render([o], state))]).map(cell => GRID_SIZE_X*cell.position.y + cell.position.x);
        var nums1 = unfold([obj1.map(o => render([o], state))]).map(cell => GRID_SIZE_X*cell.position.y + cell.position.x);
        return nums1.filter(n => nums2.includes(n)).length != 0;
      } else {
        var nums2 = unfold([obj2.map(o => render([o], state))]).map(cell => GRID_SIZE*cell.position.y + cell.position.x);
        var nums1 = unfold([obj1.map(o => render([o], state))]).map(cell => GRID_SIZE*cell.position.y + cell.position.x);
        return nums1.filter(n => nums2.includes(n)).length != 0;
      }

    }

  } else {
    var object = args[0];
    return intersects([object, state.scene.objects], state)
  }
}

function addObj(args, state=null) {
  var [arr, obj] = args; 
  var new_arr = JSON.parse(JSON.stringify(arr));
  if (!Array.isArray(obj)) {
    new_arr.push(obj);
  } else {
    new_arr.push(...obj);
  }
  return new_arr;
}

function removeObj(args, state=null) {
  if (args.length == 2) {
    var [arr, x] = args; 
    if (x.id != undefined) { // x is n object
      arr.filter(elt => elt.id == x.id).foreach(x => x.alive = false);
    } else {
      arr.filter(elt => !x(elt));
    }
    return arr;
  } else {
    var obj = args[0];
    obj.alive = false;
    return obj;
  }
}

function updateObj(args, state=null) {
  return null;
}

function filter_fallback(args, state=null) {
  return true;
}

function adjPositions(args, state=null) {
  var position = args[0];
  return [Position(position.x, position.y + 1), Position(position.x, position.y - 1), Position(position.x + 1, position.y), Position(position.x - 1, position.y)].filter(x => isWithinBounds([x], state));
}

function isFree(args, state=null) {

}

function rect(args, state=null) {
  var [pos1, pos2] = args;
  
  var min_x = pos1.x; 
  var max_x = pos2.x;
  var min_y = pos1.y;
  var max_y = pos2.y;

  var positions = [];
  for (let x = min_x; x < max_x + 1; x++) {
    for (let y = min_y; y < max_y + 1; y++) {
      positions.push(Position([x, y]));
    }
  }
  return positions;
}

function unitVector(args, state=null) {
  if (args.length == 2) {
    var [a, b] = args;
    if (a.id == undefined && b.id == undefined) {
      var deltaX = position2.x - position1.x;
      var deltaY = position2.y - position1.y;
      if (Math.floor(Math.absolute(Math.sign(deltaX))) == 1 && Math.floor(Math.absolute(Math.sign(deltaY))) == 1) {
        return Position([sign(deltaX), 0])
        // uniformChoice(rng, [Position(sign(deltaX), 0), Position(0, sign(deltaY))])
      } else {
        return Position([sign(deltaX), sign(deltaY)])  
      }
    } else if (a.id != undefined && b.id == undefined) {
      return unitVector([a.origin, b]);
    } else if (a.id == undefined && b.id != undefined) {
      return unitVector([a, b.origin]);
    } else if (a.id != undefined && b.id != undefined) {
      return unitVector([a.origin, b.origin]);
    }
  } else {
    var position = args[0];
    return unitVector([Position([0, 0], position)]);
  }
}

function displacement(args, state=null) {
  if (args[0].color != undefined) { // cell version
    return displacement([cell1.position, cell2.position]);
  } else { // position version
    return Position([Math.floor(position2.x - position1.x), Math.floor(position2.y - position1.y)])
  }
}

function adjacent(args, state=null) {
  if (args[1].color == undefined) { // position/position version
    var [position1, position2, unitSize] = args;
    return [Position([0, 1]), Position([0, -1]), Position([1, 0]), Position([-1, 0])].map(p => JSON.stringify(p)).includes(JSON.stringify(displacement([position1, position2])));
  } else if (Array.isArray(args[1])) { // cell/array of cells version
    var [cell1, cells, unitSize];
    return cells.filter(x => adjacent([cell, x, unitSize])).length != 0;
  } else { // cell/cell version
    var [cell1, cell2, unitSize] = args;
    return adjacent([cell1.position, cell2.position. unitSize]);
  }
}

function adjacentObjs(args, state=null) {
  var [obj, unitSize] = args;
  return state.scene.objects.filter(o => adjacent([o.origin, obj.origin, unitSize]) && (obj.id != o.id))
}

function adjacentObjsDiag(args, state=null) {
  var obj = args[0];
  return state.scene.objects.filter(o => adjacentDiag(o.origin, obj.origin) && (obj.id != o.id));
}

function adjacentDiag(args, state=null) {
  var [position1, position2] = args;
  return [Position([0, 1]), Position([0, -1]), Position([1, 0]), Position([-1, 0]), Position([1,1]), Position([1, -1]), Position([-1, 1]), Position([-1, -1])].map(p => JSON.stringify(p)).includes(JSON.stringify(displacement([position1, position2])));;
}

function adj(args, state=null) {
  var [obj1, obj2, unitSize] = args;
  if (!Array.isArray(obj1) && !Array.isArray(obj2)) {
    return adjacentObjs([obj1, unitSize], state).filter(o => o.id == obj2.id).length != 0;
  } else if (!Array.isArray(obj1) && Array.isArray(obj2)) {
    return adjacentObjs([obj1, unitSize], state).filter(o => obj2.map(x => x.id).includes(o.id)) != [];
  } else { // both are arrays
    var obj1_adjacentObjs = unfold(obj1.map(x => adjacentObjs([x, unitSize], state)));
    return intersect(obj1_adjacentObjs.map(x => x.id), obj2.map(x => x.id)) != [];
  }
}

// helper
function intersect(arr1, arr2) {
  return arr1.filter(elt => arr2.includes(elt));
}

// function adjCorner(args, state=null) {

// }

// function rotate(args, state=null) {

// }

// function rotateNoCollision(args, state=null) {

// }

function move(args, state=null) {
  if (args.length == 2) {
    var [a, b] = args;
    if (a.color == undefined && b.color == undefined) { // position, position
      return Position([a.x + b.x, a.y + b.y]);
    } else if (a.color == undefined && b.color != undefined) { // position, cell
      return Position([a.x + b.position.x, a.y + b.position.y]);
    } else { // cell, position
      return Position([a.position.x + b.x, a.position.y + b.y]);    
    }
  } else { // args.length == 3
    var [object, x, y] = args;
    return move([object, Position([x, y])]);
  }
}

function moveNoCollision(args, state=null) {
  if (args.length == 2) {
    var [object, position] = args;
    return (isWithinBounds([move([object, position])], state) && isFree([move([object, position.x, position.y]), object], state)) ? move([object, position.x, position.y]) : object; 
  } else {
    var [object, x, y] = args;
    return (isWithinBounds([move([object, x, y])], state) && isFree([move([object, x, y]), object], state)) ? move([object, x, y]) : object;
  }
}

// function moveNoCollisionColor(args, state=null) {

// }

// function moveNoCollisionColor(args, state=null) {

// }

function moveLeftNoCollision(args, state=null) {
  var object = args[0];
  return (isWithinBounds([move([object, -1, 0])], state) && isFree([move([object, -1, 0]), object], state)) ? move([object, -1, 0]) : object;
}

function moveRightNoCollision(args, state=null) {
  var object = args[0];
  return (isWithinBounds([move([object, 1, 0])], state) && isFree([move([object, 1, 0]), object], state)) ? move([object, 1, 0]) : object
}

function moveUpNoCollision(args, state=null) {
  var object = args[0];
  return (isWithinBounds([move([object, 0, -1])], state) && isFree([move([object, 0, -1]), object], state)) ? move([object, 0, -1]) : object;
}

function moveDownNoCollision(args, state=null) {
  var object = args[0];
  return (isWithinBounds([move([object, 0, 1])], state) && isFree([move([object, 0, 1]), object], state)) ? move([object, 0, 1]) : object;
}

// function moveWrap(args, state=null) {

// }

// function moveLeftWrap(args, state=null) {

// }

// function moveRightWrap(args, state=null) {

// }

// function moveUpWrap(args, state=null) {

// }

// function moveDownWrap(args, state=null) {

// }

function randomPositions(args, state=null) {
  var [GRID_SIZE, n] = args;
  if (Array.isArray(GRID_SIZE)) {
    var [GRID_SIZE_X, GRID_SIZE_Y] = GRID_SIZE;
    var nums = uniformChoice([Array.from(Array(GRID_SIZE_X*GRID_SIZE_Y - 1).keys()).map(x => x + 1), n], state)
    return nums.map(num => Position([num % GRID_SIZE_X, Math.floor(num / GRID_SIZE_X)]));
  } else {
    var nums = uniformChoice([Array.from(Array(GRID_SIZE*GRID_SIZE - 1).keys()).map(x => x + 1), n], state)
    return nums.map(num => Position([num % GRID_SIZE, Math.floor(num / GRID_SIZE)]));
  }
}

function distance(args, state=null) {
  if (!Array.isArray(args[0]) && !Array.isArray(args[1])) {
    if (args[0].id == undefined && args[1].id == undefined) { // position, position
      var [position1, position2] = args;
      return Math.absolute(position1.x - position2.x) + Math.absolute(position1.y - position2.y);
    } else if (args[0].id != undefined && args[1].id != undefined) { // object, object
      var [object1, object2] = args;
      var position1 = object1.origin;
      var position2 = object2.origin;
      return distance([position1, position2]);      
    } else if (args[0].id != undefined) { // object, position
      var [object, position] = args;
      return distance([object.origin, position]);
    } else { // position, object
      var [position, object] = args;
      return distance([object.origin, position]);
    }
  } else if (!Array.isArray(args[0])) { // second arg is array (obj, arr obj)
    var [object, objects] = args;
    if (objects.length == 0) {
      return Number.MAX_SAFE_INTEGER;
    } else {
      var distances = objects.map(obj => distance(object, obj));
      return Math.min(...distances);
    }
  } else { // both args are arrays (arr obj, arr obj)
    var [objects1, objects2] = args;
    if (objects1.length == 0 && objects2.length == 0) {
      return Number.MAX_SAFE_INTEGER;
    } else {
      var distances = unfold(objects1.map(obj => distance(obj, objects2)));
      return Math.min(...distances);
    }
  }
}

// function firstWithDefault(args, state=null) {

// }

// function farthestRandom(args, state=null) {

// }

// function farthestLeft(args, state=null) {

// }

// function farthestRight(args, state=null) {

// }

// function farthestUp(args, state=null) {

// }

// function farthestDown(args, state=null) {

// }

function closest(args, state=null) {

}

// function closestRandom(args, state=null) {

// }

// function closestLeft(args, state=null) {

// }

// function closestRight(args, state=null) {

// }

// function closestUp(args, state=null) {

// }

// function closestDown(args, state=null) {

// }

function mapPositions(args, state=null) {

}

function allPositions(args, state=null) {

}

// function updateOrigin(args, state=null) {

// }

// function updateAlive(args, state=null) {

// }

function nextLiquid(args, state=null) {

}

function nextSolid(args, state=null) {

}

function allPositions(args, state=null) {
  var GRID_SIZE = state.histories.GRID_SIZE['0'];
  if (Array.isArray(GRID_SIZE)) {
    var [GRID_SIZE_X, GRID_SIZE_Y] = GRID_SIZE;
  } else {
    var [GRID_SIZE_X, GRID_SIZE_Y] = [GRID_SIZE, GRID_SIZE];
  }
  var nums = Array.from(Array(GRID_SIZE_X*GRID_SIZE_Y - 1).keys()).map(x => x + 1);
  return nums.map(n => Position(num % GRID_SIZE_X, Math.floor(num / GRID_SIZE_X), state));
}

function unfold(args, state=null) {
  var A = args[0];
  var V = [];
  for (x of A) {
    for (elt of x) {
      V.push(elt);
    }
  }
  return V;
}