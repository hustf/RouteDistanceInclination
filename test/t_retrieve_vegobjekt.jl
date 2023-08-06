using Test
using RouteSlopeDistance
using RouteSlopeDistance: LOGSTATE, nvdb_request, get_vegobjekter__vegobjekttypeid_
import HTTP
using JSON3: pretty
# We don't need to print our
# request to screen as long as it is accepted.
#LOGSTATE.authorization = false
#LOGSTATE.request_string = false
#knr = [1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517]
#fnr = [15, 15, 15, 15, 15, 15, 15, 15]
#vsrs = ["FV61 S3D1 m2232-2237", "FV61 S3D1 m2237-2315", "FV61 S3D1 m2315-2423", "FV61 S3D1 m2423-2524", "FV61 S3D1 m2524-2603", "FV61 S3D1 m2603-2618", "FV61 S3D1 m2618-2666", "FV61 S3D1 m2666-2724"]

# From east of Dragsundbrua to Myrvågvegen.
refs = ["1516 FV61 S5D1 m1085-1273"
       "1516 FV61 S5D1 m1273-1281"
       "1516 FV61 S5D1 m1281-1401"
       "1515 FV61 S5D1 m1401-1412"
       "1515 FV61 S5D1 m1412-1527"
       "1515 FV61 S5D1 m1527-1589"
       "1515 FV61 S5D1 m1589-1879"]
Δls = [ 188.03
        8.272
        119.985
        10.372
        115.47
        61.977
        290.123]
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
@test vegobjekttype_id == 825


i = 1
ref = refs[i]
Δl = Δls[i]
url = "vegobjekter/$vegobjekttype_id?&vegsystemreferanse=$ref"
o = nvdb_request(url)[1]
# This first part is divided into downhill and uphill
@test o.metadata.antall == 2
subref_ids = map(o.objekter) do s
    s.id
end
j = 2
url = "vegobjekter/$vegobjekttype_id/$(subref_ids[j])/1"
sub_o = nvdb_request(url)[1]
@test length(sub_o.egenskaper) == 3
@test sub_o.egenskaper[2].verdi == 6.6
@test sub_o.egenskaper[2].enhet.navn == "Prosent"
@test sub_o.lokasjon.lengde == 220.495
Δh = 0.01 *  sub_o.egenskaper[2].verdi * sub_o.lokasjon.lengde
@test startswith(sub_o.geometri.wkt, "LINESTRING Z(")
wkt = map(split(sub_o.geometri.wkt[14:end-1], ',')) do v
    NTuple{3, Float64}(tryparse.(Float64, split(strip(v), ' ')))
end
@test abs(wkt[end][3] - wkt[1][3] - Δh ) < 1

#
j = 1
url = "vegobjekter/$vegobjekttype_id/$(subref_ids[j])/1"
sub_o = nvdb_request(url)[1]
@test hasproperty(sub_o, :lokasjon)
@test length(sub_o.egenskaper) == 3
@test hasproperty(sub_o.egenskaper[2], :verdi)
@test sub_o.egenskaper[2].enhet.navn == "Prosent"
@test hasproperty(sub_o.lokasjon, :lengde)
@test startswith(sub_o.geometri.wkt, "LINESTRING Z(")
@test hasproperty(sub_o, :geometri)
# Parse text to number collection
linestring = map(split(sub_o.geometri.wkt[14:end-1], ',')) do v
    NTuple{3, Float64}(tryparse.(Float64, split(strip(v), ' ')))
end
# For checking that subdivisions sum up to the total.
sub_Δl = sub_o.lokasjon.lengde
@test sub_Δl + 220.495 == Δls[i]
# Check that subdivision inclination is average from start to end
inclination = 0.01 * sub_o.egenskaper[2].verdi  # Percent is unimpressive
Δh = inclination * sub_Δl
@test abs(linestring[end][3] - linestring[1][3] - Δh ) < 1


#
# Test get_vegobjekter__vegobjekttypeid_
#


get_vegobjekter__vegobjekttypeid_(refs, Δls)








#=


# Pack arguments in a url
url = """vegobjekter/825/?vegsystemreferanse=FV16S3D1&fylke=15&strekning='m2232-2237'"""
o = nvdb_request(url)[1]  # "Ukjent parameter: strekning"
@test isempty(o)

# It seems packing in an url might work. Let's work.
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
##
##
# Look a bit more on inclination
vegobjekttype_id = catalogue["Kurvatur, stigning"][:id]
url = "vegobjekter/$vegobjekttype_id?fylke=$(fnr[4])&kommune=$(knr[4])&vegsystemreferanse=$(vsrs[4])"
o = nvdb_request(url)[1]
@test length(o.objekter) == 2
referred_urls = map(o.objekter) do obj
    "vegobjekter/$vegobjekttype_id/$(obj.id)/1"
end

s1 = nvdb_request(referred_urls[1])[1]
s2 = nvdb_request(referred_urls[2])[1]
=#