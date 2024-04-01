USE [RNDetenciones]
GO
/****** Object:  StoredProcedure [dbo].[SP_RND_fgr_busqueda_principal]    Script Date: 22/03/2024 11:49:31 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      JLCR  
-- Create date: 28 Enero 2024
-- Proyecto: interoperabilidad BNDF-RND
-- Description:	Consulta informacion HPD y FA
-- =============================================

alter PROCEDURE [dbo].[SP_RND_fgr_busqueda_principal]
( @Nun_expdiente      varchar(70) = ''
, @Cta_usuario        varchar(70) = ''
, @Nombre_usuario     varchar(70) = ''
, @Nombre             varchar(70) = ''
, @paterno            varchar(70) = ''
, @materno            varchar(50) = ''
, @curp               varchar(30) = ''
, @alias              varchar(13) = ''
, @idedo              int = 0
, @idmpio             int = 0
, @fechaultima        char(10) = ''
, @sexo               varchar(1) = ''
, @fecha_nacimiento   char(10) = ''
, @edad_minima        int = 0
, @edad_maxima        int = 0
, @pm_usuario         varchar(30) = '')
AS
BEGIN

   BEGIN TRY
    SET NOCOUNT ON

    DECLARE @sSQL             varchar(7000)
    DECLARE @sSQLFA           varchar(7000)
    DECLARE @sSQLWhere        varchar(7000)
    DECLARE @vcnombrecompleto varchar(7000)
    DECLARE @cvsexo           varchar(1)
    DECLARE @vnreg            int = 0
    DECLARE @totreg           int = 0


    SET @sSQLWhere = ''
    SET @sSQL=''

    IF OBJECT_ID(N'tempdb.dbo.##reghpd', N'U') IS NOT NULL  
       DROP TABLE ##reghpd;

    IF OBJECT_ID(N'tempdb.dbo.##regfa', N'U') IS NOT NULL  
       DROP TABLE ##regfa;

    IF OBJECT_ID(N'tempdb.dbo.##numreghpd', N'U') IS NOT NULL  
       DROP TABLE ##numreghpd;

    IF OBJECT_ID(N'tempdb.dbo.##numregfa', N'U') IS NOT NULL  
       DROP TABLE ##numregfa;

    SET    @sSQL = 'select dt.folio_detenido
            , isnull(ddc.nombre_detenido, dt.nombre) nombre
            , isnull(ddc.apellido_paterno, dt.apellido_paterno) apellido_paterno
            , isnull(ddc.apellido_materno, dt.apellido_materno) apellido_materno
            , ddc.curp
            , CASE WHEN ddc.id_pais IS NULL THEN '' '' ELSE p.nombre_pais END pais
            , CASE WHEN ddc.id_estado IS NULL THEN '' '' WHEN ddc.id_estado = 0 THEN '' '' ELSE ce.nombre END AS estado
            , CASE WHEN ddc.id_nacionalidad IS NULL THEN '' '' ELSE n.nombre_nacionalidad END AS nacionalidad
            , isnull(d.lugar_detencion,'''') lugar_detencion
            , isnull(ce.nombre,'''') as entidad
            , isnull(cm.nombre,'''') as municipio
            , isnull(cl.nombre,'''') as localidad
            , CASE WHEN d.id_colonia = 0 THEN '''' ELSE  (SELECT distinct(nombre) FROM GeoDirecciones.DBO.COLONIA WHERE IDCOLONIA=d.id_colonia) END as colonia
            , CASE WHEN d.id_calle = 0 THEN '''' ELSE (SELECT distinct(nombre) FROM GeoDirecciones.DBO.VIALIDAD WHERE CALLEID= d.id_calle) END as calle
            , CASE WHEN d.id_entrecalle = 0 THEN '''' ELSE (SELECT distinct(nombre) FROM GeoDirecciones.DBO.VIALIDAD WHERE CALLEID=d.id_entrecalle)END as entre_calle
            , CASE WHEN d.id_ycalle = 0 THEN '''' ELSE (SELECT distinct(nombre) FROM GeoDirecciones.DBO.VIALIDAD WHERE CALLEID=d.id_ycalle) END AS y_calle
            , isnull(d.numero_interio,'''') numero_interior
            , isnull(d.numero_exterior,'''') numero_exterior
            , isnull(d.codigo_postal,'''') codigo_postal
            , isnull(d.referencias,'''') referencias
           
		    , CONVERT(DATE,d.fecha_detencion) fecha_detencion
            , isnull(CONVERT(DATE,ddc.fecha_nacimiento), CONVERT(DATE,dt.fecha_nacimiento)) fecha_nacimiento
           -- , convert(nvarchar, datepart(hour,d.fecha_detencion)) + '':'' + convert(nvarchar,datepart(minute,d.fecha_detencion)) hora_detencion
            , isnull(substring(convert(nvarchar, d.fecha_detencion,108), 1, 5),'''') hora_detencion
            , DATEDIFF(YEAR, isnull(ddc.fecha_nacimiento, dt.fecha_nacimiento), GETDATE()) as edad
            , CASE WHEN STUFF((SELECT '','' + ci.institucion FROM oficiales o INNER JOIN cat_instituciones ci ON ci.id_institucion=o.id_institucion WHERE o.id_detencion=d.id_detencion FOR XML PATH('''')), 1, 1, '''') IS NULL THEN ''''
			ELSE STUFF((SELECT '','' + ci.institucion FROM oficiales o INNER JOIN cat_instituciones ci ON ci.id_institucion=o.id_institucion WHERE o.id_detencion=d.id_detencion FOR XML PATH('''')), 1, 1, '''') END  + '','' +
			CASE WHEN STUFF((SELECT '','' + institucion FROM oficiales_PSP opsp WHERE opsp.id_detencion=d.id_detencion FOR XML PATH('''')), 1, 1, '''') IS NULL THEN ''''
			ELSE STUFF((SELECT '','' + institucion FROM oficiales_PSP opsp WHERE opsp.id_detencion=d.id_detencion FOR XML PATH('''')), 1, 1, '''') END AS autoridad_detiene,
			isnull(pd.adscripcion_recibe,'''') as autoridad_recibe
			, isnull(pd.fecha_recibe,'''') fecha_recibe
			, isnull(ddc.carpeta_investigacion,'''') carpeta_investigacion
            , CONVERT(DATE,GETDATE()) fecha_consulta
			, dt.alias + '','' + DDC.alias + '','' + CASE WHEN STUFF((SELECT '','' + alias FROM alias_detenido ad WHERE ad.id_detenido_complemento=ddc.id_detenido_complemento FOR XML PATH('''')), 1, 1, '''') IS NULL THEN '''' 
			ELSE STUFF((SELECT '','' + alias FROM alias_detenido ad WHERE ad.id_detenido_complemento=ddc.id_detenido_complemento FOR XML PATH('''')), 1, 1, '''') END as alias
            into ##reghpd
            FROM detenciones d
            INNER JOIN cat_tipos_detenciones ctd
                ON ctd.id_tipo_detencion = D.id_tipo_detencion
                and d.es_activo = 1
            INNER JOIN detenidos dt
                ON D.id_detencion = dt.id_detencion
                AND dt.es_borrado = 0
            LEFT JOIN puesta_disposiciones pd
                ON dt.id_detenido = pd.id_detenido
                AND pd.es_borrado = 0
            LEFT JOIN puesta_disposiciones_oficiales_psp pdof
                ON pd.id_puesta_disposicion = pdof.Id_Puesta_Dsposicion 
            LEFT JOIN oficiales_psp ofp
                ON ofp.id_detencion = d.id_detencion
                AND ofp.usuario_participo = 1
            LEFT JOIN cat_fiscalias cf
                ON cf.id_fiscalia = pd.id_fiscalia
            LEFT JOIN detenidos_datoscomplementarios ddc
                ON pd.id_puesta_disposicion = ddc.id_puesta_disposicion
            LEFT JOIN traslados tr
                ON ddc.id_detenido_complemento = tr.id_detenido_complemento
                AND tr.es_activo = 1
            LEFT JOIN cat_fueros cfs 
                ON cfs.id_fuero = D.id_fuero
            LEFT JOIN cat_tipos_traslados ctr
                ON ctr.id_tipo_traslado = tr.id_tipo_traslado
            LEFT JOIN alias_detenido dta
                ON dta.id_detenido_complemento = ddc.id_detenido_complemento
            LEFT JOIN geodirecciones..entidad CE 
                ON CE.identidad = D.id_entidad
            LEFT JOIN geodirecciones..municipio CM 
                ON CM.identidad = D.id_entidad 
                AND CM.idmpio = D.id_municipio
            LEFT JOIN GeoDirecciones.DBO.LOCALIDAD cl 
                ON cl.IDLOC= d.id_localidad 
                AND cl.IDMPIO= cm.IDMPIO 
                AND cl.IDENTIDAD= ce.IDENTIDAD
            LEFT JOIN cat_paises p 
                ON p.id_pais=ddc.id_pais
            LEFT JOIN cat_nacionalidades n 
                ON n.id_nacionalidad=ddc.id_nacionalidad';

	----lectura de FA

    SET    @sSQLFA = 'select dt.folio_detenido
            , isnull(ddc.nombre_detenido, dt.nombre) nombre
            , isnull(ddc.apellido_paterno, dt.apellido_paterno) apellido_paterno
            , isnull(ddc.apellido_materno, dt.apellido_materno) apellido_materno
            , ddc.curp
            , CASE WHEN ddc.id_pais IS NULL THEN '' '' ELSE p.nombre_pais END pais
            , CASE WHEN ddc.id_estado IS NULL THEN '' '' WHEN ddc.id_estado = 0 THEN '' '' ELSE ce.nombre END AS estado
            , CASE WHEN ddc.id_nacionalidad IS NULL THEN '' '' ELSE n.nombre_nacionalidad END AS nacionalidad
            , isnull(d.lugar_detencion,'''') lugar_detencion
            , isnull(ce.nombre,'''') as entidad
            , isnull(cm.nombre,'''') as municipio
            , isnull(cl.nombre,'''') as localidad
            , CASE WHEN d.id_colonia = 0 THEN '''' ELSE  (SELECT distinct(nombre) FROM GeoDirecciones.DBO.COLONIA WHERE IDCOLONIA=d.id_colonia) END as colonia
            , CASE WHEN d.id_calle = 0 THEN '''' ELSE (SELECT distinct(nombre) FROM GeoDirecciones.DBO.VIALIDAD WHERE CALLEID= d.id_calle) END as calle
            , CASE WHEN d.id_entrecalle = 0 THEN '''' ELSE (SELECT distinct(nombre) FROM GeoDirecciones.DBO.VIALIDAD WHERE CALLEID=d.id_entrecalle)END as entre_calle
            , CASE WHEN d.id_ycalle = 0 THEN '''' ELSE (SELECT distinct(nombre) FROM GeoDirecciones.DBO.VIALIDAD WHERE CALLEID=d.id_ycalle) END AS y_calle
            , isnull(d.numero_interio,'''') numero_interior
            , isnull(d.numero_exterior,'''') numero_exterior
            , isnull(d.codigo_postal,'''') codigo_postal
            , isnull(d.referencias,'''') referencias
            , CONVERT(DATE,d.fecha_detencion) fecha_detencion
            , isnull(CONVERT(DATE,ddc.fecha_nacimiento)
			, CONVERT(DATE,dt.fecha_nacimiento)) fecha_nacimiento
           -- , convert(nvarchar, datepart(hour,d.fecha_detencion)) + '':'' + convert(nvarchar,datepart(minute,d.fecha_detencion)) hora_detencion
            , isnull(substring(convert(nvarchar, d.fecha_detencion,108), 1, 5),'''') hora_detencion
            , DATEDIFF(YEAR, isnull(ddc.fecha_nacimiento, dt.fecha_nacimiento), GETDATE()) as Edad
            , CASE WHEN STUFF((SELECT '','' + ci.institucion FROM RNDetenciones_FA.dbo.oficiales_fa o INNER JOIN RNDetenciones_FA.dbo.cat_instituciones_fa ci ON ci.id_institucion=o.id_institucion WHERE o.id_detencion=d.id_detencion FOR XML PATH('''')), 1, 1, '''') IS NULL THEN ''''
			ELSE STUFF((SELECT '','' + ci.institucion FROM RNDetenciones_FA.dbo.oficiales_fa o INNER JOIN RNDetenciones_FA.dbo.cat_instituciones_fa ci ON ci.id_institucion=o.id_institucion WHERE o.id_detencion=d.id_detencion FOR XML PATH('''')), 1, 1, '''') END  + '','' +
			CASE WHEN STUFF((SELECT '','' + institucion FROM RNDetenciones_FA.dbo.oficiales_PSP_fa opsp WHERE opsp.id_detencion=d.id_detencion FOR XML PATH('''')), 1, 1, '''') IS NULL THEN ''''
			ELSE STUFF((SELECT '','' + institucion FROM RNDetenciones_FA.dbo.oficiales_PSP_fa opsp WHERE opsp.id_detencion=d.id_detencion FOR XML PATH('''')), 1, 1, '''') END AS autoridad_detiene,
			isnull(pd.adscripcion_recibe,'''')  as autoridad_recibe
			, isnull(pd.fecha_recibe,'''') fecha_recibe
			, isnull(ddc.carpeta_investigacion,'''') carpeta_investigacion
            , CONVERT(DATE,GETDATE()) fecha_consulta
			, DT.alias + '','' + DDC.alias + '','' + CASE WHEN STUFF((SELECT '','' + alias FROM RNDetenciones_FA.dbo.alias_detenido_fa ad WHERE ad.id_detenido_complemento=ddc.id_detenido_complemento FOR XML PATH('''')), 1, 1, '''') IS NULL THEN '''' 
			ELSE STUFF((SELECT '','' + alias FROM RNDetenciones_FA.dbo.alias_detenido_fa ad WHERE ad.id_detenido_complemento=ddc.id_detenido_complemento FOR XML PATH('''')), 1, 1, '''') END as alias
		    into ##regfa
            FROM RNDetenciones_FA..detenciones_fa d
            INNER JOIN RNDetenciones_FA..cat_tipos_detenciones_fa ctd
                ON ctd.id_tipo_detencion = D.id_tipo_detencion
                and d.es_activo = 1
            INNER JOIN RNDetenciones_FA..detenidos_fa dt
                ON D.id_detencion = dt.id_detencion
                AND dt.es_borrado = 0
            LEFT JOIN RNDetenciones_FA..puesta_disposiciones_fa pd
                ON dt.id_detenido = pd.id_detenido
                AND pd.es_borrado = 0
            LEFT JOIN RNDetenciones_FA..puesta_disposiciones_oficiales_psp_fa pdof
                ON pd.id_puesta_disposicion = pdof.Id_Puesta_Dsposicion 
            LEFT JOIN RNDetenciones_FA..oficiales_psp_fa ofp
                ON ofp.id_detencion = d.id_detencion
                AND ofp.usuario_participo = 1
            LEFT JOIN RNDetenciones_FA..cat_fiscalias_fa cf
                ON cf.id_fiscalia = pd.id_fiscalia
            LEFT JOIN RNDetenciones_FA..detenidos_datoscomplementarios_fa ddc
                ON pd.id_puesta_disposicion = ddc.id_puesta_disposicion
            LEFT JOIN RNDetenciones_FA..traslados_fa tr
                ON ddc.id_detenido_complemento = tr.id_detenido_complemento
                AND tr.es_activo = 1
            LEFT JOIN RNDetenciones_FA..cat_fueros_fa cfs 
                ON cfs.id_fuero = D.id_fuero
            LEFT JOIN RNDetenciones_FA..cat_tipos_traslados_fa ctr
                ON ctr.id_tipo_traslado = tr.id_tipo_traslado
            LEFT JOIN RNDetenciones_FA..alias_detenido_fa dta
                ON dta.id_detenido_complemento = ddc.id_detenido_complemento
            LEFT JOIN geodirecciones..entidad CE 
                ON CE.identidad = D.id_entidad
            LEFT JOIN geodirecciones..municipio CM 
                ON CM.identidad = D.id_entidad 
                AND CM.idmpio = D.id_municipio
            LEFT JOIN GeoDirecciones.DBO.LOCALIDAD cl 
                ON cl.IDLOC= d.id_localidad 
                AND cl.IDMPIO= cm.IDMPIO 
                AND cl.IDENTIDAD= ce.IDENTIDAD
            LEFT JOIN RNDetenciones_FA.dbo.cat_paises_fa p 
                ON p.id_pais=ddc.id_pais
            LEFT JOIN RNDetenciones_FA.dbo.cat_nacionalidades_fa n 
                ON n.id_nacionalidad=ddc.id_nacionalidad';

        ---formacion de la instruccion WHERE
        IF @Nombre <> '' OR @paterno <> '' OR @materno <> ''

        BEGIN

             IF @paterno = '' SET @paterno = '%'
             
             SET @vcnombrecompleto = @Nombre + ' ' + @paterno + ' ' + @materno
                   
             /*SET @sSQLWhere = @sSQLWhere + ' case ' +
                        'when dbo.fn_limpiaCaracteres(ddc.nombre_detenido + '' '' + ddc.apellido_paterno + '' '' + ddc.apellido_materno) is null ' +
                            'then dbo.fn_limpiaCaracteres(dt.nombre + '' '' + dt.apellido_paterno + '' '' + dt.apellido_materno) ' +
                          'when dbo.fn_limpiaCaracteres(dt.nombre + '' '' + dt.apellido_paterno + '' '' + dt.apellido_materno) is null ' +
                            'then dbo.fn_limpiaCaracteres(ddc.nombre_detenido + '' '' + ddc.apellido_paterno + '' '' + ddc.apellido_materno) ' +
                     	  'else dbo.fn_limpiaCaracteres(ddc.nombre_detenido + '' '' + ddc.apellido_paterno + '' '' + ddc.apellido_materno) end like ' + '''%' + rtrim(ltrim(DBO.fn_limpiaCaracteres(@vcnombrecompleto))) + '%'''*/

               SET @sSQLWhere = @sSQLWhere + ' (dbo.fn_limpiaCaracteres(lower(ltrim(rtrim(ddc.nombre_detenido))) + '' '' + lower(ltrim(rtrim(ddc.apellido_paterno))) + '' '' + lower(ltrim(rtrim(ddc.apellido_materno)))) like ' + '''%' + lower(ltrim(rtrim(DBO.fn_limpiaCaracteres(@vcnombrecompleto)))) + '%'''
						+ ' OR dbo.fn_limpiaCaracteres(lower(ltrim(rtrim(dt.nombre))) + '' '' + lower(ltrim(rtrim(dt.apellido_paterno))) + '' '' + lower(ltrim(rtrim(dt.apellido_materno)))) like ' + '''%' + lower(ltrim(rtrim(DBO.fn_limpiaCaracteres(@vcnombrecompleto)))) + '%''' + ')'
        END


            --busquedas con CURP
            IF @curp <> ''
              BEGIN

                IF (@sSQLWhere = '')

                    SET @sSQLWhere = @sSQLWhere + ' ddc.CURP like ' + '''%' + ltrim(@curp) + '%'''

                ELSE
                   SET @sSQLWhere = @sSQLWhere + ' AND ddc.CURP like ' + '''%' + ltrim(@curp) + '%'''

              END

            --busquedas con alias
            IF @alias <> ''
              BEGIN

                IF (@sSQLWhere = '')

                    SET @sSQLWhere = @sSQLWhere + ' (DT.ALIAS LIKE ' + '''%' + ltrim(@alias) + '%''' 
												+ ' OR DDC.ALIAS LIKE ' + '''%' + ltrim(@alias) + '%''' 
												+ ' OR DTA.ALIAS LIKE ' + '''%'	+ ltrim(@alias) + '%''' 
												+ ')'

                ELSE
                   SET @sSQLWhere = @sSQLWhere + ' AND (DT.ALIAS LIKE ' + '''%' + ltrim(@alias) + '%''' 
												+ ' OR DDC.ALIAS LIKE ' + '''%' + ltrim(@alias) + '%''' 
												+ ' OR DTA.ALIAS LIKE ' + '''%'	+ ltrim(@alias) + '%''' 
												+ ')' 

              END

            --busquedas por estado
            IF @idedo <> 0
              BEGIN

                IF (@sSQLWhere = '')

                    SET @sSQLWhere = @sSQLWhere + ' d.id_entidad = ' + CONVERT(nvarchar, @idedo)

                ELSE
                   SET @sSQLWhere = @sSQLWhere + ' AND d.id_entidad = ' + CONVERT(nvarchar, @idedo)

              END


            --busquedas por municipio
            IF @idmpio <> 0
              BEGIN

                IF (@sSQLWhere = '')

                    SET @sSQLWhere = @sSQLWhere + ' d.id_municipio = ' + CONVERT(nvarchar, @idmpio)

                ELSE
                   SET @sSQLWhere = @sSQLWhere + ' AND d.id_municipio = ' + CONVERT(nvarchar, @idmpio)

              END

            --busquedas por fecha ultima vez visto
            IF @fechaultima <> ''
              BEGIN

                IF (@sSQLWhere = '')

                    SET @sSQLWhere = @sSQLWhere + ' d.fecha_detencion >= ' + '''' + @fechaultima + ''''

                ELSE
                   SET @sSQLWhere = @sSQLWhere + ' AND d.fecha_detencion >= ' + '''' + @fechaultima + ''''

              END

