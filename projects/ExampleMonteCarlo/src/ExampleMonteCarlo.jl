module ExampleMonteCarlo

# This project's own code: one equilibrated chain, and the reduction over finished points.
#
# `work_fn` lives here rather than in `scripts/` because `run!(…; load=…)` ships THIS module to the
# workers. Everything it reaches travels with it, which is why the compute environment is kept free
# of plotting.
#
# Note the qualified calls. `ClassicalMonteCarlo` exports `run!` and so does `SweepRunner`; the sweep
# calls one and a chain calls the other, so neither is imported unqualified anywhere in this project.

using ClassicalMonteCarlo: ClassicalMonteCarlo
using DataVault: DataVault
using Lattice2D: Lattice2D
using Random: MersenneTwister

export work_fn, summarise

"""
    work_fn(key) -> Dict{String,Any}

One `(lattice, L, kbT)` point of the Ising sweep: burn in with no observers, then accumulate a
`ThermodynamicObserver` over `nsteps` sweeps and return the thermodynamics.

Returns the payload; it never saves. The runtime writes what comes back, plus the `.done` marker.
"""
function work_fn(key)
    L = Int(key.params["system.L"])
    kbT = Float64(key.params["system.kbT"])
    nsteps = Int(key.params["numerics.nsteps"])
    burn = Int(key.params["numerics.burn"])

    # `build_lattice` takes the topology TYPE, not an instance:
    # `build_lattice(::Type{<:AbstractTopology{2}}, Int, Int)`.
    lat = Lattice2D.build_lattice(Lattice2D.Square, L, L)
    model = ClassicalMonteCarlo.IsingModel(; J=1.0, h=0.0)
    alg = ClassicalMonteCarlo.LocalUpdate(;
        rule=ClassicalMonteCarlo.Metropolis(),
        selection=ClassicalMonteCarlo.RandomSiteSelection(),
    )

    N = Lattice2D.num_sites(lat)
    rng = MersenneTwister(hash((L, kbT, key.sample)))
    grids = rand(rng, [-1, 1], N)

    # Burn-in carries no observer: measuring the approach to equilibrium would bias the average.
    ClassicalMonteCarlo.run!(
        rng,
        grids,
        lat,
        model,
        alg,
        ClassicalMonteCarlo.AbstractObserver[];
        kbT=kbT,
        nsteps=burn,
    )
    obs = ClassicalMonteCarlo.ThermodynamicObserver(; interval=10)
    ClassicalMonteCarlo.run!(
        rng,
        grids,
        lat,
        model,
        alg,
        ClassicalMonteCarlo.AbstractObserver[obs];
        kbT=kbT,
        nsteps=nsteps,
    )
    res = ClassicalMonteCarlo.get_thermodynamics(obs, kbT, N, model)

    return Dict{String,Any}(
        "L" => L,
        "kbT" => kbT,
        "N" => N,
        "energy" => res["Energy"],
        "magnetization" => res["Magnetization"],
        "specific_heat" => res["SpecificHeat"],
        "susceptibility" => res["Susceptibility"],
        "binder" => res["BinderParam"],
    )
end

"""
    summarise(pairs) -> Vector{NamedTuple}
    summarise(vault) -> Vector{NamedTuple}

Every finished point, sorted. The `pairs` method is the reduction; the `vault` method only reads the
vault and hands it over.

Two entry points because the two callers arrive holding different things. `scripts/collect.jl` has a
vault and nothing else. `report/report.jl` is handed `(DataKey, Dict)` pairs by `Pinax.report`, which
already walked the vault — a `vault` method there would read the same files twice. One reduction
either way, so the table printed on the cluster and the figure drawn afterwards cannot disagree.
"""
function summarise(pairs::AbstractVector)
    rows = NamedTuple[]
    for (_, d) in pairs
        push!(
            rows,
            (;
                L=d["L"],
                kbT=d["kbT"],
                energy=d["energy"],
                magnetization=d["magnetization"],
                binder=d["binder"],
            ),
        )
    end
    return sort(rows; by=r -> (r.L, r.kbT))
end

function summarise(vault::DataVault.Vault)
    return summarise([
        (k, DataVault.load(vault, k)) for k in DataVault.keys(vault; status=:done)
    ])
end

end # module ExampleMonteCarlo
