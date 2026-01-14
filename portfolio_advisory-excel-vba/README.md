# Portfolio Advisory Tool – Excel & VBA

This project is a lightweight **portfolio advisory reporting tool** built with Excel and VBA.
It illustrates how financial advisors can automate parts of a client reporting workflow
using a robust and Mac-compatible Excel setup.

The objective is not to build a production-ready system,
but to demonstrate **structured thinking, clean VBA automation, and realistic financial reporting logic**.

---

## Project Overview

The tool is organised around two core components:

### 1. Portfolio Summary (Client-specific)
- Client profile (segment, risk profile, mandate)
- Assets under management (AUM)
- Strategic allocation overview
- Structured holdings table

### 2. Market Commentary (Macro)
- Swiss macroeconomic environment
- Central bank policy (SNB)
- Inflation dynamics
- Corporate earnings and equity markets
- Geopolitical context


---

## VBA Automation

Two VBA macros are implemented:

- **Refresh Report**
  - Forces full recalculation
  - Updates a timestamp
  - Ensures data consistency

- **Generate Market Commentary**
  - Automatically generates a structured macro commentary
  - Focused on Switzerland (January 2026 context)
  - Uses a fixed layout for reliable rendering on Excel Mac

The VBA code is intentionally kept readable and modular,
and is provided separately in the `/vba` folder.


---

## Market Commentary - Sources & Assumptions

The market commentary is illustrative and based on publicly available information
and consensus views available in early 2026.

Main reference sources include:
- Swiss National Bank (SNB) monetary policy communications
- Swiss inflation and GDP forecasts (SECO, OECD)
- Market outlooks from major Swiss institutions (UBS Group, Pictet)
- International financial media (FT, Bloomberg, Reuters) for geopolitical context

The commentary is not real-time investment advice,
but a template demonstrating how macro views are structured and communicated.

---

## Screenshots

Screenshots of the main sheets are provided in the `/screenshots` folder
to allow quick review without opening Excel.

---

## Disclaimer

This project is for educational and demonstration purposes only.
It does not constitute investment advice.
