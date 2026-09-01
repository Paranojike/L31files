--IMPLEMENTAZIONE DELLE OPERAZIONI (VISTE, STORED PROCEDURES, TRIGGER)

USE gestione_antincendio;

-- Disabilita temporaneamente i controlli di chiave esterna per la creazione pulita
SET FOREIGN_KEY_CHECKS = 0;

-- 1. CREAZIONE DELLE VISTE

-- V1 (Operazione O6): Anomalie attualmente in stato "Aperta", ordinate per livello di gravità
CREATE VIEW vista_anomalie_aperte AS
SELECT a.id_anomalia, a.descrizione, a.gravita, a.data_rilevazione,
       p.id_presidio, p.tipologia, p.matricola, p.ubicazione,
       e.nome AS edificio, CONCAT(t.nome, ' ', t.cognome) AS tecnico
FROM anomalia a
JOIN intervento i ON a.intervento = i.id_intervento
JOIN presidio p ON i.presidio = p.id_presidio
JOIN planimetria pl ON p.planimetria = pl.id_planimetria
JOIN edificio e ON pl.edificio = e.id_edificio
JOIN tecnico t ON i.tecnico = t.id_tecnico
WHERE a.stato = 'Aperta'
ORDER BY FIELD(a.gravita, 'Critica', 'Alta', 'Media', 'Bassa');

-- V2 (Operazione O8): Certificazioni normative in scadenza o già scadute
CREATE VIEW vista_certificazioni_scadenza AS
SELECT c.id_certificazione, c.tipo, c.data_rilascio, c.data_scadenza,
       c.ente_certificatore, e.nome AS edificio, u.nome AS unita_organizzativa,
       (TO_DAYS(c.data_scadenza) - TO_DAYS(CURDATE())) AS giorni_mancanti,
       CASE WHEN c.data_scadenza < CURDATE() THEN 'SCADUTA'
            WHEN c.data_scadenza BETWEEN CURDATE() AND CURDATE() + INTERVAL 30 DAY THEN 'IN SCADENZA (30 gg)'
            WHEN c.data_scadenza BETWEEN CURDATE() AND CURDATE() + INTERVAL 90 DAY THEN 'IN SCADENZA (90 gg)'
            ELSE 'VALIDA' END AS stato_scadenza
FROM certificazione c
JOIN edificio e ON c.edificio = e.id_edificio
JOIN unita_organizzativa u ON e.unita = u.id_unita;

-- V3: Censimento presidi per edificio con indicazione dei giorni alla scadenza
CREATE VIEW vista_presidi_edificio AS
SELECT p.id_presidio, p.tipologia, p.matricola, p.ubicazione,
       p.data_installazione, p.data_scadenza_controllo, p.stato,
       e.nome AS edificio, e.citta, u.nome AS unita_organizzativa,
       (TO_DAYS(p.data_scadenza_controllo) - TO_DAYS(CURDATE())) AS giorni_scadenza
FROM presidio p
JOIN planimetria pl ON p.planimetria = pl.id_planimetria
JOIN edificio e ON pl.edificio = e.id_edificio
JOIN unita_organizzativa u ON e.unita = u.id_unita
ORDER BY e.nome, p.ubicazione;

-- V4 (Operazione O3): Presidi con data di controllo in scadenza
CREATE VIEW vista_presidi_scadenza AS
SELECT p.id_presidio, p.tipologia, p.matricola, p.ubicazione, p.data_scadenza_controllo,
       e.nome AS edificio, u.nome AS unita_organizzativa,
       (TO_DAYS(p.data_scadenza_controllo) - TO_DAYS(CURDATE())) AS giorni_mancanti
FROM presidio p
JOIN planimetria pl ON p.planimetria = pl.id_planimetria
JOIN edificio e ON pl.edificio = e.id_edificio
JOIN unita_organizzativa u ON e.unita = u.id_unita
ORDER BY p.data_scadenza_controllo;

