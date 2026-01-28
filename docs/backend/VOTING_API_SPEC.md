# Roadmap Voting API Specification

## Overview
This document specifies the API endpoints for the iOS app's Roadmap voting feature, allowing users to vote on features they want and track community interest.

---

## Endpoint 1: Submit Vote

**URL:** `POST /api/roadmap/vote`

**Purpose:** Record a user's vote (interest or skip) for a roadmap feature.

**Authentication:** None required (anonymous voting)

### Request Headers
```
Content-Type: application/json
```

### Request Body
```json
{
  "feature_id": "support-groups",
  "vote_type": "interested",
  "anon_user_id": "550e8400-e29b-41d4-a716-446655440000",
  "source": "ios",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `feature_id` | string | Yes | ID of the feature being voted on (e.g., "support-groups", "therapy-sessions") |
| `vote_type` | string | Yes | Type of vote: `"interested"` or `"not_important"` |
| `anon_user_id` | string | Yes | Anonymous user ID (UUID format) - prevents duplicate votes |
| `source` | string | Yes | Platform source (always "ios" from iOS app) |
| `timestamp` | string | Yes | ISO8601 timestamp of vote |

### Vote Type Values
- `"interested"` - User clicked "❤️ I Want This Feature"
- `"not_important"` - User clicked "⏳ Not Important to Me Right Now"

---

## Success Response

**Status Code:** `200 OK`

```json
{
  "success": true,
  "message": "Vote recorded successfully",
  "vote_id": "vote_abc123xyz"
}
```

### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | Always `true` for successful votes |
| `message` | string | Human-readable success message |
| `vote_id` | string | Unique ID for this vote (optional but recommended) |

---

## Error Responses

### 400 Bad Request
**Cause:** Missing required fields or invalid data

```json
{
  "success": false,
  "message": "Missing required field: feature_id"
}
```

### 409 Conflict
**Cause:** User has already voted on this feature

```json
{
  "success": false,
  "message": "You have already voted on this feature"
}
```

### 422 Unprocessable Entity
**Cause:** Invalid vote_type or feature_id

```json
{
  "success": false,
  "message": "Invalid vote_type. Must be 'interested' or 'not_important'"
}
```

### 429 Too Many Requests
**Cause:** Rate limiting (recommend: 50 votes per user per hour)

```json
{
  "success": false,
  "message": "Too many votes. Please try again later."
}
```

---

## Endpoint 2: Get Vote Counts

**URL:** `GET /api/roadmap/vote-counts`

**Purpose:** Retrieve aggregated vote counts for all roadmap features.

**Authentication:** None required (public data)

### Request Headers
```
None required
```

### Query Parameters
None

---

## Success Response

**Status Code:** `200 OK`

```json
{
  "success": true,
  "counts": {
    "support-groups": {
      "interested": 247,
      "skipped": 12
    },
    "therapy-sessions": {
      "interested": 189,
      "skipped": 8
    },
    "legal-consultations": {
      "interested": 156,
      "skipped": 15
    },
    "resource-library": {
      "interested": 98,
      "skipped": 23
    },
    "shelter-map": {
      "interested": 312,
      "skipped": 7
    }
  }
}
```

### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | Always `true` for successful requests |
| `counts` | object | Dictionary of feature_id → vote counts |
| `counts[feature_id].interested` | integer | Number of "I Want This" votes |
| `counts[feature_id].skipped` | integer | Number of "Not Important" votes |

---

## iOS App Behavior

### Optimistic UI Updates
The iOS app updates the UI immediately when a user votes, then submits to the backend in the background:

1. ✅ User clicks vote button
2. ✅ UI updates instantly (button changes, count increments)
3. ✅ Vote saved to local storage (works offline)
4. ✅ Backend submission happens asynchronously
5. ✅ If backend fails, vote remains saved locally
6. ✅ Counts refresh from backend on next app launch

### Error Handling
- **Network errors**: Silent failure, vote saved locally
- **Server errors**: Silent failure, vote saved locally
- **Duplicate votes**: iOS prevents multiple votes via local check
- **Offline mode**: Votes queue locally, submit when online (future feature)

### Vote Counts Refresh Strategy
- **On app launch**: Fetch latest counts from backend
- **After successful vote**: Refresh counts to show updated totals
- **Manual refresh**: User can pull-to-refresh on roadmap view (future feature)
- **Fallback**: Use locally cached counts if backend unavailable

---

## Recommended Supabase Schema

### Table: `roadmap_votes`

```sql
CREATE TABLE roadmap_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feature_id TEXT NOT NULL,
  vote_type TEXT NOT NULL CHECK (vote_type IN ('interested', 'not_important')),
  anon_user_id UUID NOT NULL,
  source TEXT NOT NULL DEFAULT 'ios',
  
  -- Prevent duplicate votes from same user
  UNIQUE(feature_id, anon_user_id),
  
  -- Timestamps
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_roadmap_votes_feature_id ON roadmap_votes(feature_id);
CREATE INDEX idx_roadmap_votes_anon_user_id ON roadmap_votes(anon_user_id);
CREATE INDEX idx_roadmap_votes_created_at ON roadmap_votes(created_at DESC);

