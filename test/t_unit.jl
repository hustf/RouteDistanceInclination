using Test
using RouteSlopeDistance
using RouteSlopeDistance: LOGSTATE, correct_to_increasing_distance
import HTTP
using JSON3: pretty

body = """{
    "start": "226761.786,6564469.3787 eller 0.1@1234",
    "slutt": "226855.034,6564472.225 eller 0.9@4321",
    "geometri": "LINESTRING Z(226778.2 6564468.6 5, 226747.1 6564470.1 5, 226717.5 6564466.4 5, 226705.9 6564462.7 6.2, 226687.2 6564462.9 6, 226657.7 6564460.7 6, 226628.5 6564459.5 6, 226611.3 6564459.6 6.2)",
    "maks_avstand": 10,
    "omkrets": 100,
    "konnekteringslenker": false,
    "detaljerte_lenker": false,
    "kortform": false,
    "vegsystemreferanse": "string",
    "trafikantgruppe": "string",
    "behold_trafikantgruppe": false,
    "typeveg": "string",
    "tidspunkt": "2023-07-28",
    "tidspunkt_start": "2023-07-28",
    "tidspunkt_slutt": "2023-07-28"
  }"""
method = "POST"
url_ext = "beta/vegnett/rute"
url = "$(RouteSlopeDistance.BASEURL)$url_ext"
idfields = RouteSlopeDistance.get_nvdb_fields(body)
# The body contents are slightly off.
@test_throws HTTP.Exceptions.StatusError HTTP.request(method, url, idfields, body)
@test isempty(nvdb_request(url_ext, "POST"; body)[1])

body = Dict([
    :start                  => "226761.786,6564469.3787" # eller 0.1@1234"
    :slutt                  => "226855.034,6564472.225" # eller 0.9@4321"
    :geometri               => "LINESTRING Z(226778.2 6564468.6 5, 226747.1 6564470.1 5, 226717.5 6564466.4 5, 226705.9 6564462.7 6.2, 226687.2 6564462.9 6, 226657.7 6564460.7 6, 226628.5 6564459.5 6, 226611.3 6564459.6 6.2)"
    :maks_avstand           => 10
    :omkrets                => 100
    :konnekteringslenker    => false
    :detaljerte_lenker      => false
    :kortform               => false
    :vegsystemreferanse     => "string"
    :trafikantgruppe        => "string"
    :behold_trafikantgruppe => false
    :typeveg                => "string"
    :tidspunkt              => "2023-07-28"
    :tidspunkt_start        => "2023-07-28"
    :tidspunkt_slutt        => "2023-07-28"])

@test isempty(nvdb_request(url_ext, "POST"; body)[1])

# Now that the requests are generally understood, we don't need to print our 
# request to screen as long as it is accepted.
LOGSTATE.authorization = false
LOGSTATE.request_string = false
# We modify the body based on printed feedback 
push!(body, :trafikantgruppe => "K")
push!(body, :behold_trafikantgruppe => true)
@test isempty(nvdb_request(url_ext, "POST"; body)[1])
push!(body, :typeveg => "enkelbilveg")
@test isempty(nvdb_request(url_ext, "POST"; body)[1])
pop!(body, :vegsystemreferanse)

o = nvdb_request(url_ext, "POST"; body)[1]
@test ! isempty(o)
l_straight = sqrt((226761.786 - 226855.034)^2 +(6564469.3787 - 6564472.225)^2)
@test abs(o.metadata.lengde / 167 - 1) < 0.01

# Does the "eller 0.1@1234" change the meaning of 'start?
push!(body, :start => "226761.786,6564469.3787 eller 0.1@1234")
o1 = nvdb_request(url_ext, "POST"; body)[1]
@test o.metadata.lengde == o1.metadata.lengde
push!(body, :start => "226761.786,6564469.3787")

# Is 'geometri' just an added restriction?
pop!(body, :geometri)
o1 = nvdb_request(url_ext, "POST"; body)[1]
@test o.metadata.lengde > o1.metadata.lengde
@test l_straight < o1.metadata.lengde
@test abs(l_straight / o1.metadata.lengde - 1) < 0.01

# 226761.786,6564469.3787 is in UTM33, which is used for nation wide data.
# The local zone for Sandefjord is UTM32. Do we have a choice?
push!(body, :srid => "utm32")
push!(body, :start => "570008.7,6555325.74") # Same place, in UTM32
push!(body, :slutt => "570101.23,6555336.94") # Same place, in UTM32
@test isempty(nvdb_request(url_ext, "POST"; body)[1]) # "message": "Expected SRID 5973, but was 5972"
pop!(body, :srid)
o2 = nvdb_request(url_ext, "POST"; body)[1]
@test o2.metadata.status_tekst == "IKKE_FUNNET_STARTPUNKT"
# Conclusion: 'start' and 'slutt' must be in UTM33 (or a higher resolution equivalent)

ref = "1516 KV1123 S1D1 m1818-1860"
@test correct_to_increasing_distance(ref) == ref
ref = "1516 KV1123 S1D1 m1818-1769"
@test correct_to_increasing_distance(ref) == "1516 KV1123 S1D1 m1769-1818"
ref = "KV1123 S1D1 m1818-1860"
@test correct_to_increasing_distance(ref) == ref
ref = "KV1123 S1D1 m1818-1769"
@test correct_to_increasing_distance(ref) == "KV1123 S1D1 m1769-1818"
