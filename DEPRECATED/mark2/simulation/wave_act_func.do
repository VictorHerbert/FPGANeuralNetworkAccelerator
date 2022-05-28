transcript off

set NU_COUNT [examine -unsigned definitions.NU_COUNT]
set Q_FRAC [examine -unsigned definitions.Q_FRAC]
set ACT_A_Q_FRAC [examine -unsigned definitions.ACT_A_Q_FRAC]
set ACT_B_Q_FRAC [examine -unsigned definitions.ACT_B_Q_FRAC]

radix unsigned
radix define fx -fixed -fraction $Q_FRAC -precision 2 -base decimal -signed

radix define fx_prod_full -fixed -fraction 24 -precision 2 -base decimal -signed
radix define act_a_fx -fixed -fraction $ACT_A_Q_FRAC -precision 2 -base decimal -signed
radix define act_b_fx -fixed -fraction $ACT_B_Q_FRAC -precision 2 -base decimal -signed

radix define fx_prod -fixed -fraction 16 -precision 2 -base decimal -signed


add wave -divider "Activation Function"
add wave -radix unsigned act_funct/mask
add wave -radix fx -analog -height 100 -min -8 -max 8 act_funct/x
add wave -radix act_a_fx act_funct/a_coef
add wave -radix act_b_fx act_funct/b_coef
add wave -radix fx -analog -height 100 -min -1 -max 1 act_funct/fx

mem load -i ../memories/act_func.mem -format mti act_funct/lookup_table/data


run -all
wave zoom range 0ns 180000ns
