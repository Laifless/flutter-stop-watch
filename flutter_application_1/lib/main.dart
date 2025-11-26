import 'dart:async';
import 'package:flutter/material.dart';

// Enumerazioni per gestire lo stato dell'applicazione
enum RunningState { start, stop, reset }

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
        primarySwatch: Colors.indigo,
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
  
  // Contatore per i tick
  int _tickCount = 0;

  // Timer che genera i tick
  Timer? _timer;
  
  // Controller utilizzato per il flusso di tick
  StreamController<int>? _tickController;
  
  // Riferimento al Subscription del *secondStream*
  StreamSubscription<int>? _secondStreamSubscription;


  // 1. IL TICK STREAM (Logica di creazione)
  void _startTimerAndStream() {
    // Resetta le variabili di stato
    _totalSeconds = 0;
    _tickCount = 0;
    _isPaused = false;
    
    // Crea un nuovo StreamController per i tick
    _tickController = StreamController<int>.broadcast();
    
    // Sottoscrive allo stream dei secondi
    _secondStreamSubscription = _getSecondStream().listen((_) {
      setState(() {
        _totalSeconds++;
      });
    });

    // Avvia il timer che genera i tick (ogni 10ms)
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (_isPaused) {
        return;
      }
      
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
  Stream<int> _getSecondStream() {
    if (_tickController == null) {
      return Stream.value(0);
    }
    
    return _tickController!.stream.transform(
      StreamTransformer.fromHandlers(
        handleData: (tick, sink) {
          // 100 tick da 10ms = 1 secondo
          if (tick % 100 == 0) {
            sink.add(1);
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
          _startTimerAndStream();
          break;

        case RunningState.start:
          // Da START a STOP
          _runningState = RunningState.stop;
          _stopTimerAndStream();
          break;
          
        case RunningState.stop:
          // Da STOP a RESET
          _runningState = RunningState.reset;
          _totalSeconds = 0;
          break;
      }
    });
  }

  void _handlePauseResume() {
    if (_runningState != RunningState.start) return;

    setState(() {
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
    _stopTimerAndStream();
    super.dispose();
  }

  // --- INTERFACCIA UTENTE (UI) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronometro Flutter'),
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

  // Widget helper per i pulsanti
  Widget _buildControlButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
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
          // --- MODIFICA EFFETTUATA ---
          // Qui chiamiamo la funzione passando il testo.
          // Non usiamo più Image.asset perché _getIconForText restituisce già un Widget.
          _getIconForText(text),
          
          const SizedBox(width: 8),
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
    return _isPaused ? 'RESUME' : 'PAUSE';
  }

  Color get _button2Color {
    return _isPaused ? Colors.deepPurple.shade600 : Colors.blue.shade600;
  }
  
  // Logica per l'icona
  // --- MODIFICA EFFETTUATA ---
  // Rinominta per chiarezza e ora restituisce un Widget (Icon) invece di Object
  Widget _getIconForText(String text) {
    switch (text) {
      case 'START': return const Icon(Icons.play_circle, size: 24);
      case 'STOP': return const Icon(Icons.stop_circle, size: 24);
      case 'RESET': return const Icon(Icons.replay, size: 24);
      case 'PAUSE': return const Icon(Icons.pause_circle, size: 24);
      case 'RESUME': return const Icon(Icons.timer, size: 24);
      default: return const Icon(Icons.timer, size: 24); 
    }
  }
}