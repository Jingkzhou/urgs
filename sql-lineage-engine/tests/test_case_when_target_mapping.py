from parsers.indirect_flow_parser import IndirectFlowParser
from parsers.sql_parser import LineageParser


def test_case_when_value_and_condition_keep_explicit_insert_target_column():
    sql = """
    INSERT INTO PBOCD_JS_201_CLDWDK (
        LOAN_DUE_DATE,
        DEFER_END_DATE,
        CURR_CODE,
        INT_REPRICE_DATE
    )
    SELECT
        TO_CHAR(T.MATURITY_DT, 'YYYY-MM-DD') AS LOAN_DUE_DATE,
        CASE
            WHEN ZQ.EXTENDTERM_FLG = 'Y'
            THEN TO_CHAR(ZQ.ACTUAL_MATURITY_DT, 'YYYY-MM-DD')
        END DEFER_END_DATE,
        T.CURR_CD CURR_CODE,
        CASE
            WHEN T.EXTENDTERM_FLG = 'Y'
            THEN TO_CHAR(T.ACTUAL_MATURITY_DT, 'YYYY-MM-DD')
        END AS INT_REPRICE_DATE
    FROM PM_RSDATA.SMTMODS_L_ACCT_LOAN T
    LEFT JOIN PM_RSDATA.SMTMODS_V_PUB_IDX_DK_ZQDQRJJ ZQ
      ON T.LOAN_NUM = ZQ.LOAN_NUM
    """
    parser = IndirectFlowParser("oracle")
    deps = parser.parse(sql)
    pairs = {
        (
            dep.get("source_table", "").upper(),
            dep.get("source_column", "").upper(),
            dep.get("target_column", "").upper(),
            dep.get("dependency_type", "").upper(),
        )
        for dep in deps
    }

    assert (
        "PM_RSDATA.SMTMODS_V_PUB_IDX_DK_ZQDQRJJ",
        "EXTENDTERM_FLG",
        "DEFER_END_DATE",
        "CASE_WHEN",
    ) in pairs
    assert (
        "PM_RSDATA.SMTMODS_V_PUB_IDX_DK_ZQDQRJJ",
        "ACTUAL_MATURITY_DT",
        "DEFER_END_DATE",
        "FDD",
    ) in pairs
    assert (
        "PM_RSDATA.SMTMODS_V_PUB_IDX_DK_ZQDQRJJ",
        "ACTUAL_MATURITY_DT",
        "INT_REPRICE_DATE",
        "FDD",
    ) not in pairs


