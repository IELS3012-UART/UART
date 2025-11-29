library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ctrl is
  port (
    clk        : in  std_logic;                      -- 50 MHz klokke
    reset_n    : in  std_logic;                      -- aktiv lav reset
    data_i     : in  std_logic_vector(7 downto 0);   -- mottatt data fra uartRX
    data_ready : in  std_logic;                      -- indikerer ny data
    data_ack   : out std_logic;                      -- kvitterer til uartRX
    led_o      : out std_logic;                      -- LED for data mottatt
    hex0_o     : out std_logic_vector(6 downto 0);   -- 4 minst signifikante bit (HEX0)
    hex1_o     : out std_logic_vector(6 downto 0)    -- 4 mest signifikante bit (HEX1)
  );
end entity ctrl;

architecture rtl of ctrl is

  -- intern lagring av mottatt data
  signal data_reg : std_logic_vector(7 downto 0) := (others => '0');

  -- LED blink timer
  constant LED_ON_TIME : integer := 25_000_000;  -- ~0.5 sek ved 50 MHz
  signal led_counter   : integer range 0 to LED_ON_TIME := 0;
  signal led_r         : std_logic := '0';

  -- Ack-signal
  signal ack_r : std_logic := '0';

  -- Nibble-separasjon
  signal high_hex, low_hex : std_logic_vector(3 downto 0);

  -- 7-segmentdekoding (funksjon)
  function hex_to_7seg(hex : std_logic_vector(3 downto 0)) return std_logic_vector is
    variable seg : std_logic_vector(6 downto 0);
  begin
    case hex is
      when "0000" => seg := "1000000"; -- 0
      when "0001" => seg := "1111001"; -- 1
      when "0010" => seg := "0100100"; -- 2
      when "0011" => seg := "0110000"; -- 3
      when "0100" => seg := "0011001"; -- 4
      when "0101" => seg := "0010010"; -- 5
      when "0110" => seg := "0000010"; -- 6
      when "0111" => seg := "1111000"; -- 7
      when "1000" => seg := "0000000"; -- 8
      when "1001" => seg := "0010000"; -- 9
      when "1010" => seg := "0001000"; -- A
      when "1011" => seg := "0000011"; -- b
      when "1100" => seg := "1000110"; -- C
      when "1101" => seg := "0100001"; -- d
      when "1110" => seg := "0000110"; -- E
      when others => seg := "0001110"; -- F
    end case;
    return seg;
  end function;

begin

  ---------------------------------------------------------------------------
  -- Hovedprosess
  ---------------------------------------------------------------------------
  process(clk, reset_n)
  begin
    if reset_n = '0' then
      data_reg   <= (others => '0');
      ack_r      <= '0';
      led_r      <= '0';
      led_counter <= 0;

    elsif rising_edge(clk) then
      -- Default ack lav
      ack_r <= '0';

      -- Hvis ny data mottatt:
      if data_ready = '1' then
        data_reg <= data_i;       -- lagre data
        ack_r    <= '1';          -- send ACK (1 clk)
        led_r    <= '1';          -- tenn LED
        led_counter <= LED_ON_TIME;
      end if;

      -- LED-timer nedtelling
      if led_counter > 0 then
        led_counter <= led_counter - 1;
        if led_counter = 0 then
          led_r <= '0';
        end if;
      end if;

    end if;
  end process;

  -- Split data i to hex sifre for 7-seg
  high_hex <= data_reg(7 downto 4);
  low_hex  <= data_reg(3 downto 0);

  -- 7-segment utganger (aktiv lav)
  hex0_o <= hex_to_7seg(low_hex);
  hex1_o <= hex_to_7seg(high_hex);

  -- LED og ACK
  led_o    <= led_r;
  data_ack <= ack_r;

end architecture rtl;