<div align="center">

# 😈 IMPOSTOR & DOCTOR 🏥

### *El juego de roles, engaño y estrategia social*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-API%2021+-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://android.com)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![Made with ❤️](https://img.shields.io/badge/Made%20with-❤️-red?style=for-the-badge)](https://github.com/ChrisEna07)

> **Dos módulos. Un solo propósito: descubrir al traidor entre tus amigos.**  
> Juego de fiesta para grupos de 3 a 10 jugadores — localmente o por red P2P.

---

</div>

## 🎮 ¿Qué es Impostor & Doctor?

**Impostor & Doctor** es una aplicación móvil de juego social que combina dos modos de juego independientes basados en el engaño, la deducción y la comunicación. Está diseñada para ser jugada en grupos de amigos, reuniones o eventos, tanto en modo **local** (pasando el teléfono) como en modo **multijugador en red** (cada uno con su propio dispositivo).

---

## 🃏 Módulos de Juego

### 😈 Módulo Impostor

El clásico juego de la **palabra secreta**.

- Todos los jugadores reciben la **misma palabra**, excepto el **Impostor**, quien recibe una palabra relacionada pero diferente.
- Durante la **fase de discusión**, los jugadores hablan libremente intentando demostrar que conocen la palabra sin revelarla — el Impostor debe mentir de forma convincente.
- En la **fase de votación**, el grupo decide a quién eliminar. Si votan al Impostor, los ciudadanos ganan; si el Impostor sobrevive, acumula puntos.
- El juego termina cuando un jugador alcanza el **límite de puntos** configurado.

**Roles:**
| Rol | Descripción |
|---|---|
| 🧑‍🤝‍🧑 Ciudadano | Conoce la palabra real. Debe exponer al Impostor. |
| 😈 Impostor | Recibe una palabra diferente. Debe engañar al grupo. |

---

### 🏥 Módulo Doctor

Un juego de **roles ocultos** con mecánicas nocturnas y diurnas.

- Cada noche, el **Asesino** elige a quién eliminar en secreto.
- El **Doctor** puede salvar a alguien de la muerte.
- Al **amanecer**, se revela si alguien murió y comienza la fase de discusión.
- Los ciudadanos deben identificar y votar al Asesino antes de quedarse sin miembros.

**Roles:**
| Rol | Descripción |
|---|---|
| 🧑‍🤝‍🧑 Ciudadano | Sin poder especial. Vota para eliminar al sospechoso. |
| 🔪 Asesino | Elimina un jugador cada noche en secreto. |
| 💉 Doctor | Puede proteger a un jugador de la muerte cada noche. |

---

## 🌐 Modo Multijugador en Red (P2P)

**Impostor & Doctor** incluye un sistema de multijugador peer-to-peer basado en **Nearby Connections** (Bluetooth + Wi-Fi Direct) que permite conectar hasta **10 dispositivos** sin necesidad de internet.

### ¿Cómo funciona?

```
📱 Anfitrión              📱 Jugador 1          📱 Jugador 2
   |                          |                      |
   |── Crea sala ──────────── │                      │
   |                    ─── Escanea ─────────────── │
   |◄── Solicitud de unión ───│                      │
   |── Acepta conexión ───────►│                      │
   |◄── Solicitud de unión ────────────────────────► │
   |── Acepta conexión ─────────────────────────────►│
   |                                                  |
   |═══════════ TODOS CONECTADOS ═══════════════════ │
   |── "INICIAR JUEGO" ───────────────────────────── │
   |                                                  |
   |── Rol privado ──────────►│ (solo le llega su carta)
   |── Rol privado ─────────────────────────────────►│
```

### Características del modo red:

- ✅ **Hasta 10 jugadores** simultáneos
- ✅ **Nombre obligatorio** antes de conectarse para identificar jugadores
- ✅ **Sincronización en tiempo real** — fases, temporizadores y votaciones
- ✅ **Anti-trampas integrado** — el anfitrión no puede ver las cartas de otros
- ✅ **Pantallas de espera inteligentes** — el Host espera cuando es turno de un remoto
- ✅ **Votos secretos** — cada dispositivo solo muestra su propia interfaz de voto
- ✅ **Marcador y podio** sincronizados al finalizar

