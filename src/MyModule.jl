module MyModule

# Shared code. A project's `scripts/compute.jl` calls into here, so the same
# function is what runs on one core and on a thousand.

export solve

"""
    solve(; kwargs...)

Replace this with the study's actual computation. It takes the parameters of ONE
point and returns what should be stored for that point.
"""
solve(; kwargs...) = error("MyModule.solve is not implemented yet")

end # module MyModule
