# Oppgave 3: Brukeradministrasjon og GRANT

## Læringsmål

Etter å ha fullført denne oppgaven skal du:
- Forstå rollen som databaseadministrator (DBA)
- Opprette brukere og roller i PostgreSQL
- Tildele rettigheter med GRANT
- Forstå prinsippet om minste rettighet (Principle of Least Privilege)
- Teste tilgang fra ulike brukerkontoer

## Bakgrunn

**Databaseadministrator (DBA)** er ansvarlig for:
- Brukeradministrasjon (opprette/slette brukere)
- Sikkerhetskopier og gjenoppretting
- Overvåking og optimalisering
- Tilgangsadministrasjon (GRANT/REVOKE)

**Prinsippet om minste rettighet:** En bruker skal bare ha de rettighetene som er nødvendig for å utføre sitt arbeid. For eksempel:
- **Admin:** Full tilgang
- **Foreleser:** Lese- og skrive-tilgang til studentdata
- **Student:** Kun lese-tilgang til sitt eget data

**GRANT-syntaks:**
```sql
GRANT <rettigheter> ON <objekt> TO <bruker/rolle>;
```

**Rettigheter:**
- `SELECT` - Lese data
- `INSERT` - Legge til data
- `UPDATE` - Endre data
- `DELETE` - Slette data
- `ALL` - Alle rettigheter

## Oppgave

### Del 1: Verifiser eksisterende roller

