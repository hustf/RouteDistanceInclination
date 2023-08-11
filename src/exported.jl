"""
    route_data(easting1::T, northing1::T, easting2::T, northing2::T) where T <: Float64

    --> refs, Δls, multi_linestrings

Arguments are start and end points given in UTM33 coordinates.
"""
function route_data(easting1::T, northing1::T, easting2::T, northing2::T) where T <: Float64
    # Identify the bits of road we're taking from 1 to 2. 
    q = patched_post_beta_vegnett_rute(easting1, northing1, easting2, northing2)
    refs = extract_prefixed_vegsystemreferanse(q)
    @assert ! startswith(refs[1], "Error") refs[1]
    lengths = extract_length(q)
    mls = extract_multi_linestrings(q)
    @show refs
    fart_tuples = fartsgrense_from_prefixed_vegsystemreferanse.(refs)
    # Ask nicely for fartsgrense, fartsdemper.
    # Then we might calculate curvature and output spline functions.
    # But points are useful, too, for feedback, so maybe put that elsewhere.-+
    #inclination, inc_lengde = get_vegobjekter_vegobjekttypeid_(refs, Δls)
    # Ask nicely for speed limit
    #Δl, inclination, inc_lengde
    fart_tuples
end
