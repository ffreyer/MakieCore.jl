
struct Scene <: AbstractLegder
    ledger::Overseer.Ledger
end


ledger(scene::Scene) = scene.ledger
Base.push!(scene::Scene, e::AbstractEntity) = push!(ledger(scene), e)
# ...
