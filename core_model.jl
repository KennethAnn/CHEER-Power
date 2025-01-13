# ===========================================================
#                 CHEER/Power Source Code
# ===========================================================
# This script contains the source code for the CHEER/Power 
# project, which focuses on modeling power system transition 
# pathways of China's provinces.
#
# Author: Kangxin An
# Date: 2025.01.11
# Version: 1.0
# ===========================================================

using JuMP, Gurobi, CSV, DataFrames

# model as a package
function run_model(scn, min_capacity_factor=0)
println("The scenario name is $(scn)")
# -------------------------------------
# declare the model
# -------------------------------------
mod = Model(Gurobi.Optimizer)

# -------------------------------------
# read parameters and DataFrame
# -------------------------------------
loc_periods = joinpath(pwd(), "$(scn)/inputs/periods.csv")
df_periods = CSV.read(loc_periods, DataFrames.DataFrame, header=1)
loc_timeseries = joinpath(pwd(), "$(scn)/inputs/timeseries.csv")
df_timeseries = CSV.read(loc_timeseries, DataFrames.DataFrame, header=1)
loc_timepoints = joinpath(pwd(), "$(scn)/inputs/timepoints.csv")
df_timepoints = CSV.read(loc_timepoints, DataFrames.DataFrame, header=1)
loc_financials = joinpath(pwd(), "$(scn)/inputs/financials.csv")
df_financials = CSV.read(loc_financials, DataFrames.DataFrame, header=1)
loc_non_fuel_energy_sources = joinpath(pwd(), "$(scn)/inputs/non_fuel_energy_sources.csv")
df_non_fuel_energy_sources = CSV.read(loc_non_fuel_energy_sources, DataFrames.DataFrame, header=1)
loc_gen_build_predetermined = joinpath(pwd(), "$(scn)/inputs/gen_build_predetermined.csv")
df_gen_build_predetermined = CSV.read(loc_gen_build_predetermined, DataFrames.DataFrame, header=1)
loc_ccs_install_predetermined = joinpath(pwd(), "$(scn)/inputs/ccs_install_predetermined.csv")
df_ccs_install_predetermined = CSV.read(loc_ccs_install_predetermined, DataFrames.DataFrame, header=1)
loc_ccs_new_predetermined = joinpath(pwd(), "$(scn)/inputs/ccs_new_predetermined.csv")
df_ccs_new_predetermined = CSV.read(loc_ccs_new_predetermined, DataFrames.DataFrame, header=1)
loc_gen_build_costs = joinpath(pwd(), "$(scn)/inputs/gen_build_costs.csv")
df_gen_build_costs = CSV.read(loc_gen_build_costs, DataFrames.DataFrame, header=1)
loc_ccs_install_costs = joinpath(pwd(), "$(scn)/inputs/ccs_install_costs.csv")
df_ccs_install_costs = CSV.read(loc_ccs_install_costs, DataFrames.DataFrame, header=1)
loc_load_zones = joinpath(pwd(), "$(scn)/inputs/load_zones.csv")
df_load_zones = CSV.read(loc_load_zones, DataFrames.DataFrame, header=1)
loc_loads = joinpath(pwd(), "$(scn)/inputs/loads.csv")
df_loads = CSV.read(loc_loads, DataFrames.DataFrame, header=1)
loc_zone_coincident_peak_demand = joinpath(pwd(), "$(scn)/inputs/zone_coincident_peak_demand.csv")
df_zone_coincident_peak_demand = CSV.read(loc_zone_coincident_peak_demand, DataFrames.DataFrame, header=1)
loc_fuels = joinpath(pwd(), "$(scn)/inputs/fuels.csv")
df_fuels = CSV.read(loc_fuels, DataFrames.DataFrame, header=1)
loc_gen_info = joinpath(pwd(), "$(scn)/inputs/gen_info.csv")
df_gen_info = CSV.read(loc_gen_info, DataFrames.DataFrame, header=1)
loc_variable_capacity_factors = joinpath(pwd(), "$(scn)/inputs/variable_capacity_factors.csv")
df_variable_capacity_factors = CSV.read(loc_variable_capacity_factors, DataFrames.DataFrame, header=1)
loc_hydro_timeseries = joinpath(pwd(), "$(scn)/inputs/hydro_timeseries.csv")
df_hydro_timeseries = CSV.read(loc_hydro_timeseries, DataFrames.DataFrame, header=1)
loc_regional_fuel_markets = joinpath(pwd(), "$(scn)/inputs/regional_fuel_markets.csv")
df_regional_fuel_markets = CSV.read(loc_regional_fuel_markets, DataFrames.DataFrame, header=1)
loc_fuel_cost = joinpath(pwd(), "$(scn)/inputs/fuel_cost.csv")
df_fuel_cost = CSV.read(loc_fuel_cost, DataFrames.DataFrame, header=1)
loc_fuel_supply_curves = joinpath(pwd(), "$(scn)/inputs/fuel_supply_curves.csv")
df_fuel_supply_curves = CSV.read(loc_fuel_supply_curves, DataFrames.DataFrame, header=1)
loc_zone_to_regional_fuel_market = joinpath(pwd(), "$(scn)/inputs/zone_to_regional_fuel_market.csv")
df_zone_to_regional_fuel_market = CSV.read(loc_zone_to_regional_fuel_market, DataFrames.DataFrame, header=1)
loc_planning_reserve_requirements = joinpath(pwd(), "$(scn)/inputs/planning_reserve_requirements.csv")
df_planning_reserve_requirements = CSV.read(loc_planning_reserve_requirements, DataFrames.DataFrame, header=1)
loc_planning_reserve_requirement_zones = joinpath(pwd(), "$(scn)/inputs/planning_reserve_requirement_zones.csv")
df_planning_reserve_requirement_zones = CSV.read(loc_planning_reserve_requirement_zones, DataFrames.DataFrame, header=1)
loc_transmission_lines = joinpath(pwd(), "$(scn)/inputs/transmission_lines.csv")
df_transmission_lines = CSV.read(loc_transmission_lines, DataFrames.DataFrame, header=1)
loc_trans_params = joinpath(pwd(), "$(scn)/inputs/trans_params.csv")
df_trans_params = CSV.read(loc_trans_params, DataFrames.DataFrame, header=1)
loc_carbon_policies = joinpath(pwd(), "$(scn)/inputs/carbon_policies.csv")
df_carbon_policies = CSV.read(loc_carbon_policies, DataFrames.DataFrame, header=1)
loc_total_capacity_limits = joinpath(pwd(), "$(scn)/inputs/total_capacity_limits.csv")
df_total_capacity_limits = CSV.read(loc_total_capacity_limits, DataFrames.DataFrame, header=1)
loc_capacity_plans = joinpath(pwd(), "$(scn)/inputs/capacity_plans.csv")
df_capacity_plans = CSV.read(loc_capacity_plans, DataFrames.DataFrame, header=1)
loc_build_tx_limits = joinpath(pwd(), "$(scn)/inputs/build_tx_limits.csv")
df_build_tx_limits = CSV.read(loc_build_tx_limits, DataFrames.DataFrame, header=1)
loc_gen_ccs_energy_load = joinpath(pwd(), "$(scn)/inputs/gen_ccs_energy_load.csv")
df_gen_ccs_energy_load = CSV.read(loc_gen_ccs_energy_load, DataFrames.DataFrame, header=1)
println("Finished to read data")

# -------------------------------------
# sets, parameters and model components
# -------------------------------------
# 1. timescales
# -------------------------------------
hours_per_year = 8760

# PERIODS represented investment period, which indicates the range between period_start and period_end, period_prev is the previous period of PERIODS, start_period is the start period of modeling
PERIODS = df_periods.INVESTMENT_PERIOD
period_start = Dict(a => df_periods.period_start[i] for (i, a) in enumerate(PERIODS))
period_end = Dict(a => df_periods.period_end[i] for (i, a) in enumerate(PERIODS))
period_prev = Dict(a => df_periods.period_prev[i] for (i, a) in enumerate(PERIODS))
start_period = PERIODS[1]

# timeseries represents the typical day
TIMESERIES = df_timeseries.TIMESERIES
ts_period = Dict(a => df_timeseries.ts_period[i] for (i, a) in enumerate(TIMESERIES))
ts_duration_of_tp = Dict(a => df_timeseries.ts_duration_of_tp[i] for (i, a) in enumerate(TIMESERIES))
ts_num_tps = Dict(a => df_timeseries.ts_num_tps[i] for (i, a) in enumerate(TIMESERIES))
ts_scale_to_period = Dict(a => df_timeseries.ts_scale_to_period[i] for (i, a) in enumerate(TIMESERIES))

# timepoints represents the typical hours
TIMEPOINTS = df_timepoints.timepoint_id
tp_ts = Dict(a => df_timepoints.timeseries[i] for (i, a) in enumerate(TIMEPOINTS))
tp_timestamp = Dict(a => df_timepoints.timestamp[i] for (i, a) in enumerate(TIMEPOINTS))
tp_duration_hrs = Dict(a => ts_duration_of_tp[tp_ts[a]] for a in TIMEPOINTS)
tp_weight = Dict(a => tp_duration_hrs[a] * ts_scale_to_period[tp_ts[a]] for a in TIMEPOINTS)
TPS_IN_TS = Dict(ts => [t for t in TIMEPOINTS if tp_ts[t] == ts] for ts in TIMESERIES)
tp_period = Dict(t => ts_period[tp_ts[t]] for t in TIMEPOINTS)
TS_IN_PERIOD = Dict(p => [ts for ts in TIMESERIES if ts_period[ts] == p] for p in PERIODS)
TPS_IN_PERIOD = Dict(p => [t for t in TIMEPOINTS if tp_period[t] == p] for p in PERIODS)
period_length_years = Dict(p => period_end[p] - period_start[p] + 1 for p in PERIODS)
period_length_hours = Dict(p => period_length_years[p] * hours_per_year for p in PERIODS)
CURRENT_AND_PRIOR_PERIODS_FOR_PERIOD = Dict(p => [p2 for p2 in PERIODS if p2 <= p] for p in PERIODS)
ts_scale_to_year = Dict(ts => ts_scale_to_period[ts] / period_length_years[ts_period[ts]] for ts in TIMESERIES)
ts_duration_hrs = Dict(ts => ts_num_tps[ts] * ts_duration_of_tp[ts] for ts in TIMESERIES)
tp_weight_in_year = Dict(t => tp_weight[t] / period_length_years[tp_period[t]] for t in TIMEPOINTS)

function prevw(t, gap, discrete=true)
if discrete == true
    tps = TPS_IN_TS[tp_ts[t]]
else
    tps = TPS_IN_PERIOD[tp_period[t]]
end
id_t = findfirst(isequal(t), tps)
id_t_prev = (id_t - gap) % length(tps)
if id_t_prev <= 0
t_prev = tps[id_t_prev + length(tps)]
else
t_prev = tps[id_t_prev]
end
return t_prev
end

tp_previous = Dict(t => prevw(t, 1) for t in TIMEPOINTS)
tp_previous_commit = Dict(t => prevw(t, 1) for t in TIMEPOINTS)

# -------------------------------------
# 2. financial parameters
# -------------------------------------
base_financial_year = df_financials.base_financial_year[1]
interest_rate = df_financials.interest_rate[1]
discount_rate = df_financials.discount_rate[1]

function crf(ir, t)
"""capital recovery factor
"""
if ir == 0
rf = ir / t
else
rf = ir / (1 - (1 + ir) ^ (-t))
end
return rf
end

# -------------------------------------
# 3. load zones
# -------------------------------------
LOAD_ZONES = df_load_zones.LOAD_ZONE
ZONE_PERIODS = [(r, t) for r in LOAD_ZONES for t in PERIODS]
ZONE_TIMEPOINTS = [(r, t) for r in LOAD_ZONES for t in TIMEPOINTS]
zone_demand_mw = Dict((r, t) => subset(df_loads, :load_zone => ByRow(==(r)), :TIMEPOINT => ByRow(==(t)))[1, "zone_demand_mw"] for (r, t) in ZONE_TIMEPOINTS)
zone_ccs_distance_km = Dict(a => df_load_zones.zone_ccs_distance_km[i] for (i, a) in enumerate(LOAD_ZONES))
zone_dbid = Dict(a => df_load_zones.zone_dbid[i] for (i, a) in enumerate(LOAD_ZONES))
EXTERNAL_COINCIDENT_PEAK_DEMAND_ZONE_PERIODS = [(r, p) for r in LOAD_ZONES for p in PERIODS]
zone_expected_coincident_peak_demand = Dict((r, p) => subset(df_zone_coincident_peak_demand, :LOAD_ZONE => ByRow(==(r)), :PERIOD => ByRow(==(p)))[1, "zone_expected_coincident_peak_demand"] for (r, p) in EXTERNAL_COINCIDENT_PEAK_DEMAND_ZONE_PERIODS)
zone_total_demand_in_period_mwh = Dict((r, p) => sum(zone_demand_mw[r, t] * tp_weight[t] for t in TPS_IN_PERIOD[p]) for (r, p) in EXTERNAL_COINCIDENT_PEAK_DEMAND_ZONE_PERIODS)

