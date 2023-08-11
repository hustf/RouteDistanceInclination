# Definitions directly tied to accessing the nvdb api, not processing it.
# Ref. https://nvdbapiles-v3.atlas.vegvesen.no/dokumentasjon/

"""
    get_nvdb_fields()

For nvdb requests, provide required fields.
A new UUID is generated every session.
"""
function get_nvdb_fields(body)
    ua = get_config_value("http fields", "User agent")
    ac = get_config_value("http fields", "Accept")
    idfields = ["X-Client-Session" => "$NvdbSessionID", 
    "X-Client" => "$ua",
    "User-Agent" => "$ua",
    "Accept" => "$ac"]
    if body !== ""
        push!(idfields, "Content-Type" => "application/json")
    end
    idfields
end


"Current stored credentials, access by spotcred()"
const NvdbSessionID  = string(uuid4()) * " $(now())" 
const BASEURL = get_config_value("api server", "baseurl")

"Logstate(;authorization = true, request_string = true, empty_response = true)"
Base.@kwdef mutable struct Logstate
    authorization::Bool = false
    request_string::Bool = false
    empty_response::Bool = false
end

"""
LOGSTATE mutable state
 -  .authorization::Bool
 -  .request_string::Bool
 -  .empty_response::Bool

Mutable flags for logging to REPL. Nice when 
making inline docs or new interfaces. 
This global can also be locally overruled with
keyword argument to `spotify_request`.
"""
const LOGSTATE = Logstate()

const RESP_DIC = include("lookup/response_codes_dic.jl")
