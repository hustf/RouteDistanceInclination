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
    # The length of individual segments
    lengths = extract_length(q)
    # Progression at start of first segment, start of second ... end of last.
    progression = append!([0.0], cumsum(lengths))
    mls = extract_multi_linestrings(q)
    r_extremals, s_extremals = extract_curvature_extremals_from_multi_linestrings(mls)
    fartsgrense_tuples = fartsgrense_from_prefixed_vegsystemreferanse.(refs)
    # End stops may be without defined fartsgrense, and we need 
    # a start value. We make up this.
    if isnan(fartsgrense_tuples[1][1])
        fartsgrense_tuples[1] = (1.0, 50, 50)
    end
    # Detail fartsgrense on every point of each multi_linestring.
    # A few fartgrenser may be missing. In those cases, we assume 
    # the previous
    speed_limitations = fartsgrense_at_intervals(fartsgrense_tuples, mls)
    modify_fartsgrense_with_speedbumps!(speed_limitations, refs, mls, progression)
    # 
    refs, lengths, mls, fart_mls
end
