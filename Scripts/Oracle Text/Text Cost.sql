declare 
     cost sys.ODCICost := sys.ODCICost(NULL, NULL, NULL, NULL); 
     arg0 CLOB := null;
 
    begin 
      :1 := "CTXSYS"."TEXTOPTSTATS".ODCIStatsFunctionCost(
                     sys.ODCIFuncInfo('CTXSYS', 
                            'CTX_CONTAINS', 
                            'TEXTCONTAINS', 
                            2), 
                     cost, 
                     sys.ODCIARGDESCLIST(sys.ODCIARGDESC(2, 'TEXTCONTENT', 'PH201510', '"CONTENT"', NULL, NULL, NULL), sys.ODCIARGDESC(3, NULL, NULL, NULL, NULL, NULL, NULL)) 
                     , arg0, :5, 
                     sys.ODCIENV(:6,:7,:8,:9)); 
                     
                     
declare 
     cost sys.ODCICost := sys.ODCICost(NULL, NULL, NULL, NULL); 
     arg0 CLOB := null;
 
    begin 
      :1 := "CTXSYS"."TEXTOPTSTATS".ODCIStatsIndexCost(
                     sys.ODCIINDEXINFO('PH201510', 
                            'TEXTCONTENT_IDX', 
                            sys.ODCICOLINFOLIST(sys.ODCICOLINFO('PH201510', 'TEXTCONTENT', '"CONTENT"', 'CLOB', NULL, NULL, 0, 0, 0, 0)), 
                            NULL, 
                            0, 
                            0, 0, 0), 
                     25.53598847, 
                     cost, 
                     sys.ODCIQUERYINFO(2, NULL, sys.ODCICOMPQUERYINFO(NULL, NULL)), 
                     sys.ODCIPREDINFO('CTXSYS', 
                            'CONTAINS', 
                            NULL, 
                            0), 
                     sys.ODCIARGDESCLIST(sys.ODCIARGDESC(3, NULL, NULL, NULL, NULL, NULL, NULL), sys.ODCIARGDESC(5, NULL, NULL, NULL, NULL, NULL, NULL), sys.ODCIARGDESC(2, 'TEXTCONTENT', 'PH201510', '"CONTENT"', NULL, NULL, NULL), sys.ODCIARGDESC(3, NULL, NULL, NULL, NULL, NULL, NULL)), 
                     :6, 
                     NULL 
                     , :7, 
                     sys.ODCIENV(:8,:9,:10,:11));                       