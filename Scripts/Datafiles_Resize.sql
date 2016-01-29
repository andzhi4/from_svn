  SELECT f.file#,
         ROUND (f.bytes / 1024 / 1024, 2) || ' Mb' megabytes,
         DECODE (TRUNC (e.maxextend * blocksize / 1000 / 10),
                 0, ROUND (e.maxextend * blocksize, 2) || ' Mb',
                 NULL, NULL,
                 'Unlimited')
            maxextend,
         DECODE (e.inc, NULL, NULL, ROUND (e.inc * blocksize, 2) || ' Mb') inc,
         CEIL (NVL (r.min_resize, 0) * blocksize) || ' Mb' min_resize,
         f.name
    FROM sys.filext$ e,
         v$datafile f,
         (  SELECT e.file_id file#, MAX (e.block_id + e.blocks) AS min_resize
              FROM dba_extents e
          GROUP BY e.file_id) r,
         (SELECT TO_NUMBER (VALUE) / 1024 / 1024 blocksize
            FROM v$parameter
           WHERE name = 'db_block_size')
   WHERE e.file#(+) = f.file# AND r.file#(+) = f.file#
ORDER BY 1