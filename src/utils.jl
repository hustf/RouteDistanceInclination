# Small functions used elsewhere

"""
    reverse_linestrings_where_needed!(multi_linestring, easting1, northing1)
    ---> Vector{Bool}

In-place reversing of linestrings point order for continuity. 

Returns a vector where 'true' indicated that this linestring was reversed.
This may be used for reversing associated data.
"""
function reverse_linestrings_where_needed!(multi_linestring, easting1, northing1)
    previous_point = (easting1, northing1, 0.0)
    reversed = Bool[]
    for i in eachindex(multi_linestring)
        current_first_point = multi_linestring[i][1]
        current_last_point = multi_linestring[i][end]
        isrev = is_reversed(previous_point, current_first_point, current_last_point)
        if isrev
            reverse!(multi_linestring[i])
        end
        push!(reversed, isrev)
        previous_point = multi_linestring[i][end]
    end
    reversed
end

function is_reversed(previous_point, current_first_point, current_last_point)
    d_first = distance_between(previous_point, current_first_point)
    d_last = distance_between(previous_point, current_last_point)
    d_last < d_first
end

"""
    check_continuity_of_multi_linestrings(multi_linestring)

The last point in a linestring should match with the first point of the next.
We do allow some leeway here, 10 cm.
"""
function check_continuity_of_multi_linestrings(multi_linestring)
    # A little bit of checking that the geometry is right
    # Check C0 continuity
    previousend = (0.0, 0.0, 0.0)
    for (i, ls) in enumerate(multi_linestring)
        thisstart = ls[1]
        thisend = ls[end]
        if i > 1 
            if distance_between(thisstart, previousend) > 0.1 
                msg = "Not matching start point $thisstart and previous end $previousend \n"
                msg *= "The distance between is  $(distance_between(thisstart, previousend))\n"
                msg *= "This start point is on $(vegsystemreferanse_prefixed[i])\n"
                msg *= "Previous end is on $(vegsystemreferanse_prefixed[i - 1])\n"
                println()
                throw(AssertionError(msg))
            end
        end
        previousend = thisend
    end
end



# The below 'urlstrings' and 'build_query_strings' may be useful for general web APIs
# when using Julia keywords. The keywords are defined as "" in general, and
# will be excluded in the web API call.
"""
    urlstring

Encodes the arguments as expected in a query string.

Type info is seldom necessary, because the type of arguments
is given by the API endpoint.

Empty argument values => the argument name is considered redundant.
"""
function urlstring(;kwds...)
    isempty(kwds) && return ""
    urlstring(kwds)
end
function urlstring(kwds::Base.Pairs)
    iter = collect(kwds)
    parts = ["$(urlstring(k))=$(urlstring(v))" for (k,v) in iter if v !== "" && v !== 0 && v !== -1]
    join(parts, "&")
end

function urlstring(d::Dict)
    parts = ["$(urlstring(k))=$(urlstring(v))" for (k,v) in d if v !== "" && v !== 0 && v !== -1]
    s = join(parts, "&")
end
function urlstring(v::Vector)
    vs = urlstring.(v)
    join(vs, "%2C")
end
function urlstring(d::DateTime)
    string(d)[1:19] # Whole seconds
end
function urlstring(s)
    "$s"
end


"""
    build_query_string(xs::Vararg{String,N} where N)

Includes separators if needed, for urlstrings.
"""
function build_query_string(xs::Vararg{String,N} where N)
    sf = first(xs)
    if sf == ""
        throw("The first argument can not be an empty string")
    end
    others = filter( s -> s!== "", xs[2:end])
    if length(others) == 0
        return first(xs)
    end
    if sf[end] == '/' || sf[end] == '='
        sf * join(others, "&")
    else
        first(xs) * "?" * join(others, "&")
    end
end

"""
    extract_from_to_meter(vegsystemreferanse::String)

Assumes ending like: 1515 FV61 S5D1 m1401-1412
"""
function extract_from_to_meter(vegsystemreferanse::String)
    from_to = split(vegsystemreferanse, ' ')[end]
    @assert startswith(from_to, 'm') vegsystemreferanse
    Tuple(tryparse.(Int, split(from_to[2:end], '-')))
