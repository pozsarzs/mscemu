{ +--------------------------------------------------------------------------+ }
{ | MSCEmu v0.1 * Mini serial console emulator for MM8D                      | }
{ | Copyright (C) 2023 Pozsar Zsolt <pozsarzs@gmail.com>                     | }
{ | unserial.pas                                                             | }
{ | serial port handler                                                      | }
{ +--------------------------------------------------------------------------+ }

{
  This program is Public Domain, you can redistribute it and/or modify
  it under the terms of the Creative Common Zero Universal version 1.0.
}

unit unserial;
interface
var
  ba: integer;
const
  { serial port parameters }
  bps1200     =   96;
  bps2400     =   48;
  bps4800     =   24;
  bps9600     =   12;
  bps14400    =    8;
  bps19200    =    6;
  bps28800    =    4;
  bps38400    =    3;
  bps57600    =    2;
  bps115200   =    1;
  pNoneParity =  $00;
  pEvenParity =  $18;
  pOddParity  =  $08;
  s1StopBit   =  $00;
  s2StopBit   =  $04;
  d5DataBit   =  $00;
  d6DataBit   =  $01;
  d7DataBit   =  $02;
  d8DataBit   =  $03;
  COM1        = $3f8;
  COM2        = $2f8;
  COM3        = $2e8;
  COM4        = $3e8;
  { offset of the UART registers }
  THR         =  $00;                             { Transmit Holding Register }
  RBR         =  $00;                               { Receive Buffer Register }
  DLL         =  $00;                                { Divisor Latch Low byte }
  DLH         =  $01;                               { Divisor Latch High byte }
  IER         =  $01;                             { Interrupt Enable Register }
  IIR         =  $02;                     { Interrupt Identification Register }
  LCR         =  $03;                                 { Line Control Register }
  MCR         =  $04;                                { Modem Control Register }
  LSR         =  $05;                                  { Line Status Register }
  MSR         =  $06;                                 { Modem Status Register }
  SCR         =  $07;                                      { Scratch Register }

procedure initserialport(com: word; defaults: byte);
procedure setspeed(speed: word);
procedure sendchar(c: char);
function  receivechar: char;
function  dataready: boolean;

implementation

{ set speed of the serial port }
procedure setspeed(speed: word); assembler;
asm
  MOV   DX,ba
  ADD   DX,LCR
  IN    AL,DX
  OR    AL,10000000B
  OUT   DX,AL
  MOV   BL,AL
  SUB   DX,LCR
  MOV   AX,speed
  OUT   DX,AX
  ADD   DX,LCR
  MOV   AL,BL
  AND   AL,01111111B
  OUT   DX,AL
end;

{ initialize serial port }
procedure initserialport(com: word; defaults: byte); assembler;
asm
  MOV   DX,com
  MOV   BA,DX
  IN    AL,DX
  MOV   AL,defaults
  AND   AL,01111111B
  ADD   DX,LCR
  OUT   DX,AL
  INC   DX            { MCR      }
  IN    AL,DX
  AND   AL,$01
  OR    AL,$0A
  OUT   DX,AL         { set  MCR }
  MOV   DX,ba
  IN    AL,DX         { read RBR }
  ADD   DX,MSR
  IN    AL,DX         { read MSR }
  DEC   DX
  IN    AL,DX         { read LSR }
  SUB   DX,3
  IN    AL,DX         { read IIR }
end;

{ send a character via serial port }
procedure sendchar(c: char); assembler;
asm
  MOV   DX,ba
  ADD   DX,LSR
@WAIT:
  IN    AL,DX
  AND   AL,00100000B
  JZ    @WAIT
  SUB   DX,5
  MOV   AL,c
  OUT   DX,AL
end;

{ recevice a character from serial port }
function  receivechar: char; assembler;
asm
  MOV   DX,ba
  IN    AL,DX          { read RBR }
end;

{ is there a received character? }
function  dataready: boolean; assembler;
asm
  MOV   DX,ba
  ADD   DX,LSR
  IN    AL,DX
  AND   AL,00000001B
end;
end.