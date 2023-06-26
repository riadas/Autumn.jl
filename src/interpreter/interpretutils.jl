module InterpretUtils
using ..AExpressions: AExpr
using ..SExpr
using ..AutumnStandardLibrary
using Setfield
export interpret, interpret_let, interpret_call, interpret_init_next, interpret_object, interpret_object_call, interpret_on, Environment, empty_env, std_env, update, primapl, isprim, update
import MLStyle
using MappedArrays

"""Substitute value v for AExpr/Symbol x in aex"""
function sub(aex::AExpr, (x, v))
  if isempty(v)
    return sub_emptyv(aex, x)
  end
  if (x isa AExpr) && aex.head == x.head && aex.args == x.args
    v 
  else
    aex.head == :fn && let 
      (args, body) = aex.args
      return AExpr(:fn, args, sub(body, x => v))
    end

    aex.head == :if && let 
      (c, t, e) = aex.args
      return AExpr(:if, sub(c, x => v), sub(t, x => v), sub(e, x => v))
    end

    aex.head == :assign && let 
      a1, a2 = aex.args
      return AExpr(:assign, a1, sub(a2, x => v))
    end

    aex.head == :list && let 
      args = aex.args
      return AExpr(:list, Any[sub(arg, x => v) for arg in args])
    end

    aex.head == :typedecl && let 
      args = aex.args
      return AExpr(:typedecl, args...)
    end

    aex.head == :let && let 
      args = aex.args
      return AExpr(:let, Any[sub(arg, x => v) for arg in args])
    end

    aex.head == :lambda && let 
      args, body = aex.args
      return AExpr(:fn, args, sub(body, x => v))
    end

    aex.head == :call && let 
      args = aex.args
      return AExpr(:call, Any[sub(arg, x => v) for arg in args])
    end

    aex.head == :object && let 
      args = aex.args
      return AExpr(:object, Any[sub(arg, x => v) for arg in args])
    end

    aex.head == :on && let 
      event, update = aex.args
      return AExpr(:on, sub(event, x => v), sub(update, x => v))
    end

    aex.head == :field && let 
      o, fieldname = aex.args
      return AExpr(:field, sub(o, x => v), fieldname)
    end

    aex.head == :object && let 
      args = aex.args
      return AExpr(:object, Any[sub(arg, x => v) for arg in args])
    end

    aex.head == :on && let 
      event, update = aex.args
      return AExpr(:on, sub(event, x => v), sub(update, x => v))
    end

    error("Could not sub $aex")

  end
end


function sub_emptyv(aex::AExpr, x)
  if (x isa AExpr) && aex.head == x.head && aex.args == x.args
    Any[]
  else
    aex.head == :fn && let 
      (args, body) = aex.args
      return AExpr(:fn, args, sub_emptyv(body, x))
    end

    aex.head == :if && let 
      (c, t, e) = aex.args
      return AExpr(:if, sub_emptyv(c, x), sub_emptyv(t, x), sub_emptyv(e, x))
    end

    aex.head == :assign && let 
      a1, a2 = aex.args
      return AExpr(:assign, a1, sub_emptyv(a2, x))
    end

    aex.head == :list && let 
      args = aex.args
      return AExpr(:list, (sub_emptyv(arg, x) for arg in args)...)
    end

    aex.head == :typedecl && let 
      args = aex.args
      return AExpr(:typedecl, args...)
    end

    aex.head == :let && let 
      args = aex.args
      return AExpr(:let, (sub_emptyv(arg, x) for arg in args)...)
    end

    aex.head == :lambda && let 
      args, body = aex.args
      return AExpr(:fn, args, sub_emptyv(body, x))
    end

    aex.head == :call && let 
      args = aex.args
      return AExpr(:call, (sub_emptyv(arg, x) for arg in args)...)
    end

    aex.head == :object && let 
      args = aex.args
      return AExpr(:object, (sub_emptyv(arg, x) for arg in args)...)
    end

    aex.head == :on && let 
      event, update = aex.args
      return AExpr(:on, sub_emptyv(event, x), sub_emptyv(update, x))
    end

    aex.head == :field && let 
      o, fieldname = aex.args
      return AExpr(:field, sub_emptyv(o, x), fieldname)
    end

    aex.head == :object && let 
      args = aex.args
      return AExpr(:object, (sub_emptyv(arg, x) for arg in args)...)
    end

    aex.head == :on && let 
      event, update = aex.args
      return AExpr(:on, sub_emptyv(event, x), sub_emptyv(update, x))
    end

    error("Could not sub $aex")

  end
