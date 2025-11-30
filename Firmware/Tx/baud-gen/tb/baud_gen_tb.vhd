library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all; 

entity baud_gen_tb is 
end entity baud_gen_tb; 

architecture sim of baud_gen_tb is 

    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0'; 
    signal dsvr : unsigned(15 downto 0) := (others => '0'); 
    signal s_tick8x : std_logic; 
    signal s_tick : std_logic; 

    constant CLK_PERIOD : time := 20 ns; 

begin 
    uut: entity work.baud_gen
    port map( 
        clk => clk,
        rst_n => rst_n, 
        dsvr => dsvr,
        s_tick8x => s_tick8x,
        s_tick => s_tick
    ); 

    clk_process : process
    begin
        clk <= '0'; 
        wait for CLK_PERIOD/2; 
        clk <= '1'; 
        wait for CLK_PERIOD/2;
    end process; 


    stim_proc : process
    begin 

        -- Reset 
        rst_n <= '1'; 
        wait for 100 ns; 
        rst_n <= '0'; 
        wait for 100 ns; 

        -- Baud Rate 9600
        dsvr <= to_unsigned(651, 16); 
        wait for 200 us;

        -- Baud rate 19200
        dsvr <= to_unsigned(326, 16); 
        wait for 400 us; 

        -- Baud rate 28800
        dsvr <= to_unsigned(217,16); 
        wait for 1 ms; 

        report "Simulation finished" severity note; 
        std.env.stop; 
        wait; 
    end process; 
end architecture sim; 
