import pandas as pd
import numpy as np

dict_techs_for_gen = {
    'Battery Storage': 'Battery Charge',
    'Pumped Storage': 'Pumped Charge',
    # 'CAS Storage': 'CAS Charge',
    'Coal W/O CCS': 'Coal W/O CCS',
    'Coal W/ CCS': 'Coal W/ CCS',
    'Gas W/O CCS': 'Gas W/O CCS',
    'Gas W/ CCS': 'Gas W/ CCS',
    'Biomass W/O CCS': 'BE W/O CCS',
    'Biomass W/ CCS': 'BE W/ CCS',
    'Nuclear W/O CCS': 'Nuclear',
    'Hydro W/O CCS': 'Hydro',
    'Central PV W/O CCS': 'Central PV',
    'Distributed PV W/O CCS': 'Distributed PV',
    'Onshore Wind W/O CCS': 'Onshore Wind',
    'Offshore Wind W/O CCS': 'Offshore Wind',
    'Battery W/O CCS': 'Battery Discharge',
    'Pumped W/O CCS': 'Pumped Discharge',
    # 'CAS W/O CCS': 'CAS Discharge',
}

dict_techs_for_capac = {
    'Coal W/O CCS': 'Coal W/O CCS',
    'Coal W/ CCS': 'Coal W/ CCS',
    'Gas W/O CCS': 'Gas W/O CCS',
    'Gas W/ CCS': 'Gas W/ CCS',
    'Biomass W/O CCS': 'BE W/O CCS',
    'Biomass W/ CCS': 'BE W/ CCS',
    'Nuclear W/O CCS': 'Nuclear',
    'Hydro W/O CCS': 'Hydro',
    'Central PV W/O CCS': 'Central PV',
    'Distributed PV W/O CCS': 'Distributed PV',
    'Onshore Wind W/O CCS': 'Onshore Wind',
    'Offshore Wind W/O CCS': 'Offshore Wind',
    'Battery W/O CCS': 'Battery Storage',
    'Pumped W/O CCS': 'Pumped Hydro',
    # 'CAS W/O CCS': 'CAS Storage',
}

dict_periods = {
    2018: 2020,
    2023: 2025,
    2028: 2030,
    2033: 2035,
    2038: 2040,
    2043: 2045,
    2048: 2050,
    2053: 2055,
    2058: 2060
}

dict_colors_for_capac = {
    'Coal W/O CCS': '#4C5561',
    'Coal W/ CCS': '#778e91',
    'Gas W/O CCS': '#9b8063',
    'Gas W/ CCS': '#d7af83',
    'Nuclear':'#ae98b6',
    'Hydro': '#6c9ac0',
    'Central PV': '#f2c69c',
    'Distributed PV': '#f8e5c2',
    'Onshore Wind': '#9dc2de',
    'Offshore Wind': '#badbe9',
    'BE W/O CCS': '#98c39a',
    'BE W/ CCS': '#516850',
    'Battery Storage': '#f39a8f',
    'CAS Storage': '#9dc2de',
    'Pumped Hydro': '#6497a8'
}

dict_colors_for_gen = {
    'Battery Charge': '#e77a83',
    'CAS Charge': '#9dc2de',
    'Pumped Charge': '#318a98',
    'Coal W/O CCS': '#4C5561',
    'Coal W/ CCS': '#778e91',
    'Gas W/O CCS': '#9b8063',
    'Gas W/ CCS': '#d7af83',
    'Nuclear':'#ae98b6',
    'Hydro': '#6c9ac0',
    'Central PV': '#f2c69c',
    'Distributed PV': '#f8e5c2',
    'Onshore Wind': '#9dc2de',
    'Offshore Wind': '#badbe9',
    'BE W/O CCS': '#98c39a',
    'BE W/ CCS': '#516850',
    'Battery Discharge': '#f39a8f',
    'CAS Discharge': '#9dc2de',
    'Pumped Discharge': '#6497a8'
}

