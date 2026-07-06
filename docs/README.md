# GiftThread SA

**Design. Personalize. Gift from the heart.**

A modern, full-stack web platform for creating custom clothing and meaningful personalized gifts with a beautiful design experience, fast local South African production, and seamless gifting workflows.

![GiftThread SA Interactive Prototype](https://raw.githubusercontent.com/yourusername/giftthread-sa/main/screenshots/homepage.png)

> **Current Status**: Interactive prototype complete • Full project proposal & technical specification available • Ready for MVP development

---

## Overview

GiftThread SA is a purpose-built platform that enables individuals, corporates, schools, creators, and event planners to design high-quality custom apparel and gifts in minutes. 

The platform combines:
- A premium, intuitive **design customizer** powered by Fabric.js
- Thoughtful **gifting experiences** (recipient messaging, occasion templates, wrapping options)
- **Hybrid fulfillment** (global scale via Printful + fast local Johannesburg production partners)
- Strong focus on **South African context** (local speed, POPIA compliance, cultural relevance)

Unlike generic print-on-demand marketplaces, GiftThread prioritizes emotional connection in gifting and operational excellence for the South African market.

---

## The Problem

South Africans looking for personalized clothing and gifts currently face several pain points:

- Clunky or limited customization tools on existing platforms
- Slow and expensive international fulfillment (customs delays, high shipping costs)
- Poor gifting-specific experiences (no dedicated recipient flows or beautiful unboxing)
- Limited support for local cultural expressions, corporate/team needs, or school events
- Fragmented experience between design, payment, tracking, and reordering

---

## Our Solution

GiftThread delivers a **beautiful, fast, and locally-optimized** end-to-end experience:

1. **Intuitive Design Studio** — Users create professional-looking designs in under 2 minutes using text, photos, and curated templates.
2. **Gifting-First Flows** — Special modes for birthdays, anniversaries, corporate gifting, family, and events with recipient messaging.
3. **Hybrid Production** — Core items fulfilled locally in Johannesburg for speed (2–5 days). Broader catalog via Printful.
4. **Seamless Commerce** — Paystack integration, saved designs, order tracking, and easy reordering.
5. **Trust & Compliance** — POPIA-first approach to personal data and user-generated designs.

---

## Key Features

### For Customers
- **Powerful Customizer**
  - Live realistic preview on products
  - Multiple text layers with rich styling
  - Image uploads with positioning
  - Occasion-based template library
  - Layers management and undo/redo

- **Gifting Experience**
  - Dedicated "Create a Gift" flow
  - Recipient name + personal message
  - Gift wrapping and premium packaging options
  - Scheduled delivery notes

- **Account & Convenience**
  - Save and manage designs
  - Order history and easy reordering
  - Multiple shipping addresses

### For Business / Future
- Corporate & bulk order portal
- Designer marketplace mode (upload & sell designs)
- Analytics dashboard
- AI-assisted design suggestions (planned)

---

## Target Users

| Segment              | Use Cases                              | Example Products          |
|----------------------|----------------------------------------|---------------------------|
| **Individuals**      | Birthdays, anniversaries, "just because" | Custom tees, mugs, totes |
| **Corporates & SMMEs** | Team wear, client gifts, events       | Hoodies, polos, branded gifts |
| **Schools & Universities** | Graduation, sports, staff apparel   | Tees, hoodies, mugs      |
| **Creators & Artists** | Merch drops, fan engagement          | Limited edition apparel  |
| **Events & Weddings** | Bridal parties, guest gifts           | Totes, mugs, apparel     |

---

## Tech Stack (Proposed for MVP)

| Layer          | Technology                              | Rationale |
|----------------|-----------------------------------------|---------|
| **Backend**    | Python + Django + Django REST Framework | Rapid development, robust admin, security |
| **Frontend**   | Angular 18+ + Nx monorepo + Tailwind    | Strong typing, excellent DX for complex UI |
| **Design Editor** | Fabric.js                            | Industry standard for POD customizers |
| **Database**   | PostgreSQL (with JSONB for designs)     | Flexible design storage + relational integrity |
| **Payments**   | Paystack                                | Best-in-class South African support |
| **Fulfillment**| Printful API + Local Johannesburg partners | Breadth + speed |
| **Deployment** | Docker + VPS (Hetzner or similar)       | Control, cost, low latency |

**Interactive Prototype**: Built as a self-contained HTML + Tailwind + Fabric.js experience (included in this repository).

---

## Architecture Highlights

- **Design Data Model**: Flexible JSONB storage for layers, text, images, and positioning — allows the customizer to evolve without heavy migrations.
- **Order Flow**: Payment webhook → Celery task generates print files → Submit to fulfillment provider → Webhook status updates.
- **Hybrid Fulfillment**: Start with Printful for wide catalog. Accelerate high-volume items via local partners (OneOff, Teeprint, etc.).
- **Compliance**: POPIA-ready data handling, consent flows, secure file storage, and content moderation.

---

## Business Model

- **Asset-light POD model** — No inventory.
- Revenue from markup on base product + printing/shipping costs.
- Typical margins: 50–120%+ depending on positioning.
- Future revenue streams: Corporate service fees, premium templates, designer marketplace commissions.

---

## Differentiators

| Factor                    | Generic POD Platforms      | GiftThread SA                     |
|---------------------------|----------------------------|-----------------------------------|
| Customizer Quality        | Basic                      | Premium (Fabric.js + rich tools) |
| Gifting Experience        | Afterthought               | First-class (messages, templates, wrapping) |
| Fulfillment Speed (SA)    | Often slow/international   | Hybrid: Local priority + global scale |
| Cultural & Local Relevance| Low                        | High (templates, partners, compliance) |
| End-to-End Experience     | Fragmented                 | Unified design → payment → tracking |

---

## Current Status & Roadmap

**Completed**
- Full Project Proposal & Technical Specification (v1.0)
- Interactive web prototype (Fabric.js customizer, cart, simulated checkout)
- Market research & competitor analysis

**MVP Roadmap (8–10 weeks)**
1. **Foundation** (Weeks 1–3): Project setup, auth, catalog, basic customizer, Paystack integration
2. **Polish & Fulfillment** (Weeks 4–6): Enhanced customizer, Printful API, order management
3. **Gifting & Launch** (Weeks 7–10): Gift flows, local partner integration, public launch

**Future Phases**
- AI design assistance
- Corporate/B2B portal
- Designer marketplace
- Mobile app (PWA-first)

---

## Getting Started (Prototype)

```bash
# Simply open the prototype in your browser
open index.html
```

Or serve it locally:

```bash
python -m http.server 8000
# Then visit http://localhost:8000
```

**Try these interactions**:
- Click trending products on homepage
- Use the Design Studio (add text, upload images, apply templates)
- Change product colours
- Add items to cart and simulate checkout

---

## Project Structure (Future)

```
giftthread-sa/
├── backend/                 # Django + DRF
├── frontend/                # Angular + Nx
├── prototype/               # Current interactive HTML prototype
├── docs/                    # Proposals, specs, architecture
└── README.md
```

---

## Compliance & South African Context

- **POPIA** compliant data handling and consent flows
- Local production partners for faster delivery and lower environmental impact
- Support for local languages and cultural design elements
- Secure handling of personal designs and customer data

---

## Contributing

This project is currently in active development as a solo-founder initiative with AI-assisted development.

We welcome:
- Feedback on the prototype and proposal
- Suggestions for templates or features
- Introductions to local production partners
- Design contributions (templates, UI improvements)

---

## License & Contact

**Internal / Confidential** — Project proposal and prototype for discussion purposes.

For collaboration, partnership, or investment discussions, please reach out.

---

**Built with ❤️ for South Africa**

*GiftThread SA — Where meaningful gifts are designed, not just ordered.*