end

sub(aex::Symbol, (x, v)) = aex == x ? v : aex

sub_emptyv(aex::Symbol, x) = aex == x ? Any[] : aex

sub(aex, (x, v)) = aex # aex is a value

sub_emptyv(aex, x) = aex # aex is a value

const Environment = NamedTuple
empty_env() = NamedTuple()
std_env() = empty_env()

"Produces new environment Γ' s.t. `Γ(x) = v` (and everything else unchanged)"
function update(Γ::Env, x::Symbol, v)::Env 
  setfield!(Γ, x, v)
  Γ
end

function update(Γ::State, x::Symbol, v)::State 
  setfield!(Γ, x, v)
  Γ
end

function update(Γ::Scene, x::Symbol, v)::Scene 
  setfield!(Γ, x, v)
  Γ
end

function update(Γ::Object, x::Symbol, v)::Object 
  if x == :id 
    Γ = @set Γ.id = v
  elseif x == :type 
    Γ = @set Γ.type = v
  elseif x == :alive 
    Γ = @set Γ.alive = v
  elseif x == :custom_fields 
    Γ = @set Γ.custom_fields = v
  elseif x == :render
    Γ = @set Γ.render = v
  elseif x == :origin 
    Γ = @set Γ.origin = v
  else
    # # println("yeet")
    Γ = deepcopy(Γ)
    Γ.custom_fields[x] = v
  end
  Γ
end

# primitive function handling 
const prim_to_func = let prims = (:+, :-, :*, :/, :&, :!, :|, :>, :>=, :<, :<=, :(==), :%, :!=,)
  NamedTuple{prims}(getproperty.(Ref(Base), prims))
end

isprim(f) = f in keys(prim_to_func)

function primapl(f, x, @nospecialize(Γ::Env)) 
  prim_to_func[f](x), Γ
end

function primapl(f, x1, x2, @nospecialize(Γ::Env))
  prim_to_func[f](x1, x2), Γ
end

const lib_to_func = let keys = (
    :Position,
    :Cell,
    :Click,
    :render, 
    :renderScene, 
    :occurred,
    :uniformChoice, 
    :min,
    :isWithinBounds, 
    :isOutsideBounds,
    :clicked, 
    :objClicked, 
    :intersects, 
    :moveIntersects,
    :pushConfiguration,
    :addObj, 
    :removeObj, 
    :updateObj,
    :filter_fallback,
    :adjPositions,
    :isFree, 
    :rect, 
    :unitVector, 
    :displacement, 
    :adjacent, 
    :adjacentObjs, 
    :adjacentObjsDiag,
    :adj,
    :adjCorner,
    #  :rotate, 
    #  :rotateNoCollision, 
    :move, 
    :moveLeft, 
    :moveRight, 
    :moveUp, 
    :moveDown, 
    :moveNoCollision, 
    :moveNoCollisionColor, 
    :moveLeftNoCollision, 
    :moveRightNoCollision, 
    :moveDownNoCollision, 
    :moveUpNoCollision, 
    :moveWrap, 
    :moveLeftWrap,
    :moveRightWrap, 
    :moveUpWrap, 
    :moveDownWrap, 
    :scalarMult,
    :randomPositions, 
    :distance,
    :closest,
    :closestRandom,
    :closestLeft,
    :closestRight,
    :closestUp,
    :closestDown, 
    :farthestRandom,
    :farthestLeft,
    :farthestRight,
    :farthestUp,
    :farthestDown, 
    :mapPositions, 
    :allPositions, 
    :updateOrigin, 
    :updateAlive, 
    :nextLiquid, 
    :nextSolid,
    :unfold,
    :range,
    :prev,
    :firstWithDefault)
  NamedTuple{keys}(getproperty.(Ref(AutumnStandardLibrary), keys))
end

islib(f) = f in keys(lib_to_func)

