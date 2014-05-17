// https://gist.github.com/smittytone/11370844#file-one_wire_single-device-nut

function one_wire_reset()
{
    // Configure UART for 1-Wire RESET timing
    
    ow.configure(9600, 8, PARITY_NONE, 1, NO_CTSRTS);
    ow.write(0xF0);
    ow.flush();
    if (ow.read() == 0xF0)
    {
        // UART RX will read TX if there's no device connected
        
        server.log("No 1-Wire devices are present.");
        return false;
    } 
    else 
    {
        // Switch UART to 1-Wire data speed timing
        
        ow.configure(115200, 8, PARITY_NONE, 1, NO_CTSRTS);
        return true;
    }
}
 
 
function one_wire_write_byte(byte)
{
    for (local i = 0; i < 8; i++, byte = byte >> 1)
    {
        // Run through the bits in the byte, extracting the
        // LSB (bit 0) and sending it to the bus
        
        one_wire_bit(byte & 0x01);
    }
} 
 
 
function one_wire_read_byte()
{
    local byte = 0;
    for (local i = 0; i < 8; i++)
    {
        // Build up byte bit by bit, LSB first
        
        byte = (byte >> 1) + 0x80 * one_wire_bit(1);
    }
    
    return byte;
}
 
 
function one_wire_bit(bit)
{
    bit = bit ? 0xFF : 0x00;
    ow.write(bit);
    ow.flush();
    local return_value = ow.read() == 0xFF ? 1 : 0;
    return return_value;
}
 
 
// Wake up every 5 seconds and write to the server
 
function awake_and_get_temp()
{
    local temp_LSB = 0; 
    local temp_MSB = 0; 
    local temp_celsius = 0; 
    
    // Run loop again in 5 seconds
    
    imp.wakeup(5.0, awake_and_get_temp);
 
    if (one_wire_reset())
    {
        one_wire_write_byte(0xCC);
        one_wire_write_byte(0x44);
        
        imp.sleep(0.8);     // Wait for at least 750ms for data to be collated
    
        one_wire_reset();
        one_wire_write_byte(0xCC);
        one_wire_write_byte(0xBE);
        
        temp_LSB = one_wire_read_byte();
        temp_MSB = one_wire_read_byte();
    
        one_wire_reset();   // Reset bus to stop sensor sending unwanted data
    
        temp_celsius = ((temp_MSB * 256) + temp_LSB) / 16.0;
        
        server.log(format("Temperature: %3.2f degrees C", temp_celsius));
    }
}
 
 
// PROGRAM STARTS HERE
 
ow <- hardware.uart12;
 
awake_and_get_temp();

