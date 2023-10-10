#########################################################################
# This tests how well RouteSlopeDistance.progression_and_radii_of_segment
# could measure radius from sampled points.
# We use points perfectly placed on arcs with known radius,
# and vary the density of sampling points.
# 
# We then test helixes (we are interested in the projected radius),
# and spirals (varying radius).
#
# Plots are used for checking understanding and could be commented out 
# so that the Plots dependency can be dropped.
#########################################################################

using Test
using RouteSlopeDistance
using RouteSlopeDistance: progression_and_radii_of_segment
using Plots

function test_half_circle_pts(np)
    R = 1 / π
    θ = collect(range(0, π, length = np))
    px = R .* cos.(θ)
    py = R .* sin.(θ)
    pz = 0.0 .* py
    s0 = 1.0
    s1 = s0  + 1
    s, r = progression_and_radii_of_segment(px, py, pz, s0, s1)
    s, r, px, py
end    



## Test with a half-circle with arc length 1. 
np = 100
s, r, px, py = test_half_circle_pts(np)
plot(px, py, marker = true)
r_relative_error = (r .- 1 / π) ./ 1 / π
plot(s, r_relative_error)
@test maximum(abs.(filter(!isnan, r_relative_error))) < 0.00026

## Test with a half-circle with arc length 1, too few points to estimate radius
np = 4
s, r, px, py = test_half_circle_pts(np)
plot(px, py, marker = true)
@test all(isnan.(r))
@test length(r) == length(s) == np

## Test with a half-circle with arc length 1, minimum no. of points.
np = 5
s, r, px, py = test_half_circle_pts(np)
plot(px, py, marker = true)
r_relative_error = (r .- 1 / π) ./ (1 / π)
@test maximum(abs.(filter(!isnan, r_relative_error))) < 0.17
@test length(r) == length(s) == np

## Test with a half-circle with arc length 9 (filtered)
np = 9
s, r, px, py = test_half_circle_pts(np)
plot(px, py, marker = true)
r_relative_error = (r .- 1 / π) ./ (1 / π)
@test maximum(abs.(filter(!isnan, r_relative_error))) < 0.04
@test length(r) == length(s) == np


function test_constant_slope_pts(np, slope)
    R = 1 / π
    θ = collect(range(0, π, length = np))
    px = R .* cos.(θ)
    py = R .* sin.(θ)
    pz = slope .* (range(0, 1, length = np))
    s0 = 1.0
    s1 = s0  + hypot(1, slope)
    s, r = progression_and_radii_of_segment(px, py, pz, s0, s1)
    s, r, px, py, pz
end 

# Test slope constant 1:10 in a helix
np = 9
s, r, px, py, pz = test_constant_slope_pts(np, 0.1)
plot(px, py, marker = true)
r_relative_error = (r .- 1 / π) ./ (1 / π)
# The curve radius is no longer 1 / π. That is the
# radius of the horizontal projection of the curve.
@test maximum(abs.(filter(!isnan, r_relative_error))) < 0.06
@test length(r) == length(s) == np


np = 999
s, r, px, py, pz = test_constant_slope_pts(np, 0.1)
plot(px, py, marker = true)
r_relative_error = (r .- 1 / π) ./ (1 / π)
# The curve radius is no longer 1 / π. That is the
# radius of the horizontal projection of the curve.
@test maximum(abs.(filter(!isnan, r_relative_error))) < 0.016
@test length(r) == length(s) == np

function test_spiral(np; reversed = false)
    θ = 2π * 5
    θs = collect(range(0 , θ, length = np))
    b = 20
    R = b .* θs
    px = R .* cos.(θs)
    py = R .* sin.(θs)
    pz = R .* 0
    arclength = 0.5b * (θ * sqrt(1 + θ^2) + log(θ + sqrt(1 + θ^2)))
    s0 = 1.0
    s1 = s0 + arclength
    if reversed
        px, py = reverse(px), reverse(py)
    end
    s, r = progression_and_radii_of_segment(px, py, pz, s0, s1)
    s, r, px, py, pz
end 

# "Flat spiral" starting with small radius, left turning.
# Radius is positive, right hand rule
np = 999
s, r, px, py, pz = test_spiral(np)
plot(px, py, marker = true)
plot(s, r)
@test maximum(abs.(filter(!isnan, r))) < 500
@test minimum(filter(!isnan, r)) > 0

# "Flat spiral" starting with large absolute radius, right turning.
# Radius is negative, right hand rule
np = 999
s, r, px, py, pz = test_spiral(np; reversed = true)
plot(px, py, marker = true)
plot(s, r)
@test maximum(abs.(filter(!isnan, r))) < 500
@test minimum(filter(!isnan, r)) < 400



