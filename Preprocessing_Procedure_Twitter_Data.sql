--CREATE STRING CLEANING STORED PROCEDURE
CREATE PROCEDURE [dbo].[usp_Massage_Twitter_Data] 
(@table_name NVARCHAR(100))
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON
 
        --CREATE CLUSTERED INDEX SQL
        DECLARE @SQL_Drop_Index NVARCHAR(1000)
        SET @SQL_Drop_Index = 
                'IF EXISTS (SELECT name FROM sys.indexes
                WHERE name = N''IX_Feed_ID'')
                DROP INDEX IX_Feed_ID ON ' + @table_name + '
                CREATE CLUSTERED INDEX IX_Feed_ID 
                ON  ' + @Table_Name + '  (ID)';
 
        --REMOVE UNWANTED CHARACTERS SQL
        DECLARE @SQL_Remove_Chars NVARCHAR(2000)
        SET @SQL_Remove_Chars = 
                'UPDATE ' + @Table_Name + '
                SET feed = (select dbo.RemoveSpecialChars(feed))
        
                DECLARE @z int
                DECLARE db_cursor CURSOR
                FOR
                    SELECT id
                    FROM ' + @Table_Name + '
                    OPEN db_cursor
                    FETCH NEXT
                    FROM db_cursor INTO @z
                    WHILE @@FETCH_STATUS = 0
                        BEGIN
                        DECLARE @Combined_String VARCHAR(max);
                        WITH cte(id, val)  AS (
                            SELECT a.id, fs.val
                            FROM ' + @Table_Name + '  a
                            CROSS APPLY  dbo.split('' '', feed)  AS fs
                            WHERE fs.val NOT LIKE  ''%http%'' and a.id = @z)
                        SELECT @Combined_String = 
                        COALESCE(@Combined_String + '' '', '''')  + val
                        FROM cte
 
                        UPDATE ' + @Table_Name + '
                        SET feed  = ltrim(rtrim(@Combined_String))
                        WHERE ' + @Table_Name + '.id = @z
 
                        SELECT @Combined_String = ''''
                        FETCH NEXT
                        FROM db_cursor INTO @z
                        END
                    CLOSE db_cursor
                    DEALLOCATE db_cursor'
 
        --RESEED IDENTITY COLUMN & DELETE EMPTY RECORDS SQL
        DECLARE @SQL_Reseed_Delete NVARCHAR(1000)
 
        SET @SQL_Reseed_Delete = 
                'IF EXISTS  (SELECT   c.is_identity
                FROM   sys.tables t
                JOIN sys.schemas s
                ON t.schema_id = s.schema_id
                JOIN sys.Columns c
                ON c.object_id = t.object_id
                JOIN sys.Types ty
                ON ty.system_type_id = c.system_type_id
                WHERE  t.name = ''+ @Table_Name +''
                AND s.Name = ''dbo''
                AND c.is_identity=1)
                SET IDENTITY_INSERT ' + @Table_Name + ' ON
 
                DELETE FROM ' + @Table_Name + '
                WHERE Feed IS NULL or Feed =''''
 
                DBCC CHECKIDENT (' + @Table_Name + ', reseed, 1)
                SET IDENTITY_INSERT ' + @Table_Name + ' OFF
 
                ALTER INDEX IX_Feed_ID ON ' + @Table_Name + '
                REORGANIZE'
 
        EXECUTE sp_executesql @SQL_Drop_Index
        EXECUTE sp_executesql @SQL_Remove_Chars
        EXECUTE sp_executesql @SQL_Reseed_Delete
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION
        END
 
        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;
        SELECT  @ErrorMessage = ERROR_MESSAGE(),
                @ErrorSeverity = ERROR_SEVERITY(),
                @ErrorState = ERROR_STATE();
        RAISERROR (
                @ErrorMessage,-- Message text.
                @ErrorSeverity,-- Severity.
                @ErrorState -- State.
                );
    END CATCH
        IF @@TRANCOUNT > 0
            BEGIN
                COMMIT TRANSACTION
    END
END