function libapl(f, args, @nospecialize(Γ::Env))
  if f == :clicked && (length(args) == 0)
    interpret(f, Γ)
  elseif f == :clicked
    lib_to_func[f](interpret(:click, Γ)[1], args..., Γ.state), Γ
  else
    has_function_arg = false
    for arg in args 
      if (arg isa AbstractArray) && (length(arg) == 2) && (arg[1] isa AExpr || arg[1] isa Symbol) && (arg[2] isa AExpr || arg[2] isa Symbol)
        has_function_arg = true
      end
    end
  
    if !has_function_arg && (f != :updateObj)
      lib_to_func[f]((interpret(arg, Γ)[1] for arg in args)..., Γ.state), Γ    
    else
      if f == :updateObj 
        interpret_updateObj(args, Γ)
      elseif f == :removeObj 
        interpret_removeObj(args, Γ)
      else 
        lib_to_func[f]((interpret(arg, Γ)[1] for arg in args)..., Γ.state), Γ
      end
    end
  end
end

const julia_lib_to_func = 
  (get = get, 
   map = map,
   filter = filter,
   first = first,
   last = last,
   in = in, 
   intersect = intersect,
   length = length,
   sign = sign,
   vcat = vcat, 
   count = count)
isjulialib(f) = f in keys(julia_lib_to_func)

function julialibapl(f, args, @nospecialize(Γ::Env))
  # println("JULIALIBAPL")
  # @show f 
  if !(f in [:map, :filter])
    julia_lib_to_func[f](args...), Γ
  elseif f == :map 
    interpret_julia_map(args, Γ)
  elseif f == :filter 
    interpret_julia_filter(args, Γ)
  end
end

"""Main interpret function: interpret aex given environment Γ"""
function interpret(aex::AExpr, @nospecialize(Γ::Env))
  aex.head == :if       && return _if_interpret(Γ, aex.args...)
    aex.head == :assign   && return _assign_interpret(Γ, aex.args...)
    aex.head == :list     && return _list_interpret(Γ, aex.args...)
    aex.head == :typedecl && return _typedecl_interpret(Γ, aex.args...)
    aex.head == :let      && return _let_interpret(Γ, aex.args...)
    aex.head == :lambda   && return (aex.args, Γ)
    aex.head == :fn       && return (aex.args, Γ)
    aex.head == :call     && return _call_interpret(Γ, aex.args...)
    aex.head == :field    && return _field_interpret(Γ, aex.args...)
    aex.head == :object   && return _object_interpret(Γ, aex.args...)
    aex.head == :on       && return interpret_on(aex.args, Γ)
    error(string("Invalid AExpr Head: ", aex.head))
end

function _if_interpret(@nospecialize(Γ::Env), c, t, e)
  (v, Γ2) = interpret(c, Γ) 
  interpret(v ? t : e, Γ2)
end


function _assign_interpret(@nospecialize(Γ::Env), x, v::AExpr)
  if v.head == :initnext 
    interpret_init_next(x, v, Γ)
  else
    (v2, Γ_) = interpret(v, Γ)
    _assign_interpret(Γ_, x, v2)
  end
end

function _assign_interpret(@nospecialize(Γ::Env), x, v::Symbol)
  (v2, Γ_) = interpret(v, Γ)
  _assign_interpret(Γ_, x, v2)
end

function _assign_interpret(@nospecialize(Γ::Env), x, v::BigInt)
    Γ.current_var_values[x] = convert(Int, v) 
    (AExpr(:assign, x, v), Γ) 
end

function _assign_interpret(@nospecialize(Γ::Env), x, v)
  Γ.current_var_values[x] = v
  (AExpr(:assign, x, v), Γ) 
end

function _list_interpret(@nospecialize(Γ::Env), args...)
  interpret_list(args, Γ)
end

function _typedecl_interpret(@nospecialize(Γ::Env), args...)
  (AExpr(:typedecl, args...), Γ)
end

function _let_interpret(@nospecialize(Γ::Env), args...)
  interpret_let(args, Γ) 
end

function _lambda_interpret(@nospecialize(Γ::Env), args...)
  (args, Γ)
end

function _fn_interpret(@nospecialize(Γ::Env), args...)
  (args, Γ)
end