# -------------------------------------
# 4. energy sources
# -------------------------------------
NON_FUEL_ENERGY_SOURCES = df_non_fuel_energy_sources.fuel
FUELS = df_fuels.fuel
f_co2_intensity = Dict(a => convert(Float64, replace(df_fuels.co2_intensity, "." => "0.0")[i]) for (i, a) in enumerate(FUELS))
f_upstream_co2_intensity = Dict(a => parse(Float64, replace(df_fuels.upstream_co2_intensity, "." => "0.0")[i]) for (i, a) in enumerate(FUELS))
ENERGY_SOURCES = Set([NON_FUEL_ENERGY_SOURCES; FUELS])

# -------------------------------------
# 5 capacity installation, early retirement and CCS retrofit
# -------------------------------------
GENERATION_PROJECTS = df_gen_info.GENERATION_PROJECT
gen_dbid = Dict(a => df_gen_info.gen_dbid[i] for (i, a) in enumerate(GENERATION_PROJECTS))
gen_tech = Dict(a => df_gen_info.gen_tech[i] for (i, a) in enumerate(GENERATION_PROJECTS))
GENERATION_TECHNOLOGIES = Set([gen_tech[t] for t in GENERATION_PROJECTS])
gen_energy_source = Dict(a => convert(Array{String7}, df_gen_info.gen_energy_source)[i] for (i, a) in enumerate(GENERATION_PROJECTS))
gen_load_zone = Dict(a => convert(Array{String31}, df_gen_info.gen_load_zone)[i] for (i, a) in enumerate(GENERATION_PROJECTS))
gen_max_age = Dict(a => convert(Array{Int8}, df_gen_info.gen_max_age)[i] for (i, a) in enumerate(GENERATION_PROJECTS))
gen_is_variable = Dict(a => convert(Array{Bool}, df_gen_info.gen_is_variable)[i] for (i, a) in enumerate(GENERATION_PROJECTS))
gen_is_baseload = Dict(a => convert(Array{Bool}, df_gen_info.gen_is_baseload)[i] for (i, a) in enumerate(GENERATION_PROJECTS))
gen_is_flexible_baseload = Dict(a => convert(Array{Bool}, df_gen_info.gen_is_flexible_baseload)[i] for (i, a) in enumerate(GENERATION_PROJECTS))
gen_is_cogen = Dict(a => convert(Array{Bool}, df_gen_info.gen_is_cogen)[i] for (i, a) in enumerate(GENERATION_PROJECTS))
gen_is_distributed = Dict(a => false for (i, a) in enumerate(GENERATION_PROJECTS))
gen_scheduled_outage_rate = Dict(a => convert(Array{Float16}, df_gen_info.gen_scheduled_outage_rate)[i] for (i, a) in enumerate(GENERATION_PROJECTS))
gen_forced_outage_rate = Dict(a => convert(Array{Float16}, df_gen_info.gen_forced_outage_rate)[i] for (i, a) in enumerate(GENERATION_PROJECTS))

function GENS_IN_ZONE_init(LOAD_ZONES)
    GEN_IN_ZONE_dict = Dict(z => [] for z in LOAD_ZONES)
        for g in GENERATION_PROJECTS
        push!(GEN_IN_ZONE_dict[gen_load_zone[g]], g)
        end
    return GEN_IN_ZONE_dict
end
GENS_IN_ZONE = GENS_IN_ZONE_init(LOAD_ZONES)
VARIABLE_GENS = [g for g in GENERATION_PROJECTS if gen_is_variable[g]]

function VARIABLE_GENS_IN_ZONE_init(LOAD_ZONES)
VARIABLE_GEN_IN_ZONE_dict = Dict(z => [] for z in LOAD_ZONES)
for g in VARIABLE_GENS
push!(VARIABLE_GEN_IN_ZONE_dict[gen_load_zone[g]], g)
end
return VARIABLE_GEN_IN_ZONE_dict
end
VARIABLE_GENS_IN_ZONE = VARIABLE_GENS_IN_ZONE_init(LOAD_ZONES)
BASELOAD_GENS = [g for g in GENERATION_PROJECTS if gen_is_baseload[g]]

function GENS_BY_TECHNOLOGY_init(GENERATION_TECHNOLOGIES)
GENS_BY_TECH_dict = Dict(t => [] for t in GENERATION_TECHNOLOGIES)
for g in GENERATION_PROJECTS
push!(GENS_BY_TECH_dict[gen_tech[g]], g)
end
return GENS_BY_TECH_dict
end
GENS_BY_TECHNOLOGY = GENS_BY_TECHNOLOGY_init(GENERATION_TECHNOLOGIES)
CAPACITY_LIMITED_GENS = GENERATION_PROJECTS[findall(x-> x != ".", df_gen_info.gen_capacity_limit_mw)]

gen_capacity_limit_mw = Dict(a => parse(Float64, df_gen_info.gen_capacity_limit_mw[findall(x->x != ".", df_gen_info.gen_capacity_limit_mw)][i]) for (i, a) in enumerate(CAPACITY_LIMITED_GENS))

gen_min_build_capacity = Dict(a => parse(Float64, replace(df_gen_info.gen_min_build_capacity, "." => "0.0")[i]) for (i, a) in enumerate(GENERATION_PROJECTS))

gen_ccs_capture_efficiency = Dict(a => 0.90 for (i, a) in enumerate(GENERATION_PROJECTS))
gen_uses_fuel = Dict(g => gen_energy_source[g] in FUELS for g in GENERATION_PROJECTS)

NON_FUEL_BASED_GENS = [g for g in GENERATION_PROJECTS if gen_uses_fuel[g] != true]

FUEL_BASED_GENS = [g for g in GENERATION_PROJECTS if gen_uses_fuel[g]]

gen_full_load_heat_rate = Dict(a => parse(Float64, replace(df_gen_info.gen_full_load_heat_rate, "." => "0.0")[i]) for (i, a) in enumerate(GENERATION_PROJECTS))

FUELS_FOR_GEN = Dict(g => [gen_energy_source[g]] for g in FUEL_BASED_GENS)

function GENS_BY_ENERGY_SOURCE_init(ENERGY_SOURCES)
GENS_BY_ENERGY_SOURCE_dict = Dict(z => [] for z in ENERGY_SOURCES)
for g in GENERATION_PROJECTS
if g in FUEL_BASED_GENS
    for f in FUELS_FOR_GEN[g]
        push!(GENS_BY_ENERGY_SOURCE_dict[f], g)
    end
else
    push!(GENS_BY_ENERGY_SOURCE_dict[gen_energy_source[g]], g)
end
end
return GENS_BY_ENERGY_SOURCE_dict
end
GENS_BY_ENERGY_SOURCE = GENS_BY_ENERGY_SOURCE_init(ENERGY_SOURCES)
GENS_BY_NON_FUEL_ENERGY_SOURCE = Dict(g => GENS_BY_ENERGY_SOURCE[g] for g in NON_FUEL_ENERGY_SOURCES)
GENS_BY_FUEL = Dict(g => GENS_BY_ENERGY_SOURCE[g] for g in FUELS)

PREDETERMINED_GEN_BLD_YRS = [(g, p) for (g, p) in eachrow(Array(df_gen_build_predetermined[!, [:GENERATION_PROJECT, :build_year]]))]

PREDETERMINED_GEN_BLD_INST_YRS = [(g, p, pt) for (g, p, pt) in eachrow(Array(df_ccs_install_predetermined[!, [:GENERATION_PROJECT, :build_year, :install_year]]))]

GEN_BLD_YRS = [(g, p) for (g, p) in eachrow(Array(df_gen_build_costs[!, [:GENERATION_PROJECT, :build_year]]))]

GEN_BLD_INST_YRS = [(g, p, pt) for (g, p, pt) in eachrow(Array(df_ccs_install_costs[!, [:GENERATION_PROJECT, :build_year, :install_year]]))]

CCS_GENS = Set([g for (g, p, pt) in GEN_BLD_INST_YRS])
NOCCS_GENS = setdiff(GENERATION_PROJECTS, CCS_GENS)
function BLD_YRS_FOR_GENS_init(GENERATION_PROJECTS)
BLD_YRS_FOR_GENS_dict = Dict(t => [] for t in GENERATION_PROJECTS)
for (gen, bld_yr) in GEN_BLD_YRS
push!(BLD_YRS_FOR_GENS_dict[gen], bld_yr)
end
return BLD_YRS_FOR_GENS_dict
end
BLD_YRS_FOR_GENS = BLD_YRS_FOR_GENS_init(GENERATION_PROJECTS)

function BLD_YRS_FOR_CCS_GENS_init(CCS_GENS)
BLD_YRS_FOR_CCS_GENS_dict = Dict(t => [] for t in CCS_GENS)
for (gen, bld_yr, inst_yr) in GEN_BLD_INST_YRS
push!(BLD_YRS_FOR_CCS_GENS_dict[gen], bld_yr)
end
return BLD_YRS_FOR_CCS_GENS_dict
end

BLD_YRS_FOR_CCS_GENS = BLD_YRS_FOR_CCS_GENS_init(CCS_GENS)
CCS_GEN_BLD_YRS = [(g, p) for g in CCS_GENS for p in BLD_YRS_FOR_CCS_GENS[g]]
NOCCS_GEN_BLD_YRS = setdiff(GEN_BLD_YRS, CCS_GEN_BLD_YRS)
NEW_GEN_BLD_YRS = setdiff(GEN_BLD_YRS, PREDETERMINED_GEN_BLD_YRS)
NEW_GEN_BLD_INST_YRS = setdiff(GEN_BLD_INST_YRS, PREDETERMINED_GEN_BLD_INST_YRS)

build_gen_predetermined = Dict(a => df_gen_build_predetermined.build_gen_predetermined[i] for (i, a) in enumerate(PREDETERMINED_GEN_BLD_YRS))

install_ccs_predetermined = Dict(a => df_ccs_install_predetermined.install_ccs_predetermined[i] for (i, a) in enumerate(PREDETERMINED_GEN_BLD_INST_YRS))
new_ccs_predetermined = Dict(a => df_ccs_new_predetermined.new_ccs_predetermined[i] for (i, a) in enumerate(PREDETERMINED_GEN_BLD_INST_YRS))

function gen_build_can_operate_in_period(g, build_year, period)
online = build_year
retirement = online + gen_max_age[g]
return online <= period < retirement
end

PERIODS_FOR_GEN_BLD_YR = Dict((g, bld_yr) => [period for period in PERIODS if gen_build_can_operate_in_period(g, bld_yr, period)] for (g, bld_yr) in GEN_BLD_YRS)

BLD_YRS_FOR_GEN_PERIOD = Dict((g, period) => Set([bld_yr for (gen, bld_yr) in GEN_BLD_YRS if ((gen == g) & gen_build_can_operate_in_period(g, bld_yr, period))]) for g in GENERATION_PROJECTS for period in PERIODS)

function ccs_install_can_operate_in_period(g, build_year, install_year, period)
online = install_year
retirement = build_year + gen_max_age[g]
return online <= period < retirement
end

INST_YRS_FOR_GEN_BLD_YRS_PERIOD = Dict((g, bld_yr, period) => Set([inst_yr for (gen, build_yr, inst_yr) in GEN_BLD_INST_YRS if (gen == g) & (build_yr == bld_yr) & ccs_install_can_operate_in_period(g, bld_yr, inst_yr, period)]) for (g, bld_yr) in CCS_GEN_BLD_YRS for period in PERIODS)

PERIODS_FOR_GEN = Dict(g => [p for p in PERIODS if length(BLD_YRS_FOR_GEN_PERIOD[g, p]) > 0] for g in GENERATION_PROJECTS)

function bounds_BuildGen(g, bld_yr)
if (g, bld_yr) in PREDETERMINED_GEN_BLD_YRS
return (
    build_gen_predetermined[g, bld_yr],
    build_gen_predetermined[g, bld_yr],
)
elseif g in CAPACITY_LIMITED_GENS
return (0, gen_capacity_limit_mw[g])
else
return (0, Inf)
end
end

@variable(mod, BuildGen[(g, bld_yr) in GEN_BLD_YRS], start=bounds_BuildGen(g, bld_yr)[1], lower_bound=bounds_BuildGen(g, bld_yr)[1], upper_bound=bounds_BuildGen(g, bld_yr)[2])
for (g, bld_yr) in PREDETERMINED_GEN_BLD_YRS
JuMP.fix(BuildGen[(g, bld_yr)], build_gen_predetermined[g, bld_yr]; force=true)
end
GEN_PERIODS = [(g, p) for g in GENERATION_PROJECTS for p in PERIODS_FOR_GEN[g]]
gen_ccs_energy_load = Dict((t, p) => 0.0 for t in GENERATION_TECHNOLOGIES for p in PERIODS)
for row in eachrow(df_gen_ccs_energy_load)
    gen_ccs_energy_load[(row.gen_tech, row.period)] = row.gen_ccs_energy_load
