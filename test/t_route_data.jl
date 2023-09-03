using Test
using RouteSlopeDistance
using RouteSlopeDistance: patched_post_beta_vegnett_rute, 
    extract_prefixed_vegsystemreferanse,
    extract_length,
    extract_multi_linestrings,
    fartsgrense_from_prefixed_vegsystemreferanse,
    speed_nested_in_intervals, 
    modify_fartsgrense_with_speedbumps!,
    link_split_key,
    progression_and_radii_of_curvature_from_multiline_string,
    smooth_slope_from_multiline_string
using JSON3: pretty


M = ["Hareid bussterminal" 36975.94566374121 6.947658805705906e6; "Hareid ungdomsskule fv. 61" 36532.55545087671 6.947581886945733e6; "Holstad" 35983.1443116063 6.947673163559002e6; "Grimstad aust" 35464.96463259688 6.947468011095509e6; "Grimstad vest" 34865.66712469625 6.947308159359314e6; "Bjåstad aust" 34417.88533130888 6.94710510180928e6; "Bjåstad vest" 34054.27868455148 6.946887317608121e6; "Bigsetkrysset" 33728.64367864374 6.946682380315655e6; "Byggeli" 33142.22175210371 6.946488830511735e6; "Nybøen" 32851.70907960052 6.946449354497116e6; "Korshaug" 32343.566099463962 6.946360408979714e6; "Rise aust" 31908.81277878303 6.946301439017767e6; "Rise" 31515.075405728596 6.946166435782562e6; "Rise vest" 31166.8812895664 6.946060114423563e6; "Varleitekrysset" 29426.092089441197 6.945334778036252e6; "Ulstein vgs." 28961.357645253593 6.945248138849279e6; "Støylesvingen" 28275.444230089895 6.945288942957118e6; "Holsekerdalen" 27714.179788790876 6.945606747071537e6; "Ulsteinvik skysstasjon" 27262.18078544963 6.945774337512597e6; "Saunes nord" 27457.300948846503 6.945077356432355e6; "Saunes sør" 27557.2207297993 6.944743999927791e6; "Strandabøen" 27810.953292181366 6.944172090808818e6; "Dimnakrysset" 27720.899809156603 6.943086326247893e6; "Botnen" 26807.34408127074 6.941533714193652e6; "Garneskrysset" 26448.894934401556 6.940129956181607e6; "Dragsund sør" 24823.194600016985 6.939041381131042e6; "Myrvåglomma" 23910.869586607092 6.938920557515621e6; "Myrvåg" 23411.547657008457 6.939347655974448e6; "Aurvåg" 22731.993701261526 6.939785509768682e6; "Aspevika" 22119.248180354887 6.939611088769487e6; "Kalveneset" 21507.79140086705 6.939661984886746e6; "Tjørvåg indre" 20670.579345440492 6.939661472948665e6; "Tjørvåg" 20295.777947708208 6.93996120795614e6; "Tjørvågane" 20222.213099840155 6.940343660939465e6; "Tjørvåg nord" 20407.956564288645 6.940731998657505e6; "Rafteset" 20793.75811150472 6.941312130095156e6; "Storneset" 20778.735032497556 6.941911649292342e6; "Stokksund" 20353.192697804363 6.94241189645477e6; "Notøy" 19428.907322990475 6.943496947023508e6; "Røyra øst" 19921.774665450328 6.944582534682405e6; "Røyra vest" 19604.993318945984 6.944607764588606e6; "Frøystadvåg" 19495.16047112737 6.94540013477574e6; "Frøystadkrysset" 19646.29224914976 6.9457027824882725e6; "Nerøykrysset" 18738.6739445625 6.946249249481636e6; "Berge bedehus" 17918.84676897031 6.946488791539114e6; "Elsebøvegen" 17679.55323949206 6.946358107562704e6; "Verket" 17441.2284281507 6.946183037961578e6; "Berge" 17254.861414988118 6.946052685186134e6; "Hjelmeset" 16948.82774523727 6.94588028132061e6; "Demingane" 16575.39314737235 6.945716940684748e6; "Eggesbønes" 16077.868413755263 6.94569855075708e6; "Myklebust" 16016.077339820331 6.945895007681623e6; "Herøy kyrkje" 16156.369994148146 6.946651348835291e6; "Fosnavåg sparebank" 16235.327457943466 6.94727099225032e6; "Fosnavåg terminal" 16063.782613804331 6.947514879242669e6]

