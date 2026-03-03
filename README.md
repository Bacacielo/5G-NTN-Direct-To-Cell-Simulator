# 5G NTN Direct-to-Cell Simulator

A high-fidelity, system-level RF and Physical Layer (PHY) modeling framework evaluating the performance of Low Earth Orbit (LEO) satellite constellations providing direct broadband connectivity to unmodified 5G smartphones.

> **Note:** Above: The simulation dashboard actively tracking a LEO constellation pass, highlighting bursty throughput, stochastic SINR drops against the 3GPP demodulation floor, and residual Doppler shifts.

## Overview
As the telecommunications industry races to close the global connectivity gap, Direct-to-Cell (D2C) Non-Terrestrial Networks (NTN) present unique physical layer challenges. This simulator bridges orbital mechanics with advanced RF engineering to answer a critical feasibility question: Can a LEO satellite close a link with an unmodified smartphone (-30 dB/K G/T) and deliver meaningful 5G capacity? Built entirely in Object-Oriented MATLAB, this tool moves beyond static link budget spreadsheets. It provides a dynamic, time-domain simulation that models phased array beamforming, stochastic channel fading, co-channel interference, and dynamic 3GPP link adaptation.

## Key Technical Features

### Advanced Antenna & RF Modeling
* **Phased Array Synthesis:** Dynamically constructs an S-Band (2 GHz) Uniform Rectangular Array (URA) with configurable grid sizes (e.g., 10x10).
* **Spatial Sidelobe Suppression:** Implements Chebwin tapering algorithms to rigorously shape beams and minimize spatial energy leakage.
* **Smartphone Receiver Constraints:** Faithfully models consumer handset limitations using an isotropic antenna profile and a highly restrictive G/T ratio (-30 dB/K).

### Stochastic Channel Physics
* **Elevation-Dependent Fading:** Replaces basic Free Space Path Loss (FSPL) with dynamic Rician fading, where the K-factor adapts in real-time to the satellite's elevation angle.
* **Environmental Degradation:** Incorporates log-normal shadowing and configurable atmospheric/rain attenuation based on the secant of the elevation angle.
* **Co-Channel Interference (CCI):** Aggregates RF leakage from adjacent, un-connected satellites within the constellation to compute true dynamic SINR.

### 3GPP Protocol Integration
* **TS 38.214 Link Adaptation:** Maps real-time SINR to 5G New Radio (NR) spectral efficiencies using standard CQI/MCS tables, stepping from 64-QAM down to QPSK, and cutting off at the -6.5 dB demodulation floor.
* **Predictive Handover Logic:** Analyzes the derivative (trend) of signal degradation alongside hysteresis boundaries to execute seamless handovers before link failure.
* **Doppler & Feeder Constraints:** Simulates GNSS-based residual Doppler pre-compensation errors and enforces 28 GHz Ka-band Gateway feeder link dependencies.

## Simulation Architecture (The 4 Phases)
1. **Orbital Ephemeris Generation:** Uses MATLAB's Satellite Scenario toolbox to propagate multi-plane LEO constellations. Auto-caches ephemeris data (mat) to bypass heavy re-computations.
2. **Array Synthesis:** Builds the physical transmit hardware based on user-defined UI parameters.
3. **Beam Steering:** Establishes line-of-sight targeting between the active constellation and the terrestrial UE.
4. **Research Engine Execution:** The core time-series loop that computes interference, applies stochastic fading, calculates MCS throughput, and renders telemetry to the dashboard.

## Getting Started

### Prerequisites
* MATLAB R2023b or newer.
* **Required Toolboxes:**
  * Satellite Communications Toolbox
  * Phased Array System Toolbox
  * Aerospace Toolbox

### Installation & Execution
1. **Clone the repository:** `git clone https://github.com/yourusername/5G-NTN-Simulator.git`
2. **Open MATLAB** and navigate to the project directory.
3. **Run the main application file:** `app Master_UI();`
4. **Using the UI:**
   * Select your constellation parameters and click Generate Constellation.
   * Execute Phase 2 (Build Array) and Phase 3 (Steer Beams).
   * Toggle the Research Engine ON and hit Phase 4 to run the stochastic physics analysis.

## Future Roadmap / Research Opportunities
* Exporting time-series SINR/Throughput trace files (.csv or .pcap) for ingestion into ns-3 to test TCP/IP congestion control under NTN conditions.
* Implementing Tapped Delay Line (TDL) frequency-selective fading models per 3GPP TR 38.811.
* Machine Learning-based handover optimization algorithms.

***

*Developed as part of advanced telecommunications and aerospace research.* *For inquiries regarding the physics models or simulation architecture, please feel free to reach out.*

