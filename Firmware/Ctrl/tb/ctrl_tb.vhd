library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ctrl_tb is
end entity;

architecture sim of ctrl_tb is

    -- DUT signals
    signal clk        : std_logic := '0';
    signal rst_n      : std_logic := '0';

    signal rx_din     : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_ready   : std_logic := '0';
    signal rx_ack     : std_logic;

    signal tx_busy    : std_logic := '0';
    signal tx_start   : std_logic;
    signal tx_data    : std_logic_vector(7 downto 0);

    signal sw_baud    : std_logic_vector(3 downto 0) := "0001";
    signal baud_value : unsigned(15 downto 0);

    signal key0       : std_logic := '0';  -- Send 8-tegns streng
    signal key1       : std_logic := '0';  -- Send ett tegn

    signal led_o      : std_logic;
    signal hex0       : std_logic_vector(6 downto 0);
    signal hex1       : std_logic_vector(6 downto 0);

begin

    
    -- 50 MHz clock (20 ns periode)
    
    clk <= not clk after 10 ns;

    
    -- DUT (ctrl-modulen)
    
    dut: entity work.ctrl
    port map(
        clk        => clk,
        rst_n      => rst_n,

        rx_din     => rx_din,
        rx_ready   => rx_ready,
        rx_ack     => rx_ack,

        tx_busy    => tx_busy,
        tx_start   => tx_start,
        tx_data    => tx_data,

        sw_baud    => sw_baud,
        baud_value => baud_value,

        key0       => key0,
        key1       => key1,

        led_o      => led_o,
        hex0       => hex0,
        hex1       => hex1
    );

    
    -- Stim. tx functionality
    
    stim_proc : process
    begin
        
        -- active high - reset
        
        rst_n <= '1';
        wait for 200 ns;
        rst_n <= '0';
        wait for 200 ns;

        
        -- Test 1: Loopback (rx to tx)
        
        rx_din   <= x"41";   -- 'A'
        rx_ready <= '1';
        wait for 20 ns;
        rx_ready <= '0';

        wait for 100 ns;

        -- Sim. transmittion busty periode
        tx_busy <= '1';
        wait for 300 ns;
        tx_busy <= '0';

        wait for 200 ns;

        ----------------------------------------------------------------
        -- TEST 2: KEY1 → Send ett tegn
        ----------------------------------------------------------------
        key1 <= '1';
        wait for 20 ns;
        key1 <= '0';

        -- Sim. TX busy while signs are sent
        wait for 100 ns;
        tx_busy <= '1';
        wait for 250 ns;
        tx_busy <= '0';

        wait for 200 ns;

        ----------------------------------------------------------------
        -- Test 3: send 8 strings
        ----------------------------------------------------------------
        key0 <= '1';
        wait for 20 ns;
        key0 <= '0';

        -- Sim. tx-busy between each send char
        for i in 0 to 7 loop
            wait for 100 ns;
            tx_busy <= '1';
            wait for 200 ns;
            tx_busy <= '0';
        end loop;

        wait for 500 ns;

        
        -- end
        
        report "Testbench ferdig";
        std.env.stop;
        wait;
        
    end process;

end architecture sim;
