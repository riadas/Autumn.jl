module Scope
using ..SubExpressions
using ..AExpressions
using MLStyle

export vars_in_scope

"""
`vars_in_scope(subex::SubExpr)`

Variables in scope at `subex`

```
prog = au\"\"\"(program
                 (= x 3)
                 (= d (let ((= a 3) (= b 4)) (+ a b)))
                 (= y (fn (a b c) (+)))
                 (= z (fn (q t) (+ q t))))
              \"\"\"

subex1 = subexpr(prog, [2, 2, 3])
subex2 = subexpr(prog, [1, 2])
vars_in_scope(subex1)
```

"""
function vars_in_scope(subex::SubExpr)
  reduce(subexprs(subex.aex); init = Symbol[]) do accum, subex_ 
    vcat(accum, projected_vars(subex_, subex))
  end
end

## Function scope
"Variables projected from `subexa` to `subexb`"
function projected_vars(subexa::SubExpr, subexb::SubExpr)
  inletscope() = 
    parent(subexa).head == :letargs && ((subexb ∈ descendents(args(parent(subexa, 2), 2))) || (subexb ∈ youngersiblings(subexa)))

  # Matches
  # AExpr(:fn, AExpr(:list, ..., x, ...), ...)
  isfuncarg(subex) = (parent(subex).head == :list) && (parent(subex, 2).head == :fn) && (pos(parent(subex)) == 1)
  infnscope(subexa, subexb) = isfuncarg(subexa) && (isyoungersibling(subexb, subexa) || subexb ∈ descendents(args(parent(subexa, 2), 2)))

  # Global assignments
  # AExpr(:program, ...)
  isglobalassign(subex) = (parent(subex).head == :program)
  inglobalscope(subexa, subexb) = isglobalassign(subexa) && subexb ∈ Iterators.flatten((descendents(sib) for sib in youngersiblings(subexa)))

  # external


  # case expressions

  aex = resolve(subexa)
  ex = aex isa AExpr ? Expr(aex) : aex
  MLStyle.@match ex begin
    Expr(:assign, q::Symbol, val) && if inletscope() end                 => Symbol[q]
    Expr(:assign, q::Symbol, val) && if inglobalscope(subexa, subexb) end => Symbol[q]
    # Expr(:external, Expr(:typedecl, q::Symbol, _))                       => Symbol[q]
    # Expr(:external, typedecl)                                            => Symbol[typedecl.args[1]]
    # Expr(:casevalue)
    fnarg::Symbol && if infnscope(subexa, subexb) end                    => Symbol[fnarg]
    _                                                                    => Symbol[]
  end
end

end