# Also see exported.jl 

function plot_elevation_and_slope_vs_progression!(p::T, s, z, slope, progression_at_ends, refs, na1, na2) where T <: Union{Plots.Plot, Plots.Subplot}
    pz = plot!(p, s, z, label="Elevation", legend=:topleft, 
        ylabel = "Elevation [m]", xlabel = "Progression [m]")
    ps = twinx(pz)
    plot!(ps, s, slope, color=:red, xticks=:none, label="Slope", legend=:topright, 
        linestyle=:dash, ylabel = "Slope [m / m]")
    hline!(ps, [0], label = "", linestyle = :dash, color = :red)
    t1 = text(na1, 8, :left, :bottom, :green, rotation = -90)
    y = (maximum(z) + minimum(z)) / 2
    annotate!(pz, [(0, y, t1)])
    t2 = text(na2, 8, :left, :top, :green, rotation = -90)
    annotate!(pz, [(s[end], y, t2)])
end
function plot_elevation_and_slope_vs_progression!(p::T, d::Dict, na1, na2)  where T <: Union{Plots.Plot, Plots.Subplot}
    s = d[:progression]
    slope = d[:slope]
    progression_at_ends = d[:progression_at_ends]
    mls = d[  :multi_linestring]
    _, _, z = unique_unnested_coordinates_of_multiline_string(mls)
    refs = d[:prefixed_vegsystemreferanse]
    plot_elevation_and_slope_vs_progression!(p, s, z, slope, progression_at_ends, refs, na1, na2)
end

