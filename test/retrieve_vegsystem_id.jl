using Test
using RouteSlopeDistance
using RouteSlopeDistance: LOGSTATE
import HTTP
using JSON3: pretty
# We don't need to print our 
# request to screen as long as it is accepted.
LOGSTATE.authorization = false
LOGSTATE.request_string = false

url_ext = "beta/vegnett/rute"

northing1 = 6.947308159359314e6 # Grimstad aust bus stop in UTM33
easting1 = 34865.66712469625    # Grimstad aust bus stop in UTM33
northing2 = 6.94710510180928e6  # Grimstad vest bus stop in UTM33
easting2 = 34417.88533130888    # Grimstad vest bus stop in UTM33


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
fnr = map(o.vegnettsrutesegmenter) do s
    s.fylke
end
vsrs = map(o.vegnettsrutesegmenter) do s
    r = s.vegsystemreferanse
    @assert r.vegsystem.fase == "V" # Existing
    r.kortform
end

