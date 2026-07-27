# Mendix Nanoflow Skill

This skill provides guidance for writing Mendix nanoflows in MDL syntax. Nanoflows share syntax with microflows but execute client-side with restricted capabilities.

## When to Use This Skill

Use this skill when:
- Writing CREATE NANOFLOW statements
- Debugging nanoflow validation errors
- Understanding nanoflow restrictions vs microflows
- Building mobile or offline-capable features

If you're not sure whether the logic belongs in a nanoflow or a microflow, read the next section first. The mirror lives in [write-microflows.md](./write-microflows.md) — keep both copies in sync.

## When to Use a Nanoflow vs a Microflow

| Scenario | Use |
|----------|-----|
| Client-side form validation before save | Nanoflow |
| UI navigation and page routing | Nanoflow |
| Calling device features (GPS, phone, camera) | Nanoflow |
| Offline data access and local storage | Nanoflow |
| Calling JavaScript actions (NanoflowCommons) | Nanoflow |
| Showing progress indicators / confirmation dialogs | Nanoflow |
| Querying the database | Microflow |
| Calling REST services or external actions | Microflow |
| Running Java actions | Microflow |
| File generation or download | Microflow |
| Transactional commits (rollback on error) | Microflow |
| Background scheduled logic | Microflow |

**Rule of thumb:** A nanoflow runs before the server call. A microflow IS the server call.

## Key Differences from Microflows

| Aspect | Microflow | Nanoflow |
|--------|-----------|----------|
| **Execution** | Server-side | Client-side (browser/mobile) |
| **Database access** | Full | No direct access |
| **Transactions** | Supported | Not supported |
| **Java actions** | Supported | Not supported |
| **JavaScript actions** | Not supported | Supported |
| **SYNCHRONIZE** | Not available | Available (offline sync) |
| **File downloads** | Supported | Not supported |
| **Error handling** | Full `ON ERROR` blocks + `RAISE ERROR` | Per-action `ON ERROR` supported; `RAISE ERROR` / `ErrorEvent` forbidden |
| **Offline** | Not available | Available |
| **Binary return type** | Supported | Not supported |

## Nanoflow Structure

```mdl
/**
 * Nanoflow description
 *
 * @param $Parameter1 Description
 * @returns Description of return value
 */
CREATE [OR MODIFY] NANOFLOW Module.NAV_Name (
  $Parameter1: type
)
RETURNS ReturnType
FOLDER 'FolderPath'
BEGIN
  -- Nanoflow logic here
  RETURN $Result;
END;
```

## Naming Convention

Nanoflow names use the `NAV_` prefix by convention:
- `NAV_ValidateCart` — client-side validation
- `NAV_ShowDetails` — page navigation
- `NAV_ToggleFilter` — UI state toggle
- `NAV_SignIn` — authentication
- `NAV_SyncChanges` — offline sync

## Supported Activities

### Object Operations (in-memory only)
```mdl
$Item = CREATE Sales.CartItem (Quantity = 1);
CHANGE $Item (Quantity = $Item/Quantity + 1);
COMMIT $Item;
DELETE $Item;
ROLLBACK $Item;
```

### Calling Other Flows
```mdl
$Result = CALL NANOFLOW Sales.NAV_ValidateCart (Cart = $Cart);
$ServerResult = CALL MICROFLOW Sales.ACT_SubmitOrder (Order = $Order);
$JsResult = CALL JAVASCRIPT ACTION NanoflowCommons.SignIn (userName = $Name, password = $Pass);
```

### UI Activities
```mdl
SHOW PAGE Sales.CartDetail ($Cart = $Cart);
CLOSE PAGE;
SHOW MESSAGE WARNING 'Connection unavailable. Working offline.';
VALIDATION FEEDBACK $Item/Quantity MESSAGE 'Quantity must be at least 1';
```

### Logging and Variables
```mdl
LOG INFO 'Cart updated with ' + toString($ItemCount) + ' items';
DECLARE $IsValid Boolean = true;
SET $IsValid = false;
```

### Control Flow
```mdl
IF $Cart/ItemCount = 0 THEN
  VALIDATION FEEDBACK $Cart/ItemCount MESSAGE 'Cart is empty';
  RETURN false;
ELSE
  SHOW PAGE Sales.Checkout ($Cart = $Cart);
  RETURN true;
END IF;
```