end 
function bounds_CCSGen(g, bld_yr, inst_yr)
if (g, bld_yr, inst_yr) in PREDETERMINED_GEN_BLD_INST_YRS
return (
    install_ccs_predetermined[g, bld_yr, inst_yr],
    install_ccs_predetermined[g, bld_yr, inst_yr],
)
elseif g in CAPACITY_LIMITED_GENS
return (0, gen_capacity_limit_mw[g])
else
return (0, Inf)
end
end

function bounds_NewCCSGen(g, bld_yr, inst_yr)
if (g, bld_yr, inst_yr) in PREDETERMINED_GEN_BLD_INST_YRS
return (
    new_ccs_predetermined[g, bld_yr, inst_yr],
    new_ccs_predetermined[g, bld_yr, inst_yr],
)
elseif g in CAPACITY_LIMITED_GENS
return (0, gen_capacity_limit_mw[g])
else
return (0, Inf)
end
end

@variable(mod, RetireGEN[(g, bld_yr, inst_yr) in GEN_BLD_INST_YRS] >= 0)

@variable(mod, NewRetireGEN[(g, bld_yr, inst_yr) in GEN_BLD_INST_YRS] >= 0)

@constraint(mod, Kept_NewRetireGEN_GasBio[(g, bld_yr, period) in GEN_BLD_INST_YRS; gen_energy_source[g] in ["Biomass", "Gas"]], RetireGEN[(g, bld_yr, period)] == 0)

@constraint(mod, Kept_NewRetireGEN_no1yr[(g, bld_yr, period) in NEW_GEN_BLD_INST_YRS; period > max(start_period, bld_yr)], RetireGEN[(g, bld_yr, period_prev[period])] + NewRetireGEN[(g, bld_yr, period)] == RetireGEN[(g, bld_yr, period)])

@constraint(mod, Kept_NewRetireGEN_1yr[(g, bld_yr, period) in NEW_GEN_BLD_INST_YRS; period == max(start_period, bld_yr)], NewRetireGEN[(g, bld_yr, period)] == RetireGEN[(g, bld_yr, period)])

@variable(mod, CCSGEN[(g, bld_yr, inst_yr) in GEN_BLD_INST_YRS], start=bounds_CCSGen(g, bld_yr, inst_yr)[1], lower_bound=bounds_CCSGen(g, bld_yr, inst_yr)[1], upper_bound=bounds_CCSGen(g, bld_yr, inst_yr)[2])

@variable(mod, NewCCSGEN[(g, bld_yr, inst_yr) in GEN_BLD_INST_YRS], start=bounds_NewCCSGen(g, bld_yr, inst_yr)[1], lower_bound=bounds_NewCCSGen(g, bld_yr, inst_yr)[1], upper_bound=bounds_NewCCSGen(g, bld_yr, inst_yr)[2])

@constraint(mod, Kept_NewCCSGEN_no1yr[(g, bld_yr, period) in NEW_GEN_BLD_INST_YRS; period > max(start_period, bld_yr)], CCSGEN[(g, bld_yr, period_prev[period])] + NewCCSGEN[(g, bld_yr, period)] == CCSGEN[(g, bld_yr, period)])

@constraint(mod, Kept_NewCCSGEN_1yr[(g, bld_yr, period) in NEW_GEN_BLD_INST_YRS; period == max(start_period, bld_yr)], NewCCSGEN[(g, bld_yr, period)] == CCSGEN[(g, bld_yr, period)])

@constraint(mod, Kept_CCSGEN[(g, bld_yr, period) in GEN_BLD_INST_YRS], CCSGEN[(g, bld_yr, period)] + RetireGEN[(g, bld_yr, period)] <= BuildGen[(g, bld_yr)])

function GenCapacityNOCCS_func(g, period)
if length(BLD_YRS_FOR_GEN_PERIOD[g, period]) == 0
GenCapacityNOCCS = 0
else
if g in CCS_GENS
    GenCapacityNOCCS = sum(BuildGen[(g, bld_yr)] - RetireGEN[(g, bld_yr, period)] - CCSGEN[(g, bld_yr, period)] for bld_yr in BLD_YRS_FOR_GEN_PERIOD[g, period])
else
    GenCapacityNOCCS = sum(BuildGen[(g, bld_yr)] for bld_yr in BLD_YRS_FOR_GEN_PERIOD[(g, period)])
end
end
return GenCapacityNOCCS
end
@expression(mod, GenCapacityNOCCS[g in GENERATION_PROJECTS, period in PERIODS], GenCapacityNOCCS_func(g, period))

function GenCapacityCCS_func(g, period)
if length(BLD_YRS_FOR_GEN_PERIOD[g, period]) == 0
GenCapacityCCS = 0
else
if g in CCS_GENS
    GenCapacityCCS = sum(CCSGEN[(g, bld_yr, period)] for bld_yr in BLD_YRS_FOR_GEN_PERIOD[g, period])
else
    GenCapacityCCS = 0
end
end
return GenCapacityCCS
end

@expression(mod, GenCapacityCCS[g in GENERATION_PROJECTS, period in PERIODS], GenCapacityCCS_func(g, period))
@expression(mod, GenCapacity[g in GENERATION_PROJECTS, period in PERIODS], GenCapacityCCS[g, period] + GenCapacityNOCCS[g, period])

@constraint(mod, Max_Build_Potential[g in CAPACITY_LIMITED_GENS, p in PERIODS], gen_capacity_limit_mw[g] >= GenCapacity[g, p])

NEW_GEN_WITH_MIN_BUILD = Set([g for (g, p) in NEW_GEN_BLD_YRS if gen_min_build_capacity[g] > 0])
NEW_GEN_WITH_MIN_BUILD_YEARS = [(g, p) for (g, p) in NEW_GEN_BLD_YRS if gen_min_build_capacity[g] > 0]
@variable(mod, BuildMinGenCap[(g, p) in NEW_GEN_WITH_MIN_BUILD_YEARS], Bin)
@constraint(mod, Enforce_Min_Build_Lower[(g, p) in NEW_GEN_WITH_MIN_BUILD_YEARS], BuildMinGenCap[(g, p)]  * gen_min_build_capacity[g] <= BuildGen[(g, p)])

_gen_max_cap_for_binary_constraints = 1e9
@constraint(mod, Enforce_Min_Build_Upper[(g, p) in NEW_GEN_WITH_MIN_BUILD_YEARS], BuildMinGenCap[(g, p)]  * _gen_max_cap_for_binary_constraints >= BuildGen[(g, p)])

# Costs
gen_variable_om = Dict(a => convert(Float64, df_gen_info.gen_variable_om[i]) for (i, a) in enumerate(GENERATION_PROJECTS))
ccs_variable_om = replace(df_gen_info.ccs_variable_om, "." => "0")
ccs_variable_om = Dict(a => parse(Float64, ccs_variable_om[i]) for (i, a) in enumerate(GENERATION_PROJECTS))
ccs_storage_cost = Dict(a => df_gen_info.ccs_storage_cost[i] for (i, a) in enumerate(GENERATION_PROJECTS))
ccs_transport_cost = Dict(a => df_gen_info.ccs_transport_cost[i] for (i, a) in enumerate(GENERATION_PROJECTS))
gen_connect_cost_per_mw = Dict(a => df_gen_info.gen_connect_cost_per_mw[i] for (i, a) in enumerate(GENERATION_PROJECTS))

gen_overnight_cost = Dict(a => df_gen_build_costs.gen_overnight_cost[i] for (i, a) in enumerate(GEN_BLD_YRS))
gen_fixed_om = Dict(a => df_gen_build_costs.gen_fixed_om[i] for (i, a) in enumerate(GEN_BLD_YRS))
ccs_overnight_cost = Dict(a => df_ccs_install_costs.ccs_overnight_cost[i] for (i, a) in enumerate(GEN_BLD_INST_YRS))
ccs_fixed_om = Dict(a => df_ccs_install_costs.ccs_fixed_om[i] for (i, a) in enumerate(GEN_BLD_INST_YRS))

gen_capital_cost_annual = Dict((g, bld_yr) => (gen_overnight_cost[(g, bld_yr)] + gen_connect_cost_per_mw[g]) * crf(interest_rate, gen_max_age[g]) for (g, bld_yr) in GEN_BLD_YRS)

ccs_capital_cost_annual = Dict((g, bld_yr, inst_yr) => ccs_overnight_cost[(g, bld_yr, inst_yr)] * crf(interest_rate, gen_max_age[g] + bld_yr - inst_yr) + ccs_fixed_om[g, bld_yr, inst_yr] for (g, bld_yr, inst_yr) in GEN_BLD_INST_YRS)

# GenCapitalCosts
@expression(mod, GenCapitalCosts[g in GENERATION_PROJECTS, p in PERIODS], sum(BuildGen[(g, bld_yr)] * gen_capital_cost_annual[(g, bld_yr)] for bld_yr in BLD_YRS_FOR_GEN_PERIOD[g, p]))

@expression(mod, GenFixedOMCosts_CCS[g in CCS_GENS, p in PERIODS], sum((BuildGen[(g, bld_yr)] - RetireGEN[(g, bld_yr, p)]) * gen_fixed_om[(g, bld_yr)] for bld_yr in BLD_YRS_FOR_GEN_PERIOD[g, p]))

@expression(mod, GenFixedOMCosts_NOCCS[g in NOCCS_GENS, p in PERIODS], sum(BuildGen[(g, bld_yr)] * gen_fixed_om[(g, bld_yr)] for bld_yr in BLD_YRS_FOR_GEN_PERIOD[g, p]))

@expression(mod, CCSFixedCosts[g in CCS_GENS, p in PERIODS], sum(sum(NewCCSGEN[(g, bld_yr, inst_yr)] * ccs_capital_cost_annual[(g, bld_yr, p)] for inst_yr in INST_YRS_FOR_GEN_BLD_YRS_PERIOD[(g, bld_yr, p)]) for bld_yr in BLD_YRS_FOR_GEN_PERIOD[g, p]))

@expression(mod, TotalGenFixedCosts[p in PERIODS], sum(GenCapitalCosts[g, p] for g in GENERATION_PROJECTS) + sum(CCSFixedCosts[g, p] + GenFixedOMCosts_CCS[g, p] for g in CCS_GENS) + sum(GenFixedOMCosts_NOCCS[g, p] for g in NOCCS_GENS))

# ---------------------------------------------
# 6 economic dispatch of generators
# ---------------------------------------------
function GENS_IN_PERIOD_init(PERIODS)
GENS_IN_PERIOD_dict = Dict(p => [] for p in PERIODS)
for (gen, p) in GEN_PERIODS
push!(GENS_IN_PERIOD_dict[p], gen)
end
return GENS_IN_PERIOD_dict
end
GENS_IN_PERIOD = GENS_IN_PERIOD_init(PERIODS)
TPS_FOR_GEN = Dict(g => Set([tp for p in PERIODS_FOR_GEN[g] for tp in TPS_IN_PERIOD[p]]) for g in GENERATION_PROJECTS)

function TPS_FOR_GEN_IN_PERIOD_init(GENERATION_PROJECTS, PERIODS)
TPS_FOR_GEN_IN_PERIOD_dict = Dict((g, p) => [] for g in GENERATION_PROJECTS for p in PERIODS)
for g in GENERATION_PROJECTS
for t in TPS_FOR_GEN[g]
    push!(TPS_FOR_GEN_IN_PERIOD_dict[(g, tp_period[t])], t)
end
end
return TPS_FOR_GEN_IN_PERIOD_dict
end
TPS_FOR_GEN_IN_PERIOD = TPS_FOR_GEN_IN_PERIOD_init(GENERATION_PROJECTS, PERIODS)

GEN_TPS = [(g, tp) for g in GENERATION_PROJECTS for tp in TPS_FOR_GEN[g]]
VARIABLE_GEN_TPS = [(g, tp) for g in VARIABLE_GENS for tp in TPS_FOR_GEN[g]]
FUEL_BASED_GEN_TPS = [(g, tp) for g in FUEL_BASED_GENS for tp in TPS_FOR_GEN[g]]
GEN_TP_FUELS = [(g, t, f) for (g, t) in FUEL_BASED_GEN_TPS for f in FUELS_FOR_GEN[g]]

@expression(mod, GenCapacityNOCCSInTP[(g, t) in GEN_TPS], GenCapacityNOCCS[g, tp_period[t]])
@expression(mod, GenCapacityCCSInTP[(g, t) in GEN_TPS], GenCapacityCCS[g, tp_period[t]])
@expression(mod, GenCapacityInTP[(g, t) in GEN_TPS], GenCapacityNOCCSInTP[(g, t)] + GenCapacityCCSInTP[(g, t)])
@variable(mod, DispatchGenNOCCS[(g, t) in GEN_TPS]>=0)
@variable(mod, DispatchGenCCS[(g, t) in GEN_TPS]>=0)
@expression(mod, DispatchGen[(g, t) in GEN_TPS], DispatchGenNOCCS[(g, t)] + DispatchGenCCS[(g, t)] * (1 - gen_ccs_energy_load[(gen_tech[g], tp_period[t])]))
@expression(mod, ZoneTotalCentralDispatch[z in LOAD_ZONES, t in TIMEPOINTS], sum(DispatchGen[(p, t)] for p in GENS_IN_ZONE[z] if ((tp_period[t] in PERIODS_FOR_GEN[p]) & (gen_is_distributed[p] == false))))

