#%%
import pandas as pd
import matplotlib.pyplot as plt
from get_info import get_gen_techs, get_capac_techs
plt.rc('font', family='Arial', size=6)

Xlabels = [
    'Mod Base', 
    # 比较煤电灵活性参数假设
    'Mod LowFlex', 'Mod Flex', 'Mod HighFlex',
    # 比较风光资源充裕度
    'Base Base', 'Base Flex', 'Loose Base', 'Loose Flex',
    # 比较风光储成本
    'Relow Base', 'Relow Flex', 'Batterylow Base', 'Batterylow Flex', 'Reslow Base', 'Reslow Flex',
    # 比较燃料成本
    'Super Base', 'Super Flex', 
    'GasLow Base', 'GasLow Flex', 'CoalLow Base', 'CoalLow Flex',
    # 比较电力需求高低
    'High Base', 'High Flex', 'Low Base', 'Low Flex',
    # 比较CCS高技术成本
    "CCShigh Base", "CCShigh Flex",
    # 比较CCS灵活性
    "Mod CCSBase", "Mod CCSFlex" 
    ]

Xnames = [
    'Base', 
    # 比较煤电灵活性参数假设
    'LowFlex', 'Flex', 'HighFlex',
    # 比较风光资源充裕度
    'Base-MidREPot', 'Flex-MidREPot', 'Base-HighREPot', 'Flex-HighREPot',
    # 比较风光储成本
    'Base-LowRECost', 'Flex-LowRECost', 'Base-LowBatteryCost', 'Flex-LowBatteryCost', 'Base-LowREBatCost', 'Flex-LowREBatCost',
    # 比较燃料成本
    'Base-HighCoal', 'Flex-HighCoal',
    'Base-LowGas', 'Flex-LowGas',
    'Base-LowCoal', 'Flex-LowCoal',
    # 比较电力需求高低
    'Base-HighDemand', 'Flex-HighDemand',
    'Base-LowDemand', 'Flex-LowDemand',
    # 比较CCS高技术成本
    'Base-HighCCS', 'Flex-HighCCS',
    # 比较CCS灵活性
    "Flex-BaseCCS", "Flex-FlexCCS"
    ]

scenarios = [
'MOD-Base', 
# 比较煤电灵活性参数假设
'Capno_Carbon38_baseflex_Strict4h',
'MOD-Flex', 
'Capno_Carbon38_deep_Strict4h',
# 比较风光资源充裕度
'Capno_Carbon38_base_Base4h',
'Capno_Carbon38_flex_Base4h',
'Capno_Carbon38_base_Loose4h',
'Capno_Carbon38_flex_Loose4h',
# 比较风光储成本
'Capno_Carbon38_base_Strict_relow4h',
'Capno_Carbon38_flex_Strict_relow4h',
'Capno_Carbon38_base_Strict_batterylow4h',
'Capno_Carbon38_flex_Strict_batterylow4h',
'Capno_Carbon38_base_Strict_reslow4h',
'Capno_Carbon38_flex_Strict_reslow4h',
# 比较燃料成本
'Capno_Carbon38_base_Strict_super4h', 
'Capno_Carbon38_flex_Strict_super4h', 
'Capno_Carbon38_base_Strict_gaslow4h', 
'Capno_Carbon38_flex_Strict_gaslow4h', 
'Capno_Carbon38_base_Strict_low4h', 
'Capno_Carbon38_flex_Strict_low4h',
# 比较电力需求高低
'Capno_Carbon38_basedemand_high4h',
'Capno_Carbon38_flexdemand_high4h',
'Capno_Carbon38_basedemand_low4h',
'Capno_Carbon38_flexdemand_low4h',
# 比较CCS高技术成本
"MOD-Base-CCS-High", 
"MOD-Flex-CCS-High",
# 比较CCS灵活性
"CCS-Base", 
"CCS-Flex"
]
dict_scn = dict(zip(scenarios, Xlabels))
dict_names = dict(zip(Xlabels, Xnames))

