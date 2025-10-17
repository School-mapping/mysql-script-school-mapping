CREATE DATABASE SchoolMapping;

USE SchoolMapping;

CREATE TABLE TB_Usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    senha VARCHAR(255) NOT NULL,
    tipo VARCHAR(20) NOT NULL DEFAULT 'Padrão',
    criado_em DATE NOT NULL
);

CREATE TABLE TB_Importacao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    arquivo VARCHAR(255) NOT NULL,
    data DATE NOT NULL,
    sucesso BOOLEAN NOT NULL,
    log VARCHAR(1000),
    FOREIGN KEY (usuario_id) REFERENCES TB_Usuarios(id)
);

CREATE TABLE TB_Escolas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    codigo_inep VARCHAR(8) NOT NULL UNIQUE,
    ideb DECIMAL(3,2),
    municipio_nome VARCHAR(100) DEFAULT 'São Paulo'
);

CREATE TABLE TB_Enderecos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    escola_id INT NOT NULL,
    logradouro VARCHAR(255),
    numero VARCHAR(10),
    bairro VARCHAR(100),
    cep CHAR(9),
    zona VARCHAR(10),
    FOREIGN KEY (escola_id) REFERENCES TB_Escolas(id)
);

CREATE TABLE TB_Indicadores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    escola_id INT NOT NULL,
    ano INT NOT NULL,
    ciclo VARCHAR(10),
    serie INT,
    ideb DECIMAL(4,2),
    fluxo DECIMAL(4,2),
    aprendizado DECIMAL(4,2),
    nota_lp DECIMAL(6,2),
    nota_mt DECIMAL(6,2),
    lp_adequado DECIMAL(4,2),
    mt_adequado DECIMAL(4,2),
    lp_insuficiente DECIMAL(4,2),
    mt_insuficiente DECIMAL(4,2),
    lp_basico DECIMAL(4,2),
    mt_basico DECIMAL(4,2),
    lp_proficiente DECIMAL(4,2),
    mt_proficiente DECIMAL(4,2),
    lp_avancado DECIMAL(4,2),
    mt_avancado DECIMAL(4,2),
    matriculas INT,
    aprovados DECIMAL(5,2),
    reprovados DECIMAL(5,2),
    abandonos DECIMAL(5,2),
    FOREIGN KEY (escola_id) REFERENCES TB_Escolas(id)
);

CREATE TABLE TB_DistorcaoIdadeSerie (
    id INT AUTO_INCREMENT PRIMARY KEY,
    escola_id INT NOT NULL,
    ano INT NOT NULL,
    ef_1ano DECIMAL(5,2),
    ef_2ano DECIMAL(5,2),
    ef_3ano DECIMAL(5,2),
    ef_4ano DECIMAL(5,2),
    ef_5ano DECIMAL(5,2),
    ef_6ano DECIMAL(5,2),
    ef_7ano DECIMAL(5,2),
    ef_8ano DECIMAL(5,2),
    ef_9ano DECIMAL(5,2),
    ef_total_ai DECIMAL(5,2),
    ef_total_af DECIMAL(5,2),
    ef_total DECIMAL(5,2),
    em_1ano DECIMAL(5,2),
    em_2ano DECIMAL(5,2),
    em_3ano DECIMAL(5,2),
    em_4ano DECIMAL(5,2),
    em_total DECIMAL(5,2),
    FOREIGN KEY (escola_id) REFERENCES TB_Escolas(id)
);

CREATE TABLE TB_Gastos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    escola_id INT NOT NULL,
    ano INT NOT NULL,
    repasse VARCHAR(20),
    parcela VARCHAR(20),
    valor_vulnerabilidade DECIMAL(12,2),
    valor_extraordinario DECIMAL(12,2),
    valor_gremio DECIMAL(12,2),
    portaria_sme VARCHAR(20),
    FOREIGN KEY (escola_id) REFERENCES TB_Escolas(id)
);

CREATE TABLE TB_Logs (
id INT AUTO_INCREMENT PRIMARY KEY,
dataLog DATETIME,
nivel VARCHAR (10),
descricao VARCHAR(250),
origem VARCHAR(100)
);

