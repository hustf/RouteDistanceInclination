# RouteSlopeDistance.jl

The package exports `route_data(A, B)`, where `A` and `B` are UTM33 coordinates. 

It harvests speed limits, geometry and related data from Norsk Vegdatabase. To reduce the number API calls, the package serializes results in a binary file, until you `delete_memoization_file()`. 

Horizontal curvature is found using Bsplines, and expressed as signed radius of curvature (negative values is right turn). Use this to estimate acceptable velocity from acceptable centripetal acceleration.

Slope is also found using Bsplines and filtering designed to overcome stairstepping from low resolution data, and continuity at joints.

The result dictionary may be used for calculating travel times and energy consumption with different vehicle models. 
A good model would include available power, vehicle mass and gear shift times. An advanced model would include
traffic data, which can also be pulled using this package.

Database error corrections can be edited in the .ini file. The API base url, version, etc. is configureable in the .ini file. 
 
You may also call `nvdb_request` directly for e.g. traffic counts. API docs: https://nvdbapiles-v3.atlas.vegvesen.no/dokumentasjon/