function gen_availability_init(GENERATION_PROJECTS)
gen_availability_dict = Dict()
for g in GENERATION_PROJECTS
if gen_is_baseload[g]
    gen_availability_dict[g] = (1 - gen_forced_outage_rate[g]) * (1 - gen_scheduled_outage_rate[g])
elseif gen_is_flexible_baseload[g]
    gen_availability_dict[g] = (1 - gen_forced_outage_rate[g]) * (1 - gen_scheduled_outage_rate[g])
else
    gen_availability_dict[g] = 1 - gen_forced_outage_rate[g]
end
end
return gen_availability_dict
end
gen_availability = gen_availability_init(GENERATION_PROJECTS)

VARIABLE_GEN_TPS_RAW = [(g, p) for (g, p) in eachrow(Array(df_variable_capacity_factors[!, [:GENERATION_PROJECT, :timepoint]]))]
gen_max_capacity_factor = Dict(a => df_variable_capacity_factors.gen_max_capacity_factor[i] for (i, a) in enumerate(VARIABLE_GEN_TPS_RAW))

@variable(mod, GenFuelUseRateNOCCS[(g, t, f) in GEN_TP_FUELS] >= 0)
@variable(mod, GenFuelUseRateCCS[(g, t, f) in GEN_TP_FUELS] >= 0)

@expression(mod, DispatchEmissions[(g, t, f) in GEN_TP_FUELS], ifelse(g in CCS_GENS, GenFuelUseRateCCS[(g, t, f)] * (f_co2_intensity[f] * (1 - gen_ccs_capture_efficiency[g]) + f_upstream_co2_intensity[f]) + GenFuelUseRateNOCCS[(g, t, f)] * (f_co2_intensity[f] + f_upstream_co2_intensity[f]), GenFuelUseRateNOCCS[(g, t, f)] * (f_co2_intensity[f] + f_upstream_co2_intensity[f])))

@expression(mod, AnnualEmissions[period in PERIODS], sum(DispatchEmissions[(g, t, f)] * tp_weight_in_year[t] for (g, t, f) in GEN_TP_FUELS if tp_period[t] == period))

@expression(mod, GenVariableOMCostsInTP[t in TIMEPOINTS], sum(DispatchGen[(g, t)] * gen_variable_om[g] for g in GENS_IN_PERIOD[tp_period[t]]))

@expression(mod, CCSVariableOMCostsInTP[t in TIMEPOINTS], sum(DispatchGenCCS[(g, t)] * ccs_variable_om[g] for g in GENS_IN_PERIOD[tp_period[t]]) + sum(sum(GenFuelUseRateCCS[(g, t, f)] * f_co2_intensity[f] * gen_ccs_capture_efficiency[g] * (ccs_storage_cost[g] + ccs_transport_cost[g]) for f in FUELS_FOR_GEN[g]) for g in GENS_IN_PERIOD[tp_period[t]] if gen_uses_fuel[g]))

# ---------------------------------------------
# 7 local transmission and distribution
# ---------------------------------------------
existing_local_td = Dict(a => df_load_zones.existing_local_td[i] for (i, a) in enumerate(LOAD_ZONES))
@variable(mod, BuildLocalTD[(z, p) in ZONE_PERIODS] >= 0)
@expression(mod, LocalTDCapacity[(z, period) in ZONE_PERIODS], existing_local_td[z] + sum(BuildLocalTD[(z, bld_yr)] for bld_yr in CURRENT_AND_PRIOR_PERIODS_FOR_PERIOD[period]))
local_td_loss_rate = Dict(a => 0.053 for (i, a) in enumerate(LOAD_ZONES))
@constraint(mod, Meet_Local_TD[(z, period) in ZONE_PERIODS], (LocalTDCapacity[(z, period)] * (1 - local_td_loss_rate[z]) >= zone_expected_coincident_peak_demand[(z, period)]))
local_td_annual_cost_per_mw = Dict(a => df_load_zones.local_td_annual_cost_per_mw[i] for (i, a) in enumerate(LOAD_ZONES))
@expression(mod, LocalTDFixedCosts[p in PERIODS], sum(LocalTDCapacity[(z, p)] * local_td_annual_cost_per_mw[z] for z in LOAD_ZONES))
@variable(mod, WithdrawFromCentralGrid[(z, t) in ZONE_TIMEPOINTS] >= 0)
@constraint(mod, Enforce_Local_TD_Capacity_Limit[(z, t) in ZONE_TIMEPOINTS], WithdrawFromCentralGrid[(z, t)] <= LocalTDCapacity[(z, tp_period[t])])
@expression(mod, InjectIntoDistributedGrid[(z, t) in ZONE_TIMEPOINTS], WithdrawFromCentralGrid[(z, t)] * (1 - local_td_loss_rate[z]))

# ---------------------------------------------
# 8 unit commitment of generators
# ---------------------------------------------
@variable(mod, CommitGenCCS[(g, t) in GEN_TPS]>=0)
@variable(mod, CommitGenNOCCS[(g, t) in GEN_TPS]>=0)
@expression(mod, CommitGen[(g, t) in GEN_TPS], CommitGenCCS[(g, t)] + CommitGenNOCCS[(g, t)])

gen_max_commit_fraction = Dict((g, t) => 1.0 for (g, t) in GEN_TPS)
gen_min_commit_fraction = Dict((g, t) => ifelse(g in BASELOAD_GENS, gen_max_commit_fraction[(g, t)], 0.0) for (g, t) in GEN_TPS)

@expression(mod, CommitCCSLowerLimit[(g, t) in GEN_TPS], (
GenCapacityCCSInTP[(g, t)]
* gen_availability[g]
* gen_min_commit_fraction[(g, t)]
))
@expression(mod, CommitNOCCSLowerLimit[(g, t) in GEN_TPS], (
GenCapacityNOCCSInTP[(g, t)]
* gen_availability[g]
* gen_min_commit_fraction[(g, t)]
))
@expression(mod, CommitCCSUpperLimit[(g, t) in GEN_TPS], (
GenCapacityCCSInTP[(g, t)]
* gen_availability[g]
* gen_max_commit_fraction[(g, t)]
))
@expression(mod, CommitNOCCSUpperLimit[(g, t) in GEN_TPS], (
GenCapacityNOCCSInTP[(g, t)]
* gen_availability[g]
* gen_max_commit_fraction[(g, t)]
))
@expression(mod, CommitUpperLimit[(g, t) in GEN_TPS], CommitCCSUpperLimit[(g, t)] + CommitNOCCSUpperLimit[(g, t)])
@expression(mod, CommitLowerLimit[(g, t) in GEN_TPS], CommitCCSLowerLimit[(g, t)] + CommitNOCCSLowerLimit[(g, t)])
@constraint(mod, Enforce_CommitCCS_Lower_Limit[(g, t) in GEN_TPS], (CommitCCSLowerLimit[(g, t)] <= CommitGenCCS[(g, t)]))
@constraint(mod, Enforce_CommitNOCCS_Lower_Limit[(g, t) in GEN_TPS], (CommitNOCCSLowerLimit[(g, t)] <= CommitGenNOCCS[(g, t)]))
@constraint(mod, Enforce_CommitCCS_Upper_Limit[(g, t) in GEN_TPS], (CommitGenCCS[(g, t)] <= CommitCCSUpperLimit[(g, t)]))
@constraint(mod, Enforce_CommitNOCCS_Upper_Limit[(g, t) in GEN_TPS], (CommitGenNOCCS[(g, t)] <= CommitNOCCSUpperLimit[(g, t)]))
@expression(mod, CommitSlackUp[(g, t) in GEN_TPS], (CommitUpperLimit[(g, t)] - CommitGen[(g, t)]))
@expression(mod, CommitSlackDown[(g, t) in GEN_TPS], (CommitGen[(g, t)] - CommitLowerLimit[(g, t)]))
@variable(mod, StartupGenCapacity[(g, t) in GEN_TPS] >= 0)
@variable(mod, ShutdownGenCapacity[(g, t) in GEN_TPS] >= 0)
@constraint(mod, Commit_StartupGenCapacity_ShutdownGenCapacity_Consistency[(g, t) in GEN_TPS], (CommitGen[(g, tp_previous_commit[t])] + StartupGenCapacity[(g, t)] - ShutdownGenCapacity[(g, t)] == CommitGen[(g, t)]))

gen_startup_fuel = Dict(a => 0.0 for (i, a) in enumerate(GENERATION_PROJECTS))
gen_startup_om = Dict(a => parse(Float64, replace(df_gen_info.gen_startup_om, "." => "0")[i]) for (i, a) in enumerate(GENERATION_PROJECTS))
@expression(mod, Total_StartupGenCapacity_OM_Costs[t in TIMEPOINTS], sum(gen_startup_om[g] * StartupGenCapacity[(g, t)] / tp_duration_hrs[t] for g in GENS_IN_PERIOD[tp_period[t]]))

gen_min_uptime = Dict(a => parse(Float64, replace(df_gen_info.gen_min_uptime, "." => "0")[i]) for (i, a) in enumerate(GENERATION_PROJECTS))
gen_min_downtime = Dict(a => parse(Float64, replace(df_gen_info.gen_min_downtime, "." => "0")[i]) for (i, a) in enumerate(GENERATION_PROJECTS))

function hrs_to_num_tps(hrs, t)
return Int(round(hrs / ts_duration_of_tp[tp_ts[t]]))
end

function time_window(t, hrs, add_one=false)
n = hrs_to_num_tps(hrs, t)
if add_one == true
n += 1
end
window = [prevw(t, i) for i in 1:n]
return window
end

UPTIME_CONSTRAINED_GEN_TPS = [
(g, t)
for g in GENERATION_PROJECTS
if gen_min_uptime[g] > 0.0
for t in TPS_FOR_GEN[g]
if hrs_to_num_tps(gen_min_uptime[g], t) > 0
]

DOWNTIME_CONSTRAINED_GEN_TPS = [
(g, t)
for g in GENERATION_PROJECTS
if gen_min_downtime[g] > 0.0
for t in TPS_FOR_GEN[g]
if hrs_to_num_tps(gen_min_downtime[g], t) > 0
]

@constraint(mod, Enforce_Min_Uptime[(g, t) in UPTIME_CONSTRAINED_GEN_TPS], CommitGen[(g, t)] >= sum(StartupGenCapacity[(g, t_prior)] for t_prior in time_window(t, gen_min_uptime[g])))

@constraint(mod, Enforce_Min_Downtime[(g, t) in DOWNTIME_CONSTRAINED_GEN_TPS], CommitGen[(g, t)] <= (GenCapacityInTP[(g, t)] * gen_availability[g] * maximum(gen_max_commit_fraction[(g, t_prior)] for t_prior in time_window(t, gen_min_downtime[g], true))) - sum(ShutdownGenCapacity[(g, t_prior)] for t_prior in time_window(t, gen_min_downtime[g])))

gen_min_load_fraction = Dict(a => df_gen_info.gen_min_load_fraction[i] for (i, a) in enumerate(GENERATION_PROJECTS))
gen_min_load_fraction_TP = Dict((g, t) => gen_min_load_fraction[g] for (g, t) in GEN_TPS)
@expression(mod, DispatchCCSLowerLimit[(g, t) in GEN_TPS], CommitGenCCS[(g, t)] * gen_min_load_fraction_TP[(g, t)])
@expression(mod, DispatchNOCCSLowerLimit[(g, t) in GEN_TPS], CommitGenNOCCS[(g, t)] * gen_min_load_fraction_TP[(g, t)])

function DispatchCCSUpperLimit_expr(g, t)
if g in VARIABLE_GENS
return CommitGenCCS[(g, t)] * gen_max_capacity_factor[(g, t)]
else
return CommitGenCCS[(g, t)]
end
end

function DispatchNOCCSUpperLimit_expr(g, t)
if g in VARIABLE_GENS
return CommitGenNOCCS[(g, t)] * gen_max_capacity_factor[(g, t)]
else
return CommitGenNOCCS[(g, t)]
end
end

