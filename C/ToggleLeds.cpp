/*
    Blink two LEDs (PB1 and PB2) on an ATmega328p at 1 Hz on opposite duty cycles

    The MIT License (MIT)

    Copyright (c) 2020 Igor Mikolic-Torreira

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/


#include <avr/io.h>
#include <avr/interrupt.h>

extern "C" void delayTenthsOfSeconds( char );



const char kPauseTime = 20;                     // Seconds



ISR( TIMER1_COMPA_vect )
{
    // Toggle pins.  Note that PORTx bits can be toggled by writing a 1 to the corresponding PINx bit.

    PINB |= (1 << PINB1);                       // Toggle the green LED
    PINB |= (1 << PINB2);                       // Toggle the red LED
}



int main()
{
    DDRB |= (1 << DDB1);                        // Green LED to output mode
    DDRB |= (1 << DDB2);                        // Red LED to output mode

    PORTB |= (1 << PORTB1);                     // Green LED high
    PORTB |= (1 << PORTB2);                     // Red LED high

    delayTenthsOfSeconds( kPauseTime );

    PORTB &= ~(1 << PORTB1);                    // Green LED low
    PORTB &= ~(1 << PORTB2);                    // Red LED low

    delayTenthsOfSeconds( kPauseTime );

    PORTB |= (1 << PORTB1);                     // Green LED high

    TCCR1B = (1 << WGM12) | (1 << CS12);       // CTC mode
    OCR1A  = 62499;                            // "Top" for 1Hz output with prescalar of 256
    TIMSK1 = (1 << OCIE1A);                    // Enable CTC interrupt

    sei();                                      //  Enable global interrupts

    while ( 1 )
    {
        // Do nothing
    }
}
