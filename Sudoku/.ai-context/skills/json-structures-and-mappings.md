# JSON Structures, Import Mappings & Export Mappings

This skill covers creating and managing JSON structures, import mappings, and export mappings in Mendix using MDL.

## Key Concepts

### JSON Structures
A JSON structure defines the schema of a JSON payload. It stores a JSON snippet and auto-derives an element tree with paths, types, and custom names.

### Import Mappings
An import mapping converts a JSON string into Mendix entity objects. It maps JSON fields to entity attributes.

### Export Mappings
An export mapping converts Mendix entity objects into a JSON string. It maps entity attributes to JSON fields.

### Critical: Import and Export Need Different Domain Models

**Import and export mappings for the same JSON structure typically require different entity structures.**

- **Import**: The child entity owns the FK to the parent (`from Child to Parent`). Arrays map directly to the item entity — no intermediate container entity needed.
- **Export**: The domain model mirrors the JSON structure. Arrays need an intermediate container entity (e.g., `Items`) plus an item entity (e.g., `ItemsItem`). The container links to the parent, the item links to the container.

---

## JSON Structures

### Create

```sql
create json structure Module.JSON_Pet
  snippet '{"id": 1, "name": "Fido", "status": "available"}';
```

For multi-line JSON, use dollar-quoting:
```sql
create json structure Module.JSON_Order
  snippet $${
  "orderId": 100,
  "customer": {"name": "Alice", "email": "alice@example.com"},
  "items": [{"sku": "A1", "quantity": 2, "price": 9.99}]
}$$;
```

Custom name mapping (rename JSON fields):
```sql
create json structure Module.JSON_Pet
  snippet '{"id": 1, "name": "Fido"}'
  CUSTOM NAME map ('id' as '_id');
```

### Browse

```sql
show json structures;
show json structures in module;
describe json structure Module.JSON_Pet;
drop json structure Module.JSON_Pet;
```

---

## Import Mappings

### Domain Model for Import

For import mappings, associations point FROM the child entity TO the parent:

```sql
create non-persistent entity Module.OrderResponse (
  OrderId: integer
);
/

create non-persistent entity Module.CustomerInfo (
  Name: string,
  Email: string
);
/

create non-persistent entity Module.OrderItem (
  Sku: string,
  Quantity: integer,
  Price: decimal
);
/

-- Child entity owns the FK (FROM child TO parent)
create association Module.CustomerInfo_OrderResponse
  from Module.CustomerInfo
  to Module.OrderResponse;
/

create association Module.OrderItem_OrderResponse
  from Module.OrderItem
  to Module.OrderResponse;
/
```

### Simple Import Mapping (flat JSON)

```sql
create import mapping Module.IMM_Pet
  with json structure Module.JSON_Pet
{
  create Module.PetResponse {
    PetId = id,
    Name = name,
    status = status
  }
};
```

### Nested Import Mapping (objects and arrays)

Arrays map directly to the item entity — no intermediate container needed:

```sql
create import mapping Module.IMM_Order
  with json structure Module.JSON_Order
{
  create Module.OrderResponse {
    OrderId = orderId,
    create Module.CustomerInfo_OrderResponse/Module.CustomerInfo = customer {
      Name = name,
      Email = email
    },
    create Module.OrderItem_OrderResponse/Module.OrderItem = items {
      Sku = sku,
      Quantity = quantity,
      Price = price
    }
  }
};
```

### Object Handling

| Syntax | Meaning |
|--------|---------|
| `create Module.Entity` | Always create a new object (default) |
| `find Module.Entity` | Find by KEY attributes, ignore if not found |
| `find or create Module.Entity` | Find by KEY, create if not found |

```sql
create import mapping Module.IMM_UpsertPet
  with json structure Module.JSON_Pet
{
  find or create Module.PetResponse {
    PetId = id key,
    Name = name,
    status = status
  }
};
```

**Note**: `key` is only valid with `find` or `find or create`, not with `create`.

---

## Export Mappings

### Domain Model for Export

Export mappings require entities that **mirror the JSON structure**. Arrays need an intermediate container entity:

