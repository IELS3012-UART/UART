library ieee; 
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all; 

entity fifo_tx is 
    generic ( 
        DATA_WIDTH : positive := 8;  -- Storage value (8-bit)
        FIFO_DEPTH : positive := 16  -- Addresse (Index)
    ); 

    port (
        clk : in std_logic; 
        rst_n : in std_logic; -- active high

        -- Write 
        wr_en   : in std_logic; 
        din     : in std_logic_vector(DATA_WIDTH-1 downto 0); 

        -- Read
        rd_en   : in std_logic; 
        dout    : out std_logic_vector(DATA_WIDTH-1 downto 0); 

        -- Status 
        empty   : out std_logic;
        full    : out std_logic
    ); 
end entity fifo_tx; 


architecture rtl of fifo_tx is 

    -- FIFO storage (ringbuffer)
    type mem_type is array (0 to FIFO_DEPTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0); 
    signal mem : mem_type; 

    -- Write pointer
    signal w_ptr : unsigned(7 downto 0) := (others => '0'); 

    -- Read pointer
    signal r_ptr : unsigned(7 downto 0) := (others => '0'); 

    -- Counter for entry
    signal count : unsigned(8 downto 0) := (others => '0'); 


    
begin 

    -- Output
    dout <= mem(to_integer(r_ptr)); 
    empty <= '1' when count = 0 else '0'; 
    full <= '1' when count = FIFO_DEPTH else '0'; 

    -- Write/ Read Logic 
    process(clk)
    begin
        if rising_edge(clk) then

            if rst_n = '1' then 
                w_ptr <= (others => '0'); 
                r_ptr <= (others => '0');
                count <= (others => '0'); 

            else

                -- Write
                if (wr_en = '1') and (full = '0') then
                    mem(to_integer(w_ptr)) <= din; 
                    
                    if w_ptr = FIFO_DEPTH -1 then
                        w_ptr <= (others => '0'); 
                    else
                        w_ptr <= w_ptr +1; 
                    end if; 


                    if rd_en = '0'and count < FIFO_DEPTH then
                        count <= count + 1; 
                    end if;
                end if; 

                -- Read
                if (rd_en = '1') and (empty = '0') then 
                    
                    if r_ptr = FIFO_DEPTH -1 then 
                        r_ptr <= (others => '0'); 
                    else
                        r_ptr <= r_ptr +1; 
                    end if; 


                    if wr_en = '0' then 
                        count <= count - 1; 
                    end if; 
                end if; 

            end if; 
        end if;

    end process;
end architecture;

