library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity baudGen is
  generic (
    CLK_FREQ_HZ : integer := 50_000_000;  -- systemklokke
    BAUD_RATE   : integer := 9600;        -- baudrate (kan justeres)
    OVERSAMPLE  : integer := 8            -- oversampling (betyr 8x)
  );
  port (
    clk         : in  std_logic;          -- 50 MHz klokke
    reset_n     : in  std_logic;          -- aktiv lav reset
    sample_tick : out std_logic           -- puls ved hvert sample
  );
end entity baudGen;

architecture rtl of baudGen is

  -- Beregn antall klokkesykluser mellom sample_tick
  constant DIVISOR : integer := CLK_FREQ_HZ / (BAUD_RATE * OVERSAMPLE);

  signal counter : integer range 0 to DIVISOR - 1 := 0;
  signal tick_r  : std_logic := '0';

begin
  sample_tick <= tick_r;

  -----------------------------------------------------------------
  -- Prosess: deler ned systemklokka til riktig sample-hastighet
  -----------------------------------------------------------------
  process(clk, reset_n)
  begin
    if reset_n = '0' then
      counter <= 0;
      tick_r  <= '0';
    elsif rising_edge(clk) then
      if counter = DIVISOR - 1 then
        counter <= 0;
        tick_r  <= '1';    -- send puls
      else
        counter <= counter + 1;
        tick_r  <= '0';
      end if;
    end if;
  end process;

end architecture rtl;