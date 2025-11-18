# STOP WATCH IN FLUTTER #
Nome: Samuele
Cognome: Tavani

Descrizione del progetto: una versione di un cronometro molto basilare fatta con flutter 


# Funzionalità: 
  - Start / Stop / Reset: Controllo classico del flusso temporale.

  - Pause / Resume: Logica intelligente che "congela" la generazione dei tick senza perdere lo stato.

  - Architettura a Stream: Separazione netta tra la generazione del tempo (Tick) e la visualizzazione (UI).

  - UI Personalizzata: Utilizzo di asset personalizzati per le icone dei pulsanti.

# Tecnologie e Scelte Architetturali

  - Il cuore del progetto non è la semplice conta dei secondi, ma la correlazione tra due Stream:

  - Tick Stream (StreamController): Genera un evento ogni 10ms (la base dei tempi).

  - Seconds Stream (StreamTransformer): Ascolta il Tick Stream e trasforma i dati, emettendo un evento solo ogni 100 tick (1 secondo).

#Nota dall'autore#
Essendo un progetto che può essere poco personalizzabile non ho fatto granché di personalizzazione, anche se penso di aggiungere a breve una sorta di cronologia per tenere traccia magari di eventuali "checkpoint" che si fanno durante un allenamento.
