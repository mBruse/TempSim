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
  Schrittzahl. Eingaben akzeptieren das Dezimaltrennzeichen des Systems.
* Die Fourier-Zahl r wird live angezeigt. Für r > 0,5 ist das explizite Verfahren
  instabil; mit „Stabilität sichern“ wird dt intern in Unterschritte geteilt.
  Ohne diese Option wird eine divergierende Lösung erkannt und abgebrochen.
* Oben: Schema des Systems, die Knoten sind nach aktueller Temperatur eingefärbt.
* Reiter **Zeitverlauf** (T(t) je Knoten), **Tiefenprofil** (aktuelles Profil,
  Minimum/Maximum je Knoten: Dämpfung der Temperaturwelle), **Info**.
* **Start** setzt zurück und rechnet, **Weiter** rechnet ab dem aktuellen Zustand.
  Die Zeitreihen lassen sich als CSV exportieren.

## Bauen

* RAD Studio / Delphi 11 Alexandria oder neuer (VCL, TeeChart Standard,
  `TNumberBox`): `Temperatur1D.dproj` öffnen und kompilieren.
* Optional für den Windows-11-Look: *Projekt > Optionen > Anwendung >
  Erscheinungsbild* → „Windows11 Modern Light“ (und ggf. „… Dark“) aktivieren.
  Sind mehrere Styles eingebunden, erscheint im Programm eine Design-Auswahl.

## Aufbau

| Datei | Inhalt |
|---|---|
| `Temp1DModel.pas` | numerischer Kern (ohne UI), Materialliste |
| `Temp1D.pas` / `.dfm` | Hauptfenster |
| `tests/TestModel.dpr` | Konsolentests des Modells (Delphi oder `fpc -Mdelphi -Fu.. TestModel.dpr`) |