--busquedas por clave de sexo
			IF  @sexo IN ('H','M','X')
              BEGIN

                IF (@sexo = 'H') SET @cvsexo = '2' else SET @cvsexo = '3'

                IF (@sSQLWhere = '')

					IF (@sexo != 'X')

						SET @sSQLWhere = @sSQLWhere + ' case
							when ddc.id_sexo is null
								then dt.id_sexo
							else ddc.id_sexo end in ( ' + @cvsexo + ', 1 )'

					ELSE
						SET @sSQLWhere = @sSQLWhere + ' case
							when ddc.id_sexo is null
								then dt.id_sexo
							else ddc.id_sexo end IN (SELECT id_sexo FROM cat_sexo)'

                ELSE

					IF (@sexo != 'X')
					   SET @sSQLWhere = @sSQLWhere + ' AND case
							when ddc.id_sexo is null
								then dt.id_sexo
							else ddc.id_sexo end in ( ' + @cvsexo + ', 1 )'
					ELSE
						SET @sSQLWhere = @sSQLWhere + ' AND case
							when ddc.id_sexo is null
								then dt.id_sexo
							else ddc.id_sexo  end IN (SELECT id_sexo FROM cat_sexo)'

              END -- Termina busquedas por clave de sexo

            --busquedas por fecha de nacimiento
            IF @fecha_nacimiento <> ''
              BEGIN

                IF (@sSQLWhere = '')

                    SET @sSQLWhere = @sSQLWhere + ' case
                        when ddc.fecha_nacimiento is null
                            then dt.fecha_nacimiento
                        when dt.fecha_nacimiento is null
                            then ddc.fecha_nacimiento
                        else ddc.fecha_nacimiento end = ' + '''' + @fecha_nacimiento + ''''

                ELSE
                   SET @sSQLWhere = @sSQLWhere + ' and case
                        		when ddc.fecha_nacimiento is null
                            then dt.fecha_nacimiento
     							when dt.fecha_nacimiento is null
                            then ddc.fecha_nacimiento
                        else ddc.fecha_nacimiento end = ' + '''' + @fecha_nacimiento + ''''

              END

			--busquedas edad minima y/o edad maxima
            IF @edad_minima <> 0 and @edad_maxima <> 0
              BEGIN

                IF (@sSQLWhere = '')

                    SET @sSQLWhere = @sSQLWhere + ' DATEDIFF(YEAR, isnull(ddc.fecha_nacimiento, dt.fecha_nacimiento), GETDATE()) >= ' +  cast(@edad_minima as varchar) + 
												  ' AND DATEDIFF(YEAR, isnull(ddc.fecha_nacimiento, dt.fecha_nacimiento), GETDATE()) <= ' +  cast(@edad_maxima as varchar)
                ELSE
                   SET @sSQLWhere = @sSQLWhere + ' AND (DATEDIFF(YEAR, isnull(ddc.fecha_nacimiento, dt.fecha_nacimiento), GETDATE()) >= ' +  cast(@edad_minima as varchar) + 
												  ' AND DATEDIFF(YEAR, isnull(ddc.fecha_nacimiento, dt.fecha_nacimiento), GETDATE()) <= ' +  cast(@edad_maxima as varchar) + ')'

              END

            IF @edad_minima <> 0 and @edad_maxima = 0
              BEGIN

                IF (@sSQLWhere = '')

                    SET @sSQLWhere = @sSQLWhere + ' DATEDIFF(YEAR, isnull(ddc.fecha_nacimiento, dt.fecha_nacimiento), GETDATE()) >= ' +  cast(@edad_minima as varchar) 
                ELSE
                   SET @sSQLWhere = @sSQLWhere + ' AND (DATEDIFF(YEAR, isnull(ddc.fecha_nacimiento, dt.fecha_nacimiento), GETDATE()) >= ' +  cast(@edad_minima as varchar) + ')'

              END

            IF @edad_minima = 0 and @edad_maxima <> 0
              BEGIN

             IF (@sSQLWhere = '')

                    SET @sSQLWhere = @sSQLWhere + ' DATEDIFF(YEAR, isnull(ddc.fecha_nacimiento, dt.fecha_nacimiento), GETDATE()) <= ' +  cast(@edad_maxima as varchar)
                ELSE
                   SET @sSQLWhere = @sSQLWhere + ' AND (DATEDIFF(YEAR, isnull(ddc.fecha_nacimiento, dt.fecha_nacimiento), GETDATE()) <= ' +  cast(@edad_maxima as varchar) + ')'

              END

		----crea la instruccion where
        IF @sSQLWhere <> ''
			BEGIN
			 SET @sSQL = @sSQL + ' WHERE '
			 SET @sSQL = @sSQL + @sSQLWhere 
			 SET @sSQL = @sSQL + ' ORDER BY 1, 3, 4, 2 '

			 SET @sSQLFA = @sSQLFA + ' WHERE '
			 SET @sSQLFA = @sSQLFA + @sSQLWhere 
			 SET @sSQLFA = @sSQLFA + ' ORDER BY 1, 3, 4, 2 '
			END
		ELSE
			BEGIN
			 SET @sSQL = @sSQL + ' WHERE 1 = 2'

			 SET @sSQLFA = @sSQLFA + ' WHERE 1 = 2'
			END

        --PRINT @sSQL

        EXEC (@sSQL)

        EXEC (@sSQLFA)

        --PRINT @sSQLFA

        --Lista registros encontrados HPD y FA
        select * from ##reghpd
        union
        select * from ##regfa;

        --calcula total de registros leidos HPD y FA
        select @totreg = (sum(vnthpd) + sum(vntfa)) from 
        ( select count(1) vnthpd, 0 vntfa from ##reghpd
            union
           select 0 vnthpd, count(1) vntfa from ##regfa) x

        --inserta bitacora
        INSERT INTO RND_bitacoras.dbo.BIT_FGR_CONSULTAS
            (NUMERO_EXPEDIENTE, CUENTA_USUARIO, NOMBRE_USUARIO, PM_USUARIO, VALOR_BUSQUEDA, NUM_REG_CONSULTADOS, FECHA_PROCESO)
        VALUES
            (@Nun_expdiente, @Cta_usuario, @Nombre_usuario, @pm_usuario, @sSQLWhere, @totreg, GETDATE());
END TRY
  BEGIN CATCH
        EXEC RethrowError;
  END CATCH
END