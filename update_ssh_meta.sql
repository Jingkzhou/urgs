-- 更新现有的 SSH 数据源元数据，添加 dataxHome 字段 (选填)
UPDATE `sys_datasource_meta` 
SET `form_schema` = '[
    {"name": "host", "label": "host", "type": "input", "required": true}, 
    {"name": "port", "label": "port", "type": "number", "required": true, "props": {"defaultValue": 22}}, 
    {"name": "username", "label": "username", "type": "input", "required": true}, 
    {"name": "password", "label": "password", "type": "password", "required": true},
    {"name": "dataxHome", "label": "DataX Home", "type": "input", "required": false, "help": "Remote DataX installation path (Optional in config, but required for remote task execution)"}
]'
WHERE `code` = 'ssh';