### Offline Sync
```mdl
-- Sync uncommitted changes back to server
SYNCHRONIZE $Item;
```
`SYNCHRONIZE` is nanoflow-only. Use it after committing offline objects to push changes to the server in a native mobile context.

---

## Real-World Patterns

These patterns come from 223 nanoflows across three production Mendix apps:
EnquiriesManagement (79), Evora-FactoryManagement (93), LatoProductInventory (51).

### Pattern 1: Client-Side Validation

Validate before calling a microflow to avoid a round-trip.

```mdl
/**
 * Validates the enquiry form fields before submission.
 * @param $Enquiry The enquiry being created or edited
 * @returns true if valid, false if validation errors were shown
 */
CREATE OR MODIFY NANOFLOW Enquiries.NAV_ValidateEnquiry (
  $Enquiry: Enquiries.Enquiry
)
RETURNS Boolean
FOLDER 'Validation'
BEGIN
  IF $Enquiry/Subject = '' THEN
    VALIDATION FEEDBACK $Enquiry/Subject MESSAGE 'Subject is required';
    RETURN false;
  END IF;
  IF $Enquiry/ContactEmail = '' THEN
    VALIDATION FEEDBACK $Enquiry/ContactEmail MESSAGE 'Email is required';
    RETURN false;
  END IF;
  RETURN true;
END;
```

### Pattern 2: Navigation Controller

Validate then navigate — keeps pages dumb.

```mdl
/**
 * Validates the product and opens the detail page if valid.
 * @param $Product Product to open
 */
CREATE OR MODIFY NANOFLOW Inventory.NAV_OpenProductDetail (
  $Product: Inventory.Product
)
FOLDER 'Navigation'
BEGIN
  $IsValid = CALL NANOFLOW Inventory.NAV_ValidateProduct ($Product = $Product);
  IF NOT ($IsValid) THEN
    RETURN;
  END IF;
  SHOW PAGE Inventory.ProductDetail ($Product = $Product);
END;
```

### Pattern 3: UI Feedback Wrapper

Wrap a slow server call with progress indicators.

```mdl
/**
 * Shows progress, calls the server, hides progress.
 * @param $Order The order to submit
 */
CREATE OR MODIFY NANOFLOW Sales.NAV_SubmitOrderWithProgress (
  $Order: Sales.Order
)
FOLDER 'Actions'
BEGIN
  CALL JAVASCRIPT ACTION NanoflowCommons.ShowProgress (message = 'Submitting order...');
  $Result = CALL MICROFLOW Sales.ACT_SubmitOrder (Order = $Order);
  CALL JAVASCRIPT ACTION NanoflowCommons.HideProgress ();
  IF $Result THEN
    SHOW MESSAGE SUCCESS 'Order submitted successfully.';
  END IF;
END;
```

### Pattern 4: Confirmation Dialog Before Destructive Action

```mdl
/**
 * Asks the user to confirm before deleting an item.
 * @param $Item The inventory item to delete
 */
CREATE OR MODIFY NANOFLOW Inventory.NAV_ConfirmDeleteItem (
  $Item: Inventory.Item
)
FOLDER 'Actions'
BEGIN
  $Confirmed = CALL JAVASCRIPT ACTION NanoflowCommons.ShowConfirmation (
    question = 'Delete ' + $Item/Name + '?',
    positiveButtonCaption = 'Delete',
    cancelButtonCaption = 'Cancel'
  );
  IF NOT ($Confirmed) THEN
    RETURN;
  END IF;
  CALL MICROFLOW Inventory.ACT_DeleteItem (Item = $Item);
  CLOSE PAGE;
END;
```

### Pattern 5: Authentication Flow

```mdl
/**
 * Signs the user in and navigates to the home page on success.
 * @param $Username Login username
 * @param $Password Login password
 */
CREATE OR MODIFY NANOFLOW Auth.NAV_SignIn (
  $Username: String,
  $Password: String
)
FOLDER 'Authentication'
BEGIN
  $StatusCode = CALL JAVASCRIPT ACTION NanoflowCommons.SignIn (
    userName = $Username,
    password = $Password,
    useAuthToken = true
  );
  IF $StatusCode = 200 THEN
    SHOW PAGE Home.HomePage ();
  ELSE IF $StatusCode = 401 THEN
    SHOW MESSAGE ERROR 'Incorrect username or password.';
  ELSE
    SHOW MESSAGE WARNING 'Could not connect to server (status: ' + toString($StatusCode) + ')';
  END IF;
END;
```

