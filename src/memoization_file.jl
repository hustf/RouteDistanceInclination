# This file has functions for memoization of route_data calls.
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
    println("Route data $key stored in $fna")
    value
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

