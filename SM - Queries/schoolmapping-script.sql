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
data_processamento DATE,
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
data_processamento DATE,
	CONSTRAINT fk_endereco_tb_escolas
		FOREIGN KEY (id_endereco) REFERENCES TB_Enderecos(id)
);

CREATE TABLE TB_Ideb (
id INT PRIMARY KEY AUTO_INCREMENT,
id_escola INT NOT NULL,
nota DECIMAL (3,1) NOT NULL,
ano_emissao YEAR NOT NULL,
data_processamento DATE,
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
data_processamento DATE,
	CONSTRAINT fk_escola_tb_verbas
		FOREIGN KEY (id_escola) REFERENCES TB_Escolas(id)
);

CREATE TABLE TB_Notificacao_Config (
  id INT PRIMARY KEY AUTO_INCREMENT,
  id_usuario INT,
  id_bot int default 1,
  id_canal int,
  tipo_alerta VARCHAR(50),
  ativo BOOLEAN DEFAULT true,
  ultimo_disparo DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE TB_Canal_Slack (
  id int PRIMARY KEY AUTO_INCREMENT,
  nome VARCHAR(40)
);

CREATE TABLE TB_Bot_Slack (
  id int PRIMARY KEY AUTO_INCREMENT,
  nome VARCHAR(40),
  token TEXT
);

ALTER TABLE TB_Notificacao_Config ADD FOREIGN KEY (id_canal) REFERENCES TB_Canal_Slack (id);

ALTER TABLE TB_Notificacao_Config ADD FOREIGN KEY (id_bot) REFERENCES TB_Bot_Slack (id);


INSERT INTO TB_Perfis (cargo) VALUES
('Comum'),
('Administrador');

INSERT INTO TB_Regioes (nome) VALUES
('Norte'),
('Leste'),
('Sul'),
('Centro'),
('Oeste');

SELECT * FROM TB_Escolas;

SELECT * FROM TB_Notificacao_config;

SELECT * FROM TB_Perfis;

INSERT INTO TB_Empresas (razao_social, cnpj, email, telefone) VALUES
('Tech School Solutions', '12345678000199', 'contato@techschool.com', '11987654321');

INSERT INTO TB_Usuarios (id_perfil, id_empresa, nome, email, senha) VALUES
(1, 1, 'Admin Sistema', 'admin@schoolmapping.com', 'senhaSegura123');

INSERT INTO TB_Canal_Slack (nome) VALUES
('#school_mapping_hub');

-- Inserindo o Bot do Slack
INSERT INTO TB_Bot_Slack (nome, token) VALUES
('SchoolMappingBot', 'xoxb');


INSERT INTO TB_Notificacao_Config 
(id_usuario, id_bot, id_canal, tipo_alerta, ativo, ultimo_disparo) 
values (1, 1, 1, 'NOVAS_ESCOLAS', true, '2023-11-28 10:00:00'), (1, 1, 1, 'NOVAS_VERBAS', true, '2023-11-28 10:00:00'), (1, 1, 1, 'NOVAS_NOTAS', false, '2023-11-28 10:00:00');

SELECT * FROM TB_Notificacao_Config;

UPDATE TB_Escolas set data_processamento = '2024-11-28'; 
