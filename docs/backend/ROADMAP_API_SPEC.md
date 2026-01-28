# Roadmap API Specification for Backend Integration

## Overview
This document specifies the API endpoints needed for the iOS app's Roadmap feature to integrate with your NextJS/Supabase backend.

---

## Endpoint: Submit Sponsor Referral

**URL:** `POST /api/roadmap/sponsor-referral`

**Purpose:** Accept sponsor referrals from users who know potential sponsors for roadmap features.

**Authentication:** None required (anonymous submissions)

### Request Headers
```
Content-Type: application/json
```

### Request Body
```json
{
  "feature_id": "support-groups",
  "referrer": {
    "name": "Jane Doe",
    "email": "jane@example.com",
    "phone": "+1-555-0123"  // optional
  },
  "sponsor": {
    "name": "Tech Company Inc",
    "email": "sponsor@company.com",  // optional
    "phone": "+1-555-0456"  // optional
  },
  "relationship": "Former colleague",  // optional
  "comments": "They have a CSR program focused on supporting survivors",  // optional
  "anon_user_id": "550e8400-e29b-41d4-a716-446655440000",
  "source": "ios",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `feature_id` | string | Yes | ID of the roadmap feature (e.g., "support-groups", "therapy-sessions", "legal-consultations") |
| `referrer.name` | string | Yes | Name of the person making the referral |
| `referrer.email` | string | Yes | Email of the person making the referral |
| `referrer.phone` | string | No | Phone number of the referrer |
| `sponsor.name` | string | Yes | Name or organization of potential sponsor |
| `sponsor.email` | string | No | Email of potential sponsor (if known) |
| `sponsor.phone` | string | No | Phone of potential sponsor (if known) |
| `relationship` | string | No | How the referrer knows the sponsor |
| `comments` | string | No | Additional context about the sponsor |
| `anon_user_id` | string | Yes | Anonymous user ID for analytics (UUID format) |
| `source` | string | Yes | Platform source (always "ios" from iOS app) |
| `timestamp` | string | Yes | ISO8601 timestamp of submission |

---

## Success Response

**Status Code:** `200 OK`

```json
{
  "success": true,
  "message": "Sponsor referral received successfully",
  "referral_id": "ref_abc123xyz"
}
```

### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | Always `true` for successful submissions |
| `message` | string | Human-readable success message |
| `referral_id` | string | Unique ID for the referral (optional but recommended) |

---

## Error Responses

### 400 Bad Request
**Cause:** Missing required fields or invalid data format

```json
{
  "success": false,
  "message": "Missing required field: referrer.email"
}
```

### 422 Unprocessable Entity
**Cause:** Invalid email format or data validation failure

```json
{
  "success": false,
  "message": "Invalid email format for referrer.email"
}
```

### 429 Too Many Requests
**Cause:** Rate limiting (recommend: 10 submissions per IP per hour)

```json
{
  "success": false,
  "message": "Too many referrals. Please try again later."
}
```

### 500 Internal Server Error
**Cause:** Database error or server issue

```json
{
  "success": false,
  "message": "Internal server error. Please try again later."
}
```

---

## iOS App Error Handling

The iOS app includes comprehensive error handling:

✅ **Network connectivity checks**
- Automatic retry on network failure
- User-friendly error messages
- Retry button in error alert

✅ **Loading states**
- Spinner during submission
- Button disabled while submitting
- Prevents duplicate submissions

✅ **Error differentiation**
- Network errors vs server errors
- Specific error messages from API
- Fallback generic messages

✅ **User feedback**
- Success alert on completion
- Error alert with retry option
- Console logging for debugging

---

## Recommended Supabase Schema

### Table: `sponsor_referrals`

```sql
CREATE TABLE sponsor_referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feature_id TEXT NOT NULL,
  
  -- Referrer info
  referrer_name TEXT NOT NULL,
  referrer_email TEXT NOT NULL,
  referrer_phone TEXT,
  
  -- Sponsor info
  sponsor_name TEXT NOT NULL,
  sponsor_email TEXT,
  sponsor_phone TEXT,
  
  -- Additional context
  relationship TEXT,
  comments TEXT,
  
  -- Analytics
  anon_user_id UUID NOT NULL,
  source TEXT NOT NULL DEFAULT 'ios',
  
  -- Status tracking
  status TEXT DEFAULT 'pending', -- 'pending', 'contacted', 'interested', 'declined', 'converted'
  contacted_at TIMESTAMP,
  notes TEXT,
  
  -- Timestamps
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_sponsor_referrals_feature_id ON sponsor_referrals(feature_id);
CREATE INDEX idx_sponsor_referrals_status ON sponsor_referrals(status);
CREATE INDEX idx_sponsor_referrals_created_at ON sponsor_referrals(created_at DESC);
CREATE INDEX idx_sponsor_referrals_anon_user_id ON sponsor_referrals(anon_user_id);

