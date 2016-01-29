conn sys as sysdba@ol7.local:1521/orcl

SELECT pname, pval1
FROM aux_stats$
WHERE sname = 'SYSSTATS_MAIN';

exec dbms_stats.delete_system_stats;

GRANT gather_system_statistics TO andzhi4;

conn andzhi4/password@ol7.local:1521/orcl

-- gather workload over the next 15 minutes 
exec dbms_stats.gather_system_stats('INTERVAL', 15);

CREATE TABLE airplanes (

program_id     VARCHAR2(3),

line_number    NUMBER(10),

customer_id    VARCHAR2(4),

order_date     DATE,

delivered_date DATE)

PCTFREE 0

PCTUSED 99;



CREATE INDEX ix_program_id

ON airplanes (program_id)

PCTFREE 0;



DECLARE

 progid  VARCHAR2(3) := '000';

 lineno  NUMBER(10) := 0;

 custid  VARCHAR2(4) := 'AAL';

 orddate DATE;

 deldate DATE;

BEGIN

  LOOP

    SELECT DECODE(progid,'000','737','737','747','747','757','757','767','767','777','777','999')

    INTO progid

    FROM dual;



    IF progid = 999 THEN

      EXIT;

    END IF;



    FOR x IN 1..50000

    LOOP

      lineno := lineno + 1;



      SELECT DECODE(custid,'AAL','DAL','DAL','SAL','SAL','ILC','ILC','SWA','SWA','NWO','NWO','USAF','USAF','AAL')

      INTO custid

      FROM dual;



      OrdDate := SYSDATE + lineno;

      DelDate := OrdDate + lineno + 100;



      INSERT INTO airplanes

      (program_id, line_number, customer_id,

      order_date, delivered_date)

      VALUES

      (progid, lineno, custid, orddate, deldate);

    END LOOP;

    lineno := 0;

  END LOOP;

  COMMIT;

END load_airplanes;

-- remove index
drop index ix_program_id;

SELECT *
FROM airplanes;

exec dbms_stats.gather_system_stats('STOP');

conn / as sysdba

SELECT pname, pval1
FROM aux_stats$
WHERE sname = 'SYSSTATS_MAIN';