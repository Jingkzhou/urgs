import json

from parsers.indirect_flow_parser import IndirectFlowParser
from parsers.sql_parser import LineageParser
from utils.metadata_resolver import MetadataResolver
from utils.metadata_pack_resolver import MetadataPackResolver


def write_pack(tmp_path):
    pack = {
        "packVersion": 1,
        "recordId": "test-record",
        "dataSourceId": 1,
        "owner": "ODS",
        "generatedAt": "2026-05-27T00:00:00",
        "tableCount": 5,
        "fieldCount": 12,
        "tables": [
            {
                "id": "a",
                "owner": "ODS",
                "name": "A",
                "qualifiedName": "ODS.A",
                "fields": [
                    {"name": "ID", "type": "VARCHAR(64)", "sortOrder": 1},
                    {"name": "AMOUNT", "type": "DECIMAL(18,2)", "sortOrder": 2},
                    {"name": "K", "type": "VARCHAR(64)", "sortOrder": 3},
                ],
            },
            {
                "id": "b",
                "owner": "ODS",
                "name": "B",
                "qualifiedName": "ODS.B",
                "fields": [
                    {"name": "ID", "type": "VARCHAR(64)", "sortOrder": 1},
                    {"name": "K", "type": "VARCHAR(64)", "sortOrder": 2},
                ],
            },
            {
                "id": "src",
                "owner": "ODS",
                "name": "SRC",
                "qualifiedName": "ODS.SRC",
                "fields": [
                    {"name": "C1", "type": "VARCHAR(64)", "sortOrder": 1},
                    {"name": "C2", "type": "VARCHAR(64)", "sortOrder": 2},
                ],
            },
            {
                "id": "tgt",
                "owner": "MART",
                "name": "TGT",
                "qualifiedName": "MART.TGT",
                "fields": [
                    {"name": "C1", "type": "VARCHAR(64)", "sortOrder": 1},
                    {"name": "C2", "type": "VARCHAR(64)", "sortOrder": 2},
                ],
            },
            {
                "id": "loan",
                "owner": "ODS",
                "name": "LOAN",
                "qualifiedName": "ODS.LOAN",
                "fields": [
                    {"name": "LOAN_NUM", "type": "VARCHAR(64)", "sortOrder": 1},
                    {"name": "CUST_ID", "type": "VARCHAR(64)", "sortOrder": 2},
                    {"name": "DRAWDOWN_DT", "type": "DATE", "sortOrder": 3},
                    {"name": "DATA_DATE", "type": "VARCHAR(8)", "sortOrder": 4},
                ],
            },
        ],
    }
    path = tmp_path / "metadata-pack.json"
    path.write_text(json.dumps(pack), encoding="utf-8")
    return path


def test_metadata_pack_resolves_tables_and_fields(tmp_path):
    path = write_pack(tmp_path)
    resolver = MetadataPackResolver(str(path))

    assert resolver.get_table_fields("ODS.A") == ["ID", "AMOUNT", "K"]
    assert resolver.get_table_fields("A") == ["ID", "AMOUNT", "K"]
    assert resolver.validate_column("ODS.A", "amount")["confidence"] == "HIGH"
    assert resolver.validate_column("ODS.A", "missing")["ambiguity_code"] == "MISSING_COLUMN"


def test_unqualified_column_uses_unique_metadata_match(tmp_path):
    path = write_pack(tmp_path)
    parser = IndirectFlowParser("oracle", resolver=MetadataPackResolver(str(path)))
    deps = parser.parse(
        """
        INSERT INTO MART.TGT (C1)
        SELECT AMOUNT
        FROM ODS.A A
        JOIN ODS.B B ON A.K = B.K
        """
    )

    assert any(
        dep["source_table"] == "ODS.A"
        and dep["source_column"].upper() == "AMOUNT"
        and dep.get("confidence") == "HIGH"
        for dep in deps
    )


def test_unqualified_column_ambiguity_is_marked_as_reference(tmp_path):
    path = write_pack(tmp_path)
    parser = IndirectFlowParser("oracle", resolver=MetadataPackResolver(str(path)))
    deps = parser.parse(
        """
        INSERT INTO MART.TGT (C1)
        SELECT ID
        FROM ODS.A A
        JOIN ODS.B B ON A.K = B.K
        """
    )

    ambiguous = [dep for dep in deps if dep.get("ambiguityCode") == "AMBIGUOUS_COLUMN"]
    assert ambiguous
    assert {dep["source_table"] for dep in ambiguous} == {"ODS.A", "ODS.B"}
    assert {dep["neo4j_type"] for dep in ambiguous} == {"REFERENCES"}


