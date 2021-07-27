module Interpret
using Base: Integer, Bool
using ..AExpressions: AExpr
export empty_env, Environment, interpret, init_interpret, std_env
import MLStyle

const Environment = NamedTuple
empty_env() = NamedTuple()
std_env() = empty_env()

"Produces new environment Γ' s.t. `Γ(x) = v` (and everything else unchanged)"
update(Γ, x::Symbol, v) = merge(Γ, NamedTuple{(x,)}((v,)))

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

# function fn_arg(aex::AExpr)
#   arr = [aex.head, aex.args...]
#   MLStyle.@match arr begin
#     [:fn, arg, body]                                       => arg
#     _                                                      => error("Could find body of $arr")
#   end
# end

# function fn_body(aex::AExpr)
#   arr = [aex.head, aex.args...]
#   MLStyle.@match arr begin
#     [:fn, arg, body]                                       => body
#     _                                                      => error("Could find body of $arr")
#   end
# end

# "substitute x for v within expr"
# function sub(aex::AExpr, (x, v))
#   # print("SUb")
#   # @show aex
#   # @show x
#   # @show v
#   arr = [aex.head, aex.args...]
#   # next(x) = interpret(x, Γ)
#   isaexpr(x) = x isa AExpr
#   MLStyle.@match arr begin
#     [:fn, args, body]                                       => AExpr(:fn, args, sub(body, x => v))
#     [:call, f, arg1] && if isprim(f) end                    => AExpr(:call, f, sub(arg1, x => v))
#     [:call, f, arg1, arg2] && if isprim(f) end              => AExpr(:call, f, sub(arg1, x => v),  sub(arg2, x => v))
#     [:if, c, t, e]                                          => AExpr(:if, sub(c, x => v), sub(t, x => v), sub(e, x => v))
#     [:let, x, val, body] && if x ∉ keys(Γ) end              => AExpr(:let, x, val, sub(body, x => v))
#     [:call, t1, t2]                                         => AExpr(:call, sub(t1, x => v),  sub(t2, x => v))
#     _                                                       => error("Could not sub $arr")
#   end
# end

# sub(aex::Symbol, (x, v)) = aex == x ? v : aex
# sub(aex::Real, (x, v)) = aex

function interpret_let(args::AbstractArray, Γ::Environment)
  Γ2 = Γ
  for arg in args[1:end-1] 
    v2, Γ2 = interpret(arg, Γ2)
  end

  if args[end] isa AExpr 
    if args[end].head == :assign 
      v2, Γ2 = interpret(arg, Γ2)
      (aex, Γ2)
    else  
      v2, Γ2 = interpret(arg, Γ2)
      (v2, Γ)
    end
  else
    (args[end], Γ)
  end
end

function interpret_call(func_name, params, Γ::Environment)
  # update to handle library functions later (have them added to an environment/a library function environment)
  if func_name in keys(Γ)
    func = Γ[func_name]
    func_args = func[1]
    func_body = func[2]

    # construct environment 
    Γ2 = Γ
    if func_args isa AExpr 
      for i in 1:length(func_args.args)
        param_name = func_args.args[i]
        param_val = interpret(params[i], Γ)
        Γ2 = update(Γ2, param_name, param_val)
      end
    elseif func_args isa Symbol
      param_name = func_args
      param_val = interpret(params[1], Γ)
      Γ2 = update(Γ2, param_name, param_val)
    else
      error("Could not interpret $(func_args)")
    end
    
    # evaluate func_body in environment 
    v, Γ2 = interpret(func_body, Γ2)
    
    # return value and original environment
    v, Γ
  else
    error("Could not interpret $(func_name)")
  end
end

function interpret_init_next(var_name, var_val, Γ)
  init_func = var_val.args[1]
  next_func = var_val.args[2]

  if var_name in keys(Γ) # variable not initialized; use init clause
    # initialize var_name
    Γ2 = update(Γ, var_name, interpret(init_func, Γ)[1])

    # construct prev function 
    _, Γ2 = interpret(AExpr(:assign, [Symbol(string(:prev, uppercasefirst(string(var_name)))), parseautumn("""(fn () (.. oldEnvironment $(string(var_name))))""")]), Γ2) 

  else # variable initialized; use next clause 
    # update var_name 
    Γ2 = update(Γ, var_name, interpret(next_func, Γ)[1])
  end
  AExpr(:assign, [var_name, var_val]), Γ2
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
    [:list, args...]                                           => (AExpr(:list, map(arg -> interpret(arg, Γ)[1], args)), Γ) 
    [:typedecl, args...]                                       => (aex, Γ)
    [:let, args...]                                            => interpret_let(args, Γ)
    
    # [:case, args...] => compilecase(expr, data)
    # [:typealias, args...] => compiletypealias(expr, data)      
    [:lambda, args...]                                         => (aex.args, Γ)
    [:fn, args...]                                             => (aex.args, Γ)
    [:call, f, arg1] && if isprim(f) end                       => primapl(f, interpret(arg1, Γ)[1])
    [:call, f, arg1, arg2] && if isprim(f) end                 => primapl(f, interpret(arg1, Γ)[1], interpret(arg2, Γ)[1])
    [:call, f, args...]                                        => interpret_call(f, args, Γ)

    
    [:field, x, fieldname] => 
    [:object, args...] => compileobject(expr, data) # TODO
    [:on, args...] => compileon(expr, data) # TODO
    [args...] => throw(AutumnError(string("Invalid AExpr Head: ", expr.head)))
    _                                                          => error("Could not interpret $arr")
  end
  # println("FINSIH", arr)
  # @show(t)
  t
end

# canparse(t, x) = !isnothing(tryparse(t, x))

# function interpret(x::Symbol, Γ::Environment)
#   if x == Symbol("false")
#     false
#   elseif x == Symbol("true")
#     true
#   else
#     MLStyle.@match x begin
#       x::Symbol  && if x ∈ keys(Γ) end                        => interpret(Γ[x].expr, Γ[x].env)  # Var
#       x && if canparse(Float64, string(x)) end                => parse(Float64, string(x))
#       _                                                       => error("Could not interpret $x")
#     end
#   end
# end

function interpret_program(aex, Γ)
  aex.head == :program || error("Must be a program aex")
  for stmt in aex.args
    Γ = interpret_assign(stmt, Γ)
  end
  return Γ
end

# Interpret until termination
function interpret_terminate(aex, env)
  while !done(aex, env)
    aex, env = interpret(aex, env)
  end
  aex, env
end

function start(aex::AExpr)::Environment
  env = empty_env()
  aex_, env_ = interpret_terminate(aex, env)
  env_
end

function step(aex::AExpr, env::Environment)::Environment
  aex_, env_ = interpret_terminate(aex, env)
  env_
end

end