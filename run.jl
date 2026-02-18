#!/usr/bin/env julia
#
# StockSim — Regime-Switching Stock Simulation Tool
#
# Usage:
#   julia --project=. run.jl
#
# Edit the TICKERS list below to simulate different assets.
#

using StockSim

# ─────────────────────────────────────────────────────────────────────
# CONFIGURATION — edit these parameters
# ─────────────────────────────────────────────────────────────────────

# Tickers to analyse (any Yahoo Finance symbol)
const TICKERS = ["AAPL", "MSFT", "TSLA"]

# Simulation parameters
const N_PATHS       = 200       # number of Monte Carlo paths per asset
const N_YEARS       = 10        # simulation horizon in years
const N_TRADING_DAYS = N_YEARS * 252   # ≈ 252 trading days per year

# Historical data range for model fitting
# Using 15 years rather than full history — avoids fitting to early growth eras
# that may not be representative of current market dynamics
const DATA_RANGE    = "15y"

# Output directory for plots
const OUTPUT_DIR    = "output"

# Random seed for reproducibility (set to `nothing` for random)  
const SEED          = 42

# ─────────────────────────────────────────────────────────────────────

function main()
    println("╔══════════════════════════════════════════════════════════════╗")
    println("║   StockSim — Regime-Switching Stochastic Stock Simulator    ║")
    println("╠══════════════════════════════════════════════════════════════╣")
    println("║  Model: 2-regime Markov switching (Hamilton, 1989)          ║")
    println("║  Capturing bull/bear market persistence via behavioural     ║")
    println("║  regime dynamics inferred from historical data              ║")
    println("╚══════════════════════════════════════════════════════════════╝")
    println()
    println("Tickers:    $(join(TICKERS, ", "))")
    println("Sim paths:  $N_PATHS")
    println("Sim horizon: $N_YEARS years ($N_TRADING_DAYS trading days)")
    println("Output:     $OUTPUT_DIR/")
    println()
    
    mkpath(OUTPUT_DIR)
    
    for ticker in TICKERS
        println("\n" * "━"^70)
        println("  Processing: $ticker")
        println("━"^70)
        
        # Step 1: Fetch historical data
        df = fetch_asset_data(ticker; range=DATA_RANGE)
        
        # Step 2: Compute log-returns from adjusted close prices
        # (adjusted for splits and dividends — gives cleaner return distributions)
        prices = Float64.(df.adjclose)
        log_returns = compute_log_returns(prices)
        
        # Step 3: Fit regime-switching model
        result = fit_regime_model(ticker, log_returns)
        
        # Step 4: Simulate forward paths (start from latest close)
        last_price = Float64(df.close[end])
        sim_paths = simulate_paths(result, last_price;
                                    n_paths=N_PATHS,
                                    n_days=N_TRADING_DAYS,
                                    seed=SEED)
        
        # Step 5: Generate plots
        hist_plot, sim_plot = run_all_plots(ticker, df, sim_paths;
                                            output_dir=OUTPUT_DIR)
        
        println("\n  ✓ $ticker complete")
        println("    Historical plot: $hist_plot")
        println("    Simulation plot: $sim_plot")
    end
    
    println("\n" * "═"^70)
    println("  All tickers processed successfully!")
    println("  Plots saved to: $OUTPUT_DIR/")
    println("═"^70)
end

main()
