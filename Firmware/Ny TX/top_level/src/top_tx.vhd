library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_tx is
    port (
        clk     : in std_logic;
        rst_n   : in std_logic;

        -- BAUD GEN
        dsvr    : in unsigned(15 downto 0);
        tick    : buffer std_logic;

        -- FIFO control (from testbench)
        wr_en   : in std_logic;
        wr_data : in std_logic_vector(7 downto 0);

        -- FIFO observation
        fifo_dout  : out std_logic_vector(7 downto 0);
        fifo_empty : out std_logic;
        fifo_full  : out std_logic;
        rd_en      : out std_logic;

        -- UART TX
        tx_start    : buffer std_logic;
        tx_din      : buffer std_logic_vector(7 downto 0);
        parity_mode : in  std_logic_vector(1 downto 0);

        tx        : out std_logic;
        tx_busy   : out std_logic;
        tx_done   : buffer std_logic
    );
end entity;

architecture rtl of top_tx is

    -- internal FIFO to UART 
    signal dout_int  : std_logic_vector(7 downto 0);
    signal empty_int : std_logic;
    signal full_int  : std_logic;

    signal rd_en_int : std_logic := '0';

begin

    -------------------------------
    -- Baud generator
    -------------------------------
    u_baud : entity work.baud_gen
        port map(
            clk      => clk,
            rst_n    => rst_n,
            dsvr     => dsvr,
            s_tick8x => open,
            s_tick   => tick
        );

    -------------------------------
    -- FIFO
    -------------------------------
    u_fifo : entity work.fifo_tx
        generic map(
            DATA_WIDTH => 8,
            FIFO_DEPTH => 16
        )
        port map(
            clk     => clk,
            rst_n   => rst_n,

            wr_en   => wr_en,
            din     => wr_data,

            rd_en   => rd_en_int,
            dout    => dout_int,

            empty   => empty_int,
            full    => full_int
        );

    -- expose FIFO observation signals
    fifo_dout  <= dout_int;
    fifo_empty <= empty_int;
    fifo_full  <= full_int;
    rd_en      <= rd_en_int;

    -------------------------------
    -- UART TX
    -------------------------------
    u_tx : entity work.uart_tx
        port map(
            clk          => clk,
            s_tick       => tick,
            rst_n        => rst_n,

            tx_start     => tx_start,
            tx_din       => tx_din,
            parity_mode  => parity_mode,

            tx           => tx,
            tx_done_tick => tx_done,
            tx_busy      => tx_busy
        );

 
    tx_din   <= dout_int;         -- data comes directly from FIFO
    tx_start <= not empty_int;    -- start when FIFO has data

    rd_en_int <= tx_done;         -- dequeue after each frame

end architecture;
