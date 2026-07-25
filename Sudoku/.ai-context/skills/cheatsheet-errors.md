# MDL Common Errors Cheatsheet

Quick fixes for common MDL syntax errors.

## Variable Errors

### "Variable 'X' is not declared"

**Problem**: Using SET on a variable that wasn't declared.

```mdl
-- WRONG
if $value > 10 then
  set $IsValid = false;  -- ERROR: $IsValid not declared
end if;
```

**Fix**: Add DECLARE before SET.

```mdl
-- CORRECT
declare $IsValid boolean = true;
if $value > 10 then
  set $IsValid = false;
end if;
```

### "Selected type is not allowed" (CE0053)

**Problem**: Declaring an object (entity) or list variable. A `declare` maps to a
Create Variable activity, which only accepts primitives
(String/Integer/Long/Decimal/Boolean/DateTime/Enumeration). Declaring an object or
list is rejected (CE0053/CE0038, plus CE7247 on any later `set`) — bare *or*
initialized. The `as` keyword is also a parse error in mxcli. `mxcli check` flags an
object declare as **MDL043** and a list declare as **MDL040**.

```mdl
-- WRONG: declaring an object — there is no "empty object variable" (MDL043)
declare $Product Module.Product = empty;
declare $Product as Module.Product;         -- AS is also a parse error
-- WRONG: declaring a list (MDL040)
declare $Products list of Module.Product = empty;
```

**Fix**: Objects and lists can't be declared — get them from a source that produces one.

```mdl
-- object: a microflow parameter, a retrieve, a create, or a loop iterator
retrieve $Product from Module.Product where Code = $Code limit 1;  -- retrieve
$Product = create Module.Product (Name = $Name);                   -- create
-- or: create microflow M.Save ($Product: Module.Product) ... / loop $Product in $Products ...

-- list: a parameter, a retrieve, or a create list
$Products = create list of Module.Product;   -- empty list to accumulate into
retrieve $Products from Module.Product where ...;  -- or populate from the database
```

## Expression Errors

### "Error in expression" (CE0117)

**Problem 1**: Using unqualified association name in XPath.

```mdl
-- WRONG: Missing module qualification
set $Name = $Order/Customer/Name;
```

**Fix**: Use fully qualified association name.

```mdl
-- CORRECT: Module.AssociationName
set $Name = $Order/Shop.Order_Customer/Name;
```

**Problem 2**: Using `not` without parentheses — Mendix requires `not(expr)` form.

```mdl
-- WRONG: bare not rejected by Studio Pro
if not $IsActive then ...
if not contains($Name, 'demo') then ...
```

**Fix**: Always wrap the negated expression in parentheses.

```mdl
-- CORRECT: not(expr)
if not($IsActive) then ...
if not(contains($Name, 'demo')) then ...
```

> mxcli enforces this at parse time — `not expr` without parens is a syntax error.

### "Type mismatch" in enum comparison

**Problem**: Comparing enumeration with string literal.

```mdl
-- WRONG: String literal instead of enum value
if $task/status = 'Completed' then
```

**Fix**: Use qualified enumeration value.

```mdl
-- CORRECT: Module.Enumeration.Value
if $task/status = Module.TaskStatus.Completed then
```

## Control Flow Errors

### "Activity cannot be the last object" (CE0105)

**Problem**: Missing RETURN statement.

```mdl
-- WRONG: No RETURN
begin
  declare $Result boolean = true;
  log info 'Done';
  -- Missing RETURN!
end;
```

**Fix**: Add RETURN statement.

```mdl
-- CORRECT
begin
  declare $Result boolean = true;
  log info 'Done';
  return $Result;
end;
```

### "Action activity is unreachable" (CE0104)

**Problem**: Code after RETURN statement.

```mdl
-- WRONG: Code after RETURN
if $value < 0 then
  return false;
  log info 'Negative';  -- Unreachable!
end if;
```

**Fix**: Move code before RETURN.

```mdl
-- CORRECT
if $value < 0 then
  log info 'Negative';
  return false;
end if;
```

## Syntax Errors

### Division operator

```mdl
-- WRONG: Using / for division
set $average = $Total / $count;

-- CORRECT: Use 'div' keyword
set $average = $Total div $count;
```

### Missing END IF / END LOOP

```mdl
-- WRONG: Missing END IF
if $value > 0 then
  set $Positive = true;
-- Missing END IF!

-- CORRECT
if $value > 0 then
  set $Positive = true;
end if;
```

### Missing semicolons

```mdl
-- WRONG: Missing semicolon
declare $count integer = 0
set $count = 1

-- CORRECT
declare $count integer = 0;
set $count = 1;
```

## Reference Errors

### "Module not found"

**Problem**: Using non-existent module name.

**Fix**: Check module exists with `show modules`.

### "Entity not found"

**Problem**: Using non-existent entity name.

**Fix**:
1. Check entity exists: `show entities in ModuleName`
2. Use fully qualified name: `Module.EntityName`

### "Microflow not found"

**Problem**: Calling non-existent microflow.

**Fix**:
1. Check microflow exists: `show microflows in ModuleName`
2. Use fully qualified name: `Module.MicroflowName`

## Studio Pro Error Code Reference

| Code | Message | Common Cause |
|------|---------|--------------|
| CE0053 | Selected type is not allowed | Declared an object/list variable — get it from a parameter/retrieve/create/loop (MDL043 objects, MDL040 lists) |
| CE0104 | Action activity is unreachable | Code after RETURN |
| CE0105 | Must end with end event | Missing RETURN |
| CE0117 | Error in expression | Unqualified association path |
| CE1571 | No argument selected for parameter | `$currentObject` in a control-bar button (not row-scoped) — `check` flags MDL-BUTTON01 |
| CE1834 | The 'Page' property is required | Workflow user task without a `page` — `check` flags MDL-WF01 |
| CE1876 | Single outcome must not contain activities | Single-outcome user task with a nested activity flow — `check` flags MDL-WF02 |
| CW0094 | Variable never used | Unused parameter/variable |

## Quick Validation Checklist

Before executing MDL:

- [ ] No object or list is declared — objects come from a parameter/retrieve/create/loop (MDL043); lists from a parameter/retrieve/create list (MDL040)
- [ ] All SET targets have prior DECLARE
- [ ] Association paths are qualified: `$var/Module.Assoc/attr`
- [ ] Enum comparisons use `Module.Enum.Value`
- [ ] Every flow path ends with RETURN
- [ ] Division uses `div` not `/`
- [ ] All statements end with `;`
- [ ] IF/LOOP properly closed with END IF/END LOOP
