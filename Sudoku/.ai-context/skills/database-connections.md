# Skill: Create External Database Connections

## Purpose
Create and manage external database connections in Mendix using the External Database Connector. This skill helps you set up JDBC connections to external databases (Oracle, PostgreSQL, MySQL, SQL Server, etc.) and define SQL queries that map results to non-persistent entities.

## When to Use This Skill
- User asks to connect to an external database **from a Mendix app** (via JDBC)
- User needs to query data from Oracle, PostgreSQL, MySQL, SQL Server, or other JDBC databases
- User wants to create database connection configurations
- User needs to define SQL queries with parameter binding
- User wants to map query results to Mendix entities

> **Tip:** Use `generate connector` to auto-create all constants, entities, and queries from a database schema:
> ```
> SQL CONNECT postgres 'postgres://user:pass@host/db' AS source;
> SQL source GENERATE CONNECTOR INTO MyModule;
> -- Or generate for specific tables and execute immediately:
> SQL source GENERATE CONNECTOR INTO MyModule TABLES (employees, departments) EXEC;
> ```
> For manual exploration, use `sql source show tables;` and `sql source describe tablename;`.

## Prerequisites

### 1. Required Mendix Version
- Mendix 9.22+ (Database Connector introduced)
- Mendix 10.10+ (stable version recommended)

### 2. Required Non-Persistent Entities
Database query results must be mapped to NON-PERSISTENT entities. Create these first:

```sql
-- Entity to hold query results
create non-persistent entity MyModule.EmployeeRecord (
  EmployeeId: integer,
  EmployeeName: string(100),
  Department: string(50),
  Salary: decimal
);
```

### 3. Required Constants
Connection credentials should be stored in constants:

```sql
-- Connection string (JDBC URL)
create constant MyModule.DbConnectionString type string
  default 'jdbc:oracle:thin:@//hostname:1521/SERVICENAME'
  comment 'JDBC connection string for external database';

-- Username
create constant MyModule.DbUsername type string
  default 'app_user'
  comment 'Database username';

-- Password (use PRIVATE for local development)
create constant MyModule.DbPassword type string
  default ''
  comment 'Database password - inject via environment variable in production'
  PRIVATE;
```

## Database Connection Syntax

### Basic Connection Structure

```sql
create database connection Module.ConnectionName
type '<database-type>'
connection string @Module.ConnectionStringConstant
username @Module.UsernameConstant
password @Module.PasswordConstant
begin
  -- Query definitions go here
end;
```

### Supported Database Types

| Database | TYPE Value |
|----------|------------|
| Oracle | `'Oracle'` |
| PostgreSQL | `'PostgreSQL'` |
| MySQL | `'MySQL'` |
| SQL Server | `'MSSQL'` or `'SQLServer'` |
| Snowflake | `'Snowflake'` |
| Amazon Redshift | `'Redshift'` |

## Query Definition Syntax

### Simple Query (No Parameters)

```sql
query QueryName
  sql 'SELECT column1, column2 FROM table_name'
  returns Module.EntityName;
```

### Parameterized Query

```sql
query QueryName
  sql 'SELECT * FROM table_name WHERE column = {paramName}'
  parameter paramName: string
  returns Module.EntityName;
```

### Query with Column Mapping

When database column names don't match entity attribute names:

```sql
query QueryName
  sql 'SELECT emp_id, emp_name, dept_no FROM employees'
  returns Module.EmployeeRecord
  map (
    emp_id as EmployeeId,
    emp_name as EmployeeName,
    dept_no as DepartmentNumber
  );
```

### Supported Parameter Types

- `string` - Text values
- `integer` - Whole numbers
- `decimal` - Decimal numbers
- `boolean` - true/false
- `datetime` - Date and time values

### Parameter Test Values

Parameters can include a test value for Studio Pro testing, or indicate they should be tested with NULL:

```sql
-- Test value (used in Studio Pro's Execute Query dialog)
parameter empName: string default 'Smith'

-- Test with NULL value
parameter optionalDate: datetime null
```

