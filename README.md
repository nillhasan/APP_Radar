# AppRadar — Full Starter Project

AI-powered App Opportunity Discovery Platform.

## What is included

- Flutter Web + Android UI prototype
- Dashboard
- Opportunities
- App Details
- Competitors
- Reports
- Build With AI screen
- Sample data so the UI works immediately
- Supabase SQL schema
- Node/TypeScript automation starter
- GitHub Actions daily scheduler
- OpenAI analysis prompt
- Email report template
- Environment variable templates

## Architecture

Flutter -> Supabase -> AI/API layer
                       |
                 GitHub Actions
                       |
                Daily email report

## Fastest way to run the UI

1. Install Flutter.
2. Open `flutter_app`.
3. Run:
   flutter pub get
   flutter run -d chrome

The first version intentionally uses local sample data so the UI can be tested before connecting APIs.

## Next integration steps

1. Create Supabase project.
2. Run `supabase/schema.sql`.
3. Add API keys to GitHub Actions secrets.
4. Connect the TypeScript automation to permitted app-data APIs.
5. Connect Flutter to Supabase.
6. Enable the daily GitHub Actions workflow.

## Important

Do not put OpenAI, Supabase service-role, or email provider secrets inside Flutter code. Secrets belong in server-side functions/GitHub Actions secrets.
