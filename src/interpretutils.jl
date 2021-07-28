module InterpretUtils
using ..AExpressions: AExpr
using ..SExpr
export interpret, interpret_let, interpret_call, interpret_init_next, interpret_object, interpret_object_call, interpret_on, Environment, empty_env, std_env, update, primapl, isprim, update
import MLStyle

function sub(aex::AExpr, (x, v))
  # print("SUb")
  # @show aex
  # @show x
  # @show v
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
      [:call, f, args...]                                     => AExpr(:call, f, map(arg -> sub(arb, x => v) , args)...)      
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
update(Γ, x::Symbol, v) = merge(Γ, NamedTuple{(x,)}((v,)))

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
                    :(==) => ==,)

isprim(f) = f in keys(prim_to_func)
primapl(f, x...) = prim_to_func[f](x...)

# function Position(x, y)
#   (x=x, y=y)
# end

# function Cell(x, y, color)
#   (x=x, y=y, color=color)
# end

struct Position 
  x::Int
  y::Int 
end

struct Cell 
  x::Int
  y::Int
  color::String 
end

lib_to_func = Dict(:Position => Position,
                   :Cell => Cell)
islib(f) = f in keys(lib_to_func)

# library function handling 
function libapl(f, args)
  lib_to_func[f](args...)
end

julia_lib_to_func = Dict(:get => get)
isjulialib(f) = f in keys(julia_lib_to_func)

function julialibapl(f, args)
  julia_lib_to_func[f](args...)
end

function interpret(aex::AExpr, Γ::Environment)
  arr = [aex.head, aex.args...]
  # println()
  # println("Env:")
  # display(Γ)
  # @show arr 
  # next(x) = interpret(x, Γ)
  isaexpr(x) = x isa AExpr
  t = MLStyle.@match arr begin
    [:if, c, t, e] && if interpret(c, Γ)[1] == true end        => interpret(t, Γ)
    [:if, c, t, e] && if interpret(c, Γ)[1] == false end       => interpret(e, Γ)
    [:assign, x, v::AExpr] && if v.head == :initnext end       => interpret_init_next(x, v, Γ)
    [:assign, x, v::Union{AExpr, Symbol}]                      => let (v2, Γ_) = interpret(v, Γ)
                                                                    interpret(AExpr(:assign, x, v2), Γ_)
                                                                  end
    [:assign, x, v]                                            => (aex, update(Γ, x, v))
    [:list, args...]                                           => (map(arg -> interpret(arg, Γ)[1], args), Γ) 
    [:typedecl, args...]                                       => (aex, Γ)
    [:let, args...]                                            => interpret_let(args, Γ) 
    [:lambda, args...]                                         => (args, Γ)
    [:fn, args...]                                             => (args, Γ)
    [:call, f, arg1] && if isprim(f) end                       => (primapl(f, interpret(arg1, Γ)[1]), Γ)
    [:call, f, arg1, arg2] && if isprim(f) end                 => (primapl(f, interpret(arg1, Γ)[1], interpret(arg2, Γ)[1]), Γ)
    [:call, f, args...] && if islib(f) end                     => (libapl(f, map(a -> interpret(a, Γ)[1], args)), Γ)
    [:call, f, args...] && if isjulialib(f) end                => (julialibapl(f, map(a -> interpret(a, Γ)[1], args)), Γ)
    [:call, f, args...] && if f == :prev end                   => interpret(AExpr(:call, Symbol(string(f, uppercasefirst(string(args[1])))), :state), Γ)
    [:call, f, args...] && if f in keys(Γ[:object_types]) end  => interpret_object_call(f, args, Γ)
    [:call, f, args...]                                        => interpret_call(f, args, Γ)

    
    [:field, x, fieldname]                                     => interpret_field(x, fieldname, Γ)
    [:object, args...]                                         => interpret_object(args, Γ)
    [:on, args...]                                             => interpret_on(args, Γ)
    [args...]                                                  => error(string("Invalid AExpr Head: ", aex.head))
    _                                                          => error("Could not interpret $arr")
  end
  # println("FINSIH", arr)
  # @show(t)
  t
end

