/*
	1. Ime, prezime, spol (ispisati ‘MUŠKI’, ‘ŽENSKI’, ‘NEPOZNATO’, ‘OSTALO’),
	   ime države i prosječna plaća u toj državi za svakog trenera.
*/

SELECT t.name as Ime_i_prezime, 
    CASE 
        WHEN t.sex = 'M' THEN 'MUŠKI'
        WHEN t.sex = 'F' THEN 'ŽENSKI'
        WHEN t.sex = 'U' THEN 'NEPOZNATO'
        WHEN t.sex = 'O' THEN 'OSTALO'
		END AS Spol,
    c.Name as Država, 
    c.AverageSalary as Prosječna_plata
FROM Trainer t
JOIN Center ce on ce.Id = t.CenterId
JOIN Country c on c.Id = ce.CountryId;

/*
	2. Naziv i termin održavanja svake sportske igre zajedno s imenima glavnih trenera
	   u formatu Prezime, I.; npr. Horvat, M.; Petrović, T.).
*/

SELECT a.Name AS Naziv_aktivnosti, 
    s.Date AS Termin_održavanja, 
    CONCAT(
        RIGHT(t.Name, LENGTH(t.Name) - POSITION(' ' IN t.Name)), 
        ', ', 
        LEFT(t.Name, 1), 
        '.'
    ) AS Glavni_trener
FROM 
    Activity a
JOIN Schedule s ON a.ID = s.ActivityId
JOIN TrainerActivity ta ON a.ID = ta.ActivityId
JOIN Trainer t ON ta.TrainerId = t.ID
WHERE ta.TrainerType = 'lead';

/*
	3. Top 3 fitness centra s najvećim brojem aktivnosti u rasporedu
*/

SELECT ce.Name AS Fitness_centar, 
    COUNT(s.ActivityId) AS Broj_aktivnosti
FROM Center ce
JOIN Trainer t ON ce.ID = t.CenterId
JOIN TrainerActivity ta ON t.ID = ta.TrainerId
JOIN Activity a ON ta.ActivityId = a.ID
JOIN Schedule s ON a.ID = s.ActivityId
GROUP BY ce.Name
ORDER BY Broj_aktivnosti DESC
LIMIT 3;

/*
	4. Po svakom terneru koliko trenutno aktivnosti vodi; ako nema aktivnosti, ispiši “DOSTUPAN”,
	   ako ima do 3 ispiši “AKTIVAN”, a ako je na više ispiši “POTPUNO ZAUZET”.
*/

SELECT t.Name AS Trener,
    COUNT(ta.ActivityId) AS Broj_aktivnosti,
    CASE 
        WHEN COUNT(ta.ActivityId) = 0 THEN 'DOSTUPAN'
        WHEN COUNT(ta.ActivityId) <= 3 THEN 'AKTIVAN'
        ELSE 'POTPUNO ZAUZET'
    END AS Status
FROM Trainer t
LEFT JOIN TrainerActivity ta ON t.ID = ta.TrainerId
GROUP BY t.Name
ORDER BY t.Name;

/*
	5. Imena svih članova koji trenutno sudjeluju na nekoj aktivnosti.
*/

SELECT m.Name AS Član
FROM Member m
JOIN MemberActivity ma ON m.ID = ma.MemberId;

/*
	6. Sve trenere koji su vodili barem jednu aktivnost između 2019. i 2022.
*/

SELECT DISTINCT t.Name AS Trener
FROM Trainer t
JOIN TrainerActivity ta ON t.ID = ta.TrainerId
JOIN Schedule s ON ta.ActivityId = s.ActivityId
WHERE s.Date BETWEEN '2019-01-01' AND '2022-12-31';

/*
	7. Prosječan broj sudjelovanja po tipu aktivnosti po svakoj državi.
*/

SELECT c.Name AS Država,
    a.Type AS Tip_aktivnosti,
    COUNT(ma.MemberId)::float / COUNT(DISTINCT a.ID) AS Prosječan_broj_sudjelovanja
FROM Country c
JOIN Center ce ON c.ID = ce.CountryId
JOIN Trainer t ON ce.ID = t.CenterId
JOIN TrainerActivity ta ON t.ID = ta.TrainerId
JOIN Activity a ON ta.ActivityId = a.ID
JOIN MemberActivity ma ON a.ID = ma.ActivityId
GROUP BY c.Name, a.Type;

/*
	8. Top 10 država s najvećim brojem sudjelovanja u injury rehabilitation tipu aktivnosti
*/

SELECT c.Name AS Država,
    COUNT(ma.MemberId) AS Broj_sudjelovanja
FROM Country c
JOIN Center ce ON c.ID = ce.CountryId
JOIN Trainer t ON ce.ID = t.CenterId
JOIN TrainerActivity ta ON t.ID = ta.TrainerId
JOIN Activity a ON ta.ActivityId = a.ID
JOIN MemberActivity ma ON a.ID = ma.ActivityId
WHERE a.Type = 'rehab'
GROUP BY c.Name
ORDER BY Broj_sudjelovanja DESC
LIMIT 10;

/*
	9. Ako aktivnost nije popunjena, ispiši uz nju “IMA MJESTA”, a ako je popunjena ispiši “POPUNJENO”
*/

SELECT a.Name AS Aktivnost,
    CASE WHEN COUNT(ma.MemberId) < a.Capacity THEN 'IMA MJESTA'
        ELSE 'POPUNJENO'
    END AS Status
FROM Activity a
LEFT JOIN MemberActivity ma ON a.ID = ma.ActivityId
GROUP BY a.ID;

/*
	10. 10 najplaćenijih trenera, ako po svakoj aktivnosti dobije prihod kao brojSudionika * cijenaPoTerminu
*/

SELECT t.Name AS Trener,
    SUM(a.Price * (SELECT COUNT(*) FROM MemberActivity ma WHERE ma.ActivityId = a.ID)) AS Ukupan_prihod
FROM Trainer t
JOIN TrainerActivity ta ON t.ID = ta.TrainerId
JOIN Activity a ON ta.ActivityId = a.ID
GROUP BY t.Name
ORDER BY Ukupan_prihod DESC
LIMIT 10;
