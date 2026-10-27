package membership

import (
	"context"
	"database/sql"
	"errors"
)

type Membership struct{ OrganizationID, MembershipID, Role string }

// ProvisionFirstLogin is idempotent and can only create an end-user membership in the default organization.
func ProvisionFirstLogin(ctx context.Context, db *sql.DB, subjectID, displayName string) (Membership, error) {
	if db == nil || subjectID == "" {
		return Membership{}, errors.New("database and authenticated subject are required")
	}
	var m Membership
	err := db.QueryRowContext(ctx, `SELECT organization_id::text,membership_id::text,role FROM provision_default_end_user($1,$2)`, subjectID, displayName).Scan(&m.OrganizationID, &m.MembershipID, &m.Role)
	return m, err
}
