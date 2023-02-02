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

}

function isFree(args, state=null) {

}

function rect(args, state=null) {

}

function unitVector(args, state=null) {

}

function displacement(args, state=null) {

}

function adjacent(args, state=null) {

}

function adjacentObjs(args, state=null) {

}

function adjacentObjsDiag(args, state=null) {

}

function adj(args, state=null) {

}

// function adjCorner(args, state=null) {

// }

// function rotate(args, state=null) {

// }

// function rotateNoCollision(args, state=null) {

// }

function move(args, state=null) {

}

function moveNoCollision(args, state=null) {

}

function moveNoCollisionColor(args, state=null) {

}

function moveNoCollisionColor(args, state=null) {

}

function moveLeftNoCollision(args, state=null) {

}

function moveRightNoCollision(args, state=null) {

}

function moveUpNoCollision(args, state=null) {

}

function moveDownNoCollision(args, state=null) {

}

function moveWrap(args, state=null) {

}

function moveLeftWrap(args, state=null) {

}

function moveRightWrap(args, state=null) {

}

function moveUpWrap(args, state=null) {

}

function moveDownWrap(args, state=null) {

}

function randomPositions(args, state=null) {

}

function distance(args, state=null) {

}

function firstWithDefault(args, state=null) {

}

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

function updateOrigin(args, state=null) {

}

function updateAlive(args, state=null) {

}

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