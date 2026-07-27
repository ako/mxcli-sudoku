# CONV008: Module Role to User Role Mapping
#
# Each module role should be mapped to exactly one user role for a clean
# separation of concerns. A module role mapped to zero user roles is unused;
# a module role mapped to multiple user roles may indicate overlapping
# responsibilities.

RULE_ID = "CONV008"
RULE_NAME = "ModuleRoleMapping"
DESCRIPTION = "Each module role should be mapped to exactly one user role"
CATEGORY = "security"
SEVERITY = "info"

def check():
    violations = []

    # Build a dict of module_role -> set of user_roles
    role_mapping = {}
    for ur in user_roles():
        for mr in ur.module_roles:
            if mr not in role_mapping:
                role_mapping[mr] = []
            role_mapping[mr].append(ur.name)

    for module_role, user_role_list in role_mapping.items():
        if len(user_role_list) > 1:
            violations.append(violation(
                message="Module role '{}' is mapped to {} user roles: {}. Each module role should map to exactly one user role.".format(
                    module_role, len(user_role_list), ", ".join(user_role_list)
                ),
                location=location(
                    module="",
                    document_type="security",
                    document_name="ProjectSecurity",
                ),
                suggestion="Review the user role assignments for '{}' and ensure a 1:1 mapping".format(module_role),
            ))

    return violations
