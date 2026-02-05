# Deploying Flutter Web Apps to Render

## ⚠️ Important: Flutter Build Environment

Render's static site build environment **does not include Flutter** by default. You have two options:

## Option 1: Build Locally and Commit (Recommended for Quick Demo)

This is the fastest way to get your apps deployed:

1. **Build Admin App Locally:**
   ```bash
   cd apps/admin_app
   flutter build web --release
   ```

2. **Build Staff App Locally:**
   ```bash
   cd apps/staff_app
   flutter build web --release
   ```

3. **Commit the build folders:**
   ```bash
   git add apps/admin_app/build/web
   git add apps/staff_app/build/web
   git commit -m "Add Flutter web builds for deployment"
   git push
   ```

4. **Deploy on Render:**
   - Create Static Site
   - Root Directory: `apps/admin_app`
   - Build Command: `echo "Using pre-built files"`
   - Publish Directory: `apps/admin_app/build/web`

## Option 2: Use Custom Dockerfile (Advanced)

If you want Render to build Flutter automatically, you'll need a custom Dockerfile:

1. **Create Dockerfile in `apps/admin_app/`:**
   ```dockerfile
   FROM ubuntu:22.04

   # Install dependencies
   RUN apt-get update && apt-get install -y \
       curl \
       git \
       unzip \
       xz-utils \
       zip \
       libglu1-mesa

   # Install Flutter
   RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter
   ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

   # Verify Flutter installation
   RUN flutter doctor

   # Set working directory
   WORKDIR /app

   # Copy pubspec files
   COPY pubspec.yaml pubspec.lock ./
   COPY ../../packages/shared/pubspec.yaml ../../packages/shared/pubspec.lock ../../packages/shared/

   # Get dependencies
   RUN flutter pub get

   # Copy source code
   COPY . .

   # Build web
   RUN flutter build web --release

   # Serve with nginx
   FROM nginx:alpine
   COPY --from=0 /app/build/web /usr/share/nginx/html
   ```

2. **Update Render to use Docker:**
   - In Render, select "Docker" as the environment
   - Point to the Dockerfile location

## Option 3: Use GitHub Actions (Best for CI/CD)

Create `.github/workflows/deploy-flutter-web.yml`:

```yaml
name: Build and Deploy Flutter Web

on:
  push:
    branches: [main]

jobs:
  build-admin:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: cd apps/admin_app && flutter pub get
      - run: cd apps/admin_app && flutter build web --release
      - uses: actions/upload-artifact@v3
        with:
          name: admin-web-build
          path: apps/admin_app/build/web

  build-staff:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: cd apps/staff_app && flutter pub get
      - run: cd apps/staff_app && flutter build web --release
      - uses: actions/upload-artifact@v3
        with:
          name: staff-web-build
          path: apps/staff_app/build/web
```

Then deploy the artifacts to Render.

## 🎯 Recommended Approach for Stakeholder Demo

**Use Option 1** (build locally and commit):
- Fastest to set up
- No complex configuration
- Works immediately
- You can rebuild and push updates anytime

## 📝 Steps for Option 1

1. **Update API URL first:**
   ```dart
   // In packages/shared/lib/core/config/api_config.dart
   static const String _productionUrl = 'https://your-backend.onrender.com/api';
   ```

2. **Build both apps:**
   ```bash
   # Admin app
   cd apps/admin_app
   flutter clean
   flutter pub get
   flutter build web --release

   # Staff app
   cd ../staff_app
   flutter clean
   flutter pub get
   flutter build web --release
   ```

3. **Add to .gitignore exception (if needed):**
   - If `build/` is in `.gitignore`, temporarily remove it or force add:
   ```bash
   git add -f apps/admin_app/build/web
   git add -f apps/staff_app/build/web
   ```

4. **Commit and push:**
   ```bash
   git add .
   git commit -m "Add Flutter web builds for Render deployment"
   git push
   ```

5. **Deploy on Render:**
   - Create Static Site for admin app
   - Root: `apps/admin_app`
   - Build: `echo "Using pre-built files"` (or leave empty)
   - Publish: `apps/admin_app/build/web`
   - Repeat for staff app

## 🔄 Updating After Changes

When you make code changes:

1. Update API config if backend URL changed
2. Rebuild locally:
   ```bash
   cd apps/admin_app && flutter build web --release
   cd ../staff_app && flutter build web --release
   ```
3. Commit and push:
   ```bash
   git add apps/*/build/web
   git commit -m "Update Flutter web builds"
   git push
   ```
4. Render will auto-redeploy

## ✅ Verification

After deployment, check:
- ✅ Admin app loads at your Render URL
- ✅ Staff app loads at your Render URL
- ✅ Both apps can connect to backend API
- ✅ Login works
- ✅ No CORS errors in browser console
