-- V1: Anomalie aperte 
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

-- V2: Certificazioni in scadenza 
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

-- V3: Presidi per edificio
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

-- V4: Presidi in scadenza
CREATE VIEW vista_presidi_scadenza AS
SELECT p.id_presidio, p.tipologia, p.matricola, p.ubicazione, p.data_scadenza_controllo,
       e.nome AS edificio, u.nome AS unita_organizzativa,
       (TO_DAYS(p.data_scadenza_controllo) - TO_DAYS(CURDATE())) AS giorni_mancanti
FROM presidio p
JOIN planimetria pl ON p.planimetria = pl.id_planimetria
JOIN edificio e ON pl.edificio = e.id_edificio
JOIN unita_organizzativa u ON e.unita = u.id_unita
ORDER BY p.data_scadenza_controllo;

-- V5: Riepilogo edifici
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

-- V6: Storico interventi
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