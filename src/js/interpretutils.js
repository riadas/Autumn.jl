// import { parseau } from "./sexpr.js"
// import * as AutumnStandardLibrary from "./autumnstdlib.js"

const { parseau } = require("./sexpr.js");
const { Cell, Position, moveLeft, ObjectType } = require("./autumnstdlib.js");

module.exports = { interpret, update };

function update(env, x, v) {
  new_env = JSON.parse(JSON.stringify(env))
  new_env[x] = v;
  return new_env;
}

function isaexpr(aex) {
  return (typeof(aex) == "object" && aex.head != undefined)
}

function isobject(aex) {
  return (typeof(aex) == "object" && aex.id != undefined)
}

prim_to_func = {"+" : function(x, y) {return x + y;},
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
  return [prim_to_func[f](x), env]
}

function primapl(f, x, y, env) {
  return [prim_to_func[f](x, y), env]
}

lib_to_func = {"moveLeft" : moveLeft,
               "Position" : Position,
               "Cell" : Cell,
              }

function islib(f) {
  return (f in lib_to_func);
}

function libapl(f, args, env) {
  if (f == "clicked" && args.length == 0) {
    return interpret(f, env);
  } else if (f == "clicked") {
    return [lib_to_func[f]([interpret("click", env)[0], ...args], env.state), env]
  } else {
    has_function_arg = false; 
    for (arg of args) {
      if (Array.isArray(arg) && (arg.length == 2) && (isaexpr(args[0]) || typeof(args[0]) == "string") && (isaexpr(args[1] || typeof(args[1]) == "string"))) {
        has_function_arg = false;
      }
    }

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

function julialibapl(f, args, env) {
  if (f == "get") {
    console.log("GET ME")
    console.log(f);
    console.log(args);
    console.log(env);
    var [dict, env] = interpret(args[0], env);
    var key = args[1];
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
    [l, env] = interpret(args[0], env);
    return [l[0], env];
  } else if (f == "last") {
    [l, env] = interpret(args[0], env);
    return [l[l.length - 1], env];
  } else if (f == "in") {
    elt, env = interpret(args[0], env);
    l, env = interpret(args[1], env);
    return [l.includes(elt), env];
  } else if (f == "intersect") {
    l1, env = interpret(args[0], env);
    l2, env = interpret(args[1], env);
    return [l1.filter(elt => l2.includes(elt)), env];
  } else if (f == "length") {
    l, env = interpret(args[0], env);
    return [l.length, env];
  } else if (f == "sign") {
    v, env = interpret(args[0], env);
    return [v >= 0 ? 1 : -1, env];
  } else if (f == "vcat") {
    ls = args.map(l => interpret(l, env)[0]);
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
      [c, t, e] = aex.args; 
      v, env2 = interpret(c, env);
      if (v) {
        return interpret(t, env2);
      } else {
        return interpret(e, env2);
      }
    } else if (aex.head == "assign") {
      [x, v] = aex.args 
      if (v.head == "initnext") {
        return interpret_init_next(x, v, env);
      } else if (isaexpr(v) || typeof(v) == "string") {
        [v2, env] = interpret(v, env);
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
      f = aex.args[0];
      args = aex.args[1];

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
        return interpret({"head" : "call", "args" : ["prev" + args[0][0].toUpperCase() + args[0].slice(1), ["state"]]}, env);
      } else if (islib(f)) {
        return interpret_lib(f, args, env);
      } else if (isjslib(f)) {
        return interpret_js_lib(f, args, env);
      } else if (f in env.state.object_types) {
        return interpret_object_call(f, args, env);
      } else {
        console.log("WOAH");
        return interpret_call(f, args, env);
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
    if (typeof(aex) == "object") {
      return [aex.valueOf(), env];
    } else {
      return [aex, env];
    }
  }
}

function interpret_list(args, env) {
  new_list = [];
  for (arg of args) {
    [new_arg, env] = interpret(arg, env);
    new_list.push(new_arg);
  }
  return [new_list, env];
}

function interpret_lib(f, args, env) {
  new_args = [];
  for (arg of args) {
    [new_arg, env] = interpret(arg, env);
    new_args.push(new_arg);
  }
  return libapl(f, new_args, env);
} 

function interpret_js_lib(f, args, env) {
  return julialibapl(f, args, env);
}

function interpret_field(x, f, env) {
  [val, env2] = interpret(x, env);
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
  env2 = JSON.parse(JSON.stringify(env));
  if (args.length > 0 ) {
    for (arg of args.slice(1)) {
      v2, env2 = interpret(arg, env2);
    }

    if (isaexpr(args[args.length - 1])) {
      if (args.head == "assign") {
        v2, env2 = interpret(args[args.length - 1], env2);
        return [{"head" : "let", "args" : args}, env2];
      } else {
        v2, env2 = interpret(args[args.length - 1], env2);
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
  func_args = func[0];
  func_body = func[1];

  // construct environment 
  old_current_var_values = JSON.parse(JSON.stringify(env.current_var_values));
  env2 = JSON.parse(JSON.stringify(env))
  if (isaexpr(func_args)) {
    for (i = 0; i < func_args.args.length; i++) {
      param_name = func_args.args[i];
      [param_val, env2] = interpret(params[0], env2);
      env2.current_var_values[param_name] = param_val;
    }
  } else if (typeof(func_args) == "string") {
    param_name = func_args; 
    [param_val, env2] = interpret(params[0], env2);
    env2.current_var_values[param_name] = param_val;
  } else {
    throw new Error(`Could not interpret ${func_args}`);
  }

  [v, env2] = interpret(func_body, env2);

  // return value and original environment, except with state updated
  env = update(env, "state", update(env.state, "objectsCreated", env2.state.objectsCreated));
  env.current_var_values = old_current_var_values;
  return [v, env];
}

function interpret_object_call(f, args, env) {
  console.log("INTERPRET_OBJECT_CALL");
  console.log(f);
  console.log(JSON.stringify(args));
  console.log(JSON.stringify(env));
  new_state = update(env.state, "objectsCreated", env.state.objectsCreated + 1);
  env = update(env, "state", new_state);

  var [origin, env] = interpret(args[args.length - 1], env);

  console.log("ORIGIN");
  console.log(origin);
  // object_repr = (origin=origin, type=f, alive=true, id=Γ.state.objectsCreated)

  old_current_var_values = JSON.parse(JSON.stringify(env.current_var_values));
  env2 = env;
  fields = env2.state.object_types[f].fields;
  field_values = {}
  for (i = 0; i < fields.length; i++) {
    field_name = fields[i].args[0];
    [field_value, env2] = interpret(args[i], env2);
    field_values[field_name] = field_value;
    // object_repr = update(object_repr, field_name, field_value)
    env2.current_var_values[field_name] = field_value

  }

  if (fields.length == 0) { 
    object_repr = {"id" : env.state.objectsCreated, "origin" : origin, "type" : f, "alive" : true, "custom_fields" : field_values, "render" : null} 
  } else {
    render, env2 = interpret(env.state.object_types[f].render, env2)
    render = Array.isArray(render) ? render : [render]
    object_repr = {"id" : env.state.objectsCreated, "origin" : origin, "type" : f, "alive" : true, "custom_fields" : field_values, "render" : render}
  }
  env.current_var_values = old_current_var_values
  return [object_repr, env];
}

function interpret_init_next(var_name, var_val, env) {
  init_func = var_val.args[0];
  next_func = var_val.args[1];
  console.log(JSON.stringify(env));
  env2 = JSON.parse(JSON.stringify(env));
  if (!(var_name in env2.current_var_values)) { // variable not initialized; use init clause
    [var_val, env2] = interpret(init_func, env2);

    console.log("var_val");
    console.log(var_val);

    env2.current_var_values[var_name] = var_val;

    env2.state.histories[var_name] = {};

    var [_, env2] = interpret({"head" : "assign", "args": ["prev" + var_name[0].toUpperCase() + var_name.slice(1), parseau(`(fn (state) (get (get (.. state histories) ${var_name} -1) (- (.. state time) 1) ${var_name}))`)]}, env2); 
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
  object_name = args[0];
  object_fields = args.slice(1,-1);
  object_render = args[args.length - 1];

  if (object_fields.length == 0) {
    [render, _] = interpret(object_render, env);
    if (!Array.isArray(render)) {
      render = [render];
    }
    object_tuple = ObjectType(render, object_fields);
  } else {
    object_tuple = ObjectType(object_render, object_fields);
  }
  env.state.object_types[object_name] = object_tuple;
  return [{"head" : "object", "args" : args}, env];
}

function interpret_on(args, env) {
  event = args[1]
  update_ = args[2]

  [e, env] = interpret(event, env);
  if (e) {
    [_, env2] = interpret(update_, env);
  }
  return [{"head" : "on", "args" : args}, env2];
}

function interpret_updateObj(args, env) {
  // # # println("MADE IT!")
  env2 = JSON.parse(JSON.stringify(env));
  numFunctionArgs = args.map(arg => Array.isArray(arg) && (arg.length == 2) && (isaexpr(arg[0]) || typeof(arg[0]) == "string") && (isaexpr(arg[1]) || typeof(arg[1]) == "string")).filter(x => x == true).length;
  if (numFunctionArgs == 1) {
    list, env2 = interpret(args[0], env2);
    map_func = args[1];

    // # # # # # @showlist 
    // # # # # # @showmap_func

    new_list = []
    for (item of list) { 
      // # # # # # # println("PRE=PLS WORK")
      // # # # # # # @showΓ2.state.objectsCreated      
      new_item, env2 = interpret({"head" : "call", "args" : [map_func, item]}, env2);
      // # # # # # # println("PLS WORK")
      // # # # # # # @showΓ2.state.objectsCreated
      new_list.push(new_item);
    }
    return [new_list, env2];
   } else if (numFunctionArgs == 2) {
    list, env2 = interpret(args[0], env2);
    map_func = args[1];
    filter_func = args[2];

    // # # @show list 
    // # # @show map_func


    new_list = [];
    for (item of list) { 
      [pred, env2] = interpret({"head" : "call", "args" : [filter_func, item]}, env2);
      if (pred == true) { 
        // # # println("PRED TRUE!")
        // # # @show item 
        [new_item, env2] = interpret({"head" : "call", "args" : [map_func, item]}, env2);
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
    obj = args[0];
    field_string = args[1];
    new_value = args[2];
    new_obj = update(obj, field_string, new_value);

    // # update render
    object_type = env.state.object_types[obj.type];
    
    old_current_var_values = copy(env.current_var_values);
    env3 = JSON.parse(JSON.stringify(env2));
    fields = object_type.fields;
    for (i = 0; i < fields.length; i++) {
      field_name = fields[i].args[0];
      field_value = new_obj.custom_fields[field_name];
      env3.current_var_values[field_name] = field_value;
    }

    if (fields.length != 0) { 
      render, env3 = interpret(env.state.object_types[obj.type].render, env3);
      render = Array.isArray(render) ? render : [render];
      new_obj = update(new_obj, "render", render);
    }
    env2.current_var_values = old_current_var_values;
    return [new_obj, env2];
    // # Γ2 = update(Γ2, :state, update(Γ2.state, :objectsCreated, Γ2.state.objectsCreated + 1))
  } else {
    throw new Error("Could not interpret updateObj");
  }
}

function interpret_removeObj(args, env) {
  list, env = interpret(args[0], env);
  func = args[1];
  new_list = [];
  for (item of list) {
    pred, env = interpret({call, func, item}, env);
    if (!pred) {
      new_list.push(item);
    } else {
      new_item = update(item, "alive", false);
      new_list.push(new_item);
    }
  }
  return [new_list, env];
}

function interpret_js_map(args, env) {
  new_list = [];
  map_func = args[0];
  list, env = interpret(args[1], env);
  for (arg of list) { 
    new_arg, env = interpret({"head" : "call", "args" : [map_func, arg]}, env)
    new_list.push(new_arg);
  }
  return [new_list, env]
}

function interpret_js_filter(args, env) {
  new_list = [];
  filter_func = args[0];
  list, env = interpret(args[1], env);
  for (arg of list) {
    v, env = interpret({"head" : "call", "args" : [filter_func, arg]}, env)
    if (v == true) { 
      new_list.push(interpret(arg, env)[0])
    }
  }
  return [new_list, env];
}

function interpret_js_count(args, env) {
  new_list = [];
  filter_func = args[0];
  list, env = interpret(args[1], env);
  for (arg of list) {
    v, env = interpret({"head" : "call", "args" : [filter_func, arg]}, env)
    if (v == true) { 
      new_list.push(interpret(arg, env)[0])
    }
  }
  return [new_list.length, env]
}