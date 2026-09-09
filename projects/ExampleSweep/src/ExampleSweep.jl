module ExampleSweep

# This study's own reduction. It lives here, and not in `scripts/` or `report/`,
# because both call it — a summary printed on the cluster and a figure drawn
# afterwards then cannot report different numbers.

using DataVault: DataVault

export summarise

"""
    summarise(pairs) -> Vector{NamedTuple}
    summarise(vault) -> Vector{NamedTuple}

Reduce every finished point. `pairs` is the reduction; the `vault` method only reads
them off disk first — `Pinax.report` already holds the pairs, `scripts/collect.jl` does
not. One reduction either way, so the two cannot report different numbers.

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
