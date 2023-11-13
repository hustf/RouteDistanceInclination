# This file has functions for memoization of route_leg_data calls.
# The file is binary, call `delete_memoization_file()`
# if old results are invalidated.

function get_memoized_value(key) 
    d = read_memoized_dict()
    get(d, key, Dict())
end

function set_memoized_value(key, value) 
    d = read_memoized_dict()
    push!(d, key => value)
    fna = _get_memoization_filename_but_dont_create_file()
    serialize(fna, d)
    println("\tRoute data $key stored in $fna")
    value
end


"""
    delete_memoized_pair(key; also_reverse = true)
    ---> Nothing

This can be useful if a stored key is corrupted, or route is revised. Otherwise, use `delete_memoization_file`.


# Example
```
julia> delete_memoized_pair("(31515 6946166)-(31167 6946060)")
Unknown key in C:\\Users\\f\\RouteSlopeDistance.jls, nothing removed

julia> delete_memoized_pair("(33142 6946489)-(32852 6946449)")
Route data (33142 6946489)-(32852 6946449) removed from C:\\Users\\f\\RouteSlopeDistance.jls

julia> delete_memoized_pair("(33142 6946489)-(32852 6946449)")
Nothing removed from C:\\Users\\f\\RouteSlopeDistance.jls : Unknown key. 
```
"""
function delete_memoized_pair(key; also_reverse = true)
    d = read_memoized_dict()
    wasvalue = pop!(d, key, Dict())
    fna = _get_memoization_filename_but_dont_create_file()
    if ! isempty(wasvalue)
        println("Route data $key removed from $fna")
        serialize(fna, d)
    else
        println("Nothing removed from $fna : Unknown key $key.")
    end
    if also_reverse
        parts = split(key, '-')
        reversekey = parts[2] * "-" * parts[1]
        # Recurse.
        delete_memoized_pair(reversekey; also_reverse = false)
    end
    nothing
end

function read_memoized_dict()
    fnam = _get_memoization_fnam()
    deserialize(fnam)
end


"Get an existing, readable ini file name, create it if necessary"
function _get_memoization_fnam()
    fna = _get_memoization_filename_but_dont_create_file()
    if !isfile(fna)
        serialize(fna, Dict())
    end
    fna
end
_get_memoization_filename_but_dont_create_file() =  joinpath(homedir(), "RouteSlopeDistance.jls")

