# TODO: maybe add some caching based on input
function _solve_pullback(solver, res, problem, x0, params)
    (; lag_hess_rows, lag_hess_cols, parametric_lag_hess_vals) = problem.lag_hess_primals
    (; cost_jac_rows, cost_jac_cols, parametric_cost_jac_vals) = problem.parametric_cost_jac
    (; jac_rows, jac_cols, parametric_jac_vals) = problem.jac_primals
    (; jac_p_rows, jac_p_cols, parametric_jac_p_vals) = problem.jac_params

    (; n, num_equality) = problem
    m = problem.num_equality + problem.num_inequality
    l = size(params, 1)

    (; primals, equality_duals, inequality_duals) = res
    duals = [equality_duals; inequality_duals]

    Qvals = zeros(size(lag_hess_rows, 1))
    parametric_lag_hess_vals(Qvals, x0, params, primals, duals, 1.0, 1.0)
    Q = sparse(lag_hess_rows, lag_hess_cols, Qvals, n, n)

    Rvals = zeros(size(cost_jac_rows, 1))
    parametric_cost_jac_vals(Rvals, params, primals)
    R = sparse(cost_jac_rows, cost_jac_cols, Rvals, n, l)

    Avals = zeros(size(jac_rows, 1))
    parametric_jac_vals(Avals, x0, params, primals)
    A = sparse(jac_rows, jac_cols, Avals, m, n)

    Bvals = zeros(size(jac_p_rows, 1))
    parametric_jac_p_vals(Bvals, x0, params, primals)
    B = sparse(jac_p_rows, jac_p_cols, Bvals, m, l)

    lower_active = duals .> 1e-3
    lower_active[1:num_equality] .= 0
    equality = zero(lower_active)
    equality[1:num_equality] .= 1
    active = lower_active .| equality
    num_lower_active = sum(lower_active)
    num_active = num_equality + num_lower_active

    A_l_active = A[lower_active, :]
    A_equality = A[equality, :]
    B_l_active = B[lower_active, :]
    B_equality = B[equality, :]
    A_active = [A_equality; A_l_active]
    B_active = [B_equality; B_l_active]

    dual_inds = eachindex(duals)
    lower_active_map = dual_inds[lower_active] .- num_equality

    M = [
        Q -A_active'
        A_active zeros(num_active, num_active)
    ]
    N = [R; B_active]

    MinvN = (qr(-Matrix(M), ColumnNorm()) \ Matrix(N))
    ∂x∂y = MinvN[1:n, :]
    ∂duals∂y = spzeros(length(inequality_duals), length(params))
    ∂duals∂y[lower_active_map, :] .= let
        lower_dual_range = (1:num_lower_active) .+ (n + num_equality)
        MinvN[lower_dual_range, :]
    end

    (; ∂x∂y, ∂duals∂y)
end

function ChainRulesCore.rrule(::typeof(solve), solver, problem, x0, params)
    res = solve(solver, problem, x0, params)
    project_y = ProjectTo(params)

    _back = _solve_pullback(solver, res, problem, x0, params)

    function solve_pullback(∂res)
        no_grad_args = (;
            ∂self = NoTangent(),
            ∂solver = NoTangent(),
            ∂problem = NoTangent(),
            ∂x0 = NoTangent(),
        )

        ∂y = @thunk let
            _back.∂x∂y' * ∂res.primals + _back.∂duals∂y' * ∂res.inequality_duals
        end

        no_grad_args..., project_y(∂y)
    end

    res, solve_pullback
end

function solve(
    solver,
    problem,
    x0,
    params::AbstractVector{<:ForwardDiff.Dual{T}},
) where {T}
    # strip off the duals:
    params_v = ForwardDiff.value.(params)
    params_d = ForwardDiff.partials.(params)
    # forward pass
    res = solve(solver, problem, x0, params_v)
    # backward pass
    _back = _solve_pullback(solver, res, problem, x0, params_v)

    ∂primals = _back.∂x∂y * params_d
    ∂inequality_duals = _back.∂duals∂y * params_d

    # glue forward and backward pass together into dual number types
    (;
        primals = ForwardDiff.Dual{T}.(res.primals, ∂primals),
        # we don't need these so I'm just creating a non-dual result size here
        res.equality_duals,
        inequality_duals = ForwardDiff.Dual{T}.(res.inequality_duals, ∂inequality_duals),
    )
end
