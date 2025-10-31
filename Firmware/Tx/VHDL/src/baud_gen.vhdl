library ieee;
use ieee.std_logic_1164.all; 
use ieee.NUMERIC_STD.all; 

--============================================================
-- Sub-Module Name: Baud Rate
-- Author: Yamn S. Salim
-- Project: IELS3012 - UART Module (TX)
-- Descirption: 

--    Generates
--     - s_tick8x: 8x baud tick for Rx
--     - s_tick: 1x baud tick for Tx
--============================================================


entity baud_gen is
    port (
        clk   : in std_logic;                -- System clock
        rst_n : in std_logic;                -- Active high 
        dvsr  : in unsigned(15 downto 0);    -- Divider value (set baud rate)

        s_tick8x : out std_logic;            -- 8X tick for Rx
        s_tick : out std_logic               -- 1x tick for Tx
    );
end entity; 



architecture rtl of baud_gen is
    signal count : unsigned(15 downto 0) := (others => '0'); -- 8 bits 
    signal sub_count : unsigned(2 downto 0) := (others => '0'); -- 8 bits
    signal tick8x_int : std_logic := '0'; 

begin
    --============================
    -- Generate 8x tick (s_tick8x)
    --============================
    process(clk)
    begin 
        if (rising_edge(clk)) then 

            -- When counter is reset
            if (rst_n = '1') then 
                count  <= (others => '0'); 
                tick8x_int <= '0'; 
            
            -- Give a tick Pulse
            elsif count = dvsr then              -- Divide by 8
                count <= (others => '0'); 
                tick8x_int <= '1';
                
            -- When counter is incrementing
            else 
                count <= count + 1; 
                tick8x_int <= '0';
            
            end if; 
        end if; 
    end process; 

    -- s_tick goes high when counter wraps to 0 at normal speed 
    s_tick8x <= tick8x_int; 


    --================================
    -- Divide s_tick8x by 8 -> s_tick
    --================================
    process(clk)
    begin 
        if (rising_edge(clk)) then 

            -- When reset is high
            if (rst_n = '1') then
                sub_count <= (others => '0'); 

            elsif tick8x_int = '1' then
                 -- Give a tick pulse
                if sub_count =  7 then 
                    sub_count <= (others => '0');
                
                 -- Increment 
                else 
                    sub_count <= sub_count + 1; 
                end if; 
            end if; 
        end if; 
    end process; 

    s_tick <= '1' when sub_count = 0 else '0';  

end architecture;