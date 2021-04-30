abstract type AbstractRenderSystem <: System end


# TODO 
abstract type AbstractComponentUpdater <: System end

struct SpatialUpdater <: AbstractRenderSystem end

# all that a scatter could have but doesn't necessarily need to have
function Overseer.requested_componets(::SpatialUpdater) 
    (NeedsUpdate, SpatialX, SpatialY, SpatialXY, SpatialXYZ)
end

function Overseer.update(::SpatialUpdater, m::AbstractLedger)
    needs_update = m[NeedsUpdate]
    x = m[SpatialX]
    y = m[SpatialY]
    z = m[SpatialZ]
    xy = m[SpatialXY]
    xyz = m[SpatialXYZ]

    for e in @entities_with(needs_update && x && y && xy)
        if needs_update[e]
            xy[e] = SpatialXY(x[e], y[e])
        end
    end

    for e in @entities_with(needs_update && xy && z && xyz)
        if needs_update[e]
            xyz[e] = SpatialXYZ(xy[e], z[e])
        end
    end

    for e in @entities_with(needs_update && x && y && z && xyz && !xy)
        if needs_update[e]
            xyz[e] = SpatialXYZ(x[e], y[e], z[e])
        end
    end

    nothing
end
