DROP PROCEDURE IF EXISTS remove_inceptor_nosasl_default;

DELIMITER $$

CREATE PROCEDURE remove_inceptor_nosasl_default()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF EXISTS (SELECT 1 FROM `sys_datasource_meta` WHERE `code` = 'inceptor') THEN
        UPDATE `sys_datasource_meta`
        SET `form_schema` = '[{"name": "host", "label": "Host", "type": "input", "required": true, "props": {"placeholder": "10.10.1.30"}}, {"name": "port", "label": "Port", "type": "number", "required": true, "props": {"defaultValue": 10000}}, {"name": "database", "label": "Database Name", "type": "input", "required": true}, {"name": "username", "label": "Username", "type": "input", "required": true}, {"name": "password", "label": "Password", "type": "password", "required": true}, {"name": "jdbcParams", "label": "JDBC Params", "type": "input", "required": false, "props": {"placeholder": "留空使用用户名密码；免认证填 auth=noSasl；HTTP 模式填 transportMode=http;httpPath=cliservice"}}, {"name": "driverClass", "label": "Driver Class", "type": "input", "required": false, "props": {"defaultValue": "org.apache.hive.jdbc.HiveDriver"}}, {"name": "jdbcUrl", "label": "JDBC URL Override", "type": "input", "required": false, "props": {"placeholder": "jdbc:inceptor2://host:10000/database"}}]'
        WHERE `code` = 'inceptor';

        UPDATE `sys_datasource_config` c
        JOIN `sys_datasource_meta` m ON m.`id` = c.`meta_id`
        SET c.`connection_params` = JSON_REMOVE(c.`connection_params`, '$.jdbcParams')
        WHERE m.`code` = 'inceptor'
          AND LOWER(JSON_UNQUOTE(JSON_EXTRACT(c.`connection_params`, '$.jdbcParams'))) = 'auth=nosasl';

        UPDATE `sys_datasource_config` c
        JOIN `sys_datasource_meta` m ON m.`id` = c.`meta_id`
        SET c.`connection_params` = JSON_SET(
            c.`connection_params`,
            '$.jdbcUrl',
            LEFT(JSON_UNQUOTE(JSON_EXTRACT(c.`connection_params`, '$.jdbcUrl')), CHAR_LENGTH(JSON_UNQUOTE(JSON_EXTRACT(c.`connection_params`, '$.jdbcUrl'))) - CHAR_LENGTH(';auth=noSasl'))
        )
        WHERE m.`code` = 'inceptor'
          AND LOWER(JSON_UNQUOTE(JSON_EXTRACT(c.`connection_params`, '$.jdbcUrl'))) LIKE '%;auth=nosasl';
    END IF;
END$$

DELIMITER ;

CALL remove_inceptor_nosasl_default();

DROP PROCEDURE IF EXISTS remove_inceptor_nosasl_default;
