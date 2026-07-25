# CONV003: Page Naming Suffix
#
# Page names should end with a suffix indicating the page type:
#   _NewEdit, _View, _Overview, _Select, _Details, _Dashboard
#
# This makes it easy to identify a page's purpose from its name.
# Info severity - advisory only.

RULE_ID = "CONV003"
RULE_NAME = "PageNamingSuffix"
DESCRIPTION = "Page names should end with a type suffix (_NewEdit, _View, _Overview, _Select, _Details, _Dashboard)"
CATEGORY = "naming"
SEVERITY = "info"

VALID_SUFFIXES = ("_NewEdit", "_View", "_Overview", "_Select", "_Details", "_Dashboard")

def check():
    violations = []

    for page in pages():
        name = page.name
        has_suffix = False
        for suffix in VALID_SUFFIXES:
            if name.endswith(suffix):
                has_suffix = True
                break

        if not has_suffix:
            violations.append(violation(
                message="Page '{}' does not end with a recognized suffix (_NewEdit, _View, _Overview, _Select, _Details, _Dashboard)".format(name),
                location=location(
                    module=page.module_name,
                    document_type="Page",
                    document_name=page.qualified_name,
                ),
                suggestion="Rename the page to include a suffix indicating its purpose, e.g., '{}_Overview'".format(name),
            ))

    return violations
