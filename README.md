# RTOP – Palantir Foundry Integration

A **Microsoft Dynamics 365 Business Central AL extension** that connects Business Central to [Palantir Foundry](https://www.palantir.com/platforms/foundry/) for data export, analytics, and AI-driven insights.

---

## Features

- **Flexible dataset configuration** – Map any supported BC entity (Customers, Vendors, Items, G/L Accounts) to a Foundry dataset.
- **One-click sync** – Push data from a list or card page with a single action.
- **Scheduled auto-sync** – Enable background sync at a configurable interval.
- **Transaction-safe uploads** – Data is written using Foundry's transaction API; failures automatically abort the transaction to avoid partial writes.
- **Connection test** – Validate Foundry URL and API Token before running a sync.
- **Per-dataset status tracking** – Each dataset stores its last sync time, status, record count, and any error message.

---

## Setup

1. Open **Palantir Setup** (search in Business Central).
2. Enter your **Foundry URL** (e.g. `https://your-org.palantirfoundry.com`).
3. Paste your **API Token** (a Foundry service-account bearer token).
4. Optionally enter the **Compass Project RID** – the folder where new datasets will be created automatically.
5. Click **Test Connection** to verify.
6. Open **Datasets** and create one entry per entity you want to export.

---

## Dataset Configuration

| Field | Description |
|---|---|
| Code | Unique identifier for this dataset config |
| Description | Human-readable name (also used as the Foundry dataset name when auto-creating) |
| Source Type | BC entity to export: Customer, Vendor, Item, G/L Account |
| Dataset RID | Foundry resource identifier – filled automatically on first sync if blank |
| Branch Name | Foundry branch to write to (default: `master`) |
| Enabled | Toggle to include/exclude from scheduled sync |

---

## Supported Source Types

| Source Type | Fields exported |
|---|---|
| Customer | No., Name, City, Country/Region, Currency, Balance (LCY), Balance Due (LCY), Blocked |
| Vendor | No., Name, City, Country/Region, Currency, Balance (LCY), Balance Due (LCY), Blocked |
| Item | No., Description, Type, Unit Price, Unit Cost, Inventory, Base UOM, Blocked |
| G/L Account | No., Name, Account Type, Account Category, Net Change, Balance, Blocked |

---

## Object IDs

| Object | Type | ID |
|---|---|---|
| Palantir Setup | Table | 70000 |
| Palantir Dataset | Table | 70001 |
| Palantir Setup Card | Page | 70000 |
| Palantir Datasets | Page | 70001 |
| Palantir Dataset Card | Page | 70002 |
| Palantir Management | Codeunit | 70000 |
| Palantir API Integration | Codeunit | 70001 |

---

## Build

Requires the **AL Language** extension for VS Code and a Business Central sandbox.

```bash
# Build the .app file
Ctrl+Shift+B  (VS Code AL: Package)
```
