using Test
using RouteSlopeDistance
using RouteSlopeDistance: LOGSTATE, nvdb_request, get_vegobjekter__vegobjekttypeid_, fartsgrense_from_prefixed_vegsystemreferanse
import HTTP
using JSON3: pretty

# From east of Dragsundbrua to Myrvågvegen.
refs = ["1516 FV61 S5D1 m1085-1273"
       "1516 FV61 S5D1 m1273-1281"
       "1516 FV61 S5D1 m1281-1401"
       "1515 FV61 S5D1 m1401-1412"
       "1515 FV61 S5D1 m1412-1527"
       "1515 FV61 S5D1 m1527-1589"
       "1515 FV61 S5D1 m1589-1879"]



# First get the catalogue of the ~400 types of info we can ask for
url_ext = "vegobjekttyper"
catalogue_obj = nvdb_request(url_ext)[1]
catalogue = Dict(map(catalogue_obj) do o
    o.navn => Dict(o)
end)
#print.(lpad.(sort(collect(keys(catalogue))), 40));
catalogue["Fartsgrense"]

# We are interested in "Fartsgrense"
url_ext = "vegobjekter/"
vegobjekttype_id = catalogue["Fartsgrense"][:id]
@test vegobjekttype_id == 105

# Get a value for one ref.
i = 1
ref = refs[i]
url = "vegobjekter/$vegobjekttype_id?&vegsystemreferanse=$ref"
o = nvdb_request(url)[1]
@test o.metadata.antall == 1
subref_ids = map(o.objekter) do s
    s.id
end
j = 1
url = "vegobjekter/$vegobjekttype_id/$(subref_ids[j])/1"
sub_o = nvdb_request(url)[1]
@test length(sub_o.egenskaper) == 4

egenskaper = filter(e->e.navn == "Fartsgrense", sub_o.egenskaper)
@test length(egenskaper) == 1
egenskap = egenskaper[1]
@test egenskap.enhet == "Kilometer/time"
@test egenskap.verdi == 60



# Now try to do this more effectively, with one call.
vegobjekttype_id = 105
inkluder = "egenskaper"
url = "vegobjekter/$vegobjekttype_id?&vegsystemreferanse=$ref&inkluder=$inkluder"
o = nvdb_request(url)[1]
@test o.metadata.antall == 1
@test length(o.objekter) == 1
egenskaper = o.objekter[1].egenskaper
@test length(egenskaper) == 5

fartsgrenser = filter(e->e.navn == "Fartsgrense", sub_o.egenskaper)
@test length(fartsgrenser) == 1
fartsgrense = fartsgrenser[1]
@test fartsgrense.enhet.navn == "Kilometer/time"
@test fartsgrense.verdi == 60

# Try to use the defined function
@test fartsgrense_from_prefixed_vegsystemreferanse(refs[1]) == (1.0, 60, 60)
@test fartsgrense_from_prefixed_vegsystemreferanse(refs[end]) == (1.0, 80, 80)
@test fartsgrense_from_prefixed_vegsystemreferanse.(refs) isa Vector{Tuple{Float64, Int64, Int64}}

# Step up the difficulty

refs =  ["1517 FV61 S3D1 m86 KD1 m9-13"
       "1517 FV61 S3D1 m86 KD1 m13-21"
       "1517 FV61 S3D1 m86 KD1 m21-29"
       "1517 FV61 S3D1 m86 KD1 m29-31"
       "1517 FV61 S3D1 m86-143"
       "1517 FV61 S3D1 m143-161"
       "1517 FV61 S3D1 m161-270"
       "1517 FV61 S3D1 m270-370"
       "1517 FV61 S3D1 m370-425"
       "1517 FV61 S3D1 m425-444"
       "1517 FV61 S3D1 m444-473"
       "1517 FV61 S3D1 m473-477"
       "1517 FV61 S3D1 m477-481"]

fartsgrense_from_prefixed_vegsystemreferanse.(refs) 

ref = refs[5]