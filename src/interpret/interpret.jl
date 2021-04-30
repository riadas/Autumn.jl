"Autumn interpreter"
module Interpret

using ..Autumn: AExpr
using ..Passes: KExpr

export auinterpret

"""
`auinterpret(aex::AExpr, env, ext)`

# Inputs
- `aex` Autumn program
- `env`: Environment
- `ext`: External inputs

# Return type

"""
function auinterpret(aex::AExpr, env, ext)
  
end

"Produce an environment"
function start(kex::KExpr)
  ## So what shall we do?
  env = Env()
  # Go through all the statements
end

function step(kex::Expr, envs)
  
end


## Continuation functions

fps(max = 60) = ..

""""
Interpret program until `stop`
"""
function auinterpret(kex::KExpr, exts, dontstop)
  env = start(kex)
  while dontstop()
    env_ = merge(env, exts)
    env = step(kex, exts)
  end
end

auinterpret(prog::AExpr, args...) = auinterpret(knormalize(prog), args...)

function trace(kex::KExpr, exts, dontstop)
end

end