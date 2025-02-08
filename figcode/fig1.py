#%%
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib import gridspec
plt.rc('font',family='Arial',size=6)

scenarios = ['REF-Base', 'REF-Flex', 'MOD-Base', 'MOD-Flex', 'STR-Base', 'STR-Flex']

dict_colors_for_scn = {
    'STR-Flex': (26/255, 8/255, 65/255),
    'MOD-Flex': (79/255, 157/255, 166/255),
    'MOD-Base': (255/255, 173/255, 90/255),
    'STR-Base': (255/255, 89/255, 89/255),
}

retirements = pd.DataFrame()
for scn in scenarios:
    agg_path = "../scn/%s" %scn
    dir_path = agg_path + '/outputs'
    retirement = pd.read_csv(dir_path + '/CCSGEN.csv')
    retirement['energy_source'] = retirement.GENERATION_PROJECT.apply(lambda x: x.split('-')[1])
    retirement = retirement[retirement.energy_source == 'Coal']
    retirement = retirement.groupby(['build_year', 'install_year'])['RetireGEN'].sum().reset_index()
    retirement = retirement.groupby(['build_year'])['RetireGEN'].max().reset_index().rename(columns={'RetireGEN': scn})
    if retirements.empty:
        retirements = retirement
    else:
        retirements = retirements.merge(retirement, on='build_year', how='left')
retirements = retirements.set_index('build_year')
ref_retirements = retirements['REF-Flex']
retirements = retirements[['MOD-Base', 'MOD-Flex','STR-Base', 'STR-Flex']]
for col in retirements.columns:
    retirements[col] = (retirements[col] - ref_retirements) / 1000
retirements = retirements.loc[:2020]

gen_predetermined = pd.read_csv(agg_path + '/inputs/gen_build_predetermined.csv')
gen_predetermined = gen_predetermined[gen_predetermined.GENERATION_PROJECT.apply(lambda x: x.split('-')[1] == 'Coal')]
gen_predetermined = gen_predetermined.groupby(['build_year'])['build_gen_predetermined'].sum()
gen_predetermined
#%% unachieved capital costs
newretires = pd.DataFrame()
for scn in scenarios:
# scn = scenarios[0]
    agg_path = "../scn/%s" %scn
    dir_path = agg_path + '/outputs'
    retirement = pd.read_csv(dir_path + '/CCSGEN.csv')
    retirement['energy_source'] = retirement.GENERATION_PROJECT.apply(lambda x: x.split('-')[1])
    retirement = retirement[retirement.energy_source == 'Coal']
    retirement = retirement.pivot_table(index=['GENERATION_PROJECT', 'build_year'], columns='install_year', values='RetireGEN').fillna(0)
    newretire = retirement.copy(deep=True)
    for yr in retirement.columns[:-1]:
        newretire[yr+5] = retirement[yr+5] - retirement[yr]
        newretire[yr+5] = newretire[yr+5].apply(lambda x: max(0, x))
    newretire = newretire.reset_index().melt(id_vars=['GENERATION_PROJECT', 'build_year'], value_name='retire')
    newretire = newretire.groupby(['build_year', 'install_year'])['retire'].sum().reset_index().rename(columns={'retire': scn})
    if newretires.empty:
        newretires = newretire
    else:
        newretires = newretires.merge(newretire, on=['build_year', 'install_year'], how='left')
newretires['MOD-Delta'] = newretires['MOD-Base'] - newretires['MOD-Flex']
newretires['STR-Delta'] = newretires['STR-Base'] - newretires['STR-Flex']

retireMODBase = newretires.pivot_table(index='build_year', columns='install_year', values='MOD-Base') / 1000
retireMODBase = retireMODBase.loc[:2020]
retireSTRBase = newretires.pivot_table(index='build_year', columns='install_year', values='STR-Base') / 1000
retireSTRBase = retireSTRBase.loc[:2020]
retireMODFlex = newretires.pivot_table(index='build_year', columns='install_year', values='MOD-Flex') / 1000
retireMODFlex = retireMODFlex.loc[:2020]
retireSTRFlex = newretires.pivot_table(index='build_year', columns='install_year', values='STR-Flex') / 1000
retireSTRFlex = retireSTRFlex.loc[:2020]
newretires = newretires.rename(columns={'build_year': 'installation period', 'install_year': 'retirement period'})
newretires = newretires[newretires['installation period'] <= 2020]
newretires['installation period'] = newretires['installation period'].apply(lambda x: '%d-%d' %(x-1, x+3))
newretires['retirement period'] = newretires['retirement period'].apply(lambda x: '%d-%d' %(x-2, x+2))

