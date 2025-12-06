CREATE DATABASE SchoolMapping;

USE SchoolMapping;

CREATE TABLE TB_Empresas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    razao_social VARCHAR(60) NOT NULL,
    cnpj CHAR(14) NOT NULL UNIQUE,
    email VARCHAR(80) NOT NULL,
    telefone CHAR(11) NOT NULL
);

CREATE TABLE TB_Perfis (
    id INT PRIMARY KEY AUTO_INCREMENT,
    cargo VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE TB_Usuarios (
    id INT PRIMARY KEY AUTO_INCREMENT,
    id_perfil INT NOT NULL DEFAULT 1,
    id_empresa INT,
    nome VARCHAR(60) NOT NULL,
    email VARCHAR(80) NOT NULL UNIQUE,
    senha VARCHAR(100) NOT NULL,
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_perfil_tb_usuarios FOREIGN KEY (id_perfil) REFERENCES TB_Perfis(id),
    CONSTRAINT fk_empresa_tb_usuarios FOREIGN KEY (id_empresa) REFERENCES TB_Empresas(id)
);


CREATE TABLE TB_Tokens (
    id INT PRIMARY KEY AUTO_INCREMENT,
    id_empresa INT UNIQUE NOT NULL,
    token VARCHAR(45) NOT NULL UNIQUE,
    ativo BOOLEAN NOT NULL,
    CONSTRAINT fk_token_tb_empresas FOREIGN KEY (id_empresa) REFERENCES TB_Empresas(id)
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


CREATE TABLE TB_Regioes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(10) NOT NULL UNIQUE
);

CREATE TABLE TB_Enderecos (
    id INT AUTO_INCREMENT,
    id_regiao INT NOT NULL,
    cep CHAR(9) NOT NULL,
    bairro VARCHAR(45) NOT NULL,
    logradouro VARCHAR(45) NOT NULL,
    numero VARCHAR(10) NOT NULL,
    CONSTRAINT fk_regiao_tb_enderecos FOREIGN KEY (id_regiao) REFERENCES TB_Regioes(id),
    PRIMARY KEY (id, id_regiao)
);

CREATE TABLE TB_Escolas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    id_endereco INT UNIQUE,
    nome VARCHAR(100) NOT NULL,
    codigo_inep CHAR(8) NOT NULL UNIQUE,
    subprefeitura VARCHAR(60),
    data_processamento DATE,
    CONSTRAINT fk_endereco_tb_escolas FOREIGN KEY (id_endereco) REFERENCES TB_Enderecos(id)
);

CREATE TABLE TB_Ideb (
    id INT PRIMARY KEY AUTO_INCREMENT,
    id_escola INT NOT NULL,
    nota DECIMAL(3,1) NOT NULL,
    ano_emissao YEAR NOT NULL,
    data_processamento DATE,
    CONSTRAINT fk_escola_tb_ideb FOREIGN KEY (id_escola) REFERENCES TB_Escolas(id)
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
    data_processamento DATE,
    CONSTRAINT fk_escola_tb_verbas FOREIGN KEY (id_escola) REFERENCES TB_Escolas(id)
);


CREATE TABLE TB_Status_Chamados (
    id INT PRIMARY KEY AUTO_INCREMENT,
    tipo VARCHAR(45) NOT NULL UNIQUE
);

CREATE TABLE TB_Chamados (
    id INT PRIMARY KEY AUTO_INCREMENT,
    id_usuario INT NOT NULL,
    id_status INT,
    assunto VARCHAR(45) NOT NULL,
    descricao TEXT NOT NULL,
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP, -- já registra a data automaticamente
    CONSTRAINT fk_usuario_tb_chamados FOREIGN KEY (id_usuario) REFERENCES TB_Usuarios(id),
    CONSTRAINT fk_status_tb_chamados FOREIGN KEY (id_status) REFERENCES TB_Status_Chamados(id)
);

INSERT INTO TB_Status_Chamados (id, tipo) VALUES
(1, 'Aberto'),
(2, 'Finalizado'),
(3, 'Descontinuado');

CREATE TABLE TB_Canal_Slack (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(40) NOT NULL
);

