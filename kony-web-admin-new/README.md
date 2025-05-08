# Kony Web Admin Dashboard

A web-based admin dashboard for the Kony application, allowing administrators to manage technical visit reports and user accounts.

## Features

- User authentication with role-based access control
- Technical visit report management (view, approve, delete)
- PDF generation for reports
- User management

## Technology Stack

- Vanilla JavaScript with Vite for bundling
- Firebase Authentication
- Firestore Database
- Firebase Hosting
- GitHub Actions for CI/CD

## Development

### Prerequisites

- Node.js 16+
- npm 7+
- Firebase CLI

### Setup

1. Clone the repository
2. Install dependencies: `npm install`
3. Start development server: `npm run dev`

### Testing

Run tests with: `npm test`

### Deployment

The project automatically deploys to Firebase Hosting when changes are pushed to the main branch.

Manual deployment: `npm run build && firebase deploy`

## Project Structure

- `src/` - Source code
  - `components/` - UI components
  - `firebase/` - Firebase configuration
  - `utils/` - Utility functions
- `public/` - Static assets
