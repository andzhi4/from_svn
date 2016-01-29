DECLARE
   TYPE ir_t IS TABLE OF andzhi4.ier%ROWTYPE
      INDEX BY BINARY_INTEGER;

   ir   ir_t;
   l    NUMBER;
   k    BINARY_INTEGER := 1;
BEGIN
   l := DBMS_UTILITY.GET_TIME;

   SELECT *
     BULK COLLECT INTO ir
     FROM andzhi4.ier;

   DBMS_OUTPUT.put_line (DBMS_UTILITY.GET_TIME - l);
   l := DBMS_UTILITY.GET_TIME;

   FOR i IN (SELECT * FROM andzhi4.ier)
   LOOP
      ir (k).id := i.id;
      ir (k).name := i.name;
      ir (k).pid := i.pid;
      k := k + 1;
   END LOOP;

   DBMS_OUTPUT.put_line (DBMS_UTILITY.GET_TIME - l);


   FOR i IN ir.FIRST .. ir.LAST
   LOOP
      DBMS_OUTPUT.put_line (
         ir (i).id || ' ' || ir (i).pid || ' ' || ir (i).name);
   END LOOP;
END;

SELECT * FROM dba_objects