library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tx_core_tb is
end entity;

architecture tb of tx_core_tb is

    -- DUT (Device Under Test) component declaration
    component tx_core
        port (
            clk           : in  std_logic;
            rst_n         : in  std_logic;
            tx_start      : in  std_logic;
            d_in          : in  std_logic_vector(7 downto 0);
            s_tick        : in  std_logic;
            tx            : out std_logic;
            tx_done_tick  : out std_logic;
            tx_busy       : out std_logic
        );
    end component;

    -- Signals to connect to DUT
    signal clk           : std_logic := '0';
    signal rst_n         : std_logic := '0';
    signal tx_start      : std_logic := '0';
    signal d_in          : std_logic_vector(7 downto 0) := (others => '0');
    signal s_tick        : std_logic := '0';
    signal tx            : std_logic;
    signal tx_done_tick  : std_logic;
    signal tx_busy       : std_logic;

    -- Timing constants
    constant CLK_PERIOD  : time := 20 ns;  -- 50 MHz clock
    constant BAUD_TICK   : time := 160 ns; -- arbitrary tick rate (for testing)

begin

    ----------------------------------------------------------
    -- Instantiate the UART Transmitter (Device Under Test)
    ----------------------------------------------------------
    DUT: tx_core
        port map (
            clk           => clk,
            rst_n         => rst_n,
            tx_start      => tx_start,
            d_in          => d_in,
            s_tick        => s_tick,
            tx            => tx,
            tx_done_tick  => tx_done_tick,
            tx_busy       => tx_busy
        );

    ----------------------------------------------------------
    -- Clock generation (50 MHz)
    ----------------------------------------------------------
    clk_process: process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    ----------------------------------------------------------
    -- Baud tick generation
    ----------------------------------------------------------
    tick_process: process
    begin
        while true loop
            s_tick <= '1';
            wait for BAUD_TICK / 10;  -- short pulse
            s_tick <= '0';
            wait for BAUD_TICK;
        end loop;
    end process;

    ----------------------------------------------------------
    -- Stimulus process
    ----------------------------------------------------------
    stim_proc: process
    begin
        -- Hold reset for a few cycles
        rst_n <= '0';
        wait for 100 ns;
        rst_n <= '1';
        wait for 100 ns;
        rst_n <= '1';

        -- Load data and trigger transmission
        d_in <= "10101010";   -- example data byte (0xAA)
        tx_start <= '1';
        wait for CLK_PERIOD;
        tx_start <= '0';

        -- Wait for transmission to complete
        wait until tx_done_tick = '1';
        wait for 500 ns;

        -- Send another byte to test re-triggering
        d_in <= "11001100";   -- example data byte (0xCC)
        tx_start <= '1';
        wait for CLK_PERIOD;
        tx_start <= '0';

        wait until tx_done_tick = '1';
        wait for 500 ns;

        -- End simulation
        wait;
    end process;

end architecture;
