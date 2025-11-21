CREATE DATABASE SchoolMapping;
USE SchoolMapping;

/* INFOS_CREDENCIAIS */

CREATE TABLE TB_Empresas (
id INT PRIMARY KEY AUTO_INCREMENT,
razao_social VARCHAR(45) NOT NULL,
cnpj CHAR(14) NOT NULL,
email VARCHAR(45) NOT NULL,
telefone CHAR(11) NOT NULL
);

CREATE TABLE TB_Perfis (
id INT PRIMARY KEY AUTO_INCREMENT,
cargo VARCHAR(20) NOT NULL 
);

CREATE TABLE TB_Usuarios (
id INT PRIMARY KEY AUTO_INCREMENT,
id_perfil INT NOT NULL DEFAULT 1,
id_empresa INT,
nome VARCHAR(60) NOT NULL,
email VARCHAR(45) NOT NULL,
senha VARCHAR(45) NOT NULL, 
data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT fk_perfil_tb_usuarios
		FOREIGN KEY (id_perfil) REFERENCES TB_Perfis(id),
	CONSTRAINT fk_empresa_tb_usuarios
		FOREIGN KEY (id_empresa) REFERENCES TB_Empresas(id)
);

CREATE TABLE TB_Tokens (
id INT PRIMARY KEY AUTO_INCREMENT,
id_empresa INT,
id_usuario INT,
token VARCHAR(45) NOT NULL,
ativo BOOLEAN NOT NULL,
	CONSTRAINT fk_token_tb_usuarios
		FOREIGN KEY (id_usuario) REFERENCES TB_Usuarios(id),
	CONSTRAINT fk_token_tb_empresas
		FOREIGN KEY (id_empresa) REFERENCES TB_Empresas(id),
	CONSTRAINT chk_empresa_ou_usuario
		CHECK (
			(id_usuario IS NOT NULL AND id_empresa IS NULL) OR
            (id_usuario IS NULL AND id_empresa IS NOT NULL)
		)
);

CREATE TABLE TB_Logs (
id INT PRIMARY KEY AUTO_INCREMENT,
data_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
nivel VARCHAR(10) NOT NULL,
descricao VARCHAR(255) NOT NULL,
origem VARCHAR(40) NOT NULL
);

CREATE TABLE TB_Config_Slack (
id INT PRIMARY KEY AUTO_INCREMENT,
canal_slack VARCHAR(45) NOT NULL,
intervalo_envio TIME NOT NULL,
parametro_notificacao VARCHAR(45) NOT NULL,
ativo BOOLEAN NOT NULL,
data_ultima_atualizacao DATETIME DEFAULT CURRENT_TIMESTAMP
);

/* INFO_ESCOLARES*/

CREATE TABLE TB_Regioes (
id INT PRIMARY KEY AUTO_INCREMENT,
nome VARCHAR(10) NOT NULL /*da para ser ENUM*/
);

CREATE TABLE TB_Enderecos (
id INT AUTO_INCREMENT,
id_regiao INT,
cep CHAR(9) NOT NULL, # Inserir com " - "
bairro VARCHAR(45) NOT NULL,
logradouro VARCHAR(45) NOT NULL,
numero VARCHAR(10) NOT NULL,
	CONSTRAINT fk_regiao_tb_enderecos
		FOREIGN KEY (id_regiao) REFERENCES TB_Regioes(id),
	CONSTRAINT pk_composta_tb_enderecos 
		PRIMARY KEY (id, id_regiao)
);

CREATE TABLE TB_Escolas (
id INT PRIMARY KEY AUTO_INCREMENT,
id_endereco INT,
nome VARCHAR(100) NOT NULL,
codigo_inep CHAR(8) NOT NULL,
subprefeitura VARCHAR(60),
	CONSTRAINT fk_endereco_tb_escolas
		FOREIGN KEY (id_endereco) REFERENCES TB_Enderecos(id)
);

CREATE TABLE TB_Ideb (
id INT PRIMARY KEY AUTO_INCREMENT,
id_escola INT NOT NULL,
nota DECIMAL (3,1) NOT NULL,
ano_emissao YEAR NOT NULL,
	CONSTRAINT fk_escola_tb_ideb
		FOREIGN KEY (id_escola) REFERENCES TB_Escolas(id)
);

CREATE TABLE TB_Verbas (
id INT PRIMARY KEY AUTO_INCREMENT,
id_escola INT NOT NULL,
ano YEAR NOT NULL,
portaria_sme VARCHAR(60),
valor_primeira_parcela DECIMAL(12,2) NOT NULL,
valor_segunda_parcela DECIMAL(12,2),
valor_terceira_parcela DECIMAL(12,2),
valor_vulnerabilidade DECIMAL(12,2),
valor_extraordinario DECIMAL(12,2),
valor_gremio DECIMAL(12,2),
	CONSTRAINT fk_escola_tb_verbas
		FOREIGN KEY (id_escola) REFERENCES TB_Escolas(id)
);

INSERT INTO TB_Perfis (cargo) VALUES
('Comum'),
('Administrador');

