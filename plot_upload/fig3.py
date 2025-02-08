#%% 
# 配置并导出数据
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import rcParams
config = {
    'font.family': 'Arial',
    'font.size': 6,
    'font.weight': 'normal'
}
rcParams.update(config)
Xlabels = ['Flex', 'Base']
filenames = ['STR-Flex', 'STR-Base']
dict_labels = dict(zip(filenames, Xlabels))

dict_periods = {
    1990: 2015,
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

dict_techs = {
    'Battery Storage': 'Battery Charge',
    'Pumped Storage': 'Pumped Charge',
    'Coal W/O CCS': 'Coal W/O CCS',
    'Coal W/ CCS': 'Coal W/ CCS',
    'Gas W/O CCS': 'Gas W/O CCS',
    'Gas W/ CCS': 'Gas W/ CCS',
    'Biomass W/O CCS': 'Biomass W/O CCS',
    'Biomass W/ CCS': 'Biomass W/ CCS',
    'Nuclear W/O CCS': 'Nuclear',
    'Hydro W/O CCS': 'Hydro',
    'Central PV W/O CCS': 'Central PV',
    'Distributed PV W/O CCS': 'Distributed PV',
    'Onshore Wind W/O CCS': 'Onshore Wind',
    'Offshore Wind W/O CCS': 'Offshore Wind',
    'Battery W/O CCS': 'Battery Discharge',
    'Pumped W/O CCS': 'Pumped Discharge',
}

dict_colors = {
    'Battery Charge': '#e77a83',
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
    'Biomass W/O CCS': '#98c39a',
    'Biomass W/ CCS': '#516850',
    'Battery Discharge': '#f39a8f',
    'Pumped Discharge': '#6497a8'
}

gen_techs_data = pd.DataFrame()
load_balance_data = pd.DataFrame()
for filename in filenames:
    agg_path = "../scn/%s" %filename
    scenario_name = agg_path + '/outputs'
    merge_region = pd.read_csv('./pack/merge_grid_region.csv')
    merge_tech = pd.read_csv('pack/merge_tech.csv')
    load_balance = pd.read_csv('%s/load_balance.csv' %scenario_name).rename(columns={'load_zone': 'province'})
    load_balance = load_balance.merge(merge_region, on='province', how='left')
    load_balance['period'] = load_balance['timestamp'].apply(lambda x: int(x.split('-')[0]))
    load_balance = load_balance.groupby(['period', 'region'])[['WithdrawFromCentralGrid']].sum() * 120 / 1e6
    load_balance = load_balance.reset_index()
    gen_ccs_energy_load = 0.21
    gen_project = pd.read_csv('%s/gen_project_annual_summary.csv' %scenario_name).rename(columns={'gen_load_zone': 'province'})
    gen_project = gen_project.merge(merge_region, on='province', how='left')
    gen_techs = gen_project.groupby(['period', 'region', 'gen_tech'])[['EnergyCCS_GWh_typical_yr', 'EnergyNOCCS_GWh_typical_yr', 'Store_GWh_typical_yr']].sum().reset_index()
    gen_techs = gen_techs.merge(merge_tech, on =['gen_tech'], how='left')
    gen_techs = gen_techs.groupby(['period', 'region', 'gen_energy_source'])[['EnergyCCS_GWh_typical_yr', 'EnergyNOCCS_GWh_typical_yr', 'Store_GWh_typical_yr']].sum()
    gen_techs['EnergyCCS_GWh_typical_yr'] *= (1 - gen_ccs_energy_load)
    gen_techs['Store_GWh_typical_yr'] *= -1
    gen_techs.columns = ['W/ CCS', 'W/O CCS', 'Storage']
    gen_techs = gen_techs.reset_index()
    gen_techs = gen_techs.melt(id_vars=['period', 'region', 'gen_energy_source'], value_name = 'gen', var_name='CCS')
    gen_techs['tech_name'] = gen_techs['gen_energy_source'] + ' ' + gen_techs['CCS']
    gen_techs['tech_name'] = gen_techs['tech_name'].apply(lambda x: dict_techs[x] if x in dict_techs.keys() else np.nan)
    gen_techs['period'] = gen_techs['period'].apply(lambda x: dict_periods[x] if x in dict_periods.keys() else np.nan)
    gen_techs = gen_techs.dropna().groupby(['region', 'period', 'tech_name'])['gen'].sum().reset_index()
    gen_techs['scn'] = dict_labels[filename]
    load_balance['scn'] = dict_labels[filename]
    if gen_techs_data.empty:
        gen_techs_data = gen_techs
        load_balance_data = load_balance
    else:
        gen_techs_data = pd.concat([gen_techs_data, gen_techs], axis=0)
        load_balance_data = pd.concat([load_balance_data, load_balance], axis=0)
gen_techs_data = gen_techs_data[gen_techs_data.period.isin([2030, 2045, 2060])]
gen_techs_data['scn_period'] = gen_techs_data.scn + ' ' + gen_techs_data.period.astype(str)
load_balance_data = load_balance_data[load_balance_data.period.isin([2030, 2045, 2060])]
load_balance_data['scn_period'] = load_balance_data.scn + ' ' + load_balance_data.period.astype(str)

gen_techs_pvt = gen_techs_data[gen_techs_data.scn == 'Flex']
gen_techs_pvt = gen_techs_pvt.pivot_table(index=['region', 'period'], columns='tech_name', values='gen')

dict_colors_reg = {'Central': (0.269944, 0.014625, 0.341379, 1.0),
 'East': (0.273006, 0.20452, 0.501721, 1.0),
 'North': (0.210503, 0.363727, 0.552206, 1.0),
 'Northeast': (0.151918, 0.500685, 0.557587, 1.0),
 'Northwest': (0.122312, 0.633153, 0.530398, 1.0),
 'South': (0.288921, 0.758394, 0.428426, 1.0),
 'Southwest': (0.616293, 0.852709, 0.230052, 1.0)}

def plt_region(r, ax, id):
    gen_tech_reg = gen_techs_data[gen_techs_data.region == r].drop('region', axis=1)
    gen_tech_reg = gen_tech_reg[gen_tech_reg.period.isin([2030, 2045, 2060])]
    gen_tech_reg['index'] = gen_tech_reg.scn + '\n' + gen_tech_reg.period.astype(str)
    gen_tech_reg = gen_tech_reg.pivot_table(index='index', columns='tech_name', values='gen')
    gen_tech_reg = gen_tech_reg.loc[['Base\n2030', 'Flex\n2030', 'Base\n2045', 'Flex\n2045', 'Base\n2060', 'Flex\n2060']]
    load_reg = load_balance_data[load_balance_data.region == r]
    load_reg = load_reg[load_reg.period.isin([2030, 2045, 2060])]
    load_reg['index'] = load_reg.scn + '\n' + load_reg.period.astype(str)
    load_reg = load_reg.set_index('index')
    nan_techs = set(dict_techs.values()) - set(gen_tech_reg.columns)
    gen_tech_reg[list(nan_techs)] = 0
    gen_tech_reg = gen_tech_reg[dict_techs.values()].fillna(0) / 1e3 # TWh
    
    for i, g in enumerate(gen_tech_reg.columns):
        if i <= 1:
            bottom1 = gen_tech_reg.iloc[:,:i].sum(axis=1)
            ax.bar(gen_tech_reg.index, gen_tech_reg.iloc[:, i], bottom = bottom1, color = dict_colors[g], label=g, width=0.8)
        else:
            bottom2 = gen_tech_reg.iloc[:, 2:i].sum(axis=1)
            ax.bar(gen_tech_reg.index, gen_tech_reg.iloc[:, i], bottom = bottom2, color = dict_colors[g], label=g, width=0.8)
    ax.scatter(load_reg.index.values, load_reg.WithdrawFromCentralGrid.values, color='black', marker='s', s=3, zorder=3, label='Demand')
    ax.set_xticks(gen_tech_reg.index)
    if r in ['Central', 'South', 'East']:
        ax.set_xticklabels(gen_tech_reg.index, rotation=0)
    else:
        ax.set_xticklabels([''] * 6)
    # ax.set_xlabel('year')
    if r in ['Northwest', 'South', 'Southwest']:
        ax.set_ylabel('TWh')
    ax.set_title(id,loc='left',y=0.98, fontweight='bold')
    
fig, axes = plt.subplots(3, 3, figsize=(180/25.4, 120/25.4))
fig.delaxes(axes[2, 1])
fig.delaxes(axes[2, 2])
ax_leg = fig.add_subplot(3, 3, (8, 9))
fig.patch.set_facecolor('white')

ax_nw = axes[0, 0]
plt_region('Northwest', ax_nw, 'a')

ax_n = axes[0, 1]
plt_region('North', ax_n, 'b')

ax_ne = axes[0, 2]
plt_region('Northeast', ax_ne, 'c')

ax_c = axes[1, 1]
plt_region('Central', ax_c, 'e')

ax_e= axes[1, 2]
plt_region('East', ax_e, 'f')

ax_sw = axes[1, 0]
plt_region('Southwest', ax_sw, 'd')

ax_s = axes[2, 0]
plt_region('South', ax_s, 'g')

ax_leg.legend(*ax_s.get_legend_handles_labels(), loc='lower center', fancybox = False, edgecolor='white', ncol=3, )
ax_leg.axis('off')
fig.savefig('../figures/fig3.pdf', bbox_inches = 'tight', pad_inches = 0.1, dpi=600)