# SEC008: Unconstrained READ on Entities Containing PII Attributes
#
# Flags entities that contain personally identifiable information (PII) where
# at least one module role has READ access with no XPath constraint.
# An unconstrained READ means a role can retrieve ALL rows — typically
# inappropriate for PII entities where access should be scoped to the
# current user's own data.

RULE_ID = "SEC008"
RULE_NAME = "UnconstrainedPiiRead"
DESCRIPTION = "Roles can read all rows of entities containing PII without XPath row-scoping"
CATEGORY = "security"
SEVERITY = "warning"

PII_PATTERNS = [
    "email",
    "password",
    "creditcard",
    "credit_card",
    "cardnumber",
    "dateofbirth",
    "date_of_birth",
    "birthdate",
    "ssn",
    "socialsecurity",
    "passport",
    "phonenumber",
    "phone_number",
    "bsn",
    "iban",
    "taxid",
    "tax_id",
    "nationalid",
    "driverlicense",
]

def check():
    violations = []
    for e in entities():
        if e.entity_type != "Persistent" or e.is_external:
            continue

        # Check for PII-sounding attributes
        pii_attrs = []
        for attr in attributes_for(e.qualified_name):
            attr_lower = attr.name.lower()
            for pattern in PII_PATTERNS:
                if pattern in attr_lower:
                    pii_attrs.append(attr.name)
                    break

        if len(pii_attrs) == 0:
            continue

        # Find roles with unconstrained READ
        unconstrained_roles = []
        for perm in permissions_for(e.qualified_name):
            if perm.access_type == "READ" and perm.member_name == "" and not perm.is_constrained:
                unconstrained_roles.append(perm.module_role_name)

        if len(unconstrained_roles) > 0:
            violations.append(violation(
                message="Entity '{}' contains PII attributes ({}) and is readable without XPath row constraints by: {}".format(
                    e.qualified_name,
                    ", ".join(pii_attrs),
                    ", ".join(unconstrained_roles),
                ),
                location=location(
                    module=e.module_name,
                    document_type="Entity",
                    document_name=e.qualified_name,
                ),
                suggestion="Add XPath constraints to scope access to the current user's own data, e.g. [Sales.Order_Customer/Sales.Customer/id = '[%CurrentUser%]']",
            ))

    return violations
