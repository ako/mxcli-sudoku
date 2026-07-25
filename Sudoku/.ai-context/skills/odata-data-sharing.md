# OData Data Sharing Between Mendix Apps

This skill covers how to use OData services to share data between Mendix applications, with emphasis on using view entities as an abstraction layer to decouple the API contract from the internal domain model.

## When to Use This Skill

- User asks to expose data from one Mendix app to another
- User wants to set up inter-app communication via OData
- User needs to create an API layer that abstracts internal entities
- User asks about external entities, consumed/published OData services
- User wants to decouple modules or apps for independent deployment
- User asks about the view entity pattern for OData services
- User asks about local metadata files or offline OData development

## MetadataUrl Formats

`CREATE ODATA CLIENT` supports three formats for the `MetadataUrl` parameter:

| Format | Example | Stored In Model |
|--------|---------|-----------------|
| **HTTP(S) URL** | `https://api.example.com/odata/v4/$metadata` | Unchanged |
| **Absolute file:// URI** | `file:///Users/team/contracts/service.xml` | Unchanged |
| **Relative path** | `./metadata/service.xml` or `metadata/service.xml` | **Normalized to absolute `file://`** |

**Path Normalization:**
- Relative paths (with or without `./`) are **automatically converted** to absolute `file://` URLs in the Mendix model
- This ensures Studio Pro can properly detect local file vs HTTP metadata sources (radio button in UI)
- Example: `./metadata/service.xml` → `file:///absolute/path/to/project/metadata/service.xml`

**Path Resolution (before normalization):**
- With project loaded (`-p` flag or REPL): relative paths are resolved against the `.mpr` file's directory
- Without project: relative paths are resolved against the current working directory

**Use Cases for Local Metadata:**
- **Offline development** — no network access required
- **Testing and CI/CD** — reproducible builds with metadata snapshots
- **Version control** — commit metadata files alongside code
- **Pre-production** — test against upcoming API changes before deployment
- **Firewall-friendly** — works in locked-down corporate environments

## ServiceUrl Must Be a Constant

**IMPORTANT:** The `ServiceUrl` parameter **must always be a constant reference** (prefixed with `@`). Direct URLs are not allowed.

**Correct:**
```sql
CREATE CONSTANT ProductClient.ProductDataApiLocation
  TYPE String
  DEFAULT 'http://localhost:8080/odata/productdataapi/v1/';

CREATE ODATA CLIENT ProductClient.ProductDataApiClient (
  ODataVersion: OData4,
  MetadataUrl: 'https://api.example.com/$metadata',
  ServiceUrl: '@ProductClient.ProductDataApiLocation'  -- ✅ Constant reference
);
```

**Incorrect:**
```sql
CREATE ODATA CLIENT ProductClient.ProductDataApiClient (
  ODataVersion: OData4,
  MetadataUrl: 'https://api.example.com/$metadata',
  ServiceUrl: 'https://api.example.com/odata'  -- ❌ Direct URL not allowed
);
```

This enforces Mendix best practice of externalizing configuration values for different environments.

## Architecture Overview

OData data sharing follows a **producer/consumer** pattern with three layers:

```
┌─────────────────────────────────────────────┐
│  PRODUCER APP                               │
│                                             │
│  persistent entities  ──▶  view entities    │
│  (Shop.Customer,          (Api.CustomerVE)  │
│   Shop.Address)                             │
│                          ▼                  │
│                    odata service             │
│                   (Api.CustomerApi)          │
└──────────────────────┬──────────────────────┘
                       │ HTTP/OData4
┌──────────────────────▼──────────────────────┐
│  CONSUMER APP                               │
│                                             │
│                    odata client             │
│                  (Client.CustomerApiClient)  │
│                          ▼                  │
│                  external entities           │
│                 (Client.CustomersEE)         │
│                          ▼                  │
│                  pages & microflows          │
└─────────────────────────────────────────────┘
```

### Why View Entities?