rw = 8
na1, ea1, no1 = M[rw, :]
na2, ea2, no2 = M[rw + 1 , :]
println(lpad("$rw $(rw + 1)", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
easting1, northing1, easting2, northing2 = ea1, no1, ea2, no2

# Lookups are quite slow; we need to store results.
#
#  0.499989 seconds (1.30 k allocations: 276.625 KiB)
@time q = patched_post_beta_vegnett_rute(easting1, northing1, easting2, northing2);

#  0.000185 seconds (455 allocations: 52.797 KiB)
@time refs = extract_prefixed_vegsystemreferanse(q);

#  0.000119 seconds (139 allocations: 26.203 KiB)
@assert ! startswith(refs[1], "Error") refs[1];

#  0.000110 seconds (138 allocations: 26.141 KiB)
@time lengths = extract_length(q);

#   0.000010 seconds (3 allocations: 352 bytes)
progression_at_ends = append!([0.0], cumsum(lengths))

# 0.000389 seconds (608 allocations: 76.211 KiB)
@time mls, reversed = extract_multi_linestrings(q);

@test length(progression_at_ends) == length(mls) + 1

# 0.000280 seconds (1.96 k allocations: 181.469 KiB)
@time  progression, r = progression_and_radii_of_curvature_from_multiline_string(mls, progression_at_ends)

@test issorted(progression)
@test length(r) == length(progression)
slope = smooth_slope_from_multiline_string(mls, progression)
@test length(slope)  == length(progression)


#   8.807276 seconds (13.95 k allocations: 1.346 MiB)
@time fartsgrense_tuples = fartsgrense_from_prefixed_vegsystemreferanse.(refs, reversed)

if isnan(fartsgrense_tuples[1][1])
    fartsgrense_tuples[1] = (1.0, 50, 50)
end

#  0.000038 seconds (121 allocations: 13.375 KiB)
@time speed_lims_in_intervals = speed_nested_in_intervals(fartsgrense_tuples, mls)

# 1.197382 seconds (2.33 k allocations: 234.508 KiB)
@time modify_fartsgrense_with_speedbumps!(speed_lims_in_intervals, refs, mls)


# Unpack nested speed limitations. Apply at first coordinate of each interval (there is one more coordinate than intervals)
speed_limitation = vcat(speed_lims_in_intervals..., speed_lims_in_intervals[end][end])
@test length(progression) == length(speed_limitation) 


# Test 'overlapping' speed limit segments where we exit or enter a road:
ea1 = 38751
no1 = 6946371
no2 = 6946328
ea2 = 38786
d = route_data(ea1, no1, ea2, no2)
@test all(d[:speed_limitation] .== 40.0)


#########################
# Curvature - speed tests
# # This is moved out of package
#
#########################
#=
kalibrering = ["https://nvdbapiles-v3.atlas.vegvesen.no/beta/vegnett/rute?start=23593.713839066448,6942485.5900078565&slutt=23771.052968726202,6942714.9388697725&maks_avstand=10&omkrets=100&konnekteringslenker=true&detaljerte_lenker=false&behold_trafikantgruppe=false&pretty=true&kortform=true",
"https://nvdbapiles-v3.atlas.vegvesen.no/beta/vegnett/rute?start=10929.721370896965,6932488.729146618&slutt=10906.172339663783,6932221.839157347&maks_avstand=10&omkrets=100&konnekteringslenker=true&detaljerte_lenker=false&behold_trafikantgruppe=false&pretty=true&kortform=true",
"https://nvdbapiles-v3.atlas.vegvesen.no/beta/vegnett/rute?start=38744.875253753446,6946346.347827989&slutt=38856.09116223373,6946141.295902717&maks_avstand=10&omkrets=100&konnekteringslenker=true&detaljerte_lenker=false&behold_trafikantgruppe=false&pretty=true&kortform=true",
"https://nvdbapiles-v3.atlas.vegvesen.no/beta/vegnett/rute?start=17233.49,6933166.44&slutt=17411.16742345906,6933361.249064187&maks_avstand=10&omkrets=100&konnekteringslenker=true&detaljerte_lenker=false&behold_trafikantgruppe=false&pretty=true&kortform=true",
"https://nvdbapiles-v3.atlas.vegvesen.no/beta/vegnett/rute?start=19888.753066316945,6944574.509461373&slutt=20264.900856445194,6944368.952139658&maks_avstand=10&omkrets=100&konnekteringslenker=true&detaljerte_lenker=false&behold_trafikantgruppe=false&pretty=true&kortform=true",
"https://nvdbapiles-v3.atlas.vegvesen.no/beta/vegnett/rute?start=26521.552530414192,6940216.455383167&slutt=26457.440704222478,6940123.788953421&maks_avstand=10&omkrets=100&konnekteringslenker=true&detaljerte_lenker=false&behold_trafikantgruppe=false&trafikantgruppe=K&pretty=true&kortform=true",
"https://nvdbapiles-v3.atlas.vegvesen.no/beta/vegnett/rute?start=26343.660416060884,6950023.898755312&slutt=26736.355686723255,6950277.5537265055&maks_avstand=10&omkrets=100&konnekteringslenker=true&detaljerte_lenker=false&behold_trafikantgruppe=false&trafikantgruppe=K&pretty=true&kortform=true",
"https://nvdbapiles-v3.atlas.vegvesen.no/beta/vegnett/rute?start=28758.084434766264,6945107.442628212&slutt=28872.074380539998,6945084.460240152&maks_avstand=10&omkrets=100&konnekteringslenker=true&detaljerte_lenker=false&behold_trafikantgruppe=false&trafikantgruppe=K&pretty=true&kortform=true",
"https://nvdbapiles-v3.atlas.vegvesen.no/beta/vegnett/rute?start=20957.20257390075,6939620.818590216&slutt=20637.109098991437,6939678.886214065&maks_avstand=10&omkrets=100&konnekteringslenker=true&detaljerte_lenker=false&behold_trafikantgruppe=false&trafikantgruppe=K&pretty=true&kortform=true",
"https://nvdbapiles-v3.atlas.vegvesen.no/beta/vegnett/rute?start=12406.263465148688,6933858.521046377&slutt=12658.589337749,6933842.480074977&maks_avstand=10&omkrets=100&konnekteringslenker=true&detaljerte_lenker=false&behold_trafikantgruppe=false&trafikantgruppe=K&pretty=true&kortform=true",
"https://nvdbapiles-v3.atlas.vegvesen.no/beta/vegnett/rute?start=23131.961055209278,6936838.823032396&slutt=23178.72879053885,6937309.664867436&maks_avstand=10&omkrets=100&konnekteringslenker=true&detaljerte_lenker=false&behold_trafikantgruppe=false&trafikantgruppe=K&pretty=true&kortform=true",
"https://nvdbapiles-v3.atlas.vegvesen.no/beta/vegnett/rute?start=36702.36624956445,6950291.6474007955&slutt=36778.50157994096,6950016.548198562&maks_avstand=10&omkrets=100&konnekteringslenker=true&detaljerte_lenker=false&behold_trafikantgruppe=false&trafikantgruppe=K&pretty=true&kortform=true",
"https://nvdbapiles-v3.atlas.vegvesen.no/beta/vegnett/rute?start=20853.204308743123,6939592.358717515&slutt=20638.11771304172,6939679.444927726&maks_avstand=10&omkrets=100&konnekteringslenker=true&detaljerte_lenker=false&behold_trafikantgruppe=false&trafikantgruppe=K&pretty=true&kortform=true",
"https://nvdbapiles-v3.atlas.vegvesen.no/beta/vegnett/rute?start=16112.167162967904,6946267.653663013&slutt=16176.453134912474,6946340.517977856&maks_avstand=10&omkrets=100&konnekteringslenker=true&detaljerte_lenker=false&behold_trafikantgruppe=false&trafikantgruppe=K&pretty=true&kortform=true",
"https://nvdbapiles-v3.atlas.vegvesen.no/beta/vegnett/rute?start=38792.42584442743,6946386.567167263&slutt=38946.91037624149,6946291.330794491&maks_avstand=10&omkrets=100&konnekteringslenker=true&detaljerte_lenker=false&behold_trafikantgruppe=false&trafikantgruppe=K&pretty=true&kortform=true"]

s = kalibrering[4]
args = split(split(s, '?')[2], '&')
start = split(args[1], '=')[2]
slutt = split(args[2], '=')[2]
stea, stno = split(start, ',')
slea, slno = split(slutt, ',')
ea1 = Int(round(tryparse(Float64, stea)))
no1 = Int(round(tryparse(Float64, stno)))
ea2 = Int(round(tryparse(Float64, slea)))
no2 = Int(round(tryparse(Float64, slno)))
easting1, northing1, easting2, northing2 = ea1, no1, ea2, no2
key = link_split_key(easting1, northing1, easting2, northing2)
q = patched_post_beta_vegnett_rute(easting1, northing1, easting2, northing2)
refs = extract_prefixed_vegsystemreferanse(q)
lengths = extract_length(q)
progression_at_ends = append!([0.0], cumsum(lengths))
mls, reversed = extract_multi_linestrings(q)
progression, r = progression_and_radii_of_curvature_from_multiline_string(mls, progression_at_ends)


fartsgrense_tuples = fartsgrense_from_prefixed_vegsystemreferanse.(refs, reversed)
speed_limitations_nested = speed_nested_in_intervals(fartsgrense_tuples, mls)
modify_fartsgrense_with_speedbumps!(speed_limitations_nested, refs, mls)
speed_limitation = vcat(speed_limitations_nested...)
=#


# The below takes several minutes, and serializes these request for faster run next time.
# Call `delete_memoization_file` to start over.
rws = 1:(size(M)[1])
for (start, stop) in zip(rws[1: (end - 1)], rws[2:end])
    na1, ea1, no1 = M[start, :]
    na2, ea2, no2 = M[stop, :]
    print("\n", lpad("$start $stop", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
    println(link_split_key(ea1, no1, ea2, no2))
    d = route_data(ea1, no1, ea2, no2)
    println("   Progression end: ", d[:progression][end])
end 

#############
# Spot checks
#############
using Plots
function niceplot(s, slope, speed_limitation, progression_at_ends, refs, na1, na2)
    p = plot(layout = (2, 1), size = (1200, 800), thickness_scaling = 2, framestyle=:origin, legend = false)
    plot!(p[1], s, slope)
    title!(p[1], "Slope [-]")
    plot!(p[2], s, speed_limitation)
    title!(p[2], "Speed limit [km/h]")
    for i in 1:(length(refs) - 1)
        xs = progression_at_ends[i]
        ref = "$i:" * refs[i][5:end]
        j = findfirst(x -> x > xs, s )
        y = speed_limitation[j]
        annotate!(p[2], [(xs,y,text(ref, 6, :left, :top, :blue, rotation = -30))])
    end
    annotate!(p[1], [(0, 0, text(na1, 8, :left, :top, :green, rotation = -30))])
    annotate!(p[1], [(s[end], maximum(slope), text(na2, 8, :left, :top, :green, rotation = -90))])
    p
end
function niceplot(d::Dict, na1, na2)
    speed_limitation = d[:speed_limitation]
    s = d[:progression]
    slope = d[:slope]
    refs = d[:prefixed_vegsystemreferanse]
    progression_at_ends = d[:progression_at_ends]
    niceplot(s, slope, speed_limitation, progression_at_ends, refs, na1, na2)
end

start, stop = 44, 45
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
print(lpad("$start $stop", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
println(link_split_key(ea1, no1, ea2, no2))
d = route_data(ea1, no1, ea2, no2)
niceplot(d, na1, na2)


# Here, the speed limit is 60 at the end, because we do not
# currently read speed limits at 'sideanlegg'. 
# The previous plot starts at 50 because it can assume the default applies.
# Consider fixing 'is_segment_relevant!
start, stop = 45, 44
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
print(lpad("$start $stop", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
println(link_split_key(ea1, no1, ea2, no2))
d = route_data(ea1, no1, ea2, no2)
niceplot(d, na1, na2)


# This works fine
start, stop = 25, 26
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
print(lpad("$start $stop", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
println(link_split_key(ea1, no1, ea2, no2))
d = route_data(ea1, no1, ea2, no2)
niceplot(d, na1, na2)
# The oposite order would suffer from the same issue.




# This works poorly for slope due to long distance between geometry points. 
# TODO: make slope function do some checks so
# it works better in these cases.
# Also consider that large distance between points is not beneficial to
# solving a vehicle's diffeq with fixed step size. Another solution might be to fill in missing values
# when progress jumps are detected.
na1 = "Eika"
ea1 = 28130
no1 = 6934881
na2 = "Nær midt tunnell"
ea2 = 27804
no2 = 6932152
print(lpad("$start $stop", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
println(link_split_key(ea1, no1, ea2, no2))
d = route_data(ea1, no1, ea2, no2)
niceplot(d, na1, na2)
s = d[:progression]
slope = d[:slope]
mls = d[  :multi_linestring]
_, _, z = RouteSlopeDistance.unique_unnested_coordinates_of_multiline_string(mls)
p = plot(layout = (2, 1), size = (1200, 800), thickness_scaling = 2, framestyle=:origin, legend = false)
plot!(p[1], s, slope, marker = true)
plot!(p[2], s, z, marker = true)