declare
    sfile utl_file.file_type;    
begin
    UTL_FILE.FCOPY('QUEST_SOO_BDUMP_DIR', 'orcl_ora_10301.trc', 'DUMPS', 'flist.sh');
    UTL_FILE.FCLOSE_ALL;
    sfile := UTL_FILE.FOPEN('DUMPS','flist.sh', 'w');
    UTL_FILE.PUT_LINE(sfile, 'targetDir=`/home/oracle/Documents $1`');
    UTL_FILE.PUT_LINE(sfile, '/bin/ls -l --time-style=long-iso $targetDir | /usr/bin/awk ''BEGIN {OFS = ",";} {print $1, $2, $3, $4, $5, $6" "$7, $8}''');
    UTL_FILE.PUT_LINE(sfile, 'exit 0');
    UTL_FILE.FCLOSE(sfile);
end;    


declare
    sfile utl_file.file_type;
    buff varchar2(1024) := 'YO';    
begin
     sfile := UTL_FILE.FOPEN('DUMPS','flist.sh', 'r');
     begin
     while buff is not null loop
        UTL_FILE.GET_LINE(sfile, buff);
        DBMS_OUTPUT.PUT_LINE(buff);
     end loop;
     exception when no_data_found
       then UTL_FILE.FCLOSE(sfile); 
     end;     
end;     


create table list_files_xt
(
    permissions varchar2(15),
    hard_links number,
    file_owner varchar2(32),
    group_name varchar2(32),
    size_bytes number,
    last_modified date,
    file_name varchar2(255)
)
    organization external
    (
        type oracle_loader
        default directory DUMPS
        access parameters
        (
            records delimited by newline
            nologfile
            preprocessor DUMPS : 'flist.sh'           
            skip 1
            fields terminated by ','           
            ( 
                permissions,
                hard_links,
                file_owner,
                group_name,
                size_bytes,
                last_modified date 'YYYY-MM-DD HH24:MI',
                file_name
            )
        )
        location('list_files_dummy.txt')
    )
    
    
select * from list_files_xt    

