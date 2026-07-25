# CONV004: Enumeration Prefix
#
# Enumeration names should start with ENUM_ to distinguish them from entities
# at a glance. Info severity - advisory only.

RULE_ID = "CONV004"
RULE_NAME = "EnumerationPrefix"
DESCRIPTION = "Enumeration names should start with ENUM_ prefix"
CATEGORY = "naming"
SEVERITY = "info"

def check():
    violations = []

    for enum in enumerations():
        if not enum.name.startswith("ENUM_"):
            violations.append(violation(
                message="Enumeration '{}' does not start with ENUM_ prefix".format(enum.name),
                location=location(
                    module=enum.module_name,
                    document_type="Enumeration",
                    document_name=enum.qualified_name,
                ),
                suggestion="Rename to 'ENUM_{}'".format(enum.name),
            ))

    return violations