end

"""
    extract_strekning_delstrekning(vegsystemreferanse::String)

Assumes ending like: 1515 FV61 S5D1 m1401-1412
"""
function extract_strekning_delstrekning(vegsystemreferanse::String)
    excluding_position = split(vegsystemreferanse, ' ')[1:(end - 1)]
    String(excluding_position[end])
end

"""
    extract_vegnummer(vegsystemreferanse::String)

Assumes ending like: 1515 FV61 S5D1 m1401-1412
"""
function extract_vegnummer(vegsystemreferanse::String)
    excluding_position_and_strekning = split(vegsystemreferanse, ' ')[1:(end - 2)]
    String(excluding_position_and_strekning[end])
end

"""
    correct_to_increasing_distance(vegsystemreferanse::String)

Some requests to post_beta_vegnett_rute return invalid 
vegsystemreferanse. The highest meter value comes first.

This corrects the error by swapping the last two numbers.
"""
function correct_to_increasing_distance(vegsystemreferanse::String)
    ref_from, ref_to = extract_from_to_meter(vegsystemreferanse)
    if ref_from <= ref_to 
        return vegsystemreferanse
    else
        v = split(vegsystemreferanse, ' ')
        to = Int(round(ref_from))
        from = Int(round(ref_to))
        return join(v[1:(end - 1)], ' ') * " m$from-$to"
    end
end

"""
    is_segment_relevant(ref, vegsegment)

Some requests to vegdatabase return segments fully outside
the specified vegsystemreferanse limits. 

This is a way to filter out such results.

"""
function is_segment_relevant(ref, vegsegment)
    ref_from, ref_to = extract_from_to_meter(ref)
    ref_strekning_delstrekning = extract_strekning_delstrekning(ref)
    if hasproperty(vegsegment, :vegsystemreferanse)
        vegsystemreferanse = vegsegment.vegsystemreferanse
        if hasproperty(vegsystemreferanse, :kortform)
            kortform = vegsystemreferanse.kortform
            strekning_delstrekning = extract_strekning_delstrekning(kortform)
            if ref_strekning_delstrekning !== strekning_delstrekning
                return false
            end
        else
            throw("Why not? $ref")
        end
        if hasproperty(vegsystemreferanse, :strekning)
            strekning = vegsystemreferanse.strekning
            if hasproperty(strekning, :fra_meter)
                fra_meter = strekning.fra_meter
                if fra_meter <= ref_to
                    if hasproperty(strekning, :til_meter)
                        til_meter = strekning.til_meter
                        if til_meter >= ref_from
                            if til_meter - ref_from >= 1
                                if ref_to - fra_meter >= 1
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    false
end 


"""
    is_rpoint_in_ref(rpoint, ref)

# Example
```
julia> is_rpoint_in_ref("1515 PV3080 S1D1 m20-84", "1515 PV3080 S1D1 m56")
true
```
"""
function is_rpoint_in_ref(rpoint, ref)
    if extract_vegnummer(ref) ==  extract_vegnummer( rpoint)
        if extract_strekning_delstrekning(ref) ==  extract_strekning_delstrekning(rpoint)
            enveloping = extract_from_to_meter(ref)
            point = extract_from_to_meter(rpoint)
            @assert length(point) == 1
            if enveloping[1] <= point[1]
                if enveloping[2] >= point[1]
                    return true
                end
            end
        end
    end
    false
end


"""
    fartsgrense_at_intervals_in_multilinestring(tupl, ml)

Applies an (interpolated) fartsgrense at each point in the
vector of 3d-points, 'ml', based on 'tupl'.
"""
function fartsgrense_at_intervals(fart_tuples, mls)
    v = Vector{Vector{Float64}}()
    @assert length(fart_tuples) == length(mls)
    prev_tupl = fart_tuples[1]
    tupl = fart_tuples[1]
    i = 1
    while i <= length(mls)
        if ! isnan(fart_tuples[i][1])
            tupl = fart_tuples[i]
        else
            tupl = prev_tupl
        end
        ml = mls[i]
        push!(v, fartsgrense_at_intervals_in_multilinestring(tupl, ml))
        i += 1
        prev_tupl = tupl
    end
    v
