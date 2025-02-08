#%%
import pandas as pd
import matplotlib.pyplot as plt

plt.rc('font', family='Arial', size=6)
dict_colors_for_scn = {
    'STR-Flex': (26/255, 8/255, 65/255),
    'MOD-Flex': (79/255, 157/255, 166/255),
    'MOD-Base': (255/255, 173/255, 90/255),
    'STR-Base': (255/255, 89/255, 89/255),
}

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
    'Total_StartupGenCapacity_OM_Costs',
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

scenarios = ['REF-Base', 'REF-Flex', 'MOD-Base', 'MOD-Flex', 'STR-Base', 'STR-Flex']
data_costs = pd.DataFrame()
for scn in scenarios:
    agg_path = "../scn/%s" %scn
    dir_path = agg_path + '/outputs'
    costs = pd.read_csv(dir_path + '/electricity_cost.csv', index_col=0)
    costs.index += 2
    costs = costs.loc[2025:]
    costs = costs[['SystemCost']] / 1e9
    costs = costs.rename(columns={'SystemCost': scn})
    if data_costs.empty:
        data_costs = costs
    else:
        data_costs = pd.concat([data_costs, costs], axis=1)
ref_costs = data_costs['REF-Flex'].copy(deep=True)
data_costs = data_costs[['MOD-Base', 'MOD-Flex','STR-Base', 'STR-Flex']]
for col in data_costs.columns:
    data_costs[col] = (data_costs[col] / ref_costs - 1) * 100
data_costs[r'$\Delta$MOD'] = data_costs['MOD-Base'] - data_costs['MOD-Flex']
data_costs[r'$\Delta$STR'] = data_costs['STR-Base'] - data_costs['STR-Flex']

comp_costs = pd.DataFrame()
for scn in scenarios:
    agg_path = "../scn/%s" %scn
    dir_path = agg_path + '/outputs'
    costs = pd.read_csv(dir_path + '/electricity_cost.csv', index_col=0)
    costs.index += 2
    costs = costs.loc[2025:]
    comp_cost = costs.apply(lambda col: sum([col[t] * 5 / (1.08 ** (t - 2020)) for t in costs.index])) / 1e9
    comp_cost.name = scn
    if comp_costs.empty:
        comp_costs = comp_cost
    else:
        comp_costs = pd.concat([comp_costs, comp_cost], axis=1)
comp_costs.loc['TDFixedCosts'] = comp_costs.loc['TxFixedCosts'] + comp_costs.loc['LocalTDFixedCosts']
comp_costs.loc['TotalGenCapacityCosts'] = comp_costs.loc['TotalGenCapacityCosts'] + comp_costs.loc['StorageEnergyFixedCost']
comp_costs = comp_costs.loc[items]
ref_comp = comp_costs['REF-Flex'].copy(deep=True)
comp_costs = comp_costs[['MOD-Base', 'MOD-Flex','STR-Base', 'STR-Flex']]
for col in comp_costs.columns:
    comp_costs[col] = (comp_costs[col] - ref_comp)
comp_costs = comp_costs.T
comp_costs.loc[r'$\Delta$MOD'] = comp_costs.loc['MOD-Base'] - comp_costs.loc['MOD-Flex']
comp_costs.loc[r'$\Delta$STR'] = comp_costs.loc['STR-Base'] - comp_costs.loc['STR-Flex']
comp_costs.sum(axis=1)/ref_comp.sum()

comp_costs_by_period = pd.DataFrame()
MODBase = pd.read_csv('../scn/MOD-Base/outputs/electricity_cost.csv', index_col=0)
MODBase.index += 2
MODFlex = pd.read_csv('../scn/MOD-Flex/outputs/electricity_cost.csv', index_col=0)
MODFlex.index += 2
STRBase = pd.read_csv('../scn/STR-Base/outputs/electricity_cost.csv', index_col=0)
STRBase.index += 2
STRFlex = pd.read_csv('../scn/STR-Flex/outputs/electricity_cost.csv', index_col=0)
STRFlex.index += 2
MODDelta = MODBase - MODFlex
MODDelta['TDFixedCosts'] = MODDelta['TxFixedCosts'] + MODDelta['LocalTDFixedCosts']
MODDelta['TotalGenCapacityCosts'] = MODDelta['TotalGenCapacityCosts'] + MODDelta['StorageEnergyFixedCost']
MODDelta = MODDelta[items] / 1e9
MODDelta_positive = MODDelta.apply(lambda row: row.apply(lambda x: x if x>=0 else 0))
MODDelta_negative = MODDelta.apply(lambda row: row.apply(lambda x: x if x<0 else 0))