### Compatibilidad de dispositivos:

| Marca | Estado |
|---|---|
| Motorola (Razr 60, G72) | ✅ Probado y funcional |
| Samsung | ✅ Funcional |
| Xiaomi | ✅ Funcional |
| Oppo / Realme | ⚠️ Activar GPS manual + Bluetooth visible |
| iPhone (iOS) | ❌ Nearby Connections solo Android |

> 💡 **TIP:** Asegúrate de tener **Bluetooth**, **Wi-Fi** y **Ubicación** activados en todos los dispositivos.

---

## ✨ Características Técnicas

- **Framework:** Flutter 3.x con arquitectura `Provider` (ChangeNotifier)
- **Navegación:** MaterialApp con rutas push/pop y PopScope
- **Animaciones:** `flutter_animate` para transiciones fluidas
- **Audio:** `audioplayers` para efectos de sonido temáticos
- **Confetti:** Lluvia de confeti al final de partida con `confetti`
- **Fuentes:** Google Fonts integrado con tema oscuro personalizado
- **P2P:** `nearby_connections` v4.3 — Bluetooth + Wi-Fi Direct sin servidor
- **Persistencia:** `shared_preferences` para configuraciones
- **IDs únicos:** `uuid` para identificación de jugadores

---

## 🏗️ Arquitectura del Proyecto

```
lib/
├── main.dart                        # Punto de entrada
├── models/
│   ├── player.dart                  # Modelo jugador Impostor
│   ├── doctor_player.dart           # Modelo jugador Doctor
│   ├── game_settings.dart           # Configuración de partida
│   └── word_pair.dart               # Par de palabras (real/impostor)
├── providers/
│   ├── game_provider.dart           # Estado del módulo Impostor
│   └── doctor_game_provider.dart    # Estado del módulo Doctor
├── screens/
│   ├── home_screen.dart             # Pantalla principal
│   ├── setup_screen.dart            # Configuración partida Impostor
│   ├── game_screen.dart             # Conductor de fases Impostor
│   ├── multiplayer_lobby_screen.dart# Lobby P2P (Host + Cliente)
│   ├── remote_player_screen.dart    # Pantalla cliente remoto
│   ├── phases/                      # Fases del módulo Impostor
│   │   ├── word_reveal_screen.dart
│   │   ├── discussion_screen.dart
│   │   ├── voting_screen.dart
│   │   ├── result_screen.dart
│   │   ├── round_end_screen.dart
│   │   └── game_over_screen.dart
│   └── doctor/                      # Módulo Doctor
│       ├── doctor_setup_screen.dart
│       ├── doctor_game_screen.dart
│       └── phases/
│           ├── night_intro_screen.dart
│           ├── night_assassin_screen.dart
│           ├── night_doctor_screen.dart
│           ├── dawn_screen.dart
│           ├── doctor_discussion_screen.dart
│           ├── doctor_voting_screen.dart
│           ├── doctor_vote_result_screen.dart
│           └── doctor_game_over_screen.dart
├── services/
│   ├── multiplayer_service.dart     # Capa de transporte P2P
│   └── audio_service.dart           # Gestión de audio
├── theme/
│   └── app_theme.dart               # Tema oscuro, colores y gradientes
└── widgets/
    ├── gradient_button.dart         # Botón con gradiente animado
    └── player_avatar.dart           # Avatar generado por iniciales
```

---

## 🚀 Instalación y Compilación

### Requisitos previos

```bash
# Flutter SDK 3.x o superior
flutter --version

# Verificar dependencias
flutter doctor
```

### Clonar y ejecutar

```bash
# Clonar el repositorio
git clone https://github.com/ChrisEna07/Impostor-Doctor.git
cd "Impostor-Doctor"

# Instalar dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# Compilar APK de producción
flutter build apk --release
```

### Permisos Android requeridos

