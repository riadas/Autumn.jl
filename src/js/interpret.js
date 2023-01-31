import { parseau } from "./sexpr.js"
import { interpret } from "./interpretutils.js"

function interpret_program(aex, env) {
  if (aex.head != "program") {
    throw new Error("Must be a program aex");
  }

  for (line of aex.args) {
    [_, env] = interpret(line, env);
  }
  return [aex, env]
}

function start(aex) {
  if (aex.head != "program") {
    throw new Error("Must be a program aex");
  }

  env = {"left" : false, 
         "right" : false, 
         "up" : false, 
         "down" : false, 
         "click" : null, 
         "current_var_values" : {},
         "lifted" : {},
         "on_clauses" : {}, 
         "state" : {"time" : 0, 
                    "objectsCreated" : 0, 
                    "scene" : {"objects" : [], 
                               "background" : "white",
                              },
                    "object_types" : {}, 
                    "histories" : {}, 
                  }
  }

  lines = aex.args 

  grid_params_and_object_type_lines = lines.filter(l => !(l.head in ["assign", "on"]))
  initnext_lines = lines.filter(l => l.head == "assign" && (typeof(l.args[1]) == "object" && l.args[1].head == "initnext"))
  lifted_lines = lines.filter(l => l.head == "assign" && (typeof(l.args[1]) != "object" || l.args[1].head != "initnext"))
  on_clause_lines = lines.filter(l => l.head == "on")

  reordered_lines = grid_params_and_object_type_lines.concat(initnext_lines).concat(on_clause_lines).concat(lifted_lines)

  for (line of lifted_lines) {
    var_name = line.args[0] 
    // construct history variable in state
    env.state.histories[var_name] = {}

    // construct prev function 
    [_, env] = interpret({"head" : "assign", "args" : ["prev" + var_name[0].toUpperCase() + var_name.slice(1), parseau(`(fn () (get (.. (.. state histories) ${var_name}) (- (.. state time) 1) ${var_name}))`)]}, env) 
  }

  // add background to scene 
  background_assignments = lifted_lines.filter(l => l.args[0] == "background")
  background = background_assignments != [] ? background_assignments[-1].args[1] : "#ffffff00"
  env.state.scene.background = background

  // initialize lifted variables
  // env = update(env, :lifted, empty_env()) 
  for (line of lifted_lines) {
    var_name = line.args[1]
    env.lifted[var_name] = line.args[1] 
    if (var_name in ["GRID_SIZE", "background"]) {
      env.current_var_values[var_name] = interpret(line.args[1], env)[0]
    } 
  }

  new_aex = AExpr("program", reordered_lines) // try interpreting the init_next's before on for the first time step (init)
  [aex_, env_] = interpret_program(new_aex, env)

  // update state (time, histories, scene)
  env_ = update_state(env_)

  return [aex_, env_]
}

function step(aex, env, user_events) {
  // update env with user event 
  for (user_event in user_events) {
    if (user_events[user_event] != null) {
      env = update(env, user_event, user_events[user_event])
    }
  }

  [aex_, env_] = interpret_program(aex, env)

  // update state (time, histories, scene) + reset user_event
  env_ = update_state(env_)
  
  return env_
}

function update_state(env) {

}

function interpret_over_time(aex, iters, user_events=[]) {

}

function interpret_over_time_variable(aex, var_name, iters, user_events=[]) {

}

function interpret_over_time_observations(aex, iters, user_events=[]) {

}