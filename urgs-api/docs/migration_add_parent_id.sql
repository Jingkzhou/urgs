ALTER TABLE metadata_regulatory_asset ADD COLUMN parent_id BIGINT COMMENT '父级资产ID (如指标所属的报表ID)';
CREATE INDEX idx_parent_id ON metadata_regulatory_asset (parent_id);
