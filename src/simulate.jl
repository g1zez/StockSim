"""
    simulate_paths(result::RegimeModelResult, last_price::Float64;
                   n_paths=100, n_days=2520, seed=nothing) -> Matrix{Float64}

Run Monte Carlo forward simulation of asset prices using the fitted regime-switching model.

Each simulation path:
1. Starts at `last_price` (typically the most recent observed close)
2. At each time step, transitions between regimes according to the estimated transition matrix `P`
3. Draws a daily log-return from `Normal(μ_regime, σ_regime)` for the current regime
4. Computes the next price as `P_{t+1} = P_t × exp(r_t)`

# Arguments
- `result::RegimeModelResult` — fitted model with regime parameters
- `last_price::Float64` — starting price for all paths
- `n_paths::Int` — number of Monte Carlo simulation paths (default: 100)
- `n_days::Int` — number of trading days to simulate (default: 2520 ≈ 10 years)
- `seed` — optional random seed for reproducibility

# Returns
- `Matrix{Float64}` of size `(n_days + 1, n_paths)` — each column is one price path,
  with the first row being `last_price`.
"""
function simulate_paths(result::RegimeModelResult, last_price::Float64;
                         n_paths::Int=100, n_days::Int=2520, seed=nothing)
    
    if seed !== nothing
        Random.seed!(seed)
    end
    
    k = length(result.μ)
    μ = result.μ
    σ = result.σ
    P = result.P
    
    @info "Simulating $n_paths paths × $n_days days for $(result.ticker) from price $(@sprintf("%.2f", last_price))..."
    
    # Price paths matrix: rows = time steps, columns = paths
    paths = Matrix{Float64}(undef, n_days + 1, n_paths)
    
    # Determine initial regime probabilities from the stationary distribution
    # For a 2-state Markov chain, stationary distribution satisfies π = Pπ
    # π₁ = P[1,2] / (P[1,2] + P[2,1]), π₂ = P[2,1] / (P[1,2] + P[2,1])
    if k == 2
        p12 = P[2, 1]  # probability of transitioning from state 1 to state 2
        p21 = P[1, 2]  # probability of transitioning from state 2 to state 1
        stationary = [p21 / (p12 + p21), p12 / (p12 + p21)]
    else
        # For k > 2, use eigenvalue method
        # Find left eigenvector corresponding to eigenvalue 1
        eig = eigen(P')
        idx = argmin(abs.(eig.values .- 1.0))
        stationary = abs.(eig.vectors[:, idx])
        stationary ./= sum(stationary)
    end
    
    for path in 1:n_paths
        paths[1, path] = last_price
        
        # Sample initial regime from stationary distribution
        current_regime = rand() < stationary[1] ? 1 : 2
        
        for t in 2:(n_days + 1)
            # Draw log-return from current regime's distribution
            r = rand(Normal(μ[current_regime], σ[current_regime]))
            
            # Update price
            paths[t, path] = paths[t-1, path] * exp(r)
            
            # Transition to next regime
            # P is left-stochastic: P[j,i] = probability of going from state i to state j
            # So for current_regime i, the next state probabilities are P[:, i]
            transition_probs = P[:, current_regime]
            u = rand()
            cumprob = 0.0
            for s in 1:k
                cumprob += transition_probs[s]
                if u <= cumprob
                    current_regime = s
                    break
                end
            end
        end
    end
    
    @info "  Simulation complete. Price range at end: $(@sprintf("%.2f", minimum(paths[end,:]))) — $(@sprintf("%.2f", maximum(paths[end,:])))"
    
    return paths
end
