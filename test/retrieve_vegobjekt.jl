using Test
using RouteSlopeDistance
using RouteSlopeDistance: LOGSTATE
import HTTP
using JSON3: pretty
# We don't need to print our 
# request to screen as long as it is accepted.
LOGSTATE.authorization = false
LOGSTATE.request_string = false
knr = [1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517]
fnr = [15, 15, 15, 15, 15, 15, 15, 15]
vsrs = ["FV61 S3D1 m2232-2237", "FV61 S3D1 m2237-2315", "FV61 S3D1 m2315-2423", "FV61 S3D1 m2423-2524", "FV61 S3D1 m2524-2603", "FV61 S3D1 m2603-2618", "FV61 S3D1 m2618-2666", "FV61 S3D1 m2666-2724"]
#
# First get the catalogue of the ~400 types of info we can ask for
url_ext = "vegobjekttyper"
catalogue_obj = nvdb_request(url_ext)[1]
catalogue = Dict(map(catalogue_obj) do o
    o.navn => Dict(o)  
end)
print.(lpad.(sort(collect(keys(catalogue))), 40));

# We are interested in "Kurvatur, stigning"
url_ext = "vegobjekter/"
vegobjekttype_id = catalogue["Kurvatur, stigning"][:id]

# Pack arguments in a url
url = """vegobjekter/825/?vegsystemreferanse=FV16S3D1&fylke=15&strekning='m2232-2237'"""
o = nvdb_request(url)[1]  # "Ukjent parameter: strekning"
@test isempty(o)

# It seems packing in an url might work.
url = """vegobjekter/825/?fylke=15&vegsystemreferanse=FV16S3D1"""
o = nvdb_request(url)[1] 
@test o.metadata.antall == 0
# Work more on the url
url = """vegobjekter/825/?fylke=15&vegsystemreferanse=FV16S2-3"""
o = nvdb_request(url)[1] 
@test o.metadata.antall == 0

# The latest and greatest is
url = "vegobjekter/$vegobjekttype_id?fylke=$(fnr[1])&kommune=$(knr[1])&vegsystemreferanse=$(vsrs[1])"
o = nvdb_request(url)[1]
@test o.metadata.antall == 1
url = "vegobjekter/$vegobjekttype_id/$(o.objekter[1].id)/1"
o = nvdb_request(url)[1]
@test length(o.egenskaper) == 3
@test o.egenskaper[2].verdi == -0.2
@test o.egenskaper[1].innhold[1].retning == "MED"

# Nice, we can use that. We need other properties, too. So try to ask for "Fartsgrense":
vegobjekttype_id = catalogue["Fartsgrense"][:id]
url = "vegobjekter/$vegobjekttype_id?fylke=$(fnr[1])&kommune=$(knr[1])&vegsystemreferanse=$(vsrs[1])"
o = nvdb_request(url)[1]
@test o.metadata.antall == 1
url = "vegobjekter/$vegobjekttype_id/$(o.objekter[1].id)/1"
o = nvdb_request(url)[1]
@test length(o.egenskaper) == 4
@test o.egenskaper[3].navn == "Fartsgrense"
@test o.egenskaper[3].verdi == 60
@test o.egenskaper[1].innhold[1].retning == "MED"
