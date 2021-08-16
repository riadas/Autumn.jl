module InterpretUtils
using ..AExpressions: AExpr
using ..SExpr
using ..AutumnStandardLibrary
using ..CompileUtils
export interpret, interpret_let, interpret_call, interpret_init_next, interpret_object, interpret_object_call, interpret_on, Environment, empty_env, std_env, update, primapl, isprim, update
import MLStyle

function sub(aex::AExpr, (x, v))
  # print("SUb")
  # # # # @show aex
  # # # # @show x
  # # # # @show v
  arr = [aex.head, aex.args...]
  # next(x) = interpret(x, Γ)
  if (x isa AExpr) && ([x.head, x.args...] == arr)  
    v 
  else
    MLStyle.@match arr begin
      [:fn, args, body]                                       => AExpr(:fn, args, sub(body, x => v))
      [:if, c, t, e]                                          => AExpr(:if, sub(c, x => v), sub(t, x => v), sub(e, x => v))
      [:assign, a1, a2]                                       => AExpr(:assign, a1, sub(a2, x => v))
      [:list, args...]                                        => AExpr(:list, map(arg -> sub(arg, x => v), args)...)
      [:typedecl, args...]                                    => AExpr(:typedecl, args...)
      [:let, args...]                                         => AExpr(:let, map(arg -> sub(arg, x => v), args)...)      
      # [:case, args...] => compilecase(expr, data)            
      # [:typealias, args...] => compiletypealias(expr, data)      
      [:lambda, args, body]                                   => AExpr(:fn, args, sub(body, x => v))
      [:call, f, args...]                                     => AExpr(:call, f, map(arg -> sub(arg, x => v) , args)...)      
      [:field, o, fieldname]                                  => AExpr(:field, sub(o, x => v), fieldname)
      [:object, args...]                                      => AExpr(:object, args...)
      [:on, event, update]                                    => AExpr(:on, sub(event, x => v), sub(update, x => v))
      [args...]                                               => throw(AutumnError(string("Invalid AExpr Head: ", expr.head)))
      _                                                       => error("Could not sub $arr")
    end
  end
end

sub(aex::Symbol, (x, v)) = aex == x ? v : aex
sub(aex, (x, v)) = aex # aex is a value

const Environment = NamedTuple
empty_env() = NamedTuple()
std_env() = empty_env()

"Produces new environment Γ' s.t. `Γ(x) = v` (and everything else unchanged)"
# update(@nospecialize(Γ::NamedTuple), x::Symbol, v) = merge(Γ, NamedTuple{(x,)}((v,)))

function update(@nospecialize(Γ::NamedTuple), x::Symbol, @nospecialize(v)) 
  merge(Γ, NamedTuple{(x,)}((v,)))
end

# primitive function handling 
prim_to_func = Dict(:+ => +,
                    :- => -,
                    :* => *,
                    :/ => /,
                    :& => &,
                    :! => !,
                    :| => |,
                    :> => >,
                    :>= => >=,
                    :< => <,
                    :<= => <=,
                    :(==) => ==,
                    :% => %,
                    :!= => !=)

isprim(f) = f in keys(prim_to_func)
# primapl(f, x...) = (prim_to_func[f](x[1:end-1]...), x[end])

function primapl(f, x, @nospecialize(Γ::NamedTuple)) 
  prim_to_func[f](x), Γ
end

function primapl(f, x1, x2, @nospecialize(Γ::NamedTuple))
  prim_to_func[f](x1, x2), Γ
end

