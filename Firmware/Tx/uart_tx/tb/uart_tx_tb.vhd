library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

entity uart_tx_tb is 
end entity; 

architecture sim of uart_tx_tb is 
    signal clk          : std_logic := '0';
    signal rst_n        : std_logic := '0';
    signal s_tick       : std_logic := '0'; 
    signal tx_start     : std_logic := '0';
    signal tx_din       : std_logic_vector(7 downto 0) := (others => '0');
    signal parity_mode  : std_logic_vector(1 downto 0);
    signal dsvr         : unsigned(15 downto 0) := (others => '0');
    signal tx           : std_logic;
    signal tx_done_tick : std_logic; 
    signal tx_busy      : std_logic;

    constant CLK_PERIOD : time := 20 ns; 

begin 

    -- Baud Gen
    baud: entity work.baud_gen
    port map(
        clk       => clk,
        rst_n     => rst_n,
        dsvr      => dsvr, 
        s_tick8x  => open,
        s_tick    => s_tick
    );

    -- UART TX
    tx_uut: entity work.uart_tx
    port map ( 
        clk          => clk,
        s_tick       => s_tick,
        rst_n        => rst_n,
        tx_start     => tx_start,
        tx_din       => tx_din, 
        parity_mode  => parity_mode,
        tx           => tx,
        tx_done_tick => tx_done_tick,
        tx_busy      => tx_busy 
    );

    -- Clock
    clk_process : process
    begin
        clk <= '0';  wait for CLK_PERIOD/2; 
        clk <= '1';  wait for CLK_PERIOD/2; 
    end process; 

    ----------------------------------------------------------------
    -- Stimulus
    ----------------------------------------------------------------
    stim : process
    begin 

        ----------------------------------------------------------------
        -- Reset system
        ----------------------------------------------------------------
        dsvr <= to_unsigned(651, 16);   -- default 9600 baud
        
        rst_n <= '1';   -- APPLY reset (active high)
        wait for 100 ns;
        rst_n <= '0';   -- RELEASE reset
        wait for 100 ns;

        ----------------------------------------------------------------
        -- TEST 1: Send byte without parity
        ----------------------------------------------------------------
        report "TEST 1: Sending byte without parity (mode = 00)";

        parity_mode <= "00"; 
        wait for 40 ns;          -- let parity_bit update

        tx_din <= "10101010";

        tx_start <= '1';
        wait until rising_edge(clk);
        tx_start <= '0';

        wait until rising_edge(tx_done_tick); 
        report "TEST 1: Done sending byte without parity";

        wait for 50 ns;  -- liten margin



        ----------------------------------------------------------------
        -- TEST 2: Send byte with parity
        ----------------------------------------------------------------
        report "TEST 2: Sending byte without parity (mode = 01) even";

        parity_mode <= "10"; 
        wait for 40 ns;          -- let parity_bit update

        tx_din <= "01010001";

        tx_start <= '1';
        wait until rising_edge(clk);
        tx_start <= '0';

        wait until rising_edge(tx_done_tick); 
        report "TEST 2: Done sending byte without parity";

        wait for 50 ns;  -- liten margin



        report "SIMULATION FINISHED" severity note; 
        std.env.stop; 
        wait;
    end process; 

end architecture sim;
