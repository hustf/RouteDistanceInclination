# This converts single multi_linestring to bsplines
# in order to calculate curvature.
# The aim not not to analyze curvature, but
# to make a basis for finding speed limitations in curves.

function progression_and_radii_of_curvature_from_multiline_string(mls, progression_at_ends)
    n = length(mls)
    @assert length(progression_at_ends) == n + 1
    progression = Float64[]
    radii_of_curvature = Float64[]
    for i in 1:n
        # Put this in a separate function??
        # Now considering:
        p = mls[i]
        s0 = progression_at_ends[i]     # The first is zero we expect.
        s1 = progression_at_ends[i + 1] # The first is zero we expect.
        # s0 and s1 are the Vegsystemreferanse progressions.
        # We' correct progression_at_ends values to match these at the ends of each curve.
        px = map(point -> point[1], p)
        py = map(point -> point[2], p)
        pz = map(point -> point[3], p)
        s, r = progression_and_radii_of_segment(px, py, pz, s0, s1)
        if i !== n
            append!(progression,  s[1:(end - 1)])
            append!(radii_of_curvature,  r[1:(end - 1)])
        else
            append!(progression,  s)
            append!(radii_of_curvature,  r)
        end
    end
    progression, radii_of_curvature
end


function progression_and_radii_of_segment(px, py, pz, s0, s1)
    x = progression_at_each_coordinate(px, py, pz)
    # map x[1] to s0, x[end] to s1, linearly in between.
    s = s0 .+ ((s1 - s0) ./ (x[end] - x[1])) .* (x .- x[1])
    # The detailed progression, s, for this part is used as breakpoints:
    b  = BSplineBasis(4, s)
    # We'll make three curves (and their derivatives). Each is padded at the end (no tangents).
    xe = vcat(px[1], px, px[end])
    ye = vcat(py[1], py, py[end])
    # The smooth curves... Wrapping in Function ensures that NaN will be 
    # returned for any parameter outside of b's 'support' or 'range', s.
    sx´ = Function(Spline(b, xe), Derivative(1))
    sy´ = Function(Spline(b, ye), Derivative(1))
    sx´´ = Function(Spline(b, xe), Derivative(2))
    sy´´ = Function(Spline(b, ye), Derivative(2))
    # We make a small error by neglecting the vertical contribution, 
    # but we consider it good enough for the purpose of finding comfortable
    # driving speed in a curve. Latteral inclination matters much more, and we don't have that.
    p´(s) = (sx´(s), sy´(s))
    p´´(s) = (sx´´(s), sy´´(s))
    # For naturally parametrized curves (we approximate that closely), 
    # change in tangent direction equals the signed curvature κ (ref. Kreyzig):
    ϕ´(s) = perp_dot_product(p´(s) , p´´(s))
    r = smooth_signed_radii(ϕ´, s)
    s, r
end

function smooth_signed_radii(ϕ´, s)
    # Shy away from dubious ends of splines. Derivatives don't mean much there. 
    drop_pts = 2
    if length(s) < 5
        return NaN .* s
    end
    ss = s[1 + drop_pts:(end - drop_pts)]
    κs = map(ϕ´, ss)
    if length(s) < 9 # 9 - 4 = 5, minimum for filtering.
        r_unfiltered = 1 ./ κs
        return vcat(repeat([NaN], drop_pts), r_unfiltered,  repeat([NaN], drop_pts))
    end
    κsm = smooth_coordinate(κs)
    # We keep the sign of curvature. Hence, curving to the left is positive, to right is negative.
    # Smooth signed radii:
    rsm = 1 ./ κsm
    # Radii larger than 500 m are not interesting to our purposes. Cut off with NaN.
    rcu = map(r -> abs(r) <= 500 ? r : NaN,  rsm)
    # Pad the ends with NaNs
    r = vcat(repeat([NaN], drop_pts), rcu,  repeat([NaN], drop_pts))
    @assert length(r) == length(s)
    r
end


"""
    perp_dot_product(a1, a2, b1, b2)
    perp_dot_product(p´, p´´)

'Cross product for 2d'.
"""
perp_dot_product(a1, a2, b1, b2) = a1 * b2 - a2 * b1
perp_dot_product(p´, p´´) = perp_dot_product(p´[1], p´[2], p´´[1], p´´[2])

"""
    smooth_slope_from_multiline_string(mls::Vector{ Vector{Tuple{Float64, Float64, Float64}}}, progression)
    ---> Vector{Float64}
"""
function smooth_slope_from_multiline_string(mls::Vector{ Vector{Tuple{Float64, Float64, Float64}}}, progression)
    _, _, z = unique_unnested_coordinates_of_multiline_string(mls)
    smooth_slope(z, progression)
end


"""
    smooth_slope(z::T, progression::T) where T<: Vector{Float64}
    ---> Vector{Float64}

This assumes z is low-resolution measurement, not really noisy measurement.
This gives very spiky changes.
progression is assumed to be directly useable.   
"""
function smooth_slope(z::T, progression::T) where T<: Vector{Float64}
    x = progression
    zsm = smooth_coordinate(z)
    # Pad ends
    xp = vcat(x[1], x, x[end])
    zp = vcat(zsm[1], zsm, zsm[end])
    b  = BSplineBasis(4, x)
    fz´ = Function(Spline(b, zp), Derivative(1))
    z´ = map(fz´, x)
    # With this method, we most likely get reasonable end of range values
    # by copying the next to last value.
    z´[1] = z´[2]
    z´[end - 1] = z´[end - 2]
    z´[end] = z´[end - 1]
    z´
end

"""
    smooth_coordinate(rough::Vector{Float64}; max_filter_length = 17)
    ---> Vector{Float64}

Henderson moving average.
"""
function smooth_coordinate(rough::Vector{Float64}; max_filter_length = 17)
    @assert ! iseven(max_filter_length)
    n = length(rough)
    nfi = min(max_filter_length, iseven(n) ?  n - 1 : n)
    hma(rough, nfi)
end