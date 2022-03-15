-- =============================================
-- Author:      Chad Petrovay
-- Create date: 2021-04-08
-- Description: Switch the element in an existing dimension record
-- =============================================
-- Parameters:
--   @ObjectNumber - The unique Object Number in TMS
--   @OldElement - The Dimension Element that is being switched out
--   @NewElement - The Dimension Element that is being switched to
--   @Login - The login for the user making the change
--   @Description (optional) - The Element Details description
-- =============================================


CREATE PROCEDURE [dbo].[MLM_ChangeDimensionElement] @ObjectNumber NVARCHAR(64), @OldElement NVARCHAR(32), @NewElement NVARCHAR(32), @Login NVARCHAR(32), @Description NVARCHAR(64) = NULL AS
BEGIN
	DECLARE @OBJECTID INT; -- Object primary key
	DECLARE @DIMENSION NVARCHAR(max); -- Object dimension label
	DECLARE @ELEMENTID_OLD INT; -- The current Dimension Element primary key
	DECLARE @SHOW_OLD INT; -- Is the current Dimension Element name displayed in the dimension label
	DECLARE @ELEMENTID_NEW INT; -- The replacement Dimension Element primary key
	DECLARE @SHOW_NEW INT; -- Is the replacement Dimension Element name displayed in the dimension label
	DECLARE @DESCRIPTION_OLD NVARCHAR(64); -- The current Dimension Element details description

	-- Validate that @ObjectNumber is unique
	IF (SELECT COUNT(*) FROM Objects WHERE ObjectNumber = @ObjectNumber) = 1
		SELECT @OBJECTID = ObjectID, @DIMENSION = Dimensions FROM Objects WHERE ObjectNumber = @ObjectNumber;
	ELSE 
	BEGIN
		PRINT 'Error: Check the object number for accuracy, ensuring only one object has that value.';
		RETURN;
	END

	-- Validate that the Dimension Elements can be resolved
	IF (SELECT COUNT(*) FROM DimensionElements WHERE Element IN (@OldElement,@NewElement)) = 2
	BEGIN
		SELECT @ELEMENTID_OLD = ElementID, @SHOW_OLD = ShowElementName FROM DimensionElements WHERE Element = @OldElement;
		SELECT @ELEMENTID_NEW = ElementID, @SHOW_NEW = ShowElementName FROM DimensionElements WHERE Element = @NewElement;
	END
	ELSE 
	BEGIN
		PRINT 'Error: Check the dimension elements for spelling and accuracy.';
		RETURN;
	END

	-- Validate that the Dimension Elements is only used once in the Object
	IF (SELECT COUNT(*) FROM DimItemElemXrefs WHERE ElementID = @ELEMENTID_OLD AND ID = @OBJECTID AND TableID = 108) = 1
	BEGIN
		SELECT @DESCRIPTION_OLD = CASE WHEN [Description] = '' THEN NULL ELSE [Description] END
		FROM DimItemElemXrefs
		WHERE ElementID = @ELEMENTID_OLD AND ID = @OBJECTID AND TableID = 108;
	END
	ELSE 
	BEGIN
		PRINT 'Error: This procedure only works when the element is only used once.';
		RETURN;
	END

	-- Prepare changes to the Object Dimension label
	DECLARE @FIND NVARCHAR(255); -- Current Dimension Element name and description string
	DECLARE @REPLACE NVARCHAR(255); -- Replacement Dimension Element name and description string

	SELECT @FIND = CONCAT(
		CASE WHEN @SHOW_OLD = 1 THEN @OldElement END,
		CASE WHEN @SHOW_OLD = 1 AND ISNULL(@DESCRIPTION_OLD,'') <> '' THEN ' (' END,
		CASE WHEN ISNULL(@DESCRIPTION_OLD,'') <> '' THEN @DESCRIPTION_OLD END,
		CASE WHEN @SHOW_OLD = 1 AND ISNULL(@DESCRIPTION_OLD,'') <> '' THEN ')' END,
		':');

	SELECT @REPLACE = CONCAT(
		CASE WHEN @SHOW_NEW = 1 THEN @NewElement END,
		CASE WHEN @SHOW_NEW = 1 AND (ISNULL(@Description,'') <> '' OR ISNULL(@DESCRIPTION_OLD,'') <> '') THEN ' (' END,
		CASE WHEN ISNULL(@Description,'') <> '' THEN @Description 
			WHEN ISNULL(@DESCRIPTION_OLD,'') <> '' THEN @DESCRIPTION_OLD END,
		CASE WHEN @SHOW_NEW = 1 AND (ISNULL(@Description,'') <> '' OR ISNULL(@DESCRIPTION_OLD,'') <> '') THEN ')' END,
		':');

	IF @FIND <> ':' AND @REPLACE <> ':'
		SELECT @DIMENSION = REPLACE(@DIMENSION,@FIND,@REPLACE);
	ELSE
		PRINT CONCAT('MANUALLY CREATE LABEL FOR ',@ObjectNumber,'!!');
	
	-- Perform the update to the DimItemElemXrefs table
	IF @Description IS NULL
		UPDATE DimItemElemXrefs SET ElementID = @ELEMENTID_NEW WHERE ElementID = @ELEMENTID_OLD AND ID = @OBJECTID AND TableID = 108;
	ELSE 
		UPDATE DimItemElemXrefs SET ElementID = @ELEMENTID_NEW, Description = @Description WHERE ElementID = @ELEMENTID_OLD AND ID = @OBJECTID AND TableID = 108;

	-- Perform update to Object Dimension label
	EXECUTE MLM_UpdateFieldValue 1239, @OBJECTID, @DIMENSION, @Login;

	PRINT CONCAT('Dimension element for ',@ObjectNumber,' has been corrected.');

END
GO
