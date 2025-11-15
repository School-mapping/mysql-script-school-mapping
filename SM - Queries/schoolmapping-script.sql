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
cargo VARCHAR(20)
);

CREATE TABLE TB_Usuarios (
id INT PRIMARY KEY AUTO_INCREMENT,
id_perfil INT NOT NULL,
id_empresa INT,
nome VARCHAR(60) NOT NULL,
email VARCHAR(45) NOT NULL,
senha VARCHAR(45) NOT NULL,
tipo VARCHAR(15) NOT NULL DEFAULT "Padrão",
data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT fk_perfil_tb_usuarios
		FOREIGN KEY (id_perfil) REFERENCES TB_Perfis(id)
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
nome VARCHAR(10) NOT NULL
);

CREATE TABLE TB_Enderecos (
id INT,
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
id_endereco INT NOT NULL,
nome VARCHAR(60) NOT NULL,
codigo_inep CHAR(8) NOT NULL,
subprefeitura VARCHAR(60) NOT NULL,
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
('Oeste');
