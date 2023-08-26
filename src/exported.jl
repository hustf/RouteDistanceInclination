"""
    route_data(easting1::T, northing1::T, easting2::T, northing2::T; default_fartsgrense = 50) where T <: Int
    route_data(;start = "", slutt = ""; default_fartsgrense = 50)
    route_data(s::String; default_fartsgrense = 50)

    --> Dict{Any}

Arguments are start and end points given in UTM33 coordinates.
Results are memoized and stored to disk. Results are stored after rounding 
arguments to whole numbers, i.e. a resolution of 1 m.

For easy copy / paste from map applications, 's' can be any string containing url-style arguments
'start' and 'slutt'.

default_fartsgrense is used in case the starting point has no defined speed limit, e.g. in bus terminals.

# Example

Three calls, same result:
```
julia> s = "https://nvdbapiles-v3.atlas.vegvesen.no/beta/vegnett/rute?start=23593.713839066448,6942485.5900078565&slutt=23771.052968726202,6942714.9388697725&ma......etc"

julia route_data(s);

julia> s = "(23594 6942486)-(23771 6942715)"

julia> route_data(s);

julia> route_data(;start = "23593.713839066448,6942485.5900078565", slutt = "23771.052968726202,6942714.9388697725");

julia> route_data(23594,6942486, 23771,6942715);
Curvature limited velocity: 32.46935208780521 km/h at 109.79520214324043 m due to radius 67.78927629898796
Route data (23594 6942486)-(23771 6942715) stored in C:\\Users\\f\\RouteSlopeDistance.jls
Dict{Symbol, Vector} with 5 entries:
  :slope_detailed              => [0.0200961, 0.0125534, 0.0028205, 0.00851354, 0.0114698, -0.00179656, 0.…
  :multi_linestring            => [[(23594.2, 6.94249e6, 10.483), (23594.1, 6.94249e6, 10.507), (23593.1, …
  :prefixed_vegsystemreferanse => ["1516 FV5884 S1D1 m6860-7196"]
  :progression_detailed        => [0.0, 1.1945, 13.1444, 16.6898, 28.4363, 32.7958, 44.4849, 49.8823, 63.0…
  :speed_limitations_detailed  => [80.0, 80.0, 80.0, 80.0, 80.0, 80.0, 80.0, 80.0, 80.0, 80.0  …  80.0, 80…
```
"""
function route_data(easting1::T, northing1::T, easting2::T, northing2::T; default_fartsgrense = 50) where T <: Int
    # Use stored data if available.
    key = link_split_key(easting1, northing1, easting2, northing2)
    thisdata = get_memoized_value(key)
    if ! isempty(thisdata) 
        return thisdata
    end
    # Identify the bits of road we're taking from 1 to 2. This retrieves
    # vegsystemreferanser, individual lengths of each ref, and curve
    # geometry for each. All packed in q...
    q = patched_post_beta_vegnett_rute(easting1, northing1, easting2, northing2)
    refs = extract_prefixed_vegsystemreferanse(q)
    @assert ! startswith(refs[1], "Error") refs[1]
    # The length of individual segments 
    lengths = extract_length(q)
    # Progression at start of first segment, start of second ... end of last.
    progression = append!([0.0], cumsum(lengths))
    mls, reversed = extract_multi_linestrings(q)
    @assert length(progression) == length(mls) + 1
    @assert length(mls) == length(reversed)
    # Detail progression at each point on the curve.
    progression_detailed = progression_at_each_coordinate(mls, progression)
    @assert issorted(progression_detailed)
    # Get the minimum radius, and position along curve for each curve in mls
    r_extremals, s_extremals_local = extract_curvature_extremals_from_multi_linestrings(mls)
    # Let's add progression at start of each curve in mls
    s_extremals = s_extremals_local .+ progression[1:(end - 1)]

    # We have unpacked the useful information from the first request.
    # Now ask for related information, and unpack it.    
    # 
    # The tuples refer to the nominal direction of segments
    fartsgrense_tuples = fartsgrense_from_prefixed_vegsystemreferanse.(refs, reversed)
    # End stops may be without defined fartsgrense. However, we need 
    # a start value, so modify if missing:
    if isnan(fartsgrense_tuples[1][1])
        fartsgrense_tuples[1] = (1.0, default_fartsgrense, default_fartsgrense)
    end
    # 
    # Detail fartsgrense on every point of each multi_linestring. We'll 
    # unpack further below.
    speed_limitations_nested = fartsgrense_at_intervals(fartsgrense_tuples, mls)
    # Practical speed limit is reduced by speedbumps.
    # Make further requests for speedbumps and reduce
    # the speeed limit at each bump's coordinates. In-place function.
    modify_fartsgrense_with_speedbumps!(speed_limitations_nested, refs, mls)
    # 
    # Unpack nested speed limitations.
    speed_limitations_detailed = vcat(speed_limitations_nested...)
    @assert length(progression_detailed) == length(speed_limitations_detailed) + 1

    # Another practical speed limit is for passenger comfort.
    # Acceptable centripetal acceleration is calibrated against 
    # Ecosafe logs over ~30000 km.
    a_centripetal_max = 3.44 # m/s²
    # For every minimum radius, find the maximum velocity.
    # a = v² / r      =>  v = √(a·r)
    v_centripetal_max = sqrt.(a_centripetal_max .* r_extremals) * 3.6 # km / h
    # Apply the speed limitations due to curvature
    for (s, v_c, r) in zip(s_extremals, v_centripetal_max, r_extremals) 
        if ! isnan(s)
            i = findfirst(t -> t >= s, progression_detailed)
            if speed_limitations_detailed[i] > v_c
                println("Curvature limited velocity: $v_c km/h at $s m due to radius $r ")
                speed_limitations_detailed[i] = v_c
            end
        end
    end
    # Finally detail slope also.
    slope_detailed = slope_at_each_coordinate(mls)
    # Sum up
    thisdata = Dict(:prefixed_vegsystemreferanse => refs,
        :progression_detailed => progression_detailed,
        :speed_limitations_detailed => speed_limitations_detailed,
        :slope_detailed => slope_detailed,
        :multi_linestring => mls,
        :key => key,
        :r_extremals => r_extremals,
        :s_extremals => s_extremals)
    # Store results on disk.
    set_memoized_value(key, thisdata)
