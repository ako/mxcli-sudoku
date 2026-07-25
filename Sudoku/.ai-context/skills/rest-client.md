# REST Integration Skill

Use this skill when integrating with external REST APIs from Mendix.

## Three Approaches

Mendix offers three ways to call REST APIs from microflows. Choose based on the use case:

| Approach | When to Use | Artifacts |
|----------|-------------|-----------|
| **OpenAPI import** | API has an OpenAPI 3.0 spec — auto-generate from the spec | REST client document generated in one command |
| **REST Client (manual)** | No spec available, or need fine-grained control | REST client document + microflow |
| **REST CALL (inline)** | One-off calls, quick prototyping, dynamic URLs, low-level HTTP control | Microflow only |

Both REST Client approaches can be combined with **Data Transformers** (Mendix 11.9+) and **Import/Export Mappings** to map between JSON and entities.

---

## Approach 0: OpenAPI Import (Fastest)

If the API has an OpenAPI 3.0 spec (JSON or YAML), generate the REST client in one command:

```sql
-- From a local file (relative to the .mpr file)
create or modify rest client CapitalModule.CapitalAPI (
  OpenAPI: 'specs/capital.json'
);

-- From a URL
create or modify rest client PetStoreModule.PetStoreAPI (
  OpenAPI: 'https://petstore3.swagger.io/api/v3/openapi.json'
);

-- Override the base URL (replaces servers[0].url from the spec)
create or modify rest client PetStoreModule.PetStoreStaging (
  OpenAPI: 'https://petstore3.swagger.io/api/v3/openapi.json',
  BaseUrl: 'https://staging.petstore.example.com/api/v3'
);
```

This generates:
- All operations with correct HTTP method, path, parameters, headers, body, and response type
- Resource groups based on OpenAPI `tags`
- Basic auth if the spec declares it at the top level
- The spec stored inside the document for Studio Pro parity

`BaseUrl` is optional. When omitted, `servers[0].url` from the spec is used. When provided, it overrides that value — useful when the spec points at production but you need to import against staging or a different version.

**Preview without writing:**
```sql
describe contract operation from openapi 'specs/capital.json';
```

**After import:** the REST client is ready to use with `SEND REST REQUEST`. No manual operation definition needed.

---

## Approach 1: REST Client (Manual)

Define the API once as a REST client document, then call its operations from microflows.

### Step 1 — Create the REST Client

```sql
create rest client Module.OpenMeteoAPI (
  BaseUrl: 'https://api.open-meteo.com/v1',
  authentication: none
)
{
  operation GetForecast {
    method: get,
    path: '/forecast',
    query: ($latitude: decimal, $longitude: decimal, $current: string),
    headers: ('Accept' = 'application/json'),
    timeout: 30,
    response: json as $WeatherJson
  }

  operation PostData {
    method: post,
    path: '/submit',
    headers: ('Content-Type' = 'application/json'),
    body: json from $JsonPayload,
    response: none
  }
};
```

### Authentication

```sql
-- No authentication
authentication: none

-- Basic auth
authentication: basic (username: 'user', password: 'secret')
```

### Body Types

```sql
-- JSON variable (Mendix expression stored on the operation)
body: json from $JsonPayload

-- String template with parameter placeholders
body: template '{ "name": "{name}", "value": {value} }'

-- Export mapping (entity → JSON, aligned with export mapping syntax)
body: mapping Module.RequestEntity {
  name = Name,
  email = Email,
}
```

### Response Types

```sql
-- Simple types (variable binding is at the call site, not stored on the operation)
response: json as $Result
response: string as $text
response: file as $Document
response: status as $Code
response: none

-- Import mapping (JSON → entity, aligned with import mapping syntax)
response: mapping Module.ResponseEntity {
  "Id" = "id",
  "status" = "status",
  create Module.Items_Response/Module.Item = items {
    "Sku" = "sku",
    "Quantity" = "quantity",
  }
}
```

