FROM ods.a a
JOIN ods.b b USING (id)
INSERT OVERWRITE TABLE dwd.joined (id, v1, v2)
SELECT a.id, a.v1, b.v2;
