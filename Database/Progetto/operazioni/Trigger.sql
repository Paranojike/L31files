-- TRIGGER

-- T1: Calcolo scadenza per nuovo presidio
CREATE TRIGGER check_date_presidio
BEFORE INSERT ON presidio
FOR EACH ROW
BEGIN
    IF NEW.data_scadenza_controllo <= NEW.data_installazione THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Errore: La data di scadenza del controllo deve essere successiva alla data di installazione.';
    END IF;
END$$


-- T2: Controllo date intervento 
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

-- T3: Aggiornamento stato dopo intervento
CREATE TRIGGER gestisci_presidio_dopo_intervento
AFTER INSERT ON intervento
FOR EACH ROW
BEGIN
    DECLARE v_nuovo_stato VARCHAR(50);

    -- 1. Determino il nuovo stato in base all'esito
    IF NEW.esito = 'Positivo' THEN 
        SET v_nuovo_stato = 'Operativo';
    ELSEIF NEW.esito = 'Da verificare' THEN 
        SET v_nuovo_stato = 'Da revisionare';
    ELSEIF NEW.esito = 'Negativo' THEN 
        SET v_nuovo_stato = 'Guasto';
    END IF;

    -- 2. Aggiorno lo stato del presidio
    UPDATE presidio 
    SET stato = v_nuovo_stato 
    WHERE id_presidio = NEW.presidio;
END$$



-- T4: Controllo data rilevazione anomalia
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


-- T5: Allarme anomalia critica 
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

-- T6: Controllo date certificazione
CREATE TRIGGER check_date_certificazione
BEFORE INSERT ON certificazione
FOR EACH ROW
BEGIN
    IF NEW.data_scadenza <= NEW.data_rilascio THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Errore: La data di scadenza deve essere successiva alla data di rilascio.';
    END IF;
END$$

