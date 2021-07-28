module Interpret
using ..InterpretUtils
using ..AExpressions: AExpr
using ..SExpr
export empty_env, Environment, std_env, start, step, run, interpret_program, interpret_over_time
import MLStyle

function interpret_program(aex, Γ)
  aex.head == :program || error("Must be a program aex")
  for line in aex.args
    v, Γ = interpret(line, Γ)
  end
  return aex, Γ
end

function start(aex::AExpr)
  aex.head == :program || error("Must be a program aex")
  env = (object_types=empty_env(), on_clauses=empty_env(), state=(time=0, objectsCreated=0, scene=[]))
  lines = aex.args 

  # reorder program lines
  grid_params_and_object_type_lines = filter(l -> l.head != :assign, lines) # || (l.head == :assign && l.args[1] in [:GRID_SIZE, :background])
  initnext_lines = filter(l -> l.head == :assign && (l.args[2] isa AExpr && l.args[2].head == :initnext), lines)
  lifted_lines = filter(l -> l.head == :assign && (!(l.args[2] isa AExpr) || l.args[2].head != :initnext), lines)
  on_clause_lines = filter(l -> l.head == :on, lines)

  reordered_lines = vcat(grid_params_and_object_type_lines, 
                         on_clause_lines, 
                         initnext_lines, 
                         lifted_lines)

  # add prev functions and variable history to state for lifted variables 
  for line in filter(l -> !(l.args[1] in [:background, :GRID_SIZE]), lifted_lines)
    var_name = l.args[1] 
    # construct history variable in state
    new_state = update(env.state, Symbol(string(var_name, "History")), Dict())
    env = update(env, :state, new_state)

    # construct prev function 
    _, env = interpret(AExpr(:assign, Symbol(string(:prev, uppercasefirst(string(var_name)))), parseautumn("""(fn () (get (.. state $(string(var_name, "History"))) (- (.. state time) 1) $(var_name)))""")), Γ2) 
  end

  new_aex = AExpr(:program, reordered_lines...)

  aex_, env_ = interpret_program(new_aex, env)

  # update state (time, histories, scene)
  env_ = update_state(env_)

  new_aex, env_
end

function step(aex::AExpr, env::Environment)::Environment
  aex_, env_ = interpret_program(aex, env)

  # update state (time, histories, scene)
  env_ = update_state(env_)
  
  env_
end

"""Update the history variables, scene, and time fields of env_.state"""
function update_state(env_)
  # add updated variable values to history
  for key in filter(sym -> occursin("History", string(sym)), keys(env_.state))
    var_name = Symbol(replace(string(key), "History" => ""))
    env_.state[key][env_.state.time] = env_[var_name]
  end

  # update scene 
  new_scene = []
  for key in keys(env_)
    if !(key in [:state, :object_types, :on_clauses]) && env_[key] isa NamedTuple && (:id in keys(env_[key]))
      object_val = env_[key]
      push!(new_scene, object_val)
    end
  end
  env_ = update(env_, :state, update(env_.state, :scene, new_scene))

  # update time 
  new_state = update(env_.state, :time, env_.state.time + 1)
  env_ = update(env_, :state, new_state)
end

function interpret_over_time(aex::AExpr, iters)::Environment
  new_aex, env_ = start(aex)
  for i in 1:iters
    env_ = step(aex, env_)
  end
  env_
end

end