CREATE TABLE TB_Bot_Slack (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(40) NOT NULL,
    token TEXT NOT NULL
);

CREATE TABLE TB_Notificacao_Config (
    id INT PRIMARY KEY AUTO_INCREMENT,
    id_usuario INT,
    id_bot INT DEFAULT 1,
    id_canal INT,
    tipo_alerta VARCHAR(50),
    ativo BOOLEAN DEFAULT TRUE,
    ultimo_disparo DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notif_usuario FOREIGN KEY (id_usuario) REFERENCES TB_Usuarios(id),
    CONSTRAINT fk_notif_bot FOREIGN KEY (id_bot) REFERENCES TB_Bot_Slack(id),
    CONSTRAINT fk_notif_canal FOREIGN KEY (id_canal) REFERENCES TB_Canal_Slack(id)
);


CREATE VIEW vw_notas AS
SELECT 
    AVG(ideb.nota) AS media_nota,
    ideb.ano_emissao AS ano_nota,
    regiao.nome AS regiao
FROM TB_Ideb ideb
JOIN TB_Escolas escola ON ideb.id_escola = escola.id
JOIN TB_Enderecos endereco ON escola.id_endereco = endereco.id
JOIN TB_Regioes regiao ON endereco.id_regiao = regiao.id
GROUP BY ideb.ano_emissao, regiao.nome
ORDER BY ano_nota DESC;

CREATE VIEW vw_verbas AS
SELECT
    AVG(
        valor_primeira_parcela +
        IFNULL(valor_segunda_parcela,0) +
        IFNULL(valor_terceira_parcela,0) +
        IFNULL(valor_vulnerabilidade,0) +
        IFNULL(valor_extraordinario,0) +
        IFNULL(valor_gremio,0)
    ) AS media_ptrf,
    SUM(
        valor_primeira_parcela +
        IFNULL(valor_segunda_parcela,0) +
        IFNULL(valor_terceira_parcela,0) +
        IFNULL(valor_vulnerabilidade,0) +
        IFNULL(valor_extraordinario,0) +
        IFNULL(valor_gremio,0)
    ) AS soma_ptrf,
    verba.ano AS ano_verba,
    regiao.nome AS regiao
FROM TB_Verbas verba
JOIN TB_Escolas escola ON verba.id_escola = escola.id
JOIN TB_Enderecos endereco ON escola.id_endereco = endereco.id
JOIN TB_Regioes regiao ON endereco.id_regiao = regiao.id
GROUP BY verba.ano, regiao.nome
ORDER BY ano_verba DESC;

CREATE VIEW vw_escolas AS
SELECT
    escola.id AS id_escola,
    escola.nome AS nome_escola,
    escola.codigo_inep AS codigo_inep,
    CONCAT(endereco.logradouro, ', ', endereco.numero, ' - ', endereco.bairro) AS endereco,
    endereco.cep AS cep,
    anos.ano AS ano,
    COALESCE(ideb.nota, 'N/A') AS nota_ideb,
    COALESCE(ideb.ano_emissao, 'N/A') AS ano_ideb,
    COALESCE(verba.soma_ptrf, 'N/A') AS soma_ptrf,
    COALESCE(verba.ano, 'N/A') AS ano_ptrf
FROM TB_Escolas escola
LEFT JOIN TB_Enderecos endereco ON endereco.id = escola.id_endereco
LEFT JOIN (
    SELECT id_escola, ano_emissao AS ano FROM TB_Ideb
    UNION
    SELECT id_escola, ano FROM TB_Verbas
) anos ON anos.id_escola = escola.id
LEFT JOIN TB_Ideb ideb ON ideb.id_escola = escola.id AND ideb.ano_emissao = anos.ano
LEFT JOIN (
    SELECT id_escola, ano,
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
) verba ON verba.id_escola = escola.id AND verba.ano = anos.ano
ORDER BY escola.nome, anos.ano DESC;


DELIMITER $$

