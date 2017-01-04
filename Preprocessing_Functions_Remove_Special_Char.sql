USE [Twiter]
GO

/****** Object:  UserDefinedFunction [dbo].[RemoveSpecialChars]    Script Date: 11/26/2016 2:04:25 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


  --CREATE FUNCTION TO REMOVE UNWANTED CHARACTERS
CREATE FUNCTION [dbo].[RemoveSpecialChars]
(@Input VARCHAR(MAX))
RETURNS VARCHAR(MAX)
BEGIN
   DECLARE @Output VARCHAR(MAX)
   IF (ISNULL(@Input,'')='')
      SET @Output = @Input
   ELSE
   BEGIN
    DECLARE @Len INT
    DECLARE @Counter INT
    DECLARE @CharCode INT
    SET @Output = ''
    SET @Len = LEN(@Input)
   SET @Counter = 1
       WHILE @Counter <= @Len
       BEGIN
          SET @CharCode = ASCII(SUBSTRING(@Input, @Counter, 1))
          IF @CharCode=32 OR @CharCode BETWEEN 48 and 57 OR @CharCode BETWEEN 65 AND 90
          OR @CharCode BETWEEN 97 AND 122
             SET @Output = @Output + CHAR(@CharCode)
          SET @Counter = @Counter + 1
       END
   END
   RETURN @Output
END

GO


