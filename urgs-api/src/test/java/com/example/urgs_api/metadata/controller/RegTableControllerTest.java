package com.example.urgs_api.metadata.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class RegTableControllerTest {

    private final RegTableController controller = new RegTableController();

    @Test
    void keepsSelectUnionAllAndSeparatesJoinedInsertStatements() {
        String snippet = "INSERT INTO old_table SELECT 1 UNION ALL SELECT 2\n"
                + "UNION ALL\n"
                + "INSERT OVERWRITE TABLE other_table SELECT 3;";

        String result = controller.normalizeHiveInsertStatements(snippet, "`pm_rsdata`.`G17_6.5.1.C.2021`");

        assertTrue(result.contains("SELECT 1 UNION ALL SELECT 2"));
        assertTrue(result.contains("INSERT OVERWRITE TABLE `pm_rsdata`.`G17_6.5.1.C.2021` SELECT 3;"));
        assertFalse(result.contains("UNION ALL\nINSERT"));
    }

    @Test
    void quotesSchemaAndCompleteIndicatorCodeSeparately() {
        assertEquals("`pm_rsdata`.`S71_I_1..B1.2018`",
                controller.formatQualifiedTableName("pm_rsdata", "S71_I_1..B1.2018"));
    }
}
