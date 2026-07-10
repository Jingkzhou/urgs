MERGE INTO dwh.customer_dim d
USING (
  SELECT id, UPPER(name) AS clean_name, status
    FROM ods.customer
   WHERE active_flag = 'Y'
) s
ON (d.id = s.id)
WHEN MATCHED THEN UPDATE SET
  d.name = s.clean_name,
  d.status = s.status
WHEN NOT MATCHED THEN INSERT (id, name, status)
  VALUES (s.id, s.clean_name, s.status);
