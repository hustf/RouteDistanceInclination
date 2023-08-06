using Test
using RouteSlopeDistance
using RouteSlopeDistance: LOGSTATE, length_of_linestring
import HTTP
using JSON3: pretty
# We don't need to print our 
# request to screen as long as it is accepted.
LOGSTATE.authorization = false
LOGSTATE.request_string = false

url_ext = "beta/vegnett/rute"

northing1 = 6.94747e6 # Grimstad aust bus stop in UTM33
easting1 = 35465.0    # Grimstad aust bus stop in UTM33
northing2 = 6.94731e6 # Grimstad vest bus stop in UTM33
easting2 = 34865.7    # Grimstad vest bus stop in UTM33


body = Dict([
    :typeveg                => "enkelbilveg"
    :konnekteringslenker    => false
    :start                  => "$easting1 , $northing1"
    :trafikantgruppe        => "K"
    :detaljerte_lenker      => false
    :behold_trafikantgruppe => true
    :slutt                  => "$easting2 , $northing2"
    :tidspunkt              => "2023-07-28"])

o = nvdb_request(url_ext, "POST"; body)[1]
@test ! isempty(o)
l_straight = sqrt((easting2 - easting1)^2 +(northing2 - northing1)^2)
@test o.metadata.lengde > l_straight
@test abs(l_straight / o.metadata.lengde - 1) < 0.01

# We need to make several requests in order to get e.g. 'fartsgrense'. 
# Let's grab the vegsystemreferanses. 
# For kommunal (K) and fylke (F), the kommunenr and fylkesnr
# together with the vegsystemreferanses form a unique ID.
Δl = map(o.vegnettsrutesegmenter) do s
    s.lengde
end
@test sum(Δl) ≈ o.metadata.lengde

knr = map(o.vegnettsrutesegmenter) do s
    s.kommune
end

vsrs = map(o.vegnettsrutesegmenter) do s
    r = s.vegsystemreferanse
    @assert r.vegsystem.fase == "V" # Existing
    r.kortform
end
multi_linestring = Vector{Vector{Tuple{Float64, Float64, Float64}}}()
multi_linestring = map(o.vegnettsrutesegmenter) do s
    map(split(s.geometri.wkt[14:end-1], ',')) do v
        NTuple{3, Float64}(tryparse.(Float64, split(strip(v), ' ')))
    end
end

# Check C0 continuity
previousend = (0.0, 0.0, 0.0)
for (i, ls) in enumerate(multi_linestring)
    global previousend
    thisstart = ls[1]
    println(thisstart)
    thisend = ls[end]
    if i > 1 
        @assert thisstart == previousend
    end
    previousend = thisend
end


function length_of_projected_linestring(ls::Vector{Tuple{Float64, Float64, Float64}})
    l = 0.0
    prevpt = ls[1]
    for pt in ls[2:end]
        Δx = pt[1] - prevpt[1]
        Δy = pt[2] - prevpt[2]
        l += hypot(Δx, Δy)
        prevpt = pt
    end
    l
end


Δl_linestrings = map(length_of_projected_linestring, multi_linestring)

abs.(Δl .- Δl_linestrings)


# FV61 S5D1 m1281-1401 Dragsundbrua aust

northing1 = 6939377.37 
easting1 = 25468    
northing2 = 6939333.54
easting2 = 25363.46
body = Dict([
    :typeveg                => "enkelbilveg"
    :konnekteringslenker    => false
    :start                  => "$easting1 , $northing1"
    :trafikantgruppe        => "K"
    :detaljerte_lenker      => false
    :behold_trafikantgruppe => true
    :slutt                  => "$easting2 , $northing2"
    :tidspunkt              => "2023-07-28"])

o = nvdb_request(url_ext, "POST"; body)[1]
multi_linestring = map(o.vegnettsrutesegmenter) do s
    map(split(s.geometri.wkt[14:end-1], ',')) do v
        NTuple{3, Float64}(tryparse.(Float64, split(strip(v), ' ')))
    end
end
ls = multi_linestring[1]
l3d = length_of_linestring(ls)
l2d = length_of_projected_linestring(ls)
@test round(l3d; digits = 3) == o.metadata.lengde
@test round(l2d; digits = 3) < o.metadata.lengde