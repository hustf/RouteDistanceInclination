"""
    patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)

This layer modifies a request to post_beta_vegnett_rute,
splits them in two if necessary,
and stitches the returned segments together.
"""
function patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
    # First insert extra points where recognized
    sequence = sequential_patched_positions(ea1, no1, ea2, no2)
    # Then replace recognized points
    for i in 1:length(sequence)
        tup = sequence[i]
        ingoing = i == 1 ? false : true
        sequence[i] = corrected_coordinates(ingoing, tup...)
    end
    vegsystemreferanse_prefixed = String[]
    Δl = Float64[]
    multi_linestrings = Vector{Vector{Tuple{Float64, Float64, Float64}}}()
    # Collect patches and add them to the quilt
    for i in 1:(length(sequence) - 1)
        tup1 = sequence[i]
        tup2 = sequence[i + 1]
        refs, lengths, multi_linestring = post_beta_vegnett_rute(tup1..., tup2...)
        # Add this patch to output
        append!(vegsystemreferanse_prefixed, refs)
        append!(Δl, lengths)
        append!(multi_linestring, multi_linestrings)
    end
    # Output the quilt
    vegsystemreferanse_prefixed, Δl, multi_linestrings
end


"""
    corrected_coordinates(ingoing::Bool, easting, northing)

Do a, rather slow lookup and potential replacement from the .ini file.
"""
function corrected_coordinates(ingoing::Bool, easting, northing)
    key = coordinate_key(ingoing::Bool, easting, northing)
    value = get_config_value("coordinates replacement", key, Tuple{Float64, Float64}, nothing_if_not_found = true)
    if isnothing(value)
        easting, northing
    else
        value
    end
end

"""
    sequential_patched_positions(ea1, no1, ea2, no2)
    --> Vector{Tuple{Float64, Float64}}

Do a, rather slow lookup and potential replacement from the .ini file.
An unpatched sequence has length 2.
"""
function sequential_patched_positions(ea1, no1, ea2, no2)
    sequence = Vector{Tuple{Float64, Float64}}()
    push!(sequence, (ea1, no1))
    key = link_split_key(ea1, no1, ea2, no2)
    value = get_config_value("link split", key, Tuple{Float64, Float64}, nothing_if_not_found = true)
    if ! isnothing(value)
        push!(sequence, value)
    end
    push!(sequence, (ea2, no2))
    sequence
end