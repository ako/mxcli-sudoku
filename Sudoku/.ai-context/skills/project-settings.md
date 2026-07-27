# Project Settings

## When to Use This Skill

Use this skill when the user wants to:
- Configure database connections (PostgreSQL, SQLServer, etc.)
- Set up Kafka endpoints or other constant overrides
- Change the after-startup or before-shutdown microflows
- Modify hash algorithms, Java versions, or rounding modes
- View or modify language settings
- Configure workflow settings (user entity, parallelism)

## Commands

### View Settings

```sql
-- Overview table of all settings parts
show settings;

-- Full MDL output (round-trippable ALTER SETTINGS statements)
describe settings;
```

### Modify Model Settings

```sql
alter settings model AfterStartupMicroflow = 'Module.MF_Startup';  -- must return Boolean (CE0142)
alter settings model BeforeShutdownMicroflow = 'Module.MF_Shutdown';
alter settings model HealthCheckMicroflow = 'Module.MF_HealthCheck';
alter settings model HashAlgorithm = 'BCrypt';
alter settings model BcryptCost = 12;
alter settings model JavaVersion = 'Java21';
alter settings model RoundingMode = 'HalfUp';
alter settings model AllowUserMultipleSessions = true;
alter settings model ScheduledEventTimeZoneCode = 'Etc/UTC';
```

### Modify Configuration Settings

```sql
-- Full database configuration
alter settings configuration 'Default'
  DatabaseType = 'PostgreSql',
  DatabaseUrl = 'localhost:5432',
  DatabaseName = 'mydb',
  DatabaseUserName = 'mendix',
  DatabasePassword = 'mendix',
  HttpPortNumber = 8080,
  ServerPortNumber = 8090;

-- Update a single field
alter settings configuration 'Default'
  DatabaseUrl = 'newhost:5432';
```

### Constant Overrides

```sql
-- View constant values across all configurations
show constant values;
show constant values in MyModule;    -- Filter by module

-- Override a constant value in a configuration
alter settings constant 'BusinessEvents.ServerUrl' value 'kafka:9092'
  in configuration 'Default';

-- Without IN CONFIGURATION (uses first configuration)
alter settings constant 'MyModule.ApiKey' value 'abc123';

-- Remove a constant override (reset to default)
alter settings drop constant 'MyModule.ApiKey' in configuration 'Default';
```

### Create / Drop Configurations

```sql
-- Create a new server configuration
create configuration 'Staging';

-- Create with properties
create configuration 'Production'
  DatabaseType = 'POSTGRESQL',
  DatabaseUrl = 'prod-db:5432',
  HttpPortNumber = 8080;

-- Drop a configuration
drop configuration 'Staging';
```

### Language and Workflow Settings

```sql
alter settings LANGUAGE DefaultLanguageCode = 'en_US';

alter settings workflows
  UserEntity = 'System.User',
  DefaultTaskParallelism = 3;
```

## Common Patterns

### PostgreSQL Configuration
```sql
alter settings configuration 'Default'
  DatabaseType = 'PostgreSql',
  DatabaseUrl = 'localhost:5432',
  DatabaseName = 'myapp',
  DatabaseUserName = 'mendix',
  DatabasePassword = 'mendix',
  HttpPortNumber = 8080;
```

### SQL Server Configuration
```sql
alter settings configuration 'Default'
  DatabaseType = 'SqlServer',
  DatabaseUrl = 'localhost:1433',
  DatabaseName = 'myapp',
  DatabaseUserName = 'sa',
  DatabasePassword = 'MyPassword',
  HttpPortNumber = 8080;
```

## Checklist

- [ ] Always run `show settings` or `describe settings` first to see current values
- [ ] Verify changes after modification with `show settings`
- [ ] There is always exactly one ProjectSettings document; it cannot be created or deleted
- [ ] Model setting key names are case-sensitive (e.g., `JavaVersion`, not `javaversion`)
- [ ] Configuration names are case-insensitive (e.g., `'default'` matches `'default'`)
