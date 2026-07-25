# Skill: Write OQL Queries for Mendix VIEW Entities

## Purpose
Generate correct OQL (Object Query Language) queries for Mendix VIEW entities. This skill helps you create VIEW entities with proper OQL syntax that will execute successfully in Mendix runtime.

## When to Use This Skill
- User asks to create a VIEW entity
- User requests help with OQL queries
- User wants to create analytics, reports, or aggregated data views
- User needs to join entities or create calculated fields
- You encounter OQL syntax errors when creating VIEW entities

## Critical OQL Syntax Rules

### 0. VIEW Entity Best Practices (CRITICAL)

**RULE 1: All SELECT columns MUST have explicit AS aliases**

Every column in the SELECT clause must have an alias that matches the entity attribute name:

```sql
-- ❌ WRONG - Missing aliases
create view entity Finance.CashFlowProjection (
  ProjectionDate: datetime,
  ProjectedIncome: decimal,
  ProjectedExpense: decimal
) as (
  select
    fl.ForecastDate,              -- Missing AS alias
    fl.ProjectedIncome,           -- Missing AS alias
    fl.ProjectedExpense           -- Missing AS alias
  from Finance.ForecastLine as fl
);

-- ✅ CORRECT - All columns have explicit aliases
create view entity Finance.CashFlowProjection (
  ProjectionDate: datetime,
  ProjectedIncome: decimal,
  ProjectedExpense: decimal
) as (
  select
    fl.ForecastDate as ProjectionDate,
    fl.ProjectedIncome as ProjectedIncome,
    fl.ProjectedExpense as ProjectedExpense
  from Finance.ForecastLine as fl
);
```

**RULE 2: NEVER use ORDER BY or LIMIT in VIEW entity OQL**

The UI component or microflow using the view will handle sorting and pagination:

```sql
-- ❌ WRONG - Hardcoded sorting and limits
create view entity Finance.TopCustomers (...) as (
  select c.Name as CustomerName, sum(o.Amount) as TotalSpent
  from Finance.Customer as c
  inner join Finance.Order_Customer/Finance.Order as o
  GROUP by c.Name
  ORDER by TotalSpent desc        -- Remove this
  limit 100                       -- Remove this
);

-- ✅ CORRECT - No ORDER BY or LIMIT
create view entity Finance.TopCustomers (...) as (
  select c.Name as CustomerName, sum(o.Amount) as TotalSpent
  from Finance.Customer as c
  inner join Finance.Order_Customer/Finance.Order as o
  GROUP by c.Name
  -- Let the UI component handle sorting and limits
);
```

**Why these rules matter:**
- **Explicit aliases**: Required for proper OQL-to-entity attribute mapping in Mendix
- **No ORDER BY/LIMIT**: Provides flexibility - different pages/microflows can sort and paginate the same view differently

### 1. Aggregate Functions (MUST BE LOWERCASE)
```sql
-- ❌ WRONG - Uppercase will fail
sum(o.Amount)
avg(o.Amount)
max(o.OrderDate)
min(o.Amount)

-- ✅ CORRECT - Lowercase
sum(o.Amount)
avg(o.Amount)
max(o.OrderDate)
min(o.Amount)
```

### 2. COUNT Function
```sql
-- ❌ WRONG - count(*) not supported in Mendix OQL
count(*)

-- ✅ CORRECT - Count by ID or entity
count(t.ID)           -- Count by ID attribute
count(t)              -- Count entity instances
```

### Aggregate Function Return Types

| Function | Input Type | Returns | MDL Declaration |
|----------|-----------|---------|-----------------|
| `count(expr)` | any | Integer | `attr: integer` |
| `sum(expr)` | Integer | Integer | `attr: integer` |
| `sum(expr)` | Decimal | Decimal | `attr: decimal` |
| `avg(expr)` | any numeric | Decimal | `attr: decimal` |
| `max(expr)` / `min(expr)` | Integer | Integer | `attr: integer` |
| `max(expr)` / `min(expr)` | Decimal | Decimal | `attr: decimal` |
| `max(expr)` / `min(expr)` | DateTime | DateTime | `attr: datetime` |
| `datepart(part, expr)` | DateTime | Integer | `attr: integer` |
| `length(expr)` | String | Integer | `attr: integer` |

