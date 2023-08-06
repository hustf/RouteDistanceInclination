# RouteSlopeDistance.jl

The package provides details along a route determined by start and end points.

Data is pulled from Norsk Vegdatabase. Results include speed limits and inclination along the route.

The data may be used for calculating travel times and energy consumption with different vehicle models. 
A good model would include available power, vehicle mass and gear shift times. An advanced model would include
traffic data, which can also be pulled using this package.

The API base url, version, etc. is configureable in the .ini file, and could possibly be compatible with other national systems.

If an endpoint is not wrapped in ` exported.jl`, use `nvdb_request` directly. See inline docs and the API docs:

https://nvdbapiles-v3.atlas.vegvesen.no/dokumentasjon/