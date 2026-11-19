<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Family Flight Deck</title>
    <!-- Tailwind CSS CDN -->
    <script src="https://cdn.tailwindcss.com"></script>
    <!-- Inter Font -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
    <!-- Zero-API-Key Vector Map Libraries (D3 + TopoJSON) -->
    <script src="https://cdn.jsdelivr.net/npm/d3@7/dist/d3.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/topojson-client@3/dist/topojson-client.min.js"></script>

    <style>
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            user-select: none;
            -webkit-user-select: none;
            -webkit-tap-highlight-color: transparent;
        }

        /* Allow text selection inside Settings & Pilot Remote inputs */
        input, textarea, select {
            user-select: text;
            -webkit-user-select: text;
        }

        /* Smooth airplane floating animation on flight progress track */
        @keyframes floatPlane {
            0%, 100% { transform: translateY(-50%) translateX(-50%) translateY(0px); }
            50% { transform: translateY(-50%) translateX(-50%) translateY(-4px); }
        }

        .plane-marker {
            animation: floatPlane 2.4s ease-in-out infinite;
            transition: left 1s cubic-bezier(0.22, 1, 0.36, 1);
        }

        /* Ringing pulse halo */
        @keyframes pulseRing {
            0% { transform: scale(0.95); opacity: 0.8; }
            70% { transform: scale(1.45); opacity: 0; }
            100% { transform: scale(1.45); opacity: 0; }
        }

        .ring-pulse::before {
            content: '';
            position: absolute;
            inset: 0;
            border-radius: 9999px;
            background-color: #10b981;
            animation: pulseRing 1.6s cubic-bezier(0.24, 0, 0.38, 1) infinite;
            z-index: -1;
        }

        /* Ensure Jitsi iframe fills its container cleanly */
        #jitsi-wrapper iframe {
            width: 100% !important;
            height: 100% !important;
            border: 0 !important;
            display: block;
        }
    </style>
