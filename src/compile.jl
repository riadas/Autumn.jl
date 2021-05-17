"Compilation to Julia"
module Compile

using ..AExpressions, ..CompileUtils, ..SExpr
import MacroTools: striplines
import ..Autumn  # this is because autumn is not defined relative to this module

export compiletojulia, runprogram, compiletosketch, AULIBPATH

const AULIBPATH = joinpath(dirname(pathof(Autumn)), "..", "lib")

# Return an AExpr where all includes have been replaced with the code that it points to
function sub_includes(aexpr::AExpr)
  # this is a short-circuit or, so then it would only compute error when the first statement is false
  aexpr.head == :program || error("Expects program Aexpr")

  # copy and paste the include source file into our actual autumn file
  newargs = []
  for child in aexpr.args
    if typeof(child) == AExpr && child.head == :include
      path = child.args[1]
      # TODO we don't want to have duplicated code
      includedcode = preprocess(parsefromfile(path)) # Get the source code
      append!(newargs, includedcode.args)  # we wouldn't be including a program because we have the args
    else
      push!(newargs, child)
    end
  end
  AExpr(:program, newargs...)
end
# Return an AExpr where all includes have been replaced with the code that it points to
# function sub_includes(aexpr::AExpr, already_included=Set{String}()::Set{String})
#     # this is a short-circuit or, so then it would only compute error when the first statement is false
#   aexpr.head == :program || error("Expects program Aexpr")
#   # copy and paste the include source file into our actual autumn file
#   newargs = []
#   for child in aexpr.args
#     if child.head == :include
#       # TODO
#       # file a
#       # file b includes a (uses the local path)
#       # file c includes a (uses the global path)
#       # something that is more robust than the path
#       path = child.args[1]
#       if path in already_included
#         continue
#       end
#       # TODO use AULIBPATH
#       push!(already_included, path)
#       # TODO we don't want to have duplicated code
#       includedcode = sub_includes(parsefromfile(path), already_included) # Get the source code
#       append!(newargs, includedcode.args)  # we wouldn't be including a program because we have the args
#     else
#       push!(newargs, child)
#     end
#   end
#   AExpr(:program, newargs...)
# end


function preprocess(aexpr::AExpr)
  aexpr = sub_includes(aexpr)
  sub_import(aexpr)
end

"""
Finds all the import statements. Imports modules by name.

We name the file of the module such that the name of Module = filename

Files are located in the lib folder
"""
function sub_import(aexpr::AExpr, already_included=Set{String}()::Set{String})
  # this is a short-circuit or, so then it would only compute error when the first statement is false
  aexpr.head == :program || error("Expects program or module AExpr")

  # copy and paste the include source file into our actual autumn file
  newargs = []
  for child in aexpr.args
    if child.head == :import
      modulename = child.args[1]
      if modulename in already_included
        continue
      end
      push!(already_included, string(modulename))
      
      modulepath = joinpath(AULIBPATH, string(modulename) * ".au")
      # assume for now that modules cannot import other modules or include other code
      # includedcode = sub_import(parsefromfile(modulepath), already_included) # Get the source code
      includedcode = parsefromfile(modulepath)
      append!(newargs, includedcode.args[2:end])  # don't include first arg b/c it's the module name
    else
      push!(newargs, child)
    end
  end
  AExpr(:program, newargs...)
end

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

  historydata = Dict([("external" => []),  # no built-in external variables
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
                   vcat(lines, statestruct, initstatestruct, prevfunctions, initnextfunctions))  # do not automatically include builtinfunctions

    # construct module
    expr = quote
      module CompiledProgram
        export init, next
        import Base.min
        using Distributions
        # using MLStyle: @match
        using Random
        using Autumn.AutumnBase
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