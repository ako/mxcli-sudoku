# Create Entity

Create a new entity in the Mendix domain model using MDL.

## Usage

Describe the entity you want:
- Module name (use existing module or specify new one)
- Entity name
- Attributes with types and constraints
- Any associations to other entities

## Example Prompts

- "Create a Customer entity in Sales with Name, Email, and Phone"
- "Add a Product entity with SKU, Name, Price, and StockQuantity"
- "Create Order and OrderLine entities with an association between them"

## Notes

- Use the generate-domain-model skill for MDL syntax
- Run `mxcli check script.mdl` to validate before executing
- Entity positions are set with @Position(x, y) annotation
