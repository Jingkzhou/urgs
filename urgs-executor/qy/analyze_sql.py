
import re

INPUT_FILE = 't_quartz_task.sql'

def parse_sql_value(value):
    if value == 'NULL':
        return None
    if value.startswith("'") and value.endswith("'"):
        return value[1:-1]
    return value

def parse_insert_statement(line):
    match = re.search(r"INSERT INTO `t_quartz_task` VALUES \((.*)\);", line)
    if not match:
        return None
    
    values_str = match.group(1)
    values = []
    current_val = ""
    in_quote = False
    escape = False
    
    for char in values_str:
        if escape:
            current_val += char
            escape = False
        elif char == '\\':
            escape = True
            current_val += char
        elif char == "'" and not escape:
            in_quote = not in_quote
            current_val += char
        elif char == ',' and not in_quote:
            values.append(parse_sql_value(current_val.strip()))
            current_val = ""
        else:
            current_val += char
    values.append(parse_sql_value(current_val.strip()))
    return values

def analyze():
    print(f"Analyzing {INPUT_FILE}...")
    task_beans = set()
    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        for line in f:
            if line.startswith("INSERT INTO `t_quartz_task`"):
                vals = parse_insert_statement(line)
                if vals:
                    task_beans.add(vals[2])
    
    print(f"Unique task_bean values: {task_beans}")

if __name__ == '__main__':
    analyze()