Publishing persistent entities directly exposes your internal schema. When you change a column name, add a table, or restructure associations, every consumer app breaks. **View entities** solve this:

1. **Stable API contract** -- the view's shape stays the same even when the underlying tables change
2. **Flattened data** -- joins across multiple tables into a single flat resource (e.g., Customer + BillingAddress + DeliveryAddress into one `CustomerAddressVE`)
3. **Computed fields** -- add calculated columns like `FullAddress` or `ActivePrice` using OQL expressions
4. **Filtered datasets** -- restrict what's visible (e.g., only active products, cheap products)
5. **Aggregations** -- expose pre-aggregated metrics (e.g., orders per day, sum of line items)

## Step-by-Step: Read-Only API with View Abstraction

### Step 1: Create the Producer Module and Role

```sql
create module ProductApi;

create module role ProductApi.ApiUser
  description 'Role for OData API access';
```

### Step 2: Create View Entities as the API Layer

Instead of publishing `Shop.Product` and `Shop.Price` directly, create a view that joins and flattens them:

```sql
/**
 * Flattened product with current active price.
 * Joins Product with the most recent Price entry.
 */
create view entity ProductApi.ProductWithPriceVE (
  ProductId: integer,
  Name: string,
  description: string,
  PriceInEuro: decimal
) as (
  select p.ID         as ProdId
  ,      p.ProductId  as ProductId
  ,      p.Name       as Name
  ,      p.Description as description
  ,      ( select pr.PriceInEuro
           from   Shop.Price as pr
           where  pr.StartDate <= '[%BeginOfTomorrow%]'
           and    pr/Shop.Price_Product = p.ID
           order  by pr.StartDate desc
           limit  1
         ) as PriceInEuro
  from   Shop.Product as p
  where  p.IsActive
);

grant ProductApi.ApiUser on ProductApi.ProductWithPriceVE
  (read *, write *);
```

For aggregated data:

```sql
/**
 * Daily sales totals for cheap products.
 */
create view entity ProductApi.CheapProductSalesVE (
  OrderDate: datetime,
  TotalItems: long
) as (
  select o.OrderDate     as OrderDate
  ,      sum(ol.Amount)  as TotalItems
  from   Shop.OrderLine as ol
    left join Shop.OrderLine_Order/Shop."Order" as o
  where  ol/Shop.OrderLine_Product/Shop.Product.PriceInEuro < 100
  group by o.OrderDate
  order by o.OrderDate desc
  limit 1000
);

grant ProductApi.ApiUser on ProductApi.CheapProductSalesVE
  (read *, write *);
```

For flattening across associations:

```sql
/**
 * Customer with billing and delivery address flattened into one resource.
 */
create view entity ProductApi.CustomerAddressVE (
  CustomerId: long,
  CustomerName: string,
  Email: string,
  BillingStreet: string,
  BillingCity: string,
  BillingCountry: string,
  DeliveryStreet: string,
  DeliveryCity: string,
  DeliveryCountry: string
) as (
  select c.ID                              as CustomerID
  ,      c.CustomerId                      as CustomerId
  ,      c.FirstName + ' ' + c.LastName    as CustomerName
  ,      c.EmailAddress                    as Email
  ,      ba.Streetname                     as BillingStreet
  ,      ba.City                           as BillingCity
  ,      ba.Country                        as BillingCountry
  ,      da.Streetname                     as DeliveryStreet
  ,      da.City                           as DeliveryCity
  ,      da.Country                        as DeliveryCountry
  from   Shop.Customer as c
    left outer join c/Shop.BillingAddress_Customer/Shop.Address as ba
    left outer join c/Shop.DeliveryAddress_Customer/Shop.Address as da
);

grant ProductApi.ApiUser on ProductApi.CustomerAddressVE
  (read *, write *);
```

### Step 3: Publish the OData Service

