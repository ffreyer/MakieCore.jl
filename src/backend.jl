using Cairo

# Maybe backend as singleton component?

@simple_component CairoContextComponent Cairo.CairoContext
...


"""
    struct CairoScreen{S} <: AbstractScreen

A "screen" type for CairoMakie, which encodes a surface
and a context which are used to draw a Scene.
"""
@component struct CairoScreen{S}
    surface::S
    context::Cairo.CairoContext
end

function CairoScreen(w, h; device_scaling_factor = 1, antialias = Cairo.ANTIALIAS_BEST)
    w, h = (w, h) .* device_scaling_factor
    surf = Cairo.CairoARGBSurface(w, h)
    # this sets a scaling factor on the lowest level that is "hidden" so its even
    # enabled when the drawing space is reset for strokes
    # that means it can be used to increase or decrease the image resolution
    ccall((:cairo_surface_set_device_scale, Cairo.libcairo), Cvoid, (Ptr{Nothing}, Cdouble, Cdouble),
        surf.ptr, device_scaling_factor, device_scaling_factor)

    ctx = Cairo.CairoContext(surf)
    Cairo.set_antialias(ctx, antialias)

    return CairoScreen(surf, ctx)
end



################################################################################
### Rendering System
################################################################################


function rgbatuple(c::Colorant)
    rgba = RGBA(c)
    red(rgba), green(rgba), blue(rgba), alpha(rgba)
end

to_2d_scale(x::Number) = Vec2f0(x)
to_2d_scale(x::Vec) = Vec2f0(x)

function project_position(camera, point, model)
    # use transform func
    res = camera.resolution
    p4d = to_ndim(Vec4f0, to_ndim(Vec3f0, point, 0f0), 1f0)
    clip = camera.projectionview * model * p4d
    @inbounds begin
        # between -1 and 1
        p = (clip ./ clip[4])[Vec(1, 2)]
        # flip y to match cairo
        p_yflip = Vec2f0(p[1], -p[2])
        # normalize to between 0 and 1
        p_0_to_1 = (p_yflip .+ 1f0) / 2f0
    end
    # multiply with scene resolution for final position
    return p_0_to_1 .* res
end

project_scale(cam, s::Number, model = Mat4f0(I)) = project_scale(cam, Vec2f0(s), model)

function project_scale(camera, s, model = Mat4f0(I))
    p4d = to_ndim(Vec4f0, s, 0f0)
    p = @inbounds (camera.projectionview[] * model * p4d)[Vec(1, 2)] ./ 2f0
    return p .* camera.resolution[]
end


struct CairoScatter <: AbstractRenderSystem end

# all that a scatter could have but doesn't necessarily need to have
function Overseer.requested_componets(::CairoScatter)
    (
        Parent, SpatialXYZ, Color, CharMarker, CircleMarker, MarkerSpace,
        Scale2D, Offset2D, StrokeColor, StrokeWidth, Transform, Camera,
        TransformMarker
    )
end

function Overseer.update(::CairoScatter, m::AbstractLedger)
    ctx = singleton(m, CairoContextComponent)

    # components
    parents = m[Parent]
    positions = m[SpatialXYZ]
    colors = m[Color]
    char_markers = m[CharMarker]
    circle_markers = m[CircleMarker]
    markersizes = m[Scale2D]
    markeroffsets = m[Offset2D]
    space = m[MarkerSpace]
    transform_marker = m[TransformMarker]
    strokecolors = m[StrokeColor]
    strokewidths = m[StrokeWidth]
    transforms = m[Transform]
    cameras = m[Camera]

    # is_pixelspace = p.markerspace == Pixel
    for e in @entities_with(parents && positions && (char_markers || circle_markers))
        parent = parents[e]

        # All of these (hidden) if's probably suck for performance...
        in_pixelspace = fallback_get(space, e, parent) == Pixel
        camera = fallback_get(cameras, e, parent)
        transform = fallback_get(transform, e, parent)
        should_transform = haskey(transform_marker, e) || haskey(transform_marker, parent)
        if in_pixelspace
            scale =  fallback_get(markersize, e, parent)
            offset = fallback_get(markeroffsets, e, parent)
        else
            size_model = should_transform ? transform.model : Mat4f0(I)
            scale = project_scale(camera, fallback_get(markersize, e, parent), size_model)
            offset = project_scale(camera, fallback_get(markeroffsets, e, parent), size_model)
        end
        strokecolor = fallback_get(strokecolor, e, parent)
        strokewidth = fallback_get(strokewidth, e, parent)
        color = fallback_get(colors, e, parent)

        marker = haskey(char_markers, e) ? char_markers[e] : circle_markers[parent]

        pos = project_position(..., positions[e], transform.model)
        isnan(pos) && continue
        
        Cairo.set_source_rgba(ctx, rgbatuple(col)...)
        draw_marker(ctx, marker, pos, scale, strokecolor, strokewidth, offset)
    end

    nothing
end