// import { parseau } from "./sexpr.js"
// import { interpret } from "./interpretutils.js"

const { parseau } = require("./sexpr.js");
const { interpret, update } = require("./interpretutils.js");


function interpret_program(aex, env) {
  if (aex.head != "program") {
    throw new Error("Must be a program aex");
  }

  for (line of aex.args) {
    console.log("YOOOOOOOOO")
    console.log(line.head)
    console.log(env);
    console.log(JSON.stringify(env));
    var [_, env] = interpret(line, env);
  }
  return [aex, env]
}

function start(aex) {
  if (aex.head != "program") {
    throw new Error("Must be a program aex");
  }

  var env = {"left" : false, 
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

  var lines = aex.args 

  var grid_params_and_object_type_lines = lines.filter(l => !(["assign", "on"].includes(l.head)))
  var initnext_lines = lines.filter(l => l.head == "assign" && (typeof(l.args[1]) == "object" && l.args[1].head == "initnext"))
  var lifted_lines = lines.filter(l => l.head == "assign" && (typeof(l.args[1]) != "object" || l.args[1].head != "initnext"))
  var on_clause_lines = lines.filter(l => l.head == "on")

  var reordered_lines = grid_params_and_object_type_lines.concat(initnext_lines).concat(on_clause_lines).concat(lifted_lines)

  for (line of lifted_lines) {
    console.log("HUHHHHHHHHHHHH")
    console.log(line)
    var var_name = line.args[0] 
    // construct history variable in state
    env.state.histories[var_name] = {};

    // construct prev function 
    var [wtf, env_] = interpret({"head" : "assign", "args" : ["prev" + var_name[0].toUpperCase() + var_name.slice(1), parseau(`(fn () (get (.. (.. state histories) ${var_name}) (- (.. state time) 1) ${var_name}))`)]}, env); 
    var env = env_;
  }

  // add background to scene 
  var background_assignments = lifted_lines.filter(l => l.args[0] == "background")
  var background = background_assignments.length != 0 ? background_assignments[-1].args[1] : "#ffffff00"
  env.state.scene.background = background

  // initialize lifted variables
  // env = update(env, :lifted, empty_env()) 
  for (line of lifted_lines) {
    var var_name = line.args[0]
    env.lifted[var_name] = line.args[1] 
    if (["GRID_SIZE", "background"].includes(var_name)) {
      env.current_var_values[var_name] = interpret(line.args[1], env)[0]
    } 
  }

  var new_aex = {"head" : "program", "args" : reordered_lines} // try interpreting the init_next's before on for the first time step (init)
  var [aex_, env_] = interpret_program(new_aex, env)

  // update state (time, histories, scene)
  var env_ = update_state(env_)

  return [aex_, env_]
}

function step(aex, env, user_events) {
  // update env with user event 
  for (user_event in user_events) {
    if (user_events[user_event] != null) {
      var env = update(env, user_event, user_events[user_event])
    }
  }

  var [aex_, env_] = interpret_program(aex, env)

  // update state (time, histories, scene) + reset user_event
  var env_ = update_state(env_)
  
  return env_
}

function update_state(env_) {
  // reset user events 
  for (user_event of ["left", "right", "up", "down"]) {
    var env_ = update(env_, user_event, false)
  }
  var env_ = update(env_, "click", null)

  // add updated variable values to history
  for (key in env_.state.histories) {
    var val = env_.current_var_values[key];
    if (Array.isArray(val)) { 
      if (val.length > 0 && val[0].id != undefined) {
        val = env_.current_var_values[key].filter(obj => obj.alive);
      }
    }   
    env_.state.histories[key][env_.state.time] = JSON.parse(JSON.stringify(val))
  
    // delete earlier times stored in history, since we only use prev up to 1 level back
    if (env_.state.time > 0) {
      // delete env_.state.histories[key][(env_.state.time - 1).toString()];
    }

  }

  // update lifted variables 
  for (var_name in env_.lifted) {
    env_.current_var_values[var_name] = interpret(env_.lifted[var_name], env_)[0]
  }

  // update scene.objects 
  var new_scene_objects = []
  for (key in env_.current_var_values) {
    if (typeof(env_.current_var_values[key]) == "object" && env_.current_var_values[key].id != undefined || (Array.isArray(env_.current_var_values[key]) && ((env_.current_var_values[key].length) > 0) && typeof(env_.current_var_values[key][0]) == "object" && env_.current_var_values[key][0].id != undefined)) {
      var object_val = env_.current_var_values[key]
      if (Array.isArray(object_val)) { 
        new_scene_objects.push(...object_val)
      } else {
        new_scene_objects.push(object_val)
      }
    }
  }
  
  env_.state.scene.objects = new_scene_objects

  // update time 
  var new_state = update(env_.state, "time", env_.state.time + 1)
  var env_ = update(env_, "state", new_state)
  return env_
}

function interpret_over_time(aex, iters, user_events=[]) {
  var [new_aex, env_] = start(aex)
  if (user_events.length == 0) {
    for (i = 0; i < iters; i++) {
      // @show i
      var env_ = step(new_aex, env_)
    }
  } else {
    for (i = 0; i < iters; i++) {
      // @show i
      var env_ = step(new_aex, env_, user_events[i])
    }
  }
  return env_
}

function interpret_over_time_variable(aex, var_name, iters, user_events=[]) {

}

function interpret_over_time_observations(aex, iters, user_events=[]) {

}

// TODO: check null usage/equality checks, check 1-index vs. 0-index, etc.


// tests (TODO: move to test folder)
function test_particle() {
  var program_str = `(program
                       (= GRID_SIZE 16)
                       (object Particle (Cell 0 0 "blue"))
                       (: particle Particle)
                       (= particle (initnext (Particle (Position 8 8)) (moveLeft (prev particle))))
                       (on right (= particle (moveRight (prev particle))))
                     )`
  var aex = parseau(program_str);

  var [aex_, env_] = start(aex);

  for (let i = 0; i < 5; i++) {
    if (i % 3 == 1) {
      var user_event = {"left" : false, "right" : true, "up" : false, "down" : false, "click" : null}
    } else {
      var user_event = {"left" : false, "right" : false, "up" : false, "down" : false, "click" : null}
    }
    // console.log(i);
    env_ = step(aex_, env_, user_event);
  }
  // console.log(env_.state.histories.particle);
  return [`0`, `1`, `2`, `3`, `4`, `5`].map(i => env_.state.histories.particle[i].origin);
}

function test_particle_list() {
  var program_str = `(program
                       (= GRID_SIZE 16)
                       (object Particle (Cell 0 0 "blue"))
                       (: particles (List Particle))
                       (= particles (initnext (list (Particle (Position 8 8)) (Particle (Position 10 10))) (updateObj (prev particles) (--> obj (moveLeft obj)))))
                       (on right (let ((= particles (updateObj (prev particles) (--> obj (moveRight obj)))))))
                     )`
  var aex = parseau(program_str);

  var [aex_, env_] = start(aex);

  for (let i = 0; i < 5; i++) {
    if (i % 3 == 1) {
      var user_event = {"left" : false, "right" : true, "up" : false, "down" : false, "click" : null}
    } else {
      var user_event = {"left" : false, "right" : false, "up" : false, "down" : false, "click" : null}
    }
    // console.log(i);
    env_ = step(aex_, env_, user_event);
  }
  // console.log(env_.state.histories.particle);
  return [`0`, `1`, `2`, `3`, `4`, `5`].map(i => [env_.state.histories.particles[i][0].origin, env_.state.histories.particles[i][1].origin]);
}

function test_particle_actual() {
  var program_str = `(program
                      (= GRID_SIZE 16)
                      
                      (object Particle (Cell 0 0 "blue"))
                      
                      (: particles (List Particle))
                      (= particles 
                        (initnext (list) 
                                  (updateObj (prev particles) (--> obj (uniformChoice (list (moveLeft obj) (moveRight obj) (moveDown obj) (moveUp obj)) ))))) 
                      
                      (on clicked (= particles (addObj particles (Particle (Position (.. click x) (.. click y))))))
                      )`
  var aex = parseau(program_str);

  var [aex_, env_] = start(aex);

  for (let i = 0; i < 5; i++) {
    if (i % 3 == 1) {
      var user_event = {"left" : false, "right" : false, "up" : false, "down" : false, "click" : {"x" : Math.floor(15 * Math.random()), "y" : Math.floor(15 * Math.random())}}
    } else {
      var user_event = {"left" : false, "right" : false, "up" : false, "down" : false, "click" : null}
    }
    // console.log(i);
    env_ = step(aex_, env_, user_event);
  }
  // console.log(env_.state.histories.particle);
  return [`0`, `1`, `2`, `3`, `4`, `5`].map(i => [env_.state.histories.particles[i].map(o => [o.origin.x, o.origin.y])]);
}

function test_ants_actual() {
  var program_str = `(program
                      (= GRID_SIZE 16)
                      
                      (object Ant (Cell 0 0 "gray"))
                      (object Food (Cell 0 0 "red"))
                      
                      (: ants (List Ant))
                      (= ants (initnext (list (Ant (Position 5 5)) (Ant (Position 1 14))) (prev ants)))
                      
                      (: foods (List Food))
                      (= foods (initnext (list) (prev foods)))
                      
                      (on true (= ants (updateObj (prev ants) (--> obj (move obj (unitVector obj (closest obj Food)))))))
                      (on true (= foods (updateObj (prev foods) (--> obj (if (intersects obj (prev ants))
                                                       then (removeObj obj)
                                                       else obj)))))

                      (on clicked (= foods (addObj foods (map Food (randomPositions GRID_SIZE 2)))))

                      )`
  var aex = parseau(program_str);

  var [aex_, env_] = start(aex);

  for (let i = 0; i < 60; i++) {
    if (i == 1) {
      var user_event = {"left" : false, "right" : false, "up" : false, "down" : false, "click" : {"x" : Math.floor(15 * Math.random()), "y" : Math.floor(15 * Math.random())}}
    } else {
      var user_event = {"left" : false, "right" : false, "up" : false, "down" : false, "click" : null}
    }
    // console.log(i);
    env_ = step(aex_, env_, user_event);
  }
  // console.log(env_.state.histories.particle);
  return env_;
  // return [`0`, `1`, `2`, `3`, `4`, `5`].map(i => [env_.state.histories.particles[i].map(o => [o.origin.x, o.origin.y])]);
}

function test_lights_actual() {
  var program_str = `(program
                      (= GRID_SIZE 10)
                      
                      (object Light (: on Bool) (Cell 0 0 (if on then "yellow" else "white")))
                      
                      (: lights (List Light))
                      (= lights (initnext (map (--> pos (Light false pos)) (filter (--> pos (== (.. pos x) (.. pos y))) (allPositions GRID_SIZE))) 
                                          (prev lights)))
                      
                      (on clicked (= lights (updateObj lights (--> obj (updateObj obj "on" (! (.. obj on)))))))

                      )`
  var aex = parseau(program_str);

  var [aex_, env_] = start(aex);

  for (let i = 0; i < 5; i++) {
    if (i % 3 == 1) {
      var user_event = {"left" : false, "right" : false, "up" : false, "down" : false, "click" : {"x" : Math.floor(15 * Math.random()), "y" : Math.floor(15 * Math.random())}}
    } else {
      var user_event = {"left" : false, "right" : false, "up" : false, "down" : false, "click" : null}
    }
    // console.log(i);
    env_ = step(aex_, env_, user_event);
  }
  // console.log(env_.state.histories.particle);
  return env_;
// return [`0`, `1`, `2`, `3`, `4`, `5`].map(i => [env_.state.histories.particles[i].map(o => [o.origin.x, o.origin.y])]);
}

function test_paint_actual() {
  var program_str = `(program
    (= GRID_SIZE 16)
    
    (object Particle (: color String) (Cell 0 0 color))
    
    (: particles (List Particle))
    (= particles (initnext (list) (prev particles)))
    
    (: currColor String)
    (= currColor (initnext "red" (prev currColor)))
    
    (on clicked (= particles (addObj (prev particles) (Particle currColor (Position (.. click x) (.. click y))))))
    (on (& up (== (prev currColor) "red")) (= currColor "gold"))
    (on (& up (== (prev currColor) "gold")) (= currColor "green"))
    (on (& up (== (prev currColor) "green")) (= currColor "blue"))
    (on (& up (== (prev currColor) "blue")) (= currColor "purple"))
    (on (& up (== (prev currColor) "purple")) (= currColor "red"))
    )`
  var aex = parseau(program_str);

  var [aex_, env_] = start(aex);

  for (let i = 0; i < 5; i++) {
    if (i % 3 == 1) {
      var user_event = {"left" : false, "right" : false, "up" : false, "down" : false, "click" : {"x" : Math.floor(15 * Math.random()), "y" : Math.floor(15 * Math.random())}}
    } else {
      var user_event = {"left" : false, "right" : false, "up" : true, "down" : false, "click" : null}
    }
    // console.log(i);
    env_ = step(aex_, env_, user_event);
  }
  // console.log(env_.state.histories.particle);
  return env_;
// return [`0`, `1`, `2`, `3`, `4`, `5`].map(i => [env_.state.histories.particles[i].map(o => [o.origin.x, o.origin.y])]);
