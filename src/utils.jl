"""
    length_of_linestring(ls::Vector{Tuple{Float64, Float64, Float64}})
    --> Float64

Assuming straight lines between points
"""
function length_of_linestring(ls::Vector{Tuple{Float64, Float64, Float64}})
    l = 0.0
    prevpt = ls[1]
    for pt in ls[2:end]
        l += distance_between(prevpt, pt)
        prevpt = pt
    end
    l
end

"""
distance_between(pt1, pt2)

Euclidean distance between 3d points
"""
function distance_between(pt1, pt2)
    Δx = pt2[1] - pt1[1]
    Δy = pt2[2] - pt1[2]
    Δz = pt2[3] - pt1[3]
    hypot(Δx, Δy, Δz)
end


"""
reverse_linestrings_where_needed!(multi_linestring, easting1, northing1)

In-place reversing of linestrings point order for continuity. 
"""
function reverse_linestrings_where_needed!(multi_linestring, easting1, northing1)
    previous_point = (easting1, northing1, 0.0)
    for i in eachindex(multi_linestring)
        current_first_point = multi_linestring[i][1]
        current_last_point = multi_linestring[i][end]
        d_first = distance_between(previous_point, current_first_point)
        d_last = distance_between(previous_point, current_last_point)
        if d_last < d_first
            reverse!(multi_linestring[i])
        end
        previous_point = multi_linestring[i][end]
    end
    multi_linestring
end