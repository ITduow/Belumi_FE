# Firebase Auth Setup

## Flutter client

`lib/firebase_options.dart` currently contains placeholders for project `belumi-1712f`.

Replace it with the real generated file:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure --project=belumi-1712f
```

This creates the real `lib/firebase_options.dart` values for Web, Android, and iOS.

The Google button flow is:

```text
Web: FirebaseAuth.signInWithPopup(GoogleAuthProvider) -> Firebase ID token -> POST /api/auth/firebase-login -> .NET JWT
Android/iOS: GoogleSignIn -> FirebaseAuth.signInWithCredential -> Firebase ID token -> POST /api/auth/firebase-login -> .NET JWT
```

For web, also check Firebase Console:

1. Authentication -> Sign-in method -> enable Google.
2. Authentication -> Settings -> Authorized domains -> add `localhost`.
3. Project settings -> General -> Your apps -> Web app -> copy config into `lib/firebase_options.dart`.

## Backend

Backend reads Firebase Admin service account from:

```text
C:\tmp\belumi-firebase-admin.json
```

Configured in:

```json
"Firebase": {
  "ServiceAccountPath": "C:\\tmp\\belumi-firebase-admin.json"
}
```

Use a Firebase service account JSON with a valid private key. Do not commit that JSON file.
