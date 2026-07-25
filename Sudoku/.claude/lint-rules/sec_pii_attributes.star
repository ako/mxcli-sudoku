# SEC006: PII Attributes on Entities with No Access Rules
#
# Detects entities that contain attributes with PII-sounding names
# (email, password, credit card, date of birth, SSN, etc.) but have
# no access rules configured. In Production mode these entities are
# inaccessible, but a security level downgrade would expose them to all users.
#
# This also catches newly created entities where a developer added PII
# fields before configuring access rules.

RULE_ID = "SEC006"
RULE_NAME = "PiiAttributesWithoutAccessRules"
DESCRIPTION = "Entities with PII-sounding attributes should have access rules configured"
CATEGORY = "security"
SEVERITY = "warning"

# Attribute name fragments that suggest personally identifiable information
PII_PATTERNS = [
    "email",
    "password",
    "creditcard",
    "credit_card",
    "cardnumber",
    "card_number",
    "dateofbirth",
    "date_of_birth",
    "birthdate",
    "ssn",
    "socialsecurity",
    "passport",
    "driverlicense",
    "nationalid",
    "phonenumber",
    "phone_number",
    "bsn",
    "iban",
    "taxid",
    "tax_id",
]

def check():
    violations = []

    for e in entities():
        if e.entity_type != "Persistent":
            continue
        if e.is_external:
            continue
        if e.access_rule_count > 0:
            continue  # Has access rules - SEC001 covers the zero-rule case

        # Check if any attribute has a PII-sounding name
        pii_attrs = []
        for attr in attributes_for(e.qualified_name):
            attr_lower = attr.name.lower()
            for pattern in PII_PATTERNS:
                if pattern in attr_lower:
                    pii_attrs.append(attr.name)
                    break

        if len(pii_attrs) > 0:
            violations.append(violation(
                message="Entity '{}' has PII-sounding attributes ({}) but no access rules.".format(
                    e.qualified_name,
                    ", ".join(pii_attrs)
                ),
                location=location(
                    module=e.module_name,
                    document_type="Entity",
                    document_name=e.qualified_name,
                ),
                suggestion="Add access rules with appropriate XPath constraints before this entity contains real data.",
            ))

    return violations
