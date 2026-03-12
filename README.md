# 5G NTN Direct-to-Cell Simulator

A high-fidelity, system-level RF and Physical Layer (PHY) modeling framework evaluating the performance of Low Earth Orbit (LEO) satellite constellations providing direct broadband connectivity to unmodified 5G smartphones.

> **Note:** Above: The simulation dashboard actively tracking a LEO constellation pass, highlighting bursty throughput, stochastic SINR drops against the 3GPP demodulation floor, and residual Doppler shifts.

## Overview
As the telecommunications industry races to close the global connectivity gap, Direct-to-Cell (D2C) Non-Terrestrial Networks (NTN) present unique physical layer challenges. This simulator bridges orbital mechanics with advanced RF engineering to answer a critical feasibility question: Can a LEO satellite close a link with an unmodified smartphone (-30 dB/K G/T) and deliver meaningful 5G capacity? 

The simulator is available in **two formats**: 
1. A zero-setup, interactive web dashboard built with Python and Streamlit.
2. A comprehensive Object-Oriented MATLAB desktop application.

Both versions provide a dynamic, time-domain simulation that models phased array beamforming, stochastic channel fading, co-channel interference, and dynamic 3GPP link adaptation.

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

## Accessing the Simulator

### Option 1: The Interactive Web App (Zero Setup)
The fastest way to experience the simulator. It runs directly in your browser on any operating system, requiring no installations or coding knowledge.

👉 **[Click here to launch the 5G NTN Simulator Web App](https://5g-ntn-direct-to-cell-simulator.streamlit.app/)**

### Option 2: The MATLAB Version (Full Desktop Simulation)
For researchers who want to run the core Object-Oriented MATLAB models locally.

**Prerequisites:**
* MATLAB R2023b or newer.
* Required Toolboxes: Satellite Communications Toolbox, Phased Array System Toolbox, Aerospace Toolbox.

**Execution:**
1. Clone this repository: `git clone https://github.com/Bacacielo/5G-NTN-Direct-To-Cell-Simulator.git`
2. Open MATLAB and navigate to the `matlab/` directory.
3. Run the main application file: `app Master_UI;`
4. Use the UI to Generate the Constellation, Build the Array, Steer Beams, and run the Research Engine.

### Option 3: Local Python Execution (For Developers)
If you wish to modify the Streamlit web app code locally:
1. Navigate to the `python/` directory.
2. Install the required dependencies: `pip install -r requirements.txt`
3. Run the app: `streamlit run app.py`

## Future Roadmap / Research Opportunities
* Exporting time-series SINR/Throughput trace files (.csv or .pcap) for ingestion into ns-3 to test TCP/IP congestion control under NTN conditions.
* Implementing Tapped Delay Line (TDL) frequency-selective fading models per 3GPP TR 38.811.
* Machine Learning-based handover optimization algorithms.

***

*Developed as part of advanced telecommunications and aerospace research.* *For inquiries regarding the physics models or simulation architecture, please feel free to reach out.*
