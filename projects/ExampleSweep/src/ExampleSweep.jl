module ExampleSweep

# This study's own reduction. It lives here, and not in `scripts/` or `report/`,
# because both call it — a summary printed on the cluster and a figure drawn
# afterwards then cannot report different numbers.

using DataVault: DataVault

export summarise

"""
    summarise(vault) -> Vector{NamedTuple}

Read every finished point back and reduce it. Replace the body; keep the shape,
so `scripts/collect.jl` and `report/report.jl` stay in agreement.
"""
function summarise(vault)
    rows = NamedTuple[]
    for key in DataVault.keys(vault; status=:done)
        d = DataVault.load(vault, key)
        push!(rows, (; a=d["a"], dt=d["dt"], rel_error=d["rel_error"]))
    end
    return sort(rows; by=r -> (r.a, r.dt))
end

end # module ExampleSweep