def test_subquery_window_alias_does_not_become_physical_column(tmp_path):
    path = write_pack(tmp_path)
    parser = LineageParser("hive", metadata_file=str(path))
    deps = parser.get_column_lineage(
        """
        INSERT INTO MART.TGT (C1)
        SELECT CASE
                 WHEN LA.RN = 1 THEN '1'
                 WHEN LA.RN >= 2 THEN '0'
               END AS C1
          FROM ODS.A A
          LEFT JOIN (
                SELECT T.LOAN_NUM,
                       ROW_NUMBER() OVER (
                         PARTITION BY T.CUST_ID
                         ORDER BY T.DRAWDOWN_DT ASC, T.LOAN_NUM
                       ) RN
                  FROM ODS.LOAN T
          ) LA ON A.ID = LA.LOAN_NUM
        """
    )

    assert not [
        dep
        for dep in deps
        if dep.get("source_table") == "ODS.LOAN"
        and dep.get("source_column", "").upper() == "RN"
    ]

    case_sources = {
        dep.get("source_column", "").upper()
        for dep in deps
        if dep.get("source_table") == "ODS.LOAN"
        and dep.get("target_table") == "MART.TGT"
        and dep.get("target_column") == "C1"
        and dep.get("dependency_type") == "CASE_WHEN"
    }
    assert {"CUST_ID", "DRAWDOWN_DT", "LOAN_NUM"}.issubset(case_sources)


def test_subquery_star_projection_resolves_outer_column_to_physical_source(tmp_path):
    path = write_pack(tmp_path)
    parser = LineageParser("hive", metadata_file=str(path))
    deps = parser.get_column_lineage(
        """
        INSERT INTO MART.TGT (C1)
        SELECT ABS(A.C1) AS C1
          FROM (SELECT S.* FROM ODS.SRC S) A
        """
    )

    assert any(
        dep.get("source_table") == "ODS.SRC"
        and dep.get("source_column") == "C1"
        and dep.get("target_table") == "MART.TGT"
        and dep.get("target_column") == "C1"
        and dep.get("dependency_type") == "fdd"
        for dep in deps
    )


def test_cte_union_derived_table_expands_all_branch_sources(tmp_path):
    path = write_pack(tmp_path)
    parser = LineageParser("hive", default_schema="PM_RSDATA", metadata_file=str(path))
    deps = parser.get_column_lineage(
        """
        WITH ACCT_LOAN_FARMING_FULL AS (
          SELECT A.LOAN_NUM, A.SNDKFL, F.COOP_LAON_FLAG
            FROM (
              SELECT T.LOAN_NUM, T.SNDKFL
                FROM smtmods_V_PUB_IDX_DK_GRSNDK T
               WHERE T.DATA_DATE = i_date
              UNION ALL
              SELECT T.LOAN_NUM, T.SNDKFL
                FROM smtmods_V_PUB_IDX_DK_GTGSHSNDK T
               WHERE T.DATA_DATE = i_date
              UNION ALL
              SELECT A.LOAN_NUM, A.SNDKFL
                FROM smtmods_V_PUB_IDX_DK_DGSNDK A
                JOIN PM_RSDATA.SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = i_date
               WHERE A.DATA_DATE = i_date
            ) A
            JOIN PM_RSDATA.SMTMODS_L_ACCT_LOAN_FARMING F
              ON A.LOAN_NUM = F.LOAN_NUM
             AND F.DATA_DATE = i_date
        )
        INSERT INTO PM_RSDATA.TGT (LOAN_NUM, SNDKFL, COOP_LAON_FLAG)
        SELECT X.LOAN_NUM, X.SNDKFL, X.COOP_LAON_FLAG
          FROM ACCT_LOAN_FARMING_FULL X
        """
    )

    actual = {
        (
            dep.get("source_table", "").upper(),
            dep.get("source_column", "").upper(),
            dep.get("target_table", "").upper(),
            dep.get("target_column", "").upper(),
        )
        for dep in deps
        if dep.get("dependency_type") == "fdd"
    }

    assert not any(
        dep.get("source_table", "").upper() == "ACCT_LOAN_FARMING_FULL"
        for dep in deps
    )
    assert {
        (
            "PM_RSDATA.SMTMODS_V_PUB_IDX_DK_GRSNDK",
            "LOAN_NUM",
            "PM_RSDATA.TGT",
            "LOAN_NUM",
        ),
        (
            "PM_RSDATA.SMTMODS_V_PUB_IDX_DK_GTGSHSNDK",
            "LOAN_NUM",
            "PM_RSDATA.TGT",
            "LOAN_NUM",
        ),
        (
            "PM_RSDATA.SMTMODS_V_PUB_IDX_DK_DGSNDK",
            "LOAN_NUM",
            "PM_RSDATA.TGT",
            "LOAN_NUM",
        ),
        (
            "PM_RSDATA.SMTMODS_V_PUB_IDX_DK_GRSNDK",
            "SNDKFL",
            "PM_RSDATA.TGT",
            "SNDKFL",
        ),
        (
            "PM_RSDATA.SMTMODS_V_PUB_IDX_DK_GTGSHSNDK",
            "SNDKFL",
            "PM_RSDATA.TGT",
            "SNDKFL",
        ),
        (
            "PM_RSDATA.SMTMODS_V_PUB_IDX_DK_DGSNDK",
            "SNDKFL",
            "PM_RSDATA.TGT",
            "SNDKFL",
        ),
        (
            "PM_RSDATA.SMTMODS_L_ACCT_LOAN_FARMING",
            "COOP_LAON_FLAG",
            "PM_RSDATA.TGT",
            "COOP_LAON_FLAG",
        ),
    }.issubset(actual)


