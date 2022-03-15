-- =============================================
-- Author:      Chad Petrovay
-- Create date: 2022-03-15
-- Description: Add a dimension type to an existing dimension record, using the element's rank
-- =============================================
-- Parameters:
--   @ObjectNumber - The unique Object Number in TMS
--   @Rank - The ranking or position of the Dimension Element that is being amended
--   @NewType - The Dimension Type that is being amended
--   @Metric - The Dimension in either centimeters (cm) or kilograms (kg)
--   @Login - The login for the user
-- =============================================


CREATE PROCEDURE [dbo].[MLM_AddDimensionType_ByRank] @ObjectNumber NVARCHAR(64), @Rank INT, @Type NVARCHAR(32), @Metric DECIMAL(22,10), @Login NVARCHAR(32) AS
BEGIN
	DECLARE @OBJECTID INT; -- Object primary key
	DECLARE @ELEMENTID INT; -- The Dimension Element primary key
	DECLARE @DIMTYPEID INT; -- The Dimension Type primary key
	DECLARE @DEIXID INT; -- The Object Dimension Element Xref primary key
	DECLARE @DISPLAYORDER INT; -- The display order for the new dimension type
	DECLARE @ELEMENT NVARCHAR(32); -- The Dimension Element

	-- Validate that @ObjectNumber is unique
	IF (SELECT COUNT(*) FROM Objects WHERE ObjectNumber = @ObjectNumber) = 1
		SELECT @OBJECTID = ObjectID FROM Objects WHERE ObjectNumber = @ObjectNumber;
	ELSE 
	BEGIN
		PRINT 'Error: Check the object number for accuracy, ensuring only one object has that value.';
		RETURN;
	END

	-- Validate that the Dimension Type can be resolved
	IF (SELECT COUNT(*) FROM DimensionTypes WHERE DimensionType = @Type) = 1
		SELECT @DIMTYPEID = DimensionTypeID FROM DimensionTypes WHERE DimensionType = @Type;
	ELSE 
	BEGIN
		PRINT 'Error: Check the dimension type for spelling and accuracy.';
		RETURN;
	END

	-- Validate that the Dimension Elements is only used once in the Object
	IF (SELECT COUNT(*) FROM DimItemElemXrefs WHERE ID = @OBJECTID AND TableID = 108 AND Rank = @Rank) = 1
	BEGIN
		SELECT @DEIXID = DimItemElemXrefID, @ELEMENTID = ElementID FROM DimItemElemXrefs WHERE ID = @OBJECTID AND TableID = 108 AND Rank = @Rank;
		SELECT @ELEMENT = Element FROM DimensionElements WHERE ElementID = @ELEMENTID;
	END
	ELSE 
	BEGIN
		PRINT 'Error: There is no element with the required ranking.';
		RETURN;
	END

	-- Validate that the Object Dimension Element Xref does not already include the Dimension Type
	IF (SELECT COUNT(*) FROM Dimensions WHERE DimItemElemXrefID = @DEIXID AND DimensionTypeID = @DIMTYPEID) = 0
		SELECT @DISPLAYORDER = MAX(Rank) + 1 FROM Dimensions WHERE DimItemElemXrefID = @DEIXID;
	ELSE 
	BEGIN
		PRINT 'Error: Dimension types can only be used once in an element.';
		RETURN;
	END

	-- Add the new dimension to the Object Dimension Element Xref
    INSERT INTO Dimensions (DimItemElemXrefID, DimensionTypeID, PrimaryUnitID, SecondaryUnitID, Displayed, Rank, LoginID, Dimension)
    (SELECT @DEIXID, DimensionTypeID, PrimaryUnitID, SecondaryUnitID, 1, @DISPLAYORDER, @Login, @Metric
	FROM DimensionTypes WHERE DimensionTypeID = @DIMTYPEID);

	PRINT CONCAT(@Type,' has been added to ', @ELEMENT,' for ',@ObjectNumber);
	PRINT CONCAT('MANUALLY CREATE LABEL FOR ',@ObjectNumber,'!!');

END
GO
