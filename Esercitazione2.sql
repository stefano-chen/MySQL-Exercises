# Quali studenti non hanno mai preso una lode?
select * from studenti where matricola not in (select distinct studente from esami where lode = true);

# Quali docenti svolgono un monte ore annuo minore di 120 ore?
select p.matricola,concat(p.nome, ' ' ,p.cognome) as professore, sum(c.cfu) * 8 as ore
from professori p inner join corsi c on p.matricola = c.professore
group by c.professore having ore < 120;

# Mostra la media ponderata di ogni studente
select s.nome, s.cognome, sum(voto * cfu)/sum(cfu) as media
from studenti s inner join esami e on s.matricola = e.studente inner join corsi c on e.corso = c.codice
group by e.studente;

# Casi di omonimia tra studenti e/o professori
select u.nome, count(u.nome) as ricorenze from
(select nome, cognome from studenti
union
select nome, cognome from professori) u
group by u.nome having ricorenze > 1;

# Prepared Statement che mostri tutti gli studenti appartenenti ad un corso di laurea passato come parametro
prepare show_studenti_corso from 'select * from studenti s where substr(s.matricola, 1, 4) = ?';

set @cds = 'IN05';

execute show_studenti_corso using @cds;

# Prepared Statement che mostri tutti gli studenti che hanno superato l' esame di un dato corso, il cui codice è passato come paramentro
prepare show_passed_students from 'select s.nome, s.cognome, e.corso, e.voto, e.lode from studenti s inner join esami e on s.matricola = e.studente where e.corso = ?';

set @corso = '008QV';

execute show_passed_students using @corso;

# Quali sono i voti preferiti di ogni professore?
drop view if exists view_mark_freq;

create view view_mark_freq as
    select p.matricola, p.nome, p.cognome, e.voto, count(e.voto) as freq
    from professori p inner join corsi c on p.matricola = c.professore inner join esami e on c.codice = e.corso
    group by p.matricola, e.voto;

select *
from view_mark_freq d1
where d1.freq = (select max(freq) from view_mark_freq d2 where d1.matricola = d2.matricola);

# Quali sono gli studenti più bravi di ogni corso di laurea
# la bravura viene misurata dalla somma dei voti per il suoi cfu.

drop view if exists view_bravura;

create view view_bravura as
    select substr(s.matricola, 1, 4) as CdL, s.nome, s.cognome, sum(e.voto * c.cfu) as bravura
    from studenti s inner join esami e on s.matricola = e.studente inner join corsi c on e.corso = c.codice
    group by s.matricola;

select  Cdl, nome, cognome, bravura
from view_bravura v1
where bravura = (select MAX(bravura) from view_bravura v2 where v1.Cdl = v2.Cdl);
