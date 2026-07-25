# Create CRUD

Generate a complete CRUD (Create, Read, Update, Delete) setup for an entity.

## What Gets Created

1. **Entity** - Persistent entity with attributes
2. **Overview Page** - DataGrid listing all records with New/Edit/Delete buttons
3. **NewEdit Page** - Form for creating and editing records
4. **Navigation Snippet** (optional) - Reusable menu

## Usage

Specify:
- Module name
- Entity name and attributes
- Which pages to generate

## Example Prompts

- "Create CRUD for a Product entity in the Catalog module"
- "Generate overview and edit pages for the existing Customer entity"
- "Create a Task entity with Name, Description, DueDate, Status and full CRUD pages"

## Notes

- Uses overview-pages skill for page patterns
- Pages use Atlas_Core layouts (Atlas_Default for overview, PopupLayout for edit)
- Follow naming convention: Entity_Overview, Entity_NewEdit
