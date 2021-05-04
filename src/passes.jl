module Passes

import MLStyle
using ..Autumn: AExpr

# "K Normalized expression"
# struct KExpr
  
# ends

const KExpr = AExpr

iskarg(x) = x isa Symbol || isconst(x)

function k_call(f, args)
  if any(map(!iskarg, args))
    args_ = map(kn, args)
    KExpr(:let, )
  else
    KExpr(f, args...)
  end
end

function kn_if(A, B, C)
  KExpr(:if, kn(A), kn(B), kn(C))
end

kn_initnext(E, I) = KExpr(:initnext, kn(E), kn(I))
kn_on(E, I) = KExpr(:initnext, kn(E), kn(I))
kn_assign(q, v) = KExpr(:assign, q, kn(V))

"""Normalize `aex` into normal form

knormalization defines every intermediate expression expression in a nested expression
(for instance `(x + 3)`` in `(x + 3) / 2` as an intermediate variable )
"""
# function knormalize(aex::AExpr)
#   MLStyle.@match aex begin
#     AExpr(:call, [f, args...)              => kn_call(f, args)
#     AExpr(:if, A, B, C)                   => kn_if(A, B, C)
#     AExpr(:initnext, I, N)                => kn_initnext(I, N)
#     AExpr(:on, E, I)                      => kn_initnext(E, I)
#     AExpr(:case, E, I)                    => kn_initnext(E, I)
#     AExpr(:assign, q::Symbol, val)        => kn_assign(q, val)
#     _                                     => Aex
#   end
# end

function knormalize end
const kn = knormalize
end