module ExampleSweep

# This study's own reduction. It lives here, and not in `scripts/` or `report/`,
# because both call it — a summary printed on the cluster and a figure drawn
# afterwards then cannot report different numbers.

using DataVault: DataVault

export summarise

"""
    summarise(pairs) -> Vector{NamedTuple}
    summarise(vault) -> Vector{NamedTuple}

Reduce every finished point. The `pairs` method is the reduction; the `vault` method
only reads the vault and hands it over.

Two entry points because the two callers arrive holding different things.
`scripts/collect.jl` has a vault and nothing else. `report/report.jl` has already been
handed `(DataKey, Dict)` pairs by `Pinax.report`, which walked the vault itself — so a
`vault` method would make it read the same files a second time. Splitting here keeps
ONE reduction: the table printed on the cluster and the figure drawn afterwards cannot
report different numbers.

Replace the body; keep the shape.
"""
function summarise(pairs::AbstractVector)
    rows = NamedTuple[]
    for (_, d) in pairs
        push!(rows, (; a=d["a"], dt=d["dt"], rel_error=d["rel_error"]))
    end
    return sort(rows; by=r -> (r.a, r.dt))
end

function summarise(vault::DataVault.Vault)
    return summarise([
        (k, DataVault.load(vault, k)) for k in DataVault.keys(vault; status=:done)
    ])
end

end # module ExampleSweep
