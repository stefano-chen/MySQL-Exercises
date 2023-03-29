# Mostra le Studentesse di Ingegneria
SELECT * FROM studenti
WHERE matricola LIKE 'IN%'
  AND ((cf LIKE '_________4%') OR (cf LIKE '_________5%') OR (cf LIKE '_________6%') OR (cf LIKE '_________7%'));

#Mostra le Studentesse di Ingegneria usando la funzione SUBSTRING
#LE STRINGHE IN SQL INIZIANO DAL INDICE 1!!!
SELECT * FROM studenti
WHERE matricola LIKE 'IN%'
    AND SUBSTR(cf,10,1) IN ('4','5','6','7');


# Aggiungiamo la colonna genere per rendere la query più semplice
ALTER TABLE studenti
ADD COLUMN genere CHAR(1) NOT NULL;

# Disattiva la protezione contro query che modificano le righe senza specificare una condizione WHERE
SET SQL_SAFE_UPDATES = 0;
# Assegno M a tutte le righe della colonna genere
UPDATE studenti SET genere = 'M';
# Assegno F alle studentesse
UPDATE studenti SET genere = 'F' WHERE SUBSTR(cf,10,1) BETWEEN '4' AND '7';
# Riattivo il Safe Update
SET SQL_SAFE_UPDATES = 1;

# Aggiungo Vincolo di Controllo sulla colonna genere
ALTER TABLE studenti
ADD CHECK ( genere IN ('M', 'F') );

# Mostra tutte le studentesse di Ingegneria
SELECT * FROM studenti
WHERE matricola LIKE 'IN%' AND genere = 'F';


# Numero di Studenti che hanno preso la lode negli esami del prof. De Lorenzo
SELECT COUNT(DISTINCT e.studente)
FROM studenti s INNER JOIN esami e ON s.matricola = e.studente
    INNER JOIN corsi c on e.corso = c.codice INNER JOIN professori p on c.professore = p.matricola
WHERE e.lode = TRUE AND p.cognome = 'De Lorenzo';

# Studenti che hanno preso più di una lode negli esami del prof. De Lorenzo
SELECT e.studente, COUNT(e.lode) as NumeroLodi
FROM studenti s INNER JOIN esami e ON s.matricola = e.studente
    INNER JOIN corsi c on e.corso = c.codice INNER JOIN professori p on c.professore = p.matricola
WHERE e.lode = TRUE AND p.cognome = 'De Lorenzo'
GROUP BY e.studente HAVING NumeroLodi > 1;