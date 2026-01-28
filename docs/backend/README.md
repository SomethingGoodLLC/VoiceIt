# Backend API Documentation

This folder contains API specifications and documentation for integrating the VoiceIt iOS app with the backend (NextJS/Supabase) at **VoiceItNow.org**.

## 📁 Contents

### [VOTING_API_SPEC.md](./VOTING_API_SPEC.md)
Complete specification for the Roadmap voting API endpoints:
- **Submit Vote** - Record user votes (interested or skip)
- **Get Vote Counts** - Retrieve aggregated vote counts for all features
- Supabase schema with duplicate prevention
- Materialized views for performance
- NextJS implementation examples
- Analytics queries

### [ROADMAP_API_SPEC.md](./ROADMAP_API_SPEC.md)
Complete specification for the Roadmap sponsor referral API:
- **Sponsor Referral Submission** - Accept referrals from users who know potential sponsors
- Request/response formats
- Error handling specifications
- Supabase database schema
- Example NextJS implementation
- Testing examples

## 🔗 Backend Base URL

```
Production: https://voiceitnow.org
```

To change the base URL in the iOS app, edit:
```
VoiceIt/Utilities/Constants.swift → Constants.API.baseURL
```

## 🛠️ Current API Endpoints

### Authentication
- `POST /api/auth/signup` - Create new user account
- `POST /api/auth/login` - User login
- `POST /api/auth/verify` - Verify auth token
- `POST /forgot-password` - Request password reset

### Timeline
- `GET /api/timeline/entries` - Get user's timeline entries
- `POST /api/timeline/entries` - Create new timeline entry

### Analytics
- `POST /api/analytics/app-open` - Track app opens

### Waitlist
- `POST /api/app/waitlist` - Join waitlist

### Roadmap
- `POST /api/roadmap/vote` - Submit a vote for a feature
- `GET /api/roadmap/vote-counts` - Get aggregated vote counts
- `POST /api/roadmap/sponsor-referral` - Submit sponsor referral

## 📝 Adding New API Endpoints

When adding new endpoints:

1. **Update Constants.swift**
   ```swift
   enum Endpoints {
       static let newEndpoint = "/api/new/endpoint"
   }
   ```

2. **Add method to APIService.swift**
   ```swift
   func newMethod() async throws -> Response {
       let url = URL(string: "\(Constants.API.baseURL)\(Constants.API.Endpoints.newEndpoint)")!
       // ... implementation
   }
   ```

3. **Document in this folder**
   - Create a new `.md` file with full specification
   - Include request/response examples
   - Document error codes
   - Provide backend implementation example

## 🔒 Security Notes

- **No authentication required** for anonymous submissions (roadmap votes, sponsor referrals)
- **Bearer token authentication** for user-specific endpoints (timeline, profile)
- **Rate limiting** recommended for public endpoints (10-20 requests per IP per hour)
- **Input validation** always performed server-side
- **HTTPS only** - all requests must use secure connections

## 🧪 Testing

Each API spec document includes:
- cURL examples for testing
- Expected success/error responses
- Common edge cases

## 📊 Database

Backend uses **Supabase (PostgreSQL)** for:
- User accounts and authentication
- Timeline entries
- Sponsor referrals
- Analytics events
- Waitlist entries

See individual spec files for table schemas.

## 🚀 Deployment

Backend is deployed at: **https://voiceitnow.org**

- **Framework**: NextJS
- **Database**: Supabase
- **Hosting**: (TBD - Vercel, Railway, etc.)

## 📮 Questions?

For implementation questions or issues:
1. Check the specific API spec document
2. Review the iOS implementation in `VoiceIt/Services/APIService.swift`
3. Test with cURL examples provided in each spec
