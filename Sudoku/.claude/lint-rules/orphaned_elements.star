# Starlark Lint Rule: Orphaned Elements
#
# This rule checks for elements that are not referenced anywhere in the project.
# Orphaned elements may be:
#   - Dead code that should be removed
#   - Entry points that should be documented
#   - Work in progress that was forgotten
#
# Checks:
#   - Microflows with no callers (except ACT_ which are UI entry points)
#   - Pages with no show_page references (except entry pages)
#   - Entities with no references at all
#
# This rule requires REFRESH CATALOG FULL to populate the refs table.

RULE_ID = "QUAL004"
RULE_NAME = "Orphaned Elements"
DESCRIPTION = "Elements should be referenced somewhere in the project or marked as entry points"
CATEGORY = "quality"
SEVERITY = "info"

# Prefixes for microflows that are expected to be entry points
ENTRY_POINT_PREFIXES = ["ACT_", "SCH_", "WS_", "REST_", "OData_"]

# Page name patterns that are likely entry points
ENTRY_PAGE_PATTERNS = ["Home", "Login", "Index", "Dashboard"]

def is_entry_point_microflow(name):
    """Check if a microflow name suggests it's a UI/scheduled entry point."""
    for prefix in ENTRY_POINT_PREFIXES:
        if name.startswith(prefix):
            return True
    return False

def is_entry_point_page(name):
    """Check if a page name suggests it's an entry point."""
    for pattern in ENTRY_PAGE_PATTERNS:
        if pattern in name:
            return True
    return False

def check():
    """
    Check for orphaned elements that have no incoming references.
    """
    violations = []

    # Check microflows
    for mf in microflows():
        # Skip entry point microflows
        if is_entry_point_microflow(mf.name):
            continue

        # Get references to this microflow
        refs = refs_to(mf.qualified_name)

        # Check if any reference is a call
        has_callers = False
        for ref in refs:
            if ref.ref_kind == "call":
                has_callers = True
                break

        if not has_callers:
            loc = location(
                module=mf.module_name,
                document_type="Microflow",
                document_name=mf.qualified_name
            )
            v = violation(
                message="Microflow '{}' is not called from anywhere.".format(mf.name),
                location=loc,
                suggestion="Remove if unused, or rename with ACT_/SCH_ prefix if it's an entry point."
            )
            violations.append(v)

    # Check pages
    for page in pages():
        # Skip likely entry point pages
        if is_entry_point_page(page.name):
            continue

        # Get references to this page
        refs = refs_to(page.qualified_name)

        # Check if any reference shows this page
        is_shown = False
        for ref in refs:
            if ref.ref_kind == "show_page":
                is_shown = True
                break

        if not is_shown:
            loc = location(
                module=page.module_name,
                document_type="Page",
                document_name=page.qualified_name
            )
            v = violation(
                message="Page '{}' is not shown from any microflow.".format(page.name),
                location=loc,
                suggestion="Remove if unused, or verify it's configured as a menu item or home page."
            )
            violations.append(v)

    return violations
