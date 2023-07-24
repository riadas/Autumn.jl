"Autum Expressions"
module AExpressions

using MLStyle
export AExpr

export istypesymbol,
       istypevarsymbol,
       args,
       arg,
       wrap,
       showstring,
       AutumnError

"Autumn Error"
struct AutumnError <: Exception
  msg
end
AutumnError() = AutumnError("")

const autumngrammar = """
x           := a | b | ... | aa ...
program     := statement*
statement   := externaldecl | assignexpr | typedecl | typedef

typedef     := type fields  #FIXME
typealias   := "type alias" type fields
fields      := field | fields field
field       := constructor | constructor typesymbol*
cosntructor := typesymbol

typedecl    := x : typeexpr
externaldecl:= external typedecl

assignexpr  := x = valueexpr

typeexpr    := typesymbol | paramtype | typevar | functiontype
funtype     := typeexpr -> typeexpr
producttype := typeexpr × typexexpr × ...
typesymbol  := primtype | customtype
primtype    := Int | Bool | Float
customtype  := A | B | ... | Aa | ...

valueexpr   := fappexpr | lambdaexpr | iteexpr | initnextexpr | letexpr |
               this | lambdaexpr
iteexpr     := if expr then expr else expr
intextexpr  := init expr next expr
fappexpr    := valueexpr valueexpr*
letexpr     := let x = valueexpr in valueexpr
lambdaexpr  := x --> expr
"""

"Autumn Expression"
struct AExpr
  head::Symbol
  args::Vector{Any}
  AExpr(head::Symbol, @nospecialize args...) = new(head, collect(args))
  AExpr(head::Symbol, args::Vector{Any}) = new(head, args)
end
"Arguements of expression"
function args end

args(aex::AExpr) = aex.args
head(aex::AExpr) = aex.head
args(ex::Expr) = ex.args

"Expr in ith location in arg"
arg(aex, i) = args(aex)[i]

Base.Expr(aex::AExpr) = Expr(aex.head, aex.args...)

# wrap(expr::Expr) = AExpr(expr)
# wrap(x) = x

# AExpr(xs...) = AExpr(Expr(xs...))

# function Base.getproperty(aexpr::AExpr, name::Symbol)
#   expr = getfield(aexpr, :expr)
#   if name == :expr
#     expr
#   elseif name == :head
#     expr.head
#   elseif name == :args
#     expr.args
#   else
#     error("no property $name of AExpr")
#   end
# end


# Expression types
"Is `sym` a type symbol"
istypesymbol(sym) = (q = string(sym); length(q) > 0 && isuppercase(q[1]))
istypevarsymbol(sym) = (q = string(sym); length(q) > 0 && islowercase(q[1]))

# ## Printing
isinfix(f::Symbol) = f ∈ [:+, :-, :/, :*, :&&, :||, :>=, :<=, :>, :<, :(==)]
isinfix(f) = false


"Pretty print"
function showstring(aexpr::AExpr)
  # repr(expr)
  expr = Expr(aexpr)
  @match expr begin
    Expr(:program, statements...) => "(program\n$(join(map(s -> showstring(s), statements), "\n")))"
    Expr(:typedecl, x, val) => "(: $(x) $(showstring(val)))"
    Expr(:assign, x, val) => "(= $(x) $(showstring(val)))"
    Expr(:if, i, t, e) => "(if $(showstring(i)) then $(showstring(t)) else $(showstring(e)))"
    Expr(:initnext, i, n) => "(initnext $(showstring(i)) $(showstring(n)))"
    Expr(:call, f, args...) => "($(showstring(f)) $(join(map(a -> showstring(a), args), " ")))"
    Expr(:let, vars...) => "(let ($(join(map(showstring, vars), " "))))"
    Expr(:fn, params, body) => "(fn ($(join(map(p -> showstring(p), params), " "))) $(showstring(body)))"
    Expr(:list, vals...) => "(list $(join(map(x -> showstring(x), vals), " ")))"
    Expr(:field, var, field) => "(.. $(showstring(var)) $(showstring(field)))"
    Expr(:lambda, var, val) => "(--> $(showstring(var)) $(showstring(val)))"
    Expr(:object, name, args...) => "(object $(showstring(name)) $(join(map(showstring, args), " ")))"
    Expr(:on, event, upd) => "(on $(showstring(event)) $(showstring(upd)))"
    Expr(:deriv, x, val) => "(deriv $(showstring(x)) $(showstring(val)))"
    Expr(:in, x, args...) => "(in $(showstring(x)) $(showstring(args...)))"
    Expr(:runner, x) => "(runner $(showstring(x)))"
    Expr(:run, x) => "(run $(showstring(x)))"
    x                       => "Fail $x"
  end
end

showstring(lst::Array{}) = "($(join(map(showstring, lst), " ")))"
showstring(str::String) = "\"$(str)\""

# function needequals(val)
#   if typeof(val) == Expr && val.head == :fn
#     ""
#    else
#     "="
#   end
# end

showstring(s::Union{Symbol, Integer}) = s
showstring(s::Type{T}) where {T <: Number} = s
Base.show(io::IO, aexpr::AExpr) = print(io, showstring(aexpr))

end
