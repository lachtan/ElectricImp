// based on https://github.com/electricimp/reference/blob/master/hardware/ws2812/ws2812.device.nut

class NeoPixels
{    
	Zero = 0xC0;
	One = 0xF8;
	BitsPerColor = 8;
	BitsPerPixel = 24;

	prefareSpeed = null;
	
	intensityTable = null;
	blackColor = null

	spi = null;
	pixels = null;
	frame = null;

	constructor(spi, pixels, prefareSpeed = true)
	{
		this.spi = spi;
		this.pixels = pixels;
		this.frame = blob(pixels * BitsPerPixel + 1);
		this.frame[pixels * BitsPerPixel] = 0;
		this.prefareSpeed = prefareSpeed;

		if (prefareSpeed)
		{
		    prepareIntensityTable();
		}
		
		blackColor = intensityTable[0];

		clear();
		show();
	}

	function prepareIntensityTable()
	{
		// constantly occupy 256 * BitsPerPixel = 6144 bytes
		
		intensityTable = array(256);
		for (local intensity = 0; intensity < 256; intensity++)
		{
			local intensityValue = blob(BitsPerColor);
			local mask = 0x80;
			for (local bit = 0; bit < BitsPerColor; bit++)
			{
				intensityValue.writen((intensity & mask) > 0 ? One : Zero, 'b');
				mask = mask >> 1;
			}
			intensityTable[intensity] = intensityValue;
		}
	}
	
	function intensityToBytes(intensity)
	{
		if (prefareSpeed)
		{
		    return intensityTable[intensity];
		}
		else
		{
    		intensity = intensity.tointeger();
    		local intensityValue = blob(BitsPerColor);
    		local mask = 0x80;
    		for (local bit = 0; bit < BitsPerColor; bit++)
    		{
    			intensityValue.writen((intensity & mask) > 0 ? One : Zero, 'b');
    			mask = mask >> 1;
    		}
    		return intensityValue;
		}
	}

	function writePixel(index, color)
	{
		frame.seek(index * BitsPerPixel);
		frame.writeblob(intensityToBytes(color[1]));
		frame.writeblob(intensityToBytes(color[0]));
		frame.writeblob(intensityToBytes(color[2]));
	}

	function setColor(color)
	{
		frame.seek(0);
		for (local pixel = 0; pixel < pixels; pixel++)
		{
		    writePixel(pixel, color);
		}
	}
	
	function clear()
	{
		frame.seek(0);
		for (local pixel = 0; pixel < pixels; pixel++)
		{
			frame.writeblob(blackColor);
		}
	}

	function show()
	{
		spi.write(frame);
	}
}

// -----------------------------------------------------------------------------
// main
// -----------------------------------------------------------------------------

const SpiClkFreqKhz = 7500;
const Pixels = 8;
const Delay = 0.1;

spi <- hardware.spi257;
spi.configure(MSB_FIRST, SpiClkFreqKhz);
pixelStrip <- NeoPixels(spi, Pixels);

pixels <- [0, 0, 0, 0, 0]
currentPixel <- 0;
pAdd <- 1;

function test(d = null)
{ 
	pixelStrip.writePixel(pixels[0], [0, 0, 0]);
	for (local i = 1; i < 5; i++)
	{
		local b = math.pow(2, i);
		pixelStrip.writePixel(pixels[i], [ b, b / 2, b * 1.5 ]);
	}

	pixelStrip.show();
	if (currentPixel >= Pixels-1) pAdd = -1;
	if (currentPixel <= 0) pAdd = 1;
	currentPixel += pAdd;

	for (local i = 0; i < 4; i++) pixels[i] = pixels[i+1];
	pixels[4] = currentPixel;

	imp.wakeup(Delay, test);
} 

test();
