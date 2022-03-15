-- =============================================
-- Author:      Chad Petrovay
-- Create date: 2022-03-15
-- Description: Add a dimension type to an existing dimension record, using the element's rank
-- =============================================
-- Parameters:
--   @ObjectNumber - The unique Object Number in TMS
--   @Element - The Dimension Element that is being added
--   @H (optional) - The height in centimeters (cm)
--   @W (optional) - The width in centimeters (cm)
--   @D (optional) - The depth in centimeters (cm)
--   @Login - The login for the user
--   @Description (optional) - The Element Details description
-- =============================================


ALTER PROCEDURE [dbo].[MLM_AddNewDimension] @ObjectNumber NVARCHAR(64), @Element NVARCHAR(32), @H DECIMAL(22,10) = NULL, @W DECIMAL(22,10) = NULL, @D DECIMAL(22,10) = NULL, @Login NVARCHAR(32), @Description NVARCHAR(64) = NULL AS
BEGIN
	DECLARE @OBJECTID INT; -- Object primary key
	DECLARE @ELEMENTID INT; -- The Dimension Element primary key
	DECLARE @DISPLAYORDER INT; -- The display order for the new element
	DECLARE @DEIXID INT; -- The Object Dimension Element Xref primary key 

	IF (SELECT ISNULL(@H,0) + ISNULL(@W,0) + ISNULL(@D,0)) > 0
	BEGIN
		-- Validate that @ObjectNumber is unique
		IF (SELECT COUNT(*) FROM Objects WHERE ObjectNumber = @ObjectNumber) = 1
			SELECT @OBJECTID = ObjectID FROM Objects WHERE ObjectNumber = @ObjectNumber;
		ELSE 
		BEGIN
			PRINT 'Error: Check the object number for accuracy, ensuring only one object has that value.';
			RETURN;
		END

		-- Validate that the Dimension Elements can be resolved
		IF (SELECT COUNT(*) FROM DimensionElements WHERE Element = @Element) <> 1
		BEGIN
			PRINT 'Error: Check the dimension element for spelling and accuracy.';
			RETURN;
		END

		--Get positioning
		SELECT @DISPLAYORDER = ISNULL(MAX(Rank),0) + 1 FROM DimItemElemXrefs WHERE ID = @OBJECTID AND TableID = 108;

		--Add new element
		INSERT INTO DimItemElemXrefs (ElementID, ID, TableID, Rank, Displayed, Description, LoginID)
		(SELECT ElementID, @OBJECTID, 108, @DISPLAYORDER, Displayed, CASE WHEN ISNULL(@Description,'') = '' THEN NULL ELSE @Description END, @Login FROM DimensionElements WHERE Element = @Element);

		SELECT @DEIXID = DimItemElemXrefID FROM DimItemElemXrefs WHERE ID = @OBJECTID AND TableID = 108 AND Rank = @DISPLAYORDER;

		--When height is set
		IF @H > 0
		BEGIN
			INSERT INTO Dimensions (DimItemElemXrefID, DimensionTypeID, PrimaryUnitID, SecondaryUnitID, Displayed, Rank, LoginID, Dimension)
			(SELECT @DEIXID, DimensionTypeID, PrimaryUnitID, SecondaryUnitID, 1, 1, @Login, @H FROM DimensionTypes WHERE [System] = 1);
		END

		--When width is set
		IF @W > 0
		BEGIN
			INSERT INTO Dimensions (DimItemElemXrefID, DimensionTypeID, PrimaryUnitID, SecondaryUnitID, Displayed, Rank, LoginID, Dimension)
			(SELECT @DEIXID, DimensionTypeID, PrimaryUnitID, SecondaryUnitID, 1, CASE WHEN @H > 0 THEN 2 ELSE 1 END, @Login, @W FROM DimensionTypes WHERE [System] = 2);
		END

		--When depth is set
		IF @D > 0
		BEGIN
			INSERT INTO Dimensions (DimItemElemXrefID, DimensionTypeID, PrimaryUnitID, SecondaryUnitID, Displayed, Rank, LoginID, Dimension)
			(SELECT @DEIXID, DimensionTypeID, PrimaryUnitID, SecondaryUnitID, 1, CASE WHEN @H > 0 AND @W > 0 THEN 3 WHEN @H > 0 OR @W > 0 THEN 2 ELSE 1 END, @Login, @D FROM DimensionTypes WHERE [System] = 3);
		END

		PRINT CONCAT(@ELEMENT,' has been added to ',@ObjectNumber);
		PRINT CONCAT('MANUALLY CREATE LABEL FOR ',@ObjectNumber,'!!');
	END
	ELSE
		PRINT 'Error: Request does not include any dimensions';

END
GO
