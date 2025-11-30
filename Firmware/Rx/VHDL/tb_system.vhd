library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_system is
end entity;

architecture sim of tb_system is

    --------------------------------------------------------------------
    -- Clock
    --------------------------------------------------------------------
    constant CLK_PERIOD : time := 20 ns;
    signal clk : std_logic := '0';

    --------------------------------------------------------------------
    -- Reset
    --------------------------------------------------------------------
    signal reset : std_logic := '1';

    --------------------------------------------------------------------
    -- UART signals
    --------------------------------------------------------------------
    signal rx_i        : std_logic := '1';
    signal rx_ready    : std_logic;
    signal rx_ack      : std_logic;
    signal rx_data     : std_logic_vector(7 downto 0);

    signal tx_busy     : std_logic := '0';
    signal tx_start    : std_logic;
    signal tx_data     : std_logic_vector(7 downto 0);

    --------------------------------------------------------------------
    -- Baudgen signals
    --------------------------------------------------------------------
    signal s_tick8x    : std_logic;
    signal s_tick      : std_logic;
    signal baud_value  : unsigned(15 downto 0);

    --------------------------------------------------------------------
    -- CTRL outputs
    --------------------------------------------------------------------
    signal led_o       : std_logic;
    signal hex0        : std_logic_vector(6 downto 0);
    signal hex1        : std_logic_vector(6 downto 0);

    --------------------------------------------------------------------
    -- Switches and keys
    --------------------------------------------------------------------
    signal sw_baud     : std_logic_vector(3 downto 0) := "0001";
    signal key0        : std_logic := '0';
    signal key1        : std_logic := '0';

begin

    --------------------------------------------------------------------
    -- Clock generator
    --------------------------------------------------------------------
    clk <= not clk after CLK_PERIOD/2;

    --------------------------------------------------------------------
    -- Reset
    --------------------------------------------------------------------
    process
    begin
        reset <= '1';
        wait for 200 ns;
        reset <= '0';
        wait;
    end process;

    --------------------------------------------------------------------
    -- Baud generator
    --------------------------------------------------------------------
    baud_inst : entity work.baud_gen
        port map (
            clk      => clk,
            rst_n    => reset,
            dsvr     => baud_value,
            s_tick8x => s_tick8x,
            s_tick   => s_tick
        );

    --------------------------------------------------------------------
    -- UART RX
    --------------------------------------------------------------------
    rx_inst : entity work.uartRX
        port map (
            clk         => clk,
            reset       => reset,
            rx_i        => rx_i,
            sample_tick => s_tick8x,
            data_o      => rx_data,
            data_ready  => rx_ready,
            data_ack    => rx_ack
        );

    --------------------------------------------------------------------
    -- CTRL
    --------------------------------------------------------------------
    ctrl_inst : entity work.ctrl
        port map (
            clk        => clk,
            rst_n      => reset,

            rx_din     => rx_data,
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

    --------------------------------------------------------------------
    -- Stimuli process
    --------------------------------------------------------------------
    stim_proc : process
        procedure send_byte(b : std_logic_vector(7 downto 0)) is
        begin
            report "TB: Sender byte " & integer'image(to_integer(unsigned(b)));

            -- Startbit
            rx_i <= '0';
            for i in 0 to 7 loop
                wait until rising_edge(s_tick8x);
            end loop;

            -- Data bits
            for bit_i in 0 to 7 loop
                rx_i <= b(bit_i);
                for i in 0 to 7 loop
                    wait until rising_edge(s_tick8x);
                end loop;
            end loop;

            -- Stopbit
            rx_i <= '1';
            for i in 0 to 7 loop
                wait until rising_edge(s_tick8x);
            end loop;
        end procedure;
    begin
        wait until reset = '0';
        wait for 1 ms;

        send_byte(x"41"); -- A
        wait for 2 ms;

        send_byte(x"42"); -- B
        wait for 2 ms;

        send_byte(x"43"); -- C
        wait for 2 ms;

        report "SIM DONE" severity failure;
    end process;

end architecture sim;
