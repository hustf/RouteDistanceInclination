"""
    patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)

This layer modifies a request to post_beta_vegnett_rute.
If the coordinate pairs (four coordinates) are recognized 
from the .ini-file, will split the request in two requests (or more).

If single coordinate pair replacements are recognized, will
then replace those before making the request.

The returned value, a quilt, both contains the request start
and end coordinates, and the resulting JSON3 objects.
"""
function patched_post_beta_vegnett_rute(ea1::T, no1::T, ea2::T, no2::T) where T<: Int
    q = Quilt()
    build_fromtos!(q, ea1, no1, ea2, no2)
    correct_coordinates!(q)
    build_patches!(q)
    @assert length(q.fromtos) == length(q.patches)
    q
end
function patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
    ea1, no1, ea2, no2 = Int.(round.([ea1, no1, ea2, no2]))
    patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
end

"Do a, rather slow, lookup and potential insertion from the .ini file."
function build_fromtos!(q::Quilt, ea1::T, no1::T, ea2::T, no2::T) where T<:Int64
    before = copy(q.fromtos)
    push!(q.fromtos, [ea1, no1, ea2, no2])
    while ! (q.fromtos == before)  # beware: q.fromtos !== before is incorrect
        before = copy(q.fromtos)
        i = 1
        while i <= length(q.fromtos)
            amend_fromtos!(q, i)
            i += 1
        end
    end
    q
end

function amend_fromtos!(q, i)
    ea1, no1, ea2, no2 = q.fromtos[i]
    key = link_split_key(ea1, no1, ea2, no2)
    value = get_config_value("link split", key, Tuple{Int64, Int64}, nothing_if_not_found = true)
    if ! isnothing(value)
        to_inserted_point = [ea1, no1, value...]
        from_inserted_point = [value..., ea2, no2]
        q.fromtos[i] = to_inserted_point
        insert!(q.fromtos, i + 1, from_inserted_point)
        print("\nLink split patch ")
        printstyled(rpad(key, 32), color = :yellow)
        print(" => ")
        printstyled("$(rpad(link_split_key(to_inserted_point...), 32))\n", color = :green)
        printstyled(repeat(' ', 53) * "$(rpad(link_split_key(from_inserted_point...), 32))\n", color = :green)
    else
        @debug "No patching for $key"
    end
    q
end

function build_patches!(q::Quilt)
    for (ea1, no1, ea2, no2) in q.fromtos
        o = post_beta_vegnett_rute(ea1, no1, ea2, no2)
        @assert !isempty(o)
        # Before failing, we'll increase 'omkrets' in steps.
        if iszero(o.metadata.antall)
            min_omkrets = 150 # Double default value
            max_omkrets = 2000 # Perhaps slow or unpredictable
            for x in range(min_omkrets, max_omkrets, length = 18)
                omkrets = Int64(round(x))
                printstyled("Retrying route request $(link_split_key(ea1, no1, ea2, no2)) with larger 'omkrets' = $omkrets \n", color =:176)
                o = post_beta_vegnett_rute(ea1, no1, ea2, no2; omkrets)
                @assert !isempty(o)
                ! iszero(o.metadata.antall) && break
            end
        end
        if iszero(o.metadata.antall)
            msg = extract_prefixed_vegsystemreferanse(o, ea1, no1, ea2, no2)[1]
            @assert ! iszero(o.metadata.antall) "$msg"
        end
        push!(q.patches, o)
    end
end



function correct_coordinates!(q::Quilt)
    for i in 1:length(q.fromtos)
        ea_out, no_out, ea_in, no_in = q.fromtos[i]
        # Out of corrected_coordinates
        ea, no = corrected_coordinates(false, ea_out, no_out)
        if ea !== ea_out
            q.fromtos[i][1] = ea
        end
        if no !== no_out
            q.fromtos[i][2] = no
        end
        # In to coords
        ea, no = corrected_coordinates(true, ea_in, no_in)
        if ea !== ea_in
            q.fromtos[i][3] = ea
        end
        if no !== no_in
            q.fromtos[i][4] = no
        end
    end
end

"""
    corrected_coordinates(ingoing::Bool, easting, northing)
    --> (x, y)

Do a, rather slow lookup and potential replacement from the .ini file.
"""
function corrected_coordinates(ingoing::Bool, easting, northing)
    key = coordinate_key(ingoing::Bool, easting, northing)
    value = get_config_value("coordinates replacement", key, Tuple{Int64, Int64}, nothing_if_not_found = true)
    if isnothing(value)
        easting, northing
    else
        print("\nCorrected coordinates ")
        printstyled(rpad(key, 16), color = :yellow)
        print(" => ")
        printstyled("$(rpad(value, 16))\n", color = :green)
        value
    end
end
