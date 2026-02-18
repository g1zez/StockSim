# StockSim — Regime-Switching Stochastic Stock Simulator

A Julia tool that simulates future stock price trajectories using a **Markov switching model** to capture the behavioural persistence of bull and bear markets.

## How It Works

Standard geometric Brownian motion (GBM) assumes constant drift and volatility — this fails to capture how real markets behave. Bull markets and bear markets can persist for months or years, driven by investor sentiment and herd behaviour.

This tool uses a **2-regime Markov switching model** (Hamilton, 1989):

- **Regime 1 (Bull)**: Higher mean return, typically lower volatility
- **Regime 2 (Bear)**: Lower/negative mean return, typically higher volatility
- **Transition Matrix**: Captures the probability of staying in or switching between regimes

The model parameters are **inferred individually for each asset** from its full historical daily return data using maximum likelihood estimation.

### Forward Simulation

Monte Carlo simulation generates future price paths by:
1. Sampling the current market regime from the transition matrix at each time step
2. Drawing a daily return from the regime-specific distribution
3. Compounding returns into a price path

This produces realistic trajectories where periods of sustained growth or decline emerge naturally from the regime dynamics.

## Quick Start

```bash
# Install dependencies
julia --project=. -e 'using Pkg; Pkg.instantiate()'

# Run simulation (edit TICKERS in run.jl to customise)
julia --project=. run.jl
```

## Configuration

Edit the constants at the top of `run.jl`:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `TICKERS` | `["AAPL", "MSFT", "TSLA"]` | Yahoo Finance ticker symbols |
| `N_PATHS` | `200` | Number of Monte Carlo simulation paths |
| `N_YEARS` | `10` | Simulation horizon |
| `DATA_RANGE` | `"max"` | Historical data range (`"5y"`, `"10y"`, `"max"`) |
| `SEED` | `42` | Random seed (set to `nothing` for non-deterministic) |

## Output

For each ticker, two plots are generated in the `output/` directory:

- **`{TICKER}_historical.png`** — Full historical price chart
- **`{TICKER}_simulation.png`** — Historical prices continued by simulated trajectories, with median path and confidence bands (10th–90th and 25th–75th percentiles)

Model summaries with regime parameters are printed to the console.

## Dependencies

- [MarSwitching.jl](https://github.com/m-dadej/MarSwitching.jl) — Markov switching dynamic models
- [YFinance.jl](https://github.com/eohne/YFinance.jl) — Yahoo Finance data
- [Plots.jl](https://github.com/JuliaPlots/Plots.jl) — Visualisation
- [DataFrames.jl](https://github.com/JuliaData/DataFrames.jl) — Data handling
- [Distributions.jl](https://github.com/JuliaStats/Distributions.jl) — Statistical distributions

## References

- Hamilton, J. D. (1989). *A new approach to the economic analysis of nonstationary time series and the business cycle.* Econometrica, 357-384.
- Dadej, M. (2024). *MarSwitching.jl: A Julia package for Markov switching dynamic models.* Journal of Open Source Software, 9(98), 6441.