def test_schema_qualified_cte_table_fallback_resolves_to_physical_sources(tmp_path):
    path = write_pack(tmp_path)
    parser = LineageParser("hive", default_schema="PM_RSDATA", metadata_file=str(path))
    cte_registry = {
        "S6301_DATA_COLLECT_GUARANTEE": {
            "physical_tables": {"PM_RSDATA.SMTMODS_L_AGRE_GUA_RELATION"},
            "column_map": {},
        }
    }
    sources, targets, relations, _ = parser._resolve_cte_in_table_results(
        {"PM_RSDATA.S6301_DATA_COLLECT_GUARANTEE"},
        {"PM_RSDATA.YBT_T_6_27"},
        [
            {
                "source": "PM_RSDATA.S6301_DATA_COLLECT_GUARANTEE",
                "target": "PM_RSDATA.YBT_T_6_27",
                "lineage_origin": "regex_fallback",
                "relation_level": "table_fallback",
            }
        ],
        [],
        cte_registry,
    )

    assert sources == {"PM_RSDATA.SMTMODS_L_AGRE_GUA_RELATION"}
    assert targets == {"PM_RSDATA.YBT_T_6_27"}
    assert relations[0]["source"] == "PM_RSDATA.SMTMODS_L_AGRE_GUA_RELATION"


def test_select_star_expands_with_metadata_pack(tmp_path):
    path = write_pack(tmp_path)
    parser = LineageParser.__new__(LineageParser)
    parser.resolver = MetadataResolver(metadata_file=str(path))
    deps = parser._expand_star_dependency(
        {
            "source_table": "ODS.SRC",
            "source_column": "*",
            "target_table": "MART.TGT",
            "target_column": "*",
            "dependency_type": "fdd",
        }
    )
    pairs = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
        )
        for dep in deps
    }

    assert ("ODS.SRC", "C1", "MART.TGT", "C1") in pairs
    assert ("ODS.SRC", "C2", "MART.TGT", "C2") in pairs


def test_select_star_with_explicit_target_columns_pairs_by_position(tmp_path):
    path = write_pack(tmp_path)
    parser = LineageParser.__new__(LineageParser)
    parser.resolver = MetadataResolver(metadata_file=str(path))

    first = parser._expand_star_dependency(
        {
            "source_table": "ODS.SRC",
            "source_column": "*",
            "target_table": "MART.TGT",
            "target_column": "C1",
            "dependency_type": "fdd",
            "_star_target_index": 0,
        }
    )
    second = parser._expand_star_dependency(
        {
            "source_table": "ODS.SRC",
            "source_column": "*",
            "target_table": "MART.TGT",
            "target_column": "C2",
            "dependency_type": "fdd",
            "_star_target_index": 1,
        }
    )
    pairs = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
        )
        for dep in first + second
    }

    assert pairs == {
        ("ODS.SRC", "C1", "MART.TGT", "C1"),
        ("ODS.SRC", "C2", "MART.TGT", "C2"),
    }


def test_duplicate_column_dependencies_are_merged():
    parser = LineageParser.__new__(LineageParser)
    deps = parser._deduplicate_column_dependencies(
        [
            {
                "source_table": "ODS.SRC",
                "source_column": "C1",
                "target_table": "MART.TGT",
                "target_column": "C1",
                "dependency_type": "fdd",
                "confidence": "HIGH",
                "validation_note": "from gsp",
            },
            {
                "source_table": "ODS.SRC",
                "source_column": "C1",
                "target_table": "MART.TGT",
                "target_column": "C1",
                "dependency_type": "fdd",
                "neo4j_type": "DERIVES_TO",
                "confidence": "HIGH",
                "validation_note": "from metadata",
            },
        ]
    )

    assert len(deps) == 1
    assert deps[0]["validation_note"] == "from gsp; from metadata"


