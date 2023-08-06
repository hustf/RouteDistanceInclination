using RouteSlopeDistance
using RouteSlopeDistance: patched_post_beta_vegnett_rute
M = ["Hareid bussterminal" 36975.94566374121 6.947658805705906e6; "Hareid ungdomsskule fv. 61" 36532.55545087671 6.947581886945733e6; "Holstad" 35983.1443116063 6.947673163559002e6; "Grimstad aust" 35464.96463259688 6.947468011095509e6; "Grimstad vest" 34865.66712469625 6.947308159359314e6; "Bjåstad aust" 34417.88533130888 6.94710510180928e6; "Bjåstad vest" 34054.27868455148 6.946887317608121e6; "Bigsetkrysset" 33728.64367864374 6.946682380315655e6; "Byggeli" 33142.22175210371 6.946488830511735e6; "Nybøen" 32851.70907960052 6.946449354497116e6; "Korshaug" 32343.566099463962 6.946360408979714e6; "Rise aust" 31908.81277878303 6.946301439017767e6; "Rise" 31515.075405728596 6.946166435782562e6; "Rise vest" 31166.8812895664 6.946060114423563e6; "Varleitekrysset" 29426.092089441197 6.945334778036252e6; "Ulstein vgs." 28961.357645253593 6.945248138849279e6; "Støylesvingen" 28275.444230089895 6.945288942957118e6; "Holsekerdalen" 27714.179788790876 6.945606747071537e6; "Ulsteinvik skysstasjon" 27262.18078544963 6.945774337512597e6; "Saunes nord" 27457.300948846503 6.945077356432355e6; "Saunes sør" 27557.2207297993 6.944743999927791e6; "Strandabøen" 27810.953292181366 6.944172090808818e6; "Dimnakrysset" 27720.899809156603 6.943086326247893e6; "Botnen" 26807.34408127074 6.941533714193652e6; "Garneskrysset" 26448.894934401556 6.940129956181607e6; "Dragsund sør" 24823.194600016985 6.939041381131042e6; "Myrvåglomma" 23910.869586607092 6.938920557515621e6; "Myrvåg" 23411.547657008457 6.939347655974448e6; "Aurvåg" 22731.993701261526 6.939785509768682e6; "Aspevika" 22119.248180354887 6.939611088769487e6; "Kalveneset" 21507.79140086705 6.939661984886746e6; "Tjørvåg indre" 20670.579345440492 6.939661472948665e6; "Tjørvåg" 20295.777947708208 6.93996120795614e6; "Tjørvågane" 20222.213099840155 6.940343660939465e6; "Tjørvåg nord" 20407.956564288645 6.940731998657505e6; "Rafteset" 20793.75811150472 6.941312130095156e6; "Storneset" 20778.735032497556 6.941911649292342e6; "Stokksund" 20353.192697804363 6.94241189645477e6; "Notøy" 19428.907322990475 6.943496947023508e6; "Røyra øst" 19921.774665450328 6.944582534682405e6; "Røyra vest" 19604.993318945984 6.944607764588606e6; "Frøystadvåg" 19495.16047112737 6.94540013477574e6; "Frøystadkrysset" 19646.29224914976 6.9457027824882725e6; "Nerøykrysset" 18738.6739445625 6.946249249481636e6; "Berge bedehus" 17918.84676897031 6.946488791539114e6; "Elsebøvegen" 17679.55323949206 6.946358107562704e6; "Verket" 17441.2284281507 6.946183037961578e6; "Berge" 17254.861414988118 6.946052685186134e6; "Hjelmeset" 16948.82774523727 6.94588028132061e6; "Demingane" 16575.39314737235 6.945716940684748e6; "Eggesbønes" 16077.868413755263 6.94569855075708e6; "Myklebust" 16016.077339820331 6.945895007681623e6; "Herøy kyrkje" 16156.369994148146 6.946651348835291e6; "Fosnavåg sparebank" 16235.327457943466 6.94727099225032e6; "Fosnavåg terminal" 16063.782613804331 6.947514879242669e6]

# This route should be easy
start = 5
stop = 6
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
vegsystemreferanse_prefi-xed, Δl = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
println(vegsystemreferanse_prefixed[1])

# Test status 4041. This also triggers Http error 404. We don't suppress that mistake.
start = 1
stop = 2
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
vegsystemreferanse_prefixed, Δl = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
println(vegsystemreferanse_prefixed[1])

# Test status 4042. This also triggers Http error 404. We don't suppress that mistake.
start = 54
stop = 55
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
vegsystemreferanse_prefixed, Δl = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
println(vegsystemreferanse_prefixed[1])

# Test status 4040
start = 39
stop = 40
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
vegsystemreferanse_prefixed, Δl = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
println(vegsystemreferanse_prefixed[1])

