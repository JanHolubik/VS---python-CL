-- Historie poskytnutých úvěrů

-- Napište dotaz, který připraví souhrn poskytnutých úvěrů v následujících dimenzích:
-- rok, měsíc,
-- čtvrtletí,
-- celkový.
-- celková výše úvěrů,
-- průměrná výše úvěru,
-- celkový počet poskytnutých půjček.

select
   year(l.date) as rok,
   month(l.date) as mesic,
   quarter(l.date) as ctvrtleti,
   sum(l.amount) as celkovy_uver,
   avg(l.amount) as prum_uver,
   count(loan_id) as celkovy_pocet_pujcek
from loan l
group by year(l.date), quarter(l.date), month(l.date), day(l.date) ;



--  Na webu databáze můžeme najít informaci, že v databázi je celkem 682 udělených úvěrů, z nichž 606 bylo splaceno a 76 ne.

-- zjištění celkového počtu 682
select
    count(loan_id) as pocet_uveru
from loan l
;
-- 682 udělených úvěrů


 -- spočítání jednotlivých skupin
select
    loan.status,
    count(status) as pocet
from loan
group by loan.status
order by status
;
-- A+C  - splacené  203 + 403 = 606
-- B+D  - nesplacené 31 +45 = 76


-- Zjistěte zůstatek splacených úvěrů dělený podle pohlaví klienta.

with cte_splecene_dle_pohlavi as (
    select
       l.amount,
       status,  -- splacené/nesplacené
       gender as pohlaví
       from loan l
       join disp d on l.account_id = d.account_id
       join client c on d.client_id = c.client_id
       where l.status in ('A', 'C') -- jen splacené půjčky
)
select
    pohlaví,
    sum(amount) as zustatek_splacenych_uveru
from cte_splecene_dle_pohlavi
group by pohlaví ;

-- Zůstatek splacených je : pro ŽENY - 54629148  a  MUŽE - 55330572



--  Analýza účtů

-- Napište dotaz, který seřadí účty podle následujících kritérií:
-- počet poskytnutých půjček (klesající),
-- objem poskytnutých úvěrů (klesající),
-- průměrná výše úvěru,
-- Zohledňují se pouze plně splacené půjčky.

with cte_anylza as (
    select
        loan_id,
        sum(amount) as suma_poskytnutych_uveru, -- součet splacených částek úvěru
        count(amount) as count_poskytnutych_uveru, -- počet splacených půjček
        avg(amount) as prumer  -- průměrná výše splacených půjček
    from loan
    where status in ('A', 'C')  -- pouze splacené půjčky
    group by loan_id
)
select
    *,
    dense_rank() over (order by suma_poskytnutych_uveru desc ) as suma_rank,
    dense_rank() over (order by count_poskytnutych_uveru desc ) as count_rank
from cte_anylza;

-- Analýza klienta - 1. část

-- Kdo má více splacených půjček - ženy nebo muži?
-- Jaký je průměrný věk dlužníka dělený podle pohlaví?


with cte_prumer_vek as (
SELECT
    c.gender,
    2025 - extract(year from birth_date) as age,
    sum(l.amount) as loans_amount,
    count(l.amount) as loans_count
FROM loan as l
join account a on l.account_id = a.account_id
join disp d on a.account_id = d.account_id
join client c on d.client_id = c.client_id
WHERE True
    AND l.status IN ('A', 'C')
    AND d.type = 'OWNER'
GROUP BY c.gender, 2
)

SELECT
    gender,
    avg(age) as avg_age,
    SUM(loans_count) as loans_count
FROM cte_prumer_vek
GROUP BY gender
;
 -- průměrný věk je u MUŽŮ - 67.5  a u ŽEN - 65.5 let
 -- Více splacených půjček mají ŽENY - 307


-- Analýza klienta - 2. část
-- která oblast má nejvíce klientů,
-- ve které oblasti byl splacen nejvyšší počet půjček,
-- ve které oblasti byla vyplacena nejvyšší částka půjček,

with cte_oblast as (
    select
         dt.A2,
         count(distinct c.client_id) as customer_amount,
         sum(l.amount) as suma_amount,
         sum(l.amount) as loans_given_amount,
         count(l.amount) as loans_given_count
     from loan l
     join account a on l.account_id = a.account_id
     join disp d on a.account_id = d.account_id
     join client c on d.client_id = c.client_id
     join district dt on a.district_id = dt.district_id

     WHERE True
        AND l.status IN ('A', 'C')
        AND d.type = 'OWNER'
     group by dt.district_id
)

