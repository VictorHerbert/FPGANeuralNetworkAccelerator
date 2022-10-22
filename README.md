# FPGA Neural Network Accelerator

## Requirements

* Python 3.7 + 
* Mentor Modelsim*

*Other simulators may work with some tweaks, not tested

## Verification

Use the golden_model module to generate test vectors in 'src/testbench/vector'

```
python -m golden_model
```

Run 'src/testbench/testbench.sv' testbench to generate a log.txt file as follows

```
Case           0: MSE 0.000122
Case           1: MSE 0.000244
Case           2: MSE 0.000000
Case           3: MSE 0.000244
...            ...
```