**Key rule**: `count()` and `avg()` have fixed return types. `sum()`, `min()`, `max()` preserve the input type.

### 3. DATEPART Function (Comma Syntax)
```sql
-- ✅ CORRECT - Use comma syntax
datepart(YEAR, t.TransactionDate)
datepart(MONTH, t.TransactionDate)
datepart(QUARTER, t.TransactionDate)
datepart(WEEK, t.TransactionDate)
datepart(DAY, t.TransactionDate)

-- ❌ WRONG - FROM syntax not supported
DATEPART(YEAR from t.TransactionDate)
```

### 4. Enumeration Comparisons (String Literals)
```sql
-- ❌ WRONG - Qualified enum names
t.TransactionType = Finance.TransactionType.INCOME
t.Status != Finance.TransactionStatus.VOID

-- ✅ CORRECT - Use string literals
t.TransactionType = 'INCOME'
t.Status != 'VOID'
```

### 5. Division Operator (Colon, not Slash)
```sql
-- ❌ WRONG - Using / causes parsing errors
select amount / quantity as price
select (total - discount) * 100.0 / total as percentage

-- ✅ CORRECT - Use : for division
select amount : quantity as price
select (total - discount) * 100.0 : total as percentage
```

### 6. ORDER BY with Aliases
```sql
-- ❌ WRONG - Using expressions in ORDER BY
ORDER by datepart(YEAR, t.TransactionDate) desc

-- ✅ CORRECT - Use column aliases
select
  datepart(YEAR, t.TransactionDate) as OrderYear
from Finance.Transaction as t
ORDER by OrderYear desc
```

### 7. Operators (Use != not <>)
```sql
-- ❌ WRONG - <> causes errors in Mendix
where t.Status <> 'VOIDED'

-- ✅ CORRECT - Use !=
where t.Status != 'VOIDED'
```

**Note:** Both `!=` and `<>` are valid in standard SQL, but Mendix OQL only accepts `!=`.

### 8. IN Expression Syntax
```sql
-- ✅ IN with value list
where t.Status in ('ACTIVE', 'PENDING', 'REVIEW')

-- ✅ IN with subquery
where t.CustomerId in (
  select c.CustomerId from Shop.Customer as c where c.IsVIP = true
)

-- ✅ Enumeration values use identifiers, not captions
where t.Priority in ('HIGH', 'CRITICAL')  -- Not 'High', 'Critical'
```

### 9. Subqueries (Scalar and Correlated)
```sql
-- ✅ Scalar subquery in SELECT (returns single value)
select
  p.Name as ProductName,
  p.Price - (select avg(p2.Price) from Shop.Product as p2) as DiffFromAvg
from Shop.Product as p

-- ✅ Scalar subquery in WHERE
where p.Price > (select avg(p2.Price) from Shop.Product as p2)

-- ✅ Correlated subquery (references outer query by attribute)
select
  o.OrderNumber as OrderNumber,
  (select count(o2.OrderId) from Shop.Order as o2 where o2.CustomerId = o.CustomerId) as CustomerOrderCount
from Shop.Order as o

-- ✅ Correlated subquery via association (compare to .ID)
select
  p.Name as ProductName,
  (select pr.PriceInEuro from Shop.Price as pr
   where pr/Shop.Price_Product = p.ID
   ORDER by pr.StartDate desc limit 1) as LatestPrice
from Shop.Product as p

-- ❌ WRONG - bare alias without .ID
where pr/Shop.Price_Product = p    -- Doesn't resolve

-- ✅ CORRECT - compare to entity .ID
where pr/Shop.Price_Product = p.ID
```

### 10. Association Path Syntax
```sql
-- Association paths in OQL use '/' not '.'
-- ✅ CORRECT - slash prefix for association traversal
where l/Library.Loan_Member = m.ID
join l/Library.Loan_Book/Library.Book as b

-- ❌ WRONG - dot instead of slash
where l.Library.Loan_Member = m.ID     -- Error: does not resolve
```

### 11. JOIN Syntax (Association Traversal and ON Clause)

Mendix OQL supports both association traversal and SQL-style JOIN ON:

