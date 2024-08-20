#=
Author: Nathan Winslow
Date: 08/20/2024
=#

# In julialang, importing a module permits the developer to extend the module
import Pkg
import Makie

using Pkg
Pkg.add("GR")
Pkg.add("Makie")
Pkg.add("MakieCore")
Pkg.add("CairoMakie")
Pkg.add("CSV")
Pkg.add("DataFrames")
Pkg.add("Suppressor") # For catching the output of describe
Pkg.add("Plots")
Pkg.add("StatsPlots") # if FFMPEG is causing issues, try adding FFMPEG in the REPL
Pkg.add("Distributions") 
Pkg.activate(@__DIR__)

#=
Using a module puts it "in scope", but cannot be extended

For further clarification on `import` vs `using`, see
https://stackoverflow.com/a/61072552
=#
using CairoMakie
using Makie.Colors
using MakieCore
using CSV
using DataFrames
using Statistics
using Serialization
using Suppressor
using Distributions


colors = Makie.wong_colors()  # for making the plots easier to read.

#=
This is an example of a Macro in julialang.
https://docs.julialang.org/en/v1/manual/metaprogramming/#man-macros

A Makie recipe consist of two parts, a plot type name defined via @recipe 
and a custom plot!(::Makie.plot) which creates the actual plot via 
plotting functions already defined.

For more information: https://juliadatascience.io/recipe_df
=#
@recipe(DfPlot, df) do scene
  Attributes(
    x = :X,
    y = :Y,
    c = :C,
    color = :red,
    colormap = :plasma,
    markersize = 20,
    marker = :rect,
    colorrange = (0,1),
    label = "",
  )
end

function Makie.plot!(p::DfPlot{<:Tuple{<:DataFrame}})
  #= 
  Note the extra [] at the end of each variable.
  These are due to recipes in Makie are dynamic, 
  meaning that our plots will update if our 
  variables change. 
  =# 
  df = p[:df][]
  x = getproperty(df, p[:x][]) # X-axis of plot
  y = getproperty(df, p[:y][]) # Y-axis of plot
  c = getproperty(df, p[:color][])
  scatter!(
    p, x, y;
    color = p[:color][],
    colormap = p[:colormap][],
    marker = p[:marker][],
    colorrange = (minimum(x), maximum(x)),
    label = p[:label][]
  )
  hist(x,y,

  )
  return p
end

function data_gather(path)
  # path = "path/to/logs"
  filepaths = readdir(path, join=true)
  for file in filepaths
    if (occursin("csv", file))
      data_parse(file)
    end
  end
end

function data_save(output)
  open("data_results.csv", "a", lock=true) do f
    write(f, output)
  end
end

function data_parse(fpath) 
  data = string()  # string to store the imcoming data.
  open(fpath, lock=true) do f 

    while ! eof(f)
      s = readline(f)
      temp = string(s, "\r\n")
      data = data * temp
    end
  end
  data_save(data)
end

function histogram_table_create(state, fname)

  title = "My histogram: "
  subtitle = string()

  f = Figure()
  Label(f[0, 1], title, justification = :center)
  Label(f[0, 2], subtitle, justification = :center)
  dp1 = filter(:Signal=> ==("point_1"), state)
  # dp2 = filter(:Signal=> ==("point_2"), state)
  # dp3 = filter(:Signal=> ==("point_3"), state)
  # dp4 = filter(:Signal=> ==("point_4"), state)
  num_bins = 50

  # The following demonstrates how to create a log file from histogram data.

  # stats = string()
  # stats *= "========  STATS 1 ========\r\n"
  # dp1_points = @capture_out begin describe(dp1[!, 3]) end;
  # stats *= (dp1_points * "\r\n")

  # stats *= "======== STATS 2 ========\r\n"
  # dp2_points =  @capture_out begin describe(dp2[!, 3]) end;
  # stats *= (dp2_points * "\r\n")
  
  # stats *= "========  STATS 3 ========\r\n"
  # dp3_points = @capture_out begin describe(dp3[!, 3]) end;
  # stats *= (dp3_points * "\r\n")

  # stats *= "========  STATS 4 ========\r\n"
  # dp4_points = @capture_out begin describe(dp4[!, 3]) end;
  # stats *= (dp4_points * "\r\n")
  
  # fpath = fname * ".txt" # Change this variable if needed
  # open(fpath, "a", lock=true) do f
  #   write(f, stats)
  # end

  # histogram for dp1_points
  f[1, 1] = Axis(f, title = "Data Set 1", xlabel = "X Axis", ylabel = "Y Axis")
  m_dp1 = median(dp1[!,3])
  vlines!(f[1,1], [m_dp1]; color= :red, linewidth=2)
  hist!(f[1,1],
  dp1[!, 3], # data
  normalization = :none,
  strokewidth = 0.5, strokecolor = (:black, 0.5), color = :values,
  bins = num_bins, 
  )

  # Repeat the above for each data point.

  f # May not need to call this
  fpath = fname * ".png"
  save(fpath, f)
end


# *** MAIN CODE *** #
results = "my_data.csv"
df = DataFrame(CSV.File(results))
sort!(df, [order(:Col1), order(:Col2), order(:Col3)])

# Hi-PWR ON | Enable ON
state_1 = filter(:Col1=> ==(1), df)
create_histogram_table(state_1, "hi_pwr_on_enable_on_hist")

# Hi-PWR OFF | Enable ON
state_2 = filter(:State=> ==(2), df)
create_histogram_table(state_2, "hi_pwr_off_enable_on_hist")

# Hi-PWR OFF | Enable OFF
state_3 = filter(:State=> ==(3), df)
create_histogram_table(state_3, "hi_pwr_off_enable_off_hist")

# Hi-PWR ON | Enable OFF
state_4 = filter(:State=> ==(4), df)
create_histogram_table(state_4, "hi_pwr_on_enable_off_hist")
