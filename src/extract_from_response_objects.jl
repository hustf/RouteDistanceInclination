# Extract things we need from json3 objects we get from the API.
"""
    extract_prefixed_vegsystemreferanse(o)
    --> Vector{String}

Call this before extracting other data,
since this replaces references with an extended 
error message.
"""
function extract_prefixed_vegsystemreferanse(o, ea1, no1, ea2, no2)
    @assert !isempty(o)
    # Extract just what we want. There is much more.
    if iszero(o.metadata.antall)
        if o.metadata.status == 4040 
            msg = "Error: $(o.metadata.status)  $(o.metadata.status_tekst) \n"
            msg *= "\t$(coordinate_key(false, ea1, no1)):\n\t\t"
            msg *=  get_posisjon(ea1, no1)
            msg *= "\n\t"
            msg *= "$(coordinate_key(true, ea2, no2)):\n\t\t"
            msg *= get_posisjon(ea2, no2)
            msg *= "\n\t"
            msg *= "$(link_split_key(ea1, no1, ea2, no2))\n\t\t"
            return [msg]
        elseif o.metadata.status == 4041
            msg = "Error: $(o.metadata.status)  $(o.metadata.status_tekst) \n"
            msg *= "$(coordinate_key(false, ea1, no1)):\n\t"
            msg *=  get_posisjon(ea1, no1)
            return [msg]
        elseif o.metadata.status == 4042
            msg = "Error: $(o.metadata.status)  $(o.metadata.status_tekst) \n"
            msg *= "\n\t"
            msg *= "$(coordinate_key(true, ea2, no2)):\n\t"
            msg *= get_posisjon(ea2, no2)
            return [msg]
        else
            throw("unknown error code")
        end
    end
    map(o.vegnettsrutesegmenter) do s
        r = s.vegsystemreferanse
        @assert r.vegsystem.fase == "V" # Existing. If not, improve the query.
        sref = r.kortform
        scorr= correct_to_increasing_distance(sref)
        k = s.kommune
        "$k $scorr"
    end
end
function extract_prefixed_vegsystemreferanse(q::Quilt)
    refs = String[]
    for (o, fromto) in zip(q.patches, q.fromtos)
        append!(refs, extract_prefixed_vegsystemreferanse(o, fromto...))
    end
    refs
end



"""
    extract_length(o)
    --> Vector
"""
function extract_length(o)
    @assert hasproperty(o, :vegnettsrutesegmenter)
    if o.metadata.antall == 0
        return [NaN]
    end
    Δl = map(o.vegnettsrutesegmenter) do s
        s.lengde
    end
    total = Float64(o.metadata.lengde)
    su = sum(Δl)
    @assert su ≈ total
    Δl
end
function extract_length(q::Quilt)
    Δl = Float64[]
    for o in q.patches
        append!(Δl, extract_length(o))
    end
    Δl
end

"""
    extract_multi_linestrings(o, ea, no)
    --> Vector{Vector{Tuple{Float64, Float64, Float64}}}

The starting point coordinates are given, so that
we can reverse the linestrings returned from API.
Each vector contains a linestring.
Start and end points of each coincide.
"""
function extract_multi_linestrings(o, ea, no)
    multi_linestring = map(o.vegnettsrutesegmenter) do s
        ls = map(split(s.geometri.wkt[14:end-1], ',')) do v
            NTuple{3, Float64}(tryparse.(Float64, split(strip(v), ' ')))
        end
    end
    @assert ! isempty(multi_linestring)
    # Flip the order of points if necessary for continuity. 
    reverse_linestrings_where_needed!(multi_linestring, ea, no)
    @assert ! isempty(multi_linestring)
    check_continuity_of_multi_linestrings(multi_linestring)
    @assert ! isempty(multi_linestring)
    # Check length with straight lines between points.
    Δl_linestrings = map(length_of_linestring, multi_linestring)
    if abs(round(sum(Δl_linestrings)) - round(o.metadata.lengde)) > 4
        msg = "Trouble when checking length totals. o.metadata.lengde = $(o.metadata.lengde)\n" 
        msg *= "\t\t\tsum(Δl_linestrings) - o.metadata.lengde =  $(sum(Δl_linestrings) - o.metadata.lengde)\n"
        for (i, ref) in enumerate(vegsystemreferanse_prefixed)
            msg *= "\t$ref     Δl_linestrings[$i] = $(Δl_linestrings[i])\n"
        end
        println()
        @warn msg
    end
    multi_linestring
end
function extract_multi_linestrings(q::Quilt)
    mls = Vector{Vector{Tuple{Float64, Float64, Float64}}}()
    for (o, fromto) in zip(q.patches, q.fromtos)
        ea1, no1, _, __ = fromto
        patchml = extract_multi_linestrings(o, ea1, no1)
        append!(mls, patchml)
    end
    mls