def test_constant_case_condition_is_not_direct_value_lineage(
    mock_metadata_resolver,
    monkeypatch,
):
    sql = """
    INSERT INTO TARGET_TABLE (ITEM_NUM)
    SELECT CASE CURR_CD
             WHEN 'USD' THEN 'A'
             WHEN 'EUR' THEN 'B'
           END AS ITEM_NUM
      FROM SOURCE_TABLE
     GROUP BY CASE CURR_CD
                WHEN 'USD' THEN 'A'
                WHEN 'EUR' THEN 'B'
              END
    """
    parser = LineageParser("oracle")
    monkeypatch.setattr(
        parser.parser,
        "parse",
        lambda *_args, **_kwargs: {
            "gsp_json": {
                "dlineage": {
                    "relationships": [
                        {
                            "type": "fdd",
                            "target": {
                                "parentName": "TARGET_TABLE",
                                "column": "ITEM_NUM",
                            },
                            "sources": [
                                {
                                    "parentName": "SOURCE_TABLE",
                                    "column": "CURR_CD",
                                }
                            ],
                        }
                    ]
                }
            }
        },
    )

    deps = parser.get_column_lineage(sql)
    facts = {
        (
            dep.get("source_column"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("neo4j_type"),
        )
        for dep in deps
    }

    assert ("CURR_CD", "ITEM_NUM", "CASE_WHEN", "CASE_WHEN") in facts
    assert ("CURR_CD", "*", "fdr", "GROUPS") in facts
    assert ("CURR_CD", "ITEM_NUM", "fdd", None) not in facts
    assert ("CURR_CD", "*", "CASE_WHEN", "CASE_WHEN") not in facts


def test_case_value_column_keeps_direct_value_lineage(
    mock_metadata_resolver,
    monkeypatch,
):
    sql = """
    INSERT INTO TARGET_TABLE (ITEM_VAL)
    SELECT CASE
             WHEN STATUS = 'A' THEN AMOUNT
             ELSE FALLBACK_AMOUNT
           END AS ITEM_VAL
      FROM SOURCE_TABLE
    """
    parser = LineageParser("oracle")
    monkeypatch.setattr(
        parser.parser,
        "parse",
        lambda *_args, **_kwargs: {
            "gsp_json": {
                "dlineage": {
                    "relationships": [
                        {
                            "type": "fdd",
                            "target": {
                                "parentName": "TARGET_TABLE",
                                "column": "ITEM_VAL",
                            },
                            "sources": [
                                {
                                    "parentName": "SOURCE_TABLE",
                                    "column": "STATUS",
                                },
                                {
                                    "parentName": "SOURCE_TABLE",
                                    "column": "AMOUNT",
                                },
                                {
                                    "parentName": "SOURCE_TABLE",
                                    "column": "FALLBACK_AMOUNT",
                                },
                            ],
                        }
                    ]
                }
            }
        },
    )

    direct_sources = {
        dep.get("source_column")
        for dep in parser.get_column_lineage(sql)
        if dep.get("target_column") == "ITEM_VAL"
        and dep.get("dependency_type") == "fdd"
    }

    assert direct_sources == {"AMOUNT", "FALLBACK_AMOUNT"}


def test_case_condition_column_used_as_value_keeps_direct_lineage(
    mock_metadata_resolver,
    monkeypatch,
):
    sql = """
    INSERT INTO TARGET_TABLE (ITEM_VAL)
    SELECT CASE WHEN AMOUNT > 0 THEN AMOUNT ELSE 0 END AS ITEM_VAL
      FROM SOURCE_TABLE
    """
    parser = LineageParser("oracle")
    monkeypatch.setattr(
        parser.parser,
        "parse",
        lambda *_args, **_kwargs: {
            "gsp_json": {
                "dlineage": {
                    "relationships": [
                        {
                            "type": "fdd",
                            "target": {
                                "parentName": "TARGET_TABLE",
                                "column": "ITEM_VAL",
                            },
                            "sources": [
                                {
                                    "parentName": "SOURCE_TABLE",
                                    "column": "AMOUNT",
                                }
                            ],
                        }
                    ]
                }
            }
        },
    )

    deps = parser.get_column_lineage(sql)

    assert any(
        dep.get("source_column") == "AMOUNT"
        and dep.get("target_column") == "ITEM_VAL"
        and dep.get("dependency_type") == "fdd"
        for dep in deps
    )


def test_nested_union_constant_case_condition_is_not_direct_value_lineage(
    mock_metadata_resolver,
    monkeypatch,
):
    sql = """
    INSERT INTO TARGET_TABLE (ITEM_NUM)
    SELECT ITEM_NUM
      FROM (
            SELECT CASE A.CURR_CD
                     WHEN 'USD' THEN 'A'
                     WHEN 'EUR' THEN 'B'
                   END AS ITEM_NUM
              FROM SOURCE_TABLE A
            UNION
            SELECT CASE A.CURR_CD
                     WHEN 'USD' THEN 'A'
                     WHEN 'EUR' THEN 'B'
                   END AS ITEM_NUM
              FROM SOURCE_TABLE A
           ) U
     GROUP BY ITEM_NUM
    """
    parser = LineageParser("hive")
    monkeypatch.setattr(
        parser.parser,
        "parse",
        lambda *_args, **_kwargs: {
            "gsp_json": {
                "dlineage": {
                    "relationships": [
                        {
                            "type": "fdd",
                            "target": {
                                "parentName": "TARGET_TABLE",
                                "column": "ITEM_NUM",
                            },
                            "sources": [
                                {
                                    "parentName": "SOURCE_TABLE",
                                    "column": "CURR_CD",
                                }
                            ],
                        }
                    ]
                }
            }
        },
    )

    deps = parser.get_column_lineage(sql)

    assert any(
        dep.get("source_column") == "CURR_CD"
        and dep.get("target_column") == "ITEM_NUM"
        and dep.get("neo4j_type") == "CASE_WHEN"
        for dep in deps
    )
    assert not any(
        dep.get("source_column") == "CURR_CD"
        and dep.get("target_column") == "ITEM_NUM"
        and dep.get("dependency_type") == "fdd"
        for dep in deps
    )
