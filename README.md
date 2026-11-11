# Temperatur1D

Lehrprogramm (Delphi/VCL) zur expliziten Lösung der eindimensionalen
Wärmeleitungsgleichung

    dT/dt = a · d²T/dx²

auf einer Kette von N Knoten im Abstand dx (FTCS-Verfahren):

    T_i(t+dt) = T_i(t) + r · (T_i-1 − 2·T_i + T_i+1),   r = a·dt/dx²

**Randbedingungen:** Knoten 0 schwingt mit `T = Tinit + A·cos(2π·t/P)`,
der letzte Knoten bleibt konstant auf `Tinit`.

## Bedienung

* Links: Material (Temperaturleitfähigkeit), Gitter (Knotenzahl, dx),
  Start-/Randbedingungen (Tinit, Amplitude A, Periode P), Zeitschritt dt und
  Schrittzahl. Eingaben akzeptieren Dezimalkomma und -punkt; ungültige oder
  außerhalb des Bereichs liegende Werte werden rot markiert und begrenzt.
* Die Fourier-Zahl r wird live angezeigt. Für r > 0,5 ist das explizite Verfahren
  instabil; mit „Stabilität sichern“ wird dt intern in Unterschritte geteilt.
  Ohne diese Option wird eine divergierende Lösung erkannt und abgebrochen.
* Oben: Schema des Systems, die Knoten sind nach aktueller Temperatur eingefärbt.
* Reiter **Zeitverlauf** (T(t) je Knoten), **Tiefenprofil** (aktuelles Profil,
  Minimum/Maximum je Knoten: Dämpfung der Temperaturwelle), **Isoplethen**
  (Thermoisoplethendiagramm: Farbflächen und Isolinien, Zeit auf der x-Achse,
  Tiefe auf der y-Achse nach unten), **Info**.
* **Start** setzt zurück und rechnet, **Weiter** rechnet ab dem aktuellen Zustand.
  Die Zeitreihen lassen sich als CSV exportieren.

## Stoffwerte

Das Modell rechnet mit der Temperaturleitfähigkeit a = λ / (ρ·c). In
`Temp1DModel.pas` sind dafür Wärmeleitfähigkeit λ, Dichte ρ und spezifische
Wärmekapazität c hinterlegt. Es sind typische Werte: Böden, Schnee, Wasser
und Luft nach Oke (1987, *Boundary Layer Climates*, Tab. 2.1), Gestein und
Baustoffe als Richtwerte nach DIN EN ISO 10456 / DIN 4108-4, Metalle nach
Standardtabellen bei Raumtemperatur. Natürliche Stoffe streuen je nach
Porosität, Feuchte und Temperatur deutlich.

| Material | λ (W/(m·K)) | ρ (kg/m³) | c (J/(kg·K)) | a (mm²/s) |
|---|---:|---:|---:|---:|
| Sand trocken | 0.3 | 1600 | 800 | 0.234 |
| Sand feucht (20 Vol.-% Wasser) | 1.6 | 1800 | 1178 | 0.755 |
| Ton trocken | 0.25 | 1600 | 890 | 0.176 |
| Ton wassergesättigt | 1.58 | 2000 | 1550 | 0.51 |
| Torf trocken | 0.06 | 300 | 1920 | 0.104 |
| Torf wassergesättigt | 0.5 | 1100 | 3650 | 0.125 |
| Schnee frisch | 0.06 | 100 | 2090 | 0.287 |
| Schnee alt | 0.42 | 480 | 2090 | 0.419 |
| Eis (0 °C) | 2.24 | 917 | 2100 | 1.16 |
| Wasser (ruhend, 20 °C) | 0.598 | 998 | 4182 | 0.143 |
| Luft (ruhend, 20 °C) | 0.0257 | 1.204 | 1005 | 21.2 |
| Granit | 2.8 | 2600 | 1000 | 1.08 |
| Sandstein | 2.3 | 2600 | 1000 | 0.885 |
| Kalkstein | 1.7 | 2200 | 1000 | 0.773 |
| Beton (Normalbeton) | 2.0 | 2400 | 1000 | 0.833 |
| Ziegelstein (Vollziegel) | 0.81 | 1800 | 1000 | 0.45 |
| Putz (Kalkzement) | 1.0 | 1800 | 1000 | 0.556 |
| Gipskarton | 0.25 | 900 | 1000 | 0.278 |
| Asphalt | 0.7 | 2100 | 1000 | 0.333 |
| Glas | 1.0 | 2500 | 750 | 0.533 |
| Holz (Nadelholz) | 0.13 | 500 | 1600 | 0.163 |
| Dämmung (Polystyrol EPS) | 0.035 | 20 | 1450 | 1.21 |
| Eisen (rein) | 80.2 | 7870 | 449 | 22.7 |
| Stahl (unlegiert) | 50.0 | 7850 | 460 | 13.8 |
| Edelstahl | 15.0 | 7900 | 500 | 3.8 |
| Aluminium | 237.0 | 2700 | 897 | 97.9 |
| Kupfer | 401.0 | 8960 | 385 | 116 |

## Bauen

* RAD Studio / Delphi mit VCL und dem mitgelieferten TeeChart Standard
  (Projekt zuletzt mit Delphi 11 gespeichert): `Temperatur1D.dproj` öffnen
  und kompilieren. Es werden nur Standard-VCL-Komponenten verwendet.
* Optional für den Windows-11-Look: *Projekt > Optionen > Anwendung >
  Erscheinungsbild* → „Windows11 Modern Light“ (und ggf. „… Dark“) aktivieren.
  Sind mehrere Styles eingebunden, erscheint im Programm eine Design-Auswahl.

## Aufbau

| Datei | Inhalt |
|---|---|
| `Temp1DModel.pas` | numerischer Kern (ohne UI), Materialliste |
| `Temp1DContour.pas` | Isolinien (Marching Squares), Interpolation, Farbbänder |
| `Temp1D.pas` / `.dfm` | Hauptfenster |
| `tests/TestModel.dpr`, `tests/TestContour.dpr` | Konsolentests (Delphi oder `fpc -Mdelphi -Fu.. TestModel.dpr`) |