end 

"""
    fartsgrense_at_intervals_in_multilinestring(tupl, ml)

Applies an (interpolated) fartsgrense for each interval
between points in 'ml', based on 'tupl'.

Hence, if ml has N points, this returns N-1 fartsgrenser.
"""
function fartsgrense_at_intervals_in_multilinestring(tupl, ml)
    @assert ! isnan(tupl[1])
    # This is where the split happens (in 0..1)
    c = tupl[1]
    # This is the initial fartsgrense
    v_start = tupl[2]
    # This is the fartsgrense we change to
    v_end = tupl[3]
    # Unitless 1-dim positions along multi_linestring:
    s_ul_at_start_of_interval, s_ul_at_end_of_interval = unitless_interval_progression_pairs(ml)
    map(zip(s_ul_at_start_of_interval, s_ul_at_end_of_interval)) do (xs, xe)
        if xe <= c
            Float64(v_end)
        elseif xe > c && xs < c
            frac = (c -xs)
            v_start * frac + v_end * (1 - frac)
        else
            Float64(v_start)
        end
    end
end


"""
    modify_fartsgrense_with_speedbumps!(speed_limitations::Vector{Vector{Float64}}, prefixed_refs, mls)

Instead of making a request for pretty rare speedbumps
per small stretch of road, we make one for the kommune and ignore
irrelevant speedbumps.

This modifies speed-limitations in-place by reducing by 15 km/h 
at the location of a speed bump.

Some speedbumps contain detailed info,
but some don't. We will treat all the same.

The reduction is according to section 3.11 in 

'https://www.vegvesen.no/globalassets/fag/handboker/hb-v128-fartsdempende-tiltak.pdf'

for heavy vehicles.
"""
function modify_fartsgrense_with_speedbumps!(speed_limitations::Vector{Vector{Float64}}, prefixed_refs, mls)
    n = length(speed_limitations)
    @assert n == length(prefixed_refs)
    # Find which kommune nos are present if prefixed_refs.
    all_nos = map(prefixed_refs) do r
        split(r, ' ')[1]
    end
    nos = unique(all_nos)
    kommune = join(nos, ',')
    # Some speedbumps contain detailed info,
    # but some don't. We will treat all the same.
    vegobjekttype_id = 103 
    o = get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, ""; kommune, inkluder = "vegsegmenter")
    all_bumps =  extract_prefixed_vegsystemreferanse(o)
    for (i, enveloping_ref) in enumerate(prefixed_refs)
        relevant_bumps = filter(b -> is_rpoint_in_ref(b, enveloping_ref), all_bumps)
        if length(relevant_bumps) > 0
            println("found $relevant_bumps contained by $enveloping_ref")
            for bump in relevant_bumps
                bump_at_meter = extract_from_to_meter(bump)[1]
                ref_start_at_meter = extract_from_to_meter(enveloping_ref)[1]
                ml = mls[i]
                s_at_start_of_interval, _ = interval_progression_pairs(ml)
                for (j, s) in enumerate(s_at_start_of_interval)
                    if s + ref_start_at_meter >= bump_at_meter
                        # Reduce the speed limit at this one point, where
                        # the bump is.
                        speed_limitations[i][j] -= 15
                        break # exit loop placing this bump
                    end
                end
            end
        end
    end
    speed_limitations
end

