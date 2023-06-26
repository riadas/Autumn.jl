module Interpret
using ..InterpretUtils
using ..AExpressions: AExpr
using ..AutumnStandardLibrary
using ..SExpr
using Random
export empty_env, Environment, std_env, start, step, run, interpret_program, interpret_over_time, interpret_over_time_observations, interpret_over_time_observations_and_env
import MLStyle

"""Interpret program for given number of time steps, returning final environment"""
function interpret_over_time(aex::AExpr, iters, user_events=[]; show_rules=-1)::Env
  new_aex, env_ = start(aex, show_rules=show_rules)
  for i in 1:iters
    env_ = (user_events == []) ? step(new_aex, env_) : step(new_aex, env_, user_events[i])
  end
  env_
end

"""Initialize environment with variable values"""
function start(aex::AExpr, rng=Random.GLOBAL_RNG; show_rules=-1)
  aex.head == :program || error("Must be a program aex")
  env = Env(false, false, false, false, nothing, Dict(), State(0, 0, rng, Scene([], "white"), Dict(), Dict()), show_rules)

  lines = aex.args 

  # reorder program lines
  grid_params_and_object_type_lines = filter(l -> !(l.head in (:assign, :on, :deriv)), lines) # || (l.head == :assign && l.args[1] in [:GRID_SIZE, :background])
  initnext_lines = filter(l -> l.head == :assign && (l.args[2] isa AExpr && l.args[2].head == :initnext), lines)
  lifted_lines = filter(l -> l.head == :assign && (!(l.args[2] isa AExpr) || l.args[2].head != :initnext), lines) # GRID_SIZE and background here
  deriv_lines = filter(l -> l.head == :deriv, lines)
  on_clause_lines = filter(l -> l.head == :on, lines)

  default_on_clause_lines = []
  for line in initnext_lines 
    var_name = line.args[1]
    next_clause = line.args[2].args[2]
    if !(next_clause isa AExpr && next_clause.head == :call && length(next_clause.args) == 2 && next_clause.args[1] == :prev && next_clause.args[2] == var_name)
      new_on_clause = AExpr(:on, Symbol("true"), AExpr(:assign, var_name, next_clause))
      push!(default_on_clause_lines, new_on_clause)
    end
  end

  # ----- START deriv handling -----
  deriv_on_clause_lines = []
  for line in deriv_lines 
    new_on_clause = AExpr(:on, Symbol("true"), line)
    push!(deriv_on_clause_lines, new_on_clause)
  end

  on_clause_lines_ = [default_on_clause_lines..., deriv_on_clause_lines..., on_clause_lines...]

  on_clause_lines = []
  for oc in on_clause_lines_ 
    if oc.args[2].head == :deriv 
      var = oc.args[2].args[1]
      update = oc.args[2].args[2]
      new_oc = AExpr(:on, oc.args[1], parseautumn("""(= $(var) (+ $(var) (* (/ 1 2) $(repr(update)))))"""))
      push!(on_clause_lines, new_oc)
    else
      push!(on_clause_lines, oc)
    end
  end
  # ----- END deriv handling -----

  reordered_lines_init = vcat(grid_params_and_object_type_lines, 
                              initnext_lines, 
                              on_clause_lines, 
                              # lifted_lines
                            )

  # following initialization, we no longer need initnext lines 
  reordered_lines = on_clause_lines

  # add prev functions and variable history to state for lifted variables 
  for line in lifted_lines
    var_name = line.args[1] 
    # construct history variable in state
    env.state.histories[var_name] = Dict()
    # construct prev function 
    # env.current_var_values[Symbol(string(:prev, uppercasefirst(string(var_name))))] = [AExpr(:list, [:state]), AExpr(:call, :get, env.state.histories[var_name], AExpr(:call, :-, AExpr(:field, :state, :time), 1), var_name)]
    # _, env = interpret(AExpr(:assign, Symbol(string(:prev, uppercasefirst(string(var_name)))), parseautumn("""(fn () (get (.. (.. state histories) $(string(var_name))) (- (.. state time) 1) $(var_name)))""")), env) 
  end

  # add background to scene 
  background_assignments = filter(l -> l.args[1] == :background, lifted_lines)
  background = background_assignments != [] ? background_assignments[end].args[2] : "#ffffff00"
  env.state.scene.background = background

  # initialize lifted variables
  for line in lifted_lines
    var_name = line.args[1]
    # env.lifted[var_name] = line.args[2] 
    if var_name in [:GRID_SIZE, :background]
      env.current_var_values[var_name] = interpret(line.args[2], env)[1]
    end
  end 

  new_aex = AExpr(:program, reordered_lines_init...) # try interpreting the init_next's before on for the first time step (init)
  aex_, env_ = interpret_program(new_aex, env)

  # update state (time, histories, scene)
  env_ = update_state(env_)

  AExpr(:program, reordered_lines...), env_
