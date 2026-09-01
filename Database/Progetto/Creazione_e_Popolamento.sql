-- CREAZIONE DATABASE E DATI DI ESEMPIO

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

SET FOREIGN_KEY_CHECKS = 0;



-- Tabella unita_organizzativa
CREATE TABLE unita_organizzativa (
    id_unita INT NOT NULL AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    responsabile VARCHAR(100) DEFAULT NULL,
    PRIMARY KEY (id_unita)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabella tecnico
CREATE TABLE tecnico (
    id_tecnico INT NOT NULL AUTO_INCREMENT,
    nome VARCHAR(50) NOT NULL,
    cognome VARCHAR(50) NOT NULL,
    telefono VARCHAR(20) DEFAULT NULL,
    PRIMARY KEY (id_tecnico)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabella edificio
CREATE TABLE edificio (
    id_edificio INT NOT NULL AUTO_INCREMENT,
    unita INT NOT NULL,
    nome VARCHAR(100) NOT NULL,
    indirizzo VARCHAR(100) NOT NULL,
    citta VARCHAR(100) NOT NULL,
    PRIMARY KEY (id_edificio),
    KEY fk_unitaorganizzativa (unita),
    CONSTRAINT fk_edificio_unita FOREIGN KEY (unita) REFERENCES unita_organizzativa (id_unita)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabella planimetria
CREATE TABLE planimetria (
    id_planimetria INT NOT NULL AUTO_INCREMENT,
    edificio INT NOT NULL,
    piano INT NOT NULL,
    file VARCHAR(100) DEFAULT NULL,
    data_aggiornamento DATE NOT NULL,
    PRIMARY KEY (id_planimetria),
    UNIQUE KEY idx_edificio_piano (edificio, piano),
    KEY fk_edificio (edificio),
    CONSTRAINT fk_planimetria_edificio FOREIGN KEY (edificio) REFERENCES edificio (id_edificio) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabella presidio
CREATE TABLE presidio (
    id_presidio INT NOT NULL AUTO_INCREMENT,
    planimetria INT NOT NULL,
    tipologia ENUM('Estintore', 'Idrante', 'Rilevatore di fumo', 'Centrale antincendio') NOT NULL,
    matricola VARCHAR(50) NOT NULL,
    ubicazione VARCHAR(100) DEFAULT NULL,
    data_installazione DATE NOT NULL,
    data_scadenza_controllo DATE NOT NULL,
    stato ENUM('Operativo', 'Da revisionare', 'Guasto', 'Da sostituire') DEFAULT 'Operativo',
    PRIMARY KEY (id_presidio),
    UNIQUE KEY uq_presidio_matricola (matricola),
    KEY fk_presidio_planimetria (planimetria),
    KEY idx_scadenza_presidio (data_scadenza_controllo),
    CONSTRAINT fk_presidio_planimetria FOREIGN KEY (planimetria) REFERENCES planimetria (id_planimetria)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabella intervento
CREATE TABLE intervento (
    id_intervento INT NOT NULL AUTO_INCREMENT,
    presidio INT NOT NULL,
    tecnico INT NOT NULL,
    data_intervento DATE NOT NULL,
    tipo_intervento ENUM('Controllo periodico', 'Manutenzione straordinaria', 'Collaudo', 'Sostituzione', 'Riparazione') NOT NULL,
    esito ENUM('Positivo', 'Negativo', 'Da verificare') NOT NULL DEFAULT 'Da verificare',
    note TEXT,
    PRIMARY KEY (id_intervento),
    KEY fk_presidio (presidio),
    KEY fk_tecnico (tecnico),
    KEY idx_data_intervento (data_intervento),
    CONSTRAINT fk_intervento_presidio FOREIGN KEY (presidio) REFERENCES presidio (id_presidio),
    CONSTRAINT fk_intervento_tecnico FOREIGN KEY (tecnico) REFERENCES tecnico (id_tecnico)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabella anomalia
CREATE TABLE anomalia (
    id_anomalia INT NOT NULL AUTO_INCREMENT,
    intervento INT NOT NULL,
    descrizione TEXT NOT NULL,
    gravita ENUM('Bassa', 'Media', 'Alta', 'Critica') NOT NULL,
    stato ENUM('Aperta', 'In lavorazione', 'Verificata', 'Chiusa') NOT NULL DEFAULT 'Aperta',
    data_rilevazione DATE NOT NULL,
    PRIMARY KEY (id_anomalia),
    KEY fk_intervento (intervento),
    KEY idx_stato_anomalia (stato),
    CONSTRAINT fk_anomalia_intervento FOREIGN KEY (intervento) REFERENCES intervento (id_intervento)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabella certificazione
CREATE TABLE certificazione (
    id_certificazione INT NOT NULL AUTO_INCREMENT,
    edificio INT NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    data_rilascio DATE NOT NULL,
    data_scadenza DATE NOT NULL,
    ente_certificatore VARCHAR(100) NOT NULL,
    PRIMARY KEY (id_certificazione),
    KEY fk_certificazione_edificio (edificio),
    KEY idx_scadenza_certificazione (data_scadenza),
    CONSTRAINT fk_certificazione_edificio FOREIGN KEY (edificio) REFERENCES edificio (id_edificio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- POPOLAMENTO DATI 

-- Unità Organizzative
INSERT INTO unita_organizzativa (id_unita, nome, responsabile) VALUES
(1, 'Amministrazione', 'Mario Rossi'),
(2, 'Produzione', 'Luca Bianchi'),
(3, 'Magazzino', 'Anna Verdi'),
(4, 'Ricerca e Sviluppo', 'Giulia Neri'),
(5, 'Qualità', 'Marco Gallo'),
(6, 'Manutenzione', 'Paolo Ferri');

-- Tecnici
INSERT INTO tecnico (id_tecnico, nome, cognome, telefono) VALUES
(1, 'Andrea', 'Russo', '3331111111'),
(2, 'Matteo', 'Greco', '3331111112'),
(3, 'Davide', 'Caruso', '3331111113'),
(4, 'Simone', 'Vitale', '3331111114'),
(5, 'Francesco', 'Messina', '3331111115'),
(6, 'Alessio', 'Rizzo', '3331111116');

-- Edifici
INSERT INTO edificio (id_edificio, unita, nome, indirizzo, citta) VALUES
(1, 1, 'Palazzina Uffici', 'Via Roma 12', 'Catania'),
(2, 2, 'Stabilimento Nord', 'Via Etnea 35', 'Catania'),
(3, 3, 'Magazzino Centrale', 'Via Palermo 91', 'Catania'),
(4, 4, 'Laboratorio Chimico', 'Via Milano 22', 'Catania'),
(5, 5, 'Centro Qualità', 'Via Firenze 9', 'Acireale'),
(6, 6, 'Officina Tecnica', 'Via Messina 41', 'Acireale');

-- Planimetrie
INSERT INTO planimetria (id_planimetria, edificio, piano, file, data_aggiornamento) VALUES
(1, 1, 0, 'uffici_pt.pdf', '2026-01-10'),
(2, 1, 1, 'uffici_p1.pdf', '2026-01-10'),
(3, 2, 0, 'stabilimento_pt.pdf', '2026-02-18'),
(4, 2, 1, 'stabilimento_p1.pdf', '2026-02-18'),
(5, 3, 0, 'magazzino.pdf', '2026-03-05'),
(6, 4, 0, 'laboratorio.pdf', '2026-04-02');

-- Presidi
INSERT INTO presidio (id_presidio, planimetria, tipologia, matricola, ubicazione, data_installazione, data_scadenza_controllo, stato) VALUES
(1, 1, 'Estintore', 'EST-001', 'Corridoio Piano Terra', '2024-01-10', '2025-01-10', 'Operativo'),
(2, 3, 'Idrante', 'IDR-102', 'Ingresso Magazzino', '2022-03-15', '2024-03-15', 'Da revisionare'),
(3, 4, 'Rilevatore di fumo', 'RIL-045', 'Laboratorio Chimico Est', '2023-06-20', '2026-06-20', 'Operativo'),
(4, 2, 'Centrale antincendio', 'CEN-999', 'Sala Server', '2020-11-05', '2022-11-05', 'Guasto');

-- Interventi
INSERT INTO intervento (id_intervento, presidio, tecnico, data_intervento, tipo_intervento, esito, note) VALUES
(1, 1, 1, '2024-07-05', 'Controllo periodico', 'Positivo', 'Pressione regolare, nessun difetto.'),
(2, 2, 2, '2024-03-10', 'Controllo periodico', 'Da verificare', 'Tubo usurato, necessita controllo approfondito.'),
(3, 4, 3, '2023-11-10', 'Manutenzione straordinaria', 'Negativo', 'Scheda logica bruciata, impossibile ripristinare sul posto.');

-- Anomalie
INSERT INTO anomalia (id_anomalia, intervento, descrizione, gravita, stato, data_rilevazione) VALUES
(1, 2, 'Lieve perdita di pressione e tubo con abrasioni.', 'Media', 'In lavorazione', '2024-03-11'),
(2, 3, 'Scheda logica andata, rischio corto circuito.', 'Critica', 'Aperta', '2023-11-10');

-- Certificazioni
INSERT INTO certificazione (id_certificazione, edificio, tipo, data_rilascio, data_scadenza, ente_certificatore) VALUES
(1, 1, 'Prevenzione Incendi', '2024-01-10', '2029-01-10', 'Vigili del Fuoco'),
(2, 2, 'Prevenzione Incendi', '2023-11-18', '2028-11-18', 'Vigili del Fuoco'),
(3, 3, 'Conformità Antincendio', '2025-02-05', '2030-02-05', 'Ente Certificatore Italia'),
(4, 4, 'Prevenzione Incendi', '2024-06-15', '2029-06-15', 'Vigili del Fuoco'),
(5, 5, 'Conformità Antincendio', '2021-05-10', '2026-05-10', 'Vigili del Fuoco'),
(6, 6, 'Prevenzione Incendi', '2021-09-01', '2026-09-01', 'Vigili del Fuoco');

SET FOREIGN_KEY_CHECKS = 1;

COMMIT;
