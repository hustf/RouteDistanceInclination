using Test
using RouteSlopeDistance
using RouteSlopeDistance: patched_post_beta_vegnett_rute, coordinate_key, get_config_value
using RouteSlopeDistance: corrected_coordinates, link_split_key
using RouteSlopeDistance: extract_length, extract_multi_linestrings, extract_prefixed_vegsystemreferanse
using RouteSlopeDistance: reverse_linestrings_where_needed!
using RouteSlopeDistance: Quilt, amend_fromtos!
using RouteSlopeDistance: build_fromtos!, correct_coordinates!, build_patches!
M = ["Hareid bussterminal" 36976 6947659; "Hareid ungdomsskule fv. 61" 36533 6947582; "Holstad" 35983 6947673; "Grimstad aust" 35465 6947468; "Grimstad vest" 34866 6947308; "Bjåstad aust" 34418 6947105; "Bjåstad vest" 34054 6946887; "Bigsetkrysset" 33729 6946682; "Byggeli" 33142 6946489; "Nybøen" 32852 6946449; "Korshaug" 32344 6946360; "Rise aust" 31909 6946301; "Rise" 31515 6946166; "Rise vest" 31167 6946060; "Varleitekrysset" 29426 6945335; "Ulstein vgs." 28961 6945248; "Støylesvingen" 28275 6945289; "Holsekerdalen" 27714 6945607; "Ulsteinvik skysstasjon" 27262 6945774; "Saunes nord" 27457 6945077; "Saunes sør" 27557 6944744; "Strandabøen" 27811 6944172; "Dimnakrysset" 27721 6943086; "Botnen" 26807 6941534; "Garneskrysset" 26449 6940130; "Dragsund sør" 24823 6939041; 
"Myrvåglomma" 23911 6938921; "Myrvåg" 23412 6939348; "Aurvåg" 22732 6939786; "Aspevika" 22119 6939611; "Kalveneset" 21508 6939662; "Tjørvåg indre" 20671 6939661; "Tjørvåg" 20296 6939961; "Tjørvågane" 20222 6940344; "Tjørvåg nord" 20408 6940732; "Rafteset" 20794 6941312; "Storneset" 20779 6941912; "Stokksund" 20353 6942412; "Notøy" 19429 6943497; "Røyra øst" 19922 6944583; "Røyra vest" 19605 6944608; "Frøystadvåg" 19495 6945400; "Frøystadkrysset" 19646 6945703; "Nerøykrysset" 18739 6946249; "Berge bedehus" 17919 6946489; "Elsebøvegen" 17680 6946358; "Verket" 17441 6946183; "Berge" 17255 6946053; "Hjelmeset" 16949 6945880; "Demingane" 16575 6945717; "Eggesbønes" 16078 6945699; "Myklebust" 16016 6945895; "Herøy kyrkje" 16156 6946651; "Fosnavåg sparebank" 16235 6947271; "Fosnavåg terminal" 16064 6947515]
# Unit test amend_fromtos!
# This relies on pathces defined in init file for testing purpose.
q = Quilt()
push!(q.fromtos, [1, 1, 5, 5]) 
before = copy(q.fromtos)
amend_fromtos!(q, 1)
@test before !== q.fromtos
before = copy(q.fromtos)
amend_fromtos!(q, 1)
@test before == q.fromtos
amend_fromtos!(q, 2)
@test before !== q.fromtos
before = copy(q.fromtos)
amend_fromtos!(q, 3)
@test before !== q.fromtos
before = copy(q.fromtos)
amend_fromtos!(q, 4)
@test before == q.fromtos

# Unit test build_fromtos!
q = Quilt()
build_fromtos!(q, 1, 1, 5, 5)
@test q.fromtos == [[1, 1, 2, 2], [2, 2, 3, 3], [3, 3, 4, 4], [4, 4, 5, 5]]

@test_throws AssertionError patched_post_beta_vegnett_rute(1, 1, 5, 5)

# Test a defined single point replacement
start = 1
na1, ea1, no1 = M[start, :]
key = coordinate_key(false, ea1, no1)
@test ! isnothing(get_config_value("coordinates replacement", key, Tuple{Int64, Int64}; nothing_if_not_found = true))
cea, cno = corrected_coordinates(false, ea1, no1)
@test (cea, cno) !== (ea1, no1)
@test corrected_coordinates(true, ea2, no2) == (ea2, no2)
q = Quilt()
build_fromtos!(q, ea1, no1, ea2, no2)
correct_coordinates!(q)
@test length(q.fromtos) == 1
@test q.fromtos[1] == [cea, cno, ea2, no2]


# Test a non-defined single point replacement
start = 2
na1, ea1, no1 = M[start, :]
@test corrected_coordinates(false, ea1 + 1, no1) == (ea1 + 1, no1)

# Test a non-patched or point corrected segment. This also returns just one segment.
start = 5
stop = 6
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
@test build_fromtos!(Quilt(), ea1, no1, ea2, no2).fromtos == [[ea1, no1,ea2, no2]]
q = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2);
@test length(q.fromtos) == 1
@test length(q.patches) == 1
refs = extract_prefixed_vegsystemreferanse(q)
@test refs[1] == "1517 FV61 S3D1 m2231-2237"
Δls = extract_length(q)
@test length(Δls) == 8
mls, reversed = extract_multi_linestrings(q)
@test length(mls) == 8
@test mls isa Vector{Vector{Tuple{Float64, Float64, Float64}}}