STRDelta = STRBase - STRFlex
STRDelta['TDFixedCosts'] = STRDelta['TxFixedCosts'] + STRDelta['LocalTDFixedCosts']
STRDelta['TotalGenCapacityCosts'] = STRDelta['TotalGenCapacityCosts'] + STRDelta['StorageEnergyFixedCost']
STRDelta = STRDelta[items] / 1e9
STRDelta_positive = STRDelta.apply(lambda row: row.apply(lambda x: x if x>=0 else 0))
STRDelta_negative = STRDelta.apply(lambda row: row.apply(lambda x: x if x<0 else 0))
comp_positive = comp_costs.apply(lambda row: row.apply(lambda x: x if x>=0 else 0))
comp_negative = comp_costs.apply(lambda row: row.apply(lambda x: x if x<0 else 0))

fig = plt.figure(constrained_layout=True, figsize=(180/25.4, 0.65*180/25.4))
gs = fig.add_gridspec(7, 12)
axes = []
axes.append((fig.add_subplot(gs[0:3, 0:5])))
axes.append((fig.add_subplot(gs[0:3, 5:12])))
axes.append((fig.add_subplot(gs[3:6, 0:6])))
axes.append((fig.add_subplot(gs[3:6, 6:12], sharey=axes[2])))
axes.append((fig.add_subplot(gs[6:7, :])))

for col in data_costs.columns[:4]:
    axes[0].plot(data_costs.index.values, data_costs[col].values, color = dict_colors_for_scn[col], label= col, linewidth=2, linestyle = '-')
axes[0].set_title('a', loc='left', y=0.9, x=0.01, fontweight='bold')
axes[0].legend(loc='lower right', fancybox = False, edgecolor='none')
axes[0].set_ylabel('%')

for i, g in enumerate(items):
    bottom = comp_positive.loc[:,items[:i]].sum(axis=1)
    axes[1].bar(comp_costs.index, comp_positive.loc[:, g], bottom = bottom, color = dict_colors_for_items[g], label=dict_labels_for_items[g], width=0.8)
for i, g in enumerate(items):
    bottom = comp_negative.loc[:,items[:i]].sum(axis=1)
    axes[1].bar(comp_costs.index, comp_negative.loc[:, g], bottom = bottom, color = dict_colors_for_items[g], width=0.8)

axes[1].plot(comp_costs.index.values, comp_costs.sum(axis=1).values, color=dict_colors_for_scn['STR-Base'], linewidth=2, marker='o', markersize='6', label='Total Cost')
# axes[1].set_xticklabels(comp_costs.index, rotation=30)
axes[1].set_ylabel("billion dollars")
# axes[1].set_xlabel("scenario")
axes[1].set_title('b', loc='left', y=0.9, x=0.01, fontweight='bold')

for i, g in enumerate(items):
    bottom = MODDelta_positive.loc[:,items[:i]].sum(axis=1)
    axes[2].bar(MODDelta.index, MODDelta_positive.loc[:, g], bottom = bottom, color = dict_colors_for_items[g], label=dict_labels_for_items[g], width=4)
for i, g in enumerate(items):
    bottom = MODDelta_negative.loc[:,items[:i]].sum(axis=1)
    axes[2].bar(MODDelta.index, MODDelta_negative.loc[:, g], bottom = bottom, color = dict_colors_for_items[g], width=4)
# axes[2].plot(MODDelta.index.values, MODDelta.sum(axis=1).values, color=dict_colors_for_scn['MOD-Flex'], linewidth=4, marker='o', markersize='10', label='Total Cost')
axes[2].set_ylabel("billion dollars")
axes[2].set_title('c', loc='left', y=0.9, x=0.01, fontweight='bold')

for i, g in enumerate(items):
    bottom = STRDelta_positive.loc[:,items[:i]].sum(axis=1)
    axes[3].bar(STRDelta.index, STRDelta_positive.loc[:, g], bottom = bottom, color = dict_colors_for_items[g], label=dict_labels_for_items[g], width=4)
for i, g in enumerate(items):
    bottom = STRDelta_negative.loc[:,items[:i]].sum(axis=1)
    axes[3].bar(STRDelta.index, STRDelta_negative.loc[:, g], bottom = bottom, color = dict_colors_for_items[g], width=4)
axes[3].set_ylabel("billion dollars")
axes[3].set_title('d', loc='left', y=0.9, x=0.01, fontweight='bold')
axes[4].legend(*axes[3].get_legend_handles_labels(), loc='center', ncol=len(comp_costs.columns) // 2 + 1, frameon=False, fancybox=False, edgecolor='black')
axes[4].axis('off')

plt.tight_layout()
plt.savefig('../figures/fig4.png', bbox_inches = 'tight', pad_inches = 0.1, dpi=600)