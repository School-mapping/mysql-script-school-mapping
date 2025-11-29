CREATE DATABASE SchoolMapping;

USE SchoolMapping;

/* INFOS_CREDENCIAIS */
CREATE TABLE
    TB_Empresas (
        id INT PRIMARY KEY AUTO_INCREMENT,
        razao_social VARCHAR(45) NOT NULL,
        cnpj CHAR(14) NOT NULL UNIQUE,
        email VARCHAR(80) NOT NULL,
        telefone CHAR(11) NOT NULL
    );

CREATE TABLE
    TB_Perfis (
        id INT PRIMARY KEY AUTO_INCREMENT,
        cargo VARCHAR(20) NOT NULL UNIQUE
    );

CREATE TABLE
    TB_Usuarios (
        id INT PRIMARY KEY AUTO_INCREMENT,
        id_perfil INT NOT NULL DEFAULT 1,
        id_empresa INT,
        nome VARCHAR(60) NOT NULL,
        email VARCHAR(80) NOT NULL UNIQUE,
        senha VARCHAR(100) NOT NULL,
        data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT fk_perfil_tb_usuarios FOREIGN KEY (id_perfil) REFERENCES TB_Perfis (id),
        CONSTRAINT fk_empresa_tb_usuarios FOREIGN KEY (id_empresa) REFERENCES TB_Empresas (id)
    );
    
CREATE TABLE
    TB_Status_Chamados (
        id INT PRIMARY KEY AUTO_INCREMENT,
        tipo VARCHAR(45) NOT NULL UNIQUE
    );
CREATE TABLE
    TB_Chamados (
        id INT PRIMARY KEY AUTO_INCREMENT,
        id_usuario INT NOT NULL,
        id_status INT,
        assunto VARCHAR(45) NOT NULL,
        descricao TEXT NOT NULL,
        tipo VARCHAR(45) NOT NULL,
        CONSTRAINT fk_usuario_tb_chamados FOREIGN KEY (id_usuario) REFERENCES TB_Usuarios (id),
        CONSTRAINT fk_status_tb_chamados FOREIGN KEY (id_status) REFERENCES TB_Status (id)
    );
    
CREATE TABLE
    TB_Tokens (
        id INT PRIMARY KEY AUTO_INCREMENT,
        id_empresa INT UNIQUE NOT NULL,
        token VARCHAR(45) NOT NULL UNIQUE,
        ativo BOOLEAN NOT NULL,
        CONSTRAINT fk_token_tb_empresas FOREIGN KEY (id_empresa) REFERENCES TB_Empresas (id)
        -- CONSTRAINT chk_empresa_ou_usuario CHECK (
        --     (
        --         id_usuario IS NOT NULL
        --         AND id_empresa IS NULL
        --     )
        --     OR (
        --         id_usuario IS NULL
        --         AND id_empresa IS NOT NULL
        --     )
        -- )
    );

-- INFO CONFIG
CREATE TABLE
    TB_Logs (
        id INT PRIMARY KEY AUTO_INCREMENT,
        data_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
        nivel VARCHAR(10) NOT NULL,
        descricao VARCHAR(255) NOT NULL,
        origem VARCHAR(40) NOT NULL
    );

CREATE TABLE
    TB_Config_Slack (
        id INT PRIMARY KEY AUTO_INCREMENT,
        canal_slack VARCHAR(45) NOT NULL,
        intervalo_envio TIME NOT NULL,
        parametro_notificacao VARCHAR(45) NOT NULL,
        ativo BOOLEAN NOT NULL,
        data_ultima_atualizacao DATETIME DEFAULT CURRENT_TIMESTAMP
    );

CREATE TABLE
    TB_Canal_Slack (
        id INT PRIMARY KEY AUTO_INCREMENT,
        canal_slack VARCHAR(45) NOT NULL
    );

