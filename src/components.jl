# color: RGBA or Vector{RGBA}
# marker: Symbol Char Circle
# markersize: Float VecNf0 Vector{Float} Vector{Nf0}
# markeroffset: VecNf0 Vector{VecNf0}
# strokecolor: TorVector{RGBAf0}
# strokewidth: TorVector{Float32}
# markerspace: Space -> better as symbol? - NO this is a system
# transform_marker::Bool  ???
# camera::Camera -> shared, maybe just matrices and camera as entity
# transformation::Transformation -> maybe split off model?

################################################################################
### Components
################################################################################

# TODO Idk macro hygiene
macro simple_component(name, type)
    quote
        @component struct $name
            data::$type
        end

        # generic functions could go here?
    end
end

@simple_component SpatialX Float64 
@simple_component SpatialY Float64 
@simple_component SpatialZ Float64 
@simple_component SpatialXY Float64 
@simple_component SpatialXYZ Float64 

@simple_component Color RGBAf0 

@simple_component CharMarker Char
@simple_component CircleMarker Circle #...?

# markersize but compatible with lines, meshscatters, ...
@simple_component Scale1D Float64
@simple_component Scale2D Vec2f0
@simple_component Scale3D Vec3f0

# markeroffset but compatible with text, maybe more?
@simple_component Offset2D Vec2f0 
@simple_component Offset3D Vec3f0 

# maybe these should belong to a different entity?
@simple_component StrokeColor RGBAf0
@simple_component StrokeWidth Float64

# maybe generalize?
@enum Space begin
    Pixel
    Screen
    Data
end
@simple_component MarkerSpace Space
@component struct TransformMarker end

@simple_component Parent RawEntity
Parent(e::AbstractEntity) = RawEntity(e)

# Most of these will probably be the same, especially if we do one entity per point
# though that is also the case for most of the above...
@shared_component mutable struct Transform
    translation::Vec3f0
    scale::Vec3f0
    rotation::Vec3f0
    # should model be its own component?
    model::Mat4f0
end

@shared_component mutable struct Camera
    pixel_space::Mat4f0
    view::Mat4f0
    projection::Mat4f0
    projectionview::Mat4f0
    resolution::Vec2f0
    eyeposition::Vec3f0
end




function spatial_component(input::Tuple{Vector{<: Real}, Vector{<:Real}})
    return (SpatialX.(input[1]), SpatialY.(input[2]))
end
function spatial_component(input::Tuple{Vector{<: Real}, Vector{<:Real}, Vector{<: Real}})
    return (SpatialX.(input[1]), SpatialY.(input[2]), SpatialZ.(input[3]))
end
spatial_component(input::Tuple{Vector{Point2f0}}) = (SpatialXY.(input[1]), )
spatial_component(input::Tuple{Vector{Point3f0}}) = (SpatialXYZ.(input[1]), )

const key_to_component = Dict{Symbol, Any}(
    :color => Color,
    :marker => Marker,
    :markersize => Scale,
    :markeroffset => Offset,
    :strokecolor => StrokeColor,
    :strokewidth => StrokeWidth,
    :space => Space,
    :camera => Camera,
    :model => Transform
)
to_component(key, value) = key_to_component[key](value)

Marker(::Circle) = CircleMarker(Circle())
Marker(c::Char) = CharMarker(c)
Transform(model::Mat4f0) = ...



# maybe move this
function fallback_get(component, entity, parent)
    haskey(component, entity) ? component[entity] : component[parent]
end