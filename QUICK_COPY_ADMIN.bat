@echo off
REM Quick copy script for admin app migration (Windows)
REM Run: QUICK_COPY_ADMIN.bat

cd /d "C:\Users\User\Desktop\Staff4dshire Properties"

echo Creating directories...
if not exist "apps\admin_app\lib\features\auth\screens" mkdir "apps\admin_app\lib\features\auth\screens"
if not exist "apps\admin_app\lib\features\auth\widgets" mkdir "apps\admin_app\lib\features\auth\widgets"
if not exist "apps\admin_app\lib\features\dashboard\screens" mkdir "apps\admin_app\lib\features\dashboard\screens"
if not exist "apps\admin_app\lib\features\dashboard\widgets" mkdir "apps\admin_app\lib\features\dashboard\widgets"
if not exist "apps\admin_app\lib\features\users\screens" mkdir "apps\admin_app\lib\features\users\screens"
if not exist "apps\admin_app\lib\features\companies\screens" mkdir "apps\admin_app\lib\features\companies\screens"
if not exist "apps\admin_app\lib\features\projects\screens" mkdir "apps\admin_app\lib\features\projects\screens"
if not exist "apps\admin_app\lib\features\invoices\screens" mkdir "apps\admin_app\lib\features\invoices\screens"
if not exist "apps\admin_app\lib\features\jobs\screens" mkdir "apps\admin_app\lib\features\jobs\screens"
if not exist "apps\admin_app\lib\features\jobs\widgets" mkdir "apps\admin_app\lib\features\jobs\widgets"
if not exist "apps\admin_app\lib\features\reports\screens" mkdir "apps\admin_app\lib\features\reports\screens"
if not exist "apps\admin_app\lib\features\settings\screens" mkdir "apps\admin_app\lib\features\settings\screens"
if not exist "apps\admin_app\lib\features\onboarding\screens" mkdir "apps\admin_app\lib\features\onboarding\screens"
if not exist "apps\admin_app\lib\features\notifications\screens" mkdir "apps\admin_app\lib\features\notifications\screens"
if not exist "apps\admin_app\lib\features\inductions\screens" mkdir "apps\admin_app\lib\features\inductions\screens"

echo Copying auth features...
xcopy /Y /I "mobile\lib\features\auth\screens\login_screen.dart" "apps\admin_app\lib\features\auth\screens\" >nul 2>&1
xcopy /Y /I "mobile\lib\features\auth\screens\invitation_register_screen.dart" "apps\admin_app\lib\features\auth\screens\" >nul 2>&1
xcopy /Y /E /I "mobile\lib\features\auth\widgets\*" "apps\admin_app\lib\features\auth\widgets\" >nul 2>&1

echo Copying dashboard features...
xcopy /Y /I "mobile\lib\features\dashboard\screens\admin_dashboard_screen.dart" "apps\admin_app\lib\features\dashboard\screens\" >nul 2>&1
xcopy /Y /I "mobile\lib\features\dashboard\screens\superadmin_dashboard_screen.dart" "apps\admin_app\lib\features\dashboard\screens\" >nul 2>&1
xcopy /Y /E /I "mobile\lib\features\dashboard\widgets\*" "apps\admin_app\lib\features\dashboard\widgets\" >nul 2>&1

echo Copying other admin features...
xcopy /Y /E /I "mobile\lib\features\users\*" "apps\admin_app\lib\features\users\" >nul 2>&1
xcopy /Y /E /I "mobile\lib\features\companies\*" "apps\admin_app\lib\features\companies\" >nul 2>&1
xcopy /Y /E /I "mobile\lib\features\projects\*" "apps\admin_app\lib\features\projects\" >nul 2>&1
xcopy /Y /E /I "mobile\lib\features\invoices\*" "apps\admin_app\lib\features\invoices\" >nul 2>&1
xcopy /Y /E /I "mobile\lib\features\jobs\*" "apps\admin_app\lib\features\jobs\" >nul 2>&1
xcopy /Y /E /I "mobile\lib\features\reports\*" "apps\admin_app\lib\features\reports\" >nul 2>&1
xcopy /Y /E /I "mobile\lib\features\settings\*" "apps\admin_app\lib\features\settings\" >nul 2>&1
xcopy /Y /E /I "mobile\lib\features\onboarding\*" "apps\admin_app\lib\features\onboarding\" >nul 2>&1
xcopy /Y /E /I "mobile\lib\features\notifications\*" "apps\admin_app\lib\features\notifications\" >nul 2>&1
xcopy /Y /E /I "mobile\lib\features\inductions\*" "apps\admin_app\lib\features\inductions\" >nul 2>&1

echo Copying additional providers to shared package...
xcopy /Y /I "mobile\lib\core\providers\invoice_provider.dart" "packages\shared\lib\core\providers\" >nul 2>&1
xcopy /Y /I "mobile\lib\core\providers\job_completion_provider.dart" "packages\shared\lib\core\providers\" >nul 2>&1
xcopy /Y /I "mobile\lib\core\providers\onboarding_provider.dart" "packages\shared\lib\core\providers\" >nul 2>&1
xcopy /Y /I "mobile\lib\core\providers\notification_provider.dart" "packages\shared\lib\core\providers\" >nul 2>&1

echo.
echo Done! Next steps:
echo 1. Fix import paths in copied files
echo 2. Update packages\shared\lib\shared.dart to export new providers
echo 3. Create admin router
echo 4. Update apps\admin_app\lib\main.dart
echo.
pause



