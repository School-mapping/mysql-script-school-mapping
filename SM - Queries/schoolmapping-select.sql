USE SchoolMapping;

-- testes
select * from vw_escolas order by nome_escola desc;
select * from vw_verbas;


/*Gráfico de colunas ------------------------------------------------------------------------------------------------------------------------------------------------------------------ */

select * from vw_notas;

/*Gráfico bidirecional ---------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
SELECT
    n.regiao,
    n.media_nota,
    v.media_ptrf,
    n.ano_nota AS ano
FROM
    vw_notas n
    JOIN vw_verbas v ON v.regiao = n.regiao
    AND v.ano_verba = n.ano_nota
WHERE
    n.ano_nota = (
        SELECT
            MAX(ano_nota)
        FROM
            vw_notas
        WHERE
            ano_nota IN (
                SELECT
                    ano_verba
                FROM
                    vw_verbas
            )
    )
ORDER BY
    n.regiao;

/*KPIs -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------S*/
/*Media geral ideb ultimo ano %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
SELECT
    AVG(media_nota) as media_geral,
    ano_nota
FROM
    vw_notas
where
    ano_nota = (
        SELECT
            MAX(ano_nota)
        FROM
            vw_notas
    )
GROUP BY
    ano_nota;

/*Media geral ideb penultimo ano %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
SELECT
    AVG(media_nota) as media_geral,
    ano_nota
FROM
    vw_notas
GROUP BY
    ano_nota
ORDER BY
    ano_nota DESC
LIMIT
    1
OFFSET
    1;


/*total yltimo ano e penultimo ano e Diferença de ptrf $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
SELECT
    -- 1. Soma Total do Último Ano
    SUM(CASE
        WHEN vw.ano_verba = (SELECT MAX(ano_verba) FROM vw_verbas)
        THEN vw.soma_ptrf
        ELSE 0
    END) AS soma_ultimo_ano,

    -- 2. Soma Total do Penúltimo Ano
    SUM(CASE
        WHEN vw.ano_verba = (
            SELECT
                ano_verba
            FROM
                vw_verbas
            GROUP BY
                ano_verba
            ORDER BY
                ano_verba DESC
            LIMIT 1 OFFSET 1
        )
        THEN vw.soma_ptrf
        ELSE 0
    END) AS soma_penultimo_ano,

    -- 3. Diferença (Calculada após as somas)
    (
        SUM(CASE
            WHEN vw.ano_verba = (SELECT MAX(ano_verba) FROM vw_verbas)
            THEN vw.soma_ptrf
            ELSE 0
        END)
        -
        SUM(CASE
            WHEN vw.ano_verba = (
                SELECT
                    ano_verba
                FROM
                    vw_verbas
                GROUP BY
                    ano_verba
                ORDER BY
                    ano_verba DESC
                LIMIT 1 OFFSET 1
            )
            THEN vw.soma_ptrf
            ELSE 0
        END)
    ) AS diferenca_ptrf,
    
    -- 4. ACRESCENTADO: Último Ano (MAX)
    (SELECT MAX(ano_verba) FROM vw_verbas) AS ultimo_ano,

    -- 5. ACRESCENTADO: Penúltimo Ano
    (
        SELECT
            ano_verba
        FROM
            vw_verbas
        GROUP BY
            ano_verba
        ORDER BY
            ano_verba DESC
        LIMIT 1 OFFSET 1
    ) AS penultimo_ano
FROM
    vw_verbas AS vw;

/*KPIs -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------S*/
/*Lista de escolas ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
select distinct
    (nome_escola),
    codigo_inep,
    nota_ideb,
    endereco,
    cep
from
    vw_escolas
order by
    nota_ideb asc;

/*dashporescolas ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*Gráfico de coluna e linha */
SELECT
    id_escola,
    nome_escola,
    ano_ptrf,
    soma_ptrf,
    nota_ideb,
    ano_ideb
FROM
    vw_escolas
where
    id_escola = 680;

/*KPIS ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/* KPIS Ptrf */
SELECT
    ult.soma_ptrf AS ultimo_ano,
    (ult.soma_ptrf - pen.soma_ptrf) AS diferenca
FROM
    (
        SELECT
            ano_ptrf,
            soma_ptrf
        FROM
            vw_escolas
        WHERE
            id_escola = 680
            AND ano_ptrf IS NOT NULL
        ORDER BY
            ano_ptrf DESC
        LIMIT
            1
    ) AS ult
    CROSS JOIN (
        SELECT
            ano_ptrf,
            soma_ptrf
        FROM
            vw_escolas
        WHERE
            id_escola = 680
            AND ano_ptrf IS NOT NULL
        ORDER BY
            ano_ptrf DESC
        LIMIT
            1
        OFFSET
            1
    ) AS pen;

/* KPIS ideb */
SELECT
    ult.nota_ideb AS ultimo_ano,
    (ult.nota_ideb - pen.nota_ideb) AS diferenca
FROM
    (
        SELECT
            ano_ideb,
            nota_ideb
        FROM
            vw_escolas
        WHERE
            id_escola = 680
            AND ano_ideb <> 'N/A'
        ORDER BY
            ano_ideb DESC
        LIMIT
            1
    ) AS ult
    CROSS JOIN (
        SELECT
            ano_ideb,
            nota_ideb
        FROM
            vw_escolas
        WHERE
            id_escola = 200
            AND ano_ideb <> 'N/A'
        ORDER BY
            ano_ideb DESC
        LIMIT
            1
        OFFSET
            1
    ) AS pen;

/* Rank de escola - especifica*/
SELECT
    *
FROM
    (
        SELECT
            e.id AS id_escola,
            e.nome AS nome_escola,
            i.nota AS ideb,
            i.ano_emissao AS ano,
            RANK() OVER (
                ORDER BY
                    i.nota DESC
            ) AS posicao
        FROM
            TB_Escolas e
            JOIN TB_Ideb i ON i.id_escola = e.id
        WHERE
            i.ano_emissao = (
                SELECT
                    MAX(ano_emissao)
                FROM
                    TB_Ideb
            )
    ) AS ranking
WHERE
    ranking.id_escola = 680;