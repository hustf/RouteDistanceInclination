using Test
using RouteSlopeDistance
using RouteSlopeDistance: LOGSTATE, nvdb_request, get_vegobjekter__vegobjekttypeid_,
    fartsgrense_from_prefixed_vegsystemreferanse, is_segment_relevant, extract_from_to_meter,
    extract_strekning_delstrekning, extract_prefixed_vegsystemreferanse,
    extract_kategori_fase_nummer, extract_at_meter
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

ref_from, ref_to = extract_from_to_meter(refs[1])
@test ref_from == 1085
@test ref_to == 1273

# First get the catalogue of the ~400 types of info we can ask for
url_ext = "vegobjekttyper"
catalogue_obj = nvdb_request(url_ext)[1]
catalogue = Dict(map(catalogue_obj) do o
    o.navn => Dict(o)
end)
#print.(lpad.(sort(collect(keys(catalogue))), 40));
catalogue["Fartsgrense"]
catalogue["Fartsdemper"]
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
@test egenskap.enhet.navn == "Kilometer/time"
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
@test fartsgrense_from_prefixed_vegsystemreferanse(refs[1], false) == (1.0, 60, 60)
@test fartsgrense_from_prefixed_vegsystemreferanse(refs[end], false) == (1.0, 80, 80)
@test fartsgrense_from_prefixed_vegsystemreferanse.(refs, false) isa Vector{Tuple{Float64, Int64, Int64}}
@test fartsgrense_from_prefixed_vegsystemreferanse(refs[6], false) == (0.1086935483870973, 60, 80)
@test fartsgrense_from_prefixed_vegsystemreferanse(refs[6], true) == (0.8913064516129027, 80, 60)


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
       "1517 FV61 S3D1 m477-481"
       "1516 FV61 S4D1 m4731-5230"
       "1515 FV654 S2D1 m2967-3028"
       "1516 FV61 S3D30 m1136-1136"
       "1516 FV61 S4D1 m2608-2659"
       "1515 FV654 S1D1 m0-6"
       "1515 FV5876 S1D1 m82 SD1 m9-29"
       "1516 FV61 S4D1 m5398 SD2 m85-104"
       ]
ref = refs[9]
@test extract_from_to_meter(ref) == (370, 425)
@test extract_kategori_fase_nummer(ref) == "FV61"
o = get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, ref; inkluder = "egenskaper,vegsegmenter")
@test hasproperty(o, :objekter)
@test length(o) == 2
vegsegmenter1 = o.objekter[1].vegsegmenter;
@test length(vegsegmenter1) == 1
@test hasproperty(o.objekter[2], :vegsegmenter)
vegsegmenter2 = o.objekter[2].vegsegmenter
@test length(vegsegmenter2) == 3
# We have four vegsegmenter, but we have only 
# two fartsgrense. Need filtering!
vs = [vegsegmenter1[1], vegsegmenter2[1], vegsegmenter2[2], vegsegmenter2[3]]
@test is_segment_relevant(ref, vs[1]) 
@test ! is_segment_relevant(ref, vs[2]) 
@test ! is_segment_relevant(ref, vs[3]) 
@test is_segment_relevant(ref, vs[4]) 


ref = refs[6]
@test extract_from_to_meter(ref) == (143,161)
@test extract_kategori_fase_nummer(ref) == "FV61"
o = get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, ref; inkluder = "egenskaper,vegsegmenter")
vs = o.objekter[1].vegsegmenter;
@test ! is_segment_relevant(ref, vs[1])
@test is_segment_relevant(ref, vs[2])
@test ! is_segment_relevant(ref, vs[3])


ref = refs[8]
@test extract_from_to_meter(ref) == (270, 370)
@test extract_kategori_fase_nummer(ref) == "FV61"
o = get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, ref; inkluder = "egenskaper,vegsegmenter")
vs = o.objekter[1].vegsegmenter;
@test ! is_segment_relevant(ref, vs[1])
@test is_segment_relevant(ref, vs[2])
@test ! is_segment_relevant(ref, vs[3])


ref = refs[18]
@test extract_from_to_meter(ref) == (0, 6)
@test extract_kategori_fase_nummer(ref) == "FV654"
@test extract_strekning_delstrekning(ref) == "S1D1"
o = get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, ref; inkluder = "egenskaper,vegsegmenter")
vs = o.objekter[1].vegsegmenter;
@test length(vs) == 7
@test is_segment_relevant(ref, vs[1])
@test ! is_segment_relevant(ref, vs[2])
@test ! is_segment_relevant(ref, vs[3])
@test ! is_segment_relevant(ref, vs[4])
@test ! is_segment_relevant(ref, vs[5])
@test ! is_segment_relevant(ref, vs[6])
@test ! is_segment_relevant(ref, vs[7])


# 'Krysssystem' 
ref = refs[1]
@test extract_from_to_meter(ref) == (9, 13)
@test extract_kategori_fase_nummer(ref) == "FV61"
@test extract_strekning_delstrekning(ref) == "S3D1"
o = get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, ref; inkluder = "egenskaper,vegsegmenter")
vs = o.objekter[1].vegsegmenter;
@test length(vs) == 1
@test is_segment_relevant(ref, vs[1])

# 'Sideanlegg' 
ref = refs[19]
@test extract_from_to_meter(ref) == (9, 29)
@test extract_kategori_fase_nummer(ref) == "FV5876"
@test extract_strekning_delstrekning(ref) == "S1D1"
o = get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, ref; inkluder = "egenskaper,vegsegmenter")
vs = o.objekter[1].vegsegmenter;
@test length(vs) == 2
@test ! is_segment_relevant(ref, vs[1])
@test is_segment_relevant(ref, vs[2])