for i in retireMODBase.index:
    retireMODBase.loc[i, i+41] = gen_predetermined[i] / 1000 - retireMODBase.loc[i, :i+36].sum()
    retireMODFlex.loc[i, i+41] = gen_predetermined[i] / 1000 - retireMODFlex.loc[i, :i+36].sum()
    retireSTRBase.loc[i, i+41] = gen_predetermined[i] / 1000 - retireSTRBase.loc[i, :i+36].sum()
    retireSTRFlex.loc[i, i+41] = gen_predetermined[i] / 1000 - retireSTRFlex.loc[i, :i+36].sum()
retireMODBaseage = retireMODBase.copy(deep=True)
retireMODFlexage = retireMODFlex.copy(deep=True)
retireSTRBaseage = retireSTRBase.copy(deep=True)
retireSTRFlexage = retireSTRFlex.copy(deep=True)

for i in retireMODBase.index:
    for j in retireMODBase.columns:
        retireMODBaseage.loc[i, j] = retireMODBase.loc[i, j] * (j - i - 1)
        retireMODFlexage.loc[i, j] = retireMODFlex.loc[i, j] * (j - i - 1)
        retireSTRBaseage.loc[i, j] = retireSTRBase.loc[i, j] * (j - i - 1)
        retireSTRFlexage.loc[i, j] = retireSTRFlex.loc[i, j] * (j - i - 1)
ageLoss = pd.DataFrame(index = retireMODBase.index)
ageLoss['MOD-Base'] = 40 - retireMODBaseage.sum(axis=1) / retireMODBase.sum(axis=1)
ageLoss['MOD-Flex'] = 40 - retireMODFlexage.sum(axis=1) / retireMODFlex.sum(axis=1)
ageLoss['STR-Base'] = 40 - retireSTRBaseage.sum(axis=1) / retireSTRBase.sum(axis=1)
ageLoss['STR-Flex'] = 40 - retireSTRFlexage.sum(axis=1) / retireSTRFlex.sum(axis=1)

capacityfactors = pd.DataFrame(index=range(2023, 2063, 5))
for scn in scenarios:
    agg_path = "../scn/%s" %scn
    dir_path = agg_path + '/outputs'
    gen_project = pd.read_csv(dir_path + '/gen_project_annual_summary.csv')
    gen_project = gen_project[gen_project.gen_energy_source == 'Coal']
    gen_ccs_energy_load = 0.21
    gen_project['Coal W/ CCS'] = gen_project['EnergyCCS_GWh_typical_yr'] * (1 - gen_ccs_energy_load)
    gen_project['Coal W/O CCS'] = gen_project['EnergyNOCCS_GWh_typical_yr']
    gen_project['Generation_GWh'] = gen_project['Coal W/ CCS'] + gen_project['Coal W/O CCS']
    gen_project = gen_project.groupby(['period',])[['GenCapacity_MW', 'Generation_GWh']].sum()
    gen_project['cf'] = gen_project['Generation_GWh'] / gen_project['GenCapacity_MW'] * 1000
    capacityfactors.loc[gen_project.index, scn] = gen_project.cf
capacityfactors = capacityfactors[['MOD-Flex', 'STR-Flex']]

for i in retireMODBase.index:
    retireMODBase.loc[i, i+41] = 0
    retireMODFlex.loc[i, i+41] = 0
    retireSTRBase.loc[i, i+41] = 0
    retireSTRFlex.loc[i, i+41] = 0

fig = plt.figure(figsize=(180/25.4, 100/25.4))
gs = gridspec.GridSpec(2, 4, width_ratios=[1, 1, 0.42, 1])

# 创建子图
ax1 = fig.add_subplot(gs[0, 0]) 
ax2 = fig.add_subplot(gs[0, 1]) 
ax3 = fig.add_subplot(gs[1, 0]) 
ax4 = fig.add_subplot(gs[1, 1]) 
cax_position = gs[:, 2].get_position(fig) 
cax_position = [cax_position.x0 - 0.01, cax_position.y0 + 0.2, cax_position.width * 0.15, cax_position.height * 0.6]
cax = fig.add_axes(cax_position)
ax5 = fig.add_subplot(gs[0, 3])
ax6 = fig.add_subplot(gs[1, 3])
from matplotlib import cm
from matplotlib.colors import LinearSegmentedColormap, Normalize
import numpy as np
cmap = cm.RdBu
colors = cmap(np.linspace(0, 1, 200))

new_cmap = LinearSegmentedColormap.from_list("red_to_green", colors[90:200])
im1 = ax1.imshow(retireMODFlex, vmin=0, vmax=110, cmap='Blues')
ax1.set_xticks(range(len(retireMODFlex.columns)))
ax1.set_xticklabels(['' for _ in retireMODFlex.columns])
ax1.set_ylabel('installation period')
ax1.set_yticks(range(len(retireMODFlex.index)))
ax1.set_yticklabels(['%d-%d' %(yr-1, yr+3) for yr in retireMODFlex.index])
ax1.set_title('a', loc='left', y=1, fontweight='bold')

