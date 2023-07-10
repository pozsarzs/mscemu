{ +--------------------------------------------------------------------------+ }
{ | MSCEmu v0.1 * Mini serial console emulator for MM8D                      | }
{ | Copyright (C) 2023 Pozsar Zsolt <pozsarzs@gmail.com>                     | }
{ | mscemu.pas                                                               | }
{ | main program                                                             | }
{ +--------------------------------------------------------------------------+ }

{
  This program is Public Domain, you can redistribute it and/or modify
  it under the terms of the Creative Common Zero Universal version 1.0.
}

program mscemu;
uses
  crt;
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
var
  ba: word;                                                    { base address }
  page: byte;                                                { page of screen }
  {general variables}
  b:  byte;
  c:  char;
  s:  string;
  p:  byte;
  w:  word;

{ set cursor }
procedure cursor(b: boolean);
begin
  if b then
    asm
      MOV AL, $00;
      MOV AH, $01;
      MOV CL, $07;
      MOV CH, $06;
      INT $10
  end else
    asm
      MOV AL, $00;
      MOV AH, $01;
      MOV CL, $00;
      MOV CH, $10;
      INT $10
    end;
end;

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

{ write footer to screen }
procedure footer(page: byte);
var
  b: byte;
const
  FTR: array[1..3] of string=(' F1 Signs  &F2 Status  &F3 Consumption  &ESC Exit',
                              ' &F1 Signs  F2 Status  &F3 Consumption  &ESC Exit',
                              ' &F1 Signs  &F2 Status  F3 Consumption  &ESC Exit');
begin
  window(1,1,80,25);
  textbackground(lightgray);
  textcolor(black);
  gotoxy(1,25); clreol;
  for b := 1 to length(FTR[page]) do
  begin
   if FTR[page][b] = '&' then textcolor(red) else write(FTR[page][b]);
   if FTR[page][b] = ' ' then textcolor(black);
  end;
end;

{ write frame to screen }
procedure frame(page: byte);
const
  CH0: array[0..7] of string = ('T','','BE','LP','HP','T1','T2','T3');
  CH1: array[0..7] of string = ('T','RH','OM','CM','BE','LA','VE','HE');
var
  b: byte;
begin
  window(1,1,80,25);
  textbackground(blue);
  textcolor(white);
  clrscr;
  case page of
    1: begin
         { lines }
         textbackground(cyan);
         clrscr;
         gotoxy(1,1); write('Ú');
         gotoxy(80,1); write('¿');
         for b := 2 to 79 do
         begin
           gotoxy(b,1); write('Ä');
           gotoxy(b,24); write('Ä');
         end;
         for b := 2 to 24 do
         begin
           gotoxy(1,b); write('³');
           gotoxy(80,b); write('³');
         end;
         gotoxy(1,24); write('À');
         gotoxy(80,24); write('Ù');
       end;
    2: begin
         { lines }
         gotoxy(1,1); write('Ú');
         gotoxy(80,1); write('¿');
         for b := 2 to 79 do
         begin
           gotoxy(b,1); write('Ä');
           gotoxy(b,24); write('Ä');
           gotoxy(b,16); write('Ä');
           gotoxy(b,11); write('Ä');
         end;
         for b := 2 to 24 do
         begin
           gotoxy(1,b); write('³');
           if ((b > 1) and (b < 11)) or ((b > 11) and (b < 16)) then
           begin
             gotoxy(17,b); write('³');
           end;
           gotoxy(80,b); write('³');
         end;
         gotoxy(1,24); write('À');
         gotoxy(80,24); write('Ù');
         { titles }
         gotoxy(3,1); write(' Status and values ');
         gotoxy(3,16); write(' Log ');
         gotoxy(3,11); write(' Override ');
         for b := 0 to 7 do
         begin
           gotoxy(3,b + 3);
           if length(ch0[b]) > 0 then write(CH0[b] + ':');
           gotoxy(19,b + 3); write(CH1[b] + ':');
           if b > 4 then
           begin
             gotoxy(3,b + 8);
             if length(ch0[b]) > 0 then write(CH0[b] + ':');
             gotoxy(19,b + 8); write(CH1[b] + ':');
           end;
         end;
         textcolor(yellow);
         gotoxy(3,2); write('CH:');
         gotoxy(19,2); write('CH:');
         gotoxy(3,12); write('CH:');
         gotoxy(19,12); write('CH:');
         for b := 0 to 8 do
         begin
           if b = 0 then gotoxy(8,2) else gotoxy(17 + b * 7,2); write('#',b);
           if b = 0 then gotoxy(8,12) else gotoxy(17 + b * 7,12); write('#',b);
         end;
         { log box }
         window(3,17,78,23);
         textbackground(black);
         textcolor(lightgray);
         clrscr;
         window(1,1,80,25);
         textbackground(blue);
         textcolor(white);
       end;
    3: begin
         { lines }
         gotoxy(1,1); write('Ú');
         gotoxy(80,1); write('¿');
         for b := 2 to 79 do
         begin
           gotoxy(b,1); write('Ä');
           gotoxy(b,16); write('Ä');
           gotoxy(b,24); write('Ä');
         end;
         for b := 2 to 24 do
         begin
           gotoxy(1,b); write('³');
           gotoxy(80,b); write('³');
         end;
         gotoxy(1,24); write('À');
         gotoxy(80,24); write('Ù');
         { titles }
         gotoxy(3,16); write(' Log ');
         { log box }
         window(3,17,78,23);
         textbackground(black);
         textcolor(lightgray);
         clrscr;
         window(1,1,80,25);
         textbackground(blue);
         textcolor(white);
       end;
  end;
  { footer }
  footer(page);
