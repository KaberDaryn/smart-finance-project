# Interface design and user journeys

## Design approach

The browser dashboard is hand-written HTML, CSS, and JavaScript in `web/` with no framework and no build step; the Flutter client in `mobile/` shares the same brand language through its own design kit in `lib/design_system.dart` (palette, themes, panels, stat cards, progress bars, rings, category tiles, buttons). This document describes both clients.

Typography uses Inter and Space Grotesk on the web; the Flutter client uses the bundled Roboto family with tight display weights and tabular figures for amounts. The palette is an emerald brand green on neutral surfaces in both clients: deep green for primary actions, the balance summary, and the planning banner; soft green tints for active navigation and positive amounts; amber for expense accents and overspending warnings. Colour is never the only signal — signs, icons, and labels repeat it.

Both clients follow the operating-system dark-mode preference. The web dashboard selects themes through a `data-theme` attribute with a persisted `localStorage` override (`sf_theme`); the Flutter client ships a matching dark `ThemeData` and lets `ThemeMode.system` decide.

## Layout and components

The web dashboard uses a fixed sidebar with the brand, primary navigation (Overview, Transactions, Insights, Planning), a product card, and the profile row; a topbar shows the breadcrumb, the current month, and a refresh action. The Flutter client keeps the same four destinations in a bottom navigation bar, an app bar with the brand mark and CSV, refresh, and sign-out actions, and a floating add button. Sign-in and modals are separate tasks outside the page flow in both clients.

Each category keeps a stable accent colour and icon (tile in lists, pill, chart segment) across both clients, so a category is recognisable everywhere. Press feedback on mobile uses a short scale-down animation; charts, progress bars, and rings mirror the web proportions.

Components are shared across pages: stat cards for totals, bordered panels for content groups, SVG charts (cash-flow and monthly-trend bars, a category donut, budget and goal progress rings), tables for transaction lists, modals for add/delete/receipt flows, and toasts for save and error confirmations. Each category has a stable accent colour used in its icon chip, table pill, and chart segment, so a category is recognisable across pages.

## Screen specification

| Screen | Main decision | Content and controls |
| --- | --- | --- |
| Sign in / registration | Authenticate or create an account | Username, obscured password with a visibility toggle, create-account switch, inline error alert |
| Overview | Judge the current position at a glance | Greeting, stat cards, cash-flow bars, budget snapshot, recent transactions table, savings goal previews |
| Transactions | Review, add, import, export, or delete records | Search plus type/category/month filters, paginated table with per-row delete, Import CSV, Export, Scan receipt, Add transaction |
| Insights | Understand recorded spending | Category donut with legend, monthly trend bars, observations from the user's own records, forecast note |
| Planning | Set limits or track savings | Month navigation, per-category budget rows with progress bars, budget and goal modals, goal cards with progress rings |
| Modals and toasts | Confirm multi-step or destructive actions | Add transaction (type toggle, exact KZT amount, date, category with suggestion), receipt review, delete confirmations, save confirmations |

## User journeys

1. New account: create an account, record an income, record an expense, inspect the resulting balance.
2. Category suggestion: write an expense description, request a suggestion, accept or edit it, then save.
3. Budget review: set a monthly overall or category budget, add an expense, inspect the in-app overspending alert.
4. Savings: create a target, enter the total amount saved, and inspect progress. This does not transfer money.
5. Import and export: open Import CSV, provide the rows, submit, and inspect the imported records; a repeat of the same CSV adds no duplicate rows. Export downloads the recorded history.
6. Receipt scan: choose Scan receipt, select a photo, review the recognized fields, and confirm explicitly; nothing is saved before confirmation.
7. Connection failure: keep form values, show recovery guidance, and allow the user to check the list before retrying an uncertain save.

## Responsive behaviour and accessibility

Above 1500 pixels the layout gains wider gutters; below 1100 the sidebar narrows and grids tighten; below 800 the sidebar becomes an off-canvas menu behind a scrim and content grids stack; below 520 stat cards and filters fall to a single column and tables scroll horizontally.

Interactive controls keep visible focus rings; icon-only buttons carry aria-labels; form errors use alert semantics and toasts are announced through a polite live region. Motion is limited to short, subtle transitions and respects reduced-motion preferences. Expense direction uses signs and icons as well as colour, and charts keep readable labels. Screen-reader, physical-device, and 200% browser-zoom sessions remain part of the manual review matrix; no completed sessions are claimed.

This is a code-backed design specification. It is not an approved Figma file and does not claim supervisor sign-off.
