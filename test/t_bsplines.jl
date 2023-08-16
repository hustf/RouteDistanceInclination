using Test
using RouteSlopeDistance
using RouteSlopeDistance: curvature_from_linestring, distance_between

using BSplines
using Plots
using Test

# Vegsystemreferanse "1516 KV1123 S1D1 m1279-1454"
ml = [(28683.912, 6.945112857e6, 83.498), (28678.9, 6.9451121e6, 83.214), (28673.4, 6.9451116e6, 82.814), (28667.1, 6.945111e6, 82.414), (28660.811, 6.9451106e6, 81.914), (28654.811, 6.9451103e6, 81.514), (28648.4, 6.9451102e6, 81.114), (28642.311, 6.9451102e6, 80.714), (28636.6, 6.9451103e6, 80.214), (28630.699, 6.9451103e6, 79.914), (28624.99, 6.9451105e6, 79.414), (28616.1, 6.9451108e6, 78.914), (28609.6, 6.9451112e6, 78.414), (28603.6, 6.9451118e6, 78.014), (28597.311, 6.9451124e6, 77.714), (28591.311, 6.9451131e6, 77.414), (28584.99, 6.945114e6, 77.014), (28578.811, 6.9451149e6, 76.714), (28572.811, 6.945116e6, 76.314), (28565.311, 
6.9451175e6, 75.914), (28559.99, 6.9451187e6, 75.614), (28554.199, 6.94512e6, 75.314), (28549.199, 6.9451214e6, 75.114), (28543.699, 6.9451228e6, 74.814), (28538.311, 6.9451243e6, 74.614), (28532.311, 6.9451261e6, 74.314), (28526.811, 6.9451278e6, 74.014), (28520.9, 6.9451298e6, 73.814), (28512.35, 6.945133e6, 73.464)]
ml2 = map(ml) do (x,y,_)
    x, y
end
pts_start = ml[1:(end - 1)]
pts_end = ml[2:end]
Δls = distance_between.(pts_start, pts_end)
ls = vcat([0.0], cumsum(Δls))
b = BSplineBasis(4, ls)

x = map(ml) do (x,y,_)
    x
end
y = map(ml) do (x,y,_)
    y
end
s = ls
b  = BSplineBasis(4, s)
# Try not bothering with tangents, double up endpoints instead!
xe = vcat(x[1], x, x[end])
ye = vcat(y[1], y, y[end])
px = Function(Spline(b, xe), true)
py = Function(Spline(b, ye), true)
plot(px, py, 0, maximum(s))
plot!(x, y, marker = true)
vx = px.(s)
vy = py.(s)
plot!(vx, vy, linewidth = 0, marker = :square)
annotate!(vx[2], vy[2], "Arc length parametrized", :right)

px´ = Function(Spline(b, xe), Derivative(1))
py´ = Function(Spline(b, ye), Derivative(1))
p´(s) = (px´(s), py´(s))
plot(px´, py´, 0, maximum(s))
plot!(px´, py´, s[3], s[end - 2], linewidth = 5)

annotate!(px´(s[10]), py´(s[10]), "Dervivative should have followed arc...", :left)
annotate!(px´(s[3]), py´(s[3]), "...and it does so, but roughly, \nwhen excluding two \npoints each side!", :left)

# We are interested in the tangent normal unit vector.
# The length parametrization is far from perfect.
e_tx(s) = px´(s) / hypot(px´(s), py´(s))
e_ty(s) = py´(s) / hypot(px´(s), py´(s))
plot!(e_tx, e_ty, s[2], s[end - 1], linewidth = 2)

function ϕ(s) 
   angle = atan(py´(s), px´(s))
   angle < 0 ? angle + 2π : angle
end
plot(t->ϕ(t) * 180/ π, s[2], s[end - 1], title = "Tangent direction [°]", xaxis = "s [m]", legend = false)
plot(t->ϕ(t) * 180/ π, s[3], s[end - 2], linewidth = 5)


perp_dot_product(a1, a2, b1, b2) = a1 * b2 - a2 * b1
perp_dot_product(p´, p´´) = per_dot_product(p´[1], p´[2], p´´[1], p´´[2])

px´´ = Function(Spline(b, xe), Derivative(2))
py´´ = Function(Spline(b, ye), Derivative(2))
p´´(s) = (px´´(s), py´´(s))
ϕ´(s) = perp_dot_product(p´(s) , p´´(s))
κ(s) = ϕ´(s)

plot(ϕ´, s[1], s[end], title = "Curvature, [/m²]", xaxis = "s [m]", legend = false)
plot!(ϕ´, s[2], s[end - 1], linewidth = 5)
plot!(ϕ´, s[3], s[end - 2], linewidth = 7)


R(s) = 1 / κ(s)
plot(R, s[3], s[end - 2], linewidth = 5, title = "Radius of curvature [m]", xaxis = "s [m]", legend = false)

# This is too coarse. We should try to get better curve precision.