end;

{ write log to screen }
procedure writelog(s: string);
begin
  if (length(s) > 0) and (page > 1) then
  begin
    window(3,17,78,23);
    textbackground(black);
    textcolor(lightgray);
    if p = 8 then
    begin
      gotoxy(1,p - 1);
      writeln;
    end;
    if p = 8 then gotoxy(2,p - 1) else gotoxy(2,p);
    write(s);
    if p < 8 then inc(p);
    window(1,1,80,25);
    textcolor(white);
    textbackground(blue);
  end;
end;

{ write CH data to screen }
procedure writechdata(s: string);
var
  c: char;

  procedure write01(c: char; x, y: byte);
  begin
    gotoxy(x,y);
    case c of
      #0: write('0');
      #1: write('1');
      #2: write('0');
      #3: write('1');
    end;
  end;

  procedure writeovr(c: char; x, y: byte);
  begin
    gotoxy(x,y);
    case c of
      #2: write('off');
      #3: write('on');
    else
      write('neut.');
    end;
  end;

  procedure writeam(c: char; x, y: byte);
  begin
    gotoxy(x,y);
    if c = #0 then write('A') else write('M');
  end;

  procedure writehmd(c: char; x, y: byte);
  begin
    gotoxy(x,y);
    case c of
      #0: write('H');
      #1: write('M');
    else
      write('D');
    end;
  end;

begin
  if (length(s) >= 10) and (page = 2) then
  begin
    window(1,1,80,25);
    textbackground(blue);
    textcolor(white);
    if s[3] = #0 then
    begin
      { CH #0 }
      for b := 4 to 10 do
        if b = 7 then
        begin
          gotoxy(8,3); write(byte(s[7]),' øC ');
        end else
          if b < 7 then write01(s[b],8,b + 1) else write01(s[b],8,b);
      for b := 8 to 10 do
        writeovr(s[b],8,b + 5);
    end else
    begin
      { CH #1-8 }
      gotoxy(24 + (byte(s[3]) - 1) * 7,3); write(byte(s[4]),' øC');
      gotoxy(24 + (byte(s[3]) - 1) * 7,4); write(byte(s[5]),'%');
      writehmd(s[7],24 + (byte(s[3]) - 1) * 7,5);
      writeam(s[8],24 + (byte(s[3]) - 1) * 7,6);
      for b := 9 to 13 do
        if b <> 10 then
          if b = 9
          then
            write01(s[b],24 + (byte(s[3]) - 1) * 7,b - 2)
          else
            write01(s[b],24 + (byte(s[3]) - 1) * 7,b - 3);
      for b := 11 to 13 do
        writeovr(s[b],24 + (byte(s[3]) - 1) * 7,b + 2)
    end;
  end;
end;

procedure writespdata(s: string);
begin
  if (length(s) >= 10) and (page = 3) then
  begin
    window(1,1,80,25);
    textbackground(blue);
    textcolor(white);
  end;
end;

begin
  { check command line parameter}
  w := COM1;
  if paramcount > 0 then
  begin
    if paramstr(1) = '1' then w := COM1 else
      if paramstr(1) = '2' then w := COM2 else
        if paramstr(1) = '3' then w := COM3 else
          if paramstr(1) = '4' then w := COM4 else
            begin
              writeln('Usage: mscemu.exe [1..4]  COMx port');
              halt(1);
            end;
  end;
  { init serial port }
  initserialport(w,PNoneParity or s1StopBit or d8DataBit);
  setspeed(bps9600);
  { make background }
  cursor(false);
  page := 2;
  frame(page);
  { read from serial port and write data to screen }
  b := 0;
  s := '';
  p := 1;
  repeat
    if keypressed then
    begin
      c := readkey;
      if c = #0 then c := readkey;
      if c = #59 then begin page := 1; frame(page); end;
      if c = #60 then begin page := 2; frame(page); end;
      if c = #61 then begin page := 3; frame(page); end;
    end;
    if dataready then
    begin
      s := s + receivechar;
      b := 0;
    end else b := b + 1;
    delay(1);
    if b > 200 then
    begin
      if (s[1] + s[2] <> 'CH') and (s[1] + s[2] <> 'SP') then writelog(s);
      if s[1] + s[2] = 'CH' then writechdata(s);
      if s[1] + s[2] = 'SP' then writespdata(s);
      s := '';
      b := 0;
    end;
 until c = #27;
 cursor(true);
 textbackground(black);
 textcolor(lightgray);
 clrscr;
end.