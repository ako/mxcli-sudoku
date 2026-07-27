# CONV002: No Entity Default Values
#
# Default values on entity attributes should be avoided. Set default values
# in a microflow (e.g., BCR_ before create) instead, so the logic is explicit
# and traceable. AutoNumber attributes are excluded.

RULE_ID = "CONV002"
RULE_NAME = "NoEntityDefaultValues"
DESCRIPTION = "Avoid default values on entity attributes; set them in microflows instead"
CATEGORY = "quality"
SEVERITY = "info"

# Data types that commonly have default values set
CHECKED_TYPES = ("String", "Integer", "Long", "Decimal")

def check():
    violations = []

    for entity in entities():
        if entity.is_external:
            continue

        for attr in attributes_for(entity.qualified_name):
            if attr.data_type not in CHECKED_TYPES:
                continue
            if attr.default_value == "":
                continue

            violations.append(violation(
                message="Attribute '{}.{}' has default value '{}'. Use a BCR_ microflow to set defaults instead.".format(
                    entity.name, attr.name, attr.default_value
                ),
                location=location(
                    module=entity.module_name,
                    document_type="Entity",
                    document_name=entity.qualified_name,
                ),
                suggestion="Remove the default value and set it in a Before Create (BCR_) microflow for '{}'".format(entity.name),
            ))

    return violations
