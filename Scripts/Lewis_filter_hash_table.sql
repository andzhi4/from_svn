--drop table emp
create table emp (
dept_no not null,
sal,
emp_no not null,
padding,
constraint e_pk primary key(emp_no)
)
as
with generator as (
                   select --+ materialize
                   rownum as id
                   from all_objects 
                   where rownum <= 1000
                   )
select 
    mod(rownum,6),
    rownum,
    rownum,
    rpad('x',60)
from 
    generator v1,
    generator v2
where
    rownum <= 20000    ;
    
select * from emp where rownum <= 100;        

alter session set events = '10053 trace name context forever, level 1';

      select outer.*
      from emp outer
      where outer.sal > (
                         select /*+ no_unnest*/
                            avg(inner.sal)
                         from emp inner
                         where outer.dept_no = inner.dept_no
                         )

;

alter session set events = '10053 trace name context off';

select * from V$PARAMETER where name like '%dump%'

update emp set dept_no = 432 where dept_no = 0
 
select * from emp          

select 
    
    count(*)
from (
      select outer.*
      from emp outer
      where outer.sal > (
                         select 
                            avg(inner.sal)
                         from emp inner
                         where outer.dept_no = inner.dept_no
                         )
) iv
;    



select id, parent_id, lpad(operation,3*depth+length(operation),' ')||' '||options||' '||case when object_name is not null then 'of '||object_name else '' end as operation, cost, cardinality  from V$sql_plan where sql_id = 'cvx1ctr66hcs5'


            
                       