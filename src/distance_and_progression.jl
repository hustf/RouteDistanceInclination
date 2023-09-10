# This file concerns length, distance and progression from coordinate sets.

"""
    progression_at_each_coordinate(p_x, p_y, p_z)

Used as an intermediatory step. The result is later scaled to fit the authoritative total length.

# Example
```
julia> p = [(33728.644, 6.946682377e6, 31.277), (33725.9, 6.9466807e6, 31.411), (33722.49, 6.9466785e6, 31.511)]
3-element Vector{Tuple{Float64, Float64, …}}:
 (33728.644, 6.946682377e6, 31.277)
 (33725.9, 6.9466807e6, 31.411)
 (33722.49, 6.9466785e6, 31.511)

 julia> progression_at_each_coordinate(p)
 2-element Vector{Float64}:
  3.218667581541792
  7.277990185233618
```
"""
function progression_at_each_coordinate(p_x, p_y, p_z)
    n = length(p_x)
    @assert length(p_y) == n
    p0 = [(p_x[i], p_y[i], p_z[i]) for i in 1:(n - 1)]
    p1 = [(p_x[i], p_y[i], p_z[i]) for i in 2:n]
    Δls = distance_between.(p0, p1)
    append!([0.0], cumsum(Δls))
end



"""
distance_between(pt1, pt2)

Euclidean distance between 2d or 3d points

# Example
```
julia> pt1 = (33725.9, 6.9466807e6, 31.411);

julia> pt2 = (33722.49, 6.9466785e6, 31.511);

julia> distance_between(pt1, pt2)
4.059322603691826
```
"""
function distance_between(pt1, pt2)
    Δx = pt2[1] - pt1[1]
    Δy = pt2[2] - pt1[2]
    Δz = pt2[3] - pt1[3]
    hypot(Δx, Δy, Δz)
end
function distance_between(pt1, pt2::T) where T<:Tuple{Float64, Float64}
    Δx = pt2[1] - pt1[1]
    Δy = pt2[2] - pt1[2]
    hypot(Δx, Δy)
end
function distance_between(pt1::Float64, pt2::Float64)
    Δx = pt2[1] - pt1[1]
    hypot(Δx)
end

"""
    interval_progression_pairs(ml)

Return 1d- positions along the vector of 3d- or 2d- coordinates.

ml is a vector of position tuples, typically in UTM33 coordinates where '1' is '1 m'.

# Example

```
julia> ml = [(33296.1, 6.9464925e6, 37.41), (33290.699, 6.9464925e6, 37.31), (33286.773, 6.946492338e6, 37.31)]
3-element Vector{Tuple{Float64, Float64, …}}:
 (33296.1, 6.9464925e6, 37.41)
 (33290.699, 6.9464925e6, 37.31)
 (33286.773, 6.946492338e6, 37.31)

julia> interval_progression_pairs(ml)
([0.0, 5.401925675162388], [5.401925675162388, 9.331266586797394])
```
"""
function interval_progression_pairs(ml)
    pts_start = ml[1:(end -1)]
    pts_end = ml[2:end]
    Δls = distance_between.(pts_start, pts_end)
    s_at_end_of_interval = cumsum(Δls)
    s_at_start_of_interval = vcat([0.0], s_at_end_of_interval[1:(end -1)])
    return s_at_start_of_interval, s_at_end_of_interval 
end

"""
    unitless_interval_progression_pairs(ml)

# Example

```
julia> ml = [(33296.1, 6.9464925e6, 37.41), (33290.699, 6.9464925e6, 37.31), (33286.773, 6.946492338e6, 37.31)]
3-element Vector{Tuple{Float64, Float64, …}}:
 (33296.1, 6.9464925e6, 37.41)
 (33290.699, 6.9464925e6, 37.31)
 (33286.773, 6.946492338e6, 37.31)

julia> unitless_interval_progression_pairs(ml)
([0.0, 0.5789059421799667], [0.5789059421799667, 1.0])
```
"""
function unitless_interval_progression_pairs(ml)
    s_at_start_of_interval, s_at_end_of_interval = interval_progression_pairs(ml)
    l = s_at_end_of_interval[end] - s_at_start_of_interval[1]
    s_ul_at_start_of_interval = s_at_start_of_interval ./ l
    s_ul_at_end_of_interval = s_at_end_of_interval ./ l 
    return s_ul_at_start_of_interval, s_ul_at_end_of_interval 
end