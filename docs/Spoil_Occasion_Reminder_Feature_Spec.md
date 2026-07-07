# Spoils – Occasion Reminder Feature Specification

**Feature Name:** Occasion Reminder + Smart Gifting  
**Version:** 1.0  
**Date:** July 2026  
**Status:** Draft for Review

---

## 1. Overview

### Purpose
The **Occasion Reminder** feature allows users to add important dates (birthdays, anniversaries, etc.) so that **Spoil** can:
- Remind them in advance
- Suggest thoughtful gifts
- Optionally auto-send gifts on their behalf (with approval)

This feature turns Spoil from a one-time gift shop into a **thoughtful relationship companion**.

### Goals
- Reduce the mental load of remembering important dates
- Increase recurring engagement with the app
- Drive higher order frequency and customer lifetime value
- Strengthen emotional connection with the brand

### Non-Goals (for v1)
- Full autonomous gifting without user approval
- Complex recurring subscriptions (covered in separate spec)
- International delivery

---

## 2. User Stories

### Primary User Stories

**As a busy professional**, I want to add my partner’s birthday so that I get reminded in time to send a meaningful gift.

**As a caring child**, I want to be reminded of my parents’ anniversary so I can spoil them without forgetting.

**As a frequent gifter**, I want Spoil to suggest gifts based on the occasion and past preferences so I don’t have to start from scratch every time.

**As a user**, I want to approve or customise any suggested gift before it is sent so I stay in control.

### Secondary User Stories

**As a user**, I want to pause reminders for a specific person temporarily.

**As a user**, I want to see a calendar view of all upcoming occasions.

**As a user**, I want to receive beautiful reminder notifications that feel warm, not spammy.

---

## 3. Core Features (MVP)

### 3.1 Add & Manage Occasions
- Add new occasion (Birthday, Anniversary, “Just Because”, Other)
- Set date and recurrence (yearly by default)
- Add recipient name and relationship
- Add notes (e.g. “Loves plants”, “Avoid chocolate”)
- Edit or delete occasions

### 3.2 Smart Reminders
- Receive reminder **X days before** the occasion (user-configurable: 7, 14, or 21 days)
- Beautiful, warm notification with suggested gifts
- Option to “Remind me later” or “Skip this year”

### 3.3 Gift Suggestions
- Context-aware suggestions based on:
  - Occasion type
  - Recipient relationship & notes
  - Past purchase history
  - Current season / trends
- Ability to browse full catalog from suggestion screen

### 3.4 Approval Flow (for Auto-Gifting)
- User can choose:
  - **Manual mode**: Just get reminded
  - **Assisted mode**: Get reminded + pre-selected gift suggestion
  - **Auto-send mode** (future): Approve once and gift sends automatically

### 3.5 Calendar & Overview
- “My People” screen showing all saved recipients and upcoming occasions
- Calendar view (monthly)
- Quick actions: “Send gift now”, “Edit occasion”, “Mark as sent”

---

## 4. User Flow (MVP)

1. User goes to **“My People”** tab
2. Taps **“+ Add Person / Occasion”**
3. Enters:
   - Recipient name
   - Relationship (Partner, Mom, Friend, Colleague, etc.)
   - Occasion type + date
   - Optional notes & preferences
4. Chooses reminder timing (default = 14 days before)
5. On reminder day:
   - Receives push notification + email
   - Opens app → sees beautiful occasion card with gift suggestions
6. User can:
   - Browse & select a gift
   - Customise message/photo
   - Add to cart or buy immediately
   - Snooze or skip

---

## 5. Data Model

### Core Entities

**Recipient**
- id
- user_id
- name
- relationship
- notes (preferences, allergies, etc.)
- created_at

**Occasion**
- id
- recipient_id
- type (Birthday, Anniversary, Other)
- date (day + month, year optional)
- recurrence (yearly)
- reminder_days_before (default 14)
- notes
- is_active

**ReminderLog**
- id
- occasion_id
- sent_at
- status (sent, opened, acted_on)
- chosen_gift_id (if any)

---

## 6. Notifications Strategy

### Notification Types

| Type                    | Timing                    | Tone                  | Content Example |
|-------------------------|---------------------------|-----------------------|-----------------|
| **Upcoming Reminder**   | 14 days before            | Warm & encouraging    | “Thandi’s birthday is coming up. Ready to spoil her?” |
| **Gentle Nudge**        | 7 days before             | Supportive            | “Still time to find the perfect gift for Mom.” |
| **Day Before**          | 1 day before              | Urgent but kind       | “Tomorrow is the big day. Shall we send something beautiful?” |
| **Post-Gift**           | After delivery            | Celebratory           | “Your gift to Thandi has been delivered. She’s going to love it.” |

**Best Practices:**
- Use rich notifications with images where possible
- Allow users to customise frequency and tone
- Never feel salesy — always feel helpful

---

## 7. Edge Cases & Considerations

- What if the user has multiple occasions on the same day?
- How to handle leap years for birthdays (Feb 29)?
- Should we support cultural/religious occasions (e.g. Eid, Diwali, Passover)?
- Privacy: How do we store recipient data sensitively?
- What happens when a user deletes their account?