function _call_interpret(@nospecialize(Γ::Env), f, args...)
  if isprim(f)
    if length(args) == 1
      arg1 = only(args)
      (new_arg, Γ2) = interpret(arg1, Γ)
      return primapl(f, new_arg, Γ2)
    elseif length(args) == 2
      (arg1, arg2) = args
      (new_arg1, Γ2) = interpret(arg1, Γ)
      (new_arg2, Γ2) = interpret(arg2, Γ2)
      return primapl(f, new_arg1, new_arg2, Γ2)
    end
  end
  if f == :prev && args != (:obj,)
    Γ.state.histories[args[1]][Γ.state.time - 1], Γ
  elseif islib(f)
    interpret_lib(f, args, Γ)
  elseif isjulialib(f)
    interpret_julia_lib(f, args, Γ)
  elseif f in keys(Γ.state.object_types)
    interpret_object_call(f, args, Γ)
  else
    interpret_call(f, args, Γ)
  end
end

function _field_interpret(@nospecialize(Γ::Env), x, fieldname)
  interpret_field(x, fieldname, Γ)
end

function _object_interpret(@nospecialize(Γ::Env), args...)
  interpret_object(collect(args), Γ)
end


function interpret(x::Symbol, @nospecialize(Γ::Env))
  if x == Symbol("false")
    false, Γ
  elseif x == Symbol("true")
    true, Γ
  elseif x == :left 
    Γ.left, Γ
  elseif x == :right 
    Γ.right, Γ
  elseif x == :up
    Γ.up, Γ
  elseif x == :down 
    Γ.down, Γ
  elseif x == :click 
    Γ.click, Γ
  elseif x == :clicked 
    _call_interpret(Γ, :occurred, :click)
  elseif x in keys(Γ.state.object_types)
    x, Γ
  elseif x == :state 
    Γ.state, Γ
  elseif x in keys(Γ.current_var_values)
    Γ.current_var_values[x], Γ
  else
    error("Could not interpret $x")
  end
end

# if x is not an AExpr or a Symbol, it is just a value (return it)
function interpret(x, @nospecialize(Γ::Env))
  if x isa BigInt 
    (convert(Int, x), Γ)
  else
    (x, Γ)
  end
end 

function interpret_list(args, @nospecialize(Γ::Env))
  new_list = Vector{Any}(undef, length(args))
  for (j, arg) in enumerate(args)
    new_arg, Γ = interpret(arg, Γ)
    new_list[j] = new_arg
  end
  new_list, Γ
end

function interpret_lib(f, args, @nospecialize(Γ::Env))
  new_args = Vector{Any}(undef, length(args))
  for (j, arg) in enumerate(args) 
    new_arg, Γ = interpret(arg, Γ)
    new_args[j] = new_arg
    # push!(new_args, new_arg)
  end
  libapl(f, new_args, Γ)
end

function interpret_julia_lib(f, args, @nospecialize(Γ::Env))
  new_args = Vector{Any}(undef, length(args))
  for i in eachindex(args)
    arg = args[i] 
    if f == :get && i == 2 && args[i] isa Symbol
      new_arg = arg
    else
      new_arg, Γ = interpret(arg, Γ)
    end
    new_args[i] = new_arg
  end
  julialibapl(f, new_args, Γ)
end

function interpret_field(x, f, @nospecialize(Γ::Env))
  val, Γ2 = interpret(x, Γ)
  if val isa Object
    if f in [:id, :origin, :type, :alive, :changed, :render]
      (getfield(val, f), Γ2)
    else
      (val.custom_fields[f], Γ2)
    end
  else
    (getfield(val, f), Γ2)
  end
end

function interpret_let(args, @nospecialize(Γ::Env))
  Γ2 = Γ
  if length(args) > 0
    for arg in args[1:end-1] # all lines in let except last
      v2, Γ2 = interpret(arg, Γ2)
    end
  
    if args[end] isa AExpr
      if args[end].head == :assign # all assignments are global; no return value 
        v2, Γ2 = interpret(args[end], Γ2)
        (AExpr(:let, args...), Γ2)
      else # return value is AExpr   
        v2, Γ2 = interpret(args[end], Γ2)
        (v2, Γ)
      end
    else # return value is not AExpr
      (interpret(args[end], Γ2)[1], Γ)
    end
  else
    AExpr(:let, args...), Γ2
  end
end