### Step 2 — Call from a Microflow

```sql
create microflow Module.ACT_GetWeather ()
returns Module.WeatherInfo as $Weather
begin
  -- Call the REST client operation
  send rest request Module.OpenMeteoAPI.GetForecast;

  -- Extract response body from system variable
  declare $RawJson string = $latestHttpResponse/content;

  -- (Optional) Transform with JSLT
  $SimplifiedJson = transform $RawJson with Module.SimplifyWeather;

  -- Import into entity
  $Weather = import from mapping Module.IMM_Weather($SimplifiedJson);

  return $Weather;
end;
/
```

**CRITICAL**: After `send rest request`, the response is in `$latestHttpResponse` (System.HttpResponse):
- `$latestHttpResponse/content` — response body (String)
- `$latestHttpResponse/StatusCode` — HTTP status (Integer)

### Show / Describe / Drop

```sql
show rest clients [in module];
describe rest client Module.ClientName;
drop rest client Module.ClientName;
create or modify rest client Module.ClientName ...  -- idempotent
```

---

## Approach 2: REST CALL (Inline HTTP)

Call an HTTP endpoint directly from a microflow — no REST client document needed. Best for one-off calls, dynamic URLs, or low-level control.

```sql
-- Simple GET returning a string
$response = rest call get 'https://api.example.com/data'
  header Accept = 'application/json'
  timeout 30
  returns string;

-- GET with URL template parameters
$response = rest call get 'https://api.example.com/users/{1}' with (
  {1} = toString($UserId)
)
  header Accept = 'application/json'
  returns string;

-- POST with body
$response = rest call post 'https://api.example.com/items'
  header 'Content-Type' = 'application/json'
  body '{"name": "test"}'
  returns string;

-- With basic auth
$response = rest call get 'https://api.example.com/secure'
  auth basic 'username' password 'password'
  returns string;

-- With import mapping (JSON → entity)
$item = rest call get 'https://api.example.com/item/1'
  header Accept = 'application/json'
  returns mapping Module.IMM_Item as Module.Item;

-- Fire and forget
rest call delete 'https://api.example.com/item/1'
  returns nothing;

-- Error handling
$response = rest call get 'https://api.example.com/data'
  returns string
  on error continue;
```

---

## Data Transformers (JSLT — Mendix 11.9+)

Transform complex JSON responses into simpler structures before import mapping.

```sql
-- Define the transformer
create data transformer Module.SimplifyWeather
source json '{"latitude": 52.52, "current": {"temperature_2m": 12.8, "wind_speed_10m": 18.3}}'
{
  jslt $$
{
  "temp": .current.temperature_2m,
  "wind": .current.wind_speed_10m,
  "lat": .latitude
}
  $$;
};

-- Use in a microflow
$SimplifiedJson = transform $RawJson with Module.SimplifyWeather;
```

Single-line JSLT: `jslt '{ "temp": .current.temperature_2m }';`
Multi-line JSLT: `jslt $$ { ... } $$;` (dollar-quoting, same as Java actions)

```sql
list data transformers [in module];
describe data transformer Module.Name;
drop data transformer Module.Name;
```

---

## JSON Structures & Mappings

See [json-structures-and-mappings.md](json-structures-and-mappings.md) for full reference. Quick summary:

```sql
-- JSON structure from snippet
create json structure Module.JSON_Weather
snippet '{"temp": 12.8, "wind": 18.3, "lat": 52.52}';

-- Non-persistent entity
create non-persistent entity Module.WeatherInfo (
  Temperature: decimal,
  WindSpeed: decimal,
  Latitude: decimal
);
/

-- Import mapping (JSON → entity)
create import mapping Module.IMM_Weather
  with json structure Module.JSON_Weather
{
  create Module.WeatherInfo {
    Temperature = temp,
    WindSpeed = wind,
    Latitude = lat
  }
};

-- Use in microflow
$Weather = import from mapping Module.IMM_Weather($JsonString);
$JsonOutput = export to mapping Module.EMM_Weather($WeatherEntity);
```