CREATE PROCEDURE SP_CadastrarUsuario(
    IN p_nome VARCHAR(60),
    IN p_email VARCHAR(80),
    IN p_senha VARCHAR(100),
    IN p_id_perfil INT
)
BEGIN
    INSERT INTO TB_Usuarios (nome, email, senha, id_perfil)
    VALUES (p_nome, p_email, p_senha, p_id_perfil);

    SELECT LAST_INSERT_ID() AS id_usuario;
END $$

CREATE PROCEDURE SP_LogarUsuario(
    IN p_usuario VARCHAR(60),
    IN p_senha VARCHAR(100)
)
BEGIN
    SELECT id AS id_usuario, nome, email
    FROM TB_Usuarios
    WHERE nome = p_usuario AND senha = p_senha
    LIMIT 1;
END $$

CREATE PROCEDURE SP_AtualizarEmail(
    IN p_id INT,
    IN p_email VARCHAR(80)
)
BEGIN
    UPDATE TB_Usuarios SET email = p_email WHERE id = p_id;
    SELECT ROW_COUNT() AS linhas_afetadas;
END $$

CREATE PROCEDURE SP_AtualizarSenha(
    IN p_id INT,
    IN p_senha VARCHAR(100)
)
BEGIN
    UPDATE TB_Usuarios SET senha = p_senha WHERE id = p_id;
    SELECT ROW_COUNT() AS linhas_afetadas;
END $$

CREATE PROCEDURE SP_DeletarUsuario(IN p_id INT)
BEGIN
    DELETE FROM TB_Usuarios WHERE id = p_id;
    SELECT ROW_COUNT() AS linhas_afetadas;
END $$

CREATE PROCEDURE SP_CadastrarEmpresa(
    IN p_razao_social VARCHAR(60),
    IN p_cnpj CHAR(14),
    IN p_email VARCHAR(80),
    IN p_telefone CHAR(11)
)
BEGIN
    INSERT INTO TB_Empresas (razao_social, cnpj, email, telefone)
    VALUES (p_razao_social, p_cnpj, p_email, p_telefone);

    SELECT LAST_INSERT_ID() AS id_empresa;
END $$

CREATE PROCEDURE SP_CarregarEmpresas()
BEGIN
    SELECT 
        e.id,
        e.razao_social,
        e.cnpj,
        e.email,
        e.telefone,
        t.token
    FROM TB_Empresas e
    LEFT JOIN TB_Tokens t ON e.id = t.id_empresa;
END $$


CREATE PROCEDURE SP_GerarToken(
    IN p_id_empresa INT,
    IN p_token VARCHAR(45)
)
BEGIN
    INSERT INTO TB_Tokens (id_empresa, token, ativo)
    VALUES (p_id_empresa, p_token, TRUE)
    ON DUPLICATE KEY UPDATE 
        token = VALUES(token),
        ativo = TRUE;

    SELECT ROW_COUNT() AS linhas_afetadas;
END;

CREATE PROCEDURE SP_AtualizarEmpresa(
    IN p_id INT,
    IN p_razao_social VARCHAR(60),
    IN p_cnpj CHAR(14),
    IN p_email VARCHAR(80),
    IN p_telefone CHAR(11)
)
BEGIN
    UPDATE TB_Empresas
    SET razao_social = p_razao_social,
        cnpj = p_cnpj,
        email = p_email,
        telefone = p_telefone
    WHERE id = p_id;

    SELECT ROW_COUNT() AS linhas_afetadas;
END $$

CREATE PROCEDURE SP_DeletarEmpresa(IN p_id INT)
BEGIN
    DELETE FROM TB_Usuarios WHERE id_empresa = p_id;

    DELETE FROM TB_Tokens WHERE id_empresa = p_id;

    DELETE FROM TB_Empresas WHERE id = p_id;

    SELECT ROW_COUNT() AS linhas_afetadas;
END $$

CREATE PROCEDURE SP_CarregarPerfil(IN p_id INT)
BEGIN
    SELECT 
        u.id_perfil,
        p.cargo AS nome_perfil,
        e.razao_social
    FROM TB_Usuarios u
    JOIN TB_Perfis p ON u.id_perfil = p.id
    LEFT JOIN TB_Empresas e ON u.id_empresa = e.id
    WHERE u.id = p_id;
END $$

