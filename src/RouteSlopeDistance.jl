module RouteSlopeDistance()
using HTTP, IniFile, JSON3, UUIDs, Dates
import BSplines
using BSplines: BSplineBasis, Spline, Derivative, Function
import Smoothers
using Smoothers: hma
using Serialization
export route_data, delete_memoization_file, nvdb_request
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
include("memoization_file.jl")
end