# This skips the layer where we patch errors in finding routes.
# We use the output to make patches.
rws = 1:(size(M)[1])
for (start, stop) in zip(rws[1: (end - 1)], rws[2:end])
    println()
    na1, ea1, no1 = M[start, :]
    na2, ea2, no2 = M[stop, :]
    print(lpad("$start $stop", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
    vegsystemreferanse_prefixed, Δl = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
    for (r, Δ) in zip(vegsystemreferanse_prefixed, Δl)
         print(r, "  Δl = ",  Δ)
         print("\n", lpad(" ", 72))
    end
    println()
end




#=
  1 2             Hareid bussterminal -> Hareid ungdomsskule fv. 61          GET https://nvdbapiles-v3.test.atlas.vegvesen.no/posisjon?nord=6.947658805705906e6&ost=36975.94566374121&maks_avstand=10
Error: 4041  IKKE_FUNNET_STARTPUNKT 
Out of 36976 6947659:
        Error: Fant ingen veglenkesekvenser i nærheten av søkepunkt: POINT (36975.9457 6947658.8057)
Det er for lang avstand til nærmeste veg  Δl = 0.0


  2 3      Hareid ungdomsskule fv. 61 -> Holstad                        1517 FV61 S3D1 m481-559  Δl = 77.955
                                                                        1517 FV61 S3D1 m559-632  Δl = 72.203
                                                                        1517 FV61 S3D1 m632-743  Δl = 111.43
                                                                        1517 FV61 S3D1 m743-895  Δl = 151.553
                                                                        1517 FV61 S3D1 m895-946  Δl = 51.691
                                                                        1517 FV61 S3D1 m946-1012  Δl = 65.798
                                                                        1517 FV61 S3D1 m1012-1048  Δl = 35.656


  3 4                         Holstad -> Grimstad aust                  1517 FV61 S3D1 m1048-1125  Δl = 77.565
                                                                        1517 FV61 S3D1 m1125-1179  Δl = 53.445
                                                                        1517 FV61 S3D1 m1179-1218  Δl = 38.815
                                                                        1517 FV61 S3D1 m1218-1307  Δl = 89.517
                                                                        1517 FV61 S3D1 m1307-1486  Δl = 179.053
                                                                        1517 FV61 S3D1 m1486-1533  Δl = 47.068
                                                                        1517 FV61 S3D1 m1533-1557  Δl = 23.318
                                                                        1517 FV61 S3D1 m1557-1606  Δl = 49.445


  4 5                   Grimstad aust -> Grimstad vest                  1517 FV61 S3D1 m1606-1609  Δl = 2.638
                                                                        1517 FV61 S3D1 m1609-1685  Δl = 75.899
                                                                        1517 FV61 S3D1 m1685-1758  Δl = 73.708
                                                                        1517 FV61 S3D1 m1758-1766  Δl = 7.864
                                                                        1517 FV61 S3D1 m1766-1954  Δl = 187.932
                                                                        1517 FV61 S3D1 m1954-2058  Δl = 104.452
                                                                        1517 FV61 S3D1 m2058-2132  Δl = 73.798
                                                                        1517 FV61 S3D1 m2132-2231  Δl = 99.082


  5 6                   Grimstad vest -> Bjåstad aust                   1517 FV61 S3D1 m2231-2237  Δl = 5.247
                                                                        1517 FV61 S3D1 m2237-2315  Δl = 78.415
                                                                        1517 FV61 S3D1 m2315-2423  Δl = 108.17
                                                                        1517 FV61 S3D1 m2423-2524  Δl = 100.911
                                                                        1517 FV61 S3D1 m2524-2602  Δl = 78.216
                                                                        1517 FV61 S3D1 m2602-2618  Δl = 15.571
                                                                        1517 FV61 S3D1 m2618-2666  Δl = 47.67
                                                                        1517 FV61 S3D1 m2666-2723  Δl = 57.935


  6 7                    Bjåstad aust -> Bjåstad vest                   1517 FV61 S3D1 m2723-2744  Δl = 20.344
                                                                        1517 FV61 S3D1 m2744-2893  Δl = 149.284
                                                                        1517 FV61 S3D1 m2893-2955  Δl = 61.845
                                                                        1517 FV61 S3D1 m2955-2987  Δl = 31.799
                                                                        1517 FV61 S3D1 m2987-3069  Δl = 81.908
                                                                        1517 FV61 S3D1 m3069-3135  Δl = 66.366
                                                                        1517 FV61 S3D1 m3135-3148  Δl = 13.383


  7 8                    Bjåstad vest -> Bigsetkrysset                  1517 FV61 S3D1 m3148-3154  Δl = 5.882
                                                                        1517 FV61 S3D1 m3154-3190  Δl = 36.057
                                                                        1517 FV61 S3D1 m3190-3286  Δl = 96.144
                                                                        1517 FV61 S3D1 m3286-3306  Δl = 19.398
                                                                        1517 FV61 S3D1 m3306-3338  Δl = 31.996
                                                                        1517 FV61 S3D1 m3338-3358  Δl = 20.374
                                                                        1517 FV61 S3D1 m3358-3426  Δl = 67.696
                                                                        1517 FV61 S3D1 m3426-3455  Δl = 29.415
                                                                        1517 FV61 S3D1 m3455-3482  Δl = 26.8
                                                                        1517 FV61 S3D1 m3482-3490  Δl = 7.448
                                                                        1517 FV61 S3D1 m3490-3533  Δl = 43.734


  8 9                   Bigsetkrysset -> Byggeli                        1517 FV61 S3D1 m3533-3547  Δl = 13.654
                                                                        1517 FV61 S3D1 m3547-3555  Δl = 7.517
                                                                        1517 FV61 S3D1 m3555-3564  Δl = 9.066
                                                                        1517 FV61 S3D1 m3564-3577  Δl = 12.945
                                                                        1517 FV61 S3D1 m3577-3731  Δl = 154.225
                                                                        1517 FV61 S3D1 m3731-3826  Δl = 95.455
                                                                        1517 FV61 S3D1 m3826-3907  Δl = 80.824
                                                                        1517 FV61 S3D1 m3907-3942  Δl = 34.79
                                                                        1517 FV61 S3D1 m3942-4017  Δl = 74.79
                                                                        1517 FV61 S3D1 m4017-4026  Δl = 9.331
                                                                        1517 FV61 S3D1 m4026-4050  Δl = 24.277
                                                                        1517 FV61 S3D1 m4050-4147  Δl = 96.441
                                                                        1517 FV61 S3D1 m4147-4171  Δl = 24.006


 9 10                         Byggeli -> Nybøen                         1517 FV61 S3D1 m4171-4304  Δl = 133.623
                                                                        1517 FV61 S3D1 m4304-4382  Δl = 77.772
                                                                        1517 FV61 S3D1 m4382-4440  Δl = 57.78
                                                                        1517 FV61 S3D1 m4440-4465  Δl = 24.856


10 11                          Nybøen -> Korshaug                       1517 FV61 S3D1 m4465-4490  Δl = 24.954
                                                                        1517 FV61 S3D1 m4490-4497  Δl = 7.636
                                                                        1517 FV61 S3D1 m4497-4714  Δl = 216.416
                                                                        1517 FV61 S3D1 m4714-4716  Δl = 2.448
                                                                        1517 FV61 S3D1 m4716-4765  Δl = 49.301
                                                                        1517 FV61 S3D1 m4765-4798  Δl = 32.586
                                                                        1517 FV61 S3D1 m4798-4953  Δl = 154.466
                                                                        1517 FV61 S3D1 m4953-4961  Δl = 8.338
                                                                        1517 FV61 S3D1 m4961-4979  Δl = 18.489


11 12                        Korshaug -> Rise aust                      1517 FV61 S3D1 m4979-5287  Δl = 307.256
                                                                        1517 FV61 S3D1 m5287-5314  Δl = 26.972
                                                                        1517 FV61 S3D1 m5314-5415  Δl = 100.981
                                                                        1517 FV61 S3D1 m5415-5423  Δl = 8.576


12 13                       Rise aust -> Rise                           1517 FV61 S3D1 m5423-5520  Δl = 97.367
                                                                        1517 FV61 S3D1 m5520-5526  Δl = 5.073
                                                                        1517 FV61 S3D1 m5526-5595  Δl = 69.465
                                                                        1517 FV61 S3D1 m5595-5786  Δl = 190.768
                                                                        1517 FV61 S3D1 m5786-5814  Δl = 27.947
                                                                        1517 FV61 S3D1 m5814-5840  Δl = 26.202


13 14                            Rise -> Rise vest                      1517 FV61 S3D1 m5840-5853  Δl = 12.887
                                                                        1517 FV61 S3D1 m5853-6038  Δl = 185.504
                                                                        1517 FV61 S3D1 m6038-6200  Δl = 162.083
                                                                        1517 FV61 S3D1 m6200-6205  Δl = 4.14


14 15                       Rise vest -> Varleitekrysset                1517 FV61 S3D1 m6205-6400  Δl = 194.967
                                                                        1517 FV61 S3D1 m6400-6759  Δl = 359.624
                                                                        1517 FV61 S3D1 m6759-7059  Δl = 299.73
                                                                        1516 FV61 S3D1 m7059-7468  Δl = 408.987
                                                                        1516 FV61 S3D1 m7468-7954  Δl = 486.616
                                                                        1516 FV61 S3D1 m7954-8071  Δl = 117
                                                                        1516 FV61 S3D1 m8071-8081  Δl = 9.79
                                                                        1516 FV61 S3D1 m8081-8089  Δl = 8.21
                                                                        1516 FV61 S3D1 m8089-8115  Δl = 25.179


15 16                 Varleitekrysset -> Ulstein vgs.                   1516 FV61 S3D1 m8115-8350  Δl = 234.98
                                                                        1516 FV61 S3D1 m8350-8364  Δl = 14.401
                                                                        1516 FV61 S3D1 m8364-8447  Δl = 82.954
                                                                        1516 FV61 S3D1 m8447-8452  Δl = 4.531
                                                                        1516 KV1123 S1D1 m1909-1934  Δl = 29.013
                                                                        1516 KV1123 S1D1 m1871-1909  Δl = 38.975
                                                                        1516 KV1123 S1D1 m1860-1871  Δl = 10.088
                                                                        1516 KV1123 S1D1 m1818-1860  Δl = 41.973
                                                                        1516 KV1123 S1D1 m1818-1769  Δl = 49.566


16 17                    Ulstein vgs. -> Støylesvingen                  1516 KV1123 S1D1 m1769-1738  Δl = 31.008
                                                                        1516 KV1123 S1D1 m1587-1738  Δl = 151.244
                                                                        1516 KV1123 S1D1 m1540-1587  Δl = 46.553
                                                                        1516 KV1023 S1D1 m0-11  Δl = 10.731
                                                                        1516 KV1123 S2D50 m275-530  Δl = 255.787
                                                                        1516 PV1123 S1D1 m0-9  Δl = 9.117
                                                                        1516 KV1123 S1D1 m1200-1279  Δl = 79.51
                                                                        1516 KV1123 S1D1 m1003-1200  Δl = 196.886
                                                                        1516 KV1123 S1D1 m997-1003  Δl = 5.474
                                                                        1516 KV1123 S1D1 m997-994  Δl = 3.471


17 18                   Støylesvingen -> Holsekerdalen                  1516 KV1123 S1D1 m994-990  Δl = 4.122
                                                                        1516 KV1123 S1D1 m531-990  Δl = 458.406
                                                                        1516 KV1123 S1D1 m505-531  Δl = 26.611
                                                                        1516 KV1123 S1D1 m478-505  Δl = 26.421
                                                                        1516 KV1123 S1D1 m312-478  Δl = 166.733
                                                                        1516 KV1123 S1D1 m289-312  Δl = 23.063


18 19                   Holsekerdalen -> Ulsteinvik skysstasjon         Error: 4042  IKKE_FUNNET_SLUTTPUNKT 

        In to 27262 6945774:
        Error: Vegsystemreferanse mangler på dette objektet.  Δl = 0.0


19 20          Ulsteinvik skysstasjon -> Saunes nord                    Error: 4041  IKKE_FUNNET_STARTPUNKT 
Out of 27262 6945774:
        Error: Vegsystemreferanse mangler på dette objektet.  Δl = 0.0


20 21                     Saunes nord -> Saunes sør                     1516 FV61 S3D30 m609-611  Δl = 2.497
                                                                        1516 FV61 S3D30 m569-609  Δl = 39.929
                                                                        1516 FV61 S3D30 m502-569  Δl = 67.227
                                                                        1516 FV61 S3D30 m497-502  Δl = 4.936
                                                                        1516 FV61 S3D30 m405-497  Δl = 91.453
                                                                        1516 FV61 S3D30 m394-405  Δl = 11.038
                                                                        1516 FV61 S3D30 m314-394  Δl = 80.623
                                                                        1516 FV61 S3D30 m260-314  Δl = 53.874


21 22                      Saunes sør -> Strandabøen                    1516 FV61 S3D30 m258-260  Δl = 1.825
                                                                        1516 FV61 S3D30 m30-258  Δl = 228.168
                                                                        1516 FV61 S3D30 m11-30  Δl = 18.304
                                                                        1516 FV61 S3D30 m4-11  Δl = 7.405
                                                                        1516 FV61 S3D30 m0-4  Δl = 3.956
                                                                        1516 FV61 S3D1 m10639 KD1 m14-19  Δl = 5
                                                                        1516 FV61 S3D1 m10639 KD1 m19-26  Δl = 7
                                                                        1516 FV61 S3D1 m10639-10651  Δl = 13.407
                                                                        1516 FV61 S3D1 m10651-10652  Δl = 0.431
                                                                        1516 FV61 S3D1 m10652-10653  Δl = 0.098
                                                                        1516 FV61 S3D1 m10653-10656  Δl = 5.11
                                                                        1516 FV61 S3D1 m10656-10669  Δl = 12.559
                                                                        1516 FV61 S3D1 m10669-10723  Δl = 53.794
                                                                        1516 FV61 S4D1 m0-5  Δl = 4.507
                                                                        1516 FV61 S4D1 m5-261  Δl = 256.08
                                                                        1516 FV61 S4D1 m261-284  Δl = 23.292


22 23                     Strandabøen -> Dimnakrysset                   1516 FV61 S4D1 m284-319  Δl = 35.051
                                                                        1516 FV61 S4D1 m319-503  Δl = 184.229
                                                                        1516 FV61 S4D1 m503-1365  Δl = 861.461
                                                                        1516 FV61 S4D1 m1365-1370  Δl = 5.872
                                                                        1516 FV61 S4D1 m1370-1375  Δl = 4.611
                                                                        1516 FV61 S4D1 m1375-1404  Δl = 28.893


23 24                    Dimnakrysset -> Botnen                         1516 FV61 S4D1 m1404-2608  Δl = 1204.166
                                                                        1516 FV61 S4D1 m2608-2659  Δl = 50.684
                                                                        1516 FV61 S4D1 m2659-3155  Δl = 495.818
                                                                        1516 FV61 S4D1 m3155-3280  Δl = 125.172
                                                                        1516 FV61 S4D1 m3280-3363  Δl = 83.017


24 25                          Botnen -> Garneskrysset                  Error: 4040  IKKE_FUNNET_RUTE 
        Out of 26807 6941534:
                1516 FV61 S4D1 m3363
        In to 26449 6940130:
                1516 FV61 S4D1 m5398 SD1 m141
        (26807 6941534)-(26449 6940130)
                  Δl = 0.0


25 26                   Garneskrysset -> Dragsund sør                   1516 FV61 S4D1 m5398 SD1 m141-173  Δl = 31.853
                                                                        1516 FV61 S5D120 m0-6  Δl = 6.455
                                                                        1516 FV61 S5D120 m6-17  Δl = 10.436
                                                                        1516 FV61 S5D120 m17-118  Δl = 101.516
                                                                        1516 FV61 S5D120 m118-121  Δl = 2.907
                                                                        1516 FV61 S5D1 m168-239  Δl = 71
                                                                        1516 FV61 S5D1 m239-391  Δl = 152.229
                                                                        1516 FV61 S5D1 m391-467  Δl = 75.371
                                                                        1516 FV61 S5D1 m467-564  Δl = 97.499
                                                                        1516 FV61 S5D1 m564-681  Δl = 117.189
                                                                        1516 FV61 S5D1 m681-694  Δl = 13.124
                                                                        1516 FV61 S5D1 m694-848  Δl = 153.859
                                                                        1516 FV61 S5D1 m848-912  Δl = 63.473
                                                                        1516 FV61 S5D1 m912-1085  Δl = 173.375
                                                                        1516 FV61 S5D1 m1085-1273  Δl = 188.03
                                                                        1516 FV61 S5D1 m1273-1281  Δl = 8.272
                                                                        1516 FV61 S5D1 m1281-1401  Δl = 119.985
                                                                        1515 FV61 S5D1 m1401-1412  Δl = 10.372
                                                                        1515 FV61 S5D1 m1412-1527  Δl = 115.47
                                                                        1515 FV61 S5D1 m1527-1589  Δl = 61.977
                                                                        1515 FV61 S5D1 m1589-1879  Δl = 290.123
                                                                        1515 FV61 S5D1 m1879-1937  Δl = 57.812
                                                                        1515 FV61 S5D1 m1937-2001  Δl = 63.738
                                                                        1515 FV61 S5D1 m2001-2004  Δl = 3.564
                                                                        1515 FV61 S5D1 m2004-2019  Δl = 14.818


26 27                    Dragsund sør -> Myrvåglomma                    1515 FV61 S5D1 m2019-2389  Δl = 369.421
                                                                        1515 FV61 S5D1 m2389-2685  Δl = 295.919
                                                                        1515 FV61 S5D1 m2685-2759  Δl = 74.329
                                                                        1515 FV61 S5D1 m2759-2765  Δl = 5.773
                                                                        1515 FV654 S1D1 m0-6  Δl = 5.747
                                                                        1515 FV654 S1D1 m6-11  Δl = 5.648
                                                                        1515 FV654 S1D1 m11-75  Δl = 63.793
                                                                        1515 FV654 S1D1 m75-172  Δl = 97.019
                                                                        1515 KV3225 S1D1 m0-3  Δl = 3.37
                                                                        1515 KV3225 S1D1 m3-30  Δl = 26.662
                                                                        1515 KV3225 S2D1 m0-23  Δl = 23.384
                                                                        1515 PV98594 S1D1 m61-72  Δl = 11.551
                                                                        1515 KV3225 S1D60 m15-26  Δl = 10.804


27 28                     Myrvåglomma -> Myrvåg                         1515 KV3225 S1D60 m26-63  Δl = 37.414
                                                                        1515 KV3225 S1D60 m63-399  Δl = 335.763
                                                                        1515 KV3210 S1D1 m46-59  Δl = 12.825
                                                                        1515 KV3210 S2D1 m0-8  Δl = 8.421
                                                                        1515 KV3210 S2D1 m8-25  Δl = 16.403
                                                                        1515 KV3210 S2D1 m25-191  Δl = 166.003
                                                                        1515 KV3210 S2D1 m191-221  Δl = 29.684
                                                                        1515 FV654 S1D110 m0-56  Δl = 56.222
                                                                        1515 FV654 S1D110 m56-103  Δl = 46.357
                                                                        1515 FV654 S1D110 m103-109  Δl = 6.809
                                                                        1515 KV3465 S1D1 m0-13  Δl = 13.062
                                                                        1515 FV654 S1D1 m918-921  Δl = 2.557


28 29                          Myrvåg -> Aurvåg                         1515 FV654 S1D1 m921-944  Δl = 23.543
                                                                        1515 FV654 S1D1 m944-1163  Δl = 219.174
                                                                        1515 FV654 S1D1 m1163-1263  Δl = 100.079
                                                                        1515 FV654 S1D1 m1263-1276  Δl = 12.566
                                                                        1515 FV654 S1D1 m1276-1659  Δl = 383.061
                                                                        1515 FV654 S1D1 m1659-1674  Δl = 14.731
                                                                        1515 FV654 S1D1 m1674-1759  Δl = 85.292
                                                                        1515 FV654 S1D1 m1759-1765  Δl = 6.021
                                                                        1515 FV654 S1D1 m1765-1782  Δl = 17.02


29 30                          Aurvåg -> Aspevika                       1515 FV654 S1D1 m1782-1852  Δl = 70.39
                                                                        1515 FV654 S1D1 m1852-2120  Δl = 267.441
                                                                        1515 FV654 S1D1 m2120-2139  Δl = 18.622
                                                                        1515 FV654 S1D1 m2139-2291  Δl = 151.988
                                                                        1515 FV654 S1D1 m2291-2427  Δl = 136.405


30 31                        Aspevika -> Kalveneset                     1515 FV654 S1D1 m2427-2433  Δl = 6.332
                                                                        1515 FV654 S1D1 m2433-2449  Δl = 15.277
                                                                        1515 FV654 S1D1 m2449-2575  Δl = 126.156
                                                                        1515 FV654 S1D1 m2575-2789  Δl = 214
                                                                        1515 FV654 S1D1 m2789-2860  Δl = 71.485
                                                                        1515 FV654 S1D1 m2860-2869  Δl = 8.515
                                                                        1515 FV654 S1D1 m2869-2892  Δl = 23.191
                                                                        1515 FV654 S1D1 m2892-2911  Δl = 19.602
                                                                        1515 FV654 S1D1 m2911-2932  Δl = 20.207
                                                                        1515 FV654 S1D1 m2932-2961  Δl = 29.811
                                                                        1515 FV654 S1D1 m2961-3069  Δl = 107.189
                                                                        1515 FV654 S1D1 m3069-3069  Δl = 0.7


31 32                      Kalveneset -> Tjørvåg indre                  1515 FV654 S1D1 m3069-3307  Δl = 237.3
                                                                        1515 FV654 S1D1 m3307-3422  Δl = 114.925
                                                                        1515 FV654 S1D1 m3422-3724  Δl = 302.381
                                                                        1515 FV654 S2D1 m0-82  Δl = 82.297
                                                                        1515 FV654 S2D1 m82-220  Δl = 137.364


32 33                   Tjørvåg indre -> Tjørvåg                        1515 FV654 S2D1 m220-264  Δl = 44.457
                                                                        1515 FV654 S2D1 m264-304  Δl = 39.994
                                                                        1515 FV654 S2D1 m304-400  Δl = 95.446
                                                                        1515 FV654 S2D1 m400-511  Δl = 111.834
                                                                        1515 FV654 S2D1 m511-658  Δl = 147.03
                                                                        1515 FV654 S2D1 m658-688  Δl = 30.016
                                                                        1515 FV654 S2D1 m688-708  Δl = 19.122


33 34                         Tjørvåg -> Tjørvågane                     1515 FV654 S2D1 m708-744  Δl = 36.816
                                                                        1515 FV654 S2D1 m744-877  Δl = 132.271
                                                                        1515 FV654 S2D1 m877-942  Δl = 65.401
                                                                        1515 FV654 S2D1 m942-960  Δl = 18.329
                                                                        1515 FV654 S2D1 m960-1003  Δl = 42.207
                                                                        1515 FV654 S2D1 m1003-1094  Δl = 91.813
                                                                        1515 FV654 S2D1 m1094-1108  Δl = 13.364


34 35                      Tjørvågane -> Tjørvåg nord                   1515 FV654 S2D1 m1108-1189  Δl = 80.858
                                                                        1515 FV654 S2D1 m1189-1233  Δl = 43.901
                                                                        1515 FV654 S2D1 m1233-1475  Δl = 242.609
                                                                        1515 KV2870 S1D1 m0-14  Δl = 13.841
                                                                        1515 FV654 S2D110 m1506-1508  Δl = 2.268
                                                                        1515 FV654 S2D110 m1508-1511  Δl = 3.181
                                                                        1515 FV654 S2D110 m1511-1598  Δl = 86.258


35 36                    Tjørvåg nord -> Rafteset                       1515 FV654 S2D110 m1598-1609  Δl = 11.11
                                                                        1515 FV654 S2D110 m1609-1616  Δl = 7.45
                                                                        1515 FV654 S2D110 m1616-1664  Δl = 48.116
                                                                        1515 FV654 S2D110 m1664-1790  Δl = 126
                                                                        1515 PV3435 S1D1 m0-5  Δl = 5.417
                                                                        1515 FV654 S2D1 m1757-2079  Δl = 322.026
                                                                        1515 FV654 S2D1 m2079-2186  Δl = 107.299
                                                                        1515 FV654 S2D1 m2186-2208  Δl = 21.721
                                                                        1515 FV654 S2D1 m2208-2277  Δl = 68.634


36 37                        Rafteset -> Storneset                      1515 FV654 S2D1 m2277-2355  Δl = 78.572
                                                                        1515 FV654 S2D1 m2355-2648  Δl = 292.762
                                                                        1515 FV654 S2D1 m2648-2701  Δl = 52.368
                                                                        1515 FV654 S2D1 m2701-2783  Δl = 82.395
                                                                        1515 FV654 S2D1 m2783-2836  Δl = 52.782
                                                                        1515 FV654 S2D1 m2836-2896  Δl = 60.526
                                                                        1515 FV654 S2D1 m2896-2913  Δl = 17.196
                                                                        1515 FV654 S2D1 m2913-2915  Δl = 1.47


37 38                       Storneset -> Stokksund                      1515 FV654 S2D1 m2915-2964  Δl = 49.229
                                                                        1515 FV654 S2D1 m2964-2967  Δl = 3.066
                                                                        1515 FV654 S2D1 m2967-3028  Δl = 60.834
                                                                        1515 FV654 S2D1 m3028-3041  Δl = 12.8
                                                                        1515 FV654 S2D1 m3041-3118  Δl = 76.888
                                                                        1515 FV654 S2D1 m3118-3468  Δl = 350.364
                                                                        1515 FV654 S2D1 m3468-3544  Δl = 76.32
                                                                        1515 KV3130 S1D1 m457-480  Δl = 23.796
                                                                        1515 PV3130 S1D1 m37-76  Δl = 39.642


38 39                       Stokksund -> Notøy                          1515 PV3130 S1D1 m37-76  Δl = 39.642
                                                                        1515 KV3130 S1D1 m457-480  Δl = 23.796
                                                                        1515 FV654 S2D1 m3544-3903  Δl = 358.751
                                                                        1515 FV654 S2D1 m3903-4013  Δl = 110
                                                                        1515 FV654 S2D1 m4013-4097  Δl = 83.48
                                                                        1515 FV654 S2D1 m4097-4328  Δl = 231.004
                                                                        1515 FV654 S2D1 m4328-4346  Δl = 18.177
                                                                        1515 FV654 S2D1 m4346-4447  Δl = 100.742
                                                                        1515 FV654 S3D1 m0-246  Δl = 245.629
                                                                        1515 FV654 S3D1 m246-483  Δl = 237.569
                                                                        1515 FV654 S3D1 m483-1009  Δl = 525.683
                                                                        1515 FV654 S3D1 m1009-1038  Δl = 29.177
                                                                        1515 FV654 S3D1 m1065 SD1 m0-5  Δl = 5.259


39 40                           Notøy -> Røyra øst                      Error: 4040  IKKE_FUNNET_RUTE 
        Out of 19429 6943497:
                1515 FV654 S3D1 m1065 SD1 m7
        In to 19922 6944583:
                1515 FV654 S3D1 m3060
        (19429 6943497)-(19922 6944583)
                  Δl = 0.0


40 41                       Røyra øst -> Røyra vest                     1515 FV654 S3D1 m3060-3260  Δl = 200.058
                                                                        1515 FV654 S3D1 m3260-3339  Δl = 79.319
                                                                        1515 FV654 S3D1 m3339-3384  Δl = 44.37
                                                                        1515 FV654 S3D1 m3384-3391  Δl = 7.05


41 42                      Røyra vest -> Frøystadvåg                    Error: 4040  IKKE_FUNNET_RUTE 
        Out of 19605 6944608:
                1515 FV654 S3D1 m3391
        In to 19495 6945400:
                1515 PV99132 S1D1 m48
        (19605 6944608)-(19495 6945400)
                  Δl = 0.0


42 43                     Frøystadvåg -> Frøystadkrysset                1515 PV99132 S1D1 m0-48  Δl = 47.923
                                                                        1515 FV654 S3D1 m4549-4757  Δl = 208.292
                                                                        1515 KV3350 S1D1 m0-15  Δl = 15.43
                                                                        1515 KV3350 S2D1 m0-31  Δl = 31.305
                                                                        1515 KV2775 S1D10 m0-11  Δl = 11.361
                                                                        1515 KV2775 S1D10 m11-60  Δl = 48.251
                                                                        1515 KV2775 S1D10 m60-112  Δl = 52.146
                                                                        1515 KV2775 S1D10 m112-136  Δl = 24.343
                                                                        1515 FV654 S3D160 m63-65  Δl = 2.198
                                                                        1515 FV654 S3D160 m48-63  Δl = 14.712
                                                                        1515 FV654 S3D160 m38-48  Δl = 10.155
                                                                        1515 FV654 S3D160 m20-38  Δl = 18.061
                                                                        1515 FV654 S3D160 m9-20  Δl = 10.81
                                                                        1515 FV654 S3D160 m2-9  Δl = 7.035
                                                                        1515 FV654 S3D160 m0-2  Δl = 2.338
                                                                        1515 FV654 S3D170 m42-136  Δl = 93.659
                                                                        1515 FV654 S3D170 m136-138  Δl = 2.567
                                                                        1515 PV98735 S1D1 m0-10  Δl = 10.031
                                                                        1515 FV654 S3D1 m5290-5296  Δl = 5.899
                                                                        1515 FV654 S3D1 m5227-5290  Δl = 63.454
                                                                        1515 FV654 S3D1 m5221-5227  Δl = 5.871
                                                                        1515 FV654 S3D1 m5114-5221  Δl = 106.541


43 44                 Frøystadkrysset -> Nerøykrysset                   1515 FV654 S3D1 m5114-5221  Δl = 106.541
                                                                        1515 FV654 S3D1 m5221-5227  Δl = 5.871
                                                                        1515 FV654 S3D1 m5227-5290  Δl = 63.454
                                                                        1515 FV654 S3D1 m5290-5296  Δl = 5.899
                                                                        1515 FV654 S3D1 m5296-5312  Δl = 16.256
                                                                        1515 FV654 S3D1 m5312-5579  Δl = 266.742
                                                                        1515 PV98912 S1D1 m0-9  Δl = 9.202
                                                                        1515 FV654 S3D140 m627-986  Δl = 358.653
                                                                        1515 FV654 S3D140 m986-1296  Δl = 310.471
                                                                        1515 FV654 S3D140 m1296-1311  Δl = 14.656
                                                                        1515 FV654 S3D140 m1311-1319  Δl = 7.926
                                                                        1515 FV5876 S1D1 m82 SD1 m9-29  Δl = 20.073
                                                                        1515 FV5876 S1D1 m82 SD1 m29-36  Δl = 6.69


44 45                    Nerøykrysset -> Berge bedehus                  1515 FV5876 S1D1 m82 SD1 m29-36  Δl = 6.69
                                                                        1515 FV5876 S1D1 m82 SD1 m9-29  Δl = 20.073
                                                                        1515 FV5876 S1D1 m82 SD1 m4-9  Δl = 5.077
                                                                        1515 FV5876 S1D1 m82 SD1 m0-4  Δl = 3.926
                                                                        1515 FV5876 S1D1 m38-53  Δl = 15.393
                                                                        1515 FV5876 S1D1 m32-38  Δl = 5.955
                                                                        1515 FV5876 S1D1 m5-32  Δl = 29.169
                                                                        1515 FV5876 S1D1 m0-5  Δl = 5.526
                                                                        1515 FV654 S3D1 m6273-6370  Δl = 97.481
                                                                        1515 FV654 S3D1 m6370-6594  Δl = 223.323
                                                                        1515 FV654 S3D1 m6594-6662  Δl = 68.454
                                                                        1515 FV654 S3D1 m6662-6976  Δl = 313.434
                                                                        1515 FV654 S3D1 m6976-7049  Δl = 73.291
                                                                        1515 FV654 S3D1 m7049-7066  Δl = 17.456
                                                                        1515 FV654 S3D1 m7066-7070  Δl = 3.357
                                                                        1515 FV654 S3D1 m7070-7076  Δl = 6.289
                                                                        1515 FV654 S3D1 m7076-7080  Δl = 4.057


45 46                   Berge bedehus -> Elsebøvegen                    1515 FV654 S3D1 m7080-7083  Δl = 2.705
                                                                        1515 FV654 S3D1 m7083-7198  Δl = 115.521
                                                                        1515 FV654 S3D1 m7198-7211  Δl = 13.012
                                                                        1515 FV654 S3D1 m7211-7227  Δl = 15.563
                                                                        1515 FV654 S3D1 m7227-7314  Δl = 87.307
                                                                        1515 FV654 S3D1 m7314-7321  Δl = 7.165
                                                                        1515 KV3395 S1D1 m0-7  Δl = 7.424
                                                                        1515 FV654 S3D190 m1134-1139  Δl = 4.87
                                                                        1515 FV654 S3D190 m1139-1169  Δl = 30.092


46 47                     Elsebøvegen -> Verket                         1515 FV654 S3D190 m1169-1350  Δl = 180.934
                                                                        1515 FV654 S3D190 m1350-1480  Δl = 129.808
                                                                        1515 FV654 S3D190 m1480-1481  Δl = 1.809
                                                                        1515 FV654 S3D190 m1481-1486  Δl = 4.214
                                                                        1515 KV2690 S1D1 m0-9  Δl = 9.494
                                                                        1515 FV654 S3D1 m7666-7669  Δl = 3.018
                                                                        1515 FV654 S3D1 m7650-7666  Δl = 15.735


47 48                          Verket -> Berge                          1515 FV654 S3D1 m7650-7666  Δl = 15.735
                                                                        1515 FV654 S3D1 m7666-7669  Δl = 3.018
                                                                        1515 FV654 S3D1 m7669-7787  Δl = 118.571
                                                                        1515 FV654 S3D1 m7787-7874  Δl = 86.646
                                                                        1515 FV654 S3D1 m7874-7878  Δl = 3.76


48 49                           Berge -> Hjelmeset                      1515 FV654 S3D1 m7878-7941  Δl = 63.204
                                                                        1515 FV654 S3D1 m7941-7995  Δl = 53.953
                                                                        1515 FV654 S3D1 m7995-8034  Δl = 39.058
                                                                        1515 FV654 S3D1 m8034-8038  Δl = 8.022
                                                                        1515 FV654 S3D1 m8038 KD1 m0-19  Δl = 19
                                                                        1515 FV654 S3D1 m8038-8043  Δl = 7.073
                                                                        1515 FV654 S3D1 m8043-8055  Δl = 12.928
                                                                        1515 FV654 S3D1 m8055-8089  Δl = 32.65
                                                                        1515 FV654 S3D1 m8089-8153  Δl = 64.689
                                                                        1515 FV654 S3D1 m8153-8208  Δl = 54.784


49 50                       Hjelmeset -> Demingane                      1515 FV654 S3D1 m8208-8219  Δl = 10.743
                                                                        1515 FV654 S3D1 m8219-8255  Δl = 35.917
                                                                        1515 FV654 S3D1 m8255-8456  Δl = 201.347
                                                                        1515 FV654 S3D1 m8456-8559  Δl = 102.536
                                                                        1515 FV654 S3D1 m8559-8576  Δl = 16.198
                                                                        1515 FV654 S3D1 m8576-8590  Δl = 13.312
                                                                        1515 FV654 S3D1 m8590-8599  Δl = 9.13
                                                                        1515 FV654 S3D1 m8599-8617  Δl = 18.766


50 51                       Demingane -> Eggesbønes                     1515 FV654 S3D1 m8617-8694  Δl = 77.097
                                                                        1515 FV654 S3D1 m8694-9071  Δl = 376.112
                                                                        1515 FV654 S3D1 m9071-9074  Δl = 3.211
                                                                        1515 FV654 S3D1 m9111 SD1 m0-6  Δl = 6.023
                                                                        1515 FV654 S3D1 m9111 SD1 m6-65  Δl = 58.844


51 52                      Eggesbønes -> Myklebust                      1515 FV654 S3D1 m9111 SD1 m65-69  Δl = 3.829
                                                                        1515 FV654 S3D1 m9111 SD1 m69-76  Δl = 7.13
                                                                        1515 FV654 S3D1 m9149-9202  Δl = 53.861
                                                                        1515 FV654 S3D1 m9202-9214  Δl = 11.24
                                                                        1515 FV654 S3D1 m9214-9218  Δl = 4.388
                                                                        1515 FV654 S3D1 m9218-9305  Δl = 86.904
                                                                        1515 FV654 S3D1 m9305-9314  Δl = 8.868
                                                                        1515 FV654 S3D1 m9314-9320  Δl = 5.676
                                                                        1515 FV654 S3D1 m9320-9353  Δl = 33.166


52 53                       Myklebust -> Herøy kyrkje                   1515 FV654 S3D1 m9353-9361  Δl = 8.136
                                                                        1515 FV654 S3D1 m9361-9457  Δl = 96
                                                                        1515 FV654 S3D1 m9457-9489  Δl = 32.456
                                                                        1515 FV654 S3D1 m9489-9608  Δl = 118.84
                                                                        1515 FV654 S3D1 m9608-9674  Δl = 65.558
                                                                        1515 FV654 S3D1 m9674-9684  Δl = 10.492
                                                                        1515 FV654 S3D1 m9684-9698  Δl = 13.715
                                                                        1515 FV654 S3D1 m9698-9741  Δl = 42.865
                                                                        1515 FV654 S3D1 m9741-9892  Δl = 151.193
                                                                        1515 FV654 S3D1 m9892-9936  Δl = 43.795
                                                                        1515 FV654 S3D1 m9936-10054  Δl = 117.822
                                                                        1515 FV654 S3D1 m10054-10060  Δl = 6.272
                                                                        1515 FV654 S3D1 m10060-10066  Δl = 6.1
                                                                        1515 FV654 S3D1 m10066-10084  Δl = 18.435
                                                                        1515 FV654 S3D1 m10115 SD1 m0-6  Δl = 5.866
                                                                        1515 FV654 S3D1 m10115 SD1 m6-13  Δl = 7.399
                                                                        1515 FV654 S3D1 m10115 SD1 m13-44  Δl = 30.379


53 54                    Herøy kyrkje -> Fosnavåg sparebank             1515 FV654 S3D1 m10115 SD1 m44-61  Δl = 17.355
                                                                        1515 FV654 S3D1 m10115 SD1 m61-69  Δl = 7.586
                                                                        1515 FV654 S3D1 m10147-10185  Δl = 37.975
                                                                        1515 FV654 S3D1 m10185-10230  Δl = 44.862
                                                                        1515 FV654 S3D1 m10230-10283  Δl = 53.053
                                                                        1515 FV654 S3D1 m10283-10445  Δl = 161.573
                                                                        1515 FV654 S3D1 m10445-10499  Δl = 54.752
                                                                        1515 FV654 S3D1 m10499-10618  Δl = 119.07
                                                                        1515 FV654 S3D1 m10618-10702  Δl = 83.19
                                                                        1515 FV654 S3D1 m10702-10782  Δl = 80.502
                                                                        1515 FV654 S3D1 m10782-10836  Δl = 53.601


54 55              Fosnavåg sparebank -> Fosnavåg terminal                   GET https://nvdbapiles-v3.test.atlas.vegvesen.no/posisjon?nord=6.947514879242669e6&ost=16063.782613804331&maks_avstand=10
Error: 4042  IKKE_FUNNET_SLUTTPUNKT

        In to 16064 6947515:
        Error: Fant ingen veglenkesekvenser i nærheten av søkepunkt: POINT (16063.7826 6947514.8792)
Det er for lang avstand til nærmeste veg  Δl = 0.0

=#