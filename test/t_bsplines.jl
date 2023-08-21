using Test
using RouteSlopeDistance
using RouteSlopeDistance: curvature_from_linestring, distance_between

using BSplines
using Plots
using Test
import Smoothers
using Smoothers: sma, hma

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
p1 = plot(px, py, 0, maximum(s))
plot!(p1, x, y, marker = true)
vx = px.(s)
vy = py.(s)
plot!(p1, vx, vy, linewidth = 0, marker = :square)
annotate!(p1, vx[2], vy[2], "Arc length parametrized", :right)

px´ = Function(Spline(b, xe), Derivative(1))
py´ = Function(Spline(b, ye), Derivative(1))
p´(s) = (px´(s), py´(s))

p2 = plot(px´, py´, 0, maximum(s))
plot!(p2, px´, py´, s[3], s[end - 2], linewidth = 5)

annotate!(p2, px´(s[10]), py´(s[10]), "Dervivative should have followed arc...", :left)
annotate!(p2, px´(s[3]), py´(s[3]), "...and it does so, but roughly, \nwhen excluding two \npoints each side!", :left)

# We are interested in the tangent normal unit vector.
# The length parametrization is far from perfect.
e_tx(s) = px´(s) / hypot(px´(s), py´(s))
e_ty(s) = py´(s) / hypot(px´(s), py´(s))
plot!(p2, e_tx, e_ty, s[2], s[end - 1], linewidth = 2)

function ϕ(s) 
   angle = atan(py´(s), px´(s))
   angle < 0 ? angle + 2π : angle
end
p3 = plot(t->ϕ(t) * 180/ π, s[2], s[end - 1], title = "Tangent direction [°]", xaxis = "s [m]", legend = false)
plot!(p3, t->ϕ(t) * 180/ π, s[3], s[end - 2], linewidth = 5)


perp_dot_product(a1, a2, b1, b2) = a1 * b2 - a2 * b1
perp_dot_product(p´, p´´) = perp_dot_product(p´[1], p´[2], p´´[1], p´´[2])

px´´ = Function(Spline(b, xe), Derivative(2))
py´´ = Function(Spline(b, ye), Derivative(2))
p´´(s) = (px´´(s), py´´(s))
ϕ´(s) = perp_dot_product(p´(s) , p´´(s))
# κ(s) = ϕ´(s)

p4 = plot(ϕ´, s[1], s[end], title = "Curvature κ [/m]", xaxis = "s [m]", legend = false)
ss = s[3:(end - 2)]
plot!(p4, ϕ´, ss, linewidth = 7)


#
# We think we have a mathematically sound curvature κ, but the multilines
# may be imperfect or intended for a different type of spline. 
# We need to smooth what we have
#

# Function sma simple moving average
κs = map(ϕ´, ss)
p5 = plot(ss, κs, linewidth = 1, label = "κ", size= (1200, 1100), layout = (2, 1))
plot!(p5[1], title = "Curvature, [/m]\n(moving average)", xaxis = "s [m]")
plot!(p5[2], title = "Radius of curvature, [m]\n(moving average)", xaxis = "s [m]")
for n in 8:10
    κsm = sma(κs, n, true)
    ssm = [s for (s, κ) in zip(ss, κsm) if ! ismissing(κ)]
    κsmo = [κ for κ in κsm if ! ismissing(κ)]
    plot!(p5[1], ssm, κsmo, linewidth = n, label = "κ smooth $n", linestyles = isodd(n) ? :dash : :solid)
    minR = Int(round(minimum(-1 ./ κsmo)))
    plot!(p5[2], ssm, -1 ./ κsmo, linewidth = n, label = "$n minR $minR", linestyles = isodd(n) ? :dash : :solid)
end
p5


# Function hma Henderson moving average
κs = map(ϕ´, ss)
p6 = plot(ss, κs, linewidth = 1, label = "κ", size= (1200, 1100), layout = (2, 1))
plot!(p6[1], title = "Curvature, [/m]\n(moving average)", xaxis = "s [m]")
plot!(p6[2], title = "Radius of curvature, [m]\n(moving average)", xaxis = "s [m]")
for n in 5:2:21
    κsm = hma(κs, n)
    ssm = [s for (s, κ) in zip(ss, κsm) if ! ismissing(κ)]
    κsmo = [κ for κ in κsm if ! ismissing(κ)]
    plot!(p6[1], ssm, κsmo, linewidth = n, label = "κ smooth $n", linestyles = isodd(n) ? :dash : :solid)
    minR = Int(round(minimum(-1 ./ κsmo)))
    plot!(p6[2], ssm, -1 ./ κsmo, linewidth = n / 3, label = "$n minR $minR", linestyle = isodd(div(n, 2)) ? :dash : :solid)
end
p6

# Henderson moving average with n = 17 seems to give ok results for this curve. We'll use it.

