#%%
import pandas as pd
import matplotlib.pyplot as plt
from get_info import get_gen_techs, get_capac_techs, dict_colors_for_capac, dict_colors_for_gen
plt.rc('font',family='Arial',size=6)

# 生成不同情景agg_5r
scenarios = ['REF-Base', 'REF-Flex', 'MOD-Base', 'MOD-Flex', 'STR-Base', 'STR-Flex']

fig = plt.figure(constrained_layout=True, figsize=(180/25.4, 12/18*180/25.4))
gs = fig.add_gridspec(4, 3, width_ratios=[1, 1, 1], height_ratios = [1, 0.2, 1, 0.2])
axes = []
axes.append((fig.add_subplot(gs[0:1, 0:1])))
axes.append((fig.add_subplot(gs[0:1, 1:2], sharey=axes[0])))
axes.append((fig.add_subplot(gs[0:1, 2:3], sharey=axes[0])))
axes.append((fig.add_subplot(gs[2:3, 0:1])))
axes.append((fig.add_subplot(gs[2:3, 1:2], sharey=axes[3])))
axes.append((fig.add_subplot(gs[2:3, 2:3], sharey=axes[3])))
axes.append(fig.add_subplot(gs[1:2, :]))
axes.append((fig.add_subplot(gs[3:4, :])))
bottoms = []
gen_data_scns = pd.DataFrame()
for scn in scenarios:
    agg_path = "../scn/%s" %scn
    dir_path = agg_path + '/outputs'
    gen_data = get_capac_techs(dir_path).loc[[2030], :]
    gen_data['scn'] = scn
    if gen_data_scns.empty:
        gen_data_scns = gen_data
    else:
        gen_data_scns = pd.concat([gen_data_scns, gen_data], axis=0)
gen_data_scns = gen_data_scns.set_index('scn')

for i, g in enumerate(gen_data_scns.columns):
    bottom1 = gen_data_scns.iloc[:,:i].sum(axis=1)
    axes[0].bar(gen_data_scns.index, gen_data_scns.iloc[:, i], bottom = bottom1, color = dict_colors_for_capac[g], label=g, width=0.8)
axes[0].set_xticklabels([''])
axes[0].set_title('a', loc='left', y=1, fontweight='bold')
axes[0].set_ylabel('Capacity(GW)')
bottoms = []
gen_data_scns = pd.DataFrame()
for scn in scenarios:
    agg_path = "../scn/%s" %scn
    dir_path = agg_path + '/outputs'
    gen_data = get_capac_techs(dir_path).loc[[2045], :]
    gen_data['scn'] = scn
    if gen_data_scns.empty:
        gen_data_scns = gen_data
    else:
        gen_data_scns = pd.concat([gen_data_scns, gen_data], axis=0)
gen_data_scns = gen_data_scns.set_index('scn')

for i, g in enumerate(gen_data_scns.columns):
    bottom1 = gen_data_scns.iloc[:,:i].sum(axis=1)
    axes[1].bar(gen_data_scns.index, gen_data_scns.iloc[:, i], bottom = bottom1, color = dict_colors_for_capac[g], label=g, width=0.8)
axes[1].set_xticklabels([''])
axes[1].set_title('b', loc='left', y=1, fontweight='bold')
# axes[1].set_ylabel('Capacity(GW)')

bottoms = []
gen_data_scns = pd.DataFrame()
for scn in scenarios:
    agg_path = "../scn/%s" %scn
    dir_path = agg_path + '/outputs'
    gen_data = get_capac_techs(dir_path).loc[[2060], :]
    gen_data['scn'] = scn
    if gen_data_scns.empty:
        gen_data_scns = gen_data
    else:
        gen_data_scns = pd.concat([gen_data_scns, gen_data], axis=0)
gen_data_scns = gen_data_scns.set_index('scn')

for i, g in enumerate(gen_data_scns.columns):
    bottom1 = gen_data_scns.iloc[:,:i].sum(axis=1)
    axes[2].bar(gen_data_scns.index, gen_data_scns.iloc[:, i], bottom = bottom1, color = dict_colors_for_capac[g], label=g, width=0.8)
axes[2].set_xticklabels([''])
axes[2].set_title('c', loc='left', y=1, fontweight='bold')

axes[6].legend(*axes[1].get_legend_handles_labels(), loc='center', fancybox = False, edgecolor='black', ncol=6)
axes[6].axis('off')