# used for lambda function calls!
function interpret_call(f, params, @nospecialize(Γ::Env))
  func, Γ = interpret(f, Γ)
  func_args = func[1]
  func_body = func[2]

  # construct environment
  old_current_var_values = copy(Γ.current_var_values) 
  Γ2 = Γ
  if func_args isa AExpr 
    for i in eachindex(func_args.args)
      param_name = func_args.args[i]
      param_val, Γ2 = interpret(params[i], Γ2)
      Γ2.current_var_values[param_name] = param_val
    end
  elseif func_args isa Symbol
    param_name = func_args
    param_val, Γ2 = interpret(params[1], Γ2)
    Γ2.current_var_values[param_name] = param_val
  else
    error("Could not interpret $(func_args)")
  end
  # evaluate func_body in environment 
  v, Γ2 = interpret(func_body, Γ2)
  
  # return value and original environment, except with state updated 
  Γ = update(Γ, :state, update(Γ.state, :objectsCreated, Γ2.state.objectsCreated))
  Γ.current_var_values = old_current_var_values
  (v, Γ)
end

function interpret_object_call(f, args, @nospecialize(Γ::Env))
  new_state = update(Γ.state, :objectsCreated, Γ.state.objectsCreated + 1)
  Γ = update(Γ, :state, new_state)

  origin, Γ = interpret(args[end], Γ)
  # object_repr = (origin=origin, type=f, alive=true, changed=false, id=Γ.state.objectsCreated)

  old_current_var_values = copy(Γ.current_var_values)
  Γ2 = Γ
  fields = Γ2.state.object_types[f].fields
  field_values = Dict()
  for i in eachindex(fields)
    field_name = fields[i].args[1]
    field_value, Γ2 = interpret(args[i], Γ2)
    field_values[field_name] = field_value
    Γ2.current_var_values[field_name] = field_value
  end
  if length(fields) == 0 
    object_repr = Object(Γ.state.objectsCreated, origin, f, true, false, field_values, nothing)  
  else
    render, Γ2 = interpret(Γ.state.object_types[f].render, Γ2)
    render = render isa AbstractArray ? render : [render]
    object_repr = Object(Γ.state.objectsCreated, origin, f, true, false, field_values, render)
  end
  Γ.current_var_values = old_current_var_values
  (object_repr, Γ)  
end

function interpret_init_next(var_name, var_val, @nospecialize(Γ::Env))
  init_func = var_val.args[1]
  next_func = var_val.args[2]

  Γ2 = Γ
  if !(var_name in keys(Γ2.current_var_values)) # variable not initialized; use init clause
    var_val, Γ2 = interpret(init_func, Γ2)
    Γ2.current_var_values[var_name] = var_val

    # construct history variable in state 
    Γ2.state.histories[Symbol(string(var_name))] = Dict()

  end
  (AExpr(:assign, var_name, var_val), Γ2)
end

function interpret_object(args, @nospecialize(Γ::Env))
  object_name = args[1]
  object_fields = args[2:end-1]
  object_render = args[end]

  # construct object creation function
  if length(object_fields) == 0
    render, _ = interpret(object_render, Γ)
    if !(render isa AbstractArray) 
      render = [render]
    end
    object_tuple = ObjectType(render, object_fields)
  else
    object_tuple = ObjectType(object_render, object_fields)
  end
  Γ.state.object_types[object_name] = object_tuple
  (AExpr(:object, args...), Γ)
end

function interpret_on(args, @nospecialize(Γ::Env))
  event = args[1]
  update_ = args[2]
  Γ2 = Γ
  if Γ2.state.time != 0
    e, Γ2 = interpret(event, Γ2) 
    if e == true
      if Γ2.show_rules != -1
        open("likelihood_output_$(Γ2.show_rules).txt", "a") do io
          println(io, "----- global -----")
          println(io, repr([event isa Symbol ? event : repr(event), repr(update_)]))
        end
      end
      t = interpret(update_, Γ2)
      Γ3 = t[2]
      Γ2 = Γ3
    end
  end
  (AExpr(:on, args...), Γ2)
end