CREATE TABLE
    TB_Notificacoes_Slack (
        id INT PRIMARY KEY AUTO_INCREMENT,
        canal_slack VARCHAR(45) NOT NULL
    );
    
CREATE TABLE
    TB_Canais_Slack (
        id INT PRIMARY KEY AUTO_INCREMENT,
        canal_slack VARCHAR(45) NOT NULL
    );
    
    
/* INFO_ESCOLARES*/
CREATE TABLE
    TB_Regioes (
        id INT PRIMARY KEY AUTO_INCREMENT,
        nome VARCHAR(10) NOT NULL UNIQUE /*da para ser ENUM*/
    );

CREATE TABLE
    TB_Enderecos (
        id INT AUTO_INCREMENT,
        id_regiao INT,
        cep CHAR(9) NOT NULL, /* 9 pois vai Inserir com " - " */
        bairro VARCHAR(45) NOT NULL,
        logradouro VARCHAR(45) NOT NULL,
        numero VARCHAR(10) NOT NULL,
        CONSTRAINT fk_regiao_tb_enderecos FOREIGN KEY (id_regiao) REFERENCES TB_Regioes (id),
        CONSTRAINT pk_composta_tb_enderecos PRIMARY KEY (id, id_regiao)
    );

CREATE TABLE
    TB_Escolas (
        id INT PRIMARY KEY AUTO_INCREMENT,
        id_endereco INT UNIQUE,
        nome VARCHAR(100) NOT NULL,
        codigo_inep CHAR(8) NOT NULL UNIQUE,
        subprefeitura VARCHAR(60),
        CONSTRAINT fk_endereco_tb_escolas FOREIGN KEY (id_endereco) REFERENCES TB_Enderecos (id)
    );

CREATE TABLE
    TB_Ideb (
        id INT PRIMARY KEY AUTO_INCREMENT,
        id_escola INT NOT NULL,
        nota DECIMAL(3, 1) NOT NULL,
        ano_emissao YEAR NOT NULL,
        CONSTRAINT fk_escola_tb_ideb FOREIGN KEY (id_escola) REFERENCES TB_Escolas (id)
    );

CREATE TABLE
    TB_Verbas (
        id INT PRIMARY KEY AUTO_INCREMENT,
        id_escola INT NOT NULL,
        ano YEAR NOT NULL,
        portaria_sme VARCHAR(60),
        valor_primeira_parcela DECIMAL(12, 2) NOT NULL,
        valor_segunda_parcela DECIMAL(12, 2),
        valor_terceira_parcela DECIMAL(12, 2),
        valor_vulnerabilidade DECIMAL(12, 2),
        valor_extraordinario DECIMAL(12, 2),
        valor_gremio DECIMAL(12, 2),
        CONSTRAINT fk_escola_tb_verbas FOREIGN KEY (id_escola) REFERENCES TB_Escolas (id)
    );

INSERT INTO
    TB_Perfis (cargo)
VALUES
    ('Comum'),
    ('Administrador');

INSERT INTO
    TB_Regioes (nome)
VALUES
    ('Norte'),
    ('Leste'),
    ('Sul'),
    ('Centro'),
    ('Oeste');
    
-- Campo de testes
SELECT COUNT(*) AS TB_Escolas FROM TB_Escolas;
SELECT * FROM TB_Escolas;

SELECT COUNT(*) AS TB_Verbas FROM TB_Verbas;
SELECT * FROM TB_Verbas;

SELECT COUNT(*) AS TB_Ideb FROM TB_Ideb;
SELECT * FROM TB_Ideb;

SELECT COUNT(*) AS TB_Enderecos FROM TB_Enderecos;
SELECT * FROM TB_Enderecos;

/*VIWs  */
/*View media notas */
CREATE VIEW
    vw_notas as
SELECT
    AVG(ideb.nota) AS media_nota,
    ideb.ano_emissao AS ano_nota,
    regiao.nome AS regiao
