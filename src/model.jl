"""
    RegimeModelResult

Holds the fitted Markov switching model and extracted regime parameters for a single asset.

# Fields
- `ticker::String` — asset ticker symbol
- `model::MSM` — fitted MarSwitching.jl model object  
- `μ::Vector{Float64}` — regime-dependent mean returns (bull, bear)
- `σ::Vector{Float64}` — regime-dependent volatilities
- `P::Matrix{Float64}` — transition probability matrix
- `bull_regime::Int` — index of the bull (higher-return) regime
- `bear_regime::Int` — index of the bear (lower-return) regime
"""
struct RegimeModelResult
    ticker::String
    model::Any  # MSM type from MarSwitching
    μ::Vector{Float64}
    σ::Vector{Float64}
    P::Matrix{Float64}
    bull_regime::Int
    bear_regime::Int
end

"""
    fit_regime_model(ticker::String, log_returns::Vector{Float64}; k=2) -> RegimeModelResult

Fit a `k`-regime Markov switching model to the daily log-returns of the given asset.

The model uses regime-switching intercept and variance (Hamilton, 1989).
Parameters μ (mean return) and σ (volatility) are estimated for each regime,
along with the transition probability matrix P.

Regimes are labelled as \"bull\" (higher mean return) and \"bear\" (lower mean return).
"""
function fit_regime_model(ticker::String, log_returns::Vector{Float64}; k::Int=2)
    @info "Fitting $k-regime Markov switching model for $ticker ($(length(log_returns)) observations)..."
    
    # Fit the Markov switching model with switching intercept and switching variance
    # Use random_search to explore multiple starting points — avoids degenerate solutions
    # where both regimes collapse to identical parameters
    model = MSModel(log_returns, k, 
                     intercept="switching", 
                     switching_var=true,
                     random_search=20,
                     maxtime=120)
    
    # Extract regime parameters
    # β[state][1] is the intercept (mean return) for each state
    μ = [model.β[s][1] for s in 1:k]
    σ = model.σ
    P = model.P
    
    # Identify bull (higher mean return) and bear (lower mean return) regimes
    bull_regime = argmax(μ)
    bear_regime = argmin(μ)
    
    @info "  Regime parameters for $ticker:"
    @info "    Bull regime ($bull_regime): μ_daily = $(@sprintf("%.6f", μ[bull_regime])), σ_daily = $(@sprintf("%.6f", σ[bull_regime]))"
    @info "      Annualised: return ≈ $(@sprintf("%.1f", μ[bull_regime]*252*100))%, vol ≈ $(@sprintf("%.1f", σ[bull_regime]*sqrt(252)*100))%"
    @info "    Bear regime ($bear_regime): μ_daily = $(@sprintf("%.6f", μ[bear_regime])), σ_daily = $(@sprintf("%.6f", σ[bear_regime]))"
    @info "      Annualised: return ≈ $(@sprintf("%.1f", μ[bear_regime]*252*100))%, vol ≈ $(@sprintf("%.1f", σ[bear_regime]*sqrt(252)*100))%"
    @info "    P(stay bull) = $(@sprintf("%.4f", P[bull_regime, bull_regime])), P(stay bear) = $(@sprintf("%.4f", P[bear_regime, bear_regime]))"
    
    # Expected regime durations
    bull_duration = 1.0 / (1.0 - P[bull_regime, bull_regime])
    bear_duration = 1.0 / (1.0 - P[bear_regime, bear_regime])
    @info "    Expected bull duration: $(@sprintf("%.1f", bull_duration)) days ($(@sprintf("%.1f", bull_duration/252)) years)"
    @info "    Expected bear duration: $(@sprintf("%.1f", bear_duration)) days ($(@sprintf("%.1f", bear_duration/252)) years)"
    
    # Print full model summary (may fail if Hessian has NaN — non-fatal)
    println("\n" * "="^70)
    println("MODEL SUMMARY: $ticker")
    println("="^70)
    try
        summary_msm(model)
    catch e
        @warn "  Could not compute full summary table (Hessian numerical issue): $e"
        println("  Transition matrix:")
        transition_mat(model)
        println("  Expected regime durations:")
        expected_duration(model)
    end
    println("="^70 * "\n")
    
    return RegimeModelResult(ticker, model, μ, σ, P, bull_regime, bear_regime)
end
