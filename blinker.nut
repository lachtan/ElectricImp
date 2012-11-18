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
	detectDirectionPin = null;
	
	constructor(ledLines, detectDirectionPin)
	{
		this.ledLines = ledLines;
		this.detectDirectionPin = detectDirectionPin;
		setDirection(true);
		OfflineStateTime = PeriodTime / ledLines.len() - OnlineStateTime;
		init();
	}
	
	function start()	
	{
		blink();
	}
	
	function changeDirection()
	{
		direction = -direction;
	}
	
	function setDirection(normal)
	{
		direction = normal ? 1 : -1;
	}
	
	function init()
	{
		detectDirectionPin.configure(DIGITAL_IN_PULLUP, detectDirection.bindenv(this));
		foreach(index, ledLine in ledLines)
		{
			ledLine.configure(DIGITAL_OUT_OD_PULLUP);
		}
	}
	
	function detectDirection()
	{
		local state = hardware.pin9.read();
		setDirection(state);
	}
	
	function blink()
	{
		local ledLine = ledLines[actualLed];	
		ledState = !ledState;
		light(ledLine, ledState);
		local delay = ledState ? OnlineStateTime : OfflineStateTime;
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

function changeDirection()
{
}

local ledLines = [
	hardware.pin1,
	hardware.pin2,
	hardware.pin5,
	hardware.pin7
];
 
imp.configure("Blinker", [], []);
info();
blinker <- Blinker(ledLines, hardware.pin9);
blinker.start();