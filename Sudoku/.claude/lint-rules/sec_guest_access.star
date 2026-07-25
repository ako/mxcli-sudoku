# SEC004: Guest Access Enabled
#
# Warns when anonymous/guest access is turned on in project security.
# This is the prerequisite for DIVD-2022-00019: once guest access is
# enabled, any entity access rule granted to the anonymous user role
# without an XPath constraint exposes data to unauthenticated users.
#
# https://csirt.divd.nl/cases/DIVD-2022-00019/

RULE_ID = "SEC004"
RULE_NAME = "GuestAccessEnabled"
DESCRIPTION = "Guest (anonymous) access is enabled - review all entity access rules for the anonymous user role"
CATEGORY = "security"
SEVERITY = "warning"

def check():
    sec = project_security()
    if sec == None:
        return []

    if not sec.enable_guest_access:
        return []

    return [violation(
        message="Guest access is enabled. Review entity access rules granted to the anonymous user role - any unconstrained READ exposes data to unauthenticated users (DIVD-2022-00019).",
        location=location(module="", document_type="security", document_name="ProjectSecurity"),
        suggestion="For each entity accessible to the anonymous role, add an XPath constraint or remove the grant entirely if the data should not be public.",
    )]
