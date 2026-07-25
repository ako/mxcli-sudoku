# CONV001: Boolean Attribute Naming
#
# Boolean attributes should start with a verb prefix to clearly indicate
# their true/false nature: Is, Has, Can, Should, Was, or Will.
#
# Examples:
#   Good: IsActive, HasChildren, CanEdit, ShouldNotify
#   Bad:  Active, Children, Edit, Notify
#
# Skips attributes on external entities (marketplace modules).

RULE_ID = "CONV001"
RULE_NAME = "BooleanNaming"
DESCRIPTION = "Boolean attributes should start with Is, Has, Can, Should, Was, or Will"
CATEGORY = "naming"
SEVERITY = "info"

BOOLEAN_PREFIXES = ("Is", "Has", "Can", "Should", "Was", "Will")

def check():
    violations = []

    for entity in entities():
        if entity.is_external:
            continue

        for attr in attributes_for(entity.qualified_name):
            if attr.data_type != "Boolean":
                continue

            name = attr.name
            has_prefix = False
            for prefix in BOOLEAN_PREFIXES:
                if name.startswith(prefix):
                    has_prefix = True
                    break

            if not has_prefix:
                violations.append(violation(
                    message="Boolean attribute '{}.{}' should start with Is, Has, Can, Should, Was, or Will".format(
                        entity.name, name
                    ),
                    location=location(
                        module=entity.module_name,
                        document_type="Entity",
                        document_name=entity.qualified_name,
                    ),
                    suggestion="Rename to 'Is{}' or another appropriate prefix (Has, Can, Should, Was, Will)".format(name),
                ))

    return violations