#%%
# 节约的转型成本
comp_costs = pd.DataFrame()
for scn in scenarios:
    if scn in ['MOD-Base', 'STR-Base', 'REF-Base', 'MOD-Flex', 'STR-Flex', 'REF-Flex', "CCS-Base", "CCS-Flex"]:
        agg_path = "../scn/%s" %scn
    else:
        agg_path = "D:/PhDmodels/cheerpowerv1.1/sensitivie_scns/%s"%scn
    dir_path = agg_path + '/outputs'
    costs = pd.read_csv(dir_path + '/electricity_cost.csv', index_col=0)
    costs.index += 2
    costs = costs.loc[2025:]
    comp_cost = costs.apply(lambda col: sum([col[t] * 5 / (1.08 ** (t - 2020)) for t in costs.index])) / 1e9
    comp_cost.name = dict_scn[scn]
    if comp_costs.empty:
        comp_costs = comp_cost
    else:
        comp_costs = pd.concat([comp_costs, comp_cost], axis=1)
comp_costs.loc['TDFixedCosts'] = comp_costs.loc['TxFixedCosts'] + comp_costs.loc['LocalTDFixedCosts']
comp_costs.loc['TotalGenCapacityCosts'] = comp_costs.loc['TotalGenCapacityCosts'] + comp_costs.loc['StorageEnergyFixedCost']
comp_costs

#%%
dict_colors_for_items = {
    'TotalGenCapacityCosts': '#4C5561',
    'TotalGenFixedOMCosts': '#9b8063',
    'TotalCCSFixedCosts':'#ae98b6',
    'TDFixedCosts': '#f2c69c',
    'GenVariableOMCosts': '#9dc2de',
    'CCSVariableOMCosts': '#98c39a',
    'FuelCostsPerPeriod': '#f39a8f',
    'Total_StartupGenCapacity_OM_Costs': '#6497a8',
}

items = [
    'FuelCostsPerPeriod',
    'GenVariableOMCosts',
    'TotalGenCapacityCosts',
    'TotalGenFixedOMCosts',
    'TotalCCSFixedCosts',
    'TDFixedCosts',
    'CCSVariableOMCosts',
    'Total_StartupGenCapacity_OM_Costs'
]

dict_labels_for_items = {
    'TotalGenCapacityCosts': 'Capital Investment',
    'TotalGenFixedOMCosts': 'Fixed O&M',
    'TotalCCSFixedCosts':'CCS Fixed',
    'TDFixedCosts': 'T&D Fixed',
    'GenVariableOMCosts': 'Variable O&M',
    'CCSVariableOMCosts': 'CCS Variable',
    'FuelCostsPerPeriod': 'Fuel',
    'Total_StartupGenCapacity_OM_Costs': 'Startup O&M',
}

comp_costs = comp_costs.T
delta_costs = comp_costs.copy(deep=True).iloc[:0, :]
for scn in Xlabels:
    if scn.split(' ')[1] != 'Base':
        delta_costs.loc[r'dollars\Deltadollars' + scn] = comp_costs.loc[scn.split(' ')[0] + ' Base'] - comp_costs.loc[scn]
delta_costs = delta_costs[items]
delta_costs = delta_costs.reset_index().melt(id_vars='index', var_name='Comp')
delta_costs['Comp'] = delta_costs.Comp.apply(lambda x: dict_labels_for_items[x])

#%%
# 获取各期新建电池储能容量
BatteryCapacity = pd.DataFrame()
for scn in scenarios:
    print(scn)
    if scn in ['MOD-Base', 'STR-Base', 'REF-Base', 'MOD-Flex', 'STR-Flex', 'REF-Flex', "CCS-Base", "CCS-Flex"]:
        agg_path = "../scn/%s" %scn
    else:
        agg_path = "D:/PhDmodels/cheerpowerv1.1/sensitivie_scns/%s"%scn
    dir_path = agg_path + '/outputs'
    BuildStorageEnergy = pd.read_csv(dir_path + '/gen_project_annual_summary.csv')
    BuildStorageEnergy = BuildStorageEnergy[BuildStorageEnergy.gen_tech == 'Battery']
    BuildStorageEnergy = BuildStorageEnergy.groupby(['period'])['StorageEnergyCapacity_GWh'].sum()
    BuildStorageEnergy.name = dict_scn[scn]
    if BatteryCapacity.empty:
        BatteryCapacity = BuildStorageEnergy
    else:
        BatteryCapacity = pd.concat([BatteryCapacity, BuildStorageEnergy], axis=1)
