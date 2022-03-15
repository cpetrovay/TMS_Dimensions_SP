# Stored Procedures for TMS: Object Dimensions

A Stored Procedure to manage object dimensions in TMS on SQL Server
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