INSERT INTO TB_Regioes (nome) VALUES
('Norte'),
('Leste'),
('Sul'),
('Centro'),
('Oeste');

SELECT COUNT(*) AS total_escolas
FROM TB_Escolas;
SELECT * FROM TB_Escolas;

SELECT COUNT(*) AS TB_Verbas
FROM TB_Verbas;
SELECT * FROM TB_Verbas;

SELECT COUNT(*) AS TB_Ideb
FROM TB_Ideb;
SELECT * FROM TB_Ideb;

SELECT COUNT(*) AS TB_Enderecos
FROM TB_Enderecos;
SELECT * FROM TB_Enderecos;




/*Gráfico de colunas ------------------------------------------------------------------------------------------------------------------------------------------------------------------ */
	SELECT 
		AVG(ideb.nota) AS media_nota,
		ideb.ano_emissao AS ano_nota,
		endereco.id_regiao AS regiao
	FROM TB_Ideb AS ideb
	JOIN TB_Escolas AS escola 
		ON ideb.id_escola = escola.id
	JOIN TB_Enderecos AS endereco 
		ON escola.id_endereco = endereco.id
	GROUP BY ideb.ano_emissao, endereco.id_regiao;




/*Gráfico bidirecional ---------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
	SELECT
		r.nome AS regiao,
		ideb.ano_emissao AS ano,
		AVG(ideb.nota) AS media_ideb,
		AVG(
			verba.valor_primeira_parcela +
			IFNULL(verba.valor_segunda_parcela, 0) +
			IFNULL(verba.valor_terceira_parcela, 0) +
			IFNULL(verba.valor_vulnerabilidade, 0) +
			IFNULL(verba.valor_extraordinario, 0) +
			IFNULL(verba.valor_gremio, 0)
		) AS media_ptrf
	FROM TB_Ideb AS ideb
	JOIN TB_Escolas AS e 
		ON ideb.id_escola = e.id
	JOIN TB_Enderecos AS ender 
		ON e.id_endereco = ender.id
	JOIN TB_Regioes AS r 
		ON ender.id_regiao = r.id
	JOIN TB_Verbas AS verba 
		ON verba.id_escola = e.id
	   AND verba.ano = ideb.ano_emissao        
	WHERE ideb.ano_emissao = (
		SELECT MAX(ano_emissao) FROM TB_Ideb
	)
	GROUP BY r.nome, ideb.ano_emissao;



/*KPIs -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------S*/
	
    /*Media geral ideb ultimo ano %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
	SELECT 
		AVG(ideb.nota) AS media_nota,
		ideb.ano_emissao AS ano_nota
	FROM TB_Ideb AS ideb
	JOIN TB_Escolas AS escola 
		ON ideb.id_escola = escola.id
	WHERE ideb.ano_emissao = (
		SELECT MAX(ano_emissao) FROM TB_Ideb
	)
	GROUP BY ideb.ano_emissao;


	/*Media geral ideb ultimo ano - feito com IA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
	SELECT 
		AVG(ideb.nota) AS media_nota,
		ideb.ano_emissao AS ano_nota
	FROM TB_Ideb AS ideb
	WHERE ideb.ano_emissao = (
		SELECT ano_emissao
		FROM TB_Ideb
		GROUP BY ano_emissao
		ORDER BY ano_emissao DESC
		LIMIT 1 OFFSET 1  -- pega o 2º maior (penúltimo)
	)
	GROUP BY ideb.ano_emissao;

	/*Soma geral ptrf ultimo ano $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
	SELECT SUM(
			valor.valor_primeira_parcela +
			IFNULL(valor.valor_segunda_parcela, 0) +
			IFNULL(valor.valor_terceira_parcela, 0) +
			IFNULL(valor.valor_vulnerabilidade, 0) +
			IFNULL(valor.valor_extraordinario, 0) +
			IFNULL(valor.valor_gremio, 0)
		) as soma_total
		FROM TB_Verbas AS valor
		WHERE valor.ano = (SELECT MAX(ano) FROM TB_Verbas);


/*Diferença de ptrf ultimo ano x penultimo ano $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
SELECT
(
  SELECT SUM(
        valor.valor_primeira_parcela +
        IFNULL(valor.valor_segunda_parcela, 0) +
        IFNULL(valor.valor_terceira_parcela, 0) +
        IFNULL(valor.valor_vulnerabilidade, 0) +
        IFNULL(valor.valor_extraordinario, 0) +
        IFNULL(valor.valor_gremio, 0)
    ) as soma_total
    FROM TB_Verbas AS valor
    WHERE valor.ano = (SELECT MAX(ano) FROM TB_Verbas)
)
-
(
    SELECT SUM(
        v.valor_primeira_parcela +
        IFNULL(v.valor_segunda_parcela, 0) +
        IFNULL(v.valor_terceira_parcela, 0) +
        IFNULL(v.valor_vulnerabilidade, 0) +
        IFNULL(v.valor_extraordinario, 0) +
        IFNULL(v.valor_gremio, 0)
    )
    FROM TB_Verbas v
    WHERE v.ano = (
        SELECT ano
        FROM TB_Verbas
        GROUP BY ano
        ORDER BY ano DESC
        LIMIT 1 OFFSET 1
    )
) AS diferenca_ptrf;
/*KPIs -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------S*/

