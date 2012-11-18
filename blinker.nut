/*
 * Basic code structure
 * http://devwiki.electricimp.com/doku.php?id=basiccodestructure
 *
 * Garbage collector problems
 * http://devwiki.electricimp.com/doku.php?id=garbagecollectorproblems
 *
 * Squirrel 3.0 Reference Manual
 * http://squirrel-lang.org/doc/squirrel3.html
 *
 */

function light(led, state)
{
	local value = state ? 1 : 0;
	led.write(value);
}

function info()
{
	server.log("Voltage: " + hardware.voltage());
	server.log("ID: " + hardware.getimpeeid());
	server.log("WiFi strength: " + imp.rssi());
	server.log("MAC: " + imp.getmacaddress());
}

class Blinker
{
	PeriodTime = 1.0;
	OnlineStateTime = 0.05;
	OfflineStateTime = null;
	
	ledLines = null;
	direction = null;
	ledState = false;	
	actualLed = 0;	
	
	constructor(ledLines, reverseDirection = false)
	{
		this.ledLines = ledLines;
		direction = reverseDirection ? -1 : 1;
		OfflineStateTime = PeriodTime / ledLines.len() - OnlineStateTime;
		init();
	}
	
	function start()	
	{
		blink();
	}
	
	function init()
	{
		foreach(index, ledLine in ledLines)
		{
			ledLine.configure(DIGITAL_OUT_OD_PULLUP);
		}
	}
	
	function blink()
	{
		local ledLine = ledLines[actualLed];	
		ledState = !ledState;
		light(ledLine, ledState);
		local delay = ledState ? 0.05 : 0.2;
		if (!ledState)
		{
			actualLed = (actualLed + direction) % ledLines.len();
			if (actualLed < 0)
			{
				actualLed += ledLines.len();
			}
		}
		imp.wakeup(delay, blink.bindenv(this));
	}	
}


local ledLines = [
	hardware.pin1,
	hardware.pin2,
	hardware.pin5,
	hardware.pin7
];
 
imp.configure("Blinker", [], []);
info();
blinker <- Blinker(ledLines, true);
blinker.start();

