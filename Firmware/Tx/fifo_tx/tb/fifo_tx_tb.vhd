library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_tx_tb is
end entity;

architecture sim of fifo_tx_tb is

    -- Testbench signals
    signal clk     : std_logic := '0';
    signal rst_n     : std_logic := '0'; -- aktic high

    signal wr_en   : std_logic := '0';
    signal rd_en   : std_logic := '0';

    signal din     : std_logic_vector(7 downto 0) := (others => '0');
    signal dout    : std_logic_vector(7 downto 0);

    signal empty   : std_logic;
    signal full    : std_logic;

    constant CLK_PERIOD : time := 20 ns;

begin

    --------------------------------------------------------------------
    -- DUT: FIFO
    --------------------------------------------------------------------
    uut : entity work.fifo_tx
        generic map (
            DATA_WIDTH => 8,
            FIFO_DEPTH => 4     -- liten FIFO → lett å teste wrap-around
        )
        port map (
            clk   => clk,
            rst_n   => rst_N,
            wr_en => wr_en,
            din   => din,
            rd_en => rd_en,
            dout  => dout,
            empty => empty,
            full  => full
        );

    --------------------------------------------------------------------
    -- Clock generator (50 MHz)
    --------------------------------------------------------------------
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    --------------------------------------------------------------------
    -- Test process
    --------------------------------------------------------------------
    stim : process
    begin
        ----------------------------------------------------------------
        -- RESET
        ----------------------------------------------------------------
        rst_n <= '1';
        wait for 40 ns;
        rst_n <= '0';
        wait for 40 ns;

        assert empty = '1'; 
        report "FIFO should be empty after reset" severity error;

        ----------------------------------------------------------------
        -- WRITE 3 VALUES
        ----------------------------------------------------------------
        report "Writing values A0, B1, C2";

        wr_en <= '1'; -- enable write to fifo
        din <= x"A0"; wait until rising_edge(clk);
        din <= x"B1"; wait until rising_edge(clk);
        din <= x"C2"; wait until rising_edge(clk);
        wr_en <= '0'; -- diable write to fifo

        wait for 1 ns;

        assert empty = '0' report "FIFO should NOT be empty" severity error;
        assert full  = '0' report "FIFO should NOT be full yet" severity error;

        ----------------------------------------------------------------
        -- READ BACK 3 VALUES
        ----------------------------------------------------------------
        report "Reading values (expect: A0, B1, C2)";

        rd_en <= '1'; wait until rising_edge(clk);
        assert dout = x"A0" report "Expected A0" severity error;

        wait until rising_edge(clk);
        assert dout = x"B1" report "Expected B1" severity error;

        wait until rising_edge(clk);
        assert dout = x"C2" report "Expected C2" severity error;

        rd_en <= '0';
        wait for 1 ns;

        assert empty = '1' report "FIFO should be empty now" severity error;

        ----------------------------------------------------------------
        -- TEST WRAP-AROUND
        ----------------------------------------------------------------
        report "Testing wrap-around";

        -- write 4 values (fills FIFO)
        wr_en <= '1';
        din <= x"11"; wait until rising_edge(clk);
        din <= x"22"; wait until rising_edge(clk);
        din <= x"33"; wait until rising_edge(clk);
        din <= x"44"; wait until rising_edge(clk);
        wr_en <= '0';

        assert full = '1' report "FIFO should be FULL after 4 writes" severity error;

        -- read one
        rd_en <= '1'; wait until rising_edge(clk);
        rd_en <= '0';

        assert full = '0' report "FIFO should NOT be full after 1 read" severity error;

        -- write again → should wrap correctly
        wr_en <= '1';
        din <= x"55";
        wait until rising_edge(clk);
        wr_en <= '0';

        ----------------------------------------------------------------
        -- FINISH
        ----------------------------------------------------------------
        report "FIFO test PASSED!" severity note;
        std.env.stop;
        wait;

    end process;

end architecture sim;