# Request phrased in string. 
# Detecting reversion is hard for 3d, but works when dropping z
na1 = "Rise vest"
na2 = "Rise"
s = "(31167 6946060)-(31515 6946166)"
args = split(s, '-')
start = replace(strip(args[1], ['(', ')'] ), ' ' => ',')
slutt = replace(strip(args[2], ['(', ')'] ), ' ' => ',')
stea, stno = split(start, ',')
slea, slno = split(slutt, ',')
ea1 = Int(round(tryparse(Float64, stea)))
no1 = Int(round(tryparse(Float64, stno)))
ea2 = Int(round(tryparse(Float64, slea)))
no2 = Int(round(tryparse(Float64, slno)))
@test ea1 == 31167
@test no1 == 6946060
@test ea2 == 31515 
@test no2 == 6946166
q = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
@test length(q.patches) == 1
@test length(q.fromtos) == 1
@test q.fromtos[1] == [ea1, no1, ea2, no2]
o = q.patches[1]
ea, no = ea1, no1
multi_linestring = map(o.vegnettsrutesegmenter) do s
  ls = map(split(s.geometri.wkt[14:end-1], ',')) do v
      NTuple{3, Float64}(tryparse.(Float64, split(strip(v), ' ')))
  end
end
reversed = reverse_linestrings_where_needed!(multi_linestring, ea, no)
@test reversed == [true, true, true, true]


# Test a patched segment, Notøy -> Røyra øst
start = 39
stop = 40
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
key = link_split_key(ea1, no1, ea2, no2)
insertpos = get_config_value("link split", key, Tuple{Float64, Float64}, nothing_if_not_found = true)
q = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
refs = extract_prefixed_vegsystemreferanse(q)
@test refs[1] == "1515 FV654 S3D1 m1065 SD1 m5-7"
Δls = extract_length(q)
@test sum(Δls) > 2000 && sum(Δls) < 2030
@test length(Δls) == 12
mls, reversed = extract_multi_linestrings(q)
@test length(mls) == 12
@test mls isa Vector{Vector{Tuple{Float64, Float64, Float64}}}

# Test a segment with a replaced coordinate, Holsekerdalen -> Ulsteinvik skysstasjon
start = 18
stop = 19
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
key = link_split_key(ea1, no1, ea2, no2)
insertpos = get_config_value("link split", key, Tuple{Float64, Float64}, nothing_if_not_found = true)
@test isnothing(insertpos)
key = coordinate_key(true, ea2, no2)
replaced_pos = get_config_value("coordinates replacement", key, Tuple{Int64, Int64}; nothing_if_not_found = true)
@test ! isnothing(replaced_pos)
@test corrected_coordinates(true, ea2, no2) !== (ea2, no2)
q =  patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
Δls = extract_length(q)
@test length(Δls) == 16
@test sum(Δls) > 555 && sum(Δls) < 560 

# Test a segment with a patched segment, Botnen -> Garneskrysset and also replaced end coordinate.
start = 24
stop = 25
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
key = link_split_key(ea1, no1, ea2, no2)
insertpos = get_config_value("link split", key, Tuple{Float64, Float64}, nothing_if_not_found = true)
@test ! isnothing(insertpos)
key = coordinate_key(true, ea2, no2)
replaced_pos = get_config_value("coordinates replacement", key, Tuple{Int64, Int64}; nothing_if_not_found = true)
@test ! isnothing(replaced_pos)
@test corrected_coordinates(true, ea2, no2) !== (ea2, no2)
q = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2);
Δls = extract_length(q)
@test length(Δls) == 20
@test sum(Δls) > 2110 && sum(Δls) < 2120

# This uses the layer where we patch errors in finding routes.
rws = 1:(size(M)[1])
for (start, stop) in zip(rws[1: (end - 1)], rws[2:end])
    println()
    na1, ea1, no1 = M[start, :]
    na2, ea2, no2 = M[stop, :]
    print(lpad("$start $stop", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
    q = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
    refs = extract_prefixed_vegsystemreferanse(q)
    lengths = extract_length(q)
    for (r, l) in zip(refs, lengths)
         print(rpad(r, 35) , "  l = ",  l)
         print("\n", lpad(" ", 72))
    end
    println()
end

# This requires a second pass (at least):
M = [
        "Furene"  34704  6925611
   "Hovdevatnet"  34518  6927170
       "Sørheim"  32452  6930544
   "Eiksundbrua"  27963  6935576
         "Havåg"  27158  6935798
    "Ytre Havåg"  26698  6935841
        "Selvåg"  26436  6935972
    "Haddal sør"  27382  6938074
   "Haddal nord"  27280  6939081
  "Garneskrysset" 26449  6940130
]

# The hardest part is here:
start = 3
stop = 4
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
q = Quilt()
build_fromtos!(q, ea1, no1, ea2, no2)
display(q.fromtos)
correct_coordinates!(q)
build_patches!(q)



rws = 1:(size(M)[1])
for (start, stop) in zip(rws[1: (end - 1)], rws[2:end])
    println()
    na1, ea1, no1 = M[start, :]
    na2, ea2, no2 = M[stop, :]
    print(lpad("$start $stop", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
    q = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
    refs = extract_prefixed_vegsystemreferanse(q)
    lengths = extract_length(q)
    for (r, l) in zip(refs, lengths)
         print(rpad(r, 35) , "  l = ",  l)
         print("\n", lpad(" ", 72))
    end
    println()
end


