WITH x
     AS (SELECT ve.id
           FROM vefficacy ve
          WHERE     (ve.drug IN (    SELECT dh.name
                                       FROM drugshierarchy dh
                                      WHERE dh.drug = 1
                                 START WITH dh.name IN ( :EFFICACY_DRUGCLASS)
                                 CONNECT BY PRIOR dh.id = dh.parentid
                                 UNION
                                 SELECT dn.name
                                   FROM drugnames dn
                                  WHERE    (    COALESCE (
                                                   :EFFICACY_DRUGCLASS,
                                                   :EMPTY_VALUE) =
                                                   :EMPTY_VALUE
                                            AND COALESCE ( :EFFICACY_DRUG,
                                                          :EMPTY_VALUE) =
                                                   :EMPTY_VALUE)
                                        OR dn.name IN ( :EFFICACY_DRUG)))
                AND (ve.id IN (SELECT ei.efficacyid
                                 FROM efficacyindications ei
                                WHERE    COALESCE ( :EFFICACY_INDICATION,
                                                   :EMPTY_VALUE) =
                                            :EMPTY_VALUE
                                      OR ei.indicationid IN (    SELECT i.id
                                                                   FROM indication i
                                                             START WITH i.nameIN (
                                                                           :EFFICACY_INDICATION)
                                                             CONNECT BY PRIORi.id =
                                                                           i.parentid)))
                AND (   COALESCE ( :EFFICACY_SPECIE, :EMPTY_VALUE) =
                           :EMPTY_VALUE
                     OR ve.specie IN (    SELECT s.name
                                            FROM specie s
                                      START WITH s.nameIN ( :EFFICACY_SPECIE)
                                      CONNECT BY PRIOR s.id = s.parentid))
                AND (   COALESCE ( :EFFICACY_ENDPOINTID, :EMPTY_INT) =
                           :EMPTY_INT
                     OR ve.endpointid IN (    SELECT DISTINCT id
                                                FROM efficacyendpoints
                                          START WITH id IN ( :EFFICACY_ENDPOINTID)
                                          CONNECT BY PRIOR id = parentid))
                --                 AND ((:IS_PRECLINICAL = 'TRUE' AND ve.specie NOT IN ('Human')) OR (:IS_PRECLINICAL = 'FALSE' AND ve.specie IN ('Human')))
                AND (NVL (ve.groupsize, 0) BETWEEN NVL (
                                                      :EFFICACY_GROUPSIZE_LOWER,
                                                      :MIN_VALUE)
                                               AND NVL (
                                                      :EFFICACY_GROUPSIZE_UPPER,
                                                      :MAX_VALUE))
                AND (   COALESCE ( :EFFICACY_MONOCOMBINATION, :EMPTY_VALUE) =
                           :EMPTY_VALUE
                     OR ve.monocombination IN ( :EFFICACY_MONOCOMBINATION))
                AND (   COALESCE ( :EFFICACY_ROUTE, :EMPTY_VALUE) =
                           :EMPTY_VALUE
                     OR ve.route IN ( :EFFICACY_ROUTE))
                AND (   COALESCE ( :EFFICACY_PVALUE, :EMPTY_VALUE) =
                           :EMPTY_VALUE
                     OR ve.pvalue IN ( :EFFICACY_PVALUE))
                AND (   COALESCE ( :EFFICACY_DATAPROVIDER, :EMPTY_VALUE) =
                           :EMPTY_VALUE
                     OR ve.dataprovider IN ( :EFFICACY_DATAPROVIDER))
                AND (   ve.fdochistoric = :DOCUMENT_ISHISTORIC
                     OR ve.fdochistoric = 0))
SELECT *
  FROM (SELECT v.*,
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
               v.drug AS documentdrug,
               ROWNUM rn
          FROM vefficacy v JOIN x ON v.id = x.id)
 WHERE (rn BETWEEN :ROW_FIRST AND :ROW_LAST);


SELECT *
  FROM VEFFICACY
 WHERE specie IN ('Human');