```sql
-- ✅ Association traversal (uses Mendix association path)
from Shop.Order as o
inner join o/Shop.Order_Customer/Shop.Customer as c

-- ✅ JOIN ON clause (SQL-style, for any condition)
from Shop.Order as o
inner join Shop.Customer as c on o.CustomerId = c.CustomerId

-- ✅ LEFT OUTER JOIN with ON clause
from Shop.Product as p
left outer join Shop.CompetitorProduct as cp on p.ProductCode = cp.ProductCode
```

**When to use each approach:**
- **Association traversal** (`alias/Module.Association/entity`): When joining on a Mendix-defined association
- **JOIN ON** (`join entity on condition`): When joining on arbitrary conditions or non-association fields

## Common OQL Patterns

### Pattern 1: Date-based Aggregation
```sql
create view entity Finance.MonthlySummary (
  Year: integer,
  Month: integer,
  TotalAmount: decimal,
  TransactionCount: integer
) as (
  select
    datepart(YEAR, t.Date) as Year,
    datepart(MONTH, t.Date) as Month,
    sum(t.Amount) as TotalAmount,
    count(t.ID) as TransactionCount
  from Finance.Transaction as t
  where t.Status != 'VOIDED'
  GROUP by datepart(YEAR, t.Date), datepart(MONTH, t.Date)
);
```

### Pattern 2: Conditional Aggregation
```sql
create view entity Finance.CategorySummary (
  Category: string(200),
  Income: decimal,
  Expense: decimal,
  Net: decimal
) as (
  select
    c.Name as Category,
    sum(case when t.Type = 'INCOME' then t.Amount else 0 end) as Income,
    sum(case when t.Type = 'EXPENSE' then t.Amount else 0 end) as Expense,
    sum(case when t.Type = 'INCOME' then t.Amount
             when t.Type = 'EXPENSE' then -t.Amount else 0 end) as Net
  from Finance.Transaction as t
  inner join Finance.Transaction_Category/Finance.Category as c
  GROUP by c.Name
);
```

### Pattern 3: Association Navigation
```sql
create view entity Shop.OrderDetails (
  OrderId: long,
  CustomerName: string(400),
  TotalItems: integer,
  TotalPrice: decimal
) as (
  select
    o.OrderId as OrderId,
    c.FirstName + ' ' + c.LastName as CustomerName,
    count(ol.OrderLineId) as TotalItems,
    o.TotalPrice as TotalPrice
  from Shop.CustomerOrder as o
  inner join Shop.Order_Customer/Shop.Customer as c
  left join Shop.OrderLine_Order/Shop.OrderLine as ol
  GROUP by o.OrderId, o.TotalPrice, c.FirstName, c.LastName
);
```

### Pattern 4: Calculations with Division
```sql
create view entity Finance.BudgetVariance (
  Category: string(200),
  Budget: decimal,
  Actual: decimal,
  Variance: decimal,
  VariancePercent: decimal
) as (
  select
    c.Name as Category,
    bl.PlannedAmount as Budget,
    bl.ActualAmount as Actual,
    bl.ActualAmount - bl.PlannedAmount as Variance,
    (bl.ActualAmount - bl.PlannedAmount) * 100.0 : bl.PlannedAmount as VariancePercent
  from Finance.BudgetLine as bl
  inner join Finance.BudgetLine_Category/Finance.Category as c
  where bl.PlannedAmount > 0
);
```

### Pattern 5: IN Expression with Value List
```sql
create view entity Shop.HighPriorityTasks (
  TaskId: integer,
  TaskTitle: string(200),
  Priority: string(50)
) as (
  select
    t.TaskId as TaskId,
    t.TaskTitle as TaskTitle,
    t.TaskPriority as Priority
  from Shop.Task as t
  where t.TaskPriority in ('HIGH', 'CRITICAL')
);
```

### Pattern 6: IN Expression with Subquery
```sql
create view entity Shop.CustomersWithOrders (
  CustomerId: integer,
  CustomerName: string(200)
) as (
  select
    c.CustomerId as CustomerId,
    c.Name as CustomerName
  from Shop.Customer as c
  where c.CustomerId in (
    select distinct o.CustomerId
    from Shop.Order as o
    where o.Status = 'COMPLETED'
  )
);
```

