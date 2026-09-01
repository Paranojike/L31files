-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Aug 20, 2026 at 04:09 PM
-- Server version: 8.4.3
-- PHP Version: 8.3.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `gestione_anticendio`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `NuovoIntervento` (IN `p_presidio` INT, IN `p_tecnico` INT, IN `p_tipo` VARCHAR(50), IN `p_esito` VARCHAR(20), IN `p_note` TEXT)   BEGIN
    INSERT INTO intervento (presidio, tecnico, data_intervento, tipo_intervento, esito, note)
    VALUES (p_presidio, p_tecnico, CURDATE(), p_tipo, p_esito, p_note);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `RegistraAnomalia` (IN `p_intervento` INT, IN `p_descrizione` TEXT, IN `p_gravita` VARCHAR(20), IN `p_data` DATE)   BEGIN
    INSERT INTO anomalia (intervento, descrizione, gravita, stato, data_rilevazione)
    VALUES (p_intervento, p_descrizione, p_gravita, 'Aperta', p_data);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ReportCertificazioniScadenza` (IN `p_giorni` INT)   BEGIN
    SELECT * FROM vista_certificazioni_scadenza WHERE giorni_mancanti <= p_giorni;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ReportEdificio` (IN `p_id_edificio` INT)   BEGIN
    SELECT * FROM vista_riepilogo_edifici WHERE id_edificio = p_id_edificio;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ReportScadenze` (IN `p_giorni` INT)   BEGIN
    SELECT * FROM vista_presidi_scadenza WHERE giorni_mancanti <= p_giorni;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `anomalia`
--

CREATE TABLE `anomalia` (
  `id_anomalia` int NOT NULL,
  `intervento` int NOT NULL,
  `descrizione` text NOT NULL,
  `gravita` enum('Bassa','Media','Alta','Critica') NOT NULL,
  `stato` enum('Aperta','In lavorazione','Verificata','Chiusa') NOT NULL DEFAULT 'Aperta',
  `data_rilevazione` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `anomalia`
--

INSERT INTO `anomalia` (`id_anomalia`, `intervento`, `descrizione`, `gravita`, `stato`, `data_rilevazione`) VALUES
(1, 2, 'Lieve perdita di pressione e tubo con abrasioni.', 'Media', 'In lavorazione', '2024-03-11'),
(2, 3, 'Scheda logica andata, rischio corto circuito.', 'Critica', 'Aperta', '2023-11-10');

--
-- Triggers `anomalia`
--
DELIMITER $$
CREATE TRIGGER `allarme_anomalia_critica` AFTER INSERT ON `anomalia` FOR EACH ROW BEGIN
    DECLARE v_id_presidio INT;
    SELECT presidio INTO v_id_presidio FROM intervento WHERE id_intervento = NEW.intervento;
    IF NEW.gravita IN ('Alta', 'Critica') THEN
        UPDATE presidio SET stato = 'Guasto' WHERE id_presidio = v_id_presidio;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `check_data_rilevazione_anomalia` BEFORE INSERT ON `anomalia` FOR EACH ROW BEGIN
    DECLARE v_data_intervento DATE;
    SELECT data_intervento INTO v_data_intervento FROM intervento WHERE id_intervento = NEW.intervento;
    IF NEW.data_rilevazione < v_data_intervento THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Errore: La data di rilevazione della anomalia deve essere uguale o successiva alla data di intervento.';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `certificazione`
--

CREATE TABLE `certificazione` (
  `id_certificazione` int NOT NULL,
  `edificio` int NOT NULL,
  `tipo` varchar(50) NOT NULL,
  `data_rilascio` date NOT NULL,
  `data_scadenza` date NOT NULL,
  `ente_certificatore` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `certificazione`
--

INSERT INTO `certificazione` (`id_certificazione`, `edificio`, `tipo`, `data_rilascio`, `data_scadenza`, `ente_certificatore`) VALUES
(1, 1, 'Prevenzione Incendi', '2024-01-10', '2029-01-10', 'Vigili del Fuoco'),
(2, 2, 'Prevenzione Incendi', '2023-11-18', '2028-11-18', 'Vigili del Fuoco'),
(3, 3, 'Conformità Antincendio', '2025-02-05', '2030-02-05', 'Ente Certificatore Italia'),
(4, 4, 'Prevenzione Incendi', '2024-06-15', '2029-06-15', 'Vigili del Fuoco'),
(5, 5, 'Conformità Antincendio', '2021-05-10', '2026-05-10', 'Vigili del Fuoco'),
(6, 6, 'Prevenzione Incendi', '2021-09-01', '2026-09-01', 'Vigili del Fuoco');

--
-- Triggers `certificazione`
--
DELIMITER $$
CREATE TRIGGER `check_date_certificazione` BEFORE INSERT ON `certificazione` FOR EACH ROW BEGIN
    IF NEW.data_scadenza <= NEW.data_rilascio THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Errore: La data di scadenza deve essere successiva alla data di rilascio.';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `edificio`
--

CREATE TABLE `edificio` (
  `id_edificio` int NOT NULL,
  `unita` int NOT NULL,
  `nome` varchar(100) NOT NULL,
  `indirizzo` varchar(100) NOT NULL,
  `citta` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `edificio`
--

INSERT INTO `edificio` (`id_edificio`, `unita`, `nome`, `indirizzo`, `citta`) VALUES
(1, 1, 'Palazzina Uffici', 'Via Roma 12', 'Catania'),
(2, 2, 'Stabilimento Nord', 'Via Etnea 35', 'Catania'),
(3, 3, 'Magazzino Centrale', 'Via Palermo 91', 'Catania'),
(4, 4, 'Laboratorio Chimico', 'Via Milano 22', 'Catania'),
(5, 5, 'Centro Qualità', 'Via Firenze 9', 'Acireale'),
(6, 6, 'Officina Tecnica', 'Via Messina 41', 'Acireale');

-- --------------------------------------------------------

--
-- Table structure for table `intervento`
--

CREATE TABLE `intervento` (
  `id_intervento` int NOT NULL,
  `presidio` int NOT NULL,
  `tecnico` int NOT NULL,
  `data_intervento` date NOT NULL,
  `tipo_intervento` enum('Controllo periodico','Manutenzione straordinaria','Collaudo','Sostituzione','Riparazione') NOT NULL,
  `esito` enum('Positivo','Negativo','Da verificare') NOT NULL DEFAULT 'Da verificare',
  `note` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `intervento`
--

INSERT INTO `intervento` (`id_intervento`, `presidio`, `tecnico`, `data_intervento`, `tipo_intervento`, `esito`, `note`) VALUES
(1, 1, 1, '2024-07-05', 'Controllo periodico', 'Positivo', 'Pressione regolare, nessun difetto.'),
(2, 2, 2, '2024-03-10', 'Controllo periodico', 'Da verificare', 'Tubo usurato, necessita controllo approfondito.'),
(3, 4, 3, '2023-11-10', 'Manutenzione straordinaria', 'Negativo', 'Scheda logica bruciata, impossibile ripristinare sul posto.');

--
-- Triggers `intervento`
--
DELIMITER $$
CREATE TRIGGER `check_data_intervento_installazione` BEFORE INSERT ON `intervento` FOR EACH ROW BEGIN
    DECLARE v_data_installazione DATE;
    SELECT data_installazione INTO v_data_installazione FROM presidio WHERE id_presidio = NEW.presidio;
    IF NEW.data_intervento < v_data_installazione THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Errore: La data intervento non può essere antecedente alla data di installazione del presidio.';
    END IF;
    IF NEW.data_intervento > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Errore: La data intervento non può essere nel futuro.';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `gestisci_presidio_dopo_intervento` AFTER INSERT ON `intervento` FOR EACH ROW BEGIN
    DECLARE v_nuovo_stato VARCHAR(50);

    IF NEW.esito = 'Positivo' THEN 
        SET v_nuovo_stato = 'Operativo';
    ELSEIF NEW.esito = 'Da verificare' THEN 
        SET v_nuovo_stato = 'Da revisionare';
    ELSEIF NEW.esito = 'Negativo' THEN 
        SET v_nuovo_stato = 'Guasto';
    ELSE
        SET v_nuovo_stato = 'Operativo';
    END IF;

    UPDATE presidio 
    SET stato = v_nuovo_stato 
    WHERE id_presidio = NEW.presidio;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `planimetria`
--

CREATE TABLE `planimetria` (
  `id_planimetria` int NOT NULL,
  `edificio` int NOT NULL,
  `piano` int NOT NULL,
  `file` varchar(100) DEFAULT NULL,
  `data_aggiornamento` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `planimetria`
--

INSERT INTO `planimetria` (`id_planimetria`, `edificio`, `piano`, `file`, `data_aggiornamento`) VALUES
(1, 1, 0, 'uffici_pt.pdf', '2026-01-10'),
(2, 1, 1, 'uffici_p1.pdf', '2026-01-10'),
(3, 2, 0, 'stabilimento_pt.pdf', '2026-02-18'),
(4, 2, 1, 'stabilimento_p1.pdf', '2026-02-18'),
(5, 3, 0, 'magazzino.pdf', '2026-03-05'),
(6, 4, 0, 'laboratorio.pdf', '2026-04-02');

-- --------------------------------------------------------

--
-- Table structure for table `presidio`
--

CREATE TABLE `presidio` (
  `id_presidio` int NOT NULL,
  `planimetria` int NOT NULL,
  `tipologia` enum('Estintore','Idrante','Rilevatore di fumo','Centrale antincendio') NOT NULL,
  `matricola` varchar(50) NOT NULL,
  `ubicazione` varchar(100) DEFAULT NULL,
  `data_installazione` date NOT NULL,
  `data_scadenza_controllo` date NOT NULL,
  `stato` enum('Operativo','Da revisionare','Guasto','Da sostituire') DEFAULT 'Operativo'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `presidio`
--

INSERT INTO `presidio` (`id_presidio`, `planimetria`, `tipologia`, `matricola`, `ubicazione`, `data_installazione`, `data_scadenza_controllo`, `stato`) VALUES
(1, 1, 'Estintore', 'EST-001', 'Corridoio Piano Terra', '2024-01-10', '2025-01-10', 'Operativo'),
(2, 3, 'Idrante', 'IDR-102', 'Ingresso Magazzino', '2022-03-15', '2024-03-15', 'Da revisionare'),
(3, 4, 'Rilevatore di fumo', 'RIL-045', 'Laboratorio Chimico Est', '2023-06-20', '2026-06-20', 'Operativo'),
(4, 2, 'Centrale antincendio', 'CEN-999', 'Sala Server', '2020-11-05', '2022-11-05', 'Guasto');

--
-- Triggers `presidio`
--
DELIMITER $$
CREATE TRIGGER `check_date_presidio` BEFORE INSERT ON `presidio` FOR EACH ROW BEGIN
    IF NEW.data_scadenza_controllo <= NEW.data_installazione THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Errore: La data di scadenza del controllo deve essere successiva alla data di installazione.';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `tecnico`
--

CREATE TABLE `tecnico` (
  `id_tecnico` int NOT NULL,
  `nome` varchar(50) NOT NULL,
  `cognome` varchar(50) NOT NULL,
  `telefono` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `tecnico`
--

INSERT INTO `tecnico` (`id_tecnico`, `nome`, `cognome`, `telefono`) VALUES
(1, 'Andrea', 'Russo', '3331111111'),
(2, 'Matteo', 'Greco', '3331111112'),
(3, 'Davide', 'Caruso', '3331111113'),
(4, 'Simone', 'Vitale', '3331111114'),
(5, 'Francesco', 'Messina', '3331111115'),
(6, 'Alessio', 'Rizzo', '3331111116');

-- --------------------------------------------------------

--
-- Table structure for table `unita_organizzativa`
--

CREATE TABLE `unita_organizzativa` (
  `id_unita` int NOT NULL,
  `nome` varchar(100) NOT NULL,
  `responsabile` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `unita_organizzativa`
--

INSERT INTO `unita_organizzativa` (`id_unita`, `nome`, `responsabile`) VALUES
(1, 'Amministrazione', 'Mario Rossi'),
(2, 'Produzione', 'Luca Bianchi'),
(3, 'Magazzino', 'Anna Verdi'),
(4, 'Ricerca e Sviluppo', 'Giulia Neri'),
(5, 'Qualità', 'Marco Gallo'),
(6, 'Manutenzione', 'Paolo Ferri');

-- --------------------------------------------------------

--
-- Stand-in structure for view `vista_anomalie_aperte`
-- (See below for the actual view)
--
CREATE TABLE `vista_anomalie_aperte` (
`data_rilevazione` date
,`descrizione` text
,`edificio` varchar(100)
,`gravita` enum('Bassa','Media','Alta','Critica')
,`id_anomalia` int
,`id_presidio` int
,`matricola` varchar(50)
,`tecnico` varchar(101)
,`tipologia` enum('Estintore','Idrante','Rilevatore di fumo','Centrale antincendio')
,`ubicazione` varchar(100)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vista_certificazioni_scadenza`
-- (See below for the actual view)
--
CREATE TABLE `vista_certificazioni_scadenza` (
`data_rilascio` date
,`data_scadenza` date
,`edificio` varchar(100)
,`ente_certificatore` varchar(100)
,`giorni_mancanti` int
,`id_certificazione` int
,`stato_scadenza` varchar(19)
,`tipo` varchar(50)
,`unita_organizzativa` varchar(100)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vista_presidi_edificio`
-- (See below for the actual view)
--
CREATE TABLE `vista_presidi_edificio` (
`citta` varchar(100)
,`data_installazione` date
,`data_scadenza_controllo` date
,`edificio` varchar(100)
,`giorni_scadenza` int
,`id_presidio` int
,`matricola` varchar(50)
,`stato` enum('Operativo','Da revisionare','Guasto','Da sostituire')
,`tipologia` enum('Estintore','Idrante','Rilevatore di fumo','Centrale antincendio')
,`ubicazione` varchar(100)
,`unita_organizzativa` varchar(100)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vista_presidi_scadenza`
-- (See below for the actual view)
--
CREATE TABLE `vista_presidi_scadenza` (
`data_scadenza_controllo` date
,`edificio` varchar(100)
,`giorni_mancanti` int
,`id_presidio` int
,`matricola` varchar(50)
,`tipologia` enum('Estintore','Idrante','Rilevatore di fumo','Centrale antincendio')
,`ubicazione` varchar(100)
,`unita_organizzativa` varchar(100)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vista_riepilogo_edifici`
-- (See below for the actual view)
--
CREATE TABLE `vista_riepilogo_edifici` (
`anomalie_aperte` bigint
,`certificazioni` bigint
,`da_revisionare` bigint
,`da_sostituire` bigint
,`edificio` varchar(100)
,`guasti` bigint
,`id_edificio` int
,`operativi` bigint
,`scaduti` bigint
,`totale_presidi` bigint
,`unita_organizzativa` varchar(100)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vista_storico_interventi`
-- (See below for the actual view)
--
CREATE TABLE `vista_storico_interventi` (
`data_intervento` date
,`edificio` varchar(100)
,`esito` enum('Positivo','Negativo','Da verificare')
,`id_intervento` int
,`id_presidio` int
,`matricola` varchar(50)
,`note` text
,`tecnico` varchar(101)
,`tipo_intervento` enum('Controllo periodico','Manutenzione straordinaria','Collaudo','Sostituzione','Riparazione')
,`tipologia` enum('Estintore','Idrante','Rilevatore di fumo','Centrale antincendio')
,`ubicazione` varchar(100)
);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `anomalia`
--
ALTER TABLE `anomalia`
  ADD PRIMARY KEY (`id_anomalia`),
  ADD KEY `fk_intervento` (`intervento`),
  ADD KEY `idx_stato_anomalia` (`stato`);

--
-- Indexes for table `certificazione`
--
ALTER TABLE `certificazione`
  ADD PRIMARY KEY (`id_certificazione`),
  ADD KEY `fk_certificazione_edificio` (`edificio`),
  ADD KEY `idx_scadenza_certificazione` (`data_scadenza`);

--
-- Indexes for table `edificio`
--
ALTER TABLE `edificio`
  ADD PRIMARY KEY (`id_edificio`),
  ADD KEY `fk_unitaorganizzativa` (`unita`);

--
-- Indexes for table `intervento`
--
ALTER TABLE `intervento`
  ADD PRIMARY KEY (`id_intervento`),
  ADD KEY `fk_presidio` (`presidio`),
  ADD KEY `fk_tecnico` (`tecnico`),
  ADD KEY `idx_data_intervento` (`data_intervento`);

--
-- Indexes for table `planimetria`
--
ALTER TABLE `planimetria`
  ADD PRIMARY KEY (`id_planimetria`),
  ADD UNIQUE KEY `idx_edificio_piano` (`edificio`,`piano`),
  ADD KEY `fk_edificio` (`edificio`);

--
-- Indexes for table `presidio`
--
ALTER TABLE `presidio`
  ADD PRIMARY KEY (`id_presidio`),
  ADD UNIQUE KEY `uq_presidio_matricola` (`matricola`),
  ADD KEY `fk_presidio_planimetria` (`planimetria`),
  ADD KEY `idx_scadenza_presidio` (`data_scadenza_controllo`);

--
-- Indexes for table `tecnico`
--
ALTER TABLE `tecnico`
  ADD PRIMARY KEY (`id_tecnico`);

--
-- Indexes for table `unita_organizzativa`
--
ALTER TABLE `unita_organizzativa`
  ADD PRIMARY KEY (`id_unita`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `anomalia`
--
ALTER TABLE `anomalia`
  MODIFY `id_anomalia` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `certificazione`
--
ALTER TABLE `certificazione`
  MODIFY `id_certificazione` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `edificio`
--
ALTER TABLE `edificio`
  MODIFY `id_edificio` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `intervento`
--
ALTER TABLE `intervento`
  MODIFY `id_intervento` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `planimetria`
--
ALTER TABLE `planimetria`
  MODIFY `id_planimetria` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `presidio`
--
ALTER TABLE `presidio`
  MODIFY `id_presidio` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `tecnico`
--
ALTER TABLE `tecnico`
  MODIFY `id_tecnico` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `unita_organizzativa`
--
ALTER TABLE `unita_organizzativa`
  MODIFY `id_unita` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

-- --------------------------------------------------------

--
-- Structure for view `vista_anomalie_aperte`
--
DROP TABLE IF EXISTS `vista_anomalie_aperte`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_anomalie_aperte`  AS SELECT `a`.`id_anomalia` AS `id_anomalia`, `a`.`descrizione` AS `descrizione`, `a`.`gravita` AS `gravita`, `a`.`data_rilevazione` AS `data_rilevazione`, `p`.`id_presidio` AS `id_presidio`, `p`.`tipologia` AS `tipologia`, `p`.`matricola` AS `matricola`, `p`.`ubicazione` AS `ubicazione`, `e`.`nome` AS `edificio`, concat(`t`.`nome`,' ',`t`.`cognome`) AS `tecnico` FROM (((((`anomalia` `a` join `intervento` `i` on((`a`.`intervento` = `i`.`id_intervento`))) join `presidio` `p` on((`i`.`presidio` = `p`.`id_presidio`))) join `planimetria` `pl` on((`p`.`planimetria` = `pl`.`id_planimetria`))) join `edificio` `e` on((`pl`.`edificio` = `e`.`id_edificio`))) join `tecnico` `t` on((`i`.`tecnico` = `t`.`id_tecnico`))) WHERE (`a`.`stato` = 'Aperta') ORDER BY field(`a`.`gravita`,'Critica','Alta','Media','Bassa') ASC ;

-- --------------------------------------------------------

--
-- Structure for view `vista_certificazioni_scadenza`
--
DROP TABLE IF EXISTS `vista_certificazioni_scadenza`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_certificazioni_scadenza`  AS SELECT `c`.`id_certificazione` AS `id_certificazione`, `c`.`tipo` AS `tipo`, `c`.`data_rilascio` AS `data_rilascio`, `c`.`data_scadenza` AS `data_scadenza`, `c`.`ente_certificatore` AS `ente_certificatore`, `e`.`nome` AS `edificio`, `u`.`nome` AS `unita_organizzativa`, (to_days(`c`.`data_scadenza`) - to_days(curdate())) AS `giorni_mancanti`, (case when (`c`.`data_scadenza` < curdate()) then 'SCADUTA' when (`c`.`data_scadenza` between curdate() and (curdate() + interval 30 day)) then 'IN SCADENZA (30 gg)' when (`c`.`data_scadenza` between curdate() and (curdate() + interval 90 day)) then 'IN SCADENZA (90 gg)' else 'VALIDA' end) AS `stato_scadenza` FROM ((`certificazione` `c` join `edificio` `e` on((`c`.`edificio` = `e`.`id_edificio`))) join `unita_organizzativa` `u` on((`e`.`unita` = `u`.`id_unita`))) ;

-- --------------------------------------------------------

--
-- Structure for view `vista_presidi_edificio`
--
DROP TABLE IF EXISTS `vista_presidi_edificio`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_presidi_edificio`  AS SELECT `p`.`id_presidio` AS `id_presidio`, `p`.`tipologia` AS `tipologia`, `p`.`matricola` AS `matricola`, `p`.`ubicazione` AS `ubicazione`, `p`.`data_installazione` AS `data_installazione`, `p`.`data_scadenza_controllo` AS `data_scadenza_controllo`, `p`.`stato` AS `stato`, `e`.`nome` AS `edificio`, `e`.`citta` AS `citta`, `u`.`nome` AS `unita_organizzativa`, (to_days(`p`.`data_scadenza_controllo`) - to_days(curdate())) AS `giorni_scadenza` FROM (((`presidio` `p` join `planimetria` `pl` on((`p`.`planimetria` = `pl`.`id_planimetria`))) join `edificio` `e` on((`pl`.`edificio` = `e`.`id_edificio`))) join `unita_organizzativa` `u` on((`e`.`unita` = `u`.`id_unita`))) ORDER BY `e`.`nome` ASC, `p`.`ubicazione` ASC ;

-- --------------------------------------------------------

--
-- Structure for view `vista_presidi_scadenza`
--
DROP TABLE IF EXISTS `vista_presidi_scadenza`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_presidi_scadenza`  AS SELECT `p`.`id_presidio` AS `id_presidio`, `p`.`tipologia` AS `tipologia`, `p`.`matricola` AS `matricola`, `p`.`ubicazione` AS `ubicazione`, `p`.`data_scadenza_controllo` AS `data_scadenza_controllo`, `e`.`nome` AS `edificio`, `u`.`nome` AS `unita_organizzativa`, (to_days(`p`.`data_scadenza_controllo`) - to_days(curdate())) AS `giorni_mancanti` FROM (((`presidio` `p` join `planimetria` `pl` on((`p`.`planimetria` = `pl`.`id_planimetria`))) join `edificio` `e` on((`pl`.`edificio` = `e`.`id_edificio`))) join `unita_organizzativa` `u` on((`e`.`unita` = `u`.`id_unita`))) ORDER BY `p`.`data_scadenza_controllo` ASC ;

-- --------------------------------------------------------

--
-- Structure for view `vista_riepilogo_edifici`
--
DROP TABLE IF EXISTS `vista_riepilogo_edifici`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_riepilogo_edifici`  AS SELECT `e`.`id_edificio` AS `id_edificio`, `e`.`nome` AS `edificio`, `u`.`nome` AS `unita_organizzativa`, count(distinct `p`.`id_presidio`) AS `totale_presidi`, count(distinct (case when (`p`.`stato` = 'Operativo') then `p`.`id_presidio` end)) AS `operativi`, count(distinct (case when (`p`.`stato` = 'Guasto') then `p`.`id_presidio` end)) AS `guasti`, count(distinct (case when (`p`.`stato` = 'Da revisionare') then `p`.`id_presidio` end)) AS `da_revisionare`, count(distinct (case when (`p`.`stato` = 'Da sostituire') then `p`.`id_presidio` end)) AS `da_sostituire`, count(distinct (case when (`p`.`data_scadenza_controllo` < curdate()) then `p`.`id_presidio` end)) AS `scaduti`, count(distinct `a`.`id_anomalia`) AS `anomalie_aperte`, count(distinct `c`.`id_certificazione`) AS `certificazioni` FROM ((((((`edificio` `e` join `unita_organizzativa` `u` on((`e`.`unita` = `u`.`id_unita`))) left join `planimetria` `pl` on((`e`.`id_edificio` = `pl`.`edificio`))) left join `presidio` `p` on((`pl`.`id_planimetria` = `p`.`planimetria`))) left join `intervento` `i` on((`p`.`id_presidio` = `i`.`presidio`))) left join `anomalia` `a` on(((`i`.`id_intervento` = `a`.`intervento`) and (`a`.`stato` = 'Aperta')))) left join `certificazione` `c` on((`e`.`id_edificio` = `c`.`edificio`))) GROUP BY `e`.`id_edificio`, `e`.`nome`, `u`.`nome` ;

-- --------------------------------------------------------

--
-- Structure for view `vista_storico_interventi`
--
DROP TABLE IF EXISTS `vista_storico_interventi`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_storico_interventi`  AS SELECT `i`.`id_intervento` AS `id_intervento`, `i`.`data_intervento` AS `data_intervento`, `i`.`tipo_intervento` AS `tipo_intervento`, `i`.`esito` AS `esito`, `i`.`note` AS `note`, `p`.`id_presidio` AS `id_presidio`, `p`.`tipologia` AS `tipologia`, `p`.`matricola` AS `matricola`, `p`.`ubicazione` AS `ubicazione`, concat(`t`.`nome`,' ',`t`.`cognome`) AS `tecnico`, `e`.`nome` AS `edificio` FROM ((((`intervento` `i` join `presidio` `p` on((`i`.`presidio` = `p`.`id_presidio`))) join `planimetria` `pl` on((`p`.`planimetria` = `pl`.`id_planimetria`))) join `edificio` `e` on((`pl`.`edificio` = `e`.`id_edificio`))) join `tecnico` `t` on((`i`.`tecnico` = `t`.`id_tecnico`))) ORDER BY `i`.`data_intervento` ASC ;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `anomalia`
--
ALTER TABLE `anomalia`
  ADD CONSTRAINT `fk_anomalia_intervento` FOREIGN KEY (`intervento`) REFERENCES `intervento` (`id_intervento`);

--
-- Constraints for table `certificazione`
--
ALTER TABLE `certificazione`
  ADD CONSTRAINT `fk_certificazione_edificio` FOREIGN KEY (`edificio`) REFERENCES `edificio` (`id_edificio`);

--
-- Constraints for table `edificio`
--
ALTER TABLE `edificio`
  ADD CONSTRAINT `fk_edificio_unita` FOREIGN KEY (`unita`) REFERENCES `unita_organizzativa` (`id_unita`);

--
-- Constraints for table `intervento`
--
ALTER TABLE `intervento`
  ADD CONSTRAINT `fk_intervento_presidio` FOREIGN KEY (`presidio`) REFERENCES `presidio` (`id_presidio`),
  ADD CONSTRAINT `fk_intervento_tecnico` FOREIGN KEY (`tecnico`) REFERENCES `tecnico` (`id_tecnico`);

--
-- Constraints for table `planimetria`
--
ALTER TABLE `planimetria`
  ADD CONSTRAINT `fk_planimetria_edificio` FOREIGN KEY (`edificio`) REFERENCES `edificio` (`id_edificio`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Constraints for table `presidio`
--
ALTER TABLE `presidio`
  ADD CONSTRAINT `fk_presidio_planimetria` FOREIGN KEY (`planimetria`) REFERENCES `planimetria` (`id_planimetria`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
