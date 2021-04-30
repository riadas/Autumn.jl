"Compilation to Julia"
module Compile

using ..AExpressions, ..CompileUtils, ..SExpr
import MacroTools: striplines
import ..Autumn

export compiletojulia, runprogram, compiletosketch, AULIBPATH

const AULIBPATH = joinpath(dirname(pathof(Autumn)), "..", "lib")

# Return an AExpr where all includes have been replaced with the code that it points to
function sub_includes(aexpr::AExpr)
  aexpr.head == :program || error("Expects program Aexpr")

  newargs = []
  for child in aexpr.args
    if child.head == :include
      path = child.args[1]
      includedcode = sub_includes(parsefromfile(path)) # Get the source code
      append!(newargs, includedcode.args)
    else
      push!(newargs, child)
    end
  end
  AExpr(:program, newargs...)
end

preprocess(aexpr::AExpr) = sub_includes(aexpr)

"Produces `AExpr` from Autumn code at `path`"
function parsefromfile(path)
  progstring = open(path, "r") do io
    read(io, String)
  end
  parseautumn(progstring) 
end

"compile `aexpr` into Expr"
function compiletojulia(aexpr_::AExpr)::Expr
  aexpr = preprocess(aexpr_)
  # dictionary containing types/definitions of global variables, for use in constructing init func.,
  # next func., etcetera; the three categories of global variable are external, initnext, and lifted  
  historydata = Dict([("external" => [au"""(external (: click Click))""".args[1], au"""(external (: left KeyPress))""".args[1], au"""(external (: right KeyPress))""".args[1], au"""(external (: up KeyPress))""".args[1], au"""(external (: down KeyPress))""".args[1]]), # :typedecl aexprs for all external variables
               ("initnext" => []), # :assign aexprs for all initnext variables
               ("lifted" => []), # :assign aexprs for all lifted variables
               ("types" => Dict{Symbol, Any}([:click => :Click, :left => :KeyPress, :right => :KeyPress, :up => :KeyPress, :down => :KeyPress, :GRID_SIZE => :Int, :background => :String])), # map of global variable names (symbols) to types
               ("on" => []),
               ("objects" => [])]) 
               
  if (aexpr.head == :program)
    # handle AExpression lines
    lines = filter(x -> x !== :(), map(arg -> compile(arg, historydata, aexpr), aexpr.args))
    
    # construct STATE struct and initialize state::STATE
    statestruct = compilestatestruct(historydata)
    initstatestruct = compileinitstate(historydata)
    
    # handle init, next, prev, and built-in functions
    initnextfunctions = compileinitnext(historydata)
    prevfunctions = compileprevfuncs(historydata)
    builtinfunctions = compilebuiltin()

    # remove empty lines
    lines = filter(x -> x != :(), 
            vcat(builtinfunctions, lines, statestruct, initstatestruct, prevfunctions, initnextfunctions))

    # construct module
    expr = quote
      module CompiledProgram
        export init, next
        import Base.min
        using Distributions
        using MLStyle: @match
        using Random
        rng = Random.GLOBAL_RNG
        $(lines...)
      end
    end  
    expr.head = :toplevel
    striplines(expr) 
  else
    throw(AutumnError("AExpr Head != :program"))
  end
end

"Run `prog` for finite number of time steps"
function runprogram(prog::Expr, n::Int)
  mod = eval(prog)
  state = mod.init(mod.Click(5, 5))

  for i in 1:n
    externals = [nothing, mod.Click(rand([1:10;]), rand([1:10;]))]
    state = mod.next(mod.next(state, externals[rand(Categorical([0.7, 0.3]))]))
  end
  state
end

end