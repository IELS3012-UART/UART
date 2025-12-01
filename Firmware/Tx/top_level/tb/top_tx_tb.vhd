library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_tx_tb is
end;

architecture sim of top_tx_tb is

    -- Standard
    signal clk     : std_logic := '0';
    signal rst_n   : std_logic := '0';

    -- Baud gen
    signal dsvr        : unsigned(15 downto 0) := to_unsigned(16, 16);
    signal tick        : std_logic;

    -- fifo control
    signal wr_en       : std_logic := '0';
    signal wr_data     : std_logic_vector(7 downto 0) := (others => '0');
    signal fifo_dout   : std_logic_vector(7 downto 0);
    signal fifo_empty  : std_logic;
    signal fifo_full   : std_logic;
    signal rd_en       : std_logic;

    -- uart tx
    signal tx_start    : std_logic;
    signal tx_din      : std_logic_vector(7 downto 0);
    signal parity_mode : std_logic_vector(1 downto 0) := "00";
    signal tx_out      : std_logic;
    signal tx_busy     : std_logic;
    signal tx_done     : std_logic;

begin

    clk <= not clk after 10 ns;

    dut : entity work.top_tx
        port map(
            clk     => clk,
            rst_n   => rst_n,

            dsvr    => dsvr,
            tick    => tick,

            wr_en   => wr_en,
            wr_data => wr_data,

            fifo_dout  => fifo_dout,
            fifo_empty => fifo_empty,
            fifo_full  => fifo_full,
            rd_en      => rd_en,

            tx_start    => tx_start,
            tx_din      => tx_din,
            parity_mode => parity_mode,

            tx      => tx_out,
            tx_busy => tx_busy,
            tx_done => tx_done
        );

    --------------------------------------------------------------------
    -- stimulus
    --------------------------------------------------------------------
    stim : process
    begin
        rst_n <= '1';
        wait for 200 ns;
        rst_n <= '0';
        wait for 200 ns;

        ------------------------------------------------------
        -- fifo write three bites
        ------------------------------------------------------
        wr_en   <= '1';

        wr_data <= x"41"; wait for 20 ns;   -- A
        wr_data <= x"42"; wait for 20 ns;   -- B
        wr_data <= x"43"; wait for 20 ns;   -- C

        wr_en <= '0';

        ------------------------------------------------------
        -- Wait 
        ------------------------------------------------------
        wait for 10 ms;

        report "TRINN 3 complete.";
        std.env.stop;
    end process;

end architecture;