end

"""Interpret program for one time step"""
function step(aex::AExpr, env::Env, user_events=(click=nothing, left=false, right=false, down=false, up=false))::Env
  # update env with user event 
  for user_event in keys(user_events)
    if !isnothing(user_events[user_event])
      env = update(env, user_event, user_events[user_event])
    end
  end

  aex_, env_ = interpret_program(aex, env)

  # update state (time, histories, scene) + reset user_event
  env_ = update_state(env_)
  
  env_
end

"""Helper for single-time-step interpretation"""
function interpret_program(aex, Γ::Env)
  aex.head == :program || error("Must be a program aex")
  for line in aex.args
    v, Γ = interpret(line, Γ)
  end
  return aex, Γ
end

"""Update the history variables, scene, and time fields of env_.state"""
function update_state(env_::Env)
  # reset user events 
  for user_event in [:left, :right, :up, :down]
    env_ = update(env_, user_event, false)
  end
  env_ = update(env_, :click, nothing)

  # add updated variable values to history
  for key in keys(env_.state.histories)    
    env_.state.histories[key][env_.state.time] = env_.current_var_values[key]
  
    # delete earlier times stored in history, since we only use prev up to 1 level back
    if env_.state.time > 0
      delete!(env_.state.histories, env_.state.time - 1)
    end

  end

  # # update lifted variables 
  # for var_name in keys(env_.lifted)
  #   env_.current_var_values[var_name] = interpret(env_.lifted[var_name], env_)[1]
  # end

  # update scene.objects 
  new_scene_objects = []
  for key in keys(env_.current_var_values)
    if ((env_.current_var_values[key] isa Object) || (env_.current_var_values[key] isa AbstractArray && (length(env_.current_var_values[key]) > 0) && (env_.current_var_values[key][1] isa Object)))
      object_val = env_.current_var_values[key]
      if object_val isa AbstractArray 
        push!(new_scene_objects, object_val...)
      else
        push!(new_scene_objects, object_val)
      end
    end
  end
  env_.state.scene.objects = new_scene_objects

  # update time 
  new_state = update(env_.state, :time, env_.state.time + 1)
  env_ = update(env_, :state, new_state)
end

"""Interpret program for given number of time steps, returning values of given variable"""
function interpret_over_time_variable(aex::AExpr, var_name, iters, user_events=[])
  variable_values = []
  new_aex, env_ = start(aex)
  push!(variable_values, env_.state.histories[var_name][env_.state.time])
  for i in 1:iters
    env_ = user_events == [] ? step(new_aex, env_) : step(new_aex, env_, user_events[i])
    push!(variable_values, env_.state.histories[var_name][env_.state.time])
  end
  variable_values
end

"""Interpret program for given number of time steps, returning observed scenes"""
function interpret_over_time_observations(aex::AExpr, iters, user_events=[], rng=Random.GLOBAL_RNG)
  scenes, env_ = interpret_over_time_observations_and_env(aex, iters, user_events, rng)
  scenes
end

"""Interpret program for given number of time steps, returning observed scenes and final environment"""
function interpret_over_time_observations_and_env(aex::AExpr, iters, user_events=[], rng=Random.GLOBAL_RNG)
  scenes = []
  new_aex, env_ = start(aex, rng)
  push!(scenes, AutumnStandardLibrary.renderScene(env_.state.scene, env_.state))
  for i in 1:iters
    env_ = (user_events == []) ? step(new_aex, env_) : step(new_aex, env_, user_events[i])
    push!(scenes, AutumnStandardLibrary.renderScene(env_.state.scene, env_.state))
  end
  scenes, env_
end

end