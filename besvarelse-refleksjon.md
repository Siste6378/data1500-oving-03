# Besvarelse av refleksjonsspørsmål - DATA1500 Oppgavesett 1.3

Skriv dine svar på refleksjonsspørsmålene fra hver oppgave her.

---

## Oppgave 1: Docker-oppsett og PostgreSQL-tilkobling

### Spørsmål 1: Hva er fordelen med å bruke Docker i stedet for å installere PostgreSQL direkte på maskinen?

**Ditt svar:**

[Skriv ditt svar her]
Docker gjør at PostgreSQL kjører isolert i en container, uten å påvirke resten av systemet. Det blir enklere å 
sette opp, enklere å fjerne, og man unngår konflikter med andre versjoner eller programmer. Hele miljøet blir også 
likt for alle studenter, noe som gjør feilsøking og samarbeid mye enklere.

---

### Spørsmål 2: Hva betyr "persistent volum" i docker-compose.yml? Hvorfor er det viktig?

**Ditt svar:**

[Skriv ditt svar her]
Et persistent volum betyr at dataene lagres utenfor selve containeren. Selv om containeren stoppes eller slettes, 
ligger dataene fortsatt trygt på maskinen. Dette er viktig fordi en database ikke skal miste innholdet sitt hver 
gang man starter eller oppdaterer containeren.
---

### Spørsmål 3: Hva skjer når du kjører `docker-compose down`? Mister du dataene?

**Ditt svar:**

[Skriv ditt svar her]
docker-compose down stopper og fjerner containeren, men volumet blir ikke slettet. Det betyr at dataene fortsatt 
ligger lagret og kommer tilbake neste gang containeren startes. Man mister bare data hvis man også sletter volumet manuelt.

---

### Spørsmål 4: Forklar hva som skjer når du kjører `docker-compose up -d` første gang vs. andre gang.

**Ditt svar:**

[Skriv ditt svar her]
Første gang opprettes containeren, nettverket og volumet. PostgreSQL initialiseres, og init‑skriptene kjøres for å lage tabeller 
og fylle inn testdata. Andre gang bruker Docker det eksisterende volumet, så databasen starter mye raskere og init‑skriptene kjøres ikke på nytt.
---

### Spørsmål 5: Hvordan ville du delt docker-compose.yml-filen med en annen student? Hvilke sikkerhetshensyn må du ta?

**Ditt svar:**

[Skriv ditt svar her]
Jeg kunne delt filen via GitHub eller som en vanlig tekstfil. Det viktigste er å ikke dele sensitive data som passord eller API‑nøkler 
i klartekst. Hvis docker-compose.yml inneholder passord, bør de flyttes til miljøvariabler eller en .env‑fil som ikke deles offentlig

---

## Oppgave 2: SQL-spørringer og databaseskjema

### Spørsmål 1: Hva er forskjellen mellom INNER JOIN og LEFT JOIN? Når bruker du hver av dem?

**Ditt svar:**

[Skriv ditt svar her]
INNER JOIN returnerer kun rader som har match i begge tabeller. Hvis en rad ikke har en tilhørende rad i den andre tabellen, blir den filtrert bort.
LEFT JOIN returnerer alle rader fra venstre tabell, selv om det ikke finnes en match i høyre tabell. Manglende verdier fylles med NULL.
Jeg bruker INNER JOIN når jeg kun vil ha data som hører sammen i begge tabeller, og LEFT JOIN når jeg vil beholde alle rader fra venstre tabell, 
også de som mangler tilknytning.

---

### Spørsmål 2: Hvorfor bruker vi fremmednøkler? Hva skjer hvis du prøver å slette et program som har studenter?

**Ditt svar:**

[Skriv ditt svar her]
Fremmednøkler sikrer referensiell integritet i databasen. De sørger for at relasjoner mellom tabeller er gyldige, og hindrer at man får “hengende” data 
som peker til noe som ikke finnes. Hvis jeg prøver å slette et program som fortsatt har studenter knyttet til seg, vil databasen stoppe operasjonen og 
gi en feil. Dette beskytter dataene mot inkonsistens.