# evaluate updateObj on arguments that include functions 
function interpret_updateObj(args, @nospecialize(Γ::Env))
  Γ2 = Γ
  numFunctionArgs = count(x -> x == true, mappedarray(arg -> (arg isa AbstractArray) && (length(arg) == 2) && (arg[1] isa AExpr || arg[1] isa Symbol) && (arg[2] isa AExpr || arg[2] isa Symbol), args))
  if numFunctionArgs == 1
    
    list, Γ2 = interpret(args[1], Γ2)
    map_func = args[2]

    if Γ2.show_rules != -1 && list != []
      open("likelihood_output_$(Γ2.show_rules).txt", "a") do io
        println(io, "----- updateObj 3 -----")
        println(io, repr(mappedarray(x -> x isa Symbol || x isa AbstractArray ? x : repr(x), [args[1], args[2][1], args[2][2], :obj, Symbol("true")])))
      end
    end

    new_list = Vector{Any}(undef, length(list))
    for (j, item) in enumerate(list)
      if Γ2.show_rules != -1
        open("likelihood_output_$(Γ2.show_rules).txt", "a") do io
          println(io, "object_id")
          println(io, item.id) # list, map_func, filter_func, item
        end
      end
      new_item, Γ2 = interpret(AExpr(:call, map_func, item), Γ2)
      new_list[j] = new_item
    end
    new_list, Γ2
  elseif numFunctionArgs == 2
    list, Γ2 = interpret(args[1], Γ2)
    map_func = args[2]
    filter_func = args[3]

    if Γ2.show_rules != -1
      open("likelihood_output_$(Γ2.show_rules).txt", "a") do io
        println(io, "----- updateObj 3 -----")
        println(io, repr(mappedarray(x -> x isa Symbol || x isa AbstractArray ? x : repr(x), [args[1], args[2]..., args[3]...])))
      end
    end

    new_list = Vector{Any}(undef, length(list))
    for (j, item) in enumerate(list)
      pred, Γ2 = interpret(AExpr(:call, filter_func, item), Γ2)
      if pred == true 
        if Γ2.show_rules != -1
          open("likelihood_output_$(Γ2.show_rules).txt", "a") do io
            println(io, "object_id")
            println(io, item.id) # list, map_func, filter_func, item
          end
        end

        new_item, Γ2 = _call_interpret(Γ2, map_func, item)

        # new_item, Γ2 = interpret(AExpr(:call, map_func, item), Γ2)
        new_list[j] = new_item
      else
        new_list[j] = item
      end
    end
    new_list, Γ2
  elseif numFunctionArgs == 0
    obj = args[1]
    field_string = args[2]
    new_value = args[3]
    new_obj = update(obj, Symbol(field_string), new_value)

    # update render
    object_type = Γ.state.object_types[obj.type]
    
    old_current_var_values = copy(Γ.current_var_values)
    Γ3 = Γ2
    fields = object_type.fields
    for i in eachindex(fields)
      field_name = fields[i].args[1]
      field_value = new_obj.custom_fields[field_name]
      Γ3.current_var_values[field_name] = field_value
    end

    if length(fields) != 0 
      render, Γ3 = interpret(Γ.state.object_types[obj.type].render, Γ3)
      render = render isa AbstractArray ? render : [render]
      new_obj = update(new_obj, :render, render)
    end  
    Γ2.current_var_values = old_current_var_values
    new_obj, Γ2
  else
    error("Could not interpret updateObj")
  end
end

function interpret_removeObj(args, @nospecialize(Γ::Env))
  list, Γ = interpret(args[1], Γ)
  func = args[2]
  new_list = []
  for item in list
    pred, Γ = interpret(AExpr(:call, func, item), Γ) 
    if pred == false 
      push!(new_list, item)
    else
      new_item = update(item, :alive, false)
      push!(new_list, new_item)
    end
  end
  new_list, Γ
end

function interpret_julia_map(args, @nospecialize(Γ::Env))
  map_func = args[1]
  list, Γ = interpret(args[2], Γ)
  new_list = Vector{Any}(undef, length(list))
  for (j, arg) in enumerate(list)  
    new_arg, Γ = interpret(AExpr(:call, map_func, arg), Γ)
    new_list[j] = new_arg
  end
  new_list, Γ
end

function interpret_julia_filter(args, @nospecialize(Γ::Env))
  new_list = []
  filter_func = args[1]
  list, Γ = interpret(args[2], Γ)
  for arg in list
    v, Γ = interpret(AExpr(:call, filter_func, arg), Γ)
    if v == true 
      push!(new_list, interpret(arg, Γ)[1])
    end
  end
  new_list, Γ
end

end