-- RLS (Row Level Security) - Optional
-- Since these are anonymous submissions, you might want to make the table
-- insert-only for anonymous users and read/update only for admins
ALTER TABLE sponsor_referrals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous inserts" ON sponsor_referrals
  FOR INSERT TO anon
  WITH CHECK (true);

CREATE POLICY "Allow admin access" ON sponsor_referrals
  FOR ALL TO authenticated
  USING (true);
```

---

## Example NextJS API Route

```typescript
// app/api/roadmap/sponsor-referral/route.ts
import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    
    // Validate required fields
    const requiredFields = [
      'feature_id',
      'referrer.name',
      'referrer.email',
      'sponsor.name',
      'anon_user_id'
    ];
    
    for (const field of requiredFields) {
      const keys = field.split('.');
      let value = body;
      for (const key of keys) {
        value = value?.[key];
      }
      if (!value) {
        return NextResponse.json(
          {
            success: false,
            message: `Missing required field: ${field}`
          },
          { status: 400 }
        );
      }
    }
    
    // Validate email formats
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(body.referrer.email)) {
      return NextResponse.json(
        {
          success: false,
          message: 'Invalid email format for referrer.email'
        },
        { status: 422 }
      );
    }
    
    // Optional: Rate limiting by IP
    // (Implement using Redis, Upstash, or similar)
    
    // Insert into Supabase
    const { data, error } = await supabase
      .from('sponsor_referrals')
      .insert({
        feature_id: body.feature_id,
        referrer_name: body.referrer.name,
        referrer_email: body.referrer.email,
        referrer_phone: body.referrer.phone || null,
        sponsor_name: body.sponsor.name,
        sponsor_email: body.sponsor.email || null,
        sponsor_phone: body.sponsor.phone || null,
        relationship: body.relationship || null,
        comments: body.comments || null,
        anon_user_id: body.anon_user_id,
        source: body.source || 'ios'
      })
      .select('id')
      .single();
    
    if (error) {
      console.error('Supabase error:', error);
      return NextResponse.json(
        {
          success: false,
          message: 'Failed to save referral'
        },
        { status: 500 }
      );
    }
    
    // Optional: Send notification email to your team
    // await sendNotificationEmail(body);
    
    return NextResponse.json({
      success: true,
      message: 'Sponsor referral received successfully',
      referral_id: `ref_${data.id}`
    });
    
  } catch (error) {
    console.error('API error:', error);
    return NextResponse.json(
      {
        success: false,
        message: 'Internal server error'
      },
      { status: 500 }
    );
  }
}
```

---

## Testing

### Test with cURL:
```bash
curl -X POST https://voiceitnow.org/api/roadmap/sponsor-referral \
  -H "Content-Type: application/json" \
  -d '{
    "feature_id": "support-groups",
    "referrer": {
      "name": "Test User",
      "email": "test@example.com"
    },
    "sponsor": {
      "name": "Test Sponsor Inc"
    },
    "anon_user_id": "550e8400-e29b-41d4-a716-446655440000",
    "source": "ios",
    "timestamp": "2024-01-15T10:30:00Z"
  }'
```

### Expected Success Response:
```json
{
  "success": true,
  "message": "Sponsor referral received successfully",
  "referral_id": "ref_abc123xyz"
}
```

---

## iOS App Configuration

The app currently points to: `https://voiceitnow.org/api/roadmap/sponsor-referral`

To change the base URL, update: `VoiceIt/Utilities/Constants.swift`

```swift
enum API {
    static let baseURL = "https://voiceitnow.org"  // Change this
}
```

---

## Additional Features to Consider

1. **Email Notifications**: Send your team an email when a new referral comes in
2. **Admin Dashboard**: Build a dashboard to review and manage referrals
3. **Status Updates**: Track referral status (pending → contacted → interested → converted)
4. **Duplicate Detection**: Prevent duplicate referrals based on sponsor email
5. **Analytics**: Track which features are getting the most referrals
6. **Follow-up System**: Automated reminders to contact potential sponsors

---

## Questions?

If you have any questions about implementing this endpoint, check:
- The iOS implementation in `VoiceIt/Services/APIService.swift`
- The form UI in `VoiceIt/Views/Roadmap/SponsorFormView.swift`
- Error handling examples in the `submitFormAsync()` method