end

"""
    extract_split_fartsgrense(o, ref_from, ref_to)
    --> () fractional_distance_of_ref, fartsgrense_start, fartsgrense_end

Returns (NaN, 0, 0) when no interpretation is found.
    
o is the object returned from request made in 

    fartsgrense_from_prefixed_vegsystemreferanse
     > get_vegobjekter__vegobjekttypeid_

ref is prefixed vegsystemreferanse for the request.
"""
function extract_split_fartsgrense(o, ref)
    ref_from, ref_to = extract_from_to_meter(ref)
    @assert hasproperty(o, :metadata) ref
    @assert hasproperty(o, :objekter) ref
    @assert o.metadata.antall == length(o.objekter) ref
    indices = collect(1:o.metadata.antall)
    # Keep top-level indices which has relevant segments
    relevant_indices = filter(indices) do i
        objekt = o.objekter[i]
        @assert hasproperty(objekt, :vegsegmenter) ref
        vegsegmenter = objekt.vegsegmenter
        relevant_segments = filter(vegsegmenter) do s
            is_segment_relevant(ref, s)
        end
        length(relevant_segments) > 0
    end
    objekter = o.objekter[relevant_indices]
    fartsgrense_objekter = map(objekter) do ob
        es = filter(ob.egenskaper) do e
            @assert hasproperty(e, :navn)
            e.navn == "Fartsgrense"
        end
        @assert length(es) == 1
        es[1]
    end
    fartsgrenser = map(fartsgrense_objekter) do fa
        @assert hasproperty(fa, :enhet)
        enhet = fa.enhet
        @assert hasproperty(enhet, :kortnavn)
        @assert enhet.kortnavn == "km/h"
        fa.verdi
    end
    if length(fartsgrenser) == 1
    end
    strekninger = map(objekter) do ob
        @assert hasproperty(ob, :vegsegmenter) ref
        vegsegmenter = filter(ob.vegsegmenter) do s
            is_segment_relevant(ref, s)
        end
        @assert length(vegsegmenter) == 1 ref
        @assert hasproperty(vegsegmenter[1], :vegsystemreferanse) ref
        vegsystemreferanse = vegsegmenter[1].vegsystemreferanse
        @assert hasproperty(vegsystemreferanse, :strekning) ref
        vegsystemreferanse.strekning
    end
    fra_meters = map(strekninger) do s
        @assert hasproperty(s, :fra_meter) 
        s.fra_meter
    end
    til_meters = map(strekninger) do s
        @assert hasproperty(s, :til_meter) 
        s.til_meter
    end
    permutation = sortperm(fra_meters)
    fra_m_s = fra_meters[permutation]
    til_m_s = til_meters[permutation] # Could be used for double checking continuity
    fartsgrenser_s = fartsgrenser[permutation]
    _extract_split_fartsgrense(fra_m_s, til_m_s, fartsgrenser_s, ref_to, ref_from)
end
function _extract_split_fartsgrense(fra_m_s, til_m_s, fartsgrenser_s, ref_to, ref_from)
    if length(fartsgrenser_s) == 0
        return (NaN, 0, 0)
    elseif length(fartsgrenser_s) == 1
        return 1.0, fartsgrenser_s[1], fartsgrenser_s[1]
    elseif length(fartsgrenser_s) == 2
        if fartsgrenser_s[1] == fartsgrenser_s[2]
            return 1.0, fartsgrenser_s[1], fartsgrenser_s[1]
        else
            split_after_ref_from = til_m_s[1]- ref_from
            fractional_distance_of_ref = split_after_ref_from / (ref_to - ref_from)
            return fractional_distance_of_ref, fartsgrenser_s[1], fartsgrenser_s[2]
        end
    elseif length(fartsgrenser_s) == 3
        # Make sure two of three are equal
        @assert fartsgrenser_s[1] == fartsgrenser_s[2] ||
            fartsgrenser_s[2] == fartsgrenser_s[3] ||
            fartsgrenser_s[1] == fartsgrenser_s[3] ref
        if fartsgrenser_s[1] == fartsgrenser_s[2]
            split_after_ref_from = til_m_s[2]- ref_from
            fractional_distance_of_ref = split_after_ref_from / (ref_to - ref_from)
            return fractional_distance_of_ref, fartsgrenser_s[1], fartsgrenser_s[3]
        else
            split_after_ref_from = til_m_s[1]- ref_from
            fractional_distance_of_ref = split_after_ref_from / (ref_to - ref_from)
            return fractional_distance_of_ref, fartsgrenser_s[1], fartsgrenser_s[2]
        end
    else
        throw("Unexpected length(fartsgrenser_s). Ref = $ref")
    end
end