```sql
/**
 * Product and customer data API.
 * Exposes flattened views for external consumers.
 */
create odata service ProductApi.ProductDataApi (
  path: 'odata/productdataapi/v1/',
  version: '1.0.0',
  ODataVersion: OData4,
  namespace: 'DefaultNamespace',
  ServiceName: 'ProductDataApi',
  Summary: 'Product and customer data API',
  PublishAssociations: No
)
authentication basic
{
  publish entity ProductApi.ProductWithPriceVE as 'Product' (
    ReadMode: ReadFromDatabase,
    InsertMode: NotSupported,
    UpdateMode: NotSupported,
    DeleteMode: NotSupported
  )
  expose (
    ProductId as 'ProductId' (Filterable, Sortable, key),
    Name as 'Name' (Filterable, Sortable),
    description as 'Description' (Filterable, Sortable),
    PriceInEuro as 'PriceInEuro' (Filterable, Sortable)
  );

  publish entity ProductApi.CustomerAddressVE as 'CustomerAddress' (
    ReadMode: ReadFromDatabase,
    InsertMode: NotSupported,
    UpdateMode: NotSupported,
    DeleteMode: NotSupported
  )
  expose (
    CustomerId as 'CustomerId' (Filterable, Sortable, key),
    CustomerName as 'CustomerName' (Filterable, Sortable),
    Email as 'Email' (Filterable, Sortable),
    BillingStreet as 'BillingStreet' (Filterable, Sortable),
    BillingCity as 'BillingCity' (Filterable, Sortable),
    BillingCountry as 'BillingCountry' (Filterable, Sortable),
    DeliveryStreet as 'DeliveryStreet' (Filterable, Sortable),
    DeliveryCity as 'DeliveryCity' (Filterable, Sortable),
    DeliveryCountry as 'DeliveryCountry' (Filterable, Sortable)
  );
};

grant access on odata service ProductApi.ProductDataApi
  to ProductApi.ApiUser;
```

### Step 4: Set Up the Consumer App

In the consuming application, create an OData client and external entities:

```sql
create module ProductClient;

create module role ProductClient.User;

-- Location constant (configure per environment)
create constant ProductClient.ProductDataApiLocation
  type string
  default 'http://localhost:8080/odata/productdataapi/v1/';

-- OData client connection
create odata client ProductClient.ProductDataApiClient (
  ODataVersion: OData4,
  MetadataUrl: 'http://localhost:8080/odata/productdataapi/v1/$metadata',
  timeout: 300,
  ServiceUrl: '@ProductClient.ProductDataApiLocation',
  UseAuthentication: Yes,
  HttpUsername: 'MxAdmin',
  HttpPassword: '1'
);

-- OData client with local file - relative path (offline development)
-- Resolved relative to .mpr directory when project is loaded
CREATE ODATA CLIENT ProductClient.ProductDataApiClient (
  ODataVersion: OData4,
  MetadataUrl: './metadata/productdataapi.xml',
  Timeout: 300,
  ServiceUrl: '@ProductClient.ProductDataApiLocation',
  UseAuthentication: Yes,
  HttpUsername: 'MxAdmin',
  HttpPassword: '1'
);

-- OData client with local file - relative path without ./
CREATE ODATA CLIENT ProductClient.ProductDataApiClient (
  ODataVersion: OData4,
  MetadataUrl: 'metadata/productdataapi.xml',
  Timeout: 300,
  ServiceUrl: '@ProductClient.ProductDataApiLocation',
  UseAuthentication: Yes,
  HttpUsername: 'MxAdmin',
  HttpPassword: '1'
);

-- OData client with local file - absolute file:// URI
CREATE ODATA CLIENT ProductClient.ProductDataApiClient (
  ODataVersion: OData4,
  MetadataUrl: 'file:///Users/team/contracts/productdataapi.xml',
  Timeout: 300,
  ServiceUrl: '@ProductClient.ProductDataApiLocation',
  UseAuthentication: Yes,
  HttpUsername: 'MxAdmin',
  HttpPassword: '1'
);

-- External entities (mapped from published service)
create external entity ProductClient.ProductsEE
from odata client ProductClient.ProductDataApiClient
(
  EntitySet: 'Product',
  RemoteName: 'Product',
  Countable: Yes
)
(
  ProductId: long,
  Name: string,
  description: string,
  PriceInEuro: decimal
);

grant ProductClient.User on ProductClient.ProductsEE (read *);

create external entity ProductClient.CustomerAddressesEE
from odata client ProductClient.ProductDataApiClient
(
  EntitySet: 'CustomerAddress',
  RemoteName: 'CustomerAddress',
  Countable: Yes
)
(
  CustomerId: long,
  CustomerName: string,
  Email: string,
  BillingStreet: string,
  BillingCity: string,
  BillingCountry: string,
  DeliveryStreet: string,
  DeliveryCity: string,
  DeliveryCountry: string
);

grant ProductClient.User on ProductClient.CustomerAddressesEE (read *);
```