## Complete Examples

### Example 1: Oracle HR Database Connection

```sql
-- Step 1: Create module
create module OracleDemo;

-- Step 2: Create constants for connection
create constant OracleDemo.OracleConnectionString type string
  default 'jdbc:oracle:thin:@//10.211.55.2:1522/ORCLPDB1';

create constant OracleDemo.OracleUser type string default 'scott';

create constant OracleDemo.OraclePassword type string default 'tiger' PRIVATE;

-- Step 3: Create non-persistent entity for results
create non-persistent entity OracleDemo.EmpRecord (
  EMPNO: decimal,
  ENAME: string(10),
  JOB: string(9),
  SAL: decimal,
  DEPTNO: decimal
);

-- Step 4: Create database connection
create database connection OracleDemo.HRDatabase
type 'Oracle'
connection string @OracleDemo.OracleConnectionString
username @OracleDemo.OracleUser
password @OracleDemo.OraclePassword
begin
  query GetAllEmployees
    sql 'SELECT EMPNO, ENAME, JOB, SAL, DEPTNO FROM EMP ORDER BY EMPNO'
    returns OracleDemo.EmpRecord;

  query GetEmployeeByName
    sql 'SELECT EMPNO, ENAME, JOB, SAL, DEPTNO FROM EMP WHERE ENAME = {empName}'
    parameter empName: string
    returns OracleDemo.EmpRecord;

  query GetHighEarners
    sql 'SELECT EMPNO, ENAME, JOB, SAL, DEPTNO FROM EMP WHERE SAL >= {minSalary}'
    parameter minSalary: decimal
    returns OracleDemo.EmpRecord;
end;
```

### Example 2: PostgreSQL Connection

```sql
create constant Inventory.PgConnectionString type string
  default 'jdbc:postgresql://localhost:5432/inventory_db';

create constant Inventory.PgUser type string default 'inventory_app';
create constant Inventory.PgPassword type string default '' PRIVATE;

create non-persistent entity Inventory.ProductRecord (
  ProductId: integer,
  ProductName: string(100),
  Quantity: integer,
  Price: decimal
);

create database connection Inventory.ProductDatabase
type 'PostgreSQL'
connection string @Inventory.PgConnectionString
username @Inventory.PgUser
password @Inventory.PgPassword
begin
  query GetAllProducts
    sql 'SELECT product_id, product_name, quantity, price FROM products'
    returns Inventory.ProductRecord
    map (
      product_id as ProductId,
      product_name as ProductName,
      quantity as Quantity,
      price as Price
    );

  query SearchProducts
    sql 'SELECT product_id, product_name, quantity, price FROM products WHERE product_name ILIKE {searchPattern}'
    parameter searchPattern: string
    returns Inventory.ProductRecord
    map (
      product_id as ProductId,
      product_name as ProductName,
      quantity as Quantity,
      price as Price
    );
end;
```

## Viewing Connections

```sql
-- List all database connections
show database connections;

-- List connections in a specific module
show database connections in MyModule;

-- View connection source code
describe database connection MyModule.MyDatabase;
```

## Best Practices

### 1. Connection String Management
- Store JDBC URLs in constants for environment-specific overrides
- Use `MX_Module_ConstantName` environment variables in production

### 2. Credential Security
- Use `PRIVATE` flag for password constants during development
- Never commit real passwords to version control
- Inject credentials via CI/CD pipelines in production

### 3. Entity Design
- Use NON-PERSISTENT entities for query results
- Match attribute types to database column types
- Use MAP clause when column names differ from attribute names

### 4. Query Design
- Use parameterized queries to prevent SQL injection
- Keep queries simple and focused
- Create separate queries for different use cases

## Troubleshooting

### Connection Issues
1. Verify JDBC URL format for your database type
2. Check network connectivity to database host
3. Verify credentials are correct
4. Ensure JDBC driver is available

### Query Issues
1. Test queries directly in database client first
2. Check parameter types match expected database types
3. Verify entity attributes match query result columns
4. Use MAP clause for column name mismatches

