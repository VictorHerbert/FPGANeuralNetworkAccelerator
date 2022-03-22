import re
import subprocess



s = subprocess.run(['vsim', '-c', '-do', 'src/simulation/run_lint.do'], stdout=subprocess.PIPE) \
    .stdout \
    .decode('utf-8') \
    .replace('\r','')

print(s)

r = re.findall('(Warning|Error|Note)( .*?)?: \(.*\) (.*.sv)\((\d*)\): (\[.*?\] - )?(.*)', s)

errors = []

for entry in r:
    errors.append((entry[0], entry[2], entry[3], entry[5]))


r = re.findall('(Warning|Error|Note)( .*?)?: (\(vsim-\d*\) )?(\[.*?\] - )?(.*)\n#    Time: .* (.*.sv) Line: (\d*)',s)

for entry in r:
    errors.append((entry[0], entry[5], entry[6], entry[4]))

for i,error in enumerate(errors):
    print(error[0], error[1], error[2], i+1, error[3], sep='|')
