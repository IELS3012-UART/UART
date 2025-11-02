library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity baud_gen_tb is
end baud_gen_tb;

architecture sim of baud_gen_tb is

  -- Signals for testbench
  signal clk_tb      : std_logic := '0';
  signal rst_n_tb    : std_logic := '1';
  signal dvsr_tb     : unsigned(15 downto 0) := (others => '0');
  signal s_tick8x_tb : std_logic;
  signal s_tick_tb   : std_logic;

  constant CLK_PERIOD : time := 20 ns;  -- 50 MHz clock

begin
  ---------------------------------------------------------------------------
  -- Instantiate DUT (Device Under Test)
  ---------------------------------------------------------------------------
  uut: entity work.baud_gen
    port map (
      clk      => clk_tb,
      rst_n    => rst_n_tb,
      dvsr     => dvsr_tb,
      s_tick8x => s_tick8x_tb,
      s_tick   => s_tick_tb
    );

  ---------------------------------------------------------------------------
  -- Clock generation
  ---------------------------------------------------------------------------
  clk_process : process
  begin
    clk_tb <= '0';
    wait for CLK_PERIOD / 2;
    clk_tb <= '1';
    wait for CLK_PERIOD / 2;
  end process;

  ---------------------------------------------------------------------------
  -- Stimulus
  ---------------------------------------------------------------------------
  stim_proc : process
  begin
    -- Hold reset for a short period
    rst_n_tb <= '1';
    wait for 200 ns;
    rst_n_tb <= '0';

    -- Set divisor for 9600 baud @ 8x oversampling, 50 MHz clock
    dvsr_tb <= to_unsigned(650, 16);

    -- Run long enough to see multiple ticks
    wait for 5 ms;

    report "Simulation completed successfully." severity note;
    wait;
  end process;

end architecture;
