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
  if (args.length == 3) {
    var [x, y, color] = args;
    console.log("CELL")
    console.log([x, y, color])
    return {"position" : {"x" : x, "y" : y}, "color" : color };
  } else {
    var [position, color] = args;
    console.log("CELL")
    console.log([position, color])
    return {"position" : {"x" : position.x, "y" : position.y}, "color" : color };
  }
}

function moveLeft(args, state=null) {
  console.log("MOVELEFT");
  console.log(args);
  var obj = JSON.parse(JSON.stringify(args[0]));
  obj.origin.x = obj.origin.x - 1;
  return obj;
}

function moveRight(args, state=null) {
  console.log("MOVERIGHT");
  console.log(args);
  var obj = JSON.parse(JSON.stringify(args[0]));
  obj.origin.x = obj.origin.x + 1;
  return obj;
}

function moveUp(args, state=null) {
  console.log("MOVEUP");
  console.log(args);
  var obj = JSON.parse(JSON.stringify(args[0]));
  obj.origin.y = obj.origin.y - 1;
  return obj;
}

function moveDown(args, state=null) {
  console.log("MOVEDOWN");
  console.log(args);
  var obj = JSON.parse(JSON.stringify(args[0]));
  obj.origin.y = obj.origin.y + 1;
  return obj;
}

function prev(args, state=null) {
  var obj = args[0];
  var prev_objects = state.scene.objects.filter(o => o.id == obj.id);
  if (prev_objects.length != 0) {
    return JSON.parse(JSON.stringify(prev_objects[0]));
  } else {
    return JSON.parse(JSON.stringify(obj));
  }
}