@expression(mod, DispatchCCSUpperLimit[(g, t) in GEN_TPS], DispatchCCSUpperLimit_expr(g, t))
@expression(mod, DispatchNOCCSUpperLimit[(g, t) in GEN_TPS], DispatchNOCCSUpperLimit_expr(g, t))
@expression(mod, DispatchUpperLimit[(g, t) in GEN_TPS], DispatchNOCCSUpperLimit[(g, t)] + DispatchCCSUpperLimit[(g, t)])
@expression(mod, DispatchLowerLimit[(g, t) in GEN_TPS], DispatchNOCCSLowerLimit[(g, t)] + DispatchCCSLowerLimit[(g, t)])
@constraint(mod, Enforce_DispatchCCS_Lower_Limit[(g, t) in GEN_TPS], DispatchCCSLowerLimit[(g, t)] <= DispatchGenCCS[(g, t)])
@constraint(mod, Enforce_DispatchNOCCS_Lower_Limit[(g, t) in GEN_TPS], (DispatchNOCCSLowerLimit[(g, t)] <= DispatchGenNOCCS[(g, t)]))
@constraint(mod, Enforce_DispatchCCS_Upper_Limit[(g, t) in GEN_TPS], (DispatchGenCCS[(g, t)] <= DispatchCCSUpperLimit[(g, t)]))
@constraint(mod, Enforce_DispatchNOCCS_Upper_Limit[(g, t) in GEN_TPS], (DispatchGenNOCCS[(g, t)] <= DispatchNOCCSUpperLimit[(g, t)]))
@expression(mod, DispatchSlackUp[(g, t) in GEN_TPS], DispatchUpperLimit[(g, t)] - DispatchGen[(g, t)])
@expression(mod, DispatchSlackDown[(g, t) in GEN_TPS], DispatchGen[(g, t)] - DispatchLowerLimit[(g, t)])

# ---------------------------------------------
# 9 fuel use of generators
# ---------------------------------------------
@constraint(mod, GenFuelUseRateNOCCS_Calculate[(g, t) in FUEL_BASED_GEN_TPS], sum(GenFuelUseRateNOCCS[(g, t, f)] for f in FUELS_FOR_GEN[g]) == gen_full_load_heat_rate[g] * DispatchGenNOCCS[(g, t)])

@constraint(mod, GenFuelUseRateCCS_Calculate[(g, t) in FUEL_BASED_GEN_TPS], sum(GenFuelUseRateCCS[(g, t, f)] for f in FUELS_FOR_GEN[g]) == gen_full_load_heat_rate[g] * DispatchGenCCS[(g, t)])

@expression(mod, GenFuelUseRate[(g, t, f) in GEN_TP_FUELS], GenFuelUseRateCCS[(g, t, f)] + GenFuelUseRateNOCCS[(g, t, f)])

# ---------------------------------------------
# 10 hydropower dispatch
# ---------------------------------------------
HYDRO_GEN_TS_RAW = [(g, t) for (g, t) in eachrow(Array(df_hydro_timeseries[!, [:hydro_project, :timeseries]]))]
HYDRO_GENS = Set(df_hydro_timeseries.hydro_project)
HYDRO_GEN_TS = Set([(g, tp_ts[tp]) for g in HYDRO_GENS for tp in TPS_FOR_GEN[g]])
HYDRO_GEN_TPS = [(g, t) for (g, t) in GEN_TPS if g in HYDRO_GENS]
hydro_min_flow_per_mw = Dict(a => df_hydro_timeseries.hydro_min_flow_per_mw[i] for (i, a) in enumerate(HYDRO_GEN_TS_RAW))
hydro_avg_flow_per_mw = Dict(a => df_hydro_timeseries.hydro_avg_flow_per_mw[i] for (i, a) in enumerate(HYDRO_GEN_TS_RAW))
@constraint(mod, Enforce_Hydro_Min_Flow[(g, t) in HYDRO_GEN_TPS], DispatchGen[(g, t)] >= hydro_min_flow_per_mw[(g, tp_ts[t])] * GenCapacityInTP[(g, t)])
@variable(mod, SpillHydro[(g, t) in HYDRO_GEN_TPS] >= 0)
@constraint(mod, Enforce_Hydro_Avg_Flow[g in HYDRO_GENS, ts in TIMESERIES], sum(DispatchGen[(g, t)] + SpillHydro[(g, t)] for t in TPS_IN_TS[ts]) == hydro_avg_flow_per_mw[g, ts] * GenCapacity[g, ts_period[ts]] * ts_num_tps[ts])

# ---------------------------------------------
# 11 energy storage technology charge decisions
# ---------------------------------------------
STORAGE_GENS = GENERATION_PROJECTS[df_gen_info.gen_storage_efficiency .!= "."]
STORAGE_GEN_PERIODS = [(g, p) for g in STORAGE_GENS for p in PERIODS_FOR_GEN[g]]
gen_storage_efficiency = Dict(g => parse(Float64, df_gen_info.gen_storage_efficiency[i]) for (i, g) in enumerate(GENERATION_PROJECTS) if g in STORAGE_GENS)
gen_store_to_release_ratio = Dict(g => 1.0 for g in STORAGE_GENS)
gen_storage_energy_to_power_ratio = replace(df_gen_info.gen_storage_energy_to_power_ratio, "." => Inf64)
function parser_mod(v)
if typeof(v) == Float64
return convert(Float64, v)
elseif typeof(v) == Int
return convert(Float64, v)
else
return parse(Float64, v)
end
end
gen_storage_energy_to_power_ratio = Dict(g => parser_mod(gen_storage_energy_to_power_ratio[i]) for (i, g) in enumerate(GENERATION_PROJECTS) if g in STORAGE_GENS)
gen_storage_max_cycles_per_year = Dict(g => Inf64 for g in STORAGE_GENS)
STORAGE_GEN_BLD_YRS = [(g, bld_yr) for (g, bld_yr) in GEN_BLD_YRS if g in STORAGE_GENS]
PREDETERMINED_STORAGE_GEN_BLD_YRS = [(g, bld_yr) for (g, bld_yr) in PREDETERMINED_GEN_BLD_YRS if g in STORAGE_GENS]
gen_storage_energy_overnight_cost = Dict((g, bld_yr) => parser_mod(replace(df_gen_build_costs.gen_storage_energy_overnight_cost, "." => "0.0")[i]) for (i, (g, bld_yr)) in enumerate(GEN_BLD_YRS) if g in STORAGE_GENS)
build_gen_energy_predetermined = Dict((g, bld_yr) => parser_mod(replace(df_gen_build_predetermined.build_gen_energy_predetermined, "." => "0.0")[i]) for (i, (g, bld_yr)) in enumerate(PREDETERMINED_GEN_BLD_YRS) if g in STORAGE_GENS)

function bounds_BuildStorageEnergy(g, bld_yr)
if (g, bld_yr) in PREDETERMINED_STORAGE_GEN_BLD_YRS
return (
    build_gen_energy_predetermined[g, bld_yr],
    build_gen_energy_predetermined[g, bld_yr],
)
else
return (0, Inf64)
end
end

@variable(mod, BuildStorageEnergy[(g, bld_yr) in STORAGE_GEN_BLD_YRS], start=bounds_BuildStorageEnergy(g, bld_yr)[1], lower_bound=bounds_BuildStorageEnergy(g, bld_yr)[1], upper_bound=bounds_BuildStorageEnergy(g, bld_yr)[2])

@expression(mod, StorageEnergyCapitalCost[g in STORAGE_GENS, p in PERIODS], sum(
BuildStorageEnergy[(g, bld_yr)]
* gen_storage_energy_overnight_cost[(g, bld_yr)]
* crf(interest_rate, gen_max_age[g])
for bld_yr in BLD_YRS_FOR_GEN_PERIOD[g, p]
))

@expression(mod, StorageEnergyFixedCost[p in PERIODS], sum(StorageEnergyCapitalCost[g, p] for g in STORAGE_GENS))

@expression(mod, StorageEnergyCapacity[g in STORAGE_GENS, period in PERIODS], sum(
BuildStorageEnergy[(g, bld_yr)]
for bld_yr in BLD_YRS_FOR_GEN_PERIOD[g, period]
))

STORAGE_GEN_TPS = [(g, tp) for g in STORAGE_GENS for tp in TPS_FOR_GEN[g]]

@variable(mod, ChargeStorage[(g, tp) in STORAGE_GEN_TPS] >= 0)

Storage_Charge_Summation_dict = Dict()
for (g, t2) in STORAGE_GEN_TPS
z2 = gen_load_zone[g]
Storage_Charge_Summation_dict[(z2, t2)] = []
end
for (g, t2) in STORAGE_GEN_TPS
z2 = gen_load_zone[g]
push!(Storage_Charge_Summation_dict[(z2, t2)], g)
end

@expression(mod, StorageNetCharge[z in LOAD_ZONES, t in TIMEPOINTS], sum(ChargeStorage[(g, t)] for g in Storage_Charge_Summation_dict[(z, t)]))

@constraint(mod, Enforce_Fixed_Energy_Storage_Ratio[(g, y) in STORAGE_GEN_BLD_YRS; gen_storage_energy_to_power_ratio[g] != Inf64], BuildStorageEnergy[(g, y)] == gen_storage_energy_to_power_ratio[g] * BuildGen[(g, y)])

@constraint(mod, Charge_Storage_Upper_Limit[(g, t) in STORAGE_GEN_TPS], ChargeStorage[(g, t)] <= DispatchUpperLimit[(g, t)] * gen_store_to_release_ratio[g])

@variable(mod, StateOfCharge[(g, tp) in STORAGE_GEN_TPS] >= 0)
@constraint(mod, Track_State_Of_Charge[(g, t) in STORAGE_GEN_TPS], StateOfCharge[(g, t)] == StateOfCharge[(g, tp_previous[t])] + (ChargeStorage[(g, t)] * gen_storage_efficiency[g] - DispatchGen[(g, t)]) * tp_duration_hrs[t])

@constraint(mod, State_Of_Charge_Upper_Limit[(g, t) in STORAGE_GEN_TPS], StateOfCharge[(g, t)] <= StorageEnergyCapacity[g, tp_period[t]])

@constraint(mod, Battery_Cycle_Limit[(g, p) in STORAGE_GEN_PERIODS; gen_storage_max_cycles_per_year[g] != Inf64], sum(DispatchGen[(g, tp)] * tp_duration_hrs[tp] for tp in TPS_IN_PERIOD[p]) <= gen_storage_max_cycles_per_year[g] * StorageEnergyCapacity[(g, p)] * period_length_years[p])

# ---------------------------------------------
# 12. fuel costs
# ---------------------------------------------
REGIONAL_FUEL_MARKETS = df_regional_fuel_markets.regional_fuel_market
rfm_fuel = Dict(m => df_regional_fuel_markets.fuel[i] for (i, m) in enumerate(REGIONAL_FUEL_MARKETS))
ZONE_RFMS = [(z, m) for (z, m) in eachrow(Array(df_zone_to_regional_fuel_market[!, [:load_zone, :regional_fuel_market]]))]

function zone_fuel_rfm_init(load_zone, fuel)
# find first (only) matching rfm
for (z, rfm) in ZONE_RFMS
if (z == load_zone) & (fuel == rfm_fuel[rfm])
    return rfm
end
end
end

RFM_SUPPLY_TIERS = [(m, p, tr) for (m, p, tr) in eachrow(Array(df_fuel_supply_curves[!, [:regional_fuel_market, :period, :tier]]))]
rfm_supply_tier_cost = Dict((m, p, tr) => df_fuel_supply_curves.unit_cost[i] for (i, (m, p, tr)) in enumerate(RFM_SUPPLY_TIERS))
rfm_supply_tier_limit = Dict((m, p, tr) => df_fuel_supply_curves.max_avail_at_cost[i] for (i, (m, p, tr)) in enumerate(RFM_SUPPLY_TIERS))

for dat in eachrow(df_fuel_cost)
z = dat.load_zone
f = dat.fuel
p = Int(dat.period)
f_cost = Float64(dat.fuel_cost)
rfm = z * "_" * f
push!(REGIONAL_FUEL_MARKETS, rfm)
rfm_fuel[rfm] = f
push!(ZONE_RFMS, (z, rfm))
st = 0
push!(RFM_SUPPLY_TIERS, (rfm, p, st))
rfm_supply_tier_cost[(rfm, p, st)] = f_cost
rfm_supply_tier_limit[(rfm, p, st)] = Inf
end

REGIONAL_FUEL_MARKETS = unique(REGIONAL_FUEL_MARKETS)

ZONE_FUELS = [(z, rfm_fuel[rfm]) for (z, rfm) in ZONE_RFMS]
zone_fuel_rfm = Dict((load_zone, fuel) => zone_fuel_rfm_init(load_zone, fuel) for (load_zone, fuel) in ZONE_FUELS)
ZONES_IN_RFM = Dict(rfm => Set([z for (z, r) in ZONE_RFMS if r == rfm]) for rfm in REGIONAL_FUEL_MARKETS)

SUPPLY_TIERS_FOR_RFM_PERIOD = Dict((rfm, ip) => [(r, p, st) for (r, p, st) in RFM_SUPPLY_TIERS if (r == rfm) & (p == ip)] for rfm in REGIONAL_FUEL_MARKETS for ip in PERIODS)
@variable(mod, ConsumeFuelTier[rfm_supply_tier in RFM_SUPPLY_TIERS] >=0, upper_bound = ifelse(rfm_supply_tier_limit[rfm_supply_tier] != Inf64, rfm_supply_tier_limit[rfm_supply_tier], Inf64))

