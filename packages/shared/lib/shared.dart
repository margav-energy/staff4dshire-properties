// Main export file for the shared package
// Import all shared modules here

// Core Config
export 'core/config/api_config.dart';

// Models
export 'core/models/user_model.dart';
export 'core/models/company_model.dart';
export 'core/models/project_model.dart';
export 'core/models/company_invitation_model.dart';
export 'core/models/invoice_model.dart';
export 'core/models/job_completion_model.dart';
export 'core/models/document_model.dart';
export 'core/models/incident_model.dart';
export 'core/models/onboarding_model.dart';
export 'core/models/cis_onboarding_model.dart';
export 'core/models/chat_models.dart';

// Providers
export 'core/providers/auth_provider.dart';
export 'core/providers/user_provider.dart';
export 'core/providers/company_provider.dart';
export 'core/providers/project_provider.dart';
export 'core/providers/invoice_provider.dart';
export 'core/providers/job_completion_provider.dart';
export 'core/providers/onboarding_provider.dart';
export 'core/providers/notification_provider.dart';
export 'core/providers/timesheet_provider.dart';
export 'core/providers/document_provider.dart';
export 'core/providers/incident_provider.dart';
export 'core/providers/location_provider.dart';
export 'core/providers/xero_provider.dart';
export 'core/providers/chat_provider.dart';

// Services
export 'core/services/api_service.dart';
export 'core/services/user_api_service.dart';
export 'core/services/company_api_service.dart';
export 'core/services/company_invitation_api_service.dart';
export 'core/services/invitation_request_api_service.dart';
export 'core/services/password_reset_api_service.dart';
export 'core/services/timesheet_export_service.dart';
export 'core/services/photo_sync_service.dart';
export 'core/services/notification_api_service.dart';
export 'core/services/chat_api_service.dart';
export 'core/services/chat_socket_service.dart';

// Utils
export 'core/utils/uk_data.dart';
export 'core/utils/notification_sound_player.dart';
export 'core/utils/photo_url_helper.dart';

// Theme
export 'core/theme/app_theme.dart';

