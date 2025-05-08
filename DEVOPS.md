# DevOps Implementation for Kony Web Admin

## Overview

This document outlines the DevOps practices implemented for the Kony Web Admin dashboard.

## Testing Framework

- **Framework**: Vitest
- **Coverage**: Integrated with Vitest's coverage capabilities
- **Test Types**: Unit tests for auth utilities

## CI/CD Pipeline

- GitHub Actions workflow for automated testing
- Linting with ESLint
- Automatic deployment to Firebase Hosting

## Run Tests Locally

```bash
# Run tests in watch mode
npm test

# Run tests with coverage
npm run test:coverage
```
