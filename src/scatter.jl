# TODO Nodes and updates

function scatter!(scene, args...; kwargs...)
    push!(scene, scatter(args...; kwargs...))
end

function scatter(spatial...; attributes...)
    spatial_components = spatial_component(spatial)
    general_components = to_component.(attributes)

    EntityCollection(
        default_scatter_entity(), 
        spatial_components..., general_components...
    )
end

# this is kinda defaults
function default_scatter_entity()
    PlotEntity(
        # Spatial must be provided
        Color(RGBAf0(0.3, 0.3, 0.3, 1.0)),
        CharMarker('o'),
        Scale1D(10.0),
        Offset2D(0.0),
        StrokeColor(RGBAf0(1, 1, 1, 1)),
        StrokeWidth(1)
    )
end