---

### Spørsmål 3: Forklar hva `GROUP BY` gjør og hvorfor det er nødvendig når du bruker aggregatfunksjoner.

**Ditt svar:**

[Skriv ditt svar her]
GROUP BY grupperer rader basert på én eller flere kolonner, slik at aggregatfunksjoner som COUNT, AVG, SUM og MAX kan beregnes per gruppe i stedet 
for på hele tabellen. Det er nødvendig fordi aggregatfunksjoner gir én verdi per gruppe. Uten GROUP BY ville databasen ikke vite hvordan radene skal 
deles opp før beregningen.

---

### Spørsmål 4: Hva er en indeks og hvorfor er den viktig for ytelse?

**Ditt svar:**

[Skriv ditt svar her]
En indeks er en datastruktur som gjør det raskere å finne rader i en tabell, omtrent som et register i en bok. I stedet for å skanne hele tabellen, 
kan databasen slå opp verdier direkte i indeksen. Indekser er viktige for ytelse fordi de dramatisk reduserer tiden det tar å kjøre spørringer, 
spesielt på store tabeller eller kolonner som ofte brukes i WHERE, JOIN eller ORDER BY.

---

### Spørsmål 5: Hvordan ville du optimalisert en spørring som er veldig treg?

**Ditt svar:**

[Skriv ditt svar her]
Jeg ville først sjekket om spørringen bruker riktige indekser på kolonner som filtreres eller joines på. Deretter ville jeg analysert
spørringen med EXPLAIN for å se hvor flaskehalsen ligger. Jeg kunne også forenkle spørringen, redusere unødvendige JOINs, bruke riktige
betingelser, eller normalisere data hvis strukturen skaper problemer.
---

## Oppgave 3: Brukeradministrasjon og GRANT

### Spørsmål 1: Hva er prinsippet om minste rettighet? Hvorfor er det viktig?

**Ditt svar:**

[Skriv ditt svar her]
Prinsippet om minste rettighet betyr at en bruker kun skal få de rettighetene som er nødvendige for å utføre sine oppgaver – ikke mer. 
Dette er viktig fordi det reduserer risikoen for feil, misbruk og sikkerhetsbrudd. Hvis en konto blir kompromittert, 
begrenser dette også hvor mye skade som kan gjøres.

---

### Spørsmål 2: Hva er forskjellen mellom en bruker og en rolle i PostgreSQL?

**Ditt svar:**

[Skriv ditt svar her]
En bruker er en konto som kan logge inn i databasen. En rolle er en samling rettigheter som kan tildeles brukere eller andre roller. 
Brukere representerer personer eller systemer, mens roller representerer tilgangsnivåer eller funksjoner.
---

### Spørsmål 3: Hvorfor er det bedre å bruke roller enn å gi rettigheter direkte til brukere?

**Ditt svar:**

[Skriv ditt svar her]
Roller gjør tilgangskontroll enklere og mer oversiktlig. I stedet for å gi rettigheter til hver enkelt bruker, kan man gi rettigheter 
til en rolle og la brukere arve disse. Det gjør administrasjon enklere, mer konsistent og mindre feilutsatt, spesielt når mange brukere skal ha samme type tilgang.
---

### Spørsmål 4: Hva skjer hvis du gir en bruker `DROP` rettighet? Hvilke sikkerhetsproblemer kan det skape?

**Ditt svar:**

[Skriv ditt svar her]
n bruker med DROP‑rettighet kan slette tabeller, views eller andre databaseobjekter. Dette kan føre til tap av data, 
ødelagte applikasjoner og alvorlige driftsproblemer. Hvis kontoen blir misbrukt eller kompromittert, kan hele databasen bli ødelagt.

---

