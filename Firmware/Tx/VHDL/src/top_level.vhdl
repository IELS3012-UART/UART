library ieee;
use ieee.std_logic_1164.all; 

--============================================================
-- Module Name: uart_tx
-- Author: Yamn S. Salim
-- Project: IELS3012 - UART Module (TX)
-- Descirption: 

--    UART Transmitter Tx module
--    Converts an 8-bit parallel input into a serial UART Frame
--    1 start bot, 8 data bits (LSB first), 1 stop bit
--    Transmission is started by asserting tx_start. 
--============================================================


entity uart_tx is
    port (
        clk         : in std_logic;                       -- System Clock (50MHz)
        rst         : in std_logic;                       -- Active-high syncronous reset
        tx_start    : in std_logic;                       -- Start transmission pulse (1 clk cycle)
        tx_data     : in std_logic_vector(7 downto 0);    -- 8-bit parallel data input to be transmitted
        tx_busy     : out std_logic;                      -- High while transmission is in process
        tx_line     : out std_logic                       -- UART seriel output line (idle = '1')
    );
end entity;
