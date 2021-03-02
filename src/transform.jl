"Code transformations to Autumn programs"
module Transform
using ..AExpressions
using ..SubExpressions
# using ..Parameters
using ..Scope
using MLStyle
export sub, recursub
# using OmegaCore

"Non-terminal node in grammar"
abstract type NonTerminal end

struct Statement <: NonTerminal end
struct External <: NonTerminal end
struct Assignment <: NonTerminal end
struct TypeDeclaration <: NonTerminal end
struct VariableName <: NonTerminal end
struct ExistingVariableName <: NonTerminal end

# ## Values
struct ValueExpression <: NonTerminal end
struct Literal <: NonTerminal end
struct FunctionApp <: NonTerminal end
struct Lambda <: NonTerminal end
struct Let <: NonTerminal end
struct LetBindings <: NonTerminal end
struct LetBinding <: NonTerminal end

struct ArgumentList <: NonTerminal end

# ## Types
struct TypeExpression <: NonTerminal end
struct PrimitiveType <: NonTerminal end
struct CustomType <: NonTerminal end
struct FunctionType <: NonTerminal end

AExpressions.showstring(T::Q) where {Q <: NonTerminal} = "{$(Q.name.name)}"
Base.show(io::IO, nt::NonTerminal) = print(io, AExpressions.showstring(nt))

"`sub(ϕ, subexpr::SubExpr{<:Statement})`returns `parent` with subexpression subed"
function sub end

function sub(ϕ, subex::SubExpr, ::Statement)
  choice(ϕ, [External(), Assignment(), TypeDeclaration()])
end

function sub(ϕ, subex::SubExpr, ::External)
  AExpr(:external, TypeDeclaration())
end

# ## Types
function sub(ϕ, subex::SubExpr, ::TypeDeclaration)
  AExpr(:typedecl, VariableName(), TypeExpression())
end

function sub(ϕ, subex::SubExpr, ::TypeExpression)
  choice(ϕ, [PrimitiveType(), FunctionType()])
end

function sub(ϕ, subex::SubExpr, ::PrimitiveType)
  # FIXME: include all primitive types
  primtypes = [Int, Float64, Bool]
  choice(ϕ, primtypes)
end

function sub(ϕ, subex::SubExpr, ::FunctionType)
  AExpr(:functiontype, TypeExpression(), TypeExpression())
end

function sub(ϕ, subex::SubExpr, ::Assignment)
  # @show vars_in_scope(subex)
  AExpr(:assign, VariableName(), ValueExpression())
end

# FIXME: This is a finite set, is it enough?
const VARNAMES = 
  map(Symbol ∘ join,
      Iterators.product('a':'z', 'a':'z', 'a':'z'))[:]

function sub(ϕ, subex::SubExpr, ::VariableName)
  # Choose a variable name that is correct in this context
  # i.e., not already in scope 
  vars = vars_in_scope(subex)
  choice_ = choice(ϕ, setdiff(VARNAMES, vars))
end

function sub(φ, subex::SubExpr, ::ExistingVariableName)
  vars = vars_in_scope(subex)

  # If there are no variables to use then we have to backtrack
  # For the moment, we simply return the same node which essentially means do nothin
  if isempty(vars)
    ExistingVariableName()
  else
    choice(φ, vars)
  end
end

function sub(ϕ, subex::SubExpr, ::ValueExpression)
  choice(ϕ, [Literal(), FunctionApp(), Lambda(), Let(), ExistingVariableName()])
end

function sub(ϕ, subex::SubExpr, ::Lambda)
  AExpr(:fn, ArgumentList(), ValueExpression())
end

function sub(ϕ, subex::SubExpr, ::LetBindings)
  MAXARGS = 4
  nargs = choice(ϕ, 1:MAXARGS)
  args = [Assignment() for i = 1:nargs]
  AExpr(:letargs, args...)
end

function sub(ϕ, subex::SubExpr, ::Let)
  AExpr(:let, LetBindings(), ValueExpression())
end

function sub(ϕ, subex::SubExpr, ::ArgumentList)
  MAXARGS = 4
  nargs = choice(ϕ, 1:MAXARGS)
  args = [VariableName() for i = 1:nargs]
  AExpr(:args, args...)
end

function sub(ϕ, subex::SubExpr, ::FunctionApp)
  # TODO: Need type constraitns
  AExpr(:call, ValueExpression(), ValueExpression(), ValueExpression())
end

function sub(ϕ, subex::SubExpr, ::Literal)
  # FINISHME: Do type inference
  literaltype = Int
  choice(ϕ, literaltype)
end

function sub(ϕ, subex::SubExpr)
  aex = resolve(subex)
  MLStyle.@match aex begin
    # This will be doing dynamic dispatch, which will be slow
    Statement => sub(ϕ, subex, aex)
    # FIXME: well this must be wrong
  end
end

"all nonterminals in `aex`"
allnonterminals(aex) = 
  filter(x-> resolve(x) isa NonTerminal, subexprs(aex))

## Stopping functions

"Stop when the graph is too large"
stopwhenbig(subexpr; sizelimit = 100) = nnodes(subex) > sizelimit

"Returns a stop function that stops after `n` calls"
stopaftern(n) = (i = 1; (ϕ, subexpr) -> (i += 1; i > n))

"""
  `recursub(ϕ, aex::AExpr, stop`

Recursively fill `aex` until `stop`

# Arguments
- `ϕ`: parameter space (in Omega sense)
- `aex`: Autumn expression containing non-terminals
- `stop`: when `stop(ϕ, aex)` is true the procedure will stop and return `aex`
  stop takes a parameter ϕ so that an inference procedure can determine when to sotp

# Returns
AExpression which has some or all non-terminal nodes expanded

```
aex = AExpr(:program, Statement(), Statement(), Statement(), Statement())
ϕ = Phi()
recursub(ϕ, aex)
```
"""
function recursub(ϕ, aex::AExpr, stop = stopaftern(100))
  # FIXME, what if i want stop to have state
  # FIXME: account for fact that there is none
  while !stop(ϕ, aex)
    nts = allnonterminals(aex)      
    if isempty(nts)
      break
    else
      subex = choice(ϕ, nts)      # Choose a nonterminal
      newex = sub(ϕ, subex)       # find replacement for chosen NT
      aex = update(subex, newex)  # substiute replacement into aex
      # println("#### Done\n")
    end
  end
  aex
end

end
