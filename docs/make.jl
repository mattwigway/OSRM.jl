using Documenter
using OSRM

makedocs(
    sitename = "OSRM",
    format = Documenter.HTML(),
    modules = [OSRM]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "https://github.com/mattwigway/OSRM.jl"
)
