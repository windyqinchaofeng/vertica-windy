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
---备份角色

-- Roles
------------------------------------------------------------
SELECT '-- Create Roles';
SELECT 'CREATE ROLE ' || name || ' ;' AS TXT_CR
FROM v_catalog.roles
WHERE name NOT IN ('public','dbadmin','pseudosuperuser','dbduser')
ORDER BY 1;

------------------------------------------------------------
-- Add users to Roles
------------------------------------------------------------
SELECT '-- Add users to roles';
SELECT 'GRANT ' || all_roles || ' TO ' || user_name || ';'
FROM v_catalog.users
WHERE user_name NOT IN ('dbadmin')
ORDER BY 1;

--备份schema
SELECT '-- Create Schema';
SELECT 'CREATE SCHEMA ' || schema_name  ||  ';'
FROM schemata
WHERE schema_name NOT IN ('v_internal','v_catalog','v_monitor','TxtIndex')
ORDER BY 1;
--备份用户

SELECT '-- Create Users';
SELECT 'CREATE USER ' || user_name  || ' RESOURCE POOL ' || resource_pool ||  ' ;'
FROM v_catalog.users
WHERE user_name NOT IN ('dbadmin')
ORDER BY 1;
---各手shcema大小

SELECT /*+(estimated_raw_size)*/
       pj.anchor_table_schema,
       pj.used_compressed_gb,
       pj.used_compressed_gb * la.ratio AS raw_estimate_gb
FROM   (SELECT ps.anchor_table_schema,
               SUM(used_bytes) / ( 1024^3 ) AS used_compressed_gb
        FROM   v_catalog.projections p
               JOIN v_monitor.projection_storage ps
                 ON ps.projection_id = p.projection_id
        WHERE  p.is_super_projection = 't'
        GROUP  BY ps.anchor_table_schema) pj
       CROSS JOIN (SELECT (SELECT database_size_bytes
                           FROM   v_catalog.license_audits
                           ORDER  BY audit_start_timestamp DESC
                           LIMIT  1) / (SELECT SUM(used_bytes)
                                        FROM   V_MONITOR.projection_storage) AS ratio) la
ORDER  BY pj.used_compressed_gb DESC;

--备份权限
--backup grants
 select 'grant '|| privileges_description || ' on '|| object_name || ' to '|| grantee||';' 
 from grants where grantor<>grantee 
 order by object_name;