```sql
-- Root entity (matches top-level JSON object)
create non-persistent entity Module.ExRoot (
  OrderId: integer
);
/

-- Nested object entity (1-1 relationship, use OWNER Both)
create non-persistent entity Module.ExCustomer (
  Name: string,
  Email: string
);
/

-- Array CONTAINER entity (no attributes, just links parent to items)
create non-persistent entity Module.ExItems;
/

-- Array ITEM entity (attributes for each array element)
create non-persistent entity Module.ExItemsItem (
  Sku: string,
  Quantity: integer,
  Price: decimal
);
/

-- Associations: child FROM, parent TO
create association Module.ExCustomer_ExRoot
  from Module.ExCustomer
  to Module.ExRoot
  owner both;   -- 1-1 for nested objects
/

create association Module.ExItems_ExRoot
  from Module.ExItems
  to Module.ExRoot;   -- 1-* for arrays
/

create association Module.ExItemsItem_ExItems
  from Module.ExItemsItem
  to Module.ExItems;   -- 1-* for array items
/
```

### Simple Export Mapping (flat JSON)

```sql
create export mapping Module.EMM_Pet
  with json structure Module.JSON_Pet
{
  Module.PetResponse {
    id = PetId,
    name = Name,
    status = status
  }
};
```

### Nested Export Mapping (objects and arrays)

Arrays have TWO levels: container entity + item entity:

```sql
create export mapping Module.EMM_Order
  with json structure Module.JSON_Order
{
  Module.ExRoot {
    orderId = OrderId,
    Module.ExCustomer_ExRoot/Module.ExCustomer as customer {
      name = Name,
      email = Email
    },
    Module.ExItems_ExRoot/Module.ExItems as items {
      Module.ExItemsItem_ExItems/Module.ExItemsItem as ItemsItem {
        sku = Sku,
        quantity = Quantity,
        price = Price
      }
    }
  }
};
```

### NULL VALUES option

```sql
create export mapping Module.EMM_Pet
  with json structure Module.JSON_Pet
  null values SendAsNil     -- or LeaveOutElement (default)
{
  ...
};
```

---

## Microflow Actions

### Import from Mapping (JSON → entities)

```sql
-- With result variable (non-persistent entities)
$PetResponse = import from mapping Module.IMM_Pet($JsonContent);

-- Without result variable (persistent entities, stores to DB)
import from mapping Module.IMM_Pet($JsonContent);
```

### Export to Mapping (entity → JSON)

```sql
$JsonOutput = export to mapping Module.EMM_Pet($PetResponse);
```

### Complete Pipeline

```sql
create microflow Module.ProcessData ()
begin
  declare $json string = $latestHttpResponse/content;
  $PetResponse = import from mapping Module.IMM_Pet($json);
  -- Process...
  $Output = export to mapping Module.EMM_Pet($PetResponse);
  log info node 'Integration' 'Result: ' + $Output;
end;
/
```

---

## Browse

```sql
show import mappings [in module];
show export mappings [in module];
describe import mapping Module.Name;
describe export mapping Module.Name;
drop import mapping Module.Name;
drop export mapping Module.Name;
```

---

## Export Workflow: PE → NPE → JSON

Export mappings work on non-persistent entity (NPE) structures that mirror the target JSON. When the source data is in persistent entities (PE) in the database, the typical workflow is:

1. **Retrieve** persistent data from the database
2. **Build NPE tree** in a microflow: create NPE objects, set attributes, link via associations to match the JSON structure
3. **Export to mapping** to serialize the NPE tree to JSON

```sql
-- Example: build NPE tree from persistent Order data, then export
create microflow Module.ExportOrder ($Order: Module.Order)
returns string as $json
begin
  -- Build the NPE tree matching the JSON structure
  $Root = create Module.ExRoot (OrderId = $Order/OrderId);

  retrieve $Customer from $Order/Module.Order_Customer;
  $ExCust = create Module.ExCustomer (Name = $Customer/Name, Email = $Customer/Email);
  -- Link customer to root...

  -- Export
  $json = export to mapping Module.EMM_Order($Root);
  return $json;
end;
/
```

### Shortcut with View Entities

View Entities (OQL-backed) can retrieve data directly into the export-ready structure, skipping the manual NPE assembly:

```sql
create view entity Module.ExOrderView (
  OrderId: integer,
  CustomerName: string,
  CustomerEmail: string
) as select o.OrderId, c.Name, c.Email
   from Module.Order o
   join Module.Order_Customer/Module.Customer c;
```

This can reduce the microflow to a single retrieve + export step.

---

## Realistic Example: Countries REST API

A complete example consuming a Countries REST API, importing the response, and
exporting country data back to JSON.

### Step 1: JSON Structures

```sql
-- Single country (flat object)
create json structure Integration.JSON_Country
  snippet '{"name": "Netherlands", "officialName": "Kingdom of the Netherlands", "capital": "Amsterdam", "region": "Europe", "population": 18100436, "flagUrl": "https://flagcdn.com/w320/nl.png"}';

-- List of countries (array of objects)
create json structure Integration.JSON_CountryList
  snippet '[{"name": "Netherlands", "capital": "Amsterdam", "region": "Europe", "population": 18100436}]';
```

### Step 2: Import — Single Country

```sql
create non-persistent entity Integration.Country (
  Name: string,
  OfficialName: string,
  Capital: string,
  Region: string,
  Population: integer,
  FlagUrl: string
);
/

create import mapping Integration.IMM_Country
  with json structure Integration.JSON_Country
{
  create Integration.Country {
    Name = name,
    OfficialName = officialName,
    Capital = capital,
    Region = region,
    Population = population,
    FlagUrl = flagUrl
  }
};
```

### Step 3: Import — List of Countries

For a list response, the import mapping maps the array item directly (no container):

```sql
create non-persistent entity Integration.CountryListItem (
  Name: string,
  Capital: string,
  Region: string,
  Population: integer
);
/

create import mapping Integration.IMM_CountryList
  with json structure Integration.JSON_CountryList
{
  create Integration.CountryListItem {
    Name = name,
    Capital = capital,
    Region = region,
    Population = population
  }
};
```

### Step 4: Export — Serialize Country to JSON

For the flat country, the same entity works for both import and export:

```sql
create export mapping Integration.EMM_Country
  with json structure Integration.JSON_Country
{
  Integration.Country {
    name = Name,
    officialName = OfficialName,
    capital = Capital,
    region = Region,
    population = Population,
    flagUrl = FlagUrl
  }
};
```

### Step 5: Export — List of Countries

For exporting a list, the export domain model needs a root container + item entities:

```sql
-- Container entity wrapping the array
create non-persistent entity Integration.ExCountryList;
/

-- Item entity for each country in the array
create non-persistent entity Integration.ExCountryItem (
  Name: string,
  Capital: string,
  Region: string,
  Population: integer
);
/

create association Integration.ExCountryItem_ExCountryList
  from Integration.ExCountryItem
  to Integration.ExCountryList;
/

create export mapping Integration.EMM_CountryList
  with json structure Integration.JSON_CountryList
{
  Integration.ExCountryList {
    Integration.ExCountryItem_ExCountryList/Integration.ExCountryItem as Root {
      name = Name,
      capital = Capital,
      region = Region,
      population = Population
    }
  }
};
```

### Step 6: Microflow — Fetch, Import, Process, Export

```sql
create microflow Integration.GetCountryInfo ()
returns string as $json
begin
  -- Fetch country data from REST API
  $response = rest call get 'https://restcountries.com/v3.1/name/netherlands'
    header Accept = 'application/json'
    timeout 30
    returns string
    on error continue;

  -- Import JSON into entity
  $Country = import from mapping Integration.IMM_Country($response);

  -- Export back to our own JSON format
  $json = export to mapping Integration.EMM_Country($Country);
  log info node 'Integration' 'Country: ' + $json;

  return $json;
end;
/
```

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Reusing import domain model for export | Export needs separate entities mirroring JSON structure |
| Association direction wrong | Always FROM child TO parent (child owns FK) |
| Using `owner default` for 1-1 nested objects in export | Use `owner both` for 1-1 relationships |
| Missing array container entity in export | Arrays need Container + Item entities |
| Using `key` with `create` handling | `key` only valid with `find` or `find or create` |
| Arrays in import with container entity | Import arrays map directly to item entity, no container |
