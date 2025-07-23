CREATE TABLE IF NOT EXISTS `plug_sales_log` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `item_name` VARCHAR(100) NOT NULL,
    `amount` INT NOT NULL,
    `total_price` INT NOT NULL,
    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_timestamp` (`timestamp`)
);
