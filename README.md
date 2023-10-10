# RouteSlopeDistance.jl

This package provides data for calculating minimum travel times and energy usage for (heavy) vehicles on Norwegian roads. It could be adapted for similar countries by editing an .ini file, but this is not tested.

The package exports `route_data(A, B)`, where `A` and `B` are UTM33 coordinates. Such requests return a dictionary with rich details including centreline coordinates, curvature and slope from `A` to `B`. The effect of speed bumps is included as a 15 km/h local reduction in speed limit (relevant to heavy vehicles).

It also exports a plot definition, `plot_elevation_and_slope_vs_progression`, using `Plots.jl`.

Basic data is fetched from Norsk Vegdatabase. To reduce the number of web API calls, the package serializes results in a binary file, until you `delete_memoization_file()`. 

Horizontal curvature is found using Bsplines, and expressed as signed radius of curvature (negative values is right turn). Use this to estimate acceptable velocity from acceptable centripetal acceleration.

Slope is also found using Bsplines and filtering designed to overcome stairstepping from low resolution data, and continuity at joints.

The result dictionary may be used for calculating travel times and energy consumption with different vehicle models. 
A good model would include available power curves, vehicle mass, gear shift times and air resistance. An advanced vehicle model would 
also include power train inertia, gear ratios, torque curves, and air temperature. 

For more conservative travel times, traffic count data can be pulled with this package. Call `nvdb_request` directly. API docs: https://nvdbapiles-v3.atlas.vegvesen.no/dokumentasjon/

Database error corrections can be edited in the .ini file. Routes between `A` and `B` can also be corrected by inserting additional points in the .ini file.
