"""
    fetch_asset_data(ticker::String; range="max", interval="1d") -> DataFrame

Download historical price data for `ticker` from Yahoo Finance via YFinance.jl.

Returns a DataFrame with columns: `timestamp`, `open`, `high`, `low`, `close`, `adjclose`, `vol`.
Rows are sorted by date ascending with any missing values dropped.
"""
function fetch_asset_data(ticker::String; range::String="max", interval::String="1d")
    @info "Fetching data for $ticker (range=$range, interval=$interval)..."
    
    raw = get_prices(ticker, range=range, interval=interval)
    
    df = DataFrame(raw)
    
    # Ensure sorted by date
    sort!(df, :timestamp)
    
    # Drop rows with missing close prices
    dropmissing!(df, :close)
    
    @info "  Retrieved $(nrow(df)) data points for $ticker ($(df.timestamp[1]) to $(df.timestamp[end]))"
    return df
end

"""
    compute_log_returns(prices::Vector{<:Real}) -> Vector{Float64}

Compute daily log-returns from a price series: log(P_t / P_{t-1}).
Returns a vector of length `length(prices) - 1`.
"""
function compute_log_returns(prices::Vector{<:Real})
    n = length(prices)
    returns = Vector{Float64}(undef, n - 1)
    for i in 2:n
        returns[i-1] = log(prices[i] / prices[i-1])
    end
    return returns
end
