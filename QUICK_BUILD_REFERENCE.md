# Quick Build Reference Card

**Created: 2025-09-20**

## 🚀 Most Common Commands

### After Making Any Changes
```bash
# 1. For development testing
yarn generate:android     # Android only
yarn generate:ios        # iOS only
yarn generate            # Both platforms

# 2. For production release
yarn generate:release    # Both platforms optimized
npm pack                 # Create installable package
```

### Daily Workflow
```bash
# Morning setup
git pull origin normalsync-voip-support
yarn install

# After code changes
yarn generate:android    # Quick Android build (~5 min)
yarn typecheck          # Verify types
yarn lint               # Check code style

# Before committing
yarn generate:release   # Full build (~35 min)
git add .
git commit -m "feat: your changes"
git push origin normalsync-voip-support
```

## 📱 Platform-Specific Builds

### Android Only
```bash
export ANDROID_NDK_HOME=$HOME/Android/Sdk/ndk/26.1.10909125
yarn generate:android           # Debug build
yarn generate:release:android   # Release build
```

### iOS Only (macOS required)
```bash
yarn generate:ios               # Debug build
yarn generate:release:ios       # Release build
cd example/ios && pod install  # Update iOS dependencies
```

## 📦 Creating Package for App

### Local Development Package
```bash
# Build everything
yarn generate:release

# Create package
cd package
npm pack
# Creates: unomed-react-native-matrix-sdk-0.7.0.tgz

# Use in your app
cd ~/your-app
yarn add file:../react-native-matrix-sdk/unomed-react-native-matrix-sdk-0.7.0.tgz
```

### Production Release
```bash
# Full release build
yarn generate:release

# Package binaries for GitHub
node scripts/package-binaries.js
# Creates: binaries.tar.gz

# Create NPM package
npm pack
```

## 🔧 Troubleshooting

### Clean Everything and Rebuild
```bash
yarn ubrn:clean
yarn ubrn:checkout
yarn generate:release
```

### Android Build Issues
```bash
# Fix NDK path
export ANDROID_NDK_HOME=$HOME/Android/Sdk/ndk/26.1.10909125

# Clean Android build
cd android
./gradlew clean
cd ..
yarn generate:android
```

### iOS Build Issues
```bash
# Clean iOS build
cd ios
pod deintegrate
pod cache clean --all
pod install
cd ..
yarn generate:ios
```

## ⏱️ Build Times

- `yarn generate:android` → ~5 minutes
- `yarn generate:ios` → ~10 minutes
- `yarn generate` → ~15 minutes
- `yarn generate:release` → ~35 minutes

## 📝 What Each Command Does

| Command | What it does | When to use |
|---------|-------------|------------|
| `yarn generate` | Builds debug binaries for both platforms | Development/testing |
| `yarn generate:release` | Builds optimized binaries | Before release/production |
| `yarn prepare` | Rebuilds TypeScript only | After TS changes |
| `npm pack` | Creates installable .tgz file | For app integration |
| `yarn ubrn:clean` | Removes all generated files | When build is corrupted |

## 🎯 Example: After Adding VoIP Feature

```bash
# 1. Made changes to send VoIP events
vim src/voip-handler.ts

# 2. Build for testing
yarn generate:android

# 3. Test in example app
cd example
yarn android

# 4. If working, build release
cd ..
yarn generate:release

# 5. Create package
npm pack

# 6. Document the change
echo "2025-09-20: Added VoIP support using room.sendRaw()" >> CHANGELOG.md

# 7. Commit
git add .
git commit -m "feat: add VoIP support with encryption"
git push origin normalsync-voip-support
```

---
**Remember**: Always run `yarn generate:release` before using in production!