function interpret(x::Symbol, Γ::Environment)
  if x == Symbol("false")
    false, Γ
  elseif x == Symbol("true")
    true, Γ
  else
    MLStyle.@match x begin
      x::Symbol  && if x ∈ keys(Γ) end                        => (Γ[x], Γ)  # Var
      _                                                       => error("Could not interpret $x")
    end
  end
end

# if x is not an AExpr or a Symbol, it is just a value (return it)
function interpret(x, Γ::Environment)
  (x, Γ)
end 

function interpret_field(x, f, Γ::Environment)
  val = interpret(x, Γ)[1]
  (val[f], Γ)
end

function interpret_let(args::AbstractArray, Γ::Environment)
  Γ2 = Γ
  for arg in args[1:end-1] # all lines in let except last
    v2, Γ2 = interpret(arg, Γ2)
  end

  if args[end] isa AExpr
    if args[end].head == :assign # all assignments are global; no return value 
      v2, Γ2 = interpret(arg, Γ2)
      (aex, Γ2)
    else # return value is AExpr   
      v2, Γ2 = interpret(arg, Γ2)
      (v2, Γ)
    end
  else # return value is not AExpr
    (interpret(args[end], Γ2)[1], Γ)
  end
end

function interpret_call(f, params, Γ::Environment)
  @show Γ.object_types
  func, _ = interpret(f, Γ)
  func_args = func[1]
  func_body = func[2]

  # construct environment 
  Γ2 = Γ
  if func_args isa AExpr 
    for i in 1:length(func_args.args)
      param_name = func_args.args[i]
      param_val = interpret(params[i], Γ)[1]
      Γ2 = update(Γ2, param_name, param_val)
    end
  elseif func_args isa Symbol
    param_name = func_args
    param_val = interpret(params[1], Γ)[1]
    Γ2 = update(Γ2, param_name, param_val)
  else
    error("Could not interpret $(func_args)")
  end
  
  # evaluate func_body in environment 
  v, Γ2 = interpret(func_body, Γ2)
  
  # return value and original environment
  (v, Γ)
end

function interpret_object_call(f, args, Γ)
  origin, _ = interpret(args[end], Γ)
  render, _ = interpret(Γ.object_types[f][:render], Γ)

  object_repr = (origin=origin, alive=true, changed=false, render=render, id=Γ.state.objectsCreated)

  new_state = update(Γ.state, :objectsCreated, Γ.state.objectsCreated + 1)
  Γ = update(Γ, :state, new_state)

  fields = Γ.object_types[f][:fields]
  for i in 1:length(fields)
    field_name = fields[i].args[1]
    field_value = interpret(args[i], Γ)[1] 
    object_repr = update(object_repr, field_name, field_value)
  end
  (object_repr, Γ)  
end

function interpret_init_next(var_name, var_val, Γ)
  init_func = var_val.args[1]
  next_func = var_val.args[2]

  Γ2 = Γ
  if !(var_name in keys(Γ2)) # variable not initialized; use init clause
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

      # replace (prev var_name) or var_name with unchanged_val 
      modified_next_func = sub(next_func, AExpr(:call, :prev, var_name) => unchanged_val)
      modified_next_func = sub(modified_next_func, var_name => unchanged_val)

      default_val = interpret(modified_next_func, Γ)[1]
      final_val = filter(obj -> obj.alive, vcat(changed_val, default_val))
    else # variable is not an array
      events = Γ[:on_clauses][var_name]
      changed = foldl(|, map(e -> interpret(e, Γ)[1], events), init=false)
      if !changed 
        final_val = interpret(next_func, Γ)[1]
      else
        final_val = var_val
      end
    end
    Γ2 = update(Γ, var_name, final_val)
  end
  (AExpr(:assign, var_name, var_val), Γ2)
end

function interpret_object(args, Γ)
  object_name = args[1]
  object_fields = args[2:end-1]
  object_render = args[end]

  # construct object creation function 
  object_tuple = (render=object_render, fields=object_fields)
  Γ = update(Γ, :object_types, update(Γ[:object_types], object_name, object_tuple))
  (AExpr(:object, args...), Γ)
end

function interpret_on(args, Γ)
  event = args[1]
  update_ = args[2]
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
    else
      error("Could not interpret $(update_)")
    end
  else
    if interpret(event, Γ2)[1] == true 
      ex, Γ2 = interpret(update_, Γ2)
    end
  end
  (AExpr(:on, args...), Γ2)
end

end