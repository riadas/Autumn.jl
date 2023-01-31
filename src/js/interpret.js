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
         "state" : {}
  }

}

function step(aex, env, user_event) {

}

function update_state(env) {

}

function interpret_over_time(aex, iters, user_events=[]) {

}

function interpret_over_time_variable(aex, var_name, iters, user_events=[]) {

}

function interpret_over_time_observations(aex, iters, user_events=[]) {

}