lib_to_func = Dict(:Position => AutumnStandardLibrary.Position,
                   :Cell => AutumnStandardLibrary.Cell,
                   :Click => AutumnStandardLibrary.Click,
                   :render => AutumnStandardLibrary.render, 
                   :occurred => AutumnStandardLibrary.occurred,
                   :uniformChoice => AutumnStandardLibrary.uniformChoice, 
                   :min => AutumnStandardLibrary.min,
                   :isWithinBounds => AutumnStandardLibrary.isWithinBounds, 
                   :clicked => AutumnStandardLibrary.clicked, 
                   :objClicked => AutumnStandardLibrary.objClicked, 
                   :intersects => AutumnStandardLibrary.intersects, 
                   :addObj => AutumnStandardLibrary.addObj, 
                   :removeObj => AutumnStandardLibrary.removeObj, 
                   :updateObj => AutumnStandardLibrary.updateObj,
                   :filter_fallback => AutumnStandardLibrary.filter_fallback,
                   :adjPositions => AutumnStandardLibrary.adjPositions,
                   :isWithinBounds => AutumnStandardLibrary.isWithinBounds,
                   :isFree => AutumnStandardLibrary.isFree, 
                   :rect => AutumnStandardLibrary.rect, 
                   :unitVector => AutumnStandardLibrary.unitVector, 
                   :displacement => AutumnStandardLibrary.displacement, 
                   :adjacent => AutumnStandardLibrary.adjacent, 
                   :adjacentObjs => AutumnStandardLibrary.adjacentObjs, 
                   :adjacentObjsDiag => AutumnStandardLibrary.adjacentObjsDiag,
                   :rotate => AutumnStandardLibrary.rotate, 
                   :rotateNoCollision => AutumnStandardLibrary.rotateNoCollision, 
                   :move => AutumnStandardLibrary.move, 
                   :moveLeft => AutumnStandardLibrary.moveLeft, 
                   :moveRight => AutumnStandardLibrary.moveRight, 
                   :moveUp => AutumnStandardLibrary.moveUp, 
                   :moveDown => AutumnStandardLibrary.moveDown, 
                   :moveNoCollision => AutumnStandardLibrary.moveNoCollision, 
                   :moveLeftNoCollision => AutumnStandardLibrary.moveLeftNoCollision, 
                   :moveRightNoCollision => AutumnStandardLibrary.moveRightNoCollision, 
                   :moveDownNoCollision => AutumnStandardLibrary.moveDownNoCollision, 
                   :moveUpNoCollision => AutumnStandardLibrary.moveUpNoCollision, 
                   :moveWrap => AutumnStandardLibrary.moveWrap, 
                   :moveLeftWrap => AutumnStandardLibrary.moveLeftWrap,
                   :moveRightWrap => AutumnStandardLibrary.moveRightWrap, 
                   :moveUpWrap => AutumnStandardLibrary.moveUpWrap, 
                   :moveDownWrap => AutumnStandardLibrary.moveDownWrap, 
                   :randomPositions => AutumnStandardLibrary.randomPositions, 
                   :distance => AutumnStandardLibrary.distance,
                   :closest => AutumnStandardLibrary.closest, 
                   :mapPositions => AutumnStandardLibrary.mapPositions, 
                   :allPositions => AutumnStandardLibrary.allPositions, 
                   :updateOrigin => AutumnStandardLibrary.updateOrigin, 
                   :updateAlive => AutumnStandardLibrary.updateAlive, 
                   :nextLiquid => AutumnStandardLibrary.nextLiquid, 
                   :nextSolid => AutumnStandardLibrary.nextSolid,
                   :unfold => AutumnStandardLibrary.unfold,
                   :prev => AutumnStandardLibrary.prev
                  )
islib(f) = f in keys(lib_to_func)

# library function handling 
function libapl(f, args, @nospecialize(Γ::NamedTuple))
  # println("libapl")
  # @show f 
  # @show args 

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
      # # println("CHECK HERE")
      # # @show f
      # # @show args
      # # @show keys(Γ.state)
      # @show args 
      lib_to_func[f](map(x -> interpret(x, Γ)[1], args)..., Γ.state), Γ    
    else
      if f == :updateObj 
        interpret_updateObj(args, Γ)
      else # f == :removeObj 
        interpret_removeObj(args, Γ)
      end
    end
  end
end