### Pattern 7: Scalar Subquery in SELECT
```sql
create view entity Shop.ProductsAboveAverage (
  ProductId: integer,
  Name: string(200),
  Price: decimal,
  PriceDifferenceFromAvg: decimal
) as (
  select
    p.ProductId as ProductId,
    p.Name as Name,
    p.Price as Price,
    p.Price - (select avg(p2.Price) from Shop.Product as p2) as PriceDifferenceFromAvg
  from Shop.Product as p
  where p.Price > (select avg(p3.Price) from Shop.Product as p3)
);
```

### Pattern 8: Correlated Subquery
```sql
create view entity Shop.OrdersWithCustomerStats (
  OrderId: integer,
  OrderNumber: string(50),
  CustomerTotalOrders: integer,
  CustomerTotalSpend: decimal
) as (
  select
    o.OrderId as OrderId,
    o.OrderNumber as OrderNumber,
    (select count(o2.OrderId) from Shop.Order as o2 where o2.CustomerId = o.CustomerId) as CustomerTotalOrders,
    (select sum(o3.TotalAmount) from Shop.Order as o3 where o3.CustomerId = o.CustomerId) as CustomerTotalSpend
  from Shop.Order as o
);
```

### Pattern 9: Correlated Subquery via Association
```sql
-- Get the latest price for each product using association traversal
create view entity Shop.ProductCurrentPrice (
  ProductId: string(50),
  Name: string(200),
  PriceInEuro: decimal,
  IsActive: boolean
) as (
  select
    p.ProductId as ProductId,
    p.Name as Name,
    (select pr.PriceInEuro
     from Shop.Price as pr
     where pr.StartDate <= '[%BeginOfTomorrow%]'
     and pr/Shop.Price_Product = p.ID
     ORDER by pr.StartDate desc
     limit 1) as PriceInEuro,
    p.IsActive as IsActive
  from Shop.Product as p
  where p.IsActive
);
```

**Key points:**
- Use `pr/Shop.Price_Product = p.ID` (association path with `.ID`)
- Never use bare alias: `pr/Shop.Price_Product = p` will fail
- ORDER BY and LIMIT are valid inside correlated subqueries (just not at the view level)

### Pattern 10: JOIN with ON Clause (Non-Association)
```sql
-- When joining on arbitrary conditions (not Mendix associations)
create view entity Shop.ProductComparison (
  ProductId: integer,
  ProductName: string(200),
  CompetitorPrice: decimal
) as (
  select
    p.ProductId as ProductId,
    p.Name as ProductName,
    cp.Price as CompetitorPrice
  from Shop.Product as p
  left join Shop.CompetitorProduct as cp on p.ProductCode = cp.ProductCode
  where cp.CompetitorName = 'ACME'
);
```

## Step-by-Step Process

### Step 1: Define VIEW Entity Schema

**Always include @Position annotation:**

```sql
/**
 * View entity description
 *
 * @since 1.0.0
 */
@position(300, 500)
create view entity Module.ViewName (
  Attribute1: type,
  Attribute2: type,
  -- ... more attributes
) as (
  -- OQL query goes here
);
```

### Step 2: Write SELECT Clause
- Use **lowercase** aggregate functions: `sum()`, `avg()`, `count()`
- Use `count(entity.ID)` not `count(*)`
- Create meaningful aliases for all columns
- Use `:` for division operations

### Step 3: Write FROM Clause
- Use table aliases (AS t, AS c, etc.)
- Navigate associations: `Entity_Association/TargetEntity`

### Step 4: Add JOINs if Needed
```sql
-- Association join syntax
inner join Shop.Order_Customer/Shop.Customer as c
left join Shop.Product_Category/Shop.Category as cat
```

### Step 5: Add WHERE Clause
- Use string literals for enum comparisons: `'value'`
- Use standard comparison operators: `=`, `!=`, `>`, `<`, `>=`, `<=`

### Step 6: Add GROUP BY if Using Aggregates
- Include all non-aggregated columns
- Use same expressions as SELECT (e.g., `datepart()`)

### Step 7: Verify Aliases
- Ensure ALL SELECT columns have explicit AS aliases
- Aliases must match entity attribute names exactly