/*Lista de escolas ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
SELECT 
	escola.nome as nome_escola,  
    escola.codigo_inep as codigo_inep,
    ideb.nota as nota_ideb,
    concat(
		endereco.logradouro, ", ",
        endereco.numero, " - ",
        endereco.bairro
    ) as endereco,
    endereco.cep as cep
    FROM TB_Escolas as escola
	JOIN TB_Ideb as ideb
        ON escola.id = ideb.id_escola
	JOIN TB_Enderecos as endereco
		ON endereco.id = escola.id_endereco;
/*Lista de escolas ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

/*dashporescolas ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
	
    /*Gráfico de coluna e linha */
	SELECT 
		v.ano AS ano,
		SUM(
			v.valor_primeira_parcela +
			IFNULL(v.valor_segunda_parcela, 0) +
			IFNULL(v.valor_terceira_parcela, 0) +
			IFNULL(v.valor_vulnerabilidade, 0) +
			IFNULL(v.valor_extraordinario, 0) +
			IFNULL(v.valor_gremio, 0)
		) AS soma_total_repasse,
		i.nota AS nota_ideb
	FROM TB_Verbas AS v
	LEFT JOIN TB_Ideb AS i 
		ON i.id_escola = v.id_escola
		AND i.ano_emissao = v.ano 
	WHERE v.id_escola = 1
	GROUP BY v.ano, i.nota
	ORDER BY v.ano DESC;


	/*KPIS ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
		
        /* KPIS Ptrf */
		SELECT
		/* 1. Total do último ano */
		(
			SELECT SUM(
				v.valor_primeira_parcela +
				IFNULL(v.valor_segunda_parcela, 0) +
				IFNULL(v.valor_terceira_parcela, 0) +
				IFNULL(v.valor_vulnerabilidade, 0) +
				IFNULL(v.valor_extraordinario, 0) +
				IFNULL(v.valor_gremio, 0)
			)
			FROM TB_Verbas v
			WHERE v.id_escola = 1
			  AND v.ano = (SELECT MAX(ano) FROM TB_Verbas WHERE id_escola = 1)
		) AS total_ultimo_ano,
		(
			(
				SELECT SUM(
					v.valor_primeira_parcela +
					IFNULL(v.valor_segunda_parcela, 0) +
					IFNULL(v.valor_terceira_parcela, 0) +
					IFNULL(v.valor_vulnerabilidade, 0) +
					IFNULL(v.valor_extraordinario, 0) +
					IFNULL(v.valor_gremio, 0)
				)
				FROM TB_Verbas v
				WHERE v.id_escola = 1
				  AND v.ano = (SELECT MAX(ano) FROM TB_Verbas WHERE id_escola = 1)
			)
			-
			(
				SELECT SUM(
					v.valor_primeira_parcela +
					IFNULL(v.valor_segunda_parcela, 0) +
					IFNULL(v.valor_terceira_parcela, 0) +
					IFNULL(v.valor_vulnerabilidade, 0) +
					IFNULL(v.valor_extraordinario, 0) +
					IFNULL(v.valor_gremio, 0)
				)
				FROM TB_Verbas v
				WHERE v.id_escola = 1
				  AND v.ano = (
						SELECT ano
						FROM TB_Verbas
						WHERE id_escola = 1
						GROUP BY ano
						ORDER BY ano DESC
						LIMIT 1 OFFSET 1
				  )
			)
		) AS diferenca;
        
        
        /* KPIS ideb */
        SELECT
    /* 1. Nota do último ano */
    (
        SELECT i.nota
        FROM TB_Ideb i
        WHERE i.id_escola = 1
        ORDER BY i.ano_emissao DESC
        LIMIT 1
    ) AS ideb_ultimo_ano,

    /* 2. Diferença: (último - penúltimo) */
    (
        (
            SELECT i.nota
            FROM TB_Ideb i
            WHERE i.id_escola = 1
            ORDER BY i.ano_emissao DESC
            LIMIT 1
        )
        -
        (
            SELECT i.nota
            FROM TB_Ideb i
            WHERE i.id_escola = 1
            ORDER BY i.ano_emissao DESC
            LIMIT 1 OFFSET 1
        )
    ) AS diferenca_ideb;


	/* Rank de escola - especifica*/
        SELECT *
			FROM (
				SELECT 
					e.id AS id_escola,
					e.nome AS nome_escola,
					i.nota AS ideb,
					i.ano_emissao AS ano,
					RANK() OVER (ORDER BY i.nota DESC) AS posicao
				FROM TB_Escolas e
				JOIN TB_Ideb i 
					ON i.id_escola = e.id
				WHERE i.ano_emissao = (
					SELECT MAX(ano_emissao)
					FROM TB_Ideb
				)
			) AS ranking
			WHERE ranking.id_escola = 1;

