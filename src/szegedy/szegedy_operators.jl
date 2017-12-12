function proj(v::SparseVector{T}) where T<:Number
   SparseMatrixCSC{T}(v*v')
end

function proj(v::AbstractVector{T}) where T<:Number
   v*v'
end

"""


"""
function szegedywalkoperators(szegedy::Szegedy{G,S}) where {G,S<:Real}
   order = nv(szegedy.graph)
   projectors = [2.*proj(szegedy.sqrtstochastic[:,v]) for v=1:order]

   r1 = cat([1, 2], projectors...)::SparseMatrixCSC{S,Int}

   r2 = spzeros(S, order^2, order^2)
   for x=1:order
      r2[(1:order:order^2)+x-1,(1:order:order^2)+x-1] = projectors[x]
   end

   r1 -= speye(r1)
   r2 -= speye(r2)

   (r1, r2)
end

function szegedywalkoperators(szegedy::T where T<:AbstractSzegedy)
   order = nv(szegedy.graph)
   projectors = map(x->2.*proj(szegedy.sqrtstochastic[:,x]), 1:order)


   r1 = cat([1, 2], projectors...)

   r2 = spzeros(eltype(szegedy.sqrtstochastic), order^2, order^2)
   for x=1:order
      r2[(1:order:order^2)+x-1,(1:order:order^2)+x-1] = projectors[x]
   end

   r1 -= speye(r1)
   r2 -= speye(r2)

   (r1, r2)
end

function szegedyoracleoperators(szegedy::T where T<:AbstractSzegedy,
                                marked::Vector{Int})
   order = nv(szegedy.graph)

   markedidentity = speye(eltype(szegedy.sqrtstochastic), order)
   for v=marked
      markedidentity[v,v] = -1.
   end

   q1 = kron(markedidentity, speye(order))
   q2 = kron(speye(order), markedidentity)

   (q1, q2)
end
