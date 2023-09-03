"""
    patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)

This layer modifies a request to post_beta_vegnett_rute.
If the coordinates are a recognized pair, will split
the request in two requests and return a quilt defined 
above. If not, returns a JSON3 object.
"""
function patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
    # First insert extra points where recognized
    sequence = sequential_patched_positions(ea1, no1, ea2, no2)
    # Then replace recognized points where recognized
    for i in eachindex(sequence)
        ea1, no1, ea2, no2 = sequence[i]
        ea1, no1 = corrected_coordinates(false, ea1, no1)
        ea2, no2 = corrected_coordinates(true, ea2, no2)
        sequence[i] = [ea1, no1, ea2, no2]
    end
    # Make a request for each patch and store each result object
    patches = Vector{JSON3.Object}()
    for i in eachindex(sequence)
        ea1, no1, ea2, no2 = sequence[i]
        o = post_beta_vegnett_rute(ea1, no1, ea2, no2)
        @assert !isempty(o) 
        @assert ! iszero(o.metadata.antall) "$(extract_prefixed_vegsystemreferanse(o, ea1, no1, ea2, no2)[1])"
        push!(patches, o)
    end
    # Store the successfully found patched route
    Quilt(sequence, patches)
end


"""
    corrected_coordinates(ingoing::Bool, easting, northing)

Do a, rather slow lookup and potential replacement from the .ini file.
"""
function corrected_coordinates(ingoing::Bool, easting, northing)
    key = coordinate_key(ingoing::Bool, easting, northing)
    value = get_config_value("coordinates replacement", key, Tuple{Int64, Int64}, nothing_if_not_found = true)
    if isnothing(value)
        easting, northing
    else
        print("\nCorrected coordinates ")
        printstyled(rpad(key, 16), color = :yellow)
        print(" => ")
        printstyled("$(rpad(value, 16))\n", color = :green)
        value
    end
end

"""
    sequential_patched_positions(ea1, no1, ea2, no2)
    --> Vector{Vector{Float64}}

Do a, rather slow lookup and potential insertion from the .ini file.

# No match returns 

```
[[ea1, no1, ea2, ea2]]`
```

# A match returns

```
[[ea1, no1, x, y],
 [x, y, ea2, ea2]]`
```

where `x, y` is from the config file.
"""
function sequential_patched_positions(ea1, no1, ea2, no2)
    sequence = Vector{Vector{Float64}}()
    key = link_split_key(ea1, no1, ea2, no2)
    value = get_config_value("link split", key, Tuple{Int64, Int64}, nothing_if_not_found = true)
    if ! isnothing(value)
        split1 = [ea1, no1, value...]
        push!(sequence, split1)
        split2 = [value..., ea2, no2]
        push!(sequence, split2)
        print("\nLink split patch ")
        printstyled(rpad(key, 32), color = :yellow)
        print(" => ")
        printstyled("$(rpad(split1, 32))\n", color = :green)
        printstyled(repeat(' ', 53) * "$(rpad(key, 32))\n", color = :green)
    else
        push!(sequence, [ea1, no1, ea2, no2])
    end
    # Future note: We might recurse here, but we postpone to when that is practically needed.
    sequence
end