@expression(mod, FuelConsumptionInMarket[rfm in REGIONAL_FUEL_MARKETS, p in PERIODS], sum(ConsumeFuelTier[rfm_supply_tier] for rfm_supply_tier in SUPPLY_TIERS_FOR_RFM_PERIOD[(rfm, p)]))

function rfm_annual_costs(rfm, p)
return sum(ConsumeFuelTier[rfm_st] * rfm_supply_tier_cost[rfm_st] for rfm_st in SUPPLY_TIERS_FOR_RFM_PERIOD[rfm, p])
end
@expression(mod, FuelCostsPerPeriod[p in PERIODS], sum(rfm_annual_costs(rfm, p) for rfm in REGIONAL_FUEL_MARKETS))

function GENS_FOR_RFM_PERIOD_rule(REGIONAL_FUEL_MARKETS, PERIODS)
GENS_FOR_RFM_PERIOD_dict = Dict((rfm, p) => [] for rfm in REGIONAL_FUEL_MARKETS for p in PERIODS)
for p in PERIODS
for g in FUEL_BASED_GENS
    if g in GENS_IN_PERIOD[p]
        for f in FUELS_FOR_GEN[g]
            if (gen_load_zone[g], f) in ZONE_FUELS
                rfm = zone_fuel_rfm[(gen_load_zone[g], f)]
                push!(GENS_FOR_RFM_PERIOD_dict[(rfm, p)], g)
            end
        end
    end
end
end
return GENS_FOR_RFM_PERIOD_dict
end

GENS_FOR_RFM_PERIOD = GENS_FOR_RFM_PERIOD_rule(REGIONAL_FUEL_MARKETS, PERIODS)
@constraint(mod, Enforce_Fuel_Consumption[rfm in REGIONAL_FUEL_MARKETS, p in PERIODS], FuelConsumptionInMarket[rfm, p] == sum(GenFuelUseRate[(g, t, rfm_fuel[rfm])] * tp_weight_in_year[t] for g in GENS_FOR_RFM_PERIOD[(rfm, p)] for t in TPS_IN_PERIOD[p]))

@expression(mod, RFM_ANNUAL_COSTS[rfm in REGIONAL_FUEL_MARKETS, p in PERIODS], rfm_annual_costs(rfm, p))

# ---------------------------------------------
# 13 operating reserves requirement
# ---------------------------------------------
zone_balancing_area = Dict(a => df_load_zones.zone_balancing_area[i] for (i, a) in enumerate(LOAD_ZONES))
BALANCING_AREAS = Set([zone_balancing_area[z] for z in LOAD_ZONES])
ZONES_IN_BALANCING_AREA = Dict(a => [z for z in LOAD_ZONES if zone_balancing_area[z] == a] for a in BALANCING_AREAS)
BALANCING_AREA_TIMEPOINTS = [(a, tp) for a in BALANCING_AREAS for tp in TIMEPOINTS]

# ---------------------------------------------
# 14 spinning reserves requirement
# ---------------------------------------------
gen_can_provide_spinning_reserves = Dict(g => df_gen_info.gen_can_provide_spinning_reserves[i] for (i, g) in enumerate(GENERATION_PROJECTS))
SPINNING_RESERVE_GEN_TPS = [(g, t) for (g, t) in GEN_TPS if (gen_can_provide_spinning_reserves[g] == true) & (g in GENS_IN_PERIOD[tp_period[t]])]
gen_ramp_rate_10min = Dict(g => df_gen_info.gen_ramp_rate_10min[i] for (i, g) in enumerate(GENERATION_PROJECTS))

@variable(mod, CommitGenSpinningReserves[(g, t) in SPINNING_RESERVE_GEN_TPS]>=0)
@constraint(mod, CommitGenSpinningReserves_Limit[(g, t) in SPINNING_RESERVE_GEN_TPS; g ∈ STORAGE_GENS], CommitGenSpinningReserves[(g, t)] <= DispatchSlackUp[(g, t)] + ChargeStorage[(g, t)])

@constraint(mod, CommitGenSpinningReserves_Limit_ramprate[(g, t) in SPINNING_RESERVE_GEN_TPS; g ∈ STORAGE_GENS], CommitGenSpinningReserves[(g, t)] <= StateOfCharge[(g, t)] * 6)

@constraint(mod, CommitGenSpinningReserves_Limit_not_storage[(g, t) in SPINNING_RESERVE_GEN_TPS; g ∉ STORAGE_GENS], CommitGenSpinningReserves[(g, t)] <= DispatchSlackUp[(g, t)])

@constraint(mod, CommitGenSpinningReserves_Limit_not_storage_ramprate[(g, t) in SPINNING_RESERVE_GEN_TPS; g ∉ STORAGE_GENS], CommitGenSpinningReserves[(g, t)] <= gen_ramp_rate_10min[g] * DispatchUpperLimit[(g, t)])

@expression(mod, CommittedSpinningReserve[(b, t) in BALANCING_AREA_TIMEPOINTS], sum(CommitGenSpinningReserves[(g, t)] for z in ZONES_IN_BALANCING_AREA[b] for g in GENS_IN_ZONE[z] if (gen_can_provide_spinning_reserves[g] == true) & (length(TPS_FOR_GEN[g]) != 0)))

@expression(mod, VarGenSpinningReserveRequirement[(b, t) in BALANCING_AREA_TIMEPOINTS], 0.05 * sum(WithdrawFromCentralGrid[(z, t)] for z in LOAD_ZONES if b == zone_balancing_area[z]) + 0.10 * sum(DispatchGen[(g, t)] for g in BASELOAD_GENS if ((length(TPS_FOR_GEN[g]) != 0) & (b == zone_balancing_area[gen_load_zone[g]]))) + 0.30 * sum(DispatchGen[(g, t)] for g in VARIABLE_GENS if ((length(TPS_FOR_GEN[g]) != 0) & (b == zone_balancing_area[gen_load_zone[g]]))))

@constraint(mod, Satisfy_Spinning_Reserve_Requirement[(b, t) in BALANCING_AREA_TIMEPOINTS], VarGenSpinningReserveRequirement[(b, t)] <= CommittedSpinningReserve[(b, t)])

# ---------------------------------------------
# 14 planning reserves requirement
# ---------------------------------------------
PLANNING_RESERVE_REQUIREMENTS = df_planning_reserve_requirements.PLANNING_RESERVE_REQUIREMENTS
PRR_ZONES = [(g, p) for (g, p) in eachrow(Array(df_planning_reserve_requirement_zones[!, [:PLANNING_RESERVE_REQUIREMENTS, :LOAD_ZONE]]))]
prr_cap_reserve_margin = Dict(a => df_planning_reserve_requirements.prr_cap_reserve_margin[i] for (i, a) in enumerate(PLANNING_RESERVE_REQUIREMENTS))
# prr_cap_reserve_margin = Dict(a => 0.0 for (i, a) in enumerate(PLANNING_RESERVE_REQUIREMENTS))
prr_enforcement_timescale = Dict(a => df_planning_reserve_requirements.prr_enforcement_timescale[i] for (i, a) in enumerate(PLANNING_RESERVE_REQUIREMENTS))

function get_peak_timepoints(prr)
peak_timepoint_list = []
ZONES = [z for (_prr, z) in PRR_ZONES if _prr == prr]
for p in PERIODS
peak_timepoint = TPS_IN_PERIOD[p][1]
peak_load = 0.0
for t in TPS_IN_PERIOD[p]
    load = sum(zone_demand_mw[z, t] for z in ZONES)
    if load >= peak_load
        peak_timepoint = t
        peak_load = load
    end
end
push!(peak_timepoint_list, peak_timepoint)
end
return peak_timepoint_list
end

function PRR_TIMEPOINTS_init()
PRR_TIMEPOINTS = []
for prr in PLANNING_RESERVE_REQUIREMENTS
if prr_enforcement_timescale[prr] == "all_timepoints"
    push!(PRR_TIMEPOINTS, [(prr, t) for t in TIMEPOINTS][1])
elseif prr_enforcement_timescale[prr] == "peak_load"
    push!(PRR_TIMEPOINTS, [(prr, t) for t in get_peak_timepoints(prr)][1])
end
end
return PRR_TIMEPOINTS
end

PRR_TIMEPOINTS = PRR_TIMEPOINTS_init()

gen_can_provide_cap_reserves = Dict(a => true for a in GENERATION_PROJECTS)

function gen_capacity_value_default(g, t, variable_availability=true)
if gen_can_provide_cap_reserves[g] == false
return 0.0
elseif g in VARIABLE_GENS
    if variable_availability == true
        return min(1.0, gen_max_capacity_factor[g, t])
    else
        return 0
    end
else
return 1.0
end
end

gen_capacity_value = Dict((g, t) => gen_capacity_value_default(g, t) for (g, t) in GEN_TPS)

function zones_for_prr(prr)
return [z for (_prr, z) in PRR_ZONES if _prr == prr]
end

function AvailableReserveCapacity_rule(prr, t)
reserve_cap = 0.0
ZONES = zones_for_prr(prr)
GENS = [
g
for z in ZONES
for g in GENS_IN_ZONE[z]
if (length(TPS_FOR_GEN[g]) != 0) & gen_can_provide_cap_reserves[g]
]
for g in GENS
if g in STORAGE_GENS
    reserve_cap += DispatchGen[(g, t)] - ChargeStorage[(g, t)]
elseif gen_is_distributed[g]
    pass
else
    reserve_cap += gen_capacity_value[g, t] * GenCapacityInTP[(g, t)]
end
end
return reserve_cap
end

@expression(mod, AvailableReserveCapacity[(prr, t) in PRR_TIMEPOINTS], AvailableReserveCapacity_rule(prr, t))
function CapacityRequirements_rule(prr, t)
ZONES = zones_for_prr(prr)
return sum((1 + prr_cap_reserve_margin[prr]) * WithdrawFromCentralGrid[(z, t)]
for z in ZONES)
end

@expression(mod, CapacityRequirements[(prr, t) in PRR_TIMEPOINTS], CapacityRequirements_rule(prr, t))

# ---------------------------------------------
# 15 transmission line construction
# ---------------------------------------------
trans_capital_cost_per_mw_km = df_trans_params.trans_capital_cost_per_mw_km[1]
trans_lifetime_yrs = df_trans_params.trans_lifetime_yrs[1]
trans_fixed_om_fraction = df_trans_params.trans_fixed_om_fraction[1]
TRANSMISSION_LINES = df_transmission_lines.TRANSMISSION_LINE
trans_lz1 = Dict(a => df_transmission_lines.trans_lz1[i] for (i, a) in enumerate(TRANSMISSION_LINES))
trans_lz2 = Dict(a => df_transmission_lines.trans_lz2[i] for (i, a) in enumerate(TRANSMISSION_LINES))
trans_dbid = Dict(a => df_transmission_lines.trans_dbid[i] for (i, a) in enumerate(TRANSMISSION_LINES))
trans_length_km = Dict(a => df_transmission_lines.trans_length_km[i] for (i, a) in enumerate(TRANSMISSION_LINES))
trans_efficiency = Dict(a => df_transmission_lines.trans_efficiency[i] for (i, a) in enumerate(TRANSMISSION_LINES))
existing_trans_cap = Dict(a => df_transmission_lines.existing_trans_cap[i] for (i, a) in enumerate(TRANSMISSION_LINES))
trans_new_build_allowed = Dict(a => df_transmission_lines.trans_new_build_allowed[i] for (i, a) in enumerate(TRANSMISSION_LINES))
trans_new_build_cap = Dict(a => df_transmission_lines.trans_new_build_cap[i] for (i, a) in enumerate(TRANSMISSION_LINES))
trans_capital_cost_per_mw = Dict(a => df_transmission_lines.trans_capital_cost_per_mw[i] for (i, a) in enumerate(TRANSMISSION_LINES))
TRANS_BLD_YRS = [(tx, p) for tx in TRANSMISSION_LINES for p in PERIODS if trans_new_build_allowed[tx] == true]

@variable(mod, BuildTx[(tx, p) in TRANS_BLD_YRS] >= 0)
build_trans_limit_mw = Dict(a => df_build_tx_limits.build_trans_limit_mw[i] for (i, a) in enumerate(PERIODS))
@constraint(mod, Kept_BuildTx[p in PERIODS], sum(BuildTx[(tx, p)] for tx in TRANSMISSION_LINES) <= build_trans_limit_mw[p])
@expression(mod, TxCapacityNameplate[tx in TRANSMISSION_LINES, period in PERIODS], ifelse((tx, period) in TRANS_BLD_YRS, sum(BuildTx[(tx, bld_yr)] for bld_yr in PERIODS if bld_yr <= period) + existing_trans_cap[tx], existing_trans_cap[tx]))
@constraint(mod, Kept_TxCapacityCap[(tx, period) in TRANS_BLD_YRS], sum(BuildTx[(tx, bld_yr)] for bld_yr in PERIODS if bld_yr <= period) <= trans_new_build_cap[tx])
trans_derating_factor = Dict(a => 1.0 for a in TRANSMISSION_LINES)
@expression(mod, TxCapacityNameplateAvailable[tx in TRANSMISSION_LINES, period in PERIODS], (TxCapacityNameplate[tx, period] * trans_derating_factor[tx]))
trans_terrain_multiplier = Dict(a => 1.0 for a in TRANSMISSION_LINES)
trans_cost_annual = Dict(tx => (trans_capital_cost_per_mw[tx] * trans_terrain_multiplier[tx] * (crf(interest_rate, trans_lifetime_yrs) + trans_fixed_om_fraction)) for tx in TRANSMISSION_LINES)
@expression(mod, TxFixedCosts[p in PERIODS], sum(TxCapacityNameplate[tx, p] * trans_cost_annual[tx] for tx in TRANSMISSION_LINES))

