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