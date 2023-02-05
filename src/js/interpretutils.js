// import { parseau } from "./sexpr.js"
// import * as AutumnStandardLibrary from "./autumnstdlib.js"
const { parseau } = require("./sexpr.js");
module.exports = { interpret, update };

// imports
const { ObjectType,
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
      } = require("./autumnstdlib.js");

function update(env, x, v) {
  var new_env = JSON.parse(JSON.stringify(env))
  new_env[x] = v;
  return new_env;
}

function isaexpr(aex) {
  return (aex != null && typeof(aex) == "object" && aex.head != undefined)
}

function isobject(aex) {
  return (aex != null && typeof(aex) == "object" && aex.id != undefined)
}

var prim_to_func = {"+" : function(x, y) {return x + y;},
                   "-" : function(x, y) {return x - y;},
                   "*" : function(x, y) {return x * y;},
                   "/" : function(x, y) {return x / y;},
                   "&" : function(x, y) {return x && y;},
                   "!" : function(x) {return !x;},
                   "|" : function(x, y) {return x || y;},
                   ">" : function(x, y) {return x > y;},
                   "<" : function(x, y) {return x < y;},
                   "<=" : function(x, y) {return x <= y;},
                   "==" : function(x, y) {return x == y;},
                   "%" : function(x, y) {return x % y;},
                   "!=" : function(x, y) {return x != y},  
                  }

function isprim(f) {
  return (f in prim_to_func);
}

function primapl_uni(f, x, env) {
  var [x, env] = interpret(x, env);
  return [prim_to_func[f](x), env];
}

function primapl(f, x, y, env) {
  console.log("PRIMAPL");
  console.log(x);
  console.log(y);
  var [x, env] = interpret(x, env);
  var [y, env] = interpret(y, env);
  if (f == "==" || f == "!=") {
    return [prim_to_func[f](JSON.stringify(x), JSON.stringify(y)), env]
  } else {
    return [prim_to_func[f](x, y), env]
  }
}

var lib_to_func = {"ObjectType" : ObjectType,
                   "Position" : Position, 
                   "Cell" : Cell, 
                   "moveLeft" : moveLeft, 
                   "moveRight" : moveRight, 
                   "moveUp" : moveUp, 
                   "moveDown" : moveDown, 
                   "prev" : prev,
                   "render" : render,
                   "renderScene" : renderScene,
                   "occurred" : occurred, 
                   "uniformChoice" : uniformChoice,
                   "isWithinBounds" : isWithinBounds,
                   "isOutsideBounds" : isOutsideBounds,
                   "clicked" : clicked,
                   "objClicked" : objClicked,
                   "intersects" : intersects, 
                   "addObj" : addObj,
                   "removeObj" : removeObj,
                   "updateObj" : updateObj,
                   "filter_fallback" : filter_fallback,
                   "adjPositions" : adjPositions,
                   "isFree" : isFree,
                   "rect" : rect,
                   "unitVector" : unitVector,
                   "displacement" : displacement,
                   "adjacent" : adjacent,
                   "adjacentObjs" : adjacentObjs,
                   "adjacentObjsDiag" : adjacentObjsDiag,
                   "adjacentDiag" : adjacentDiag,
                   "adj" : adj,
                   "intersect" : intersect,
                   "move" : move,
                   "moveNoCollision" : moveNoCollision,
                   "moveLeftNoCollision" : moveLeftNoCollision,
                   "moveRightNoCollision" : moveRightNoCollision,
                   "moveUpNoCollision" : moveUpNoCollision,
                   "moveDownNoCollision" : moveDownNoCollision,
                   "randomPositions" : randomPositions,
                   "distance" : distance,
                   "closest" : closest,
                   "mapPositions" : mapPositions,
                   "nextLiquid" : nextLiquid,
                   "nextSolid" : nextSolid,
                   "allPositions" : allPositions,
                   "unfold" : unfold,
                  }

function islib(f) {
  return (f in lib_to_func);
}