-- Index for aggregation queries
CREATE INDEX idx_roadmap_votes_feature_type ON roadmap_votes(feature_id, vote_type);
```

### Materialized View for Fast Counts (Optional)

```sql
-- Create materialized view for fast count queries
CREATE MATERIALIZED VIEW roadmap_vote_counts AS
SELECT 
  feature_id,
  COUNT(*) FILTER (WHERE vote_type = 'interested') AS interested,
  COUNT(*) FILTER (WHERE vote_type = 'not_important') AS skipped
FROM roadmap_votes
GROUP BY feature_id;

-- Refresh materialized view (run periodically or after votes)
REFRESH MATERIALIZED VIEW roadmap_vote_counts;

-- Index on materialized view
CREATE UNIQUE INDEX idx_vote_counts_feature ON roadmap_vote_counts(feature_id);
```

### Function to Get or Update Vote

```sql
-- Function to insert or update vote (prevents duplicates)
CREATE OR REPLACE FUNCTION upsert_roadmap_vote(
  p_feature_id TEXT,
  p_vote_type TEXT,
  p_anon_user_id UUID,
  p_source TEXT
) RETURNS UUID AS $$
DECLARE
  v_vote_id UUID;
BEGIN
  INSERT INTO roadmap_votes (feature_id, vote_type, anon_user_id, source)
  VALUES (p_feature_id, p_vote_type, p_anon_user_id, p_source)
  ON CONFLICT (feature_id, anon_user_id) 
  DO UPDATE SET 
    vote_type = EXCLUDED.vote_type,
    updated_at = NOW()
  RETURNING id INTO v_vote_id;
  
  RETURN v_vote_id;
