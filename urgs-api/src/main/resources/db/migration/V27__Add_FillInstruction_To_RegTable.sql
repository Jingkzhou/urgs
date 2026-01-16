-- V27__Add_FillInstruction_To_RegTable.sql
ALTER TABLE `reg_table` ADD COLUMN `fill_instruction` TEXT COMMENT '填报说明';
