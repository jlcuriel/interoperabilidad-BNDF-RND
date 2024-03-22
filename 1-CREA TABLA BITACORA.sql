-- RND_bitacoras.dbo.BIT_FGR_CONSULTAS

-- Drop table

-- DROP TABLE RND_bitacoras.dbo.BIT_FGR_CONSULTAS;

CREATE TABLE BIT_FGR_CONSULTAS
( ID_FGR_CONSULTA       INT IDENTITY(1,1) NOT NULL
, NUMERO_EXPEDIENTE     varchar(30) NOT NULL
, CUENTA_USUARIO        varchar(20) NOT NULL
, NOMBRE_USUARIO        varchar(120) NOT NULL
, PM_USUARIO            varchar(30) NOT NULL
, VALOR_BUSQUEDA        varchar(1000) NOT NULL
, NUM_REG_CONSULTADOS   numeric(5) DEFAULT 0 NOT NULL
, FECHA_PROCESO         datetime DEFAULT getdate() NULL,
	CONSTRAINT PKID_FGR_CONSULTA PRIMARY KEY (ID_FGR_CONSULTA)
);

-- Extended properties

EXEC RND_bitacoras.sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Clave única de la tabla de bitacora', @level0type=N'Schema', @level0name=N'dbo', @level1type=N'Table', @level1name=N'BIT_FGR_CONSULTAS', @level2type=N'Column', @level2name=N'ID_FGR_CONSULTA';
EXEC RND_bitacoras.sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Número de espediente que esta originando la busqueda', @level0type=N'Schema', @level0name=N'dbo', @level1type=N'Table', @level1name=N'BIT_FGR_CONSULTAS', @level2type=N'Column', @level2name=N'NUMERO_EXPEDIENTE';
EXEC RND_bitacoras.sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Usuario que esta originando la busqueda', @level0type=N'Schema', @level0name=N'dbo', @level1type=N'Table', @level1name=N'BIT_FGR_CONSULTAS', @level2type=N'Column', @level2name=N'CUENTA_USUARIO';
EXEC RND_bitacoras.sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Nombre completo de la persona que esta realizando la busqueda', @level0type=N'Schema', @level0name=N'dbo', @level1type=N'Table', @level1name=N'BIT_FGR_CONSULTAS', @level2type=N'Column', @level2name=N'NOMBRE_USUARIO';
EXEC RND_bitacoras.sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Clave de usuario de Plataforma México', @level0type=N'Schema', @level0name=N'dbo', @level1type=N'Table', @level1name=N'BIT_FGR_CONSULTAS', @level2type=N'Column', @level2name=N'PM_USUARIO';
EXEC RND_bitacoras.sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Valores con los que se realiza la busqueda', @level0type=N'Schema', @level0name=N'dbo', @level1type=N'Table', @level1name=N'BIT_FGR_CONSULTAS', @level2type=N'Column', @level2name=N'VALOR_BUSQUEDA';
EXEC RND_bitacoras.sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Número de registros debueltos en la busqueda', @level0type=N'Schema', @level0name=N'dbo', @level1type=N'Table', @level1name=N'BIT_FGR_CONSULTAS', @level2type=N'Column', @level2name=N'NUM_REG_CONSULTADOS';
EXEC RND_bitacoras.sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha en que se realiza la busqueda', @level0type=N'Schema', @level0name=N'dbo', @level1type=N'Table', @level1name=N'BIT_FGR_CONSULTAS', @level2type=N'Column', @level2name=N'FECHA_PROCESO';

