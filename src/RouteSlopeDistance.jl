module RouteSlopeDistance()
    using HTTP, IniFile, JSON3, UUIDs, Dates
    export nvdb_request, route_data
    include("ini_file.jl")
    include("nvdb_utils.jl")
    include("request_nvdb.jl")
    include("endpoints.jl")
end