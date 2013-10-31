CREATE TABLE `event` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `createdAt` datetime NOT NULL,
  `code` varchar(11) NOT NULL DEFAULT '',
  `name` varchar(256) NOT NULL DEFAULT '',
  `info` varchar(256) NOT NULL DEFAULT '',
  `place` varchar(256) NOT NULL DEFAULT '',
  `address` varchar(256) NOT NULL DEFAULT '',
  `latitude` float NOT NULL,
  `longitude` float NOT NULL,
  `date` date NOT NULL,
  `creatorId` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `creator` (`creatorId`)
) ENGINE=MyISAM AUTO_INCREMENT=32 DEFAULT CHARSET=utf8;

CREATE TABLE `user` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `createdAt` date NOT NULL,
  `updatedAt` date NOT NULL,
  `name` varchar(256) NOT NULL DEFAULT '',
  `phone` varchar(256) NOT NULL DEFAULT '',
  `eventId` int(11) NOT NULL,
  `latitude` float NOT NULL,
  `longitude` float NOT NULL,
  PRIMARY KEY (`id`),
  KEY `event` (`eventId`)
) ENGINE=MyISAM AUTO_INCREMENT=53 DEFAULT CHARSET=utf8;
