INSERT INTO `sys_datasource_meta` (`code`, `name`, `category`, `form_schema`)
SELECT
    'inceptor',
    '星环 Inceptor',
    'Big Data',
    '[{"name": "host", "label": "Host", "type": "input", "required": true, "props": {"placeholder": "10.10.1.30"}}, {"name": "port", "label": "Port", "type": "number", "required": true, "props": {"defaultValue": 10000}}, {"name": "database", "label": "Database Name", "type": "input", "required": true}, {"name": "username", "label": "Username", "type": "input", "required": true}, {"name": "password", "label": "Password", "type": "password", "required": true}, {"name": "jdbcParams", "label": "JDBC Params", "type": "input", "required": false, "props": {"placeholder": "auth=noSasl"}}, {"name": "driverClass", "label": "Driver Class", "type": "input", "required": false, "props": {"defaultValue": "io.transwarp.jdbc.InceptorDriver"}}, {"name": "jdbcUrl", "label": "JDBC URL Override", "type": "input", "required": false, "props": {"placeholder": "jdbc:hive2://host:10000/database"}}]'
WHERE NOT EXISTS (
    SELECT 1 FROM `sys_datasource_meta` WHERE `code` = 'inceptor'
);
