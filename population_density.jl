using Shapefile, DataFrames, Statistics, Plots, RollingFunctions
plotlyjs()

table = Shapefile.Table("./data/JRC_POPULATION_2018.shp")

df = DataFrame(table)

function country2cumsums(country)
    populations = df[df.CNTR_ID .== country, :].TOT_P_2018 |> sort!

    cum_population = cumsum(populations)

    (populations, cum_population)
end

function densityatquantile(q,poptuple)
    populations, cum_population = poptuple
    quantileth_man(q) = last(cum_population)*q

    quantileth_density(q) = populations[findfirst(x->x>quantileth_man(q), cum_population)]
    quantileth_density(q)
end

datadict = Dict(k=>country2cumsums(k) for k in [
"FR",
"UK",
#"DE",
"ES",
#"NL",
#"PL",
#"BE",
"IT",
#"NO",
])

qs = 0:0.001:0.999999

# # percentile plots
# p = plot()
# [plot!(p, qs.*100, [densityatquantile(q,v) for q in qs], label=k, xlabel="population percentile", ylabel="population/km^2") for (k,v) in datadict]
# p

# colin wants lorenz curves so we should add in empty dummy bins until we get to the right area for each country

quantiledict = Dict(k=>[densityatquantile(q,v) for q in qs] for (k,v) in datadict)

function popwithindensity(bins,range,pops)
    # todo: calculate the maximum safe density or just skip missings
    densities = minimum(pops):(maximum(pops)*(1-range*2)-minimum(pops))/bins:maximum(pops)*(1-range*2)
    (densities,[sum(qs[findfirst(x->x>d,pops):findfirst(x->x>d*(1+range),pops)]) for d in densities])
end


bins = 1000
width = 0.05
smoothing = 50
p = plot();
for (k,v) in quantiledict
    (density, pop) = popwithindensity(bins,width,v)
    plot!(p, rollmean(density,smoothing), rollmean(pop,smoothing); label=k,xlabel="population/km^2", ylabel="pop% within $(width*100)pp density", xscale=:log10);
end
Plots.savefig(p, "test.png")
p
