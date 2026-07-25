# Starlark Lint Rule: Long Microflows
#
# This rule checks that microflows don't have too many activities.
# Long microflows are hard to understand, test, and maintain.
#
# Thresholds:
#   - Warning: > 25 activities
#   - Consider splitting into sub-microflows (SUB_) for reusability
#
# Microflow properties:
#   .activity_count  - Number of activities in the microflow
#   .complexity      - McCabe cyclomatic complexity

RULE_ID = "QUAL003"
RULE_NAME = "Long Microflows"
DESCRIPTION = "Microflows should not have more than 25 activities"
CATEGORY = "quality"
SEVERITY = "warning"

# Maximum allowed activities per microflow
MAX_ACTIVITIES = 25

def check():
    """
    Check that microflows don't have too many activities.
    Long microflows should be split into smaller, reusable sub-microflows.
    """
    violations = []

    for mf in microflows():
        if mf.activity_count > MAX_ACTIVITIES:
            loc = location(
                module=mf.module_name,
                document_type="Microflow",
                document_name=mf.qualified_name
            )
            v = violation(
                message="Microflow '{}' has {} activities (max: {}). Consider splitting into smaller microflows.".format(
                    mf.name,
                    mf.activity_count,
                    MAX_ACTIVITIES
                ),
                location=loc,
                suggestion="Extract logical sections into SUB_ microflows. This improves readability, testability, and reusability."
            )
            violations.append(v)

    return violations
