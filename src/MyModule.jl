"""
MyModule — the study's own code, and the function the sweep calls.

Intentionally DEPENDENCY-FREE, like the kernel in SweepRunner's own examples.
`run!(…; load=MyModule)` ships this package to the workers, and everything it
`using`s travels with it — so keeping it lean is what makes the fan-out cheap
and what removes the whole "module not defined on a worker" class of bug.

The placeholder below is a damped exponential, integrated by explicit Euler. It
is here because it has an EXACT answer (`x(t) = exp(-a t)`), so `test/` can check
the result rather than only that something ran. Replace it with the real physics;
keep the shape of `work_fn`.
"""
module MyModule

export decay_error, work_fn

"""
    decay_error(a, dt; t_end=1.0) -> Float64

Relative error of explicit Euler on `x' = -a x`, `x(0) = 1`, at `t_end`, against
the exact `exp(-a t_end)`. First order in `dt`, which is the property the test
asserts: halving `dt` halves the error.
"""
function decay_error(a::Float64, dt::Float64; t_end::Float64=1.0)::Float64
    x = 1.0
    n = round(Int, t_end / dt)
    for _ in 1:n
        x += -a * x * dt
    end
    exact = exp(-a * t_end)
    return abs(x - exact) / exact
end

"""
    work_fn(key) -> Dict{String,Any}

One parameter point. Reads the swept values off the `DataKey` by their DOTTED
names (`"group.leaf"`, matching the `[paramsets.group]` block in the config) and
RETURNS the payload.

It does not save anything: the runtime calls `DataVault.save!` with whatever this
returns and writes the `.done` marker. Returning a non-`Dict` is a runtime error.
"""
function work_fn(key)
    a = Float64(key.params["system.a"])
    dt = Float64(key.params["numerics.dt"])
    return Dict{String,Any}("a" => a, "dt" => dt, "rel_error" => decay_error(a, dt))
end

end # module MyModule