function libapl(f, args, env) {
  console.log("libapl");
  console.log(f);
  console.log(args);
  console.log(JSON.stringify(env));
  if (f == "clicked" && args.length == 0) {
    return interpret(f, env);
  } else if (f == "clicked") {
    return [lib_to_func[f]([interpret("click", env)[0], ...args], env.state), env]
  } else {
    var has_function_arg = false; 
    for (arg of args) {
      console.log("arg");
      console.log(JSON.stringify(arg));
      if (Array.isArray(arg) && (arg.length == 2) && (isaexpr(arg[0]) || typeof(arg[0]) == "string") && (isaexpr(arg[1]) || typeof(arg[1]) == "string")) {
        has_function_arg = true;
      }
    }

    console.log("has_function_arg__");
    console.log(has_function_arg);
    if (!has_function_arg && f != "updateObj") {
      return [lib_to_func[f](args.map(a => interpret(a, env)[0]), env.state), env]
    } else {
      if (f == "updateObj") {
        return interpret_updateObj(args, env)
      } else if (f == "removeObj") {
        return interpret_removeObj(args, env)
      } else {
        [lib_to_func[f](args.map(a => interpret(a, env)[0]), env.state), env]
      }
    }

  }
}

js_lib_to_func = new Set(["get",
                         "map",
                         "filter",
                         "first",
                         "last",
                         "in", 
                         "intersect",
                         "length",
                         "sign",
                         "vcat", 
                         "count"]);

function isjslib(f) {
  return (js_lib_to_func.has(f));
}

function jslibapl(f, args, env) {
  if (f == "get") {
    console.log("GET ME")
    console.log(f);
    console.log(args);
    console.log(env);
    var [dict, env] = interpret(args[0], env);
    var key = args[1];
    if (isaexpr(key)) {
      [key, env] = interpret(key, env);
    } 
    var [default_, env] = interpret(args[2], env);

    console.log("DICT");
    console.log(dict);
    console.log("key");
    console.log(key);
    console.log("default_");
    console.log(default_);

    return [(key in dict ? dict[key] : default_), env];
  } else if (f == "map") {  
    return interpret_js_map(args, env);
  } else if (f == "filter") {
    return interpret_js_filter(args, env);
  } else if (f == "first") {
    var [l, env] = interpret(args[0], env);
    return [l[0], env];
  } else if (f == "last") {
    var [l, env] = interpret(args[0], env);
    return [l[l.length - 1], env];
  } else if (f == "in") {
    var [elt, env] = interpret(args[0], env);
    var [l, env] = interpret(args[1], env);
    return [l.includes(elt), env];
  } else if (f == "intersect") {
    var [l1, env] = interpret(args[0], env);
    var [l2, env] = interpret(args[1], env);
    return [l1.filter(elt => l2.includes(elt)), env];
  } else if (f == "length") {
    var [l, env] = interpret(args[0], env);
    return [l.length, env];
  } else if (f == "sign") {
    var [v, env] = interpret(args[0], env);
    return [v >= 0 ? 1 : -1, env];
  } else if (f == "vcat") {
    var ls = args.map(l => interpret(l, env)[0]);
    return [[].concat(...ls), env];
  } else if (f == "count") {
    return interpret_js_count(args, env);
  }
}

function interpret(aex, env) {
  console.log("INTERPRET GLOBAL")
  console.log(aex)
  if (isaexpr(aex)) {
    console.log(aex.head)
    if (aex.head == "if") {
      var [c, t, e] = aex.args; 
      var [v, env2] = interpret(c, env);
      if (v) {
        return interpret(t, env2);
      } else {
        return interpret(e, env2);
      }
    } else if (aex.head == "assign") {
      var [x, v] = aex.args 
      if (v.head == "initnext") {
        return interpret_init_next(x, v, env);
      } else if (isaexpr(v) || typeof(v) == "string") {
        var [v2, env] = interpret(v, env);
        return interpret({"head" : "assign", "args" : [x, v2]}, env);
      } else {
        env.current_var_values[x] = interpret(v, env)[0];
        return [aex, env];
      }
      
    } else if (aex.head == "list") {
      return interpret_list(aex.args, env);
    } else if (aex.head == "typedecl") {
      return [aex, env];
    } else if (aex.head == "let") {
      return interpret_let(aex.args, env);
    } else if (aex.head == "lambda") {
      return [aex.args, env];
    } else if (aex.head == "fn") {
      return [aex.args, env];
    } else if (aex.head == "call") {
      var f = aex.args[0];
      var args = aex.args[1];

      if (!Array.isArray(args)) {
        args = [args];
      }

      console.log(f);
      console.log(args);
      console.log(JSON.stringify(env));

      if (isprim(f)) {
        
        if (args.length == 1) {
          return primapl_uni(f, args[0], env);
        } else {
          return primapl(f, args[0], args[1], env);
        }
      } else if (f == "prev" && args != ["obj"]) {
        console.log("WOAH  2");
        var [v, env_] = interpret({"head" : "call", "args" : ["prev" + args[0][0].toUpperCase() + args[0].slice(1), ["state"]]}, env);
        return [JSON.parse(JSON.stringify(v)), env_]
      } else if (islib(f)) {
        console.log("here?");
        return interpret_lib(f, args, env);
      } else if (isjslib(f)) {
        return interpret_js_lib(f, args, env);
      } else if (f in env.state.object_types) {
        return interpret_object_call(f, args, env);
      } else {
        console.log("WOAH");
        if (Array.isArray(args)) {
          return interpret_call(f, args, env);
        } else {
          return interpret_call(f, [args], env);
        }
      }
    } else if (aex.head == "field") {
      return interpret_field(aex.args[0], aex.args[1], env);
    } else if (aex.head == "object") {
      return interpret_object(aex.args, env);
    } else if (aex.head == "on") {
      return interpret_on(aex.args, env);
    } else {
      throw new Error(`Invalid AExpr Head: ${aex.head}`);
    }
  } else if (typeof(aex) == "string") {
    if (aex == "true") {
      return [true, env];
    } else if (aex == "false") {
      return [false, env];
    } else if (aex == "left") {
      return [env.left, env];
    } else if (aex == "right") { 
      return [env.right, env];
    } else if (aex == "up") {
      return [env.up, env];
    } else if (aex == "down") {
      return [env.down, env];
    } else if (aex == "click") {
      return [env.click, env];
    } else if (aex == "clicked") {
      return interpret({"head" : "call", "args" : ["occurred", ["click"]]}, env)
    } else if (aex in env.state.object_types) {
      return [aex, env]
    } else if (aex == "state") {
      return [env.state, env]
    } else if (aex in env.current_var_values) {
      return [env.current_var_values[aex], env]
    } else {
      throw new Error(`Could not interpret ${x}`);
    }
  } else {
    if (aex != null && typeof(aex) == "object") {
      return [aex.valueOf(), env];
    } else {
      return [aex, env];
    }
  }
}

