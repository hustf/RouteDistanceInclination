# This converts single multi_linestring to bsplines
# in order to calculate curvature.
# The aim not not to analyze curvature, but
# to make a basis for finding speed limitations in curves.

function extract_curvature_extremals_from_multi_linestrings(mls::Vector{Vector{Tuple{Float64, Float64, Float64}}})
    r_extremals = Float64[]
    s_extremals = Float64[]
    for p in mls
        r, s = curvature_from_linestring(p)
        push!(r_extremals, r)
        push!(s_extremals, s)
    end
    r_extremals, s_extremals
end
"""
    curvature_from__linestring(p::Vector{Tuple{Float64, Float64, Float64}})
    curvature_from_linestring(px, py)

    --> Tightest turning radius, at arc length from start of curve

A linestring is a vector of (x, y, z) coordinates as per roadbuilding nomenclature.

Vertical curvature is ignored in the curvature calculation,
but vertical position is included in lengths. So this is slightly approximate.

Since we need to apply some smoothing, this returns the minimum
radius of curvature after filtering.
"""
function curvature_from_linestring(p::Vector{Tuple{Float64, Float64, Float64}})
    px = map(point -> point[1], p)
    py = map(point -> point[2], p)
    pz = map(point -> point[3], p)
    curvature_from_linestring(px, py, pz)
end
function curvature_from_linestring(p_x, p_y, p_z)
    s = progression_at_each_coordinate(p_x, p_y, p_z)
    b  = BSplineBasis(4, s)
    # Values to interpolate between.
    # Try not bothering with tangents, double up endpoints instead!
    # We'll take values away from the ends anyway.
    xe = vcat(p_x[1], p_x, p_x[end])
    ye = vcat(p_y[1], p_y, p_y[end])
    # We consider the following to be naturally parametrized curve,
    # i.e. the argument is arc length in meters.
    # This is not perfect, so we need to do some smoothing and testing.   
    px = Function(Spline(b, xe), true)
    py = Function(Spline(b, ye), true)
    px´ = Function(Spline(b, xe), Derivative(1))
    py´ = Function(Spline(b, ye), Derivative(1))
    p´(s) = (px´(s), py´(s))
    px´´ = Function(Spline(b, xe), Derivative(2))
    py´´ = Function(Spline(b, ye), Derivative(2))
    p´´(s) = (px´´(s), py´´(s))
    # And voîla, the signed curvature κ is also (Kreyzig):
    ϕ´(s) = perp_dot_product(p´(s) , p´´(s))
    extract_smoooth_minimum_radius_of_curvature(ϕ´, s)
end


"""
    extract_smoooth_minimum_radius_of_curvature(ϕ´::Function, s::Vector)
"""
function extract_smoooth_minimum_radius_of_curvature(ϕ´::Function, s::Vector)
    if length(s) < 9 # 9 - 4 = 5, minimum for filtering. 
        # Estimating curvature from this few points would
        # be quite inaccurate. Better to drop it.
        # CONSIDER Revisit with thorough testing?
        return NaN, NaN
    end
    # Shy away from dubious ends. This is four points.
    ss = s[3:(end - 2)]
    κs = map(ϕ´, ss)
    # Henderson moving average, nn = 17 seems to work get rid of most of the noise.
    nκ = length(κs)
    nfi = min(17, iseven(nκ) ?  nκ - 1 : nκ)
    κsm = hma(κs, nfi)
    # The largest smoothed curvature is
    κ_max, i_max = findmax(abs.(κsm))
    @assert ! iszero(κ_max)
    # The smallest radius of curvature is
    r_extreme = 1 / κ_max
    # The arc length position for the tightest curve is
    s_extreme = ss[i_max]
    # Tightest radius, at arc length from start
    r_extreme, s_extreme
end
# p = [(28683.912, 6.945112857e6, 83.498), (28678.9, 6.9451121e6, 83.214), (28673.4, 6.9451116e6, 82.814), (28667.1, 6.945111e6, 82.414), (28660.811, 6.9451106e6, 81.914), (28654.811, 6.9451103e6, 81.514), (28648.4, 6.9451102e6, 81.114), (28642.311, 6.9451102e6, 80.714), (28636.6, 6.9451103e6, 80.214), (28630.699, 6.9451103e6, 79.914), (28624.99, 6.9451105e6, 79.414), (28616.1, 6.9451108e6, 78.914), (28609.6, 6.9451112e6, 78.414), (28603.6, 6.9451118e6, 78.014), (28597.311, 6.9451124e6, 77.714), (28591.311, 6.9451131e6, 77.414), (28584.99, 6.945114e6, 77.014), (28578.811, 6.9451149e6, 76.714), (28572.811, 6.945116e6, 76.314), (28565.311, 
# 6.9451175e6, 75.914), (28559.99, 6.9451187e6, 75.614), (28554.199, 6.94512e6, 75.314), (28549.199, 6.9451214e6, 75.114), (28543.699, 6.9451228e6, 74.814), (28538.311, 6.9451243e6, 74.614), (28532.311, 6.9451261e6, 74.314), (28526.811, 6.9451278e6, 74.014), (28520.9, 6.9451298e6, 73.814), (28512.35, 6.945133e6, 73.464)]

"""
    perp_dot_product(a1, a2, b1, b2)
    perp_dot_product(p´, p´´)

'Cross product for 2d'.
"""
perp_dot_product(a1, a2, b1, b2) = a1 * b2 - a2 * b1
perp_dot_product(p´, p´´) = perp_dot_product(p´[1], p´[2], p´´[1], p´´[2])