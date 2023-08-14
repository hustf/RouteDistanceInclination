using Test
using RouteSlopeDistance
using RouteSlopeDistance: LOGSTATE, nvdb_request, get_vegobjekter__vegobjekttypeid_,
    fartsgrense_from_prefixed_vegsystemreferanse, is_segment_relevant, extract_from_to_meter,
    extract_strekning_delstrekning
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
       "1517 FV61 S3D1 m477-481"
       "1516 FV61 S4D1 m4731-5230"
       "1515 FV654 S2D1 m2967-3028"
       "1516 FV61 S3D30 m1136-1136"
       "1516 FV61 S4D1 m2608-2659"
       "1515 FV654 S1D1 m0-6"
       ]
ref = refs[9]
ref_from, ref_to = extract_from_to_meter(ref)
o = get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, ref; inkluder = "egenskaper,vegsegmenter")
@test hasproperty(o, :objekter)
@test length(o) == 2
vegsegmenter1 = o.objekter[1].vegsegmenter;
@test length(vegsegmenter1) == 1 ref
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
ref_from, ref_to = extract_from_to_meter(ref)
o = get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, ref; inkluder = "egenskaper,vegsegmenter")
vs = o.objekter[1].vegsegmenter;
@test ! is_segment_relevant(ref, vs[1])
@test is_segment_relevant(ref, vs[2])
@test ! is_segment_relevant(ref, vs[3])


ref = refs[8]
ref_from, ref_to = extract_from_to_meter(ref)
o = get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, ref; inkluder = "egenskaper,vegsegmenter")
vs = o.objekter[1].vegsegmenter;
@test ! is_segment_relevant(ref, vs[1])
@test is_segment_relevant(ref, vs[2])
@test ! is_segment_relevant(ref, vs[3])

ref = refs[18]
ref_from, ref_to = extract_from_to_meter(ref)
@test extract_strekning_delstrekning(ref) == "S1D1"
@test extract_strekning_delstrekning("FV654 S1D1 m0-6") == "S1D1"
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


# Tests on a higher level
ref = refs[9]
@test fartsgrense_from_prefixed_vegsystemreferanse(ref) == (0.2545454545454545, 50, 60)
ref = refs[5]
@test fartsgrense_from_prefixed_vegsystemreferanse(ref) == (1.0, 50, 50)
ref = refs[1]
@test isnan(fartsgrense_from_prefixed_vegsystemreferanse(ref)[1])
ref = refs[16]
@test isnan(fartsgrense_from_prefixed_vegsystemreferanse(ref)[1])
ref = refs[17]
@test fartsgrense_from_prefixed_vegsystemreferanse(ref) == (1.0, 70, 70) 
ref = refs[14]
@test fartsgrense_from_prefixed_vegsystemreferanse(ref) == (0.8471042084168335, 70, 60)
ref = refs[15]
@test fartsgrense_from_prefixed_vegsystemreferanse(ref) == (1.0, 60, 60)
ref = refs[6]
@test fartsgrense_from_prefixed_vegsystemreferanse(ref) == (1.0, 50, 50)
ref = refs[8]
@test fartsgrense_from_prefixed_vegsystemreferanse(ref) == (1.0, 50, 50)


@test fartsgrense_from_prefixed_vegsystemreferanse.(refs) isa Vector{Tuple{Float64, Int64, Int64}} 

