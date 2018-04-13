```@meta
DocTestSetup = quote
   using QuantumWalk, LightGraphs
end
```

# Quantum evolution

The simplest quantum walk evolution. It simply takes the model and initial state from
the user, simulate an evolution and outputs the state or the probability distribution
of measured state.

The dynamics requires `evolve`, `measure` and `check_qwdynamics` functions.
It provides `execute`, `execute_single`, `execute_single_measured`, `execute_all` and
`execute_all_measured` functions. Depending on the name it outputs single state
or all states, measured or not measured. The execute combines the last four functions.
In the case of type-stability requirement, we recommend to use the last four
functions. `execute_all` and `execute_all_measured` are provided only for discrete
quantum walk models.

Following functions are connected to the dynamics:
```@index
Order = [:type, :function]
Modules = [QuantumWalk]
Pages   = ["quantum_walk.md"]
```

## Example
```julia
julia> using LightGraphs, QuantumWalk

julia> qwe = QWEvolution(Szegedy(CompleteGraph(4)));

julia> state = rand(16); state = sparse(state/norm(state));

julia> execute_single(qwe, state, 4)
16-element SparseVector{Float64,Int64} with 16 stored entries:
  [1 ]  =  0.37243
  [2 ]  =  0.402212
  [3 ]  =  0.356914
  [4 ]  =  0.0384893
  [5 ]  =  0.230443
  [6 ]  =  0.0373444
  [7 ]  =  0.12092
  [8 ]  =  0.285178
  [9 ]  =  0.151519
  [10]  =  0.258755
  [11]  =  0.30374
  [12]  =  0.375624
  [13]  =  0.169741
  [14]  =  -0.0403198
  [15]  =  0.255573
  [16]  =  0.0344363

julia> execute_all_measured(qwe, state, 4)
4×5 Array{Float64,2}:
 0.273249  0.455568  0.308632  0.339199  0.429348
 0.20334   0.165956  0.188335  0.188466  0.150447
 0.244393  0.213254  0.378161  0.171268  0.323264
 0.279018  0.165221  0.124872  0.301066  0.0969412

julia> execute(qwe, state, 4, )
execute(qwd::QuantumWalk.QWDynamics, initstate, runtime::Real; all, measure) in QuantumWalk at /home/adam/.julia/v0.6/QuantumWalk/src/dynamics.jl:23
julia> execute(qwe, state, 4, measure=true, all=true)
4×5 Array{Float64,2}:
 0.273249  0.455568  0.308632  0.339199  0.429348
 0.20334   0.165956  0.188335  0.188466  0.150447
 0.244393  0.213254  0.378161  0.171268  0.323264
 0.279018  0.165221  0.124872  0.301066  0.0969412
```

## Adjusting model to `QWEvolution`

The `QWEvolution` requires an implementation of `evolve`, `measure` and `check_qwdynamics`.
Instead of implementing purely quantum walk, we will implement simple random walk,
which still fits our considerations. Note that we creates an additional `AbstractStochastic` supertype, in case someone would prefer to make different
stochastic evolution (for example change the stochastic matrix). Note we skipped
some assertion checking for readability. Furthermore note we have defined two
versions of `measure`: in most cases measuring only part of `vertices` are faster
than making full measurement.

```julia
abstract type AbstractStochastic <: QWModelDiscr end

struct UniformStochastic{G<:SimpleGraph} <: AbstractStochastic
  graph::G
end

UniformScaling(digraph::G) where G= UniformStochastic{G}(digraph)

function check_qwdynamics(::Type{QWEvolution},
                          abs_stoch::UniformStochastic,
                          parameters::Dict{Symbol,Any})
  @assert :stochastic ∈ keys(parameters) "parameters needs to have key stochastic"
  n = nv(graph(abs_stoch))
  @assert isa(parameters[:stochastic], SparseMatrixCSC{<:Real}) "value for :stochastic needs to be sparse matrix with real numbers"
  @assert size(parameters[:stochastic], 1) == size(parameters[:stochastic], 2) "Stochastic matrix needs to be square stochastic matrix"
  @assert mapslices(sum, parameters[:stochastic], 1)[1,:] ≈ ones(n) "Stochastic matrix needs to be square stochastic matrix of order graph"
end

function stochastic_matrix(g::SimpleGraph)
  a = adjacency_matrix(g)
  a*spdiagm(mapslices(x->1/sum(x), a, 1)[1,:])
end

function QWEvolution(stoch::AbstractStochastic)
   parameters = Dict{Symbol,Any}(:stochastic => stochastic_matrix(graph(stoch)))
   QWEvolution(stoch, parameters)
end

function stochastic_evolution(s::SparseMatrixCSC{T}, v::Vector{T}) where T<:Real
  s*v
end

function evolve(qss::QWDynamics{<:AbstractStochastic}, state)
  stochastic_evolution(parameters(qss)[:stochastic], state)
end

function measure(::QWDynamics{<:AbstractStochastic}, state::Vector{<:Real})
   return state
end

function measure(::QWDynamics{<:AbstractStochastic},
                 state::Vector{<:Real},
                 vertices::Vector{Int})
   return state[vertices]
end
```

Thanks to the definition above we can make a pure walk evolution.

```julia
dynamic = QWEvolution(UniformStochastic(smallgraph(:bull)))

println(execute_single(dynamic, fill(1./5, 5), 5))
# [0.186831, 0.313169, 0.313169, 0.0934156, 0.0934156]
```

Note that continuous quantum walks requires time argument in `evolution` function.

## Full docs


```@docs
QWEvolution
check_qwdynamics(::Any)
evolve(::Any)
execute(::QWDynamics, ::Any, ::Real)
execute_all(qwd::QWDynamics{<:QWModelDiscr}, ::Any, ::Int)
execute_all_measured(qwd::QWDynamics{<:QWModelDiscr}, ::Any, ::Int)
execute_single(::QWDynamics{<:QWModelDiscr}, ::Any, ::Int)
execute_single_measured(::QWDynamics, ::Any, ::Real)
measure(::Any)
```