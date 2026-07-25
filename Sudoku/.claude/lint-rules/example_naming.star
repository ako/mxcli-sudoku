# Example Starlark Lint Rule: Entity Naming Convention
#
# This rule checks that entity names follow PascalCase naming convention.
# Place .star files in .claude/lint-rules/ to add custom lint rules.
#
# Available query functions:
#   entities()         - Returns list of all entities in the catalog
#   microflows()       - Returns list of all microflows
#   pages()            - Returns list of all pages
#   enumerations()     - Returns list of all enumerations
#   widgets()          - Returns list of all widgets
#   attributes_for(qn) - Returns attributes for entity qualified name
#   refs_to(name)      - Returns cross-references to a target
#   project_security() - Returns project security settings (or None)
#
# Entity properties:
#   .id                - Document ID
#   .name              - Simple name (e.g., "Customer")
#   .qualified_name    - Full name (e.g., "MyModule.Customer")
#   .module_name       - Module name (e.g., "MyModule")
#   .entity_type       - "Persistent", "NonPersistent", or "View"
#   .description       - Documentation
#   .generalization    - Parent entity if any
#   .attribute_count   - Number of attributes
#   .access_rule_count - Number of access rules
#   .is_external       - True if entity is from an external service
#
# Helper functions:
#   is_pascal_case(s)  - Returns True if string is PascalCase
#   is_camel_case(s)   - Returns True if string is camelCase
#   matches(s, pattern) - Returns True if string matches regex pattern
#   violation(message, location?, suggestion?) - Create a violation
#   location(module, document_type, document_name, document_id?) - Create location
#
# Full API reference: .claude/skills/mendix/write-lint-rules.md

# Rule metadata - these are required
RULE_ID = "CUSTOM001"
RULE_NAME = "Entity PascalCase"
DESCRIPTION = "Entity names must use PascalCase naming convention"
CATEGORY = "naming"
SEVERITY = "warning"

def check():
    """
    Main check function - called by the linter.
    Returns a list of violations.

    The function takes no arguments - use the built-in entities(), microflows(),
    pages(), and enumerations() functions to access catalog data.
    """
    violations = []

    for entity in entities():
        name = entity.name  # Simple name without module prefix

        # Skip if already PascalCase
        if is_pascal_case(name):
            continue

        # Create a violation with location
        loc = location(
            module=entity.module_name,
            document_type="Entity",
            document_name=entity.qualified_name
        )
        v = violation(
            message="Entity '{}' should use PascalCase naming".format(name),
            location=loc
        )
        violations.append(v)

    return violations