El juego solicita automáticamente los permisos necesarios para la conectividad P2P:

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES" />
```

---

## 🎨 Diseño y Tema

El juego usa un **tema oscuro** personalizado con paleta de colores cuidadosamente elegida:

| Token | Color | Uso |
|---|---|---|
| `primary` | `#7B2FBE` | Acciones principales, Impostor |
| `secondary` | `#2F86BE` | Acentos secundarios |
| `accent` | `#FFD700` | Detalles, iconos |
| `impostorRed` | `#E84040` | Peligro, eliminación |
| `doctorGreen` | `#1A8C6A` | Módulo Doctor |
| `neonGreen` | `#39FF14` | Firma ChrizDev, indicadores |
| `bgDark` | `#0F0F1E` | Fondo principal |
| `surface` | `#1A1A2E` | Superficies de tarjetas |

---

## 🎮 Guía de Juego Rápida

### Modo Local (un dispositivo)
1. Abre la app → Selecciona módulo (**Impostor** o **Doctor**)
2. Agrega los nombres de todos los jugadores
3. Ajusta la configuración (puntos, tiempo, etc.)
4. Presiona **INICIAR JUEGO** y pasa el teléfono a cada jugador en su turno

### Modo Red (varios dispositivos)
1. **Anfitrión:** Selecciona módulo → **MULTIJUGADOR** → escribe tu nombre → **SER ANFITRIÓN**
2. **Jugadores:** Selecciona módulo → **MULTIJUGADOR** → escribe tu nombre → **UNIRSE A SALA**
3. Los jugadores seleccionan la sala del anfitrión en la lista y pulsan **UNIRSE**
4. El anfitrión acepta las solicitudes
5. Una vez todos conectados: Anfitrión pulsa **CONFIGURAR PARTIDA** → **INICIAR JUEGO**

---

## 📊 Sistema de Puntuación (Módulo Impostor)

| Evento | Puntos |
|---|---|
| Ciudadanos votan correctamente al Impostor | +`pointsForCorrectVote` cada uno |
| Impostor sobrevive la votación | +`pointsForSurviving` |
| Impostor es atrapado | 0 puntos |

La partida termina cuando:
- Un jugador alcanza el número de puntos configurado (**modo puntos**)
- O un jugador llega a 0 vidas (**modo penitencia**)

---

## 🛠️ Configuraciones Disponibles

### Módulo Impostor
| Parámetro | Rango | Por defecto |
|---|---|---|
| Jugadores máximos | 3 - 10 | 8 |
| Puntos para ganar | 5 - 30 | 15 |
| Puntos por voto correcto | 1 - 5 | 2 |
| Puntos impostor sobrevive | 1 - 5 | 3 |
| Modo de fin | Puntos / Penitencia | Puntos |

### Módulo Doctor
| Parámetro | Configuración |
|---|---|
| Jugadores mínimos | 4 |
| Jugadores máximos | 10 |
| Tiempo de discusión | Configurable |
| Roles | Asignación automática aleatoria |

---

## 🗺️ Hoja de Ruta

- [x] Módulo Impostor completo (local + red)
- [x] Módulo Doctor completo (local + red)
- [x] Sistema P2P hasta 10 jugadores
- [x] Anti-trampas en modo red
- [x] Sincronización de fases, timer y votación en tiempo real
- [x] Nombre obligatorio en modo red
- [x] Pantallas de espera inteligentes por rol
- [ ] Soporte iOS (requiere cambio de librería P2P)
- [ ] Categorías de palabras adicionales
- [ ] Modo espectador
- [ ] Historial de partidas
- [ ] Sonidos personalizables por rol

---

## 👨‍💻 Autor

<div align="center">

**Christian Romero** · *ChrizDev*

[![GitHub](https://img.shields.io/badge/GitHub-ChrisEna07-181717?style=for-the-badge&logo=github)](https://github.com/ChrisEna07)

*"Desarrollado con pasión, probado con amigos."*

---

**Versión:** `1.0.0` · **Plataforma:** Android (API 21+) · **Lenguaje:** Dart / Flutter

</div>
