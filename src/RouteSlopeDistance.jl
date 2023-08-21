module RouteSlopeDistance()
using HTTP, IniFile, JSON3, UUIDs, Dates
import BSplines
using BSplines: BSplineBasis, Spline, Derivative, Function
import Smoothers
using Smoothers: hma
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
include("distance_and_progression.jl")
include("vegdata_from_vegsystemreferanse.jl")
include("curvature_bsplines.jl")
end