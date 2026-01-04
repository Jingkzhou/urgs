UPDATE sys_issue SET status = '新建' WHERE status IS NULL OR status = '';
