# Data Processing Patterns

Patterns for loops, aggregates, batch processing, and data transformation.

## Loop Patterns

### Basic Loop

```mdl
/**
 * Process all items in a list
 */
create microflow Module.ProcessItems (
  $Items: list of Module.Item
)
returns boolean
begin
  declare $ProcessedCount integer = 0;

  loop $item in $Items
  begin
    -- Process each item
    change $item (ProcessedDate = [%CurrentDateTime%]);
    commit $item;
    set $ProcessedCount = $ProcessedCount + 1;
  end loop;

  log info node 'Processing' 'Processed ' + $ProcessedCount + ' items';
  return true;
end;
/
```

### Loop with Filtering

```mdl
/**
 * Process only active items
 */
create microflow Module.ProcessActiveItems (
  $Items: list of Module.Item
)
returns integer
begin
  declare $count integer = 0;

  loop $item in $Items
  begin
    if $item/IsActive then
      -- Process active item
      change $item (LastProcessed = [%CurrentDateTime%]);
      commit $item;
      set $count = $count + 1;
    end if;
  end loop;

  return $count;
end;
/
```

### Loop with Accumulator

```mdl
/**
 * Calculate total value of all orders
 */
create microflow Module.CalculateOrderTotal (
  $Orders: list of Module.Order
)
returns decimal
begin
  declare $Total decimal = 0;

  loop $Order in $Orders
  begin
    set $Total = $Total + $Order/Amount;
  end loop;

  return $Total;
end;
/
```

## Retrieve by Association

Use `retrieve $list from $Parent/Module.AssociationName` to retrieve related objects
via association instead of a database XPath query. This is **required** for:

- **Non-persistent entities (NPEs)** — database XPath queries always return empty for NPEs
- **Uncommitted objects** — objects not yet committed to the database
- **JSON mapping results** — imported data structures held in memory

### Persistent Entity Example

```mdl
/**
 * Get all orders for a customer via association
 */
create microflow Module.GetCustomerOrders (
  $Customer : Module.Customer
)
returns list of Module.Order
begin
  retrieve $Orders from $Customer/Module.Order_Customer;
  return $Orders;
end;
/
```

### Non-Persistent Entity Example (NPE)

```mdl
/**
 * Process imported rows from an in-memory result object.
 * Database RETRIEVE would return empty for NPEs — use association retrieve.
 */
create microflow Module.ProcessImportRows (
  $ImportResult : Module.ImportResult
)
returns integer
begin
  -- Association retrieve is the ONLY way to get related NPEs
  retrieve $Rows from $ImportResult/Module.ImportResult_ImportRow;

  declare $ValidCount integer = 0;

  loop $row in $Rows
  begin
    if $row/IsValid then
      set $ValidCount = $ValidCount + 1;
    end if;
  end loop;

  return $ValidCount;
end;
/
```

### When to Use Which Retrieve

| Scenario | Syntax | Why |
|----------|--------|-----|
| Query persistent entities by attribute | `retrieve $list from Module.Entity where ...` | Database XPath query |
| Get related persistent objects | `retrieve $list from $Parent/Module.Association` | Simpler, no XPath needed |
| Get related NPEs / uncommitted objects | `retrieve $list from $Parent/Module.Association` | **Only option** — database has no data |
| JSON mapping results (import) | `retrieve $list from $Parent/Module.Association` | Mapping creates in-memory NPEs |

**Important:** Association retrieve always returns a list. It does not support WHERE, SORT BY, LIMIT, or OFFSET clauses.

## Aggregate Patterns

Aggregates use **function-call syntax** — there is no `AGGREGATE` keyword.

| Function | Syntax | Returns |
|----------|--------|---------|
| COUNT | `$n = count($list)` | Integer |
| SUM | `$n = sum($list.Attr)` | Decimal |
| AVERAGE | `$n = average($list.Attr)` | Decimal |
| MINIMUM | `$n = minimum($list.Attr)` | Same as attribute |
| MAXIMUM | `$n = maximum($list.Attr)` | Same as attribute |

**Important:** RETRIEVE implicitly declares its variable — do NOT add a separate DECLARE
before RETRIEVE, or you'll get CE0111 "Duplicate variable name".

### Count Items

```mdl
/**
 * Count active customers
 */
create microflow Module.CountActiveCustomers ()
returns integer
begin
  retrieve $Customers from Module.Customer
    where IsActive = true;

  $count = count($Customers);
  return $count;
end;
/
```

### Sum Values

```mdl
/**
 * Sum order amounts for a customer
 */
create microflow Module.GetCustomerTotalOrders (
  $Customer: Module.Customer
)
returns decimal
begin
  retrieve $Orders from Module.Order
    where Module.Order_Customer = $Customer;

  $Total = sum($Orders.Amount);
  return $Total;
end;
/
```