-- V5 (Operazione O4): Riepilogo di conformità e conteggi statistici per Edificio
CREATE VIEW vista_riepilogo_edifici AS
SELECT e.id_edificio, e.nome AS edificio, u.nome AS unita_organizzativa,
       COUNT(DISTINCT p.id_presidio) AS totale_presidi,
       COUNT(DISTINCT CASE WHEN p.stato = 'Operativo' THEN p.id_presidio END) AS operativi,
       COUNT(DISTINCT CASE WHEN p.stato = 'Guasto' THEN p.id_presidio END) AS guasti,
       COUNT(DISTINCT CASE WHEN p.stato = 'Da revisionare' THEN p.id_presidio END) AS da_revisionare,
       COUNT(DISTINCT CASE WHEN p.stato = 'Da sostituire' THEN p.id_presidio END) AS da_sostituire,
       COUNT(DISTINCT CASE WHEN p.data_scadenza_controllo < CURDATE() THEN p.id_presidio END) AS scaduti,
       COUNT(DISTINCT a.id_anomalia) AS anomalie_aperte,
       COUNT(DISTINCT c.id_certificazione) AS certificazioni
FROM edificio e
JOIN unita_organizzativa u ON e.unita = u.id_unita
LEFT JOIN planimetria pl ON e.id_edificio = pl.edificio
LEFT JOIN presidio p ON pl.id_planimetria = p.planimetria
LEFT JOIN intervento i ON p.id_presidio = i.presidio
LEFT JOIN anomalia a ON i.id_intervento = a.intervento AND a.stato = 'Aperta'
LEFT JOIN certificazione c ON e.id_edificio = c.edificio
GROUP BY e.id_edificio, e.nome, u.nome;

-- V6 (Operazione O5): Storico cronologico globale degli interventi
CREATE VIEW vista_storico_interventi AS
SELECT i.id_intervento, i.data_intervento, i.tipo_intervento, i.esito, i.note,
       p.id_presidio, p.tipologia, p.matricola, p.ubicazione,
       CONCAT(t.nome, ' ', t.cognome) AS tecnico, e.nome AS edificio
FROM intervento i
JOIN presidio p ON i.presidio = p.id_presidio
JOIN planimetria pl ON p.planimetria = pl.id_planimetria
JOIN edificio e ON pl.edificio = e.id_edificio
JOIN tecnico t ON i.tecnico = t.id_tecnico
ORDER BY i.data_intervento;


-- 2. CREAZIONE DELLE STORED PROCEDURES 

DELIMITER $$

-- SP1 (Operazione O1): Inserimento di un nuovo intervento (la data_intervento è impostata a CURDATE())
CREATE PROCEDURE NuovoIntervento (
    IN p_presidio INT,
    IN p_tecnico INT,
    IN p_tipo VARCHAR(50),
    IN p_esito VARCHAR(20),
    IN p_note TEXT
)
BEGIN
    INSERT INTO intervento (presidio, tecnico, data_intervento, tipo_intervento, esito, note)
    VALUES (p_presidio, p_tecnico, CURDATE(), p_tipo, p_esito, p_note);
END$$

-- SP2 (Operazione O2): Registrazione facilitata di un'anomalia
CREATE PROCEDURE RegistraAnomalia (
    IN p_intervento INT,
    IN p_descrizione TEXT,
    IN p_gravita VARCHAR(20),
    IN p_data DATE
)
BEGIN
    INSERT INTO anomalia (intervento, descrizione, gravita, stato, data_rilevazione)
    VALUES (p_intervento, p_descrizione, p_gravita, 'Aperta', p_data);
END$$

-- SP3 (Operazione O8): Report delle certificazioni in scadenza entro N giorni
CREATE PROCEDURE ReportCertificazioniScadenza (
    IN p_giorni INT
)
BEGIN
    SELECT * FROM vista_certificazioni_scadenza
    WHERE giorni_mancanti <= p_giorni;
END$$

-- SP4 (Operazione O4): Report statistico di dettaglio per un singolo Edificio
CREATE PROCEDURE ReportEdificio (
    IN p_id_edificio INT
)
BEGIN
    SELECT * FROM vista_riepilogo_edifici
    WHERE id_edificio = p_id_edificio;