**Bulk alternative:** Instead of creating external entities one by one, import all (or a subset) from the contract:

```sql
-- All entities from the service
create external entities from ProductClient.ProductDataApiClient;

-- Or specific ones only
create external entities from ProductClient.ProductDataApiClient
  entities (Product, CustomerAddress);

-- Idempotent re-import
create or modify external entities from ProductClient.ProductDataApiClient;
```

### AllowCreateChangeLocally — Read-Only API, Editable in the App

Use `AllowCreateChangeLocally: Yes` when the remote OData API only supports GET (read-only), but the Mendix app needs to let users edit the data locally before passing it to another API call — for example, an external action or a REST microflow that POSTs the change to a different endpoint.

Without this flag, external entities are completely non-editable in the client: form widgets are read-only and no in-memory change can be committed. With the flag, Mendix allows the object to be created and changed locally (in memory or in the Mendix database), without trying to write back through the OData client.

**Typical pattern:**
1. Retrieve data via the OData client into the external entity (GET only).
2. User edits the record in a page — possible because `AllowCreateChangeLocally` is set.
3. A microflow reads the changed object and calls an external action or REST operation (POST/PUT) to submit the change to the remote system.

```sql
-- API is read-only (no insert/update/delete on the OData endpoint).
-- AllowCreateChangeLocally lets users edit the object in the app
-- and submit changes via a separate external action.
create or modify external entity ShopClient.Product
from odata client ShopClient.ShopApiClient
(
  EntitySet: 'Products',
  Countable: Yes,
  Creatable: No,
  Deletable: No,
  Updatable: No,
  AllowCreateChangeLocally: Yes
)
(
  ProductId: long,
  Name: string,
  Price: decimal
);

-- Toggle the flag without recreating the entity.
alter entity ShopClient.Product set allow_create_change_locally = true;
alter entity ShopClient.Product set allow_create_change_locally = false;
```

## Step-by-Step: Read-Write API with Microflow Handlers

For write operations (insert, update, delete), the OData service delegates to microflows that map between the view entity and the underlying persistent entities.

### Step 1: Create CUD Microflows on the Producer

Each microflow receives the view entity and an `$HttpRequest` parameter:

