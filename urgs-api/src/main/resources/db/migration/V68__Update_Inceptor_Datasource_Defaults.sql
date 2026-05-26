DROP PROCEDURE IF EXISTS update_inceptor_datasource_defaults;

DELIMITER $$

CREATE PROCEDURE update_inceptor_datasource_defaults()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF EXISTS (SELECT 1 FROM `sys_datasource_meta` WHERE `code` = 'inceptor') THEN
        UPDATE `sys_datasource_meta`
        SET `form_schema` = '[{"name": "host", "label": "Host", "type": "input", "required": true, "props": {"placeholder": "10.10.1.30"}}, {"name": "port", "label": "Port", "type": "number", "required": true, "props": {"defaultValue": 10000}}, {"name": "database", "label": "Database Name", "type": "input", "required": true}, {"name": "username", "label": "Username", "type": "input", "required": true}, {"name": "password", "label": "Password", "type": "password", "required": true}, {"name": "jdbcParams", "label": "JDBC Params", "type": "input", "required": false, "props": {"placeholder": "auth=noSasl", "defaultValue": "auth=noSasl"}}, {"name": "driverClass", "label": "Driver Class", "type": "input", "required": false, "props": {"defaultValue": "org.apache.hive.jdbc.HiveDriver"}}, {"name": "jdbcUrl", "label": "JDBC URL Override", "type": "input", "required": false, "props": {"placeholder": "jdbc:inceptor2://host:10000/database"}}]'
        WHERE `code` = 'inceptor';

        UPDATE `sys_datasource_config` c
        JOIN `sys_datasource_meta` m ON m.`id` = c.`meta_id`
        SET c.`connection_params` = JSON_SET(c.`connection_params`, '$.driverClass', 'org.apache.hive.jdbc.HiveDriver')
        WHERE m.`code` = 'inceptor'
          AND JSON_UNQUOTE(JSON_EXTRACT(c.`connection_params`, '$.driverClass')) = 'io.transwarp.jdbc.InceptorDriver';

        UPDATE `sys_datasource_config` c
        JOIN `sys_datasource_meta` m ON m.`id` = c.`meta_id`
        SET c.`connection_params` = JSON_SET(c.`connection_params`, '$.jdbcParams', 'auth=noSasl')
        WHERE m.`code` = 'inceptor'
          AND (
              JSON_EXTRACT(c.`connection_params`, '$.jdbcParams') IS NULL
              OR JSON_UNQUOTE(JSON_EXTRACT(c.`connection_params`, '$.jdbcParams')) = ''
          );

        UPDATE `sys_datasource_config` c
        JOIN `sys_datasource_meta` m ON m.`id` = c.`meta_id`
        SET c.`connection_params` = JSON_SET(
            c.`connection_params`,
            '$.jdbcUrl',
            REPLACE(JSON_UNQUOTE(JSON_EXTRACT(c.`connection_params`, '$.jdbcUrl')), 'jdbc:hive2://', 'jdbc:inceptor2://')
        )
        WHERE m.`code` = 'inceptor'
          AND JSON_UNQUOTE(JSON_EXTRACT(c.`connection_params`, '$.jdbcUrl')) LIKE 'jdbc:hive2://%';

        UPDATE `sys_datasource_config` c
        JOIN `sys_datasource_meta` m ON m.`id` = c.`meta_id`
        SET c.`connection_params` = JSON_SET(
            c.`connection_params`,
            '$.jdbcUrl',
            CONCAT(JSON_UNQUOTE(JSON_EXTRACT(c.`connection_params`, '$.jdbcUrl')), ';auth=noSasl')
        )
        WHERE m.`code` = 'inceptor'
          AND JSON_EXTRACT(c.`connection_params`, '$.jdbcUrl') IS NOT NULL
          AND JSON_UNQUOTE(JSON_EXTRACT(c.`connection_params`, '$.jdbcUrl')) <> ''
          AND LOWER(JSON_UNQUOTE(JSON_EXTRACT(c.`connection_params`, '$.jdbcUrl'))) NOT LIKE '%;auth=%'
          AND LOWER(JSON_UNQUOTE(JSON_EXTRACT(c.`connection_params`, '$.jdbcUrl'))) NOT LIKE '%;principal=%';
    END IF;
END$$

DELIMITER ;

CALL update_inceptor_datasource_defaults();

DROP PROCEDURE IF EXISTS update_inceptor_datasource_defaults;