Databasen har allerede tre roller opprettet. Verifiser dem (kan også vurdere å bruke pgAdmin eller DBeaver:

```bash
	$ docker-compoes exec postgres psql -U admin -d data1500_db
```

Passord: `admin123`

Kjør:
```sql
-- Vis alle roller
SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%';

-- Vis rettigheter for admin_role
SELECT grantee, privilege_type 
FROM information_schema.role_table_grants 
WHERE grantee = 'admin_role';
```

### Del 2: Test tilgang som foreleser

Åpne en ny terminal og koble til som foreleser:

```bash
	$ docker-compose exec postgres psql -U foreleser_role -d data1500_db
```

Passord: `foreleser_pass`

Prøv disse kommandoene:

```sql
-- Skal fungere (SELECT)
SELECT * FROM studenter;

-- Skal fungere (INSERT)
INSERT INTO studenter (fornavn, etternavn, epost, program_id) 
VALUES ('Test', 'Bruker', 'test@example.com', 1);

-- Skal IKKE fungere (DELETE)
DELETE FROM studenter WHERE student_id = 1;
```

Hva skjer? Dokumenter resultatene.
-- SELECT * FROM studenter; 
Funket i terminalen ✅

-- INSERT INTO studenter (fornavn, etternavn, epost, program_id)
VALUES ('Test', 'Bruker', 'test@example.com', 1);
Funket i terminalen ✅

-- DELETE FROM studenter WHERE student_id = 1;
Funket ikke, ikke tilgang ❌

### Del 3: Test tilgang som student

Åpne en ny terminal og koble til som student:

```bash
	docker-compose exec psql -U student_role -d data1500_db
```

Passord: `student_pass`

Prøv disse kommandoene:

```sql
-- Skal fungere (SELECT)
SELECT * FROM studenter;

-- Skal IKKE fungere (INSERT)
INSERT INTO studenter (fornavn, etternavn, epost, program_id) 
VALUES ('Test', 'Bruker', 'test@example.com', 1);

-- Skal IKKE fungere (UPDATE)
UPDATE studenter SET fornavn = 'Ola' WHERE student_id = 1;
```

Hva skjer? Dokumenter resultatene.
-- SELECT * FROM studenter;
Funket i terminalen ✅

-- INSERT INTO studenter (fornavn, etternavn, epost, program_id)
VALUES ('Test', 'Bruker', 'test@example.com', 1);
Funket ikke, ikke tilgang ❌

-- DELETE FROM studenter WHERE student_id = 1;
Funket ikke, ikke tilgang ❌

### Del 4: Opprett ny rolle med begrenset tilgang

Som admin, opprett en ny rolle som bare kan lese emner:

```bash
	# Koble til som admin
	$ docker-compose exec postgres psql -U admin -d data1500_db
```

```sql
-- Opprett rollen
CREATE ROLE emne_leser LOGIN PASSWORD 'emne_pass';

-- Se i metadata om rollen er laget 
SELECT * FROM pg_roles WHERE rolname = 'emne_leser';

-- Gi kun SELECT-rettighet på emner-tabellen
GRANT SELECT ON emner TO emne_leser;

-- Verifiser
SELECT * FROM information_schema.role_table_grants 
WHERE grantee = 'emne_leser';
```

Test tilgangen:

```bash
	$ docker-compose exec postgres psql -U emne_leser -d data1500_db
```

Passord: `emne_pass`

```sql
-- Skal fungere
SELECT * FROM emner;

-- Skal IKKE fungere
SELECT * FROM studenter;
```

### Del 5: Opprett rolle med UPDATE-rettighet

Opprett en rolle som kan oppdatere karakterer:

```sql
-- Koble til som admin
psql -h localhost -U admin -d data1500_db

-- Opprett rollen
CREATE ROLE karakter_oppdaterer LOGIN PASSWORD 'karakter_pass';

-- Gi SELECT og UPDATE på emneregistreringer
GRANT SELECT, UPDATE ON emneregistreringer TO karakter_oppdaterer;

-- Gi SELECT på relaterte tabeller (for JOIN)
GRANT SELECT ON studenter, emner TO karakter_oppdaterer;
```

Test tilgangen:

```bash
	$ docker-compose exec postgres psql -U karakter_oppdaterer -d data1500_db
```

Passord: `karakter_pass`

```sql
-- Skal fungere (SELECT)
SELECT * FROM emneregistreringer;

-- Skal fungere (UPDATE)
UPDATE emneregistreringer SET karakter = 'A' 
WHERE registrering_id = 1;

-- Skal IKKE fungere (DELETE)
DELETE FROM emneregistreringer WHERE registrering_id = 1;
```

### Del 6: Revoke-rettigheter

Fjern UPDATE-rettighet fra foreleser_role:

```sql
-- Koble til som admin
psql -h localhost -U admin -d data1500_db

-- Fjern UPDATE-rettighet
REVOKE UPDATE ON emneregistreringer FROM foreleser_role;

-- Verifiser
SELECT grantee, privilege_type 
FROM information_schema.role_table_grants 
WHERE grantee = 'foreleser_role';
```

Test at foreleser ikke lenger kan oppdatere:

```bash
	$ docker-compose exec postgres psql -h localhost -U foreleser_role -d data1500_db
```

```sql
-- Skal IKKE fungere lenger
UPDATE emneregistreringer SET karakter = 'B' 
WHERE registrering_id = 1;
```

## Oppgaver du skal løse

1. **Opprett en rolle `program_ansvarlig` som kan lese og oppdatere programmer-tabellen, men ikke slette**

2. **Opprett en rolle `student_self_view` som bare kan se sitt eget studentdata (hint: bruk en VIEW)**

3. **Gi `foreleser_role` tilgang til å lese fra `student_view` (som allerede er opprettet)**

4. **Opprett en rolle `backup_bruker` som bare har SELECT-rettighet på alle tabeller**

5. **Lag en oversikt over alle roller og deres rettigheter**

**Viktig:** Lagre alle SQL-spørringene og SQL-setnigene dine i en fil `oppgave3_losning.sql` i mappen `test-scripts` for at man kan teste disse med kommando (OBS! du må forsikre at spørringene / setnignen ikke påvirker databaseintegritet/ønsket resultat, hvis de utføres flere ganger):

```bash
docker-compose exec postgres psql -U admin -d data1500_db -f test-scripts/oppgave2_losning.sql
```

## Refleksjonsspørsmål

Besvar refleksjonsspørsmål i filen **besvarelse-refleksjon.md**


## Avslutning

Når du er ferdig:
- Du forstår brukeradministrasjon i PostgreSQL
- Du kan tildele og fjerne rettigheter med GRANT/REVOKE
