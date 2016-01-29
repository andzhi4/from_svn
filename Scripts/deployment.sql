/*-------------------------------------------
----Package: PG_JOIN
----Author: Viacheslav Andzhich
----Version: 0.1
----Date: 21/04/2015
---------------------------------------------
Purporse: Implements view and several functions for cluster analyzing of
the database. Allows you to join several tables in your database by existing
FKEY relations. You don't need to know how exactly the tables are interconnected.
You just specifiy the list of tables you want to join and the BUILD_QUERY func-
tion will find the shortest path. If there are several paths available between
two tables, you can explicitly specifiy what tables you want to include in the
join.
---------------------------------------------
Usage: call BUILD_QUERY functions with the specified parameters:
  from_tabs character varying[] - list of tables to be included in the query
  from_cols character varying[] - list of columns to join on,
                                  in case of several FKs between two tables
  sel_cols character varying[] - columns to select
  filt character varying - WHERE clause
  shortcut boolean DEFAULT false - if TRUE, shortcuts the path by excluding unnecessary tables
  spec_cols boolean DEFAULT false - if TRUE, tells function to use values specified
                                    in the from_cols parameter.
  groupby boolean DEFAULT false - if TRUE, function will generate aggregate condition
                                  count(0) for columns specified in the sel_cols parameter.
---------------------------------------------
BUILD_QUERY call example:
  select * from build_query (
  array['ordering.construct','concept','registry','inventory.lot','inventory.container'],
  array['ordering.construct.tail_id'],
  array['ordering.construct.construct_id'],
  'ordering.construct.construct_id>10',
  true,
  true,
  true)
  f (con_id bigint, count  bigint);
---------------------------------------------
For full documentation reffer to: ---DOC REFERENCE---
---------------------------------------------*/

/*********************Deployment script start**********************************/

/*Creating fake table for successive compilation of tab_path function.
The table is droppped then. */
create  table path_tab (tbl1 varchar, tbl2 varchar, col1 varchar, col2 varchar, nm integer) ;

create type tab_ret_t as (tab varchar, col varchar, typ varchar);

  -- View: devqc_all_fkeys

  -- DROP VIEW devqc_all_fkeys;

CREATE OR REPLACE VIEW devqc_all_fkeys AS
         SELECT f.confrelid::character varying AS confrelid,
            f.fcol::character varying AS fcol,
            f.conrelid::character varying AS conrelid,
            f.col::character varying AS col
           FROM ( SELECT ss2.confrelid::regclass AS confrelid,
                    af.attname AS fcol, ss2.conrelid::regclass AS conrelid,
                    a.attname AS col
                   FROM pg_attribute af, pg_attribute a,
                    ( SELECT ss.conrelid, ss.confrelid, ss.conkey[ss.i] AS conkey,
                            ss.confkey[ss.i] AS confkey
                           FROM ( SELECT pg_constraint.conrelid,
                                    pg_constraint.confrelid,
                                    pg_constraint.conkey, pg_constraint.confkey,
                                    generate_series(1, array_upper(pg_constraint.conkey, 1)) AS i
                                   FROM pg_constraint
                                  WHERE pg_constraint.contype = 'f'::"char") ss) ss2
                  WHERE af.attnum = ss2.confkey AND af.attrelid = ss2.confrelid AND a.attnum = ss2.conkey AND a.attrelid = ss2.conrelid) f
UNION ALL
         SELECT f.conrelid::character varying AS confrelid,
            f.col::character varying AS fcol,
            f.confrelid::character varying AS conrelid,
            f.fcol::character varying AS col
           FROM ( SELECT ss2.confrelid::regclass AS confrelid,
                    af.attname AS fcol, ss2.conrelid::regclass AS conrelid,
                    a.attname AS col
                   FROM pg_attribute af, pg_attribute a,
                    ( SELECT ss.conrelid, ss.confrelid, ss.conkey[ss.i] AS conkey,
                            ss.confkey[ss.i] AS confkey
                           FROM ( SELECT pg_constraint.conrelid,
                                    pg_constraint.confrelid,
                                    pg_constraint.conkey, pg_constraint.confkey,
                                    generate_series(1, array_upper(pg_constraint.conkey, 1)) AS i
                                   FROM pg_constraint
                                  WHERE pg_constraint.contype = 'f'::"char") ss) ss2
                  WHERE af.attnum = ss2.confkey AND af.attrelid = ss2.confrelid AND a.attnum = ss2.conkey AND a.attrelid = ss2.conrelid) f;


