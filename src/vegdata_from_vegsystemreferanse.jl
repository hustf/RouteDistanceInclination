# Intermediate layer between 'endpoints' and 'exported'

"""
    fartsgrense_from_prefixed_vegsystemreferanse(ref)
    --> fractional_distance_of_ref::Float64, fartsgrense1::Int, fartsgrense2::Int

This interface won't work if ref has more than two speed limits.

# Example 1 

Constant speed limit

```
julia> fartsgrense_from_prefixed_vegsystemreferanse("1516 FV61 S5D1 m1085-1273")
(1.0, 60, 60
```

# Example 2

Shifting speed limit

```
julia> fractional_distance_of_ref, fartsgrense1, fartsgrense = fartsgrense_from_prefixed_vegsystemreferanse("1515 FV61 S5D1 m1527-1589")
(0.1086935483870973, 80, 60)

julia> change_at_meter = 1527 + fractional_distance_of_ref * (1589-1527)
1533.739
```


# Details

```
julia> catalogue["Fartsgrense"][:tilleggsinformasjon]
"Fartsgrense skal være heldekkende, det gjelder også ramper og rundkjøringer."

julia> catalogue["Fartsgrense"][:beskrivelse]
"Høyeste tillatte hastighet på en vegstrekning."
```
"""
function fartsgrense_from_prefixed_vegsystemreferanse(ref)
    vegobjekttype_id = 105
    o = get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, ref; inkluder = "egenskaper,vegsegmenter")
    if o.metadata.antall == 1
        @assert length(o.objekter) == 1
        egenskaper = o.objekter[1].egenskaper
        fartsgrenser = filter(e->e.navn == "Fartsgrense", egenskaper)
        @assert length(fartsgrenser) == 1
        @assert fartsgrenser[1].enhet.navn == "Kilometer/time"
        return 1.0, fartsgrenser[1].verdi, fartsgrenser[1].verdi
    elseif o.metadata.antall == 2
        egenskaper1 = o.objekter[1].egenskaper
        fartsgrenser1 = filter(e->e.navn == "Fartsgrense", egenskaper1)
        @assert length(fartsgrenser1) == 1
        @assert fartsgrenser1[1].enhet.navn == "Kilometer/time"
        fartsgrense1 = fartsgrenser1[1].verdi
        #
        egenskaper2 = o.objekter[2].egenskaper
        fartsgrenser2 = filter(e->e.navn == "Fartsgrense", egenskaper2)
        @assert length(fartsgrenser2) == 1
        @assert fartsgrenser2[1].enhet.navn == "Kilometer/time"
        fartsgrense2 = fartsgrenser2[1].verdi
        if fartsgrense1 == fartsgrense2
            return 1.0, fartsgrense1, fartsgrense1
        else
            vegsegmenter1 = o.objekter[1].vegsegmenter
            @assert length(vegsegmenter1) == 1
            vegsegmenter2 = o.objekter[2].vegsegmenter
            @assert length(vegsegmenter2) == 1
            vegsystemreferanse1 = vegsegmenter1[1].vegsystemreferanse
            @assert hasproperty(vegsystemreferanse1, :strekning)
            vegsystemreferanse2 = vegsegmenter2[1].vegsystemreferanse
            @assert hasproperty(vegsystemreferanse2, :strekning)
            @assert vegsystemreferanse1.strekning.strekning == vegsystemreferanse2.strekning.strekning
            @assert vegsystemreferanse1.strekning.delstrekning == vegsystemreferanse2.strekning.delstrekning
            fra_meter1 = vegsystemreferanse1.strekning.fra_meter
            til_meter1 = vegsystemreferanse1.strekning.til_meter
            fra_meter2 = vegsystemreferanse2.strekning.fra_meter
            til_meter2 = vegsystemreferanse2.strekning.til_meter
            @assert fra_meter1 >= fra_meter1
            # Compare with request ref
            ref_fra_til = split(ref, ' ')[end]
            @assert startswith(ref_fra_til, 'm')
            ref_fra = tryparse(Float64, split(ref_fra_til[2:end], '-')[1])
            ref_til = tryparse(Float64, split(ref_fra_til[2:end], '-')[2])
            @assert ref_fra < ref_til
            if fra_meter1 < fra_meter2
                @assert fra_meter1 <= ref_fra
                @assert til_meter2 >= ref_til
                split_after_ref_fra = til_meter1 - ref_fra
                fractional_distance_of_ref = split_after_ref_fra / (ref_til - ref_fra)
                return fractional_distance_of_ref, fartsgrense2, fartsgrense1
            else
                @assert fra_meter2 <= ref_fra
                @assert til_meter1 >= ref_til
                split_after_ref_fra = til_meter2 - ref_fra
                fractional_distance_of_ref = split_after_ref_fra / (ref_til - ref_fra)
                return fractional_distance_of_ref, fartsgrense1, fartsgrense2
            end
        end
    elseif o.metadata.antall == 3
        egenskaper1 = o.objekter[1].egenskaper
        fartsgrenser1 = filter(e->e.navn == "Fartsgrense", egenskaper1)
        @assert length(fartsgrenser1) == 1
        @assert fartsgrenser1[1].enhet.navn == "Kilometer/time"
        fartsgrense1 = fartsgrenser1[1].verdi
        #
        egenskaper2 = o.objekter[2].egenskaper
        fartsgrenser2 = filter(e->e.navn == "Fartsgrense", egenskaper2)
        @assert length(fartsgrenser2) == 1
        @assert fartsgrenser2[1].enhet.navn == "Kilometer/time"
        fartsgrense2 = fartsgrenser2[1].verdi
        #
        egenskaper3 = o.objekter[3].egenskaper
        fartsgrenser3 = filter(e->e.navn == "Fartsgrense", egenskaper3)
        @assert length(fartsgrenser3) == 1
        @assert fartsgrenser3[1].enhet.navn == "Kilometer/time"
        fartsgrense3 = fartsgrenser3[1].verdi
        if fartsgrense1 == fartsgrense2 == fartsgrense3
            return 1.0, fartsgrense1, fartsgrense1
        else
            throw("Not yet implemented. ref = $ref , fartsgrenser = $(fartsgrense1) $(fartsgrense2) $(fartsgrense3)")
            vegsegmenter1 = o.objekter[1].vegsegmenter
            @assert length(vegsegmenter1) == 1
            vegsegmenter2 = o.objekter[2].vegsegmenter
            @assert length(vegsegmenter2) == 1
            vegsystemreferanse1 = vegsegmenter1[1].vegsystemreferanse
            @assert hasproperty(vegsystemreferanse1, :strekning)
            vegsystemreferanse2 = vegsegmenter2[1].vegsystemreferanse
            @assert hasproperty(vegsystemreferanse2, :strekning)
            @assert vegsystemreferanse1.strekning.strekning == vegsystemreferanse2.strekning.strekning
            @assert vegsystemreferanse1.strekning.delstrekning == vegsystemreferanse2.strekning.delstrekning
            fra_meter1 = vegsystemreferanse1.strekning.fra_meter
            til_meter1 = vegsystemreferanse1.strekning.til_meter
            fra_meter2 = vegsystemreferanse2.strekning.fra_meter
            til_meter2 = vegsystemreferanse2.strekning.til_meter
            @assert fra_meter1 >= fra_meter1
            # Compare with request ref
            ref_fra_til = split(ref, ' ')[end]
            @assert startswith(ref_fra_til, 'm')
            ref_fra = tryparse(Float64, split(ref_fra_til[2:end], '-')[1])
            ref_til = tryparse(Float64, split(ref_fra_til[2:end], '-')[2])
            @assert ref_fra < ref_til
            if fra_meter1 < fra_meter2
                @assert fra_meter1 <= ref_fra
                @assert til_meter2 >= ref_til
                split_after_ref_fra = til_meter1 - ref_fra
                fractional_distance_of_ref = split_after_ref_fra / (ref_til - ref_fra)
                return fractional_distance_of_ref, fartsgrense2, fartsgrense1
            else
                @assert fra_meter2 <= ref_fra
                @assert til_meter1 >= ref_til
                split_after_ref_fra = til_meter2 - ref_fra
                fractional_distance_of_ref = split_after_ref_fra / (ref_til - ref_fra)
                return fractional_distance_of_ref, fartsgrense1, fartsgrense2
            end
        end

    else
        throw(">Three fartsgrenser? We may have to do this in another way. ref = $ref")
    end
end
#=

j = 1
url = "vegobjekter/$vegobjekttype_id/$(subref_ids[j])/1"
sub_o = nvdb_request(url)[1]
@test length(sub_o.egenskaper) == 4

egenskaper = filter(e->e.navn == "Fartsgrense", sub_o.egenskaper)
@test length(egenskaper) == 1
egenskap = egenskaper[1]
@test egenskap.enhet == "Kilometer/time"
@test egenskap.verdi == 60

=#