BatteryCapacity.index += 2
BatteryCapacity_melt = BatteryCapacity.reset_index().melt(id_vars='period', var_name='scn', value_name='battery')
BatteryCapacity_melt.loc[BatteryCapacity_melt.scn.apply(lambda x: x.split(' ')[1] == 'Base'), 'Mod'] = 'Base'
BatteryCapacity_melt.loc[BatteryCapacity_melt.scn.apply(lambda x: x.split(' ')[1] != 'Base'), 'Mod'] = 'Flex'

#%%
# 2030, 2045和2060年煤电装机容量
capac_scns = pd.DataFrame()
for scn in scenarios:
    if scn in ['MOD-Base', 'STR-Base', 'REF-Base', 'MOD-Flex', 'STR-Flex', 'REF-Flex', "CCS-Base", "CCS-Flex"]:
        agg_path = "../scn/%s" %scn
    else:
        agg_path = "D:/PhDmodels/cheerpowerv1.1/sensitivie_scns/%s"%scn
    dir_path = agg_path + '/outputs'
    gen_data = get_capac_techs(dir_path).reset_index()
    gen_data['scn'] = dict_scn[scn]
    if capac_scns.empty:
        capac_scns = gen_data
    else:
        capac_scns = pd.concat([capac_scns, gen_data], axis=0)

# 2030, 2045和2060年煤电装机容量
gen_scns = pd.DataFrame()
for scn in scenarios:
    if scn in ['MOD-Base', 'STR-Base', 'REF-Base', 'MOD-Flex', 'STR-Flex', 'REF-Flex', "CCS-Base", "CCS-Flex"]:
        agg_path = "../scn/%s" %scn
    else:
        agg_path = "D:/PhDmodels/cheerpowerv1.1/sensitivie_scns/%s"%scn
    dir_path = agg_path + '/outputs'
    gen_data = get_gen_techs(dir_path).reset_index()
    gen_data['scn'] = dict_scn[scn]
    if gen_scns.empty:
        gen_scns = gen_data
    else:
        gen_scns = pd.concat([gen_scns, gen_data], axis=0)

import seaborn as sns
capac_scns.loc[capac_scns.scn.apply(lambda x: x.split(' ')[1] == 'Base'), 'Mod'] = 'Base'
capac_scns.loc[capac_scns.scn.apply(lambda x: x.split(' ')[1] != 'Base'), 'Mod'] = 'Flex'
capac_scns['Gas'] = capac_scns['Gas W/O CCS'] + capac_scns['Gas W/ CCS']
capac_scns['Solar'] = capac_scns['Central PV'] + capac_scns['Distributed PV'] 
capac_scns['Wind'] = capac_scns['Onshore Wind'] + capac_scns['Offshore Wind'] 
capac_scns['VRE'] = capac_scns['Solar'] + capac_scns['Wind']
capac_scns.to_csv('../figures/capacity_sensitivity_results.csv')
capac_scns['scn'] = capac_scns['scn'].apply(lambda x: dict_names[x])
capac_coal_woccs = capac_scns[['period', 'scn', 'Coal W/O CCS']]
capac_coal_woccs = capac_coal_woccs.pivot_table(values='Coal W/O CCS', index='scn', columns='period')
capac_coal_woccs.columns = ['Coal W/O CCS ' + str(i) for i in capac_coal_woccs.columns]

capac_coal_ccs = capac_scns[['period', 'scn', 'Coal W/ CCS']]
capac_coal_ccs = capac_coal_ccs.pivot_table(values='Coal W/ CCS', index='scn', columns='period')
capac_coal_ccs.columns = ['Coal W/ CCS ' + str(i) for i in capac_coal_ccs.columns]