-- nejvyšší počet splacených půjček je v Hl.m. Praha
SELECT *
FROM cte_oblast
ORDER BY loans_given_count DESC
LIMIT 1

-- nevyší splacená půjčka je v Hl.m. Praha
SELECT *
FROM cte_oblast
ORDER BY loans_given_amount DESC
LIMIT 1


-- nejvetší počet zákazníků -- SOKOLOV
select *
from cte_oblast
order by customer_amount
limit 1
;

-- Analýza klienta - 3. část
-- Použijte dotaz vytvořený v předchozím úkolu a upravte ho tak,
-- aby určoval procentuální podíl každého okresu na celkovém objemu poskytnutých úvěrů.

with cte_oblast as (
    select
         dt.A2 as okres,
         count(distinct c.client_id) as customer_amount,
         sum(l.amount) as suma_amount,
         sum(l.amount) as pocet_pujcek,
         count(l.amount) as loans_given_count
     from loan l
     join account a on l.account_id = a.account_id
     join disp d on a.account_id = d.account_id
     join client c on d.client_id = c.client_id
     join district dt on a.district_id = dt.district_id

     WHERE True
        AND l.status IN ('A', 'C')
        AND d.type = 'OWNER'
     group by dt.district_id
)
SELECT
    okres,
    customer_amount,
    pocet_pujcek,
    loans_given_count,
    ROUND(100 * pocet_pujcek / SUM(pocet_pujcek) OVER (), 2) AS procentualni_podil
FROM cte_oblast
ORDER BY procentualni_podil DESC;

-- Výběr - 1. část

-- zůstatek na jejich účtu je vyšší než 1000,
-- mají více než 5 půjček,
-- narodili se po roce 1990.


select
    l.account_id,
    cast(a.date as date) as datum_narozeni,
    sum(amount - payments) as zustatek_na_uctu,
    count(loan_id) as pocet_pujcek
from loan l
join account a on l.account_id = a.account_id
join disp d on a.account_id = d.account_id
WHERE True
        AND l.status IN ('A', 'C')  -- splacené půjčky
        AND d.type = 'OWNER'   -- majitel účtu
        AND a.date >= '1990-01-01'   -- rok narození > než 1990
     group by account_id,datum_narozeni
having sum(amount - payments) > 1000  -- zustatek na účtu > než 1000
       and count(loan_id) >5
;


-- Výběr - 2. část

select
    l.account_id,
    cast(a.date as date) as datum_narozeni,
    sum(amount - payments) as zustatek_na_uctu,
    count(loan_id) as pocet_pujcek
from loan l
join account a on l.account_id = a.account_id
join disp d on a.account_id = d.account_id
WHERE True
        AND l.status IN ('A', 'C')  -- splacené půjčky
        AND d.type = 'OWNER'   -- majitel účtu
        AND a.date >= '1990-01-01'   -- rok narození > než 1990
     group by account_id,datum_narozeni
having sum(amount - payments) > 1000  -- zustatek na účtu > než 1000
     --   and count(loan_id) >5  -- všichni zákazníci mají pouze jednu půjčku !
;

--

-- Karty s vypršením platnosti

DELIMITER $$

CREATE PROCEDURE financial11_127.generate_cards_at_expiration_report(IN p_date DATE)
BEGIN
    WITH cte_karty AS (
        SELECT
            ct.client_id,
            card_id,
            issued AS datum_vydani_karty,
            DATE_ADD(issued, INTERVAL 3 YEAR) AS datum_expirace_karty,
            A3 AS adresa_klienta
        FROM card c
        JOIN disp d ON c.disp_id = d.disp_id
        JOIN client ct ON d.client_id = ct.client_id
        JOIN district dt ON ct.district_id = dt.district_id
    )
    SELECT *
    FROM cte_karty
    WHERE p_date BETWEEN DATE_ADD(datum_expirace_karty, INTERVAL -7 DAY) AND datum_expirace_karty;

END$$

DELIMITER ;

CALL financial11_127.generate_cards_at_expiration_report('2001-01-01');

