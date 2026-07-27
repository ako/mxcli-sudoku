# Test Microflows Skill

This skill guides you through writing and running MDL-based microflow tests using `mxcli test`.

## When to Use This Skill

Use this when:
- The user asks to test microflow logic (not UI/pages)
- The user wants to verify that microflows return correct values
- The user wants to validate entity creation, updates, or control flow
- You have generated MDL microflows and want to verify they work at runtime
- The user asks for unit tests or integration tests on business logic

For **UI/page testing** (widget rendering, form interactions, browser tests), see the `test-app` skill instead.

## Prerequisites

- Mendix project with microflows to test
- Docker stack initialized: `mxcli docker init -p app.mpr`
- App buildable: `mxcli docker build -p app.mpr`

---

## Test File Formats

### `.test.mdl` — Pure MDL Tests

Test blocks separated by `/`, each with a javadoc comment containing test annotations:

```sql
/**
 * @test String concatenation
 * @expect $result = 'John Doe'
 */
$result = call microflow MyModule.ConcatNames(
  FirstName = 'John', LastName = 'Doe'
);
/

/**
 * @test Arithmetic operation
 * @expect $result = 50
 */
$result = call microflow MyModule.Multiply(A = 10, B = 5);
/
```

### `.test.md` — Markdown Specification

Tests embedded in documentation as `mdl-test` fenced code blocks:

~~~markdown
# MyModule Specification

## string Operations

The ConcatNames microflow joins first and last name.

```mdl-test
/** @expect $result = 'John Doe' */
$result = call microflow MyModule.ConcatNames(
  FirstName = 'John', LastName = 'Doe'
);
```
~~~

The markdown format turns your tests into living documentation.

---

## Annotations

| Tag | Purpose | Example |
|-----|---------|---------|
| `@test` | Test name (required) | `@test string concatenation` |
| `@expect` | Assert variable value | `@expect $result = 'John Doe'` |
| `@expect` | Assert entity attribute | `@expect $product/Name = 'TestProduct'` |
| `@verify` | OQL post-condition | `@verify select count(*) from Mod.E where Code = 'X' = 1` |
| `@throws` | Expect error | `@throws 'validation failed'` |
| `@cleanup` | Rollback strategy | `@cleanup rollback` (default) or `@cleanup none` |

---

## Running Tests

```bash
# run tests from a file
mxcli test tests/microflows.test.mdl -p app.mpr

# run all tests in a directory
mxcli test tests/ -p app.mpr

# list tests without executing
mxcli test tests/ -p app.mpr --list

# Output JUnit xml for CI
mxcli test tests/ -p app.mpr --junit results.xml

# Skip build (reuse existing deployment)
mxcli test tests/ -p app.mpr --skip-build

# Verbose output (show all runtime logs)
mxcli test tests/ -p app.mpr --verbose
```

---

## How It Works

The test runner uses the **after-startup microflow** pattern:

1. Parses test files and extracts test blocks with annotations
2. Generates a `MxTest.TestRunner` microflow with assertion logic
3. Sets security OFF and after-startup to `MxTest.TestRunner`
4. Builds the project and restarts the Docker runtime
5. Captures structured `MXTEST:` log lines for pass/fail
6. Restores original security and after-startup settings
7. Outputs results (console, JUnit XML)

---

## Writing Good Tests

### Test a Single Behavior

Each test block should test one thing:

```sql
/**
 * @test Discount applied for orders over 100
 * @expect $result = 90.0
 */
$result = call microflow Sales.CalculateDiscount(OrderTotal = 100.0);
/
```

### Test Multiple Scenarios

Use separate blocks for different input values:

```sql
/**
 * @test Negative value returns 'negative'
 * @expect $result = 'negative'
 */
$result = call microflow MyModule.Classify(value = -5);
/

/**
 * @test Zero returns 'zero'
 * @expect $result = 'zero'
 */
$result = call microflow MyModule.Classify(value = 0);
/

/**
 * @test Positive value returns 'positive'
 * @expect $result = 'positive'
 */
$result = call microflow MyModule.Classify(value = 42);
/
```

### Test Entity Operations

Tests can create, modify, and verify entities:

```sql
/**
 * @test Create and update product
 * @expect $updated = true
 */
$product = call microflow Sales.CreateProduct(
  Name = 'Widget', Code = 'W-001'
);
commit $product;
$updated = call microflow Sales.UpdateProduct(
  Product = $product, NewName = 'Super Widget'
);
/
```

### Test Error Handling

Use `@throws` to verify that a microflow raises an error:

```sql
/**
 * @test Invalid input throws validation error
 * @throws 'Validation failed'
 */
call microflow Sales.ValidateOrder(Total = -1);
/
```

---

## Test File Organization

Recommended structure:

```
tests/
├── microflows.test.mdl      # business logic tests
├── entities.test.mdl         # entity CRUD tests
├── validation.test.mdl       # validation tests
└── specs/
    └── sales-module.test.md  # Markdown specification
```

---

## Interpreting Failures

| Failure | Cause | Fix |
|---------|-------|-----|
| `Exception during execution` | Microflow threw a runtime error | Check BSON structure, entity references, attribute types |
| `Expected $result = 'X' but got 'Y'` | Wrong return value | Fix microflow logic |
| `Test was not executed` | Runtime crashed before reaching it | Check earlier test failures or runtime logs |
| `after startup microflow should return a boolean` | Generated runner has wrong return type | Report as bug in mxcli |

---

## CI Integration

Use `--junit` to produce JUnit XML for CI systems:

```bash
mxcli test tests/ -p app.mpr --junit test-results.xml
```

The JUnit XML works with GitHub Actions, Jenkins, Azure DevOps, GitLab CI, etc.

```yaml
# GitHub actions example
- name: run microflow tests
  run: mxcli test tests/ -p app.mpr --junit test-results.xml
- name: publish test results
  uses: dorny/test-reporter@v1
  with:
    name: microflow Tests
    path: test-results.xml
    reporter: java-junit
```

## Related Skills

- [test-app.md](test-app.md) — Playwright UI tests (pages, widgets, browser interactions)
- [write-microflows.md](write-microflows.md) — Microflow syntax reference
- [docker-workflow.md](docker-workflow.md) — Docker build and runtime workflow
- [verify-with-oql.md](verify-with-oql.md) — OQL queries for data verification