## Related Commands

```sql
-- Constants for configuration
create constant Module.Name type string default 'value';
show constants in module;

-- Non-persistent entities for results
create non-persistent entity Module.Name (...);
show entities in module;
```

## Executing Queries from Microflows

Once a database connection and queries are defined, execute them from microflows using `execute database query`. The query is referenced by its **3-part qualified name**: `Module.Connection.Query`.

### Basic Syntax

```sql
-- Execute a query and store results
$ResultList = execute database query Module.Connection.QueryName;

-- Fire-and-forget (no output variable)
execute database query Module.Connection.QueryName;
```

### Dynamic SQL Override

Override the query's SQL at runtime using `dynamic`:

```sql
$ResultList = execute database query Module.Connection.QueryName
  dynamic 'SELECT id, name FROM employees WHERE active = true LIMIT 10';
```

### Parameterized Queries

Pass values for query parameters defined with `parameter` in the query definition:

```sql
-- Query definition (in DATABASE CONNECTION block):
--   QUERY GetDriversByNationality
--     SQL 'SELECT * FROM drivers WHERE nationality = {nation}'
--     PARAMETER nation: String
--     RETURNS Module.DriverRecord;

-- Microflow execution:
$Drivers = execute database query Module.Connection.GetDriversByNationality
  (nation = $NationalityVar);
```

**CRITICAL**: Parameter names must exactly match those in the query definition (e.g., `nation`, not `nationality`). Mismatched names cause Studio Pro to regenerate mappings and clear values.

### Runtime Connection Override

Override connection parameters at runtime using `connection`. Use case: multiple databases with the same schema but different data (e.g., region-specific databases).

```sql
$Results = execute database query Module.Connection.QueryName
  connection (DBSource = $url, DBUsername = $user, DBPassword = $Pass);
```

**Caveat**: ConnectionParameterMappings require the database connection to have been tested/validated in Studio Pro first. Creating them programmatically may trigger "parameters have been updated" on first open.

### Error Handling

`execute database query` only supports `on error rollback` (the default). `on error continue` is **not supported** for this action type.

### Complete Example

```sql
-- Set up non-persistent entity, constants, and connection
create non-persistent entity HR.EmployeeRecord (
  EmpId: integer,
  Name: string(100),
  Department: string(50)
);

create constant HR.DbUrl type string default 'jdbc:postgresql://localhost:5432/hrdb';
create constant HR.DbUser type string default 'app';
create constant HR.DbPass type string default '' PRIVATE;

create database connection HR.MainDB
type 'PostgreSQL'
connection string @HR.DbUrl
username @HR.DbUser
password @HR.DbPass
begin
  query GetAllEmployees
    sql 'SELECT emp_id, name, department FROM employees'
    returns HR.EmployeeRecord
    map (emp_id as EmpId, name as Name, department as Department);

  query GetByDepartment
    sql 'SELECT emp_id, name, department FROM employees WHERE department = {dept}'
    parameter dept: string
    returns HR.EmployeeRecord
    map (emp_id as EmpId, name as Name, department as Department);
end;

-- Microflow that executes the query
create microflow HR.ACT_LoadEmployees($Department: string)
returns list of HR.EmployeeRecord as $Employees
begin
  $Employees = execute database query HR.MainDB.GetByDepartment
    (dept = $Department);
  return $Employees;
end;
```

## Importing Data from External Databases

To bulk-import data from an external database directly into the Mendix app's PostgreSQL
database (bypassing the runtime), use `import from` instead of the Database Connector:

```sql
sql connect postgres 'postgres://user:pass@host:5432/legacydb' as source;
import from source query 'SELECT name, email FROM employees'
  into HRModule.Employee
  map (name as Name, email as Email);
```

See [demo-data.md](./demo-data.md) for details on the Mendix ID system and manual insertion.

## References

- [Mendix External Database Connector](https://docs.mendix.com/appstore/modules/external-database-connector/)
- [JDBC Connection Strings](https://docs.mendix.com/appstore/modules/external-database-connector/#connection-details)