julia_lib_to_func = Dict(:get => get, 
                         :map => map,
                         :filter => filter,
                         :first => first,
                         :last => last,
                         :in => in, 
                         :intersect => intersect,
                         :length => length,)
isjulialib(f) = f in keys(julia_lib_to_func)

function julialibapl(f, args, @nospecialize(Γ::NamedTuple))
  # println("julialibapl")
  # @show f 
  # @show args 
  if !(f in [:map, :filter])
    julia_lib_to_func[f](args...), Γ
  elseif f == :map 
    interpret_julia_map(args, Γ)
  elseif f == :filter 
    interpret_julia_filter(args, Γ)
  end
end

function interpret(aex::AExpr, @nospecialize(Γ::NamedTuple))
  arr = [aex.head, aex.args...]
  # # # # println()
  # # # # println("Env:")
  # display(Γ)
  # # # # @show arr 
  # next(x) = interpret(x, Γ)
  isaexpr(x) = x isa AExpr
  t = MLStyle.@match arr begin
    [:if, c, t, e]                                              => let (v, Γ2) = interpret(c, Γ) 
                                                                       if v == true
                                                                         interpret(t, Γ2)
                                                                       else
                                                                         interpret(e, Γ2)
                                                                       end
                                                                   end
    [:assign, x, v::AExpr] && if v.head == :initnext end        => interpret_init_next(x, v, Γ)
    [:assign, x, v::Union{AExpr, Symbol}]                       => let (v2, Γ_) = interpret(v, Γ)
                                                                    # @show v 
                                                                    # @show x
                                                                     interpret(AExpr(:assign, x, v2), Γ_)
                                                                   end
    [:assign, x, v]                                             => (aex, update(Γ, x, v))
    [:list, args...]                                            => interpret_list(args, Γ)
    [:typedecl, args...]                                        => (aex, Γ)
    [:let, args...]                                             => interpret_let(args, Γ) 
    [:lambda, args...]                                          => (args, Γ)
    [:fn, args...]                                              => (args, Γ)
    [:call, f, arg1] && if isprim(f) end                        => let (new_arg, Γ2) = interpret(arg1, Γ)
                                                                     primapl(f, new_arg, Γ2)
                                                                   end
                                                                    
    [:call, f, arg1, arg2] && if isprim(f) end                  => let (new_arg1, Γ2) = interpret(arg1, Γ)
                                                                       (new_arg2, Γ2) = interpret(arg2, Γ2)
                                                                       primapl(f, new_arg1, new_arg2, Γ2)
                                                                   end
    [:call, f, args...] && if f == :prev && args != [:obj] end  => interpret(AExpr(:call, Symbol(string(f, uppercasefirst(string(args[1])))), :state), Γ)
    [:call, f, args...] && if islib(f) end                      => interpret_lib(f, args, Γ)
    [:call, f, args...] && if isjulialib(f) end                 => interpret_julia_lib(f, args, Γ)
    [:call, f, args...] && if f in keys(Γ[:object_types]) end   => interpret_object_call(f, args, Γ)
    [:call, f, args...]                                         => interpret_call(f, args, Γ)
     
    [:field, x, fieldname]                                      => interpret_field(x, fieldname, Γ)
    [:object, args...]                                          => interpret_object(args, Γ)
    [:on, args...]                                              => interpret_on(args, Γ)
    [args...]                                                   => error(string("Invalid AExpr Head: ", aex.head))
    _                                                           => error("Could not interpret $arr")
  end
  # # # # println("FINSIH", arr)
  # # # # @show(t)
  t
end

function interpret(x::Symbol, @nospecialize(Γ::NamedTuple))
  # @show keys(Γ)
  if x == Symbol("false")
    false, Γ
  elseif x == Symbol("true")
    true, Γ
  elseif x == :clicked 
    interpret(AExpr(:call, :occurred, :click), Γ)
  elseif x in keys(Γ[:object_types])
    x, Γ
  elseif x in keys(Γ)
    # @show eval(:($(Γ).$(x)))
    eval(:($(Γ).$(x))), Γ
  else
    error("Could not interpret $x")
  end
