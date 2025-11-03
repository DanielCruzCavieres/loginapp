-- Script de base de datos para My Construction
CREATE DATABASE IF NOT EXISTS myconstruction CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE myconstruction;

CREATE TABLE IF NOT EXISTS usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password VARCHAR(100) NOT NULL
);

INSERT INTO usuarios (username, password) VALUES ('admin', '1234');
