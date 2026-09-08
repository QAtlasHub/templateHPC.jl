using ExampleMonteCarlo
using Test

@testset "ExampleMonteCarlo" begin
    @test isfile(joinpath(@__DIR__, "..", "configs", "smoke.toml"))

    # One point, small enough to run in a test. The assertion is physics, not a threshold: deep in
    # the ordered phase the Ising magnetisation is near saturation, and well above the transition it
    # is near zero. A chain that silently stopped equilibrating fails both ways.
    mk(L, kbT) = (;
        params=Dict(
            "system.L" => L,
            "system.kbT" => kbT,
            "numerics.nsteps" => 400,
            "numerics.burn" => 200,
        ),
        sample=1,
    )

    cold = ExampleMonteCarlo.work_fn(mk(8, 1.2))
    hot = ExampleMonteCarlo.work_fn(mk(8, 4.0))

    @test cold isa Dict{String,Any}
    @test cold["magnetization"] > 0.8          # ordered
    @test hot["magnetization"] < 0.3           # disordered
    @test cold["energy"] < hot["energy"]       # and the ordered phase is the lower-energy one
end