end

# if x is not an AExpr or a Symbol, it is just a value (return it)
function interpret(x, @nospecialize(Γ::NamedTuple))
  if x isa BigInt 
    (convert(Int, x), Γ)
  else
    (x, Γ)
  end
end 

function interpret_list(args, @nospecialize(Γ::NamedTuple))
  new_list = []
  for arg in args
    new_arg, Γ = interpret(arg, Γ)
    push!(new_list, new_arg)
  end
  new_list, Γ
end

function interpret_lib(f, args, @nospecialize(Γ::NamedTuple))
  # println("INTERPRET_LIB")
  # @show f 
  # @show args 
  new_args = []
  for arg in args 
    new_arg, Γ = interpret(arg, Γ)
    push!(new_args, new_arg)
  end
  # @show new_args
  libapl(f, new_args, Γ)
end

function interpret_julia_lib(f, args, @nospecialize(Γ::NamedTuple))
  # @show f 
  # @show args
  new_args = []
  for arg in args 
    # @show arg 
    new_arg, Γ = interpret(arg, Γ)
    # @show new_arg 
    # @show Γ
    push!(new_args, new_arg)
  end
  julialibapl(f, new_args, Γ)
end

function interpret_field(x, f, @nospecialize(Γ::NamedTuple))
  # # println("INTERPRET_FIELD")
  # # @show keys(Γ)
  # # @show x 
  # # @show f 
  val, Γ2 = interpret(x, Γ)
  if val isa NamedTuple 
    (val[f], Γ2)
  else
    (eval(:($(val).$(f))), Γ2)
  end
end

function interpret_let(args::AbstractArray, @nospecialize(Γ::NamedTuple))
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

function interpret_call(f, params, @nospecialize(Γ::NamedTuple))
  func, Γ = interpret(f, Γ)
  func_args = func[1]
  func_body = func[2]

  # construct environment 
  Γ2 = Γ
  if func_args isa AExpr 
    for i in 1:length(func_args.args)
      param_name = func_args.args[i]
      param_val, Γ2 = interpret(params[i], Γ2)
      Γ2 = update(Γ2, param_name, param_val)
    end
  elseif func_args isa Symbol
    param_name = func_args
    param_val, Γ2 = interpret(params[1], Γ2)
    Γ2 = update(Γ2, param_name, param_val)
  else
    error("Could not interpret $(func_args)")
  end
  # # # @show typeof(Γ2)
  # evaluate func_body in environment 
  v, Γ2 = interpret(func_body, Γ2)
  
  # return value and original environment, except with state updated 
  Γ = update(Γ, :state, update(Γ.state, :objectsCreated, Γ2.state.objectsCreated))
  # # # println("DONE")
  (v, Γ)
end

function interpret_object_call(f, args, @nospecialize(Γ::NamedTuple))
  # # # println("BEFORE")
  # # # @show Γ.state.objectsCreated 
  new_state = update(Γ.state, :objectsCreated, Γ.state.objectsCreated + 1)
  Γ = update(Γ, :state, new_state)

  origin, Γ = interpret(args[end], Γ)
  object_repr = (origin=origin, type=f, alive=true, changed=false, id=Γ.state.objectsCreated)

  Γ2 = Γ
  fields = Γ2.object_types[f][:fields]
  for i in 1:length(fields)
    field_name = fields[i].args[1]
    field_value, Γ2 = interpret(args[i], Γ2)
    object_repr = update(object_repr, field_name, field_value)
    Γ2 = update(Γ2, field_name, field_value)
  end

  render, Γ2 = interpret(Γ.object_types[f][:render], Γ2)
  render = render isa AbstractArray ? render : [render]
  object_repr = update(object_repr, :render, render)
  # # # println("AFTER")
  # # # @show Γ.state.objectsCreated 
  (object_repr, Γ)  
