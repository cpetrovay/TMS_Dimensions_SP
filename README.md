# Stored Procedures for TMS: Object Dimensions

Stored Procedures for adding and managing object dimensions in TMS on SQL Server.

## MLM_AddDimensionType_ByName
Add a new dimension type (Height, Width, Depth, etc) to an existing dimension record, referencing the dimension element's name.

### Parameters

- `@ObjectNumber` : The unique Object Number for the record where the element is being changed
- `@Element` : The existing Dimension Element that is being amended
- `@NewType` : The Dimension Type that is being amended
- `@Metric` : The Dimension in either centimeters (cm) or kilograms (kg)
- `@Login` : The login for the user

This stored procedure will not work if an object has more than one dimension with the `@OldElement` value; consider using `MLM_AddDimensionType_ByRank` instead.

### Example

User John Doe can add a depth to an existing Frame dimension, using:

```EXECUTE MLM_AddDimensionType_ByName '2022.233', 'Frame', 'Depth', 6.5, 'john.doe'```

## MLM_AddDimensionType_ByRank
Add a new dimension type (Height, Width, Depth, etc) to an existing dimension record, referencing the dimension element's rank. Useful when an object has multiple dimensions of the same element.

### Parameters

- `@ObjectNumber` : The unique Object Number for the record where the element is being changed
- `@Rank` : The rank of the existing Dimension Element that is being amended
- `@NewType` : The Dimension Type that is being amended
- `@Metric` : The Dimension in either centimeters (cm) or kilograms (kg)
- `@Login` : The login for the user

### Example

An object has two different storage dimensions; User John Doe can add a weight to the Storage dimension in the 4 position, using:

```EXECUTE MLM_AddDimensionType_ByRank 'FURN.7A-B', 4, 'Weight', 34, 'john.doe'```

## MLM_ChangeDimensionElement
During data cleanup, it may be necessary to change the element of an existing dimension. There is no way to do this using the UI; the work around is either to recreate the dimension with the new element, or the script the change using SQL.

### Parameters

- `@ObjectNumber` : The unique Object Number for the record where the element is being changed
- `@OldElement` : The existing Dimension Element that needs to be changed
- `@NewElement` : The replacement Dimension Element
- `@Login` : The login for the user making the change, for use in the Audit Trail
- `@Description` *(optional)* : A new value for the Element Details description

This stored procedure will not work if an object has more than one dimension with the `@OldElement` value.

### Example

Someone used the overall element for an object's frame dimensions. User John Doe will correct the elements, using:

```EXECUTE MLM_ChangeDimensionElement '2020.1', 'Overall', 'Frame', 'john.doe'```
