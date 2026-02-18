"""
    plot_historical(ticker::String, df::DataFrame; output_dir="output") -> String

Plot the historical adjusted close price for the given ticker.
Saves the plot as a PNG and returns the file path.
"""
function plot_historical(ticker::String, df::DataFrame; output_dir::String="output")
    mkpath(output_dir)
    
    dates = df.timestamp
    prices = df.close
    
    p = plot(dates, prices,
        title = "$ticker — Historical Price",
        xlabel = "Date",
        ylabel = "Price (USD)",
        label = ticker,
        linewidth = 1.5,
        linecolor = :steelblue,
        fillrange = 0,
        fillalpha = 0.08,
        fillcolor = :steelblue,
        size = (1200, 500),
        dpi = 150,
        legend = :topleft,
        grid = true,
        gridstyle = :dash,
        gridalpha = 0.3,
        framestyle = :box,
        margin = 8Plots.mm,
        titlefontsize = 14,
        guidefontsize = 11,
        tickfontsize = 9)
    
    filepath = joinpath(output_dir, "$(ticker)_historical.png")
    savefig(p, filepath)
    @info "  Saved historical plot: $filepath"
    return filepath
end

"""
    plot_simulation_fan(ticker::String, df::DataFrame, sim_paths::Matrix{Float64};
                        output_dir="output", n_display_paths=50) -> String

Plot historical prices seamlessly continued by simulated Monte Carlo paths.

Produces a fan chart showing:
- Historical adjusted close price in solid blue
- Individual Monte Carlo paths as semi-transparent lines
- Median simulated path highlighted in red
- 10th–90th percentile confidence band as shaded region
- Vertical dashed line at the boundary between historical and simulated

Saves the plot as PNG and returns the file path.
"""
function plot_simulation_fan(ticker::String, df::DataFrame, sim_paths::Matrix{Float64};
                              output_dir::String="output", n_display_paths::Int=50)
    mkpath(output_dir)
    
    n_sim_days = size(sim_paths, 1)
    n_paths = size(sim_paths, 2)
    
    # Historical data
    hist_dates = df.timestamp
    hist_prices = df.close
    last_hist_date = hist_dates[end]
    
    # Generate future dates (approximate: skip weekends)
    future_dates = Vector{DateTime}(undef, n_sim_days)
    future_dates[1] = last_hist_date
    current_date = last_hist_date
    for i in 2:n_sim_days
        current_date += Day(1)
        # Skip weekends
        while dayofweek(current_date) > 5
            current_date += Day(1)
        end
        future_dates[i] = current_date
    end
    
    # Compute percentiles across simulation paths at each time step
    median_path = [median(sim_paths[t, :]) for t in 1:n_sim_days]
    p10 = [quantile(sim_paths[t, :], 0.10) for t in 1:n_sim_days]
    p25 = [quantile(sim_paths[t, :], 0.25) for t in 1:n_sim_days]
    p75 = [quantile(sim_paths[t, :], 0.75) for t in 1:n_sim_days]
    p90 = [quantile(sim_paths[t, :], 0.90) for t in 1:n_sim_days]
    
    # Determine y-axis range
    all_prices = vcat(hist_prices, vec(sim_paths))
    y_max = quantile(all_prices, 0.98) * 1.1  # cap at 98th percentile + margin
    y_min = max(0, minimum(hist_prices) * 0.8)
    
    # Start the plot with historical data
    p = plot(hist_dates, hist_prices,
        title = "$ticker — Historical + Simulated Price Trajectories",
        xlabel = "Date",
        ylabel = "Price (USD)",
        label = "Historical",
        linewidth = 2.0,
        linecolor = :steelblue,
        size = (1400, 600),
        dpi = 150,
        legend = :topleft,
        grid = true,
        gridstyle = :dash,
        gridalpha = 0.3,
        framestyle = :box,
        margin = 8Plots.mm,
        titlefontsize = 14,
        guidefontsize = 11,
        tickfontsize = 9,
        ylims = (y_min, y_max))
    
    # Add 10-90th percentile band
    plot!(p, future_dates, p10,
        fillrange = p90,
        fillalpha = 0.15,
        fillcolor = :orange,
        linewidth = 0,
        label = "10th–90th percentile")
    
    # Add 25-75th percentile band  
    plot!(p, future_dates, p25,
        fillrange = p75,
        fillalpha = 0.2,
        fillcolor = :darkorange,
        linewidth = 0,
        label = "25th–75th percentile")
    
    # Plot a subset of individual paths
    paths_to_show = min(n_display_paths, n_paths)
    path_indices = sort(randperm(n_paths)[1:paths_to_show])
    for (i, idx) in enumerate(path_indices)
        plot!(p, future_dates, sim_paths[:, idx],
            linewidth = 0.3,
            linealpha = 0.2,
            linecolor = :grey,
            label = i == 1 ? "Simulated paths" : false)
    end
    
    # Add median path
    plot!(p, future_dates, median_path,
        linewidth = 2.0,
        linecolor = :red,
        linestyle = :solid,
        label = "Median")
    
    # Vertical line at boundary between historical and simulated
    vline!(p, [last_hist_date],
        linewidth = 1.5,
        linestyle = :dash,
        linecolor = :black,
        linealpha = 0.5,
        label = "Simulation start")
    
    filepath = joinpath(output_dir, "$(ticker)_simulation.png")
    savefig(p, filepath)
    @info "  Saved simulation fan chart: $filepath"
    return filepath
end

"""
    run_all_plots(ticker, df, sim_paths; output_dir="output") -> Tuple{String, String}

Generate both historical and simulation plots for a ticker.
"""
function run_all_plots(ticker::String, df::DataFrame, sim_paths::Matrix{Float64};
                        output_dir::String="output")
    p1 = plot_historical(ticker, df; output_dir=output_dir)
    p2 = plot_simulation_fan(ticker, df, sim_paths; output_dir=output_dir)
    return (p1, p2)
end
