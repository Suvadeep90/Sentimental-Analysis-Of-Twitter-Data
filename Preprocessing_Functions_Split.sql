USE [Twiter]
GO

/****** Object:  UserDefinedFunction [dbo].[Split]    Script Date: 11/26/2016 2:04:33 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[Split](@sep VARCHAR(32), @s VARCHAR(MAX))
RETURNS @t TABLE
 (val VARCHAR(MAX))
AS
   BEGIN
     DECLARE @xml XML
     SET @XML = N'' + REPLACE(@s, @sep, '') + ''
     INSERT INTO @t(val)
     SELECT r.value('.','VARCHAR(1000)') as Item
     FROM @xml.nodes('//root/r') AS RECORDS(r)
     RETURN
  END

GO