### Pattern 6: Connectivity Check Before Server Call

Common in field-service and factory-management apps where offline is normal.

```mdl
/**
 * Submits inspection results, warns user if offline.
 * @param $Inspection The inspection to submit
 */
CREATE OR MODIFY NANOFLOW Factory.NAV_SubmitInspection (
  $Inspection: Factory.Inspection
)
FOLDER 'Inspections'
BEGIN
  $IsOnline = CALL JAVASCRIPT ACTION NanoflowCommons.IsConnectedToServer ();
  IF NOT ($IsOnline) THEN
    SHOW MESSAGE WARNING 'You are offline. Changes will sync when reconnected.';
    COMMIT $Inspection;
    RETURN;
  END IF;
  COMMIT $Inspection;
  SYNCHRONIZE $Inspection;
  CALL MICROFLOW Factory.ACT_ProcessInspection (Inspection = $Inspection);
END;
```

### Pattern 7: Geolocation Capture

Used in enquiry and field-service apps to tag records with GPS coordinates.

```mdl
/**
 * Captures the current GPS position and stores it on the record.
 * @param $Record The record to tag with location
 */
CREATE OR MODIFY NANOFLOW Enquiries.NAV_CaptureLocation (
  $Record: Enquiries.SiteVisit
)
FOLDER 'Location'
BEGIN
  $Location = CALL JAVASCRIPT ACTION NanoflowCommons.GetCurrentLocation (
    timeout = 10000,
    maximumAge = 0,
    highAccuracy = true
  );
  CHANGE $Record (
    Latitude = $Location/Latitude,
    Longitude = $Location/Longitude,
    LocationTimestamp = $Location/Timestamp
  );
END;
```

### Pattern 8: Platform-Conditional Logic

```mdl
/**
 * Opens a map or shows coordinates depending on platform.
 * @param $Latitude Latitude coordinate
 * @param $Longitude Longitude coordinate
 */
CREATE OR MODIFY NANOFLOW Enquiries.NAV_ShowOnMap (
  $Latitude: Decimal,
  $Longitude: Decimal
)
FOLDER 'Location'
BEGIN
  $Platform = CALL JAVASCRIPT ACTION NanoflowCommons.GetPlatform ();
  IF $Platform = 'Native_mobile' THEN
    CALL JAVASCRIPT ACTION NanoflowCommons.OpenMap (
      latitude = $Latitude,
      longitude = $Longitude
    );
  ELSE
    SHOW PAGE Enquiries.LocationDetail (Lat = $Latitude, Lon = $Longitude);
  END IF;
END;
```

### Pattern 9: Local Storage Cache

Store a frequently accessed value locally to avoid a round-trip.

```mdl
/**
 * Loads the last-used filter value from local storage.
 * @returns The cached filter string, or empty if never set
 */
CREATE OR MODIFY NANOFLOW Inventory.NAV_LoadFilterCache ()
RETURNS String
FOLDER 'Filters'
BEGIN
  $Exists = CALL JAVASCRIPT ACTION NanoflowCommons.StorageItemExists (
    key = 'InventoryFilter'
  );
  IF NOT ($Exists) THEN
    RETURN '';
  END IF;
  $FilterValue = CALL JAVASCRIPT ACTION NanoflowCommons.GetStorageItemString (
    key = 'InventoryFilter'
  );
  RETURN $FilterValue;
END;
```

### Pattern 10: Device Communication (Field Apps)

```mdl
/**
 * Lets the user call the on-site contact directly.
 * @param $Contact The site contact to call
 */
CREATE OR MODIFY NANOFLOW Factory.NAV_CallContact (
  $Contact: Factory.Contact
)
FOLDER 'Communication'
BEGIN
  IF $Contact/Phone = '' THEN
    SHOW MESSAGE WARNING 'No phone number on record for ' + $Contact/Name;
    RETURN;
  END IF;
  CALL JAVASCRIPT ACTION NanoflowCommons.CallPhoneNumber (
    phoneNumber = $Contact/Phone
  );
END;
```

