# CONV006: No Direct Create/Delete Rights
#
# Entity access rules should not grant CREATE or DELETE directly. Instead,
# create and delete operations should go through microflows that enforce
# business logic. Only READ and WRITE should be granted via access rules.
#
# Requires FULL catalog (REFRESH CATALOG FULL).

RULE_ID = "CONV006"
RULE_NAME = "NoCreateDeleteRights"
DESCRIPTION = "Entity access rules should not grant CREATE or DELETE directly; use microflows instead"
CATEGORY = "security"
SEVERITY = "warning"

def check():
    violations = []

    for entity in entities():
        if entity.entity_type != "Persistent" or entity.is_external:
            continue

        for perm in permissions_for(entity.qualified_name):
            if perm.access_type in ("CREATE", "DELETE"):
                violations.append(violation(
                    message="Entity '{}' grants {} to role '{}'. Use a microflow to enforce business logic.".format(
                        entity.qualified_name, perm.access_type, perm.module_role_name
                    ),
                    location=location(
                        module=entity.module_name,
                        document_type="Entity",
                        document_name=entity.qualified_name,
                    ),
                    suggestion="Remove the {} right and implement a microflow (ACT_) with security checks".format(
                        perm.access_type
                    ),
                ))

    return violations