---

## 8. Success Metrics (KPIs)

| Metric                          | Target (6 months) | How to Measure                  |
|---------------------------------|-------------------|---------------------------------|
| % of users who add at least 1 occasion | 35%             | Analytics                       |
| Reminder open rate              | > 60%             | Push + email analytics          |
| Conversion from reminder to order | > 25%           | Funnel tracking                 |
| Average number of occasions per active user | 3.5+        | Database query                  |
| Churn reduction for users with occasions | -15%         | Cohort analysis                 |

---

## 9. Future Enhancements (Post-MVP)

- AI-powered gift recommendations based on recipient profile
- Group gifting (multiple people contributing to one gift)
- Integration with phone contacts / calendar
- “Surprise Mode” — fully autonomous gifting within budget
- Shared family calendars
- Corporate team birthday/anniversary management

---

## 10. Open Questions

1. Should we charge for advanced reminder features, or keep it free to drive engagement?
2. How aggressive should we be with notifications?
3. Should we allow users to gift anonymously through the reminder system?

---

## 11. Screen-by-Screen Wireframe Descriptions (MVP)

### Screen 1: My People (Dashboard / Overview)

**Purpose:**  
Central hub where users see all saved recipients and upcoming occasions at a glance.

**Main Elements:**
- Header with greeting + "Add Person" button
- Search bar
- List of recipients (cards or rows)
  - Recipient name + relationship
  - Next upcoming occasion + countdown (e.g., "Mom’s Birthday – in 12 days")
  - Quick action buttons: "Send Gift", "View Details"
- Empty state: "You haven’t added anyone yet. Start spoiling the people you love."

**States:**
- Empty state (first-time users)
- Populated list (sorted by soonest occasion)
- Search results

**Navigation:**
- Tap recipient → goes to Occasion Detail screen
- "Add Person" → Add Occasion flow

---

### Screen 2: Add Occasion / Add Person

**Purpose:**  
Allow users to add a new recipient and their occasion(s).

**Main Elements:**
- Form fields:
  - Recipient Name (required)
  - Relationship (dropdown: Partner, Mom, Dad, Friend, Colleague, Other)
  - Occasion Type (Birthday, Anniversary, “Just Because”, Other)
  - Date picker (day + month, year optional)
  - Notes / Preferences (text area: “Loves plants”, “No chocolate”)
- Reminder timing selector (7 / 14 / 21 days before – default 14)
- Toggle: “Enable reminders for this occasion”
- Save button

**States:**
- Validation errors (missing name, invalid date)
- Success state with confirmation toast

**Navigation:**
- Back button
- After saving → returns to My People screen with new entry highlighted

---

### Screen 3: Occasion Detail Screen

**Purpose:**  
Show details of a specific occasion and allow management.

**Main Elements:**
- Recipient name + relationship
- Occasion type and date
- Countdown banner (“12 days until Thandi’s Birthday”)
- Notes / Preferences section
- Upcoming reminder date
- List of past gifts sent to this person (if any)
- Action buttons:
  - “Send Gift Now”
  - “Edit Occasion”
  - “Pause Reminders”
  - “Delete”

**States:**
- Normal view
- Paused state (shows when reminders are paused)

---

### Screen 4: Reminder Notification & In-App Card

**Purpose:**  
Deliver the reminder in a warm, brand-aligned way.

**Push Notification:**
- Title: “Thandi’s birthday is coming up”
- Body: “Ready to spoil her? We’ve got some beautiful ideas ready for you.”

**In-App Reminder Card (when user opens app):**
- Beautiful hero image (relevant to occasion)
- Warm headline: “Thandi turns 32 in 12 days”
- Suggested gifts (3–4 cards with images + price)
- “Browse more gifts” button
- Quick actions: “Send a gift”, “Remind me later”, “Skip this year”

**Tone:** Warm, encouraging, never pushy.

---

### Screen 5: Gift Suggestion Screen (from Reminder)

**Purpose:**  
Help the user choose and personalise a gift quickly.

**Main Elements:**
- Occasion context header
- Horizontal scroll of recommended gifts (with “Why we picked this” microcopy)
- Full catalog browsing option
- Selected gift preview area
- Message composer (with template suggestions)
- Photo upload option
- Gift wrapping / ribbon selector
- Price summary
- Prominent “Add to Cart” or “Buy Now” button

**States:**
- Loading suggestions
- No suggestions available (fallback to full catalog)
- Personalisation in progress

---

### Screen 6: Calendar View (Nice-to-Have for MVP)

**Purpose:**  
Give users a visual overview of all upcoming occasions.

**Main Elements:**
- Monthly calendar view
- Days with occasions highlighted
- List view below calendar showing upcoming occasions in chronological order
- Quick filters: “This month”, “Next 3 months”, “All”

---

## 12. Next Steps

- User research / validation interviews
- Detailed wireframes based on the screen descriptions above
- Technical architecture for reminders & notifications
- Define initial gift suggestion algorithm
- Notification copy and design system alignment

---

*This spec is ready for review and can be expanded into full product requirements with UI mocks.*