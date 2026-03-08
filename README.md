# Fuelex

A Phoenix LiveView web application that calculates fuel requirements for spacecraft interplanetary travel.

## Setup

```bash
# Install dependencies
mix setup

# Start the server
mix phx.server
```

Visit http://localhost:4000

## Description

Users enter their spacecraft mass and build a flight path by selecting planets. The app calculates total fuel required using realistic physics formulas that account for fuel weight itself.

## Spec Overview

### Core Modules

| Module | Purpose |
|--------|---------|
| `Fuelex.FuelCalculator` | Fuel calculation engine |
| `Fuelex.TravelPaths` | Travel path manipulation helpers |
| `Fuelex.TravelPaths.TravelPath` | Embedded schema for travel path |
| `Fuelex.TravelPaths.Flight` | Embedded schema for flights |
| `FuelexWeb.HomeLive` | LiveView for the web interface |

### Supported Planets

| Planet | Gravity (m/s²) |
|--------|----------------|
| Earth | 9.807 |
| Moon | 1.62 |
| Mars | 3.711 |

### Formulas

- **Launch**: `floor(mass × gravity × 0.042 - 33)`
- **Landing**: `floor(mass × gravity × 0.033 - 42)`

The algorithm uses recursion to account for the weight of the fuel itself.
