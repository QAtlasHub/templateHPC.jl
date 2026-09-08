using MyModule
using Test

@testset "MyModule" begin
    # The placeholder kernel is first-order in dt, so halving dt halves the error.
    # Asserting the RATE rather than a threshold is what makes this a real test:
    # a guessed tolerance passes for the wrong reason as soon as the method changes.
    e1 = MyModule.decay_error(1.0, 1e-2)
    e2 = MyModule.decay_error(1.0, 5e-3)
    @test 1.8 < e1 / e2 < 2.2

    # …and the sweep's entry point returns what the runtime will store.
    key = (; params=Dict("system.a" => 1.0, "numerics.dt" => 1e-2), sample=1)
    d = MyModule.work_fn(key)
    @test d isa Dict{String,Any}
    @test haskey(d, "rel_error")
end
