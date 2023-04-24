# Start a Transaction to assign the most free professor to the only not taken course
start transaction;
select @prof:=p.matricola, sum(cfu) as totCFU from professori p inner join corsi c on p.matricola = c.professore
group by c.professore order by totCFU limit 1;
update corsi SET professore = @prof where professore is null;
commit;

# Create a Stored Procedure that return the average and weighted average of grades of all students
drop procedure if exists student_avg;

DELIMITER $$
create procedure student_avg()
begin
    select s.matricola, s.nome, s.cognome, sum(e.voto)/count(e.voto) as avg, sum(e.voto * c.cfu)/sum(c.cfu) as weightAVG
    from studenti s inner join esami e on s.matricola = e.studente inner join corsi c on e.corso = c.codice
    group by s.matricola;
end $$
delimiter ;

CALL student_avg();

# Create a Stored Procedure that return in a parameter the number of hours of a professor in input
# Raise a Error if the professor doesn't exist

drop procedure if exists prof_hours;

set @hours = 0;
set @prof_id = 41;

delimiter $$

create procedure prof_hours(OUT n_hours INT, IN prof INT)
begin
    select sum(cfu * 8) into n_hours
    from corsi where professore = prof;
    if n_hours is null then
        signal SQLSTATE '45000'
        SET message_text = 'Professor not found';
    end if;
end $$

delimiter ;

call prof_hours(@hours, @prof_id);

select @prof_id, @hours;

# Create a User Defined Function that return the study course from a student number

drop function if exists study_course;

delimiter $$

create function study_course(student CHAR(9))
RETURNS CHAR(4) DETERMINISTIC
begin
    return substr(student, 1, 4);
end $$

delimiter ;

select matricola, nome, cognome, study_course(matricola) as StudyCourse from studenti;

# Create a USER DEFINED FUNCTION that return the weighted average of a student grade

drop function if exists weight_avg;

delimiter $$

create function weight_avg(student CHAR(9))
RETURNS float deterministic
begin
    declare avg FLOAT;
    select sum(c.cfu * e.voto)/sum(c.cfu) into avg
    from studenti s inner join esami e on s.matricola = e.studente inner join corsi c on e.corso = c.codice
    where s.matricola = student;
    return avg;
end $$

delimiter ;

select matricola, nome, cognome, weight_avg(matricola) from studenti;

# Create a UDF that returns the rank of a student by the study course based on weighted average

drop function rank_student;

delimiter $$

create function rank_student(student CHAR(9))
RETURNS INT DETERMINISTIC
begin
    declare student_rank INT;
    if weight_avg(student) is null then
        return null;
    end if;
    select count(matricola) into student_rank from studenti
    where study_course(student) = study_course(matricola)
    AND weight_avg(matricola) > weight_avg(student);
    return student_rank + 1 ;
end $$

delimiter ;

select matricola, nome, cognome,study_course(matricola) as Course,
       weight_avg(matricola) as weightAVG, rank_student(matricola) as StudentRank
from studenti order by Course, weightAVG DESC;


# Create a Trigger to Log all the new insert professors

create table if not exists professori_assunzioni(
    matricola INT,
    nome VARCHAR(45) NOT NULL,
    cognome VARCHAR(45) NOT NULL,
    dataAssunzione date NOT NULL,
    PRIMARY KEY (matricola),
    FOREIGN KEY (matricola) REFERENCES professori(matricola)
    ON DELETE CASCADE ON UPDATE CASCADE
);

drop trigger if exists log_assunzioni;

delimiter $$

create trigger log_assunzioni
AFTER INSERT ON professori
FOR EACH ROW
BEGIN
    INSERT into professori_assunzioni(matricola, nome, cognome, dataAssunzione)
        VALUES(NEW.matricola, NEW.nome, NEW.cognome, CURDATE());
end $$

delimiter ;

INSERT into professori(nome, cognome, cf, settore) VALUES ('Stefano', 'Chen', 'CHNSFN01L19L719Y', 'ING -INF/05');
delete from professori where cf = 'CHNSFN01L19L719Y';

# Create a Trigger that if a course without prof is insert then it automatically assigned to a professor with no course

drop trigger if exists assign_prof;

delimiter $$

create trigger assign_prof
BEFORE INSERT ON corsi
FOR EACH ROW
BEGIN
    if NEW.professore is null then
        SET NEW.professore = (select matricola from professori left join corsi c on professori.matricola = c.professore
                         where codice is null order by matricola limit 1);
    end if;
end $$

delimiter ;

INSERT INTO corsi VALUES ('999IN', 'Sex', 12, null);

delete from corsi where codice = '999IN';


