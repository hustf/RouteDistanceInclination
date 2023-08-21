# Small functions used elsewhere






"""
reverse_linestrings_where_needed!(multi_linestring, easting1, northing1)

In-place reversing of linestrings point order for continuity. 
"""
function reverse_linestrings_where_needed!(multi_linestring, easting1, northing1)
    previous_point = (easting1, northing1, 0.0)
    for i in eachindex(multi_linestring)
        current_first_point = multi_linestring[i][1]
        current_last_point = multi_linestring[i][end]
        if is_reversed(previous_point, current_first_point, current_last_point)
            reverse!(multi_linestring[i])
        end
        previous_point = multi_linestring[i][end]
    end
    multi_linestring
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
    (speed_limitations::Vector{Vector{Float64}}, prefixed_refs, mls)

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

