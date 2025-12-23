
import re
import json

delete_ids = {
    '10002', '10003', '10004', '10005', '10006', '10007', '10008', '10009', '10010', 
    '10011', '10012', '10013', '10014', '10015', '10016', '10017', '10018', '10019', 
    '10020', '10021', '10022', '10023', '10024', '10025', '10026', '10027', '10028', 
    '10029', '10030', '10031', '10032', '10033', '10034', '10035', '10036', '10037', 
    '10038', '10039', '10040', '10041', '10042', '10043', '10044', '10045', '10046', 
    '10047', '10048', '10049', '10050', '10051', '10052', '10053', '10054', '10055', 
    '10056', '10057', '10058', '10059', '10060', '10061', '10062', '10063', '10064', 
    '10065', '10066', '10067', '10068', '10069', '10070', '10071', '10073', '10074', 
    '10075', '10076', '10077', '10078', '10079', '10080', '10081', '10082', '10083', 
    '10084', '10085', '10086', '10087', '10088', '10089', '10090', '10091', '10092', 
    '10093', '10094', '10095', '10096', '10097', '10098', '10099', '10100', '10101', 
    '10102', '10103', '10104', '10105', '10106', '10107', '10108', '10109', '10110', 
    '10111', '10112', '10113', '10114', '10115', '10116', '10117', '10118', '10119', 
    '10120', '10681', '10122', '10123', '10129', '10131', '10130', '10134', '10127', 
    '10128', '10680', '10135', '10553', '10676', '10640', '10652', '10813'
}

print(f"-- DELETE FROM sys_task")
ids_list = [f"'{x}'" for x in delete_ids]
print(f"DELETE FROM sys_task WHERE id IN ({', '.join(ids_list)});")
print()

file_path = '/Users/work/Documents/gitee/urgs/migrated_urgs_data.sql'

with open(file_path, 'r', encoding='utf-8') as f:
    for line in f:
        if line.startswith("INSERT INTO `sys_workflow`"):
            # Extract content JSON
            # Pattern: INSERT INTO `sys_workflow` ... VALUES (id, 'name', 'desc', 'JSON_CONTENT', ...)
            # We can use regex to roughly grab the values. 
            # CAUTION: JSON might contain escaped quotes.
            # Assuming simple structure for now based on file view.
            
            # Find the position of the content field.
            # VALUES (1, 'LDM接口表', 'Migrated from LDM接口表', '{...}', 'admin')
            
            match = re.search(r"VALUES \(\d+, '[^']+', '[^']+', '(\{.*?\})',", line)
            if not match:
                # Try pattern where description might be NULL or different
                # VALUES (1, 'name', NULL, '{...}', ...)
                match = re.search(r"VALUES \(\d+, '[^']+', (?:'[^']+'|NULL), '(\{.*?\})',", line)
            
            if match:
                json_str = match.group(1)
                # Unescape escaped single quotes in SQL string if any (though usually json uses double quotes)
                # The SQL string itself might have escaped characters.
                # In the file view: '{"nodes": ...}'
                
                try:
                    workflow_data = json.loads(json_str)
                    
                    nodes = workflow_data.get('nodes', [])
                    edges = workflow_data.get('edges', [])
                    
                    original_node_count = len(nodes)
                    original_edge_count = len(edges)
                    
                    # Filter nodes
                    new_nodes = [n for n in nodes if str(n.get('data', {}).get('id')) not in delete_ids and str(n.get('id')) not in delete_ids]
                    
                    # Also collect IDs of deleted nodes to remove edges properly
                    remaining_node_ids = set(n.get('id') for n in new_nodes)
                    
                    # Filter edges
                    new_edges = [e for e in edges if e.get('source') in remaining_node_ids and e.get('target') in remaining_node_ids]
                    
                    workflow_data['nodes'] = new_nodes
                    workflow_data['edges'] = new_edges
                    
                    if len(new_nodes) < original_node_count or len(new_edges) < original_edge_count:
                        # Extract Workflow ID
                        wf_id_match = re.search(r"VALUES \((\d+),", line)
                        if wf_id_match:
                            wf_id = wf_id_match.group(1)
                            new_json_str = json.dumps(workflow_data, ensure_ascii=False)
                            # Escape single quotes for SQL
                            new_json_str_sql = new_json_str.replace("'", "\\'")
                            print(f"-- Update sys_workflow ID {wf_id}")
                            print(f"UPDATE sys_workflow SET content = '{new_json_str_sql}' WHERE id = {wf_id};")
                            print()
                            
                except Exception as e:
                    print(f"-- Error parsing JSON for line: {e}")
                    # print(f"-- Line: {line[:100]}...")

