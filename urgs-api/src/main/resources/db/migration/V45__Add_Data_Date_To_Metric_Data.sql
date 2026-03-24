-- V45__Add_Data_Date_To_Metric_Data.sql
-- Add data_date to t_metric_data for metric trending calculations.

ALTER TABLE `t_metric_data` ADD COLUMN `data_date` DATE NULL COMMENT '数据日期 (yyyy-MM-dd)' AFTER `metric_time`;

UPDATE `t_metric_data` SET `data_date` = DATE(`metric_time`);

ALTER TABLE `t_metric_data` MODIFY COLUMN `data_date` DATE NOT NULL COMMENT '数据日期 (yyyy-MM-dd)';