ref = refs[5]
@test extract_from_to_meter(ref) == (86, 143)
@test extract_kategori_fase_nummer(ref) == "FV61"
@test extract_strekning_delstrekning(ref) == "S3D1"
o = get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, ref; inkluder = "egenskaper,vegsegmenter")
vs = o.objekter[1].vegsegmenter;
@test length(vs) == 3
@test is_segment_relevant(ref, vs[1])
@test ! is_segment_relevant(ref, vs[2])
@test ! is_segment_relevant(ref, vs[3])


ref = refs[20]
@test extract_from_to_meter(ref) == (85, 104)
@test extract_kategori_fase_nummer(ref) == "FV61"
@test extract_strekning_delstrekning(ref) == "S4D1"
o = get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, ref; inkluder = "egenskaper,vegsegmenter")
vs = o.objekter[1].vegsegmenter;
@test length(vs) == 10
@test ! is_segment_relevant(ref, vs[1])
@test ! is_segment_relevant(ref, vs[2])
@test ! is_segment_relevant(ref, vs[3])
@test  is_segment_relevant(ref, vs[4])
@test ! is_segment_relevant(ref, vs[5])
@test ! is_segment_relevant(ref, vs[6])
@test ! is_segment_relevant(ref, vs[7])
@test ! is_segment_relevant(ref, vs[8])
@test ! is_segment_relevant(ref, vs[9])
@test ! is_segment_relevant(ref, vs[10])








# Tests on a higher level
ref = refs[9]
@test fartsgrense_from_prefixed_vegsystemreferanse(ref, false) == (0.2545454545454545, 50, 60)
@test fartsgrense_from_prefixed_vegsystemreferanse(ref, true) == (0.7454545454545455, 60, 50)
ref = refs[5]
@test fartsgrense_from_prefixed_vegsystemreferanse(ref, false) == (1.0, 50, 50)
@test fartsgrense_from_prefixed_vegsystemreferanse(ref, true) == (1.0, 50, 50)
ref = refs[1]
@test fartsgrense_from_prefixed_vegsystemreferanse(ref, false) == (1.0, 50, 50)
ref = refs[16]
@test isnan(fartsgrense_from_prefixed_vegsystemreferanse(ref, false)[1])
ref = refs[17]
@test fartsgrense_from_prefixed_vegsystemreferanse(ref, false) == (1.0, 70, 70) 
ref = refs[14]
@test fartsgrense_from_prefixed_vegsystemreferanse(ref, false) == (0.8471042084168335, 70, 60)
ref = refs[15]
@test fartsgrense_from_prefixed_vegsystemreferanse(ref, false) == (1.0, 60, 60)
ref = refs[6]
@test fartsgrense_from_prefixed_vegsystemreferanse(ref, false) == (1.0, 50, 50)
ref = refs[8]
@test fartsgrense_from_prefixed_vegsystemreferanse(ref, false) == (1.0, 50, 50)
ref = refs[20]
@test fartsgrense_from_prefixed_vegsystemreferanse(ref, false) == (1.0, 50, 50)

@test fartsgrense_from_prefixed_vegsystemreferanse.(refs, false) isa Vector{Tuple{Float64, Int64, Int64}} 



# Fartsdemper. These are few, and we can test out other ways to find those than
# making a request per each and every lenke.
catalogue["Fartsdemper"][:id]
vegobjekttype_id = 103
kommune = 1517
o = get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, ""; kommune, inkluder = "vegsegmenter")
@test o.metadata.antall == 2
@test o.objekter[1].vegsegmenter[1].vegsystemreferanse.kortform == "FV61 S3D1 m3593"
@test o.objekter[2].vegsegmenter[1].vegsystemreferanse.kortform == "FV61 S3D1 m3398"

kommune = "1516"
o = get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, ""; kommune, inkluder = "vegsegmenter,egenskaper")
@test o.metadata.antall == 5
@test o.objekter[1].vegsegmenter[1].vegsystemreferanse.kortform == "FV5882 S1D1 m254"
@test o.objekter[2].vegsegmenter[1].vegsystemreferanse.kortform == "FV5882 S1D1 m158"
@test o.objekter[3].vegsegmenter[1].vegsystemreferanse.kortform == "FV5882 S1D1 m66"
@test o.objekter[4].vegsegmenter[1].vegsystemreferanse.kortform == "FV5884 S1D1 m1320"
@test o.objekter[5].vegsegmenter[1].vegsystemreferanse.kortform == "FV5884 S1D1 m1445"

for obj in o.objekter
     profilegenskaper = filter(e->e.navn == "Profil", obj.egenskaper)
     if length(profilegenskaper) == 1
        profil = profilegenskaper[1]
        println(profil[:verdi])
     else
        @show obj.egenskaper
     end
end

# Since not all fartshumper have interesting properties registered, maybe just
# apply a 15 km/h speed reduction......
# In that case, use: 
o = get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, ""; kommune, inkluder = "vegsegmenter")

fartshumper = String[]
for obj in o.objekter
    @test hasproperty(obj, :vegsegmenter)
    @test length(obj.vegsegmenter) == 1
    vegsegment = obj.vegsegmenter[1]
    @test hasproperty(vegsegment, :vegsystemreferanse)
    vegsystemreferanse = vegsegment.vegsystemreferanse
    @test hasproperty(vegsystemreferanse, :kortform)
    push!(fartshumper, vegsystemreferanse.kortform)
end
all_bumpd = extract_prefixed_vegsystemreferanse(o)
