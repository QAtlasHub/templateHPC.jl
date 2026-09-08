module ExampleSweep

# Project-local code: how THIS study reduces its own results.
#
# It lives here, and not in `scripts/` or in `report/`, because both of those
# call it. A summary printed on the cluster and a figure drawn afterwards then
# cannot report different numbers — there is only one function to be wrong.

using DataVault

export summarise

"""
    summarise(vault) -> NamedTuple

Reduce a finished vault to whatever this study reports. Replace the body; keep
the shape, so `scripts/collect.jl` and `report/report.jl` stay in agreement.
"""
function summarise(vault)
    ks = DataVault.keys(vault)
    return (; n_points=length(ks))
end

end # module ExampleSweep
