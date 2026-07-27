# SEC007: Unconstrained Entity READ for Anonymous Users
#
# Directly detects the DIVD-2022-00019 pattern: an entity access rule
# grants READ to a module role that is assigned to the anonymous user role,
# with no XPath constraint — meaning every row of that entity is accessible
# to unauthenticated users.
#
# https://csirt.divd.nl/cases/DIVD-2022-00019/

RULE_ID = "SEC007"
RULE_NAME = "UnconstrainedAnonymousEntityRead"
DESCRIPTION = "Entity readable by anonymous users without row-level XPath constraint (DIVD-2022-00019)"
CATEGORY = "security"
SEVERITY = "error"

def check():
    sec = project_security()
    if sec == None or not sec.enable_guest_access:
        return []

    # Collect module roles assigned to anonymous user roles
    anon_module_roles = {}
    for ur in user_roles():
        if ur.is_anonymous:
            for mr in ur.module_roles:
                anon_module_roles[mr] = True

    if len(anon_module_roles) == 0:
        return []

    violations = []
    for e in entities():
        if e.entity_type != "Persistent" or e.is_external:
            continue
        for perm in permissions_for(e.qualified_name):
            if perm.access_type == "READ" and not perm.is_constrained:
                if perm.module_role_name in anon_module_roles:
                    violations.append(violation(
                        message="Entity '{}' is readable by anonymous users (via role '{}') with no XPath constraint — all rows exposed to unauthenticated users. (DIVD-2022-00019)".format(
                            e.qualified_name, perm.module_role_name
                        ),
                        location=location(
                            module=e.module_name,
                            document_type="Entity",
                            document_name=e.qualified_name,
                        ),
                        suggestion="Add an XPath constraint to the access rule for '{}', or remove the grant if this data should not be public.".format(
                            perm.module_role_name
                        ),
                    ))
    return violations
