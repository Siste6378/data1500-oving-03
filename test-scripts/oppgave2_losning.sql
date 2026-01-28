-- 1. Studenter uten emneregistreringer
SELECT
    s.student_id,
    s.fornavn,
    s.etternavn,
    s.epost
FROM studenter s
         LEFT JOIN emneregistreringer er
                   ON s.student_id = er.student_id
WHERE er.student_id IS NULL;

-- 2. Emner uten registrerte studenter
SELECT
    e.emne_id,
    e.emne_kode,
    e.emne_navn
FROM emner e
         LEFT JOIN emneregistreringer er
                   ON e.emne_id = er.emne_id
WHERE er.emne_id IS NULL;

-- 3. Studenter med høyeste karakter per emne
WITH karakterverdi AS (
    SELECT
        er.registrering_id,
        er.student_id,
        er.emne_id,
        CASE
            WHEN er.karakter = 'A' THEN 5
            WHEN er.karakter = 'B' THEN 4
            WHEN er.karakter = 'C' THEN 3
            WHEN er.karakter = 'D' THEN 2
            WHEN er.karakter = 'E' THEN 1
            ELSE 0
            END AS verdi
    FROM emneregistreringer er
)
SELECT
    s.fornavn,
    s.etternavn,
    e.emne_navn,
    kv.verdi AS karakterverdi
FROM karakterverdi kv
         JOIN studenter s ON kv.student_id = s.student_id
         JOIN emner e ON kv.emne_id = e.emne_id
WHERE kv.verdi = (
    SELECT MAX(verdi)
    FROM karakterverdi kv2
    WHERE kv2.emne_id = kv.emne_id
)
ORDER BY e.emne_navn, kv.verdi DESC;

-- 4. Rapport: student, program og antall emner
SELECT
    s.fornavn,
    s.etternavn,
    p.program_navn,
    COUNT(er.registrering_id) AS antall_emner
FROM studenter s
         LEFT JOIN programmer p ON s.program_id = p.program_id
         LEFT JOIN emneregistreringer er ON s.student_id = er.student_id
GROUP BY s.student_id, s.fornavn, s.etternavn, p.program_navn
ORDER BY s.etternavn, s.fornavn;

-- 5. Studenter registrert på både DATA1500 og DATA1100
SELECT
    s.student_id,
    s.fornavn,
    s.etternavn
FROM studenter s
WHERE s.student_id IN (
    SELECT er.student_id
    FROM emneregistreringer er
             JOIN emner e ON er.emne_id = e.emne_id
    WHERE e.emne_kode = 'DATA1500'
)
  AND s.student_id IN (
    SELECT er.student_id
    FROM emneregistreringer er
             JOIN emner e ON er.emne_id = e.emne_id
    WHERE e.emne_kode = 'DATA1100'
);