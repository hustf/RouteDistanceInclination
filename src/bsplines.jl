# This converts single multi_linestring to bsplines
# in order to calculate curvature.
# The aim not not to analyze curvature, but
# to make a basis for finding speed limitations in curves.

using BSplines
"""
curvature_from__linestring(linestring::Vector{Tuple{Float64, Float64, Float64}})

A linestring is a vector of (x, y, z) coordinates
"""
function curvature_from_linestring(linestring::Vector{Tuple{Float64, Float64, Float64}})
    

end