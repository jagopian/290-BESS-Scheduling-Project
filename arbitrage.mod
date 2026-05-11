# Sets
set T; # Time steps 
set H;
set MAP within {H, T}; # Mapping of hours to time steps

# General Parameters 
param SOC_0;           # Initial SOC (MWh)
# param P_CH_0;
# param P_G_0;
# param SOC_T_limit;     # Terminal SOC (MWh)
param SOC_cap;         # Total Storage capacity (MWh)
param P_CH_max;        # Max charging power (MW)
param P_G_max;         # Max discharging power (MW)
param eff_ch;          # Charging efficiency (%)
param eff_g;           # Discharging efficiency (%)
# param RUP;             # Ramping up limit (MW/h)
# param RDWN;            # Ramping down limit (MW/h)
param num_t_per_hour;   # Number of time steps per hour

param Pi_DA_E{H};      # DA Energy Price($/MWh)
param Pi_RT_E{T};      # RT Energy Price($/MWh)

# Decision Variables [cite: 36]
var y{H} binary;       # DA charge-mode
var z{T} binary;       # RT charge-mode
var pg_DA{H} >= 0;     # DA discharging (MW)
var pch_DA{H} >= 0;    # DA charging (MW)
var pg_RT{T} >= 0;     # RT discharging (MW)
var pch_RT{T} >= 0;    # RT charging (MW)
var soc{0..card(T)} >= 0, <= SOC_cap; # (MWh)
var DA_Profit{H};      # DA Profit ($)
var RT_Profit{T};      # RT Profit ($)


maximize Total_Profit: sum {h in H, t in T: (h, t) in MAP} 
((Pi_RT_E[t] / num_t_per_hour) * ((pg_RT[t] - pg_DA[h]) - (pch_RT[t] - pch_DA[h])))
+ sum{h in H} (Pi_DA_E[h] * (pg_DA[h] - pch_DA[h]));

subject to DA_Mode_PCH {h in H}: pch_DA[h] <= y[h] * P_CH_max;

subject to DA_Mode_PG  {h in H}: pg_DA[h] <= (1 - y[h]) * P_G_max;

subject to RT_Mode_PCH {t in T}: pch_RT[t] <= z[t] * P_CH_max;

subject to RT_Mode_PG  {t in T}: pg_RT[t] <= (1 - z[t]) * P_G_max;

subject to RT_Charge_Commitments {h in H, t in T: (h, t) in MAP}:
    pch_RT[t] >= pch_DA[h];

subject to RT_Discharge_Commitments {h in H, t in T: (h, t) in MAP}:
    pg_RT[t] >= pg_DA[h];

subject to SOC_Init: soc[0] = SOC_0;

subject to SOC_Balance {t in T}:
    soc[t] = soc[t-1] + (eff_ch) * (pch_RT[t] / num_t_per_hour) - 
    (1/eff_g) * (pg_RT[t] / num_t_per_hour);

# subject to SOC_Terminal: soc[card(T)] >= SOC_T_limit;

# subject to Charge_Initial: pch_RT[0] = P_CH_0;

# subject to Discharge_Initial: pg_RT[0] = P_G_0;

# subject to Ramp_Up {t in T}:
#     pg_RT[t] - pg_RT[t-1] <= RUP/num_t_per_hour;

# subject to Ramp_Down {t in T}:
#     pg_RT[t-1] - pg_RT[t] <= RDWN/num_t_per_hour;

# subject to Ramp_Up_ch {t in T}:
#     pch_RT[t] - pch_RT[t-1] <= RUP/num_t_per_hour;

# subject to Ramp_Down_ch {t in T}:
#     pch_RT[t-1] - pch_RT[t] <= RDWN/num_t_per_hour;

# subject to Terminal_Discharge: pg_RT[card(T)] <= RDWN/num_t_per_hour;