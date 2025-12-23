-- 为监管指标元素表添加三个新字段
-- 是否初始化项、是否归并公式项、是否填报业务项

-- 如果字段已存在会报错，可以忽略
ALTER TABLE sys_reg_element ADD COLUMN is_init TINYINT(1) DEFAULT 0 COMMENT '是否初始化项(0:否, 1:是)';
ALTER TABLE sys_reg_element ADD COLUMN is_merge_formula TINYINT(1) DEFAULT 0 COMMENT '是否归并公式项(0:否, 1:是)';
ALTER TABLE sys_reg_element ADD COLUMN is_fill_business TINYINT(1) DEFAULT 0 COMMENT '是否填报业务项(0:否, 1:是)';