function interpret_list(args, env) {
  console.log("INTERPRET_LIST");
  console.log(args);
  var new_list = [];
  for (arg of args) {
    var [new_arg, env] = interpret(arg, env);
    new_list.push(new_arg);
  }
  console.log("new_list");
  console.log(new_list);
  return [new_list, env];
}

function interpret_lib(f, args, env) {
  console.log("interpret_lib");
  console.log(f);
  console.log(args);
  console.log(JSON.stringify(env));
  var new_args = [];
  for (arg of args) {
    [new_arg, env] = interpret(arg, env);
    new_args.push(new_arg);
  }
  console.log("new_args");
  console.log(new_args);
  return libapl(f, new_args, env);
} 

function interpret_js_lib(f, args, env) {
  return jslibapl(f, args, env);
}

function interpret_field(x, f, env) {
  var [val, env2] = interpret(x, env);
  if (isobject(val)) {
    if (["id", "origin", "type", "alive", "changed", "render"].includes(f)) {
      return [val[f], env2];
    } else {
      return [val.custom_fields[f], env2];
    }
  } else {
    return [val[f], env2];
  }
}

function interpret_let(args, env) {
  console.log("interpret_let");
  console.log(args);
  console.log(JSON.stringify(env));
  var env2 = JSON.parse(JSON.stringify(env));
  if (args.length > 0 ) {
    for (arg of args.slice(0, args.length - 1)) {
      var [v2, env2] = interpret(arg, env2);
    }

    if (isaexpr(args[args.length - 1])) {
      if (args[args.length - 1].head == "assign") {
        console.log("woo");
        console.log(args[args.length - 1]);
        var [v2, env2] = interpret(args[args.length - 1], env2);
        return [{"head" : "let", "args" : args}, env2];
      } else {
        var [v2, env2] = interpret(args[args.length - 1], env2);
        return [v2, env];
      }
    } else {
      return [interpret(args[args.length - 1], env2)[0], env];
    }

  } else {
    return [{"head" : "let", "args" : args}, env2]
  }
}

function interpret_call(f, params, env) {
  console.log("INTERPRET_CALL")
  console.log(f)
  console.log(params)
  console.log(env)
  var [func, env] = interpret(f, env);
  var func_args = func[0];
  var func_body = func[1];

  console.log("func_args");
  console.log(func_args);

  console.log("func_body");
  console.log(func_body);

  // construct environment 
  var old_current_var_values = JSON.parse(JSON.stringify(env.current_var_values));
  var env2 = env; // JSON.parse(JSON.stringify(env))
  if (isaexpr(func_args)) {
    for (let i = 0; i < func_args.args.length; i++) {
      var param_name = func_args.args[i];
      var [param_val, env2] = interpret(params[0], env2);
      env2.current_var_values[param_name] = param_val;
    }
  } else if (typeof(func_args) == "string") {
    var param_name = func_args; 
    [param_val, env2] = interpret(params[0], env2);
    env2.current_var_values[param_name] = param_val;
  } else {
    throw new Error(`Could not interpret ${func_args}`);
  }

  var [v, env2] = interpret(func_body, env2);

  // return value and original environment, except with state updated
  // env.objectsCreated = env2.state.objectsCreated;
  env.current_var_values = old_current_var_values;
  return [v, env];
}