def get_gen_techs(dir_path):
    gen_ccs_energy_load = pd.read_csv('%s/../inputs/gen_ccs_energy_load.csv' %dir_path).rename(columns={'gen_tech': 'gen_energy_source'}) # need to be noted
    gen_project = pd.read_csv('%s/gen_project_annual_summary.csv' %dir_path)
    gen_project = gen_project.merge(gen_ccs_energy_load, on=['gen_energy_source', 'period'], how='left').fillna(0)
    gen_project['EnergyCCS_GWh_typical_yr'] = gen_project['EnergyCCS_GWh_typical_yr'] * (1 - gen_project['gen_ccs_energy_load'])
    merge_tech = pd.read_csv('pack/merge_tech.csv')
    gen_techs = gen_project.groupby(['period','gen_tech'])[['EnergyCCS_GWh_typical_yr', 'EnergyNOCCS_GWh_typical_yr', 'Store_GWh_typical_yr']].sum().reset_index()
    gen_techs = gen_techs.merge(merge_tech, on =['gen_tech'], how='left')
    gen_techs = gen_techs.groupby(['period', 'gen_energy_source'])[['EnergyCCS_GWh_typical_yr', 'EnergyNOCCS_GWh_typical_yr', 'Store_GWh_typical_yr']].sum()
    gen_techs['Store_GWh_typical_yr'] *= -1
    gen_techs.columns = ['W/ CCS', 'W/O CCS', 'Storage']
    gen_techs = gen_techs.reset_index()
    gen_techs = gen_techs.melt(id_vars=['period', 'gen_energy_source'], value_name = 'gen', var_name='CCS')
    gen_techs['tech_name'] = gen_techs['gen_energy_source'] + ' ' + gen_techs['CCS']
    gen_techs['tech_name'] = gen_techs['tech_name'].apply(lambda x: dict_techs_for_gen[x] if x in dict_techs_for_gen.keys() else np.nan)
    gen_techs['period'] = gen_techs['period'].apply(lambda x: dict_periods[x] if x in dict_periods.keys() else np.nan)
    gen_techs = gen_techs.dropna().groupby(['period', 'tech_name'])['gen'].sum().reset_index()
    gen_techs = gen_techs.pivot_table(index='period', columns='tech_name', values='gen')[dict_techs_for_gen.values()] / 1e3 # TWh
    return gen_techs

def get_capac_techs(dir_path):
    gen_project = pd.read_csv('%s/gen_project_annual_summary.csv' %dir_path)
    gen_techs = gen_project.groupby(['period','gen_tech'])[['GenCapacityCCS_MW', 'GenCapacityNOCCS_MW']].sum().reset_index()
    merge_tech = pd.read_csv('pack/merge_tech.csv')
    gen_techs = gen_techs.merge(merge_tech, on =['gen_tech'], how='left')
    gen_techs = gen_techs.groupby(['period', 'gen_energy_source'])[['GenCapacityCCS_MW', 'GenCapacityNOCCS_MW']].sum()
    gen_techs.columns = ['W/ CCS', 'W/O CCS']
    gen_techs = gen_techs.reset_index()
    gen_techs = gen_techs.melt(id_vars=['period', 'gen_energy_source'], value_name = 'gen', var_name='CCS')
    gen_techs['tech_name'] = gen_techs['gen_energy_source'] + ' ' + gen_techs['CCS']
    gen_techs['tech_name'] = gen_techs['tech_name'].apply(lambda x: dict_techs_for_capac[x] if x in dict_techs_for_capac.keys() else np.nan)
    gen_techs['period'] = gen_techs['period'].apply(lambda x: dict_periods[x] if x in dict_periods.keys() else np.nan)
    gen_techs = gen_techs.dropna().groupby(['period', 'tech_name'])['gen'].sum().reset_index()
    gen_techs = gen_techs.pivot_table(index='period', columns='tech_name', values='gen')[dict_techs_for_capac.values()] / 1e3 # GW
    return gen_techs
