alter session set tracefile_identifier='MY_10053';
alter session set events '10053 trace name context forever';
select * from emp where emp_no > 20;
alter session set events '10053 trace name context off';

select * from user_indexes where table_name = 'EMP'

select * from user_tables where table_name = 'EMP'

select * from dba_segments where segment_name = 'EMP'

select * from dba_segments where segment_name = 'E_PK'


select count(*) from V$STATNAME where name like '%CPU%'

select * from V$PARAMETER where name like '%optimizer%'




