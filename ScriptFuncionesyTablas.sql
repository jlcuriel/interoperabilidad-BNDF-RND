USE [DATABASENAME]

/****** Object:  UserDefinedFunction [dbo].[Split]    Script Date: 25/01/2024 04:47:25 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Split] (
@WordBreak CHAR(1)
, @Phrase VARCHAR(8000)
)
RETURNS @Words TABLE (
WordID INT
, Word VARCHAR(8000)
)
AS
BEGIN


;    WITH Words (WordID, Start, Stop) AS
(
      SELECT 1, 1, CHARINDEX(@WordBreak, @Phrase)
      UNION ALL
      SELECT WordID + 1, Stop + 1, CHARINDEX(@WordBreak, @Phrase, Stop + 1)
        FROM Words
       WHERE Stop > 0
    )
    INSERT INTO @Words
    SELECT WordID
, SUBSTRING(@Phrase
                   , Start
                   , CASE 
                       WHEN Stop > 0 THEN Stop-Start 
                       ELSE 8000
                     END) AS Word
      FROM Words
    OPTION (MAXRECURSION 0)     

RETURN

END
GO

/****** Object:  UserDefinedFunction [dbo].[SearchString]    Script Date: 25/01/2024 04:47:25 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[SearchString]
(
              @Expresion                     VARCHAR(MAX)
,             @Lematizador  BIT
)
RETURNS VARCHAR(MAX)
AS 
BEGIN   

DECLARE
              @Terminos TABLE (
                            Grupo                               CHAR(10),
                            Termino                                          VARCHAR(MAX),
                            Equivalencia      VARCHAR(MAX)
              )

DECLARE
              @Frase               VARCHAR(1024)
,             @Palabras         VARCHAR(MAX)
,             @Normalized VARCHAR(MAX)

DECLARE
              @i         TINYINT
,             @j         TINYINT
              
-- First of all, nothing to do with nasty words
;
WITH Normal 
AS
(
SELECT WORD
  FROM dbo.Split(' ', @Expresion)
WHERE LEN(WORD)>0
   AND WORD NOT IN (SELECT NOISY_WORD FROM NOISY_WORD)
)
SELECT @Normalized = COALESCE(@Normalized + ' ', '') + WORD
  FROM Normal
  
SET @Expresion = @Normalized 

-- Separa frases
WHILE PATINDEX('%"%"%', @Expresion)>0
BEGIN
              SET @i = CHARINDEX('"', @Expresion, 1)
              SET @j = CHARINDEX('"', @Expresion, @i+1)
              SET @Frase = SUBSTRING(@Expresion,
                                              @i, 
                           @j - @i + 1        
                          )
              SET @Expresion = STUFF(@Expresion, @i, @j-@i+1, '')
              INSERT INTO @Terminos (Grupo, Termino) VALUES ('FRASE', REPLACE(@Frase, '"', ''))
END


-- Agrega palabras restantes
INSERT INTO @Terminos(Grupo, Termino)
SELECT 'PALABRA', WORD
FROM dbo.Split(' ', @Expresion)
WHERE LEN(WORD) > 0

-- Elimina noisywords
DELETE @Terminos
WHERE Termino IN (SELECT NOISY_WORD FROM NOISY_WORD)

-- Construye la expresión con sinónimos para búsquedas fulltext
;
WITH Palabras (Termino)
AS
(
    SELECT DISTINCT LTRIM(RTRIM(REPLACE(Termino, '+', ' ')))
      FROM @Terminos
)
SELECT @Palabras = COALESCE(@Palabras + ' AND ', '')
     + '( "' + Termino 
             + CASE 
                 WHEN @Lematizador = 1 THEN '" OR FORMSOF(INFLECTIONAL, "' + Termino + '" )'
                 ELSE '"'
               END 
     + COALESCE((SELECT ' OR "' + LTRIM(RTRIM(Equivalencia)) 
                                + CASE
                                    WHEN @Lematizador = 1 THEN '" OR FORMSOF(INFLECTIONAL, "' + LTRIM(RTRIM(Equivalencia)) + '")'
                                    ELSE '"'
                                  END
                  FROM   @Terminos AS Sinonimos
                  WHERE  LTRIM(RTRIM(REPLACE(Sinonimos.Termino, '.', ''))) = LTRIM(RTRIM(REPLACE(Palabras.Termino, '.', '')))
                  FOR XML PATH('')
                 )
               ,'')
     + ' )'
  FROM Palabras

RETURN @Palabras

END
GO
/****** Object:  UserDefinedFunction [dbo].[StringSoundexSQL]    Script Date: 25/01/2024 04:47:25 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[StringSoundexSQL] (
       @Expression   VARCHAR(1024)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
       DECLARE
             @Subquery     VARCHAR(MAX)

--     SET @Expression = dbo.StripCharacters(@Expression, '^A-Z ÁÉÍÓÚÜÑáéíóúúñ')
             
       SELECT @Subquery = COALESCE(@Subquery + ' ', '') + WORD
       FROM (SELECT SOUNDEX((LTRIM(RTRIM(WORD)))) AS WORD
               FROM dbo.Split(' ', @Expression) AS TBL
             WHERE LEN(WORD) > 2
              AND WORD NOT IN (SELECT NOISY_WORD FROM NOISY_WORD)         
              AND WORD <> '0000'
             ) AS X
       OPTION (MAXRECURSION 0)

       RETURN @Subquery
END
GO
/****** Object:  Table [dbo].[NOISY_WORD]    Script Date: 25/01/2024 04:47:25 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NOISY_WORD](
	[NOISY_WORD] [varchar](32) NOT NULL,
 CONSTRAINT [PK_NOISY_WORD] PRIMARY KEY CLUSTERED 
(
	[NOISY_WORD] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'algún')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'alguna')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'algunas')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'alguno')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'algunos')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'ambos')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'ante')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'antes')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'aquel ')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'aquellas')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'aquellos')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'aqui')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'arriba')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'atras')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'bajo')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'bastante')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'bien')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'cada')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'cierta')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'ciertas')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'cierto')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'ciertos')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'como')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'con')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'conseguimos')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'conseguir')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'consigo')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'consigue')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'consiguen')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'consigues')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'cual')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'cuando')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'dentro')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'desde')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'donde')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'dos')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'el')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'ellas')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'ellos')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'en')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'encima')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'entonces')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'entre')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'era')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'eramos')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'eran')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'eras')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'eres')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'es')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'esta')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'estaba')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'estado')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'estais')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'estamos')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'estan')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'estoy')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'fin')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'fue')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'fueron')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'fui')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'fuimos')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'gueno')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'ha')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'hace')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'haceis')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'hacemos')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'hacen')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'hacer')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'haces')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'hago')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'incluso')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'intenta')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'intentais')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'intentamos')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'intentan')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'intentar')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'intentas')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'intento')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'ir')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'la')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'largo')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'las')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'lo')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'los')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'mientras')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'mio')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'modo')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'muchos')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'muy')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'nos')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'nosotros')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'otro')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'para')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'pero')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'podeis')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'podemos')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'podria')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'podriais')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'podriamos')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'podrian')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'podrias')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'por')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'por qué')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'porque')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'primero ')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'puede')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'pueden')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'puedo')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'quien')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'sabe')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'sabeis')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'sabemos')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'saben')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'saber')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'sabes')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'ser')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'si')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'siendo')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'sin')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'sobre')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'sois')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'solamente')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'solo')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'somos')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'soy')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'su')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'sus')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'también')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'teneis')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'tenemos')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'tener')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'tengo')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'tiempo')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'tiene')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'tienen')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'todo')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'tras')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'tuyo')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'ultimo')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'un')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'una')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'unas')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'uno')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'unos')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'usa')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'usais')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'usamos')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'usan')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'usar')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'usas')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'va')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'vais')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'valor')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'vamos')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'van')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'vaya')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'verdad')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'verdadera ')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'verdadero')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'vosotras')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'vosotros')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'voy')
GO
INSERT [dbo].[NOISY_WORD] ([NOISY_WORD]) VALUES (N'yo')
GO
/****** Object:  StoredProcedure [dbo].[usp_consultaBNDF]    Script Date: 25/01/2024 04:47:25 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_consultaBNDF] (
@nombre varchar(50)
, @primer_apellido varchar(50)
, @segundo_apellido varchar(50)
, @sexo char(1) 
, @curp varchar(18)
, @alias varchar(128)
, @fecha_nacimiento date
, @fecha_ultima_vez_visto date
)
AS
BEGIN
DECLARE
  @NOMBRE_COMPLETO VARCHAR(128)
, @SEARCH_STRING VARCHAR(128)
, @SEARCH_STRING_SNDX VARCHAR(128)
, @SEARCH_STRING_SNDX_REV VARCHAR(128)
, @SEARCH_STRING_ALIAS VARCHAR(128)

   SET @NOMBRE_COMPLETO        = coalesce(trim(@nombre), '') + ' ' + coalesce(trim(@primer_apellido), '') + ' ' + coalesce(trim(@segundo_apellido), '')
   SET @SEARCH_STRING          = dbo.SearchString(@NOMBRE_COMPLETO, 0)
   SET @SEARCH_STRING_SNDX     = COALESCE(dbo.SearchString(dbo.StringSoundexSQL(@NOMBRE_COMPLETO), 0), 'XXX')
   SET @SEARCH_STRING_SNDX_REV = COALESCE(dbo.SearchString(dbo.StringSoundexSQL(REVERSE(@NOMBRE_COMPLETO)), 0), 'XXX')
   SET @SEARCH_STRING_ALIAS    = COALESCE(dbo.SearchString(COALESCE(@ALIAS, 'QWERTY'), 0), 'XXX')

   SELECT D.ID_REGISTRO, D.NOMBRE, D.PRIMER_APELLIDO, D.SEGUNDO_APELLIDO, D.SEXO, D.CURP, D.ALIASES, D.FECHA_NACIMIENTO, D.FECHA_DETENCION
     FROM RND.DETENIDO D
	      JOIN RND.REGISTRO R ON D.ID_REGISTRO = R.ID_REGISTRO
	      JOIN CONTAINSTABLE(RND.DETENIDO, NOMBRE_COMPLETO, @SEARCH_STRING) AS K ON D.ID_DETENIDO = K.[KEY]
	WHERE ( @sexo IS NULL OR ( @sexo IN ('H', 'M') AND D.SEXO = @sexo ) )
--	  AND ( @fecha_ultima_vez_visto IS NOT NULL AND D.FECHA_DETENCION >= @fecha_ultima_vez_visto )
--	  AND ( @fecha_nacimiento IS NOT NULL AND D.FECHA_NACIMIENTO BETWEEN DATEADD(YEAR, -3, @fecha_nacimiento) AND DATEADD(YEAR, 3, @fecha_nacimiento) )

   UNION

   SELECT D.ID_REGISTRO, D.NOMBRE, D.PRIMER_APELLIDO, D.SEGUNDO_APELLIDO, D.SEXO, D.CURP, D.ALIASES, D.FECHA_NACIMIENTO, D.FECHA_DETENCION
     FROM RND.DETENIDO D
	      JOIN RND.REGISTRO R ON D.ID_REGISTRO = R.ID_REGISTRO
	      JOIN CONTAINSTABLE(RND.DETENIDO, NOMBRE_COMPLETO_SOUNDEX, @SEARCH_STRING_SNDX) AS K ON D.ID_DETENIDO = K.[KEY]
	WHERE ( @sexo IN ('H', 'M') AND D.SEXO = @sexo )
	  AND ( @fecha_ultima_vez_visto IS NOT NULL AND D.FECHA_DETENCION >= @fecha_ultima_vez_visto )
	  AND ( @fecha_nacimiento IS NOT NULL AND D.FECHA_NACIMIENTO BETWEEN DATEADD(YEAR, -3, @fecha_nacimiento) AND DATEADD(YEAR, 3, @fecha_nacimiento) )

   UNION

   SELECT D.ID_REGISTRO, D.NOMBRE, D.PRIMER_APELLIDO, D.SEGUNDO_APELLIDO, D.SEXO, D.CURP, D.ALIASES, D.FECHA_NACIMIENTO, D.FECHA_DETENCION
     FROM RND.DETENIDO D
	      JOIN RND.REGISTRO R ON D.ID_REGISTRO = R.ID_REGISTRO
	      JOIN CONTAINSTABLE(RND.DETENIDO, NOMBRE_COMPLETO_SOUNDEX, @SEARCH_STRING_SNDX_REV) AS K ON D.ID_DETENIDO = K.[KEY]
	WHERE ( @sexo IN ('H', 'M') AND D.SEXO = @sexo )
	  AND ( @fecha_ultima_vez_visto IS NOT NULL AND D.FECHA_DETENCION >= @fecha_ultima_vez_visto )
	  AND ( @fecha_nacimiento IS NOT NULL AND D.FECHA_NACIMIENTO BETWEEN DATEADD(YEAR, -3, @fecha_nacimiento) AND DATEADD(YEAR, 3, @fecha_nacimiento) )

   UNION

   SELECT D.ID_REGISTRO, D.NOMBRE, D.PRIMER_APELLIDO, D.SEGUNDO_APELLIDO, D.SEXO, D.CURP, D.ALIASES, D.FECHA_NACIMIENTO, D.FECHA_DETENCION
     FROM RND.DETENIDO D
	      JOIN RND.REGISTRO R ON D.ID_REGISTRO = R.ID_REGISTRO
	WHERE ( @curp IS NOT NULL AND CURP = @curp )
	  AND ( @sexo IN ('H', 'M') AND D.SEXO = @sexo )
	  AND ( @fecha_ultima_vez_visto IS NOT NULL AND D.FECHA_DETENCION >= @fecha_ultima_vez_visto )
	  AND ( @fecha_nacimiento IS NOT NULL AND D.FECHA_NACIMIENTO BETWEEN DATEADD(YEAR, -3, @fecha_nacimiento) AND DATEADD(YEAR, 3, @fecha_nacimiento) )
 
   UNION

   SELECT D.ID_REGISTRO, D.NOMBRE, D.PRIMER_APELLIDO, D.SEGUNDO_APELLIDO, D.SEXO, D.CURP, D.ALIASES, D.FECHA_NACIMIENTO, D.FECHA_DETENCION
     FROM RND.DETENIDO D
	      JOIN RND.REGISTRO R ON D.ID_REGISTRO = R.ID_REGISTRO
	      JOIN CONTAINSTABLE(RND.DETENIDO, ALIASES, @SEARCH_STRING_ALIAS) AS K ON D.ID_DETENIDO = K.[KEY]
	WHERE ( @sexo IN ('H', 'M') AND D.SEXO = @sexo )
	  AND ( @fecha_ultima_vez_visto IS NOT NULL AND D.FECHA_DETENCION >= @fecha_ultima_vez_visto )
	  AND ( @fecha_nacimiento IS NOT NULL AND D.FECHA_NACIMIENTO BETWEEN DATEADD(YEAR, -3, @fecha_nacimiento) AND DATEADD(YEAR, 3, @fecha_nacimiento) )

END
GO
