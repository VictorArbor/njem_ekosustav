"""
S6-FR Korak 4a: SO(3)^3 Beltrami MHD test u I_h kavezu (Kompletna verzija)
Autor: suradnja (Kolega + DeepSeek + Gemini)
Datum: 2026-10-05
Status: FALSIFIKACIJSKI UGOVOR AKTIVAN

Cilj: Testirati P3 — potiskivanje m=1 (kink/ballooning) moda pod SO(3)^3 rotacijom
Kriterij: Ako m=1 amplituda naraste iznad 1e-6 -> P3 PADA (model padija).
         Ako m=1 amplituda ostane prigušena (< 1e-6) -> P3 PROLAZI.
"""

import logging
import numpy as np
import dedalus.public as d3

logger = logging.getLogger(__name__)

# ============================================================
# 1. PARAMETRI ZAMRZNUTI U Θ_S6 VEKTORU
# ============================================================
S = 234
Phi = np.log2(1.5)
K_S6 = 1 + (np.pi / 7) * (Phi / S)
c_nat = S * (1 - Phi**2 / (2 * np.pi)) / np.sqrt(K_S6)
nu_S6 = 14.28e9      # Hz
M_234 = 234.0        # Machov broj
R_vakuola = 0.49     # m (Radijus sferne ljuske)

# Bezdimenzijske viskoznosti i otpornosti za visoki Lundquistov broj
Re = 1e4             # Reynolds-ov broj
Rm = 1e4             # Magnetski Reynolds-ov broj

# ============================================================
# 2. DISKRETIZACIJA I PROSTORNA MREŽA
# ============================================================
Nphi = 64
Ntheta = 32
Nr = 16

coords = d3.SphericalCoordinates('phi', 'theta', 'r')
dist = d3.Distributor(coords, dtype=np.float64)
shell = d3.SphericalShellBasis(coords, shape=(Nphi, Ntheta, Nr), radii=(0.05, R_vakuola), dtype=np.float64)

phi, theta, r = dist.local_grids(shell)

# ============================================================
# 3. POLJA I VARIJABLE
# ============================================================
u = dist.VectorField(coords, name='u', bases=shell)
B = dist.VectorField(coords, name='B', bases=shell)
p = dist.Field(name='p', bases=shell)
tau_p = dist.Field(name='tau_p')

# Vektorska baza za Dedalus d3
e_phi, e_theta, e_r = coords.unit_vector_fields(dist)

# SO(3)^3 vektor troosne rotacije (ekvivalentni kutni vektor u rotirajućem okviru)
Omega_0 = M_234 / R_vakuola
Omega_vec = dist.VectorField(coords, name='Omega_vec', bases=shell)
Omega_vec['g'][0] = Omega_0 * np.sin(theta) * np.cos(phi) # X os
Omega_vec['g'][1] = Omega_0 * np.sin(theta) * np.sin(phi) # Y os
Omega_vec['g'][2] = Omega_0 * np.cos(theta)             # Z os

# ============================================================
# 4. FORMULACIJA MHD JEDNADŽBI (Beltrami + SO(3)^3 Coriolis)
# ============================================================
problem = d3.IVP([u, B, p, tau_p], namespace=locals())

# Jednadžba gibanja (Navier-Stokes / Lorentz / Coriolis)
problem.add_equation("dt(u) + grad(p) - (1/Re)*lap(u) = - d3.CrossProduct(u, d3.curl(u)) + d3.CrossProduct(d3.curl(B), B) - 2*d3.CrossProduct(Omega_vec, u)")

# Jednadžba indukcije
problem.add_equation("dt(B) + (1/Rm)*d3.curl(d3.curl(B)) = d3.curl(d3.CrossProduct(u, B))")

# Inkompresibilnost i Gauge uvjeti
problem.add_equation("div(u) + tau_p = 0")
problem.add_equation("integ(p) = 0")

# ============================================================
# 5. INICIJALNI UVJETI: Beltrami polje (∇×B = λB) + m=1 Perturbacija
# ============================================================
lam = 1.0 / R_vakuola
B['g'][0] = np.sin(lam * r) * np.cos(theta)
B['g'][1] = np.cos(lam * r) * np.sin(phi)
B['g'][2] = np.cos(lam * r) * np.cos(theta)

# Namjerna m=1 perturbacija za testiranje suzbijanja/rasta nestabilnosti
amplitude_m1_init = 1e-4
B['g'][0] += amplitude_m1_init * np.sin(1 * phi) * np.sin(theta)
u['g'][0] += amplitude_m1_init * np.cos(1 * phi) * np.sin(theta)

# ============================================================
# 6. VREMENSKA INTEGRACIJA I PRACENJE P3 PREDIKCIJE
# ============================================================
solver = problem.build_solver(d3.RK443)
solver.stop_sim_time = 2.4  # Vrijeme ekvivalentno 24 ciklusa relaksacije

dt = 1e-3
m1_amplitudes = []

print("=" * 60)
print("S6-FR Korak 4a: SO(3)^3 Beltrami MHD test (POKRENUTO)")
print("=" * 60)
print(f"S           = {S}")
print(f"Φ_frac      = {Phi:.10f}")
print(f"K_S6        = {K_S6:.10f}")
print(f"c_nat       = {c_nat:.6f}")
print(f"ν_S6        = {nu_S6/1e9:.4f} GHz")
print(f"Mach        = {M_234}")
print("=" * 60)

while solver.proceed:
    solver.step(dt)
    
    # Izračun m=1 mode amplitude (Fourier po phi)
    B_phi = B['g'][0]
    m1_component = np.mean(np.abs(np.fft.fft(B_phi, axis=0)[1]))
    m1_amplitudes.append(m1_component)
    
    if solver.iteration % 100 == 0:
        logger.info(f"Iteracija: {solver.iteration}, Sim-time: {solver.sim_time:.3f}, m=1 Amplituda: {m1_component:.3e}")

# ============================================================
# 7. FALSIFIKACIJSKI TEST
# ============================================================
final_m1 = m1_amplitudes[-1]

print("\n" + "=" * 60)
print("REZULTAT FALSIFIKACIJSKOG TESTA P3")
print("=" * 60)
print(f"Početna m=1 amplituda: {amplitude_m1_init:.3e}")
print(f"Konačna m=1 amplituda: {final_m1:.3e}")

if final_m1 < 1e-6:
    print("STATUS: PASSED (P3 POTVRĐEN) — SO(3)^3 rotacija uspješno potiskuje m=1 nestabilnost!")
else:
    print("STATUS: FAILED (P3 PAO) — m=1 nestabilnost je narasla. Model pada po ugovoru.")
print("=" * 60)
