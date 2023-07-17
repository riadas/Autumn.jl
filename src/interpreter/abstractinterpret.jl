module AbstractInterpret
using ..AExpressions: AExpr
using ..AutumnStandardLibrary 
using MLStyle
export findnodes, identify_constants, compute_depth_bound, sub_depth

function identify_constants(aex::AExpr, Γ::Env)
  constant_variables = deepcopy(Γ.current_var_values)
  for line in aex.args 
    assign_aexpr = line.args[2]
    
    if assign_aexpr.head == :let 
      assignments = assign_aexpr.args
    else 
      assignments = [assign_aexpr]
    end

    for a in assignments 
      var_name, val_expr = a.args
      if repr(val_expr) != "(prev $(var_name))" # TODO: write a better equality check
        delete!(constant_variables, var_name)        
      end
    end

  end
  constant_variables
end

function compute_depth_bound(aex::AExpr, constant_variables, Γ) 
  if aex.head == :call && aex.args[1] == :uniformChoice 
    return Inf
  end

  for arg in aex.args 
    bound = compute_depth_bound(arg, constant_variables, Γ)
    if bound == Inf 
      return bound
    end
  end
  0
end

function compute_depth_bound(aex::Symbol, constant_variables, Γ) 
  if aex in keys(constant_variables) || (aex in (:+, :-, :*, :/, :&, :!, :|, :>, :>=, :<, :<=, :(==), :%, :!=,))
    0    
  else
    Inf
  end 
end

function compute_depth_bound(aex, constant_variables, Γ) 
  aex
end

function sub_depth(aex::AExpr, prev_aex::AExpr, depth::Int)
  sub(aex, (prev_aex, AExpr(:call, [:prev, prev_aex.args[2], depth])))
end

function findnodes(aex::AExpr, subaex::Symbol)
  solutions = Set()
  _ = findnodes(aex, subaex, nothing, solutions)
  solutions
end

function findnodes(aex::AExpr, subaex::Symbol, parent::Union{Nothing, AExpr}, solutions::Set)
  for i in 1:length(aex.args)
    _ = findnodes(aex.args[i], subaex, aex, solutions)
  end
end

function findnodes(aex, subaex::Symbol, parent::Union{Nothing, AExpr}, solutions::Set)
  if aex == subaex
    push!(solutions, parent)
  end
end

function sub(aex::AExpr, (x, v))
  arr = [aex.head, aex.args...]
  if (x isa AExpr) && ([x.head, x.args...] == arr)  
    v 
  else
    MLStyle.@match arr begin
      [:program, lines...]                                    => AExpr(:program, map(l -> sub(l, (x, v)), lines)...)
      [:fn, args, body]                                       => AExpr(:fn, args, sub(body, x => v))
      [:if, c, t, e]                                          => AExpr(:if, sub(c, x => v), sub(t, x => v), sub(e, x => v))
      [:assign, a1, a2]                                       => AExpr(:assign, a1, sub(a2, x => v))
      [:list, args...]                                        => AExpr(:list, map(arg -> sub(arg, x => v), args)...)
      [:typedecl, args...]                                    => AExpr(:typedecl, args...)
      [:let, args...]                                         => AExpr(:let, map(arg -> sub(arg, x => v), args)...)      
      [:lambda, args, body]                                   => AExpr(:fn, args, sub(body, x => v))
      [:call, f, args...]                                     => AExpr(:call, f, map(arg -> sub(arg, x => v) , args)...)      
      [:field, o, fieldname]                                  => AExpr(:field, sub(o, x => v), fieldname)
      [:object, args...]                                      => AExpr(:object, args...)
      [:on, event, update]                                    => AExpr(:on, sub(event, x => v), sub(update, x => v))
      [args...]                                               => throw(error(string("Invalid AExpr Head: ", aex.head)))
      _                                                       => error("Could not sub $arr")
    end
  end
end

sub(aex::Symbol, (x, v)) = aex == x ? v : aex
sub(aex, (x, v)) = aex # aex is a value

end