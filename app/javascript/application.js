// Entry point for the build script in your package.json
import "bootstrap/dist/js/bootstrap.bundle"

// API Client
import "./api_client"

// Shared utilities
import "./modal"
import "./theme-switcher"
import "./alerts"

// Page-specific scripts
import "./activity-log"
import "./admin-classes"
import "./admin-quiz"
import "./admin-school-profile"
import "./admin-teachers"
import "./admin-teachers-validation"
import "./dashboard-sidebar"
import "./register-create-account"
import "./register-digit-code"
import "./register-verify"
import "./superadmin-dashboard"
import "./superadmin-headmasters"
// Temporarily disabled for /admin/schools page - handled by inline script
// import "./superadmin-schools"
import "./teacher-dashboard"
import "./teacher-students-video"
import "./login-tabs"
import "./login-pin"
import "./management-administrations"
import "./management-parents"
