# Small functions used elsewhere

"""
    length_of_linestring(ls::Vector{Tuple{Float64, Float64, Float64}})
    --> Float64

Assuming straight lines between points
"""
function length_of_linestring(ls::Vector{Tuple{Float64, Float64, Float64}})
    l = 0.0
    prevpt = ls[1]
    for pt in ls[2:end]
        l += distance_between(prevpt, pt)
        prevpt = pt
    end
    l
end

"""
distance_between(pt1, pt2)

Euclidean distance between 3d points
"""
function distance_between(pt1, pt2)
    Δx = pt2[1] - pt1[1]
    Δy = pt2[2] - pt1[2]
    Δz = pt2[3] - pt1[3]
    hypot(Δx, Δy, Δz)
end


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
    c = tupl[1]
    v_start = tupl[2]
    v_end = tupl[3]
    pts_start = ml[1:(end -1)]
    pts_end = ml[2:end]
    Δls = distance_between.(pts_start, pts_end)
    x_at_end_of_interval = cumsum(Δls./sum(Δls))
    x_at_start_of_interval = vcat([0.0], x_at_end_of_interval[1:(end -1)])
    map(zip(x_at_start_of_interval, x_at_end_of_interval)) do (xs, xe)
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