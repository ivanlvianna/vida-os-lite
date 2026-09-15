\set ON_ERROR_STOP on

DO $verify$
DECLARE
  v_text text;
  v_count bigint;
BEGIN
  SELECT count(*) INTO v_count
  FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname='public' AND c.relkind='r' AND c.relname LIKE 'planning_content_%';
  IF v_count <> 51 THEN RAISE EXCEPTION 'table_count mismatch: %', v_count; END IF;

  WITH cols AS (
    SELECT table_schema,table_name,ordinal_position,column_name,data_type,udt_name,is_nullable,coalesce(column_default,'') AS column_default
    FROM information_schema.columns
    WHERE table_schema='public' AND (table_name LIKE 'planning_content_%' OR table_name LIKE 'pc_rm_%')
  )
  SELECT md5(string_agg(format('%s|%s|%s|%s|%s|%s|%s|%s',table_schema,table_name,ordinal_position,column_name,data_type,udt_name,is_nullable,column_default),E'\n' ORDER BY table_name,ordinal_position)), count(*)::text
  INTO v_text, v_count FROM cols;
  IF v_count <> 543 OR v_text <> '46bec790ff0d338f1d6b80131713973c' THEN
    RAISE EXCEPTION 'columns mismatch count=% md5=%', v_count, v_text;
  END IF;

  WITH cons AS (
    SELECT n.nspname AS schema_name,c.relname AS table_name,con.conname,pg_get_constraintdef(con.oid,true) AS def
    FROM pg_constraint con JOIN pg_class c ON c.oid=con.conrelid JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='public' AND (c.relname LIKE 'planning_content_%' OR (c.relname='planning_engagement_entities' AND con.conname='uq_planning_engagement_entities_account_engagement_entity'))
  )
  SELECT md5(string_agg(format('%s|%s|%s|%s',schema_name,table_name,conname,def),E'\n' ORDER BY table_name,conname)), count(*)::text
  INTO v_text, v_count FROM cons;
  IF v_count <> 315 OR v_text <> '4880ddb2061f37196ce0b582c5a6dbef' THEN
    RAISE EXCEPTION 'constraints mismatch count=% md5=%', v_count, v_text;
  END IF;

  WITH idx AS (
    SELECT schemaname,tablename,indexname,indexdef FROM pg_indexes
    WHERE schemaname='public' AND (tablename LIKE 'planning_content_%' OR indexname LIKE 'pc_idx_%')
  )
  SELECT md5(string_agg(format('%s|%s|%s|%s',schemaname,tablename,indexname,indexdef),E'\n' ORDER BY tablename,indexname)), count(*)::text
  INTO v_text, v_count FROM idx;
  IF v_count <> 126 OR v_text <> '70fd684b6d72f8d62c9f01ccbb2b538f' THEN
    RAISE EXCEPTION 'indexes mismatch count=% md5=%', v_count, v_text;
  END IF;

  WITH funcs AS (
    SELECT n.nspname AS schema_name,p.proname,pg_get_function_identity_arguments(p.oid) AS args,pg_get_functiondef(p.oid) AS def
    FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public' AND p.proname LIKE 'pc_%'
  )
  SELECT md5(string_agg(format('%s|%s|%s|%s',schema_name,proname,args,def),E'\n' ORDER BY proname,args)), count(*)::text
  INTO v_text, v_count FROM funcs;
  IF v_count <> 40 OR v_text <> '1b68e9a25836c635533a427be841c7ac' THEN
    RAISE EXCEPTION 'functions mismatch count=% md5=%', v_count, v_text;
  END IF;

  WITH trg AS (
    SELECT c.relname AS table_name,t.tgname,pg_get_triggerdef(t.oid,true) AS def
    FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='public' AND c.relname LIKE 'planning_content_%' AND NOT t.tgisinternal
  )
  SELECT md5(string_agg(format('%s|%s|%s',table_name,tgname,def),E'\n' ORDER BY table_name,tgname)), count(*)::text
  INTO v_text, v_count FROM trg;
  IF v_count <> 74 OR v_text <> 'e73c072ece89da32319cadb824229ed5' THEN
    RAISE EXCEPTION 'triggers mismatch count=% md5=%', v_count, v_text;
  END IF;

  WITH pol AS (
    SELECT schemaname,tablename,policyname,roles,cmd,qual,with_check FROM pg_policies
    WHERE schemaname='public' AND tablename LIKE 'planning_content_%'
  )
  SELECT md5(string_agg(format('%s|%s|%s|%s|%s|%s|%s',schemaname,tablename,policyname,roles,cmd,qual,with_check),E'\n' ORDER BY tablename,policyname)), count(*)::text
  INTO v_text, v_count FROM pol;
  IF v_count <> 51 OR v_text <> 'b974f95dee99c0003d6b7a231011ad08' THEN
    RAISE EXCEPTION 'policies mismatch count=% md5=%', v_count, v_text;
  END IF;

  WITH views AS (
    SELECT c.relname AS view_name,coalesce(array_to_string(c.reloptions,','),'') AS reloptions,pg_get_viewdef(c.oid,true) AS def
    FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='public' AND c.relkind='v' AND c.relname LIKE 'pc_rm_%'
  )
  SELECT md5(string_agg(format('%s|%s|%s',view_name,reloptions,def),E'\n' ORDER BY view_name)), count(*)::text
  INTO v_text, v_count FROM views;
  IF v_count <> 12 OR v_text <> '63675e07daaaa508b5768abe230f9e9f' THEN
    RAISE EXCEPTION 'views mismatch count=% md5=%', v_count, v_text;
  END IF;

  WITH table_grants AS (
    SELECT table_name,grantee,privilege_type FROM information_schema.role_table_grants
    WHERE table_schema='public' AND (table_name LIKE 'planning_content_%' OR table_name LIKE 'pc_rm_%')
      AND grantee IN ('anon','authenticated','service_role')
  )
  SELECT md5(string_agg(format('%s|%s|%s',table_name,grantee,privilege_type),E'\n' ORDER BY table_name,grantee,privilege_type)), count(*)::text
  INTO v_text, v_count FROM table_grants;
  IF v_count <> 63 OR v_text <> '41da46ade4adcbd9fb55d3e30daefbee' THEN
    RAISE EXCEPTION 'app table grants mismatch count=% md5=%', v_count, v_text;
  END IF;

  WITH routine_grants AS (
    SELECT routine_name,grantee,privilege_type FROM information_schema.role_routine_grants
    WHERE routine_schema='public' AND routine_name LIKE 'pc_%'
      AND grantee IN ('anon','authenticated','service_role')
  )
  SELECT md5(string_agg(format('%s|%s|%s',routine_name,grantee,privilege_type),E'\n' ORDER BY routine_name,grantee,privilege_type)), count(*)::text
  INTO v_text, v_count FROM routine_grants;
  IF v_count <> 35 OR v_text <> 'cdca1e80df563b2313d78a861690d022' THEN
    RAISE EXCEPTION 'app routine grants mismatch count=% md5=%', v_count, v_text;
  END IF;
END;
$verify$;

SELECT 'PASS: Planning Content catalog fingerprint matches homologated D3' AS result;
