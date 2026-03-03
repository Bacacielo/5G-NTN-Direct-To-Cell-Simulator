# 🛰️ 5G Non-Terrestrial Network (NTN) Direct-to-Cell Simulator

![MATLAB](https://img.shields.io/badge/MATLAB-R2023b%2B-blue)
![Domain](https://img.shields.io/badge/Domain-Aerospace%20%7C%20Telecommunications-red)
![Standard](https://img.shields.io/badge/3GPP-Release%2018%20(5G--Advanced)-brightgreen)

## 📌 Project Overview
This project is a system-level engineering simulation of a **Direct-to-Cell (D2C) Low Earth Orbit (LEO) satellite** providing 5G connectivity to an unmodified terrestrial smartphone. 

Modeled after current industry efforts by companies like AST SpaceMobile and SpaceX, this simulator calculates the hardcore RF physics required to close a link from space to ground. It actively models Free Space Path Loss (FSPL), dynamic electronic beam-steering using phased array antennas, and extreme Doppler shifts caused by orbital velocities.

## ✨ Key Features
* **Interactive Master UI:** A custom-built control panel to configure satellite hardware (Antenna Array Size and Transmit Power) without altering the underlying code.
* **Custom Phased Array Design:** Generates a Uniform Rectangular Array (URA) with $\lambda/2$ spacing to achieve high-gain (25+ dBi) pencil-beam directivity.
* **Dynamic Beam Steering:** Implements coordinate transformation algorithms to continuously track and lock onto a stationary ground node while the satellite moves at ~7.8 km/s.
* **Link Budget Analysis:** Calculates the Power at Receiver Input (PRI) to validate 5G connection thresholds (-130 dBW).
* **RF Kinematics:** Maps the non-linear Doppler shift ($\pm$ 45 kHz) that NTN modems must pre-compensate for to prevent connection drops.

## 🛠️ Prerequisites
To run this simulation, you need **MATLAB** with the following Add-Ons installed:
* Satellite Communications Toolbox
* Phased Array System Toolbox
* Aerospace Toolbox

## 🚀 How to Run the Simulation
1. Clone this repository to your local machine.
2. Open MATLAB and navigate to the repository folder.
3. Open and run `Master_UI.m`.
4. In the UI window, enter your desired **Array Grid Size** (e.g., 10 for a 10x10 array) and **Transmit Power** (e.g., 20 Watts).
5. Click the execution buttons in sequential order:
   - **Button 1:** Initializes the 3D globe, orbit, and ground station.
   - **Button 2:** Builds the Phased Array and displays the 3D radiation pattern.
   - **Button 3:** Mounts the hardware and begins invisible dynamic beam-steering.
   - **Button 4:** Extracts the link data and plots the final Link Budget and Doppler graphs.

## 🗂️ Repository Architecture
* `Master_UI.m`: The primary GUI and control logic.
* `The_Orbital_Arena_1.m`: Propagates the LEO orbit and sets the ground station coordinates (Komotini, Greece).
* `The_10x10_Phased_Array_2.m`: Constructs the antenna elements and calculates peak directivity.
* `Dynamic_Beam_Steering_3.m`: Establishes the space-to-ground link and executes the `pointAt` tracking logic.
* `The_Physics_and_Visualization_4_5.m`: Processes the RF link data and generates the final portfolio plots.

## 📊 Engineering Results & Analysis

**1. Phased Array Performance**
To overcome the immense path loss of a 500 km orbit to a 0 dBi smartphone antenna, the simulation uses a custom phased array. A 10x10 grid successfully generates a sharp main lobe with a peak gain of **25.22 dBi**, concentrating the RF energy directly onto the target cell.

**2. Link Viability**
The Link Budget plot proves that at 20W with a 10x10 array, the received power peaks at roughly **-125 dBW** when directly overhead. This briefly clears the basic 5G connection threshold (-130 dBW). This tight margin mathematically demonstrates why modern D2C satellites require massive (e.g., 100x100) unfolding arrays for reliable broadband.

**3. The Doppler Challenge**
The Doppler plot highlights a severe "S-Curve" frequency shift swinging from **+45 kHz to -45 kHz** during the 10-minute flyover. This accurately reflects the extreme RF kinematics that separate Non-Terrestrial Networks from standard terrestrial cell towers, requiring advanced firmware compensation.

---
*Developed as a portfolio project demonstrating modern RF, Aerospace, and Telecommunications integration.*