function interpret_object_call(f, args, env) {
  console.log("INTERPRET_OBJECT_CALL");
  console.log(f);
  console.log(JSON.stringify(args));
  console.log(JSON.stringify(env));
  env.state.objectsCreated = env.state.objectsCreated + 1;

  var [origin, env] = interpret(args[args.length - 1], env);

  console.log("ORIGIN");
  console.log(origin);
  // object_repr = (origin=origin, type=f, alive=true, id=Γ.state.objectsCreated)

  var old_current_var_values = JSON.parse(JSON.stringify(env.current_var_values));
  var env2 = env;
  var fields = env2.state.object_types[f].fields;
  var field_values = {}
  for (let i = 0; i < fields.length; i++) {
    var field_name = fields[i].args[0];
    var [field_value, env2] = interpret(args[i], env2);
    field_values[field_name] = field_value;
    // object_repr = update(object_repr, field_name, field_value)
    env2.current_var_values[field_name] = field_value;

  }

  if (fields.length == 0) { 
    var object_repr = {"id" : env.state.objectsCreated, "origin" : origin, "type" : f, "alive" : true, "custom_fields" : field_values, "render" : null} ;
  } else {
    var [render, env2] = interpret(env.state.object_types[f].render, env2);
    var render = Array.isArray(render) ? render : [render];
    var object_repr = {"id" : env.state.objectsCreated, "origin" : origin, "type" : f, "alive" : true, "custom_fields" : field_values, "render" : render};
  }
  env.current_var_values = old_current_var_values;
  return [object_repr, env];
}

function interpret_init_next(var_name, var_val, env) {
  var init_func = var_val.args[0];
  var next_func = var_val.args[1];
  console.log(JSON.stringify(env));
  var env2 = JSON.parse(JSON.stringify(env));
  if (!(var_name in env2.current_var_values)) { // variable not initialized; use init clause
    var [var_val, env2] = interpret(init_func, env2);

    console.log("var_val");
    console.log(var_val);

    env2.current_var_values[var_name] = var_val;

    env2.state.histories[var_name] = {};

    var [x, env2] = interpret({"head" : "assign", "args": ["prev" + var_name[0].toUpperCase() + var_name.slice(1), parseau(`(fn (state) (get (get (.. state histories) ${var_name} -1) (- (.. state time) 1) ${var_name}))`)]}, env2); 
  } else if (env.state.time > 0) { // variable initialized
    var [default_val, env] = interpret(next_func, env);
    env2.current_var_values[var_name] = default_val;
  }
  return [{"head" : "assign", "args" : [var_name, var_val]}, env2];
}

function interpret_object(args, env) {
  console.log("INTERPRET_OBJECT");
  console.log(JSON.stringify(args));
  console.log(JSON.stringify(env));
  var object_name = args[0];
  var object_fields = args.slice(1,-1);
  var object_render = args[args.length - 1];

  if (object_fields.length == 0) {
    var [render, x] = interpret(object_render, env);
    if (!Array.isArray(render)) {
      var render = [render];
    }
    var object_tuple = ObjectType(render, object_fields);
  } else {
    var object_tuple = ObjectType(object_render, object_fields);
  }
  env.state.object_types[object_name] = object_tuple;
  return [{"head" : "object", "args" : args}, env];
}

function interpret_on(args, env) {
  var event = args[0]
  var update_ = args[1]

  console.log("interpret_on");
  console.log(event);
  console.log(update_);
  console.log(JSON.stringify(env));

  if (env.state.time > 0) {
    var [e, env] = interpret(event, env);
    if (e) {
      var [x, env] = interpret(update_, env);
    }
  }
  return [{"head" : "on", "args" : args}, env];
}

