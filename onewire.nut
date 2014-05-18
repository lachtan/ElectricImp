// http://electricimp.com/docs/resources/onewire/

class OneWire
{
	uartDevice = null;
	id = null;
	nextDevice = 65;

	
	constructor(uartDevice)
	{
		this.uartDevice = uartDevice;
	}
	
	function reset()
	{
		this.uartDevice.configure(9600, 8, PARITY_NONE, 1, NO_CTSRTS);
		this.uartDevice.write(0xf0);
		this.uartDevice.flush();

		if (this.uartDevice.read() == 0xf0)
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
		for (local i = 0; i < 8; i++, byte = byte >> 1)
		{
			writeBit(byte & 0x01);
		}
	} 
	
	function read()
	{
		local byte = 0;
		for (local i = 0; i < 8; i++)
		{
			byte = (byte >> 1) + 0x80 * writeBit(1);
		}
		return byte;
	}
	
	function writeBit(bit)
	{
	    bit = bit ? 0xff : 0x00;
	    this.uartDevice.write(bit);
	    this.uartDevice.flush();
	    local value = this.uartDevice.read() == 0xff ? 1 : 0;
	    return value;
	}
	
	function search(nextNode)
	{
	    local lastForkPoint = 0;
	 
	    if (!reset())
	    {
	    	return lastForkPoint;
	    }

		write(0xF0);

		for (local i = 64; i > 0; i--) 
		{
			local byte = (i - 1) / 8;
			local bit = writeBit(1);
			if (writeBit(1))
			{
				if (bit) 
				{
					lastForkPoint = 0;
					break;
				}
			} 
			else if (!bit) 
			{
				if (nextNode > i || (nextNode != i && (id[byte] & 1)))
				{
					bit = 1;
					lastForkPoint = i;
				}                
			}
			writeBit(bit);
			id[byte] = (id[byte] >> 1) + 0x80 * bit;
		}
		return lastForkPoint;
	}
	
	function devices()
	{
	    id = [0,0,0,0,0,0,0,0];
	    nextDevice = 65;
	    local slaves = [];
	 
	    while (nextDevice)
	    {
	        nextDevice = search(nextDevice);
	        
	        slaves.push(clone(id));
	    }
	    
	    return slaves;
	}
}
 
class Temperature
{
	oneWire = null;
	
	constructor(oneWire)
	{
		this.oneWire = oneWire;
	}
	
	function oneDeviceMeasure()
	{
		local lsb = 0; 
		local msb = 0; 
		local celsius = 0; 

		if (!oneWire.reset())
		{
			// zadne zarizeni neni pritomno
			return -1000;
		}

		oneWire.write(0xcc);
		oneWire.write(0x44);

		imp.sleep(0.8);

		oneWire.reset();
		oneWire.write(0xcc);
		oneWire.write(0xbe);

		lsb = oneWire.read();
		msb = oneWire.read();

		oneWire.reset();
		
		celsius = ((msb * 256) + lsb) / 16.0;
		return celsius;		
	}
	
	function measure(device)
	{
		local lsb = 0; 
		local msb = 0; 
		local celsius = 0; 
	    
	    oneWire.reset();
	    oneWire.write(0xcc);
		oneWire.write(0x44);
	    
	    imp.sleep(0.75);
	 
		if (device[7] != 0x28)
		{
			// neumim zmerit
			return -1000;
		}

		oneWire.reset();
		oneWire.write(0x55);
		for (local i = 7; i >= 0; i--)
		{
			oneWire.write(device[i]);
		}
		oneWire.write(0xbe);

		lsb = oneWire.read();
		msb = oneWire.read();

		oneWire.reset();
		
		celsius = ((msb * 256) + lsb) / 16.0;
		return celsius;		
	}
}
 
function formatDeviceId(id)
{
	return format("%02x-%02x%02x%02x%02x%02x%02x", id[7], id[1], id[2], id[3], id[4], id[5], id[6]);
}

function logTemp()
{		
	local devices = oneWire.devices();
	foreach (device, id in devices)	
	{
		local celsius = temperature.measure(id);
		id = formatDeviceId(id);
		server.log(format("%s Temperature: %3.2f degrees C", id, celsius));
		
		local data = {
		    "imp": hardware.getdeviceid(),
		    "mac": imp.getmacaddress(),
		    "id": id,
		    "celsius": celsius
		};

		agent.send("temp", data);
	}
}

function delay(delay)
{
	local start = hardware.millis();
	while (hardware.millis() - start < delay);
}

function ledBlink()
{
	for (local i = 0; i < 3; i++)
	{
		led.write(1);
		delay(20);
		led.write(0);
		delay(50);
	}
}

function measure()
{
	server.log("--------------------------------------------------");
	//imp.wakeup(10.0, awakeAndGetTemp);
	logTemp();	
	ledBlink();
	server.log("Go to sleep for 60 seconds");
	server.sleepfor(60);
}

// ----------------------------------------------------------------------------
// main
// ----------------------------------------------------------------------------

oneWire <- OneWire(hardware.uart12);
temperature <- Temperature(oneWire);

led <- hardware.pin9;
led.configure(DIGITAL_OUT);

imp.onidle(measure);
