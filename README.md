# RouteSlopeDistance.jl

## What does it do?
This package fetches and processes data for calculating minimum travel times and energy usage for (heavy) vehicles on Norwegian roads. It could be adapted for similar countries by editing an .ini file, but this is not tested.

The package exports `route_leg_data(A, B)`, where `A` and `B` are UTM33 coordinates. Such requests return a dictionary with rich details including 
- centreline 3d coordinates
- curvature and slope based on centreline
- speed limit
- progression
- database references

There's also a plot definition, `plot_elevation_and_slope_vs_progression`, uses `Plots.jl`.

For unsupported data endpoints, e.g. traffic counts, road class or surface, adapt based on `endpoints.jl`.

## Data source
Raw data is fetched from [Norsk Vegdatabase](https://nvdb.atlas.vegvesen.no/). Data can be used under [public license](https://data.norge.no/nlod/no/1.0).

Expert web interface: [vegkart.no/](https://vegkart.atlas.vegvesen.no/)
Expert route patching (put patches in .ini file): [nvdb-vegdata.github.io/nvdb-visrute/STM/](https://nvdb-vegdata.github.io/nvdb-visrute/STM/)

To reduce the number of web API calls, the package serializes results in a binary file, until you `delete_memoization_file()`. 

## Processed data
Horizontal road curvature is found with the aid of Bsplines, and expressed as signed radius of curvature (negative values is right turn). Use this to estimate acceptable velocity from acceptable centripetal acceleration (`a = v² / r`).

Slope is also found with the aid of Bsplines and filtering designed to overcome stairstepping from low resolution data, and continuity at joints.

The effect of speed bumps is included as a 15 km/h local reduction in speed limit. The reduction is considered generally relevant to heavy vehicles, as the speed bump profile is often not available.

## Additional terminology

NVDB terms have clear definitions. Additionaly, this may be used in a public transportation context with a hierarchy:

`journey` or `route` > `leg` > `segment` > `point`

## How to use

```
pkg> registry add https://github.com/hustf/M8

pkg> add RouteSlopeDistance

julia> using RouteSlopeDistance

julia> begin # Integer UTM coordinates - one unit is 1m.
       ea1 = 24823
       no1 = 6939041
       ea2 = 23911
       no2 = 6938921
       d = route_leg_data(ea1, no1, ea2, no2)
       end
Dict{Symbol, Any} with 9 entries:
  :radius_of_curvature         => [NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN…
  :multi_linestring            => [[(24822.8, 6.93904e6, 16.831), (24808.…
  :fartsgrense_tuples          => [(1.0, 80, 80), (1.0, 80, 80), (1.0, 80…
  :prefixed_vegsystemreferanse => ["1515 FV61 S5D1 m2020-2389", "1515 FV6…
  :key                         => "(24823 6939041)-(23911 6938921)"       
  :progression                 => [0.0, 15.8022, 31.7241, 48.6967, 65.138…
  :speed_limitation            => [80.0, 80.0, 80.0, 80.0, 80.0, 80.0, 80…
  :slope                       => [-0.00433073, -0.00467919, -0.00616139,…
  :progression_at_ends         => [0.0, 369.107, 665.026, 739.355, 745.12…

julia> plot_elevation_and_slope_vs_progression(d, "A", "B")
```

## Suggested use
Routes between `A` and `B` can also be corrected by inserting additional points in the .ini file. When a route can't be found, further hints are printed.

Leg data may be used for calculating travel times and energy consumption with different vehicle models.

A good model would include available power curves, vehicle mass, gear shift times and air resistance. An advanced vehicle model would 
also include power train inertia, gear ratios, torque curves, and air temperature. 

For more conservative travel times, traffic count and light signal data can be fetched. 