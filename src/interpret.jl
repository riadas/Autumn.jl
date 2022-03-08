module Interpret
using ..InterpretUtils
using ..AExpressions: AExpr
using ..AutumnStandardLibrary
using ..SExpr
using Random
export empty_env, Environment, std_env, start, step, run, interpret_program, interpret_over_time, interpret_over_time_observations
import MLStyle

function interpret_program(aex, @nospecialize(Γ::NamedTuple))
  aex.head == :program || error("Must be a program aex")
  for line in aex.args
    v, Γ = interpret(line, Γ)
  end
  return aex, Γ
end

function start(aex::AExpr, rng=Random.GLOBAL_RNG)
  aex.head == :program || error("Must be a program aex")
  env = (on_clauses=empty_env(),
         left=false, 
         right=false,
         up=false,
         down=false,
         click=nothing, 
         state=(time=0, objectsCreated=0, rng=rng, scene=empty_env(), object_types=empty_env()))
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
    new_state = update(env.state, Symbol(string(var_name, "History")), Dict())
    env = update(env, :state, new_state)

    # construct prev function 
    _, env = interpret(AExpr(:assign, Symbol(string(:prev, uppercasefirst(string(var_name)))), parseautumn("""(fn () (get (.. state $(string(var_name, "History"))) (- (.. state time) 1) $(var_name)))""")), env) 
  end

  # add background to scene 
  background_assignments = filter(l -> l.args[1] == :background, lifted_lines)
  background = background_assignments != [] ? background_assignments[end].args[2] : "#ffffff00"
  env = update(env, :state, update(env.state, :scene, update(env.state.scene, :background, background)))


  # initialize scene.objects 
  env = update(env, :state, update(env.state, :scene, update(env.state.scene, :objects, [])))

  # initialize lifted variables
  env = update(env, :lifted, empty_env()) 
  for line in lifted_lines
    var_name = line.args[1]
    env = update(env, :lifted, update(env.lifted, var_name, line.args[2])) 
    if var_name in [:GRID_SIZE, :background]
      env = update(env, var_name, interpret(line.args[2], env)[1])
    end
  end 

  new_aex = AExpr(:program, reordered_lines_temp...) # try interpreting the init_next's before on for the first time step (init)
  # # @show new_aex
  aex_, env_ = interpret_program(new_aex, env)

  # update state (time, histories, scene)
  env_ = update_state(env_)

  AExpr(:program, reordered_lines...), env_
end

function step(aex::AExpr, @nospecialize(env::NamedTuple), user_events=(click=nothing, left=false, right=false, down=false, up=false))::NamedTuple
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

"""Update the history variables, scene, and time fields of env_.state"""
function update_state(@nospecialize(env_::NamedTuple))
  # reset user events 
  for user_event in [:left, :right, :up, :down]
    env_ = update(env_, user_event, false)
  end
  env_ = update(env_, :click, nothing)

  # add updated variable values to history
  for key in filter(sym -> occursin("History", string(sym)), keys(env_.state))
    var_name = Symbol(replace(string(key), "History" => ""))
    env_.state[key][env_.state.time] = env_[var_name]
  end

  # update lifted variables 
  for var_name in keys(env_.lifted)
    env_ = update(env_, var_name, interpret(env_.lifted[var_name], env_)[1])
  end

  # update scene.objects 
  new_scene_objects = []
  for key in keys(env_)
    if !(key in [:state, :on_clauses, :lifted]) && ((env_[key] isa NamedTuple && (:id in keys(env_[key]))) || (env_[key] isa AbstractArray && (length(env_[key]) > 0) && (env_[key][1] isa NamedTuple)))
      object_val = env_[key]
      if object_val isa AbstractArray 
        push!(new_scene_objects, object_val...)
      else
        push!(new_scene_objects, object_val)
      end
    end
  end
  env_ = update(env_, :state, update(env_.state, :scene, update(env_.state.scene, :objects, new_scene_objects)))

  # update time 
  new_state = update(env_.state, :time, env_.state.time + 1)
  env_ = update(env_, :state, new_state)
end

function interpret_over_time(aex::AExpr, iters, user_events=[])::NamedTuple
  new_aex, env_ = start(aex)
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

function interpret_over_time_observations(aex::AExpr, iters, user_events=[])
  scenes = []
  new_aex, env_ = start(aex)
  push!(scenes, AutumnStandardLibrary.renderScene(env_.state.scene, env_))
  if user_events == []
    for i in 1:iters
      # # @show i
      env_ = step(new_aex, env_)
      push!(scenes, AutumnStandardLibrary.renderScene(env_.state.scene, env_))
    end
  else
    for i in 1:iters
      # # @show i
      env_ = step(new_aex, env_, user_events[i])
      push!(scenes, AutumnStandardLibrary.renderScene(env_.state.scene, env_))
    end
  end
  scenes
end

# function render_scene(scene, env)
#   observations = []
#   for obj in filter(x -> x.alive, scene.objects) 
#     push!(observations, AutumnStandardLibrary.render(scene.objects, env)...)
#   end
#   observations
# end

end