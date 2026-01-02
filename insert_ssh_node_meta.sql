INSERT INTO `sys_datasource_meta` (`code`, `name`, `category`, `form_schema`, `create_time`) VALUES
('ssh_node', 'SSH 远程节点', 'compute', '[
    {"field": "host", "label": "主机地址", "type": "input", "required": true, "placeholder": "请输入 IP 或域名"},
    {"field": "port", "label": "端口", "type": "number", "required": true, "defaultValue": 22},
    {"field": "username", "label": "用户名", "type": "input", "required": true},
    {"field": "password", "label": "密码", "type": "password", "required": true},
    {"field": "dataxHome", "label": "DataX 安装路径", "type": "input", "required": true, "defaultValue": "/opt/module/datax", "placeholder": "例如: /opt/module/datax"}
]', NOW());
