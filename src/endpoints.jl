"""
    get_posisjon(easting::T, northing::T) where T
    --> ::String

https://nvdbapiles-v3.atlas.vegvesen.no/dokumentasjon/openapi/#/Vegnett/get_posisjon

Returns a vegsystemreferanse prefixed by kommunenummer, or an error message.
The server sends more info. Unfortunately, the server returns HTTP error 
'404 Not found' when an object can't be found, which 
is printed and can be annoying.

Instead of adding lots of parameters to the call, we stick with the default
'Kjørende' selection.

We only intend to use this for identifying problematic points on a route.
When such are identified, we could 'hard-code' some numeric replacements,
updated in the .ini file.
"""
function get_posisjon(easting::T, northing::T;
    trafikantgruppe        = "K",
        maks_avstand = 10) where T
    url = "posisjon?nord=$northing&ost=$easting"
    url *= "& maks_avstand = $maks_avstand"
    url *= "& trafikantgruppe =  $trafikantgruppe "
    o = nvdb_request(url)[1]
    if o isa AbstractArray
        # A successful response methinks
        @assert length(o) == 1 "$o"
        kortform = get(o[1].vegsystemreferanse, :kortform, "")
        if kortform !== ""
            return "$(o[1].kommune) $(o[1].vegsystemreferanse.kortform)"
        else
            return "Error: Vegsystemreferanse mangler på dette objektet."
        end
    else
        code = get(o, :code, 0)
        if code == 4012
            return "Error: " * o.message * "\n" * o.message_detailed
        end
    end
    JSON3.pretty(o)
    throw("unknown response")
end




"""
    post_beta_vegnett_rute(easting1, northing1, easting2, northing2)
    --> JSON3.Object, waitsec

https://nvdbapiles-v3.atlas.vegvesen.no/dokumentasjon/openapi/#/Vegnett/post_beta_vegnett_rute
"""
function post_beta_vegnett_rute(easting1, northing1, easting2, northing2)
    # "Gyldige verdier for 'typeveg' er [kanalisertveg, enkelbilveg, rampe, rundkjøring, 
    # bilferje, passasjerferje, gangogsykkelveg, sykkelveg, gangveg, gågate, fortau, trapp, 
    # gangfelt, gatetun, traktorveg, sti, annet]
    body = Dict([
        :typeveg                => "kanalisertVeg,enkelBilveg,rampe,rundkjøring,gangOgSykkelveg"
        :konnekteringslenker    => true
        :start                  => "$easting1 , $northing1"
        :trafikantgruppe        => "K"
        :maks_avstand  => 10
        :omkrets => 100
        :detaljerte_lenker      => true
        :behold_trafikantgruppe => true
        :slutt                  => "$easting2 , $northing2"
        :tidspunkt              => "2023-07-28"
        ])
    # Make the call, get a json object
   nvdb_request("beta/vegnett/rute", "POST"; body)[1]
end


"""
    get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, vegsystemreferanse::String; inkluder = "", alle_versjoner = false)
    --> JSON3.Object

https://nvdbapiles-v3.atlas.vegvesen.no/dokumentasjon/openapi/#/Vegobjekter/get_vegobjekter__vegobjekttypeid_
"""
function get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, vegsystemreferanse::String; 
    inkluder = "", alle_versjoner = false, segmentering = false, arm = false, kommune = "")
    u = "vegobjekter/$vegobjekttype_id"
    a = urlstring(;  vegsystemreferanse = vegsystemreferanse, inkluder, alle_versjoner, segmentering, arm, kommune)
    url = build_query_string(u, a)
    o, waitsec = nvdb_request(url)
    isempty(o) && throw("Request failed, check connection")
    o
end
