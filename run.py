# ===========================================================
#                 Running
# ===========================================================
# This script is responsible for running the CHEER/Power model

# Author: Kangxin An
# Date: 2025.01.11
# Version: 1.0
# ===========================================================

from julia import Main as jl
from gen_summary import gen_sum

scenario_name = 'case' # replace by the name of scenario folder
jl.include("core_model.jl")
jl.run_model(scenario_name) 
gen_sum(scenario_name)