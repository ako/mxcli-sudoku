# CONV007: XPath Constraint on All Entity Access
#
# Every READ or WRITE access rule on a persistent entity should have an XPath
# constraint to enforce row-level security. Unconstrained access grants the
# role access to ALL rows, which is rarely the correct intent.
#
# Requires FULL catalog (REFRESH CATALOG FULL).

RULE_ID = "CONV007"
RULE_NAME = "XPathOnAllAccess"
DESCRIPTION = "Entity READ/WRITE access rules should have XPath constraints for row-level security"
CATEGORY = "security"
SEVERITY = "info"

def check():
    violations = []

    for entity in entities():
        if entity.entity_type != "Persistent" or entity.is_external:
            continue

        for perm in permissions_for(entity.qualified_name):
            if perm.access_type not in ("READ", "WRITE"):
                continue
            if perm.is_constrained:
                continue

            violations.append(violation(
                message="Entity '{}' has unconstrained {} access for role '{}' - all rows are accessible".format(
                    entity.qualified_name, perm.access_type, perm.module_role_name
                ),
                location=location(
                    module=entity.module_name,
                    document_type="Entity",
                    document_name=entity.qualified_name,
                ),
                suggestion="Add an XPath constraint to limit which rows '{}' can {} on '{}'".format(
                    perm.module_role_name, perm.access_type, entity.name
                ),
            ))

    return violations
