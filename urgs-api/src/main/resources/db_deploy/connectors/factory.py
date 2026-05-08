import os

class DBConnector:
    def execute(self, sql: str):
        raise NotImplementedError()
    def fetch(self, sql: str, params=None) -> list:
        raise NotImplementedError()
    def close(self):
        pass

class OracleConnector(DBConnector):
    def __init__(self, config):
        import cx_Oracle
        self.conn = cx_Oracle.connect(config['user'], config['password'], config['dsn'])
    def execute(self, sql: str):
        cursor = self.conn.cursor()
        cursor.execute(sql)
        self.conn.commit()
        return cursor.rowcount
    def fetch(self, sql: str, params=None) -> list:
        cursor = self.conn.cursor()
        if params:
            cursor.execute(sql, params)
        else:
            cursor.execute(sql)
        return cursor.fetchall()
    def close(self):
        self.conn.close()

class MySQLConnector(DBConnector):
    def __init__(self, config):
        import pymysql
        self.conn = pymysql.connect(
            host=config['host'], port=config['port'],
            user=config['user'], password=config['password'], database=config['database']
        )
    def execute(self, sql: str):
        with self.conn.cursor() as cursor:
            cursor.execute(sql)
            self.conn.commit()
            return cursor.rowcount
    def fetch(self, sql: str, params=None) -> list:
        with self.conn.cursor() as cursor:
            if params:
                cursor.execute(sql, params)
            else:
                cursor.execute(sql)
            return cursor.fetchall()
    def close(self):
        self.conn.close()

class GBaseConnector(MySQLConnector):
    """GBase 8a 兼容 MySQL 协议，直接复用 MySQLConnector"""
    pass

class JdbcConnector(DBConnector):
    """JDBC 通用连接器，用于星环等需要上传 JDBC jar 的数据库平台"""
    def __init__(self, config):
        import jaydebeapi
        jdbc_url = config.get('jdbc_url') or config.get('jdbcUrl')
        driver_class = config.get('driver_class') or config.get('jdbcDriverClass')
        driver_jar = config.get('driver_jar') or config.get('driverJar')
        if not jdbc_url:
            raise ValueError("JDBC config missing jdbc_url")
        if not driver_class:
            raise ValueError("JDBC config missing driver_class")
        if not driver_jar:
            raise ValueError("JDBC config missing driver_jar")
        if not os.path.isabs(driver_jar):
            driver_jar = os.path.abspath(driver_jar)
        if not os.path.exists(driver_jar):
            raise FileNotFoundError(f"JDBC driver jar not found: {driver_jar}")
        self.conn = jaydebeapi.connect(
            driver_class,
            jdbc_url,
            [config.get('user'), config.get('password')],
            driver_jar
        )
    def execute(self, sql: str):
        cursor = self.conn.cursor()
        try:
            cursor.execute(sql)
            if hasattr(self.conn, 'commit'):
                self.conn.commit()
            return cursor.rowcount
        finally:
            cursor.close()
    def fetch(self, sql: str, params=None) -> list:
        cursor = self.conn.cursor()
        try:
            if params:
                cursor.execute(sql, params)
            else:
                cursor.execute(sql)
            return cursor.fetchall()
        finally:
            cursor.close()
    def close(self):
        self.conn.close()

class ConnectorFactory:
    _instances = {}

    @classmethod
    def get_connector(cls, target_name: str, connections_config: dict) -> DBConnector:
        if target_name in cls._instances:
            return cls._instances[target_name]

        config = connections_config.get(target_name)
        if not config:
            raise ValueError(f"Connection config for '{target_name}' not found")

        db_type = config.get('type', '').lower()
        use_jdbc = all(config.get(k) for k in ('jdbc_url', 'driver_class', 'driver_jar'))
        if db_type in ('jdbc', 'xinghuan', 'transwarp') or use_jdbc:
            conn = JdbcConnector(config)
        elif db_type == 'oracle':
            conn = OracleConnector(config)
        elif db_type == 'mysql':
            conn = MySQLConnector(config)
        elif db_type == 'gbase':
            conn = GBaseConnector(config)
        else:
            raise NotImplementedError(f"Database type '{db_type}' not supported yet")

        cls._instances[target_name] = conn
        return conn

    @classmethod
    def close_all(cls):
        for conn in cls._instances.values():
            conn.close()
        cls._instances.clear()