---

## NanoflowCommons JavaScript Actions Reference

All three test apps include the `NanoflowCommons` module. The actions below are available in any app that has this module installed.

### Authentication & Connectivity

| Action | Parameters | Returns | Notes |
|--------|-----------|---------|-------|
| `NanoflowCommons.SignIn` | `userName`, `password`, `useAuthToken` | Integer | 200=success, 401=bad creds, 0=offline |
| `NanoflowCommons.SignOut` | — | — | Logs out current user |
| `NanoflowCommons.IsConnectedToServer` | — | Boolean | false when offline |

### Device Features

| Action | Parameters | Returns | Notes |
|--------|-----------|---------|-------|
| `NanoflowCommons.GetCurrentLocation` | `timeout`, `maximumAge`, `highAccuracy` | `NanoflowCommons.Geolocation` | Object has Lat, Lon, Accuracy, Timestamp |
| `NanoflowCommons.Geocode` | `address`, `provider`, `apiKey` | `NanoflowCommons.Geolocation` | Address → coordinates |
| `NanoflowCommons.ReverseGeocode` | `latitude`, `longitude`, `provider`, `apiKey` | String | Coordinates → address |
| `NanoflowCommons.GetStraightLineDistance` | `fromLat`, `fromLon`, `toLat`, `toLon`, `distanceUnit` | Decimal | Haversine distance |
| `NanoflowCommons.OpenMap` | `latitude`, `longitude` | — | Opens maps app |
| `NanoflowCommons.CallPhoneNumber` | `phoneNumber` | — | Opens dialer |
| `NanoflowCommons.SendTextMessage` | `phoneNumber` | — | Opens SMS app |
| `NanoflowCommons.DraftEmail` | `to`, `subject`, `body` | — | Opens email client |
| `NanoflowCommons.Share` | `content` | — | Native share dialog |
| `NanoflowCommons.OpenURL` | `url` | — | Opens in browser |
| `NanoflowCommons.GetPlatform` | — | String | `Web`, `Native_mobile`, `Hybrid_mobile` |

### UI & Navigation

| Action | Parameters | Returns | Notes |
|--------|-----------|---------|-------|
| `NanoflowCommons.ShowProgress` | `message` | — | Shows loading overlay |
| `NanoflowCommons.HideProgress` | — | — | Hides loading overlay |
| `NanoflowCommons.ShowConfirmation` | `question`, `positiveButtonCaption`, `cancelButtonCaption` | Boolean | true = confirmed |
| `NanoflowCommons.NavigateTo` | `target` | — | Programmatic navigation |
| `NanoflowCommons.ToggleSidebar` | — | — | Show/hide sidebar |

### Local Storage

| Action | Parameters | Returns | Notes |
|--------|-----------|---------|-------|
| `NanoflowCommons.SetStorageItemString` | `key`, `value` | — | Persist string locally |
| `NanoflowCommons.GetStorageItemString` | `key` | String | Read stored string |
| `NanoflowCommons.SetStorageItemObject` | `key`, `value` | — | Persist Mendix object |
| `NanoflowCommons.GetStorageItemObject` | `key`, `entity` | Object | Read stored object |
| `NanoflowCommons.StorageItemExists` | `key` | Boolean | Check before reading |
| `NanoflowCommons.RemoveStorageItem` | `key` | — | Delete a stored item |
| `NanoflowCommons.ClearLocalStorage` | — | — | Clear everything |

### Object Utilities

| Action | Parameters | Returns | Notes |
|--------|-----------|---------|-------|
| `NanoflowCommons.GetGuid` | `object` | String | GUID of Mendix object |
| `NanoflowCommons.GetObjectByGuid` | `entity`, `guid` | Object | Retrieve by GUID |
| `NanoflowCommons.RefreshObject` | `object` | — | Refresh without page reload |
| `NanoflowCommons.RefreshEntity` | `entity` | — | Refresh all objects of type |

### Utilities

