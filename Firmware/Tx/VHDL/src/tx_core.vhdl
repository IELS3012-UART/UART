library ieee; 
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all; 

--============================================================
-- Sub-Module Name: Tx-Core
-- Author: Yamn S. Salim
-- Project: IELS3012 - UART Module (TX)
-- Descirption: 
--      -- UART transmitter core with 8 data bits, no parity, 1 stop bit
--============================================================

entity tx_core is
    port ( 
        clk : in std_logic;                     -- System clock 50Mhz
        rst_n : in std_logic;                   -- Reset active low


        tx_start : in std_logic;                -- One-cycle start trigger 
        d_in : in std_logic_vector(7 downto 0); -- Data byte to send
        s_tick : in std_logic;                  -- Baud tick
       
        
        tx : out std_logic;                     --  Serial line output 
        tx_done_tick : out std_logic;           -- Indicate when complete transmission
        tx_busy   : out std_logic               -- High while transmitting 
        
    );
end entity; 



architecture rtl of tx_core is 
    -- FSM state type 
    type state_type is (idle, start, data, stop); 

    -- Signal declarations 
    signal state_reg, state_next : state_type;             -- Control FSM current state
    signal n_reg, n_next : unsigned(2 downto 0);           -- Bit counter 
    signal b_reg, b_next : std_logic_vector(7 downto 0);   -- Shift register, holding the byte and shifting it out
    signal tx_reg, tx_next : std_logic;                    -- Tx output register
    signal tx_done_tick_reg, tx_done_tick_next: std_logic;  -- Tranmsission done flag

begin 
    ----------------------------------------
    -- Sequential processs (register update)
    ----------------------------------------
    process(clk,rst_n)
    begin

        -- Reset all internal register 

        if rst_n = '0' then 
            state_reg   <= idle; 
            n_reg       <= (others => '0'); 
            b_reg       <= (others => '0'); 
            tx_reg      <= '1'; -- line idle high
            tx_done_tick_reg <= '0'; 

        --Update all register   

        elsif rising_edge(clk) then 
            state_reg       <= state_next; 
            n_reg           <= n_next; 
            b_reg           <= b_next; 
            tx_reg          <= tx_next;
            tx_done_tick_reg <= tx_done_tick_next; -- default; high for 1 cycle
        end if; 
    end process; 

    ------------------------------------------
    -- FSM next state logic & functional units
    ------------------------------------------ 
    process (state_reg, n_reg, b_reg, tx_reg, tx_start, s_tick)
    begin 
        -- Default values 
        state_next <= state_reg; 
        n_next <= n_reg; 
        b_next <= b_reg; 
        tx_next <= tx_reg; 
        tx_done_tick_next <= '0'; 

        case state_reg is 

            -------------
            -- IDLE state 
            -------------
            when idle =>
                tx_next <= '1'; -- Tx line idle high 
                if tx_start = '1' then 
                    b_next      <= d_in;            -- load data into shift register 
                    n_next      <= (others => '0'); -- clear bit counter 
                    state_next  <= start;           -- go to start bit state 
                end if; 

            -------------
            -- Start state
            -------------
            when start => 
                tx_next <= '0'; -- send start bit 
                if  s_tick = '1' then 
                    state_next <= data; -- after 1 tick, move to data state 
                end if; 

            -------------
            -- DATA state 
            -------------
            when data => 
                tx_next <= b_reg(0);    -- Transmit LSB
                if s_tick = '1' then 
                    --shift register right by one 
                    b_next <= '0' & b_reg(7 downto 1);
                    -- check if we have sent all 8 bits
                    if n_reg = "111" then
                        state_next <= stop; -- done sending all bits 
                    else
                        n_next <= n_reg + 1; -- increment bit counter 
                    end if;
                end if;  

            -----------------
            -- STOP state
            ---------------
            when stop => 
                tx_next <= '1'; -- send stop bit
                if s_tick = '1' then 
                    state_next <= idle; -- return to idle 
                    tx_done_tick_next <= '1'; -- signal done
                end if; 
            end case; 
        end process; 


        ---------------------
        -- Output assignments
        ---------------------
        tx <= tx_reg; 
        tx_done_tick <= tx_done_tick_reg; 
        tx_busy <= '1' when state_reg /= idle else '0'; 

end architecture;