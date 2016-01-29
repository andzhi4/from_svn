create table test_tab (id int,
  obj tab_of_objs_t)
nested table obj store as objs_tab;

select * from test_tab;

select o.id, o.name, o.action from test_tab t, table(obj) o where t.id  in (1,2);

insert into test_tab values (1, tab_of_objs_t
(tab_arr_t(1,'ORCL','INST'),
tab_arr_t(2,'MSSQL','DEINST'),
tab_arr_t(3,'MSOFFICE','INST'))
);

insert into test_tab values (2, tab_of_objs_t
(tab_arr_t(1,'PG','INST'),
tab_arr_t(2,'MONGO','DEINST'),
tab_arr_t(3,'APACHE','INST'))
);

commit;

create type print_t as object (id int, name varchar2(100)) not instantiable not final;

create type book_t under print_t (ISBN varchar2(13));