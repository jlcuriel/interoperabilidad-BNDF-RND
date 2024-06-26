USE [RNDetenciones]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_limpiaCaracteres]    Script Date: 03/04/2024 04:18:49 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[fn_limpiaCaracteres]( @Cadena VARCHAR(MAX) )
RETURNS VARCHAR(MAX)
AS 
BEGIN
-- ============================================================
-- Author: JLCR
-- Create date: 19 Enero 2024
-- Description: limpia caracteres especiales, Tabulador, salto de línea, Retorno de carro
-- Retorno: Cadena limpia de caracteres espaciales y espacios al inicio y final de la misma
-- ============================================================
 --Reemplazamos las vocales acentuadas y caracteres especiales
 -- áéíóúàèìòùãõâêîôûäëïöüñÑçÇ ÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜ
    RETURN
    REPLACE(REPLACE( /*vocales ÃÕ*/
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( /*vocales ÄËÏÖÜ*/
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( /*vocales ÂÊÎÔÛ*/
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( /*vocales ÀÈÌÒÙ*/
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( /*vocales ÁÉÍÓÚ*/
    REPLACE(REPLACE( /*vocales çÇ*/
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( /*vocales äëïöü*/
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( /*vocales âêîôû*/
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( /*vocales àèìòù*/
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( /*vocales áéíóú*/
    REPLACE(REPLACE(REPLACE( /*Tabulador, salto de línea, Retorno de carro*/
        ltrim(rtrim(@Cadena)), char(9), ''), char(10), ''), char(13), '')
            ,'á','a'),'é','e'),'í','i'),'ó','o'),'ú','u')
            ,'à','a'),'è','e'),'ì','i'),'ò','o'),'ù','u')
            ,'â','a'),'ê','e'),'î','i'),'ô','o'),'û','u')
            ,'ä','a'),'ë','e'),'ï','i'),'ö','o'),'ü','u')
            ,'ç','c'),'Ç','C')
            ,'Á','A'),'É','E'),'Í','I'),'Ó','O'),'Ú','U')
            ,'À','A'),'È','E'),'Ì','I'),'Ò','O'),'Ù','U')
            ,'Â','A'),'Ê','E'),'Î','I'),'Ô','O'),'Û','U')
            ,'Ä','A'),'Ë','E'),'Ï','I'),'Ö','O'),'Ü','U')
            ,'Ã','A'),'Õ','O')
END