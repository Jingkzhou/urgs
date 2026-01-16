-- V26__Rename_Reg_Tables.sql
-- Rename sys_reg_table to reg_table and sys_reg_element to reg_element
-- This preserves data and effectively removes the old table names.

RENAME TABLE `sys_reg_table` TO `reg_table`;
RENAME TABLE `sys_reg_element` TO `reg_element`;
