# Spoil – MVP Technical Architecture

**Version:** 1.0  
**Date:** July 2026  
**Scope:** Minimum Viable Product (MVP)

---

## 1. High-Level Architecture

**Spoil** follows a classic **modern web application architecture**:

- **Frontend**: Single Page Application (SPA)
- **Backend**: REST API
- **Database**: Relational with some JSON flexibility
- **Async Processing**: Task queue for reminders, emails, and order workflows
- **Third-party Integrations**: Payments, image storage, notifications

**Architecture Diagram (Text Representation)**

```
User (Browser / Mobile)
        ↓
   Frontend (Angular)
        ↓ (REST API + JWT)
   Backend (Django + DRF)
        ↓
   PostgreSQL Database
        ↓
   Celery + Redis (Background Tasks)
        ↓
   External Services:
   - Paystack (Payments)
   - Cloudinary / S3 (Images)
   - Email Service (Transactional emails)
   - Push Notification Service
```

---

## 2. Recommended Technology Stack

| Layer              | Technology                          | Reason |
|--------------------|-------------------------------------|--------|
| **Frontend**       | Angular 18+                         | Strong typing, excellent for complex UIs (customisation flow) |
| **Backend**        | Django 5 + Django REST Framework    | Rapid development, robust admin, security, great for MVPs |
| **Database**       | PostgreSQL                          | Reliable, supports JSONB for flexible data (e.g. order customisation) |
| **Task Queue**     | Celery + Redis                      | Background jobs (reminders, emails, order processing) |
| **Payments**       | Paystack                            | Best South African payment gateway with excellent developer experience |
| **Image Storage**  | Cloudinary or AWS S3                | Easy image upload, transformation, and delivery |
| **Authentication** | JWT (SimpleJWT)                     | Stateless, mobile-friendly |
| **Deployment**     | Docker + Docker Compose             | Consistent environments |
| **Hosting**        | VPS (Hetzner / DigitalOcean) or Railway / Render | Cost-effective and controllable |
| **Monitoring**     | Sentry + Basic logging              | Error tracking |

**Alternative Consideration**:  
If speed to market is critical, a **Django + HTMX / Alpine.js** approach could be used instead of full Angular for a lighter frontend. However, Angular is recommended for long-term maintainability.

---

## 3. System Components

### 3.1 Frontend (Angular)
- **Core Modules**:
  - Auth Module
  - Product / Catalog Module
  - Customisation Module
  - Cart & Checkout Module
  - Orders Module
  - Reminders Module (light version)
- State management: NgRx or Angular Signals (recommended for newer versions)
- Routing with lazy loading

### 3.2 Backend (Django)
- **Main Apps**:
  - `users` (authentication & profiles)
  - `products` (catalog, categories, variants)
  - `orders` (cart, checkout, order lifecycle)
  - `customisation` (messages, photos, wrapping options)
  - `reminders` (occasions, notifications)
  - `admin` (extended Django admin)

### 3.3 Background Tasks (Celery)
- Send reminder notifications
- Process order confirmations and status updates
- Handle image processing / optimisation
- Send transactional emails

---

## 4. Data Model (Key Entities)

### Core Models

**User**
- id, email, password, full_name, phone, created_at

**Recipient** (for reminders)
- id, user_id, name, relationship, notes

**Occasion**
- id, recipient_id, type, date, reminder_days_before, is_active

**Product**
- id, name, slug, description, base_price, category, is_active

**ProductVariant** (optional in MVP)
- id, product_id, name, price_modifier, sku

**Order**
- id, user_id, status, total_amount, delivery_address, delivery_date, created_at

**OrderItem**
- id, order_id, product_id, quantity, unit_price, customisation_details (JSONB)

**Customisation**
- id, order_item_id, message, photo_url, wrapping_style, ribbon_color

---

## 5. Key Integrations

| Service          | Purpose                        | Integration Type     | Priority |
|------------------|--------------------------------|----------------------|----------|
| **Paystack**     | Payments                       | REST API + Webhooks  | Critical |
| **Cloudinary**   | Image upload & delivery        | SDK / REST           | High     |
| **Email Service**| Transactional emails           | SMTP or API (e.g. SendGrid, Postmark) | High |
| **Push Notifications** | Reminders & order updates | Firebase / OneSignal | Medium   |

---

## 6. Deployment & Infrastructure

**Recommended Setup for MVP:**

- **Docker Compose** for local development and production
- **PostgreSQL** database
- **Redis** for caching and Celery broker
- **Gunicorn** + **Nginx** for serving the application
- **Celery worker** + **Celery beat** (for scheduled reminders)

**Hosting Options:**
- **Hetzner Cloud** or **DigitalOcean** (cost-effective VPS)
- **Railway** or **Render** (easier managed deployment)

**CI/CD:**
- GitHub Actions for automated testing and deployment (recommended even for MVP)

---

## 7. Security & Compliance

**Must Implement in MVP:**
- HTTPS everywhere
- JWT-based authentication with proper expiration
- Input validation and sanitisation
- Protection against common attacks (SQL injection, XSS, CSRF)
- Secure handling of user-uploaded images
- Basic rate limiting on authentication and checkout endpoints

**POPIA Compliance (South Africa):**
- Clear consent for storing recipient data
- Ability for users to export or delete their data
- Secure storage of personal information

---

## 8. Scalability Considerations (Future)

While keeping MVP simple, the architecture should allow easy scaling:

- Stateless backend (easy horizontal scaling)
- Use of task queues for heavy operations
- Image CDN (Cloudinary) to reduce server load
- Database indexing on frequently queried fields (orders, occasions)
- Potential future move to microservices if needed (not recommended early)

---

## 9. Recommended Development Approach

**Phase 1 – Core Shopping Flow**
1. User authentication
2. Product catalog + detail pages
3. Customisation flow
4. Cart + Paystack checkout
5. Order history

**Phase 2 – Emotional Features**
1. Basic Occasion Reminders
2. Notification system
3. “My People” section

**Phase 3 – Polish & Operations**
1. Admin improvements
2. Better error handling & monitoring
3. Performance optimisation

---

## 10. Summary

**MVP Technical Stack Summary:**

- **Frontend**: Angular 18+
- **Backend**: Django + DRF
- **Database**: PostgreSQL
- **Async**: Celery + Redis
- **Payments**: Paystack
- **Images**: Cloudinary
- **Deployment**: Docker on VPS

This architecture is **robust enough** for a solid MVP while remaining **simple and maintainable** for a small team or solo developer.

---

*Document Version 1.0 | July 2026*