```sql
/**
 * Handles INSERT on ProductWithPriceVE.
 * Creates a new Product and initial Price entry.
 */
create microflow ProductApi.InsertProductWithPriceVE (
  $ProductWithPriceVE: ProductApi.ProductWithPriceVE,
  $HttpRequest: System.HttpRequest
)
begin
  -- Map view fields to persistent entities
  $Product = create Shop.Product (
    Name = $ProductWithPriceVE/Name,
    description = $ProductWithPriceVE/description,
    IsActive = true
  );
  commit $Product;

  $Price = create Shop.Price (
    PriceInEuro = $ProductWithPriceVE/PriceInEuro,
    StartDate = '[%CurrentDateTime%]'
  );
  change $Price (Shop.Price_Product = $Product);
  commit $Price;
end;

grant execute on microflow ProductApi.InsertProductWithPriceVE
  to ProductApi.ApiUser;

/**
 * Handles UPDATE on ProductWithPriceVE.
 * Updates the Product name/description and creates a new Price entry.
 */
create microflow ProductApi.UpdateProductWithPriceVE (
  $ProductWithPriceVE: ProductApi.ProductWithPriceVE,
  $HttpRequest: System.HttpRequest
)
begin
  retrieve $Product from Shop.Product
    where ProductId = $ProductWithPriceVE/ProductId
    limit 1;

  change $Product (
    Name = $ProductWithPriceVE/Name,
    description = $ProductWithPriceVE/description
  );
  commit $Product;
end;

grant execute on microflow ProductApi.UpdateProductWithPriceVE
  to ProductApi.ApiUser;

/**
 * Handles DELETE on ProductWithPriceVE.
 * Soft-deletes the product by setting IsActive = false.
 */
create microflow ProductApi.DeleteProductWithPriceVE (
  $ProductWithPriceVE: ProductApi.ProductWithPriceVE,
  $HttpRequest: System.HttpRequest
)
begin
  retrieve $Product from Shop.Product
    where ProductId = $ProductWithPriceVE/ProductId
    limit 1;

  change $Product (IsActive = false);
  commit $Product;
end;

grant execute on microflow ProductApi.DeleteProductWithPriceVE
  to ProductApi.ApiUser;
```

### Step 2: Wire Microflows to Published Entity

Set `InsertMode`, `UpdateMode`, `DeleteMode` to `CallMicroflow`:

```sql
  publish entity ProductApi.ProductWithPriceVE as 'Product' (
    ReadMode: ReadFromDatabase,
    InsertMode: microflow ProductApi.InsertProductWithPriceVE,
    UpdateMode: microflow ProductApi.UpdateProductWithPriceVE,
    DeleteMode: microflow ProductApi.DeleteProductWithPriceVE
  )
  expose (...);
```

### Step 3: Grant Write Access on External Entity

On the consumer side, grant CREATE, WRITE, and DELETE rights:

```sql
grant ProductClient.User on ProductClient.ProductsEE
  (create, delete, read *, write *);
```

The consumer can now create, update, and delete products through the OData API, and the producer's microflows handle the mapping to persistent entities.

## Advanced: Configuration Microflow for Custom Headers

When the consumer needs to pass custom headers (e.g., for audit trails or user context), use a configuration microflow:

```sql
/**
 * Adds current user name as custom header for audit logging.
 */
create microflow ProductClient.SetClientHeaders (
  $httpResponse: System.HttpResponse
)
returns list of System.HttpHeader as $HttpHeaderList
begin
  $HttpHeaderList = create list of System.HttpHeader;
  $NewHttpHeader = create System.HttpHeader (
    key = 'X-Audit-User',
    value = $currentUser/Name
  );
  add $NewHttpHeader to $HttpHeaderList;
  return $HttpHeaderList;
end;
```

Reference it in the client:

```sql
create odata client ProductClient.ProductDataApiClient (
  ...
  ConfigurationMicroflow: microflow ProductClient.SetClientHeaders
);
```

## API Versioning

When your API contract changes, create a new version rather than breaking existing consumers:

```sql
-- v1: Original API (keep running for existing consumers)
create odata service ProductApi.ProductDataApi (
  path: 'odata/productdataapi/v1/',
  version: '1.0.0',
  ...
);

-- v2: New version with additional fields
create odata service ProductApi.ProductDataApi_v2 (
  path: 'odata/productdataapi/v2/',
  version: '2.0.0',
  ODataVersion: OData4,
  ServiceName: 'ProductDataApi',
  Summary: 'Product API v2 - includes weight and tags',
  ...
)
authentication basic
{
  publish entity ProductApi.ProductWithPriceAndTagsVE as 'Product' (
    ReadMode: ReadFromDatabase,
    InsertMode: microflow ProductApi.InsertProductV2,
    UpdateMode: microflow ProductApi.UpdateProductV2,
    DeleteMode: microflow ProductApi.DeleteProductV2
  )
  expose (...);
};
```

## Folder Organization

Use the `Folder` property to organize OData documents within modules.

