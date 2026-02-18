module StockSim

using DataFrames
using Dates
using Distributions
using MarSwitching
using Plots
using Printf
using Random
using Statistics
using YFinance

include("data.jl")
include("model.jl")
include("simulate.jl")
include("plotting.jl")

export fetch_asset_data, compute_log_returns
export fit_regime_model, RegimeModelResult
export simulate_paths
export plot_historical, plot_simulation_fan, run_all_plots

end # module StockSim
