library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ctrl is
    port (
        clk        : in  std_logic;
        rst_n      : in  std_logic;

        -- UART RX interface
        rx_din     : in  std_logic_vector(7 downto 0);
        rx_ready   : in  std_logic;
        rx_ack     : out std_logic;

        -- UART TX interface
        tx_busy    : in  std_logic;
        tx_start   : out std_logic;
        tx_data    : out std_logic_vector(7 downto 0);

        -- Baud rate selection
        sw_baud    : in  std_logic_vector(3 downto 0);
        baud_value : out unsigned(15 downto 0);

        -- Button inputs
        key0       : in std_logic;   -- KEY0: send 8-byte string (REQ CTRL 05)
        key1       : in std_logic;   -- KEY1: send single char (REQ CTRL 04)

        -- Outputs
        led_o      : out std_logic;
        hex0       : out std_logic_vector(6 downto 0);
        hex1       : out std_logic_vector(6 downto 0)
    );
end entity ctrl;

architecture rtl of ctrl is

    
    -- Internal RX storage
    
    signal rx_data_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_ack_reg  : std_logic := '0';

    
    -- LED pulse timer

    constant LED_ON_TIME : integer := 25_000_000;      
    signal led_counter   : integer range 0 to LED_ON_TIME := 0;
    signal led_state     : std_logic := '0';

    
    -- TX registers
    
    signal tx_start_r : std_logic := '0';
    signal tx_data_r  : std_logic_vector(7 downto 0) := (others => '0');

    
    -- Button edge detection (KEY0 & KEY1)
    
    signal key0_sync, key0_prev : std_logic := '0';
    signal key1_sync, key1_prev : std_logic := '0';

    
    -- 7-segment nibbles
    
    signal high_hex, low_hex : std_logic_vector(3 downto 0);

    
    -- Predefined 8-byte string (REQ CTRL 05)
    
    type msg_type is array(0 to 7) of std_logic_vector(7 downto 0); 
    constant MSG : msg_type := (
        x"48", -- H
        x"45", -- E
        x"20", -- space
        x"59", -- Y
        x"4F", -- O
        x"55", -- U
        x"21", -- !
        x"21"  -- newline
    ); 

    signal msg_index   : integer range 0 to 7 := 0;
    signal sending_msg : std_logic := '0';

    
    -- Single-character for REQ CTRL 04
    
    constant SINGLE_CHAR : std_logic_vector(7 downto 0) := x"42"; -- 'B'


    --------------------------------------------------------------------
    -- HEX lookup
    --------------------------------------------------------------------
    function hex_to_7seg(hex : std_logic_vector(3 downto 0))
        return std_logic_vector is
        variable seg : std_logic_vector(6 downto 0);
    begin
        case hex is
            when "0000" => seg := "1000000";
            when "0001" => seg := "1111001";
            when "0010" => seg := "0100100";
            when "0011" => seg := "0110000";
            when "0100" => seg := "0011001";
            when "0101" => seg := "0010010";
            when "0110" => seg := "0000010";
            when "0111" => seg := "1111000";
            when "1000" => seg := "0000000";
            when "1001" => seg := "0010000";
            when "1010" => seg := "0001000";
            when "1011" => seg := "0000011";
            when "1100" => seg := "1000110";
            when "1101" => seg := "0100001";
            when "1110" => seg := "0000110";
            when others => seg := "0001110";
        end case;
        return seg;
    end function;


begin

    --------------------------------------------------------------------
    -- Baud rate selection
    --------------------------------------------------------------------
    process(sw_baud)
    begin
        case sw_baud is
            when "0001" => baud_value <= to_unsigned(62,16); 
            when "0010" => baud_value <= to_unsigned(31,16);
            when "0011" => baud_value <= to_unsigned(21,16);
            when "0100" => baud_value <= to_unsigned(16,16);
            when "0101" => baud_value <= to_unsigned(13,16);
            when "0110" => baud_value <= to_unsigned(10,16);
            when "0111" => baud_value <= to_unsigned(9,16);
            when "1000" => baud_value <= to_unsigned(8,16);
            when "1001" => baud_value <= to_unsigned(7,16);
            when "1010" => baud_value <= to_unsigned(6,16);
            when others => baud_value <= to_unsigned(62,16);
        end case;
    end process;


    
    -- main process
   
    process(clk, rst_n)
    begin
        if rst_n = '1' then

            rx_data_reg <= (others => '0');
            rx_ack_reg  <= '0';

            led_state   <= '0';
            led_counter <= 0;

            key0_sync <= '0'; key0_prev <= '0';
            key1_sync <= '0'; key1_prev <= '0';

            tx_start_r <= '0';

            sending_msg <= '0';
            msg_index   <= 0;

        elsif rising_edge(clk) then

            
            -- sync buttons
            
            key0_sync <= key0;
            key0_prev <= key0_sync;

            key1_sync <= key1;
            key1_prev <= key1_sync;

            
            -- defaults
            
            rx_ack_reg <= '0';
            tx_start_r <= '0';

            
            -- rx event
            
            if rx_ready = '1' then

                rx_data_reg <= rx_din;
                rx_ack_reg  <= '1';

                led_state   <= '1';
                led_counter <= LED_ON_TIME;

                -- loopback only if not sending predefined message
                if (tx_busy = '0') and (sending_msg = '0') then
                    tx_data_r  <= rx_din;
                    tx_start_r <= '1';
                end if;
            end if;


            
            -- LED timer
            
            if led_counter > 0 then
                led_counter <= led_counter - 1;
                if led_counter = 0 then
                    led_state <= '0';
                end if;
            end if;


            
            -- sends single predefined character
            
            if (key1_sync = '1' and key1_prev = '0') then
                if (tx_busy = '0') and (sending_msg = '0') then
                    tx_data_r  <= SINGLE_CHAR;
                    tx_start_r <= '1';
                end if;
            end if;


            
            -- sending 8-byte string
            
            if (key0_sync = '1' and key0_prev = '0') then

                -- start msg
                sending_msg <= '1';
                msg_index <= 0;
                tx_data_r <= MSG(0);
                tx_start_r <= '1'; 

            elsif sending_msg = '1' then 
                
                -- proceed
                if tx_busy = '0' then
                    if msg_index < 7 then 
                        msg_index <= msg_index + 1; 
                        tx_data_r <= MSG(msg_index + 1);
                        tx_start_r <= '1';
                    else
                        sending_msg <= '0';
                    end if;
                end if;
            end if;


            
            -- string send fsm
            
            if sending_msg = '1' then

                if tx_busy = '0' then
                    if msg_index < 7 then
                        msg_index <= msg_index + 1;
                        tx_data_r <= MSG(msg_index + 1);
                        tx_start_r <= '1';
                    else
                        sending_msg <= '0';
                    end if;
                end if;

            end if;

        end if;
    end process;


    
    -- outputs

    rx_ack <= rx_ack_reg;
    tx_start <= tx_start_r;
    tx_data  <= tx_data_r;

    led_o <= led_state;

    high_hex <= rx_data_reg(7 downto 4);
    low_hex  <= rx_data_reg(3 downto 0);

    hex0 <= hex_to_7seg(low_hex);
    hex1 <= hex_to_7seg(high_hex);

end architecture rtl;