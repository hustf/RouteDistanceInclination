using RouteSlopeDistance
using RouteSlopeDistance: post_beta_vegnett_rute
using JSON3: pretty
#northing1 = 6.947308159359314e6 # Grimstad aust bus stop in UTM33
#easting1 = 34865.66712469625    # Grimstad aust bus stop in UTM33
#northing2 = 6.94710510180928e6  # Grimstad vest bus stop in UTM33
#easting2 = 34417.88533130888    # Grimstad vest bus stop in UTM33
name1 = "Notøy"
easting1 = 19428.907322990475
northing1 = 6.943496947023508e6
name2 = "Røyra øst"
easting2 = 19921.774665450328
northing2 = 6.944582534682405e6

Δl, inclination, inc_lengde = route_data(easting1, northing1, easting2, northing2)
@test length(Δl) == length(inclination)