**MetadataUrl accepts three formats:**
1. **HTTP(S) URL** — fetches from remote service (production)
2. **file:///absolute/path** — reads from local absolute path
3. **./path or path/file.xml** — reads from local relative path (resolved against .mpr directory)

```sql
-- Format 1: HTTP(S) URL
create odata client ProductClient.ProductDataApiClient (
  ODataVersion: OData4,
  MetadataUrl: 'https://api.example.com/odata/v4/$metadata',
  Folder: 'Integration/ProductAPI'
);

-- Format 2: Absolute file:// URI
create odata client ProductClient.ProductDataApiClient (
  ODataVersion: OData4,
  MetadataUrl: 'file:///Users/team/contracts/productdataapi.xml',
  Folder: 'Integration/ProductAPI'
);

-- Format 3a: Relative path with ./
create odata client ProductClient.ProductDataApiClient (
  ODataVersion: OData4,
  MetadataUrl: './metadata/productdataapi.xml',
  Folder: 'Integration/ProductAPI'
);

-- Format 3b: Relative path without ./
create odata client ProductClient.ProductDataApiClient (
  ODataVersion: OData4,
  MetadataUrl: 'metadata/productdataapi.xml',
  Folder: 'Integration/ProductAPI'
);

create odata service ProductApi.ProductDataApi (
  path: 'odata/productdataapi/v1/',
  version: '1.0.0',
  ODataVersion: OData4,
  folder: 'Integration/APIs'
)
authentication basic
{ ... };
```

Folders are created automatically if they don't exist. Use `/` for nested folders.

## Module Organization Conventions

Follow this naming convention for clean separation:

| Module | Purpose | Contains |
|--------|---------|----------|
| `Shop` | Core domain | Persistent entities, business logic |
| `ShopApi` or `ShopViews` | API layer (producer) | View entities, OData service, CUD microflows |
| `ShopClient` or `ShopViewsClient` | API consumer | OData client, external entities, client constants |

This keeps the API contract separate from the domain logic, and the consumer separate from the producer.

## Checklist

Before publishing:
- [ ] View entities expose only the fields consumers need (no internal IDs unless needed for writes)
- [ ] View entity has at least one `key` field for OData identity
- [ ] Module role created and granted on view entities (READ, optionally WRITE)
- [ ] OData service has AUTHENTICATION set (Basic, Session, or Microflow)
- [ ] GRANT ACCESS ON ODATA SERVICE to the API module role
- [ ] CUD microflows (if writable) accept `($ViewEntity, $HttpRequest)` parameters
- [ ] CUD microflows granted EXECUTE to the API module role

Before consuming:
- [ ] Location constant created for environment-specific URLs
- [ ] OData client `MetadataUrl` points to either:
  - HTTP(S) URL: `https://api.example.com/$metadata`
  - Local file (absolute): `file:///path/to/metadata.xml`
  - Local file (relative): `./metadata/service.xml` (resolved against `.mpr` directory)
- [ ] OData client uses `ServiceUrl: '@Module.Constant'` for runtime endpoint
- [ ] External entities match the published exposed names and types
- [ ] Module role created and granted on external entities (READ, optionally CREATE/WRITE/DELETE)

## Exploration Commands

Use these commands to inspect existing OData setup in a project:

```sql
-- List all published and consumed services
show odata services;
show odata clients;

-- Inspect a specific service
describe odata service ShopViews.ShopViewsApi;
describe odata client ShopViewsClient.ShopViewsApiClient;

-- See external entities and view entities
show entities in ShopViewsClient;
show external entities;
show external actions;

-- Browse available assets from cached $metadata contract
show contract entities from ShopViewsClient.ShopViewsApiClient;
show contract actions from ShopViewsClient.ShopViewsApiClient;
describe contract entity ShopViewsClient.ShopViewsApiClient.Product;
describe contract entity ShopViewsClient.ShopViewsApiClient.Product format mdl;

-- Check security setup
show access on odata service ShopViews.ShopViewsApi;
show module roles in ShopViews;
```
