# TODO cleanup function names, drop redundant...

"""
    progression_at_each_coordinate(p_x, p_y, p_z)
    progression_at_each_coordinate(p::Vector{Tuple{Float64, Float64, Float64}})
    ---> Vector{Float64}

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
function progression_at_each_coordinate(p::Vector{Tuple{Float64, Float64, Float64}})
    px = map(point -> point[1], p)
    py = map(point -> point[2], p)
    pz = map(point -> point[3], p)
    progression_at_each_coordinate(px, py, pz)
end
"""
    progression_at_each_coordinate(mls::Vector{Vector{Tuple{Float64, Float64, Float64}}}, progressions::Vector{Float64})
    ---> Vector{Float64}

Distances detailed, one per coordinate in the 'multi-linestring'.

So as not to deviate from official measurements too much, length along the path 
is 'recalibrated' at the end of each segment, values taken from 'progression'.

# Example
```
julia> mls = [ [(33728.644, 6.946682377e6, 31.277), (33725.9, 6.9466807e6, 31.411), (33722.49, 6.9466785e6, 31.511)],
[(0.0, 0.0, 0.0), (10.0, 0.0, 0.0)] ];

julia> progressions = [0.0, 7.277990185233618, 17.27799018523361];

julia> progression_at_each_coordinate(mls, progressions)
```
"""
function progression_at_each_coordinate(mls::Vector{Vector{Tuple{Float64, Float64, Float64}}}, progressions::Vector{Float64})
    n = length(mls)
    @assert length(progressions) == n + 1
    s = Float64[] 
    for i in 1:n
        # Now considering:
        p = mls[i]
        s0 = progressions[i]
        # 1d-positions along p, starting at s0
        vs = progression_at_each_coordinate(mls[i]) .+ s0
        @assert length(vs) == length(p)
        if i == 1
            append!(s, vs)
        else
            # We're joining two curves where two ends are identical
            append!(s, vs[2:end])
        end
    end
    s
end







"""
    length_of_linestring(ls::Vector{Tuple{Float64, Float64, Float64}})
    --> Float64

Assuming straight lines between points

# Example
```
julia> p = [(33728.644, 6.946682377e6, 31.277), (33725.9, 6.9466807e6, 31.411), (33722.49, 6.9466785e6, 31.511)]
3-element Vector{Tuple{Float64, Float64, …}}:
 (33728.644, 6.946682377e6, 31.277)
 (33725.9, 6.9466807e6, 31.411)
 (33722.49, 6.9466785e6, 31.511)

 julia> length_of_linestring(p)
7.277990185233618
```
"""
function length_of_linestring(ls::Vector{Tuple{Float64, Float64, Float64}})
    # throw("u1")
    progression_at_each_coordinate(ls)[end]
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
    # throw("u2")
    Δx = pt2[1] - pt1[1]
    Δy = pt2[2] - pt1[2]
    Δz = pt2[3] - pt1[3]
    hypot(Δx, Δy, Δz)
end
function distance_between(pt1::T, pt2::T) where T<:Tuple{Float64, Float64}
    # throw("u3")
    Δx = pt2[1] - pt1[1]
    Δy = pt2[2] - pt1[2]
    hypot(Δx, Δy)
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
    # throw("u5")
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
    # throw("u6")
    s_at_start_of_interval, s_at_end_of_interval = interval_progression_pairs(ml)
    l = s_at_end_of_interval[end]
    s_ul_at_start_of_interval = s_at_end_of_interval ./ l
    s_ul_at_end_of_interval = s_at_end_of_interval ./ l 
    return s_ul_at_start_of_interval, s_ul_at_end_of_interval 
end