capac_gas = capac_scns[['period', 'scn', 'Gas']]
capac_gas = capac_gas.pivot_table(values='Gas', index='scn', columns='period')
capac_gas.columns = ['Gas ' + str(i) for i in capac_gas.columns]

#%%
gen_scns['Solar'] = gen_scns['Central PV'] + gen_scns['Distributed PV'] 
gen_scns['Wind'] = gen_scns['Onshore Wind'] + gen_scns['Offshore Wind'] 
gen_scns['VRE'] = gen_scns['Solar'] + gen_scns['Wind']
gen_scns['Storage'] = gen_scns['Battery Discharge'] + gen_scns['Pumped Discharge'] 
gen_scns.loc[gen_scns.scn.apply(lambda x: x.split(' ')[1] == 'Base'), 'Mod'] = 'Base'
gen_scns.loc[gen_scns.scn.apply(lambda x: x.split(' ')[1] != 'Base'), 'Mod'] = 'Flex'
gen_scns.to_csv('../figures/generation_sensitivity_results.csv')
gen_scns['scn'] = gen_scns['scn'].apply(lambda x: dict_names[x])

capac_vre = capac_scns[['period', 'scn', 'VRE']]
capac_vre = capac_vre.pivot_table(values='VRE', index='scn', columns='period')
capac_vre.columns = ['VRE ' + str(i) for i in capac_vre.columns]

#%%
colors = {
    'Flex': (79/255, 157/255, 166/255),
    'Base': (255/255, 173/255, 90/255),
}
fig, axes = plt.subplots(2, 3, figsize=(180/25.4, 90/25.4))
axes = axes.flatten()
sns.boxplot(x='period', y='Coal W/O CCS', hue='Mod',data=capac_scns, ax=axes[0], palette=colors, width=0.8, flierprops={"marker": "o", "color": "black", "markersize": 3})
sns.move_legend(axes[0], loc='upper right', title=None, frameon=False)
sns.boxplot(x='period', y='Coal W/ CCS', hue='Mod',data=capac_scns, ax=axes[1], palette=colors, width=0.8, flierprops={"marker": "o", "color": "black", "markersize": 3})
sns.move_legend(axes[1], loc='upper left', title=None, frameon=False)
sns.boxplot(x='period', y='Gas', hue='Mod',data=capac_scns, ax=axes[2], palette=colors, width=0.8, flierprops={"marker": "o", "color": "black", "markersize": 3})
sns.move_legend(axes[2], loc='upper left', title=None, frameon=False)
sns.boxplot(x='period', y='VRE', hue='Mod',data=capac_scns, ax=axes[3], palette=colors, width=0.8, flierprops={"marker": "o", "color": "black", "markersize": 3})
sns.move_legend(axes[3], loc='upper left', title=None, frameon=False)
sns.boxplot(x='period', y='battery', hue='Mod',data=BatteryCapacity_melt, ax=axes[4], palette=colors, width=0.8, flierprops={"marker": "o", "color": "black", "markersize": 3})
sns.move_legend(axes[4], loc='upper left', title=None, frameon=False)
sns.boxplot(x='Comp', y='value',data=delta_costs, ax=axes[5], orient='v', color=colors['Flex'], width=0.8, flierprops={"marker": "o", "color": "black", "markersize": 3})
units = ['GW', 'GW', 'GW', 'GW', 'GWh', 'billion dollars']
titles = ['a', 'b', 'c', 'd', 'e', 'f']
xlabel=['Period', 'Period', 'Period', 'Period', 'Period', 'Component']
for iax in range(0, 6):
    axes[iax].set_xlabel(xlabel[iax])
    axes[iax].set_ylabel(units[iax])
    axes[iax].set_title(titles[iax], loc='left', y=1, fontweight='bold')
for iax in range(5):
    axes[iax].set_xticks([1, 3, 5, 7])
axes[5].set_xticks(delta_costs.Comp.drop_duplicates())
axes[5].set_xticklabels(delta_costs.Comp.drop_duplicates(), rotation=60)
plt.subplots_adjust(wspace=0.35, hspace=0.3)
plt.savefig('../figures/fig5.png', bbox_inches = 'tight', pad_inches = 0.1, dpi=600)