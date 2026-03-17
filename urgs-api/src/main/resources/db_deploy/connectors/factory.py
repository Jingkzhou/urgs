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
        if db_type == 'oracle':
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
