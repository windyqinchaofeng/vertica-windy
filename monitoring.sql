----查询表存储信息
----通过列存储查询
SELECT anchor_table_schema, 
       anchor_table_name, 
       SUM(used_bytes) / ( 1024^3 ) AS used_compressed_gb 
FROM   v_monitor.column_storage 
GROUP  BY anchor_table_schema, 
          anchor_table_name 
ORDER  BY SUM(used_bytes) DESC;

----通过projection查询
SELECT anchor_table_schema, 
       anchor_table_name, 
       SUM(used_bytes) / ( 1024^3 ) AS used_compressed_gb 
FROM   v_monitor.projection_storage 
GROUP  BY anchor_table_schema, 
          anchor_table_name 
ORDER  BY SUM(used_bytes) DESC;

----CPU使用情况
SELECT start_time, 
       AVG(average_cpu_usage_percent) AS avg_cpu_usage 
FROM   v_monitor.cpu_usage 
GROUP  BY start_time 
ORDER  BY start_time;


----糕CPU使用情况
SELECT start_time, 
       AVG(average_cpu_usage_percent) AS avg_cpu_usage 
FROM   v_monitor.cpu_usage 
WHERE  start_time BETWEEN NOW() - INTERVAL '24 hours' AND NOW() 
GROUP  BY start_time 
ORDER  BY AVG(average_cpu_usage_percent) DESC
LIMIT  10;

----磁盘IO使用情况
SELECT start_time, 
       SUM(read_kbytes_per_sec) AS total_read_kb,
       SUM(written_kbytes_per_sec) AS total_written_kb,
       SUM(read_kbytes_per_sec + written_kbytes_per_sec) AS total_kb
FROM   v_monitor.io_usage 
GROUP  BY start_time 
ORDER  BY start_time;

-----糕磁盘IO使用情况
SELECT start_time, 
       SUM(read_kbytes_per_sec + written_kbytes_per_sec) AS total_kb
FROM   v_monitor.io_usage 
WHERE  start_time BETWEEN NOW() - INTERVAL '24 hours' AND NOW() 
GROUP  BY start_time 
ORDER  BY SUM(read_kbytes_per_sec + written_kbytes_per_sec) DESC
LIMIT  10;

-----每个节点磁盘使用情况
SELECT host_name, 
     (disk_space_free_mb/1024) AS disk_space_free_gb,
     (disk_space_used_mb/1024) AS disk_space_used_gb,
     (disk_space_total_mb/1024) AS disk_space_total_gb
FROM v_monitor.host_resources;

SELECT node_name, 
         SUM(disk_space_used_mb)/1024 AS disk_space_used_gb,
         SUM(disk_space_free_mb)/1024 AS disk_space_free_gb,
         SUM((disk_space_used_mb+disk_space_free_mb)/1024) AS disk_space_total_gb
FROM     v_monitor.disk_storage
WHERE    storage_usage = 'DATA,TEMP'
GROUP BY node_name
ORDER BY node_name;

SELECT   node_name,
         SUM(used_bytes)/(1024^3) AS disk_space_used_gb,
         SUM((used_bytes+free_bytes)-used_bytes)/(1024^3) AS disk_space_free_gb,
         SUM(used_bytes+free_bytes)/(1024^3) AS disk_space_total_gb
FROM     v_monitor.storage_usage
WHERE    filesystem = 'vertica'
GROUP BY node_name
ORDER BY node_name;

-----查询license
SELECT DISPLAY_LICENSE();

---备份资源池
SELECT    'CREATE RESOURCE POOL ' || name
        || CASE WHEN memorysize                IS NULL THEN ' ' ELSE ' MEMORYSIZE '                 || '''' || memorysize               || '''' END
        || CASE WHEN maxmemorysize = ''                THEN ' ' ELSE ' MAXMEMORYSIZE '              || '''' || maxmemorysize            || '''' END
        || CASE WHEN executionparallelism     = 'AUTO' THEN ' ' ELSE ' EXECUTIONPARALLELISM '       || '''' || executionparallelism     || '''' END
        || CASE WHEN NULLIFZERO(priority)      IS NULL THEN ' ' ELSE ' PRIORITY '                   || '''' || priority                 || '''' END
        || CASE WHEN runtimepriority           IS NULL THEN ' ' ELSE ' RUNTIMEPRIORITY '            ||         runtimepriority                  END
        || CASE WHEN runtimeprioritythreshold  IS NULL THEN ' ' ELSE ' RUNTIMEPRIORITYTHRESHOLD '   ||         runtimeprioritythreshold         END
        || CASE WHEN queuetimeout              IS NULL THEN ' ' ELSE ' QUEUETIMEOUT '               ||         queuetimeout                     END
        || CASE WHEN maxconcurrency            IS NULL THEN ' ' ELSE ' MAXCONCURRENCY '             ||         maxconcurrency                   END
        || CASE WHEN runtimecap                IS NULL THEN ' ' ELSE ' RUNTIMECAP '                 || '''' || runtimecap               || '''' END
        || ' ; '
FROM v_catalog.resource_pools
WHERE NOT is_internal
ORDER BY name;

-----查询copy进度
select load_start,load_duration_ms,accepted_row_count,read_bytes,input_file_size_bytes,parse_complete_percent from load_streams where table_name='tb_tl_cu_user_day';

------终止会话
---方法一：
SELECT transaction_id FROM locks; ---查看transaction_id
SELECT session_id,statement_id FROM sessions where transaction_id=<>;
SELECT INTERRUPT_STATEMENT('<session_id>', '<statement_id>');
---方法二：
select transaction_id from locks;--获取transaction_id字段
select session_id from sessions where transaction_id ='';--将上面获取的transaction_id带入,查看transaction_start，判断是否是以前锁的
select CLOSE_SESSION('');--带入上面查出来的session_id
