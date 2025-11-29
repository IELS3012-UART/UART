library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uartRX is
end entity;

architecture sim of tb_uartRX is

  constant CLK_FREQ_HZ : integer := 50_000_000;  -- 50 MHz systemklokke
  constant CLK_PERIOD  : time := 20 ns;          -- 50 MHz
  constant BAUD_RATE   : integer := 9600;
  constant OVERSAMPLE  : integer := 8;

  signal clk         : std_logic := '0';
  signal reset_n     : std_logic := '0';
  signal rx_i        : std_logic := '1';
  signal sample_tick : std_logic;
  signal data_o      : std_logic_vector(7 downto 0);
  signal data_ready  : std_logic;
  signal data_ack    : std_logic := '0';

  -- beregn antall klokkesykluser per bitperiode (for riktig timing)
  constant CLKS_PER_BIT : integer := CLK_FREQ_HZ / BAUD_RATE;

begin

  -- -------------------------------------------------------------
  -- Generer systemklokken
  -- -------------------------------------------------------------
  clk <= not clk after CLK_PERIOD / 2;

  -- -------------------------------------------------------------
  -- Reset
  -- -------------------------------------------------------------
  process
  begin
    reset_n <= '0';
    wait for 200 ns;
    reset_n <= '1';
    wait;
  end process;

  -- -------------------------------------------------------------
  -- Instans av baud-generator
  -- -------------------------------------------------------------
  baud_inst : entity work.baudGen
    generic map (
      CLK_FREQ_HZ => CLK_FREQ_HZ,
      BAUD_RATE   => BAUD_RATE,
      OVERSAMPLE  => OVERSAMPLE
    )
    port map (
      clk         => clk,
      reset_n     => reset_n,
      sample_tick => sample_tick
    );

  -- -------------------------------------------------------------
  -- Instans av UART RX-modul
  -- -------------------------------------------------------------
  uut: entity work.uartRX
    port map (
      clk         => clk,
      reset_n     => reset_n,
      rx_i        => rx_i,
      sample_tick => sample_tick,
      data_o      => data_o,
      data_ready  => data_ready,
      data_ack    => data_ack
    );

  -- -------------------------------------------------------------
  -- Stimuli: sender én byte korrekt i tid (1 start + 8 data + 1 stopp)
  -- -------------------------------------------------------------
  stim_proc: process
    procedure wait_clks(n: natural) is
    begin
      for k in 1 to n loop
        wait until rising_edge(clk);
      end loop;
    end procedure;

    procedure send_byte(b: std_logic_vector(7 downto 0)) is
    begin
      report "TB: sender byte " & integer'image(to_integer(unsigned(b)));
      -- Startbit (lav)
      rx_i <= '0';
      wait_clks(CLKS_PER_BIT);

      -- Send databiter LSB først
      for i in 0 to 7 loop
        rx_i <= b(i);
        wait_clks(CLKS_PER_BIT);
      end loop;

      -- Stoppbit (høy)
      rx_i <= '1';
      wait_clks(CLKS_PER_BIT);
    end procedure;

  begin
    wait until reset_n = '1';
    wait for 500 us;  -- litt "idle" først

    send_byte(x"41"); -- sender 65 / 'A'

    wait until data_ready = '1';
    report "TB: mottatt byte = " & integer'image(to_integer(unsigned(data_o)));

    data_ack <= '1';
    wait until rising_edge(clk);
    data_ack <= '0';

    report "SIM DONE" severity failure;
  end process;

  -- Watchdog
  watchdog: process
  begin
    wait for 10 ms;
    assert false report "TIMEOUT: data_ready trigget ikke" severity failure;
  end process;

end architecture sim;