def test_duplicate_column_dependencies_are_not_merged_across_statements():
    parser = LineageParser.__new__(LineageParser)
    deps = parser._deduplicate_column_dependencies(
        [
            {
                "statementUid": "stmt-1",
                "source_table": "ODS.SRC",
                "source_column": "C1",
                "target_table": "MART.TGT",
                "target_column": "C1",
                "dependency_type": "fdd",
            },
            {
                "statementUid": "stmt-2",
                "source_table": "ODS.SRC",
                "source_column": "C1",
                "target_table": "MART.TGT",
                "target_column": "C1",
                "dependency_type": "fdd",
            },
        ]
    )

    assert len(deps) == 2


def test_indirect_parser_outputs_statement_and_expression_identity(tmp_path):
    path = write_pack(tmp_path)
    parser = IndirectFlowParser("oracle", resolver=MetadataPackResolver(str(path)))
    deps = parser.parse(
        "INSERT INTO MART.TGT (C1, C2) SELECT S.C1 AS C1, S.C2 FROM ODS.SRC S",
        source_file="/tmp/proc.sql",
    )
    c1_dep = next(dep for dep in deps if dep.get("target_column") == "C1")

    assert c1_dep.get("statementUid")
    assert c1_dep.get("statementHash")
    assert c1_dep.get("projectionIndex") == 0
    assert c1_dep.get("sourceExpression").upper() == "S.C1"
    assert "S.C1" in c1_dep.get("targetExpression").upper()


def test_insert_without_target_columns_uses_target_metadata_order(tmp_path):
    path = write_pack(tmp_path)
    parser = IndirectFlowParser("oracle", resolver=MetadataPackResolver(str(path)))
    deps = parser.parse("INSERT INTO MART.TGT SELECT C1, C2 FROM ODS.SRC")
    pairs = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
        )
        for dep in deps
        if dep.get("context") == "SELECT"
    }

    assert ("ODS.SRC", "C1", "MART.TGT", "C1") in pairs
    assert ("ODS.SRC", "C2", "MART.TGT", "C2") in pairs
    assert not any(dep.get("target_column") == "*" for dep in deps if dep.get("context") == "SELECT")


def test_select_star_uses_prior_insert_column_context_when_metadata_missing(tmp_path):
    path = write_pack(tmp_path)
    parser = LineageParser("hive", default_schema="PM_RSDATA", metadata_file=str(path))
    deps = parser.get_column_lineage(
        """
        INSERT INTO PM_RSDATA.PBOCD_RESULT_JS_201_GRDKFS PARTITION (CJRQ = II_DATADATE)
          (DATA_DATE, ASS_SEC_PRO_TYPE, BASE_INT_RAT)
        SELECT S.C1, S.C2, S.K
          FROM ODS.A S;

        INSERT INTO PM_RSDATA.PBOCD_JS_201_GRDKFS_20251215
        SELECT * FROM PM_RSDATA.PBOCD_RESULT_JS_201_GRDKFS
         WHERE CJRQ = II_DATADATE;
        """
    )

    pairs = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
        )
        for dep in deps
        if dep.get("dependency_type") == "fdd"
        and dep.get("source_table") == "PM_RSDATA.PBOCD_RESULT_JS_201_GRDKFS"
        and dep.get("target_table") == "PM_RSDATA.PBOCD_JS_201_GRDKFS_20251215"
    }

    assert (
        "PM_RSDATA.PBOCD_RESULT_JS_201_GRDKFS",
        "ASS_SEC_PRO_TYPE",
        "PM_RSDATA.PBOCD_JS_201_GRDKFS_20251215",
        "ASS_SEC_PRO_TYPE",
    ) in pairs
    assert (
        "PM_RSDATA.PBOCD_RESULT_JS_201_GRDKFS",
        "BASE_INT_RAT",
        "PM_RSDATA.PBOCD_JS_201_GRDKFS_20251215",
        "BASE_INT_RAT",
    ) in pairs
    assert not any(
        dep.get("source_table") == "PM_RSDATA.PBOCD_RESULT_JS_201_GRDKFS"
        and dep.get("target_table") == "PM_RSDATA.PBOCD_JS_201_GRDKFS_20251215"
        and dep.get("source_column") == "*"
        for dep in deps
    )


def test_unexpandable_select_star_is_marked_low_confidence(tmp_path):
    path = write_pack(tmp_path)
    parser = LineageParser("hive", metadata_file=str(path))
    deps = parser.get_column_lineage(
        "INSERT INTO MART.UNKNOWN_TGT SELECT * FROM ODS.UNKNOWN_SRC"
    )

    star_deps = [dep for dep in deps if dep.get("source_column") == "*"]
    assert star_deps
    assert {dep.get("ambiguityCode") for dep in star_deps} == {"STAR_EXPANSION_UNAVAILABLE"}
    assert {dep.get("confidence") for dep in star_deps} == {"LOW"}
