import 'dart:async';
import 'package:flutter/material.dart';

// Enumerazioni per gestire lo stato dell'applicazione
enum RunningState { start, stop, reset }
// L'enum PauseState non è più necessario, useremo un booleano _isPaused

// La classe principale dell'applicazione
void main() {
  runApp(const StopWatchApp());
}

class StopWatchApp extends StatelessWidget {
  const StopWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cronometro con Stream',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        useMaterial3: true,
      ),
      home: const StopWatchScreen(),
    );
  }
}

class StopWatchScreen extends StatefulWidget {
  const StopWatchScreen({super.key});

  @override
  State<StopWatchScreen> createState() => _StopWatchScreenState();
}

class _StopWatchScreenState extends State<StopWatchScreen> {
  // --- GESTIONE DEGLI STREAM E DELLO STATO ---

  // Stato corrente del cronometro (START, STOP, RESET)
  RunningState _runningState = RunningState.reset;
  
  // Stato della pausa (true = in pausa, false = in esecuzione)
  bool _isPaused = false;

  // Variabile per tenere traccia dei secondi totali trascorsi
  int _totalSeconds = 0;
  
  // Contatore per i tick (spostato a variabile di stato)
  int _tickCount = 0;

  // Timer che genera i tick
  Timer? _timer;
  
  // Controller utilizzato per il flusso di tick
  StreamController<int>? _tickController;
  
  // Riferimento al Subscription del *secondStream*
  StreamSubscription<int>? _secondStreamSubscription;


