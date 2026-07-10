INSERT INTO `tgt` (`id`, `val`)
SELECT s.`id`, IFNULL(s.`val`, 0)
  FROM `src` s;
