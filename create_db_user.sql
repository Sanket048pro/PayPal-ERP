-- Run as MySQL root after schema.sql. Set the password yourself.
CREATE USER IF NOT EXISTS 'Sanket048pro'@'127.0.0.1' IDENTIFIED BY '<set-locally>' REQUIRE SSL;
GRANT SELECT,INSERT,UPDATE,DELETE,EXECUTE ON PayPal_ERP.* TO 'Sanket048pro'@'127.0.0.1';
FLUSH PRIVILEGES;