end

function interpret_init_next(var_name, var_val, @nospecialize(Γ::NamedTuple))
  # println("INTERPRET INIT NEXT")
  init_func = var_val.args[1]
  next_func = var_val.args[2]

  Γ2 = Γ
  if !(var_name in keys(Γ2)) # variable not initialized; use init clause
    # println("HELLO")
    # initialize var_name
    var_val, Γ2 = interpret(init_func, Γ2)
    Γ2 = update(Γ2, var_name, var_val)

    # construct history variable in state 
    new_state = update(Γ2.state, Symbol(string(var_name, "History")), Dict())
    Γ2 = update(Γ2, :state, new_state)

    # construct prev function 
    _, Γ2 = interpret(AExpr(:assign, Symbol(string(:prev, uppercasefirst(string(var_name)))), parseautumn("""(fn (state) (get (.. state $(string(var_name, "History"))) (- (.. state time) 1) -1))""")), Γ2) 

  elseif Γ.state.time > 0 # variable initialized; use next clause if simulation time > 0  
    # update var_val 
    var_val = Γ[var_name]
    if var_val isa Array 
      changed_val = filter(x -> x.changed, var_val) # values changed by on-clauses
      unchanged_val = filter(x -> !x.changed, var_val) # values unchanged by on-clauses; apply default behavior
      # # @show var_val 
      # # @show changed_val 
      # # @show unchanged_val
      # replace (prev var_name) or var_name with unchanged_val 
      modified_next_func = sub(next_func, AExpr(:call, :prev, var_name) => unchanged_val)
      modified_next_func = sub(modified_next_func, var_name => unchanged_val)
      # # println("HERE I AM ONCE AGAIN")
      # # @show Γ.state.objectsCreated
      default_val, Γ = interpret(modified_next_func, Γ)
      # # @show default_val 
      # # println("HERE I AM ONCE AGAIN 2")
      # # @show Γ.state.objectsCreated
      final_val = map(o -> update(o, :changed, false), filter(obj -> obj.alive, vcat(changed_val, default_val)))
    else # variable is not an array
      if var_name in keys(Γ[:on_clauses])
        events = Γ[:on_clauses][var_name]
      else
        events = []
      end
      changed = false 
      for e in events 
        v, Γ = interpret(e, Γ)
        if v == true 
          changed = true
        end
      end
      if !changed 
        final_val, Γ = interpret(next_func, Γ)
      else
        final_val = var_val
      end
    end
    Γ2 = update(Γ, var_name, final_val)
  end
  (AExpr(:assign, var_name, var_val), Γ2)
end

function interpret_object(args, @nospecialize(Γ::NamedTuple))
  object_name = args[1]
  object_fields = args[2:end-1]
  object_render = args[end]

  # construct object creation function 
  object_tuple = (render=object_render, fields=object_fields)
  Γ = update(Γ, :object_types, update(Γ[:object_types], object_name, object_tuple))
  (AExpr(:object, args...), Γ)
end

function interpret_on(args, @nospecialize(Γ::NamedTuple))
  # println("INTERPRET ON")
  event = args[1]
  update_ = args[2]
  # @show event 
  # @show update_
  Γ2 = Γ
  if Γ2.state.time == 0 
    if update_.head == :assign
      var_name = update_.args[1]
      if !(var_name in keys(Γ2[:on_clauses]))
        Γ2 = update(Γ2, :on_clauses, update(Γ2[:on_clauses], var_name, [event]))
      else
        Γ2 = update(Γ2, :on_clauses, update(Γ2[:on_clauses], var_name, vcat(event, Γ2[:on_clauses][var_name])))
      end
    elseif update_.head == :let 
      assignments = update_.args
      if length(assignments) > 0 
        if (assignments[end] isa AExpr) && (assignments[end].head == :assign)
          for a in assignments 
            var_name = a.args[1]
            if !(var_name in keys(Γ2[:on_clauses]))
              Γ2 = update(Γ2, :on_clauses, update(Γ2[:on_clauses], var_name, [event]))
            else
              Γ2 = update(Γ2, :on_clauses, update(Γ2[:on_clauses], var_name, vcat(event, Γ2[:on_clauses][var_name])))
            end
          end
        end
      end
    else
      error("Could not interpret $(update_)")
    end
  else
    # # println("ON CLAUSE")
    # # @show event 
    # # @show update_  
    # @show repr(event)
    e, Γ2 = interpret(event, Γ2) 
    # @show e 
    if e == true
      # # println("EVENT IS TRUE!") 
      ex, Γ2 = interpret(update_, Γ2)
    end
  end
  (AExpr(:on, args...), Γ2)