function init_DIRECTIONAL_TX()
tx_dir = []
for tx in TRANSMISSION_LINES
push!(tx_dir, (trans_lz1[tx], trans_lz2[tx]))
push!(tx_dir, (trans_lz2[tx], trans_lz1[tx]))
end
return tx_dir
end
DIRECTIONAL_TX = init_DIRECTIONAL_TX()

TX_CONNECTIONS_TO_ZONE = Dict(lz => [z for z in LOAD_ZONES if (z, lz) in DIRECTIONAL_TX] for lz in LOAD_ZONES)

function init_trans_d_line(zone_from, zone_to)
for tx in TRANSMISSION_LINES
if ((trans_lz1[tx] == zone_from) & (trans_lz2[tx] == zone_to)) | (
    (trans_lz2[tx] == zone_from) & (trans_lz1[tx] == zone_to))
    return tx
end
end
end
trans_d_line = Dict((zone_from, zone_to) => init_trans_d_line(zone_from, zone_to) for (zone_from, zone_to) in DIRECTIONAL_TX)

# ---------------------------------------------
# 16 dispatch of transmission lines
# ---------------------------------------------
TRANS_TIMEPOINTS = [(zone_from, zone_to, t) for (zone_from, zone_to) in DIRECTIONAL_TX for t in TIMEPOINTS]

@variable(mod, DispatchTx[(zone_from, zone_to, t) in TRANS_TIMEPOINTS] >= 0)

@constraint(mod, Maximum_DispatchTx[(zone_from, zone_to, tp) in TRANS_TIMEPOINTS], DispatchTx[(zone_from, zone_to, tp)] <= TxCapacityNameplateAvailable[trans_d_line[zone_from, zone_to], tp_period[tp]])

@expression(mod, TxPowerSent[(zone_from, zone_to, tp) in TRANS_TIMEPOINTS], DispatchTx[(zone_from, zone_to, tp)])

@expression(mod, TxPowerReceived[(zone_from, zone_to, tp) in TRANS_TIMEPOINTS], DispatchTx[(zone_from, zone_to, tp)] * trans_efficiency[trans_d_line[zone_from, zone_to]])

function TXPowerNet_calculation(z, tp)
return sum(TxPowerReceived[(zone_from, z, tp)] for zone_from in TX_CONNECTIONS_TO_ZONE[z]) - sum(TxPowerSent[(z, zone_to, tp)] for zone_to in TX_CONNECTIONS_TO_ZONE[z])
end
@expression(mod, TXPowerNet[z in LOAD_ZONES, tp in TIMEPOINTS], TXPowerNet_calculation(z, tp))

# ---------------------------------------------
# 17 carbon policies
# ---------------------------------------------
carbon_cap_tco2_per_yr = Dict(a => df_carbon_policies.carbon_cap_tco2_per_yr[i] for (i, a) in enumerate(PERIODS))
carbon_cost_dollar_per_tco2 = Dict(a => df_carbon_policies.carbon_cost_dollar_per_tco2[i] for (i, a) in enumerate(PERIODS))
@constraint(mod, Enforce_Carbon_Cap[p in PERIODS], AnnualEmissions[p] <= carbon_cap_tco2_per_yr[p])
@expression(mod, EmissionCosts[p in PERIODS], AnnualEmissions[p] * carbon_cost_dollar_per_tco2[p])

# ---------------------------------------------
# 18 technology planning or limits
# ---------------------------------------------
TOTAL_CAPACITY_LIMIT_INDEX = [(e, p) for (e, p) in eachrow(Array(df_total_capacity_limits[!, [:energy_sources, :period]]))]

total_capacity_limit_mw = Dict((e, p) => subset(df_total_capacity_limits, :energy_sources => ByRow(==(e)), :period => ByRow(==(p)))[1, "total_capacity_limit_mw"] for (e, p) in TOTAL_CAPACITY_LIMIT_INDEX)

@expression(mod, TotalCapByEnergySource[(e, p) in TOTAL_CAPACITY_LIMIT_INDEX], sum(GenCapacity[g, p] for g in GENS_BY_ENERGY_SOURCE[e]))

@constraint(mod, Enforce_Total_Capacity_Limit[(e, p) in TOTAL_CAPACITY_LIMIT_INDEX], TotalCapByEnergySource[(e, p)] <= total_capacity_limit_mw[(e, p)])

CAPACITY_PLAN_INDEX = [(tc, r, p) for (tc, r, p) in eachrow(Array(df_capacity_plans[!, [:gen_tech, :load_zones, :period]]))]
capacity_plan_mw = Dict((tc, r, p) => subset(df_capacity_plans, :gen_tech => ByRow(==(tc)), :load_zones => ByRow(==(r)), :period => ByRow(==(p)))[1, "planned_capacity_mw"] for (tc, r, p) in CAPACITY_PLAN_INDEX)
@expression(mod, CapByTech[(tc, r, p) in CAPACITY_PLAN_INDEX], sum(GenCapacity[g, p] for g in GENS_BY_TECHNOLOGY[tc] if g in GENS_IN_ZONE[r]))
@constraint(mod, Enforce_Capacity_Plan[(tc, r, p) in CAPACITY_PLAN_INDEX], CapByTech[(tc, r, p)] >= capacity_plan_mw[(tc, r, p)])

# ---------------------------------------------
# 19 capacity factor policy on coal power
# ---------------------------------------------
@constraint(mod, Enforce_Capacity_Factor_Limits[(g, p) in GEN_PERIODS; (g in GENS_IN_PERIOD[p]) & (gen_energy_source[g] == "Coal")], sum(DispatchGen[(g, t)] * tp_weight_in_year[t] for t in TPS_FOR_GEN_IN_PERIOD[(g, p)]) >= hours_per_year * min_capacity_factor * GenCapacity[g, p])

# ---------------------------------------------
# 20 partial equilibrium of province-level electricity supply-demand both distribution and central
# ---------------------------------------------
@expression(mod, Zone_Power_Injections[(z, t) in ZONE_TIMEPOINTS], ZoneTotalCentralDispatch[z, t] + TXPowerNet[z, t])

@expression(mod, Zone_Power_Withdrawals[(z, t) in ZONE_TIMEPOINTS], WithdrawFromCentralGrid[(z,t)] + StorageNetCharge[z,t])

@constraint(mod, Zone_Energy_Balance[(z, t) in ZONE_TIMEPOINTS], Zone_Power_Injections[(z, t)] == Zone_Power_Withdrawals[(z, t)])

@expression(mod, Distributed_Power_Withdrawals[(z, t) in ZONE_TIMEPOINTS], zone_demand_mw[z, t])

@expression(mod, Distributed_Power_Injections[(z, t) in ZONE_TIMEPOINTS], InjectIntoDistributedGrid[(z, t)])

@constraint(mod, Distributed_Energy_Balance[(z, t) in ZONE_TIMEPOINTS], Distributed_Power_Injections[(z, t)] == Distributed_Power_Withdrawals[(z, t)])

# 计划备用
#  + sum(TXPowerNet[z, t] for z in zones_for_prr(prr))
@constraint(mod, Enforce_Planning_Reserve_Margin[(prr, t) in PRR_TIMEPOINTS], AvailableReserveCapacity[(prr, t)] >= CapacityRequirements[(prr, t)])

# ---------------------------------------------
# 21 objective, coming from financials.py
# ---------------------------------------------
function uniform_series_to_present_value(ir, t)
return (1 - (1 + ir) ^ (-t)) / ir
end 

function future_to_present_value(ir, t)
return (1 + ir) ^ (-t)
end

bring_annual_costs_to_base_year = Dict(p => uniform_series_to_present_value(interest_rate, period_length_years[p]) * future_to_present_value(interest_rate, p - base_financial_year) for p in PERIODS)

bring_timepoint_costs_to_base_year = Dict(t => (bring_annual_costs_to_base_year[tp_period[t]] * tp_weight_in_year[t]) for t in TIMEPOINTS)

function calc_tp_costs_in_period(t)
return (GenVariableOMCostsInTP[t] + CCSVariableOMCostsInTP[t]
+ Total_StartupGenCapacity_OM_Costs[t]) * tp_weight_in_year[t]
end

function calc_annual_costs_in_period(p)
return TotalGenFixedCosts[p] + StorageEnergyFixedCost[p] + FuelCostsPerPeriod[p] + TxFixedCosts[p] + LocalTDFixedCosts[p] + EmissionCosts[p]
end

function calc_sys_costs_per_period(p)
return (calc_annual_costs_in_period(p) + sum(calc_tp_costs_in_period(t) for t in TPS_IN_PERIOD[p])) * bring_annual_costs_to_base_year[p]
end

@expression(mod, SystemCostPerPeriod[p in PERIODS], calc_sys_costs_per_period(p))
@expression(mod, SystemCost, sum(SystemCostPerPeriod[p] for p in PERIODS))
@objective(mod, Min, SystemCost)
println("Finish to read objective and constraints")

# ---------------------------------------------
# solve the model and export the results
# ---------------------------------------------
optimize!(mod)
println("Finish to solve the model")

# ---------------------------------------------
# post-solve treat and export of results
# ---------------------------------------------
# 1. BuildGen.csv
val_BuildGen = value.(BuildGen)
df_BuildGen = DataFrame(:GENERATION_PROJECT => [g for (g, p) in GEN_BLD_YRS], :province =>[gen_load_zone[g] for (g, p) in GEN_BLD_YRS], :energy_source => [gen_energy_source[g] for (g, p) in GEN_BLD_YRS], :technology => [gen_tech[g] for (g, p) in GEN_BLD_YRS], :build_year => [p for (g, p) in GEN_BLD_YRS], :BuildGen => [val_BuildGen[(g, p)] for (g, p) in GEN_BLD_YRS])

# 2. BuildStorageEnergy.CSV
val_BuildStorageEnergy = value.(BuildStorageEnergy)
df_BuildStorageEnergy = DataFrame(:GENERATION_PROJECT => [g for (g, p) in STORAGE_GEN_BLD_YRS], :province =>[gen_load_zone[g] for (g, p) in STORAGE_GEN_BLD_YRS], :energy_source => [gen_energy_source[g] for (g, p) in STORAGE_GEN_BLD_YRS], :technology => [gen_tech[g] for (g, p) in STORAGE_GEN_BLD_YRS], :build_year => [p for (g, p) in STORAGE_GEN_BLD_YRS], :BuildStorageEnergy => [val_BuildStorageEnergy[(g, p)] for (g, p) in STORAGE_GEN_BLD_YRS])

# 3. BuildTx.csv
val_BuildTx = value.(BuildTx)
df_BuildTx = DataFrame(:TRANSMISSION_LINE => [tx for (tx, p) in TRANS_BLD_YRS], :build_year => [p for (tx, p) in TRANS_BLD_YRS], :BuildTx => [val_BuildTx[(tx, p)] for (tx, p) in TRANS_BLD_YRS])

# 4.CCSGEN and NewCCSGEN.csv
val_CCSGEN = value.(CCSGEN)
val_RetireGEN = value.(RetireGEN)
df_CCSGEN = DataFrame(:GENERATION_PROJECT => [g for (g, p, inst_yr) in GEN_BLD_INST_YRS], :build_year => [p for (g, p, inst_yr) in GEN_BLD_INST_YRS], :install_year => [inst_yr for (g, p, inst_yr) in GEN_BLD_INST_YRS], :CCSGEN => [val_CCSGEN[a] for a in GEN_BLD_INST_YRS], :RetireGEN => [val_RetireGEN[a] for a in GEN_BLD_INST_YRS])

val_NewCCSGEN = value.(NewCCSGEN)
df_NewCCSGEN = DataFrame(:GENERATION_PROJECT => [g for (g, p, inst_yr) in GEN_BLD_INST_YRS], :build_year => [p for (g, p, inst_yr) in GEN_BLD_INST_YRS], :install_year => [inst_yr for (g, p, inst_yr) in GEN_BLD_INST_YRS], :NewCCSGEN => [val_NewCCSGEN[(g, p, inst_yr)] for (g, p, inst_yr) in GEN_BLD_INST_YRS])

