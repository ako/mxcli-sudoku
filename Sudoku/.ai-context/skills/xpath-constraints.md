# XPath Constraints in MDL

This skill provides reference for writing XPath constraint expressions in MDL RETRIEVE statements, page data sources, and security rules.

## When to Use This Skill

- Writing `retrieve ... where [xpath]` statements in microflows
- Writing `database from entity where [xpath]` in page data sources
- Writing `grant ... where 'xpath'` for row-level entity access
- Debugging XPath parsing or serialization issues

## XPath vs Mendix Expressions

**Critical distinction**: XPath constraints (inside `[...]`) use different syntax from Mendix expressions (in SET, IF, DECLARE, etc.):

| Feature | XPath `[...]` | Mendix Expression |
|---------|---------------|-------------------|
| Path separator | `/` (always path traversal) | `/` (also division) |
| Boolean ops | lowercase: `and`, `or`, `not()` | `and`, `or`, `not` |
| Negation | `not(expr)` function | `not expr` |
| Empty check | `= empty`, `!= empty` | `= empty` |
| Token quoting | `'[%CurrentUser%]'` (quoted) | `[%CurrentUser%]` (unquoted) |
| Nested filter | `Assoc/entity[pred]` | Not applicable |

## Syntax Reference

### Simple Comparisons

```mdl
retrieve $Orders from Module.Order
  where [State = 'Completed'];

retrieve $Active from Module.Customer
  where [IsActive = true];

retrieve $Recent from Module.Order
  where [OrderDate != empty];

retrieve $HighValue from Module.Order
  where [TotalAmount >= $MinAmount];
```

Operators: `=`, `!=`, `<`, `>`, `<=`, `>=`

> **Inline vs quoted form.** The inline bracket form `where [State = 'Completed']`
> is preferred. The quoted form — `where '[State = ''Completed'']'`, with internal
> single quotes doubled (`''`) — is also accepted for `retrieve` and datasource
> `where` clauses, and now stores the identical constraint (it un-escapes the `''`
> and strips the outer quotes). Don't double-bracket: write either `[...]` or
> `'[...]'`, not both.

### Boolean Logic

```mdl
-- AND
where [State = 'Completed' and IsPaid = true]

-- OR
where [State = 'Pending' or State = 'Processing']

-- Grouped
where [State = 'Completed' and ($IgnorePaid or IsPaid = true)]

-- NOT
where [not(IsPaid)]
where [not(contains(Name, 'demo'))]
```

### Association Path Traversal

Bare association paths (without `$variable` prefix) navigate through the domain model:

```mdl
-- Single-hop: filter by associated object
where [Module.Order_Customer = $Customer]

-- Multi-hop: traverse through associations
where [Module.Order_Customer/Module.Customer/Name = $CustomerName]

-- Existence check: has an associated object
where [Module.Order_Customer/Module.Customer]

-- Negated existence: has NO associated object
where [not(Module.Order_Customer/Module.Customer)]
```

**Rule**: Always use the fully qualified association name (`Module.AssociationName`).

### Variable Paths

```mdl
-- Compare attribute via variable path
where [Module.Assoc/Module.Entity/Name = $Variable/Name]

-- Variable on right side
where [Name = $currentObject/SearchString]
```

### Nested Predicates

Filter intermediate path steps with inline `[predicate]`:

```mdl
-- Only lines of completed orders
where [Module.OrderLine_Order/Module.Order[State = 'Completed']]

-- Nested predicate with further traversal
where [Module.OrderLine_Order/Module.Order[State = 'Active']/Module.Order_Category/Module.Category/Name = $CategoryName]

-- reversed() path modifier (traverse association in reverse direction)
where [System.grantableRoles[reversed()]/System.UserRole/System.UserRoles = '[%CurrentUser%]']
```

### Functions

```mdl
-- String search
where [contains(Name, $SearchStr)]
where [starts-with(Name, $Prefix)]
where [not(contains(Name, 'demo'))]

-- Boolean functions
where [IsActive = true()]
where [Displayed = false()]
```

Supported functions: `contains()`, `starts-with()`, `not()`, `true()`, `false()`

### Tokens

Mendix tokens provide runtime values. In an XPath constraint a token used as a
value is stored quoted as `'[%Token%]'` (Studio Pro requires this, or it reports
CE0161). mxcli quotes it for you whether you write the bare or quoted form:

```mdl
-- Both store identically as '[%CurrentDateTime%]' and pass mx check
where [OrderDate < [%CurrentDateTime%]]
where [OrderDate < '[%CurrentDateTime%]']
where [System.owner = '[%CurrentUser%]']
```

> **Tokens are typed.** `[%CurrentUser%]` is a **User** reference — compare it only
> to an association to System.User (e.g. `System.owner`), never to a String/other
> attribute (`[Title = '[%CurrentUser%]']` is a type error → CE0161).
> `[%CurrentDateTime%]` compares to DateTime attributes, etc.

> **`System.owner` / `System.changedBy` must be enabled** on the entity before you
> can reference them in XPath, or Studio Pro reports CE0161. Enable with
> `alter entity Module.Entity add attribute owner: autoowner;` (mxcli's
> `check --references` flags this). Same for `changedBy`/`changedDate`/`createdDate`.

Common tokens: `[%CurrentUser%]`, `[%CurrentDateTime%]`, `[%CurrentObject%]`, `[%UserRole_RoleName%]`, `[%DayLength%]`