end
function route_data(;start = "", slutt = "", default_fartsgrense = 50)
    stea, stno = split(start, ',')
    slea, slno = split(slutt, ',')
    ea1 = Int(round(tryparse(Float64, stea)))
    no1 = Int(round(tryparse(Float64, stno)))
    ea2 = Int(round(tryparse(Float64, slea)))
    no2 = Int(round(tryparse(Float64, slno)))
    route_data(ea1, no1, ea2, no2; default_fartsgrense)
end
function route_data(s::String; default_fartsgrense = 50)
    if contains(s, '?')
        # url-style
        args = split(split(s, '?')[2], '&')
        @assert startswith(args[1], "start")
        @assert startswith(args[2], "slutt")
        start = split(args[1], '=')[2]
        slutt = split(args[2], '=')[2]
    else
        @assert contains(s, '-')
        # key-style: "(23594 6942486)-(23771 6942715)"
        args = split(s, '-')
        start = replace(strip(args[2], ['(', ')'] ), ' ' => ',')
        slutt = replace(strip(args[2], ['(', ')'] ), ' ' => ',')
    end
    route_data(;start, slutt, default_fartsgrense)
end

"""
    delete_memoization_file()

Start over after results are invalidated.
"""
function delete_memoization_file()
    fna = _get_memoization_filename_but_dont_create_file()
    if isfile(fna) 
        rm(fna)
        println("Removed $fna")
    else
        println("$fna Didn't and doesn't exist.")
    end
end