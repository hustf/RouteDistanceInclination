module RouteSlopeDistance()
using HTTP, IniFile, JSON3, UUIDs, Dates
export nvdb_request, route_data, delete_init_file
"Contains patched routes"
struct Quilt
    fromtos::Vector{Vector{Float64}} 
    patches::Vector{JSON3.Object}
end

include("ini_file.jl")
include("nvdb_utils.jl")
include("request_nvdb.jl")
include("extract_from_response_objects.jl")
include("endpoints.jl")
include("exported.jl")
include("patch_links_and_coordinates.jl")
include("utils.jl")
end