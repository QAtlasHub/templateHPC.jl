using Test
@testset "ExampleSweep" begin
    @test isfile(joinpath(@__DIR__, "..", "configs", "smoke.toml"))
end
