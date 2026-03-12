import streamlit as st
import numpy as np
import plotly.graph_objects as go
from skyfield.api import EarthSatellite, load, wgs84

# --- PAGE CONFIGURATION ---
st.set_page_config(page_title="5G NTN Direct-to-Cell Simulator", layout="wide")
st.title("📡 5G NTN Research Simulator - Physical Layer Fidelity")
st.write("Welcome to the web version of the Direct-to-Cell Simulator.")

# --- SIDEBAR: CONTROLS ---
st.sidebar.header("1. Orbital Data Cache")
col1, col2 = st.sidebar.columns(2)
num_planes = col1.number_input("Orbit Planes:", min_value=1, max_value=50, value=6)
sats_per_plane = col2.number_input("Sats/Plane:", min_value=1, max_value=100, value=8)

if st.sidebar.button("Generate Constellation"):
    st.sidebar.success("Orbit Processing Complete!")

st.sidebar.header("2. Advanced RF Parameters")
grid_size = st.sidebar.number_input("Array Grid Size (NxN):", min_value=2, max_value=100, value=10)
tx_power = st.sidebar.number_input("Satellite TX Power (dBW):", min_value=-30, max_value=50, value=20)
weather_type = st.sidebar.selectbox("Base Weather Loss:", ["Clear Sky", "Light Rain", "Heavy Rain"])

st.sidebar.header("Research Engine")
doppler_precomp = st.sidebar.toggle("Doppler Pre-Compensation", value=True) # Doppler Toggle
research_mode = st.sidebar.toggle("Research Engine (Fading/CCI)", value=True)

# --- MAIN DASHBOARD ---
st.header("Simulation Results")

# 1. Setup Locations (User and Gateway)
ts = load.timescale()
komotini = wgs84.latlon(41.119, 25.405) # Service Link UE
athens = wgs84.latlon(37.9838, 23.7275) # Feeder Link Gateway

# 2. Build the Walker-Delta Constellation
satellites = []
for p in range(int(num_planes)):
    raan = p * (360.0 / num_planes)
    for s in range(int(sats_per_plane)):
        ma = s * (360.0 / sats_per_plane)
        line1 = f'1 99999U 26001A   26071.00000000  .00000000  00000-0  50000-4 0  9990'
        line2 = f'2 99999  53.0000 {raan:8.4f} 0001000   0.0000 {ma:8.4f} 15.22000000    12'
        satellites.append(EarthSatellite(line1, line2, f'Sat-P{p}-S{s}', ts))

# 3. Simulate the full constellation pass over a 60-minute window
t_now = ts.now()
time_steps_mins = np.linspace(0, 60, 300)
delta_t_sec = (time_steps_mins[1] - time_steps_mins[0]) * 60 # Seconds per step
t_array = ts.utc(t_now.utc_datetime().year, t_now.utc_datetime().month, t_now.utc_datetime().day, 
                 t_now.utc_datetime().hour, t_now.utc_datetime().minute + time_steps_mins)

num_sats = len(satellites)
num_steps = len(time_steps_mins)

# Data matrices to hold physics for all satellites
all_rx_powers = np.full((num_sats, num_steps), -150.0)
all_elevations = np.zeros((num_sats, num_steps))
all_feeder_snrs = np.full((num_sats, num_steps), -100.0) 
all_raw_dopplers = np.zeros((num_sats, num_steps)) #  Doppler matrix

# 4. Calculate Physics for EVERY satellite in the sky
freq_mhz = 2000 # S-Band User Link
array_gain_dbi = 10 * np.log10(grid_size**2)
weather_loss_dict = {"Clear Sky": 0.5, "Light Rain": 3.0, "Heavy Rain": 12.0}
base_loss = weather_loss_dict[weather_type]
speed_of_light = 3e8

for i, sat in enumerate(satellites):
    # --- A. Service Link (S-Band to Komotini) ---
    diff = sat - komotini
    topocentric = diff.at(t_array)
    alt, az, distance = topocentric.altaz()
    
    elev = alt.degrees
    dist_km = distance.km
    all_elevations[i] = elev
    visible_mask = elev > 0
    
    # Calculate Radial Velocity and Raw Doppler Shift (Matching MATLAB logic)
    radial_vel_mps = np.concatenate(([0], np.diff(dist_km * 1000))) / delta_t_sec
    all_raw_dopplers[i] = (radial_vel_mps / speed_of_light) * (freq_mhz * 1e6)
    
    if np.any(visible_mask):
        fspl = 20 * np.log10(dist_km[visible_mask]) + 20 * np.log10(freq_mhz) + 32.44
        sin_elev = np.maximum(np.sin(np.radians(elev[visible_mask])), 0.087)
        dynamic_weather_loss = base_loss / sin_elev
        
        rx_pwr = tx_power + array_gain_dbi - fspl - dynamic_weather_loss + 105
        all_rx_powers[i, visible_mask] = rx_pwr

    # --- B. Feeder Link (Ka-Band to Athens) ---
    diff_gw = sat - athens
    topo_gw = diff_gw.at(t_array)
    alt_gw, az_gw, dist_gw = topo_gw.altaz()
    elev_gw = alt_gw.degrees
    gw_visible = elev_gw > 5 
    
    if np.any(gw_visible):
        gw_fspl = 20 * np.log10(dist_gw.km[gw_visible]) + 20 * np.log10(28000) + 32.44
        all_feeder_snrs[i, gw_visible] = 60 - gw_fspl + 15 + 228.6 - 10 * np.log10(100e6)

