-- ============================================================
-- OPPGAVE 3 – LØSNING
-- Idempotent script som kan kjøres flere ganger
-- ============================================================

-- ------------------------------------------------------------
-- 1. Roller (opprettes kun hvis de ikke finnes)
-- ------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'student_role') THEN
CREATE ROLE student_role;
END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'foreleser_role') THEN
CREATE ROLE foreleser_role;
END IF;
END
$$;

-- ------------------------------------------------------------
-- 2. RLS på studenter-tabellen
-- ------------------------------------------------------------
ALTER TABLE studenter ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS student_select_own ON studenter;

CREATE POLICY student_select_own ON studenter
    FOR SELECT
                        USING (student_id = current_setting('app.current_student_id')::int);

-- ------------------------------------------------------------
-- 3. Foreleser skal se alle karakterer
-- ------------------------------------------------------------
DROP POLICY IF EXISTS foreleser_select_grades ON emneregistreringer;

CREATE POLICY foreleser_select_grades ON emneregistreringer
    FOR SELECT
                        TO foreleser_role
                        USING (true);

-- ------------------------------------------------------------
-- 4. Forhindre DELETE (kun admin)
-- ------------------------------------------------------------
DROP POLICY IF EXISTS prevent_delete ON emneregistreringer;

CREATE POLICY prevent_delete ON emneregistreringer
    FOR DELETE
USING (false);

-- ------------------------------------------------------------
-- 5. View: foreleser_karakteroversikt
-- ------------------------------------------------------------
DROP VIEW IF EXISTS foreleser_karakteroversikt;

CREATE VIEW foreleser_karakteroversikt AS
SELECT
    s.fornavn,
    s.etternavn,
    e.emne_navn,
    r.karakter,
    r.semester
FROM emneregistreringer r
         JOIN studenter s ON r.student_id = s.student_id
         JOIN emner e ON r.emne_id = e.emne_id;

GRANT SELECT ON foreleser_karakteroversikt TO foreleser_role;

-- ------------------------------------------------------------
-- 6. Audit-tabell for karakterendringer (oppgave 3)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS karakter_audit;

CREATE TABLE karakter_audit (
                                audit_id SERIAL PRIMARY KEY,
                                registrering_id INT,
                                gammel_karakter TEXT,
                                ny_karakter TEXT,
                                endret_av TEXT,
                                endret_tid TIMESTAMP DEFAULT now()
);

-- Gi roller tilgang til audit-tabellen (viktig!)
GRANT INSERT ON karakter_audit TO foreleser_role;
GRANT INSERT ON karakter_audit TO student_role;

-- Gi tilgang til sekvensen for SERIAL-kolonnen
GRANT USAGE, SELECT ON SEQUENCE karakter_audit_audit_id_seq TO foreleser_role;
GRANT USAGE, SELECT ON SEQUENCE karakter_audit_audit_id_seq TO student_role;

-- ------------------------------------------------------------
-- 7. Trigger for karakterendringer (oppgave 3)
-- ------------------------------------------------------------
DROP FUNCTION IF EXISTS log_karakter_endring() CASCADE;

CREATE FUNCTION log_karakter_endring()
    RETURNS trigger AS $$
BEGIN
    IF NEW.karakter IS DISTINCT FROM OLD.karakter THEN
        INSERT INTO karakter_audit (registrering_id, gammel_karakter, ny_karakter, endret_av)
        VALUES (OLD.registrering_id, OLD.karakter, NEW.karakter, current_user);
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_karakter_endring
    AFTER UPDATE ON emneregistreringer
    FOR EACH ROW
    EXECUTE FUNCTION log_karakter_endring();

-- ============================================================
-- BONUS: Audit-Logging for alle endringer i emneregistreringer
-- ============================================================

-- 1. Opprett audit_log-tabell (idempotent)
DROP TABLE IF EXISTS audit_log;

CREATE TABLE audit_log (
                           log_id SERIAL PRIMARY KEY,
                           tabell_navn VARCHAR(50),
                           operasjon VARCHAR(10),
                           bruker VARCHAR(50),
                           endret_data JSONB,
                           endret_tid TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Opprett trigger-funksjon (idempotent)
DROP FUNCTION IF EXISTS log_changes() CASCADE;

CREATE OR REPLACE FUNCTION log_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- DELETE bruker OLD
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (tabell_navn, operasjon, bruker, endret_data)
        VALUES (TG_TABLE_NAME, TG_OP, current_user, to_jsonb(OLD));
RETURN OLD;
END IF;

    -- INSERT og UPDATE bruker NEW
INSERT INTO audit_log (tabell_navn, operasjon, bruker, endret_data)
VALUES (TG_TABLE_NAME, TG_OP, current_user, to_jsonb(NEW));

RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Opprett trigger på emneregistreringer (idempotent)
DROP TRIGGER IF EXISTS emneregistreringer_audit ON emneregistreringer;

CREATE TRIGGER emneregistreringer_audit
    AFTER INSERT OR UPDATE OR DELETE ON emneregistreringer
    FOR EACH ROW EXECUTE FUNCTION log_changes();

-- Gi roller tilgang til audit_log-tabellen
GRANT INSERT ON audit_log TO foreleser_role;
GRANT INSERT ON audit_log TO student_role;

-- Gi tilgang til sekvensen for audit_log
GRANT USAGE, SELECT ON SEQUENCE audit_log_log_id_seq TO foreleser_role;
GRANT USAGE, SELECT ON SEQUENCE audit_log_log_id_seq TO student_role;