### ID Pseudo-Attribute

The `id` pseudo-attribute compares object identity (GUID):

```mdl
where [id = $currentUser]
where [id != $existingObject]
where [id = '[%CurrentUser%]']
```

## Usage Contexts

### RETRIEVE in Microflows

```mdl
retrieve $Results from Module.Entity
  where [IsActive = true and State = 'Ready']
  sort by Name asc
  limit 100;
```

The expression inside `[...]` is parsed as XPath and stored in BSON as the `XpathConstraint` field.

### Page Data Sources

```mdl
datagrid dg (
  datasource: database from Module.Entity where [State != 'Cancelled'] sort by Name asc
) {
  column col1 (attribute: Name, caption: 'Name')
}
```

Multiple bracket constraints can be chained. Consecutive brackets without an operator are treated as AND (standard Mendix XPath):

```mdl
-- Consecutive brackets (implicit AND) — standard Mendix XPath syntax
datasource: database from Module.Entity where [IsActive = true][Stock > 0]

-- Explicit AND: same result
datasource: database from Module.Entity where [IsActive = true] and [Stock > 0]

-- Mix with OR: combines into single bracket
datasource: database from Module.Entity where [IsActive = true] or [Stock > 10]
```

### GRANT Entity Access (Security)

For security rules, XPath is passed as a **string literal** (not parsed):

```mdl
grant Module.Role on Module.Entity (
  read *,
  write *
) where '[System.owner = ''[%CurrentUser%]'']';
```

Note the double single-quotes for escaping inside the string literal.

## Enumeration Attributes

**Critical**: XPath constraints are translated to database SQL WHERE clauses at runtime. The database stores enum values as plain strings (the value key), not qualified names. This means:

- `[Status = 'Open']` — always valid: direct string literal match
- `[Status = Module.OrderStatus.Open]` — also valid: mxcli converts to `'Open'` in BSON automatically

Both forms are accepted by mxcli in the write direction. `DESCRIBE MICROFLOW` always shows the qualified name form for readability, even though BSON stores `'Open'`.

**Do NOT use qualified names in expression context (IF, SET, DECLARE) for comparisons** — those contexts use a different form. See `write-microflows.md` "Enumeration Comparisons" section.

```mdl
-- Preferred (mxcli converts to 'Open' in BSON):
retrieve $OpenOrders from Module.Order
  where [Status = Module.OrderStatus.Open];

-- Also accepted (stored as-is):
retrieve $OpenOrders from Module.Order
  where [Status = 'Open'];

-- NOT equal
retrieve $Active from Module.Order
  where [Status != Module.OrderStatus.Cancelled];

-- OR across multiple enum values
retrieve $InProgress from Module.Order
  where [Status = Module.OrderStatus.Open or Status = Module.OrderStatus.Processing];

-- Enum combined with other predicates
retrieve $Results from Module.Order
  where [Status = Module.OrderStatus.Completed and TotalAmount >= $MinAmount];
```

### Troubleshooting silent empty results with enums

If a RETRIEVE returns empty unexpectedly when filtering by an enum attribute:
1. Check the **value key** (not caption) — the key is what's stored in the DB column. Check with `DESCRIBE ENUMERATION Module.EnumName`.
2. Keys are **case-sensitive**: `'open'` ≠ `'Open'`.
3. Confirm the attribute type is actually an enumeration and not a string — `DESCRIBE ENTITY Module.EntityName`.

## Common Patterns

### Parameterized Search

```mdl
create microflow Module.Search ($query: string, $ActiveOnly: boolean)
returns boolean
begin
  retrieve $Results from Module.Customer
    where [($ActiveOnly = false or IsActive = true)
      and (contains(Name, $query) or contains(Email, $query))];
  return true;
end;
```

### Date Range Filter

```mdl
retrieve $Orders from Module.Order
  where [OrderDate >= $StartDate and OrderDate <= $EndDate];
```

### Optional Filters (empty = skip)

```mdl
retrieve $Orders from Module.Order
  where [($Category = empty or Module.Order_Category = $Category)
    and ($State = empty or State = $State)];
```

### Owner-Based Security

```mdl
-- In microflow
retrieve $MyItems from Module.Item
  where [System.owner = '[%CurrentUser%]'];

-- In security rule
grant Module.User on Module.Item (read all) where '[System.owner = ''[%CurrentUser%]'']';
```

## Validation

Always validate XPath syntax before execution:

```bash
# Syntax check (no project needed)
./bin/mxcli check script.mdl

# with reference validation (needs project)
./bin/mxcli check script.mdl -p app.mpr --references
```

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| `mismatched input` on keyword | Attribute name is a reserved word | This is handled — `xpathWord` accepts any keyword as identifier |
| Token not quoted in BSON | Token in Mendix expression context | Use `[...]` bracket syntax for XPath, not bare expression |
| `CE0111` path error | Missing module prefix on association | Use `Module.AssociationName`, not just `AssociationName` |
| `CE0161` XPath constraint error | Qualified name used for non-enum or wrong format | Use string literal `'Value'` or qualified name `Module.Enum.Value`; mxcli converts automatically |
| `not` parsed as keyword | Using `not` (uppercase) in XPath | XPath uses lowercase `not()` as a function |
| Retrieve returns empty for enum filter | String literal value key mismatch | Key is case-sensitive; verify with `DESCRIBE ENUMERATION Module.Name` |
