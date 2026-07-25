# CONV016: No Entity Event Handlers
#
# Event handlers on entities (before/after commit, create, delete, rollback)
# execute implicitly and can cause hard-to-debug side effects. Use explicit
# microflow calls (BCO_, ACO_, BCR_, ACR_, BDE_, ADE_) instead.

RULE_ID = "CONV016"
RULE_NAME = "NoEventHandlers"
DESCRIPTION = "Avoid entity event handlers; use explicit microflow calls instead"
CATEGORY = "performance"
SEVERITY = "info"

def check():
    violations = []

    for entity in entities():
        if entity.entity_type != "Persistent" or entity.is_external:
            continue

        if entity.has_event_handlers:
            violations.append(violation(
                message="Entity '{}' has event handlers. Event handlers execute implicitly and can cause hidden side effects.".format(
                    entity.qualified_name
                ),
                location=location(
                    module=entity.module_name,
                    document_type="Entity",
                    document_name=entity.qualified_name,
                ),
                suggestion="Replace event handlers with explicit microflow calls (BCO_, ACO_, BCR_, ACR_, BDE_, ADE_ prefixes)",
            ))

    return violations
