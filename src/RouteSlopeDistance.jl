module RouteSlopeDistance()
    using HTTP, IniFile, JSON3, UUIDs, Dates
    export nvdb_request, route_data, delete_init_file
    include("ini_file.jl")
    include("nvdb_utils.jl")
    include("request_nvdb.jl")
    include("endpoints.jl")
    include("exported.jl")
    include("patch_links_and_coordinates.jl")
end