function render(args, state=null) {
  var obj = args[0];
  if (obj.alive) {
    if (obj.render == null) {
      render_ = state.object_types[obj.type].render;
      console.log("render_");
      console.log(render_);
      return render_.map(cell => Cell([move([cell.position, obj.origin]), cell.color]));
    } else {
      return obj.render.map(cell => Cell([move([cell.position, obj.origin]), cell.color]));
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
  console.log("UNIFORMCHOICE");
  var freePositions = args[0];
  console.log("freePositions");
  console.log(freePositions);
  if (args.length == 1) {
    return freePositions[Math.floor(Math.random()*freePositions.length)];
  } else {
    var n = args[1];
    var vals = [];
    for (let i = 0; i < n; i++) {
      vals.push(freePositions[Math.floor(Math.random()*freePositions.length)]);
    }
    return vals;
  }
}

function isWithinBounds(args, state=null) {
  if (args[0].id != undefined) {
    var obj = args[0];
    return render([obj], state).filter(cell => !isWithinBounds([cell.position], state)).length == 0;
  } else {
    var position = args[0];
    var GRID_SIZE = state.histories.GRID_SIZE[(state.time - 1).toString()]; 
    if (Array.isArray(GRID_SIZE)) { 
      var [GRID_SIZE_X, GRID_SIZE_Y] = GRID_SIZE;
    } else {
      var GRID_SIZE_X = GRID_SIZE;
      var GRID_SIZE_Y = GRID_SIZE;
    }
    return (position.x >= 0) && (position.x < GRID_SIZE_X) && (position.y >= 0) && (position.y < GRID_SIZE_Y);
  }
}

function isOutsideBounds(args, state=null) {
  var obj = args[0];
  return render([obj], state).filter(cell => isWithinBounds([cell.position], state)).length == 0;
}

function clicked(args, state=null) {
  console.log("clicked woo");
  console.log(args);
  console.log(JSON.stringify(args));
  console.log(state);
  console.log(JSON.stringify(state));
  if (args.length == 2) {
    if (Array.isArray(args[1])) { // clicked array of objects
      var [click, objects] = args;
      if (click == null) {
        return false;
      } else {
        console.log("clicked sad");
        console.log("ret_val");
        console.log(objects.map(obj => clicked([click, obj], state)).reduce((a, b) => a || b, false));
        console.log("huh");
        return objects.map(obj => clicked([click, obj], state)).reduce((a, b) => a || b, false);
      }
    } else if (args[1].id != undefined) { // clicked(click, object)

      var [click, object] = args;
      if (click == null) {
        return false;
      } else {
        var GRID_SIZE = state.histories.GRID_SIZE[(state.time - 1).toString()];
        if (Array.isArray(GRID_SIZE)) {
          var GRID_SIZE_X = GRID_SIZE[0]
          var nums = render([object], state).map(cell => GRID_SIZE_X*cell.position.y + cell.position.x);
          return nums.includes(GRID_SIZE_X * click.y + click.x);
        } else {
          nums = render([object], state).map(cell => GRID_SIZE*cell.position.y + cell.position.x)
          return nums.includes(GRID_SIZE * click.y + click.x)
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
  console.log("objClicked woo");
  console.log(args);
  var [click, objects] = args;
  if (click == null) {
    return null;
  } else {
    var clicked_objects = objects.filter(obj => clicked([click, obj], state));
    if (clicked_objects.length == 0) {
      return null;
    } else {
      console.log("answer");
      console.log(clicked_objects[0]);
      return JSON.parse(JSON.stringify(clicked_objects[0]));
    }
  }
}

// function pushConfiguration(args, state=null) {

// }

// function moveIntersects(args, state=null) {

// }

function intersects(args, state=null) {
  console.log("INTERSECTS");
  console.log(args);
  if (args.length == 2) {
    var [obj1, obj2] = args;

    if (!Array.isArray(obj1) && !Array.isArray(obj2)) {

      var GRID_SIZE = state.histories.GRID_SIZE[(state.time - 1).toString()];
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

      var GRID_SIZE = state.histories.GRID_SIZE[(state.time - 1).toString()];
      if (Array.isArray(GRID_SIZE)) {
        var [GRID_SIZE_X, GRID_SIZE_Y] = GRID_SIZE;
        var nums1 = render([obj1], state).map(cell => GRID_SIZE_X*cell.position.y + cell.position.x);
        var nums2 = unfold([obj2.map(o => render([o], state))]).map(cell => GRID_SIZE_X*cell.position.y + cell.position.x);
        
        return nums1.filter(n => nums2.includes(n)).length != 0;
      } else {
        console.log(JSON.stringify(obj1));
        console.log(JSON.stringify(obj2));

        console.log("GRID_SIZE");
        console.log(GRID_SIZE);
        console.log("HUH");
        console.log(render([obj1], state));
        console.log("HUH END");
        console.log(unfold([obj2.map(o => render([o], state))]));
        console.log("HUH END 2");
        var nums1 = render([obj1], state).map(cell => GRID_SIZE*cell.position.y + cell.position.x);
        var nums2 = unfold([obj2.map(o => render([o], state))]).map(cell => GRID_SIZE*cell.position.y + cell.position.x);
        
        console.log("nums1");
        console.log(nums1);
        console.log("nums2");
        console.log(nums2);
        
        return nums1.filter(n => nums2.includes(n)).length != 0;
      }

    } else if (Array.isArray(obj1) && !Array.isArray(obj2)) {

      var GRID_SIZE = state.histories.GRID_SIZE[(state.time - 1).toString()];
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

      var GRID_SIZE = state.histories.GRID_SIZE[(state.time - 1).toString()];
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
  console.log("addObj woo");
  console.log("args");
  console.log(args);
  var [arr, obj] = args; 
  var new_arr = JSON.parse(JSON.stringify(arr));
  if (!Array.isArray(obj)) {
    new_arr.push(JSON.parse(JSON.stringify(obj)));
  } else {
    new_arr.push(...JSON.parse(JSON.stringify(obj)));
  }
  console.log("new_arr");
  console.log(new_arr);
  return new_arr;
}

function removeObj(args, state=null) {
  console.log("removeObj woo");
  console.log(args);
  if (args.length == 2) {
    var [arr, x] = JSON.parse(JSON.stringify(args)); 
    if (x.id != undefined) { // x is an object
      for (elt of arr) {
        if (elt.id == x.id) {
          elt.alive = false;
        }
      }
      console.log("filtered_arr");
      console.log(arr);
      return arr;
    } else {
      console.log("filtered_arr 2");
      console.log(arr.filter(elt => !x(elt)))
      return arr.filter(elt => !x(elt));
    }
    return arr;
  } else {
    var obj = JSON.parse(JSON.stringify(args[0]));
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
  console.log("isFree");
  console.log(args);
  if (args.length == 1) {
    if (Array.isArray(args[0])) {
      var positions = args[0];
      return positions.map(pos => isFree([pos], state)).reduce((a,b) => a || b, false);
    } else {
      if (args[0] == null) {
        return false;
      } else {
        var position = args[0];
        return renderScene([state.scene], state).filter(cell => cell.position.x == position.x && cell.position.y == position.y).length == 0;
      }
    }
  } else if (args.length == 2) {
    if (args[0].id == undefined && args[1].id == undefined) { // position, position
      var [start, stop] = args;
      var GRID_SIZE = state.histories.GRID_SIZE[(state.time - 1).toString()];
      if (Array.isArray(GRID_SIZE)) { 
        var GRID_SIZE_X = GRID_SIZE[0];
        var GRID_SIZE_Y = GRID_SIZE[1];
      } else {
        var GRID_SIZE_X = GRID_SIZE;
        var GRID_SIZE_Y = GRID_SIZE;
      }
      var translated_start = GRID_SIZE_X * start.y + start.x; 
      var translated_stop = GRID_SIZE_X * stop.y + stop.x;
      if (translated_start < translated_stop) {
        var ordered_start = translated_start;
        var ordered_end = translated_stop;
      } else {
        var ordered_start = translated_stop;
        var ordered_end = translated_start;
      }
      var nums = Array.from(Array(ordered_end - ordered_start + 1).keys()).map(x => x + ordered_start); // [ordered_start:ordered_end;]
      return nums.map(num => isFree([Position([num % GRID_SIZE_X, Math.floor, num / GRID_SIZE_X)])], state)).reduce((a, b) => (a && b), true);
    } else if (args[0].id != undefined && args[1].id != undefined) { // object, object
      var [object, orig_object] = args;
      return render([object], state).map(cell => cell.position).map(x => isFree([x, orig_object], state)).reduce((a, b) => (a && b), true);
    } else { // position, object
      var [position, object] = args;
      return renderScene([Scene(state.scene.objects.filter(obj => obj.id != object.id), state.scene.background)], state).filter(cell => cell.position.x == position.x && cell.position.y == position.y).length == 0;
    }

  } else if (args.length == 3) {
    var [start, stop, object] = args;
    var GRID_SIZE = state.histories.GRID_SIZE[(state.time - 1).toString()];
    if (Array.isArray(GRID_SIZE)) { 
      var GRID_SIZE_X = GRID_SIZE[0];
      var GRID_SIZE_Y = GRID_SIZE[1];
    } else {
      var GRID_SIZE_X = GRID_SIZE;
      var GRID_SIZE_Y = GRID_SIZE;
    }
    var translated_start = GRID_SIZE_X * start.y + start.x; 
    var translated_stop = GRID_SIZE_X * stop.y + stop.x;
    if (translated_start < translated_stop) {
      var ordered_start = translated_start;
      var ordered_end = translated_stop;
    } else {
      var ordered_start = translated_stop;
      var ordered_end = translated_start;
    }
    var nums = Array.from(Array(ordered_end - ordered_start + 1).keys()).map(x => x + ordered_start); // [ordered_start:ordered_end;]
    return nums.map(num => isFree([Position([num % GRID_SIZE_X, Math.floor, num / GRID_SIZE_X)]), object], state)).reduce((a, b) => (a && b), true);
  }
}

// helper
function Scene(objects, background) {
  return {"objects" : objects, "background" : background };
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
  console.log("UNITVECTOR");
  console.log(args);
  if (args.length == 2) {
    var [a, b] = args;
    if (a.id == undefined && b.id == undefined) {
      var deltaX = b.x - a.x;
      var deltaY = b.y - a.y;
      if (Math.floor(Math.abs(Math.sign(deltaX))) == 1 && Math.floor(Math.abs(Math.sign(deltaY))) == 1) {
        return Position([Math.sign(deltaX), 0])
        // uniformChoice(rng, [Position(sign(deltaX), 0), Position(0, sign(deltaY))])
      } else {
        return Position([Math.sign(deltaX), Math.sign(deltaY)])  
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
    return unitVector([Position([0, 0]), position]);
  }
}

function displacement(args, state=null) {
  if (args[0].color != undefined) { // cell version
    var [cell1, cell2] = args;
    return displacement([cell1.position, cell2.position]);
  } else { // position version
    var [position1, position2] = args;
    return Position([Math.floor(position2.x - position1.x), Math.floor(position2.y - position1.y)])
  }
}

function adjacent(args, state=null) {
  if (args[1].color == undefined) { // position/position version
    var [position1, position2, unitSize] = args;
    return [Position([0, 1]), Position([0, -1]), Position([1, 0]), Position([-1, 0])].map(p => JSON.stringify(p)).includes(JSON.stringify(displacement([position1, position2])));
  } else if (Array.isArray(args[1])) { // cell/array of cells version
    var [cell1, cells, unitSize] = args;
    return cells.filter(x => adjacent([cell, x, unitSize])).length != 0;
  } else { // cell/cell version
    var [cell1, cell2, unitSize] = args;
    return adjacent([cell1.position, cell2.position. unitSize]);
  }
}

function adjacentObjs(args, state=null) {
  var [obj, unitSize] = JSON.parse(JSON.stringify(args));
  return JSON.parse(JSON.stringify(state.scene.objects.filter(o => adjacent([o.origin, obj.origin, unitSize]) && (obj.id != o.id))))
}

function adjacentObjsDiag(args, state=null) {
  var obj = args[0];
  return JSON.parse(JSON.stringify(state.scene.objects.filter(o => adjacentDiag([o.origin, obj.origin]) && (obj.id != o.id))));
}

function adjacentDiag(args, state=null) {
  var [position1, position2] = args;
  return [Position([0, 1]), Position([0, -1]), Position([1, 0]), Position([-1, 0]), Position([1,1]), Position([1, -1]), Position([-1, 1]), Position([-1, -1])].map(p => JSON.stringify(p)).includes(JSON.stringify(displacement([position1, position2])));;
}

function adj(args, state=null) {
  console.log("adj");
  console.log(args);
  var [obj1, obj2, unitSize] = args;
  if (!Array.isArray(obj1) && !Array.isArray(obj2)) {
    console.log("answer 1");
    console.log(adjacentObjs([obj1, unitSize], state).filter(o => o.id == obj2.id).length != 0);
    return adjacentObjs([obj1, unitSize], state).filter(o => o.id == obj2.id).length != 0;
  } else if (!Array.isArray(obj1) && Array.isArray(obj2)) {
    console.log("answer 2");
    console.log(adjacentObjs([obj1, unitSize], state).filter(o => obj2.map(x => x.id).includes(o.id)).length != 0);
    return adjacentObjs([obj1, unitSize], state).filter(o => obj2.map(x => x.id).includes(o.id)).length != 0;
  } else { // both are arrays
    console.log("answer 3");
    var obj1_adjacentObjs = unfold(obj1.map(x => adjacentObjs([x, unitSize], state)));
    console.log(intersect(obj1_adjacentObjs.map(x => x.id), obj2.map(x => x.id)).length != 0)
    return intersect(obj1_adjacentObjs.map(x => x.id), obj2.map(x => x.id)).length != 0;
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
  console.log("MOVE WOO");
  console.log(args);
  if (args.length == 2) {
    var [a, b] = args;
    if (a.id != undefined) {
      var new_a = JSON.parse(JSON.stringify(a));
      new_a.origin = move([a.origin, b]);
      console.log("new_a");
      console.log(new_a);
      return new_a;
    } else if (a.color == undefined && b.color == undefined) { // position, position
      return Position([a.x + b.x, a.y + b.y]);
    } else if (a.color == undefined && b.color != undefined) { // position, cell
      return Position([a.x + b.position.x, a.y + b.position.y]);
    } else { // cell, position
      return Position([a.position.x + b.x, a.position.y + b.y]);    
    }
  } else { // args.length == 3
    var [object, x, y] = JSON.parse(JSON.stringify(args));
    return move([object, Position([x, y])]);
  }
}

function moveNoCollision(args, state=null) {
  if (args.length == 2) {
    var [object, position] = JSON.parse(JSON.stringify(args));
    return (isWithinBounds([move([object, position])], state) && isFree([move([object, position.x, position.y]), object], state)) ? move([object, position.x, position.y]) : object; 
  } else {
    var [object, x, y] = JSON.parse(JSON.stringify(args));
    return (isWithinBounds([move([object, x, y])], state) && isFree([move([object, x, y]), object], state)) ? move([object, x, y]) : object;
  }
}

// function moveNoCollisionColor(args, state=null) {

// }

// function moveNoCollisionColor(args, state=null) {

// }

function moveLeftNoCollision(args, state=null) {
  var object = JSON.parse(JSON.stringify(args[0]));
  return (isWithinBounds([move([object, -1, 0])], state) && isFree([move([object, -1, 0]), object], state)) ? move([object, -1, 0]) : object;
}

function moveRightNoCollision(args, state=null) {
  var object = JSON.parse(JSON.stringify(args[0]));
  return (isWithinBounds([move([object, 1, 0])], state) && isFree([move([object, 1, 0]), object], state)) ? move([object, 1, 0]) : object
}

function moveUpNoCollision(args, state=null) {
  var object = JSON.parse(JSON.stringify(args[0]));
  return (isWithinBounds([move([object, 0, -1])], state) && isFree([move([object, 0, -1]), object], state)) ? move([object, 0, -1]) : object;
}

function moveDownNoCollision(args, state=null) {
  var object = JSON.parse(JSON.stringify(args[0]));
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
  console.log("RANDOMPOSITIONS");
  console.log(args);
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
      return Math.abs(position1.x - position2.x) + Math.abs(position1.y - position2.y);
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
      var distances = objects.map(obj => distance([object, obj]));
      return Math.min(...distances);
    }
  } else { // both args are arrays (arr obj, arr obj)
    var [objects1, objects2] = args;
    if (objects1.length == 0 && objects2.length == 0) {
      return Number.MAX_SAFE_INTEGER;
    } else {
      var distances = unfold([objects1.map(obj => distance([obj, objects2]))]);
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
  console.log("CLOSEST");
  console.log(args);
  console.log("huh");
  var GRID_SIZE = state.histories.GRID_SIZE[(state.time - 1).toString()];
  if (Array.isArray(GRID_SIZE)) {
    GRID_SIZE = GRID_SIZE[0];
  }
  if (Array.isArray(args[1])) {
    var [object, arr] = args;
    if (arr.length == 0) {
      return object.origin;
    }
    
    if (arr[0].x != undefined) { // array of positions
      var [object, positions] = JSON.parse(JSON.stringify(args));
      var distances = positions.map(pos => distance([pos, object.origin]));
      distances.sort((a, b) => a - b);
      var closestDistance = distances[0];
      var closest = positions.filter(pos => distance([pos, object.origin]) == closestDistance)[0];
      return closest;
    } else { // array of types
      var [object, types] = args;
      var objects_of_type = state.scene.objects.filter(obj => (types.includes(obj.type)) && (obj.alive))
      if (objects_of_type.length == 0) {
        return object.origin;
      } else {
        var min_distance = Math.min(...objects_of_type.map(obj => distance([object, obj])));
        var objects_of_min_distance = JSON.parse(JSON.stringify(objects_of_type.filter(obj => distance([object, obj]) == min_distance)));
        objects_of_min_distance.sort((o1, o2) => o1.origin.y * GRID_SIZE + o1.origin.x < o2.origin.y * GRID_SIZE + o2.origin.x ? -1 : 1);
        return objects_of_min_distance[0].origin;      
      }
    }
  } else { // obj, type
    var [object, type] = args;
    var objects_of_type = state.scene.objects.filter(obj => (obj.type == type) && (obj.alive))
    if (objects_of_type.length == 0) {
      return object.origin;
    } else {
      console.log("hullo");

      var min_distance = Math.min(...objects_of_type.map(obj => distance([object, obj])));
      var objects_of_min_distance = JSON.parse(JSON.stringify(objects_of_type.filter(obj => distance([object, obj]) == min_distance)));
      objects_of_min_distance.sort((o1, o2) => o1.origin.y * GRID_SIZE + o1.origin.x < o2.origin.y * GRID_SIZE + o2.origin.x ? -1 : 1);
      return objects_of_min_distance[0].origin;      
    }
  }
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
  var [constructor, GRID_SIZE, filterFunction, args_] = args;
  return allPositions([GRID_SIZE]).filter(pos => filterFunction(pos)).map(x => constructor(x));
}

// function updateOrigin(args, state=null) {

// }

// function updateAlive(args, state=null) {

// }

function nextLiquid(args, state=null) {
  // # # println("nextLiquid")
  console.log("nextLiquid");
  console.log(args);

  var [object] = args;
  var GRID_SIZE = state.histories.GRID_SIZE[0];
  if (Array.isArray(GRID_SIZE)) { 
    var GRID_SIZE_X = GRID_SIZE[0]
    var GRID_SIZE_Y = GRID_SIZE[1]
  } else {
    var GRID_SIZE_X = GRID_SIZE;
    var GRID_SIZE_Y = GRID_SIZE;
  }
  var new_object = JSON.parse(JSON.stringify(object));
  if (object.origin.y != GRID_SIZE_Y - 1 && isFree([move([object.origin, Position([0, 1])])], state)) {
    new_object.origin = move([object.origin, Position([0, 1])]);
  } else {
    var leftHoles = allPositions([GRID_SIZE], state).filter(pos => (pos.y == object.origin.y + 1)
                                                                && (pos.x < object.origin.x)
                                                                && isFree([pos], state));
    var rightHoles = allPositions([GRID_SIZE], state).filter(pos => (pos.y == object.origin.y + 1)
                                                                 && (pos.x > object.origin.x)
                                                                 && isFree([pos], state));
    if ((leftHoles.length != 0) || (rightHoles.length != 0)) {
      if (leftHoles.length == 0) {
        var closestHole = closest([object, rightHoles], state);
        if (isFree([move([closestHole, Position([0, -1])]), move([object.origin, Position([1, 0])])], state)) {
          new_object.origin = move([object.origin, unitVector([object, move([closestHole, Position([0, -1])])], state)], state);
        }
      } else if (rightHoles.length == 0) {
        var closestHole = closest([object, leftHoles], state);
        if (isFree([move([closestHole, Position([0, -1])]), move([object.origin, Position([-1, 0])])], state)) {
          new_object.origin = move([object.origin, unitVector([object, move([closestHole, Position([0, -1])])], state)]);                    
        }
      } else {
        var closestLeftHole = closest([object, leftHoles], state);
        var closestRightHole = closest([object, rightHoles], state);
        if (distance([object.origin, closestLeftHole]) > distance([object.origin, closestRightHole])) {
          if (isFree([move([object.origin, Position([1, 0])]), move([closestRightHole, Position([0, -1])])], state)) {
            new_object.origin = move([object.origin, unitVector([new_object, move([closestRightHole, Position([0, -1])])], state)]);
          } else if (isFree([move([closestLeftHole, Position([0, -1])]), move([object.origin, Position([-1, 0])])], state)) {
            new_object.origin = move([object.origin, unitVector([new_object, move([closestLeftHole, Position([0, -1])])])], state);
          }
        } else {
          if (isFree([move([closestLeftHole, Position([0, -1])]), move([object.origin, Position([-1, 0])])], state)) {
            new_object.origin = move([object.origin, unitVector([new_object, move([closestLeftHole, Position([0, -1])])], state)]);
          } else if (isFree([move([object.origin, Position([1, 0])]), move([closestRightHole, Position([0, -1])])], state)) {
            new_object.origin = move([object.origin, unitVector([new_object, move([closestRightHole, Position([0, -1])])], state)]);
          }
        }
      }
    }
  }
  return new_object;
}

function nextSolid(args, state=null) {
  return moveDownNoCollision(args, state);
}

function allPositions(args, state=null) {
  var GRID_SIZE = args[0];
  console.log("GRID_SIZE");
  console.log(GRID_SIZE);
  if (Array.isArray(GRID_SIZE)) {
    var [GRID_SIZE_X, GRID_SIZE_Y] = GRID_SIZE;
  } else {
    var [GRID_SIZE_X, GRID_SIZE_Y] = [GRID_SIZE, GRID_SIZE];
  }
  console.log(GRID_SIZE_X);
  console.log(GRID_SIZE_Y);
  var nums = Array.from(Array(GRID_SIZE_X*GRID_SIZE_Y).keys());
  return nums.map(num => Position([num % GRID_SIZE_X, Math.floor(num / GRID_SIZE_X)], state));
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

// exports 
module.exports = { ObjectType,
                   Position, 
                   Cell, 
                   moveLeft, 
                   moveRight, 
                   moveUp, 
                   moveDown, 
                   prev,
                   render,
                   renderScene,
                   occurred, 
                   uniformChoice,
                   isWithinBounds,
                   isOutsideBounds,
                   clicked,
                   objClicked,
                   intersects, 
                   addObj,
                   removeObj,
                   updateObj,
                   filter_fallback,
                   adjPositions,
                   isFree,
                   rect,
                   unitVector,
                   displacement,
                   adjacent,
                   adjacentObjs,
                   adjacentObjsDiag,
                   adjacentDiag,
                   adj,
                   intersect,
                   move,
                   moveNoCollision,
                   moveLeftNoCollision,
                   moveRightNoCollision,
                   moveUpNoCollision,
                   moveDownNoCollision,
                   randomPositions,
                   distance,
                   closest,
                   mapPositions,
                   nextLiquid,
                   nextSolid,
                   allPositions,
                   unfold,
 };
