# ===========================================================
#                 Generation Project Summary
# ===========================================================
# This script is responsible for summarizing the generation 
# project, including key details, progress, and outcomes.

# Author: Kangxin An
# Date: 2025.01.11
# Version: 1.0
# ===========================================================

import pandas as pd

def gen_sum(dir_path):
    ##%%
    dispatch_full_df = pd.read_csv('%s/outputs/dispatch.csv' %dir_path, low_memory=False).fillna(0)
    dispatch_full_df = dispatch_full_df.drop(['timestamp'], axis=1)
    # Annual summary of each generator
    gen_sum = dispatch_full_df.groupby(
        [
            "generation_project",
            "gen_dbid",
            "gen_tech",
            "gen_load_zone",
            "gen_energy_source",
            "period",
            "GenCapacity_MW",
            "GenCapacityCCS_MW",
            "GenCapacityNOCCS_MW",
            "StorageEnergyCapacity_GWh",
            "GenCapitalCosts",
            "GenFixedOMCosts",
            "CCSFixedCosts",
            'StorageEnergyCapitalCost'
        ]
    ).agg(
        lambda x: x.sum(min_count=1, skipna=False)
    )
    gen_sum.reset_index(inplace=True)
    gen_sum.set_index(
        inplace=True,
        keys=[
            "generation_project",
            "gen_dbid",
            "gen_tech",
            "gen_load_zone",
            "gen_energy_source",
            "period",
        ],
    )
    gen_sum["Energy_out_avg_MW"] = (
        gen_sum["Energy_GWh_typical_yr"] * 1000 / gen_sum["tp_weight_in_year_hrs"]
    )
    hrs_per_yr = gen_sum.iloc[0]["tp_weight_in_year_hrs"]
    try:
        idx = gen_sum["is_storage"].astype(bool)
        gen_sum.loc[idx, "Energy_out_avg_MW"] = (
            gen_sum.loc[idx, "Discharge_GWh_typical_yr"]
            * 1000
            / gen_sum.loc[idx, "tp_weight_in_year_hrs"]
        )
    except KeyError:
        pass

    def add_cap_factor_and_lcoe(df):
        df["capacity_factor"] = df["Energy_out_avg_MW"] / df["GenCapacity_MW"]
        no_cap = df["GenCapacity_MW"] == 0
        df.loc[no_cap, "capacity_factor"] = 0

        df["LCOE_dollar_per_MWh"] = (
            df["GenCapitalCosts"] + df["GenFixedOMCosts"] + df["GenVariableCost_per_yr"] + df["CCSVariableCost_per_yr"] + df["GenFuelCost_per_yr"] + df['CCSFixedCosts'] + df['StartupGenCapacity_OM_Costs_per_yr'] + df['StorageEnergyCapitalCost'].fillna(0)
        ) / (df["Energy_out_avg_MW"] * hrs_per_yr)
        no_energy = df["Energy_out_avg_MW"] == 0
        df.loc[no_energy, "LCOE_dollar_per_MWh"] = 0
        return df

    gen_sum = add_cap_factor_and_lcoe(gen_sum)
    gen_sum.to_csv('%s/outputs/gen_project_annual_summary.csv' %dir_path)