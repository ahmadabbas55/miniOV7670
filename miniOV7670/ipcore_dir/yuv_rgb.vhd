----------------------------------------------------------------------------------
-- Author:Ahmad Abbas <abbasweb55@gmail.com> 
-- 
-- Create Date:    12:29:30 02/07/2015 
-- Project Name:   miniOV7670	
-- Target Devices: Spartan6-FT256-LX25 
-- 
-- Based on:  
-- 	Company:LAAS-CNRS 
-- 	Author:Jonathan Piat <piat.jonathan@gmail.com> 
-- 	
-- 	Create Date:    11:48:01 03/12/2012 
-- 	Design Name: 
-- 	Module Name:    binarization - Behavioral 
-- 	Project Name: 
-- 	Target Devices: Spartan 6 
-- 	Tool versions: ISE 14.1 
-- 	Description: 
--	
-- 	Dependencies: 
--	
-- 	Revision: 
-- 	Revision 0.01 - File Created
-- 	Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL ;
use IEEE.STD_LOGIC_UNSIGNED.ALL ;

library work;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity yuv_rgb is
port( clk	:	in std_logic ;
		resetn	:	in std_logic ;		
		pixel_clock, hsync, vsync,DE : in std_logic; 
		pixel_clock_out, hsync_out, vsync_out,DE_out : out std_logic; 
 		pixel_y : in std_logic_vector(7 downto 0) ;
		pixel_u : in std_logic_vector(7 downto 0) ;
		pixel_v : in std_logic_vector(7 downto 0) ;
		pixel_r : out std_logic_vector(7 downto 0) ;
		pixel_g : out std_logic_vector(7 downto 0)  ;
		pixel_b : out std_logic_vector(7 downto 0)  
);
end yuv_rgb;

architecture Behavioral of yuv_rgb is
component edge_triggered_latch is
	 generic(NBIT : positive := 8; POL : std_logic :='1');
    Port ( clk : in  STD_LOGIC;
           resetn : in  STD_LOGIC;
           sraz : in  STD_LOGIC;
           en : in  STD_LOGIC;
           d : in  STD_LOGIC_VECTOR((NBIT - 1) downto 0);
           q : out  STD_LOGIC_VECTOR((NBIT - 1) downto 0));
end component;
signal pixel_r_t, pixel_g_t, pixel_b_t: signed(15 downto 0);
signal clamp_pixel_r_t, clamp_pixel_g_t, clamp_pixel_b_t: std_logic_vector(7 downto 0);
signal yl, ul, vl: std_logic_vector(15 downto 0);
signal c, d, e: signed(15 downto 0);
signal c_298, d_100, d_516, e_409, e_208: signed(15 downto 0);
signal pixel_data1_bin, pixel_data2_bin, pixel_data3_bin, pixels_and : std_logic ;
begin



yl <= X"00" & pixel_y ;
ul <= X"00" & pixel_u ;
vl <= X"00" & pixel_v ;

c <= signed(yl) - to_signed(16, 16) ;
d <= signed(ul) - to_signed(128, 16) ;
e <= signed(vl) - to_signed(128, 16) ;

c_298 <= (c(15) & c(6 downto 0) & X"00") + (c(15) & c(9 downto 0) & "00000") ; -- 256 * c + 32 * c 
d_100 <= (d(15) & d(7 downto 0) & "0000000") - (d(15) & d(9 downto 0) & "00000") ; --wrong it is 96-- 128 * d - 32 * d
d_516 <= (d(15) & d(5 downto 0) & "0" & X"00") ; -- 512 * d
e_409 <= (e(15) & e(5 downto 0) & "0" & X"00") - (e(15) & e(7 downto 0) & "0000000") ; -- 512 *e - 128 * e
e_208 <= (e(15) & e(6 downto 0) & X"00") - (e(15) & e(9 downto 0) & "00000"); -- 256 *e - 32 * e



--pixel_r_t <= signed(c_298) + signed(e_409) + to_signed(128, 16);
--pixel_g_t <= signed(c_298) - signed(d_100) - signed(e_208) + to_signed(128, 16);
--pixel_b_t <= signed(c_298) + signed(d_516) + to_signed(128, 16);

pixel_r_t <= signed(yl) + signed(vl) - to_signed(164, 16);
pixel_g_t <= signed(yl) - signed( ul(15 downto 2)) - signed(vl(15 downto 1)) + to_signed(80, 16);
pixel_b_t <= signed(yl) + signed(ul(14 downto 0) & '0') - to_signed(272, 16);


clamp_pixel_r_t <= X"FF" when pixel_r_t > 255 else
						 X"00" when pixel_r_t < 0 else
						 std_logic_vector(pixel_r_t(7 downto 0)) ;

clamp_pixel_g_t <= X"FF" when pixel_g_t > 255 else
						 X"00" when pixel_g_t < 0 else
						 std_logic_vector(pixel_g_t(7 downto 0)) ;

clamp_pixel_b_t <= X"FF" when pixel_b_t > 255 else
						 X"00" when pixel_b_t < 0 else
						 std_logic_vector(pixel_b_t(7 downto 0)) ;

pixel_r_latch0 : edge_triggered_latch 
		 generic map( NBIT => 8)
		 port map( clk =>clk,
				  resetn => resetn ,
				  sraz => '0' ,
				  en => pixel_clock ,
				  d => clamp_pixel_r_t(7 downto 0) , 
				  q => pixel_r);
				  
pixel_g_latch0 : edge_triggered_latch 
		 generic map( NBIT => 8)
		 port map( clk =>clk,
				  resetn => resetn ,
				  sraz => '0' ,
				  en => pixel_clock ,
				  d => clamp_pixel_g_t(7 downto 0) , 
				  q => pixel_g);

pixel_b_latch0 : edge_triggered_latch 
		 generic map( NBIT => 8)
		 port map( clk =>clk,
				  resetn => resetn ,
				  sraz => '0' ,
				  en => pixel_clock ,
				  d => clamp_pixel_b_t(7 downto 0) , 
				  q => pixel_b);				  

process(clk, resetn)
begin
	if resetn = '0' then
		pixel_clock_out <= '0';
		hsync_out <= '0' ;
		vsync_out <= '0' ;
		DE_out<='0';
	elsif clk'event and clk = '1' then
		pixel_clock_out <= pixel_clock;
		hsync_out <= hsync ;
		vsync_out <= vsync ;
		DE_out<=DE;
	end if ;
end process ;

end Behavioral;


