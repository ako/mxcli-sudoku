# Navigation Management Skill

This skill covers inspecting and modifying Mendix navigation profiles via MDL: home pages, menu items, login pages, role-based routing, and navigation catalog queries.

## When to Use This Skill

Use when the user asks to:
- View or change navigation home pages
- View or modify the navigation menu structure
- Set login or not-found pages
- Configure role-based home page routing
- Discover which pages are navigation entry points
- Set up navigation for a new project

## Navigation Concepts

- **Navigation Profiles** — Every Mendix project has navigation profiles: Responsive, Phone, Tablet, and optionally Native. Each profile has its own home page, menu, and login page.
- **Home Page** — The default page shown after login. Can be a PAGE or MICROFLOW.
- **Role-Based Home Pages** — Override the default home page per user role (e.g., admins see a dashboard, users see a task list).
- **Menu Items** — Hierarchical menu tree. Each item has a caption and optionally targets a PAGE or MICROFLOW. Sub-menus nest with `menu 'caption' (...)`.
- **Login Page** — Custom login page (optional; Mendix provides a default).
- **Not-Found Page** — Custom 404 page (optional).

## Show Commands (Read-Only)

```sql
-- Summary of all navigation profiles (home pages, menu counts)
show navigation;

-- Full MDL description of a profile (round-trippable output)
describe navigation Responsive;
describe navigation;              -- all profiles

-- Menu tree for a specific profile
show navigation menu Responsive;
show navigation menu;             -- all profiles

-- Home page assignments across all profiles and roles
show navigation homes;
```

## CREATE OR REPLACE NAVIGATION (Full Replacement)

This command fully replaces a navigation profile's configuration. All clauses are optional — omitted clauses clear that section. The output from `describe navigation` can be pasted back directly.

### Basic: Set Home and Login Page

```sql
create or replace navigation Responsive
  home page MyModule.Home_Web
  login page Administration.Login;
```

### Role-Based Home Pages

Add `for Module.Role` to override the home page for specific user roles:

```sql
create or replace navigation Responsive
  home page MyModule.Home_Web
  home page MyModule.AdminDashboard for Administration.Administrator
  home page MyModule.CustomerPortal for MyModule.Customer
  login page Administration.Login;
```

### Full Menu Tree

The `menu (...)` block replaces the entire menu. Use `menu item` for leaf items and `menu 'caption' (...)` for sub-menus:

```sql
create or replace navigation Responsive
  home page MyModule.Home_Web
  login page Administration.Login
  menu (
    menu item 'Home' page MyModule.Home_Web;
    menu 'Orders' (
      menu item 'All Orders' page Orders.Order_Overview;
      menu item 'New Order' page Orders.Order_New;
    );
    menu 'Admin' (
      menu item 'Users' page Administration.Account_Overview;
      menu item 'Run Report' microflow Reports.ACT_GenerateReport;
    );
  );
```

### Clear the Menu

An empty `menu ()` block removes all menu items:

```sql
create or replace navigation Responsive
  home page MyModule.Home_Web
  menu ();
```

### Not-Found Page

```sql
create or replace navigation Responsive
  home page MyModule.Home_Web
  not found page MyModule.Custom404;
```

### Microflow as Home Page

Use `home microflow` instead of `home page` to run a microflow on login:

```sql
create or replace navigation Responsive
  home microflow MyModule.ACT_ShowHome;
```

## Round-Trip Workflow

The DESCRIBE output is directly executable. Use this pattern to inspect, modify, and re-apply:

```sql
-- Step 1: Inspect current state
describe navigation Responsive;

-- Step 2: Copy the output, modify as needed, paste back
create or replace navigation Responsive
  home page MyModule.Home_Web
  login page Administration.Login
  menu (
    menu item 'Home' page MyModule.Home_Web;
    menu item 'New Feature' page MyModule.NewFeature;
  );

-- Step 3: Verify
describe navigation Responsive;
```

## Catalog Queries

After `refresh catalog full`, navigation references appear in the `REFS` table:

```sql
refresh catalog full;

-- Find all pages that are navigation entry points
select SourceName, TargetName, RefKind
from CATALOG.REFS
where RefKind in ('home_page', 'menu_item', 'login_page');

-- What references point to a specific page?
show references to MyModule.Home_Web;

-- Impact analysis: what breaks if I change this page?
show impact of MyModule.Home_Web;

-- Full context for a page (includes navigation references)
show context of MyModule.Home_Web;
```

## Common Patterns

### New Project Setup

Set up navigation for a freshly created project:

```sql
-- Create home page
create page MyModule.Home_Web
(
  title: 'Home',
  layout: Atlas_Core.Atlas_Default
)
{
  container ctnMain {
    dynamictext txtWelcome (content: 'Welcome!')
  }
}

-- Configure navigation
create or replace navigation Responsive
  home page MyModule.Home_Web
  menu (
    menu item 'Home' page MyModule.Home_Web;
  );
```

### Adding a New Page to Navigation

After creating a new page, add it to the menu:

```sql
-- First inspect current menu
describe navigation Responsive;

-- Then re-apply with the new item added (copy existing + add new)
create or replace navigation Responsive
  home page MyModule.Home_Web
  login page Administration.Login
  menu (
    menu item 'Home' page MyModule.Home_Web;
    menu item 'Customers' page MyModule.Customer_Overview;  -- new
    menu 'Admin' (
      menu item 'Users' page Administration.Account_Overview;
    );
  );
```

## Checklist

- [ ] Profile name matches an existing profile (Responsive, Phone, Tablet, or a native profile)
- [ ] All PAGE/MICROFLOW targets are fully qualified (`Module.Name`)
- [ ] Role references in `for` clauses are fully qualified (`Module.Role`)
- [ ] Every `menu item` and `menu 'caption' (...)` ends with `;`
- [ ] Sub-menu items are wrapped in `menu 'caption' ( ... );`
- [ ] Use `describe navigation` to verify changes after applying
