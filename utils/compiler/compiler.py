import sys
import re
from difflib import get_close_matches

from params import instructions

def list_to_mem(l, filename):
    with open(filename, 'w') as f:
        f.write('//format=mti addressradix=d dataradix=d version=1.0 wordsperline=1\n')
        for i, x in enumerate(l):
            f.write(f'{i}: {x}\n')

statements = {
    'label' : r'([a-zA-Z_0-9]*):',
    'instruction' : r'([A-Z]+)( (\d+(,\d+)*))*',
    'comment' : r'//.*'
}

def parse_labels(filelines):
    labels = {}
    i = 0
    for line in filelines:
        found = re.search(statements['label'], line)
        if found:
            label = found.group(1)
            labels[label] = i
        else:
            i+=1
    return labels

def compile(filename):
    with open(filename) as f:

        filelines = f.read().split('\n')
        labels = parse_labels(filelines)

        error_count = 0
        binary = []
        i = 0
        for fileline, line in enumerate(filelines,1):
            if re.search(statements['label'], line) or re.search(statements['comment'], line):
                continue

            instruction = re.search(statements['instruction'], line)
            if not instruction:
                print(f'{filename}({fileline}): Unrecognized instruction')
                error_count += 1
                continue

            mnemonic = instruction.group(1)
            args = [int(arg) for arg in instruction.group(3).split(',')] \
                if instruction.group(3) else []
            
            if mnemonic in instructions:
                try:
                    microcode = instructions[mnemonic](*args)
                    binary.append(microcode)
                except ValueError as error:
                    print(f'{filename}({fileline}): {error.args[0]}')                    
                    error_count += 1
            else:
                suggestions = get_close_matches(mnemonic, instructions.keys(), n=3)
                if len(suggestions) > 0:
                    suggestions_str = ','.join(suggestions)
                    print(f'{filename}({fileline}): Mnemonic "{mnemonic}" not found, did you mean \"{suggestions_str}\"?')
                else:
                    print(f'{filename}({fileline}): Mnemonic "{mnemonic}" not found')
                                    
                error_count += 1

        if error_count:
            print(f'{error_count} error{"s" if error_count > 1 else ""} found in {filename}')
            return None

        print('Compiled successfully')
        return binary

if __name__ == '__main__':
    binary = compile(sys.argv[1])
    if binary:
        list_to_mem(binary,sys.argv[2])