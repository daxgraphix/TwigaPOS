# TwigaPOS Setup Guide

## Prerequisites

1. Flutter SDK (3.0.0 or higher)
2. Supabase account (https://supabase.com)

## Supabase Setup

1. Create a new project on Supabase
2. Go to Settings > API
3. Copy your Project URL and anon/public key
4. Update `lib/core/supabase/supabase_config.dart`:
   ```dart
   static const String supabaseUrl = 'https://your-project-id.supabase.co';
   static const String supabaseAnonKey = 'your-anon-key-here';
   ```

## Authentication Setup

1. In your Supabase dashboard, go to Authentication > Settings
2. Configure email confirmation settings as needed
3. The app will automatically handle user registration and login

## Environment Variables (Optional)

You can also set environment variables:
```bash
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

## Building the App

```bash
flutter pub get
flutter run
```

## Features

- Email/Password authentication with Supabase
- Automatic session management
- Protected routes based on authentication status
- User profile management
- Secure logout functionality

## Troubleshooting

- Make sure your Supabase URL and keys are correctly configured
- Check that email confirmation is properly set up in Supabase
- Ensure network connectivity for authentication