# RouteSlopeDistance.jl

The package exports `route_data(A, B)`, where `A` and `B` are UTM33 coordinates. 

It harvests speed limits, geometry and related data from Norsk Vegdatabase. To reduce the number API calls, the package serializes results in a binary file, until you `delete_memoization_file()`. 

Horizontal curvature is found using Bsplines, and applied as further speed reduction. 

The result dictionary may be used for calculating travel times and energy consumption with different vehicle models. 
A good model would include available power, vehicle mass and gear shift times. An advanced model would include
traffic data, which can also be pulled using this package.

Database error corrections can be edited in the .ini file. The API base url, version, etc. is configureable in the .ini file. 
 
You may also call `nvdb_request` directly. API docs: https://nvdbapiles-v3.atlas.vegvesen.no/dokumentasjon/