FROM
    TB_Ideb AS ideb
    JOIN TB_Escolas AS escola ON ideb.id_escola = escola.id
    JOIN TB_Enderecos AS endereco ON escola.id_endereco = endereco.id
    JOIN TB_Regioes AS regiao ON endereco.id_regiao = regiao.id
GROUP BY
    ideb.ano_emissao,
    regiao.nome
order by
    ano_nota desc;



/*View media verbas */
create view
    vw_verbas as
SELECT
    AVG(
        verba.valor_primeira_parcela + IFNULL (verba.valor_segunda_parcela, 0) + IFNULL (verba.valor_terceira_parcela, 0) + IFNULL (verba.valor_vulnerabilidade, 0) + IFNULL (verba.valor_extraordinario, 0) + IFNULL (verba.valor_gremio, 0)
    ) AS media_ptrf,
    SUM(
        verba.valor_primeira_parcela + IFNULL (verba.valor_segunda_parcela, 0) + IFNULL (verba.valor_terceira_parcela, 0) + IFNULL (verba.valor_vulnerabilidade, 0) + IFNULL (verba.valor_extraordinario, 0) + IFNULL (verba.valor_gremio, 0)
    ) as soma_ptrf,
    verba.ano AS ano_verba,
    regiao.nome AS regiao
FROM
    TB_Verbas AS verba
    JOIN TB_Escolas AS escola ON verba.id_escola = escola.id
    JOIN TB_Enderecos AS endereco ON escola.id_endereco = endereco.id
    JOIN TB_Regioes AS regiao ON endereco.id_regiao = regiao.id
GROUP BY
    verba.ano,
    regiao.nome
order by
    ano_verba desc;



/*Lista de escolas - feito com auxilio de IA*/
CREATE VIEW vw_escolas AS
SELECT
    escola.id AS id_escola,
    escola.nome AS nome_escola,
    escola.codigo_inep AS codigo_inep,

    CONCAT(
        endereco.logradouro, ', ', endereco.numero, ' - ', endereco.bairro
    ) AS endereco,
    endereco.cep AS cep,

    -- Ano consolidado (de IDEB ou PTRF)
    anos.ano AS ano,

    -- IDEB relacionado ao ano
    COALESCE(CAST(ideb.nota AS CHAR), 'N/A') AS nota_ideb,
    COALESCE(CAST(ideb.ano_emissao AS CHAR), 'N/A') AS ano_ideb,

    -- PTRF relacionado ao ano
    COALESCE(CAST(verba.soma_ptrf AS CHAR), 'N/A') AS soma_ptrf,
    COALESCE(CAST(verba.ano AS CHAR), 'N/A') AS ano_ptrf

FROM TB_Escolas AS escola

LEFT JOIN TB_Enderecos AS endereco
    ON endereco.id = escola.id_endereco

-- União de todos os anos vinculados à escola
LEFT JOIN (
    SELECT id_escola, ano_emissao AS ano FROM TB_Ideb
    UNION
    SELECT id_escola, ano FROM TB_Verbas
) AS anos
    ON anos.id_escola = escola.id

-- Dados do IDEB no ano correspondente
LEFT JOIN TB_Ideb AS ideb
    ON ideb.id_escola = escola.id
    AND ideb.ano_emissao = anos.ano

-- Soma PTRF agrupada por ano
LEFT JOIN (
    SELECT
        id_escola,
        ano,
        SUM(
            IFNULL(valor_primeira_parcela,0) +
            IFNULL(valor_segunda_parcela,0) +
            IFNULL(valor_terceira_parcela,0) +
            IFNULL(valor_vulnerabilidade,0) +
            IFNULL(valor_extraordinario,0) +
            IFNULL(valor_gremio,0)
        ) AS soma_ptrf
    FROM TB_Verbas
    GROUP BY id_escola, ano
) AS verba
    ON verba.id_escola = escola.id
    AND verba.ano = anos.ano

ORDER BY escola.nome, anos.ano DESC;