END;
$$ LANGUAGE plpgsql;
```

---

## Example NextJS API Routes

### Route 1: Submit Vote

```typescript
// app/api/roadmap/vote/route.ts
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
    if (!body.feature_id || !body.vote_type || !body.anon_user_id) {
      return NextResponse.json(
        {
          success: false,
          message: 'Missing required fields'
        },
        { status: 400 }
      );
    }
    
    // Validate vote_type
    if (!['interested', 'not_important'].includes(body.vote_type)) {
      return NextResponse.json(
        {
          success: false,
          message: "Invalid vote_type. Must be 'interested' or 'not_important'"
        },
        { status: 422 }
      );
    }
    
    // Use upsert function to handle duplicates
    const { data, error } = await supabase
      .rpc('upsert_roadmap_vote', {
        p_feature_id: body.feature_id,
        p_vote_type: body.vote_type,
        p_anon_user_id: body.anon_user_id,
        p_source: body.source || 'ios'
      });
    
    if (error) {
      console.error('Supabase error:', error);
      return NextResponse.json(
        {
          success: false,
          message: 'Failed to record vote'
        },
        { status: 500 }
      );
    }
    
    // Optional: Refresh materialized view
    // await supabase.rpc('refresh_vote_counts');
    
    return NextResponse.json({
      success: true,
      message: 'Vote recorded successfully',
      vote_id: `vote_${data}`
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

### Route 2: Get Vote Counts

```typescript
// app/api/roadmap/vote-counts/route.ts
import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

export async function GET() {
  try {
    // Option 1: Query materialized view (fastest)
    const { data: materializedData, error: mvError } = await supabase
      .from('roadmap_vote_counts')
      .select('*');
    
    if (!mvError && materializedData) {
      // Convert to expected format
      const counts: Record<string, { interested: number; skipped: number }> = {};
      for (const row of materializedData) {
        counts[row.feature_id] = {
          interested: row.interested || 0,
          skipped: row.skipped || 0
        };
      }
      
      return NextResponse.json({
        success: true,
        counts
      });
    }
    
    // Option 2: Fallback to live aggregation
    const { data, error } = await supabase
      .from('roadmap_votes')
      .select('feature_id, vote_type');
    
    if (error) {
      console.error('Supabase error:', error);
      return NextResponse.json(
        {
          success: false,
          message: 'Failed to fetch vote counts'
        },
        { status: 500 }
      );
    }
    
    // Aggregate counts
    const counts: Record<string, { interested: number; skipped: number }> = {};
    
    for (const vote of data || []) {
      if (!counts[vote.feature_id]) {
        counts[vote.feature_id] = { interested: 0, skipped: 0 };
      }
      
      if (vote.vote_type === 'interested') {
        counts[vote.feature_id].interested++;
      } else if (vote.vote_type === 'not_important') {
        counts[vote.feature_id].skipped++;
      }
    }
    
    return NextResponse.json({
      success: true,
      counts
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

// Optional: Enable caching
export const revalidate = 60; // Cache for 60 seconds
```

---

## Testing

### Test Vote Submission:
```bash
curl -X POST https://voiceitnow.org/api/roadmap/vote \
  -H "Content-Type: application/json" \
  -d '{
    "feature_id": "support-groups",
    "vote_type": "interested",
    "anon_user_id": "550e8400-e29b-41d4-a716-446655440000",
    "source": "ios",
    "timestamp": "2024-01-15T10:30:00Z"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Vote recorded successfully",
  "vote_id": "vote_abc123xyz"
}
```

### Test Get Counts:
```bash
curl https://voiceitnow.org/api/roadmap/vote-counts
```

**Expected Response:**
```json
{
  "success": true,
  "counts": {
    "support-groups": {
      "interested": 247,
      "skipped": 12
    }
  }
}
```

---

## Performance Considerations

### For High Traffic:

1. **Use Materialized Views**
   - Pre-compute counts in materialized view
   - Refresh every 5-10 minutes
   - Much faster than live aggregation

2. **Enable Response Caching**
   - Cache GET /vote-counts for 30-60 seconds
   - Reduces database load
   - Slightly stale data is acceptable

3. **Add Database Indexes**
   - Index on (feature_id, vote_type) for aggregation
   - Index on (anon_user_id) for duplicate detection
   - Index on (created_at) for analytics

4. **Rate Limiting**
   - Limit to 50 votes per user per hour
   - Prevent abuse and spam
   - Use Redis or Upstash for distributed rate limiting

---

## Analytics & Insights

### Recommended Queries:

**Most Popular Features:**
```sql
SELECT 
  feature_id,
  COUNT(*) FILTER (WHERE vote_type = 'interested') as wants,
  COUNT(*) FILTER (WHERE vote_type = 'not_important') as skips,
  ROUND(
    COUNT(*) FILTER (WHERE vote_type = 'interested')::numeric / 
    NULLIF(COUNT(*), 0) * 100, 
    2
  ) as interest_percentage
FROM roadmap_votes
GROUP BY feature_id
ORDER BY wants DESC;
```

**Vote Trends Over Time:**
```sql
SELECT 
  feature_id,
  DATE(created_at) as date,
  COUNT(*) FILTER (WHERE vote_type = 'interested') as daily_interested,
  COUNT(*) FILTER (WHERE vote_type = 'not_important') as daily_skipped
FROM roadmap_votes
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY feature_id, DATE(created_at)
ORDER BY date DESC, daily_interested DESC;
```

**Unique Voters:**
```sql
SELECT 
  feature_id,
  COUNT(DISTINCT anon_user_id) as unique_voters
FROM roadmap_votes
GROUP BY feature_id
ORDER BY unique_voters DESC;
```

---

## iOS App Configuration

Endpoints are configured in `VoiceIt/Utilities/Constants.swift`:

```swift
enum Endpoints {
    static let roadmapVote = "/api/roadmap/vote"
    static let roadmapVoteCounts = "/api/roadmap/vote-counts"
}
```

Implementation in `VoiceIt/Services/APIService.swift` and `VoiceIt/Services/RoadmapStore.swift`.

---

## Security Notes

- ✅ Anonymous voting (no authentication required)
- ✅ Duplicate prevention via (feature_id, anon_user_id) unique constraint
- ✅ Rate limiting recommended (50 votes/user/hour)
- ✅ Input validation on server side
- ✅ HTTPS only
- ⚠️ Consider adding CAPTCHA for public endpoints if spam becomes an issue

---

## Future Enhancements

1. **Vote History**: Allow users to see their past votes
2. **Vote Deletion**: Allow users to remove their vote
3. **Vote Comments**: Let users explain why they want a feature
4. **Push Notifications**: Notify voters when features are released
5. **Email Updates**: Send progress updates to interested voters
6. **Admin Dashboard**: Visualize vote trends and feature prioritization
