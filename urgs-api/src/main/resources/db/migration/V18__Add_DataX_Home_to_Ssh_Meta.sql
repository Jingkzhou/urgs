UPDATE `sys_datasource_meta`
SET `form_schema` = '[{"name": "host", "label": "host", "type": "input", "required": true}, {"name": "port", "label": "port", "type": "number", "required": true, "props": {"defaultValue": 22}}, {"name": "username", "label": "username", "type": "input", "required": true}, {"name": "password", "label": "password", "type": "password", "required": true}, {"name": "dataxHome", "label": "DataX Home", "type": "input", "required": false, "props": {"placeholder": "/home/user/datax"}}]'
WHERE `code` = 'ssh';