CREATE PROCEDURE SP_VincularUsuario(
    IN p_idUsuario INT,
    IN p_token VARCHAR(45)
)
BEGIN
    UPDATE TB_Usuarios
    SET id_empresa = (
        SELECT id_empresa FROM TB_Tokens
        WHERE token = p_token AND ativo = TRUE LIMIT 1
    )
    WHERE id = p_idUsuario;

    SELECT ROW_COUNT() AS linhas_afetadas;
END $$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE SP_EnviarChamado(
    IN p_idUsuario INT,
    IN p_assunto VARCHAR(45),
    IN p_descricao TEXT
)
BEGIN
    INSERT INTO TB_Chamados (id_usuario, id_status, assunto, descricao)
    VALUES (p_idUsuario, 1, p_assunto, p_descricao); -- 1 = Aberto

    SELECT LAST_INSERT_ID() AS id_chamado;
END $$

CREATE PROCEDURE SP_CarregarChamados(
    IN p_idUsuario INT,
    IN p_perfil INT
)
BEGIN
    IF p_perfil = 1 THEN
        SELECT 
            c.id AS id_chamado,
            u.nome,
            u.email,
            p.cargo AS perfil,
            e.razao_social,
            c.assunto,
            c.descricao,
            s.tipo AS status,
            DATE_FORMAT(c.data_cadastro, '%d/%m/%Y') AS data_chamado
        FROM TB_Chamados c
        JOIN TB_Usuarios u ON c.id_usuario = u.id
        JOIN TB_Perfis p ON u.id_perfil = p.id
        LEFT JOIN TB_Empresas e ON u.id_empresa = e.id
        LEFT JOIN TB_Status_Chamados s ON c.id_status = s.id
        WHERE u.id = p_idUsuario
          AND c.id_status <> 3; -- 3 = Descontinuado
    ELSE
        SELECT 
            c.id AS id_chamado,
            u.nome,
            u.email,
            p.cargo AS perfil,
            e.razao_social,
            c.assunto,
            c.descricao,
            s.tipo AS status,
            DATE_FORMAT(c.data_cadastro, '%d/%m/%Y') AS data_chamado
        FROM TB_Chamados c
        JOIN TB_Usuarios u ON c.id_usuario = u.id
        JOIN TB_Perfis p ON u.id_perfil = p.id
        LEFT JOIN TB_Empresas e ON u.id_empresa = e.id
        LEFT JOIN TB_Status_Chamados s ON c.id_status = s.id;
    END IF;
END $$

CREATE PROCEDURE SP_FinalizarChamado(
    IN p_idChamado INT
)
BEGIN
    UPDATE TB_Chamados
    SET id_status = 2 -- Finalizado
    WHERE id = p_idChamado AND id_status = 1; -- Aberto

    SELECT ROW_COUNT() AS linhas_afetadas;
END $$

CREATE PROCEDURE SP_DeletarChamado(
    IN p_idChamado INT
)
BEGIN
    UPDATE TB_Chamados
    SET id_status = 3 
    WHERE id = p_idChamado AND id_status = 1; 

    SELECT ROW_COUNT() AS linhas_afetadas;
END $$

DELIMITER ;

INSERT INTO TB_Perfis (cargo) VALUES ('Comum'), ('Administrador');

INSERT INTO TB_Regioes (nome) VALUES
('Norte'), ('Leste'), ('Sul'), ('Centro'), ('Oeste');

INSERT INTO TB_Empresas (razao_social, cnpj, email, telefone) VALUES
('Tech School Solutions', '12345678000199', 'contato@techschool.com', '11987654321');

INSERT INTO TB_Usuarios (id_perfil, id_empresa, nome, email, senha)
VALUES (2, 1, 'Admin Sistema', 'admin@schoolmapping.com', 'senhaSegura123');

INSERT INTO TB_Canal_Slack (nome)
VALUES ('#school_mapping_hub');

INSERT INTO TB_Bot_Slack (nome, token)VALUES ('SchoolMappingBot', 'xoxb');

INSERT INTO TB_Tokens (id_empresa, token, ativo) VALUES (1, 'TESTE123ABC', 1);