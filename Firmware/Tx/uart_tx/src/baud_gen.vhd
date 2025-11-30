library ieee; 
use ieee.std_logic_1164.all; 
use ieee.NUMERIC_STD.all; 


entity baud_gen is
    port (
        clk : in std_logic; 
        rst_n : in std_logic;             -- aktiv high
        dsvr : in unsigned(15 downto 0); 

        s_tick8x : out std_logic; 
        s_tick : out std_logic
    );
end entity; 


architecture rtl of baud_gen is 
    signal count1 : unsigned(15 downto 0) := (others => '0'); 
    signal count2 : unsigned (2 downto 0) := (others => '0'); 
    signal tick8x : std_logic := '0'; 
    signal s_tick_int : std_logic := '0'; 
    signal dsvr_debug : unsigned(15 downto 0);

begin
    s_tick8x <= tick8x;
    s_tick <= s_tick_int;

    process(clk)
    begin 
        if (rising_edge(clk)) then 

            if (rst_n = '1') then
                count1 <= (others => '0'); 
                tick8x <= '0'; 

            elsif count1 >= dsvr - 1 then 
                count1 <= (others => '0'); 
                tick8x <= '1';
            
            else
                 count1 <= count1 + 1;
                 tick8x <= '0'; 
            end if; 
        end if; 
    end process; 

    dsvr_debug <= dsvr; 
  
    process(clk)
        begin
            if(rising_edge(clk)) then
                if (rst_n = '1') then 
                    count2 <= (others => '0'); 
                    s_tick_int <= '0'; 

                elsif tick8x = '1' then 

                    if count2 = 7 then 
                        count2 <= (others => '0');
                        s_tick_int <= '1'; 
                        
                    else 
                        count2 <= count2 + '1'; 
                        s_tick_int <= '0'; 
                    end if; 

                else
                    s_tick_int <= '0';
                end if; 

            end if; 
    end process;  
end architecture; 
          
