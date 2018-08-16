export
    QWSearch,
    marked,
    penalty,
    QSearchState,
    state,
    probability,
    runtime


"""
    QWSearch(model::QWModel, parameters::Dict{Symbol}, marked::Vector{Int}, penalty::Real)

Simulates quantum search on `model` with `marked` vertices and additional `parameters`.
`penalty` represents the cost of initial state creation and measurement, which should
be included for better optimization, see documentation of `maximizing_function`.
Note that marked vertices needs to be between `1` and `nv(graph(model))`. Furthermore
penalty needs to be nonnegative.

Needs implementation of
* `initial_state(qws::QWSearch)`
* `evolve(qws::QWSearch{<:QWModelDiscr}, state)` or `evolve(qws::QWSearch{<:QWModelCont}, state, time::Real)`
* `measure(qws::QWSearch, state[, vertices])`
* `check_qwdynamics(::QWSearch, parameters::Dict{Symbol})`
* proper constructors.

Offers functions
* `execute`
* `execute_single`
* `execute_single_measured`
* `execute_all`
* `execute_all_measured`
* `maximize_quantum_search`.

It is encoureged to implement constructor, which changes the `penalty` and/or `marked`
vertices, as their are usuallu simple to adapt.
"""
struct QWSearch{T,W<:Real} <: QWDynamics{T}
  model::T
  parameters::Dict{Symbol}
  marked::Vector{Int}
  penalty::W

  function QWSearch(model::T,
                    parameters::Dict{Symbol},
                    marked::Vector{Int},
                    penalty::W) where {T<:QWModel, W<:Real}
    @assert all(1 <= v <= nv(model.graph) for v=marked) && marked != [] "marked vertices needs to be non-empty subset of graph vertices set"
    @assert penalty >= 0 "Penalty needs to be nonnegative"

    check_qwdynamics(QWSearch, model, parameters, marked)
    new{T,W}(model, parameters, marked, penalty)
  end
end

"""
    marked(qws::QWSearch)

Returns `marked` vertices element of `qws`.
"""
marked(qws::QWSearch) = qws.marked

"""
    penalty(qws::QWSearch)

Returns `penalty` element of `qws`.
"""
penalty(qws::QWSearch) = qws.penalty


"""
    QSearchState(state, probability::Float64, runtime::Real)
    QSearchState(qws::QWSearch, state, runtime::Float64)

Creates container which consists of `state`, success probability `probability`
and running time `runtime`. Validity of `probability` and `runtime` is not checked.

In second case `state` is measured according to `qws`.

# Example
```jldoctest
julia> qws = QWSearch(Szegedy(CompleteGraph(4)), [1]);

julia> result = QSearchState(qws, initial_state(qws), 0)
QuantumWalk.QSearchState{SparseVector{Float64,Int64},Int64}(  [2 ]  =  0.288675
  [3 ]  =  0.288675
  [4 ]  =  0.288675
  [5 ]  =  0.288675
  [7 ]  =  0.288675
  [8 ]  =  0.288675
  [9 ]  =  0.288675
  [10]  =  0.288675
  [12]  =  0.288675
  [13]  =  0.288675
  [14]  =  0.288675
  [15]  =  0.288675, [0.25], 0)
```
"""
struct QSearchState{S,Y<:Real}
  state::S
  probability::Vector{Float64}
  runtime::Y

  function QSearchState(state::S,
                        probability::Vector{Float64},
                        runtime::Y) where {S,Y<:Real}
     new{S,Y}(state, probability, runtime)
  end
end

function QSearchState(qws::QWSearch, state, runtime::Real)
   QSearchState(state, measure(qws, state, qws.marked), runtime)
end

# Following for resolving method ambiguity error
function QSearchState(qws::QWSearch, state::Vector{Float64}, runtime::Real)
   QSearchState(state, measure(qws, state, qws.marked), runtime)
end

"""
    state(qsearchstate::QSearchState)

Returns the state of qsearchstate.
"""
state(qsearchstate::QSearchState) = qsearchstate.state

"""
    probability(qsearchstate::QSearchState)

Returns the list of probabilities of finding marked vertices.
"""
probability(qsearchstate::QSearchState) = qsearchstate.probability

"""
    runtime(qsearchstate::QSearchState)

Returns the time for which the state was calulated.
"""
runtime(qsearchstate::QSearchState) = qsearchstate.runtime


# documentation for
"""
    check_qwdynamics(model::QWModel, parameters::Dict{Symbol}, marked::Vector{Int})

Checks whetver combination of `model`, `marked` and `parameters` creates valid
quantum search evolution. Note that whetver list of vertices `marked` are a subset
of vertices of `graph` from `model` is checked seperately in `QWSearch` constructor.
"""
check_qwdynamics(QWSearch, ::Dict{Symbol}, ::Vector{Int})

"""
    initial_state(qws::QWSearch)

Generates initial state for `qws`.
"""
initial_state(::QWSearch)

include("qwsearch_dynamics.jl")
include("qwsearch_util.jl")
include("maximizing_function.jl")