end

# evaluate updateObj on arguments that include functions 
function interpret_updateObj(args, @nospecialize(Γ::NamedTuple))
  # # println("MADE IT!")
  Γ2 = Γ
  numFunctionArgs = count(x -> x == true, map(arg -> (arg isa AbstractArray) && (length(arg) == 2) && (arg[1] isa AExpr || arg[1] isa Symbol) && (arg[2] isa AExpr || arg[2] isa Symbol), args))
  if numFunctionArgs == 1
    list, Γ2 = interpret(args[1], Γ2)
    map_func = args[2]

    # # @show list 
    # # @show map_func

    new_list = []
    for item in list 
      # # # println("PRE=PLS WORK")
      # # # @show Γ2.state.objectsCreated      
      new_item, Γ2 = interpret(AExpr(:call, map_func, item), Γ2)
      # # # println("PLS WORK")
      # # # @show Γ2.state.objectsCreated
      push!(new_list, new_item)
    end
    new_list, Γ2
  elseif numFunctionArgs == 2
    list, Γ2 = interpret(args[1], Γ2)
    map_func = args[2]
    filter_func = args[3]

    # # @show list 
    # # @show map_func


    new_list = []
    for item in list 
      pred, Γ2 = interpret(AExpr(:call, filter_func, item), Γ2)
      if pred == true 
        new_item, Γ2 = interpret(AExpr(:call, map_func, item), Γ2)
        push!(new_list, new_item)
      else
        push!(new_list, item)
      end
    end
    new_list, Γ2
  elseif numFunctionArgs == 0
    obj = args[1]
    field_string = args[2]
    new_value = args[3]
    new_obj = update(obj, Symbol(field_string), new_value)

    # update render 
    object_type = Γ[:object_types][obj.type]
    
    Γ3 = Γ2
    fields = object_type[:fields]
    for i in 1:length(fields)
      field_name = fields[i].args[1]
      field_value = new_obj[field_name]
      Γ3 = update(Γ3, field_name, field_value)
    end
  
    render, Γ3 = interpret(Γ.object_types[obj.type][:render], Γ3)
    render = render isa AbstractArray ? render : [render]
    new_obj = update(new_obj, :render, render)

    new_obj, Γ2
    # Γ2 = update(Γ2, :state, update(Γ2.state, :objectsCreated, Γ2.state.objectsCreated + 1))
  else
    error("Could not interpret updateObj")
  end
end

function interpret_removeObj(args, @nospecialize(Γ::NamedTuple))
  # @show args
  list, Γ = interpret(args[1], Γ)
  func = args[2]
  new_list = []
  for item in list
    pred, Γ = interpret(AExpr(:call, func, item), Γ) 
    if pred == false 
      push!(new_list, item)
    end
  end
  new_list, Γ
end

function interpret_julia_map(args, @nospecialize(Γ::NamedTuple))
  new_list = []
  map_func = args[1]
  list, Γ = interpret(args[2], Γ)
  for arg in list  
    new_arg, Γ = interpret(AExpr(:call, map_func, arg), Γ)
    push!(new_list, new_arg)
  end
  new_list, Γ
end

function interpret_julia_filter(args, @nospecialize(Γ::NamedTuple))
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