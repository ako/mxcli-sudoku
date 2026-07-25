# Explore Project

Explore and understand the Mendix project structure.

## Start Here: Project Structure Overview

All element names in the output are fully qualified (`Module.Element`). In VS Code terminals, these are **clickable links** — click any element name to open its MDL description.

```sql
-- Get a compact overview of the entire project (best first command)
SHOW STRUCTURE;

-- Module-level summary with element counts
SHOW STRUCTURE DEPTH 1;

-- Elements with signatures (default) — entities, microflows, pages, etc.
SHOW STRUCTURE DEPTH 2;

-- Full types and parameter names
SHOW STRUCTURE DEPTH 3;

-- Focus on a single module
SHOW STRUCTURE IN ModuleName;

-- Include system/marketplace modules
SHOW STRUCTURE DEPTH 1 ALL;
```

CLI equivalent:
```bash
mxcli structure -p app.mpr                  # depth 2 (default)
mxcli structure -p app.mpr -d 1             # counts only
mxcli structure -p app.mpr -d 3             # full types
mxcli structure -p app.mpr -m ModuleName    # single module
mxcli structure -p app.mpr -d 1 --all       # include system modules
```

## Quick Commands

```sql
-- List all modules
SHOW MODULES;

-- List entities in a module
SHOW ENTITIES IN ModuleName;

-- Show entity definition
DESCRIBE ENTITY Module.EntityName;

-- List microflows
SHOW MICROFLOWS IN ModuleName;

-- Show microflow logic
DESCRIBE MICROFLOW Module.MicroflowName;

-- List pages
SHOW PAGES IN ModuleName;

-- List workflows
SHOW WORKFLOWS IN ModuleName;

-- Show workflow definition
DESCRIBE WORKFLOW Module.WorkflowName;
```

## Catalog Queries

For more flexible searching, use catalog queries:

```sql
REFRESH CATALOG;

-- Find entities by name pattern
SELECT QualifiedName, AttributeCount
FROM CATALOG.ENTITIES
WHERE Name LIKE '%Customer%';

-- Find large microflows
SELECT QualifiedName, ActivityCount
FROM CATALOG.MICROFLOWS
WHERE ActivityCount > 10
ORDER BY ActivityCount DESC;
```

## Code Search Commands

For deeper code navigation (requires `REFRESH CATALOG FULL`). Like structure output, qualified names in the results are **clickable in VS Code terminals**.

```sql
REFRESH CATALOG FULL;

-- Find what calls a microflow
SHOW CALLERS OF Module.MyMicroflow;
SHOW CALLERS OF Module.MyMicroflow TRANSITIVE;

-- Find what a microflow calls
SHOW CALLEES OF Module.MyMicroflow;

-- Find all references to an element
SHOW REFERENCES TO Module.Customer;

-- Analyze impact of changes
SHOW IMPACT OF Module.Customer;

-- Get context for understanding code
SHOW CONTEXT OF Module.MyMicroflow DEPTH 2;

-- Full-text search across strings and source
SEARCH 'validation';
SEARCH 'Customer';
```

## Search with Unix Pipes

Use CLI with output formats for piping:

```bash
# Names format for piping (type<TAB>name per line)
mxcli search -p app.mpr "validation" -q --format names

# Describe first match
mxcli search -p app.mpr "error" -q --format names | head -1 | awk '{print $2}' | \
  xargs mxcli describe -p app.mpr microflow

# JSON format with jq
mxcli search -p app.mpr "Customer" -q --format json | jq -r '.[].qualifiedName'
```

## Available Catalog Tables

MODULES, ENTITIES, MICROFLOWS, NANOFLOWS, PAGES, SNIPPETS, ENUMERATIONS, WORKFLOWS, ACTIVITIES, WIDGETS, REFS, PERMISSIONS, STRINGS, SOURCE