### Step 8: Validate Before Executing
```bash
mxcli check view.mdl -p app.mpr --references
```
This catches type mismatches (e.g., declaring `long` for a `count()` column that returns `integer`), missing module references, and OQL syntax errors — before they become MxBuild errors like CE6770 ("View Entity is out of sync with the OQL Query").

### Step 9: Final Check
- Remove any ORDER BY, LIMIT, or OFFSET clauses
- These should be handled by the UI component or microflow

## Common Mistakes to Avoid

### ❌ Mistake 1: Uppercase Aggregates
```sql
-- WRONG
select sum(amount) from ...

-- CORRECT
select sum(amount) from ...
```

### ❌ Mistake 2: Using count(*)
```sql
-- WRONG
select count(*) from Finance.Transaction

-- CORRECT
select count(t.ID) from Finance.Transaction as t
```

### ❌ Mistake 3: Qualified Enum Names
```sql
-- WRONG
where t.Status = Finance.Status.ACTIVE

-- CORRECT
where t.Status = 'ACTIVE'
```

### ❌ Mistake 4: Slash for Division
```sql
-- WRONG
select total / count as average

-- CORRECT
select total : count as average
```

### ❌ Mistake 5: Missing Column Aliases
```sql
-- WRONG
select
  fl.ForecastDate,
  fl.ProjectedIncome
from Finance.ForecastLine as fl

-- CORRECT
select
  fl.ForecastDate as ProjectionDate,
  fl.ProjectedIncome as ProjectedIncome
from Finance.ForecastLine as fl
```

### ❌ Mistake 6: Dot Instead of Slash for Association Paths
```sql
-- WRONG - dot notation for association
where l.Library.Loan_Member = m.ID

-- CORRECT - slash notation
where l/Library.Loan_Member = m.ID
```

### ❌ Mistake 7: Bare Alias in Association Comparison
```sql
-- WRONG - comparing association to bare entity alias
where pr/Shop.Price_Product = p

-- CORRECT - compare to entity .ID
where pr/Shop.Price_Product = p.ID
```

### ❌ Mistake 8: Using ORDER BY or LIMIT in VIEW
```sql
-- WRONG - Hardcoded in view
create view entity Finance.TopItems (...) as (
  select ...
  ORDER by Amount desc
  limit 100
);

-- CORRECT - Let UI handle it
create view entity Finance.TopItems (...) as (
  select ...
  -- No ORDER BY or LIMIT
);
```

## Complete Example

### User Request
"Create a VIEW entity showing monthly revenue with order statistics"

### Response
```sql
/**
 * Monthly revenue summary with order statistics
 *
 * Time-series view of revenue and order metrics
 * aggregated by month and year.
 *
 * @since 1.0.0
 * @see Shop.CustomerOrder
 */
@position(1400, 450)
create view entity Shop.MonthlyRevenue (
  Year: integer,
  Month: integer,
  TotalOrders: integer,
  TotalRevenue: decimal,
  AverageOrderValue: decimal
) as (
  select
    datepart(YEAR, o.OrderDate) as Year,
    datepart(MONTH, o.OrderDate) as Month,
    count(o.OrderId) as TotalOrders,
    sum(o.TotalPrice) as TotalRevenue,
    avg(o.TotalPrice) as AverageOrderValue
  from Shop.CustomerOrder as o
  GROUP by datepart(YEAR, o.OrderDate), datepart(MONTH, o.OrderDate)
);
```

### Why This Works
1. ✅ All columns have explicit AS aliases
2. ✅ Lowercase aggregates: `sum()`, `avg()`, `count()`
3. ✅ Proper COUNT: `count(o.OrderId)` not `count(*)`
4. ✅ Comma syntax for DATEPART: `datepart(YEAR, o.OrderDate)`
5. ✅ GROUP BY matches SELECT non-aggregated expressions
6. ✅ No ORDER BY or LIMIT (UI will handle sorting)

## Testing OQL Queries

Use `mxcli oql` to test queries against a running Mendix runtime (read-only preview mode):

