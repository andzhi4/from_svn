WITH endpointids
     AS (    SELECT /*+ materialize */
                    DISTINCT id
               FROM efficacyendpoints
         START WITH id IN ( :1)
         CONNECT BY PRIOR id = parentid),
     specienames
     AS (    SELECT /*+ materialize */
                    DISTINCT s.name
               FROM specie s
         START WITH s.name IN ( :2)
         CONNECT BY PRIOR s.id = s.parentid),
     ids
     AS (    SELECT /*+ materialize */
                    DISTINCT i.id
               FROM indication i
         START WITH i.name IN ( :3)
         CONNECT BY PRIOR i.id = i.parentid),
     drugnames
     AS (    SELECT /*+ materialize */
                    DISTINCT dh.name
               FROM drugshierarchy dh
              WHERE dh.drug = 1
         START WITH dh.name IN ( :4)
         CONNECT BY PRIOR dh.id = dh.parentid),
     x
     AS (SELECT v.*,
                USERENV ('sid') AS sessionid,
                COALESCE (v.fdocid, v.edocid, v.adocid) AS documentid,
                COALESCE (v.fdoc, v.edoc, v.adoc) AS documentname,
                COALESCE (v.ftype, v.etype, v.atype) AS documenttype,
                COALESCE (v.fdocpage, v.edocpage, v.adocpage) AS documentpage,
                COALESCE (v.fdoclength, v.edoclength, v.adoclength)
                   AS documentlength,
                COALESCE (v.fdocfile, v.edocfile, v.adocfile) AS documentfile,
                v.docyear AS documentyear,
                v.adocdate AS documentdate,
                v.adoccommitteeid AS documentcommitteeid,
                v.adoccommittee AS documentcommittee,
                v.fdochistoric AS documentishistoric,
                v.feature AS documentfeature,
                v.drug AS documentdrug
           FROM vefficacy v
          WHERE     (   COALESCE ( :5, :6) = :7
                     OR v.drug IN (SELECT * FROM drugnames))
                AND (   COALESCE ( :8, :9) = :10
                     OR v.id IN (SELECT ei.efficacyid
                                   FROM efficacyindications ei
                                  WHERE ei.indicationid IN (SELECT * FROM ids)))
                AND (   COALESCE ( :11, :12) = :13
                     OR v.specie IN (SELECT * FROM specienames))
                AND (   COALESCE ( :14, :15) = :16
                     OR v.endpointid IN (SELECT * FROM endpointids))
                AND (   ( :17 = 'TRUE' AND v.specie NOT IN ('Human'))
                     OR ( :18 = 'FALSE' AND v.specie IN ('Human')))
                AND (NVL (v.groupsize, 0) BETWEEN NVL ( :19, :20)
                                              AND NVL ( :21, :22))
                AND (   COALESCE ( :23, :24) = :25
                     OR v.monocombination IN ( :26))
                AND (COALESCE ( :27, :28) = :29 OR v.route IN ( :30))
                AND (COALESCE ( :31, :32) = :33 OR v.pvalue IN ( :34))
                AND (COALESCE ( :35, :36) = :37 OR v.dataprovider IN ( :38))
                AND (v.fdochistoric = :39 OR v.fdochistoric = 0))
SELECT *
  FROM (SELECT x.*, ROWNUM rn FROM x)
 WHERE (rn BETWEEN :40 AND :41)