"""
    unique_unnested_coordinates_of_multiline_string(mls::Vector{ Vector{Tuple{Float64, Float64, Float64}}})
    ---> Vector{Float64}, Vector{Float64}, Vector{Float64}

We're joining curves where two ends are identical
(we don't check that though)
"""
function unique_unnested_coordinates_of_multiline_string(mls::Vector{ Vector{Tuple{Float64, Float64, Float64}}})
    vx = Float64[] 
    vy = Float64[] 
    vz = Float64[] 
    for i in 1:length(mls)
        p = mls[i]
        px = map(point -> point[1], p)
        py = map(point -> point[2], p)
        pz = map(point -> point[3], p)
        if i == 1
            append!(vx, px)
            append!(vy, py)
            append!(vz, pz)
        else
            append!(vx, px[2:end])
            append!(vy, py[2:end])
            append!(vz, pz[2:end])
        end
    end
    vx, vy, vz
end













"""
    slope_at_each_coordinate(p_x, p_y, p_z)
    slope_at_each_coordinate(p::Vector{Tuple{Float64, Float64, Float64}})
    ---> Vector{Float64}

# Example
```
julia> p = [(33728.644, 6.946682377e6, 31.277), (33725.9, 6.9466807e6, 31.411), (33722.49, 6.9466785e6, 31.511)]
3-element Vector{Tuple{Float64, Float64, …}}:
 (33728.644, 6.946682377e6, 31.277)
 (33725.9, 6.9466807e6, 31.411)
 (33722.49, 6.9466785e6, 31.511)

 julia> slope_at_each_coordinate(p)
 2-element Vector{Float64}:
 0.04166826007770272
 0.024642130445827252
```
"""
function slope_at_each_coordinate(p_x, p_y, p_z)
    throw("Delete me too")
    n = length(p_x)
    @assert length(p_y) == n
    p0 = [(p_x[i], p_y[i], p_z[i]) for i in 1:(n - 1)]
    p1 = [(p_x[i], p_y[i], p_z[i]) for i in 2:n]
    slope_between.(p0, p1)
end
function slope_at_each_coordinate(p::Vector{Tuple{Float64, Float64, Float64}})
    throw("Delete me")
    px = map(point -> point[1], p)
    py = map(point -> point[2], p)
    pz = map(point -> point[3], p)
    slope_at_each_coordinate(px, py, pz)
end

"""
    slope_at_each_coordinate(mls::Vector{Vector{Tuple{Float64, Float64, Float64}}})
    ---> Vector{Float64}

Slopes detailed, one per unique coordinate in the 'multi-linestring'. The last value is
a copy of the next-to-last.

Slopes are forward looking: i to i + 1.

# Example
In the example, the second linestring is not continuous with the first, but
the horizontal distance is extreme. Hence, the slope is ~ 0.

```
julia> mls = [ [(33728.644, 6.946682377e6, 31.277), (33725.9, 6.9466807e6, 31.411), (33722.49, 6.9466785e6, 31.511)],
[(0.0, 0.0, 0.0), (10.0, 0.0, 0.0)] ];

julia> slope_at_each_coordinate(mls)
4-element Vector{Float64}:
 0.04166826007770272
 0.024642130445827252
 0.0
 0.0
```
"""
function slope_at_each_coordinate(mls::Vector{Vector{Tuple{Float64, Float64, Float64}}})
    throw("No good")
    s = Float64[] 
    for p in mls
        vs = slope_at_each_coordinate(p)
        @assert length(vs) == length(p) - 1
        append!(s, vs)
    end
    # We simply extend the slope one coordinate further, in
    # order to have a value at the end, too.
    append!(s, s[end])
    s
end



"""
slope_between(pt1, pt2)

Vertical change in position / horizontal change, i.e.
Rise / run

# Example
```
julia> pt1 = (33725.9, 6.9466807e6, 31.411);

julia> pt2 = (33722.49, 6.9466785e6, 31.511);

julia> slope_between(pt1, pt2)
0.024642130445827252
```
"""
function slope_between(pt1, pt2)
    throw("delete me")
    Δx = pt2[1] - pt1[1]
    Δy = pt2[2] - pt1[2]
    Δz = pt2[3] - pt1[3]
    Δz / hypot(Δx, Δy)
end



