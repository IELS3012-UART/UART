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

entity uart_tx is 
    port 
        (

            clk             : in std_logic;        -- 50 MHz 
            s_tick          : in std_logic;        -- 1x baud tick         
            rst_n           : in std_logic;        -- Active high 

            tx_start        : in std_logic;         -- Start signal 
            tx_din          : in std_logic_vector(7 downto 0); -- byte to be transmitted

            parity_mode : in std_logic_vector(1 downto 0); -- parity mode

            tx              : out std_logic;        -- UART TX line
            tx_done_tick    : out std_logic;        -- Puls when done
            tx_busy         : out std_logic         -- High when transmitting

        );
end entity uart_tx; 

architecture rtl of uart_tx is 

    -- FSM status
    type state_type is (idle, start, data, parity, stop); 

    -- state index
    signal state_reg, state_next  : state_type; 


    -- shift register
    signal b_reg, b_next : std_logic_vector(7 downto 0); 


    -- bit index counter 
    signal n_reg, n_next : unsigned(2 downto 0); 
    

    -- Tx out register
    signal tx_reg, tx_next : std_logic; 
     
    -- transmission-done flag
    signal done_reg, done_next : std_logic; 

    -- parity bit
    signal parity_bit : std_logic; 


begin 
    --------------------
    -- Output assignment
    ---------------------
    tx <= tx_reg; 
    tx_done_tick <= done_reg; 
    tx_busy <= '1' when state_reg /= idle else '0'; 


    -----------------------
    -- Parity generator
    -----------------------
    process(b_reg, parity_mode)
        variable temp : std_logic := '0';
    begin
        temp := '0';
        --XOR all bit
        for i in b_reg'range loop
            temp := temp xor b_reg(i);
        end loop;
       
        case parity_mode is
            
            when "00" =>
                parity_bit <= '0'; -- no parity
    
            when "01" => 
                parity_bit <= not temp; -- even
            
            when "10" =>
                parity_bit <= temp; -- odd
            
            when others =>
                parity_bit <= '0';-- no parity
        end case; 
    end process; 



---------------------------
-- Sequence logic registers
---------------------------
    process(clk)
    begin
        if rst_n = '1' then 

            -- set all index = 0
            state_reg <= idle; 
            b_reg <= (others => '0'); 
            n_reg <= (others => '0'); 
            tx_reg <= '1';  -- idle level
            done_reg <= '0'; 

        elsif rising_edge(clk) then 

            -- increment 
            state_reg <= state_next; 
            b_reg <= b_next; 
            n_reg <= n_next;
            tx_reg <= tx_next; 
            done_reg <= done_next; 
            
        end if; 
    end process; 

---------------------------
-- Next-state logic 
---------------------------

process(state_reg, tx_start, tx_din, b_reg, n_reg, s_tick, parity_bit, parity_mode)
begin

    -- default values 
    state_next <= state_reg; 
    b_next <= b_reg; 
    n_next <= n_reg;
    tx_next <= tx_reg; 
    done_next <= '0'; 


    case state_reg is
        
        -------------------------------------------------
        -- Idle-state 
        -------------------------------------------------
        when idle =>
            tx_next <= '1';      -- line is high when idle 


            if tx_start = '1' then
                
                b_next <= tx_din;       -- Load byte
                n_next <= (others => '0'); -- Clear bit index

                -- Next state
                state_next <= start; 
            end if; 


        -------------------------------------------------
        -- Start-state
        -------------------------------------------------
        when start => 

            tx_next <= '0'; -- send startbit 

            if s_tick = '1' then 

                -- Next state
                state_next <= data; 
            end if; 


        -------------------------------------------------
        -- Data-state 
        -------------------------------------------------
        when data => 
            tx_next <= b_reg(0); -- load lsb to transmission next

            if s_tick = '1' then 
                b_next <= '0' & b_reg(7 downto 1) ; --shift right


                -- bit counter 
                if n_reg = 7 then 

                    -- if parity used go to parity
                    if parity_mode = "01" or parity_mode = "10" then
                        state_next <= parity; 
                    else
                        state_next <= stop; 
                    end if; 
                    
                else 

                    n_next <= n_reg + 1; 

                end if; 
            end if ; 
            



        -------------------------------------------------
        -- Parity-state
        -------------------------------------------------

        when parity => 
            tx_next <= parity_bit; 
            if s_tick = '1' then
                state_next <= stop; 
            end if; 


        -------------------------------------------------
        -- Stop-state
        -------------------------------------------------

        when stop =>
        tx_next <= '1'; -- send stop bit
        
        if s_tick = '1' then
            
            done_next <= '1'; -- one cycle done pulse

            -- Next State
            state_next <= idle;

        end if;

    end case;

end process;
end architecture; 

