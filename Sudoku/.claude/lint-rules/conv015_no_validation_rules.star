# CONV015: No Entity Validation Rules
#
# Validation rules on entities should be avoided. Use microflows (VAL_ prefix)
# for validation logic instead, as it is more explicit, testable, and provides
# better user feedback. Entity validation rules run implicitly on commit and
# can be hard to debug.

RULE_ID = "CONV015"
RULE_NAME = "NoEntityValidationRules"
DESCRIPTION = "Avoid entity validation rules; use VAL_ microflows for validation instead"
CATEGORY = "quality"
SEVERITY = "info"

def check():
    violations = []

    for entity in entities():
        if entity.entity_type != "Persistent" or entity.is_external:
            continue

        if entity.validation_rule_count > 0:
            violations.append(violation(
                message="Entity '{}' has {} validation rule(s). Use VAL_ microflows for validation logic instead.".format(
                    entity.qualified_name, entity.validation_rule_count
                ),
                location=location(
                    module=entity.module_name,
                    document_type="Entity",
                    document_name=entity.qualified_name,
                ),
                suggestion="Replace entity validation rules with a VAL_{} microflow for explicit, testable validation".format(entity.name),
            ))

    return violations