| Action | Parameters | Returns | Notes |
|--------|-----------|---------|-------|
| `NanoflowCommons.Wait` | `milliseconds` | — | Async delay |
| `NanoflowCommons.TimeBetween` | `startDate`, `endDate`, `unit` | Decimal | Time difference |
| `NanoflowCommons.GenerateUniqueID` | — | String | Session-scoped unique ID |
| `NanoflowCommons.Base64Encode` | `value` | String | Encode string to Base64 |
| `NanoflowCommons.Base64Decode` | `value` | String | Decode Base64 string |

---

## Disallowed Activities

These will produce validation errors:
- `RAISE ERROR` / `ErrorEvent` — not available in nanoflows
- `CALL JAVA ACTION` — Java actions cannot run client-side
- `EXECUTE DATABASE QUERY` — direct SQL requires server
- `CALL EXTERNAL ACTION` — external actions are server-side
- `SHOW HOME PAGE` — home page navigation is server-side
- `CALL REST SERVICE` / `SEND REST REQUEST` — REST calls are server-side
- `IMPORT FROM MAPPING` / `EXPORT TO MAPPING` — mapping operations are server-side
- `TRANSFORM JSON` — JSON transformations are server-side
- `DOWNLOAD FILE` — file downloads require server-side processing
- All **workflow actions** (11 types: CallWorkflow, OpenWorkflow, SetTaskOutcome, etc.)

## Return Type Restrictions

Binary return type is NOT allowed in nanoflows.

## Error Handling in Nanoflows

Since `RAISE ERROR` is forbidden, handle errors per-action with `ON ERROR`:

```mdl
$Location = CALL JAVASCRIPT ACTION NanoflowCommons.GetCurrentLocation (
  timeout = 5000,
  maximumAge = 0,
  highAccuracy = false
) ON ERROR CONTINUE;

IF $Location = empty THEN
  SHOW MESSAGE WARNING 'Could not get your location.';
  RETURN;
END IF;
```

For per-action error handling without CONTINUE:
```mdl
$Result = CALL NANOFLOW Sales.NAV_Risky () ON ERROR ROLLBACK;
```

## Security (GRANT/REVOKE)

```mdl
GRANT EXECUTE ON NANOFLOW Shop.NAV_Filter TO Shop.User, Shop.Admin;
REVOKE EXECUTE ON NANOFLOW Shop.NAV_Filter FROM Shop.User;
```

## Management Commands

```mdl
SHOW NANOFLOWS
SHOW NANOFLOWS IN MyModule
DESCRIBE NANOFLOW MyModule.NAV_ShowDetails
DROP NANOFLOW MyModule.NAV_ShowDetails;
RENAME NANOFLOW MyModule.NAV_OldName TO NAV_NewName;
MOVE NANOFLOW Sales.NAV_OpenCart TO FOLDER 'UI/Navigation';
SHOW ACCESS ON NANOFLOW MyModule.NAV_ShowDetails;
```

## Common Mistakes

1. **Using Java actions** — Use CALL JAVASCRIPT ACTION instead.
2. **Using RAISE ERROR** — Nanoflows cannot raise errors directly. Handle per-action with ON ERROR or guard with IF checks.
3. **Expecting transactions** — Nanoflows have no automatic rollback. Design for idempotency.
4. **File operations** — DOWNLOAD FILE is server-only.
5. **Binary return types** — Not supported in nanoflows.
6. **REST/external calls** — REST calls and external actions are server-only. Call a microflow to do server work.
7. **Calling NanoflowCommons before checking availability** — Always check `StorageItemExists` before reading; always check `IsConnectedToServer` before syncing.
8. **Using SYNCHRONIZE outside native mobile context** — Only call SYNCHRONIZE in native mobile offline flows.

## Validation Checklist

- [ ] No RAISE ERROR / ErrorEvent
- [ ] No Java action calls
- [ ] No REST calls, external action calls, or database queries
- [ ] No file download operations
- [ ] No import/export mapping or JSON transformation
- [ ] No workflow actions
- [ ] No show home page
- [ ] No binary return type
- [ ] Parameters and return types are nanoflow-compatible
- [ ] JavaDoc documentation present
- [ ] NAV_ naming prefix used
- [ ] NanoflowCommons actions guarded (connectivity check, storage exists check)
- [ ] Progress indicators hidden on both success and error paths
