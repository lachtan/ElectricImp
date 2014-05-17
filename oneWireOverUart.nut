/*
 * Vzhledem k tomu, ze ElectricImp neumi komunikovat s 1 wire bus, pouziva se
 * trikove UART rozhrani (je potreba dodat pullup rezistor a diodu), kde se meni rychlosti.
 * Vse je hezky vysvetleno na strankach Maxim Integrated.
 
 * Links:
 * http://www.maximintegrated.com/app-notes/index.mvp/id/214
 * https://github.com/dword1511/onewire-over-uart
 * http://forums.electricimp.com/discussion/239/onewire-support/p1
 *
 */


class OneWire
{
	uartDevice = null;
	
	constructor(uartDevice)
	{
		this.uartDevice = uartDevice;
	}
	
	function reset()
	{
		this.uartDevice.configure(9600, 8, PARITY_NONE, 1, NO_CTSRTS);
		this.uartDevice.write(0xF0);
		this.uartDevice.flush();

		if (this.uartDevice.read() == 0xF0)
		{
			return false;
		}
		else
		{    
			this.uartDevice.configure(115200, 8, PARITY_NONE, 1, NO_CTSRTS);
			return true;
		}
	}  

	function write(byte)
	{
		local bit = 0x00;
		for (local b = 0; b < 8; b++, byte = byte >> 1)
		{
			bit = (byte & 0x01) ? 0xFF : 0x00;
			this.uartDevice.write(bit);
			this.uartDevice.flush();
			if (this.uartDevice.read() != bit)
			{
				// server.log("owDevice write error");
				// jak to poslat?
			}
		}
	} 

	function read()
	{
		local byte = 0x0;
		for (local bit = 0; bit < 8; bit++)
		{
			this.uartDevice.write(0xFF);
			this.uartDevice.flush();
			if (this.uartDevice.read() != 0xFF)
			{
				// a kdyz to rovno neni tak co? :)
				byte += (0x01 << bit);
			}
		}
		return byte;
	}
}

function example()
{
	local uartDevice = hardware.uart12;
	local oneWire <- OneWire(uartDevice);
	
	if (oneWire.reset())
	{
		server.log("Try reading 18B20");
		oneWire.write(0xCC); // SKIP ROM
		oneWire.write(0x44); // CONVERT_T DS18B20

		imp.sleep(0.750); //wait for conversion to finish

		oneWire.eset();
		oneWire.write(0xCC); // SKIP ROM
		oneWire.write(0xBE); // READ_SCRATCHPAD DS18B20
		
		server.log(oneWire.read()); //temp LSB
		server.log(oneWire.read()); //temp MSB
	}
}

