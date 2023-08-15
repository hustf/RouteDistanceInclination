"""
    route_data(easting1::T, northing1::T, easting2::T, northing2::T) where T <: Float64

    --> refs, lengths, multi_linestrings

Arguments are start and end points given in UTM33 coordinates.
"""
function route_data(easting1::T, northing1::T, easting2::T, northing2::T) where T <: Float64
    # Identify the bits of road we're taking from 1 to 2. 
    q = patched_post_beta_vegnett_rute(easting1, northing1, easting2, northing2)
    refs = extract_prefixed_vegsystemreferanse(q)
    @assert ! startswith(refs[1], "Error") refs[1]
    lengths = extract_length(q)
    mls = extract_multi_linestrings(q)
    fart_tuples = fartsgrense_from_prefixed_vegsystemreferanse.(refs)
    # End stops may be without defined fartsgrense, and we need 
    # a start value.
    if isnan(fart_tuples[1][1])
        fart_tuples[1] = (1.0, 50, 50)
    end
    # Detail fartsgrense on every point of each multi_linestring.
    # A few fartgrenser may be missing. In those cases, we assume 
    # the previous
    fart_mls = fartsgrense_at_intervals(fart_tuples, mls)
    refs, lengths, mls, fart_mls
end
