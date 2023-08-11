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
function get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, vegsystemreferanse::String; inkluder = "", alle_versjoner = false)
    u = "vegobjekter/$vegobjekttype_id"
    a = urlstring(;  vegsystemreferanse = vegsystemreferanse, inkluder, alle_versjoner)
    url = build_query_string(u, a)
    nvdb_request(url)[1]
end

#=
    # "Kurvatur, stigning"
    # "Angir gjennomsnittlig stigning på strekning. Basert på silingsfunksjon i forhold til primære høydedata. 
    #  Splitting i ny forekomst når avvik større enn gitt verdi"
    url = "vegobjekter/$vegobjekttype_id?&vegsystemreferanse=$r"
    o = nvdb_request(url)[1]
    for (r, Δl) in zip(refs, Δls)
        url = "vegobjekter/$vegobjekttype_id?&vegsystemreferanse=$r"
        o = nvdb_request(url)[1]
        subref_ids = map(o.objekter) do s
            s.id
        end
        sub_Δls = Float64[]
        for id in subref_ids
            println("r = $r    id = $id")
            url = "vegobjekter/$vegobjekttype_id/$id/1"
            sub_o = nvdb_request(url)[1]
            @assert hasproperty(sub_o, :lokasjon)
            @assert length(sub_o.egenskaper) == 3
            @assert hasproperty(sub_o.egenskaper[2], :verdi)
            @assert sub_o.egenskaper[2].enhet.navn == "Prosent"
            @assert hasproperty(sub_o.lokasjon, :lengde)
            @assert startswith(sub_o.geometri.wkt, "LINESTRING Z(")
            @assert hasproperty(sub_o, :geometri)
            @assert hasproperty(sub_o.lokasjon, :vegsystemreferanser)
            @assert length(sub_o.lokasjon.vegsystemreferanser) == 1
            @assert hasproperty(sub_o.lokasjon.vegsystemreferanser[1], :strekning)
            @assert hasproperty(sub_o.lokasjon.vegsystemreferanser[1].strekning, :fra_meter)
            @assert hasproperty(sub_o.lokasjon.vegsystemreferanser[1].strekning, :til_meter)
            # The subdivision may include parts outside of the requested ref.
            # We will want to truncate and keep only the relevant parts.
            # TODO: See if we can get the linestring from elsewhere. 
            # We do need to ask for Fartsdemper, Fartsgrense 

            # Parse text to number collection
            linestring = map(split(sub_o.geometri.wkt[14:end-1], ',')) do v
                NTuple{3, Float64}(tryparse.(Float64, split(strip(v), ' ')))
            end







            # For checking that subdivisions sum up to the total.
            sub_Δl = sub_o.lokasjon.lengde
            push!(sub_Δls, sub_Δl)
            # Check that subdivision inclination is average from start to end
            inclination = 0.01 * sub_o.egenskaper[2].verdi  # Percent is unimpressive
            Δh = inclination * sub_Δl
            @assert abs(linestring[end][3] - linestring[1][3] - Δh ) < 1


            # For output
            push!(inclinations, inclination)
            push!(Δls_redivided, sub_Δl)
            push!(multi_linestring, linestring)
        end
        @assert abs(sum(sub_Δls) - Δl) < 1 "sub_Δls = $sub_Δls   sum(sub_Δls) = $(sum(sub_Δls)) \n\t Δl = $Δl"
    end
    inclinations, Δls_redivided, multi_linestring
end
=#

#=
"""
    get_vegobjekter__vegobjekttypeid_(refs, Δls)
    --> JSON3.Object, waitsec


https://nvdbapiles-v3.atlas.vegvesen.no/dokumentasjon/openapi/#/Vegobjekter/get_vegobjekter__vegobjekttypeid_

# Arguments

...are vectors of the same length.

refs is 'vegsystemreferanse's prefixed by 'kommunenummer'
Δls  is corresponding lengths for checking purposes

# Output

Many 'veglenke' are subdivided, so the length of vectors is larger or equal to input vectors.
All vectors have the same length.

    inclinations      is Δh / Δl
    Δls_redivided     we checked that the sum is roughly equal to Δls
    multi_linestring  3d points in UTM33. Not actual strings.
"""
function get_vegobjekter__vegobjekttypeid_(refs, Δls)
    # "Kurvatur, stigning"
    # "Angir gjennomsnittlig stigning på strekning. Basert på silingsfunksjon i forhold til primære høydedata. 
    #  Splitting i ny forekomst når avvik større enn gitt verdi"
    vegobjekttype_id = 825 
    inclinations = Float64[]
    Δls_redivided = Float64[]
    multi_linestring = Vector{Vector{Tuple{Float64, Float64, Float64}}}()
    for (r, Δl) in zip(refs, Δls)
        url = "vegobjekter/$vegobjekttype_id?&vegsystemreferanse=$r"
        o = nvdb_request(url)[1]
        subref_ids = map(o.objekter) do s
            s.id
        end
        sub_Δls = Float64[]
        for id in subref_ids
            println("r = $r    id = $id")
            url = "vegobjekter/$vegobjekttype_id/$id/1"
            sub_o = nvdb_request(url)[1]
            @assert hasproperty(sub_o, :lokasjon)
            @assert length(sub_o.egenskaper) == 3
            @assert hasproperty(sub_o.egenskaper[2], :verdi)
            @assert sub_o.egenskaper[2].enhet.navn == "Prosent"
            @assert hasproperty(sub_o.lokasjon, :lengde)
            @assert startswith(sub_o.geometri.wkt, "LINESTRING Z(")
            @assert hasproperty(sub_o, :geometri)
            @assert hasproperty(sub_o.lokasjon, :vegsystemreferanser)
            @assert length(sub_o.lokasjon.vegsystemreferanser) == 1
            @assert hasproperty(sub_o.lokasjon.vegsystemreferanser[1], :strekning)
            @assert hasproperty(sub_o.lokasjon.vegsystemreferanser[1].strekning, :fra_meter)
            @assert hasproperty(sub_o.lokasjon.vegsystemreferanser[1].strekning, :til_meter)
            # The subdivision may include parts outside of the requested ref.
            # We will want to truncate and keep only the relevant parts.
            # TODO: See if we can get the linestring from elsewhere. 
            # We do need to ask for Fartsdemper, Fartsgrense 

            # Parse text to number collection
            linestring = map(split(sub_o.geometri.wkt[14:end-1], ',')) do v
                NTuple{3, Float64}(tryparse.(Float64, split(strip(v), ' ')))
            end







            # For checking that subdivisions sum up to the total.
            sub_Δl = sub_o.lokasjon.lengde
            push!(sub_Δls, sub_Δl)
            # Check that subdivision inclination is average from start to end
            inclination = 0.01 * sub_o.egenskaper[2].verdi  # Percent is unimpressive
            Δh = inclination * sub_Δl
            @assert abs(linestring[end][3] - linestring[1][3] - Δh ) < 1


            # For output
            push!(inclinations, inclination)
            push!(Δls_redivided, sub_Δl)
            push!(multi_linestring, linestring)
        end
        @assert abs(sum(sub_Δls) - Δl) < 1 "sub_Δls = $sub_Δls   sum(sub_Δls) = $(sum(sub_Δls)) \n\t Δl = $Δl"
    end
    inclinations, Δls_redivided, multi_linestring
end
=#