create or replace function get_col  (inp varchar)
returns varchar
as
$BODY$
declare
format int;
retval varchar;
i int;
begin
format := (select length(inp) - length(replace(inp,'.',''))) ;
--if format>2 then raise
retval := inp;
for i in 1..format
loop
retval := substr(retval, position('.' in retval)+1, length(inp));
end loop;
return retval;
end
$BODY$
 LANGUAGE plpgsql VOLATILE
  COST 100;


create or replace function get_tab (inp varchar)
returns varchar
as
$body$
declare
retval varchar;
begin
retval := rtrim(replace(inp, get_col(inp),''),'.');
return retval;
end
$body$
LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION get_table_columns()
  RETURNS setof record
AS
$BODY$
declare
retcur refcursor;
i int;
lrec record;
filt_stmt varchar;
stmt varchar;
retrec  tab_ret_t;

begin

  update visited_tabs set name = 'public.'||name where position('.' in name)=0;

  filt_stmt := '(';

  for lrec in (select distinct name from visited_tabs)
  loop
    filt_stmt := filt_stmt||'('''||get_tab(lrec.name)||''','''||get_col(lrec.name)||'''), ';
  end loop;
  filt_stmt := rtrim(filt_stmt,', ')||')';

  stmt := 'select table_name, column_name, data_type from information_schema.columns where (table_schema,table_name) in '||filt_stmt;

  open retcur for execute stmt;

  loop
    fetch retcur into retrec;
    exit when retrec is null;
    return next retrec;
  end loop;
  close retcur;


end $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

create or replace function key_not_exists (
  tab1 varchar,
  tab2 varchar,
  col1 varchar,
  col2 varchar)
returns boolean
as $$
declare
retval boolean default true;
begin
if exists (select * from devqc_all_fkeys where confrelid = tab1 and fcol = col1
		and conrelid = tab2 and col = col2)
then retval :=false;
end if;
return retval;
end $$
language plpgsql;

-- Function: tab_path(character varying, character varying, boolean, integer)

-- DROP FUNCTION tab_path(character varying, character varying, boolean, integer);

CREATE OR REPLACE FUNCTION tab_path(
    tab_source character varying,
    tab_target character varying,
    opt_path boolean DEFAULT false,
    call_num integer DEFAULT 1)
  RETURNS boolean AS
$BODY$
declare
	found boolean := false;
	queue varchar[];
	prev int[];
	cols varchar[];
	fcols varchar[];
	node varchar;
	k int :=1;
	num int :=1;
	cur record;
	old_num int;
	ftabs varchar[];
	path_cur record;
	prev_rec path_tab%rowtype;

BEGIN

	truncate table path_tab;

	queue[1] := tab_source;
	prev[1] := 0;
	cols[1] := 'unknown';
	fcols[1] := 'unknown';
	while queue[k] is not null
	loop
			node := queue[k];
			if node = tab_target
				then found := true;
				exit;
			end if;
		for cur in (select confrelid, fcol, conrelid, col from devqc_all_fkeys where confrelid = node)
		loop
			if not cur.conrelid = any(queue)
				then
				  queue := array_append(queue, btrim(cur.conrelid::varchar, '()')::varchar);
				  cols := array_append(cols, cur.col::varchar);
				  fcols := array_append(fcols, cur.fcol::varchar);
				  ftabs := array_append(ftabs, cur.confrelid::varchar);
				  prev := array_append(prev, k);
				end if;
			end loop;
		k := k + 1;
	end loop;

	num := k;
	if found then
	while num > 1
		LOOP
                        IF exists (select name from visited_tabs where name = queue[num]) and call_num > 1
                        THEN
			  raise warning 'Table % was passed for the second time on step % and is excluded from path.',
			    queue[num], call_num;
			  update path_tab set tbl1 = queue[num] where nm = old_num;
			  old_num := num;
			  num := prev[num];
			ELSE
			  insert into path_tab values (null, queue[num], fcols[num], cols [num], num);
			  update path_tab set tbl1 = queue[num] where nm = old_num;
			  old_num := num;
			  num := prev[num];
			END IF;
		END LOOP;


		update path_tab set tbl1 = tab_source where nm = (select min(nm) from path_tab) and tbl1 is null;

	    if opt_path then     --optimizing the path
		for path_cur in (select * from path_tab order by nm)
		loop
		  if path_cur.col1 = prev_rec.col2 then
		    delete from path_tab where nm = prev_rec.nm;
		    update path_tab set tbl1 = prev_rec.tbl1, col1 = prev_rec.col1 where nm = path_cur.nm;
		  else
		    prev_rec := path_cur;
		  end if;
		end loop;
	    end if;
	end if;
		insert into visited_tabs (select tbl1 from path_tab);
		insert into visited_tabs (select tbl2 from path_tab);

	return found;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


  -- Function: tab_join_new(character varying, character varying, integer, boolean, boolean)

  -- DROP FUNCTION tab_join_new(character varying, character varying, integer, boolean, boolean);

CREATE OR REPLACE FUNCTION tab_join_new(
      tab_source character varying,
      tab_target character varying,
      call_num integer DEFAULT 1,
      shortcut boolean DEFAULT false,
      spec_cols boolean DEFAULT false)
    RETURNS character varying AS
  $BODY$
  declare
  	found boolean := false;
  	cur record;
  	path varchar := '';
  	numways int;
  	check_cur record;
          num_fcols int;
          num_cols int;
          upd_tab varchar;
          upd_num int;
  	new_col varchar;

  BEGIN

  	found := tab_path(tab_source, tab_target, shortcut, call_num);

  	if found then
                                                               --build path
  	  if call_num =1 then path := 'from '||tab_source; end if;

  	  if spec_cols then
  	    for check_cur in (select * from path_tab)
  	    loop
  	      select count(conrelid), count(distinct fcol), count(distinct col) into numways, num_fcols, num_cols from devqc_all_fkeys where confrelid = check_cur.tbl1 and conrelid = check_cur.tbl2;

                if numways > 1 then

  	        if num_fcols > 1 then upd_tab := check_cur.tbl1; upd_num := 1;
  	        else upd_tab := check_cur.tbl2; upd_num := 2; end if;

  	        if not exists (select tab from join_cols where tab = upd_tab)
  	        then
  	          raise exception E'More than 1 relations found between % and % on step %. Can not proceed.',
  						    check_cur.tbl1, check_cur.tbl2, call_num;
  	        else

                    if upd_num = 1 then
                      update path_tab set col1 = (select col from join_cols where tab = upd_tab) where nm = check_cur.nm
  		      returning col1 into new_col;
  		    if key_not_exists (check_cur.tbl1, check_cur.tbl2, new_col, check_cur.col2)
  		    then raise exception 'No FK found between %.% and %.%!', check_cur.tbl1,new_col,check_cur.tbl2,check_cur.col2; end if;
                    elsif upd_num = 2 then
                      update path_tab set col2 = (select col from join_cols where tab = upd_tab) where nm = check_cur.nm
  		      returning col2 into new_col;
  		    if key_not_exists (check_cur.tbl1, check_cur.tbl2, check_cur.col1, new_col)
  		    then raise exception 'No FK found between %.% and %.%!', check_cur.tbl1,check_cur.col1,check_cur.tbl2,new_col;  end if;

                    else raise exception E'Can''t define columns to join % and %. Can not proceed.',
  						    check_cur.tbl1, check_cur.tbl2, call_num;
  	          end if;
                  end if; --end if not exists
                end if; --end if spec_cols
  	    end loop;
  	  end if;

  	  for cur in (select * from path_tab order by nm)
  	  loop
  	    path := path||E'\n'||' join '||cur.tbl2||E'\n'||'  on '||cur.tbl1||'.'||cur.col1||' = '||cur.tbl2||'.'||cur.col2;

  	  end loop;
  	else
  		path := null;
  	end if;
  	return path;
  END
  $BODY$
    LANGUAGE plpgsql VOLATILE
    COST 100;
  ALTER FUNCTION tab_join_new(character varying, character varying, integer, boolean, boolean)
    OWNER TO postgres;

-- Function: build_query(character varying[], character varying[], character varying[], character varying, boolean, boolean, boolean)

-- DROP FUNCTION build_query(character varying[], character varying[], character varying[], character varying, boolean, boolean, boolean);

CREATE OR REPLACE FUNCTION build_query(
    from_tabs character varying[],
    from_cols character varying[],
    sel_cols character varying[],
    filt character varying,
    shortcut boolean DEFAULT false,
    spec_cols boolean DEFAULT false,
    groupby boolean DEFAULT false)
  RETURNS setof record AS
$BODY$
declare
stmt varchar;
cur_step varchar;
tempcur record;
i int;
loc_filt varchar;
loc_group_by varchar;
retcur refcursor;
retrec record;
BEGIN

if from_tabs[1] = from_tabs[array_length(from_tabs,1)]
	then
	RAISE EXCEPTION 'Source and destination tables are the same!';
	end if;
drop table if exists visited_tabs;
create temp table visited_tabs (name varchar(1000))
	on commit preserve rows;
create  temp table path_tab (tbl1 varchar, tbl2 varchar, col1 varchar, col2 varchar, nm integer)
	  on commit drop;
create temp table join_cols (tab varchar(1000), col varchar(1000))
	on commit drop;

if from_cols[1] is not null then
for i in 1..array_length(from_cols,1)
loop
  insert into join_cols values (get_tab(from_cols[i]), get_col(from_cols[i]));
end loop;
end if;

stmt := 'select ';

if sel_cols[1] is null then sel_cols[1] := '*'; end if;


for i in 1..array_length(sel_cols,1)
loop
  stmt := stmt||sel_cols[i]||', ';
end loop;

stmt := rtrim(stmt,', ')||' ';

if groupby then stmt := stmt||', count(0) '; end if;

for i in 1..array_length(from_tabs,1)-1
	loop
	  cur_step := tab_join_new(from_tabs[i], from_tabs[i+1],i,shortcut,spec_cols);
	  if cur_step is null then
	    RAISE EXCEPTION 'Relation not found between % and %', from_tabs[i], from_tabs[i+1]
	    USING HINT = 'Please specifiy valid path';
	  end if;
	  stmt := stmt||cur_step;
	end loop;

if filt is not null then stmt := stmt||E'\n'||'where '||filt; end if;

if groupby then
  loc_group_by := E'\n'||'group by ';
  for i in 1..array_length(sel_cols,1)
  loop
    loc_group_by := loc_group_by||sel_cols[i]||', ';
  end loop;
  loc_group_by := rtrim(loc_group_by, ', ');
  stmt := stmt||loc_group_by;
end if;

raise notice '
	%', stmt;

--drop table visited_tabs;
drop table path_tab;
drop table join_cols;

open retcur for execute stmt;
--return retcur;


loop
  fetch retcur into retrec;
  exit when retrec is null;
  return next retrec;
end loop;
close retcur;
/*exception when others
then
  if retcur.isopen then close retcur; end if;
  drop table path_tab;
  drop table join_cols;
  drop table visited_tabs;
  raise;*/
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

DROP TABLE path_tab;

/*********************Deployment script end************************************/
