module Interpret
using ..InterpretUtils
using ..AExpressions: AExpr
using ..AutumnStandardLibrary
using ..SExpr
using Random
export empty_env, Environment, std_env, start, step, run, interpret_program, interpret_over_time, interpret_over_time_observations, interpret_over_time_observations_and_env
import MLStyle

function interpret_over_time(aex::AExpr, iters, user_events=[]; show_rules=-1)::Env
  new_aex, env_ = start(aex, show_rules=show_rules)
  if user_events == []
    for i in 1:iters
      # # @show i
      env_ = step(new_aex, env_)
    end
  else
    for i in 1:iters
      # # @show i
      env_ = step(new_aex, env_, user_events[i])
    end
  end
  env_
end

function start(aex::AExpr, rng=Random.GLOBAL_RNG; show_rules=-1)
  aex.head == :program || error("Must be a program aex")
  env = Env(false, false, false, false, nothing, Dict(), Dict(), Dict(), State(0, 0, rng, Scene([], "white"), Dict(), Dict()), show_rules)

  lines = aex.args 

  # reorder program lines
  grid_params_and_object_type_lines = filter(l -> !(l.head in [:assign, :on]), lines) # || (l.head == :assign && l.args[1] in [:GRID_SIZE, :background])
  initnext_lines = filter(l -> l.head == :assign && (l.args[2] isa AExpr && l.args[2].head == :initnext), lines)
  lifted_lines = filter(l -> l.head == :assign && (!(l.args[2] isa AExpr) || l.args[2].head != :initnext), lines) # GRID_SIZE and background here
  on_clause_lines = filter(l -> l.head == :on, lines)

  reordered_lines_temp = vcat(grid_params_and_object_type_lines, 
                              initnext_lines, 
                              on_clause_lines, 
                              lifted_lines)

  reordered_lines = vcat(grid_params_and_object_type_lines, 
                         on_clause_lines, 
                         initnext_lines, 
                         lifted_lines)

  # add prev functions and variable history to state for lifted variables 
  for line in lifted_lines
    var_name = line.args[1] 
    # construct history variable in state
    # new_state = update(env.state, Symbol(string(var_name, "History")), Dict())
    env.state.histories[var_name] = Dict()
    # env = update(env, :state, new_state)

    # construct prev function 
    _, env = interpret(AExpr(:assign, Symbol(string(:prev, uppercasefirst(string(var_name)))), parseautumn("""(fn () (get (.. (.. state histories) $(string(var_name))) (- (.. state time) 1) $(var_name)))""")), env) 
  end

  # add background to scene 
  background_assignments = filter(l -> l.args[1] == :background, lifted_lines)
  background = background_assignments != [] ? background_assignments[end].args[2] : "#ffffff00"
  env.state.scene.background = background


  # initialize scene.objects 
  # env = update(env, :state, update(env.state, :scene, update(env.state.scene, :objects, [])))

  # initialize lifted variables
  # env = update(env, :lifted, empty_env()) 
  for line in lifted_lines
    var_name = line.args[1]
    env.lifted[var_name] = line.args[2] 
    if var_name in [:GRID_SIZE, :background]
      env.current_var_values[var_name] = interpret(line.args[2], env)[1]
    end
  end 

  new_aex = AExpr(:program, reordered_lines_temp...) # try interpreting the init_next's before on for the first time step (init)
  # # @show new_aex
  aex_, env_ = interpret_program(new_aex, env)

  # update state (time, histories, scene)
  env_ = update_state(env_)

  AExpr(:program, reordered_lines...), env_
end

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

  # update lifted variables 
  for var_name in keys(env_.lifted)
    env_.current_var_values[var_name] = interpret(env_.lifted[var_name], env_)[1]
  end

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

function interpret_over_time_variable(aex::AExpr, var_name, iters, user_events=[])
  variable_values = []
  new_aex, env_ = start(aex)
  push!(variable_values, env_.state.histories[var_name][env_.state.time])
  if user_events == []
    for i in 1:iters
      # # @show i
      env_ = step(new_aex, env_)
      push!(variable_values, env_.state.histories[var_name][env_.state.time])
    end
  else
    for i in 1:iters
      # # @show i
      env_ = step(new_aex, env_, user_events[i])
      push!(variable_values, env_.state.histories[var_name][env_.state.time])
    end
  end
  variable_values
end

function interpret_over_time_observations(aex::AExpr, iters, user_events=[], rng=Random.GLOBAL_RNG)
  scenes = []
  new_aex, env_ = start(aex, rng)
  push!(scenes, AutumnStandardLibrary.renderScene(env_.state.scene, env_.state))
  if user_events == []
    for i in 1:iters
      # # @show i
      env_ = step(new_aex, env_)
      push!(scenes, AutumnStandardLibrary.renderScene(env_.state.scene, env_.state))
    end
  else
    for i in 1:iters
      # # @show i
      env_ = step(new_aex, env_, user_events[i])
      push!(scenes, AutumnStandardLibrary.renderScene(env_.state.scene, env_.state))
    end
  end
  scenes
end

function interpret_over_time_observations_and_env(aex::AExpr, iters, user_events=[], rng=Random.GLOBAL_RNG)
  scenes = []
  new_aex, env_ = start(aex, rng)
  push!(scenes, AutumnStandardLibrary.renderScene(env_.state.scene, env_.state))
  if user_events == []
    for i in 1:iters
      # # @show i
      env_ = step(new_aex, env_)
      push!(scenes, AutumnStandardLibrary.renderScene(env_.state.scene, env_.state))
    end
  else
    for i in 1:iters
      # # @show i
      env_ = step(new_aex, env_, user_events[i])
      push!(scenes, AutumnStandardLibrary.renderScene(env_.state.scene, env_.state))
    end
  end
  scenes, env_
end

end