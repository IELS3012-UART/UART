library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uartRX is
  port (
    clk         : in  std_logic;                    -- Systemklokke (50 MHz)
    reset_n     : in  std_logic;                    -- Aktiv lav reset
    rx_i        : in  std_logic;                    -- Serielt RX-signal
    sample_tick : in  std_logic;                    -- Puls fra baudGen (8x baudrate)
    data_o      : out std_logic_vector(7 downto 0); -- Mottatt data
    data_ready  : out std_logic;                    -- Indikerer at data er klar
    data_ack    : in  std_logic                     -- Nullstiller data_ready
  );
end entity uartRX;

architecture rtl of uartRX is

  ---------------------------------------------------------------------------
  -- Konstanter og signaler
  ---------------------------------------------------------------------------
  constant OVERSAMPLE : integer := 8;
  constant MID_INDEX  : integer := OVERSAMPLE / 2;

  type state_t is (IDLE, START, DATA, STOP, DONE);
  signal state      : state_t := IDLE;

  signal s_count    : integer range 0 to OVERSAMPLE-1 := 0;   -- Teller innenfor ett bit
  signal bit_index  : integer range 0 to 7 := 0;               -- Hvilket databitt vi leser
  signal shift_reg  : std_logic_vector(7 downto 0) := (others => '0');
  signal data_r     : std_logic_vector(7 downto 0) := (others => '0');
  signal ready_r    : std_logic := '0';

  -- Synkroniser RX-inngangen for å unngå usikkerhet
  signal rx_q1, rx_q2 : std_logic := '1';
  signal rx_fall      : std_logic := '0'; -- Ett-klokkes puls ved fallende kant
  signal idle_guard   : integer range 0 to OVERSAMPLE*2 := 0;

begin

  -- Koble interne signaler til utganger
  data_o     <= data_r;
  data_ready <= ready_r;

  ---------------------------------------------------------------------------
  -- Synkroniser RX-linjen og detekter startbit (fallende kant)
  ---------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      rx_q1 <= rx_i;
      rx_q2 <= rx_q1;

      if idle_guard = 0 then
        if (rx_q2 = '1' and rx_q1 = '0') then
          rx_fall <= '1';
        else
          rx_fall <= '0';
        end if;
      else
        rx_fall <= '0';
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Hoved prosess: FSM for mottak av serielle data
  ---------------------------------------------------------------------------
  process(clk, reset_n)
  begin
    if reset_n = '0' then
      -- Reset alt
      state      <= IDLE;
      s_count    <= 0;
      bit_index  <= 0;
      shift_reg  <= (others => '0');
      data_r     <= (others => '0');
      ready_r    <= '0';
      idle_guard <= 0;

    elsif rising_edge(clk) then

      -- Ventetid etter data_ack før ny mottak
      if idle_guard > 0 then
        idle_guard <= idle_guard - 1;
      end if;

      -----------------------------------------------------------------------
      -- Startbit detektert fra IDLE
      -----------------------------------------------------------------------
      if (state = IDLE) and (rx_fall = '1') then
        s_count   <= 0;
        bit_index <= 0;
        state     <= START;
      end if;

      -----------------------------------------------------------------------
      -- FSM på sample_tick
      -----------------------------------------------------------------------
      if sample_tick = '1' then
        case state is

          -- ---------------------------------------------------------------
          when IDLE =>
            null;

          -- ---------------------------------------------------------------
          -- START: teller 1 bitperiode, går så til DATA
          -- ---------------------------------------------------------------
          when START =>
            if s_count = OVERSAMPLE - 1 then
              s_count   <= 0;
              bit_index <= 0;
              state     <= DATA;
            else
              s_count <= s_count + 1;
            end if;

          -- ---------------------------------------------------------------
          -- DATA: sample midt i hver bit
          -- ---------------------------------------------------------------
          when DATA =>
            if s_count = MID_INDEX then
              shift_reg(bit_index) <= rx_q2;
            end if;

            if s_count = OVERSAMPLE - 1 then
              s_count <= 0;
              if bit_index = 7 then
                state <= STOP;
              else
                bit_index <= bit_index + 1;
              end if;
            else
              s_count <= s_count + 1;
            end if;

          -- ---------------------------------------------------------------
          -- STOP: vent én bitperiode før data er ferdig
          -- ---------------------------------------------------------------
          when STOP =>
            if s_count = OVERSAMPLE - 1 then
              s_count <= 0;
              data_r  <= shift_reg;
              ready_r <= '1';  -- <-- nå holdes denne høy til ACK
              report "RX: mottatt byte = " &
                     integer'image(to_integer(unsigned(shift_reg)));
              state   <= DONE;
            else
              s_count <= s_count + 1;
            end if;

          -- ---------------------------------------------------------------
          -- DONE: vent på ack fra systemet før reset og ny start
          -- ---------------------------------------------------------------
          when DONE =>
            if data_ack = '1' then
              ready_r    <= '0';
              idle_guard <= OVERSAMPLE; -- kort pause før ny deteksjon
              state      <= IDLE;
            end if;

          when others =>
            state <= IDLE;

        end case;
      end if;
    end if;
  end process;

end architecture rtl;