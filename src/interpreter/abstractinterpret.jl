module AbstractInterpret
using ..AExpressions: AExpr
using ..AutumnStandardLibrary 
export update_history_depths

function update_history_depths(aex::AExpr, Γ::Env)
  prev_aexs = findnodes(aex, :prev)
  for prev_aex in prev_aexs 
    if (length(prev_aex.args) > 2) && (prev_aex.args[end] isa Int || prev_aex.args[end] isa BigInt)
      var_name = prev_aex.args[2]
      depth = prev_aex.args[3]
      if depth > Γ.state.history_depths[var_name]
        Γ.state.history_depths[var_name] = depth
      end
    end
  end
  Γ
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

end