# 5. Handover & Co-Channel Interference (CCI) Logic
best_rx_power = np.zeros(num_steps)
best_feeder_snr = np.zeros(num_steps)
best_raw_doppler = np.zeros(num_steps) 
total_interference_linear = np.zeros(num_steps)

for t in range(num_steps):
    connected_sat_idx = np.argmax(all_rx_powers[:, t])
    best_rx_power[t] = all_rx_powers[connected_sat_idx, t]
    best_feeder_snr[t] = all_feeder_snrs[connected_sat_idx, t] 
    best_raw_doppler[t] = all_raw_dopplers[connected_sat_idx, t] 
    
    if research_mode:
        for i in range(num_sats):
            if i != connected_sat_idx and all_elevations[i, t] > 0:
                total_interference_linear[t] += 10**(all_rx_powers[i, t] / 10.0)

thermal_noise_linear = 10**(-30.0 / 10.0)
mock_sinr = best_rx_power - (10 * np.log10(thermal_noise_linear + total_interference_linear))

if research_mode:
    fading_noise = np.random.randn(num_steps) * 3
    mock_sinr = np.where(best_rx_power > -100, mock_sinr + fading_noise, mock_sinr)

# 6. Exact 3GPP MCS Table Translation & Doppler Error
mcs_table = np.array([
    [-6.5, 0.23], [-4.0, 0.38], [-2.0, 0.60], [0.0, 0.88], [2.0, 1.18], [4.0, 1.48], [6.0, 1.91], 
    [8.0, 2.41], [10.0, 2.73], [12.0, 3.32], [14.0, 3.90], [16.0, 4.52], [18.0, 5.12], [20.0, 5.55]
])

spectral_efficiencies = np.zeros_like(mock_sinr)
for threshold, efficiency in mcs_table:
    spectral_efficiencies[mock_sinr >= threshold] = efficiency

mock_throughput = np.where((best_rx_power > -100) & (best_feeder_snr > 0), (15e6 * spectral_efficiencies * 0.8) / 1e6, 0)

#  Apply Pre-Compensation Logic
if doppler_precomp:
    final_doppler_hz = np.random.randn(num_steps) * 25 # GNSS residual error
else:
    final_doppler_hz = best_raw_doppler

# --- PLOTS ---
col_left, col_right = st.columns(2)

with col_left:
    st.subheader("1. Received SINR (S-Band)")
    fig_sinr = go.Figure()
    fig_sinr.add_trace(go.Scatter(x=time_steps_mins, y=mock_sinr, mode='lines', line=dict(color='#A2142F'), name='SINR'))
    fig_sinr.add_hline(y=-6.5, line_dash="dash", line_color="red", annotation_text="3GPP Demodulation Floor")
    fig_sinr.update_layout(yaxis_title="SINR (dB)", xaxis_title="Time (Minutes)", yaxis_range=[-20, 30], height=300, margin=dict(l=0, r=0, t=30, b=0))
    st.plotly_chart(fig_sinr, use_container_width=True)

    st.subheader("2. System Throughput")
    fig_thr = go.Figure()
    fig_thr.add_trace(go.Scatter(x=time_steps_mins, y=mock_throughput, mode='lines', line=dict(color='#77AC30'), name='Capacity'))
    fig_thr.update_layout(yaxis_title="Capacity (Mbps)", xaxis_title="Time (Minutes)", height=300, margin=dict(l=0, r=0, t=30, b=0))
    st.plotly_chart(fig_thr, use_container_width=True)

with col_right:
    st.subheader("3. Doppler Shift (S-Band)")
    fig_dop = go.Figure()
    fig_dop.add_trace(go.Scatter(x=time_steps_mins, y=final_doppler_hz / 1000, mode='lines', line=dict(color='#D95319'), name='Doppler'))
    
    if doppler_precomp:
        fig_dop.update_layout(title="Residual Doppler Error (Pre-Compensated)", yaxis_title="Error (kHz)", yaxis_range=[-0.1, 0.1], height=300, margin=dict(l=0, r=0, t=30, b=0))
    else:
        fig_dop.update_layout(title="Raw Doppler Shift", yaxis_title="Shift (kHz)", height=300, margin=dict(l=0, r=0, t=30, b=0))
    st.plotly_chart(fig_dop, use_container_width=True)