---

## Complete Pipeline Example

Full example: call weather API → transform → import → show on page.

```sql
-- 1. Entity
create non-persistent entity Module.CurrentWeather (
  Temperature: decimal,
  WindSpeed: decimal,
  Latitude: decimal,
  ObservationTime: datetime
);
/

-- 2. Data Transformer (simplify API response)
create data transformer Module.SimplifyWeather
source json '{"latitude":52.52,"current":{"time":"2024-01-15T14:00","temperature_2m":12.8,"wind_speed_10m":18.3}}'
{
  jslt $$
{
  "temperature": .current.temperature_2m,
  "windSpeed": .current.wind_speed_10m,
  "latitude": .latitude,
  "observationTime": .current.time
}
  $$;
};

-- 3. JSON Structure + Import Mapping (for transformed output)
create json structure Module.JSON_Weather
snippet '{"temperature":12.8,"windSpeed":18.3,"latitude":52.52,"observationTime":"2024-01-15T14:00"}';

create import mapping Module.IMM_Weather
  with json structure Module.JSON_Weather
{
  create Module.CurrentWeather {
    Temperature = temperature,
    WindSpeed = windSpeed,
    Latitude = latitude,
    ObservationTime = observationTime
  }
};

-- 4. REST Client
create rest client Module.WeatherAPI (
  BaseUrl: 'https://api.open-meteo.com/v1',
  authentication: none
)
{
  operation GetCurrent {
    method: get,
    path: '/forecast',
    query: ($latitude: decimal, $longitude: decimal, $current: string),
    headers: ('Accept' = 'application/json'),
    response: json as $Result
  }
};

-- 5. Microflow (REST Client → Transform → Import)
create microflow Module.ACT_GetWeather ()
returns Module.CurrentWeather as $Weather
begin
  send rest request Module.WeatherAPI.GetCurrent;
  declare $RawJson string = $latestHttpResponse/content;
  $SimplifiedJson = transform $RawJson with Module.SimplifyWeather;
  $Weather = import from mapping Module.IMM_Weather($SimplifiedJson);
  return $Weather;
end;
/
```

---

## Mendix Validation Rules

| Rule | Error | Fix |
|------|-------|-----|
| Every operation MUST have an Accept header | CE7062 | Auto-added by serializer if missing |
| POST/PUT/PATCH MUST have a body | CE7064 | Auto-added by serializer (empty JSON body) |
| Template placeholders must match parameters | CE7056 | `{name}` requires a parameter named `name` |
| No custom error handling on SEND REST REQUEST | CE6035 | Always uses abort-on-error semantics |
| Data Transformer requires 11.9+ | version check | `checkFeature("integration", "data_transformer", ...)` |

## BSON Types Reference

| MDL Concept | BSON Type |
|-------------|-----------|
| REST client document | `rest$ConsumedRestService` |
| Operation | `rest$RestOperation` |
| GET/DELETE method | `rest$RestOperationMethodWithoutBody` |
| POST/PUT/PATCH method | `rest$RestOperationMethodWithBody` |
| JSON body | `rest$JsonBody` |
| Template body | `rest$StringBody` |
| Export mapping body | `rest$ImplicitMappingBody` |
| No response | `rest$NoResponseHandling` |
| Import mapping response | `rest$ImplicitMappingResponseHandling` |
| Header | `rest$HeaderWithValueTemplate` |
| Path parameter | `rest$OperationParameter` |
| Query parameter | `rest$QueryParameter` |
| Data transformer | `DataTransformers$DataTransformer` |
| JSLT step | `DataTransformers$JsltAction` |
| Transform action | `microflows$TransformJsonAction` |
| Send request action | `microflows$RestOperationCallAction` |
| Inline HTTP action | `microflows$RestCallAction` |