END$$

-- SP5 (Operazione O3): Report dei presidi in scadenza entro N giorni
CREATE PROCEDURE ReportScadenze (
    IN p_giorni INT
)
BEGIN
    SELECT * FROM vista_presidi_scadenza
    WHERE giorni_mancanti <= p_giorni;
END$$

DELIMITER ;


-- 3. CREAZIONE DEI TRIGGERS 

DELIMITER $$
-- T1: Calcolo e validazione scadenza per nuovo presidio (check_date_presidio)
CREATE TRIGGER check_date_presidio
BEFORE INSERT ON presidio
FOR EACH ROW
BEGIN
    IF NEW.data_scadenza_controllo <= NEW.data_installazione THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Errore: La data di scadenza del controllo deve essere successiva alla data di installazione.';
    END IF;
END$$

-- T2: Controllo date intervento rispetto all'installazione del presidio
CREATE TRIGGER check_data_intervento_installazione
BEFORE INSERT ON intervento
FOR EACH ROW
BEGIN
    DECLARE v_data_installazione DATE;

    SELECT data_installazione INTO v_data_installazione
    FROM presidio
    WHERE id_presidio = NEW.presidio;

    IF NEW.data_intervento < v_data_installazione THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Errore: La data intervento non può essere antecedente alla data di installazione del presidio.';
    END IF;

    IF NEW.data_intervento > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Errore: La data intervento non può essere nel futuro.';
    END IF;
END$$

-- T3 (Operazione O1): Aggiornamento automatico dello stato del presidio dopo un intervento
CREATE TRIGGER gestisci_presidio_dopo_intervento
AFTER INSERT ON intervento
FOR EACH ROW
BEGIN
    DECLARE v_nuovo_stato VARCHAR(50);

    IF NEW.esito = 'Positivo' THEN 
        SET v_nuovo_stato = 'Operativo';
    ELSEIF NEW.esito = 'Da verificare' THEN 
        SET v_nuovo_stato = 'Da revisionare';
    ELSEIF NEW.esito = 'Negativo' THEN 
        SET v_nuovo_stato = 'Guasto';
    END IF;

    UPDATE presidio 
    SET stato = v_nuovo_stato 
    WHERE id_presidio = NEW.presidio;
END$$

-- T4: Controllo coerenza temporale della data rilevazione anomalia rispetto all'ispezione
CREATE TRIGGER check_data_rilevazione_anomalia
BEFORE INSERT ON anomalia
FOR EACH ROW
BEGIN
    DECLARE v_data_intervento DATE;

    SELECT data_intervento INTO v_data_intervento
    FROM intervento
    WHERE id_intervento = NEW.intervento;

    IF NEW.data_rilevazione < v_data_intervento THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Errore: La data di rilevazione della anomalia deve essere uguale o successiva alla data di intervento.';
    END IF;
END$$

-- T5 (Operazione O2): Allarme per anomalie con gravità Alta o Critica 
CREATE TRIGGER allarme_anomalia_critica
AFTER INSERT ON anomalia
FOR EACH ROW
BEGIN
    DECLARE v_id_presidio INT;

    SELECT presidio INTO v_id_presidio
    FROM intervento
    WHERE id_intervento = NEW.intervento;

    IF NEW.gravita IN ('Alta', 'Critica') THEN
        UPDATE presidio
        SET stato = 'Guasto'
        WHERE id_presidio = v_id_presidio;
    END IF;
END$$

-- T6: Controllo date di validità delle certificazioni (scadenza successiva a rilascio)
CREATE TRIGGER check_date_certificazione
BEFORE INSERT ON certificazione
FOR EACH ROW
BEGIN
    IF NEW.data_scadenza <= NEW.data_rilascio THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Errore: La data di scadenza deve essere successiva alla data di rilascio.';
    END IF;
END$$

DELIMITER ;


SET FOREIGN_KEY_CHECKS = 1;