```bash
# basic query (reads .docker/.env for connection settings)
mxcli oql -p app.mpr "select Name, Email from MyModule.Customer"

# json output for piping to jq
mxcli oql -p app.mpr --json "SELECT count(c.ID) FROM MyModule.Order AS c" | jq '.[0]'

# Explicit connection (no project file needed)
mxcli oql --host localhost --port 8090 --token 'AdminPassword1!' "SELECT 1"

# Test a view entity query before embedding it
mxcli oql -p app.mpr "select datepart(YEAR, o.OrderDate) as Year, sum(o.Total) as Revenue from Sales.Order as o GROUP by datepart(YEAR, o.OrderDate)"
```

The app must be running first: `mxcli docker run -p app.mpr --wait`

> **Troubleshooting**: If you get "Action not found: preview_execute_oql", the Docker stack
> needs the `-Dmendix.live-preview=enabled` JVM flag. Re-initialize with:
> `mxcli docker init -p app.mpr --force`, then restart with `mxcli docker run -p app.mpr --wait`.

### Workflow: OQL → VIEW ENTITY

1. **Write and test interactively**: `mxcli oql -p app.mpr "select ..."`
2. **Iterate** until the query returns expected results
3. **Embed** in a VIEW ENTITY with matching column aliases and attribute types
4. **Validate before executing**: `mxcli check view.mdl -p app.mpr --references` to catch type mismatches (e.g., `long` vs `integer` for `count()`)
5. **Apply and rebuild**: `mxcli exec view.mdl -p app.mpr && mxcli docker run -p app.mpr --fresh --wait`

## Integration with MDL Linter

The MDL linter checks for common OQL issues:

**Rule: `consistency/oql-syntax`**
- Validates VIEW entity OQL queries
- Checks for ORDER BY without LIMIT/OFFSET (CE0174)
- Checks for missing/empty SELECT or FROM clauses

**How to Fix Linter Errors:**
```bash
# lint a file
mendix> lint file 'path/to/file.mdl';

# Common error: ORDER by without limit
# error: view entity X: ORDER by requires limit or OFFSET. Studio Pro error: CE0174
# Fix: add limit clause
```

## References

- [Mendix OQL Documentation](https://docs.mendix.com/refguide/oql/)
- [OQL Expressions](https://docs.mendix.com/refguide/oql-expressions/)
- [OQL Functions](https://docs.mendix.com/refguide/oql-expression-syntax/)
- Internal: `packages/mendix-repl/docs/syntax-proposals/OQL_SYNTAX_GUIDE.md`
- Internal: `packages/mendix-repl/examples/VIEW_ENTITY_VALIDATION.md`

## Summary Checklist

When writing OQL queries for VIEW entities, always verify:

- [ ] **CRITICAL**: Entity has @Position annotation (e.g., @Position(300, 500))
- [ ] **CRITICAL**: All SELECT columns have explicit AS aliases matching entity attributes
- [ ] **CRITICAL**: No ORDER BY, LIMIT, or OFFSET clauses (let UI handle sorting)
- [ ] Aggregate functions are lowercase (`sum`, `avg`, `count`, `max`, `min`)
- [ ] Using `count(entity.ID)` not `count(*)`
- [ ] DATEPART uses comma syntax: `datepart(YEAR, field)`
- [ ] Enum comparisons use enumeration **identifiers**, not captions: `'HIGH'` not `'High'`
- [ ] IN expressions use correct syntax: `in ('VAL1', 'VAL2')` or `in (select ...)`
- [ ] Division uses colon: `amount : quantity`
- [ ] Inequality uses `!=` not `<>`
- [ ] All non-aggregated columns are in GROUP BY
- [ ] Association paths use `/` not `.`: `alias/Module.Assoc` not `alias.Module.Assoc`
- [ ] Association comparisons use `.ID`: `pr/Shop.Price_Product = p.ID` not `= p`
- [ ] Association navigation uses correct syntax: `Entity_Assoc/Target as alias`
- [ ] JOIN ON clauses use comparison operators: `on a.Field = b.Field`
- [ ] Subqueries are enclosed in parentheses and return appropriate values
- [ ] **Validate before executing**: Run `mxcli check script.mdl -p app.mpr --references` to catch type mismatches

Following these rules ensures your OQL queries will parse and execute correctly in Mendix runtime.
