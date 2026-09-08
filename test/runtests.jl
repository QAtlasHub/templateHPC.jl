using MyModule
using Test

@testset "MyModule" begin
    @test isdefined(MyModule, :solve)
end