im2 = ax2.imshow(retireSTRFlex, vmin=0, vmax=110, cmap='Blues')
ax2.set_xticks(range(len(retireSTRFlex.columns)))
ax2.set_xticklabels(['' for _ in retireMODFlex.columns])
ax2.set_yticks(range(len(retireSTRFlex.index)))
ax2.set_yticklabels(['' for _ in retireMODFlex.index])
ax2.set_title('b', loc='left', y=1, fontweight='bold')

im3 = ax3.imshow(retireMODBase, vmin=0, vmax=110, cmap='Blues')
ax3.set_xticks(range(len(retireMODBase.columns)))
ax3.set_xticklabels(['%d-%d' %(yr-2, yr+2) for yr in retireMODFlex.columns], rotation=45)
ax3.set_ylabel('installation period')
ax3.set_yticks(range(len(retireMODBase.index)))
ax3.set_yticklabels(['%d-%d' %(yr-1, yr+3) for yr in retireMODFlex.index])
ax3.set_xlabel('retirement period')
ax3.set_title('d', loc='left', y=1, fontweight='bold')

im4 = ax4.imshow(retireSTRBase, vmin=0, vmax=110, cmap='Blues')
ax4.set_xticks(range(len(retireSTRBase.columns)))
ax4.set_xticklabels(['%d-%d' %(yr-2, yr+2) for yr in retireSTRBase.columns], rotation=45)
ax4.set_yticks(range(len(retireSTRBase.index)))
ax4.set_yticklabels(['' for _ in retireSTRBase.index])
ax4.set_xlabel('retirement period')
ax4.set_title('e', loc='left', y=1, fontweight='bold')

# bar
cbar = fig.colorbar(im4, cax=cax)
cbar.set_label('GW', labelpad=0)

for i in range(retireMODFlex.shape[0]):
    for j in range(retireMODFlex.shape[1]):
        if retireMODFlex.iloc[i, j] <= 60:
            color_text = 'black'
        else:
            color_text = 'white'
        if retireMODFlex.iloc[i, j] > 0.1:
            text = ax1.text(j, i,round(retireMODFlex.iloc[i, j], 1), ha="center", va="center", color=color_text, fontsize=5)

for i in range(retireMODFlex.shape[0]):
    for j in range(retireMODFlex.shape[1]):
        if retireSTRFlex.iloc[i, j] <= 60:
            color_text = 'black'
        else:
            color_text = 'white'
        if retireSTRFlex.iloc[i, j] > 0.1:
            text = ax2.text(j, i,round(retireSTRFlex.iloc[i, j], 1), ha="center", va="center", color=color_text, fontsize=5)

for i in range(retireMODFlex.shape[0]):
    for j in range(retireMODFlex.shape[1]):
        if retireMODBase.iloc[i, j] <= 60:
            color_text = 'black'
        else:
            color_text = 'white'
        if retireMODBase.iloc[i, j] > 0.1:
            text = ax3.text(j, i,round(retireMODBase.iloc[i, j], 1),
                       ha="center", va="center", color=color_text, fontsize=5)

for i in range(retireMODFlex.shape[0]):
    for j in range(retireMODFlex.shape[1]):
        if retireSTRBase.iloc[i, j] <= 60:
            color_text = 'black'
        else:
            color_text = 'white'
        if retireSTRBase.iloc[i, j] > 0.1:
            text = ax4.text(j, i,round(retireSTRBase.iloc[i, j], 1),  ha="center", va="center", color=color_text, fontsize=5)

ax5.bar(capacityfactors.index+1, capacityfactors['MOD-Flex'], 2, color = dict_colors_for_scn['MOD-Flex'], label = 'MOD-Flex')
ax5.bar(capacityfactors.index+3, capacityfactors['STR-Flex'], 2, color = dict_colors_for_scn['STR-Flex'], label = 'STR-Flex')
ax5.legend(fancybox = False, edgecolor='none')
ax5.set_xticks([2030, 2040, 2050, 2060])
ax5.set_xlabel('operation period', labelpad=0)
ax5.set_ylabel('hours')
ax5.set_ylim([0, 5000])
ax5.set_title('c', loc='left', y=1, fontweight='bold')

for col in ageLoss.columns:
    ax6.plot(ageLoss.index.values, ageLoss[col].values, color = dict_colors_for_scn[col], label=col, linewidth=2)
ax6.legend(fancybox = False, edgecolor='none')
ax6.set_xlabel('installation period')
ax6.set_ylabel('years')
ax6.set_xticks(ageLoss.index.values)
ax6.set_xticklabels(['%d-%d' %(yr-1, yr+3) for yr in ageLoss.index], rotation=45)
ax6.set_title('f', loc='left', y=1, fontweight='bold')

plt.subplots_adjust(wspace=0.1, hspace=0.2)
plt.savefig('../figures/fig1.png', bbox_inches = 'tight', pad_inches = 0.1, dpi=600)