function interpret_updateObj(args, env) {
  // # # println("MADE IT!")
  console.log("interpret_updateObj");
  console.log(args);
  console.log(env);
  var env2 = JSON.parse(JSON.stringify(env));
  var numFunctionArgs = args.map(arg => Array.isArray(arg) && (arg.length == 2) && (isaexpr(arg[0]) || typeof(arg[0]) == "string") && (isaexpr(arg[1]) || typeof(arg[1]) == "string")).filter(x => x == true).length;
  
  console.log("numFunctionArgs");
  console.log(numFunctionArgs);
  if (numFunctionArgs == 1) {
    var [list, env2] = interpret(args[0], env2);
    var map_func = args[1];

    // # # # # # @show list 
    // # # # # # @show map_func

    var new_list = []
    for (let item of list) { 
      // # # # # # # println("PRE=PLS WORK")
      // # # # # # # @showΓ2.state.objectsCreated      
      var [new_item, env2] = interpret({"head" : "call", "args" : [map_func, item]}, env2);
      // # # # # # # println("PLS WORK")
      // # # # # # # @showΓ2.state.objectsCreated
      new_list.push(new_item);
    }
    return [new_list, env2];
   } else if (numFunctionArgs == 2) {
    var [list, env2] = interpret(args[0], env2);
    var map_func = args[1];
    var filter_func = args[2];

    // # # @show list 
    // # # @show map_func


    var new_list = [];
    for (let item of list) { 
      var [pred, env2] = interpret({"head" : "call", "args" : [filter_func, item]}, env2);
      if (pred == true) { 
        // # # println("PRED TRUE!")
        // # # @show item 
        var [new_item, env2] = interpret({"head" : "call", "args" : [map_func, item]}, env2);
        new_list.push(new_item);
      } else {
        // # # println("PRED FALSE!")
        // # # @show item 
        new_list.push(item);
      }
    }
    // # # @show new_list 
    return [new_list, env2];
  } else if (numFunctionArgs == 0) {
    var obj = args[0];
    var field_string = JSON.stringify(args[1]).slice(8, -2);
    var new_value = args[2];

    var new_obj = JSON.parse(JSON.stringify(obj)); // TODO
    obj.custom_fields[field_string] = new_value;

    // # update render
    var object_type = env.state.object_types[obj.type];
    
    var old_current_var_values = JSON.parse(JSON.stringify(env.current_var_values));
    var env3 = JSON.parse(JSON.stringify(env2));
    var fields = object_type.fields;
    for (let i = 0; i < fields.length; i++) {
      var field_name = fields[i].args[0];
      var field_value = new_obj.custom_fields[field_name];
      env3.current_var_values[field_name] = field_value;
    }

    if (fields.length != 0) { 
      var [render, env3] = interpret(env.state.object_types[obj.type].render, env3);
      var render = Array.isArray(render) ? render : [render];
      new_obj["render"] = render;
    }
    env2.current_var_values = old_current_var_values;
    return [new_obj, env2];
    // # Γ2 = update(Γ2, :state, update(Γ2.state, :objectsCreated, Γ2.state.objectsCreated + 1))
  } else {
    throw new Error("Could not interpret updateObj");
  }
}

function interpret_removeObj(args, env) {
  console.log("interpret_removeObj");
  console.log(args);
  console.log(JSON.stringify(env));
  var [list, env] = interpret(args[0], env);
  var func = args[1];
  var new_list = [];
  for (let item of list) {
    var [pred, env] = interpret({"head" : "call", "args" : [func, item]}, env);
    console.log("pred");
    console.log(pred);
    if (!pred) {
      new_list.push(item);
    } else {
      var new_item = update(item, "alive", false);
      new_list.push(new_item);
    }
  }
  return [new_list, env];
}

function interpret_js_map(args, env) {
  console.log("INTERPRET_JS_MAP");
  console.log(args);
  console.log(env);
  var new_list = [];
  var map_func = args[0];
  var [list, env] = interpret(args[1], env);
  for (arg of list) { 
    var [new_arg, env] = interpret({"head" : "call", "args" : [map_func, arg]}, env)
    new_list.push(new_arg);
  }
  return [new_list, env]
}

function interpret_js_filter(args, env) {
  var new_list = [];
  var filter_func = args[0];
  var [list, env] = interpret(args[1], env);
  for (arg of list) {
    var [v, env] = interpret({"head" : "call", "args" : [filter_func, arg]}, env)
    if (v == true) { 
      new_list.push(interpret(arg, env)[0])
    }
  }
  return [new_list, env];
}

function interpret_js_count(args, env) {
  var new_list = [];
  var filter_func = args[0];
  var [list, env] = interpret(args[1], env);
  for (arg of list) {
    var [v, env] = interpret({"head" : "call", "args" : [filter_func, arg]}, env)
    if (v == true) { 
      new_list.push(interpret(arg, env)[0])
    }
  }
  return [new_list.length, env]
}