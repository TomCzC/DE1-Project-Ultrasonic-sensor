#  Team members

 - Adam Čermák - Odpovědný za controller a poster
 - Tomáš Běčák - Odpovědný za Github a display_control
 - Mykhailo Krasichkov - Odpovědný za echo_detect, trig_pulse a zapojení na desce
 - Daniel Kroužil - Odpovědný za controller a poster

# Abstract

Tento projekt realizuje měření vzdálenosti pomocí dvou ultrazvukových senzorů HS-SR04, řízených FPGA. Systém umožňuje:
 - Měření vzdálenosti v rozsahu 2–400 cm s rozlišením 1 cm
 - Zobrazení hodnot na 7-segmentovém displeji
 - Nastavení prahové hodnoty pomocí přepínačů (SW)
 - Vizuální signalizaci pomocí LED diod
Senzory pracují nezávisle – jeden měří vzdálenost vlevo, druhý vpravo.

# Hardware

Použité komponenty
 - FPGA deska (Nexys A7-50T)
 - Ultrazvukové senzory HC-SR04 (2×)

# Zapojení 

| Sloupec 1 | Sloupec 2 | Sloupec 3 |
|-----------|-----------|-----------|
| JA0       | Levý senzor    | Trigger    |
| JC0       | Levý senzor    | 	Echo     |
| JD0       | Pravý senzor    | Trigger    |
| JB0       | Pravý senzor    | Echo    |
| SW[8:0]   | Přepínače | Data 3    |
| BTNU      | Tlačítko  | Nastavení prahové hodnoty (0–511 cm)     |
| BTNC      | Tlačítko  | Zbrazení vzdálenosti    |
| BTND      | Tlačítko  | Zobrazit práh    |

# Hardware design
<img src="images/top_level (1).jpg" alt="top level block diagram" width="1000"/>

# Funkce systému
1. Měření vzdálenosti
 - Každý senzor periodicky vysílá ultrazvukový impuls (10 µs).
 - Čas mezi vysláním a přijetím ozvěny (echo) určuje vzdálenost.
 - Pokud senzor nezachytí ozvěnu (objekt příliš daleko), systém detekuje timeout a vrátí maximální hodnotu (511 cm).
2. Zobrazení na 7-segmentovém displeji
 - Výchozí režim: Zobrazuje d01---d02 (identifikace senzorů).
 - Stisk BTNC: Zobrazí vzdálenosti v cm (levý a pravý senzor).
 - Stisk BTND: Zobrazí nastavený práh (hodnota z přepínačů SW).
3. Signalizace LED diodami
Levé LED (LED15-LED13): Indikují blízkost levého senzoru.
   - 111 = Pod prahem
   - 110 = Do +5 cm nad prahem
   - 100 = Do +10 cm nad prahem
   - 000 = Více než +10 cm
 - Pravé LED (LED2-LED0): Stejná logika pro pravý senzor.

# Jak to funguje uvnitř?
Hlavní soubory
 - [top_level.vhd](project_files/top_level.vhd) – Propojuje všechny komponenty.
 - [echo_receiver.vhd](project_files/echo_receiver.vhd) – Detekuje echo a počítá vzdálenost.
   - Při psaní echo_receiver jsme se inspirovali projektem z minulého roku.   
 - [controller.vhd](project_files/controller.vhd) – Řídí měřicí cyklus a komunikaci se senzory.
 - [trig_pulse.vhd](project_files/trig_pulse.vhd) – Generuje 10µs trigger pro HC-SR04.
 - [display_control.vhd](project_files/display_control.vhd) – Ovládá displej a LED.

Časování měření
 - Každý senzor měří 1× za sekundu.



# Ultrasonic Distance Measurement System  
**Brno University of Technology, Faculty of Electrical Engineering, 2024/2025**  

---


---

## 📌 Abstract  
A dual-sensor ultrasonic measurement system built on the Nexys A7-50T FPGA, featuring:  
- **Distance Measurement**:  
  - Range: **2–400 cm** with **1 cm resolution**.  
  - Dual independent sensors (left/right).  
- **Dynamic Visualization**:  
  - 7-segment display for real-time distance/threshold values.  
  - LED indicators for proximity zones relative to a user-defined threshold.  
- **User Interaction**:  
  - Threshold set via **9-bit DIP switches (SW[8:0])** (0–511 cm).  
  - Buttons to toggle display modes.  

---

## 🛠️ Hardware Setup  
### Key Components  
- **FPGA Board**: Nexys A7-50T (central control unit).  
- **Sensors**: 2× HC-SR04 ultrasonic modules.  

### Pin Connections  
| **FPGA Pin** | **Component**      | **Function**       |  
|--------------|--------------------|--------------------|  
| `JA0`        | Left Sensor        | Trigger            |  
| `JC0`        | Left Sensor        | Echo               |  
| `JD0`        | Right Sensor       | Trigger            |  
| `JB0`        | Right Sensor       | Echo               |  
| `SW[8:0]`    | DIP Switches       | Threshold Setting  |  
| `BTNU`       | Button             | System Reset       |  
| `BTNC`       | Button             | Show Distances     |  
| `BTND`       | Button             | Show Threshold     |  

![Top-Level Block Diagram](images/top_level_(1).jpg)  
*Hardware architecture overview.*  

---

## ⚙️ System Features  
### 1. Distance Measurement  
- **Trigger Pulse**: 10 µs pulse sent periodically to sensors.  
- **Echo Processing**:  
  - Distance calculated from echo pulse duration.  
  - **Timeout Handling**: Returns 511 cm if no echo detected (object out of range).  

### 2. Display Modes  
- **Default**: Shows sensor IDs (`d01--d02`).  
- **Button Controls**:  
  - `BTNC`: Displays left/right distances (e.g., `200--300`).  
  - `BTND`: Shows threshold value set via switches.  

### 3. LED Proximity Indicators  
- **Left LEDs (LED15-LED13)**:  
  - `111` = **Below threshold**.  
  - `110` = **≤5 cm above threshold**.  
  - `100` = **≤10 cm above threshold**.  
  - `000` = **>10 cm above threshold**.  
- **Right LEDs (LED2-LED0)**: Same logic for the right sensor.  

---

## 🔍 Internal Workflow  
### Core Components  
- **`top_level.vhd`**: Integrates all modules.  
- **`echo_receiver.vhd`**: Measures echo pulse width → calculates distance.  
- **`controller.vhd`**: Manages sensor timing (trigger, timeout, data validation).  
- **`trig_pulse.vhd`**: Generates precise 10 µs trigger pulses.  
- **`display_control.vhd`**: Drives the 7-segment display and LEDs.  

### Timing  
- **Measurement Interval**: Each sensor updates **once per second**.  
- **Debounced Buttons**: Ensure stable mode switching.  

---

## 📂 Source Files  
- [top_level.vhd](project_files/top_level.vhd)  
- [echo_receiver.vhd](project_files/echo_receiver.vhd)  
- [controller.vhd](project_files/controller.vhd)  
- [trig_pulse.vhd](project_files/trig_pulse.vhd)  
- [display_control.vhd](project_files/display_control.vhd)  
 - Pokud není detekována ozvěna, systém automaticky pokračuje v další měřicí smyčce.