  // 1. IL TICK STREAM (Logica di creazione)
  // Questa funzione ora avvia il Timer e imposta i listener
  void _startTimerAndStream() {
    // Resetta le variabili di stato
    _totalSeconds = 0;
    _tickCount = 0;
    _isPaused = false;
    
    // Crea un nuovo StreamController per i tick
    _tickController = StreamController<int>.broadcast();
    
    // Sottoscrive allo stream dei secondi (che usa il tickController)
    _secondStreamSubscription = _getSecondStream().listen((_) {
      // Questo listener si attiva ogni volta che il secondStream emette un valore
      setState(() {
        _totalSeconds++;
      });
    });

    // Avvia il timer che genera i tick
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      // **ECCO LA CORREZIONE**
      // Se è in pausa, il timer è attivo ma non genera nuovi tick
      if (_isPaused) {
        return;
      }
      
      // Se non è in pausa, incrementa i tick e li aggiunge allo stream
      _tickCount++;
      _tickController?.add(_tickCount);
    });
  }

  // Interrompe e pulisce il timer e gli stream
  void _stopTimerAndStream() {
    _timer?.cancel();
    _secondStreamSubscription?.cancel();
    _tickController?.close();
    
    _timer = null;
    _secondStreamSubscription = null;
    _tickController = null;
    _isPaused = false;
  }
  
  // 2. IL SECONDS STREAM (Trasforma i tick in secondi)
  // Questo Stream prende i tick e ne genera uno solo ogni secondo completo.
  Stream<int> _getSecondStream() {
    if (_tickController == null) {
      // Ritorna uno stream vuoto se il controller non è inizializzato
      return Stream.value(0);
    }
    
    // Usiamo il metodo `transform` per applicare una logica di conversione.
    return _tickController!.stream.transform(
      StreamTransformer.fromHandlers(
        handleData: (tick, sink) {
          // I tick sono generati ogni 10ms (100 tick per secondo).
          // Se il numero di tick è divisibile per 100, significa che è trascorso un secondo.
          if (tick % 100 == 0) {
            sink.add(1); // Emettiamo un valore '1' per indicare che è passato un secondo
          }
        },
      ),
    );
  }
  
  // --- METODI DI GESTIONE DEI PULSANTI ---

  void _handleStartStopReset() {
    setState(() {
      switch (_runningState) {
        case RunningState.reset:
          // Da RESET a START
          _runningState = RunningState.start;
          _startTimerAndStream(); // Avvia tutto
          break;

        case RunningState.start:
          // Da START a STOP
          _runningState = RunningState.stop;
          _stopTimerAndStream(); // Ferma tutto
          break;
          
        case RunningState.stop:
          // Da STOP a RESET
          _runningState = RunningState.reset;
          _totalSeconds = 0; // Azzera il contatore (i timer sono già fermi)
          break;
      }
    });
  }

  void _handlePauseResume() {
    // Il Pause/Resume funziona solo se il cronometro è in stato "start"
    if (_runningState != RunningState.start) return;

    setState(() {
      // Inverte semplicemente lo stato di pausa
      _isPaused = !_isPaused;
    });
  }

  // Conversione dei secondi totali in formato MM:SS
  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _stopTimerAndStream(); // Pulizia finale
    super.dispose();
  }

  // --- INTERFACCIA UTENTE (UI) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronometro Flutter (Corretto)'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Tempo Trascorso',
              style: TextStyle(fontSize: 24.0, color: Colors.indigo),
            ),
            const SizedBox(height: 20),
            
            // Visualizzazione del tempo formattato
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.indigo.shade200, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                _formatTime(_totalSeconds),
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'RobotoMono',
                  color: Colors.indigo,
                ),
              ),
            ),
            
            const SizedBox(height: 50),
            
            // Pulsanti di controllo
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // PRIMO BOTTONE: START, STOP, RESET
                    _buildControlButton(
                      text: _button1Text,
                      color: _button1Color,
                      onPressed: _handleStartStopReset,
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // SECONDO BOTTONE: PAUSE, RESUME
                    _buildControlButton(
                      text: _button2Text,
                      color: _button2Color,
                      onPressed: _handlePauseResume,
                      // Il pulsante Pausa è attivo solo quando il cronometro è in esecuzione
                      enabled: _runningState == RunningState.start,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper per i pulsanti (per uno stile gradevole e riutilizzabile)
  Widget _buildControlButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    // MODIFICA: Cambiamo da ElevatedButton.icon a ElevatedButton
    // e usiamo Image.asset al posto di Icon.
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: enabled ? color : color.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // **ECCO LA MODIFICA**
          // Usiamo _getIconPathForText per ottenere il percorso dell'asset
          // e lo mostriamo con Image.asset
          Image.asset(
            _getIconPathForText(text),
            width: 24.0, // Imposta la larghezza
            height: 24.0, // Imposta l'altezza
            // 'color' permette di ricolorare l'icona (utile se sono PNG bianchi)
            // Se le tue icone sono già colorate, commenta o rimuovi la riga seguente.
            color: Colors.white, 
          ),
          const SizedBox(width: 8), // Spazio tra icona e testo
          Text(text),
        ],
      ),
    );
  }

  // Logica per il testo e il colore del PRIMO pulsante
  String get _button1Text {
    switch (_runningState) {
      case RunningState.reset: return 'START';
      case RunningState.start: return 'STOP';
      case RunningState.stop: return 'RESET';
    }
  }

  Color get _button1Color {
    switch (_runningState) {
      case RunningState.reset: return Colors.green.shade600;
      case RunningState.start: return Colors.red.shade600;
      case RunningState.stop: return Colors.orange.shade600;
    }
  }

  // Logica per il testo e il colore del SECONDO pulsante
  String get _button2Text {
    // Ora si basa sul booleano _isPaused
    return _isPaused ? 'RESUME' : 'PAUSE';
  }

  Color get _button2Color {
    return _isPaused ? Colors.deepPurple.shade600 : Colors.blue.shade600;
  }
  
  // Logica per l'icona
  // **MODIFICATA** da _getIconForText a _getIconPathForText
  // Ora restituisce una stringa (il percorso dell'asset)
  String _getIconPathForText(String text) {
    // Assicurati che questi file esistano nella tua cartella 'assets/icons/'
    // e che 'assets/icons/' sia dichiarato in pubspec.yaml
    switch (text) {
      case 'START': return 'assets/icons/start.png';
      case 'STOP': return 'assets/icons/stop.png';
      case 'RESET': return 'assets/icons/reset.png';
      case 'PAUSE': return 'assets/icons/pause.png';
      case 'RESUME': return 'assets/icons/resume.png';
      // Fornisci un'icona di default in caso di errore
      default: return 'assets/icons/default_icon.png'; 
    }
  }
}