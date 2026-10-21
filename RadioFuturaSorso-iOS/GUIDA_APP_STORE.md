# Guida Ufficiale: Installazione su iPhone e Pubblicazione su Apple App Store
## App Ufficiale Radio Futura Sorso (Solo online)

Questa guida ti accompagna passo dopo passo per:
1. Aprire ed eseguire il progetto con **Xcode su Mac**.
2. Installare l'app sul tuo **iPhone o iPad personale**.
3. Pubblicarla su **TestFlight** e sull'**App Store di Apple**.

---

### Requisiti
- Un Mac (macOS Sonoma o Sequoia) con **Xcode 15 o Xcode 16** installato (gratuito dal Mac App Store).
- Un account Apple (anche gratuito per testare sul proprio iPhone, oppure **Apple Developer Program** a 99€/anno per pubblicare sull'App Store).
- Un cavo USB / Lightning / USB-C per collegare il tuo iPhone al Mac.

---

### FASE 1: Aprire il Progetto in Xcode
1. Scarica e scompatta il file zip `RadioFuturaSorso-iOS.zip`.
2. Apri Xcode sul Mac e seleziona **Create New Xcode Project** (oppure apri la cartella del progetto).
3. Se crei un nuovo progetto iOS App:
   - **Product Name**: `RadioFuturaSorso`
   - **Organization Identifier**: `it.radiofuturasorso` (oppure il tuo identificativo)
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
4. Trascina i file della cartella scaricata all'interno del navigatore di Xcode:
   - `RadioFuturaSorsoApp.swift`
   - `RadioPlayerManager.swift`
   - `ArtworkFetcher.swift`
   - `ContentView.swift`
   - `AirPlayView.swift`
   - `CarPlaySceneDelegate.swift`
   - `Info.plist`

---

### FASE 2: Configurare Firma e Capacità (Signing & Capabilities)
1. In Xcode, fai clic sulla radice del progetto nella barra laterale sinistra (icona blu).
2. Seleziona il Target **RadioFuturaSorso** e vai sulla scheda **Signing & Capabilities**:
   - Spunta **Automatically manage signing**.
   - In **Team**, seleziona il tuo Account Apple (aggiungilo da *Xcode > Settings > Accounts* se non presente).
   - In **Bundle Identifier**, lascia o inserisci `it.radiofuturasorso.app`.
3. Verifica che sotto **Background Modes** ci sia spuntato:
   - ✅ **Audio, AirPlay, and Picture in Picture** (questo garantisce l'ascolto con schermo spento).

---

### FASE 3: Installare l'App sul tuo iPhone
1. Collega il tuo iPhone al Mac con il cavo.
2. Sblocca l'iPhone e tocca **Autorizza questo computer**.
3. Sul tuo iPhone, vai in **Impostazioni > Privacy e sicurezza > Modalità sviluppatore** e attivala (richiede un riavvio rapido del telefono).
4. In alto in Xcode, nel selettore del dispositivo di esecuzione, seleziona il tuo iPhone (es. "iPhone di Mario").
5. Premi il pulsante **Play (Run)** ▶️ in alto a sinistra in Xcode.
6. Xcode compilerà l'app e la installerà direttamente sul tuo iPhone.
7. Al primo avvio, se compare "Sviluppatore non attendibile", vai sul telefono in **Impostazioni > Generali > Gestione VPN e dispositivo** e tocca **Autorizza**.

L'app funzionerà subito in diretta con lo streaming di Radio Futura Sorso!

---

### FASE 4: Pubblicazione su App Store Connect
1. Accedi a [appstoreconnect.apple.com](https://appstoreconnect.apple.com).
2. Fai clic su **Le mie app** e poi sul tasto **+ (Nuova app)**:
   - **Nome**: Radio Futura Sorso
   - **Lingua principale**: Italiano
   - **ID bundle**: seleziona `it.radiofuturasorso.app`
   - **SKU**: `radio-futura-sorso-ios`
3. Compila la scheda dell'app:
   - **Sottotitolo**: Solo online
   - **Descrizione**: "Ascolta in diretta streaming la musica e le trasmissioni di Radio Futura Sorso. Con metadati in tempo reale, titoli delle canzoni, copertine album, supporto per AirPlay, Bluetooth e contatto diretto via WhatsApp."
   - **Parole chiave (Keywords)**: radio, sorso, sardegna, sassari, musica, streaming, radio futura
   - **URL di supporto e Privacy**: inserisci il link al sito web della radio (`https://www.radiofuturasorso.it`).
4. In Xcode, imposta il selettore del dispositivo su **Any iOS Device (arm64)**.
5. Dal menu in alto, seleziona **Product > Archive**.
6. Al termine della compilazione, nella finestra degli Archivi, clicca **Distribute App** > **App Store Connect** > **Upload**.
7. In pochi minuti la build apparirà su App Store Connect in **TestFlight** per test interni ed esterni, e potrai fare clic su **Invia per la verifica** per la pubblicazione ufficiale!
