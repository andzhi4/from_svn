WITH endpointids
     AS (    SELECT /*+ materialize */
                    DISTINCT id
               FROM efficacyendpoints
         START WITH id IN ( :EFFICACY_ENDPOINTID)
         CONNECT BY PRIOR id = parentid),
     specienames
     AS (    SELECT /*+ materialize */
                    DISTINCT s.name
               FROM specie s
         START WITH s.name IN ( :EFFICACY_SPECIE)
         CONNECT BY PRIOR s.id = s.parentid),
     ids
     AS (    SELECT /*+ materialize */
                    DISTINCT i.id
               FROM indication i
         START WITH i.name IN ( :EFFICACY_INDICATION)
         CONNECT BY PRIOR i.id = i.parentid),
     drugnames
     AS (    SELECT /*+ materialize */
                    DISTINCT dh.name
               FROM drugshierarchy dh
              WHERE dh.drug = 1
         START WITH dh.name IN ( :EFFICACY_DRUG)
         CONNECT BY PRIOR dh.id = dh.parentid),
     x
     AS (SELECT v.*,
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
          WHERE     (   COALESCE ( :EFFICACY_DRUG, :EMPTY_VALUE) =
                           :EMPTY_VALUE
                     OR v.drug IN (SELECT * FROM drugnames))
                AND (   COALESCE ( :EFFICACY_INDICATION, :EMPTY_VALUE) =
                           :EMPTY_VALUE
                     OR v.id IN (SELECT DISTINCT ei.efficacyid
                                   FROM efficacyindications ei
                                  WHERE ei.indicationid IN (SELECT * FROM ids)))
                AND (   COALESCE ( :EFFICACY_SPECIE, :EMPTY_VALUE) =
                           :EMPTY_VALUE
                     OR v.specie IN (SELECT * FROM specienames))
                AND (   COALESCE ( :EFFICACY_ENDPOINTID, :EMPTY_INT) =
                           :EMPTY_INT
                     OR v.endpointid IN (SELECT * FROM endpointids))
                AND (   (    :IS_PRECLINICAL = 'TRUE'
                         AND v.specie NOT IN ('Human'))
                     OR ( :IS_PRECLINICAL = 'FALSE' AND v.specie IN ('Human')))
                AND (NVL (v.groupsize, 0) BETWEEN NVL (
                                                     :EFFICACY_GROUPSIZE_LOWER,
                                                     :MIN_VALUE)
                                              AND NVL (
                                                     :EFFICACY_GROUPSIZE_UPPER,
                                                     :MAX_VALUE))
                AND (   COALESCE ( :EFFICACY_MONOCOMBINATION, :EMPTY_VALUE) =
                           :EMPTY_VALUE
                     OR v.monocombination IN ( :EFFICACY_MONOCOMBINATION))
                AND (   COALESCE ( :EFFICACY_ROUTE, :EMPTY_VALUE) =
                           :EMPTY_VALUE
                     OR v.route IN ( :EFFICACY_ROUTE))
                AND (   COALESCE ( :EFFICACY_PVALUE, :EMPTY_VALUE) =
                           :EMPTY_VALUE
                     OR v.pvalue IN ( :EFFICACY_PVALUE))
                AND (   COALESCE ( :EFFICACY_DATAPROVIDER, :EMPTY_VALUE) =
                           :EMPTY_VALUE
                     OR v.dataprovider IN ( :EFFICACY_DATAPROVIDER))
                AND (   v.fdochistoric = :DOCUMENT_ISHISTORIC
                     OR v.fdochistoric = 0))
SELECT *
  FROM (SELECT x.*, ROWNUM rn FROM x)
 WHERE rn < 10