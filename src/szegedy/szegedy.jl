export
   AbstractSzegedy,
   Szegedy,
   sqrtstochastic

"""
    AbstractSzegedy

Abstract Szegedy model. Description of the default parameter can be found in
https://arxiv.org/abs/1611.02238, where two oracle operator case is chosen.
Default representation of `AbstractSzegedy` is `Szegedy`.
"""
abstract type AbstractSzegedy <: QWModelDiscr end

"""
    Szegedy(graph::AbstractGraph, sqrtstochastic::SparseMatrixCSC{Real})

 Default representation of `AbstractSzegedy`. `sqrtstochastic` needs to be an
 element-wise square root of stochastic matrix.
"""
struct Szegedy{G<:AbstractGraph, T<:Number} <: AbstractSzegedy
   graph::G
   sqrtstochastic::SparseMatrixCSC{T,Int}

   function Szegedy{G, T}(graph::G,
                          sqrtstochastic::SparseMatrixCSC{T}) where {G<:AbstractGraph, T<:Number}
      new{G, T}(graph, sqrtstochastic)
   end

end

"""
    Szegedy(graph::AbstractGraph[, stochastic::SparseMatrixCSC{Real}, checkstochastic::Bool])

 Constructors of `AbstractSzegedy`. `stochastic` needs to be a stochastic
 matrix. Flag `checkstochastic` decides about checking the stochastic properties.

 Matrix `stochastic` defaults to the uniform walk operator, and
 `checkstochastic` deafults to `false` in case of default `stochastic`. If
 matrix `stochastic` is provided by the user, the default value of `stochastic`
 is `true`.
"""
function Szegedy(graph::G,
                 stochastic::SparseMatrixCSC{T},
                 checkstochastic::Bool=true) where {G<:AbstractGraph, T<:Number}
   if checkstochastic
      graphstochasticcheck(graph, stochastic)
   end
   Szegedy{G, T}(graph, sqrt.(stochastic))
end,

function Szegedy(graph::AbstractGraph)
   Szegedy(graph, default_stochastic(graph), false)
end

"""
    sqrtstochastic(szegedy::AbstractSzegedy)

Returns the `sqrtstochastic` element of `szegedy`.
"""
sqrtstochastic(szegedy::AbstractSzegedy) = szegedy.sqrtstochastic

"""
    QWSearch(szegedy::AbstractSzegedy, marked::Vector{Int}[, penalty::Real])

Creates `QWSearch` according to `AbstractSzegedy` model. By default parameter
`penalty` is set to 0. Evolution operators are constructed according to the
definition from https://arxiv.org/abs/1611.02238.

    QWSearch(qws::QWSearch[; marked::Vector{Int}, penalty::Real])

Update quantum walk search to new subset of marked elements and new penalty. By
default `marked` and `penalty` are the same as in `qws`.
"""
function QWSearch(szegedy::AbstractSzegedy,
                  marked::Vector{Int},
                  penalty::Real=0)
   r1, r2 = szegedy_walk_operators(szegedy)
   q1, q2 = szegedyoracleoperators(szegedy, marked)
   parameters = Dict{Symbol,Any}()
   parameters[:operators] = [r1*q1, r2*q2]

   QWSearch(szegedy, parameters, marked, penalty)
end

function QWSearch(qws::QWSearch{<:Szegedy};
                  marked::Vector{Int}=qws.marked,
                  penalty::Real=qws.penalty)
   oldmarked = qws.marked
   local corr_oracles
   if Set(marked) != Set(oldmarked)
    corr_oracles = szegedyoracleoperators(model(qws), oldmarked) .*
                   szegedyoracleoperators(model(qws), marked)
   else
      corr_oracles = speye.(parameters(qws)[:operators])
   end
   QWSearch(model(qws),
            Dict(:operators => parameters(qws)[:operators].*corr_oracles),
            marked,
            penalty)
end

"""
    QWEvolution(szegedy::AbstractSzegedy)

Create `QWEvolution` according to `AbstractSzegedy` model. By default, the
constructed operator is of type `SparseMatrixCSC`.
"""
function QWEvolution(szegedy::AbstractSzegedy)
   parameters = Dict{Symbol,Any}(:operators => szegedy_walk_operators(szegedy))

   QWEvolution(szegedy, parameters)
end

"""
    check_szegedy(szegedy::AbstractSzegedy, parameters::Dict{Symbol})

Private function for checking the existance of `:operators`, its type, and the
dimensionality of its elements.
"""
function check_szegedy(szegedy::AbstractSzegedy,
                       parameters::Dict{Symbol})
   @assert :operators in keys(parameters) "Parameters should contain key operators"
   @assert all(typeof(i) <: SparseMatrixCSC{<:Number} for i=parameters[:operators]) "Parameters should be a list of SparseMatrixCSC{<:Number}"
   order = nv(szegedy.graph)
   @assert all(size(i) == (order, order).^2 for i=parameters[:operators]) "Operators sizes mismatch"
end

"""
    check_qwdynamics(QWSearch, szegedy::AbstractSzegedy, marked::Vector{Int}, parameters::Dict{Symbol})

Check whetver combination of `szegedy`, `marked` and `parameters` produces valid
`QWSearch` object. It checks where `parameters` consists of key `:operators` with
corresponding value being list of `SparseMatrixCSC`. Furthermore operators
needs to be square of size equals to square of `graph(szegedy).` order.
"""
function check_qwdynamics(::Type{QWSearch},
                          szegedy::AbstractSzegedy,
                          parameters::Dict{Symbol},
                          marked::Vector{Int})
   check_szegedy(szegedy, parameters)
end

"""
    check_qwdynamics(QWEvolution, szegedy::AbstractSzegedy, parameters::Dict{Symbol})

Check whetver combination of `szegedy`, and `parameters` produces a
valid `QWEvolution` object. It checks where `parameters` consists of key
`:operators` with corresponding value being a list of `SparseMatrixCSC` objects.
Furthermore operators need to be square of size equals to square of the order of
`graph(szegedy)`.
"""
function check_qwdynamics(::Type{QWEvolution},
                          szegedy::AbstractSzegedy,
                          parameters::Dict{Symbol})
   check_szegedy(szegedy, parameters)
end

include("szegedy_stochastic.jl")
include("szegedy_operators.jl")
include("szegedy_evolution.jl")
