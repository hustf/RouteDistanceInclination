# Ref. https://nvdbapiles-v3.atlas.vegvesen.no/dokumentasjon/

"""
    get_nvdb_fields()

For nvdb requests, provide required fields.
A new UUID is generated every session.
"""
function get_nvdb_fields()
    ua = get_config_value("http fields", "User agent")
    ac = get_config_value("http fields", "Accept")
    ["X-Client-Session" => "$NvdbSessionID", 
    "X-Client-User-Agent" => "$ua",
    "User-Agent" => "$ua",
    "Accept" => "$ac"]
end


"Current stored credentials, access by spotcred()"
const NvdbSessionID  = string(uuid4()) * " $(now())" 
const BASEURL = get_config_value("api server", "baseurl")

"Logstate(;authorization = true, request_string = true, empty_response = true)"
Base.@kwdef mutable struct Logstate
    authorization::Bool = true
    request_string::Bool = true
    empty_response::Bool = true
end
Logstate(;authorization = true, request_string = true, empty_response = true) = Logstate(authorization, request_string, empty_response)

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