### Average Calculation

```mdl
/**
 * Calculate average order value
 */
create microflow Module.GetAverageOrderValue ()
returns decimal
begin
  retrieve $Orders from Module.Order;

  $average = average($Orders.Amount);
  return $average;
end;
/
```

### Min/Max

```mdl
$MinPrice = minimum($Products.Price);
$MaxPrice = maximum($Products.Price);
```

## List Operations

### Add to List

```mdl
/**
 * Collect matching items into a list
 */
create microflow Module.CollectHighValueOrders (
  $Orders: list of Module.Order,
  $Threshold: decimal
)
returns list of Module.Order
begin
  $HighValue = create list of Module.Order;

  loop $Order in $Orders
  begin
    if $Order/Amount > $Threshold then
      add $Order to $HighValue;
    end if;
  end loop;

  return $HighValue;
end;
/
```

### Remove from List

```mdl
/**
 * Remove inactive items from list
 */
create microflow Module.FilterActiveItems (
  $Items: list of Module.Item
)
returns list of Module.Item
begin
  $ToRemove = create list of Module.Item;

  -- Collect items to remove
  loop $item in $Items
  begin
    if not $item/IsActive then
      add $item to $ToRemove;
    end if;
  end loop;

  -- Remove collected items
  loop $item in $ToRemove
  begin
    remove $item from $Items;
  end loop;

  return $Items;
end;
/
```

## Batch Processing

### Process in Batches

```mdl
/**
 * Process large dataset in batches
 * Commits after each batch to avoid memory issues
 */
create microflow Module.BatchProcess (
  $Items: list of Module.Item,
  $BatchSize: integer
)
returns integer
begin
  declare $Processed integer = 0;
  declare $BatchCount integer = 0;

  loop $item in $Items
  begin
    -- Process item
    change $item (status = 'Processed');

    set $BatchCount = $BatchCount + 1;
    set $Processed = $Processed + 1;

    -- Commit batch
    if $BatchCount >= $BatchSize then
      commit $item;
      set $BatchCount = 0;
      log info node 'Batch' 'Processed ' + $Processed + ' items';
    end if;
  end loop;

  -- Final commit for remaining items
  if $BatchCount > 0 then
    log info node 'Batch' 'Final batch: ' + $Processed + ' total';
  end if;

  return $Processed;
end;
/
```

## Data Transformation

### Copy Entity

```mdl
/**
 * Create a copy of an order
 */
create microflow Module.CopyOrder (
  $source: Module.Order
)
returns Module.Order
begin
  $Copy = create Module.Order (
    OrderNumber = 'COPY-' + $source/OrderNumber,
    Amount = $source/Amount,
    status = 'Draft',
    CreatedDate = [%CurrentDateTime%]
  );

  -- Copy association
  set $Copy/Module.Order_Customer = $source/Module.Order_Customer;

  commit $Copy;
  return $Copy;
end;
/
```

### Transform List

```mdl
/**
 * Create summary records from detail records
 */
create microflow Module.CreateOrderSummaries (
  $Orders: list of Module.Order
)
returns list of Module.OrderSummary
begin
  $Summaries = create list of Module.OrderSummary;

  loop $Order in $Orders
  begin
    $Summary = create Module.OrderSummary (
      OrderNumber = $Order/OrderNumber,
      TotalAmount = $Order/Amount,
      CustomerName = $Order/Module.Order_Customer/Name
    );
    add $Summary to $Summaries;
  end loop;

  return $Summaries;
end;
/
```

## Error Handling in Loops

### Continue on Error

```mdl
/**
 * Process items, log errors but continue
 */
create microflow Module.ProcessWithErrorHandling (
  $Items: list of Module.Item
)
returns integer
begin
  declare $Processed integer = 0;
  declare $Errors integer = 0;

  loop $item in $Items
  begin
    if $item/data = empty then
      log warning node 'Process' 'Skipping item with empty data: ' + $item/Code;
      set $Errors = $Errors + 1;
    else
      change $item (status = 'Processed');
      commit $item;
      set $Processed = $Processed + 1;
    end if;
  end loop;

  log info node 'Process' 'Completed: ' + $Processed + ' processed, ' + $Errors + ' errors';
  return $Processed;
end;
/
```

## Best Practices

1. **Commit inside loops carefully**: Can cause performance issues on large sets
2. **Use batch commits**: Commit every N records for large datasets
3. **Log progress**: Add logging for long-running operations
4. **Handle errors gracefully**: Don't let one bad record stop the whole process
5. **Return counts**: Help callers know what was processed
6. **Use meaningful variable names**: `$ProcessedCount` not `$c`
