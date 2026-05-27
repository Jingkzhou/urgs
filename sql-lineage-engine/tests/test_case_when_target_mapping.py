from parsers.indirect_flow_parser import IndirectFlowParser


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
