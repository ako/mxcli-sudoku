# SEC009: Missing Attribute-Level Access Restrictions on Large Entities
#
# When a module role has entity-level READ access but no MEMBER_READ entries
# are configured, all attributes are readable. For entities with many
# attributes (>10) this may expose more data than intended.
#
# Note: absence of MEMBER_READ grants does NOT restrict access — it means
# no attribute filtering is applied and all attributes are returned.
# MEMBER_READ grants are only needed if you want to restrict which attributes
# a role can see.

RULE_ID = "SEC009"
RULE_NAME = "MissingMemberReadRestriction"
DESCRIPTION = "Large entities with entity-level READ access but no attribute-level restrictions"
CATEGORY = "security"
SEVERITY = "info"

def check():
    violations = []
    for e in entities():
        if e.entity_type != "Persistent" or e.is_external:
            continue

        entity_readers = []
        has_member_reads = False

        for perm in permissions_for(e.qualified_name):
            if perm.access_type == "READ" and perm.member_name == "":
                entity_readers.append(perm.module_role_name)
            if perm.access_type == "MEMBER_READ":
                has_member_reads = True

        # Only flag large entities where all-attribute access may be excessive
        if len(entity_readers) > 0 and not has_member_reads and e.attribute_count > 10:
            violations.append(violation(
                message="Entity '{}' ({} attributes) has no attribute-level access restrictions — all {} attributes readable by: {}".format(
                    e.qualified_name,
                    e.attribute_count,
                    e.attribute_count,
                    ", ".join(sorted(entity_readers)),
                ),
                location=location(
                    module=e.module_name,
                    document_type="Entity",
                    document_name=e.qualified_name,
                ),
                suggestion="Consider using attribute-level member grants to restrict which attributes each role can access.",
            ))

    return violations