# 2. dispatch.csv
val_DispatchGen = value.(DispatchGen)
val_DispatchGenCCS = value.(DispatchGenCCS)
val_DispatchGenNOCCS = value.(DispatchGenNOCCS)
val_GenFuelUseRateCCS = value.(GenFuelUseRateCCS)
val_GenFuelUseRate = value.(GenFuelUseRate)
val_DispatchEmissions = value.(DispatchEmissions)
val_GenCapacity = value.(GenCapacity)
val_GenCapacityCCS = value.(GenCapacityCCS)
val_GenCapacityNOCCS = value.(GenCapacityNOCCS)
val_GenCapitalCosts = value.(GenCapitalCosts)
val_GenFixedOMCosts_CCS = value.(GenFixedOMCosts_CCS)
val_GenFixedOMCosts_NOCCS = value.(GenFixedOMCosts_NOCCS)

function get_GenFixedOMCosts(g, p)
    if g in CCS_GENS
        return val_GenFixedOMCosts_CCS[g, p]
    elseif g in NOCCS_GENS
        return val_GenFixedOMCosts_NOCCS[g, p]
    else
        return 0
    end
end

val_CCSFixedCosts = value.(CCSFixedCosts)
val_ChargeStorage = value.(ChargeStorage)
val_StorageEnergyCapacity = value.(StorageEnergyCapacity)
val_StorageEnergyCapitalCost = value.(StorageEnergyCapitalCost)
val_StartupGenCapacity = value.(StartupGenCapacity)
AverageFuelCosts = value.(RFM_ANNUAL_COSTS) ./ (value.(FuelConsumptionInMarket) .+ 0.001)

df_dispatch_full = DataFrame(
:generation_project => [g for (g, t) in GEN_TPS], 
:gen_dbid => [gen_dbid[g] for (g, t) in GEN_TPS], 
:gen_tech => [gen_tech[g] for (g, t) in GEN_TPS], 
:gen_load_zone => [gen_load_zone[g] for (g, t) in GEN_TPS], 
:gen_energy_source => [gen_energy_source[g] for (g, t) in GEN_TPS], 
:timestamp => [tp_timestamp[t] for (g, t) in GEN_TPS], 
:tp_weight_in_year_hrs => [tp_weight_in_year[t] for (g, t) in GEN_TPS], 
:period => [tp_period[t] for (g, t) in GEN_TPS], 
:DispatchGen_MW => [val_DispatchGen[(g, t)] for (g, t) in GEN_TPS], 
:DispatchGenCCS_MW => [val_DispatchGenCCS[(g, t)] for (g, t) in GEN_TPS], 
:DispatchGenNOCCS_MW => [val_DispatchGenNOCCS[(g, t)] for (g, t) in GEN_TPS], 
:Energy_GWh_typical_yr => [val_DispatchGen[(g, t)] * tp_weight_in_year[t] / 1000 for (g, t) in GEN_TPS], 
:EnergyCCS_GWh_typical_yr => [val_DispatchGenCCS[(g, t)] * tp_weight_in_year[t] / 1000 for (g, t) in GEN_TPS], 
:EnergyNOCCS_GWh_typical_yr => [val_DispatchGenNOCCS[(g, t)] * tp_weight_in_year[t] / 1000 for (g, t) in GEN_TPS],
:StorageEnergyCapacity_GWh => [((g, t) in STORAGE_GEN_TPS) ? (val_StorageEnergyCapacity[g, tp_period[t]]) / 1000 : NaN for (g, t) in GEN_TPS],
:GenVariableCost_per_yr => [(gen_uses_fuel[g] == true) ? (val_DispatchGenNOCCS[(g, t)] * gen_variable_om[g] + val_DispatchGenCCS[(g, t)] * gen_variable_om[g]) * tp_weight_in_year[t] : (val_DispatchGenNOCCS[(g, t)] * gen_variable_om[g] * tp_weight_in_year[t]) for (g, t) in GEN_TPS],
:CCSVariableCost_per_yr => [(g in CCS_GENS) ? (val_DispatchGenCCS[(g, t)] * ccs_variable_om[g] + sum(val_GenFuelUseRateCCS[(g, t, f)] * f_co2_intensity[f] * gen_ccs_capture_efficiency[g]  * (ccs_storage_cost[g] + ccs_transport_cost[g]) for f in FUELS_FOR_GEN[g])) * tp_weight_in_year[t] : 0 for (g, t) in GEN_TPS],
:DispatchEmissions_tCO2_per_typical_yr => [(gen_uses_fuel[g] == true) ? sum(val_DispatchEmissions[(g, t, f)] * tp_weight_in_year[t] for f in FUELS_FOR_GEN[g]) : 0 for (g, t) in GEN_TPS],
:EmissionCosts_per_typical_yr => [(gen_uses_fuel[g] == true) ? sum(val_DispatchEmissions[(g, t, f)] * tp_weight_in_year[t] * carbon_cost_dollar_per_tco2[tp_period[t]] for f in FUELS_FOR_GEN[g]) : 0 for (g, t) in GEN_TPS],
:GenFuelCost_per_yr => [(gen_uses_fuel[g] == true) ? sum(val_GenFuelUseRate[(g, t, f)] * AverageFuelCosts[zone_fuel_rfm[gen_load_zone[g], f], tp_period[t]] * tp_weight_in_year[t] for f in FUELS_FOR_GEN[g]) : 0 for (g, t) in GEN_TPS],
:StartupGenCapacity_OM_Costs_per_yr => [gen_startup_om[g] * val_StartupGenCapacity[(g, t)] / tp_duration_hrs[t] * tp_weight_in_year[t] for (g, t) in GEN_TPS],
:GenCapacity_MW => [val_GenCapacity[g, tp_period[t]] for (g, t) in GEN_TPS],
:GenCapacityCCS_MW => [val_GenCapacityCCS[g, tp_period[t]] for (g, t) in GEN_TPS],
:GenCapacityNOCCS_MW => [val_GenCapacityNOCCS[g, tp_period[t]] for (g, t) in GEN_TPS],
:GenCapitalCosts => [val_GenCapitalCosts[g, tp_period[t]] for (g, t) in GEN_TPS],
:GenFixedOMCosts => [get_GenFixedOMCosts(g, tp_period[t]) for (g, t) in GEN_TPS],
:CCSFixedCosts => [(g in CCS_GENS) ? val_CCSFixedCosts[g, tp_period[t]] : 0 for (g, t) in GEN_TPS],
:ChargeStorage_MW => [((g, t) in STORAGE_GEN_TPS) ? (-1.0 * val_ChargeStorage[(g, t)]) : NaN for (g, t) in GEN_TPS],
:Store_GWh_typical_yr => [((g, t) in STORAGE_GEN_TPS) ? (val_ChargeStorage[(g, t)] * tp_weight_in_year[t] / 1000) : NaN for (g, t) in GEN_TPS],
:StorageEnergyCapitalCost => [((g, t) in STORAGE_GEN_TPS) ? val_StorageEnergyCapitalCost[g, tp_period[t]] : NaN for (g, t) in GEN_TPS],
:Discharge_GWh_typical_yr => [((g, t) in STORAGE_GEN_TPS) ? (val_DispatchGen[(g, t)] * tp_weight_in_year[t] / 1000) : NaN for (g, t) in GEN_TPS],
:is_storage => [((g, t) in STORAGE_GEN_TPS) ? true : false for (g, t) in GEN_TPS],
)

#3. load_balance
val_ZoneTotalCentralDispatch = value.(ZoneTotalCentralDispatch)
val_TXPowerNet = value.(TXPowerNet)
val_WithdrawFromCentralGrid = value.(WithdrawFromCentralGrid)
val_StorageNetCharge = value.(StorageNetCharge)

df_load_balance = DataFrame(
:load_zone => [z for (z, t) in ZONE_TIMEPOINTS],
:timestamp => [tp_timestamp[t] for (z, t) in ZONE_TIMEPOINTS],
:ZoneTotalCentralDispatch => [val_ZoneTotalCentralDispatch[z, t] for (z, t) in ZONE_TIMEPOINTS],
:TXPowerNet => [val_TXPowerNet[z, t] for (z, t) in ZONE_TIMEPOINTS],
:WithdrawFromCentralGrid => [val_WithdrawFromCentralGrid[(z, t)] for (z, t) in ZONE_TIMEPOINTS],
:StorageNetCharge => [val_StorageNetCharge[z, t] for (z, t) in ZONE_TIMEPOINTS],
)

#4. transmission line dispatch
val_DispatchTx = value.(DispatchTx)
df_DispatchTx = DataFrame(
:zone_from => [zone_from for (zone_from, zone_to, t) in TRANS_TIMEPOINTS],
:zone_to => [zone_to for (zone_from, zone_to, t) in TRANS_TIMEPOINTS],
:timestamp => [tp_timestamp[t] for (zone_from, zone_to, t) in TRANS_TIMEPOINTS],
:DispatchTx => [val_DispatchTx[(zone_from, zone_to, t)] for (zone_from, zone_to, t) in TRANS_TIMEPOINTS],
)

#5. power system costs
val_SystemCostPerPeriod = value.(SystemCostPerPeriod)
val_GenVariableOMCostsInTP = value.(GenVariableOMCostsInTP)
val_CCSVariableOMCostsInTP = value.(CCSVariableOMCostsInTP)
val_Total_StartupGenCapacity_OM_Costs = value.(Total_StartupGenCapacity_OM_Costs)
val_StorageEnergyFixedCost = value.(StorageEnergyFixedCost)
val_FuelCostsPerPeriod = value.(FuelCostsPerPeriod)
val_TxFixedCosts = value.(TxFixedCosts)
val_LocalTDFixedCosts = value.(LocalTDFixedCosts)
val_EmissionCosts = value.(EmissionCosts)
val_CarbonPrice = dual.(Enforce_Carbon_Cap)

df_electricity_cost = DataFrame(
:period => [p for p in PERIODS],
:SystemDemand_MWh => [sum(sum(zone_demand_mw[z, t] * tp_weight_in_year[t] for t in TPS_IN_PERIOD[p]) for z in LOAD_ZONES) for p in PERIODS],
:SystemCost => [val_SystemCostPerPeriod[p] / bring_annual_costs_to_base_year[p] for p in PERIODS],
:GenVariableOMCosts => [sum(val_GenVariableOMCostsInTP[t] * tp_weight_in_year[t] for t in TPS_IN_PERIOD[p]) for p in PERIODS],
:CCSVariableOMCosts => [sum(val_CCSVariableOMCostsInTP[t] * tp_weight_in_year[t] for t in TPS_IN_PERIOD[p]) for p in PERIODS],
:Total_StartupGenCapacity_OM_Costs => [sum(val_Total_StartupGenCapacity_OM_Costs[t] * tp_weight_in_year[t] for t in TPS_IN_PERIOD[p]) for p in PERIODS],
:TotalGenCapacityCosts => [sum(val_GenCapitalCosts[g, p] for g in GENS_IN_PERIOD[p]) for p in PERIODS],
:TotalGenFixedOMCosts => [sum(get_GenFixedOMCosts(g, p) for g in GENS_IN_PERIOD[p]) for p in PERIODS],
:TotalCCSFixedCosts => [sum(val_CCSFixedCosts[g, p] for g in GENS_IN_PERIOD[p] if g in CCS_GENS) for p in PERIODS],
:StorageEnergyFixedCost => [val_StorageEnergyFixedCost[p] for p in PERIODS],
:FuelCostsPerPeriod => [val_FuelCostsPerPeriod[p] for p in PERIODS],
:TxFixedCosts => [val_TxFixedCosts[p] for p in PERIODS],
:LocalTDFixedCosts => [val_LocalTDFixedCosts[p] for p in PERIODS],
:EmissionCosts => [val_EmissionCosts[p] for p in PERIODS],
:CarbonPrice => [val_CarbonPrice[p] / bring_annual_costs_to_base_year[p] for p in PERIODS]
)

CSV.write(joinpath(pwd(), "$(scn)/outputs/BuildGen.csv"), df_BuildGen)
CSV.write(joinpath(pwd(), "$(scn)/outputs/BuildStorageEnergy.csv"), df_BuildStorageEnergy)
CSV.write(joinpath(pwd(), "$(scn)/outputs/BuildTx.csv"), df_BuildTx)
CSV.write(joinpath(pwd(), "$(scn)/outputs/Retrofit_Retirement.csv"), df_CCSGEN)
CSV.write(joinpath(pwd(), "$(scn)/outputs/New_Retrofit_Retirement.csv"), df_NewCCSGEN)
CSV.write(joinpath(pwd(), "$(scn)/outputs/dispatch.csv"), df_dispatch_full)
CSV.write(joinpath(pwd(), "$(scn)/outputs/load_balance.csv"), df_load_balance)
CSV.write(joinpath(pwd(), "$(scn)/outputs/DispatchTx.csv"), df_DispatchTx)
CSV.write(joinpath(pwd(), "$(scn)/outputs/electricity_cost.csv"), df_electricity_cost)
println("Finish to export the results")
end