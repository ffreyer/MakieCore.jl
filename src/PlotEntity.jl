const RawEntity = Overseer.Entity

abstract type AbstractEntity end

# This is for convenience.
# It allows you to forget about the ledger for the most part and just work with
# PlotEntity instead

struct PlotEntity <: AbstractEntity
    ledger::Overseer.Ledger
    entity::RawEntity
end

"""
    PlotEntity(ledger_or_manager, entity_or_components)

Creates an `Entity` which wraps the ledger to simplify modification.
For example, it simplifies `ledger(manager)[Component][entity]` to 
`entity[Component]`.

If a set of components is passed instead of a raw entity, a new entity will be 
created and embeded in the passed ledger/ledger or scene.
"""
function PlotEntity(manager, components...)
    PlotEntity(ledger(manager), RawEntity(ledger(manager), components...))
end



# generic interface
@inline ledger(e::AbstractEntity) = e.ledger
@inline RawEntity(e::AbstractEntity) = e.entity
Base.push!(e::AbstractEntity, component) = ledger(e)[RawEntity(e)] = component
Base.haskey(e::AbstractEntity, key) = RawEntity(e) in ledger(e)[key]
Base.in(key, e::AbstractEntity) = RawEntity(e) in ledger(e)[key]
Base.getindex(e::AbstractEntity, key) = ledger(e)[key][RawEntity(e)]
Base.setindex!(e::AbstractEntity, val, key) = ledger(e)[key][RawEntity(e)] = val
Base.delete!(e::AbstractEntity) = delete!(ledger(e), RawEntity(e))
Base.delete!(e::AbstractEntity, key) = pop!(ledger(e)[key], RawEntity(e))
Base.pop!(e::AbstractEntity, key) = pop!(ledger(e)[key], RawEntity(e))
Base.:(==)(e1::AbstractEntity, e2::AbstractEntity) = RawEntity(e1) == RawEntity(e2)


# Iteration
# i.e. for component in entity
function Base.iterate(e::AbstractEntity, state = (ledger(e)[RawEntity(e)], 1))
    components, idx = state
    if idx ≤ length(components)
        @inbounds return (components[idx], (components, idx+1))
    else
        return nothing
    end
end
Base.length(e::AbstractEntity) = length(ledger(e)[RawEntity(e)])





# To simplify instanced entities

struct EntityCollection <: AbstractEntity
    ledger::Overseer.Ledger
    root::RawEntity
    children::Vector{RawEntity}
end

function EntityCollection(root::AbstractEntity, components...)
    EntityCollection(ledger(root), RawEntity(root), components...)
end

function EntityCollection(ledger, root::RawEntity, components...)
    for c in components
        if !(c isa Vector)
            ledger[root] = c
        end
    end
    
    vector_components = filter(c -> c isa Vector, components)
    N = mapreduce(length, max, vector_components)
    
    children = map(1:N) do idx
        applicable = [c[idx] for c in vector_components if length(c) >= idx]
        RawEntity(ledger, Parent(root), applicable...)
    end

    EntityCollection(ledger, root, children)
end