</head>
<body class="bg-slate-100 text-slate-900 min-h-screen w-screen overflow-x-hidden flex flex-col">

    <!-- =====================================================================
         TOP FRIENDLY NOTIFICATION BANNER
         ===================================================================== -->
    <div id="top-banner" class="fixed top-0 inset-x-0 z-50 flex justify-center px-4 pointer-events-none transition-all duration-500 -translate-y-full opacity-0">
        <div id="top-banner-card" class="pointer-events-auto mt-4 max-w-2xl w-full bg-amber-400 text-amber-950 border-2 border-amber-500 rounded-2xl shadow-2xl px-5 py-4 flex items-center justify-between gap-4">
            <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl bg-amber-500/30 flex items-center justify-center shrink-0">
                    <svg class="w-6 h-6 text-amber-950" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"/>
                    </svg>
                </div>
                <p id="top-banner-text" class="font-extrabold text-base sm:text-lg leading-snug">Status message</p>
            </div>
            <button
                type="button"
                onclick="hideTopBanner()"
                aria-label="Dismiss banner"
                class="p-2 rounded-xl hover:bg-black/10 transition shrink-0"
            >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M6 18L18 6M6 6l12 12"/>
                </svg>
            </button>
        </div>
    </div>

    <!-- =====================================================================
         DISCREET TOP-RIGHT HOLD-FOR-2-SECONDS SETTINGS BUTTON
         ===================================================================== -->
    <div class="fixed top-4 right-4 z-30 flex items-center gap-2">
        <button
            id="pilot-mode-badge-btn"
            type="button"
            onclick="setDeviceRole('pilot')"
            class="hidden bg-slate-900/90 hover:bg-slate-800 text-white text-xs font-extrabold px-3.5 py-2 rounded-full shadow-lg backdrop-blur-sm border border-white/15 flex items-center gap-1.5 transition"
        >
            <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            <span>Pilot Remote</span>
        </button>
        <div id="hold-hint-pill" class="hidden bg-slate-800/90 text-white text-xs font-semibold px-3 py-1.5 rounded-full shadow-lg backdrop-blur-sm transition-opacity">
            Hold 2s for Settings
        </div>
        <button
            id="gear-hold-btn"
            type="button"
            aria-label="Hold for 2 seconds to open Parent Settings"
            class="relative w-12 h-12 p-2.5 rounded-full bg-white/85 hover:bg-white text-slate-400 hover:text-slate-600 shadow-md border border-slate-200/80 backdrop-blur-sm flex items-center justify-center transition-colors focus:outline-none touch-none"
        >
            <!-- Circular SVG Progress Ring -->
            <svg class="absolute inset-0 w-full h-full -rotate-90 pointer-events-none" viewBox="0 0 48 48">
                <circle cx="24" cy="24" r="21" fill="none" stroke="transparent" stroke-width="3.5" />
                <circle
                    id="gear-progress-ring"
                    cx="24"
                    cy="24"
                    r="21"
                    fill="none"
                    stroke="#2563eb"
                    stroke-width="3.5"
                    stroke-linecap="round"
                    stroke-dasharray="131.95"
                    stroke-dashoffset="131.95"
                />
            </svg>
            <!-- Gear Icon -->
            <svg class="w-6 h-6 pointer-events-none" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/>
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
            </svg>
        </button>
    </div>

    <!-- =====================================================================
         1. STATUS-FIRST KID-FRIENDLY HOME DASHBOARD (DEFAULT SCREEN)
         ===================================================================== -->
    <main id="dashboard-screen" class="flex-1 w-full flex flex-col justify-center p-4 sm:p-6 lg:p-8">
        <div id="dashboard-grid" class="w-full max-w-4xl mx-auto flex-1 grid grid-cols-1 gap-6 items-stretch">
            <!-- Profile status cards rendered dynamically by renderDashboard() -->
        </div>
    </main>

    <!-- =====================================================================
         2A. FULL-SCREEN EMBEDDED VIDEO CALLING SCREEN (JITSI)
         ===================================================================== -->
    <section id="call-screen" class="hidden fixed inset-0 z-40 bg-slate-950 flex flex-col">
        <!-- Full-Screen Jitsi Meet Container -->
        <div id="jitsi-wrapper" class="relative z-10 w-full h-full"></div>

        <!-- Translucent Floating Ringing Countdown HUD (Never blocks Jitsi video behind it) -->
        <div id="ringing-hud" class="fixed bottom-6 inset-x-4 z-20 pointer-events-none flex justify-center">
            <div class="pointer-events-auto max-w-xl w-full bg-slate-900/90 backdrop-blur-xl border-2 border-white/15 text-white rounded-3xl shadow-2xl p-5 sm:p-6 flex flex-col gap-4">
                <div class="flex items-center justify-between gap-4">
                    <div class="flex items-center gap-4 min-w-0">
                        <div class="relative w-14 h-14 rounded-full bg-emerald-500 text-white flex items-center justify-center shrink-0 ring-pulse">
                            <svg class="w-7 h-7 animate-bounce" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
                            </svg>
                        </div>
                        <div class="min-w-0">
                            <h2 id="hud-calling-title" class="text-xl sm:text-2xl font-black truncate">Calling Dad...</h2>
                            <p class="text-sm font-bold text-slate-300">
                                Ringing phone • <span id="hud-countdown" class="text-emerald-400 font-black">45</span>s left
                            </p>
                        </div>
                    </div>

                    <button
                        type="button"
                        onclick="hideRingingHud()"
                        class="text-xs font-bold text-slate-300 hover:text-white bg-white/10 hover:bg-white/20 px-3 py-2 rounded-xl transition shrink-0"
                    >
                        Hide Banner
                    </button>
                </div>

                <div class="flex flex-col sm:flex-row gap-2.5">
                    <button
                        type="button"
                        onclick="hangUpCall('local')"
                        class="flex-1 bg-red-600 hover:bg-red-500 active:scale-[0.99] text-white font-black text-lg sm:text-xl py-4 px-5 rounded-2xl shadow-lg shadow-red-950/50 flex items-center justify-center gap-2.5 transition"
                    >
                        <svg class="w-6 h-6 rotate-[135deg]" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M6.62 10.79a15.053 15.053 0 006.59 6.59l2.2-2.2a1 1 0 011.01-.24c1.12.37 2.33.57 3.58.57a1 1 0 011 1V20a1 1 0 01-1 1C10.61 21 3 13.39 3 4a1 1 0 011-1h3.5a1 1 0 011 1c0 1.25.2 2.46.57 3.58a1 1 0 01-.24 1.01l-2.21 2.2z"/>
                        </svg>
                        <span>Hang Up / Cancel</span>
                    </button>
                    <button
                        type="button"
                        onclick="popOutCurrentCallToSafari()"
                        class="bg-white/10 hover:bg-white/20 text-slate-200 font-bold text-xs sm:text-sm px-4 py-3 rounded-2xl transition shrink-0"
                    >
                        Full Safari Tab ↗
                    </button>
                </div>
            </div>
        </div>
    </section>

    <!-- =====================================================================
         2B. OPTIONAL TOP-LEVEL SAFARI CALL COMPANION SCREEN
         ===================================================================== -->
    <section id="toplevel-call-screen" class="hidden fixed inset-0 z-40 bg-slate-950 text-white flex flex-col items-center justify-center p-6">
        <div class="max-w-lg w-full bg-slate-900 border-2 border-white/15 rounded-3xl p-7 text-center flex flex-col items-center gap-5 shadow-2xl">
            <div class="w-20 h-20 rounded-full bg-emerald-500/20 border-2 border-emerald-400 text-emerald-300 flex items-center justify-center">
                <svg class="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/>
                </svg>
            </div>
            <h2 id="toplevel-call-title" class="text-2xl sm:text-3xl font-black">Video Call Active in Safari</h2>
            <p class="text-sm sm:text-base text-slate-300 font-medium">
                Your video chat opened in a full Safari tab so the iPad microphone and camera work smoothly.
            </p>
            <div class="w-full flex flex-col gap-3 pt-2">
                <a
                    id="toplevel-reopen-link"
                    href="https://meet.jit.si"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="w-full bg-emerald-600 hover:bg-emerald-500 text-white font-black text-lg py-4 px-5 rounded-2xl transition"
                >
                    Switch Back to Video Tab ↗
                </a>
                <button
                    type="button"
                    onclick="closeTopLevelCall('local')"
                    class="w-full bg-red-600 hover:bg-red-500 text-white font-black text-lg py-4 px-5 rounded-2xl transition"
                >
                    End Call & Return to Dashboard
                </button>
            </div>
        </div>
    </section>

    <!-- =====================================================================
         2B-2. INCOMING CALL RINGING MODAL ON KIDS' IPAD (FROM PILOT PHONE)
         ===================================================================== -->
    <section id="incoming-call-modal" class="hidden fixed inset-0 z-50 bg-slate-950/95 backdrop-blur-xl text-white flex flex-col items-center justify-center p-6">
        <div class="max-w-lg w-full bg-slate-900 border-2 border-emerald-400/50 rounded-[2.25rem] p-7 sm:p-9 text-center flex flex-col items-center gap-6 shadow-2xl">
            <div id="incoming-call-avatar" class="relative">
                <!-- Populated dynamically -->
            </div>

            <div>
                <div class="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-emerald-500/20 border border-emerald-400/40 text-emerald-300 font-extrabold text-xs sm:text-sm uppercase tracking-wider mb-2">
                    <span class="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-ping"></span>
                    <span>Incoming Video Call</span>
                </div>
                <h2 id="incoming-call-title" class="text-3xl sm:text-4xl font-black text-white">Dad is Calling!</h2>
                <p class="text-base sm:text-lg text-slate-300 font-semibold mt-1">Tap the big green button to say hi!</p>
            </div>

            <div class="w-full flex flex-col gap-3 pt-1">
                <button
                    type="button"
                    onclick="answerIncomingCall()"
                    class="w-full bg-emerald-500 hover:bg-emerald-400 active:scale-[0.98] text-slate-950 font-black text-2xl sm:text-3xl py-6 px-6 rounded-3xl shadow-xl shadow-emerald-500/30 flex items-center justify-center gap-3 transition"
                >
                    <svg class="w-8 h-8 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
                    </svg>
                    <span>Answer</span>
                </button>

                <button
                    type="button"
                    onclick="dismissIncomingCallModal(true)"
                    class="w-full bg-white/10 hover:bg-white/20 text-slate-300 font-bold text-base py-3.5 px-5 rounded-2xl transition"
                >
                    Not Now
                </button>
            </div>
        </div>
    </section>

    <!-- =====================================================================
         2C. BUILT-IN KEYLESS AVIATION FLIGHT MAP (NO EXTERNAL TABS OR API KEYS)
         ===================================================================== -->
    <section id="tracker-screen" class="hidden fixed inset-0 z-40 bg-slate-950 text-white flex flex-col">
        <!-- Floating Top Navigation & Live Flight Telemetry Bar -->
        <div class="fixed top-4 inset-x-4 z-30 pointer-events-none flex flex-wrap items-start justify-between gap-3">
            <!-- Giant Kid-Friendly Return Button -->
            <button
                type="button"
                onclick="closeFlightAwareTracker()"
                class="pointer-events-auto bg-blue-600 hover:bg-blue-500 active:scale-95 text-white font-black text-base sm:text-xl px-5 py-3.5 sm:px-6 sm:py-4 rounded-2xl shadow-2xl shadow-blue-950/80 border-2 border-blue-400/50 flex items-center gap-2.5 transition"
            >
                <svg class="w-6 h-6 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M10 19l-7-7m0 0l7-7m-7 7h18"/>
                </svg>
                <span>Back to Flight Deck</span>
            </button>

            <!-- Live Telemetry & Zoom Controls Pill -->
            <div class="pointer-events-auto bg-slate-900/90 backdrop-blur-xl border border-white/15 rounded-2xl shadow-2xl px-4 py-3 flex items-center gap-4">
                <div>
                    <div class="flex items-center gap-2">
                        <span id="map-flight-ident" class="text-sky-400 font-black text-base sm:text-lg tracking-wide">AAL456</span>
                        <span class="text-slate-500">•</span>
                        <span id="map-route-label" class="text-white font-extrabold text-sm sm:text-base">DFW → LAX</span>
                    </div>
                    <div id="map-telemetry-sub" class="text-xs font-bold text-slate-300 mt-0.5">
                        Loading live radar position...
                    </div>
                </div>

                <div class="flex items-center gap-1.5 border-l border-white/10 pl-3">
                    <button
                        type="button"
                        onclick="zoomFlightMap(1.35)"
                        aria-label="Zoom in"
                        class="w-9 h-9 rounded-xl bg-white/10 hover:bg-white/20 text-white font-black text-lg flex items-center justify-center transition"
                    >+</button>
                    <button
                        type="button"
                        onclick="zoomFlightMap(0.74)"
                        aria-label="Zoom out"
                        class="w-9 h-9 rounded-xl bg-white/10 hover:bg-white/20 text-white font-black text-lg flex items-center justify-center transition"
                    >−</button>
                    <button
                        type="button"
                        onclick="resetFlightMapView()"
                        aria-label="Center route"
                        class="px-2.5 h-9 rounded-xl bg-white/10 hover:bg-white/20 text-sky-300 font-extrabold text-xs flex items-center justify-center transition"
                    >Fit</button>
                </div>
            </div>
        </div>

        <!-- Interactive Vector Aviation Radar Canvas -->
        <div id="flight-map-viewport" class="relative w-full h-full overflow-hidden bg-gradient-to-b from-slate-950 via-[#071326] to-slate-950 touch-none cursor-grab active:cursor-grabbing">
            <svg id="flight-map-svg" class="w-full h-full block" viewBox="0 0 1000 560" preserveAspectRatio="xMidYMid slice">
                <defs>
                    <radialGradient id="radarGlow" cx="50%" cy="50%" r="55%">
                        <stop offset="0%" stop-color="#0ea5e9" stop-opacity="0.16" />
                        <stop offset="100%" stop-color="#020617" stop-opacity="0" />
                    </radialGradient>
                    <filter id="planeShadow" x="-40%" y="-40%" width="180%" height="180%">
                        <feDropShadow dx="0" dy="3" stdDeviation="4" flood-color="#0284c7" flood-opacity="0.75"/>
                    </filter>
                </defs>
                <rect width="1000" height="560" fill="url(#radarGlow)" />
                <g id="map-pan-zoom-group">
                    <g id="map-graticule-layer"></g>
                    <g id="map-world-layer"></g>
                    <g id="map-states-layer"></g>
                    <g id="map-hubs-layer"></g>
                    <g id="map-route-layer"></g>
                    <g id="map-plane-layer"></g>
                </g>
            </svg>
        </div>

        <!-- Bottom Legend -->
        <div class="fixed bottom-4 inset-x-4 z-30 pointer-events-none flex justify-center">
            <div class="pointer-events-auto bg-slate-900/85 backdrop-blur-md border border-white/15 rounded-full px-5 py-2 text-xs sm:text-sm font-bold text-slate-300 flex items-center gap-3 shadow-xl">
                <span id="map-source-badge" class="inline-flex items-center gap-1.5 text-emerald-400">
                    <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
                    <span>Live Route Radar</span>
                </span>
                <span class="text-slate-600">|</span>
                <span>Drag or pinch to zoom</span>
            </div>
        </div>
    </section>

    <!-- =====================================================================
         2D. PILOT REMOTE MODE SCREEN (OPTIMIZED FOR GOOGLE PIXEL)
         ===================================================================== -->
    <section id="pilot-screen" class="hidden min-h-screen w-full bg-slate-950 text-white pb-24">
        <div id="pilot-remote-container" class="max-w-lg mx-auto p-4 sm:p-6 flex flex-col gap-5">
            <!-- Injected dynamically by renderPilotMode() -->
        </div>
    </section>

    <!-- =====================================================================
         3. PARENT SETTINGS & CREW PROFILES MODAL
         ===================================================================== -->
    <section id="settings-modal" class="hidden fixed inset-0 z-50 bg-slate-100 overflow-y-auto">
        <div class="max-w-6xl mx-auto p-4 sm:p-6 lg:p-8 pb-24">
            <!-- Sticky Top Header -->
            <div class="sticky top-0 z-10 bg-white/95 backdrop-blur-md border border-slate-200 rounded-3xl shadow-sm p-4 sm:p-5 mb-6 flex flex-wrap items-center justify-between gap-4">
                <div class="flex items-center gap-3">
                    <div class="w-11 h-11 rounded-2xl bg-blue-600 text-white flex items-center justify-center shadow-md">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"/>
                        </svg>
                    </div>
                    <div>
                        <h1 id="settings-modal-title" class="text-xl sm:text-2xl font-black text-slate-900">Parent Settings & Crew Profiles</h1>
                        <p id="settings-modal-subtitle" class="text-xs sm:text-sm text-slate-500 font-medium">All settings are saved automatically on this device.</p>
                    </div>
                </div>

                <button
                    type="button"
                    onclick="saveAndCloseSettings()"
                    class="bg-blue-600 hover:bg-blue-700 active:scale-95 text-white font-extrabold text-base sm:text-lg px-6 py-3 rounded-2xl shadow-lg shadow-blue-600/20 transition"
                >
                    Done & Save
                </button>
            </div>

            <!-- Two-Column Crew Profile Cards -->
            <div id="settings-profiles-grid" class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <!-- Rendered by renderSettings() -->
            </div>
        </div>
    </section>

    <!-- =====================================================================
         PER-PILOT CLOUD & KEYLESS NTFY RELAY SYNC BRIDGE
         ===================================================================== -->
    <script type="module">
        import { initializeApp } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-app.js";
        import { getAuth, signInAnonymously, signInWithCustomToken } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-auth.js";
        import { getFirestore, doc, setDoc, onSnapshot } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-firestore.js";

        let firestoreDb = null;
        let firestoreUser = null;
        const activeChannels = new Map();
        const lastHashByCode = new Map();

        function sanitizeSyncCode(raw) {
            return String(raw || '').toUpperCase().replace(/[^A-Z0-9-]/g, '').slice(0, 24);
        }

        async function initFirestoreIfAvailable() {
            if (firestoreDb && firestoreUser) return true;
            try {
                let firebaseConfig = null;
                if (typeof __firebase_config !== 'undefined' && __firebase_config) {
                    firebaseConfig = typeof __firebase_config === 'string'
                        ? JSON.parse(__firebase_config)
                        : __firebase_config;
                }
                if (!firebaseConfig || !firebaseConfig.apiKey) return false;

                const app = initializeApp(firebaseConfig);
                const auth = getAuth(app);
                firestoreDb = getFirestore(app);

                if (typeof __initial_auth_token !== 'undefined' && __initial_auth_token) {
                    const cred = await signInWithCustomToken(auth, __initial_auth_token);
                    firestoreUser = cred.user;
                } else {
                    const cred = await signInAnonymously(auth);
                    firestoreUser = cred.user;
                }
                return Boolean(firestoreUser);
            } catch (err) {
                console.warn('Firestore unavailable, using keyless ntfy JSON state relay:', err.message);
                return false;
            }
        }

        function stopChannel(channelKey) {
            const existing = activeChannels.get(channelKey);
            if (!existing) return;
            if (existing.unsubscribe) {
                try { existing.unsubscribe(); } catch (e) { /* ignore */ }
            }
            if (existing.pollTimer) {
                clearInterval(existing.pollTimer);
            }
            activeChannels.delete(channelKey);
        }

        window.cloudSyncBridge = {
            stopAll() {
                for (const key of Array.from(activeChannels.keys())) {
                    stopChannel(key);
                }
            },

            async connectChannel(channelKey, rawCode, onRemoteProfileState, onStatusChange) {
                stopChannel(channelKey);
                const code = sanitizeSyncCode(rawCode);
                if (!code) {
                    if (onStatusChange) onStatusChange('offline', 'Enter a Sync Code to link devices');
                    return;
                }

                const hasFirestore = await initFirestoreIfAvailable();
                if (hasFirestore && firestoreDb && firestoreUser) {
                    const appId = typeof __app_id !== 'undefined' ? __app_id : 'default-app-id';
                    const docRef = doc(firestoreDb, 'artifacts', appId, 'public', 'data', 'family_flight_deck_pilot_v2', code);
                    if (onStatusChange) onStatusChange('connected', `Cloud Sync Live (${code})`);

                    const unsubscribe = onSnapshot(
                        docRef,
                        (snap) => {
                            if (snap.exists()) {
                                const data = snap.data();
                                if (data && data.payloadJson && data.payloadJson !== lastHashByCode.get(code)) {
                                    lastHashByCode.set(code, data.payloadJson);
                                    try {
                                        onRemoteProfileState(JSON.parse(data.payloadJson));
                                    } catch (e) { /* ignore */ }
                                }
                            }
                        },
                        (err) => {
                            console.warn('Firestore listener error:', err);
                            if (onStatusChange) onStatusChange('error', 'Cloud sync retrying...');
                        }
                    );
                    activeChannels.set(channelKey, { unsubscribe });
                    return;
                }

                // Zero-config fallback: per-pilot ntfy.sh JSON state topic
                const relayTopic = `ffd-pilot-${code.toLowerCase()}`;
                if (onStatusChange) onStatusChange('connected', `Live Relay Linked (${code})`);

                const pollRelay = async () => {
                    try {
                        const res = await fetch(`https://ntfy.sh/${encodeURIComponent(relayTopic)}/json?poll=1&since=12h`, {
                            cache: 'no-store'
                        });
                        if (!res.ok) return;
                        const text = await res.text();
                        const lines = text.trim().split('\n').filter(Boolean);
                        for (let i = lines.length - 1; i >= 0; i--) {
                            const evt = JSON.parse(lines[i]);
                            if (evt && evt.event === 'message' && evt.message) {
                                if (evt.message !== lastHashByCode.get(code)) {
                                    lastHashByCode.set(code, evt.message);
                                    const parsed = JSON.parse(evt.message);
                                    onRemoteProfileState(parsed);
                                }
                                break;
                            }
                        }
                    } catch (err) {
                        // Silent background retry
                    }
                };

                await pollRelay();
                const pollTimer = setInterval(pollRelay, 2500);
                activeChannels.set(channelKey, { pollTimer });
            },

            async pushChannel(rawCode, profileStateObject, onStatusChange) {
                const code = sanitizeSyncCode(rawCode);
                if (!code) return false;

                const payloadJson = JSON.stringify(profileStateObject);
                lastHashByCode.set(code, payloadJson);

                const hasFirestore = await initFirestoreIfAvailable();
                if (hasFirestore && firestoreDb && firestoreUser) {
                    try {
                        const appId = typeof __app_id !== 'undefined' ? __app_id : 'default-app-id';
                        const docRef = doc(firestoreDb, 'artifacts', appId, 'public', 'data', 'family_flight_deck_pilot_v2', code);
                        await setDoc(docRef, {
                            payloadJson,
                            updatedAt: Date.now()
                        }, { merge: true });
                        if (onStatusChange) onStatusChange('connected', `Synced to iPad • ${new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`);
                        return true;
                    } catch (err) {
                        console.error('Firestore write failed:', err);
                    }
                }

                // Fallback publish to per-pilot ntfy.sh JSON relay topic
                const relayTopic = `ffd-pilot-${code.toLowerCase()}`;
                try {
                    const res = await fetch(`https://ntfy.sh/${encodeURIComponent(relayTopic)}`, {
                        method: 'POST',
                        headers: {
                            'Title': 'FFD Pilot State',
                            'Priority': 'low'
                        },
                        body: payloadJson
                    });
                    if (!res.ok) throw new Error(`HTTP ${res.status}`);
                    if (onStatusChange) onStatusChange('connected', `Synced to iPad • ${new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`);
                    return true;
                } catch (err) {
                    console.error('State relay push failed:', err);
                    if (onStatusChange) onStatusChange('error', 'Sync failed — check connection');
                    return false;
                }
            }
        };
    </script>

    <!-- =====================================================================
         MAIN APPLICATION SCRIPT
         ===================================================================== -->
    <script>
        // ============================================================================
        // CONSTANTS, AIRPORT DATABASE & UTILITY HELPERS
        // ============================================================================
        const STORAGE_KEY = 'family_flight_deck_profiles_v3';
        const APP_META_KEY = 'family_flight_deck_meta_v3';

        const IATA_TO_ICAO = {
            AA: 'AAL', DL: 'DAL', UA: 'UAL', WN: 'SWA', B6: 'JBU',
            AS: 'ASA', NK: 'NKS', F9: 'FFT', HA: 'HAL', SY: 'SCX',
            G4: 'AAY', MX: 'MXY', XP: 'VXP', OO: 'SKW', YX: 'RPA',
            MQ: 'ENY', OH: 'JIA', '9E': 'EDV', YV: 'ASH', QX: 'QXE',
            ZW: 'AWI', G7: 'GJS', C5: 'UCA', PT: 'PDT', BA: 'BAW',
            LH: 'DLH', AF: 'AFR', KL: 'KLM', AC: 'ACA', WS: 'WJA',
            QF: 'QFA', EK: 'UAE', QR: 'QTR', SQ: 'SIA', JL: 'JAL',
            NH: 'ANA', CX: 'CPA', VS: 'VIR', EI: 'EIN', IB: 'IBE'
        };

        const AIRPORT_COORDS = {
            ATL: [33.6407, -84.4277], DFW: [32.8998, -97.0403], DEN: [39.8561, -104.6737],
            ORD: [41.9742, -87.9073], LAX: [33.9416, -118.4085], JFK: [40.6413, -73.7781],
            LAS: [36.0840, -115.1537], MCO: [28.4312, -81.3081], MIA: [25.7959, -80.2870],
            CLT: [35.2144, -80.9473], SEA: [47.4502, -122.3088], PHX: [33.4352, -112.0101],
            EWR: [40.6895, -74.1745], SFO: [37.6213, -122.3790], IAH: [29.9902, -95.3368],
            BOS: [42.3656, -71.0096], FLL: [26.0742, -80.1506], MSP: [44.8848, -93.2223],
            LGA: [40.7769, -73.8740], DTW: [42.2162, -83.3554], PHL: [39.8744, -75.2424],
            SLC: [40.7899, -111.9791], DCA: [38.8512, -77.0402], IAD: [38.9531, -77.4565],
            SAN: [32.7338, -117.1933], BWI: [39.1774, -76.6684], TPA: [27.9755, -82.5332],
            AUS: [30.1975, -97.6664], BNA: [36.1263, -86.6774], MDW: [41.7868, -87.7522],
            HNL: [21.3187, -157.9225], PDX: [45.5898, -122.5951], STL: [38.7487, -90.3700],
            RDU: [35.8801, -78.7880], HOU: [29.6454, -95.2789], SMK: [38.6951, -121.5908],
            SMF: [38.6951, -121.5908], SJC: [37.3639, -121.9289], OAK: [37.7126, -122.2197],
            MSY: [29.9911, -90.2592], MCI: [39.2976, -94.7139], CLE: [41.4058, -81.8539],
            CMH: [39.9980, -82.8919], IND: [39.7173, -86.2944], PIT: [40.4915, -80.2329],
            CVG: [39.0488, -84.6678], SAT: [29.5337, -98.4698], RSW: [26.5362, -81.7552],
            JAX: [30.4941, -81.6879], OMA: [41.3032, -95.8941], ABQ: [35.0402, -106.6090],
            ANC: [61.1743, -149.9982], YYZ: [43.6777, -79.6248], YVR: [49.1967, -123.1815],
            YUL: [45.4706, -73.7408], MEX: [19.4361, -99.0719], CUN: [21.0365, -86.8771],
            LHR: [51.4700, -0.4543], LGW: [51.1537, -0.1821], CDG: [49.0097, 2.5479],
            AMS: [52.3105, 4.7683], FRA: [50.0379, 8.5622], MUC: [48.3537, 11.7750],
            MAD: [40.4983, -3.5676], FCO: [41.8003, 12.2389], DUB: [53.4264, -6.2499],
            NRT: [35.7720, 140.3929], HND: [35.5494, 139.7798], ICN: [37.4602, 126.4407],
            SYD: [-33.9399, 151.1753], SJU: [18.4394, -66.0018], STT: [18.3373, -64.9734]
        };

        function generateSlug(prefix = 'Room') {
            const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
            let suffix = '';
            for (let i = 0; i < 6; i++) {
                suffix += chars.charAt(Math.floor(Math.random() * chars.length));
            }
            return `${prefix}-${suffix}`;
        }

        function sanitizeRoomName(raw) {
            const cleaned = String(raw || '').replace(/[^a-zA-Z0-9_-]/g, '');
            return cleaned || generateSlug('FlightDeck');
        }

        function sanitizeDomain(raw) {
            const cleaned = String(raw || '')
                .replace(/^https?:\/\//i, '')
                .replace(/\/.*$/, '')
                .trim();
            return cleaned || 'meet.jit.si';
        }

        function toFlightAwareIdent(rawFlight) {
            const clean = String(rawFlight || '').toUpperCase().replace(/[^A-Z0-9]/g, '');
            const m = clean.match(/^([A-Z]{2})(\d{1,4}[A-Z]?)$/);
            if (m && IATA_TO_ICAO[m[1]]) {
                return `${IATA_TO_ICAO[m[1]]}${m[2]}`;
            }
            return clean || 'AAL456';
        }

        function formatDurationHuman(ms) {
            const totalMins = Math.max(Math.round(ms / 60000), 1);
            const hours = Math.floor(totalMins / 60);
            const mins = totalMins % 60;
            if (hours > 0 && mins > 0) return `${hours}h ${mins}m`;
            if (hours > 0) return `${hours}h`;
            return `${mins}m`;
        }

        function escapeHtml(str) {
            return String(str ?? '')
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#39;');
        }

        function isIPadOrIOS() {
            const ua = navigator.userAgent || '';
            return /iPad|iPhone|iPod/.test(ua) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
        }

        // ============================================================================
        // DEFAULT STATE & PERSISTENCE (localStorage)
        // ============================================================================
        function generatePilotSyncCode(tag = 'DAD') {
            const num = Math.floor(1000 + Math.random() * 9000);
            return `${tag}-${num}`;
        }

        const DEFAULT_PROFILES = [
            {
                id: 1,
                enabled: true,
                syncCode: generatePilotSyncCode('DAD'),
                name: 'Dad',
                callLabel: 'Call Dad',
                avatarDataUrl: '',
                jitsiRoom: generateSlug('FlightDeckDad'),
                jitsiDomain: 'meet.jit.si',
                callLaunchMode: 'embedded',
                ntfyTopic: generateSlug('flightdeck-dad'),
                icsUrl: '',
                icsText: '',
                simulationMode: 'live',
                manualFlight: {
                    flightNumber: 'AAL456',
                    origin: 'DFW',
                    destination: 'LAX',
                    minutesRemaining: 95,
                    airport: 'DEN',
                    nextFlightNumber: 'AAL789',
                    nextMinutes: 720
                },
                pilotNote: '',
                pilotNoteUpdatedAt: 0,
                incomingCall: null
            },
            {
                id: 2,
                enabled: false,
                syncCode: generatePilotSyncCode('MOM'),
                name: 'Mom',
                callLabel: 'Call Mom',
                avatarDataUrl: '',
                jitsiRoom: generateSlug('FlightDeckMom'),
                jitsiDomain: 'meet.jit.si',
                callLaunchMode: 'embedded',
                ntfyTopic: generateSlug('flightdeck-mom'),
                icsUrl: '',
                icsText: '',
                simulationMode: 'live',
                manualFlight: {
                    flightNumber: 'DAL123',
                    origin: 'ATL',
                    destination: 'SEA',
                    minutesRemaining: 120,
                    airport: 'MSP',
                    nextFlightNumber: 'DAL456',
                    nextMinutes: 640
                },
                pilotNote: '',
                pilotNoteUpdatedAt: 0,
                incomingCall: null
            }
        ];

        let appMeta = {
            deviceRole: 'kid', // 'kid' | 'pilot'
            selectedPilotProfileId: 1
        };
        let syncStatusState = 'offline';
        let syncStatusMessage = 'Not linked yet';
        const lastRemoteTimestampByProfile = { 1: 0, 2: 0 };
        const handledIncomingCallIds = new Set();
        let activeIncomingCall = null;
        let outgoingPilotCallProfileId = null;
        let outgoingPilotCallId = null;

        let profiles = [];
        let dashboardTimer = null;
        let currentJitsiApi = null;
        let currentEmbeddedProfileId = null;
        let activeTopLevelCallWindow = null;
        let topLevelCallWatchInterval = null;
        let ringCountdownInterval = null;
        let participantPollInterval = null;
        let isCallConnected = false;
        let isHangingUp = false;
        let activeCallProfileName = '';
        let bannerDismissTimeout = null;
        let loadedJitsiDomain = '';

        // Built-In Aviation Flight Map State
        let mapZoomBehavior = null;
        let mapDefaultTransform = null;
        let cachedWorldFeatures = null;
        let cachedUsStateFeatures = null;
        let geoAtlasLoadPromise = null;
        let mapLivePollInterval = null;

        // Media Permission Diagnostics
        let micPermissionState = 'unknown';
        let camPermissionState = 'unknown';
        let mediaPermissionDetail = '';

        // ============================================================================
        // PROFILE STORAGE, URL PAIRING & DEVICE ROLE HELPERS
        // ============================================================================
        function sanitizePilotSyncCode(raw) {
            return String(raw || '').toUpperCase().replace(/[^A-Z0-9-]/g, '').slice(0, 24);
        }

        function loadProfiles() {
            try {
                const rawProfiles = localStorage.getItem(STORAGE_KEY);
                const parsed = rawProfiles ? JSON.parse(rawProfiles) : null;
                if (Array.isArray(parsed) && parsed.length > 0) {
                    profiles = DEFAULT_PROFILES.map((def, idx) => {
                        const saved = parsed[idx] || {};
                        return {
                            ...def,
                            ...saved,
                            manualFlight: {
                                ...def.manualFlight,
                                ...(saved.manualFlight || {})
                            }
                        };
                    });
                } else {
                    profiles = JSON.parse(JSON.stringify(DEFAULT_PROFILES));
                }
            } catch (e) {
                profiles = JSON.parse(JSON.stringify(DEFAULT_PROFILES));
            }

            try {
                const rawMeta = localStorage.getItem(APP_META_KEY);
                if (rawMeta) {
                    appMeta = { ...appMeta, ...JSON.parse(rawMeta) };
                }
            } catch (e) { /* ignore */ }

            // Check URL parameters for direct Pilot Remote (?mode=pilot) or iPad Pairing (?mode=kid&code1=...&code2=...)
            try {
                const params = new URLSearchParams(window.location.search);
                const urlMode = params.get('mode');
                if (urlMode === 'pilot' || urlMode === 'kid') {
                    appMeta.deviceRole = urlMode;
                }
                const code1 = params.get('code1');
                if (code1) {
                    profiles[0].syncCode = sanitizePilotSyncCode(code1);
                    profiles[0].enabled = true;
                }
                const code2 = params.get('code2');
                if (code2 && profiles[1]) {
                    profiles[1].syncCode = sanitizePilotSyncCode(code2);
                    profiles[1].enabled = true;
                }
            } catch (e) { /* ignore */ }

            saveProfiles();
            saveAppMeta();
        }

        function saveProfiles() {
            try {
                localStorage.setItem(STORAGE_KEY, JSON.stringify(profiles));
            } catch (e) {
                console.warn('Unable to save profiles to localStorage:', e);
            }
        }

        function saveAppMeta() {
            try {
                localStorage.setItem(APP_META_KEY, JSON.stringify(appMeta));
            } catch (e) {
                console.warn('Unable to save app metadata:', e);
            }
        }

        function setDeviceRole(role) {
            appMeta.deviceRole = role === 'pilot' ? 'pilot' : 'kid';
            saveAppMeta();
            applyActiveDeviceRoleView();
            initCloudSync();
        }

        function applyActiveDeviceRoleView() {
            const dashboardEl = document.getElementById('dashboard-screen');
            const pilotEl = document.getElementById('pilot-screen');
            const gearBtn = document.getElementById('gear-hold-btn');
            const pilotBadgeBtn = document.getElementById('pilot-mode-badge-btn');

            if (appMeta.deviceRole === 'pilot') {
                if (dashboardEl) dashboardEl.classList.add('hidden');
                if (pilotEl) pilotEl.classList.remove('hidden');
                if (gearBtn) gearBtn.classList.add('hidden');
                if (pilotBadgeBtn) pilotBadgeBtn.classList.add('hidden');
                renderPilotMode();
            } else {
                if (pilotEl) pilotEl.classList.add('hidden');
                if (dashboardEl) dashboardEl.classList.remove('hidden');
                if (gearBtn) gearBtn.classList.remove('hidden');
                if (pilotBadgeBtn) pilotBadgeBtn.classList.add('hidden');
                renderDashboard();
            }
        }

        // ============================================================================
        // 2-SECOND HOLD-TO-OPEN SETTINGS GATE (KID-PROOF)
        // ============================================================================
        function initHoldSettingsGate() {
            const btn = document.getElementById('gear-hold-btn');
            const ring = document.getElementById('gear-progress-ring');
            const hint = document.getElementById('hold-hint-pill');
            if (!btn || !ring) return;

            const CIRCUMFERENCE = 131.95;
            const HOLD_DURATION_MS = 2000;
            let holdStart = null;
            let rafId = null;
            let triggered = false;

            const resetRing = () => {
                holdStart = null;
                triggered = false;
                if (rafId) {
                    cancelAnimationFrame(rafId);
                    rafId = null;
                }
                ring.style.strokeDashoffset = String(CIRCUMFERENCE);
                if (hint) hint.classList.add('hidden');
            };

            const step = (now) => {
                if (!holdStart || triggered) return;
                const elapsed = now - holdStart;
                const progress = Math.min(elapsed / HOLD_DURATION_MS, 1);
                ring.style.strokeDashoffset = String(CIRCUMFERENCE * (1 - progress));

                if (progress >= 1) {
                    triggered = true;
                    resetRing();
                    openSettings();
                    return;
                }
                rafId = requestAnimationFrame(step);
            };

            const startHold = (e) => {
                if (e.button !== undefined && e.button !== 0) return;
                triggered = false;
                holdStart = performance.now();
                if (hint) hint.classList.remove('hidden');
                rafId = requestAnimationFrame(step);
            };

            btn.addEventListener('pointerdown', startHold);
            btn.addEventListener('pointerup', resetRing);
            btn.addEventListener('pointerleave', resetRing);
            btn.addEventListener('pointercancel', resetRing);
            btn.addEventListener('contextmenu', (e) => e.preventDefault());
        }

        // ============================================================================
        // TOP BANNER & IFRAME-SAFE CLIPBOARD HELPERS
        // ============================================================================
        function showTopBanner(message, durationMs = 10000, tone = 'amber') {
            const banner = document.getElementById('top-banner');
            const card = document.getElementById('top-banner-card');
            const textEl = document.getElementById('top-banner-text');
            if (!banner || !card || !textEl) return;

            textEl.textContent = message;
            if (tone === 'blue') {
                card.className = 'pointer-events-auto mt-4 max-w-2xl w-full bg-sky-500 text-slate-950 border-2 border-sky-600 rounded-2xl shadow-2xl px-5 py-4 flex items-center justify-between gap-4';
            } else {
                card.className = 'pointer-events-auto mt-4 max-w-2xl w-full bg-amber-400 text-amber-950 border-2 border-amber-500 rounded-2xl shadow-2xl px-5 py-4 flex items-center justify-between gap-4';
            }

            banner.classList.remove('-translate-y-full', 'opacity-0');

            if (bannerDismissTimeout) clearTimeout(bannerDismissTimeout);
            bannerDismissTimeout = setTimeout(() => {
                hideTopBanner();
            }, durationMs);
        }

        function hideTopBanner() {
            const banner = document.getElementById('top-banner');
            if (banner) {
                banner.classList.add('-translate-y-full', 'opacity-0');
            }
        }

        function copyTextToClipboard(text, successMessage = 'Copied to clipboard!') {
            try {
                const ta = document.createElement('textarea');
                ta.value = text;
                ta.setAttribute('readonly', '');
                ta.style.position = 'fixed';
                ta.style.opacity = '0';
                document.body.appendChild(ta);
                ta.select();
                document.execCommand('copy');
                document.body.removeChild(ta);
                showTopBanner(successMessage, 5000, 'blue');
            } catch (err) {
                showTopBanner(`Copy value: ${text}`, 8000, 'amber');
            }
        }

        // ============================================================================
        // PER-PILOT CLOUD & KEYLESS RELAY SYNC HANDLERS
        // ============================================================================
        function updateSyncUiStatus(state, message) {
            syncStatusState = state;
            syncStatusMessage = message;
            const statusEl = document.getElementById('pilot-sync-status-text');
            if (statusEl) {
                statusEl.textContent = message;
                statusEl.className = `text-xs font-bold ${state === 'connected' ? 'text-emerald-400' : 'text-amber-400'}`;
            }
        }

        function applyRemoteProfilePayload(targetProfileId, remoteData) {
            if (!remoteData || typeof remoteData !== 'object') return;
            const p = profiles.find(item => item.id === targetProfileId);
            if (!p) return;

            const incomingTs = Number(remoteData.updatedAt || 0);
            if (incomingTs && incomingTs <= (lastRemoteTimestampByProfile[targetProfileId] || 0)) {
                return;
            }
            if (incomingTs) {
                lastRemoteTimestampByProfile[targetProfileId] = incomingTs;
            }

            const syncableKeys = [
                'name', 'callLabel', 'jitsiRoom', 'jitsiDomain', 'ntfyTopic',
                'icsUrl', 'icsText', 'simulationMode', 'pilotNote', 'pilotNoteUpdatedAt'
            ];
            for (const key of syncableKeys) {
                if (remoteData[key] !== undefined) {
                    p[key] = remoteData[key];
                }
            }
            if (remoteData.manualFlight && typeof remoteData.manualFlight === 'object') {
                p.manualFlight = { ...p.manualFlight, ...remoteData.manualFlight };
            }
            if (remoteData.incomingCall !== undefined) {
                p.incomingCall = remoteData.incomingCall;
            }

            saveProfiles();

            // Handle incoming two-way call alerts on the Kids' iPad
            if (appMeta.deviceRole === 'kid' && remoteData.incomingCall) {
                const inc = remoteData.incomingCall;
                if (inc.active && inc.callId && !handledIncomingCallIds.has(inc.callId)) {
                    const ageMs = Date.now() - Number(inc.timestamp || Date.now());
                    if (ageMs < 65000) {
                        showIncomingCallModal(targetProfileId, inc);
                    }
                } else if (!inc.active) {
                    if (activeIncomingCall && activeIncomingCall.profileId === targetProfileId) {
                        dismissIncomingCallModal(true);
                    }
                    if (currentEmbeddedProfileId === targetProfileId && !isHangingUp) {
                        hangUpCall('remote');
                    }
                }
            }

            if (appMeta.deviceRole === 'pilot') {
                renderPilotMode();
            } else {
                renderDashboard();
            }
        }

        function initCloudSync() {
            if (!window.cloudSyncBridge) {
                setTimeout(initCloudSync, 300);
                return;
            }

            window.cloudSyncBridge.stopAll();

            if (appMeta.deviceRole === 'pilot') {
                const selected = profiles.find(p => p.id === appMeta.selectedPilotProfileId) || profiles[0];
                if (selected && selected.syncCode) {
                    window.cloudSyncBridge.connectChannel(
                        `pilot-${selected.id}`,
                        selected.syncCode,
                        (remoteData) => applyRemoteProfilePayload(selected.id, remoteData),
                        updateSyncUiStatus
                    );
                }
            } else {
                profiles.forEach((p, idx) => {
                    if ((idx === 0 || p.enabled) && p.syncCode) {
                        window.cloudSyncBridge.connectChannel(
                            `kid-parent-${p.id}`,
                            p.syncCode,
                            (remoteData) => applyRemoteProfilePayload(p.id, remoteData),
                            updateSyncUiStatus
                        );
                    }
                });
            }
        }

        async function pushSingleProfileState(profileId, showToast = false) {
            const p = profiles.find(item => item.id === profileId);
            if (!p || !p.syncCode || !window.cloudSyncBridge) return false;

            const payload = {
                updatedAt: Date.now(),
                name: p.name,
                callLabel: p.callLabel,
                jitsiRoom: p.jitsiRoom,
                jitsiDomain: p.jitsiDomain,
                ntfyTopic: p.ntfyTopic,
                icsUrl: p.icsUrl,
                icsText: p.icsText,
                simulationMode: p.simulationMode,
                manualFlight: p.manualFlight,
                pilotNote: p.pilotNote,
                pilotNoteUpdatedAt: p.pilotNoteUpdatedAt,
                incomingCall: p.incomingCall || null
            };

            const ok = await window.cloudSyncBridge.pushChannel(p.syncCode, payload, updateSyncUiStatus);
            if (ok && showToast) {
                showTopBanner(`Synced ${p.name}'s update to Kids' iPad!`, 4000, 'blue');
            }
            return ok;
        }

        async function pushSyncStateNow(showToast = false) {
            if (appMeta.deviceRole === 'pilot') {
                return pushSingleProfileState(appMeta.selectedPilotProfileId, showToast);
            }
            for (let i = 0; i < profiles.length; i++) {
                if (i === 0 || profiles[i].enabled) {
                    await pushSingleProfileState(profiles[i].id, false);
                }
            }
            if (showToast) {
                showTopBanner('Synced all active profiles!', 4000, 'blue');
            }
            return true;
        }

        // ============================================================================
        // CREW CALENDAR (.ICS) UTC PARSER & REMOTE SYNC
        // ============================================================================
        function parseICSDateUTC(raw) {
            if (!raw) return null;
            const clean = String(raw).trim();
            // Match YYYYMMDDTHHMMSSZ or YYYYMMDDTHHMMSS
            const dtMatch = clean.match(/^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})(Z?)$/);
            if (dtMatch) {
                const year = parseInt(dtMatch[1], 10);
                const month = parseInt(dtMatch[2], 10) - 1;
                const day = parseInt(dtMatch[3], 10);
                const hour = parseInt(dtMatch[4], 10);
                const min = parseInt(dtMatch[5], 10);
                const sec = parseInt(dtMatch[6], 10);
                return new Date(Date.UTC(year, month, day, hour, min, sec));
            }
            // Match all-day YYYYMMDD
            const dateMatch = clean.match(/^(\d{4})(\d{2})(\d{2})$/);
            if (dateMatch) {
                return new Date(Date.UTC(
                    parseInt(dateMatch[1], 10),
                    parseInt(dateMatch[2], 10) - 1,
                    parseInt(dateMatch[3], 10),
                    0, 0, 0
                ));
            }
            const fallback = new Date(clean);
            return Number.isNaN(fallback.getTime()) ? null : fallback;
        }

        function parseICSEvents(icsText) {
            if (!icsText || typeof icsText !== 'string') return [];

            // Unfold RFC 5545 folded lines
            const unfolded = icsText.replace(/\r\n[ \t]/g, '').replace(/\n[ \t]/g, '');
            const lines = unfolded.split(/\r?\n/);

            const events = [];
            let current = null;

            for (const line of lines) {
                if (line === 'BEGIN:VEVENT') {
                    current = {};
                } else if (line === 'END:VEVENT') {
                    if (current && current.start && current.end) {
                        const combinedText = `${current.summary || ''} ${current.location || ''} ${current.description || ''}`;
                        const flightMatch = combinedText.match(/\b([A-Z]{2,3})\s?(\d{1,4}[A-Z]?)\b/);
                        const routeMatch = combinedText.match(/\b([A-Z]{3})\s*(?:-|–|—|to|\/|>|→)\s*([A-Z]{3})\b/i);

                        const flightNumber = flightMatch
                            ? `${flightMatch[1].toUpperCase()}${flightMatch[2].toUpperCase()}`
                            : 'FLT101';
                        const origin = routeMatch ? routeMatch[1].toUpperCase() : 'DFW';
                        const destination = routeMatch ? routeMatch[2].toUpperCase() : 'LAX';

                        events.push({
                            start: current.start,
                            end: current.end,
                            summary: current.summary || `${flightNumber} ${origin}-${destination}`,
                            location: current.location || `${origin}-${destination}`,
                            flightNumber,
                            origin,
                            destination
                        });
                    }
                    current = null;
                } else if (current) {
                    const colonIdx = line.indexOf(':');
                    if (colonIdx === -1) continue;
                    const propPart = line.slice(0, colonIdx).toUpperCase();
                    const valPart = line.slice(colonIdx + 1).trim();

                    if (propPart.startsWith('DTSTART')) {
                        current.start = parseICSDateUTC(valPart);
                    } else if (propPart.startsWith('DTEND')) {
                        current.end = parseICSDateUTC(valPart);
                    } else if (propPart.startsWith('SUMMARY')) {
                        current.summary = valPart.replace(/\\,/g, ',').replace(/\\n/g, ' ');
                    } else if (propPart.startsWith('LOCATION')) {
                        current.location = valPart.replace(/\\,/g, ',').replace(/\\n/g, ' ');
                    } else if (propPart.startsWith('DESCRIPTION')) {
                        current.description = valPart.replace(/\\,/g, ',').replace(/\\n/g, ' ');
                    }
                }
            }

            events.sort((a, b) => a.start.getTime() - b.start.getTime());
            return events;
        }

        async function refreshAllRemoteCalendars() {
            let anyUpdated = false;
            for (const p of profiles) {
                const url = (p.icsUrl || '').trim();
                if (!url) continue;
                try {
                    const res = await fetch(url, { cache: 'no-store' });
                    if (!res.ok) continue;
                    const text = await res.text();
                    if (text && text.includes('BEGIN:VCALENDAR') && text !== p.icsText) {
                        p.icsText = text;
                        anyUpdated = true;
                    }
                } catch (err) {
                    // CORS or offline; keep existing cached icsText
                }
            }
            if (anyUpdated) {
                saveProfiles();
                if (appMeta.deviceRole === 'pilot') {
                    renderPilotMode();
                } else {
                    renderDashboard();
                }
            }
        }

        // ============================================================================
        // STATUS EVALUATOR & KID-FRIENDLY HOME DASHBOARD RENDERER
        // ============================================================================
        function evaluateProfileStatus(profile) {
            const now = Date.now();
            const mode = profile.simulationMode || 'live';
            const mf = profile.manualFlight || {};

            if (mode === 'in-flight') {
                const minsLeft = Math.max(Number(mf.minutesRemaining) || 95, 1);
                const totalMins = Math.max(minsLeft + 45, 120);
                const progressPct = Math.min(Math.max(Math.round(((totalMins - minsLeft) / totalMins) * 100), 8), 94);
                return {
                    state: 'in-flight',
                    badgeText: 'In the Air',
                    flightNumber: toFlightAwareIdent(mf.flightNumber || 'AAL456'),
                    origin: (mf.origin || 'DFW').toUpperCase(),
                    destination: (mf.destination || 'LAX').toUpperCase(),
                    progressPct,
                    countdownText: `Landing in ${formatDurationHuman(minsLeft * 60000)}`
                };
            }

            if (mode === 'pre-flight') {
                return {
                    state: 'pre-flight',
                    badgeText: 'Boarding Soon',
                    flightNumber: toFlightAwareIdent(mf.flightNumber || 'AAL456'),
                    origin: (mf.origin || 'DFW').toUpperCase(),
                    destination: (mf.destination || 'LAX').toUpperCase(),
                    progressPct: 4,
                    countdownText: 'Departing in 45m'
                };
            }

            if (mode === 'layover') {
                const airport = (mf.airport || 'DEN').toUpperCase();
                const nextFlt = toFlightAwareIdent(mf.nextFlightNumber || 'AAL789');
                const nextMins = Math.max(Number(mf.nextMinutes) || 720, 15);
                return {
                    state: 'layover',
                    badgeText: `On Layover in ${airport}`,
                    airport,
                    nextFlightNumber: nextFlt,
                    countdownText: `Next flight (${nextFlt}) in ${formatDurationHuman(nextMins * 60000)}`
                };
            }

            if (mode === 'off-duty') {
                return {
                    state: 'off-duty',
                    badgeText: 'Off Duty'
                };
            }

            // Live .ics calendar evaluation
            const legs = parseICSEvents(profile.icsText);
            if (!legs.length) {
                return { state: 'off-duty', badgeText: 'Off Duty' };
            }

            // 1. Check In Flight
            for (const leg of legs) {
                const startMs = leg.start.getTime();
                const endMs = leg.end.getTime();
                if (now >= startMs && now <= endMs) {
                    const duration = Math.max(endMs - startMs, 60000);
                    const elapsed = now - startMs;
                    const progressPct = Math.min(Math.max(Math.round((elapsed / duration) * 100), 4), 96);
                    const remMs = Math.max(endMs - now, 60000);
                    return {
                        state: 'in-flight',
                        badgeText: 'In the Air',
                        flightNumber: toFlightAwareIdent(leg.flightNumber),
                        origin: leg.origin,
                        destination: leg.destination,
                        progressPct,
                        countdownText: `Landing in ${formatDurationHuman(remMs)}`
                    };
                }
            }

            // 2. Check Pre-Flight / Boarding (within 90 mins before DTSTART)
            for (const leg of legs) {
                const startMs = leg.start.getTime();
                const diffMs = startMs - now;
                if (diffMs > 0 && diffMs <= 90 * 60000) {
                    return {
                        state: 'pre-flight',
                        badgeText: 'Boarding Soon',
                        flightNumber: toFlightAwareIdent(leg.flightNumber),
                        origin: leg.origin,
                        destination: leg.destination,
                        progressPct: 3,
                        countdownText: `Departing in ${formatDurationHuman(diffMs)}`
                    };
                }
            }

            // 3. Check On Layover / Ground between completed leg and upcoming leg on active pairing
            let lastCompleted = null;
            let nextUpcoming = null;
            for (const leg of legs) {
                if (leg.end.getTime() < now) {
                    lastCompleted = leg;
                } else if (!nextUpcoming && leg.start.getTime() > now) {
                    nextUpcoming = leg;
                }
            }

            if (lastCompleted && nextUpcoming) {
                const sinceLandedMs = now - lastCompleted.end.getTime();
                const untilNextMs = nextUpcoming.start.getTime() - now;
                if (sinceLandedMs <= 36 * 3600000 && untilNextMs <= 48 * 3600000) {
                    const airport = lastCompleted.destination || 'LAYOVER';
                    const nextFlt = toFlightAwareIdent(nextUpcoming.flightNumber);
                    return {
                        state: 'layover',
                        badgeText: `On Layover in ${airport}`,
                        airport,
                        nextFlightNumber: nextFlt,
                        countdownText: `Next flight (${nextFlt} to ${nextUpcoming.destination}) in ${formatDurationHuman(untilNextMs)}`
                    };
                }
            }

            return { state: 'off-duty', badgeText: 'Off Duty' };
        }

        function renderAvatarHtml(profile, sizeClasses = 'w-20 h-20 text-3xl') {
            const initial = escapeHtml((profile.name || 'P').trim().charAt(0).toUpperCase() || 'P');
            const bgGradient = profile.id === 1
                ? 'from-blue-600 to-indigo-700'
                : 'from-purple-600 to-pink-600';

            if (profile.avatarDataUrl) {
                return `
                    <div class="${sizeClasses} rounded-full overflow-hidden border-4 border-white shadow-lg bg-gradient-to-br ${bgGradient} flex items-center justify-center shrink-0">
                        <img
                            src="${escapeHtml(profile.avatarDataUrl)}"
                            alt="${escapeHtml(profile.name)}"
                            class="w-full h-full object-cover"
                            onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';"
                        />
                        <span style="display:none" class="w-full h-full items-center justify-center font-black text-white">${initial}</span>
                    </div>
                `;
            }

            return `
                <div class="${sizeClasses} rounded-full border-4 border-white shadow-lg bg-gradient-to-br ${bgGradient} text-white font-black flex items-center justify-center shrink-0">
                    ${initial}
                </div>
            `;
        }

        function renderDashboard() {
            const grid = document.getElementById('dashboard-grid');
            if (!grid) return;

            const activeProfiles = profiles.filter((p, idx) => idx === 0 || p.enabled);
            if (activeProfiles.length >= 2) {
                grid.className = 'w-full max-w-6xl mx-auto flex-1 grid grid-cols-1 md:grid-cols-2 gap-6 items-stretch';
            } else {
                grid.className = 'w-full max-w-3xl mx-auto flex-1 grid grid-cols-1 gap-6 items-stretch';
            }

            grid.innerHTML = activeProfiles.map((profile) => {
                const status = evaluateProfileStatus(profile);

                let badgeStyle = 'bg-emerald-100 text-emerald-900 border-emerald-300';
                let dotColor = 'bg-emerald-500';
                if (status.state === 'in-flight') {
                    badgeStyle = 'bg-sky-100 text-sky-900 border-sky-300';
                    dotColor = 'bg-sky-500 animate-ping';
                } else if (status.state === 'pre-flight') {
                    badgeStyle = 'bg-amber-100 text-amber-950 border-amber-300';
                    dotColor = 'bg-amber-500 animate-pulse';
                } else if (status.state === 'layover') {
                    badgeStyle = 'bg-indigo-100 text-indigo-950 border-indigo-300';
                    dotColor = 'bg-indigo-500';
                }

                const noteBannerHtml = profile.pilotNote ? `
                    <div class="bg-amber-50 border-2 border-amber-300 rounded-2xl px-4 py-3 flex items-center gap-3">
                        <span class="text-xl shrink-0">💌</span>
                        <p class="font-extrabold text-amber-950 text-sm sm:text-base leading-snug">${escapeHtml(profile.pilotNote)}</p>
                    </div>
                ` : '';

                let middleContentHtml = '';
                if (status.state === 'in-flight' || status.state === 'pre-flight') {
                    middleContentHtml = `
                        <div class="bg-slate-50 border-2 border-slate-200/80 rounded-3xl p-5 sm:p-6 flex flex-col gap-5">
                            <div class="flex items-center justify-between gap-2">
                                <span class="px-3.5 py-1.5 rounded-xl bg-slate-900 text-white font-mono font-black text-base sm:text-lg tracking-wider">
                                    ${escapeHtml(status.flightNumber)}
                                </span>
                                <span class="text-sm sm:text-base font-extrabold text-sky-700">
                                    ${escapeHtml(status.countdownText)}
                                </span>
                            </div>

                            <!-- Origin -> Animated Plane Progress -> Destination -->
                            <div class="flex items-center gap-4">
                                <div class="text-center shrink-0">
                                    <div class="text-2xl sm:text-3xl font-black text-slate-900">${escapeHtml(status.origin)}</div>
                                    <div class="text-[11px] font-bold uppercase tracking-wider text-slate-400">From</div>
                                </div>

                                <div class="relative flex-1 h-4 bg-slate-200 rounded-full overflow-visible">
                                    <div
                                        class="h-full bg-gradient-to-r from-sky-400 to-blue-600 rounded-full transition-all duration-1000"
                                        style="width: ${status.progressPct}%"
                                    ></div>
                                    <div
                                        class="plane-marker absolute top-1/2 w-11 h-11 rounded-full bg-blue-600 text-white shadow-lg border-2 border-white flex items-center justify-center"
                                        style="left: ${status.progressPct}%"
                                    >
                                        <svg class="w-6 h-6 rotate-90" fill="currentColor" viewBox="0 0 24 24">
                                            <path d="M21 16v-2l-8-5V3.5c0-.83-.67-1.5-1.5-1.5S10 2.67 10 3.5V9l-8 5v2l8-2.5V19l-2 1.5V22l3.5-1 3.5 1v-1.5L13 19v-5.5l8 2.5z"/>
                                        </svg>
                                    </div>
                                </div>

                                <div class="text-center shrink-0">
                                    <div class="text-2xl sm:text-3xl font-black text-slate-900">${escapeHtml(status.destination)}</div>
                                    <div class="text-[11px] font-bold uppercase tracking-wider text-slate-400">To</div>
                                </div>
                            </div>
                        </div>
                    `;
                } else if (status.state === 'layover') {
                    middleContentHtml = `
                        <div class="bg-indigo-50/70 border-2 border-indigo-200/80 rounded-3xl p-5 sm:p-6 flex flex-col gap-2 text-center">
                            <div class="text-xs font-extrabold uppercase tracking-wider text-indigo-600">Current Layover Stop</div>
                            <div class="text-3xl sm:text-4xl font-black text-indigo-950">${escapeHtml(status.airport)}</div>
                            <div class="text-sm sm:text-base font-bold text-indigo-800 mt-1">${escapeHtml(status.countdownText)}</div>
                        </div>
                    `;
                } else {
                    middleContentHtml = `
                        <div class="bg-emerald-50/60 border-2 border-emerald-200/80 rounded-3xl p-5 sm:p-6 text-center flex flex-col items-center justify-center gap-1.5">
                            <div class="text-3xl">🏠</div>
                            <div class="text-lg sm:text-xl font-black text-emerald-950">${escapeHtml(profile.name)} is Off Duty</div>
                            <div class="text-sm font-semibold text-emerald-800">Ready for a video call anytime!</div>
                        </div>
                    `;
                }

                let actionButtonsHtml = '';
                if (status.state === 'in-flight') {
                    actionButtonsHtml = `
                        <div class="flex flex-col gap-3 mt-auto pt-2">
                            <button
                                type="button"
                                onclick="openBuiltInFlightMap(${profile.id}, '${escapeHtml(status.flightNumber)}', '${escapeHtml(status.origin)}', '${escapeHtml(status.destination)}', ${status.progressPct})"
                                class="w-full bg-blue-600 hover:bg-blue-700 active:scale-[0.99] text-white font-black text-xl sm:text-2xl py-5 px-6 rounded-3xl shadow-xl shadow-blue-600/25 flex items-center justify-center gap-3 transition"
                            >
                                <svg class="w-7 h-7 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7"/>
                                </svg>
                                <span>Track Plane on Map</span>
                            </button>

                            <button
                                type="button"
                                onclick="initiateCall(${profile.id})"
                                class="w-full bg-slate-100 hover:bg-slate-200 active:scale-[0.99] text-slate-700 font-extrabold text-base py-3.5 px-5 rounded-2xl border border-slate-300 flex items-center justify-center gap-2 transition"
                            >
                                <svg class="w-5 h-5 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
                                </svg>
                                <span>Try Calling Anyway</span>
                            </button>
                        </div>
                    `;
                } else {
                    const trackMiniBtn = status.state === 'pre-flight' ? `
                        <button
                            type="button"
                            onclick="openBuiltInFlightMap(${profile.id}, '${escapeHtml(status.flightNumber)}', '${escapeHtml(status.origin)}', '${escapeHtml(status.destination)}', ${status.progressPct})"
                            class="w-full bg-sky-100 hover:bg-sky-200 text-sky-900 font-extrabold text-base py-3.5 px-5 rounded-2xl border border-sky-300 flex items-center justify-center gap-2 transition"
                        >
                            <span>View Flight Route Map</span>
                        </button>
                    ` : '';

                    actionButtonsHtml = `
                        <div class="flex flex-col gap-3 mt-auto pt-2">
                            <button
                                type="button"
                                onclick="initiateCall(${profile.id})"
                                class="w-full bg-emerald-500 hover:bg-emerald-600 active:scale-[0.99] text-white font-black text-2xl sm:text-3xl py-6 px-6 rounded-3xl shadow-xl shadow-emerald-600/30 flex items-center justify-center gap-3.5 transition"
                            >
                                <svg class="w-8 h-8 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
                                </svg>
                                <span>${escapeHtml(profile.callLabel || `Call ${profile.name}`)}</span>
                            </button>
                            ${trackMiniBtn}
                        </div>
                    `;
                }

                return `
                    <article class="bg-white border-2 border-slate-200/90 rounded-[2.25rem] shadow-xl p-6 sm:p-8 flex flex-col justify-between gap-6">
                        <!-- Profile Header -->
                        <div class="flex items-center gap-4 sm:gap-5">
                            ${renderAvatarHtml(profile, 'w-20 h-20 sm:w-24 sm:h-24 text-3xl sm:text-4xl')}
                            <div class="min-w-0 flex-1">
                                <h2 class="text-3xl sm:text-4xl font-black text-slate-900 truncate">${escapeHtml(profile.name)}</h2>
                                <div class="mt-2 inline-flex items-center gap-2 px-4 py-1.5 rounded-full border-2 font-extrabold text-sm sm:text-base ${badgeStyle}">
                                    <span class="w-2.5 h-2.5 rounded-full ${dotColor}"></span>
                                    <span>${escapeHtml(status.badgeText)}</span>
                                </div>
                            </div>
                        </div>

                        ${noteBannerHtml}
                        ${middleContentHtml}
                        ${actionButtonsHtml}
                    </article>
                `;
            }).join('');
        }

        // ============================================================================
        // BUILT-IN KEYLESS AVIATION VECTOR FLIGHT MAP (D3 + REAL US/WORLD ATLAS)
        // ============================================================================
        function getAviationProjection() {
            if (window.d3 && typeof window.d3.geoMercator === 'function') {
                return window.d3.geoMercator()
                    .scale(155)
                    .center([-35, 38])
                    .translate([500, 290]);
            }
            return null;
        }

        function projectLonLat(lon, lat) {
            const proj = getAviationProjection();
            if (proj) {
                const pt = proj([lon, lat]);
                if (pt && Number.isFinite(pt[0]) && Number.isFinite(pt[1])) {
                    return pt;
                }
            }
            const x = ((lon + 170) / 215) * 1000;
            const y = ((68 - lat) / 56) * 560;
            return [x, y];
        }

        function interpolateGreatCircle(lat1, lon1, lat2, lon2, steps = 72) {
            const toRad = d => (d * Math.PI) / 180;
            const toDeg = r => (r * 180) / Math.PI;
            const phi1 = toRad(lat1), lam1 = toRad(lon1);
            const phi2 = toRad(lat2), lam2 = toRad(lon2);

            const d = 2 * Math.asin(Math.sqrt(
                Math.pow(Math.sin((phi2 - phi1) / 2), 2) +
                Math.cos(phi1) * Math.cos(phi2) * Math.pow(Math.sin((lam2 - lam1) / 2), 2)
            ));
            if (d < 1e-6) return [[lat1, lon1], [lat2, lon2]];

            const pts = [];
            for (let i = 0; i <= steps; i++) {
                const f = i / steps;
                const A = Math.sin((1 - f) * d) / Math.sin(d);
                const B = Math.sin(f * d) / Math.sin(d);
                const x = A * Math.cos(phi1) * Math.cos(lam1) + B * Math.cos(phi2) * Math.cos(lam2);
                const y = A * Math.cos(phi1) * Math.sin(lam1) + B * Math.cos(phi2) * Math.sin(lam2);
                const z = A * Math.sin(phi1) + B * Math.sin(phi2);
                const lat = toDeg(Math.atan2(z, Math.sqrt(x * x + y * y)));
                const lon = toDeg(Math.atan2(y, x));
                pts.push([lat, lon]);
            }
            return pts;
        }

        function ensureGeoAtlasLoaded() {
            if (cachedWorldFeatures && cachedUsStateFeatures) {
                return Promise.resolve();
            }
            if (geoAtlasLoadPromise) {
                return geoAtlasLoadPromise;
            }

            geoAtlasLoadPromise = Promise.all([
                fetch('https://cdn.jsdelivr.net/npm/world-atlas@2/countries-110m.json')
                    .then(r => (r.ok ? r.json() : null))
                    .catch(() => null),
                fetch('https://cdn.jsdelivr.net/npm/us-atlas@3/states-10m.json')
                    .then(r => (r.ok ? r.json() : null))
                    .catch(() => null)
            ]).then(([worldTopo, usTopo]) => {
                if (window.topojson) {
                    if (worldTopo && worldTopo.objects && worldTopo.objects.countries) {
                        cachedWorldFeatures = window.topojson.feature(worldTopo, worldTopo.objects.countries).features;
                    }
                    if (usTopo && usTopo.objects && usTopo.objects.states) {
                        cachedUsStateFeatures = window.topojson.feature(usTopo, usTopo.objects.states).features;
                    }
                }
            });

            return geoAtlasLoadPromise;
        }

        function detectStateOverflight(lon, lat) {
            if (!window.d3 || !cachedUsStateFeatures) return '';
            for (const feat of cachedUsStateFeatures) {
                try {
                    if (window.d3.geoContains(feat, [lon, lat])) {
                        return (feat.properties && feat.properties.name) ? feat.properties.name : '';
                    }
                } catch (e) { /* skip malformed geometry */ }
            }
            return '';
        }

        function renderDetailedVectorBasemap(origCode, destCode) {
            const gratLayer = document.getElementById('map-graticule-layer');
            const worldLayer = document.getElementById('map-world-layer');
            const statesLayer = document.getElementById('map-states-layer');
            const hubsLayer = document.getElementById('map-hubs-layer');
            if (!gratLayer || !worldLayer || !statesLayer || !hubsLayer) return;

            const proj = getAviationProjection();
            const pathGen = (window.d3 && proj) ? window.d3.geoPath().projection(proj) : null;

            // Graticule (lat/lon aviation grid)
            if (window.d3 && pathGen) {
                const graticule = window.d3.geoGraticule().step([15, 10])();
                gratLayer.innerHTML = `<path d="${pathGen(graticule) || ''}" fill="none" stroke="#1e293b" stroke-width="0.7" stroke-opacity="0.75" />`;
            }

            // World Countries Layer
            if (pathGen && Array.isArray(cachedWorldFeatures)) {
                worldLayer.innerHTML = cachedWorldFeatures.map(feat => {
                    const d = pathGen(feat);
                    if (!d) return '';
                    return `<path d="${d}" fill="#0d2238" stroke="#38bdf8" stroke-opacity="0.28" stroke-width="0.8" />`;
                }).join('');
            }

            // Crisp US States & Great Lakes Layer (1:10m resolution)
            if (pathGen && Array.isArray(cachedUsStateFeatures)) {
                statesLayer.innerHTML = cachedUsStateFeatures.map(feat => {
                    const d = pathGen(feat);
                    if (!d) return '';
                    return `<path d="${d}" fill="#112d4a" stroke="#38bdf8" stroke-opacity="0.48" stroke-width="0.65" stroke-linejoin="round" />`;
                }).join('');
            }

            // Subtle Major Airport Context Dots across the map
            const majorHubs = ['ATL', 'DFW', 'DEN', 'ORD', 'LAX', 'JFK', 'SEA', 'MIA', 'PHX', 'SFO', 'BOS', 'MSP', 'SLC', 'IAH', 'CLT', 'LAS', 'MCO', 'ANC', 'HNL', 'LHR', 'CDG', 'FRA', 'NRT'];
            hubsLayer.innerHTML = majorHubs
                .filter(code => code !== origCode && code !== destCode && AIRPORT_COORDS[code])
                .map(code => {
                    const [lat, lon] = AIRPORT_COORDS[code];
                    const [x, y] = projectLonLat(lon, lat);
                    return `
                        <circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="2.2" fill="#64748b" fill-opacity="0.7" />
                        <text x="${(x + 4).toFixed(1)}" y="${(y + 2.5).toFixed(1)}" fill="#64748b" font-size="7.5" font-weight="700">${code}</text>
                    `;
                }).join('');
        }

        function initMapZoomAndPan() {
            if (!window.d3) return;
            const svgEl = document.getElementById('flight-map-svg');
            const groupEl = document.getElementById('map-pan-zoom-group');
            if (!svgEl || !groupEl || mapZoomBehavior) return;

            const svgSel = window.d3.select(svgEl);
            const groupSel = window.d3.select(groupEl);

            mapZoomBehavior = window.d3.zoom()
                .scaleExtent([0.65, 10])
                .on('zoom', (event) => {
                    groupSel.attr('transform', event.transform.toString());
                });

            svgSel.call(mapZoomBehavior);
        }

        function fitMapToRouteBounds(xyPts) {
            if (!window.d3 || !mapZoomBehavior || !xyPts.length) return;
            const svgEl = document.getElementById('flight-map-svg');
            if (!svgEl) return;

            let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
            for (const [x, y] of xyPts) {
                if (x < minX) minX = x;
                if (x > maxX) maxX = x;
                if (y < minY) minY = y;
                if (y > maxY) maxY = y;
            }

            const spanX = Math.max(maxX - minX, 75);
            const spanY = Math.max(maxY - minY, 55);
            const scale = Math.min(Math.max(Math.min(680 / spanX, 360 / spanY), 0.9), 4.5);
            const midX = (minX + maxX) / 2;
            const midY = (minY + maxY) / 2;
            const tx = 500 - midX * scale;
            const ty = 280 - midY * scale;

            mapDefaultTransform = window.d3.zoomIdentity.translate(tx, ty).scale(scale);
            window.d3.select(svgEl).call(mapZoomBehavior.transform, mapDefaultTransform);
        }

        function zoomFlightMap(factor) {
            if (!window.d3 || !mapZoomBehavior) return;
            const svgEl = document.getElementById('flight-map-svg');
            if (!svgEl) return;
            window.d3.select(svgEl).transition().duration(220).call(mapZoomBehavior.scaleBy, factor);
        }

        function resetFlightMapView() {
            if (!window.d3 || !mapZoomBehavior || !mapDefaultTransform) return;
            const svgEl = document.getElementById('flight-map-svg');
            if (!svgEl) return;
            window.d3.select(svgEl).transition().duration(260).call(mapZoomBehavior.transform, mapDefaultTransform);
        }

        function drawRouteAndPlaneOnMap(icaoIdent, origCode, destCode, progressPct, liveTelemetry = null, shouldFit = false) {
            const routeLayer = document.getElementById('map-route-layer');
            const planeLayer = document.getElementById('map-plane-layer');
            const subEl = document.getElementById('map-telemetry-sub');
            const badgeEl = document.getElementById('map-source-badge');
            if (!routeLayer || !planeLayer) return;

            const origCoords = AIRPORT_COORDS[origCode] || [32.8998, -97.0403];
            const destCoords = AIRPORT_COORDS[destCode] || [33.9416, -118.4085];

            const arcPts = interpolateGreatCircle(origCoords[0], origCoords[1], destCoords[0], destCoords[1], 72);
            const xyPts = arcPts.map(([lat, lon]) => projectLonLat(lon, lat));

            const fullPathD = xyPts.map((pt, i) => `${i === 0 ? 'M' : 'L'} ${pt[0].toFixed(1)} ${pt[1].toFixed(1)}`).join(' ');
            const splitIdx = Math.min(Math.max(Math.round((progressPct / 100) * (xyPts.length - 1)), 1), xyPts.length - 1);
            const flownPts = xyPts.slice(0, splitIdx + 1);
            const flownPathD = flownPts.map((pt, i) => `${i === 0 ? 'M' : 'L'} ${pt[0].toFixed(1)} ${pt[1].toFixed(1)}`).join(' ');

            let currentLatLon = arcPts[splitIdx];
            let planeXY = xyPts[splitIdx];
            let nextXY = xyPts[Math.min(splitIdx + 1, xyPts.length - 1)];
            let headingDeg = (Math.atan2(nextXY[1] - planeXY[1], nextXY[0] - planeXY[0]) * 180) / Math.PI + 90;

            if (liveTelemetry && typeof liveTelemetry.lat === 'number' && typeof liveTelemetry.lon === 'number') {
                currentLatLon = [liveTelemetry.lat, liveTelemetry.lon];
                planeXY = projectLonLat(liveTelemetry.lon, liveTelemetry.lat);
                if (typeof liveTelemetry.track === 'number') {
                    headingDeg = liveTelemetry.track;
                }
                const overState = detectStateOverflight(liveTelemetry.lon, liveTelemetry.lat);
                if (subEl) {
                    const stateTxt = overState ? `Over ${overState} • ` : '';
                    const altTxt = liveTelemetry.alt ? `${Math.round(liveTelemetry.alt).toLocaleString()} ft` : 'Cruising';
                    const spdTxt = liveTelemetry.gs ? ` • ${Math.round(liveTelemetry.gs)} kts` : '';
                    subEl.textContent = `${stateTxt}${altTxt}${spdTxt}`;
                }
                if (badgeEl) {
                    badgeEl.innerHTML = `<span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span><span>Live ADS-B Radar (${icaoIdent})</span>`;
                }
            } else {
                const overState = detectStateOverflight(currentLatLon[1], currentLatLon[0]);
                if (subEl) {
                    const stateTxt = overState ? `Flying over ${overState} • ` : '';
                    subEl.textContent = `${stateTxt}${progressPct}% Complete`;
                }
                if (badgeEl) {
                    badgeEl.innerHTML = `<span class="w-2 h-2 rounded-full bg-sky-400 animate-pulse"></span><span>Flight Path Tracker (${origCode} → ${destCode})</span>`;
                }
            }

            const [ox, oy] = xyPts[0];
            const [dx, dy] = xyPts[xyPts.length - 1];

            routeLayer.innerHTML = `
                <path d="${fullPathD}" fill="none" stroke="#38bdf8" stroke-opacity="0.35" stroke-width="2.2" stroke-dasharray="6 6" stroke-linecap="round" />
                <path d="${flownPathD}" fill="none" stroke="#38bdf8" stroke-width="3.5" stroke-linecap="round" />

                <!-- Origin Airport Pin -->
                <circle cx="${ox.toFixed(1)}" cy="${oy.toFixed(1)}" r="5.5" fill="#0f172a" stroke="#38bdf8" stroke-width="2.8" />
                <rect x="${(ox - 20).toFixed(1)}" y="${(oy + 9).toFixed(1)}" width="40" height="17" rx="5" fill="#0f172a" stroke="#38bdf8" stroke-opacity="0.6" />
                <text x="${ox.toFixed(1)}" y="${(oy + 20.5).toFixed(1)}" fill="#f8fafc" font-size="10" font-weight="900" text-anchor="middle">${escapeHtml(origCode)}</text>

                <!-- Destination Airport Pin -->
                <circle cx="${dx.toFixed(1)}" cy="${dy.toFixed(1)}" r="5.5" fill="#10b981" stroke="#ffffff" stroke-width="2.5" />
                <rect x="${(dx - 20).toFixed(1)}" y="${(dy + 9).toFixed(1)}" width="40" height="17" rx="5" fill="#0f172a" stroke="#10b981" stroke-opacity="0.75" />
                <text x="${dx.toFixed(1)}" y="${(dy + 20.5).toFixed(1)}" fill="#6ee7b7" font-size="10" font-weight="900" text-anchor="middle">${escapeHtml(destCode)}</text>
            `;

            planeLayer.innerHTML = `
                <g transform="translate(${planeXY[0].toFixed(1)}, ${planeXY[1].toFixed(1)})" filter="url(#planeShadow)">
                    <circle r="18" fill="#0ea5e9" fill-opacity="0.24" />
                    <circle r="12" fill="#0284c7" stroke="#ffffff" stroke-width="2.2" />
                    <g transform="rotate(${headingDeg.toFixed(1)}) scale(0.62) translate(-12, -12)">
                        <path fill="#ffffff" d="M21 16v-2l-8-5V3.5c0-.83-.67-1.5-1.5-1.5S10 2.67 10 3.5V9l-8 5v2l8-2.5V19l-2 1.5V22l3.5-1 3.5 1v-1.5L13 19v-5.5l8 2.5z"/>
                    </g>
                </g>
            `;

            if (shouldFit) {
                fitMapToRouteBounds(xyPts);
            }
        }

        async function fetchKeylessLiveAdsb(icaoIdent) {
            try {
                const res = await fetch(`https://api.adsb.lol/v2/callsign/${encodeURIComponent(icaoIdent)}`, {
                    cache: 'no-store'
                });
                if (!res.ok) return null;
                const data = await res.json();
                const ac = data && Array.isArray(data.ac) && data.ac[0];
                if (ac && typeof ac.lat === 'number' && typeof ac.lon === 'number') {
                    return {
                        lat: ac.lat,
                        lon: ac.lon,
                        alt: ac.alt_baro || ac.alt_geom || null,
                        gs: ac.gs || null,
                        track: ac.track || null
                    };
                }
            } catch (e) { /* fallback to scheduled arc */ }
            return null;
        }

        async function openBuiltInFlightMap(profileId, flightIdent, origin, destination, progressPct = 50) {
            const icaoIdent = toFlightAwareIdent(flightIdent);
            const origCode = (origin || 'DFW').toUpperCase();
            const destCode = (destination || 'LAX').toUpperCase();

            const identEl = document.getElementById('map-flight-ident');
            const routeEl = document.getElementById('map-route-label');
            const trackerScreen = document.getElementById('tracker-screen');

            if (identEl) identEl.textContent = icaoIdent;
            if (routeEl) routeEl.textContent = `${origCode} → ${destCode}`;
            if (trackerScreen) trackerScreen.classList.remove('hidden');

            initMapZoomAndPan();
            renderDetailedVectorBasemap(origCode, destCode);
            drawRouteAndPlaneOnMap(icaoIdent, origCode, destCode, progressPct, null, true);

            // Load high-resolution US state borders & world countries asynchronously
            ensureGeoAtlasLoaded().then(() => {
                renderDetailedVectorBasemap(origCode, destCode);
                drawRouteAndPlaneOnMap(icaoIdent, origCode, destCode, progressPct, null, false);
            });

            const refreshRadar = async () => {
                const live = await fetchKeylessLiveAdsb(icaoIdent);
                if (live) {
                    drawRouteAndPlaneOnMap(icaoIdent, origCode, destCode, progressPct, live, false);
                }
            };
            refreshRadar();

            if (mapLivePollInterval) clearInterval(mapLivePollInterval);
            mapLivePollInterval = setInterval(refreshRadar, 15000);
        }

        function openFlightAwareTracker(profileId, flightIdent, origin, destination) {
            openBuiltInFlightMap(profileId, flightIdent, origin, destination, 55);
        }

        function closeFlightAwareTracker() {
            if (mapLivePollInterval) {
                clearInterval(mapLivePollInterval);
                mapLivePollInterval = null;
            }
            const trackerScreen = document.getElementById('tracker-screen');
            if (trackerScreen) trackerScreen.classList.add('hidden');
        }

        // ============================================================================
        // VIDEO CALLING FLOW (NTFY.SH + AUTO-HANGUP + JITSI)
        // ============================================================================
        function buildJitsiDirectUrl(profile) {
            const domain = sanitizeDomain(profile.jitsiDomain);
            const roomName = sanitizeRoomName(profile.jitsiRoom);
            const hashParams = [
                'config.prejoinPageEnabled=false',
                'config.prejoinConfig.enabled=false',
                'config.disableDeepLinking=true',
                'config.startWithAudioMuted=false',
                'config.startWithVideoMuted=false',
                'interfaceConfig.MOBILE_APP_PROMO=false',
                'userInfo.displayName=%22Family%20Home%22'
            ].join('&');
            return `https://${domain}/${roomName}#${hashParams}`;
        }

        function resolveCallLaunchMode(profile) {
            return profile.callLaunchMode === 'top-level' ? 'top-level' : 'embedded';
        }

        async function warmUpMediaForIframe() {
            if (!window.isSecureContext || !navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
                return;
            }
            try {
                const stream = await navigator.mediaDevices.getUserMedia({ audio: true, video: true });
                stream.getTracks().forEach(track => track.stop());
                micPermissionState = 'granted';
                camPermissionState = 'granted';
                await new Promise(resolve => setTimeout(resolve, 250));
            } catch (err) {
                try {
                    const audioOnly = await navigator.mediaDevices.getUserMedia({ audio: true });
                    audioOnly.getTracks().forEach(track => track.stop());
                    micPermissionState = 'granted';
                    await new Promise(resolve => setTimeout(resolve, 250));
                } catch (audioErr) {
                    // Proceed anyway so Jitsi can still connect
                }
            }
        }

        async function testMicrophoneAndCameraAccess() {
            if (!window.isSecureContext || !navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
                micPermissionState = 'error';
                camPermissionState = 'error';
                mediaPermissionDetail = 'Open this link directly in Safari over HTTPS to enable Microphone & Camera.';
                showTopBanner(mediaPermissionDetail, 12000);
                renderSettings();
                return;
            }

            try {
                const stream = await navigator.mediaDevices.getUserMedia({ audio: true, video: true });
                stream.getTracks().forEach(track => track.stop());
                micPermissionState = 'granted';
                camPermissionState = 'granted';
                mediaPermissionDetail = '';
                showTopBanner('Microphone and Camera are both working and allowed!', 6000, 'blue');
            } catch (err) {
                try {
                    const audioOnly = await navigator.mediaDevices.getUserMedia({ audio: true });
                    audioOnly.getTracks().forEach(track => track.stop());
                    micPermissionState = 'granted';
                    camPermissionState = 'denied';
                    mediaPermissionDetail = 'Microphone is Allowed, but Camera was blocked or busy.';
                } catch (audioErr) {
                    const errName = (audioErr && audioErr.name) || (err && err.name) || 'Blocked';
                    micPermissionState = 'denied';
                    camPermissionState = 'denied';
                    mediaPermissionDetail = `Browser blocked Mic/Cam (${errName}). In Safari, tap "aA" in address bar → Website Settings → Microphone & Camera → Allow.`;
                }
                showTopBanner(mediaPermissionDetail, 12000);
            }
            renderSettings();
        }

        function loadJitsiScript(domain) {
            return new Promise((resolve, reject) => {
                if (window.JitsiMeetExternalAPI && loadedJitsiDomain === domain) {
                    resolve();
                    return;
                }

                const existing = document.getElementById('jitsi-external-api-script');
                if (existing) existing.remove();
                window.JitsiMeetExternalAPI = undefined;

                const script = document.createElement('script');
                script.id = 'jitsi-external-api-script';
                script.src = `https://${domain}/external_api.js`;
                script.async = true;
                script.onload = () => {
                    loadedJitsiDomain = domain;
                    resolve();
                };
                script.onerror = () => reject(new Error(`Unable to load Jitsi API from ${domain}`));
                document.head.appendChild(script);
            });
        }

        async function sendNtfyNotification(profile, isTest = false) {
            const topic = (profile.ntfyTopic || '').trim();
            if (!topic) {
                if (isTest) showTopBanner('Please enter an ntfy.sh topic name first!', 6000);
                return false;
            }

            const domain = sanitizeDomain(profile.jitsiDomain);
            const roomName = sanitizeRoomName(profile.jitsiRoom);
            const clickUrl = `https://${domain}/${roomName}`;
            const messageBody = isTest
                ? `Test alert from Family Flight Deck! Tapping opens ${clickUrl}`
                : `Your kids are calling ${profile.name}! Tap to join video chat.`;

            const headers = {
                'Title': isTest ? 'Test Flight Deck Alert' : 'Incoming Family Call',
                'Priority': 'urgent',
                'Tags': 'airplane,telephone_receiver',
                'Click': clickUrl
            };

            try {
                const res = await fetch(`https://ntfy.sh/${encodeURIComponent(topic)}`, {
                    method: 'POST',
                    headers,
                    body: messageBody
                });
                if (!res.ok) throw new Error(`HTTP ${res.status}`);
                if (isTest) {
                    showTopBanner(`Test push alert sent to ntfy.sh/${topic}!`, 8000, 'blue');
                }
                return true;
            } catch (err) {
                console.error('ntfy.sh POST failed:', err);
                if (isTest) {
                    showTopBanner(`Could not send alert to ntfy.sh/${topic}. Check your internet or ad-blocker.`, 9000);
                }
                return false;
            }
        }

        function hideRingingHud() {
            const hud = document.getElementById('ringing-hud');
            if (hud) hud.classList.add('hidden');
        }

        function onRemoteParticipantConnected() {
            if (isCallConnected) return;
            isCallConnected = true;
            if (ringCountdownInterval) {
                clearInterval(ringCountdownInterval);
                ringCountdownInterval = null;
            }
            if (participantPollInterval) {
                clearInterval(participantPollInterval);
                participantPollInterval = null;
            }
            hideRingingHud();
        }

        function startTopLevelSafariCall(profile) {
            const jitsiUrl = buildJitsiDirectUrl(profile);
            activeCallProfileName = profile.name || 'Parent';

            try {
                activeTopLevelCallWindow = window.open(jitsiUrl, 'FamilyFlightDeckCall');
            } catch (e) {
                activeTopLevelCallWindow = null;
            }

            sendNtfyNotification(profile, false);

            const screen = document.getElementById('toplevel-call-screen');
            const titleEl = document.getElementById('toplevel-call-title');
            const reopenLink = document.getElementById('toplevel-reopen-link');
            if (titleEl) titleEl.textContent = `Calling ${activeCallProfileName} in Safari...`;
            if (reopenLink) reopenLink.href = jitsiUrl;
            if (screen) screen.classList.remove('hidden');

            if (topLevelCallWatchInterval) clearInterval(topLevelCallWatchInterval);
            topLevelCallWatchInterval = setInterval(() => {
                if (activeTopLevelCallWindow && activeTopLevelCallWindow.closed) {
                    closeTopLevelCall('local');
                }
            }, 1000);
        }

        function closeTopLevelCall(reason = 'local') {
            if (topLevelCallWatchInterval) {
                clearInterval(topLevelCallWatchInterval);
                topLevelCallWatchInterval = null;
            }
            if (activeTopLevelCallWindow && !activeTopLevelCallWindow.closed) {
                try {
                    activeTopLevelCallWindow.close();
                } catch (e) { /* ignore */ }
            }
            activeTopLevelCallWindow = null;

            const screen = document.getElementById('toplevel-call-screen');
            if (screen) screen.classList.add('hidden');
            try {
                window.focus();
            } catch (e) { /* ignore */ }

            if (reason === 'remote') {
                showTopBanner(`${activeCallProfileName} ended the call — back to flight tracker!`, 10000, 'blue');
            }
        }

        function popOutCurrentCallToSafari() {
            const profile = profiles.find(p => p.id === currentEmbeddedProfileId) || profiles[0];
            hangUpCall('local');
            if (profile) {
                startTopLevelSafariCall(profile);
            }
        }

        // ============================================================================
        // TWO-WAY CALLING: PILOT CALLS KIDS' IPAD & INCOMING RINGING MODAL
        // ============================================================================
        async function callKidsFromPilot(profileId) {
            const profile = profiles.find(p => p.id === profileId);
            if (!profile) return;

            const callId = generateSlug('CALL');
            outgoingPilotCallProfileId = profile.id;
            outgoingPilotCallId = callId;

            profile.incomingCall = {
                active: true,
                callId,
                timestamp: Date.now(),
                callerName: profile.name || 'Pilot',
                roomName: sanitizeRoomName(profile.jitsiRoom),
                domain: sanitizeDomain(profile.jitsiDomain)
            };
            saveProfiles();
            pushSingleProfileState(profile.id, false);

            // Put the pilot directly into the Jitsi room waiting for the kids to tap Answer
            await initiateCall(profile.id, { skipNtfy: true, isPilotOutgoing: true });
        }

        function showIncomingCallModal(profileId, incomingCallObj) {
            const profile = profiles.find(p => p.id === profileId);
            if (!profile || !incomingCallObj) return;

            activeIncomingCall = {
                profileId,
                callId: incomingCallObj.callId,
                callerName: incomingCallObj.callerName || profile.name || 'Parent'
            };

            const modal = document.getElementById('incoming-call-modal');
            const avatarBox = document.getElementById('incoming-call-avatar');
            const titleEl = document.getElementById('incoming-call-title');

            if (avatarBox) {
                avatarBox.innerHTML = renderAvatarHtml(profile, 'w-28 h-28 sm:w-32 sm:h-32 text-4xl sm:text-5xl');
            }
            if (titleEl) {
                titleEl.textContent = `${activeIncomingCall.callerName} is Calling!`;
            }
            if (modal) {
                modal.classList.remove('hidden');
            }
        }

        function dismissIncomingCallModal(markHandled = true) {
            if (markHandled && activeIncomingCall && activeIncomingCall.callId) {
                handledIncomingCallIds.add(activeIncomingCall.callId);
            }
            activeIncomingCall = null;
            const modal = document.getElementById('incoming-call-modal');
            if (modal) modal.classList.add('hidden');
        }

        async function answerIncomingCall() {
            if (!activeIncomingCall) return;
            const targetProfileId = activeIncomingCall.profileId;
            dismissIncomingCallModal(true);
            await initiateCall(targetProfileId, { skipNtfy: true });
        }

        async function initiateCall(profileId, callOptions = {}) {
            const profile = profiles.find(p => p.id === profileId);
            if (!profile) return;

            const domain = sanitizeDomain(profile.jitsiDomain);
            const roomName = sanitizeRoomName(profile.jitsiRoom);
            profile.jitsiDomain = domain;
            profile.jitsiRoom = roomName;
            saveProfiles();

            const effectiveMode = resolveCallLaunchMode(profile);
            if (effectiveMode === 'top-level' && !callOptions.isPilotOutgoing) {
                startTopLevelSafariCall(profile);
                return;
            }

            currentEmbeddedProfileId = profile.id;
            if (!callOptions.skipNtfy) {
                sendNtfyNotification(profile, false);
            }

            activeCallProfileName = callOptions.isPilotOutgoing ? "Kids' iPad" : (profile.name || 'Parent');
            isCallConnected = false;
            isHangingUp = false;

            const callScreen = document.getElementById('call-screen');
            const jitsiWrapper = document.getElementById('jitsi-wrapper');
            const hud = document.getElementById('ringing-hud');
            const hudTitle = document.getElementById('hud-calling-title');
            const hudCountdown = document.getElementById('hud-countdown');

            if (jitsiWrapper) jitsiWrapper.innerHTML = '';
            if (hudTitle) hudTitle.textContent = `Calling ${activeCallProfileName}...`;
            if (hudCountdown) hudCountdown.textContent = '45';
            if (hud) hud.classList.remove('hidden');
            if (callScreen) callScreen.classList.remove('hidden');

            let secondsLeft = 45;
            if (ringCountdownInterval) clearInterval(ringCountdownInterval);
            ringCountdownInterval = setInterval(() => {
                secondsLeft -= 1;
                if (hudCountdown) hudCountdown.textContent = String(Math.max(secondsLeft, 0));
                if (secondsLeft <= 0 && !isCallConnected) {
                    hangUpCall('timeout');
                }
            }, 1000);

            try {
                await warmUpMediaForIframe();
                await loadJitsiScript(domain);

                const options = {
                    roomName: roomName,
                    parentNode: jitsiWrapper,
                    width: '100%',
                    height: '100%',
                    userInfo: {
                        displayName: appMeta.deviceRole === 'pilot' ? (profile.name || 'Pilot') : 'Family Home'
                    },
                    configOverwrite: {
                        prejoinPageEnabled: false,
                        prejoinConfig: { enabled: false },
                        disableDeepLinking: true,
                        startWithAudioMuted: false,
                        startWithVideoMuted: false,
                        enableWelcomePage: false,
                        enableClosePage: false,
                        disableInviteFunctions: true,
                        lobby: {
                            autoKnock: true
                        }
                    },
                    interfaceConfigOverwrite: {
                        MOBILE_APP_PROMO: false,
                        SHOW_JITSI_WATERMARK: false,
                        SHOW_WATERMARK_FOR_GUESTS: false,
                        DISABLE_JOIN_LEAVE_NOTIFICATIONS: true,
                        TOOLBAR_BUTTONS: [
                            'microphone',
                            'camera',
                            'hangup',
                            'tileview'
                        ]
                    }
                };

                currentJitsiApi = new window.JitsiMeetExternalAPI(domain, options);

                try {
                    const iframeEl = currentJitsiApi.getIFrame ? currentJitsiApi.getIFrame() : jitsiWrapper.querySelector('iframe');
                    if (iframeEl) {
                        iframeEl.setAttribute('allow', 'camera *; microphone *; fullscreen *; display-capture *; autoplay *');
                    }
                } catch (e) { /* ignore */ }

                currentJitsiApi.addListener('participantJoined', () => {
                    onRemoteParticipantConnected();
                });

                currentJitsiApi.addListener('videoConferenceJoined', () => {
                    try {
                        if (currentJitsiApi && currentJitsiApi.getNumberOfParticipants() > 1) {
                            onRemoteParticipantConnected();
                        }
                    } catch (e) { /* ignore */ }
                });

                currentJitsiApi.addListener('participantLeft', () => {
                    if (isHangingUp) return;
                    const checkEmpty = () => {
                        if (isHangingUp || !currentJitsiApi) return;
                        try {
                            const count = currentJitsiApi.getNumberOfParticipants();
                            if (isCallConnected && count <= 1) {
                                hangUpCall('remote');
                            }
                        } catch (e) { /* ignore */ }
                    };
                    checkEmpty();
                    setTimeout(checkEmpty, 300);
                });

                currentJitsiApi.addListener('videoConferenceLeft', () => {
                    if (!isHangingUp) {
                        hangUpCall(isCallConnected ? 'remote' : 'local');
                    }
                });

                currentJitsiApi.addListener('readyToClose', () => {
                    if (!isHangingUp) {
                        hangUpCall(isCallConnected ? 'remote' : 'local');
                    }
                });

                if (participantPollInterval) clearInterval(participantPollInterval);
                participantPollInterval = setInterval(() => {
                    if (!currentJitsiApi || isHangingUp) return;
                    try {
                        const count = currentJitsiApi.getNumberOfParticipants();
                        if (!isCallConnected && count > 1) {
                            onRemoteParticipantConnected();
                        } else if (isCallConnected && count <= 1) {
                            hangUpCall('remote');
                        }
                    } catch (e) { /* ignore */ }
                }, 1500);

            } catch (err) {
                console.error('Jitsi initialization error:', err);
                hangUpCall('local');
                showTopBanner(`Could not connect to ${domain}. Please check Wi-Fi and try again.`, 10000);
            }
        }

        function hangUpCall(reason = 'local') {
            if (isHangingUp) return;
            isHangingUp = true;

            if (ringCountdownInterval) {
                clearInterval(ringCountdownInterval);
                ringCountdownInterval = null;
            }
            if (participantPollInterval) {
                clearInterval(participantPollInterval);
                participantPollInterval = null;
            }

            if (currentJitsiApi) {
                try {
                    currentJitsiApi.dispose();
                } catch (err) {
                    console.warn('Error disposing Jitsi API:', err);
                }
                currentJitsiApi = null;
            }

            const jitsiWrapper = document.getElementById('jitsi-wrapper');
            if (jitsiWrapper) jitsiWrapper.innerHTML = '';

            const callScreen = document.getElementById('call-screen');
            if (callScreen) callScreen.classList.add('hidden');

            isCallConnected = false;

            // If this was an outgoing call from Pilot Phone, clear the incomingCall beacon on the iPad
            if (outgoingPilotCallProfileId) {
                const pilotProf = profiles.find(p => p.id === outgoingPilotCallProfileId);
                if (pilotProf) {
                    pilotProf.incomingCall = {
                        active: false,
                        callId: outgoingPilotCallId,
                        timestamp: Date.now()
                    };
                    saveProfiles();
                    pushSingleProfileState(pilotProf.id, false);
                }
                outgoingPilotCallProfileId = null;
                outgoingPilotCallId = null;
            }

            if (reason === 'timeout') {
                showTopBanner(`No answer right now — check ${activeCallProfileName}'s flight status below!`, 15000, 'amber');
            } else if (reason === 'remote') {
                showTopBanner(`${activeCallProfileName} ended the call — back to flight tracker!`, 10000, 'blue');
            }
        }

        // ============================================================================
        // PARENT SETTINGS UI & PHOTO COMPRESSION
        // ============================================================================
        function openSettings() {
            renderSettings();
            const modal = document.getElementById('settings-modal');
            if (modal) modal.classList.remove('hidden');
        }

        function saveAndCloseSettings() {
            saveProfiles();
            saveAppMeta();
            const modal = document.getElementById('settings-modal');
            if (modal) modal.classList.add('hidden');
            applyActiveDeviceRoleView();
            initCloudSync();
            refreshAllRemoteCalendars();
            pushSyncStateNow(false);
        }

        function updateProfileField(profileId, field, value) {
            const p = profiles.find(item => item.id === profileId);
            if (!p) return;

            if (field === 'jitsiRoom') {
                p.jitsiRoom = sanitizeRoomName(value);
            } else if (field === 'jitsiDomain') {
                p.jitsiDomain = sanitizeDomain(value);
            } else if (field === 'syncCode') {
                p.syncCode = sanitizePilotSyncCode(value);
            } else {
                p[field] = value;
            }
            saveProfiles();
        }

        function regenerateProfileSyncCode(profileId) {
            const p = profiles.find(item => item.id === profileId);
            if (!p) return;
            const prefix = (p.name || (profileId === 1 ? 'DAD' : 'MOM')).toUpperCase().replace(/[^A-Z]/g, '').slice(0, 4) || 'CREW';
            p.syncCode = generatePilotSyncCode(prefix);
            saveProfiles();
            initCloudSync();
            renderSettings();
            renderPilotMode();
        }

        function regenerateProfileRoom(profileId) {
            const p = profiles.find(item => item.id === profileId);
            if (!p) return;
            const cleanName = (p.name || 'Crew').replace(/[^a-zA-Z0-9]/g, '') || 'Crew';
            p.jitsiRoom = generateSlug(`FlightDeck${cleanName}`);
            saveProfiles();
            renderSettings();
        }

        function handleAvatarUpload(profileId, inputEl) {
            const file = inputEl.files && inputEl.files[0];
            if (!file) return;

            const reader = new FileReader();
            reader.onload = function (e) {
                const img = new Image();
                img.onload = function () {
                    const MAX_SIZE = 240;
                    let width = img.width;
                    let height = img.height;

                    if (width > height) {
                        if (width > MAX_SIZE) {
                            height = Math.round((height * MAX_SIZE) / width);
                            width = MAX_SIZE;
                        }
                    } else {
                        if (height > MAX_SIZE) {
                            width = Math.round((width * MAX_SIZE) / height);
                            height = MAX_SIZE;
                        }
                    }

                    const canvas = document.createElement('canvas');
                    canvas.width = width;
                    canvas.height = height;
                    const ctx = canvas.getContext('2d');
                    ctx.drawImage(img, 0, 0, width, height);

                    const compressedDataUrl = canvas.toDataURL('image/jpeg', 0.8);
                    const p = profiles.find(item => item.id === profileId);
                    if (p) {
                        p.avatarDataUrl = compressedDataUrl;
                        saveProfiles();
                        renderSettings();
                    }
                };
                img.src = e.target.result;
            };
            reader.readAsDataURL(file);
        }

        function removeAvatar(profileId) {
            const p = profiles.find(item => item.id === profileId);
            if (!p) return;
            p.avatarDataUrl = '';
            saveProfiles();
            renderSettings();
        }

        function handleIcsFileUpload(profileId, inputEl) {
            const file = inputEl.files && inputEl.files[0];
            if (!file) return;

            const reader = new FileReader();
            reader.onload = function (e) {
                const content = String(e.target.result || '');
                const p = profiles.find(item => item.id === profileId);
                if (p) {
                    p.icsText = content;
                    p.simulationMode = 'live';
                    saveProfiles();
                    renderSettings();
                    const count = parseICSEvents(content).length;
                    showTopBanner(`Loaded ${count} flight leg(s) from ${file.name}!`, 6000, 'blue');
                }
            };
            reader.readAsText(file);
        }

        function clearUploadedIcs(profileId) {
            const p = profiles.find(item => item.id === profileId);
            if (!p) return;
            p.icsText = '';
            saveProfiles();
            renderSettings();
        }

        function loadSampleIcsTrip(profileId) {
            const p = profiles.find(item => item.id === profileId);
            if (!p) return;

            const fmtUtc = (dateObj) => {
                const pad = (n) => String(n).padStart(2, '0');
                return `${dateObj.getUTCFullYear()}${pad(dateObj.getUTCMonth() + 1)}${pad(dateObj.getUTCDate())}T${pad(dateObj.getUTCHours())}${pad(dateObj.getUTCMinutes())}${pad(dateObj.getUTCSeconds())}Z`;
            };

            const now = Date.now();
            const leg1Start = new Date(now - 35 * 60000);
            const leg1End = new Date(now + 95 * 60000);
            const leg2Start = new Date(now + 15 * 3600000);
            const leg2End = new Date(now + 17.5 * 3600000);

            const sampleIcs = [
                'BEGIN:VCALENDAR',
                'VERSION:2.0',
                'PRODID:-//Family Flight Deck//Sample Pairing//EN',
                'BEGIN:VEVENT',
                `DTSTART:${fmtUtc(leg1Start)}`,
                `DTEND:${fmtUtc(leg1End)}`,
                'SUMMARY:AAL456 DFW-LAX',
                'LOCATION:DFW - LAX',
                'END:VEVENT',
                'BEGIN:VEVENT',
                `DTSTART:${fmtUtc(leg2Start)}`,
                `DTEND:${fmtUtc(leg2End)}`,
                'SUMMARY:AAL789 LAX-ORD',
                'LOCATION:LAX - ORD',
                'END:VEVENT',
                'END:VCALENDAR'
            ].join('\r\n');

            p.icsText = sampleIcs;
            p.simulationMode = 'live';
            saveProfiles();
            renderSettings();
            showTopBanner(`Loaded sample 2-leg trip (AAL456 DFW-LAX) for ${p.name}!`, 6000, 'blue');
        }

        function renderSettings() {
            const container = document.getElementById('settings-profiles-grid');
            const titleEl = document.getElementById('settings-modal-title');
            const subEl = document.getElementById('settings-modal-subtitle');
            if (!container) return;

            const isPilot = appMeta.deviceRole === 'pilot';
            if (titleEl) {
                titleEl.textContent = isPilot ? 'My Pilot Phone Settings' : "Kids' iPad Setup";
            }
            if (subEl) {
                subEl.textContent = isPilot
                    ? 'Configure your own pilot channel and pair it with your kids’ iPad.'
                    : 'Link Dad and/or Mom using their Pilot Sync Codes.';
            }

            const detectedIPad = isIPadOrIOS();
            const micBadge = micPermissionState === 'granted'
                ? '<span class="px-2.5 py-1 rounded-full bg-emerald-100 text-emerald-800 text-xs font-extrabold">Mic: Allowed ✓</span>'
                : micPermissionState === 'denied'
                    ? '<span class="px-2.5 py-1 rounded-full bg-red-100 text-red-800 text-xs font-extrabold">Mic: Blocked</span>'
                    : '<span class="px-2.5 py-1 rounded-full bg-slate-100 text-slate-700 text-xs font-extrabold">Mic: Untested</span>';

            const camBadge = camPermissionState === 'granted'
                ? '<span class="px-2.5 py-1 rounded-full bg-emerald-100 text-emerald-800 text-xs font-extrabold">Camera: Allowed ✓</span>'
                : camPermissionState === 'denied'
                    ? '<span class="px-2.5 py-1 rounded-full bg-amber-100 text-amber-900 text-xs font-extrabold">Camera: Blocked</span>'
                    : '<span class="px-2.5 py-1 rounded-full bg-slate-100 text-slate-700 text-xs font-extrabold">Camera: Untested</span>';

            const detailTipHtml = mediaPermissionDetail
                ? `<p class="text-xs font-bold text-red-700 mt-1.5">${escapeHtml(mediaPermissionDetail)}</p>`
                : '';

            const topDeviceHeaderHtml = `
                <div class="lg:col-span-2 bg-white border border-slate-200 rounded-3xl shadow-sm p-5 flex flex-col gap-4">
                    <div class="flex flex-wrap items-center justify-between gap-4 border-b border-slate-100 pb-4">
                        <div class="flex-1 min-w-[240px]">
                            <h2 class="text-lg font-black text-slate-900">Device Role</h2>
                            <p class="text-xs sm:text-sm text-slate-500 mt-0.5">
                                ${isPilot
                                    ? 'This device is in <strong>Pilot Phone Mode</strong> (controls your own flight status & calls the iPad).'
                                    : 'This device is in <strong>Kid iPad Mode</strong> (displays linked parents & locks settings behind a 2s hold).'}
                            </p>
                        </div>

                        <div class="inline-flex rounded-2xl bg-slate-100 p-1 border border-slate-200">
                            <button
                                type="button"
                                onclick="setDeviceRole('kid'); renderSettings();"
                                class="px-4 py-2 rounded-xl text-xs font-black transition ${!isPilot ? 'bg-blue-600 text-white shadow' : 'text-slate-600 hover:text-slate-900'}"
                            >
                                Kid iPad Mode
                            </button>
                            <button
                                type="button"
                                onclick="setDeviceRole('pilot'); renderSettings();"
                                class="px-4 py-2 rounded-xl text-xs font-black transition ${isPilot ? 'bg-slate-900 text-white shadow' : 'text-slate-600 hover:text-slate-900'}"
                            >
                                Pilot Phone Mode
                            </button>
                        </div>
                    </div>

                    <!-- Microphone & Camera Diagnostic Row -->
                    <div class="flex flex-wrap items-center justify-between gap-4">
                        <div class="flex-1 min-w-[260px]">
                            <div class="flex flex-wrap items-center gap-2">
                                <h2 class="text-base font-black text-slate-900">Microphone & Camera Status</h2>
                                ${micBadge}
                                ${camBadge}
                            </div>
                            <p class="text-xs sm:text-sm text-slate-500 mt-1">
                                ${detectedIPad
                                    ? 'iPad detected: Embedded mode automatically ends the call when the pilot hangs up or after 45s with no answer.'
                                    : 'Test your browser microphone & camera permissions before placing a call.'}
                            </p>
                            ${detailTipHtml}
                        </div>
                        <button
                            type="button"
                            onclick="testMicrophoneAndCameraAccess()"
                            class="bg-emerald-600 hover:bg-emerald-700 active:scale-95 text-white font-extrabold text-sm px-5 py-3 rounded-2xl shadow-sm transition shrink-0"
                        >
                            Test Mic & Camera Now
                        </button>
                    </div>
                </div>
            `;

            // KID IPAD MODE SETTINGS: Clean Linked-Parents setup (Sync Codes + Photos)
            if (!isPilot) {
                const kidCardsHtml = profiles.map((p, idx) => {
                    const isSecondary = idx === 1;
                    return `
                        <div class="bg-white border border-slate-200 rounded-3xl shadow-sm p-6 flex flex-col gap-5">
                            <div class="flex items-center justify-between gap-4 border-b border-slate-100 pb-4">
                                <div>
                                    <span class="text-xs font-extrabold uppercase tracking-wider text-blue-600">Parent ${idx + 1}</span>
                                    <h2 class="text-xl font-black text-slate-900">${escapeHtml(p.name || `Parent ${idx + 1}`)}</h2>
                                </div>

                                ${isSecondary ? `
                                    <label class="inline-flex items-center gap-2.5 cursor-pointer bg-slate-100 px-3.5 py-2 rounded-2xl">
                                        <input
                                            type="checkbox"
                                            ${p.enabled ? 'checked' : ''}
                                            onchange="updateProfileField(${p.id}, 'enabled', this.checked); renderSettings();"
                                            class="w-5 h-5 rounded text-blue-600 focus:ring-blue-500"
                                        />
                                        <span class="text-sm font-bold text-slate-700">Show on iPad</span>
                                    </label>
                                ` : `
                                    <span class="text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200 px-3 py-1.5 rounded-full">Active</span>
                                `}
                            </div>

                            <!-- Sync Code Input (Pairs with that parent's phone) -->
                            <div class="bg-blue-50/70 border border-blue-200 rounded-2xl p-4 flex flex-col gap-2">
                                <label class="block text-xs font-extrabold uppercase tracking-wider text-blue-800">
                                    ${escapeHtml(p.name || `Parent ${idx + 1}`)}'s Pilot Sync Code
                                </label>
                                <input
                                    type="text"
                                    value="${escapeHtml(p.syncCode)}"
                                    placeholder="e.g., ${idx === 0 ? 'DAD-4821' : 'MOM-9104'}"
                                    oninput="updateProfileField(${p.id}, 'syncCode', this.value)"
                                    class="w-full rounded-xl border border-blue-300 bg-white px-4 py-3 text-lg font-mono font-black text-slate-900 uppercase tracking-wider focus:outline-none focus:ring-2 focus:ring-blue-500"
                                />
                                <p class="text-xs text-blue-900/80">
                                    Copy this code from <strong>${escapeHtml(p.name || `Parent ${idx + 1}`)}'s Pixel</strong>. Status, flights, notes, and video room settings sync automatically.
                                </p>
                            </div>

                            <!-- Local Display Photo & Label -->
                            <div class="flex items-center gap-4">
                                ${renderAvatarHtml(p, 'w-16 h-16 text-2xl')}
                                <div class="flex flex-col gap-2">
                                    <div class="flex flex-wrap items-center gap-2">
                                        <label class="cursor-pointer bg-slate-100 hover:bg-slate-200 text-slate-800 font-bold text-xs sm:text-sm px-3.5 py-2 rounded-xl transition">
                                            <span>Choose iPad Photo</span>
                                            <input type="file" accept="image/*" class="hidden" onchange="handleAvatarUpload(${p.id}, this)" />
                                        </label>
                                        ${p.avatarDataUrl ? `
                                            <button type="button" onclick="removeAvatar(${p.id})" class="text-xs font-bold text-red-600 hover:text-red-700 px-2.5 py-2">
                                                Remove
                                            </button>
                                        ` : ''}
                                    </div>
                                    <span class="text-xs text-slate-400">Stored locally on this iPad.</span>
                                </div>
                            </div>

                            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                <div>
                                    <label class="block text-xs font-extrabold uppercase tracking-wider text-slate-500 mb-1">Display Name</label>
                                    <input
                                        type="text"
                                        value="${escapeHtml(p.name)}"
                                        oninput="updateProfileField(${p.id}, 'name', this.value)"
                                        class="w-full rounded-xl border border-slate-300 px-3.5 py-2 text-sm font-semibold text-slate-900"
                                    />
                                </div>
                                <div>
                                    <label class="block text-xs font-extrabold uppercase tracking-wider text-slate-500 mb-1">Call Button Label</label>
                                    <input
                                        type="text"
                                        value="${escapeHtml(p.callLabel)}"
                                        oninput="updateProfileField(${p.id}, 'callLabel', this.value)"
                                        class="w-full rounded-xl border border-slate-300 px-3.5 py-2 text-sm font-semibold text-slate-900"
                                    />
                                </div>
                            </div>
                        </div>
                    `;
                }).join('');

                container.innerHTML = topDeviceHeaderHtml + kidCardsHtml;
                return;
            }

            // PILOT PHONE MODE SETTINGS: Only configures THIS pilot's own profile
            const p = profiles.find(item => item.id === appMeta.selectedPilotProfileId) || profiles[0];
            const idx = p.id - 1;
            const parsedEvents = parseICSEvents(p.icsText);
            const isAccountless = p.jitsiDomain === 'meet.ffmuc.net';

            container.innerHTML = topDeviceHeaderHtml + `
                <div class="lg:col-span-2 bg-white border border-slate-200 rounded-3xl shadow-sm p-6 flex flex-col gap-5">
                    <div class="flex flex-wrap items-center justify-between gap-4 border-b border-slate-100 pb-4">
                        <div>
                            <span class="text-xs font-extrabold uppercase tracking-wider text-blue-600">My Pilot Channel</span>
                            <h2 class="text-xl font-black text-slate-900">${escapeHtml(p.name || 'Pilot')}</h2>
                        </div>

                        <div class="inline-flex rounded-2xl bg-slate-100 p-1 border border-slate-200">
                            ${profiles.map(prof => `
                                <button
                                    type="button"
                                    onclick="setPilotSelectedProfile(${prof.id}); renderSettings();"
                                    class="px-3.5 py-1.5 rounded-xl text-xs font-black transition ${prof.id === p.id ? 'bg-blue-600 text-white shadow' : 'text-slate-600'}"
                                >
                                    ${escapeHtml(prof.name || `Pilot ${prof.id}`)}
                                </button>
                            `).join('')}
                        </div>
                    </div>

                    <!-- My Pilot Sync Code -->
                    <div class="bg-blue-50 border border-blue-200 rounded-2xl p-4 flex flex-col gap-2">
                        <label class="text-xs font-extrabold uppercase tracking-wider text-blue-800">My Pilot Sync Code</label>
                        <div class="flex gap-2">
                            <input
                                type="text"
                                value="${escapeHtml(p.syncCode)}"
                                oninput="updateProfileField(${p.id}, 'syncCode', this.value)"
                                class="flex-1 rounded-xl border border-blue-300 bg-white px-3.5 py-2.5 text-base font-mono font-black text-slate-900 uppercase"
                            />
                            <button
                                type="button"
                                onclick="regenerateProfileSyncCode(${p.id})"
                                class="bg-white hover:bg-blue-100 border border-blue-300 text-blue-900 font-bold text-xs px-3.5 py-2 rounded-xl transition"
                            >
                                New Code
                            </button>
                        </div>
                    </div>

                    <!-- Name & Call Label -->
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div>
                            <label class="block text-xs font-extrabold uppercase tracking-wider text-slate-500 mb-1.5">My Pilot / Parent Name</label>
                            <input
                                type="text"
                                value="${escapeHtml(p.name)}"
                                oninput="updateProfileField(${p.id}, 'name', this.value)"
                                class="w-full rounded-xl border border-slate-300 px-3.5 py-2.5 text-sm font-semibold text-slate-900"
                            />
                        </div>
                        <div>
                            <label class="block text-xs font-extrabold uppercase tracking-wider text-slate-500 mb-1.5">iPad Call Button Label</label>
                            <input
                                type="text"
                                value="${escapeHtml(p.callLabel)}"
                                oninput="updateProfileField(${p.id}, 'callLabel', this.value)"
                                class="w-full rounded-xl border border-slate-300 px-3.5 py-2.5 text-sm font-semibold text-slate-900"
                            />
                        </div>
                    </div>

                    <!-- Jitsi Room & Domain -->
                    <div class="bg-slate-50 border border-slate-200/80 rounded-2xl p-4 flex flex-col gap-3">
                        <div>
                            <label class="block text-xs font-extrabold uppercase tracking-wider text-slate-500 mb-1.5">My Private Jitsi Room Name</label>
                            <div class="flex gap-2">
                                <input
                                    type="text"
                                    value="${escapeHtml(p.jitsiRoom)}"
                                    onchange="updateProfileField(${p.id}, 'jitsiRoom', this.value); renderSettings();"
                                    class="flex-1 rounded-xl border border-slate-300 bg-white px-3.5 py-2 text-sm font-mono font-semibold text-slate-900"
                                />
                                <button
                                    type="button"
                                    onclick="regenerateProfileRoom(${p.id})"
                                    class="bg-white hover:bg-slate-100 border border-slate-300 text-slate-700 font-bold text-xs px-3 py-2 rounded-xl transition shrink-0"
                                >
                                    New Random
                                </button>
                            </div>
                        </div>

                        <div>
                            <div class="flex items-center justify-between mb-1">
                                <label class="text-xs font-extrabold uppercase tracking-wider text-slate-500">Jitsi Server Domain</label>
                                <button
                                    type="button"
                                    onclick="updateProfileField(${p.id}, 'jitsiDomain', '${isAccountless ? 'meet.jit.si' : 'meet.ffmuc.net'}'); renderSettings();"
                                    class="text-xs font-bold text-blue-600 hover:underline"
                                >
                                    ${isAccountless ? 'Switch to meet.jit.si' : 'Switch to Accountless (meet.ffmuc.net)'}
                                </button>
                            </div>
                            <input
                                type="text"
                                value="${escapeHtml(p.jitsiDomain)}"
                                onchange="updateProfileField(${p.id}, 'jitsiDomain', this.value); renderSettings();"
                                class="w-full rounded-xl border border-slate-300 bg-white px-3.5 py-2 text-sm font-mono font-semibold text-slate-900"
                            />
                        </div>
                    </div>

                    <!-- ntfy.sh Topic & Test Alert -->
                    <div>
                        <label class="block text-xs font-extrabold uppercase tracking-wider text-slate-500 mb-1.5">My ntfy.sh Push Alert Topic</label>
                        <div class="flex flex-col sm:flex-row gap-2">
                            <input
                                type="text"
                                value="${escapeHtml(p.ntfyTopic)}"
                                oninput="updateProfileField(${p.id}, 'ntfyTopic', this.value)"
                                class="flex-1 rounded-xl border border-slate-300 px-3.5 py-2.5 text-sm font-mono font-semibold text-slate-900"
                            />
                            <button
                                type="button"
                                onclick="sendNtfyNotification(profiles[${idx}], true)"
                                class="bg-amber-400 hover:bg-amber-500 active:scale-95 text-amber-950 font-extrabold text-xs sm:text-sm px-4 py-2.5 rounded-xl shadow-sm transition shrink-0"
                            >
                                Test Push Alert
                            </button>
                        </div>
                    </div>

                    <!-- Crew Schedule .ics URL & File -->
                    <div class="bg-slate-50 border border-slate-200/80 rounded-2xl p-4 flex flex-col gap-3">
                        <div>
                            <label class="block text-xs font-extrabold uppercase tracking-wider text-slate-500 mb-1.5">My Crew Schedule Calendar (.ics URL)</label>
                            <input
                                type="url"
                                value="${escapeHtml(p.icsUrl)}"
                                oninput="updateProfileField(${p.id}, 'icsUrl', this.value)"
                                placeholder="https://... (Flight Crew View, FLICA, or Google Calendar .ics)"
                                class="w-full rounded-xl border border-slate-300 bg-white px-3.5 py-2 text-sm font-semibold text-slate-900"
                            />
                        </div>

                        <div class="flex flex-wrap items-center justify-between gap-2 pt-1">
                            <div class="flex flex-wrap items-center gap-2">
                                <label class="cursor-pointer bg-white hover:bg-slate-100 border border-slate-300 text-slate-800 font-bold text-xs px-3.5 py-2 rounded-xl shadow-sm transition">
                                    <span>Upload .ics File</span>
                                    <input type="file" accept=".ics,text/calendar" class="hidden" onchange="handleIcsFileUpload(${p.id}, this)" />
                                </label>
                                <button
                                    type="button"
                                    onclick="loadSampleIcsTrip(${p.id})"
                                    class="bg-blue-50 hover:bg-blue-100 border border-blue-200 text-blue-700 font-bold text-xs px-3.5 py-2 rounded-xl transition"
                                >
                                    Load Sample Trip
                                </button>
                            </div>

                            ${parsedEvents.length > 0 ? `
                                <div class="flex items-center gap-2">
                                    <span class="text-xs font-bold text-emerald-700 bg-emerald-50 border border-emerald-200 px-2.5 py-1 rounded-lg">
                                        ${parsedEvents.length} leg(s) loaded
                                    </span>
                                    <button type="button" onclick="clearUploadedIcs(${p.id})" class="text-xs font-bold text-slate-400 hover:text-red-600">
                                        Clear
                                    </button>
                                </div>
                            ` : `<span class="text-xs text-slate-400">No .ics events loaded</span>`}
                        </div>
                    </div>
                </div>
            `;
        }

        // ============================================================================
        // PILOT REMOTE MODE UI (OPTIMIZED FOR GOOGLE PIXEL)
        // ============================================================================
        function setPilotSelectedProfile(profileId) {
            appMeta.selectedPilotProfileId = profileId;
            saveAppMeta();
            initCloudSync();
            renderPilotMode();
        }

        async function setPilotQuickStatus(profileId, mode) {
            const p = profiles.find(item => item.id === profileId);
            if (!p) return;
            p.simulationMode = mode;
            saveProfiles();
            renderPilotMode();
            await pushSingleProfileState(profileId, true);
        }

        function updatePilotManualField(profileId, field, value) {
            const p = profiles.find(item => item.id === profileId);
            if (!p) return;
            if (!p.manualFlight) p.manualFlight = {};
            p.manualFlight[field] = value;
            saveProfiles();
        }

        async function setPilotQuickNote(profileId, noteText) {
            const p = profiles.find(item => item.id === profileId);
            if (!p) return;
            p.pilotNote = noteText;
            p.pilotNoteUpdatedAt = Date.now();
            saveProfiles();
            renderPilotMode();
            await pushSingleProfileState(profileId, true);
        }

        function copyKidPairingLink() {
            const baseUrl = window.location.href.split('?')[0];
            const c1 = encodeURIComponent(profiles[0]?.syncCode || '');
            const c2 = profiles[1]?.syncCode ? `&code2=${encodeURIComponent(profiles[1].syncCode)}` : '';
            const pairingUrl = `${baseUrl}?mode=kid&code1=${c1}${c2}`;
            copyTextToClipboard(pairingUrl, 'Copied iPad pairing link! Open it on your kids’ iPad.');
        }

        function renderPilotMode() {
            const container = document.getElementById('pilot-remote-container');
            if (!container) return;

            const selected = profiles.find(p => p.id === appMeta.selectedPilotProfileId) || profiles[0];
            const status = evaluateProfileStatus(selected);
            const mf = selected.manualFlight || {};
            const directRoomUrl = `https://${sanitizeDomain(selected.jitsiDomain)}/${sanitizeRoomName(selected.jitsiRoom)}`;

            const statusButtons = [
                { id: 'live', label: 'Auto (.ics)', sub: 'Calendar', icon: '📅' },
                { id: 'pre-flight', label: 'Boarding', sub: 'At Gate', icon: '🛫' },
                { id: 'in-flight', label: 'In Flight', sub: 'Airborne', icon: '✈️' },
                { id: 'layover', label: 'Layover', sub: 'Hotel / Ground', icon: '🏨' },
                { id: 'off-duty', label: 'Off Duty', sub: 'At Home', icon: '🏠' }
            ];

            const quickNotes = [
                'Boarding now — love you! ✈️',
                'Just landed safely! ❤️',
                'Delayed 30 mins, talk soon!',
                'At the hotel — call anytime! 🏨'
            ];

            let statusDetailInputsHtml = '';
            if (selected.simulationMode === 'in-flight' || selected.simulationMode === 'pre-flight') {
                statusDetailInputsHtml = `
                    <div class="bg-slate-900 border border-white/10 rounded-2xl p-4 flex flex-col gap-3 mt-2">
                        <div class="text-xs font-extrabold uppercase tracking-wider text-sky-400">Active Flight Leg Details</div>
                        <div class="grid grid-cols-3 gap-2.5">
                            <div>
                                <label class="block text-[11px] font-bold text-slate-400 mb-1">Flight #</label>
                                <input
                                    type="text"
                                    value="${escapeHtml(mf.flightNumber || 'AAL456')}"
                                    oninput="updatePilotManualField(${selected.id}, 'flightNumber', this.value.toUpperCase())"
                                    class="w-full rounded-xl bg-slate-800 border border-white/15 px-3 py-2.5 text-sm font-black text-white uppercase"
                                />
                            </div>
                            <div>
                                <label class="block text-[11px] font-bold text-slate-400 mb-1">From</label>
                                <input
                                    type="text"
                                    maxlength="3"
                                    value="${escapeHtml(mf.origin || 'DFW')}"
                                    oninput="updatePilotManualField(${selected.id}, 'origin', this.value.toUpperCase())"
                                    class="w-full rounded-xl bg-slate-800 border border-white/15 px-3 py-2.5 text-sm font-black text-white uppercase"
                                />
                            </div>
                            <div>
                                <label class="block text-[11px] font-bold text-slate-400 mb-1">To</label>
                                <input
                                    type="text"
                                    maxlength="3"
                                    value="${escapeHtml(mf.destination || 'LAX')}"
                                    oninput="updatePilotManualField(${selected.id}, 'destination', this.value.toUpperCase())"
                                    class="w-full rounded-xl bg-slate-800 border border-white/15 px-3 py-2.5 text-sm font-black text-white uppercase"
                                />
                            </div>
                        </div>
                        ${selected.simulationMode === 'in-flight' ? `
                            <div>
                                <label class="block text-[11px] font-bold text-slate-400 mb-1">Minutes Until Landing</label>
                                <input
                                    type="number"
                                    min="1"
                                    max="960"
                                    value="${escapeHtml(String(mf.minutesRemaining || 95))}"
                                    oninput="updatePilotManualField(${selected.id}, 'minutesRemaining', parseInt(this.value, 10) || 60)"
                                    class="w-full rounded-xl bg-slate-800 border border-white/15 px-3 py-2 text-sm font-black text-white"
                                />
                            </div>
                        ` : ''}
                        <button
                            type="button"
                            onclick="pushSingleProfileState(${selected.id}, true); renderPilotMode();"
                            class="w-full bg-sky-500 hover:bg-sky-400 active:scale-[0.99] text-slate-950 font-black text-sm py-3 rounded-xl shadow-lg transition"
                        >
                            Update Flight on iPad
                        </button>
                    </div>
                `;
            } else if (selected.simulationMode === 'layover') {
                statusDetailInputsHtml = `
                    <div class="bg-slate-900 border border-white/10 rounded-2xl p-4 flex flex-col gap-3 mt-2">
                        <div class="text-xs font-extrabold uppercase tracking-wider text-indigo-400">Layover Details</div>
                        <div class="grid grid-cols-2 gap-2.5">
                            <div>
                                <label class="block text-[11px] font-bold text-slate-400 mb-1">Layover Airport</label>
                                <input
                                    type="text"
                                    maxlength="3"
                                    value="${escapeHtml(mf.airport || 'DEN')}"
                                    oninput="updatePilotManualField(${selected.id}, 'airport', this.value.toUpperCase())"
                                    class="w-full rounded-xl bg-slate-800 border border-white/15 px-3 py-2.5 text-sm font-black text-white uppercase"
                                />
                            </div>
                            <div>
                                <label class="block text-[11px] font-bold text-slate-400 mb-1">Next Flight #</label>
                                <input
                                    type="text"
                                    value="${escapeHtml(mf.nextFlightNumber || 'AAL789')}"
                                    oninput="updatePilotManualField(${selected.id}, 'nextFlightNumber', this.value.toUpperCase())"
                                    class="w-full rounded-xl bg-slate-800 border border-white/15 px-3 py-2.5 text-sm font-black text-white uppercase"
                                />
                            </div>
                        </div>
                        <button
                            type="button"
                            onclick="pushSingleProfileState(${selected.id}, true); renderPilotMode();"
                            class="w-full bg-indigo-500 hover:bg-indigo-400 active:scale-[0.99] text-white font-black text-sm py-3 rounded-xl shadow-lg transition"
                        >
                            Update Layover on iPad
                        </button>
                    </div>
                `;
            }

            container.innerHTML = `
                <!-- Header & Direct Pilot Settings / Kid Preview Buttons -->
                <div class="flex items-center justify-between gap-2 pt-1">
                    <div>
                        <div class="inline-flex items-center gap-2 text-xs font-black uppercase tracking-wider text-sky-400">
                            <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
                            <span>Pilot Remote</span>
                        </div>
                        <h1 class="text-2xl font-black text-white leading-tight">${escapeHtml(selected.name)}</h1>
                    </div>
                    <div class="flex items-center gap-2">
                        <button
                            type="button"
                            onclick="openSettings()"
                            class="bg-white/10 hover:bg-white/20 text-white font-extrabold text-xs px-3 py-2.5 rounded-xl border border-white/15 transition"
                        >
                            My Setup ⚙️
                        </button>
                        <button
                            type="button"
                            onclick="setDeviceRole('kid')"
                            class="bg-white/10 hover:bg-white/20 text-sky-300 font-extrabold text-xs px-3 py-2.5 rounded-xl border border-white/15 transition"
                        >
                            Kid View →
                        </button>
                    </div>
                </div>

                <!-- Which Pilot Phone Is This? -->
                <div class="grid grid-cols-2 gap-2 bg-slate-900 p-1.5 rounded-2xl border border-white/10">
                    ${profiles.map(p => `
                        <button
                            type="button"
                            onclick="setPilotSelectedProfile(${p.id})"
                            class="py-2.5 px-3 rounded-xl font-black text-sm transition ${p.id === selected.id ? 'bg-blue-600 text-white shadow' : 'text-slate-400 hover:text-white'}"
                        >
                            ${escapeHtml(p.name || `Pilot ${p.id}`)} (${escapeHtml(p.syncCode)})
                        </button>
                    `).join('')}
                </div>

                <!-- Two-Way Calling Hero Card: Call Kids' iPad Directly -->
                <div class="bg-gradient-to-br from-emerald-600 to-teal-700 rounded-3xl p-5 shadow-xl flex flex-col gap-3">
                    <div class="flex items-center justify-between gap-2">
                        <div>
                            <div class="text-xs font-extrabold uppercase tracking-wider text-emerald-100">Two-Way Family Video</div>
                            <div class="text-lg font-black text-white">Ring Kids' iPad Directly</div>
                        </div>
                        <button
                            type="button"
                            onclick="sendNtfyNotification(profiles[${selected.id - 1}], true)"
                            class="bg-black/25 hover:bg-black/35 text-white font-bold text-xs px-3 py-2 rounded-xl transition shrink-0"
                        >
                            Test Alert
                        </button>
                    </div>

                    <button
                        type="button"
                        onclick="callKidsFromPilot(${selected.id})"
                        class="w-full bg-white hover:bg-emerald-50 active:scale-[0.99] text-emerald-950 font-black text-lg py-4 px-5 rounded-2xl shadow-lg flex items-center justify-center gap-2.5 transition"
                    >
                        <svg class="w-6 h-6 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
                        </svg>
                        <span>Call Kids' iPad Now</span>
                    </button>

                    <a
                        href="${escapeHtml(directRoomUrl)}"
                        target="_blank"
                        rel="noopener noreferrer"
                        class="w-full bg-black/20 hover:bg-black/30 text-emerald-50 font-bold text-xs py-2.5 px-4 rounded-xl text-center transition"
                    >
                        Or Open Room Quietly (${escapeHtml(selected.jitsiRoom)}) ↗
                    </a>
                </div>

                <!-- Pair with Kids' iPad Card -->
                <div class="bg-slate-900/90 border border-white/15 rounded-3xl p-4 flex flex-col gap-3">
                    <div class="flex items-center justify-between gap-2">
                        <span class="text-xs font-extrabold uppercase tracking-wider text-slate-400">Pair with Kids' iPad</span>
                        <span id="pilot-sync-status-text" class="text-xs font-bold ${syncStatusState === 'connected' ? 'text-emerald-400' : 'text-amber-400'}">
                            ${escapeHtml(syncStatusMessage)}
                        </span>
                    </div>
                    <div class="flex items-center justify-between gap-2 bg-slate-800/90 border border-white/10 rounded-2xl px-4 py-3">
                        <div>
                            <div class="text-[11px] font-bold text-slate-400">Your Pilot Sync Code</div>
                            <div class="text-xl font-mono font-black text-white tracking-wider">${escapeHtml(selected.syncCode)}</div>
                        </div>
                        <div class="flex items-center gap-2">
                            <button
                                type="button"
                                onclick="copyTextToClipboard('${escapeHtml(selected.syncCode)}', 'Copied code ${escapeHtml(selected.syncCode)}!')"
                                class="bg-white/10 hover:bg-white/20 text-white font-bold text-xs px-3 py-2 rounded-xl transition"
                            >
                                Copy Code
                            </button>
                            <button
                                type="button"
                                onclick="copyKidPairingLink()"
                                class="bg-sky-500 hover:bg-sky-400 text-slate-950 font-black text-xs px-3 py-2 rounded-xl transition"
                            >
                                Copy iPad Link
                            </button>
                        </div>
                    </div>
                </div>

                <!-- 1-Thumb Status Switcher -->
                <div class="bg-slate-900/90 border border-white/15 rounded-3xl p-4 flex flex-col gap-3">
                    <div class="flex items-center justify-between">
                        <span class="text-xs font-extrabold uppercase tracking-wider text-slate-400">1-Tap iPad Status</span>
                        <span class="text-xs font-bold text-sky-400">
                            Showing: ${escapeHtml(status.state.toUpperCase())}
                        </span>
                    </div>

                    <div class="grid grid-cols-2 sm:grid-cols-3 gap-2.5">
                        ${statusButtons.map(btn => {
                            const active = selected.simulationMode === btn.id;
                            return `
                                <button
                                    type="button"
                                    onclick="setPilotQuickStatus(${selected.id}, '${btn.id}')"
                                    class="p-3.5 rounded-2xl border text-left transition active:scale-95 ${active ? 'bg-blue-600 border-blue-400 text-white shadow-lg shadow-blue-950/60' : 'bg-slate-800/80 border-white/10 text-slate-200 hover:bg-slate-800'}"
                                >
                                    <div class="text-xl mb-1">${btn.icon}</div>
                                    <div class="font-black text-sm leading-tight">${btn.label}</div>
                                    <div class="text-[11px] ${active ? 'text-blue-100' : 'text-slate-400'}">${btn.sub}</div>
                                </button>
                            `;
                        }).join('')}
                    </div>

                    ${statusDetailInputsHtml}
                </div>

                <!-- Quick Note to Kids -->
                <div class="bg-slate-900/90 border border-white/15 rounded-3xl p-4 flex flex-col gap-3">
                    <div class="flex items-center justify-between">
                        <span class="text-xs font-extrabold uppercase tracking-wider text-amber-400">Note Banner on Kids' iPad</span>
                        ${selected.pilotNote ? `
                            <button
                                type="button"
                                onclick="setPilotQuickNote(${selected.id}, '')"
                                class="text-xs font-bold text-slate-400 hover:text-red-400"
                            >Clear Note</button>
                        ` : ''}
                    </div>

                    <div class="flex gap-2">
                        <input
                            id="pilot-note-input"
                            type="text"
                            value="${escapeHtml(selected.pilotNote || '')}"
                            placeholder="Write a quick note for the kids..."
                            class="flex-1 rounded-xl bg-slate-800 border border-white/15 px-3.5 py-2.5 text-sm font-semibold text-white focus:outline-none focus:ring-2 focus:ring-amber-400"
                        />
                        <button
                            type="button"
                            onclick="setPilotQuickNote(${selected.id}, document.getElementById('pilot-note-input').value)"
                            class="bg-amber-400 hover:bg-amber-300 active:scale-95 text-slate-950 font-black text-xs px-4 py-2.5 rounded-xl transition shrink-0"
                        >
                            Send
                        </button>
                    </div>

                    <div class="flex flex-wrap gap-1.5">
                        ${quickNotes.map(note => `
                            <button
                                type="button"
                                onclick="setPilotQuickNote(${selected.id}, '${escapeHtml(note)}')"
                                class="text-xs font-bold bg-slate-800 hover:bg-slate-700 text-slate-200 border border-white/10 px-3 py-1.5 rounded-full transition"
                            >${escapeHtml(note)}</button>
                        `).join('')}
                    </div>
                </div>

                <!-- Upload / Update Crew Schedule (.ics) from Pixel -->
                <div class="bg-slate-900/90 border border-white/15 rounded-3xl p-4 flex flex-col gap-3">
                    <div class="flex items-center justify-between">
                        <span class="text-xs font-extrabold uppercase tracking-wider text-slate-400">Crew Schedule (.ics)</span>
                        <span class="text-xs font-bold text-emerald-400">${parseICSEvents(selected.icsText).length} leg(s) synced</span>
                    </div>
                    <div class="flex flex-wrap gap-2">
                        <label class="flex-1 cursor-pointer bg-slate-800 hover:bg-slate-700 border border-white/15 text-white font-bold text-xs py-3 px-4 rounded-xl text-center transition">
                            <span>Upload .ics File from Phone</span>
                            <input
                                type="file"
                                accept=".ics,text/calendar"
                                class="hidden"
                                onchange="handleIcsFileUpload(${selected.id}, this); pushSingleProfileState(${selected.id}, true); renderPilotMode();"
                            />
                        </label>
                        <button
                            type="button"
                            onclick="loadSampleIcsTrip(${selected.id}); pushSingleProfileState(${selected.id}, true); renderPilotMode();"
                            class="bg-slate-800 hover:bg-slate-700 border border-white/15 text-sky-300 font-bold text-xs py-3 px-4 rounded-xl transition"
                        >
                            Sample Trip
                        </button>
                    </div>
                </div>
            `;
        }

        // ============================================================================
        // INITIALIZATION ON WINDOW LOAD
        // ============================================================================
        window.addEventListener('DOMContentLoaded', () => {
            loadProfiles();
            initHoldSettingsGate();
            applyActiveDeviceRoleView();
            initCloudSync();
            refreshAllRemoteCalendars();

            // Refresh flight progress and UTC schedule state every 60 seconds
            dashboardTimer = setInterval(() => {
                if (appMeta.deviceRole === 'pilot') {
                    renderPilotMode();
                } else {
                    renderDashboard();
                }
                refreshAllRemoteCalendars();
            }, 60000);
        });
    </script>
</body>
</html>
