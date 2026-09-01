-- STORED PROCEDURES

-- Inserimento intervento
DELIMITER $$
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


-- Registrazione anomalia
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



--  Report certificazioni in scadenza 
CREATE PROCEDURE ReportCertificazioniScadenza (
    IN p_giorni INT
)
BEGIN
    SELECT * FROM vista_certificazioni_scadenza
    WHERE giorni_mancanti <= p_giorni;
END$$



-- Report edificio 
CREATE PROCEDURE ReportEdificio (
    IN p_id_edificio INT
)
BEGIN
    SELECT * FROM vista_riepilogo_edifici
    WHERE id_edificio = p_id_edificio;
END$$



-- Report scadenze
CREATE PROCEDURE ReportScadenze (
    IN p_giorni INT
)
BEGIN
    SELECT * FROM vista_presidi_scadenza
    WHERE giorni_mancanti <= p_giorni;
END$$

DELIMITER ;