### Spørsmål 5: Hvordan ville du implementert at en student bare kan se sine egne karakterer, ikke andres?

**Ditt svar:**

[Skriv ditt svar her]
Jeg ville brukt en av disse metodene:
- Row‑Level Security (RLS): Opprette en policy som filtrerer rader basert på studentens egen bruker-ID.
- Views: Lage et view som kun viser rader for den innloggede studenten, og gi SELECT‑rettighet til dette viewet.
- Applikasjonslogikk: La applikasjonen sende spørringer som inkluderer studentens ID, og aldri gi direkte tilgang til hele tabellen.
  
RLS er den mest sikre og databasedrevne løsningen.

---

## Notater og observasjoner

Bruk denne delen til å dokumentere interessante funn, problemer du møtte, eller andre observasjoner:

[Skriv dine notater her]
- Testet SELECT, INSERT og DELETE som ulike roller og så tydelig forskjellen i rettigheter.
- Lærte hvordan roller arver rettigheter og hvordan GRANT/REVOKE påvirker tilgang.
- Fikk erfaring med å bruke Docker‑containere og psql‑terminalen parallelt.


## Oppgave 4: Brukeradministrasjon og GRANT

1. **Hva er Row-Level Security og hvorfor er det viktig?**
   - Svar her...
- Row‑Level Security (RLS) er en mekanisme i PostgreSQL som lar databasen filtrere rader basert på hvem som spør.
  I stedet for å gi eller nekte tilgang til hele tabeller, kan du si:
- “Denne brukeren får bare se rader som tilhører dem selv.”
- “Forelesere får se alle rader.”
  Hvorfor viktig:
- Det er databasen selv som håndhever reglene, ikke applikasjonen.
- Det hindrer at brukere får tilgang til data de ikke skal se, selv om applikasjonen har en bug.
- Det gir sterk, innebygd sikkerhet som følger dataene uansett hvordan de brukes.
  Kort sagt: RLS er zero‑trust på radnivå.

2. **Hva er forskjellen mellom RLS og kolonnebegrenset tilgang?**
   - Svar her...
   - RLS styrer hvilke rader en bruker får se.
     Eksempel: Student får bare se sine egne karakterer.
     Kolonnebegrensning styrer hvilke kolonner en bruker får se.
     Eksempel: Student får se karakter, men ikke personnummer.

   - RLS bestemmer hvilke rader du får se, mens kolonnebegrensning bestemmer hvilke felter i hver rad du får se.

3. **Hvordan ville du implementert at en student bare kan se karakterer for sitt eget program?**
   - Svar her...
   - Jeg ville lagret studentens program i databasen, satt en session‑variabel ved innlogging 
   - (f.eks. SET app.current_program_id = 'IT'), og laget en RLS‑policy som kun tillater rader hvor 
   - program_id = current_setting('app.current_program_id'). Da filtrerer databasen automatisk bort alt som ikke tilhører studentens program.


4. **Hva er sikkerhetsproblemene ved å bruke views i stedet for RLS?**
   - Svar her...
   - Views kan omgås hvis brukeren har tilgang til basistabellen, de beskytter ikke mot endringer (INSERT/UPDATE/DELETE), og de er 
   - ikke en ekte sikkerhetsmekanisme — bare et logisk lag. RLS er derimot en faktisk sikkerhetsbarriere som databasen håndhever.

5. **Hvordan ville du testet at RLS-policyer fungerer korrekt?**
   - Svar her...
   - Jeg ville logget inn som ulike roller (student, foreleser, admin), kjørt SELECT/UPDATE/DELETE og sjekket at hver rolle kun 
   - får tilgang til de radene de skal. Jeg ville også forsøkt å omgå RLS (f.eks. SET row_security = off) for å bekrefte 
   - at vanlige brukere ikke kan skru det av.


---

## Referanser

- PostgreSQL dokumentasjon: https://www.postgresql.org/docs/
- Docker dokumentasjon: https://docs.docker.com/