bottoms = []
gen_data_scns = pd.DataFrame()
for scn in scenarios:
    agg_path = "../scn/%s" %scn
    dir_path = agg_path + '/outputs'
    gen_data = get_gen_techs(dir_path).loc[[2030], :]
    gen_data['scn'] = scn
    if gen_data_scns.empty:
        gen_data_scns = gen_data
    else:
        gen_data_scns = pd.concat([gen_data_scns, gen_data], axis=0)
gen_data_scns = gen_data_scns.set_index('scn')

for i, g in enumerate(gen_data_scns.columns):
    if i <= 1:
        bottom1 = gen_data_scns.iloc[:,:i].sum(axis=1)
        axes[3].bar(gen_data_scns.index, gen_data_scns.iloc[:, i], bottom = bottom1, color = dict_colors_for_gen[g], label=g, width=0.8)
    else:
        bottom2 = gen_data_scns.iloc[:, 2:i].sum(axis=1)
        axes[3].bar(gen_data_scns.index, gen_data_scns.iloc[:, i], bottom = bottom2, color = dict_colors_for_gen[g], label=g, width=0.8)
axes[3].set_xticks(gen_data_scns.index)
axes[3].set_xticklabels(scenarios, rotation=30)
axes[3].set_title('d', loc='left', y=1, fontweight='bold')
axes[3].set_ylabel('Generation(TWh)')

bottoms = []
gen_data_scns = pd.DataFrame()
for scn in scenarios:
    agg_path = "../scn/%s" %scn
    dir_path = agg_path + '/outputs'
    gen_data = get_gen_techs(dir_path).loc[[2045], :]
    gen_data['scn'] = scn
    if gen_data_scns.empty:
        gen_data_scns = gen_data
    else:
        gen_data_scns = pd.concat([gen_data_scns, gen_data], axis=0)
gen_data_scns = gen_data_scns.set_index('scn')

for i, g in enumerate(gen_data_scns.columns):
    if i <= 1:
        bottom1 = gen_data_scns.iloc[:,:i].sum(axis=1)
        axes[4].bar(gen_data_scns.index, gen_data_scns.iloc[:, i], bottom = bottom1, color = dict_colors_for_gen[g], label=g, width=0.8)
    else:
        bottom2 = gen_data_scns.iloc[:, 2:i].sum(axis=1)
        axes[4].bar(gen_data_scns.index, gen_data_scns.iloc[:, i], bottom = bottom2, color = dict_colors_for_gen[g], label=g, width=0.8)
axes[4].set_xticks(gen_data_scns.index)
axes[4].set_xticklabels(scenarios, rotation=30)
axes[4].set_title('e', loc='left', y=1, fontweight='bold')

bottoms = []
gen_data_scns = pd.DataFrame()
for scn in scenarios:
    agg_path = "../scn/%s" %scn
    dir_path = agg_path + '/outputs'
    gen_data = get_gen_techs(dir_path).loc[[2060], :]
    gen_data['scn'] = scn
    if gen_data_scns.empty:
        gen_data_scns = gen_data
    else:
        gen_data_scns = pd.concat([gen_data_scns, gen_data], axis=0)
gen_data_scns = gen_data_scns.set_index('scn')

for i, g in enumerate(gen_data_scns.columns):
    if i <= 1:
        bottom1 = gen_data_scns.iloc[:,:i].sum(axis=1)
        axes[5].bar(gen_data_scns.index, gen_data_scns.iloc[:, i], bottom = bottom1, color = dict_colors_for_gen[g], label=g, width=0.8)
    else:
        bottom2 = gen_data_scns.iloc[:, 2:i].sum(axis=1)
        axes[5].bar(gen_data_scns.index, gen_data_scns.iloc[:, i], bottom = bottom2, color = dict_colors_for_gen[g], label=g, width=0.8)
axes[5].set_xticks(gen_data_scns.index)
axes[5].set_xticklabels(scenarios, rotation=30)
axes[5].set_title('f', loc='left', y=1, fontweight='bold')

axes[7].legend(*axes[4].get_legend_handles_labels(), loc='center', fancybox = False, edgecolor='black', ncol=6)
axes[7].axis('off')
plt.savefig('../figures/fig2.png', dpi=600, bbox_inches = 'tight', pad_inches = 0.1)